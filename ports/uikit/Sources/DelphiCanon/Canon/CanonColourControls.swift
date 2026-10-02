import DelphiCore
import SwiftUI
import UIKit

/// Rows that drive a `CanonColourSolid`: any notation beside the system picker, the space, one slider per channel and
/// the View plane switch. The active slider row is the solid's slice. `onChange` runs after every change of colour or space.
public final class CanonColourControls {
    public let solid: CanonColourSolid
    public var onChange: (() -> Void)?

    public let notationRow: CanonRow
    public let spaceRow: CanonRow
    public private(set) var sliderRows: [CanonRow] = []
    public let viewPlaneRow: CanonRow

    /// Slices along the active row's channel; false cuts the solid away instead.
    public var slices = true {
        didSet { showActiveRow() }
    }

    public var isOrtho: Bool {
        get { viewPlane.isOn }
        set {
            viewPlane.isOn = newValue
            showActiveRow()
        }
    }

    public var activeRow: Int {
        didSet { showActiveRow() }
    }

    private let spaces: CanonSegmented
    private let viewPlane = CanonSwitch()
    private let notation = CanonColourNotationInput()
    private var sliders: [CanonSlider] = []

    public init(solid: CanonColourSolid, activeRow: Int = 0) {
        self.solid = solid
        self.activeRow = activeRow
        spaces = CanonSegmented(CanonColourSolid.Space.allCases.map(\.name), selected: CanonColourSolid.Space.allCases.firstIndex(of: solid.space) ?? 0, columns: 4)
        notationRow = CanonRow(String(localized: "Any notation"), form: .stacked, control: notation)
        spaceRow = CanonRow(String(localized: "Space"), form: .stacked, control: spaces)
        viewPlaneRow = CanonRow(String(localized: "View plane"), control: viewPlane)

        for index in 0..<4 {
            let slider = CanonSlider(value: 0, range: 0...1) { [unowned self] value in
                let channels = self.solid.space.channels
                return String(format: "%.\(index < channels.count ? channels[index].decimals : 0)f", value)
            }
            // row 3: cmyk black
            let isDepth = index == 3
            slider.addAction(UIAction { [unowned self] _ in
                if isDepth { self.solid.showsWhole = true } else { self.activeRow = index }
            }, for: .touchDown)
            slider.addAction(UIAction { [unowned self] _ in self.solid.showsWhole = false }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
            slider.onChange { [unowned self] slider in
                guard index < self.solid.space.channels.count else { return }
                if !isDepth { self.activeRow = index }
                let channel = self.solid.space.channels[index]
                var next = self.solid.point
                next[channel.axis] = (slider.value - channel.offset) / channel.scale
                // taps ease, drags follow
                self.solid.setPoint(next, animated: !slider.isDragging)
                syncNotation()
                onChange?()
            }
            sliders.append(slider)
            let row = CanonRow(" ", detail: "", form: .flush, control: slider)
            row.detailLabel?.isHidden = true
            sliderRows.append(row)
        }

        spaces.onChange { [unowned self] in
            select(space: CanonColourSolid.Space.allCases[$0.selectedIndex])
            onChange?()
        }
        viewPlane.onChange { [unowned self] _ in showActiveRow() }
        solid.onChange { [unowned self] _ in
            sync()
            onChange?()
        }
        notation.onColour = { [unowned self] in use($0) }
        notation.pickerColour = { [unowned self] in Color(uiColor: self.solid.colour.uiColor) }

        sync()
        showActiveRow()
    }

    public func select(space: CanonColourSolid.Space) {
        spaces.selectedIndex = CanonColourSolid.Space.allCases.firstIndex(of: space) ?? 0
        solid.space = space
        sync()
        showActiveRow()
    }

    /// Eases the solid to `colour`.
    public func use(_ colour: DelphiColour) {
        solid.setPoint(solid.space.point(for: colour), animated: true)
        sync()
        onChange?()
    }

    /// Sliders and the notation follow a colour set on the solid from outside.
    public func sync() {
        for (index, channel) in solid.space.channels.enumerated() {
            sliderRows[index].isHidden = false
            sliderRows[index].setText(title: channel.name, detail: channel.detail ?? "")
            sliderRows[index].detailLabel?.isHidden = channel.detail == nil
            sliders[index].range = channel.range
            sliders[index].value = min(solid.point[channel.axis] * channel.scale + channel.offset, channel.range.upperBound)
        }
        for row in sliderRows.dropFirst(solid.space.channels.count) { row.isHidden = true }
        syncNotation()
    }

    private func syncNotation() {
        notation.show(solid.colour)
    }

    private func showActiveRow() {
        solid.isOrtho = slices && viewPlane.isOn
        // black never slices
        let active = min(activeRow, 2)
        solid.sliceAxis = slices ? solid.space.channels[active].axis : nil
        for (index, row) in sliderRows.enumerated() {
            let lit = slices && index == active
            row.titleLabel.textColor = lit ? .delphiPrimary : .delphiForeground
            row.titleLabel.font = .delphi(.body, weight: lit ? .semibold : .regular)
        }
    }
}
