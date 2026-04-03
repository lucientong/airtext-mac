import Speech
import NaturalLanguage
import AVFoundation

/// Result from a single language candidate during auto-detection
private struct LanguageCandidate {
    let language: SpeechLanguage
    let recognizer: SFSpeechRecognizer
    var request: SFSpeechAudioBufferRecognitionRequest?
    var task: SFSpeechRecognitionTask?
    var latestText: String = ""
    var confidence: Double = 0
}

/// Delegate protocol for auto language detection events
protocol AutoLanguageDetectorDelegate: AnyObject {
    /// Called when a language has been detected and locked
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didDetectLanguage language: SpeechLanguage)
    /// Called with intermediate text during detection phase
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didRecognize text: String, isFinal: Bool)
    /// Called when detection fails
    func autoLanguageDetector(_ detector: AutoLanguageDetector, didFailWithError error: Error)
}

/// Automatically detects the spoken language by running parallel SFSpeechRecognizer
/// instances for all supported languages, then selecting the best match using
/// a combination of transcription output quality and NLLanguageRecognizer analysis.
final class AutoLanguageDetector {
    
    // MARK: - Constants
    
    /// Number of partial results to collect before making a decision
    private let decisionThreshold = 3
    /// Maximum time (seconds) before forcing a decision
    private let maxDetectionTime: TimeInterval = 3.0
    
    // MARK: - Properties
    
    weak var delegate: AutoLanguageDetectorDelegate?
    
    private var candidates: [SpeechLanguage: LanguageCandidate] = [:]
    private var isDetecting = false
    private var hasDecided = false
    private var partialResultCounts: [SpeechLanguage: Int] = [:]
    private var decisionTimer: Timer?
    private let nlRecognizer = NLLanguageRecognizer()
    
    /// The detected language after decision is made
    private(set) var detectedLanguage: SpeechLanguage?
    
    /// The winning recognizer's request (kept alive for seamless handoff)
    private(set) var winningRequest: SFSpeechAudioBufferRecognitionRequest?
    private(set) var winningTask: SFSpeechRecognitionTask?
    
    // MARK: - Public Methods
    
    /// Start auto-detection by launching parallel recognizers for all languages
    func startDetection() {
        guard !isDetecting else { return }
        
        isDetecting = true
        hasDecided = false
        detectedLanguage = nil
        winningRequest = nil
        winningTask = nil
        candidates.removeAll()
        partialResultCounts.removeAll()
        
        print("🔍 Auto language detection started")
        
        // Create a recognizer for each supported language
        for language in SpeechLanguage.allCases {
            guard let recognizer = SFSpeechRecognizer(locale: language.locale),
                  recognizer.isAvailable else {
                print("⚠️ Recognizer not available for \(language.displayName)")
                continue
            }
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.addsPunctuation = false // Disable during detection for speed
            request.taskHint = .dictation
            
            var candidate = LanguageCandidate(
                language: language,
                recognizer: recognizer,
                request: request
            )
            
            // Start recognition task
            let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self, !self.hasDecided else { return }
                
                if let error = error {
                    // Ignore cancellation errors
                    let nsError = error as NSError
                    if nsError.code != 216 && nsError.code != 1 {
                        print("⚠️ [\(language.displayName)] recognition error: \(error.localizedDescription)")
                    }
                    return
                }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.handlePartialResult(text: text, language: language, isFinal: result.isFinal)
                }
            }
            
