//
//  GroundControlTesterApp.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI

@main
struct GroundControlTesterApp: App {
    
    // ✅ 1. Create the state for the navigation path
    @State private var path = NavigationPath()
    
    var body: some Scene {
        WindowGroup {
            // ✅ 2. Bind the NavigationStack to the path
            NavigationStack(path: $path) {
                // ✅ 3. Pass the path binding into ContentView
                ContentView(path: $path)
            }
        }
    }
}
