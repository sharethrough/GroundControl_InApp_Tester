# GroundControl In-App Tester

A minimal SwiftUI iOS app for quickly loading GroundControl sandbox pages (and any custom URL) inside a WKWebView to manually verify in-app rendering, ad behavior, and media playback. It’s a manual test harness — not a full sample integration.

## Quick Start

```bash
# Clone
git clone https://github.com/sharethrough/GroundControl_InApp_Tester.git
cd GroundControl_InApp_Tester

# Open in Xcode
open GroundControlTester.xcodeproj
```

1. Choose a simulator or connect an iOS device (iOS 16.4+ for Web Inspector).
2. Press Cmd+R to build & run.
3. On the home screen select a preset URL or enter a custom one and tap “Load Custom URL”.

## Preset Pages
1. Equativ GroundControl Sandbox – `https://eqt-gc-test.rendering.sharethrough.com/`
2. Sharethrough GroundControl Sandbox – `https://groundcontrol.rendering.sharethrough.com/sandbox.html`
3. Generic test page – `https://test-a-tag.com/`

Custom URLs: if you omit a scheme it automatically prepends `https://`.

## What To Test
Use this app to manually check:
- Ad script injection & creative rendering
- Network requests to GroundControl endpoints
- Inline video & autoplay behavior
- Navigation between pages (state resets, performance)

## Using Safari Web Inspector (Device)
1. On device: Settings > Safari > Advanced > enable Web Inspector.
2. Connect device to your Mac (USB or same Wi‑Fi, Develop menu enabled in Safari Preferences > Advanced).
3. In macOS Safari menu: Develop > [Device] > GroundControl In-App Tester > select current page.
4. Inspect Console, Network, and Sources for ad tags, errors, timing.

Simulator: Open Safari’s Develop menu; the simulator’s web view should appear similarly if running iOS 16.4+ runtime.

## Quick Troubleshooting
| Symptom | Check |
| ------- | ----- |
| Blank page | URL validity, network access, Console errors |
| Web Inspector missing | iOS < 16.4 or Inspector not enabled |
| Autoplay blocked | Page policy or media attributes (look for console warnings) |
| Can’t go “Home” | Ensure navigation path not empty; relaunch if stuck |

## Modifying Presets
Edit the `presetSites` array in `ContentView.swift` to add/remove sandbox URLs.

## Scope
This app is intentionally simple: no persistence, analytics, or automated tests. Extend as needed for your workflow.

## References & Quick Links
- Xcode Download & Release Notes: https://developer.apple.com/xcode/
- Set Up Xcode (Install & Updates – Apple Doc): https://developer.apple.com/support/xcode/
- Enable Developer Mode on iOS 16+: https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device
- Safari Web Inspector Overview: https://developer.apple.com/documentation/safari-developer-tools
- WKWebView Documentation: https://developer.apple.com/documentation/webkit/wkwebview
- iOS Web Content Debugging (WebKit Blog): https://webkit.org/
- SwiftUI: https://developer.apple.com/documentation/swiftuick

---
Happy testing! Simplified for rapid manual validation.
