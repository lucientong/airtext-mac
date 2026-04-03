import AppKit

/// Content view for the floating panel
/// Contains waveform animation and transcription text
final class FloatingContentView: NSView {
    
    // MARK: - Constants
    
    private let waveformSize = NSSize(width: 44, height: 32)
    private let minTextWidth: CGFloat = 160
    private let maxTextWidth: CGFloat = 560
    private let horizontalPadding: CGFloat = 16
    private let spacing: CGFloat = 12
    
    // MARK: - Properties
    
    let waveformView: WaveformView
    private let textLabel: NSTextField
    private var textWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        waveformView = WaveformView(frame: .zero)
        textLabel = NSTextField(labelWithString: "")
        
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        waveformView = WaveformView(frame: .zero)
        textLabel = NSTextField(labelWithString: "")
        
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        wantsLayer = true
        
        // Setup waveform view
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)
        
        // Setup text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .systemFont(ofSize: 14, weight: .regular)
        textLabel.textColor = .transcriptionText
        textLabel.backgroundColor = .clear
        textLabel.isBezeled = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.maximumNumberOfLines = 1
        textLabel.cell?.truncatesLastVisibleLine = true
        addSubview(textLabel)
        
        // Setup constraints
        textWidthConstraint = textLabel.widthAnchor.constraint(equalToConstant: minTextWidth)
        
        NSLayoutConstraint.activate([
            waveformView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            waveformView.centerYAnchor.constraint(equalTo: centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: waveformSize.width),
            waveformView.heightAnchor.constraint(equalToConstant: waveformSize.height),
            
            textLabel.leadingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: spacing),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textWidthConstraint
        ])
    }
    
    // MARK: - Public Methods
    
    func updateText(_ text: String) {
        textLabel.stringValue = text
        updateTextWidth(for: text)
    }
    
    func showRefiningStatus() {
        textLabel.stringValue = "Refining..."
        textLabel.textColor = .secondaryText
    }
    
    func showDetectedLanguage(_ language: SpeechLanguage) {
        // Briefly flash the detected language name, then fade back
        let originalColor = textLabel.textColor
        textLabel.textColor = .systemGreen
        
        // After a short delay, restore the color
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.textLabel.textColor = originalColor
        }
        
        print("🌍 Floating panel: detected \(language.displayName)")
    }
    
    func resetTextColor() {
        textLabel.textColor = .transcriptionText
    }
    
    private func updateTextWidth(for text: String) {
        let attributes: [NSAttributedString.Key: Any] = [.font: textLabel.font!]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let targetWidth = min(maxTextWidth, max(minTextWidth, textSize.width + 20))
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            textWidthConstraint.animator().constant = targetWidth
        }
    }
    
    var currentWidth: CGFloat {
        return horizontalPadding * 2 + waveformSize.width + spacing + textWidthConstraint.constant
    }
}
