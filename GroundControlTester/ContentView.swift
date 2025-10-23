//
//  ContentView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI

struct PresetWebsite: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
}

struct ContentView: View {
    @Binding var path: NavigationPath

    private let presetSites: [PresetWebsite] = [
        .init(name: "Groundcontrol Sandbox EQT", url: URL(string: "https://eqt-gc-test.rendering.sharethrough.com/")!),
        .init(name: "Groundcontrol Sandbox STR", url: URL(string: "https://groundcontrol.rendering.sharethrough.com/sandbox.html")!),
        .init(name: "Test A Tag", url: URL(string: "https://test-a-tag.com/")!)
    ]
    
    @State private var customURLString: String = "https://equativ.com/"
    private let equativURL = URL(string: "https://equativ.com/")!

    var body: some View {
        List {
            Section(header: Text("Preset Websites")) {
                ForEach(presetSites) { site in
                    NavigationLink(site.name, value: site)
                }
            }
            
            Section(header: Text("Custom Website")) {
                TextField("https://equativ.com/", text: $customURLString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.go)
                
                NavigationLink(value: formattedURL(from: customURLString)) {
                    Text("Load Custom URL")
                }
                .disabled(formattedURL(from: customURLString) == nil)
            }
        }
        .toolbar {
                    ToolbarItem(placement: .principal) { // 'principal' centers it
                        VStack(spacing: 4) {
                            Spacer()
                            NavigationLink(value: equativURL) {
                                Image("equativ")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 20)
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                                Spacer()
                                Text("GroundControl IN-APP Tester")
                                    .font(.headline)
                        }
                    }
                }
        
        //    Receives a 'PresetWebsite' object
        .navigationDestination(for: PresetWebsite.self) { site in
            // Pass the site.name as the displayName
            WebViewContainer(path: $path, url: site.url, displayName: site.name)
        }
        
        //    Receives a 'URL' object
        .navigationDestination(for: URL.self) { url in
            // For custom URLs, we display the URL string as the name
            let name = (url == equativURL) ? "Equativ" : url.absoluteString
            WebViewContainer(path: $path, url: url, displayName: name)
        }
    }
    
    private func formattedURL(from string: String) -> URL? {
        var finalString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalString.isEmpty { return nil }
        
        if !finalString.lowercased().hasPrefix("http://") && !finalString.lowercased().hasPrefix("https://") {
            finalString = "https://" + finalString
        }
        
        return URL(string: finalString)
    }
}

#Preview {
    NavigationStack {
        ContentView(path: .constant(NavigationPath()))
    }
}
