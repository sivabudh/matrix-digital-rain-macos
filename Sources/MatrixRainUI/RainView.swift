import AppKit
import RainCore

/// Draws a domain scene; owns the clock and cached native image resources.
@MainActor
final class RainView: NSView {
    var onRightClick: (() -> Void)?
    private var scene: RainScene
    private let sprites: [[CGImage]]
    private var animationTimer: Timer?
    private var lastFrameTime = 0.0
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }
    override var mouseDownCanMoveWindow: Bool { (window as? RainWindow)?.mode.isLocked == false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    init(size: CGSize, seed: UInt64) {
        scene = RainScene(seed: seed).advanced(by: 0, viewport: size)
        sprites = Self.makeSprites()
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 12
    }
    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        guard mouseDownCanMoveWindow else { return }
        super.mouseDown(with: event)
    }
    override func rightMouseDown(with event: NSEvent) { onRightClick?() }

    func setAnimating(_ active: Bool) {
        guard active != (animationTimer != nil) else { return }
        animationTimer?.invalidate()
        animationTimer = nil
        guard active else { return }
        lastFrameTime = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1 / RainStyle.framesPerSecond, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advanceFrame() }
        }
        timer.tolerance = 0.004
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func advanceFrame() {
        let now = ProcessInfo.processInfo.systemUptime
        scene = scene.advanced(by: now - lastFrameTime, viewport: bounds.size)
        lastFrameTime = now
        needsDisplay = true
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed: 0, green: 0.012, blue: 0.004, alpha: 1).setFill()
        bounds.fill()
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let layout = RainLayout(viewport: bounds.size)
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: layout.scale, y: -layout.scale)
        defer { context.restoreGState() }
        for glyph in scene.glyphs(in: bounds.size) {
            let rect = CGRect(x: glyph.rect.minX,
                              y: layout.sceneSize.height - glyph.rect.maxY,
                              width: glyph.rect.width, height: glyph.rect.height)
            context.draw(sprites[glyph.brightness][glyph.character], in: rect)
        }
    }

    private static func makeSprites() -> [[CGImage]] {
        let font = NSFont(name: "HiraginoSans-W3", size: 17) ?? .monospacedSystemFont(ofSize: 17, weight: .regular)
        return (0..<12).map { brightness in
            let color: NSColor = brightness == 11
                ? NSColor(calibratedRed: 0.78, green: 1, blue: 0.85, alpha: 1)
                : NSColor(calibratedRed: 0.015, green: 0.12 + Double(brightness) * 0.075, blue: 0.1, alpha: 1)
            return RainStyle.alphabet.map { character in
                let image = NSImage(size: RainStyle.cell)
                image.lockFocusFlipped(false)
                (String(character) as NSString).draw(at: NSPoint(x: 0, y: 1),
                    withAttributes: [.font: font, .foregroundColor: color])
                image.unlockFocus()
                // A locally rasterized image always provides a CGImage.
                return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            }
        }
    }
}
