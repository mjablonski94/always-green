import Foundation

/// The small state the app publishes for the CLI to read.
public struct AppState: Codable, Equatable, Sendable {
    public var running: Bool
    public var intervalSeconds: Int

    public init(running: Bool, intervalSeconds: Int) {
        self.running = running
        self.intervalSeconds = intervalSeconds
    }
}

/// Reads/writes `AppState` as JSON at a given URL.
public struct AppStateStore {
    private let url: URL
    private let fileManager: FileManager

    public init(url: URL, fileManager: FileManager = .default) {
        self.url = url
        self.fileManager = fileManager
    }

    public func load() -> AppState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }

    public func save(_ state: AppState) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: .atomic)
    }
}
