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
        // `KeepAwake hold|release|start|stop|status …` talks to the running app and exits.
        let args = Array(CommandLine.arguments.dropFirst())
        if let command = args.first, AgentCLI.commands.contains(command) {
            exit(AgentCLI.run(args, client: AgentClient(), out: { print($0) }, err: printError))
        }
        // Claude Code and Cursor hooks: `KeepAwake hook --pid $PPID`, event JSON on stdin.
        if args.first == "hook" {
            exit(AgentHook.run(args: args, stdin: .standardInput, client: AgentClient(), out: { print($0) }))
        }
        // MCP stdio server for Claude Code, Cursor and other MCP clients.
        if args.first == "mcp" {
            MCPServer(client: AgentClient()).run()
            exit(0)
        }
        KeepAwakeApp.main()
    }

    private static func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}

struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView(controller: appDelegate.controller)
        } label: {
            MenuBarLabel(controller: appDelegate.controller)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the controller so `keepawake://` URLs reach it, even when they launched the app.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = KeepAwakeController(statusURL: StatusFile.defaultURL)

    func application(_ application: NSApplication, open urls: [URL]) {
        for command in urls.compactMap(AgentCommand.init(url:)) {
            controller.handle(command)
        }
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
            Image(nsImage: .mug(active: controller.isAwake))
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
