# How MRAID Works in This App Environment

## 1. **What is MRAID?**

MRAID (Mobile Rich Media Ad Interface Definitions) is a standardized JavaScript API that allows ads to communicate with the host app's webview. It acts as a bridge between:
- **Ad creative** (HTML/JS running in the webview)
- **Native app** (your iOS app)

## 2. **The Three Components in Your App**

### A. **MRAIDBridge.swift** (The SDK Implementation)

**Location:** `MRAIDBridge.swift:40-263`

This file contains the **JavaScript implementation** of the MRAID 3.0 API. It's not actually Swift code that runs - it's a JavaScript string that gets injected into the webview.

**Key parts:**
```javascript
window.mraid = {
    getVersion: function() { return '3.0'; },
    getState: function() { return this._state; },
    isViewable: function() { return this._isViewable; },
    open: function(url) { /* sends message to native Swift */ },
    expand: function() { /* sends message to native Swift */ },
    // ... more MRAID methods
}
```

**What it does:**
- Creates a global `window.mraid` object available to all JavaScript in the ad
- Implements all MRAID 3.0 methods (getVersion, getState, isViewable, supports, open, expand, etc.)
- Manages MRAID state machine (loading → default → expanded/resized)
- Fires MRAID events (ready, stateChange, viewableChange)

### B. **WebView.swift** (The Bridge/Injector)

**Location:** `WebView.swift:31-118`

This is where the **injection happens** and the **bridge is established**.

**Injection Process (WebView.swift:71-79):**
```swift
let mraidUserScript = WKUserScript(
    source: mraidBridge.mraidScript,  // The JavaScript from MRAIDBridge
    injectionTime: .atDocumentStart,  // CRITICAL: Before page loads
    forMainFrameOnly: true
)
configuration.userContentController.addUserScript(mraidUserScript)
```

**Why `.atDocumentStart` is critical:**
- Ad creative checks `if (typeof mraid !== 'undefined')` **immediately** when it loads
- If MRAID isn't there yet → ad thinks no MRAID → won't fire trackers
- By injecting at document start, `window.mraid` exists **before** any ad code runs

**Message Handlers (WebView.swift:66-69):**
```swift
configuration.userContentController.add(coordinator, name: "mraidOpen")
configuration.userContentController.add(coordinator, name: "mraidClose")
configuration.userContentController.add(coordinator, name: "mraidExpand")
configuration.userContentController.add(coordinator, name: "mraidResize")
```

These receive messages from JavaScript when the ad calls MRAID methods.

### C. **Coordinator** (The Message Handler)

**Location:** `WebView.swift:205-236`

Handles messages from JavaScript and performs native actions.

**Example flow (WebView.swift:213-221):**
```swift
private func handleMRAIDOpen(_ url: Any) {
    guard let urlString = url as? String, let url = URL(string: urlString) else { return }
    print("🔗 [MRAID] Opening URL: \(urlString)")
    UIApplication.shared.open(url)  // Opens in Safari/browser
}
```

## 3. **Complete MRAID Flow Example**

Let's trace what happens when an ad uses MRAID:

### Step 1: **App Starts**
```
User opens app → navigates to MRAID test page
```

### Step 2: **WebView Configuration** (makeUIView)
```swift
// Create WKWebView with MRAID script
let mraidUserScript = WKUserScript(
    source: mraidBridge.mraidScript,  // JavaScript MRAID implementation
    injectionTime: .atDocumentStart
)
// Add to webview BEFORE any content loads
```

### Step 3: **Ad HTML Loads** (updateUIView)
```swift
webView.loadHTMLString(adHTML, baseURL: URL(string: "https://equativ.com"))
```

### Step 4: **MRAID Injection Happens**
**Timeline:**
1. WebView starts loading HTML
2. **IMMEDIATELY**: MRAID JavaScript executes (because `.atDocumentStart`)
3. `window.mraid` object is created
4. MRAID state = `'loading'`
5. After 50ms delay, MRAID fires `'ready'` event and changes state to `'default'`

### Step 5: **Ad Creative Executes**
```javascript
// Ad's JavaScript code:
console.log('[Ad Creative] Starting MRAID check...');

if (typeof mraid !== 'undefined') {
    // ✅ MRAID detected!
    console.log('[SSP] MRAID tracker would FIRE here!');

    mraid.addEventListener('ready', function() {
        console.log('[SSP] MRAID ready');
        console.log('[SSP] Version: ' + mraid.getVersion());  // "3.0"
        console.log('[SSP] State: ' + mraid.getState());      // "default"
    });
}
```

### Step 6: **User Interaction** (e.g., clicks "Open URL" button)
```javascript
// In ad creative:
mraid.open('https://equativ.com');
```

**What happens:**
1. JavaScript in webview calls `mraid.open('https://equativ.com')`
2. MRAID implementation (MRAIDBridge.swift:146-153) executes:
```javascript
open: function(url) {
    console.log('[MRAID] open:', url);
    // Send message to Swift
    window.webkit.messageHandlers.mraidOpen.postMessage(url);
}
```
3. Message sent to native Swift code via `window.webkit.messageHandlers`
4. Coordinator receives message (WebView.swift:213-221)
5. Swift opens URL in Safari: `UIApplication.shared.open(url)`

## 4. **Why This Architecture?**

### **JavaScript → Native Communication**
- JavaScript can't directly access iOS APIs (security)
- `window.webkit.messageHandlers` is the **only** way for JS to talk to Swift
- Each MRAID action (open, expand, etc.) uses a message handler

### **Native → JavaScript Communication**
- Swift can inject JavaScript using `webView.evaluateJavaScript()`
- Example: Console logging (WebView.swift:354) injects script to intercept console.log

