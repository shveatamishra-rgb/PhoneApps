import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
let background = NSGradient(
    starting: NSColor(red: 0.16, green: 0.31, blue: 0.78, alpha: 1),
    ending: NSColor(red: 0.40, green: 0.27, blue: 0.84, alpha: 1)
)!
background.draw(in: canvas, angle: -45)

NSColor(red: 0.39, green: 0.84, blue: 0.75, alpha: 0.16).setFill()
NSBezierPath(ovalIn: NSRect(x: 515, y: 520, width: 560, height: 560)).fill()

let funnel = NSBezierPath()
funnel.move(to: NSPoint(x: 254, y: 724))
funnel.line(to: NSPoint(x: 770, y: 724))
funnel.line(to: NSPoint(x: 580, y: 498))
funnel.line(to: NSPoint(x: 580, y: 324))
funnel.curve(
    to: NSPoint(x: 549, y: 273),
    controlPoint1: NSPoint(x: 580, y: 303),
    controlPoint2: NSPoint(x: 568, y: 283)
)
funnel.line(to: NSPoint(x: 469, y: 230))
funnel.curve(
    to: NSPoint(x: 429, y: 254),
    controlPoint1: NSPoint(x: 451, y: 220),
    controlPoint2: NSPoint(x: 429, y: 233)
)
funnel.line(to: NSPoint(x: 429, y: 498))
funnel.close()
NSColor.white.setFill()
funnel.fill()

NSColor(red: 0.39, green: 0.84, blue: 0.75, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 254, y: 747, width: 68, height: 68)).fill()
NSBezierPath(ovalIn: NSRect(x: 702, y: 747, width: 68, height: 68)).fill()
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: 478, y: 793, width: 68, height: 68)).fill()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let representation = NSBitmapImageRep(data: tiffData),
    let pngData = representation.representation(using: .png, properties: [:])
else {
    fatalError("Could not render icon")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try pngData.write(to: outputURL)
