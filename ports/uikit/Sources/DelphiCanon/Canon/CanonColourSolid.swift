import DelphiCore
import MetalKit
import UIKit

/// A colour space drawn as a solid: drag to turn it, tap a face to pick the colour there. Sends `.valueChanged` on a pick.
///
/// The part of the solid between the picked colour and the viewer is cut away, so the pick sits on the corner where the
/// three cut faces meet and the faces show the colours around it. `marks` are further colours shown as small squares,
/// hollow where the solid hides them.
///
/// CMYK has four channels: black is depth. The CMY cube sits inside a wireframe of black's range, the outer cube at
/// 0 % and the inner at 100 %, and shrinks towards the inner one as black rises. Cyan, magenta and yellow slice it as
/// RGB's channels slice the RGB cube; black's slice is the cube itself at its size, shown with `showsWhole` while
/// black changes.
public final class CanonColourSolid: UIControl {

    /// Raw values are the shader's space numbers; `allCases` is the order a picker lists them in.
    public enum Space: Int, CaseIterable {
        /// A cube of red, green and blue.
        case rgb = 0
        /// A cube of hue, lightness and saturation, as Tilt Brush draws it.
        case hsl = 1
        /// A cylinder: hue around, saturation out, brightness up.
        case hsb = 2
        /// The sRGB gamut inside OKLab, in lightness, chroma and hue.
        case oklch = 3
        /// The same solid as `oklch`, in lightness, a and b.
        case oklab = 5
        /// The sRGB gamut inside CIELAB, in lightness, chroma and hue.
        case lch = 4
        /// The same solid as `lch`, in lightness, a and b.
        case lab = 6
        /// Cyan, magenta, yellow and black, drawn as a tesseract.
        case cmyk = 7

        public var name: String {
            switch self {
            case .rgb: "RGB"
            case .hsl: "HSL"
            case .hsb: "HSB"
            case .oklch: "OKLCH"
            case .oklab: "OKLab"
            case .lch: "LCH"
            case .lab: "Lab"
            case .cmyk: "CMYK"
            }
        }

        public struct Channel {
            public let name: String
            /// Slider range, in the channel's own units.
            public let range: ClosedRange<Double>
            /// Index into `point`.
            public let axis: Int
            /// Units per 1 of `point`.
            public let scale: Double
            public let decimals: Int
            /// Channel value at 0 of `point`.
            public var offset: Double = 0
            /// Second line under the name.
            public var detail: String? = nil

            public init(name: String, range: ClosedRange<Double>, axis: Int, scale: Double, decimals: Int, offset: Double = 0, detail: String? = nil) {
                self.name = name
                self.range = range
                self.axis = axis
                self.scale = scale
                self.decimals = decimals
                self.offset = offset
                self.detail = detail
            }
        }

        /// The channels in the order a tool lists them.
        public var channels: [Channel] {
            let hue = Channel(name: String(localized: "Hue"), range: 0...360, axis: 0, scale: 360, decimals: 0)
            // a green/pink, b blue/yellow
            func a(_ reach: Double, decimals: Int) -> Channel {
                Channel(name: String(localized: "Component A"), range: -reach...reach, axis: 0, scale: reach * 2, decimals: decimals, offset: -reach, detail: String(localized: "Pink-Green"))
            }
            func b(_ reach: Double, decimals: Int) -> Channel {
                Channel(name: String(localized: "Component B"), range: -reach...reach, axis: 2, scale: reach * 2, decimals: decimals, offset: -reach, detail: String(localized: "Blue-Yellow"))
            }
            return switch self {
            case .rgb: [
                Channel(name: String(localized: "Red"), range: 0...255, axis: 0, scale: 255, decimals: 0),
                Channel(name: String(localized: "Green"), range: 0...255, axis: 1, scale: 255, decimals: 0),
                Channel(name: String(localized: "Blue"), range: 0...255, axis: 2, scale: 255, decimals: 0),
            ]
            case .hsl: [
                hue,
                Channel(name: String(localized: "Saturation"), range: 0...100, axis: 2, scale: 100, decimals: 0),
                Channel(name: String(localized: "Lightness"), range: 0...100, axis: 1, scale: 100, decimals: 0),
            ]
            case .hsb: [
                hue,
                Channel(name: String(localized: "Saturation"), range: 0...100, axis: 1, scale: 100, decimals: 0),
                Channel(name: String(localized: "Brightness"), range: 0...100, axis: 2, scale: 100, decimals: 0),
            ]
            case .oklch: [
                Channel(name: String(localized: "Lightness"), range: 0...1, axis: 2, scale: 1, decimals: 2),
                Channel(name: String(localized: "Chroma"), range: 0...Geometry.oklabReach, axis: 1, scale: Geometry.oklabReach, decimals: 3),
                hue,
            ]
            case .oklab: [
                Channel(name: String(localized: "Lightness"), range: 0...1, axis: 1, scale: 1, decimals: 2),
                a(Geometry.oklabReach, decimals: 3),
                b(Geometry.oklabReach, decimals: 3),
            ]
            case .lab: [
                Channel(name: String(localized: "Lightness"), range: 0...100, axis: 1, scale: 100, decimals: 0),
                a(Geometry.labReach, decimals: 0),
                b(Geometry.labReach, decimals: 0),
            ]
            case .cmyk: [
                Channel(name: String(localized: "Cyan"), range: 0...100, axis: 0, scale: 100, decimals: 0),
                Channel(name: String(localized: "Magenta"), range: 0...100, axis: 1, scale: 100, decimals: 0),
                Channel(name: String(localized: "Yellow"), range: 0...100, axis: 2, scale: 100, decimals: 0),
                Channel(name: String(localized: "Black"), range: 0...100, axis: 3, scale: 100, decimals: 0),
            ]
            case .lch: [
                Channel(name: String(localized: "Lightness"), range: 0...100, axis: 2, scale: 100, decimals: 0),
                // srgb blue reaches 134
                Channel(name: String(localized: "Chroma"), range: 0...134, axis: 1, scale: Geometry.labReach, decimals: 0),
                hue,
            ]
            }
        }

        /// Channels run along the box's edges; the rest are hue, radius and height.
        public var isCartesian: Bool { self == .rgb || self == .hsl || self == .oklab || self == .lab || self == .cmyk }

        /// Largest distance of the solid from its centre.
        fileprivate var radius: Double {
            switch self {
            case .rgb, .hsl, .cmyk: 3.0.squareRoot()
            case .hsb: 2.0.squareRoot()
            case .oklch, .lch, .oklab, .lab: 1.25
            }
        }

        public func colour(at point: SIMD4<Double>) -> DelphiColour {
            let hue = (point.x - point.x.rounded(.down)) * 360
            return switch self {
            case .cmyk: DelphiColour(r: (1 - point.x) * (1 - point.w), g: (1 - point.y) * (1 - point.w), b: (1 - point.z) * (1 - point.w))
            case .rgb: DelphiColour(r: point.x, g: point.y, b: point.z)
            case .hsl: DelphiColour.fromHSL(h: hue, s: point.z * 100, l: point.y * 100)
            case .hsb: Self.fromHSB(h: hue, s: point.y, b: point.z)
            case .oklch: DelphiColour.fromOKLCH(l: point.z, c: point.y * Geometry.oklabReach, h: hue)
            case .lch: DelphiColour.fromLCH(l: point.z * 100, c: point.y * Geometry.labReach, h: hue)
            case .oklab: DelphiColour.fromOKLAB(l: point.y, a: (point.x * 2 - 1) * Geometry.oklabReach, b: (point.z * 2 - 1) * Geometry.oklabReach)
            case .lab: DelphiColour.fromLAB(l: point.y * 100, a: (point.x * 2 - 1) * Geometry.labReach, b: (point.z * 2 - 1) * Geometry.labReach)
            }
        }

        /// CMYK is the naive conversion: black takes the darkest channel, no ink limit or profile.
        public func point(for colour: DelphiColour) -> SIMD4<Double> {
            let rgb = SIMD3(colour.r, colour.g, colour.b).clamped(lowerBound: .zero, upperBound: .one)
            switch self {
            case .cmyk:
                let black = 1 - rgb.max()
                return black < 1 ? SIMD4((1 - rgb - black) / (1 - black), black) : [0, 0, 0, 1]
            case .rgb:
                return SIMD4(rgb, 0)
            case .hsl:
                let hsl = colour.hsl
                return [hsl.h / 360, hsl.l / 100, hsl.s / 100, 0]
            case .hsb:
                let top = rgb.max()
                return [colour.hsl.h / 360, top > 0 ? (top - rgb.min()) / top : 0, top, 0]
            case .oklch:
                let lch = colour.oklch
                return [lch.h / 360, lch.c / Geometry.oklabReach, lch.l, 0]
            case .lch:
                let lch = colour.lch
                return [lch.h / 360, lch.c / Geometry.labReach, lch.l / 100, 0]
            case .oklab:
                let lab = colour.oklab
                return [(lab.a / Geometry.oklabReach + 1) / 2, lab.l, (lab.b / Geometry.oklabReach + 1) / 2, 0]
            case .lab:
                let lab = colour.lab
                return [(lab.a / Geometry.labReach + 1) / 2, lab.l / 100, (lab.b / Geometry.labReach + 1) / 2, 0]
            }
        }