## 5. **MRAID State Management**

**States (MRAIDBridge.swift:22-28):**
```javascript
'loading'   → MRAID exists but not ready
'default'   → Ad in normal state (ready to use)
'expanded'  → Ad expanded to fullscreen
'resized'   → Ad resized from original size
'hidden'    → Ad hidden from view
```

**State transitions:**
- `loading` → `default`: When MRAID ready event fires
- `default` → `expanded`: When ad calls `mraid.expand()`
- `expanded` → `default`: When ad calls `mraid.close()`

## 6. **Why Ad Trackers Need MRAID**

From your test examples (MRAIDAdTestView.swift:102-114):

```javascript
if (typeof mraid !== 'undefined') {
    console.log('[SSP] ✅ MRAID detected!');
    console.log('[SSP] 🎯 MRAID tracker would FIRE here!');
    // Your Equativ SSP would fire the tracker pixel here
}
```

**Why?**
- **MRAID = proper app environment**: Publisher properly integrated the SDK
- **No MRAID = web environment**: Running in mobile browser, not in-app
- **Different pricing**: In-app inventory often costs more than mobile web
- **Viewability tracking**: MRAID provides `isViewable()` to know if ad is on screen
- **Better engagement**: MRAID allows expand, resize, video controls

## 7. **Key Insights for Your Pixel Testing**

The pixels you mentioned that were failing likely check:
1. `document.referrer` - Set in WebView.swift:156-175
2. `document.cookie` - Set in WebView.swift:119-161
3. `location.origin` - Comes from baseURL (`https://equativ.com`)

These are all simulated to make the webview **look like a real publisher environment** so ad pixels fire correctly.

The MRAID injection proves to the ad server: *"This is a real in-app placement with proper MRAID support"* which is why certain trackers depend on it.

## 8. **Architecture Diagram**

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App Layer                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              WebView.swift (Container)                  │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │         WKWebView Configuration                   │  │ │
│  │  │  • Inject MRAID at .atDocumentStart               │  │ │
│  │  │  • Register message handlers                      │  │ │
│  │  │  • Set baseURL, cookies, referrer                 │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                          ↓                              │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │         Coordinator (Message Handler)             │  │ │
│  │  │  • handleMRAIDOpen()                              │  │ │
│  │  │  • handleMRAIDExpand()                            │  │ │
│  │  │  • handleMRAIDClose()                             │  │ │
│  │  │  • handleMRAIDResize()                            │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↕ (webkit.messageHandlers)
┌─────────────────────────────────────────────────────────────┐
│                    WebView JavaScript Layer                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        MRAIDBridge.swift (JavaScript String)           │ │
│  │                                                          │ │
│  │  window.mraid = {                                       │ │
│  │    getVersion: () => '3.0',                            │ │
│  │    getState: () => this._state,                        │ │
│  │    isViewable: () => this._isViewable,                 │ │
│  │    open: (url) => {                                    │ │
│  │      webkit.messageHandlers.mraidOpen.postMessage(url) │ │
│  │    },                                                   │ │
│  │    expand: () => {                                     │ │
│  │      webkit.messageHandlers.mraidExpand.postMessage({})│ │
│  │    },                                                   │ │
│  │    // ... more methods                                 │ │
│  │  }                                                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                            ↓                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Ad Creative HTML/JavaScript                │ │
│  │                                                          │ │
│  │  if (typeof mraid !== 'undefined') {                   │ │
│  │    mraid.addEventListener('ready', () => {             │ │
│  │      console.log('MRAID ready!');                      │ │
│  │      // Fire tracking pixels                           │ │
│  │    });                                                  │ │
│  │  }                                                      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 9. **Debugging MRAID Issues**

### Check MRAID is injected:
1. Open Safari Web Inspector
2. In Console, type: `typeof mraid`
3. Should return: `"object"` (not `"undefined"`)

### Check MRAID version:
```javascript
mraid.getVersion()  // Should return "3.0"
```

### Check MRAID state:
```javascript
mraid.getState()  // Should be "default" after ready event
```

### Monitor MRAID events:
```javascript
mraid.addEventListener('ready', () => console.log('MRAID ready'));
mraid.addEventListener('stateChange', (state) => console.log('State:', state));
mraid.addEventListener('viewableChange', (viewable) => console.log('Viewable:', viewable));
```

### Common issues:
- **"mraid is undefined"**: MRAID not injected or injected too late (check `injectionTime: .atDocumentStart`)
- **State stuck at "loading"**: Ready event not firing (check 50ms timeout in MRAIDBridge)
- **Actions not working**: Message handlers not registered (check WebView.swift:66-69)

## 10. **WebView Stability for Debugging**

### Problem: Safari Web Inspector Disconnects
When the WebView reloads or recreates, Safari Web Inspector disconnects.

### Solution: Prevent Unnecessary Reloads
**Implementation (WebView.swift:120-138):**
```swift
// Track what was last loaded
var lastLoadedContent: String?

func updateUIView(_ webView: WKWebView, context: Context) {
    let contentIdentifier = "html:\(html.hashValue)"

    // Skip reload if content hasn't changed
    if context.coordinator.lastLoadedContent == contentIdentifier {
        print("⏭️ Skipping reload - keeps Web Inspector connected")
        return
    }

    context.coordinator.lastLoadedContent = contentIdentifier
    webView.loadHTMLString(html, baseURL: baseURL)
}
```

**Stable View ID (MRAIDAdTestView.swift:314):**
```swift
WebView(...)
    .id("mraid-ad-preview-stable")  // Prevents SwiftUI recreation
```

This ensures:
- WebView doesn't reload when parent view re-renders
- Safari Web Inspector stays connected
- Debugging session persists
