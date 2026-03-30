import AppKit

/// A view that displays an audio waveform with 5 animated bars
/// Driven by real-time RMS audio levels
final class WaveformView: NSView {
    
    // MARK: - Constants
    
    private let barCount = 5
    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 4
    private let barCornerRadius: CGFloat = 2
    private let minBarHeight: CGFloat = 4
    private let maxBarHeight: CGFloat = 28
    
    /// Weight distribution for bars (center-heavy)
    private let barWeights: [CGFloat] = [0.5, 0.8, 1.0, 0.75, 0.55]
    
    /// Envelope parameters
    private let attackRate: CGFloat = 0.4
    private let releaseRate: CGFloat = 0.15
    
    /// Random jitter range (±4%)
    private let jitterRange: CGFloat = 0.04
    
    // MARK: - Properties
    
    private var barLayers: [CAShapeLayer] = []
    private var smoothedLevels: [CGFloat] = []
    private var currentRMSLevel: CGFloat = 0
    private var targetRMSLevel: CGFloat = 0
    private var animationTimer: Timer?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = .clear
        smoothedLevels = Array(repeating: 0, count: barCount)
        createBarLayers()
        startAnimation()
    }
    
    private func createBarLayers() {
        barLayers.forEach { $0.removeFromSuperlayer() }
        barLayers.removeAll()
        
        for _ in 0..<barCount {
            let layer = CAShapeLayer()
            layer.fillColor = NSColor.waveformBar.cgColor
            self.layer?.addSublayer(layer)
            barLayers.append(layer)
        }
        updateBarPaths()
    }
    
    override func layout() {
        super.layout()
        updateBarPaths()
    }
    
    func updateLevel(_ level: Float) {
        targetRMSLevel = CGFloat(level)
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.animationTick()
        }
    }
    
    private func animationTick() {
        let isRising = targetRMSLevel > currentRMSLevel
        if isRising {
            currentRMSLevel = currentRMSLevel * (1 - attackRate) + targetRMSLevel * attackRate
        } else {
            currentRMSLevel = currentRMSLevel * (1 - releaseRate) + targetRMSLevel * releaseRate
        }
        
        for i in 0..<barCount {
            let jitter = 1.0 + CGFloat.random(in: -jitterRange...jitterRange)
            let targetLevel = currentRMSLevel * barWeights[i] * jitter
            
            if targetLevel > smoothedLevels[i] {
                smoothedLevels[i] = smoothedLevels[i] * (1 - attackRate) + targetLevel * attackRate
            } else {
                smoothedLevels[i] = smoothedLevels[i] * (1 - releaseRate) + targetLevel * releaseRate
            }
        }
        
        updateBarPaths()
    }
    
    private func updateBarPaths() {
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for (i, layer) in barLayers.enumerated() {
            let level = smoothedLevels[i]
            let height = minBarHeight + (maxBarHeight - minBarHeight) * min(1.0, level)
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let y = (bounds.height - height) / 2
            
            let path = NSBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: height),
                                    xRadius: barCornerRadius, yRadius: barCornerRadius)
            layer.path = path.cgPath
        }
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            case .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            @unknown default: break
            }
        }
        return path
    }
}
