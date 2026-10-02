import Observation
import SwiftUI
import UIKit

/// A calculated figure whose changed characters roll, using SwiftUI's numeric text transition.
/// UIKit has no counterpart, so this is a SwiftUI island: one `Text` in a hosting controller.
public final class CanonFigure: UIView {

    @Observable
    fileprivate final class Model {
        public var text = ""
        public var unit = ""
        public var value = 0.0
        public var colour = Color.primary
    }

    private let model = Model()
    private let host: UIHostingController<FigureText>

    /// - Parameter halo: outline and soft shadow in this colour, for a figure that sits over a picture.
    public init(size: CGFloat = 40, relativeTo style: UIFont.TextStyle = .largeTitle, colour: UIColor = .delphiPrimary, halo: UIColor? = nil) {
        // no swiftui in callers
        let scaling: [UIFont.TextStyle: Font.TextStyle] = [
            .largeTitle: .largeTitle, .title1: .title, .title2: .title2, .title3: .title3, .headline: .headline,
            .subheadline: .subheadline, .callout: .callout, .footnote: .footnote, .caption1: .caption, .caption2: .caption2,
        ]
        host = UIHostingController(rootView: FigureText(
            model: model, size: size, style: scaling[style] ?? .body, halo: halo.map { Color(uiColor: $0) }
        ))
        super.init(frame: .zero)
        model.colour = Color(uiColor: colour)
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        host.sizingOptions = .intrinsicContentSize
        pin(host.view)
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // parent carries traits
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, host.parent == nil, let parent = owningViewController else { return }
        parent.addChild(host)
        host.didMove(toParent: parent)
    }

    public func setColour(_ colour: UIColor) {
        withAnimation(.easeOut(duration: 0.2)) { model.colour = Color(uiColor: colour) }
    }

    /// - Parameter unit: set smaller, in the condensed sans, after the monospaced figure.
    public func show(_ text: String, unit: String = "", animated: Bool = true) {
        guard text != model.text || unit != model.unit else { return }
        // number sets roll direction
        let value = Double(text.prefix { $0.isNumber || $0 == "." || $0 == "-" }) ?? 0
        let animation: Animation? = animated && !UIAccessibility.isReduceMotionEnabled ? .snappy(duration: 0.35) : nil
        withAnimation(animation) {
            model.text = text
            model.unit = unit
            model.value = value
        }
        accessibilityLabel = text + unit
    }
}

private struct FigureText: View {
    public let model: CanonFigure.Model
    @ScaledMetric public var size: CGFloat
    public let halo: Color?

    public init(model: CanonFigure.Model, size: CGFloat, style: Font.TextStyle, halo: Color?) {
        self.model = model
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.halo = halo
    }

    public var body: some View {
        let clear = Color.clear
        HStack(alignment: .firstTextBaseline, spacing: size * 0.08) {
            Text(model.text)
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .contentTransition(.numericText(value: model.value))
            if !model.unit.isEmpty {
                Text(model.unit)
                    .font(.system(size: size * 0.55, weight: .semibold).width(.condensed))
                    .transition(.opacity)
            }
        }
        .foregroundStyle(model.colour)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        // stacked shadows: outline
        .shadow(color: halo ?? clear, radius: 1)
        .shadow(color: halo ?? clear, radius: 1)
        .shadow(color: halo ?? clear, radius: 1)
        .shadow(color: halo ?? clear, radius: 1)
        .shadow(color: halo ?? clear, radius: 5, y: 3)
    }
}
