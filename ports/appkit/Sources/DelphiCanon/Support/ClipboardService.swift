import AppKit

public enum ClipboardService {
    public static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    public static func copy(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    public static func copy(_ data: Data, type: NSPasteboard.PasteboardType) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(data, forType: type)
    }

    public static var string: String? {
        NSPasteboard.general.string(forType: .string)
    }

    public static var image: NSImage? {
        NSImage(pasteboard: NSPasteboard.general)
    }
}
