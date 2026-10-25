// Generates the app icon (Resources/Assets.xcassets/AppIcon.appiconset, Resources/AppIcon.icns)
// and the matching menu bar template images (MenuBarIcon*.imageset in the same catalog).
// Usage: swift scripts/generate-icon.swift
import AppKit
import SwiftUI

// Flat blueprint style: one ink colour on one paper colour, no gradients, no shadows.
let paper = Color(white: 0.07)
let ink = Color.white

// Mug body in the 1024 canvas; the handle sticks out ~110 px on the right.
// Optically centred: the light handle counts for about half, so the body sits a quarter
// of the handle left of centre, and the whole mug a little above the geometric middle.
let mug = CGRect(x: 264, y: 284, width: 440, height: 440)

struct IconView: View {
    // Large sizes get the blueprint grid; small ones only the glyph, drawn heavier.
    var detailed: Bool

    // Apple's macOS icon grid: 1024 canvas, 824 body, continuous corners.
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(paper)
                .frame(width: 824, height: 824)
            if detailed { BlueprintGrid() }
            // Hand-drawn glyph (SF Symbols may not be used in app icons).
            MugGlyph(lineWidth: detailed ? 48 : 68)
        }
        .frame(width: 1024, height: 1024)
    }
}

struct BlueprintGrid: View {
    private func lines(every step: CGFloat) -> Path {
        Path { p in
            for v in stride(from: 100, through: 924, by: step) {
                p.move(to: CGPoint(x: v, y: 100))
                p.addLine(to: CGPoint(x: v, y: 924))
                p.move(to: CGPoint(x: 100, y: v))
                p.addLine(to: CGPoint(x: 924, y: v))
            }
        }
    }

    var body: some View {
        ZStack {
            lines(every: 824 / 20).stroke(ink.opacity(0.07), lineWidth: 2)
            lines(every: 824 / 4).stroke(ink.opacity(0.14), lineWidth: 3)
        }
        .mask(RoundedRectangle(cornerRadius: 185, style: .continuous).frame(width: 824, height: 824))
    }
}

// Mug with a terminal prompt `>_` on it.
struct MugGlyph: View {
    var lineWidth: CGFloat
    var color = ink
    // Transparent background: the parts that hide the handle's inner half are cut out
    // instead of painted with `paper` (menu bar template images).
    var transparent = false
    // Solid mug with the prompt cut out (menu bar, active state). Needs `transparent`.
    var filled = false

    private func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: mug.minX + mug.width * x, y: mug.minY + mug.height * y)
    }

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: mug.width * 0.24,
            bottomTrailingRadius: mug.width * 0.24, topTrailingRadius: 0, style: .continuous
        )
        ZStack {
            // Handle (the body covers its inner half)
            RoundedRectangle(cornerRadius: mug.width * 0.17, style: .continuous)
                .stroke(color, lineWidth: lineWidth)
                .frame(width: mug.width * 0.5, height: mug.height * 0.56)
                .position(x: mug.maxX, y: mug.minY + mug.height * 0.44)
            shape.fill(transparent && !filled ? color : paper)
                .blendMode(transparent && !filled ? .destinationOut : .normal)
                .frame(width: mug.width, height: mug.height)
                .position(x: mug.midX, y: mug.midY)
            shape.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                .frame(width: mug.width, height: mug.height)
                .position(x: mug.midX, y: mug.midY)
            // Prompt
            Path { p in
                p.move(to: at(0.22, 0.30))
                p.addLine(to: at(0.40, 0.46))
                p.addLine(to: at(0.22, 0.62))
                p.move(to: at(0.53, 0.64))
                p.addLine(to: at(0.77, 0.64))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth * 0.85, lineCap: .round, lineJoin: .round))
            .blendMode(filled ? .destinationOut : .normal)
        }
        .compositingGroup()
        .frame(width: 1024, height: 1024)
    }
}

// Menu bar template image: black on transparent, cropped to the glyph, 16 pt tall
// like the other menu bar icons.
// The line is heavier than in the icon so it reads as ~1.75 pt in the menu bar.
let menuBarLineWidth: CGFloat = 54
let menuBarHeight = 16

