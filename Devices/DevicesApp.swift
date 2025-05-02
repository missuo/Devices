//
//  DevicesApp.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

@main
struct ASCProvisionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var apiService = APIService()
    
    var body: some Scene {
        WindowGroup {
            if apiService.selectedBackend == nil {
                BackendSelectionView()
                    .environmentObject(apiService)
            } else {
                ContentView()
                    .environmentObject(apiService)
            }
        }
    }
}
