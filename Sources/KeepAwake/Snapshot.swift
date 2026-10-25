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
                // Show the lid toggle as a fresh install sees it, whatever this Mac has installed.
                let lid = LidSleepOverride(fileExists: { _ in false }, helperScriptPath: "snapshot", isSandboxed: false)
                let controller = KeepAwakeController(defaults: UserDefaults(suiteName: suiteName)!, lid: lid)
                if active {
                    controller.start(minutes: 90)
                    controller.handle(.hold(HoldRequest(id: "claude-code:snapshot", name: "Claude Code", minutes: 30, pid: nil)))
                }

                let state = active ? "active" : "inactive"
                let file = outputDirectory.appendingPathComponent("menu-\(state)-\(name).png")
                guard let menu = render(SnapshotScene(controller: controller), appearance: appearance) else { continue }
                write(menu, to: file)

                // 1440×900 pt → 2880×1800 px on Retina, a valid Mac App Store size.
                // The menu is embedded as a bitmap so AppKit controls scale cleanly.
                let menuImage = NSImage(size: NSSize(width: menu.pixelsWide / 2, height: menu.pixelsHigh / 2))
                menuImage.addRepresentation(menu)
                let store = AppStoreScene(menu: menuImage, active: active)
                if let rep = render(store, appearance: appearance) {
                    write(rep, to: appStoreDirectory.appendingPathComponent("appstore-\(state)-\(name).png"))
                }
                controller.turnOff()
            }
        }
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private static var appStoreDirectory: URL {
        let url = URL(fileURLWithPath: "docs/appstore")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func render(_ view: some View, appearance: NSAppearance.Name) -> NSBitmapImageRep? {
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

        defer { window.orderOut(nil) }
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return nil }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        return rep
    }

    private static func write(_ rep: NSBitmapImageRep, to url: URL) {
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
        print("Wrote \(url.path) (\(rep.pixelsWide)×\(rep.pixelsHigh))")
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

            // A folder that doesn't exist, so no agent shows as connected.
            MenuView(controller: controller, installer: AgentInstaller(home: URL(fileURLWithPath: "/nonexistent")))
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

/// Mac App Store screenshot: headline on the left, the menu on the right.
private struct AppStoreScene: View {
    let menu: NSImage
    let active: Bool

    private var headline: String { active ? "Stops on its own." : "Keep your Mac awake." }
    private var subtitle: String {
        active
            ? "When the time is up or the battery drops below your limit, keepAwake lets your Mac sleep again."
            : "15 minutes, a few hours, or always. One click in the menu bar."
    }

    var body: some View {
        HStack(spacing: 64) {
            VStack(alignment: .leading, spacing: 24) {
                Text(headline)
                    .font(.system(size: 64, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 28, weight: .regular))
                    .opacity(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(width: 480, alignment: .leading)

            Image(nsImage: menu)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: 700)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.35), radius: 30, y: 16)
        }
        .frame(width: 1440, height: 900)
        .background(
            LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.42), Color(red: 0.45, green: 0.25, blue: 0.52)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