        private static func fromHSB(h: Double, s: Double, b: Double) -> DelphiColour {
            let hue = Geometry.hueRGB(h / 360)
            let rgb = b * (1 - s + s * hue)
            return DelphiColour(r: rgb.x, g: rgb.y, b: rgb.z)
        }
    }

    public var space: Space {
        didSet {
            guard space != oldValue else { return }
            stopUnroll()
            // ease: per-space units
            pointLink?.invalidate()
            pointLink = nil
            point = space.point(for: oldValue.colour(at: point))
            markPoints = marks.map(space.point(for:))
            if space != .cmyk { tesseract.path = nil }
            // turn lands new size
            if !isOrtho { aimTo?.fit = space.radius }
            freeAim?.fit = space.radius
            if isOrtho { reaim() } else { fitRadius = space.radius }
            redraw()
        }
    }

    /// The picked colour's channels, each 0...1 (chroma may pass 1). Order: RGB r g b; HSL h l s; Lab and OKLab a L b;
    /// CMYK c m y k; the rest hue, radius, height. Only CMYK uses `w`.
    public var point: SIMD4<Double> {
        didSet {
            guard point != oldValue else { return }
            shown = point
            followLeaf()
            redraw()
        }
    }

    /// Sets `point`; animated, the drawing eases to it, as a slider's fill does after a tap on its track.
    public func setPoint(_ next: SIMD4<Double>, animated: Bool) {
        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            stopEase()
            return point = next
        }
        pointFrom = shown
        pointProgress = 0
        pointTime = CACurrentMediaTime()
        point = next
        shown = pointFrom
        guard pointLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(pointEased))
        link.add(to: .main, forMode: .common)
        pointLink = link
    }

    public static let pointEase = 0.25
    /// The point as drawn; trails `point` while easing.
    private var shown: SIMD4<Double>
    private var pointFrom = SIMD4<Double>.zero
    private var pointProgress = 1.0
    private var pointLink: CADisplayLink?
    private var pointTime: CFTimeInterval = 0

    private func stopEase() {
        pointLink?.invalidate()
        pointLink = nil
    }

    @objc private func pointEased(_ link: CADisplayLink) {
        pointProgress = min(1, pointProgress + (link.targetTimestamp - pointTime) / Self.pointEase)
        pointTime = link.targetTimestamp
        let eased = 1 - pow(1 - pointProgress, 3)
        var delta = point - pointFrom
        // hue: shortest way
        if !space.isCartesian { delta.x -= delta.x.rounded() }
        shown = pointFrom + delta * eased
        followLeaf()
        if pointProgress >= 1 {
            shown = point
            pointLink?.invalidate()
            pointLink = nil
        }
        redraw()
    }

    public var colour: DelphiColour {
        get { space.colour(at: point) }
        set { point = space.point(for: newValue) }
    }

    /// Every drawn colour, markers included, goes through this matrix on its sRGB values, rows on (r, g, b), then clamps:
    /// a colour vision simulation. Identity draws true colours; `colour` and `point` are never changed by it.
    public private(set) var vision = matrix_identity_double3x3
    private var shownVision = matrix_identity_double3x3
    private var visionFrom = matrix_identity_double3x3
    private var visionProgress = 1.0
    private var visionLink: CADisplayLink?
    private var visionClock: CFTimeInterval = 0
    /// Seconds to ease from one vision matrix to the next.
    public static let visionEase = 0.35

    public func setVision(_ matrix: simd_double3x3, animated: Bool) {
        guard matrix != vision else { return }
        vision = matrix
        guard animated, !UIAccessibility.isReduceMotionEnabled, window != nil else {
            visionLink?.invalidate()
            visionLink = nil
            shownVision = matrix
            return redraw()
        }
        visionFrom = shownVision
        visionProgress = 0
        visionClock = CACurrentMediaTime()
        guard visionLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(visionEased))
        link.add(to: .main, forMode: .common)
        visionLink = link
    }

    @objc private func visionEased(_ link: CADisplayLink) {
        visionProgress = min(1, visionProgress + (link.targetTimestamp - visionClock) / Self.visionEase)
        visionClock = link.targetTimestamp
        let eased = visionProgress * visionProgress * (3 - 2 * visionProgress)
        shownVision = visionFrom + (vision - visionFrom) * eased
        if visionProgress >= 1 {
            shownVision = vision
            visionLink?.invalidate()
            visionLink = nil
        }
        redraw()
    }

    /// `colour` as `vision` draws it.
    private func seen(_ colour: DelphiColour) -> DelphiColour {
        let rgb = (shownVision * SIMD3(colour.r, colour.g, colour.b).clamped(lowerBound: .zero, upperBound: .one))
            .clamped(lowerBound: .zero, upperBound: .one)
        return DelphiColour(r: rgb.x, g: rgb.y, b: rgb.z)
    }

    public var marks: [DelphiColour] = [] {
        didSet {
            while markViews.count < marks.count {
                let view = Marker(side: 10)
                insertSubview(view, belowSubview: pickMarker)
                markViews.append(view)
            }
            markViews.enumerated().forEach { $1.isHidden = $0 >= marks.count }
            markPoints = marks.map(space.point(for:))
            setNeedsLayout()
        }
    }

    private var markPoints: [SIMD4<Double>] = []

    public var cutsAway = true {
        didSet { if cutsAway != oldValue { redraw() } }
    }

    /// Index into `point` of the channel to slice along, 0...2. The solid then draws faint, the slice through the pick
    /// opaque, and a tap or a drag picks on the slice; nothing is cut away. CMYK's black has no slice: see `showsWhole`.
    public var sliceAxis: Int? {
        didSet {
            guard sliceAxis != oldValue else { return }
            precondition(sliceAxis.map { (0...2).contains($0) } ?? true, "slice axes are 0...2")
            if let previous = oldValue, sliceAxis != nil, !UIAccessibility.isReduceMotionEnabled {
                turnSlice(from: previous)
            }
            if isOrtho { setUnroll(0) { [weak self] in self?.reaim() } }
            redraw()
        }
    }

    /// Seconds for a new slice to grow out of the pick while the old one shrinks into it.
    public static let sliceTurn = 0.4

    private var oldSlice: Int?
    private var sliceProgress = 1.0
    private var sliceLink: CADisplayLink?
    private var sliceTime: CFTimeInterval = 0

    private func turnSlice(from previous: Int) {
        oldSlice = previous
        sliceProgress = 0
        sliceTime = CACurrentMediaTime()
        guard sliceLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(sliceTurned))
        link.add(to: .main, forMode: .common)
        sliceLink = link
    }

    @objc private func sliceTurned(_ link: CADisplayLink) {
        sliceProgress = min(1, sliceProgress + (link.targetTimestamp - sliceTime) / Self.sliceTurn)
        sliceTime = link.targetTimestamp
        if sliceProgress >= 1 {
            oldSlice = nil
            sliceLink?.invalidate()
            sliceLink = nil
        }
        redraw()
    }

    /// How far the new slice reaches from the pick, and the old one, while they swap.
    private var sliceReaches: (new: Double, old: Double) {
        guard let oldSlice, let sliceAxis else { return (1e6, 0) }
        let eased = sliceProgress * sliceProgress * (3 - 2 * sliceProgress)
        return (extent(of: sliceAxis) * eased, extent(of: oldSlice) * (1 - eased))
    }

    /// Distance from the pick to the slice's farthest point, so both slices of a swap change over its whole length.
    private func extent(of axis: Int) -> Double {
        let geometry = geometry
        var reach = geometry.size + abs(geometry.display(geometry.pick))
        // plane: fixed axis
        if space.isCartesian { reach[axis] = 0 }
        return simd_length(reach)
    }

    /// Turn about the vertical axis and tilt towards the viewer, in radians.
    public var yaw = 0.62
    public var pitch = 0.42

    /// Turns the slice to face the viewer and flattens the view, so a drag on the slice moves the pick as on a 2D
    /// picker; the solid around it fades out. A chroma or saturation shell turns side-on at the pick's hue, then unrolls
    /// into a flat sheet, keeping its lengths. False rolls it back up, then turns back to where the view was.
    public var isOrtho = false {
        didSet {
            guard isOrtho != oldValue else { return }
            if isOrtho {
                freeAim = currentAim
                reaim()
                fadeGhost()
            } else {
                setUnroll(0) { [weak self] in
                    self?.reaim()
                    self?.fadeGhost()
                }
            }
        }
    }

    /// Seconds for a shell to unroll or roll up.
    public static let unrollTime = 0.6
    /// 0 rolled, 1 flat, linear in time; `flatness` eases it.
    private var unroll = 0.0
    private var unrollTarget = 0.0
    private var unrollLink: CADisplayLink?
    private var unrollClock: CFTimeInterval = 0
    private var afterUnroll: (() -> Void)?

    private var wantsUnroll: Bool { isOrtho && sliceAxis == 1 && !space.isCartesian }
    private var flatness: Double { unroll * unroll * (3 - 2 * unroll) }

    /// The unrolling shell, nil while rolled; faces the hue the camera looks at.
    private var sheet: Sheet? {
        flatness > 0 ? Sheet(radius: shown.y, facing: .pi / 2 - yaw, bend: 1 - flatness) : nil
    }

    private func setUnroll(_ target: Double, then done: (() -> Void)? = nil) {
        unrollTarget = target
        afterUnroll = done
        guard unroll != target, !UIAccessibility.isReduceMotionEnabled, window != nil else {
            unroll = target
            return finishUnroll()
        }
        unrollClock = CACurrentMediaTime()
        guard unrollLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(unrolled))
        link.add(to: .main, forMode: .common)
        unrollLink = link
    }

    @objc private func unrolled(_ link: CADisplayLink) {
        let step = (link.targetTimestamp - unrollClock) / Self.unrollTime
        unrollClock = link.targetTimestamp
        unroll = unroll < unrollTarget ? min(unroll + step, unrollTarget) : max(unroll - step, unrollTarget)
        if unroll == unrollTarget { finishUnroll() } else { redraw() }
    }

    private func finishUnroll() {
        unrollLink?.invalidate()
        unrollLink = nil
        redraw()
        let done = afterUnroll
        afterUnroll = nil
        done?()
    }

    /// Flat at once, for a space change; a pending turn still runs.
    private func stopUnroll() {
        unrollTarget = 0
        unroll = 0
        finishUnroll()
    }

    /// Seconds for the turn into and out of `isOrtho`.
    public static let orthoTurn = 0.55
    /// Camera distance in box units; far enough in `isOrtho` that the perspective no longer shows.
    public static let distances = (free: 6.0, ortho: 80.0)

    private struct Aim {
        public var yaw, pitch, distance, fit: Double
        public var lookAt: SIMD3<Double>
    }

    private var distance = distances.free
    private lazy var fitRadius = space.radius
    private var lookAt = SIMD3<Double>.zero
    private var freeAim: Aim?
    private var aimFrom: Aim?
    private var aimTo: Aim?
    private var aimProgress = 1.0
    private var aimLink: CADisplayLink?
    private var aimTime: CFTimeInterval = 0

    private var currentAim: Aim {
        Aim(yaw: yaw, pitch: pitch, distance: distance, fit: fitRadius, lookAt: lookAt)
    }

    private func reaim() {
        var target: Aim
        if isOrtho, let axis = sliceAxis {
            target = orthoAim(for: axis)
        } else {
            target = freeAim ?? currentAim
            target.distance = Self.distances.free
            target.fit = space.radius
            target.lookAt = .zero
            if !isOrtho { freeAim = nil }
        }
        // shortest turn
        target.yaw += 2 * .pi * ((yaw - target.yaw) / (2 * .pi)).rounded()
        stopSpin()
        guard !UIAccessibility.isReduceMotionEnabled, window != nil else {
            apply(target)
            if wantsUnroll { setUnroll(1) }
            return
        }
        aimFrom = currentAim
        aimTo = target
        aimProgress = 0
        aimTime = CACurrentMediaTime()
        guard aimLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(aimed))
        link.add(to: .main, forMode: .common)
        aimLink = link
    }

    /// Faces the slice through the pick from the side the view is already on, so the turn never passes edge on:
    /// a plane head on, the hue leaf square to it, the height disc from above or below, the shell from outside at the
    /// pick's hue.
    private func orthoAim(for axis: Int) -> Aim {
        // outer cube during black
        let size = showsWhole ? 1 : geometry.size
        func aim(_ yaws: [Double], _ pitch: Double, fit: Double, lookAt: SIMD3<Double> = .zero) -> Aim {
            let nearest = yaws.min { a, b in
                abs(remainder(a - yaw, 2 * .pi)) < abs(remainder(b - yaw, 2 * .pi))
            } ?? yaw
            return Aim(yaw: nearest, pitch: pitch, distance: Self.distances.ortho, fit: fit, lookAt: lookAt)
        }
        let overhead = pitch >= 0 ? Double.pi / 2 : -.pi / 2
        if space.isCartesian {
            return switch axis {
            case 0: aim([-.pi / 2, .pi / 2], 0, fit: size)
            case 1: aim([yaw], overhead, fit: size)
            default: aim([0, .pi], 0, fit: size)
            }
        }
        let angle = shown.x * 2 * .pi
        return switch axis {
        case 0: aim([-angle, .pi - angle], 0, fit: 1, lookAt: SIMD3(cos(angle), 0, sin(angle)) * 0.5)
        case 1: aim([.pi / 2 - angle], 0, fit: 1)
        default: aim([yaw], overhead, fit: 1)
        }
    }

    /// In `isOrtho` a hue leaf turns with the hue, so it keeps facing the viewer.
    private func followLeaf() {
        guard isOrtho, sliceAxis == 0, !space.isCartesian else { return }
        let target = orthoAim(for: 0)
        if aimLink != nil { aimTo = target } else { apply(target) }
    }

    private func apply(_ aim: Aim) {
        (yaw, pitch, distance, fitRadius, lookAt) = (aim.yaw, aim.pitch, aim.distance, aim.fit, aim.lookAt)
        redraw()
    }

    @objc private func aimed(_ link: CADisplayLink) {
        guard let from = aimFrom, let to = aimTo else { return }
        aimProgress = min(1, aimProgress + (link.targetTimestamp - aimTime) / Self.orthoTurn)
        aimTime = link.targetTimestamp
        let e = aimProgress * aimProgress * (3 - 2 * aimProgress)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        // log mix: even dolly
        let distance = exp(mix(log(from.distance), log(to.distance)))
        apply(Aim(yaw: mix(from.yaw, to.yaw), pitch: mix(from.pitch, to.pitch), distance: distance,
                  fit: mix(from.fit, to.fit), lookAt: from.lookAt + (to.lookAt - from.lookAt) * e))
        if aimProgress >= 1 {
            aimLink?.invalidate()
            aimLink = nil
            aimTo = nil
            if wantsUnroll { setUnroll(1) }
        }
    }

    public static let pitchLimit = 1.45
    /// Radians per point of drag.
    public static let turnRate = 0.009
    /// Share of the fling speed kept after one second.
    public static let flingKeep = 0.02
    /// Share of the dark side's brightness taken away by the light.
    public static let shading: Float = 0.16
    /// Opacity of the solid around a slice.
    public static let ghostOpacity: Float = 0.16
    /// Seconds for the solid around a slice to fade to opaque and back.
    public static let wholeFade = 0.2

    /// Fades the solid around a slice to opaque, so the whole solid shows, and back when false. The slice itself stays:
    /// for a drag that changes the solid rather than the slice, as CMYK's black does.
    public var showsWhole = false {
        didSet {
            guard showsWhole != oldValue else { return }
            fadeGhost()
            showTesseract()
            // frame the largest cube
            if isOrtho { reaim() }
        }
    }

    private var ghost = Double(ghostOpacity)
    private var fadeLink: CADisplayLink?
    private var fadeTime: CFTimeInterval = 0

    private let metal = MTKView()
    private let renderer: Renderer?
    private let pickMarker = Marker(side: 18)
    private var markViews: [Marker] = []
    private var axisLabels: [UILabel] = []
    private let tesseract = CAShapeLayer()
    private var spin = SIMD2<Double>.zero
    private var spinLink: CADisplayLink?
    private var spinTime: CFTimeInterval = 0
    private var dragsPick = false

    public init(space: Space = .hsl, colour: DelphiColour = DelphiColour(r: 0.12, g: 0.4, b: 0.15)) {
        self.space = space
        point = space.point(for: colour)
        shown = point
        renderer = Renderer.make()
        super.init(frame: .zero)

        metal.device = renderer?.device
        metal.colorPixelFormat = .bgra8Unorm
        metal.isOpaque = false
        metal.backgroundColor = .clear
        metal.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metal.enableSetNeedsDisplay = true
        metal.isPaused = true
        metal.isUserInteractionEnabled = false
        (metal.layer as? CAMetalLayer)?.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        renderer?.draw = { [unowned self] view in uniforms(size: view.drawableSize) }
        metal.delegate = renderer
        pin(metal)

        tesseract.fillColor = nil
        tesseract.lineWidth = DelphiMetrics.hairline
        tesseract.opacity = 0
        layer.addSublayer(tesseract)
        for _ in 0..<4 {
            let label = UILabel.canon(nil, .caption2, weight: .semibold, colour: .delphiMutedForeground)
            label.font = .delphiMono(11, relativeTo: .caption2)
            label.isAccessibilityElement = false
            addSubview(label)
            axisLabels.append(label)
        }
        // k fades with wireframe
        axisLabels[3].alpha = 0
        addSubview(pickMarker)

        let pan = CanonGrabPan(target: self, action: #selector(dragged(_:)))
        pan.grabs = { [unowned self] in nearPick($0) || (sheet == nil ? hit(at: $0) : pickHit(at: $0)) != nil }
        addGestureRecognizer(pan)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))

        isAccessibilityElement = true
        redrawsOnStyleChange(layout: true)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var accessibilityLabel: String? {
        get { space.name }
        set {}
    }

    public override var accessibilityValue: String? {
        get { "\(ColourNames.closest(colour)), \(colour.hex)" }
        set {}
    }

    private var drawnSize = CGSize.zero

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != drawnSize {
            drawnSize = bounds.size
            metal.setNeedsDisplay()
        }
        placeOverlays()
    }

    // coalesced overlay pass
    private func redraw() {
        metal.setNeedsDisplay()
        setNeedsLayout()
    }

    private struct Camera {
        public let position, right, up, forward: SIMD3<Double>
        public let tan: SIMD2<Double>
    }

    private var camera: Camera { camera(for: bounds.size) }

    private func camera(for size: CGSize) -> Camera {
        let forward = -SIMD3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
        let position = lookAt - distance * forward
        // yaw-based: valid overhead
        let right = SIMD3(cos(yaw), 0, -sin(yaw))
        let up = simd_cross(right, forward)
        let radius = fitRadius
        // sphere fits short side
        let fit = radius * 1.1 / (distance * distance - radius * radius).squareRoot()
        let aspect = size.height > 0 ? Double(size.width / size.height) : 1
        var tan = aspect < 1 ? SIMD2(fit, fit / aspect) : SIMD2(fit * aspect, fit)
        if flatness > 0 {
            // unrolled: half-width pi r
            let halfWidth = 1 + (max(1, .pi * shown.y) - 1) * flatness
            let need = SIMD2(halfWidth, 1) * 1.1 / distance
            tan *= max(1, need.x / tan.x, need.y / tan.y)
        }
        return Camera(position: position, right: right, up: up, forward: forward, tan: tan)
    }

    private var cut: SIMD4<Double> {
        let camera = camera.position
        guard cutsAway, sliceAxis == nil else { return .zero }
        if space.isCartesian {
            return SIMD4(camera.x >= 0 ? 1 : -1, camera.y >= 0 ? 1 : -1, camera.z >= 0 ? 1 : -1, 1)
        }
        var towards = atan2(camera.z, camera.x) / (2 * .pi) - shown.x
        towards -= towards.rounded()
        return SIMD4(towards >= 0 ? 1 : -1, 0, camera.y >= 0 ? 1 : -1, 1)
    }

    private func project(_ p: SIMD3<Double>) -> CGPoint? {
        let camera = camera
        let offset = p - camera.position
        let depth = simd_dot(offset, camera.forward)
        guard depth > 0 else { return nil }
        let x = simd_dot(offset, camera.right) / (depth * camera.tan.x)
        let y = simd_dot(offset, camera.up) / (depth * camera.tan.y)
        return CGPoint(x: (x + 1) / 2 * bounds.width, y: (1 - y) / 2 * bounds.height)
    }

    private func ray(through point: CGPoint) -> SIMD3<Double> {
        let camera = camera
        let x = Double(point.x / max(bounds.width, 1)) * 2 - 1
        let y = 1 - Double(point.y / max(bounds.height, 1)) * 2
        return simd_normalize(camera.forward + x * camera.tan.x * camera.right + y * camera.tan.y * camera.up)
    }

    private func hit(at point: CGPoint) -> SIMD3<Double>? {
        let origin = camera.position
        let ray = ray(through: point)
        return Geometry.march(origin: origin, ray: ray, geometry: geometry).map { origin + ray * $0 }
    }

    private var geometry: Geometry {
        Geometry(space: space, pick: SIMD3(shown.x, shown.y, shown.z), cut: cut, slice: sliceAxis, black: space == .cmyk ? shown.w : 0)
    }

    /// Where a touch meets the slice, or the solid when nothing is sliced.
    private func pickHit(at location: CGPoint) -> SIMD3<Double>? {
        guard sliceAxis != nil else { return hit(at: location) }
        let origin = camera.position
        let ray = ray(through: location)
        if let sheet {
            let geometry = geometry
            return sheet.shellPoints(origin: origin, ray: ray).first { geometry.shape($0) <= 1e-4 }
        }
        return geometry.sliceHit(origin: origin, ray: ray).map { origin + ray * $0 }
    }

    private func uniforms(size: CGSize) -> Renderer.Uniforms {
        let camera = camera(for: size)
        func four(_ v: SIMD3<Double>, _ w: Double = 0) -> SIMD4<Float> { SIMD4(Float(v.x), Float(v.y), Float(v.z), Float(w)) }
        let geometry = geometry
        let reaches = sliceReaches
        return Renderer.Uniforms(
            camera: four(camera.position), right: four(camera.right, camera.tan.x), up: four(camera.up, camera.tan.y),
            forward: four(camera.forward), pick: four(geometry.pick, geometry.black), cut: SIMD4<Float>(geometry.cut),
            params: SIMD4(Float(space.rawValue), Self.shading, Float(size.width), Float(size.height)),
            slice: SIMD4(Float(sliceAxis ?? -1), Float(ghost), Float(geometry.size), Float(flatness)),
            turn: SIMD4(Float(oldSlice ?? -1), Float(reaches.new), Float(reaches.old), Float(.pi / 2 - yaw)),
            centre: four(geometry.display(geometry.pick)),
            vision0: four(shownVision.transpose.columns.0), vision1: four(shownVision.transpose.columns.1),
            vision2: four(shownVision.transpose.columns.2)
        )
    }

    private func placeOverlays() {
        guard bounds.width > 0 else { return }
        let geometry = geometry
        let origin = camera.position
        let sheet = sheet
        func place(_ marker: Marker, at channels: SIMD4<Double>, colour: DelphiColour) {
            if let sheet {
                let placed = sheet.place(turn: remainder(channels.x * 2 * .pi - sheet.facing, 2 * .pi), y: channels.z * 2 - 1)
                guard let centre = project(placed.point) else { return marker.isHidden = true }
                marker.center = centre
                return marker.show(seen(colour), hidden: placed.far)
            }
            let box = SIMD3(channels.x, channels.y, channels.z)
            let p = Geometry(space: space, pick: box, cut: .zero, black: space == .cmyk ? channels.w : 0).display(box)
            guard let centre = project(p) else { return marker.isHidden = true }
            marker.center = centre
            // hollow when occluded
            let toward = p - origin
            let ray = simd_normalize(toward)
            let front = sliceAxis == nil || showsWhole ? Geometry.march(origin: origin, ray: ray, geometry: geometry) : geometry.sliceHit(origin: origin, ray: ray)
            let hidden = front.map { $0 < simd_length(toward) - 0.08 } ?? false
            marker.show(seen(colour), hidden: hidden)
        }
        pickMarker.isHidden = false
        place(pickMarker, at: shown, colour: space.colour(at: shown))
        for (view, (mark, point)) in zip(markViews, zip(marks, markPoints)) {
            view.isHidden = false
            place(view, at: point, colour: mark)
        }
        let anchors = axisAnchors(geometry)
        for (label, (letter, anchor)) in zip(axisLabels, anchors) {
            if label.text != letter {
                label.text = letter
                label.sizeToFit()
            }
            if let centre = project(anchor) { label.center = centre }
        }
        axisLabels.enumerated().forEach { $1.isHidden = $0 >= anchors.count || sheet != nil }
        drawTesseract()
    }

    /// Letters beside the solid, at points in its box.
    private func axisAnchors(_ geometry: Geometry) -> [(String, SIMD3<Double>)] {
        let edge = -geometry.size
        let reach = geometry.size + 0.22
        return switch space {
        case .rgb: [("R", [reach, edge, edge]), ("G", [edge, reach, edge]), ("B", [edge, edge, reach])]
        case .hsl: [("H", [reach, edge, edge]), ("L", [edge, reach, edge]), ("S", [edge, edge, reach])]
        case .hsb: [("B", [0, reach, 0]), ("S", [reach, 1, 0])]
        case .oklch, .lch: [("L", [0, reach, 0]), ("C", [reach, 0, 0])]
        case .oklab, .lab: [("L", [0, reach, 0]), ("a", [reach, 0, 0]), ("b", [0, 0, reach])]
        case .cmyk:
            // k by corner diagonal
            [("C", [reach, edge, edge]), ("M", [edge, reach, edge]), ("Y", [edge, edge, reach]),
             ("K", SIMD3(repeating: (1 + Geometry.innerSize) / 2 + 0.1))]
        }
    }

    /// Outer cube at 0 % black, inner cube at 100 %, and the edges joining their corners.
    private func drawTesseract() {
        // idle while hidden
        guard space == .cmyk, showsWhole || (tesseract.presentation()?.opacity ?? tesseract.opacity) > 0 else { return }
        let corners = (0..<8).map { SIMD3<Double>($0 & 1 == 0 ? -1 : 1, $0 & 2 == 0 ? -1 : 1, $0 & 4 == 0 ? -1 : 1) }
        let path = UIBezierPath()
        func line(_ a: SIMD3<Double>, _ b: SIMD3<Double>) {
            guard let from = project(a), let to = project(b) else { return }
            path.move(to: from)
            path.addLine(to: to)
        }
        for size in [1, Geometry.innerSize] {
            for a in 0..<8 {
                for bit in [1, 2, 4] where a & bit == 0 { line(corners[a] * size, corners[a | bit] * size) }
            }
        }
        for corner in corners { line(corner, corner * Geometry.innerSize) }
        // no implicit animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tesseract.frame = bounds
        tesseract.path = path.cgPath
        CATransaction.commit()
        tesseract.strokeColor = UIColor.delphiForeground.resolvedColor(with: traitCollection).withAlphaComponent(0.3).cgColor
    }

    private func nearPick(_ location: CGPoint) -> Bool {
        let centre = pickMarker.center
        return hypot(location.x - centre.x, location.y - centre.y) < 26
    }

    private let tick = UISelectionFeedbackGenerator()

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        if pick(at: recognizer.location(in: self)) { tick.selectionChanged() }
    }

    @discardableResult
    private func pick(at location: CGPoint) -> Bool {
        guard let p = pickHit(at: location) else { return false }
        var channels = geometry.channels(p)
        if space.isCartesian { channels = channels.clamped(lowerBound: .zero, upperBound: .one) }
        stopEase()
        var next = SIMD4(channels, point.w)
        // slice axis fixed
        if let sliceAxis { next[sliceAxis] = point[sliceAxis] }
        point = next
        sendActions(for: .valueChanged)
        return true
    }

    @objc private func dragged(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            stopSpin()
            // ortho: drags pick
            dragsPick = nearPick(location) || (isOrtho && sliceAxis != nil)
            if dragsPick { tick.selectionChanged() }
        case .changed:
            if dragsPick {
                // misses keep last pick
                pick(at: location)
            } else {
                let delta = recognizer.translation(in: self)
                recognizer.setTranslation(.zero, in: self)
                turn(by: SIMD2(Double(delta.x), Double(delta.y)) * Self.turnRate)
            }
        case .ended where !dragsPick:
            let velocity = recognizer.velocity(in: self)
            startSpin(SIMD2(Double(velocity.x), Double(velocity.y)) * Self.turnRate)
        default:
            break
        }
    }

    private func turn(by delta: SIMD2<Double>) {
        yaw -= delta.x
        pitch = min(max(pitch + delta.y, -Self.pitchLimit), Self.pitchLimit)
        redraw()
    }

    private func startSpin(_ velocity: SIMD2<Double>) {
        guard simd_length(velocity) > 0.3, !UIAccessibility.isReduceMotionEnabled else { return }
        spin = velocity
        spinTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(spun))
        link.add(to: .main, forMode: .common)
        spinLink = link
    }

    @objc private func spun(_ link: CADisplayLink) {
        let now = link.targetTimestamp
        let elapsed = now - spinTime
        spinTime = now
        turn(by: spin * elapsed)
        spin *= pow(Self.flingKeep, elapsed)
        if simd_length(spin) < 0.05 { stopSpin() }
    }

    private func stopSpin() {
        spinLink?.invalidate()
        spinLink = nil
    }

    /// The wireframe and black's letter show only while black changes.
    private func showTesseract() {
        let shown: Float = showsWhole ? 1 : 0
        CATransaction.begin()
        CATransaction.setAnimationDuration(UIAccessibility.isReduceMotionEnabled ? 0 : Self.wholeFade)
        tesseract.opacity = shown
        CATransaction.commit()
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : Self.wholeFade) { self.axisLabels[3].alpha = CGFloat(shown) }
    }

    private var ghostTarget: Double { showsWhole ? 1 : isOrtho ? 0 : Double(Self.ghostOpacity) }

    private func fadeGhost() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            ghost = ghostTarget
            return redraw()
        }
        guard fadeLink == nil else { return }
        fadeTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(faded))
        link.add(to: .main, forMode: .common)
        fadeLink = link
    }

    @objc private func faded(_ link: CADisplayLink) {
        let elapsed = link.targetTimestamp - fadeTime
        fadeTime = link.targetTimestamp
        let target = ghostTarget
        let step = elapsed / Self.wholeFade
        ghost = ghost < target ? min(ghost + step, target) : max(ghost - step, target)
        redraw()
        if ghost == target {
            fadeLink?.invalidate()
            fadeLink = nil
        }
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard newWindow == nil else { return }
        let turning = aimLink != nil
        for link in [fadeLink, aimLink, sliceLink, pointLink, spinLink, unrollLink, visionLink] { link?.invalidate() }
        (fadeLink, aimLink, sliceLink, pointLink, spinLink, unrollLink, visionLink) = (nil, nil, nil, nil, nil, nil, nil)
        shownVision = vision
        unroll = unrollTarget
        let pending = afterUnroll
        afterUnroll = nil
        // snap to targets
        ghost = ghostTarget
        shown = point
        oldSlice = nil
        if turning, let aimTo { apply(aimTo) }
        pending?()
    }

}

