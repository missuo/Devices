//
//  APIService.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import Foundation
import Combine

class APIService: ObservableObject {
    @Published var selectedBackend: Backend?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load active backend on init
        loadActiveBackend()
    }
    
    // MARK: - Backend Management
    
    func loadBackends() -> [Backend] {
        guard let data = UserDefaults.standard.data(forKey: "backends") else {
            return []
        }
        
        do {
            let backends = try JSONDecoder().decode([Backend].self, from: data)
            return backends
        } catch {
            print("Error loading backends: \(error)")
            return []
        }
    }
    
    func loadActiveBackend() {
        let backends = loadBackends()
        selectedBackend = backends.first(where: { $0.isActive })
    }
    
    func saveBackends(_ backends: [Backend]) {
        do {
            let data = try JSONEncoder().encode(backends)
            UserDefaults.standard.set(data, forKey: "backends")
            // Notify observers that backends have changed
            objectWillChange.send()
        } catch {
            print("Error saving backends: \(error)")
        }
    }
    
    func addBackend(_ backend: Backend) {
        var backends = loadBackends()
        
        // If this is the first backend, set it as active
        var newBackend = backend
        if backends.isEmpty {
            newBackend.isActive = true
            selectedBackend = newBackend
        }
        
        backends.append(newBackend)
        saveBackends(backends)
    }
    
    func updateBackend(_ backend: Backend) {
        var backends = loadBackends()
        if let index = backends.firstIndex(where: { $0.id == backend.id }) {
            backends[index] = backend
            saveBackends(backends)
            
            if backend.isActive {
                selectedBackend = backend
            } else if selectedBackend?.id == backend.id {
                selectedBackend = nil
            }
        }
    }
    
    func removeBackend(_ backend: Backend) {
        var backends = loadBackends()
        backends.removeAll(where: { $0.id == backend.id })
        
        // If removing the active backend, find a new active one if possible
        if selectedBackend?.id == backend.id {
            // Clear the selectedBackend
            selectedBackend = nil
            
            // If there are remaining backends, set the first one as active
            if let firstBackend = backends.first {
                var updatedBackend = firstBackend
                updatedBackend.isActive = true
                
                // Update the backend in the array
                if let index = backends.firstIndex(where: { $0.id == firstBackend.id }) {
                    backends[index] = updatedBackend
                }
                
                // Set as selected
                selectedBackend = updatedBackend
            }
        }
        
        saveBackends(backends)
    }
    
    func setActiveBackend(_ backend: Backend) {
        var backends = loadBackends()
        
        // Clear active flag for all backends
        for index in backends.indices {
            backends[index].isActive = (backends[index].id == backend.id)
        }
        
        // Save the updated backends
        saveBackends(backends)
        
        // Update the selectedBackend property
        selectedBackend = backend
        
        // Notify observers that the selection has changed
        objectWillChange.send()
    }
    
    // MARK: - Health Check
    
    func checkHealth(for backend: Backend, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(backend.url)/health") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data,
                      let healthResponse = try? JSONDecoder().decode(HealthResponse.self, from: data),
                      healthResponse.status == "ok" else {
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }.resume()
    }
    
    // MARK: - Device API
    
    func registerDevice(name: String, udid: String, completion: @escaping (Result<Device, Error>) -> Void) {
        guard let backend = selectedBackend, let url = URL(string: "\(backend.url)/api/devices") else {
            completion(.failure(NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No active backend or invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(backend.apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "name": name,
            "udid": udid,
            "platform": "IOS"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode == 401 {
                    throw NSError(domain: "APIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Invalid API key."])
                }
                
                if httpResponse.statusCode != 201 {
                    // Try to parse error message
                    if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                        throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error])
                    } else {
                        throw NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code \(httpResponse.statusCode)"])
                    }
                }
                
                return data
            }
            .decode(type: DeviceResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                completion(.success(response.device))
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Profile API
    
    func createAndDownloadProfile(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let backend = selectedBackend else {
            let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No active backend selected"])
            completion(.failure(error))
            return
        }
        
        guard var url = URL(string: "\(backend.url)/api/profiles/create-and-download") else {
            let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        // Add API key as query parameter for direct download
        url = url.appending(queryItems: [URLQueryItem(name: "api_key", value: backend.apiKey)])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(backend.apiKey)", forHTTPHeaderField: "Authorization")
        
        isLoading = true
        errorMessage = nil
        
        // Generate unique temporary filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("OwO_\(timestamp).mobileprovision")
        
        // Create download task
        let downloadTask = URLSession.shared.downloadTask(with: request) { fileURL, response, error in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "APIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to download profile. Status code: \(httpResponse.statusCode)"])
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let fileURL = fileURL else {
                    let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "File download failed"])
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Move file to temporary location
                do {
                    // Remove any existing file
                    if FileManager.default.fileExists(atPath: tempFileURL.path) {
                        try FileManager.default.removeItem(at: tempFileURL)
                    }
                    
                    try FileManager.default.moveItem(at: fileURL, to: tempFileURL)
                    completion(.success(tempFileURL))
                } catch {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
        
        downloadTask.resume()
    }
}
