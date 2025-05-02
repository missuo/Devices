//
//  Models.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import Foundation

// Backend server configuration
struct Backend: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var url: String
    var apiKey: String
    var isActive: Bool = false
    
    static func == (lhs: Backend, rhs: Backend) -> Bool {
        return lhs.id == rhs.id
    }
}

// Device model matching the API response
struct Device: Identifiable, Codable {
    var id: String
    var name: String
    var udid: String
    var platform: String
    var status: String?
    var deviceClass: String?
    var model: String?
    var addedDate: String?
}

// Profile model matching the API response
struct Profile: Identifiable, Codable {
    var id: String
    var name: String
    var content: String?
    var uuid: String?
    var createdDate: String?
    var expirationDate: String?
}

// API Error response model
struct APIError: Identifiable, Codable {
    var id = UUID()
    var error: String
}

// API Response wrappers
struct DeviceResponse: Codable {
    var device: Device
}

struct DevicesResponse: Codable {
    var devices: [Device]
}

struct ProfileResponse: Codable {
    var profile: Profile
}

struct ProfilesResponse: Codable {
    var profiles: [Profile]
}

struct MessageResponse: Codable {
    var message: String
}

struct HealthResponse: Codable {
    var status: String
}
