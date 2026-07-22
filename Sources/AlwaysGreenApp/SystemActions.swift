import AppKit

enum SystemActions {
    static let buyMeACoffeeURL = URL(string: "https://buymeacoffee.com/YOUR_HANDLE")!

    static func openBuyMeACoffee() {
        NSWorkspace.shared.open(buyMeACoffeeURL)
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
