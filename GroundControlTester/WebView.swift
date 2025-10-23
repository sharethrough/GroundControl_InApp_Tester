//
//  WebView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // ✅ Allow inline video playback (previews, thumbnails, etc.)
        configuration.allowsInlineMediaPlayback = true
        
        // ✅ Allow autoplay without user gesture
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        
        // ✅ Optional: enable AirPlay / PIP support
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        if #available(iOS 16.4, *) {
            webView.isInspectable = true // This enables the Safari Web Inspector
        }
        
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Page loaded successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Page failed to load: \(error.localizedDescription)")
        }
    }
}
