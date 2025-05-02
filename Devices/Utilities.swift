//
//  Utilities.swift
//  Devices
//
//  Created by Vincent Yang on 5/2/25.
//

import Foundation
import SwiftUI

// Extension to URL for appending query parameters
extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }
        
        if components.queryItems == nil {
            components.queryItems = []
        }
        
        components.queryItems?.append(contentsOf: queryItems)
        
        return components.url ?? self
    }
}

// Custom view modifiers and extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Custom progress view with label
struct LabeledProgressView: View {
    var label: String
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding(.bottom, 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}

// Alert wrapper for showing errors
struct ErrorAlert: Identifiable {
    var id = UUID()
    var message: String
    var dismissAction: (() -> Void)?
}

// Helper for redacting sensitive information
extension String {
    func redactMiddle() -> String {
        guard self.count > 8 else { return self }
        
        let startIndex = self.index(self.startIndex, offsetBy: 4)
        let endIndex = self.index(self.endIndex, offsetBy: -4)
        
        var redacted = self
        redacted.replaceSubrange(startIndex..<endIndex, with: String(repeating: "•", count: self.distance(from: startIndex, to: endIndex)))
        
        return redacted
    }
}
