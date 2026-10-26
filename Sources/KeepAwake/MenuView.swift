import SwiftUI

struct MenuView: View {
    @Bindable var controller: KeepAwakeController

    @State private var connecting: AgentTarget?
    @State private var connectMessage: String?
    var installer = AgentInstaller()

    private let presets: [(label: String, minutes: Int?)] = [
        ("15 min", 15), ("30 min", 30), ("1 h", 60),
        ("2 h", 120), ("4 h", 240), ("Always", nil),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            if controller.isAwake {
                activeSection
            }
            // Still offered while only agents hold the Mac awake.
            if !controller.isActive {
                durationSection
            }

            if let reason = controller.lastStopReason, !controller.isActive {
                Label(reason, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            batterySection

            Divider()

            agentsSection

            Divider()

            optionsSection

            Divider()

            HStack {
                Spacer()
                Button("Quit keepAwake") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 300)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: .mug(active: controller.isAwake))
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: 22)
                .foregroundStyle(controller.isAwake ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("keepAwake").font(.headline)
                Text(controller.statusText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activeText)
                .font(.callout)
            HStack(spacing: 8) {
                Button {
                    controller.turnOff()
                } label: {
                    Label("Turn Off", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                if controller.screenLockAvailable {
                    Button {
                        controller.lockScreen()
                    } label: {
                        Label("Lock Screen", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .help("Lock the screen. Your Mac and its agents keep running.")
                }
            }
            .controlSize(.large)
        }
    }

    private var activeText: String {
        guard controller.isActive else {
            return "Kept awake by \(controller.holds.holds.map(\.name).joined(separator: ", "))."
        }
        return controller.endDate == nil
            ? "Your Mac stays awake until you turn it off."
            : "Your Mac stays awake until the countdown ends."
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep awake for:").font(.callout)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                ForEach(presets, id: \.label) { preset in
                    Button {
                        controller.start(minutes: preset.minutes)
                    } label: {
                        Text(preset.label).frame(maxWidth: .infinity)
                    }
                }
            }

            HStack(spacing: 8) {
                Stepper(value: $controller.customDays, in: 0...KeepAwakeController.maxCustomDays) {
                    Text("\(controller.customDays) d").monospacedDigit()
                }
                // At the maximum number of days hours and minutes stay at 0.
                let atMaxDays = controller.customDays >= KeepAwakeController.maxCustomDays
                Stepper(value: $controller.customHours, in: 0...(atMaxDays ? 0 : 23)) {
                    Text("\(controller.customHours) h").monospacedDigit()
                }
                Stepper(value: $controller.customMinutes, in: 0...(atMaxDays ? 0 : 55), step: 5) {
                    Text("\(controller.customMinutes) min").monospacedDigit()
                }
                Spacer(minLength: 0)
                Button("Start") { controller.startCustom() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(controller.customDays == 0 && controller.customHours == 0 && controller.customMinutes == 0)
            }
        }
    }

    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Turn off when battery < \(controller.batteryThreshold)%", isOn: $controller.batteryLimitEnabled)

            if controller.batteryLimitEnabled {
                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(controller.batteryThreshold) },
                            set: { controller.batteryThreshold = Int($0) }
                        ),
                        in: 5...95,
                        step: 5
                    )
                    Text("\(controller.batteryThreshold)%")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
                Text("Applies only when running on battery.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(controller.batteryText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Let AI agents keep your Mac awake", isOn: $controller.agentControlEnabled)

            ForEach(controller.holds.holds) { hold in
                HStack(spacing: 6) {
                    Text("\(hold.name) · until \(hold.expires.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .monospacedDigit()
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 0)
                    Button {
                        controller.release(holdID: hold.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Let \(hold.name) stop keeping the Mac awake")
                    .accessibilityLabel("Release \(hold.name)")
                }
            }

            // The sandboxed build can't write the agents' config files.
            if controller.agentControlEnabled && !AgentInstaller.isSandboxed {
                HStack(spacing: 6) {
                    Text("Connect:").font(.caption).foregroundStyle(.secondary)
                    ForEach(AgentTarget.allCases, id: \.self) { target in
                        Button {
                            connect(target)
                        } label: {
                            if connecting == target {
                                ProgressView().controlSize(.mini)
                            } else if installer.isInstalled(target) {
                                Label(target.displayName, systemImage: "checkmark")
                            } else {
                                Text(target.displayName)
                            }
                        }
                        .disabled(connecting != nil)
                        .help(installer.isInstalled(target)
                              ? "Connected. Click to set up \(target.displayName) again."
                              : "Add keepAwake's hooks and MCP server to \(target.displayName).")
                    }
                }
                .controlSize(.small)

                Text(connectMessage ?? "Agents hold the Mac awake while they work, and let it sleep when they finish.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }

    private func connect(_ target: AgentTarget) {
        connecting = target
        connectMessage = nil
        let installer = installer
        Task {
            // `claude mcp add` can take a moment; keep the menu responsive.
            let result = await Task.detached { Result { try installer.install(target) } }.value
            switch result {
            case .success(let lines):
                let manual = lines.first { $0.hasPrefix("Run this yourself") }
                connectMessage = manual ?? "Connected \(target.displayName). New sessions use it."
            case .failure(let error):
                connectMessage = error.localizedDescription
            }
            connecting = nil
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Keep display on", isOn: $controller.preventDisplaySleep)
            if controller.lidModeAvailable {
                lidSection
            }
            Toggle("Launch at login", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { controller.setLaunchAtLogin($0) }
            ))
        }
    }

    private var lidSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Keep awake with lid closed", isOn: Binding(
                get: { controller.keepAwakeWithLidClosed },
                set: { enabled in Task { await controller.setKeepAwakeWithLidClosed(enabled) } }
            ))
            Group {
                if !controller.lidHelperInstalled {
                    Text("Asks for your admin password once.")
                } else if controller.keepAwakeWithLidClosed {
                    Text("Don't put a running Mac in a bag — it can overheat.")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let message = controller.lidMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
