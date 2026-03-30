import AppKit
import Carbon

/// Handles text injection into the currently focused text field
/// Uses clipboard + Cmd+V approach with input method handling
final class TextInjector {
    
    // MARK: - Properties
    
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Inject text into the currently focused input field
    func inject(text: String) {
        guard !text.isEmpty else { return }
        
        // Save current clipboard content
        let savedClipboard = saveClipboard()
        
        // Check current input source and switch if needed
        let originalInputSource = getCurrentInputSource()
        let needsInputSourceSwitch = isCJKInputSource(originalInputSource)
        
        if needsInputSourceSwitch {
            switchToASCIIInputSource()
            // Small delay to ensure input source switch takes effect
            usleep(50000) // 50ms
        }
        
        // Set clipboard to our text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Small delay to ensure clipboard is ready
        usleep(20000) // 20ms
        
        // Simulate Cmd+V
        simulatePaste()
        
        // Wait for paste to complete
        usleep(100000) // 100ms
        
        // Restore original input source
        if needsInputSourceSwitch, let original = originalInputSource {
            restoreInputSource(original)
        }
        
        // Restore original clipboard content
        restoreClipboard(savedClipboard)
    }
    
    // MARK: - Clipboard Management
    
    private func saveClipboard() -> [NSPasteboard.PasteboardType: Data]? {
        var savedItems: [NSPasteboard.PasteboardType: Data] = [:]
        
        guard let items = pasteboard.pasteboardItems else {
            return nil
        }
        
        for item in items {
            for type in item.types {
                if let data = item.data(forType: type) {
                    savedItems[type] = data
                }
            }
        }
        
        return savedItems.isEmpty ? nil : savedItems
    }
    
    private func restoreClipboard(_ savedItems: [NSPasteboard.PasteboardType: Data]?) {
        // Delay restoration to ensure paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self, let items = savedItems else { return }
            
            self.pasteboard.clearContents()
            
            let pasteboardItem = NSPasteboardItem()
            for (type, data) in items {
                pasteboardItem.setData(data, forType: type)
            }
            self.pasteboard.writeObjects([pasteboardItem])
        }
    }
    
    // MARK: - Input Source Management
    
    private func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }
    
    private func isCJKInputSource(_ inputSource: TISInputSource?) -> Bool {
        guard let source = inputSource else { return false }
        
        // Get the input source ID
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return false
        }
        
        let inputSourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        
        // Check for common CJK input source patterns
        let cjkPatterns = [
            "com.apple.inputmethod.SCIM",        // Apple Simplified Chinese
            "com.apple.inputmethod.TCIM",        // Apple Traditional Chinese
            "com.apple.inputmethod.Japanese",     // Apple Japanese
            "com.apple.inputmethod.Korean",       // Apple Korean
            "com.sogou",                          // Sogou
            "com.baidu",                          // Baidu
            "com.tencent.inputmethod",            // QQ Pinyin
            "com.iflytek",                        // iFlytek
            "jp.co.google.inputmethod",           // Google Japanese
            "com.google.inputmethod",             // Google Pinyin
            "com.apple.inputmethod.ChineseHandwriting",
        ]
        
        for pattern in cjkPatterns {
            if inputSourceID.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    private func switchToASCIIInputSource() {
        // Get list of input sources
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }
        
        // Find ABC or US keyboard
        let asciiSourceIDs = [
            "com.apple.keylayout.ABC",
            "com.apple.keylayout.US",
            "com.apple.keylayout.USExtended",
        ]
        
        for source in sources {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
                continue
            }
            
            let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            
            if asciiSourceIDs.contains(sourceID) {
                // Check if this source can be selected
                guard let selectablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else {
                    continue
                }
                
                let selectable = Unmanaged<CFBoolean>.fromOpaque(selectablePtr).takeUnretainedValue()
                
                if CFBooleanGetValue(selectable) {
                    TISSelectInputSource(source)
                    return
                }
            }
        }
    }
    
    private func restoreInputSource(_ inputSource: TISInputSource) {
        // Small delay before restoring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            TISSelectInputSource(inputSource)
        }
    }
    
    // MARK: - Keyboard Simulation
    
    private func simulatePaste() {
        // Key code for 'V'
        let vKeyCode: CGKeyCode = 9
        
        // Create key down event with Command modifier
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        // Create key up event
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // Post events
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        usleep(10000) // 10ms between down and up
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
