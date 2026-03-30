import Foundation

/// Service for LLM-based text refinement
/// Uses OpenAI-compatible API to correct speech recognition errors
final class LLMService {
    
    // MARK: - Properties
    
    private let settingsManager: SettingsManager
    private let session = URLSession.shared
    
    /// System prompt for conservative text correction
    private let systemPrompt = """
        你是一个语音识别文本校正助手。你的任务是非常保守地纠正语音识别错误：
        - 只修复明显的语音识别错误（如中文谐音错误）
        - 将英文技术术语从错误的中文音译还原（如"配森"→"Python"、"杰森"→"JSON"、"艾批艾"→"API"、"杰爱斯"→"JS"、"艾奇踢盟偶"→"HTML"、"西艾斯艾斯"→"CSS"、"瑞艾克特"→"React"、"诺的"→"Node"）
        - 修复常见的同音字错误（如"在"和"再"、"的"和"地"和"得"）
        - 绝对不要改写、润色或删除任何看起来正确的内容
        - 如果输入看起来正确，必须原样返回
        - 保持原始的标点符号和格式
        请直接返回校正后的文本，不要添加任何解释或额外内容。
        """
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Public Methods
    
    /// Check if LLM refinement is available
    var isAvailable: Bool {
        let config = settingsManager.llmConfig
        return config.isEnabled && config.isConfigured
    }
    
    /// Refine transcribed text using LLM
    /// - Parameters:
    ///   - text: The text to refine
    ///   - completion: Callback with refined text (nil if failed)
    func refineText(_ text: String, completion: @escaping (String?) -> Void) {
        let config = settingsManager.llmConfig
        
        guard config.isEnabled && config.isConfigured else {
            completion(text)
            return
        }
        
        // Build request
        guard let request = buildRequest(text: text, config: config) else {
            completion(text)
            return
        }
        
        // Send request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ LLM request failed: \(error.localizedDescription)")
                completion(text)
                return
            }
            
            guard let data = data else {
                completion(text)
                return
            }
            
            // Parse response
            if let refinedText = self.parseResponse(data) {
                completion(refinedText)
            } else {
                completion(text)
            }
        }
        
        task.resume()
    }
    
    /// Test LLM connection
    /// - Parameters:
    ///   - config: Configuration to test
    ///   - completion: Callback with success status and error message
    func testConnection(config: LLMConfig, completion: @escaping (Bool, String?) -> Void) {
        guard let request = buildRequest(text: "测试", config: config) else {
            completion(false, "Invalid configuration")
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else if httpResponse.statusCode == 401 {
                    completion(false, "Invalid API key")
                } else if httpResponse.statusCode == 404 {
                    completion(false, "Invalid API endpoint or model")
                } else {
                    completion(false, "HTTP \(httpResponse.statusCode)")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(text: String, config: LLMConfig) -> URLRequest? {
        // Construct URL
        var urlString = config.baseURL.trimmingCharacters(in: .whitespaces)
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += "chat/completions"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1,  // Low temperature for conservative corrections
            "max_tokens": 2048
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return nil
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        return request
    }
    
    private func parseResponse(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
