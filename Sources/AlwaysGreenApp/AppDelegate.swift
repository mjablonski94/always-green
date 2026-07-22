import AppKit
import Combine
import SwiftUI
import AlwaysGreenCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var engine: JiggleEngine!
    private var cancellables = Set<AnyCancellable>()
    private let stateStore = AppStateStore(url: Config.stateFileURL)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = stateStore
        engine = JiggleEngine(
            input: CGEventInputSynthesizer(),
            displaySleep: PMSetDisplaySleepReader(),
            accessibility: AXAccessibilityChecker(),
            loginItem: SMLoginItem(),
            timer: TimerRepeatingTimer(),
            onStateChange: { state in try? store.save(state) }
        )

        setupStatusItem()
        setupPopover()
        observeRunningState()
        observeCommands()
        startTrustPolling()
        startIntervalPolling()

        try? stateStore.save(AppState(running: engine.isRunning, intervalSeconds: engine.intervalSeconds))
        engine.startIfTrusted()
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = MenuBarIcon.image(on: false)
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            engine.toggle()
        } else {
            togglePopover(sender)
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView().environmentObject(engine)
        )
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        engine.refreshAccessibility()
        engine.rederiveIntervalIfAuto()
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    // MARK: - Observation

    private func observeRunningState() {
        engine.$isRunning
            .receive(on: RunLoop.main)
            .sink { [weak self] running in
                MainActor.assumeIsolated {
                    self?.statusItem.button?.image = MenuBarIcon.image(on: running)
                }
            }
            .store(in: &cancellables)
    }

    private func observeCommands() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(Config.commandNotificationName),
            object: nil,
            queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, let verb = note.object as? String,
                      case let .success(command) = Command.parse(arguments: [verb]) else { return }
                switch command {
                case .start: self.engine.start()
                case .stop: self.engine.stop()
                case .toggle: self.engine.toggle()
                case .status: break
                }
            }
        }
    }

    private func startTrustPolling() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let wasTrusted = self.engine.isAccessibilityTrusted
                self.engine.refreshAccessibility()
                if !wasTrusted, self.engine.isAccessibilityTrusted, !self.engine.isRunning {
                    self.engine.start()
                }
            }
        }
    }

    private func startIntervalPolling() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.engine.rederiveIntervalIfAuto()
            }
        }
    }
}
