//
//  SettingsView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var backends: [Backend] = []
    @State private var showingAddBackend = false
    @State private var backendStatus: [UUID: Bool] = [:]
    @State private var editMode: EditMode = .inactive
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Active Backend")) {
                    if let backend = apiService.selectedBackend {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backend.name)
                                    .font(.headline)
                                Text(backend.url)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Circle()
                                    .fill(backendStatus[backend.id] ?? false ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Text(backendStatus[backend.id] ?? false ? "Online" : "Offline")
                                    .font(.caption)
                                    .foregroundColor(backendStatus[backend.id] ?? false ? .green : .red)
                            }
                        }
                    } else {
                        Text("No active backend")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("All Backends")) {
                    if backends.isEmpty {
                        Text("No backends configured")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(backends) { backend in
                            BackendRowSettingsView(backend: backend, isOnline: backendStatus[backend.id] ?? false)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if editMode == .inactive {
                                        selectBackend(backend)
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        selectBackend(backend)
                                    }) {
                                        Label("Set as Active", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        apiService.removeBackend(backend)
                                        refreshBackends()
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deleteBackend)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBackend = true }) {
                        Label("Add Backend", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .refreshable {
                refreshBackends()
                checkAllBackendStatus()
            }
            .sheet(isPresented: $showingAddBackend) {
                NavigationView {
                    AddBackendView(isPresented: $showingAddBackend)
                        .environmentObject(apiService)
                        .navigationTitle("Add Backend")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingAddBackend = false
                                    refreshBackends()
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            refreshBackends()
            checkAllBackendStatus()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                checkAllBackendStatus()
                refreshBackends()
            }
        }
        // Add a listener for changes to the selected backend
        .onReceive(apiService.objectWillChange) { _ in
            refreshBackends()
        }
    }
    
    private func refreshBackends() {
        backends = apiService.loadBackends()
    }
    
    private func checkAllBackendStatus() {
        for backend in backends {
            apiService.checkHealth(for: backend) { isOnline in
                backendStatus[backend.id] = isOnline
            }
        }
    }
    
    private func selectBackend(_ backend: Backend) {
        guard backendStatus[backend.id] == true else {
            // Don't select offline backends
            return
        }
        
        apiService.setActiveBackend(backend)
        refreshBackends()
    }
    
    private func deleteBackend(at offsets: IndexSet) {
        for index in offsets {
            apiService.removeBackend(backends[index])
        }
        refreshBackends()
    }
}

struct BackendRowSettingsView: View {
    @EnvironmentObject private var apiService: APIService
    let backend: Backend
    let isOnline: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(backend.name)
                    .font(.headline)
                Text(backend.url)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Circle()
                    .fill(isOnline ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(isOnline ? .green : .red)
            }
            
            // Check if this backend is the selected backend
            if apiService.selectedBackend?.id == backend.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}
