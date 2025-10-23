//
//  WebViewContainer.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-23.
//

import SwiftUI

struct WebViewContainer: View {
    @Binding var path: NavigationPath

    let url: URL
    let displayName: String
    private let equativURL = URL(string: "https://equativ.com/")!

    var body: some View {
        VStack(spacing: 0) {
            
            // This is the top-level container for the header bar
            HStack {
                // --- 1. Back Button (Left) ---
                Button(action: {
                    path.removeLast(path.count)
                }) {
                    Label("Home", systemImage: "house")
                        .font(.headline)
                }
                .padding(.leading) // Pin to the left edge

                // --- 2. Title (Center) ---
                Spacer() // Pushes title away from the left button
                
                Text(displayName)
                    .font(.headline)
                    .lineLimit(1) // Don't let long names/URLs wrap
                    .truncationMode(.middle) // Truncate in the middle
                    .padding(.horizontal, 5) // Give it some breathing room
                
                Spacer() // Pushes title away from the right icon
                
                // --- 3. Icon (Right) ---
                NavigationLink(value: equativURL) {
                    Image("equativ")
                        .resizable()
                        .renderingMode(.template) // To color it white
                        .scaledToFit()
                        .frame(height: 10)
                        .padding(.trailing) // Pin to the right edge
                }
            }
            .padding(.vertical, 12) // Give the bar some height
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            
            // --- WebView (Unchanged) ---
            WebView(url: url)
                .edgesIgnoringSafeArea(.bottom)
        }
        // Hide the default navigation bar
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    // Updated preview to test long names
    NavigationStack {
        WebViewContainer(
            path: .constant(NavigationPath()),
            url: URL(string: "https://a-very-long-url-example.com/with/lots/of/path/components")!,
            displayName: "A Very Long Website Name or URL"
        )
    }
}
