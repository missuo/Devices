//
//  ContentView.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var apiService: APIService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DeviceRegistrationView()
                .tabItem {
                    Label("Register Device", systemImage: "iphone")
                }
                .tag(0)
                .environmentObject(apiService)
            
            ProfileGenerationView()
                .tabItem {
                    Label("Generate Profile", systemImage: "doc.badge.plus")
                }
                .tag(1)
                .environmentObject(apiService)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
                .environmentObject(apiService)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(APIService())
    }
}
