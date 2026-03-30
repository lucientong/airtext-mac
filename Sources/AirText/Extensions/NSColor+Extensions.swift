import AppKit

extension NSColor {
    /// Primary accent color for the app
    static var airTextAccent: NSColor {
        return NSColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0) // System blue
    }
    
    /// Waveform bar color
    static var waveformBar: NSColor {
        return NSColor.white.withAlphaComponent(0.9)
    }
    
    /// Text color for transcription
    static var transcriptionText: NSColor {
        return NSColor.white
    }
    
    /// Secondary text color
    static var secondaryText: NSColor {
        return NSColor.white.withAlphaComponent(0.7)
    }
    
    /// Background overlay color
    static var overlayBackground: NSColor {
        return NSColor.black.withAlphaComponent(0.3)
    }
}
