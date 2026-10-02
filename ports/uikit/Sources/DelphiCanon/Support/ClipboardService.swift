import UIKit
import UniformTypeIdentifiers

public enum ClipboardService {

    public static func copy(_ string: String) {
        UIPasteboard.general.string = string
    }

    public static func copy(_ image: UIImage) {
        UIPasteboard.general.image = image
    }

    public static func copy(_ data: Data, type: String) {
        UIPasteboard.general.setData(data, forPasteboardType: type)
    }

    /// encodes off main actor
    public static func copyPNG(_ image: CGImage) async {
        guard let png = await Task.detached(priority: .userInitiated, operation: { UIImage(cgImage: image).pngData() }).value else { return }
        copy(png, type: UTType.png.identifier)
    }

    public static var hasImage: Bool {
        UIPasteboard.general.hasImages
    }

    public static var string: String? {
        UIPasteboard.general.string
    }

    public static var image: UIImage? {
        UIPasteboard.general.image
    }
}
