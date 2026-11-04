import AppKit

/// Counter in the segment font, for the corner of a waveform band. Leading zeros that carry no value are dimmed.
public final class CanonTimecode: NSView {
    private let font: NSFont
    private let haloColour: NSColor
    private var shape = ""
    private var blank = true
    private var text = ""
    private var dimmed = 0

    public override var isFlipped: Bool { true }

    /// The app registers fluoWrite; without it the counter falls back to monospaced digits.
    public init(size: CGFloat = 44, halo colour: NSColor = .delphiMuted) {
        font = NSFont(name: "fluoWrite-Regular", size: size) ?? .monospacedDigitSystemFont(ofSize: size * 0.85, weight: .semibold)
        haloColour = colour
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        show(nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the digits have no side bearing; kerning either side seats it in a slot a little wider than a colon's.
    private static let stopPadding = ((21.8 - 8.2) / 2 + 4) / 100

    /// Replaces minutes, seconds and hundredths, for SMPTE timecode. The segment font has digits, colon, full stop and hyphen only.
    public var format: ((Double) -> String)? {
        didSet { render(shape, blank: blank, force: true) }
    }

    private static func hundredths(_ seconds: Double) -> String {
        let hundredths = Int((max(0, seconds) * 100).rounded())
        return String(format: "%02d:%02d.%02d", min(99, hundredths / 6000), hundredths / 100 % 60, hundredths % 100)
    }

    public func show(_ seconds: Double?) {
        render((format ?? Self.hundredths)(seconds ?? 0), blank: seconds == nil)
    }

    /// A timecode already formatted; one without digits, or `nil`, shows hyphens in that shape.
    public func show(text: String?) {
        render(text ?? (shape.isEmpty ? Self.hundredths(0) : shape), blank: !(text ?? "").contains(where: \.isNumber))
    }

    private func render(_ shape: String, blank: Bool, force: Bool = false) {
        (self.shape, self.blank) = (shape, blank)
        // font lacks semicolon
        var next = shape.replacingOccurrences(of: ";", with: ".")
        var dim = next.count
        if blank {
            next = String(next.map { $0.isNumber ? "-" : $0 })
        } else {
            // zeros dim, four stay
            dim = max(0, min(next.count - 4, next.prefix { $0 == "0" || $0 == ":" || $0 == "." }.count))
        }
        guard force || next != text || dim != dimmed else { return }
        let widthChanged = next.count != text.count
        (text, dimmed) = (next, dim)
        setAccessibilityValue(blank ? nil : next)
        if widthChanged { invalidateIntrinsicContentSize() }
        needsDisplay = true
    }

    private func styled(_ attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let styled = NSMutableAttributedString(string: text, attributes: attributes)
        let pad = Self.stopPadding * font.pointSize
        for (index, character) in text.enumerated() where character == "." {
            if index > 0 { styled.addAttribute(.kern, value: pad, range: NSRange(location: index - 1, length: 1)) }
            styled.addAttribute(.kern, value: pad, range: NSRange(location: index, length: 1))
        }
        return styled
    }

    private static func glow(_ colour: NSColor, blur: CGFloat, offset: CGSize = .zero) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = colour
        shadow.shadowBlurRadius = blur
        shadow.shadowOffset = offset
        return shadow
    }

    public override var intrinsicContentSize: NSSize {
        let size = styled([.font: font]).size()
        return NSSize(width: ceil(size.width), height: ceil(size.height))
    }

    public override func draw(_ dirtyRect: NSRect) {
        let size = styled([.font: font]).size()
        let origin = CGPoint(x: bounds.maxX - size.width, y: (bounds.height - size.height) / 2)
        // halo: stroke only, flipped shadow offset points up
        styled([
            .font: font, .strokeColor: haloColour, .strokeWidth: 12, .foregroundColor: NSColor.clear,
            .shadow: Self.glow(haloColour, blur: 5, offset: CGSize(width: 0, height: -3)),
        ]).draw(at: origin)
        let front = styled([.font: font, .foregroundColor: NSColor.delphiPrimary, .shadow: Self.glow(.delphiPrimary.withAlphaComponent(0.55), blur: 7)])
        front.addAttribute(.foregroundColor, value: NSColor.delphiPrimary.withAlphaComponent(0.28), range: NSRange(location: 0, length: dimmed))
        front.draw(at: origin)
    }
}

/// Transport lamps: every icon is always present, lit while its state holds.
public final class CanonLamps: NSView {
    public enum Lamp {
        case play, pause, loop
        /// Lit in red.
        case record

        fileprivate var systemImage: String {
            switch self {
            case .play: "play.fill"
            case .pause: "pause.fill"
            case .loop: "repeat"
            case .record: "record.circle"
            }
        }

        fileprivate var colour: NSColor { self == .record ? .delphiDestructive : .delphiPrimary }
    }

    public static let transport: [Lamp] = [.play, .pause, .loop]
    private static let side: CGFloat = 20
    private static let spacing: CGFloat = 16
    private let lamps: [Lamp]
    private var lit: Set<Lamp> = []
    private var blinking: [Lamp: DispatchWorkItem] = [:]

    public override var isFlipped: Bool { true }

    public init(lamps: [Lamp] = transport) {
        self.lamps = lamps
        super.init(frame: .zero)
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: CGFloat(lamps.count) * Self.side + CGFloat(max(0, lamps.count - 1)) * Self.spacing, height: Self.side)
    }

