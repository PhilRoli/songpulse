import Foundation

protocol ScriptRunning {
    func run(_ source: String) async throws -> String
}

struct ScriptError: Error {
    let code: Int
}

final class NSAppleScriptRunner: ScriptRunning {
    private let queue = DispatchQueue(label: "SongPulse.applescript")

    func run(_ source: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var errorInfo: NSDictionary?
                let script = NSAppleScript(source: source)
                let result = script?.executeAndReturnError(&errorInfo)
                if let errorInfo {
                    let code = (errorInfo[NSAppleScript.errorNumber] as? Int) ?? -1
                    continuation.resume(throwing: ScriptError(code: code))
                } else {
                    continuation.resume(returning: result?.stringValue ?? "")
                }
            }
        }
    }
}

enum SpotifyScripts {
    static let state = """
    if application "Spotify" is running then
        tell application "Spotify"
            set sep to (ASCII character 31)
            set ps to (player state as string)
            try
                set t to current track
                set info to (name of t) & sep & (artist of t) & sep & (artwork url of t)
            on error
                set info to sep & sep
            end try
            return ps & sep & info & sep & (shuffling as string) & sep & (repeating as string)
        end tell
    else
        return "NOT_RUNNING"
    end if
    """

    static func command(_ body: String) -> String {
        """
        if application "Spotify" is running then
            tell application "Spotify" to \(body)
        end if
        """
    }

    static let playPause = command("playpause")
    static let next = command("next track")
    static let previous = command("previous track")
    static func setShuffling(_ on: Bool) -> String { command("set shuffling to \(on)") }
    static func setRepeating(_ on: Bool) -> String { command("set repeating to \(on)") }
}

protocol SpotifyControlling {
    func fetchState() async -> PlaybackState
    func playPause() async
    func next() async
    func previous() async
    func setShuffling(_ on: Bool) async
    func setRepeating(_ on: Bool) async
}

final class SpotifyClient: SpotifyControlling {
    private static let automationDenied = -1743
    private let runner: ScriptRunning

    init(runner: ScriptRunning = NSAppleScriptRunner()) {
        self.runner = runner
    }

    func fetchState() async -> PlaybackState {
        do {
            return PlaybackState.parse(try await runner.run(SpotifyScripts.state))
        } catch let error as ScriptError where error.code == Self.automationDenied {
            return .permissionDenied
        } catch {
            return .notRunning
        }
    }

    func playPause() async { await send(SpotifyScripts.playPause) }
    func next() async { await send(SpotifyScripts.next) }
    func previous() async { await send(SpotifyScripts.previous) }
    func setShuffling(_ on: Bool) async { await send(SpotifyScripts.setShuffling(on)) }
    func setRepeating(_ on: Bool) async { await send(SpotifyScripts.setRepeating(on)) }

    private func send(_ source: String) async {
        _ = try? await runner.run(source)
    }
}