extension CanonColourSolid {
    /// A shell unrolled about the line facing the camera, lengths kept: an arc of radius `radius / bend` through the
    /// shell's front line, flat at `bend` 0. Mirrors `unrolledHit` in `Renderer.source`: change both together.
    fileprivate struct Sheet {
        public let radius, facing, bend: Double

        public var normal: SIMD3<Double> { [cos(facing), 0, sin(facing)] }
        public var tangent: SIMD3<Double> { [-sin(facing), 0, cos(facing)] }

        /// The sheet point of the shell point `turn` radians round from the facing hue, and whether it is on the far side.
        public func place(turn: Double, y: Double) -> (point: SIMD3<Double>, far: Bool) {
            let angle = turn * bend
            let along = bend > 1e-4 ? radius * sin(angle) / bend : radius * turn
            let sag = bend > 1e-4 ? radius * (1 - cos(angle)) / bend : 0
            return (normal * (radius - sag) + tangent * along + SIMD3(0, y, 0), abs(angle) > .pi / 2)
        }

        /// Shell points whose sheet points lie under the ray, near side first. Assumes the camera faces the sheet head on.
        public func shellPoints(origin: SIMD3<Double>, ray: SIMD3<Double>) -> [SIMD3<Double>] {
            let facingRay = simd_dot(ray, normal)
            guard abs(facingRay) > 1e-9, radius > 1e-4 else { return [] }
            let p = origin + ray * (simd_dot(normal * radius - origin, normal) / facingRay)
            let along = simd_dot(p, tangent)
            let bent = along * bend / radius
            guard abs(bent) <= 1 else { return [] }
            let front = asin(bent)
            let turns = bend > 1e-4 ? [front, (front < 0 ? -Double.pi : .pi) - front].map { $0 / bend } : [along / radius]
            return turns.filter { abs($0) <= .pi }.map { SIMD3(radius * cos(facing + $0), p.y, radius * sin(facing + $0)) }
        }
    }

