import Foundation

struct PlaybackState: Equatable {
    var isRunning = false
    var permissionDenied = false
    var isPlaying = false
    var title = ""
    var artist = ""
    var artworkURL: URL?
    var shuffling = false
    var repeating = false

    static let notRunning = PlaybackState()
    static let permissionDenied = PlaybackState(permissionDenied: true)

    static let separator: Character = "\u{1F}"

    static func parse(_ output: String) -> PlaybackState {
        let fields = output.split(separator: separator, omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 6 else { return .notRunning }
        return PlaybackState(
            isRunning: true,
            isPlaying: fields[0] == "playing",
            title: fields[1],
            artist: fields[2],
            artworkURL: fields[3].isEmpty ? nil : URL(string: fields[3]),
            shuffling: fields[4] == "true",
            repeating: fields[5] == "true"
        )
    }
}
