import UIKit

/// Counter in the segment font, for the corner of a waveform band. Leading zeros that carry no value are dimmed.
public final class CanonTimecode: UIView {
    private let digits = UILabel()
    // waveform runs under counter
    private let halo = UILabel()
    private let font: UIFont

    public init(size: CGFloat = 44, halo colour: UIColor = .delphiMuted) {
        // fallback: font not bundled
        let face = UIFont(name: "fluoWrite-Regular", size: size) ?? .monospacedDigitSystemFont(ofSize: size * 0.85, weight: .semibold)
        font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: face)
        super.init(frame: .zero)
        haloColour = colour
        for label in [halo, digits] {
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .right
            label.clipsToBounds = false
            pin(label)
        }
        isAccessibilityElement = true
        // shadows resolved at build
        registerForTraitChanges(UITraitCollection.delphiColourTraits) { (view: Self, _) in
            // same text skips render
            view.digits.attributedText = nil
            view.render(view.shape, blank: view.blank)
        }
        show(nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var haloColour = UIColor.delphiMuted
    private var shape = ""
    private var blank = true

    /// Glows drawn with the text: a layer shadow would be rasterised offscreen again on every change of the counter.
    private func glow(_ colour: UIColor, blur: CGFloat, offset: CGSize = .zero) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = colour.resolvedColor(with: traitCollection)
        shadow.shadowBlurRadius = blur
        shadow.shadowOffset = offset
        return shadow
    }

    /// FluoWrite's full stop is 8.2 units wide against the colon's 21.8, and the digits have no side bearing; kerning either side seats it in a slot a little wider than a colon's.
    private static let stopPadding = ((21.8 - 8.2) / 2 + 4) / 100

    private func styled(_ text: String, _ attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        let styled = NSMutableAttributedString(string: text, attributes: attributes)
        let pad = Self.stopPadding * font.pointSize
        for (index, character) in text.enumerated() where character == "." {
            if index > 0 { styled.addAttribute(.kern, value: pad, range: NSRange(location: index - 1, length: 1)) }
            styled.addAttribute(.kern, value: pad, range: NSRange(location: index, length: 1))
        }
        return styled
    }

    /// Replaces minutes, seconds and hundredths, for SMPTE timecode. The segment font has digits, colon, full stop and hyphen only.
    public var format: ((Double) -> String)? {
        didSet { digits.attributedText = nil }
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
        render(text ?? digits.attributedText?.string ?? Self.hundredths(0), blank: !(text ?? "").contains(where: \.isNumber))
    }

    private func render(_ shape: String, blank: Bool) {
        (self.shape, self.blank) = (shape, blank)
        // font lacks semicolon
        var text = shape.replacingOccurrences(of: ";", with: ".")
        var dimmed = text.count
        if blank {
            text = String(text.map { $0.isNumber ? "-" : $0 })
        } else {
            // zeros dim, four stay
            dimmed = max(0, min(text.count - 4, text.prefix { $0 == "0" || $0 == ":" || $0 == "." }.count))
        }
        // 30 hz: mostly unchanged
        guard text != digits.attributedText?.string else { return }
        let front = styled(text, [.font: font, .foregroundColor: UIColor.delphiPrimary, .shadow: glow(.delphiPrimary.withAlphaComponent(0.55), blur: 7)])
        front.addAttribute(.foregroundColor, value: UIColor.delphiPrimary.withAlphaComponent(0.28), range: NSRange(location: 0, length: dimmed))
        digits.attributedText = front
        // positive width: stroke only
        halo.attributedText = styled(text, [
            .font: font, .strokeColor: haloColour, .strokeWidth: 12, .foregroundColor: UIColor.clear,
            .shadow: glow(haloColour, blur: 5, offset: CGSize(width: 0, height: 3)),
        ])
        accessibilityValue = blank ? nil : text
    }
}

/// Transport lamps: every icon is always present, lit while its state holds.
public final class CanonLamps: UIView {

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

