import AppKit
import CoreGraphics

// Renders AppIcon.icns: a green circle on a dark rounded tile.
let files: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

func png(px: Int) -> Data {
    let dim = CGFloat(px)
    let context = CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let tile = CGRect(x: dim * 0.06, y: dim * 0.06, width: dim * 0.88, height: dim * 0.88)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: dim * 0.22, cornerHeight: dim * 0.22, transform: nil)
    context.addPath(tilePath)
    context.setFillColor(CGColor(red: 0.11, green: 0.12, blue: 0.13, alpha: 1))
    context.fillPath()

    let diameter = dim * 0.5
    let circle = CGRect(x: (dim - diameter) / 2, y: (dim - diameter) / 2, width: diameter, height: diameter)
    context.setFillColor(NSColor.systemGreen.cgColor)
    context.fillEllipse(in: circle)

    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let iconset = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for (name, px) in files {
    try! png(px: px).write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
}
print("wrote \(iconset)")
