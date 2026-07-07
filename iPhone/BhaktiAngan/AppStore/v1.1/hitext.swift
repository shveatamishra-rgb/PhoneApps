// Render (Devanagari) text to a transparent PNG using CoreText shaping.
// usage: swift hitext.swift "line1\nline2" "ITFDevanagari-Bold" 84 240,212,146 out.png [linespacing]
import AppKit

let args = CommandLine.arguments
guard args.count >= 6 else { fputs("usage: hitext.swift text font size r,g,b out.png [linespacing]\n", stderr); exit(1) }
let text = args[1].replacingOccurrences(of: "\\n", with: "\n")
let fontName = args[2]
let size = CGFloat(Double(args[3])!)
let rgb = args[4].split(separator: ",").map { CGFloat(Double($0)!)/255.0 }
let outPath = args[5]
let lineSpacing = args.count > 6 ? CGFloat(Double(args[6])!) : 14

guard let font = NSFont(name: fontName, size: size) else {
    fputs("FONT NOT FOUND: \(fontName)\n", stderr); exit(2)
}
let para = NSMutableParagraphStyle()
para.alignment = .center
para.lineSpacing = lineSpacing
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(calibratedRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1),
    .paragraphStyle: para,
]
let str = NSAttributedString(string: text, attributes: attrs)
let bounds = str.boundingRect(with: NSSize(width: 2400, height: 2400),
                              options: [.usesLineFragmentOrigin, .usesFontLeading])
let pad: CGFloat = 20
let w = Int(ceil(bounds.width) + pad*2), h = Int(ceil(bounds.height) + pad*2)

let img = NSImage(size: NSSize(width: w, height: h))
img.lockFocus()
str.draw(with: NSRect(x: pad, y: pad, width: bounds.width, height: bounds.height),
         options: [.usesLineFragmentOrigin, .usesFontLeading])
img.unlockFocus()

guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { exit(3) }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) \(w)x\(h)")
