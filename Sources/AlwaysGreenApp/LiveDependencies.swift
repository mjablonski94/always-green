import Foundation
import CoreGraphics
import ApplicationServices
import ServiceManagement
import AlwaysGreenCore

/// Posts a 1px cursor move and back via CGEvent (requires Accessibility).
final class CGEventInputSynthesizer: InputSynthesizing {
    func jiggle() {
        guard let location = CGEvent(source: nil)?.location else { return }
        move(to: CGPoint(x: location.x + 1, y: location.y))
        move(to: location)
    }

    private func move(to point: CGPoint) {
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }
}

/// Reads the effective screen-sleep timeout by parsing `pmset -g`.
final class PMSetDisplaySleepReader: DisplaySleepReading {
    func displaySleepSeconds() -> Int? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let text = String(data: data, encoding: .utf8) else { return nil }

        for rawLine in text.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("displaysleep") else { continue }
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2, let minutes = Int(parts[1]) else { return nil }
            return minutes == 0 ? nil : minutes * 60
        }
        return nil
    }
}

final class AXAccessibilityChecker: AccessibilityChecking {
    var isTrusted: Bool { AXIsProcessTrusted() }
}

final class SMLoginItem: LoginItemControlling {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}

final class TimerRepeatingTimer: RepeatingTimer {
    private var timer: Timer?

    func start(interval: TimeInterval, handler: @escaping () -> Void) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in handler() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
