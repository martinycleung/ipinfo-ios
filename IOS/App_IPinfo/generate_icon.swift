#!/usr/bin/env swift

import Foundation
import AppKit

// Create a 1024x1024 app icon
let size = NSSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

// Background gradient - modern blue gradient
let gradient = NSGradient(colors: [
    NSColor(red: 0.18, green: 0.55, blue: 1.0, alpha: 1.0),   // Bright blue
    NSColor(red: 0.08, green: 0.38, blue: 0.92, alpha: 1.0)   // Deep blue
])!
gradient.draw(in: NSRect(origin: .zero, size: size), angle: -90)

// Draw globe icon - centered and larger
let globeSize: CGFloat = 580
let globeRect = NSRect(
    x: (size.width - globeSize) / 2,
    y: (size.height - globeSize) / 2 + 20,
    width: globeSize,
    height: globeSize
)

// Globe circle with subtle shadow effect
let shadowPath = NSBezierPath(ovalIn: globeRect.offsetBy(dx: 4, dy: -4))
NSColor.black.withAlphaComponent(0.15).setFill()
shadowPath.fill()

let globePath = NSBezierPath(ovalIn: globeRect)
NSColor.white.withAlphaComponent(0.97).setFill()
globePath.fill()

// Globe outline
globePath.lineWidth = 6
NSColor(red: 0.0, green: 0.45, blue: 0.95, alpha: 0.3).setStroke()
globePath.stroke()

// Globe lines (latitude) - cleaner design
NSColor(red: 0.0, green: 0.45, blue: 0.95, alpha: 0.5).setStroke()
for i in 1...4 {
    let yOffset = CGFloat(i) * globeSize / 5
    let lineWidth = sqrt(pow(globeSize/2, 2) - pow(yOffset - globeSize/2, 2)) * 2
    let lineRect = NSRect(
        x: globeRect.midX - lineWidth/2,
        y: globeRect.minY + yOffset - 8,
        width: lineWidth,
        height: 16
    )
    let linePath = NSBezierPath(ovalIn: lineRect)
    linePath.lineWidth = 6
    linePath.stroke()
}

// Globe lines (longitude) - cleaner
for i in 0...2 {
    let angle = CGFloat(i) * 60 - 30
    let radians = angle * .pi / 180
    let ellipseWidth = globeSize * cos(radians) * 0.85
    let ellipseRect = NSRect(
        x: globeRect.midX - ellipseWidth/2,
        y: globeRect.minY + 15,
        width: ellipseWidth,
        height: globeSize - 30
    )
    let ellipsePath = NSBezierPath(ovalIn: ellipseRect)
    ellipsePath.lineWidth = 6
    ellipsePath.stroke()
}

// Center equator - more prominent
let equatorPath = NSBezierPath(ovalIn: globeRect.insetBy(dx: 15, dy: globeSize * 0.44))
equatorPath.lineWidth = 8
NSColor(red: 0.0, green: 0.45, blue: 0.95, alpha: 0.7).setStroke()
equatorPath.stroke()

// Location pin - larger and more prominent
let pinSize: CGFloat = 200
let pinX = globeRect.midX + 90
let pinY = globeRect.midY + 50

// Pin shadow
let pinShadowHead = NSBezierPath(ovalIn: NSRect(x: pinX - pinSize/4 + 3, y: pinY - 3, width: pinSize/2, height: pinSize/2))
NSColor.black.withAlphaComponent(0.2).setFill()
pinShadowHead.fill()

// Pin head (circle) with gradient
let pinHeadRect = NSRect(x: pinX - pinSize/4, y: pinY, width: pinSize/2, height: pinSize/2)
let pinGradient = NSGradient(colors: [
    NSColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0),
    NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
])!
let pinHead = NSBezierPath(ovalIn: pinHeadRect)
pinGradient.draw(in: pinHead, angle: -90)

// Pin point (triangle)
let pinPoint = NSBezierPath()
pinPoint.move(to: NSPoint(x: pinX - pinSize/4 + 5, y: pinY + pinSize/4 - 5))
pinPoint.line(to: NSPoint(x: pinX, y: pinY - pinSize/3))
pinPoint.line(to: NSPoint(x: pinX + pinSize/4 - 5, y: pinY + pinSize/4 - 5))
pinPoint.close()
NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0).setFill()
pinPoint.fill()

// Pin inner circle (white dot)
let innerCircle = NSBezierPath(ovalIn: pinHeadRect.insetBy(dx: 20, dy: 20))
NSColor.white.setFill()
innerCircle.fill()

image.unlockFocus()

// Save to file
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "/Users/yucheungleung/IOS/App_IPinfo/App_IPinfo/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    try? pngData.write(to: url)
    print("Icon saved to: \(url.path)")
} else {
    print("Failed to save icon")
}
