import Foundation

/// Supported speech recognition languages
enum SpeechLanguage: String, CaseIterable, Codable {
    case english = "en-US"
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-TW"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }
    
    var locale: Locale {
        return Locale(identifier: rawValue)
    }
}

/// Language mode: either a fixed language or automatic detection
enum LanguageMode: Codable, Equatable {
    case auto
    case fixed(SpeechLanguage)
    
    var isAuto: Bool {
        if case .auto = self { return true }
        return false
    }
    
    var fixedLanguage: SpeechLanguage? {
        if case .fixed(let lang) = self { return lang }
        return nil
    }
    
    var displayName: String {
        switch self {
        case .auto:
            return "Auto Detect"
        case .fixed(let lang):
            return lang.displayName
        }
    }
}

/// LLM configuration for text refinement
struct LLMConfig: Codable, Equatable {
    var baseURL: String
    var apiKey: String
    var model: String
    var isEnabled: Bool
    
    static let `default` = LLMConfig(
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-4o-mini",
        isEnabled: false
    )
    
    var isConfigured: Bool {
        return !apiKey.isEmpty && !baseURL.isEmpty && !model.isEmpty
    }
}

/// Manages application settings with UserDefaults persistence
final class SettingsManager: ObservableObject {
    
    // MARK: - Keys
    
    private enum Keys {
        static let speechLanguage = "speechLanguage"
        static let languageMode = "languageMode"
        static let llmConfig = "llmConfig"
    }
    
    // MARK: - Properties
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Current language mode (auto detect or fixed language)
    @Published var languageMode: LanguageMode {
        didSet {
            saveLanguageMode()
        }
    }
    
    /// Current speech recognition language (for backward compatibility)
    /// When in auto mode, returns the default language (simplifiedChinese)
    var speechLanguage: SpeechLanguage {
        switch languageMode {
        case .auto:
            return .simplifiedChinese
        case .fixed(let lang):
            return lang
        }
    }
    
    /// LLM configuration
    @Published var llmConfig: LLMConfig {
        didSet {
            saveLLMConfig()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load language mode
        if let data = defaults.data(forKey: Keys.languageMode),
           let mode = try? decoder.decode(LanguageMode.self, from: data) {
            self.languageMode = mode
        } else if let savedLanguage = defaults.string(forKey: Keys.speechLanguage),
                  let language = SpeechLanguage(rawValue: savedLanguage) {
            // Migrate from old speechLanguage setting
            self.languageMode = .fixed(language)
        } else {
            self.languageMode = .auto
        }
        
        // Load LLM config
        if let data = defaults.data(forKey: Keys.llmConfig),
           let config = try? decoder.decode(LLMConfig.self, from: data) {
            self.llmConfig = config
        } else {
            self.llmConfig = .default
        }
    }
    
    // MARK: - Public Methods
    
    /// Update speech language (sets fixed mode)
    func setLanguage(_ language: SpeechLanguage) {
        languageMode = .fixed(language)
    }
    
    /// Set language mode (auto or fixed)
    func setLanguageMode(_ mode: LanguageMode) {
        languageMode = mode
    }
    
    /// Update LLM configuration
    func updateLLMConfig(_ config: LLMConfig) {
        llmConfig = config
    }
    
    /// Enable or disable LLM refinement
    func setLLMEnabled(_ enabled: Bool) {
        var config = llmConfig
        config.isEnabled = enabled
        llmConfig = config
    }
    
    // MARK: - Private Methods
    
    private func saveLLMConfig() {
        if let data = try? encoder.encode(llmConfig) {
            defaults.set(data, forKey: Keys.llmConfig)
        }
    }
    
    private func saveLanguageMode() {
        if let data = try? encoder.encode(languageMode) {
            defaults.set(data, forKey: Keys.languageMode)
        }
    }
}