    /// The solid in its box, x y z each -1...1, y up. Mirrors `Renderer.source`: change both together.
    public struct Geometry {
        public static let oklabReach = 0.33
        public static let labReach = 110.0
        /// Share of a turn the cut takes out of a cylinder.
        public static let wedge = 0.25
        public static let steps = 128
        /// A sample closer to the surface than this gets `substeps` finer samples before the next one.
        public static let nearSurface = 0.04
        public static let substeps = 8

        /// Half-size of the CMYK box at 100 % black; 1 at 0 %.
        public static let innerSize = 0.36

        public let space: Space
        /// Channels along x y z.
        public let pick: SIMD3<Double>
        public let cut: SIMD4<Double>
        public var slice: Int? = nil
        /// CMYK's black; 0 in every other space.
        public var black = 0.0

        /// Half-size of the box.
        public var size: Double { 1 - black * (1 - Self.innerSize) }

        public static func hueRGB(_ h: Double) -> SIMD3<Double> {
            let k = SIMD3(h * 6, h * 6 + 4, h * 6 + 2)
            let wrapped = k - 6 * (k / 6).rounded(.down)
            return (abs(wrapped - 3) - 1).clamped(lowerBound: .zero, upperBound: .one)
        }

        public func channels(_ p: SIMD3<Double>) -> SIMD3<Double> {
            if space.isCartesian { return (p / size + 1) / 2 }
            let hue = atan2(p.z, p.x) / (2 * .pi)
            return SIMD3(hue < 0 ? hue + 1 : hue, (p.x * p.x + p.z * p.z).squareRoot(), (p.y + 1) / 2)
        }

