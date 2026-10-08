import Foundation

enum StatusDisplay: Equatable {
    case artwork(URL)
    case placeholder

    static func from(_ state: PlaybackState) -> StatusDisplay {
        guard state.isRunning, !state.permissionDenied, let url = state.artworkURL else { return .placeholder }
        return .artwork(url)
    }
}

enum PopoverMode: Equatable {
    case track
    case notRunning
    case permissionDenied

    static func from(_ state: PlaybackState) -> PopoverMode {
        if state.permissionDenied { return .permissionDenied }
        return state.isRunning ? .track : .notRunning
    }
}
