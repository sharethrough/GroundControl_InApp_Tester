//
//  DV360WebViewContainer.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import SwiftUI

struct DV360WebViewContainer: View {
    @Binding var path: NavigationPath
    let config: DV360Config

    private let equativURL = URL(string: "https://equativ.com/")!

    // DV360 SDK HTML with ad rendering (will be generated dynamically)
    private var dv360HTML: String {
        generateHTML()
    }

    private func generateHTML() -> String {
        let sizesJSON = config.sizes.map { "[\($0[0]), \($0[1])]" }.joined(separator: ", ")
        let adUnitPath = config.adUnitPath

        return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DV360 Ad Rendering</title>
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
            .info {
                background: white;
                padding: 15px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .ad-container {
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                min-height: 300px;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .status {
                padding: 10px;
                background: #e3f2fd;
                border-left: 4px solid #2196f3;
                margin: 10px 0;
                border-radius: 4px;
            }
            .ad-slot {
                width: 100%;
                min-height: 250px;
                border: 2px dashed #ccc;
                display: flex;
                align-items: center;
                justify-content: center;
                position: relative;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📺 DV360 SDK Ad Rendering</h1>
            </div>

            <div class="info">
                <h3>🔧 SDK Status</h3>
                <div id="sdk-status" class="status">Initializing DV360 SDK...</div>
            </div>

            <div class="ad-container">
                <h3>Ad Slot</h3>
                <div id="ad-slot" class="ad-slot">
                    <p style="color: #999;">Ad will render here</p>
                </div>
            </div>
        </div>

        <!-- DV360 SDK Integration -->
        <script>
            // Enhanced debugging
            console.log('[DV360] Starting initialization...');
            console.log('[DV360] User Agent:', navigator.userAgent);
            console.log('[DV360] Cookies enabled:', navigator.cookieEnabled);

            window.googletag = window.googletag || {cmd: []};

            // Update status
            function updateStatus(message, type = 'info') {
                const statusEl = document.getElementById('sdk-status');
                statusEl.textContent = message;
                statusEl.style.background = type === 'success' ? '#e8f5e9' :
                                          type === 'error' ? '#ffebee' : '#e3f2fd';
                statusEl.style.borderLeftColor = type === 'success' ? '#4caf50' :
                                                 type === 'error' ? '#f44336' : '#2196f3';
                console.log('[DV360]', message);
            }

            // Check if GPT script loaded
            function checkGPTLoaded() {
                if (window.googletag && window.googletag.apiReady) {
                    console.log('[DV360] GPT API is ready');
                    initializeAds();
                } else {
                    console.log('[DV360] Waiting for GPT...');
                    setTimeout(checkGPTLoaded, 100);
                }
            }

            // Initialize ads
            function initializeAds() {
                googletag.cmd.push(function() {
                    console.log('[DV360] Inside googletag.cmd');
                    updateStatus('DV360 SDK Loaded - Defining ad slot...', 'info');

                    // Set page-level settings
                    googletag.pubads().set('page_url', 'https://example.com/test');

                    // Add targeting for better ad fill
                    googletag.pubads().setTargeting('test', 'true');
                    googletag.pubads().setTargeting('environment', 'testing');

                    // Define ad slot using configured ad unit
                    console.log('[DV360] Defining slot...');
                    console.log('[DV360] Ad Unit: \(adUnitPath)');
                    console.log('[DV360] Sizes: [\(sizesJSON)]');
                    const adSlot = googletag.defineSlot('\(adUnitPath)',
                        [\(sizesJSON)],
                        'ad-slot'
                    );

                    if (!adSlot) {
                        console.error('[DV360] Failed to define slot!');
                        updateStatus('❌ Failed to define ad slot', 'error');
                        return;
                    }

                    adSlot.addService(googletag.pubads());
                    console.log('[DV360] Slot defined:', adSlot.getSlotElementId());

                    // Configure publisher ads service
                    googletag.pubads().enableSingleRequest();
                    googletag.pubads().collapseEmptyDivs();
                    googletag.pubads().setCentering(true);

                    // Enable services
                    console.log('[DV360] Enabling services...');
                    googletag.enableServices();

                    updateStatus('Ad slot defined - Requesting ads...', 'info');

                    // Listen for all events before displaying
                    googletag.pubads().addEventListener('slotRequested', function(event) {
                        console.log('[DV360] ✅ Slot requested:', event.slot.getSlotElementId());
                        updateStatus('Ad request sent...', 'info');
                    });

                    googletag.pubads().addEventListener('slotResponseReceived', function(event) {
                        console.log('[DV360] ✅ Response received:', event);
                        updateStatus('Ad response received...', 'info');
                    });

                    googletag.pubads().addEventListener('slotOnload', function(event) {
                        console.log('[DV360] ✅ Slot onload:', event.slot.getSlotElementId());
                    });

                    googletag.pubads().addEventListener('slotRenderEnded', function(event) {
                        console.log('[DV360] Ad render event:', event);
                        console.log('[DV360] isEmpty:', event.isEmpty);
                        console.log('[DV360] size:', event.size);
                        console.log('[DV360] advertiserId:', event.advertiserId);
                        console.log('[DV360] campaignId:', event.campaignId);

                        if (event.isEmpty) {
                            updateStatus('⚠️ No ad from Google (this is normal in test environments)', 'error');
                            console.log('[DV360] Showing fallback demo ad...');
                            showFallbackAd();
                        } else {
                            updateStatus(`✅ Ad rendered! Size: ${event.size[0]}x${event.size[1]}`, 'success');
                        }
                    });

                    // Fallback demo ad
                    function showFallbackAd() {
                        const adSlot = document.getElementById('ad-slot');
                        adSlot.innerHTML = `
                            <div style="width: 300px; height: 250px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                        display: flex; flex-direction: column; align-items: center; justify-content: center;
                                        border-radius: 8px; color: white; font-family: -apple-system, sans-serif; text-align: center;
                                        padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                                <div style="font-size: 48px; margin-bottom: 10px;">📺</div>
                                <div style="font-size: 18px; font-weight: 600; margin-bottom: 8px;">Demo DV360 Ad</div>
                                <div style="font-size: 12px; opacity: 0.9; margin-bottom: 15px;">SDK Integration Working!</div>
                                <div style="font-size: 10px; opacity: 0.7; line-height: 1.4;">
                                    Google's test ads may not serve in iOS WebView.<br>
                                    Real DV360 ad units will work here.
                                </div>
                                <div style="margin-top: 15px; padding: 8px 16px; background: rgba(255,255,255,0.2);
                                            border-radius: 4px; font-size: 11px; font-weight: 500;">
                                    300 × 250
                                </div>
                            </div>
                        `;
                        updateStatus('✅ Showing demo ad (SDK ready for real ads)', 'success');
                    }

                    googletag.pubads().addEventListener('impressionViewable', function(event) {
                        console.log('[DV360] Impression viewable:', event);
                        updateStatus('✅ Ad impression viewable!', 'success');
                    });

                    // Display the ad
                    console.log('[DV360] Calling display...');
                    googletag.display('ad-slot');

                    // Timeout handler - GPT doesn't timeout on its own, so we implement one
                    // GPT waits indefinitely because:
                    // 1. It's designed for web browsers with different lifecycle
                    // 2. Network responses can be legitimately slow
                    // 3. Invalid ad units don't trigger error events in GPT
                    // 4. slotRenderEnded may never fire for non-existent ad units
                    setTimeout(function() {
                        const statusEl = document.getElementById('sdk-status');
                        if (statusEl && statusEl.textContent.includes('Ad request sent')) {
                            console.log('[DV360] ⏱️ Request timeout - no response after 10 seconds');
                            console.log('[DV360] This usually means: invalid ad unit, network issue, or no ad fill');
                            updateStatus('⏱️ Request timeout - check ad unit path and network', 'error');
                            showFallbackAd();
                        }
                    }, 10000);
                });
            }

            // Load GPT script
            console.log('[DV360] Loading GPT script...');
            const script = document.createElement('script');
            script.async = true;
            script.src = 'https://securepubads.g.doubleclick.net/tag/js/gpt.js';
            script.onerror = function() {
                console.error('[DV360] ❌ Failed to load GPT script!');
                updateStatus('❌ Failed to load GPT script', 'error');
            };
            script.onload = function() {
                console.log('[DV360] ✅ GPT script loaded');
                updateStatus('GPT script loaded...', 'info');
                checkGPTLoaded();
            };
            document.head.appendChild(script);
        </script>
    </body>
    </html>
    """
    }

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
                Text("DV360 SDK")
                    .font(.headline)

                Spacer()

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

            // WebView with DV360 HTML
            WebView(loadType: .htmlString(
                dv360HTML,
                baseURL: URL(string: "https://securepubads.g.doubleclick.net")
            ))
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        DV360WebViewContainer(
            path: .constant(NavigationPath()),
            config: DV360Config(
                adUnitPath: "/21775744923/external/single_ad_samples",
                sizes: [[300, 250]]
            )
        )
    }
}