        public func display(_ channels: SIMD3<Double>) -> SIMD3<Double> {
            if space.isCartesian { return (channels * 2 - 1) * size }
            let angle = channels.x * 2 * .pi
            return SIMD3(channels.y * cos(angle), channels.z * 2 - 1, channels.y * sin(angle))
        }

        /// Linear sRGB at a point of the OKLab or CIELAB box, unclamped, as the shader's `linearAt`.
        public static func linear(_ p: SIMD3<Double>, space: Space) -> SIMD3<Double> {
            if space == .oklch || space == .oklab {
                let (l, a, b) = ((p.y + 1) / 2, p.x * oklabReach, p.z * oklabReach)
                var lms = SIMD3(l + 0.3963377774 * a + 0.2158037573 * b, l - 0.1055613458 * a - 0.0638541728 * b, l - 0.0894841775 * a - 1.2914855480 * b)
                lms *= lms * lms
                return SIMD3(
                    4.0767416621 * lms.x - 3.3077115913 * lms.y + 0.2309699292 * lms.z,
                    -1.2684380046 * lms.x + 2.6097574011 * lms.y - 0.3413193965 * lms.z,
                    -0.0041960863 * lms.x - 0.7034186147 * lms.y + 1.7076147010 * lms.z)
            }
            func inverse(_ t: Double) -> Double { t > 6.0 / 29 ? t * t * t : 3 * (6.0 / 29) * (6.0 / 29) * (t - 4.0 / 29) }
            let fy = ((p.y + 1) * 50 + 16) / 116
            let xyz = SIMD3(0.95047 * inverse(fy + p.x * labReach / 500), inverse(fy), 1.08883 * inverse(fy - p.z * labReach / 200))
            return SIMD3(
                3.2404542 * xyz.x - 1.5371385 * xyz.y - 0.4985314 * xyz.z,
                -0.9692660 * xyz.x + 1.8760108 * xyz.y + 0.0415560 * xyz.z,
                0.0556434 * xyz.x - 0.2040259 * xyz.y + 1.0572252 * xyz.z)
        }

