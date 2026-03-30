import AppKit

/// Status bar menu for the application
/// Provides language selection, LLM settings, and app controls
final class StatusBarMenu: NSObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem!
    private let settingsManager: SettingsManager
    private let llmService: LLMService
    private var settingsWindowController: SettingsWindowController?
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManager, llmService: LLMService) {
        self.settingsManager = settingsManager
        self.llmService = llmService
        super.init()
        setupStatusItem()
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "AirText")
            button.image?.isTemplate = true
        }
        
        statusItem.menu = createMenu()
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Language submenu
        let languageItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageItem.submenu = createLanguageSubmenu()
        menu.addItem(languageItem)
        
        menu.addItem(.separator())
        
        // LLM Refinement submenu
        let llmItem = NSMenuItem(title: "LLM Refinement", action: nil, keyEquivalent: "")
        llmItem.submenu = createLLMSubmenu()
        menu.addItem(llmItem)
        
        menu.addItem(.separator())
        
        // About
        menu.addItem(NSMenuItem(title: "About AirText", action: #selector(showAbout), keyEquivalent: ""))
        
        menu.addItem(.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit AirText", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set target for all items
        for item in menu.items {
            if item.action != nil {
                item.target = self
            }
        }
        
        return menu
    }
    
    private func createLanguageSubmenu() -> NSMenu {
        let submenu = NSMenu()
        
        for language in SpeechLanguage.allCases {
            let item = NSMenuItem(title: language.displayName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language
            item.state = (language == settingsManager.speechLanguage) ? .on : .off
            submenu.addItem(item)
        }
        
        return submenu
    }
    
    private func createLLMSubmenu() -> NSMenu {
        let submenu = NSMenu()
        
        // Enable toggle
        let enableItem = NSMenuItem(title: "Enable", action: #selector(toggleLLM(_:)), keyEquivalent: "")
        enableItem.target = self
        enableItem.state = settingsManager.llmConfig.isEnabled ? .on : .off
        submenu.addItem(enableItem)
        
        submenu.addItem(.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showLLMSettings), keyEquivalent: ",")
        settingsItem.target = self
        submenu.addItem(settingsItem)
        
        return submenu
    }
    
    // MARK: - Actions
    
    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? SpeechLanguage else { return }
        settingsManager.setLanguage(language)
        
        // Update menu states
        if let submenu = sender.menu {
            for item in submenu.items {
                item.state = (item.representedObject as? SpeechLanguage == language) ? .on : .off
            }
        }
    }
    
    @objc private func toggleLLM(_ sender: NSMenuItem) {
        let newState = !settingsManager.llmConfig.isEnabled
        settingsManager.setLLMEnabled(newState)
        sender.state = newState ? .on : .off
    }
    
    @objc private func showLLMSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settingsManager: settingsManager, llmService: llmService)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AirText"
        alert.informativeText = "Voice-to-text input for macOS\nVersion 1.0.0\n\nHold Fn to record, release to transcribe."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
