import SwiftUI

struct AboutView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { onBack() } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                Spacer()
                Text("Always Green \(Bundle.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    section("What it does",
                            "Always Green makes a tiny cursor movement at the interval you choose so your Mac stays active and your chat status stays \"available\". It does not click, type, record, or read anything you do.")
                    section("Interval",
                            "The interval defaults to half of your system screen-sleep time (so a nudge always lands before the screen would sleep). You can override it; it is capped to stay under the usual idle threshold.")
                    section("Data and privacy",
                            "Always Green collects no personal data and makes no network connections. It has no analytics or tracking. Your settings are stored only on this Mac. The \u{201C}Buy me a coffee\u{201D} button opens a link in your browser; that page belongs to a third party with its own terms.")
                    section("Permissions",
                            "Accessibility access is required by macOS so Always Green may move the cursor. You grant it once in System Settings and can revoke it at any time. Always Green never forces the Mac awake with a power assertion.")
                    section("Command line",
                            "The bundled \u{2018}alwaysgreen\u{2019} tool controls this same app from the terminal (start, stop, toggle, status).")
                    section("Your responsibility",
                            "You are responsible for using Always Green in line with your employer\u{2019}s and any applicable rules. Simulating activity may be restricted in some workplaces.")
                    section("Warranty",
                            "Always Green is provided \u{201C}as is\u{201D}, without warranty of any kind. Use at your own risk.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 320)
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline).bold()
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension Bundle {
    static var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
