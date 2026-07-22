import SwiftUI

struct AboutView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { onBack() } label: {
                    Label(Loc.back, systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                Spacer()
                Text("Always Green \(Bundle.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    section(Loc.aboutWhatTitle, Loc.aboutWhatBody)
                    section(Loc.aboutIntervalTitle, Loc.aboutIntervalBody)
                    section(Loc.aboutPrivacyTitle, Loc.aboutPrivacyBody)
                    section(Loc.aboutPermissionsTitle, Loc.aboutPermissionsBody)
                    section(Loc.aboutCliTitle, Loc.aboutCliBody)
                    section(Loc.aboutResponsibilityTitle, Loc.aboutResponsibilityBody)
                    section(Loc.aboutWarrantyTitle, Loc.aboutWarrantyBody)
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
