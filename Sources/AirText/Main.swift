import AppKit

/// Application entry point
/// AirText runs as a menu bar only app (LSUIElement mode)
@main
struct AirTextApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        
        // Ensure we don't show in Dock
        app.setActivationPolicy(.accessory)
        
        app.run()
    }
}