        public func shape(_ p: SIMD3<Double>) -> Double {
            let box = abs(p).max() - size
            if space == .rgb || space == .hsl || space == .cmyk { return box }
            let cylinder = max((p.x * p.x + p.z * p.z).squareRoot() - 1, abs(p.y) - 1)
            if space == .hsb { return cylinder }
            let c = Self.linear(p, space: space)
            return max(box, max((c - 1).max(), (-c).max()))
        }

        public func cutAway(_ p: SIMD3<Double>) -> Double {
            let c = channels(p)
            if space.isCartesian { return ((c - pick) * SIMD3(cut.x, cut.y, cut.z)).min() }
            var turn = cut.x > 0 ? c.x - pick.x : pick.x - c.x
            turn -= turn.rounded(.down)
            return min(min(turn, Self.wedge - turn), min(c.y - pick.y, (c.z - pick.z) * cut.z))
        }

        /// Negative inside.
        public func solid(_ p: SIMD3<Double>) -> Double {
            let inside = shape(p)
            return cut.w > 0 ? max(inside, cutAway(p)) : inside
        }

        private static func planeHit(_ o: SIMD3<Double>, _ d: SIMD3<Double>, _ index: Int, _ at: Double) -> Double {
            abs(d[index]) < 1e-9 ? -1 : (at - o[index]) / d[index]
        }

        /// Distance along `ray` to the slice where it is inside the solid.
        public func sliceHit(origin o: SIMD3<Double>, ray d: SIMD3<Double>) -> Double? {
            guard let slice else { return nil }
            let value = pick[slice]
            var hits: [Double] = []
            if space.isCartesian {
                hits = [Self.planeHit(o, d, slice, (value * 2 - 1) * size)]
            } else if slice == 2 {
                hits = [Self.planeHit(o, d, 1, value * 2 - 1)]
            } else if slice == 0 {
                let angle = value * 2 * .pi
                let normal = SIMD3(-sin(angle), 0, cos(angle))
                let facing = simd_dot(d, normal)
                if abs(facing) > 1e-9 {
                    let t = -simd_dot(o, normal) / facing
                    let p = o + d * t
                    if p.x * cos(angle) + p.z * sin(angle) >= 0 { hits = [t] }
                }
            } else {
                let a = d.x * d.x + d.z * d.z
                let b = 2 * (o.x * d.x + o.z * d.z)
                let c = o.x * o.x + o.z * o.z - value * value
                let root = b * b - 4 * a * c
                if a > 1e-12, root >= 0 { hits = [(-b - root.squareRoot()) / (2 * a), (-b + root.squareRoot()) / (2 * a)] }
            }
            return hits.first { $0 > 0 && shape(o + d * $0) <= 1e-4 }
        }

        /// Distance along `ray` to the first point inside the solid.
        public static func march(origin: SIMD3<Double>, ray: SIMD3<Double>, geometry: Geometry) -> Double? {
            let a = (-1.001 - origin) / ray
            let b = (1.001 - origin) / ray
            let near = simd_min(a, b).max()
            let far = simd_max(a, b).min()
            guard far >= max(near, 0) else { return nil }
            let step = (far - near) / Double(steps)
            func refine(_ lo: Double, _ hi: Double) -> Double {
                var (lo, hi) = (lo, hi)
                for _ in 0..<10 {
                    let mid = (lo + hi) / 2
                    if geometry.solid(origin + ray * mid) < 0 { hi = mid } else { lo = mid }
                }
                return hi
            }
            var previous = near
            for index in 0...steps {
                let t = near + step * Double(index)
                let value = geometry.solid(origin + ray * t)
                if value < 0 { return index == 0 ? t : refine(previous, t) }
                if value < nearSurface, index < steps {
                    for sub in 1..<substeps {
                        let fine = t + step * Double(sub) / Double(substeps)
                        if geometry.solid(origin + ray * fine) < 0 { return refine(fine - step / Double(substeps), fine) }
                    }
                }
                previous = t
            }
            return nil
        }

        public init(space: Space, pick: SIMD3<Double>, cut: SIMD4<Double>, slice: Int? = nil, black: Double = 0.0) {
            self.space = space
            self.pick = pick
            self.cut = cut
            self.slice = slice
            self.black = black
        }
    }