        fileprivate var colour: UIColor { self == .record ? .delphiDestructive : .delphiPrimary }
    }

    public static let transport: [Lamp] = [.play, .pause, .loop]
    private var views: [Lamp: UIImageView] = [:]

    public init(lamps: [Lamp] = transport) {
        super.init(frame: .zero)
        let row = UIStackView(arrangedSubviews: lamps.map { lamp in
            let view = UIImageView(image: UIImage(systemName: lamp.systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)))
            view.contentMode = .center
            view.layer.shadowOffset = .zero
            view.layer.shadowRadius = 6
            views[lamp] = view
            return view
        })
        row.spacing = 16
        pin(row)
        isAccessibilityElement = false
        light([])
        registerForTraitChanges(UITraitCollection.delphiColourTraits) { (view: Self, _) in view.paint() }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var lit: Set<Lamp> = []

    public func light(_ lit: Set<Lamp>) {
        self.lit = lit
        paint()
    }

    private func paint() {
        for (lamp, view) in views {
            let on = lit.contains(lamp) && blinking[lamp] == nil
            view.tintColor = on ? lamp.colour : .delphiMutedForeground.withAlphaComponent(0.3)
            // cgcolor ignores traits
            view.layer.shadowColor = lamp.colour.resolvedColor(with: traitCollection).cgColor
            view.layer.shadowOpacity = on ? 0.6 : 0
        }
    }

    /// Seconds a lamp stays unlit when it blinks.
    public static let blink = 0.12
    private var blinking: [Lamp: DispatchWorkItem] = [:]

    /// Turns a lamp off for a split second, then back to its state.
    public func flash(_ lamp: Lamp) {
        guard let view = views[lamp] else { return }
        blinking[lamp]?.cancel()
        view.tintColor = .delphiMutedForeground.withAlphaComponent(0.3)
        view.layer.shadowOpacity = 0
        let relight = DispatchWorkItem { [weak self] in
            guard let self else { return }
            blinking[lamp] = nil
            paint()
        }
        blinking[lamp] = relight
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.blink, execute: relight)
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
public protocol CanonReadoutStrip: UIView {
    var playhead: Double? { get set }
    /// Draws under the status bar and keeps its own content clear of it, as a feathered head does.
    static var runsUnderStatusBar: Bool { get }
}

extension CanonReadoutStrip {
    public static var runsUnderStatusBar: Bool { false }
}

/// A strip of the whole file under a counter and transport lamps: the banner of a media tool.
public final class CanonReadoutBand<Strip: CanonReadoutStrip>: UIView {
    public let strip: Strip
    private let timecode: CanonTimecode
    private let lamps: CanonLamps

    public enum Readout {
        /// Counter and lamps sit over the strip's bottom corners: a waveform reads through them.
        case over
        /// Counter and lamps get a row of their own under the strip: a filmstrip's frames stay clear.
        case below
    }

    /// Height of the row under the strip, and the band's height for a strip of a given height.
    public static var readoutRow: CGFloat { 44 }

    /// See `CanonTimecode.format`.
    public var format: ((Double) -> String)? {
        get { timecode.format }
        set { timecode.format = newValue }
    }
    public static func height(strip: CGFloat) -> CGFloat { strip + readoutRow }
    private var shownLoops = 0
    private var lit: Set<CanonLamps.Lamp>?

    /// - Parameter lamps: which lamps the band has; every one is always present.
    public init(_ strip: Strip, readout: Readout = .over, lamps set: [CanonLamps.Lamp] = CanonLamps.transport) {
        self.strip = strip
        timecode = CanonTimecode(size: readout == .over ? 44 : 30)
        lamps = CanonLamps(lamps: set)
        super.init(frame: .zero)
        backgroundColor = .delphiMuted
        // banner pattern shows through
        strip.backgroundColor = .clear
        strip.isOpaque = false
        for view in [strip, timecode, lamps] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        let padding = DelphiMetrics.panelPadding
        NSLayoutConstraint.activate([
            strip.topAnchor.constraint(equalTo: readout == .over && Strip.runsUnderStatusBar ? topAnchor : safeAreaLayoutGuide.topAnchor),
            strip.leadingAnchor.constraint(equalTo: leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: bottomAnchor, constant: readout == .over ? 0 : -Self.readoutRow),
            timecode.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            lamps.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: padding),
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
        [timecode, lamps].forEach { $0.isUserInteractionEnabled = false }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
        // playhead: playing or paused
        timecode.accessibilityLabel = String(localized: transport.playhead != nil ? "Position" : "Length")
    }
}
