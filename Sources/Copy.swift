import AppKit

func secureCopy(text: String) {
    let item = NSPasteboardItem()
    item.setString(text, forType: .string)
    item.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
    item.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))

    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([item])
}
