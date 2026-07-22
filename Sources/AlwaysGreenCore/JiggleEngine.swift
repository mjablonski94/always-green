import Foundation
import Combine

/// The heart of Always Green: a small state machine that, while running, posts a synthetic
/// cursor move on a timer. All side effects are injected so the engine is fully unit-testable.
@MainActor
public final class JiggleEngine: ObservableObject {
    @Published public private(set) var isRunning = false
    @Published public private(set) var isAccessibilityTrusted = false
    @Published public private(set) var intervalSeconds = IntervalPolicy.fallbackSeconds
    @Published public private(set) var autoInterval = true
    @Published public private(set) var launchAtLogin = false

    private let input: InputSynthesizing
    private let displaySleep: DisplaySleepReading
    private let accessibility: AccessibilityChecking
    private let loginItem: LoginItemControlling
    private let timer: RepeatingTimer
    private let onStateChange: ((AppState) -> Void)?

    public static let manualMinSeconds = 5
    public static let manualMaxSeconds = 600

    public init(
        input: InputSynthesizing,
        displaySleep: DisplaySleepReading,
        accessibility: AccessibilityChecking,
        loginItem: LoginItemControlling,
        timer: RepeatingTimer,
        onStateChange: ((AppState) -> Void)? = nil
    ) {
        self.input = input
        self.displaySleep = displaySleep
        self.accessibility = accessibility
        self.loginItem = loginItem
        self.timer = timer
        self.onStateChange = onStateChange
        self.isAccessibilityTrusted = accessibility.isTrusted
        self.launchAtLogin = loginItem.isEnabled
        self.intervalSeconds = IntervalPolicy.derive(displaySleepSeconds: displaySleep.displaySleepSeconds())
    }

    public var intervalLabel: String {
        if intervalSeconds < 60 { return "\(intervalSeconds)s" }
        let minutes = intervalSeconds / 60
        let seconds = intervalSeconds % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }

    // MARK: - Control

    public func toggle() {
        isRunning ? stop() : start()
    }

    public func start() {
        guard !isRunning else { return }
        refreshAccessibility()
        guard isAccessibilityTrusted else { return }
        armTimer()
        isRunning = true
        input.jiggle()
        publishState()
    }

    public func stop() {
        guard isRunning else { return }
        timer.stop()
        isRunning = false
        publishState()
    }

    /// Called on launch: start only if Accessibility is already granted (seamless, no prompt).
    public func startIfTrusted() {
        refreshAccessibility()
        if isAccessibilityTrusted { start() }
    }

    // MARK: - Interval

    /// User moved the stepper: pin the value and stop auto-deriving.
    public func setIntervalManually(_ seconds: Int) {
        autoInterval = false
        applyInterval(min(max(seconds, Self.manualMinSeconds), Self.manualMaxSeconds))
    }

    /// Re-read the screen-sleep setting and update the interval, unless the user overrode it.
    public func rederiveIntervalIfAuto() {
        guard autoInterval else { return }
        applyInterval(IntervalPolicy.derive(displaySleepSeconds: displaySleep.displaySleepSeconds()))
    }

    private func applyInterval(_ seconds: Int) {
        guard seconds != intervalSeconds else { return }
        intervalSeconds = seconds
        if isRunning { armTimer() }
        publishState()
    }

    // MARK: - Accessibility

    public func refreshAccessibility() {
        let trusted = accessibility.isTrusted
        if trusted != isAccessibilityTrusted {
            isAccessibilityTrusted = trusted
            publishState()
        }
    }

    /// Ask macOS for Accessibility access, then refresh (user-initiated from the panel).
    public func requestAccess() {
        accessibility.requestAccess()
        refreshAccessibility()
    }

    // MARK: - Login item

    public func setLaunchAtLogin(_ enabled: Bool) {
        try? loginItem.setEnabled(enabled)
        launchAtLogin = loginItem.isEnabled
    }

    // MARK: - Helpers

    private func armTimer() {
        timer.start(interval: TimeInterval(intervalSeconds)) { [weak self] in
            self?.input.jiggle()
        }
    }

    private func publishState() {
        onStateChange?(AppState(
            running: isRunning,
            intervalSeconds: intervalSeconds,
            accessibilityTrusted: isAccessibilityTrusted
        ))
    }
}
