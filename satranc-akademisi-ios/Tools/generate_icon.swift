import AppKit
import Foundation

let iconSize = NSSize(width: 1024, height: 1024)
let icon = NSImage(size: iconSize)
icon.lockFocus()
NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.19, alpha: 1).setFill()
NSRect(origin: .zero, size: iconSize).fill()
let outline = NSBezierPath(roundedRect: NSRect(x: 55, y: 55, width: 914, height: 914), xRadius: 190, yRadius: 190)
outline.lineWidth = 15
NSColor(calibratedRed: 0.86, green: 0.68, blue: 0.41, alpha: 1).setStroke()
outline.stroke()
let crown = "♛" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 555),
    .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.81, blue: 0.56, alpha: 1)
]
let bounds = crown.size(withAttributes: attrs)
crown.draw(at: NSPoint(x: (1024-bounds.width)/2, y: (1024-bounds.height)/2-20), withAttributes: attrs)
icon.unlockFocus()
guard let tiff = icon.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("App icon could not be generated")
}
let path = "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
try png.write(to: URL(fileURLWithPath: path))
print("Generated \(path)")
