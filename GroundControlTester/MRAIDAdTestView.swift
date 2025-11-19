//
//  MRAIDAdTestView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import SwiftUI

struct MRAIDAdTestView: View {
    @Binding var path: NavigationPath

    @State private var adHTML: String = """
    <!-- Paste your Equativ ad HTML here -->
    <html>
    <head>
        <style>
            body {
                margin: 0;
                padding: 20px;
                font-family: -apple-system, sans-serif;
                display: flex;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
                background: #f5f5f5;
            }
            .ad-container {
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div class="ad-container">
            <h2>📝 Paste Your Ad HTML Above</h2>
            <p>Then click "Render Ad" to test MRAID detection</p>

            <div style="margin-top: 20px; padding: 15px; background: #e3f2fd; border-radius: 4px;">
                <strong>Example: Testing MRAID</strong>
                <pre style="text-align: left; background: #fff; padding: 10px; border-radius: 4px; margin-top: 10px;">
    &lt;script&gt;
    if (typeof mraid !== 'undefined') {
    console.log('[SSP] MRAID detected!');
    // Your tracker would fire here
    mraid.addEventListener('ready', function() {
        console.log('[SSP] MRAID ready');
    });
    } else {
    console.log('[SSP] No MRAID');
    }
    &lt;/script&gt;

    &lt;div style="width: 300px; height: 250px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; display: flex; align-items: center; justify-content: center; border-radius: 8px;"&gt;
    &lt;h1&gt;Test Ad&lt;/h1&gt;
    &lt;/div&gt;
                </pre>
            </div>
        </div>
    </body>
    </html>
    """

    @FocusState private var isEditorFocused: Bool
    private let equativURL = URL(string: "https://equativ.com/")!

    // Example ad templates
    private let exampleMRAIDAd = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { margin: 0; padding: 20px; background: #f5f5f5; font-family: sans-serif; }
            .ad { width: 300px; height: 250px; background: linear-gradient(135deg, #667eea, #764ba2);
                  color: white; display: flex; flex-direction: column; align-items: center;
                  justify-content: center; border-radius: 8px; margin: 20px auto; }
            .status { background: white; padding: 15px; border-radius: 8px; margin: 10px; }
        </style>
    </head>
    <body>
        <div class="status">
            <h3>MRAID Detection Test</h3>
            <div id="status">Checking MRAID...</div>
        </div>

        <div class="ad">
            <h1>📱 Test Ad</h1>
            <p>300x250</p>
            <button onclick="testExpand()" style="margin-top: 10px; padding: 10px 20px; border: none; background: white; border-radius: 4px; cursor: pointer;">
                Expand Ad
            </button>
        </div>

        <script>
            console.log('[Ad Creative] Starting MRAID check...');

            // This is what your Equativ rendering code checks:
            if (typeof mraid !== 'undefined') {
                console.log('[SSP] ✅ MRAID detected!');
                console.log('[SSP] 🎯 MRAID tracker would FIRE here!');

                document.getElementById('status').innerHTML =
                    '<strong style="color: green;">✅ MRAID DETECTED</strong><br>' +
                    '<small>Your SSP tracker would fire!</small>';

                mraid.addEventListener('ready', function() {
                    console.log('[SSP] MRAID ready event fired');
                    console.log('[SSP] Version: ' + mraid.getVersion());
                    console.log('[SSP] State: ' + mraid.getState());
                });

                function testExpand() {
                    console.log('[Ad] User clicked expand');
                    mraid.expand();
                }
            } else {
                console.log('[SSP] ❌ No MRAID detected');
                console.log('[SSP] ⚠️ MRAID tracker would NOT fire');

                document.getElementById('status').innerHTML =
                    '<strong style="color: red;">❌ MRAID NOT DETECTED</strong><br>' +
                    '<small>Your SSP tracker would not fire</small>';
            }
        </script>
    </body>
    </html>
    """

    private let exampleBannerAd = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { margin: 0; padding: 0; display: flex; align-items: center; justify-content: center; min-height: 100vh; background: #f0f0f0; }
            .ad { width: 320px; height: 50px; background: #4CAF50; color: white; display: flex; align-items: center; justify-content: center; font-family: sans-serif; font-size: 18px; font-weight: bold; border-radius: 4px; cursor: pointer; }
        </style>
    </head>
    <body>
        <div class="ad" onclick="handleClick()">
            📱 Click Here - Banner Ad (320x50)
        </div>
        <script>
            console.log('[Ad] Banner loaded - checking MRAID...');
            if (typeof mraid !== 'undefined') {
                console.log('[SSP] ✅ MRAID available!');
                console.log('[SSP] 🎯 Tracker fires here!');
            } else {
                console.log('[SSP] ❌ No MRAID - tracker will not fire');
            }

            function handleClick() {
                console.log('[Ad] Ad clicked');
                if (typeof mraid !== 'undefined') {
                    mraid.open('https://equativ.com');
                } else {
                    window.open('https://equativ.com', '_blank');
                }
            }
        </script>
    </body>
    </html>
    """

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

                Text("Paste Ad HTML")
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

            // Content
            VStack(spacing: 0) {
                // Text Editor for pasting HTML
                TextEditor(text: $adHTML)
                    .focused($isEditorFocused)
                    .font(.body.monospaced())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(8)
                    .border(Color(UIColor.separator), width: 1)
                    .padding()

                // Instructions and Example buttons
                VStack(alignment: .leading, spacing: 12) {
                    // Paste tip for simulator
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.orange)
                            Text("Simulator Paste Tip:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text("Click in text area → Edit menu → Paste (or ⌘V)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 24)
                    }

                    Divider()

                    // Load example buttons
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                            Text("Or Load Example Ad:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                adHTML = exampleMRAIDAd
                            }) {
                                Label("MRAID Test (300x250)", systemImage: "rectangle.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }

                            Button(action: {
                                adHTML = exampleBannerAd
                            }) {
                                Label("Banner (320x50)", systemImage: "rectangle.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("MRAID is injected automatically")
                            .font(.caption)
                    }

                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.orange)
                        Text("Check Xcode console for tracker logs")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Render button
                NavigationLink(value: AdHTMLPayload(htmlString: adHTML)) {
                    Text("Render Ad & Test MRAID")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditorFocused ? "Done" : "Edit") {
                        isEditorFocused.toggle()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        MRAIDAdTestView(path: .constant(NavigationPath()))
    }
}
