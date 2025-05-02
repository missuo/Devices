//
//  DeviceRegistrationView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DeviceRegistrationView: View {
    @EnvironmentObject private var apiService: APIService
    
    @State private var deviceName = ""
    @State private var deviceUDID = ""
    @State private var showSuccessAlert = false
    @State private var registeredDevice: Device?
    @State private var showPasteOptions = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Information")) {
                    TextField("Device Name", text: $deviceName)
                        .autocapitalization(.words)
                    
                    ZStack(alignment: .trailing) {
                        TextField("Device UDID", text: $deviceUDID)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !deviceUDID.isEmpty {
                            Button(action: {
                                deviceUDID = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 4)
                        } else {
                            Button(action: {
                                showPasteOptions = true
                            }) {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing, 4)
                            .confirmationDialog("Paste from clipboard", isPresented: $showPasteOptions, titleVisibility: .visible) {
                                Button("Paste") {
                                    if let string = UIPasteboard.general.string {
                                        // Clean the string - UDID is 40 hex characters
                                        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if let range = cleaned.range(of: "[A-Fa-f0-9]{40}", options: .regularExpression) {
                                            deviceUDID = String(cleaned[range])
                                        } else {
                                            deviceUDID = cleaned
                                        }
                                    }
                                }
                                
                                Button("Cancel", role: .cancel) { }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: registerDevice) {
                        HStack {
                            Text("Register Device")
                                .frame(maxWidth: .infinity)
                            
                            if apiService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(deviceName.isEmpty || deviceUDID.isEmpty || apiService.isLoading)
                }
                
                if let errorMessage = apiService.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Guide")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to find your device's UDID:")
                            .font(.headline)
                        
                        Text("1. Connect your device to a computer")
                        Text("2. Open Finder (macOS) or iTunes (Windows)")
                        Text("3. Select your device")
                        Text("4. Click on the device name or serial number multiple times until the UDID appears")
                        Text("5. Right-click and copy the UDID")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Register Device")
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Device \(registeredDevice?.name ?? "") was successfully registered."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func registerDevice() {
        guard !deviceName.isEmpty, !deviceUDID.isEmpty else { return }
        
        apiService.registerDevice(name: deviceName, udid: deviceUDID) { result in
            switch result {
            case .success(let device):
                registeredDevice = device
                showSuccessAlert = true
                // Reset the form
                deviceName = ""
                deviceUDID = ""
            case .failure:
                // Error is already handled by APIService
                break
            }
        }
    }
}
