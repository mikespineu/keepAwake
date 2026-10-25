import SwiftUI

@main
enum Entry {
    static func main() {
        // `KeepAwake --snapshot <dir>` renders README screenshots and exits.
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot") {
            let path = CommandLine.arguments.dropFirst(index + 1).first ?? "."
            MainActor.assumeIsolated {
                Snapshot.run(outputDirectory: URL(fileURLWithPath: path))
            }
            return
        }
        KeepAwakeApp.main()
    }
}

struct KeepAwakeApp: App {
    @State private var controller = KeepAwakeController()

    var body: some Scene {
        MenuBarExtra {
            MenuView(controller: controller)
        } label: {
            MenuBarLabel(controller: controller)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    let controller: KeepAwakeController

    // MenuBarExtra keeps only a plain Image and Text from its label and drops their
    // modifiers (font, spacing), so the label is drawn into one template image instead.
    var body: some View {
        Image(nsImage: image)
            .accessibilityLabel(controller.menuBarText.map { "keepAwake, \($0) left" } ?? "keepAwake")
    }

    private var content: some View {
        HStack(spacing: 5) {
            Image(nsImage: .mug(active: controller.isActive))
            if let text = controller.menuBarText {
                // Monospaced so the item does not change width as the countdown ticks.
                Text(text).font(.system(size: NSFont.menuBarFont(ofSize: 0).pointSize, design: .monospaced))
            }
        }
        .foregroundStyle(.black)
    }

    private var image: NSImage {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}

extension NSImage {
    // Same mug as the app icon (scripts/generate-icon.swift). Comes from the asset catalog
    // in Xcode builds and from loose PNGs in build.sh builds.
    static func mug(active: Bool) -> NSImage {
        let image = NSImage(named: active ? "MenuBarIconActive" : "MenuBarIcon") ?? NSImage()
        image.isTemplate = true
        return image
    }
}
