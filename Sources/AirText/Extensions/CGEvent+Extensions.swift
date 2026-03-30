import CoreGraphics
import Carbon

extension CGEvent {
    /// Create a key down event for the given key code with optional modifiers
    static func keyDown(keyCode: CGKeyCode, flags: CGEventFlags = []) -> CGEvent? {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        event?.flags = flags
        return event
    }
    
    /// Create a key up event for the given key code with optional modifiers
    static func keyUp(keyCode: CGKeyCode, flags: CGEventFlags = []) -> CGEvent? {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        event?.flags = flags
        return event
    }
    
    /// Simulate a key press (down + up) with optional modifiers
    static func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let keyDown = CGEvent.keyDown(keyCode: keyCode, flags: flags)
        let keyUp = CGEvent.keyUp(keyCode: keyCode, flags: flags)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Simulate Cmd+V paste
    static func simulatePaste() {
        // Key code for 'V' is 9
        let vKeyCode: CGKeyCode = 9
        simulateKeyPress(keyCode: vKeyCode, flags: .maskCommand)
    }
}

// MARK: - Key Codes

enum KeyCode {
    static let fn: CGKeyCode = 0x3F  // 63
    static let v: CGKeyCode = 9
    static let space: CGKeyCode = 49
    static let returnKey: CGKeyCode = 36
    static let escape: CGKeyCode = 53
}
