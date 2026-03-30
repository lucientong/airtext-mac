import AppKit

/// Floating panel that displays recording status and transcription
/// Appears at the bottom center of the screen with elegant animations
final class FloatingPanel: NSPanel {
    
    // MARK: - Constants
    
    private let panelHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 28
    private let bottomMargin: CGFloat = 80
    
    // MARK: - Properties
    
    private let contentView_: FloatingContentView
    private let visualEffectView: NSVisualEffectView
    private var widthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    init() {
        contentView_ = FloatingContentView(frame: .zero)
        visualEffectView = NSVisualEffectView()
        
        let initialFrame = NSRect(x: 0, y: 0, width: 280, height: panelHeight)
        
        super.init(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupContent()
    }
    
    // MARK: - Setup
    
    private func setupPanel() {
        // Panel configuration
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Make it float above everything
        hidesOnDeactivate = false
    }
    
    private func setupContent() {
        // Setup visual effect view for blur background
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup content view
        contentView_.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.addSubview(visualEffectView)
        containerView.addSubview(contentView_)
        contentView = containerView
        
        // Setup constraints
        widthConstraint = visualEffectView.widthAnchor.constraint(equalToConstant: 280)
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            visualEffectView.heightAnchor.constraint(equalToConstant: panelHeight),
            widthConstraint,
            
            contentView_.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            contentView_.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            contentView_.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            contentView_.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func show() {
        // Position at bottom center of main screen
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let panelWidth = widthConstraint.constant
        let x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.minY + bottomMargin
        
        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        
        // Prepare for animation
        alphaValue = 0
        contentView?.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        
        // Show panel
        orderFrontRegardless()
        
        // Spring animation entrance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
            contentView?.layer?.transform = CATransform3DIdentity
        }
    }
    
    func hide() {
        contentView_.resetTextColor()
        
        // Exit animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
            contentView?.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1)
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.contentView?.layer?.transform = CATransform3DIdentity
        })
    }
    
    func updateText(_ text: String) {
        contentView_.updateText(text)
        
        // Update panel width
        let newWidth = contentView_.currentWidth
        updateWidth(newWidth)
    }
    
    func updateAudioLevel(_ level: Float) {
        contentView_.waveformView.updateLevel(level)
    }
    
    func showRefiningStatus() {
        contentView_.showRefiningStatus()
    }
    
    private func updateWidth(_ newWidth: CGFloat) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - newWidth / 2
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            widthConstraint.animator().constant = newWidth
            animator().setFrame(NSRect(x: x, y: frame.minY, width: newWidth, height: panelHeight), display: true)
        }
    }
    
    // MARK: - Overrides
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
