import Foundation

/// Posts the synthetic input that resets the idle timer. Backed by CGEvent in production.
public protocol InputSynthesizing: AnyObject {
    func jiggle()
}

/// Reads the current screen-sleep timeout. Backed by pmset/IOKit in production.
public protocol DisplaySleepReading: AnyObject {
    /// Screen-sleep timeout in seconds for the active power source; `nil` for Never/unknown.
    func displaySleepSeconds() -> Int?
}

/// Reports and requests macOS Accessibility trust.
public protocol AccessibilityChecking: AnyObject {
    var isTrusted: Bool { get }
    /// Ask macOS for Accessibility access (shows the standard prompt and lists the app in
    /// Privacy & Security > Accessibility so the user can enable it).
    func requestAccess()
}

/// Controls the launch-at-login registration. Backed by SMAppService in production.
public protocol LoginItemControlling: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// A restartable repeating timer. Backed by Foundation.Timer in production; a manual fake in tests.
public protocol RepeatingTimer: AnyObject {
    func start(interval: TimeInterval, handler: @escaping () -> Void)
    func stop()
}
