//
//  MRAIDTestView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import SwiftUI

struct AdHTMLPayload: Hashable {
    let htmlString: String
}

struct PasteAdTarget: Hashable {}

struct MRAIDTestView: View {
    @Binding var path: NavigationPath

    private let equativURL = URL(string: "https://equativ.com/")!

    // MRAID detection test HTML
    private let mraidTestHTML = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>MRAID Detection Test</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                border-radius: 10px;
                margin-bottom: 20px;
                text-align: center;
            }
            h1 {
                margin: 0;
                font-size: 24px;
                font-weight: 600;
            }
            .status-card {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .status-item {
                padding: 12px;
                margin: 8px 0;
                border-radius: 6px;
                display: flex;
                align-items: center;
                gap: 10px;
            }
            .status-success {
                background: #e8f5e9;
                border-left: 4px solid #4caf50;
            }
            .status-error {
                background: #ffebee;
                border-left: 4px solid #f44336;
            }
            .status-info {
                background: #e3f2fd;
                border-left: 4px solid #2196f3;
            }
            .icon {
                font-size: 24px;
            }
            .test-section {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .test-button {
                background: #2196f3;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                font-size: 16px;
                cursor: pointer;
                margin: 5px;
            }
            .test-button:active {
                background: #1976d2;
            }
            .code-block {
                background: #f5f5f5;
                padding: 12px;
                border-radius: 4px;
                font-family: monospace;
                font-size: 12px;
                overflow-x: auto;
                margin: 10px 0;
            }
            .info-box {
                background: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 15px 0;
                border-radius: 4px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📱 MRAID Detection Test</h1>
                <p style="margin: 10px 0 0 0; opacity: 0.9;">Test your SSP's MRAID tracking</p>
            </div>

            <div class="status-card">
                <h3>MRAID Availability</h3>
                <div id="mraid-status"></div>
            </div>

            <div class="test-section">
                <h3>MRAID API Tests</h3>
                <p>Click buttons to test MRAID methods (check Xcode console for native bridge logs):</p>
                <button class="test-button" onclick="testGetVersion()">getVersion()</button>
                <button class="test-button" onclick="testGetState()">getState()</button>
                <button class="test-button" onclick="testIsViewable()">isViewable()</button>
                <button class="test-button" onclick="testSupports()">supports()</button>
                <button class="test-button" onclick="testOpen()">open()</button>
                <button class="test-button" onclick="testExpand()">expand()</button>
                <div id="test-output" class="code-block" style="margin-top: 15px; min-height: 100px;">
                    Click buttons to test MRAID API...
                </div>
            </div>

            <div class="test-section">
                <h3>SSP Rendering Technique Simulation</h3>
                <p>This simulates what your Equativ rendering code would check:</p>
                <div class="code-block" id="ssp-check"></div>
            </div>

            <div class="info-box">
                <strong>ℹ️ For Your SSP Team:</strong><br>
                This page demonstrates MRAID detection. Your rendering technique should fire the MRAID tracker when:
                <ul style="margin: 10px 0;">
                    <li><code>typeof mraid !== 'undefined'</code></li>
                    <li>MRAID ready event fires</li>
                    <li>Publisher has properly injected mraid.js</li>
                </ul>
                In this test app, MRAID is injected by default (simulating proper publisher setup).
                <br><br>
                <strong>📝 Want to test your actual ad HTML?</strong><br>
                Click the document icon (📄) in the top-right corner to paste and test your Equativ ad creative.
            </div>
        </div>

        <script>
            let logOutput = '';

            function log(message) {
                console.log(message);
                logOutput += message + '\\n';
                document.getElementById('test-output').textContent = logOutput;
            }

            function clearLog() {
                logOutput = '';
                document.getElementById('test-output').textContent = 'Click buttons to test MRAID API...';
            }

            // Check MRAID availability
            function checkMRAID() {
                const statusDiv = document.getElementById('mraid-status');

                if (typeof mraid === 'undefined') {
                    statusDiv.innerHTML = `
                        <div class="status-item status-error">
                            <span class="icon">❌</span>
                            <div>
                                <strong>MRAID NOT DETECTED</strong><br>
                                <small>Publisher did not inject mraid.js into WebView</small>
                            </div>
                        </div>
                    `;
                    updateSSPCheck(false);
                    return;
                }

                // MRAID is available, wait for ready event
                if (mraid.getState() === 'loading') {
                    statusDiv.innerHTML = `
                        <div class="status-item status-info">
                            <span class="icon">⏳</span>
                            <div>
                                <strong>MRAID Loading...</strong><br>
                                <small>Waiting for ready event</small>
                            </div>
                        </div>
                    `;

                    mraid.addEventListener('ready', function() {
                        onMRAIDReady();
                    });
                } else {
                    onMRAIDReady();
                }
            }

            function onMRAIDReady() {
                const statusDiv = document.getElementById('mraid-status');
                const version = mraid.getVersion();
                const state = mraid.getState();
                statusDiv.innerHTML = `
                    <div class="status-item status-success">
                        <span class="icon">✅</span>
                        <div>
                            <strong>MRAID DETECTED & READY!</strong><br>
                            <small>Version: ` + version + ` | State: ` + state + `</small>
                        </div>
                    </div>
                    <div class="status-item status-success">
                        <span class="icon">🎯</span>
                        <div>
                            <strong>SSP MRAID Tracker: WOULD FIRE ✅</strong><br>
                            <small>Your rendering technique would detect MRAID and fire the tracker</small>
                        </div>
                    </div>
                `;
                updateSSPCheck(true);
            }

            function updateSSPCheck(mraidAvailable) {
                const sspCheckDiv = document.getElementById('ssp-check');
                if (mraidAvailable) {
                    sspCheckDiv.textContent = `
    // Your Equativ rendering code:
    if (typeof mraid !== 'undefined') {
    // ✅ MRAID detected!
    console.log('[SSP] MRAID available - firing tracker');
    fireEquativMRAIDTracker(); // This would fire in production

    mraid.addEventListener('ready', function() {
        console.log('[SSP] MRAID ready');
        // Your MRAID-specific tracking here
    });
    } else {
    // ❌ No MRAID
    console.log('[SSP] No MRAID detected');
    }

    Result: ✅ MRAID tracker WOULD FIRE
                    `;
                } else {
                    sspCheckDiv.textContent = `
    // Your Equativ rendering code:
    if (typeof mraid !== 'undefined') {
        fireEquativMRAIDTracker();
    } else {
        // ❌ This path executes when no MRAID
        console.log('[SSP] No MRAID detected');
    }

    Result: ❌ MRAID tracker WOULD NOT FIRE
                    `;
                }
            }

            // Test functions
            function testGetVersion() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                log('MRAID Version: ' + mraid.getVersion());
            }

            function testGetState() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                log('MRAID State: ' + mraid.getState());
            }

            function testIsViewable() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                log('Is Viewable: ' + mraid.isViewable());
                log('Placement Type: ' + mraid.getPlacementType());
            }

            function testSupports() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                const features = ['sms', 'tel', 'calendar', 'storePicture', 'inlineVideo', 'vpaid'];
                features.forEach(feature => {
                    log('supports("' + feature + '"): ' + mraid.supports(feature));
                });
            }

            function testOpen() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                log('Calling mraid.open("https://equativ.com")...');
                log('Check Xcode console for native bridge logs');
                mraid.open('https://equativ.com');
            }

            function testExpand() {
                clearLog();
                if (typeof mraid === 'undefined') {
                    log('❌ MRAID not available');
                    return;
                }
                log('Calling mraid.expand()...');
                log('Check Xcode console for native bridge logs');
                mraid.expand();
            }

            // Run check on load
            checkMRAID();
        </script>
    </body>
    </html>
    """

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                // Back Button
                Button(action: {
                    path.removeLast()
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }
                .padding(.leading)

                Spacer()

                // Title
                Text("MRAID Test")
                    .font(.headline)

                Spacer()

                // Test Your Ad button
                Button(action: {
                    path.append(PasteAdTarget())
                }) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                }
                .padding(.trailing, 8)

                // Equativ Icon
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

            // WebView with MRAID enabled (default)
            // Using Equativ/Sharethrough rendering domain as baseURL
            WebView(loadType: .htmlString(
                mraidTestHTML,
                baseURL: URL(string: "https://eqt-gc.rendering.sharethrough.com")
            ), injectMRAID: true)
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        MRAIDTestView(path: .constant(NavigationPath()))
    }
}
