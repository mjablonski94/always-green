import Foundation
import AppKit
import AlwaysGreenCore

let arguments = Array(CommandLine.arguments.dropFirst())

switch Command.parse(arguments: arguments) {
case .failure(let error):
    let message: String
    switch error {
    case .missing:
        message = Command.usage
    case .unknown(let verb):
        message = "alwaysgreen: unknown command '\(verb)'\n" + Command.usage
    }
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
case .success(let command):
    exit(CLI.run(command))
}

enum CLI {
    static func run(_ command: Command) -> Int32 {
        switch command {
        case .status: return status()
        case .stop: return sendStop()
        case .start, .toggle: return sendLaunching(command)
        }
    }

    static func status() -> Int32 {
        let running = isAppRunning()
        if let state = AppStateStore(url: Config.stateFileURL).load() {
            let onOff = (running && state.running) ? "on" : "off"
            let access = state.accessibilityTrusted ? "granted" : "not granted"
            print("always green: \(onOff) (interval \(state.intervalSeconds)s, app \(running ? "running" : "not running"), accessibility \(access))")
        } else {
            print("always green: \(running ? "running (state unknown)" : "not running")")
        }
        return 0
    }

    static func sendStop() -> Int32 {
        if isAppRunning() { post(.stop) }
        print("always green: stop sent")
        return 0
    }

    static func sendLaunching(_ command: Command) -> Int32 {
        if !isAppRunning() { launchApp() }
        post(command)
        print("always green: \(command.rawValue) sent")
        return 0
    }

    static func isAppRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Config.bundleIdentifier).isEmpty
    }

    static func post(_ command: Command) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(Config.commandNotificationName),
            object: command.rawValue,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    static func launchApp() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Config.bundleIdentifier) else {
            FileHandle.standardError.write(Data("alwaysgreen: Always Green.app not found; launch it once first\n".utf8))
            return
        }
        let semaphore = DispatchSemaphore(value: 0)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 3)
        Thread.sleep(forTimeInterval: 1.0)
    }
}
