import CoreGraphics

/// Border weights for the dense / flush / hairline system.
///
/// Mirrors the web's two-level hierarchy (see delphitools `DESIGN.md` §5):
/// the 2pt frame wraps a tool's editor and separates its major sections;
/// everything nested inside it — option groups, tables, sub-sections — is 1pt.
public enum DelphiMetrics {
    /// Nested rules: sub-sections, option groups, table rows and cells.
    public static let hairline: CGFloat = 1
    /// Top-level tool frame and major section dividers.
    public static let frame: CGFloat = 2
    /// Minimum flush control height — big touch targets, per the system.
    public static let controlHeight: CGFloat = 44
    /// Height of a primary action button.
    public static let primaryHeight: CGFloat = 68
    /// Height of a secondary action button.
    public static let secondaryHeight: CGFloat = 60
    /// Minimum height of a canon row.
    public static let rowHeight: CGFloat = 52
    /// Horizontal padding a panel gives its text.
    public static let panelPadding: CGFloat = 16
}
