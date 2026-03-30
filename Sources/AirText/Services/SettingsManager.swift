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
        static let llmConfig = "llmConfig"
    }
    
    // MARK: - Properties
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Current speech recognition language
    @Published var speechLanguage: SpeechLanguage {
        didSet {
            defaults.set(speechLanguage.rawValue, forKey: Keys.speechLanguage)
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
        // Load speech language with default to Simplified Chinese
        if let savedLanguage = defaults.string(forKey: Keys.speechLanguage),
           let language = SpeechLanguage(rawValue: savedLanguage) {
            self.speechLanguage = language
        } else {
            self.speechLanguage = .simplifiedChinese
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
    
    /// Update speech language
    func setLanguage(_ language: SpeechLanguage) {
        speechLanguage = language
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
}
