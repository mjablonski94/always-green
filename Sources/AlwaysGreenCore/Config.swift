import Foundation

/// Shared identifiers and file locations used by the app and the CLI.
public enum Config {
    public static let bundleIdentifier = "com.mjablonski.alwaysgreen"
    public static let commandNotificationName = "com.mjablonski.alwaysgreen.command"
    public static let appDisplayName = "Always Green"

    /// Where the running app publishes its state for the CLI's `status` command.
    public static var stateFileURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent(appDisplayName, isDirectory: true)
            .appendingPathComponent("state.json")
    }
}
