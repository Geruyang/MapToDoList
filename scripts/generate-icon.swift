import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Draw into a supported 32-bit RGB context. A 24-bit NSBitmapImageRep can
// encode pixels but does not reliably provide a drawable graphics context.
let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(data: nil, width: size, height: size,
                              bitsPerComponent: 8, bytesPerRow: size * 4,
                              space: colorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Could not create icon drawing context")
}
func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [red, green, blue, 1])!
}
context.setFillColor(color(0.09, 0.25, 0.21))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setStrokeColor(color(0.17, 0.36, 0.30))
context.setLineWidth(60)
context.setLineCap(.round)
context.move(to: CGPoint(x: -100, y: 250))
context.addCurve(to: CGPoint(x: 1110, y: 640), control1: CGPoint(x: 420, y: 480), control2: CGPoint(x: 660, y: 100))
context.strokePath()
let pin = CGMutablePath()
pin.move(to: CGPoint(x: 512, y: 190))
pin.addCurve(to: CGPoint(x: 260, y: 606), control1: CGPoint(x: 465, y: 240), control2: CGPoint(x: 260, y: 405))
pin.addCurve(to: CGPoint(x: 512, y: 860), control1: CGPoint(x: 260, y: 748), control2: CGPoint(x: 372, y: 860))
pin.addCurve(to: CGPoint(x: 764, y: 606), control1: CGPoint(x: 652, y: 860), control2: CGPoint(x: 764, y: 748))
pin.addCurve(to: CGPoint(x: 512, y: 190), control1: CGPoint(x: 764, y: 405), control2: CGPoint(x: 559, y: 240))
pin.closeSubpath()
context.addPath(pin)
context.setFillColor(color(0.97, 0.95, 0.90))
context.fillPath()
context.setStrokeColor(color(0.80, 0.39, 0.29))
context.setLineWidth(51)
context.setLineCap(.round)
context.setLineJoin(.round)
context.move(to: CGPoint(x: 403, y: 594))
context.addLine(to: CGPoint(x: 479, y: 520))
context.addLine(to: CGPoint(x: 626, y: 674))
context.strokePath()
guard CommandLine.arguments.count == 2, let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Usage: swift generate-icon.swift output.png")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not encode icon PNG") }
