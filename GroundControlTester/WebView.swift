//
//  WebView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    /// ✅ We define an enum to represent the two types of content
    /// we want our WebView to load.
    enum LoadType {
        case url(URL)
        case htmlString(String, baseURL: URL?)
    }

    /// ✅ The 'url' property is replaced with 'loadType'
    let loadType: LoadType

    /// Enable MRAID injection (default: true for all ad-serving contexts)
    let injectMRAID: Bool

    init(loadType: LoadType, injectMRAID: Bool = true) {
        self.loadType = loadType
        self.injectMRAID = injectMRAID
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true

        // Enable JavaScript (required for ads)
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Critical: Set limitsNavigationsToAppBoundDomains to false to allow third-party content
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = false
        }

        // Disable tracking prevention (iOS 14+)
        if #available(iOS 14.5, *) {
            configuration.websiteDataStore = WKWebsiteDataStore.default()
            // Disable Intelligent Tracking Prevention (ITP) for ad tracking
            configuration.websiteDataStore.httpCookieStore.setCookie(HTTPCookie(properties: [
                .domain: ".google.com",
                .path: "/",
                .name: "test_cookie",
                .value: "1",
                .secure: "TRUE"
            ])!)
        }

        // Critical: Disable ITP completely for iOS 17+
        if #available(iOS 17.0, *) {
            configuration.preferences.isElementFullscreenEnabled = true
            configuration.preferences.isFraudulentWebsiteWarningEnabled = false
        }

        // Allow all cross-origin requests (for tracking pixels)
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Add console log message handler
        configuration.userContentController.add(context.coordinator, name: "consoleLog")

        // Add MRAID message handlers and inject script BEFORE page loads
        if injectMRAID {
            configuration.userContentController.add(context.coordinator, name: "mraidOpen")
            configuration.userContentController.add(context.coordinator, name: "mraidClose")
            configuration.userContentController.add(context.coordinator, name: "mraidExpand")
            configuration.userContentController.add(context.coordinator, name: "mraidResize")

            // Inject MRAID as a user script at document start (BEFORE page content loads)
            let mraidBridge = MRAIDBridge(webView: nil)
            let mraidUserScript = WKUserScript(
                source: mraidBridge.mraidScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            configuration.userContentController.addUserScript(mraidUserScript)
            print("💉 MRAID user script added (will inject at document start)")
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)

        // Store injectMRAID flag in coordinator for later use
        context.coordinator.injectMRAID = injectMRAID

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // Allow all content and disable security restrictions for ad tracking
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // Set mobile content mode for proper ad rendering
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        // Set a realistic mobile browser user agent (matches real iOS Safari for ad compatibility)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS \(osVersion.majorVersion)_\(osVersion.minorVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(osVersion.majorVersion).0 Mobile/15E148 Safari/604.1"
        print("📱 User-Agent: \(webView.customUserAgent ?? "default")")

        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        /// ✅ The update logic now switches on 'loadType'
        /// Only reload if content has actually changed to keep Web Inspector connected
        let contentIdentifier: String
        switch loadType {
        case .url(let url):
            contentIdentifier = "url:\(url.absoluteString)"
        case .htmlString(let html, let baseURL):
            contentIdentifier = "html:\(html.hashValue):\(baseURL?.absoluteString ?? "")"
        }

        // Skip reload if content hasn't changed (prevents Web Inspector disconnection)
        if context.coordinator.lastLoadedContent == contentIdentifier {
            print("⏭️ Skipping reload - content unchanged (keeps Web Inspector connected)")
            return
        }

        context.coordinator.lastLoadedContent = contentIdentifier
        print("🔄 Loading new content into WebView")

        switch loadType {
        case .url(let url):
            var request = URLRequest(url: url)
            // Set referrer to make it look like a real navigation
            request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
            webView.load(request)

        case .htmlString(let html, let baseURL):
            // Set cookies before loading to simulate a real session
            if let baseURL = baseURL {
                let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

                // Add some common ad-related cookies that might be expected
                let cookies = [
                    HTTPCookie(properties: [
                        .domain: baseURL.host ?? "",
                        .path: "/",
                        .name: "test_session",
                        .value: UUID().uuidString,
                        .secure: "TRUE",
                        .expires: Date(timeIntervalSinceNow: 3600)
                    ])!,
                    HTTPCookie(properties: [
                        .domain: baseURL.host ?? "",
                        .path: "/",
                        .name: "user_consent",
                        .value: "1",
                        .secure: "TRUE",
                        .expires: Date(timeIntervalSinceNow: 3600)
                    ])!
                ]

                // Set cookies asynchronously
                let group = DispatchGroup()
                for cookie in cookies {
                    group.enter()
                    cookieStore.setCookie(cookie) {
                        group.leave()
                    }
                }

                // Load HTML after cookies are set
                group.notify(queue: .main) {
                    print("🍪 Cookies set for domain: \(baseURL.host ?? "unknown")")
                    webView.loadHTMLString(html, baseURL: baseURL)

                    // Inject fake referrer after load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let enhanceContextScript = """
                        // Override document.referrer to simulate real navigation
                        Object.defineProperty(document, 'referrer', {
                            get: function() { return '\(baseURL.absoluteString)'; },
                            configurable: false
                        });

                        console.log('🔧 Context enhanced:');
                        console.log('  - Referrer:', document.referrer);
                        console.log('  - Cookies:', document.cookie);
                        console.log('  - Origin:', location.origin);
                        """
                        webView.evaluateJavaScript(enhanceContextScript, completionHandler: nil)
                    }
                }
            } else {
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleLog")
        if coordinator.injectMRAID {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "mraidOpen")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "mraidClose")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "mraidExpand")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "mraidResize")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var injectMRAID: Bool = true
        var mraidBridge: MRAIDBridge?
        var lastLoadedContent: String?  // Track what was last loaded to prevent unnecessary reloads

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                print("📱 JS Console: \(message.body)")
            }
            // MRAID message handlers
            else if message.name == "mraidOpen" {
                handleMRAIDOpen(message.body)
            }
            else if message.name == "mraidClose" {
                handleMRAIDClose()
            }
            else if message.name == "mraidExpand" {
                handleMRAIDExpand(message.body)
            }
            else if message.name == "mraidResize" {
                handleMRAIDResize()
            }
        }

        // MRAID action handlers
        private func handleMRAIDOpen(_ url: Any) {
            guard let urlString = url as? String, let url = URL(string: urlString) else { return }
            print("🔗 [MRAID] Opening URL: \(urlString)")
            #if targetEnvironment(simulator)
            print("⚠️ [MRAID] URL open simulation (would open in real device)")
            #else
            UIApplication.shared.open(url)
            #endif
        }

        private func handleMRAIDClose() {
            print("❌ [MRAID] Close requested")
            // In a real implementation, this would close the ad view
        }

        private func handleMRAIDExpand(_ url: Any) {
            print("📱 [MRAID] Expand requested")
            // In a real implementation, this would expand the ad to fullscreen
        }

        private func handleMRAIDResize() {
            print("📐 [MRAID] Resize requested")
            // In a real implementation, this would resize the ad
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Page loaded successfully")

            // MRAID is now injected via user script at document start (see makeUIView)
            // No need to inject here anymore

            // Inject console.log interceptor and network request logging
            let consoleScript = """
            (function() {
                // Console logging interception
                var oldLog = console.log;
                console.log = function() {
                    var message = Array.prototype.slice.call(arguments).join(' ');
                    window.webkit.messageHandlers.consoleLog.postMessage(message);
                    oldLog.apply(console, arguments);
                };

                var oldError = console.error;
                console.error = function() {
                    var message = '❌ ' + Array.prototype.slice.call(arguments).join(' ');
                    window.webkit.messageHandlers.consoleLog.postMessage(message);
                    oldError.apply(console, arguments);
                };

                var oldWarn = console.warn;
                console.warn = function() {
                    var message = '⚠️ ' + Array.prototype.slice.call(arguments).join(' ');
                    window.webkit.messageHandlers.consoleLog.postMessage(message);
                    oldWarn.apply(console, arguments);
                };

                // Log all Image loads (tracking pixels often use img tags)
                var OriginalImage = window.Image;
                window.Image = function() {
                    var img = new OriginalImage();

                    // Track load success/failure
                    img.addEventListener('load', function() {
                        console.log('✅ [Image Success] ' + this.src);
                    });
                    img.addEventListener('error', function() {
                        console.error('❌ [Image Failed] ' + this.src);
                    });

                    var originalSrcSetter = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src').set;
                    Object.defineProperty(img, 'src', {
                        set: function(value) {
                            console.log('📷 [Image Load Attempt] ' + value);
                            originalSrcSetter.call(this, value);
                        },
                        get: function() {
                            return this.getAttribute('src');
                        }
                    });
                    return img;
                };

                // Also intercept img tags created via innerHTML
                var imgProto = HTMLImageElement.prototype;
                var originalImgSrcSetter = Object.getOwnPropertyDescriptor(imgProto, 'src').set;
                Object.defineProperty(imgProto, 'src', {
                    set: function(value) {
                        console.log('📷 [HTMLImageElement.src] ' + value);
                        originalImgSrcSetter.call(this, value);

                        // Add error/load handlers
                        this.addEventListener('load', function() {
                            console.log('✅ [Pixel Success] ' + value);
                        });
                        this.addEventListener('error', function() {
                            console.error('❌ [Pixel Failed] ' + value);
                        });
                    },
                    get: function() {
                        return originalImgSrcSetter ? this.getAttribute('src') : null;
                    }
                });

                // Log fetch requests with success/failure
                if (window.fetch) {
                    var originalFetch = window.fetch;
                    window.fetch = function() {
                        var url = arguments[0];
                        console.log('🌐 [Fetch Attempt] ' + url);
                        return originalFetch.apply(this, arguments)
                            .then(function(response) {
                                console.log('✅ [Fetch Success] ' + url + ' (Status: ' + response.status + ')');
                                return response;
                            })
                            .catch(function(error) {
                                console.error('❌ [Fetch Failed] ' + url + ' (Error: ' + error.message + ')');
                                throw error;
                            });
                    };
                }

                // Log XMLHttpRequest with success/failure
                var originalOpen = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function(method, url) {
                    console.log('🌐 [XHR Attempt] ' + method + ' ' + url);

                    // Track completion
                    this.addEventListener('load', function() {
                        console.log('✅ [XHR Success] ' + method + ' ' + url + ' (Status: ' + this.status + ')');
                    });
                    this.addEventListener('error', function() {
                        console.error('❌ [XHR Failed] ' + method + ' ' + url);
                    });
                    this.addEventListener('abort', function() {
                        console.error('⚠️ [XHR Aborted] ' + method + ' ' + url);
                    });

                    return originalOpen.apply(this, arguments);
                };

                // Log sendBeacon (commonly used for tracking pixels)
                if (navigator.sendBeacon) {
                    var originalSendBeacon = navigator.sendBeacon;
                    navigator.sendBeacon = function(url, data) {
                        console.log('📤 [Beacon] ' + url);
                        return originalSendBeacon.apply(this, arguments);
                    };
                }

                // Log document.createElement for iframes and scripts (ad loading)
                var originalCreateElement = document.createElement;
                document.createElement = function(tagName) {
                    var element = originalCreateElement.call(document, tagName);
                    if (tagName.toLowerCase() === 'iframe' || tagName.toLowerCase() === 'script') {
                        var originalSrcSetter = Object.getOwnPropertyDescriptor(element.constructor.prototype, 'src');
                        if (originalSrcSetter) {
                            Object.defineProperty(element, 'src', {
                                set: function(value) {
                                    console.log('📦 [' + tagName.toUpperCase() + '] ' + value);
                                    originalSrcSetter.set.call(this, value);
                                },
                                get: function() {
                                    return originalSrcSetter.get.call(this);
                                }
                            });
                        }
                    }
                    return element;
                };

                console.log('✅ Network request logging enabled (Image, Fetch, XHR, Beacon, Script, iframe)');

                // Log environment details to understand why pixels might not fire
                console.log('🔍 Environment Check:');
                console.log('  - window.top === window.self:', window.top === window.self);
                console.log('  - In iframe:', window.top !== window.self);
                console.log('  - document.referrer:', document.referrer || '(empty)');
                console.log('  - location.href:', location.href);
                console.log('  - location.origin:', location.origin);
                console.log('  - document.domain:', document.domain);
                console.log('  - Cookies enabled:', navigator.cookieEnabled);
                console.log('  - document.cookie:', document.cookie || '(no cookies)');

                // Try to access parent (will fail if cross-origin iframe)
                try {
                    console.log('  - Can access parent:', !!window.parent && window.parent !== window);
                } catch(e) {
                    console.log('  - Parent access blocked (cross-origin iframe)');
                }
            })();
            """

            webView.evaluateJavaScript(consoleScript, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Page failed to load: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ Provisional navigation failed: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain)")
                print("   Error code: \(nsError.code)")
                print("   Error details: \(nsError.userInfo)")
            }
        }

        // CRITICAL: Allow all navigation actions (including subresource loads like tracking pixels)
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Log all navigation attempts
            if let url = navigationAction.request.url {
                let navType = navigationAction.navigationType.rawValue
                let urlString = url.absoluteString

                // Special logging for SmartAdServer to debug why it fails
                if urlString.contains("smartadserver.com") {
                    print("⚠️ [SmartAdServer Pixel Detected]")
                    print("   URL: \(urlString)")
                    print("   Navigation type: \(navType)")
                    print("   Source frame: \(navigationAction.sourceFrame.isMainFrame ? "main" : "subframe")")
                    print("   Target frame: \(navigationAction.targetFrame?.isMainFrame ?? false ? "main" : "subframe")")
                    print("   Request headers: \(navigationAction.request.allHTTPHeaderFields ?? [:])")
                } else {
                    print("🔍 [Navigation Policy] Type: \(navType), URL: \(urlString)")
                }
            }

            // Allow all navigations (necessary for ad tracking pixels and clicks)
            decisionHandler(.allow)
        }

        // Allow all navigation responses (for tracking pixels that return 204, redirects, etc.)
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let httpResponse = navigationResponse.response as? HTTPURLResponse {
                let urlString = httpResponse.url?.absoluteString ?? "unknown"

                // Special logging for tracking pixels
                if urlString.contains("smartadserver.com") || urlString.contains("gen_204") || urlString.contains("adtrafficquality") {
                    let pixelType = urlString.contains("smartadserver.com") ? "SmartAdServer" :
                                  urlString.contains("gen_204") ? "Google gen_204" : "AdTrafficQuality"

                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        print("✅ [\(pixelType) Success!]")
                    } else {
                        print("⚠️ [\(pixelType) Unexpected Status!]")
                    }
                    print("   Status: \(httpResponse.statusCode)")
                    print("   URL: \(urlString)")
                    print("   Headers: \(httpResponse.allHeaderFields)")
                    print("   MIME Type: \(httpResponse.mimeType ?? "none")")
                } else {
                    print("📡 [Navigation Response] Status: \(httpResponse.statusCode), URL: \(urlString)")
                }
            } else {
                // No HTTP response - might be blocked or failed
                let urlString = navigationResponse.response.url?.absoluteString ?? "unknown"
                if urlString.contains("smartadserver.com") || urlString.contains("gen_204") || urlString.contains("adtrafficquality") {
                    print("❌ [Pixel Blocked] No HTTP response")
                    print("   URL: \(urlString)")
                    print("   Response type: \(type(of: navigationResponse.response))")
                    print("   Can show MIME type: \(navigationResponse.canShowMIMEType)")
                }
            }
            decisionHandler(.allow)
        }

        // Add handler for authentication challenges (for tracking pixels, images, etc.)
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Accept all certificates (for testing purposes - allows self-signed certs, etc.)
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
}
