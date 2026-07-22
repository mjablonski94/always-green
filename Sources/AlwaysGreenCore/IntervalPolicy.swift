import Foundation

/// Derives the jiggle interval from the system screen-sleep timeout.
///
/// The interval is half the screen-sleep time, so a jiggle always lands before the screen would
/// sleep. When screen-sleep is longer than five minutes (or Never/unknown), half of it would sit
/// too close to the ~5-minute presence "Away" threshold, so a safe 30-second fallback is used.
public enum IntervalPolicy {
    public static let fallbackSeconds = 30
    public static let minSeconds = 15
    /// Screen-sleep longer than this (5 minutes) falls back to `fallbackSeconds`.
    public static let longSleepThresholdSeconds = 300

    /// - Parameter displaySleepSeconds: current screen-sleep timeout in seconds, or `nil`/`0`
    ///   for "Never" / unknown, in which case the fallback is returned.
    public static func derive(displaySleepSeconds: Int?) -> Int {
        guard let seconds = displaySleepSeconds,
              seconds > 0,
              seconds <= longSleepThresholdSeconds else {
            return fallbackSeconds
        }
        return max(seconds / 2, minSeconds)
    }
}
