import Foundation

/// Derives the jiggle interval from the system screen-sleep timeout.
///
/// The interval is half the screen-sleep time (so a jiggle always lands before the screen
/// would sleep), clamped into a safe band. The upper bound stays under the ~5-minute
/// presence "Away" threshold, which matters on AC where screen-sleep can be long.
public enum IntervalPolicy {
    public static let fallbackSeconds = 30
    public static let minSeconds = 15
    public static let maxSeconds = 240

    /// - Parameter displaySleepSeconds: current screen-sleep timeout in seconds, or `nil`/`0`
    ///   for "Never" / unknown, in which case the fallback is returned.
    public static func derive(displaySleepSeconds: Int?) -> Int {
        guard let seconds = displaySleepSeconds, seconds > 0 else { return fallbackSeconds }
        let half = seconds / 2
        return min(max(half, minSeconds), maxSeconds)
    }
}
