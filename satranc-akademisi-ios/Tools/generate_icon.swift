import AppKit
import Foundation

// Premium, original Satranç Akademisi app icon.
// Generated at build time: 1024px, opaque, full-bleed (iOS applies its own mask).
// No external downloaded artwork or trademarked photography.
let side: CGFloat = 1024
let canvas = NSRect(x: 0, y: 0, width: side, height: side)
let icon = NSImage(size: canvas.size)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

let midnight = color(0.022, 0.050, 0.090)
let royalBlue = color(0.10, 0.19, 0.27)
let bronze = color(0.60, 0.39, 0.20)
let champagne = color(0.99, 0.85, 0.61)
let gold = color(0.89, 0.66, 0.35)

icon.lockFocus()

NSGradient(starting: royalBlue, ending: midnight)?
    .draw(in: NSBezierPath(rect: canvas), angle: 125)

// Very subtle checker texture, receding toward the base of the icon.
for row in 0..<8 {
    for column in 0..<8 where (row + column).isMultiple(of: 2) {
        let square = NSRect(
            x: CGFloat(column) * 128,
            y: CGFloat(row) * 128,
            width: 128,
            height: 128
        )
        color(1, 0.86, 0.57, 0.025).setFill()
        NSBezierPath(rect: square).fill()
    }
}

// Large, low-opacity atmospheric glow behind the emblem.
let halo = NSBezierPath(ovalIn: NSRect(x: 140, y: 105, width: 744, height: 744))
NSGradient(
    colors: [
        color(0.90, 0.67, 0.37, 0.20),
        color(0.90, 0.67, 0.37, 0.07),
        color(0.90, 0.67, 0.37, 0.0)
    ]
)?.draw(in: halo, relativeCenterPosition: NSPoint(x: 0, y: 0))

// Art-deco double medal rings.
let outer = NSBezierPath(ovalIn: NSRect(x: 99, y: 99, width: 826, height: 826))
outer.lineWidth = 17
gold.setStroke()
outer.stroke()

let inner = NSBezierPath(ovalIn: NSRect(x: 119, y: 119, width: 786, height: 786))
inner.lineWidth = 3
color(1, 0.91, 0.71, 0.55).setStroke()
inner.stroke()

let medallion = NSBezierPath(ovalIn: NSRect(x: 145, y: 145, width: 734, height: 734))
NSGradient(starting: color(0.09, 0.20, 0.28), ending: midnight)?
    .draw(in: medallion, angle: 120)

// Fine decorative stars on top edge.
for x in [285.0, 512.0, 739.0] {
    let dot = NSBezierPath(ovalIn: NSRect(x: x - 5, y: 835, width: 10, height: 10))
    champagne.setFill()
    dot.fill()
}

// The knight is the signature mark: a chess piece rather than a generic icon.
let knight = "♞" as NSString
let font = NSFont.systemFont(ofSize: 650, weight: .regular)
let para = NSMutableParagraphStyle()
para.alignment = .center
let textFrame = NSRect(x: 105, y: 128, width: 814, height: 740)

NSGraphicsContext.saveGraphicsState()
let drop = NSShadow()
drop.shadowColor = color(0, 0, 0, 0.62)
drop.shadowBlurRadius = 33
drop.shadowOffset = NSSize(width: 0, height: -22)
drop.set()
knight.draw(in: textFrame, withAttributes: [
    .font: font, .foregroundColor: bronze, .paragraphStyle: para
])
NSGraphicsContext.restoreGraphicsState()

knight.draw(in: NSRect(x: 103, y: 142, width: 814, height: 740), withAttributes: [
    .font: font, .foregroundColor: champagne, .paragraphStyle: para
])

// Fine floor line for a strong silhouette at small app-icon sizes.
let floor = NSBezierPath()
floor.move(to: NSPoint(x: 297, y: 236))
floor.line(to: NSPoint(x: 727, y: 236))
floor.lineWidth = 9
floor.lineCapStyle = .round
gold.setStroke()
floor.stroke()

icon.unlockFocus()

guard let tiff = icon.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Premium chess icon rendering failed")
}

let folder = URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let output = folder.appendingPathComponent("AppIcon.png")
try png.write(to: output)
print("Generated original premium 1024x1024 chess knight: \(output.path)")