            candidate.task = task
            candidates[language] = candidate
            partialResultCounts[language] = 0
        }
        
        // Set a timeout timer to force a decision
        decisionTimer = Timer.scheduledTimer(withTimeInterval: maxDetectionTime, repeats: false) { [weak self] _ in
            self?.makeDecision()
        }
    }
    
    /// Append audio buffer to all active candidate recognizers
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        for (_, candidate) in candidates {
            candidate.request?.append(buffer)
        }
    }
    
    /// Stop detection and clean up all resources
    func stopDetection() {
        guard isDetecting else { return }
        
        decisionTimer?.invalidate()
        decisionTimer = nil
        
        // Cancel all non-winning tasks
        for (language, candidate) in candidates where language != detectedLanguage {
            candidate.request?.endAudio()
            candidate.task?.cancel()
        }
        
        candidates.removeAll()
        partialResultCounts.removeAll()
        isDetecting = false
        
        print("🔍 Auto language detection stopped")
    }
    
    // MARK: - Private Methods
    
    private func handlePartialResult(text: String, language: SpeechLanguage, isFinal: Bool) {
        guard !hasDecided else { return }
        
        // Update candidate
        candidates[language]?.latestText = text
        partialResultCounts[language] = (partialResultCounts[language] ?? 0) + 1
        
        // Forward the best intermediate text to delegate for display
        let bestText = getBestIntermediateText()
        delegate?.autoLanguageDetector(self, didRecognize: bestText, isFinal: false)
        
        // Check if we have enough data to decide
        let maxCount = partialResultCounts.values.max() ?? 0
        if maxCount >= decisionThreshold {
            makeDecision()
        }
    }
    
    /// Get the longest/best text among all candidates for display
    private func getBestIntermediateText() -> String {
        return candidates.values
            .map { $0.latestText }
            .filter { !$0.isEmpty }
            .max(by: { $0.count < $1.count }) ?? ""
    }
    
    /// Analyze all candidates and pick the best language match
    private func makeDecision() {
        guard !hasDecided else { return }
        hasDecided = true
        
        decisionTimer?.invalidate()
        decisionTimer = nil
        
        // Score each candidate
        var scores: [(SpeechLanguage, Double, String)] = []
        
        for (language, candidate) in candidates {
            let text = candidate.latestText
            guard !text.isEmpty else { continue }
            
            // Score components:
            // 1. Text length (longer = more successful recognition)
            let lengthScore = Double(text.count)
            
            // 2. NLLanguageRecognizer confidence
            let nlScore = nlConfidence(for: text, expected: language) * 50.0
            
            // 3. Partial result count (more results = more active recognition)
            let activityScore = Double(partialResultCounts[language] ?? 0) * 5.0
            
            let totalScore = lengthScore + nlScore + activityScore
            scores.append((language, totalScore, text))
            
            print("🔍 [\(language.displayName)] score: \(String(format: "%.1f", totalScore)) (len:\(text.count), nl:\(String(format: "%.1f", nlScore)), activity:\(partialResultCounts[language] ?? 0)) text: \"\(text.prefix(50))\"")
        }
        
        // Sort by score and pick the winner
        scores.sort { $0.1 > $1.1 }
        
        guard let winner = scores.first else {
            // Fallback to simplified Chinese if no results
            let fallback = SpeechLanguage.simplifiedChinese
            print("⚠️ No detection results, falling back to \(fallback.displayName)")
            detectedLanguage = fallback
            finishDetection(winner: fallback)
            return
        }
        
        detectedLanguage = winner.0
        print("✅ Language detected: \(winner.0.displayName) (score: \(String(format: "%.1f", winner.1)))")
        
        finishDetection(winner: winner.0)
    }
    
    /// Use NLLanguageRecognizer to get confidence that text matches expected language
    private func nlConfidence(for text: String, expected: SpeechLanguage) -> Double {
        nlRecognizer.reset()
        nlRecognizer.processString(text)
        
        let hypotheses = nlRecognizer.languageHypotheses(withMaximum: 10)
        
        // Map SpeechLanguage to NLLanguage
        let nlLanguage: NLLanguage
        switch expected {
        case .english:
            nlLanguage = .english
        case .simplifiedChinese:
            nlLanguage = .simplifiedChinese
        case .traditionalChinese:
            nlLanguage = .traditionalChinese
        case .japanese:
            nlLanguage = .japanese
        case .korean:
            nlLanguage = .korean
        }
        
        return hypotheses[nlLanguage] ?? 0
    }
    
    /// Finish detection: keep the winning recognizer, cancel all others
    private func finishDetection(winner: SpeechLanguage) {
        // Keep the winning candidate's request and task alive
        if let winnerCandidate = candidates[winner] {
            winningRequest = winnerCandidate.request
            winningTask = winnerCandidate.task
        }
        
        // Cancel all non-winning candidates
        for (language, candidate) in candidates where language != winner {
            candidate.request?.endAudio()
            candidate.task?.cancel()
        }
        
        // Notify delegate
        delegate?.autoLanguageDetector(self, didDetectLanguage: winner)
    }
}
