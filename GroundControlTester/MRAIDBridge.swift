//
//  MRAIDBridge.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-19.
//

import Foundation
import WebKit

/// MRAID 3.0 implementation for iOS WebView
/// This simulates what proper publisher apps should inject
class MRAIDBridge: NSObject {

    weak var webView: WKWebView?

    // MRAID state
    private var state: MRAIDState = .default
    private var isViewable = true
    private var placementType: MRAIDPlacementType = .inline

    enum MRAIDState: String {
        case loading
        case `default`
        case expanded
        case resized
        case hidden
    }

    enum MRAIDPlacementType: String {
        case inline
        case interstitial
    }

    init(webView: WKWebView? = nil) {
        self.webView = webView
        super.init()
    }

    /// The MRAID JavaScript that gets injected into the WebView
    var mraidScript: String {
        return """
        (function() {
            console.log('[MRAID] Injecting MRAID 3.0 implementation...');

            // MRAID object
            window.mraid = {
                // State
                _state: 'loading',
                _isViewable: true,
                _placementType: 'inline',
                _listeners: {},

                // Constants
                STATES: {
                    LOADING: 'loading',
                    DEFAULT: 'default',
                    EXPANDED: 'expanded',
                    RESIZED: 'resized',
                    HIDDEN: 'hidden'
                },

                PLACEMENT_TYPES: {
                    INLINE: 'inline',
                    INTERSTITIAL: 'interstitial'
                },

                EVENTS: {
                    ERROR: 'error',
                    INFO: 'info',
                    READY: 'ready',
                    STATE_CHANGE: 'stateChange',
                    VIEWABLE_CHANGE: 'viewableChange',
                    SIZE_CHANGE: 'sizeChange'
                },

                // Core methods
                getVersion: function() {
                    return '3.0';
                },

                getState: function() {
                    console.log('[MRAID] getState:', this._state);
                    return this._state;
                },

                isViewable: function() {
                    console.log('[MRAID] isViewable:', this._isViewable);
                    return this._isViewable;
                },

                getPlacementType: function() {
                    console.log('[MRAID] getPlacementType:', this._placementType);
                    return this._placementType;
                },

                // Event handling
                addEventListener: function(event, listener) {
                    console.log('[MRAID] addEventListener:', event);
                    if (!this._listeners[event]) {
                        this._listeners[event] = [];
                    }
                    this._listeners[event].push(listener);
                },

                removeEventListener: function(event, listener) {
                    console.log('[MRAID] removeEventListener:', event);
                    if (this._listeners[event]) {
                        var index = this._listeners[event].indexOf(listener);
                        if (index !== -1) {
                            this._listeners[event].splice(index, 1);
                        }
                    }
                },

                _fireEvent: function(event, ...args) {
                    console.log('[MRAID] Firing event:', event, args);
                    if (this._listeners[event]) {
                        this._listeners[event].forEach(function(listener) {
                            try {
                                listener.apply(null, args);
                            } catch(e) {
                                console.error('[MRAID] Error in event listener:', e);
                            }
                        });
                    }
                },

                // Feature support
                supports: function(feature) {
                    var supportedFeatures = {
                        'sms': false,
                        'tel': true,
                        'calendar': false,
                        'storePicture': false,
                        'inlineVideo': true,
                        'vpaid': false,
                        'location': false
                    };
                    var supported = supportedFeatures[feature] || false;
                    console.log('[MRAID] supports(' + feature + '):', supported);
                    return supported;
                },

                // Actions
                open: function(url) {
                    console.log('[MRAID] open:', url);
                    if (window.webkit && window.webkit.messageHandlers.mraidOpen) {
                        window.webkit.messageHandlers.mraidOpen.postMessage(url);
                    } else {
                        window.open(url, '_blank');
                    }
                },

                close: function() {
                    console.log('[MRAID] close');
                    if (window.webkit && window.webkit.messageHandlers.mraidClose) {
                        window.webkit.messageHandlers.mraidClose.postMessage({});
                    }
                    this._setState('default');
                },

                expand: function(url) {
                    console.log('[MRAID] expand:', url);
                    if (this._state !== 'default' && this._state !== 'resized') {
                        this._fireEvent('error', 'Cannot expand from state: ' + this._state, 'expand');
                        return;
                    }
                    if (window.webkit && window.webkit.messageHandlers.mraidExpand) {
                        window.webkit.messageHandlers.mraidExpand.postMessage(url || '');
                    }
                    this._setState('expanded');
                },

                resize: function() {
                    console.log('[MRAID] resize');
                    if (this._placementType === 'interstitial') {
                        this._fireEvent('error', 'Cannot resize interstitial ad', 'resize');
                        return;
                    }
                    if (window.webkit && window.webkit.messageHandlers.mraidResize) {
                        window.webkit.messageHandlers.mraidResize.postMessage({});
                    }
                    this._setState('resized');
                },

                // Size and position
                getMaxSize: function() {
                    var size = {
                        width: window.screen.width,
                        height: window.screen.height
                    };
                    console.log('[MRAID] getMaxSize:', size);
                    return size;
                },

                getScreenSize: function() {
                    var size = {
                        width: window.screen.width,
                        height: window.screen.height
                    };
                    console.log('[MRAID] getScreenSize:', size);
                    return size;
                },

                getCurrentPosition: function() {
                    var position = {
                        x: 0,
                        y: 0,
                        width: window.innerWidth,
                        height: window.innerHeight
                    };
                    console.log('[MRAID] getCurrentPosition:', position);
                    return position;
                },

                getDefaultPosition: function() {
                    var position = {
                        x: 0,
                        y: 0,
                        width: window.innerWidth,
                        height: window.innerHeight
                    };
                    console.log('[MRAID] getDefaultPosition:', position);
                    return position;
                },

                // Internal state management
                _setState: function(newState) {
                    if (this._state !== newState) {
                        var oldState = this._state;
                        this._state = newState;
                        console.log('[MRAID] State changed:', oldState, '->', newState);
                        this._fireEvent('stateChange', newState);
                    }
                },

                _setViewable: function(isViewable) {
                    if (this._isViewable !== isViewable) {
                        this._isViewable = isViewable;
                        console.log('[MRAID] Viewable changed:', isViewable);
                        this._fireEvent('viewableChange', isViewable);
                    }
                },

                // Initialize
                _ready: function() {
                    console.log('[MRAID] Ready!');
                    this._setState('default');
                    this._fireEvent('ready');
                }
            };

            // Mark MRAID as ready after a short delay (simulate loading)
            setTimeout(function() {
                window.mraid._ready();
                console.log('[MRAID] ✅ MRAID 3.0 fully initialized and ready');
                console.log('[MRAID] Available at window.mraid');
            }, 50);

        })();
        """
    }
}
