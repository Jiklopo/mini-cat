import AppKit

let width = 56, height = 36

struct Step {
    var dx: CGFloat
    var lift: CGFloat
}

let footCycle = [
    Step(dx: 2, lift: 0), Step(dx: 1, lift: 0), Step(dx: 0, lift: 0), Step(dx: -1, lift: 0),
    Step(dx: -2, lift: 0), Step(dx: -1, lift: 2), Step(dx: 1, lift: 2), Step(dx: 2, lift: 1),
]

struct Pose {
    var a: Step
    var b: Step
    var bob: CGFloat
    var squash: (x: CGFloat, y: CGFloat)
    var rock: CGFloat
}

let poses = (0..<8).map { (i: Int) -> Pose in
    let squash: (x: CGFloat, y: CGFloat) = i % 4 == 0 ? (1.05, 0.92) : i % 4 == 1 ? (0.98, 1.03) : (1, 1)
    let rock: CGFloat = 1.5 * sin(CGFloat(i) * .pi / 4)
    return Pose(a: footCycle[i], b: footCycle[(i + 4) % 8], bob: i % 4 == 0 ? -1 : 0, squash: squash, rock: rock)
}

func draw(_ pose: Pose, scale: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * scale, pixelsHigh: height * scale,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    ctx.translateBy(x: -4, y: 0)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.setStrokeColor(NSColor.black.cgColor)

    func leg(_ x: CGFloat, _ step: Step) {
        ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 1 + step.lift, width: 6, height: 7), cornerWidth: 3, cornerHeight: 3, transform: nil))
        ctx.fillPath()
    }
    leg(13, pose.a)
    leg(20, pose.b)
    leg(34, pose.b)
    leg(42, pose.a)

    ctx.translateBy(x: 31, y: 5 + pose.bob)
    ctx.rotate(by: pose.rock * .pi / 180)
    ctx.scaleBy(x: pose.squash.x, y: pose.squash.y)
    ctx.translateBy(x: -31, y: -7)
    ctx.move(to: CGPoint(x: 20, y: 7))
    ctx.addLine(to: CGPoint(x: 43, y: 7))
    ctx.addCurve(to: CGPoint(x: 53, y: 16), control1: CGPoint(x: 50, y: 7), control2: CGPoint(x: 53, y: 10))
    ctx.addQuadCurve(to: CGPoint(x: 52, y: 28), control: CGPoint(x: 54, y: 22))
    ctx.addLine(to: CGPoint(x: 51, y: 35))
    ctx.addLine(to: CGPoint(x: 45, y: 31))
    ctx.addQuadCurve(to: CGPoint(x: 37, y: 31), control: CGPoint(x: 41, y: 32.5))
    ctx.addLine(to: CGPoint(x: 33, y: 35))
    ctx.addLine(to: CGPoint(x: 30.5, y: 28.5))
    ctx.addQuadCurve(to: CGPoint(x: 28, y: 27.3), control: CGPoint(x: 29.3, y: 27))
    ctx.addCurve(to: CGPoint(x: 11, y: 15), control1: CGPoint(x: 21.5, y: 30.5), control2: CGPoint(x: 10, y: 28))
    ctx.addCurve(to: CGPoint(x: 20, y: 7), control1: CGPoint(x: 11, y: 9), control2: CGPoint(x: 15, y: 7))
    ctx.fillPath()

    ctx.setFillColor(NSColor.clear.cgColor)
    ctx.setBlendMode(.copy)
    ctx.fillEllipse(in: CGRect(x: 33, y: 16.5, width: 3.5, height: 3.5))
    ctx.fillEllipse(in: CGRect(x: 46, y: 16.5, width: 3.5, height: 3.5))
    ctx.setStrokeColor(NSColor.clear.cgColor)
    ctx.setLineWidth(1.3)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: 38.5, y: 16))
    ctx.addQuadCurve(to: CGPoint(x: 41.25, y: 16), control: CGPoint(x: 39.9, y: 13))
    ctx.addQuadCurve(to: CGPoint(x: 44, y: 16), control: CGPoint(x: 42.6, y: 13))
    ctx.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"
let scale = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2])! : 1
for (i, pose) in poses.enumerated() {
    try! draw(pose, scale: scale).write(to: URL(fileURLWithPath: "\(out)/bongo-frame-\(i).png"))
}
