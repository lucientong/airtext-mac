import AppKit

/// Window controller for LLM settings
final class SettingsWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private let settingsManager: SettingsManager
    private let llmService: LLMService
    
    private var baseURLField: NSTextField!
    private var apiKeyField: NSSecureTextField!
    private var modelField: NSTextField!
    private var testButton: NSButton!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManager, llmService: LLMService) {
        self.settingsManager = settingsManager
        self.llmService = llmService
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LLM Settings"
        window.center()
        
        super.init(window: window)
        setupContent()
        loadSettings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupContent() {
        let contentView = NSView(frame: window!.contentView!.bounds)
        window?.contentView = contentView
        
        let padding: CGFloat = 20
        let labelWidth: CGFloat = 100
        let fieldHeight: CGFloat = 24
        let rowSpacing: CGFloat = 16
        var y = contentView.bounds.height - padding - fieldHeight
        
        // API Base URL
        let baseURLLabel = createLabel("API Base URL:")
        baseURLLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight)
        contentView.addSubview(baseURLLabel)
        
        baseURLField = NSTextField()
        baseURLField.frame = NSRect(x: padding + labelWidth + 8, y: y, width: contentView.bounds.width - padding * 2 - labelWidth - 8, height: fieldHeight)
        baseURLField.placeholderString = "https://api.openai.com/v1"
        contentView.addSubview(baseURLField)
        
        y -= fieldHeight + rowSpacing
        
        // API Key
        let apiKeyLabel = createLabel("API Key:")
        apiKeyLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight)
        contentView.addSubview(apiKeyLabel)
        
        apiKeyField = NSSecureTextField()
        apiKeyField.frame = NSRect(x: padding + labelWidth + 8, y: y, width: contentView.bounds.width - padding * 2 - labelWidth - 8, height: fieldHeight)
        apiKeyField.placeholderString = "sk-..."
        contentView.addSubview(apiKeyField)
        
        y -= fieldHeight + rowSpacing
        
        // Model
        let modelLabel = createLabel("Model:")
        modelLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight)
        contentView.addSubview(modelLabel)
        
        modelField = NSTextField()
        modelField.frame = NSRect(x: padding + labelWidth + 8, y: y, width: contentView.bounds.width - padding * 2 - labelWidth - 8, height: fieldHeight)
        modelField.placeholderString = "gpt-4o-mini"
        contentView.addSubview(modelField)
        
        y -= fieldHeight + rowSpacing + 8
        
        // Status label
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: padding, y: y, width: contentView.bounds.width - padding * 2, height: fieldHeight)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        contentView.addSubview(statusLabel)
        
        y -= fieldHeight + rowSpacing
        
        // Buttons
        let buttonWidth: CGFloat = 80
        let buttonSpacing: CGFloat = 12
        
        saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: contentView.bounds.width - padding - buttonWidth, y: padding, width: buttonWidth, height: 28)
        contentView.addSubview(saveButton)
        
        testButton = NSButton(title: "Test", target: self, action: #selector(testConnection))
        testButton.bezelStyle = .rounded
        testButton.frame = NSRect(x: contentView.bounds.width - padding - buttonWidth * 2 - buttonSpacing, y: padding, width: buttonWidth, height: 28)
        contentView.addSubview(testButton)
    }
    
    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .right
        label.font = .systemFont(ofSize: 13)
        return label
    }
    
    private func loadSettings() {
        let config = settingsManager.llmConfig
        baseURLField.stringValue = config.baseURL
        apiKeyField.stringValue = config.apiKey
        modelField.stringValue = config.model
    }
    
    // MARK: - Actions
    
    @objc private func testConnection() {
        let config = LLMConfig(
            baseURL: baseURLField.stringValue,
            apiKey: apiKeyField.stringValue,
            model: modelField.stringValue,
            isEnabled: true
        )
        
        statusLabel.stringValue = "Testing..."
        statusLabel.textColor = .secondaryLabelColor
        testButton.isEnabled = false
        
        llmService.testConnection(config: config) { [weak self] success, error in
            self?.testButton.isEnabled = true
            if success {
                self?.statusLabel.stringValue = "✅ Connection successful"
                self?.statusLabel.textColor = .systemGreen
            } else {
                self?.statusLabel.stringValue = "❌ \(error ?? "Connection failed")"
                self?.statusLabel.textColor = .systemRed
            }
        }
    }
    
    @objc private func saveSettings() {
        let config = LLMConfig(
            baseURL: baseURLField.stringValue,
            apiKey: apiKeyField.stringValue,
            model: modelField.stringValue,
            isEnabled: settingsManager.llmConfig.isEnabled
        )
        
        settingsManager.updateLLMConfig(config)
        statusLabel.stringValue = "✅ Settings saved"
        statusLabel.textColor = .systemGreen
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.window?.close()
        }
    }
}
