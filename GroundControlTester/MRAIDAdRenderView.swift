//
//  MRAIDAdRenderView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import SwiftUI

struct MRAIDAdRenderView: View {
    @Binding var path: NavigationPath
    let adHTML: String

    private let equativURL = URL(string: "https://equativ.com/")!

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Button(action: {
                    path.removeLast()
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }
                .padding(.leading)

                Spacer()

                Text("Ad Preview (MRAID Enabled)")
                    .font(.headline)

                Spacer()

                NavigationLink(value: equativURL) {
                    Image("equativ")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(height: 10)
                        .padding(.trailing)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)

            // Info banner
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("✅ MRAID 3.0 is injected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.orange)
                    Text("Check Xcode console for MRAID tracker logs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                HStack {
                    Image(systemName: "terminal")
                        .foregroundColor(.blue)
                    Text("Look for: [SSP] MRAID available - firing tracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .bottom
            )

            // Ad rendering with MRAID enabled
            // Using Equativ/Sharethrough rendering domain as baseURL
            // ID modifier keeps WebView stable and prevents Web Inspector disconnection
            WebView(loadType: .htmlString(
                adHTML,
                baseURL: URL(string: "https://eqt-gc.rendering.sharethrough.com")
            ), injectMRAID: true)
            .id("mraid-webview-stable") // Stable ID prevents recreation
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        MRAIDAdRenderView(
            path: .constant(NavigationPath()),
            adHTML: "<html><body><h1>Test Ad</h1></body></html>"
        )
    }
}
