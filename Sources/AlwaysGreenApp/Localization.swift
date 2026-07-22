import Foundation

/// Localized UI strings, resolved from the app bundle's <lang>.lproj/Localizable.strings.
/// The product name "Always Green" and the CLI name "alwaysgreen" stay untranslated.
enum Loc {
    static var statusOn: String { t("status.on") }
    static var statusOff: String { t("status.off") }
    static var start: String { t("button.start") }
    static var stop: String { t("button.stop") }
    static var grantAccess: String { t("button.grantAccess") }
    static var openSettings: String { t("button.openSettings") }
    static var recheck: String { t("button.recheck") }
    static var resetToAuto: String { t("button.resetToAuto") }
    static var buyCoffee: String { t("button.buyCoffee") }
    static var info: String { t("button.info") }
    static var quit: String { t("button.quit") }
    static var back: String { t("button.back") }
    static var intervalTitle: String { t("interval.title") }
    static var intervalAuto: String { t("interval.auto") }
    static var intervalManual: String { t("interval.manual") }
    static var launchAtLogin: String { t("toggle.launchAtLogin") }
    static var accessTitle: String { t("access.title") }
    static var accessBody: String { t("access.body") }
    static var aboutWhatTitle: String { t("about.what.title") }
    static var aboutWhatBody: String { t("about.what.body") }
    static var aboutIntervalTitle: String { t("about.interval.title") }
    static var aboutIntervalBody: String { t("about.interval.body") }
    static var aboutPrivacyTitle: String { t("about.privacy.title") }
    static var aboutPrivacyBody: String { t("about.privacy.body") }
    static var aboutPermissionsTitle: String { t("about.permissions.title") }
    static var aboutPermissionsBody: String { t("about.permissions.body") }
    static var aboutCliTitle: String { t("about.cli.title") }
    static var aboutCliBody: String { t("about.cli.body") }
    static var aboutResponsibilityTitle: String { t("about.responsibility.title") }
    static var aboutResponsibilityBody: String { t("about.responsibility.body") }
    static var aboutWarrantyTitle: String { t("about.warranty.title") }
    static var aboutWarrantyBody: String { t("about.warranty.body") }

    private static func t(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }
}
