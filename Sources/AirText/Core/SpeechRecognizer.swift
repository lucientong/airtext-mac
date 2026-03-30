import Speech
import AVFoundation

/// Delegate protocol for speech recognition events
protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognize text: String, isFinal: Bool)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error)
}

/// Speech recognizer using Apple's Speech framework
/// Supports streaming recognition with real-time partial results
final class SpeechRecognizer {
    
    // MARK: - Properties
    
    weak var delegate: SpeechRecognizerDelegate?
    
    private let settingsManager: SettingsManager
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognizing = false
    
    // MARK: - Initialization
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        updateRecognizer()
    }
    
    // MARK: - Public Methods
    
    /// Update the recognizer for the current language setting
    func updateRecognizer() {
        let locale = settingsManager.speechLanguage.locale
        recognizer = SFSpeechRecognizer(locale: locale)
        
        if recognizer == nil {
            print("⚠️ Speech recognizer not available for locale: \(locale.identifier)")
        } else {
            print("✅ Speech recognizer initialized for: \(locale.identifier)")
        }
    }
    
    /// Start speech recognition with the given audio input node
    func startRecognition(with inputNode: AVAudioInputNode) {
        guard !isRecognizing else {
            print("⚠️ Recognition already in progress")
            return
        }
        
        // Update recognizer in case language changed
        updateRecognizer()
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = recognitionRequest else {
            print("❌ Failed to create recognition request")
            return
        }
        
        // Configure request for streaming
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        
        // Set task hint based on language
        if settingsManager.speechLanguage == .simplifiedChinese ||
           settingsManager.speechLanguage == .traditionalChinese {
            request.taskHint = .dictation
        } else {
            request.taskHint = .dictation
        }
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                // Ignore cancellation errors
                if (error as NSError).code != 216 && (error as NSError).code != 1 {
                    self.delegate?.speechRecognizer(self, didFailWithError: error)
                }
                return
            }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                self.delegate?.speechRecognizer(self, didRecognize: text, isFinal: isFinal)
            }
        }
        
        isRecognizing = true
        print("✅ Speech recognition started")
    }
    
    /// Append audio buffer to the recognition request
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
    
    /// Stop speech recognition
    func stopRecognition() {
        guard isRecognizing else { return }
        
        // End the audio input
        recognitionRequest?.endAudio()
        
        // Cancel the task if still running
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
        
        print("✅ Speech recognition stopped")
    }
    
    /// Check if speech recognition is authorized
    static func checkAuthorization(completion: @escaping (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status == .authorized)
                }
            }
        default:
            completion(false)
        }
    }
}
