import AppKit

enum MenuBarIcon {
    static func image(on: Bool) -> NSImage {
        let side: CGFloat = 18
        let image = NSImage(size: NSSize(width: side, height: side))
        image.lockFocus()
        NSColor.systemGreen.set()
        let inset: CGFloat = on ? 2 : 2.5
        let rect = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
        let path = NSBezierPath(ovalIn: rect)
        if on {
            path.fill()
        } else {
            path.lineWidth = 2
            path.stroke()
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
