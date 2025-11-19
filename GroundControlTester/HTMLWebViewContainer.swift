//
//  HTMLWebViewContainer.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI

struct HTMLWebViewContainer: View {
    @Binding var path: NavigationPath

    let htmlString: String
    private let equativURL = URL(string: "https://equativ.com/")!

    var body: some View {
        VStack(spacing: 0) {
            
            // This is the top-level container for the header bar
            HStack {
                // --- 1. Back Button (Left) ---
                Button(action: {
                    // Go back to the HTML Input View, not all the way home
                    path.removeLast()
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }
                .padding(.leading)

                // --- 2. Title (Center) ---
                Spacer()
                
                Text("Custom HTML")
                    .font(.headline)
                
                Spacer()
                
                // --- 3. Icon (Right) ---
                NavigationLink(value: equativURL) {
                    Image("equativ")
                        .resizable()
                        .renderingMode(.template) // To color it white
                        .scaledToFit()
                        .frame(height: 10)
                        .padding(.trailing)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            
            // --- WebView ---
            // Here we use the .htmlString load type
            // We provide a baseURL, which is CRITICAL for ad tags
            // that need to fetch other resources (like images or scripts).
            WebView(loadType: .htmlString(
                htmlString,
                baseURL: URL(string: "https://eqt-gc.rendering.sharethrough.com")
            ))
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    NavigationStack {
        HTMLWebViewContainer(
            path: .constant(NavigationPath()),
            htmlString: "<h1>Hello World</h1>"
        )
    }
}