    public func light(_ lit: Set<Lamp>) {
        guard lit != self.lit else { return }
        self.lit = lit
        needsDisplay = true
    }

    /// Seconds a lamp stays unlit when it blinks.
    public static let blink = 0.12

    /// Turns a lamp off for a split second, then back to its state.
    public func flash(_ lamp: Lamp) {
        guard lamps.contains(lamp) else { return }
        blinking[lamp]?.cancel()
        let relight = DispatchWorkItem { [weak self] in
            guard let self else { return }
            blinking[lamp] = nil
            needsDisplay = true
        }
        blinking[lamp] = relight
        needsDisplay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.blink, execute: relight)
    }

    public override func draw(_ dirtyRect: NSRect) {
        let y = (bounds.height - Self.side) / 2
        for (index, lamp) in lamps.enumerated() {
            let on = lit.contains(lamp) && blinking[lamp] == nil
            let colour = on ? lamp.colour : NSColor.delphiMutedForeground.withAlphaComponent(0.3)
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .bold).applying(.init(paletteColors: [colour]))
            guard let image = NSImage(systemSymbolName: lamp.systemImage, accessibilityDescription: nil)?.withSymbolConfiguration(config) else { continue }
            let slot = CGRect(x: CGFloat(index) * (Self.side + Self.spacing), y: y, width: Self.side, height: Self.side)
            let rect = CGRect(x: slot.midX - image.size.width / 2, y: slot.midY - image.size.height / 2, width: image.size.width, height: image.size.height)
            NSGraphicsContext.saveGraphicsState()
            if on {
                let shadow = NSShadow()
                shadow.shadowColor = lamp.colour.withAlphaComponent(0.6)
                shadow.shadowBlurRadius = 6
                shadow.set()
            }
            image.draw(in: rect)
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

/// What a readout band shows of a player.
public struct CanonTransport: Equatable {
    public var playhead: Double?
    public var playing = false
    /// Parked at `playhead`.
    public var paused = false
    /// Capturing, for a `.record` lamp.
    public var recording = false
    public var looping = false
    /// Count of wraps; a change blinks the loop lamp.
    public var loops = 0

    public init(playhead: Double? = nil, playing: Bool = false, paused: Bool = false, recording: Bool = false, looping: Bool = false, loops: Int = 0) {
        self.playhead = playhead
        self.playing = playing
        self.paused = paused
        self.recording = recording
        self.looping = looping
        self.loops = loops
    }
}

/// The picture of the whole file inside a readout band: a waveform, a filmstrip.
public protocol CanonReadoutStrip: NSView {
    var playhead: Double? { get set }
}

/// A strip of the whole file under a counter and transport lamps: the banner of a media tool.
public final class CanonReadoutBand<Strip: CanonReadoutStrip>: CanonView {
    public let strip: Strip
    private let timecode: CanonTimecode
    private let lamps: CanonLamps
    private var shownLoops = 0
    private var lit: Set<CanonLamps.Lamp>?

    public enum Readout {
        /// Counter and lamps sit over the strip's bottom corners: a waveform reads through them.
        case over
        /// Counter and lamps get a row of their own under the strip: a filmstrip's frames stay clear.
        case below
    }

    public static var readoutRow: CGFloat { 44 }
    public static func height(strip: CGFloat) -> CGFloat { strip + readoutRow }

    /// See `CanonTimecode.format`.
    public var format: ((Double) -> String)? {
        get { timecode.format }
        set { timecode.format = newValue }
    }

    /// - Parameter lamps: which lamps the band has; every one is always present.
    public init(_ strip: Strip, readout: Readout = .over, lamps set: [CanonLamps.Lamp] = CanonLamps.transport) {
        self.strip = strip
        timecode = CanonTimecode(size: readout == .over ? 44 : 30)
        lamps = CanonLamps(lamps: set)
        super.init(fill: .delphiMuted)
        for view in [strip, timecode, lamps] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        let padding = DelphiMetrics.panelPadding
        NSLayoutConstraint.activate([
            strip.topAnchor.constraint(equalTo: topAnchor),
            strip.leadingAnchor.constraint(equalTo: leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: bottomAnchor, constant: readout == .over ? 0 : -Self.readoutRow),
            timecode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            lamps.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
        ])
        if readout == .over {
            NSLayoutConstraint.activate([
                timecode.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
                lamps.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            ])
        } else {
            NSLayoutConstraint.activate([
                timecode.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -Self.readoutRow / 2),
                lamps.centerYAnchor.constraint(equalTo: timecode.centerYAnchor),
            ])
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === timecode || hit === lamps ? self : hit
    }

    /// Runs at the playback tick rate.
    /// - Parameter idle: seconds the counter shows without a playhead; `nil` shows dashes.
    public func show(_ transport: CanonTransport, idle: Double?) {
        strip.playhead = transport.playhead
        timecode.show(transport.playhead ?? idle)
        if transport.loops != shownLoops {
            shownLoops = transport.loops
            lamps.flash(.loop)
        }
        var lit: Set<CanonLamps.Lamp> = []
        if transport.playing { lit.insert(.play) }
        if transport.paused { lit.insert(.pause) }
        if transport.looping { lit.insert(.loop) }
        if transport.recording { lit.insert(.record) }
        guard lit != self.lit else { return }
        self.lit = lit
        lamps.light(lit)
        timecode.setAccessibilityLabel(String(localized: transport.playhead != nil ? "Position" : "Length"))
    }
}
