//
//  DV360ConfigView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import SwiftUI

struct DV360Config: Hashable {
    let adUnitPath: String
    let sizes: [[Int]]
}

struct DV360ConfigView: View {
    @Binding var path: NavigationPath

    @State private var adUnitPath: String = "/21775744923/external/single_ad_samples"
    @State private var width: String = "300"
    @State private var height: String = "250"

    // Ad unit examples for testing
    private let exampleAdUnits = [
        ("Google Test Unit", "/21775744923/external/single_ad_samples"),
        ("Invalid Example (Test Timeout)", "/99999999/invalid-test-unit"),
        ("Another Invalid (Test Timeout)", "/00000000/fake-ad-unit")
    ]

    var body: some View {
        Form {
            Section(header: Text("Ad Unit Configuration")) {
                Text("Enter Your DV360 Ad Unit")
                    .font(.headline)

                TextField("Ad Unit Path", text: $adUnitPath)
                    .font(.body.monospaced())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Format: /NETWORK-ID/AD-UNIT-NAME")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("⚠️ Only use real ad units from Google Ad Manager. Invalid ad units will timeout.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Section(header: Text("Ad Size")) {
                HStack {
                    TextField("Width", text: $width)
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                    Text("×")
                    TextField("Height", text: $height)
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                    Text("px")
                        .foregroundColor(.gray)
                }

                Text("Common sizes: 300×250, 320×50, 728×90, 300×600")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section(header: Text("Quick Examples")) {
                ForEach(exampleAdUnits, id: \.0) { example in
                    Button(action: {
                        adUnitPath = example.1
                    }) {
                        HStack {
                            Text(example.0)
                            Spacer()
                            Text(example.1)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Section {
                NavigationLink(value: createConfig()) {
                    HStack {
                        Spacer()
                        Text("Load Ad")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(adUnitPath.isEmpty || width.isEmpty || height.isEmpty)
            }

            Section(header: Text("Important Information")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Google's test ad unit works but returns no ads in iOS WebView")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("This is normal behavior. Real ad units from your DV360 campaigns should work.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Text("To Get Real DV360 Ads:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    InfoRow(icon: "1.circle.fill", text: "Create a DV360 account and campaign")
                    InfoRow(icon: "2.circle.fill", text: "Set up Google Ad Manager ad units")
                    InfoRow(icon: "3.circle.fill", text: "Get your ad unit path from Ad Manager")
                    InfoRow(icon: "4.circle.fill", text: "Enter it above and load the ad")

                    Divider()

                    Text("⚠️ Don't have a DV360 account? The SDK integration is working correctly. You just need real ad units to serve actual ads.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("DV360 Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createConfig() -> DV360Config {
        let w = Int(width) ?? 300
        let h = Int(height) ?? 250
        return DV360Config(
            adUnitPath: adUnitPath,
            sizes: [[w, h]]
        )
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    NavigationStack {
        DV360ConfigView(path: .constant(NavigationPath()))
    }
}
