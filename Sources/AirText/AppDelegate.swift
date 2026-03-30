import AppKit
import AVFoundation
import Speech

/// Main application delegate that coordinates all components
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var statusBarMenu: StatusBarMenu!
    private var floatingPanel: FloatingPanel!
    private var keyboardMonitor: KeyboardMonitor!
    private var audioEngine: AudioEngine!
    private var speechRecognizer: SpeechRecognizer!
    private var textInjector: TextInjector!
    private var llmService: LLMService!
    private var settingsManager: SettingsManager!
    
    private var isRecording = false
    private var currentTranscription = ""
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize settings manager first
        settingsManager = SettingsManager()
        
        // Initialize services
        llmService = LLMService(settingsManager: settingsManager)
        textInjector = TextInjector()
        
        // Initialize audio and speech
        audioEngine = AudioEngine()
        audioEngine.delegate = self
        
        speechRecognizer = SpeechRecognizer(settingsManager: settingsManager)
        speechRecognizer.delegate = self
        
        // Initialize UI
        floatingPanel = FloatingPanel()
        statusBarMenu = StatusBarMenu(settingsManager: settingsManager, llmService: llmService)
        
        // Initialize keyboard monitor
        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor.delegate = self
        
        // Request permissions
        requestPermissions()
        
        // Start keyboard monitoring
        keyboardMonitor.start()
        
        print("AirText started successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stop()
        stopRecording()
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() {
        // Request microphone access
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                print("⚠️ Microphone access denied")
            }
        }
        
        // Request speech recognition access
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("✅ Speech recognition authorized")
            case .denied, .restricted:
                print("⚠️ Speech recognition denied or restricted")
            case .notDetermined:
                print("⚠️ Speech recognition not determined")
            @unknown default:
                break
            }
        }
        
        // Check accessibility permissions (required for CGEvent tap)
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("⚠️ Accessibility permissions required. Please grant access in System Settings > Privacy & Security > Accessibility")
        }
    }
    
    // MARK: - Recording Control
    
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        currentTranscription = ""
        
        // Show floating panel
        floatingPanel.show()
        floatingPanel.updateText("")
        
        // Start audio engine
        audioEngine.start()
        
        // Start speech recognition with audio engine's format
        if let inputNode = audioEngine.inputNode {
            speechRecognizer.startRecognition(with: inputNode)
        }
        
        print("🎙️ Recording started")
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        
        // Stop speech recognition
        speechRecognizer.stopRecognition()
        
        // Stop audio engine
        audioEngine.stop()
        
        print("🎙️ Recording stopped")
        
        // Process the final transcription
        processTranscription()
    }
    
    private func processTranscription() {
        let text = currentTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else {
            floatingPanel.hide()
            return
        }
        
        // Check if LLM refinement is enabled
        if settingsManager.llmConfig.isEnabled && !settingsManager.llmConfig.apiKey.isEmpty {
            // Show refining status
            floatingPanel.showRefiningStatus()
            
            // Refine with LLM
            llmService.refineText(text) { [weak self] refinedText in
                DispatchQueue.main.async {
                    self?.injectText(refinedText ?? text)
                    self?.floatingPanel.hide()
                }
            }
        } else {
            // Inject directly without LLM
            injectText(text)
            floatingPanel.hide()
        }
    }
    
    private func injectText(_ text: String) {
        textInjector.inject(text: text)
        print("📝 Injected: \(text)")
    }
}

// MARK: - KeyboardMonitorDelegate

extension AppDelegate: KeyboardMonitorDelegate {
    func keyboardMonitorDidDetectFnKeyDown(_ monitor: KeyboardMonitor) {
        DispatchQueue.main.async { [weak self] in
            self?.startRecording()
        }
    }
    
    func keyboardMonitorDidDetectFnKeyUp(_ monitor: KeyboardMonitor) {
        DispatchQueue.main.async { [weak self] in
            self?.stopRecording()
        }
    }
}

// MARK: - AudioEngineDelegate

extension AppDelegate: AudioEngineDelegate {
    func audioEngine(_ engine: AudioEngine, didUpdateRMSLevel level: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.floatingPanel.updateAudioLevel(level)
        }
    }
    
    func audioEngine(_ engine: AudioEngine, didReceiveBuffer buffer: AVAudioPCMBuffer) {
        speechRecognizer.appendAudioBuffer(buffer)
    }
}

// MARK: - SpeechRecognizerDelegate

extension AppDelegate: SpeechRecognizerDelegate {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognize text: String, isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.currentTranscription = text
            self?.floatingPanel.updateText(text)
        }
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) {
        print("❌ Speech recognition error: \(error.localizedDescription)")
    }
}
