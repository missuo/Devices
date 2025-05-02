//
//  BackendSelectionView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

struct BackendSelectionView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var backends: [Backend] = []
    @State private var showingAddBackend = false
    @State private var isRefreshing = false
    @State private var backendStatus: [UUID: Bool] = [:]
    
    var body: some View {
        NavigationView {
            List {
                if backends.isEmpty {
                    Text("No backends configured")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(backends) { backend in
                        BackendRowView(backend: backend, isOnline: backendStatus[backend.id] ?? false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectBackend(backend)
                            }
                    }
                    .onDelete(perform: deleteBackend)
                }
            }
            .refreshable {
                await refreshBackendStatus()
            }
            .navigationTitle("ASC Provision")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBackend = true }) {
                        Label("Add Backend", systemImage: "plus")
                    }
                }
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
        }
        // Add a listener for changes to the selected backend
        .onReceive(apiService.objectWillChange) { _ in
            refreshBackends()
        }
    }
    
    private func refreshBackends() {
        backends = apiService.loadBackends()
        Task {
            await refreshBackendStatus()
        }
    }
    
    private func refreshBackendStatus() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        for backend in backends {
            await checkBackendStatus(backend)
        }
    }
    
    private func checkBackendStatus(_ backend: Backend) async {
        await withCheckedContinuation { continuation in
            apiService.checkHealth(for: backend) { isOnline in
                backendStatus[backend.id] = isOnline
                continuation.resume()
            }
        }
    }
    
    private func selectBackend(_ backend: Backend) {
        guard backendStatus[backend.id] == true else {
            // Don't select offline backends
            return
        }
        
        apiService.setActiveBackend(backend)
        // Force refresh the UI
        refreshBackends()
    }
    
    private func deleteBackend(at offsets: IndexSet) {
        for index in offsets {
            apiService.removeBackend(backends[index])
        }
        refreshBackends()
    }
}

struct BackendRowView: View {
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
        .padding(.vertical, 4)
    }
}