    #if DEBUG
    public static func selfCheck() {
        let samples = [DelphiColour(r: 0.12, g: 0.4, b: 0.15), DelphiColour(r: 0.9, g: 0.3, b: 0.6), DelphiColour(r: 0.2, g: 0.5, b: 0.95)]
        for space in Space.allCases {
            for sample in samples {
                let back = space.colour(at: space.point(for: sample))
                assert(abs(back.r - sample.r) + abs(back.g - sample.g) + abs(back.b - sample.b) < 0.01, "\(space.name) round trip")
                let point = space.point(for: sample)
                let geometry = Geometry(space: space, pick: .zero, cut: .zero, black: point.w)
                let channels = SIMD3(point.x, point.y, point.z)
                assert(simd_length(geometry.channels(geometry.display(channels)) - channels) < 1e-9, "\(space.name) display round trip")
            }
        }
        let flat = Geometry(space: .rgb, pick: [0.5, 0.5, 0.5], cut: .zero)
        let t = Geometry.march(origin: [0, 0, 6], ray: [0, 0, -1], geometry: flat)
        assert(t.map { abs($0 - 5) < 0.01 } == true, "front face of the cube")
        let cut = Geometry(space: .rgb, pick: [0.5, 0.5, 0.5], cut: [1, 1, 1, 1])
        let corner = Geometry.march(origin: [4, 4, 4], ray: simd_normalize(SIMD3(-1, -1, -1)), geometry: cut)
        assert(corner.map { abs($0 - 48.0.squareRoot()) < 0.02 } == true, "cut reaches the centre")
        let gamut = Geometry(space: .oklch, pick: .zero, cut: .zero)
        assert(gamut.shape([0, 0, 0]) < 0 && gamut.shape([0.95, 0, 0.95]) > 0, "gamut")
        let deep = Geometry(space: .cmyk, pick: .zero, cut: .zero, black: 1)
        assert(abs(deep.size - Geometry.innerSize) < 1e-12 && deep.shape([0.5, 0, 0]) > 0, "full ink shrinks to the inner cube")
        assert(Space.cmyk.point(for: DelphiColour(r: 0, g: 0, b: 0)) == [0, 0, 0, 1], "black is all key")
        let cyanPlane = Geometry(space: .cmyk, pick: [1, 0.5, 0.5], cut: .zero, slice: 0, black: 1)
        assert(cyanPlane.sliceHit(origin: [6, 0, 0], ray: [-1, 0, 0]).map { abs($0 - (6 - Geometry.innerSize)) < 1e-9 } == true, "cmyk plane follows the box")
        let hueLeaf = Geometry(space: .hsb, pick: [0.25, 0.5, 0.5], cut: .zero, slice: 0)
        assert(hueLeaf.sliceHit(origin: [6, 0, 0.5], ray: [-1, 0, 0]).map { abs($0 - 6) < 1e-9 } == true, "hue half-plane at z = 0.5")
        assert(hueLeaf.sliceHit(origin: [6, 0, -0.5], ray: [-1, 0, 0]) == nil, "opposite half is empty")
        let shell = Geometry(space: .hsb, pick: [0, 0.5, 0.5], cut: .zero, slice: 1)
        assert(shell.sliceHit(origin: [6, 0, 0], ray: [-1, 0, 0]).map { abs($0 - 5.5) < 1e-9 } == true, "near side of the shell")
        let rolled = Sheet(radius: 0.5, facing: 0.3, bend: 1).place(turn: 1, y: 0.2).point
        assert(simd_length(rolled - SIMD3(0.5 * cos(1.3), 0.2, 0.5 * sin(1.3))) < 1e-9, "rolled sheet is the shell")
        let unrolled = Sheet(radius: 0.5, facing: 0, bend: 0)
        assert(simd_length(unrolled.place(turn: 2, y: 0).point - SIMD3(0.5, 0, 1)) < 1e-9, "flat sheet keeps arc length")
        let under = unrolled.shellPoints(origin: [80, 0.1, 1], ray: [-1, 0, 0])
        assert(under.count == 1 && simd_length(under[0] - SIMD3(0.5 * cos(2), 0.1, 0.5 * sin(2))) < 1e-9, "flat sheet picks the shell point")
        let half = Sheet(radius: 0.5, facing: 0.3, bend: 0.5)
        let bent = half.place(turn: 0.8, y: 0)
        let back = half.shellPoints(origin: bent.point + half.normal * 80, ray: -half.normal)
        assert(back.first.map { simd_length($0 - SIMD3(0.5 * cos(1.1), 0, 0.5 * sin(1.1))) < 1e-6 } == true, "bent sheet round trip")
    }
    #endif
}

private final class Renderer: NSObject, MTKViewDelegate {
    public struct Uniforms {
        public var camera, right, up, forward, pick, cut, params, slice, turn, centre, vision0, vision1, vision2: SIMD4<Float>
    }

    public let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    public var draw: ((MTKView) -> Uniforms)?

    // xcode lacks metal toolchain
    private static let shared: (device: MTLDevice, queue: MTLCommandQueue, pipeline: MTLRenderPipelineState)? = {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            let library = try device.makeLibrary(source: source, options: nil)
            descriptor.vertexFunction = library.makeFunction(name: "canonSolidVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "canonSolidFragment")
            return (device, queue, try device.makeRenderPipelineState(descriptor: descriptor))
        } catch {
            assertionFailure("colour solid shader: \(error)")
            return nil
        }
    }()

    private init(_ shared: (device: MTLDevice, queue: MTLCommandQueue, pipeline: MTLRenderPipelineState)) {
        (device, queue, pipeline) = shared
        super.init()
    }

    /// Nil without Metal or when the shader fails to compile.
    public static func make() -> Renderer? { shared.map { Renderer($0) } }

    /// Mirrors `CanonColourSolid.Geometry`: change both together.
    private static let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct SolidUniforms {
        float4 camera;
        float4 right;   // w: horizontal half-tan
        float4 up;      // w: vertical half-tan
        float4 forward;
        float4 pick;    // xyz channels, w black
        float4 cut;     // xyz signs, w on
        float4 params;  // space, shading, size
        float4 slice;   // axis, ghost, box size, flatness
        float4 turn;    // old axis, two reaches, facing
        float4 centre;  // pick in the box
        float4 vision0; // vision matrix rows
        float4 vision1;
        float4 vision2;
    };

    constant float oklabReach = \(CanonColourSolid.Geometry.oklabReach);
    constant float labReach = \(CanonColourSolid.Geometry.labReach);
    constant float wedge = \(CanonColourSolid.Geometry.wedge);
    constant int steps = \(CanonColourSolid.Geometry.steps);
    constant int substeps = \(CanonColourSolid.Geometry.substeps);
    constant float nearSurface = \(CanonColourSolid.Geometry.nearSurface);

    struct Varyings {
        float4 position [[position]];
    };

    vertex Varyings canonSolidVertex(uint id [[vertex_id]]) {
        float2 corner = float2((id << 1) & 2, id & 2);
        Varyings out;
        out.position = float4(corner * 2 - 1, 0, 1);
        return out;
    }

    static float max3(float3 v) { return max(v.x, max(v.y, v.z)); }
    static float min3(float3 v) { return min(v.x, min(v.y, v.z)); }

