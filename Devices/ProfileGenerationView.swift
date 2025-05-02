//
//  ProfileGenerationView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileGenerationView: View {
    @EnvironmentObject private var apiService: APIService
    
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var profileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Generate Ad Hoc Provisioning Profile")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("This will create a new Ad Hoc provisioning profile that includes all registered devices for your app bundle ID.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                if let errorMessage = apiService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                Button(action: generateProfile) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    } else {
                        Text("Generate Profile")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .disabled(isGenerating || apiService.selectedBackend == nil)
            }
            .navigationTitle("Generate Profile")
            .sheet(isPresented: $showShareSheet) {
                if let url = profileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func generateProfile() {
        isGenerating = true
        apiService.errorMessage = nil
        
        apiService.createAndDownloadProfile { result in
            isGenerating = false
            
            switch result {
            case .success(let url):
                profileURL = url
                showShareSheet = true
            case .failure:
                // Error is already handled by APIService
                break
            }
        }
    }
}

// Helper for sharing files
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}
