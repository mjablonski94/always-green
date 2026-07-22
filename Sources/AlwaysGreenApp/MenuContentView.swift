import SwiftUI
import AlwaysGreenCore

struct MenuContentView: View {
    @EnvironmentObject private var engine: JiggleEngine
    @State private var showingInfo = false

    var body: some View {
        Group {
            if showingInfo {
                AboutView(onBack: { showingInfo = false })
            } else {
                mainControls
            }
        }
        .padding(14)
        .frame(width: 272)
        .onAppear { engine.refreshAccessibility() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(engine.isRunning ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 10, height: 10)
            Text("Always Green").font(.headline)
            Spacer()
            Text(engine.isRunning ? "On" : "Off").foregroundStyle(.secondary)
        }
    }

    private var mainControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Button {
                engine.toggle()
            } label: {
                Text(engine.isRunning ? "Stop" : "Start").frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(engine.isRunning ? .red : .green)
            .disabled(!engine.isAccessibilityTrusted)

            if !engine.isAccessibilityTrusted {
                accessibilityNotice
            }

            Divider()

            Stepper(
                value: Binding(
                    get: { engine.intervalSeconds },
                    set: { engine.setIntervalManually($0) }
                ),
                in: 5...600,
                step: 5
            ) {
                HStack {
                    Text("Move every")
                    Spacer()
                    Text(engine.intervalLabel).monospacedDigit().foregroundStyle(.secondary)
                }
            }

            Text(engine.autoInterval ? "Auto (half your screen-sleep time)" : "Manual")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Launch at login (start with system)", isOn: Binding(
                get: { engine.launchAtLogin },
                set: { engine.setLaunchAtLogin($0) }
            ))

            Divider()

            Button {
                SystemActions.openBuyMeACoffee()
            } label: {
                Label("Buy me a coffee", systemImage: "cup.and.saucer.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            HStack {
                Button {
                    showingInfo = true
                } label: {
                    Label("Info", systemImage: "info.circle")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
            }
        }
    }

    private var accessibilityNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Accessibility access needed", systemImage: "hand.raised.fill")
                .font(.callout).bold()
                .foregroundStyle(.orange)
            Text("Click Grant access, enable \"Always Green\" in the list that opens, then click Re-check. Start stays disabled until then.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Grant access") { engine.requestAccess() }
                Button("Open Settings") { SystemActions.openAccessibilitySettings() }
                Button("Re-check") { engine.refreshAccessibility() }
            }
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
