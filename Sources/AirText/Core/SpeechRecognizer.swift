import Speech
import AVFoundation

/// Delegate protocol for speech recognition events
protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognize text: String, isFinal: Bool)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didDetectLanguage language: SpeechLanguage)
}

/// Default implementation for optional delegate methods
extension SpeechRecognizerDelegate {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didDetectLanguage language: SpeechLanguage) {}
}

/// Speech recognizer using Apple's Speech framework
/// Supports both fixed-language and auto-detect modes
final class SpeechRecognizer {
    
    // MARK: - Properties
    
    weak var delegate: SpeechRecognizerDelegate?
    
    private let settingsManager: SettingsManager
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognizing = false
    
    // Auto-detection
    private var autoDetector: AutoLanguageDetector?
    private var isInAutoMode = false
    private var hasHandedOff = false  // Whether auto-detection has handed off to fixed recognizer
    
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
        
        isRecognizing = true
        hasHandedOff = false
        
        if settingsManager.languageMode.isAuto {
            // Auto-detect mode: start parallel recognizers
            startAutoDetection()
        } else {
            // Fixed language mode: start single recognizer
            startFixedRecognition()
        }
    }
    
    /// Append audio buffer to the recognition request
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        if isInAutoMode, let detector = autoDetector {
            // During auto-detection, feed all parallel recognizers
            detector.appendAudioBuffer(buffer)
            
            // Also feed the handoff recognizer if it exists
            if hasHandedOff {
                recognitionRequest?.append(buffer)
            }
        } else {
            recognitionRequest?.append(buffer)
        }
    }
    
    /// Stop speech recognition
    func stopRecognition() {
        guard isRecognizing else { return }
        
        // Stop auto-detector if active
        if isInAutoMode {
            autoDetector?.stopDetection()
            autoDetector = nil
            isInAutoMode = false
        }
        
        // End the audio input
        recognitionRequest?.endAudio()
        
        // Cancel the task if still running
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
        hasHandedOff = false
        
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
    
    // MARK: - Private Methods
    
    /// Start fixed-language recognition (original behavior)
    private func startFixedRecognition() {
        isInAutoMode = false
        
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
        request.taskHint = .dictation
        
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
        
        print("✅ Speech recognition started (fixed: \(settingsManager.speechLanguage.displayName))")
    }
    
    /// Start auto-detection mode with parallel recognizers
    private func startAutoDetection() {
        isInAutoMode = true
        
        autoDetector = AutoLanguageDetector()
        autoDetector?.delegate = self
        autoDetector?.startDetection()
        
        print("✅ Speech recognition started (auto-detect mode)")
    }
    
    /// Hand off from auto-detection to a fixed recognizer for the detected language
    private func handOffToFixedRecognizer(language: SpeechLanguage) {
        guard isInAutoMode, !hasHandedOff else { return }
        hasHandedOff = true
        
        // Use the winning recognizer's task from auto-detector if available
        if let winningRequest = autoDetector?.winningRequest,
           let winningTask = autoDetector?.winningTask {
            // Reuse the winning recognizer — it already has context
            recognitionRequest = winningRequest
            recognitionTask = winningTask
            
            // Re-enable punctuation now that we've settled on a language
            recognitionRequest?.addsPunctuation = true
            
            // Stop all non-winning candidates but keep the winner alive
            // (already done in AutoLanguageDetector.finishDetection)
            
            print("✅ Handed off to \(language.displayName) (reusing winning recognizer)")
        } else {
            // Fallback: create a new recognizer for the detected language
            let locale = language.locale
            recognizer = SFSpeechRecognizer(locale: locale)
            
            guard let recognizer = recognizer, recognizer.isAvailable else {
                print("❌ Recognizer not available for detected language: \(language.displayName)")
                return
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            
            request.shouldReportPartialResults = true
            request.addsPunctuation = true
            request.taskHint = .dictation
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    if (error as NSError).code != 216 && (error as NSError).code != 1 {
                        self.delegate?.speechRecognizer(self, didFailWithError: error)
                    }
                    return
                }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.delegate?.speechRecognizer(self, didRecognize: text, isFinal: result.isFinal)
                }
            }
            
            print("✅ Handed off to \(language.displayName) (new recognizer)")
        }
    }
}

// MARK: - AutoLanguageDetectorDelegate

extension SpeechRecognizer: AutoLanguageDetectorDelegate {
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didDetectLanguage language: SpeechLanguage) {
        print("🎯 Auto-detected language: \(language.displayName)")
        
        // Notify delegate about detected language
        delegate?.speechRecognizer(self, didDetectLanguage: language)
        
        // Hand off to fixed recognizer for the detected language
        handOffToFixedRecognizer(language: language)
    }
    
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didRecognize text: String, isFinal: Bool) {
        // Forward intermediate results during detection phase
        delegate?.speechRecognizer(self, didRecognize: text, isFinal: isFinal)
    }
    
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didFailWithError error: Error) {
        delegate?.speechRecognizer(self, didFailWithError: error)
    }
}
