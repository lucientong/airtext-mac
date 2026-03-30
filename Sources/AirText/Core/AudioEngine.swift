import AVFoundation

/// Delegate protocol for audio engine events
protocol AudioEngineDelegate: AnyObject {
    func audioEngine(_ engine: AudioEngine, didUpdateRMSLevel level: Float)
    func audioEngine(_ engine: AudioEngine, didReceiveBuffer buffer: AVAudioPCMBuffer)
}

/// Audio engine that captures microphone input and calculates RMS levels
final class AudioEngine {
    
    // MARK: - Properties
    
    weak var delegate: AudioEngineDelegate?
    
    private let engine = AVAudioEngine()
    private var isRunning = false
    
    /// The input node for external access (e.g., for speech recognition)
    var inputNode: AVAudioInputNode? {
        return isRunning ? engine.inputNode : nil
    }
    
    /// The audio format of the input
    var inputFormat: AVAudioFormat? {
        return engine.inputNode.outputFormat(forBus: 0)
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Start capturing audio from the microphone
    func start() {
        guard !isRunning else {
            print("⚠️ Audio engine already running")
            return
        }
        
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Ensure we have a valid format
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            print("❌ Invalid audio format")
            return
        }
        
        // Install tap on input node to receive audio buffers
        // Buffer size of 1024 samples provides good balance between latency and CPU usage
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Calculate RMS level
            let rmsLevel = self.calculateRMS(buffer: buffer)
            
            // Notify delegate on main thread for UI updates
            DispatchQueue.main.async {
                self.delegate?.audioEngine(self, didUpdateRMSLevel: rmsLevel)
            }
            
            // Send buffer to delegate for speech recognition
            self.delegate?.audioEngine(self, didReceiveBuffer: buffer)
        }
        
        // Start the engine
        do {
            try engine.start()
            isRunning = true
            print("✅ Audio engine started")
        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    /// Stop capturing audio
    func stop() {
        guard isRunning else { return }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        
        print("✅ Audio engine stopped")
    }
    
    // MARK: - Private Methods
    
    /// Calculate the RMS (Root Mean Square) level of an audio buffer
    /// Returns a normalized value between 0.0 and 1.0
    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0 else {
            return 0.0
        }
        
        var sumOfSquares: Float = 0.0
        
        // Calculate sum of squares across all channels
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                let sample = samples[frame]
                sumOfSquares += sample * sample
            }
        }
        
        // Calculate RMS
        let meanOfSquares = sumOfSquares / Float(frameLength * channelCount)
        let rms = sqrt(meanOfSquares)
        
        // Convert to decibels and normalize to 0-1 range
        // Typical speech ranges from -60dB to 0dB
        let db = 20 * log10(max(rms, 0.000001))
        let normalizedLevel = (db + 60) / 60  // Map -60...0 dB to 0...1
        
        return max(0.0, min(1.0, normalizedLevel))
    }
}