    static float3 oklabToLinear(float3 lab) {
        float l = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
        float m = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
        float s = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
        l = l * l * l; m = m * m * m; s = s * s * s;
        return float3(
            4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
    }

    static float labInverse(float t) {
        return t > 6.0 / 29.0 ? t * t * t : 3 * (6.0 / 29.0) * (6.0 / 29.0) * (t - 4.0 / 29.0);
    }

    static float3 labToLinear(float3 lab) {
        float fy = (lab.x + 16) / 116;
        float3 xyz = float3(0.95047 * labInverse(fy + lab.y / 500), labInverse(fy), 1.08883 * labInverse(fy - lab.z / 200));
        return float3(
            3.2404542 * xyz.x - 1.5371385 * xyz.y - 0.4985314 * xyz.z,
            -0.9692660 * xyz.x + 1.8760108 * xyz.y + 0.0415560 * xyz.z,
            0.0556434 * xyz.x - 0.2040259 * xyz.y + 1.0572252 * xyz.z);
    }

    static float3 linearToSRGB(float3 c) {
        c = clamp(c, 0.0, 1.0);
        return select(1.055 * pow(c, 1.0 / 2.4) - 0.055, 12.92 * c, c <= 0.0031308);
    }

    static float3 hueRGB(float h) {
        return clamp(abs(fmod(h * 6 + float3(0, 4, 2), 6.0) - 3) - 1, 0.0, 1.0);
    }

    // ids: Space raw values
    static bool isCartesian(int space) { return space <= 1 || space >= 5; }

    // cylinders: hue radius height
    static float3 channels(float3 p, int space, float size) {
        if (isCartesian(space)) return (p / size + 1) * 0.5;
        float hue = atan2(p.z, p.x) / (2 * M_PI_F);
        return float3(hue < 0 ? hue + 1 : hue, length(p.xz), (p.y + 1) * 0.5);
    }

    static float3 linearAt(float3 p, int space) {
        if (space == 3 || space == 5) return oklabToLinear(float3((p.y + 1) * 0.5, p.x * oklabReach, p.z * oklabReach));
        return labToLinear(float3((p.y + 1) * 50, p.x * labReach, p.z * labReach));
    }

    static float3 trueColourAt(float3 p, constant SolidUniforms &uniforms) {
        int space = int(uniforms.params.x);
        float3 u = clamp(channels(p, space, uniforms.slice.z), 0.0, 1.0);
        switch (space) {
        case 0: return u;
        case 1: {
            float chroma = (1 - abs(2 * u.y - 1)) * u.z;
            return (hueRGB(u.x) - 0.5) * chroma + u.y;
        }
        case 2: return u.z * (1 - u.y + u.y * hueRGB(u.x));
        case 7: return (1 - u) * (1 - uniforms.pick.w);
        default: return linearToSRGB(linearAt(p, space));
        }
    }

    static float3 colourAt(float3 p, constant SolidUniforms &u) {
        float3 c = trueColourAt(p, u);
        return clamp(float3(dot(u.vision0.xyz, c), dot(u.vision1.xyz, c), dot(u.vision2.xyz, c)), 0.0, 1.0);
    }

    // negative inside
    static float shape(float3 p, int space, float size) {
        float box = max3(abs(p)) - size;
        if (space <= 1 || space == 7) return box;
        float cylinder = max(length(p.xz) - 1, abs(p.y) - 1);
        if (space == 2) return cylinder;
        float3 c = linearAt(p, space);
        return max(box, max(max3(c - 1), max3(-c)));
    }

    // positive inside the cut
    static float cutAway(float3 p, constant SolidUniforms &u) {
        int space = int(u.params.x);
        float3 c = channels(p, space, u.slice.z);
        if (isCartesian(space)) return min3((c - u.pick.xyz) * u.cut.xyz);
        float turn = fract(u.cut.x > 0 ? c.x - u.pick.x : u.pick.x - c.x);
        float around = min(turn, wedge - turn);
        return min(around, min(c.y - u.pick.y, (c.z - u.pick.z) * u.cut.z));
    }

    static float solid(float3 p, constant SolidUniforms &u) {
        float inside = shape(p, int(u.params.x), u.slice.z);
        return u.cut.w > 0 ? max(inside, cutAway(p, u)) : inside;
    }

    static float planeHit(float3 o, float3 d, int index, float at) {
        return abs(d[index]) < 1e-6 ? -1 : (at - o[index]) / d[index];
    }

    // -1 when missed
    static float sliceHit(float3 o, float3 d, constant SolidUniforms &u, int axis, float reach) {
        int space = int(u.params.x);
        float3 centre = u.centre.xyz;
        float value = u.pick[axis];
        float hits[2] = { -1, -1 };
        if (isCartesian(space)) {
            hits[0] = planeHit(o, d, axis, (value * 2 - 1) * u.slice.z);
        } else if (axis == 2) {
            hits[0] = planeHit(o, d, 1, value * 2 - 1);
        } else if (axis == 0) {
            float angle = value * 2 * M_PI_F;
            float3 normal = float3(-sin(angle), 0, cos(angle));
            float facing = dot(d, normal);
            if (abs(facing) > 1e-6) {
                float t = -dot(o, normal) / facing;
                float3 p = o + d * t;
                hits[0] = dot(p.xz, float2(cos(angle), sin(angle))) >= 0 ? t : -1;
            }
        } else {
            float a = dot(d.xz, d.xz);
            float b = 2 * dot(o.xz, d.xz);
            float c = dot(o.xz, o.xz) - value * value;
            float root = b * b - 4 * a * c;
            if (a > 1e-9 && root >= 0) {
                hits[0] = (-b - sqrt(root)) / (2 * a);
                hits[1] = (-b + sqrt(root)) / (2 * a);
            }
        }
        for (int i = 0; i < 2; i++) {
            float3 p = o + d * hits[i];
            if (hits[i] > 0 && shape(p, space, u.slice.z) <= 1e-4 && distance(p, centre) <= reach) return hits[i];
        }
        return -1;
    }

    // unrolled shell; mirrors Sheet
    static bool unrolledHit(float3 o, float3 d, constant SolidUniforms &u, thread float3 &original) {
        float r = u.pick.y;
        float facing = u.turn.w;
        float bend = 1 - u.slice.w;
        float3 normal = float3(cos(facing), 0, sin(facing));
        float3 tangent = float3(-sin(facing), 0, cos(facing));
        float facingRay = dot(d, normal);
        if (abs(facingRay) < 1e-6 || r < 1e-4) return false;
        float3 p = o + d * (dot(normal * r - o, normal) / facingRay);
        float along = dot(p, tangent);
        float bent = along * bend / r;
        if (abs(bent) > 1) return false;
        float front = asin(bent);
        float angles[2] = { front, (front < 0 ? -M_PI_F : M_PI_F) - front };
        int count = bend > 1e-4 ? 2 : 1;
        for (int i = 0; i < count; i++) {
            float turn = bend > 1e-4 ? angles[i] / bend : along / r;
            if (abs(turn) > M_PI_F) continue;
            original = float3(r * cos(facing + turn), p.y, r * sin(facing + turn));
            if (shape(original, int(u.params.x), u.slice.z) <= 1e-4) return true;
        }
        return false;
    }

    // nearer of swapping slices
    static float slicesHit(float3 o, float3 d, constant SolidUniforms &u) {
        float at = sliceHit(o, d, u, int(u.slice.x), u.turn.y);
        if (u.turn.x >= 0) {
            float old = sliceHit(o, d, u, int(u.turn.x), u.turn.z);
            if (old > 0 && (at < 0 || old < at)) at = old;
        }
        return at;
    }

    fragment float4 canonSolidFragment(Varyings in [[stage_in]], constant SolidUniforms &u [[buffer(0)]]) {
        float2 ndc = float2(in.position.x / u.params.z * 2 - 1, 1 - in.position.y / u.params.w * 2);
        float3 origin = u.camera.xyz;
        float3 ray = normalize(u.forward.xyz + ndc.x * u.right.w * u.right.xyz + ndc.y * u.up.w * u.up.xyz);

        // sheet exceeds unit box
        if (u.slice.w > 0) {
            float3 original;
            return unrolledHit(origin, ray, u, original) ? float4(colourAt(original, u), 1) : float4(0);
        }

        // unit box slab test
        float3 inverse = 1 / ray;
        float3 a = (-1.001 - origin) * inverse;
        float3 b = (1.001 - origin) * inverse;
        float near = max3(min(a, b));
        float far = min3(max(a, b));
        if (far < max(near, 0.0)) return float4(0);

        // ghost off: skip march
        if (u.slice.x >= 0 && u.slice.y <= 0) {
            float at = slicesHit(origin, ray, u);
            return at < 0 ? float4(0) : float4(colourAt(origin + ray * at, u), 1);
        }

        float step = (far - near) / steps;
        float previous = near;
        float t = near;
        bool hit = false;
        for (int i = 0; i <= steps && !hit; i++) {
            t = near + step * i;
            float value = solid(origin + ray * t, u);
            if (value < 0) { hit = true; break; }
            // catch grazing slivers
            if (value < nearSurface && i < steps) {
                for (int j = 1; j < substeps; j++) {
                    float fine = t + step * j / substeps;
                    if (solid(origin + ray * fine, u) < 0) {
                        previous = fine - step / substeps;
                        t = fine;
                        hit = true;
                        break;
                    }
                }
            }
            if (!hit) previous = t;
        }
        if (!hit) return float4(0);
        if (t > near) {
            float lo = previous, hi = t;
            for (int i = 0; i < 10; i++) {
                float mid = (lo + hi) * 0.5;
                if (solid(origin + ray * mid, u) < 0) hi = mid; else lo = mid;
            }
            t = hi;
        }

        float3 p = origin + ray * t;
        float e = 0.002;
        float3 normal = normalize(float3(
            solid(p + float3(e, 0, 0), u) - solid(p - float3(e, 0, 0), u),
            solid(p + float3(0, e, 0), u) - solid(p - float3(0, e, 0), u),
            solid(p + float3(0, 0, e), u) - solid(p - float3(0, 0, e), u)));
        float3 light = normalize(u.up.xyz * 0.8 - u.right.xyz * 0.5 - u.forward.xyz);
        float lit = max(dot(normal, light), 0.0);
        float3 colour = colourAt(p, u) * (1 - u.params.y * (1 - lit));
        if (u.slice.x < 0) return float4(colour, 1);

        // premultiplied ghost over slice
        float4 ghost = float4(colour * u.slice.y, u.slice.y);
        float at = slicesHit(origin, ray, u);
        if (at < 0) return ghost;
        return float4(colourAt(origin + ray * at, u) * (1 - ghost.a) + ghost.rgb, 1);
    }
    """

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.setNeedsDisplay()
    }

    public func draw(in view: MTKView) {
        guard var uniforms = draw?(view), let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let buffer = queue.makeCommandBuffer(), let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}

/// A square in the picked colour, framed so it reads on any face.
private final class Marker: UIView {
    public init(side: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: side, height: side))
        isUserInteractionEnabled = false
        layer.borderWidth = side > 12 ? 3 : 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 2
        layer.shadowOffset = .zero
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(_ colour: DelphiColour, hidden: Bool) {
        backgroundColor = hidden ? .clear : colour.uiColor
        let ink: UIColor = colour.takesBlackInk ? .black : .white
        layer.borderColor = (hidden ? UIColor.delphiForeground.resolvedColor(with: traitCollection).withAlphaComponent(0.5) : ink).cgColor
        layer.shadowOpacity = hidden ? 0 : 0.25
    }
}
