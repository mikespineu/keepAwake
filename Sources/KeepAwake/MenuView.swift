import SwiftUI

struct MenuView: View {
    @Bindable var controller: KeepAwakeController

    private let presets: [(label: String, minutes: Int?)] = [
        ("15 min", 15), ("30 min", 30), ("1 h", 60),
        ("2 h", 120), ("4 h", 240), ("Always", nil),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            if controller.isActive {
                activeSection
            } else {
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
            Image(nsImage: .mug(active: controller.isActive))
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: 22)
                .foregroundStyle(controller.isActive ? Color.accentColor : .secondary)
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
            Text(controller.endDate == nil
                 ? "Your Mac stays awake until you turn it off."
                 : "Your Mac stays awake until the countdown ends.")
                .font(.callout)
            Button {
                controller.stop()
            } label: {
                Label("Turn Off", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
        }
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

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Keep display on", isOn: $controller.preventDisplaySleep)
            Toggle("Launch at login", isOn: Binding(
                get: { controller.launchAtLogin },
                set: { controller.setLaunchAtLogin($0) }
            ))
        }
    }
}
