import AppKit
import CoreGraphics
import Carbon

/// Delegate protocol for keyboard monitor events
protocol KeyboardMonitorDelegate: AnyObject {
    func keyboardMonitorDidDetectFnKeyDown(_ monitor: KeyboardMonitor)
    func keyboardMonitorDidDetectFnKeyUp(_ monitor: KeyboardMonitor)
}

/// Monitors global keyboard events, specifically the Fn key
/// Uses CGEvent tap to intercept system-level key events
final class KeyboardMonitor {
    
    // MARK: - Properties
    
    weak var delegate: KeyboardMonitorDelegate?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnKeyDown = false
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring keyboard events
    func start() {
        guard eventTap == nil else {
            print("⚠️ Keyboard monitor already running")
            return
        }
        
        // Check accessibility permissions first
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("⚠️ Accessibility permissions not granted yet, event tap may fail")
        }
        
        // Create event tap for key events
        // We need to monitor flagsChanged events because Fn key is a modifier
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue) |
                                     (1 << CGEventType.keyDown.rawValue) |
                                     (1 << CGEventType.keyUp.rawValue)
        
        // Create the event tap
        // Using a wrapper to capture self
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: refcon
        ) else {
            print("❌ Failed to create event tap. Make sure Accessibility permissions are granted.")
            showAccessibilityAlert()
            return
        }
        
        eventTap = tap
        
        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        // Add to current run loop
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("✅ Keyboard monitor started")
    }
    
    /// Stop monitoring keyboard events
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isFnKeyDown = false
        
        print("✅ Keyboard monitor stopped")
    }
    
    // MARK: - Private Methods
    
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        
        // Handle tap disabled event (system may disable tap if it's too slow)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        // Handle flags changed events (modifier keys like Fn)
        if type == .flagsChanged {
            return handleFlagsChanged(event: event)
        }
        
        // Pass through other events
        return Unmanaged.passRetained(event)
    }
    
    private func handleFlagsChanged(event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Check for Fn key (keyCode 63)
        // The Fn key is special - it may not always report keyCode 63,
        // but we can detect it via the secondaryFn flag
        let isFnPressed = flags.contains(.maskSecondaryFn)
        
        // Fn key press detection
        if isFnPressed && !isFnKeyDown {
            // Fn key just pressed
            isFnKeyDown = true
            delegate?.keyboardMonitorDidDetectFnKeyDown(self)
            
            // Suppress the event to prevent emoji picker
            return nil
        } else if !isFnPressed && isFnKeyDown {
            // Fn key just released
            isFnKeyDown = false
            delegate?.keyboardMonitorDidDetectFnKeyUp(self)
            
            // Suppress the event
            return nil
        }
        
        // Pass through other flag changes
        return Unmanaged.passRetained(event)
    }
    
    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "AirText needs Accessibility permission to detect the Fn key.\n\nPlease go to System Settings > Privacy & Security > Accessibility and add AirText."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open Accessibility settings
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
