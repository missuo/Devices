//
//  AppDelegate.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize app settings if needed
        if UserDefaults.standard.object(forKey: "backends") == nil {
            UserDefaults.standard.set([], forKey: "backends")
        }
        
        return true
    }
}
