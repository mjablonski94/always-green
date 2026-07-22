import XCTest
@testable import AlwaysGreenCore

// MARK: - Fakes

final class FakeInput: InputSynthesizing {
    private(set) var count = 0
    func jiggle() { count += 1 }
}

final class FakeDisplaySleep: DisplaySleepReading {
    var seconds: Int?
    init(_ seconds: Int?) { self.seconds = seconds }
    func displaySleepSeconds() -> Int? { seconds }
}

final class FakeAccessibility: AccessibilityChecking {
    var trusted: Bool
    init(_ trusted: Bool) { self.trusted = trusted }
    var isTrusted: Bool { trusted }
}

final class FakeLoginItem: LoginItemControlling {
    var enabled = false
    var throwOnSet = false
    var isEnabled: Bool { enabled }
    func setEnabled(_ value: Bool) throws {
        if throwOnSet { throw NSError(domain: "test", code: 1) }
        enabled = value
    }
}

final class FakeTimer: RepeatingTimer {
    private(set) var isTiming = false
    private(set) var interval: TimeInterval = 0
    private(set) var startCount = 0
    private var handler: (() -> Void)?

    func start(interval: TimeInterval, handler: @escaping () -> Void) {
        isTiming = true
        self.interval = interval
        self.handler = handler
        startCount += 1
    }

    func stop() {
        isTiming = false
        handler = nil
    }

    func fire() { handler?() }
}

// MARK: - Engine

@MainActor
final class JiggleEngineTests: XCTestCase {
    private func makeEngine(
        trusted: Bool = true,
        displaySleep: Int? = 120,
        onState: ((AppState) -> Void)? = nil
    ) -> (JiggleEngine, FakeInput, FakeTimer, FakeLoginItem, FakeAccessibility, FakeDisplaySleep) {
        let input = FakeInput()
        let timer = FakeTimer()
        let login = FakeLoginItem()
        let accessibility = FakeAccessibility(trusted)
        let displaySleepReader = FakeDisplaySleep(displaySleep)
        let engine = JiggleEngine(
            input: input,
            displaySleep: displaySleepReader,
            accessibility: accessibility,
            loginItem: login,
            timer: timer,
            onStateChange: onState
        )
        return (engine, input, timer, login, accessibility, displaySleepReader)
    }

    func testInitDerivesIntervalFromDisplaySleep() {
        let (engine, _, _, _, _, _) = makeEngine(displaySleep: 120)
        XCTAssertEqual(engine.intervalSeconds, 60)
        XCTAssertTrue(engine.autoInterval)
        XCTAssertFalse(engine.isRunning)
    }

    func testStartRequiresAccessibility() {
        let (engine, input, timer, _, _, _) = makeEngine(trusted: false)
        engine.start()
        XCTAssertFalse(engine.isRunning)
        XCTAssertFalse(timer.isTiming)
        XCTAssertEqual(input.count, 0)
    }

    func testStartWhenTrusted() {
        let (engine, input, timer, _, _, _) = makeEngine(trusted: true, displaySleep: 120)
        engine.start()
        XCTAssertTrue(engine.isRunning)
        XCTAssertTrue(timer.isTiming)
        XCTAssertEqual(timer.interval, 60)
        XCTAssertEqual(input.count, 1)
    }

    func testStartIsIdempotent() {
        let (engine, input, _, _, _, _) = makeEngine()
        engine.start()
        engine.start()
        XCTAssertEqual(input.count, 1)
    }

    func testTimerFiresJiggle() {
        let (engine, input, timer, _, _, _) = makeEngine()
        engine.start()
        timer.fire()
        timer.fire()
        XCTAssertEqual(input.count, 3)
    }

    func testStopStopsTimer() {
        let (engine, _, timer, _, _, _) = makeEngine()
        engine.start()
        engine.stop()
        XCTAssertFalse(engine.isRunning)
        XCTAssertFalse(timer.isTiming)
    }

    func testStopWhenNotRunningIsNoop() {
        let (engine, _, _, _, _, _) = makeEngine()
        engine.stop()
        XCTAssertFalse(engine.isRunning)
    }

    func testToggle() {
        let (engine, _, _, _, _, _) = makeEngine()
        engine.toggle()
        XCTAssertTrue(engine.isRunning)
        engine.toggle()
        XCTAssertFalse(engine.isRunning)
    }

    func testStartIfTrustedStartsWhenTrusted() {
        let (engine, _, _, _, _, _) = makeEngine(trusted: true)
        engine.startIfTrusted()
        XCTAssertTrue(engine.isRunning)
    }

    func testStartIfTrustedStaysOffWhenUntrusted() {
        let (engine, _, _, _, _, _) = makeEngine(trusted: false)
        engine.startIfTrusted()
        XCTAssertFalse(engine.isRunning)
    }

    func testRefreshAccessibilityPicksUpGrant() {
        let (engine, _, _, _, accessibility, _) = makeEngine(trusted: false)
        XCTAssertFalse(engine.isAccessibilityTrusted)
        accessibility.trusted = true
        engine.refreshAccessibility()
        XCTAssertTrue(engine.isAccessibilityTrusted)
    }

