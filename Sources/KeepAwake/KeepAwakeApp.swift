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

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: .mug(active: controller.isActive))
                .accessibilityLabel("keepAwake")
            if let text = controller.menuBarText {
                Text(text).monospacedDigit()
            }
        }
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
