//
//  AddBackendView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

struct AddBackendView: View {
    @EnvironmentObject private var apiService: APIService
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var url = "https://"
    @State private var apiKey = ""
    @State private var isCheckingConnection = false
    @State private var connectionStatus: Bool? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Backend Information")) {
                TextField("Name", text: $name)
                    .autocapitalization(.none)
                
                TextField("URL", text: $url)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                
                TextField("API Key", text: $apiKey)
                    .autocapitalization(.none)
            }
            
            Section {
                Button(action: testConnection) {
                    if isCheckingConnection {
                        HStack {
                            Text("Testing connection...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Test Connection")
                    }
                }
                .disabled(isCheckingConnection || !isFormValid)
                
                if let status = connectionStatus {
                    HStack {
                        Text(status ? "Connection successful" : "Connection failed")
                        Spacer()
                        Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(status ? .green : .red)
                    }
                }
            }
            
            Section {
                Button(action: saveBackend) {
                    Text("Save Backend")
                }
                .disabled(!isFormValid || isCheckingConnection)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !url.isEmpty && !apiKey.isEmpty && url.starts(with: "http")
    }
    
    private func testConnection() {
        let backend = Backend(name: name, url: url, apiKey: apiKey)
        
        isCheckingConnection = true
        connectionStatus = nil
        
        apiService.checkHealth(for: backend) { isOnline in
            connectionStatus = isOnline
            isCheckingConnection = false
        }
    }
    
    private func saveBackend() {
        guard isFormValid else { return }
        
        let backend = Backend(name: name, url: url, apiKey: apiKey)
        apiService.addBackend(backend)
        isPresented = false
    }
}