    func testManualIntervalDisablesAuto() {
        let (engine, _, _, _, _, displaySleep) = makeEngine(displaySleep: 120)
        engine.setIntervalManually(45)
        XCTAssertEqual(engine.intervalSeconds, 45)
        XCTAssertFalse(engine.autoInterval)
        displaySleep.seconds = 600
        engine.rederiveIntervalIfAuto()
        XCTAssertEqual(engine.intervalSeconds, 45)
    }

    func testManualIntervalClamped() {
        let (engine, _, _, _, _, _) = makeEngine()
        engine.setIntervalManually(3)
        XCTAssertEqual(engine.intervalSeconds, 5)
        engine.setIntervalManually(9999)
        XCTAssertEqual(engine.intervalSeconds, 600)
    }

    func testRederiveAutoUpdatesInterval() {
        let (engine, _, _, _, _, displaySleep) = makeEngine(displaySleep: 120)
        XCTAssertEqual(engine.intervalSeconds, 60)
        displaySleep.seconds = 300
        engine.rederiveIntervalIfAuto()
        XCTAssertEqual(engine.intervalSeconds, 150)
    }

    func testChangingIntervalWhileRunningRestartsTimer() {
        let (engine, _, timer, _, _, _) = makeEngine(displaySleep: 120)
        engine.start()
        let before = timer.startCount
        engine.setIntervalManually(90)
        XCTAssertEqual(timer.startCount, before + 1)
        XCTAssertEqual(timer.interval, 90)
    }

    func testLoginItemToggle() {
        let (engine, _, _, login, _, _) = makeEngine()
        engine.setLaunchAtLogin(true)
        XCTAssertTrue(login.enabled)
        XCTAssertTrue(engine.launchAtLogin)
        engine.setLaunchAtLogin(false)
        XCTAssertFalse(engine.launchAtLogin)
    }

    func testLoginItemToggleHandlesThrow() {
        let (engine, _, _, login, _, _) = makeEngine()
        login.throwOnSet = true
        engine.setLaunchAtLogin(true)
        XCTAssertFalse(engine.launchAtLogin)
    }

    func testStatePublishedOnStartAndStop() {
        var states: [AppState] = []
        let (engine, _, _, _, _, _) = makeEngine(displaySleep: 120, onState: { states.append($0) })
        engine.start()
        engine.stop()
        XCTAssertEqual(states.first, AppState(running: true, intervalSeconds: 60))
        XCTAssertEqual(states.last, AppState(running: false, intervalSeconds: 60))
    }

    func testIntervalLabel() {
        let (engine, _, _, _, _, _) = makeEngine(displaySleep: nil)
        XCTAssertEqual(engine.intervalLabel, "30s")
        engine.setIntervalManually(60)
        XCTAssertEqual(engine.intervalLabel, "1m")
        engine.setIntervalManually(90)
        XCTAssertEqual(engine.intervalLabel, "1m 30s")
        engine.setIntervalManually(240)
        XCTAssertEqual(engine.intervalLabel, "4m")
    }
}

// MARK: - Interval policy

final class IntervalPolicyTests: XCTestCase {
    func testDerive() {
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: nil), 30)
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: 0), 30)
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: 120), 60)
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: 600), 240)
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: 20), 15)
        XCTAssertEqual(IntervalPolicy.derive(displaySleepSeconds: 60), 30)
    }
}

// MARK: - Command

final class CommandTests: XCTestCase {
    func testParseValid() {
        XCTAssertEqual(Command.parse(arguments: ["start"]), .success(.start))
        XCTAssertEqual(Command.parse(arguments: ["STATUS"]), .success(.status))
    }

    func testParseMissing() {
        XCTAssertEqual(Command.parse(arguments: []), .failure(.missing))
        XCTAssertEqual(Command.parse(arguments: [""]), .failure(.missing))
    }

    func testParseUnknown() {
        XCTAssertEqual(Command.parse(arguments: ["bogus"]), .failure(.unknown("bogus")))
    }

    func testUsageAndCases() {
        XCTAssertFalse(Command.usage.isEmpty)
        XCTAssertEqual(Command.allCases.count, 4)
    }
}

// MARK: - App state + config

final class AppStateTests: XCTestCase {
    func testRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = dir.appendingPathComponent("state.json")
        let store = AppStateStore(url: url)
        XCTAssertNil(store.load())
        let state = AppState(running: true, intervalSeconds: 45)
        try store.save(state)
        XCTAssertEqual(store.load(), state)
        try? FileManager.default.removeItem(at: dir)
    }
}

final class ConfigTests: XCTestCase {
    func testConstants() {
        XCTAssertEqual(Config.appDisplayName, "Always Green")
        XCTAssertTrue(Config.bundleIdentifier.contains("alwaysgreen"))
        XCTAssertTrue(Config.commandNotificationName.contains("command"))
        XCTAssertTrue(Config.stateFileURL.path.contains("Always Green"))
    }
}
