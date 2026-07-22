import Foundation

/// A verb the CLI understands and forwards to the running app.
public enum Command: String, CaseIterable, Sendable {
    case start
    case stop
    case toggle
    case status
}

public enum CommandParseError: Error, Equatable {
    case missing
    case unknown(String)
}

public extension Command {
    /// Parse CLI arguments (excluding the program name).
    static func parse(arguments: [String]) -> Result<Command, CommandParseError> {
        guard let first = arguments.first, !first.isEmpty else { return .failure(.missing) }
        guard let command = Command(rawValue: first.lowercased()) else {
            return .failure(.unknown(first))
        }
        return .success(command)
    }

    static var usage: String {
        "usage: alwaysgreen <start|stop|toggle|status>"
    }
}
