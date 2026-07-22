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
        .frame(width: 300)
        .onAppear { engine.refreshAccessibility() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(engine.isRunning ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 10, height: 10)
            Text("Always Green").font(.headline)
            Spacer()
            Text(engine.isRunning ? Loc.statusOn : Loc.statusOff).foregroundStyle(.secondary)
        }
    }

    private var mainControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Button {
                engine.toggle()
            } label: {
                Text(engine.isRunning ? Loc.stop : Loc.start).frame(maxWidth: .infinity)
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
                    Text(Loc.intervalTitle)
                    Spacer()
                    Text(engine.intervalLabel).monospacedDigit().foregroundStyle(.secondary)
                }
            }

            HStack {
                Text(engine.autoInterval ? Loc.intervalAuto : Loc.intervalManual)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !engine.autoInterval {
                    Button(Loc.resetToAuto) { engine.resetIntervalToAuto() }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            }

            Toggle(Loc.launchAtLogin, isOn: Binding(
                get: { engine.launchAtLogin },
                set: { engine.setLaunchAtLogin($0) }
            ))

            Divider()

            Button {
                SystemActions.openBuyMeACoffee()
            } label: {
                Label(Loc.buyCoffee, systemImage: "cup.and.saucer.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            HStack {
                Button {
                    showingInfo = true
                } label: {
                    Label(Loc.info, systemImage: "info.circle")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(Loc.quit) { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
            }
        }
    }

    private var accessibilityNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(Loc.accessTitle, systemImage: "hand.raised.fill")
                .font(.callout).bold()
                .foregroundStyle(.orange)
            Text(Loc.accessBody)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                engine.requestAccess()
            } label: {
                Text(Loc.grantAccess).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            HStack {
                Button(Loc.openSettings) { SystemActions.openAccessibilitySettings() }
                Spacer()
                Button(Loc.recheck) { engine.refreshAccessibility() }
            }
            .controlSize(.small)
            .buttonStyle(.borderless)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
