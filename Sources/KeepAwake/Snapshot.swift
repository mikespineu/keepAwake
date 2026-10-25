import AppKit
import SwiftUI

/// Renders the real menu views to PNG files for the README.
/// Uses a throwaway UserDefaults suite so the user's settings are untouched.
@MainActor
enum Snapshot {
    static func run(outputDirectory: URL) {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let suiteName = "keepAwake.snapshot"
        let appearances: [(name: String, appearance: NSAppearance.Name)] = [("light", .aqua), ("dark", .darkAqua)]

        for (name, appearance) in appearances {
            for active in [false, true] {
                UserDefaults().removePersistentDomain(forName: suiteName)
                let controller = KeepAwakeController(defaults: UserDefaults(suiteName: suiteName)!)
                if active { controller.start(minutes: 90) }

                let file = outputDirectory.appendingPathComponent("menu-\(active ? "active" : "inactive")-\(name).png")
                render(SnapshotScene(controller: controller), appearance: appearance, to: file)
                controller.stop()
            }
        }
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private static func render(_ view: some View, appearance: NSAppearance.Name, to url: URL) {
        let hosting = NSHostingView(rootView: view)
        hosting.appearance = NSAppearance(named: appearance)
        hosting.frame.size = hosting.fittingSize

        let window = NSWindow(
            contentRect: NSRect(origin: NSPoint(x: -10_000, y: -10_000), size: hosting.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.appearance = hosting.appearance
        window.contentView = hosting
        window.orderFrontRegardless()
        hosting.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
        window.orderOut(nil)
        print("Wrote \(url.path)")
    }
}

/// Menu bar strip with the status item, and the menu panel below it.
private struct SnapshotScene: View {
    let controller: KeepAwakeController

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 14) {
                Spacer()
                MenuBarLabel(controller: controller)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(.primary.opacity(0.15)))
                Image(systemName: "wifi")
                Image(systemName: "battery.75percent")
                Text(controller.now.formatted(date: .omitted, time: .shortened))
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))

            MenuView(controller: controller)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.15)))
                .padding(.trailing, 70)
                .padding(.bottom, 24)
        }
        .frame(width: 460)
        .background(
            LinearGradient(colors: [Color(red: 0.36, green: 0.42, blue: 0.75), Color(red: 0.75, green: 0.45, blue: 0.62)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