struct MenuBarIconView: View {
    var filled: Bool
    var width: CGFloat

    // Glyph bounds: mug body plus the handle sticking out by half its width.
    static let crop = CGRect(
        x: mug.minX - menuBarLineWidth / 2, y: mug.minY - menuBarLineWidth / 2,
        width: mug.width * 1.25 + menuBarLineWidth, height: mug.height + menuBarLineWidth
    )

    var body: some View {
        let crop = Self.crop
        MugGlyph(lineWidth: menuBarLineWidth, color: .black, transparent: true, filled: filled)
            .frame(width: 1024, height: 1024)
            .offset(x: -crop.minX - (crop.width - width) / 2, y: -crop.minY)
            .frame(width: width, height: crop.height, alignment: .topLeading)
            .clipped()
    }
}

func writePNG(_ image: CGImage, size: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    context.imageInterpolation = .high
    NSGraphicsContext.current = context
    context.cgContext.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

MainActor.assumeIsolated {
    @MainActor func render(detailed: Bool) -> CGImage {
        let renderer = ImageRenderer(content: IconView(detailed: detailed))
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("Rendering failed") }
        return image
    }
    let master = render(detailed: true)
    let simple = render(detailed: false)

    let fm = FileManager.default
    let resources = URL(fileURLWithPath: "Resources")
    let appIconSet = resources.appendingPathComponent("Assets.xcassets/AppIcon.appiconset")
    let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
    try? fm.removeItem(at: iconset)
    try! fm.createDirectory(at: appIconSet, withIntermediateDirectories: true)
    try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)

    var images: [[String: String]] = []
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let pixels = points * scale
            let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
            // The grid turns to noise below 128 px.
            let source = pixels < 128 ? simple : master
            writePNG(source, size: pixels, to: appIconSet.appendingPathComponent(name))
            writePNG(source, size: pixels, to: iconset.appendingPathComponent(name))
            images.append(["idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)", "filename": name])
        }
    }

    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    try! json.write(to: appIconSet.appendingPathComponent("Contents.json"))
    let catalogInfo = try! JSONSerialization.data(withJSONObject: ["info": ["author": "xcode", "version": 1]], options: [.prettyPrinted])
    try! catalogInfo.write(to: resources.appendingPathComponent("Assets.xcassets/Contents.json"))

    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
    try! iconutil.run()
    iconutil.waitUntilExit()
    print("Wrote \(appIconSet.path) and Resources/AppIcon.icns")

    // Whole pixels wide at @1x; the glyph is centred in the extra fraction.
    let crop = MenuBarIconView.crop
    let unitsPerPoint = crop.height / CGFloat(menuBarHeight)
    let width = (crop.width / unitsPerPoint).rounded(.up) * unitsPerPoint
    for (name, filled) in [("MenuBarIcon", false), ("MenuBarIconActive", true)] {
        let imageSet = resources.appendingPathComponent("Assets.xcassets/\(name).imageset")
        try! fm.createDirectory(at: imageSet, withIntermediateDirectories: true)
        var images: [[String: String]] = []
        for scale in [1, 2] {
            let file = scale == 1 ? "\(name).png" : "\(name)@2x.png"
            let renderer = ImageRenderer(content: MenuBarIconView(filled: filled, width: width))
            renderer.scale = CGFloat(scale) / unitsPerPoint
            guard let image = renderer.cgImage else { fatalError("Rendering failed") }
            let rep = NSBitmapImageRep(cgImage: image)
            try! rep.representation(using: .png, properties: [:])!.write(to: imageSet.appendingPathComponent(file))
            images.append(["idiom": "universal", "scale": "\(scale)x", "filename": file])
        }
        let contents: [String: Any] = [
            "images": images,
            "info": ["author": "xcode", "version": 1],
            "properties": ["template-rendering-intent": "template"],
        ]
        let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        try! json.write(to: imageSet.appendingPathComponent("Contents.json"))
        print("Wrote \(imageSet.path)")
    }
}
