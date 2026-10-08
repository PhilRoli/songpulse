import XCTest
@testable import SongPulse

final class StatusDisplayTests: XCTestCase {
    private let url = URL(string: "https://i.scdn.co/image/a")!

    func testRunningWithArtworkShowsArtwork() {
        let state = PlaybackState(isRunning: true, isPlaying: true, artworkURL: url)
        XCTAssertEqual(StatusDisplay.from(state), .artwork(url))
    }

    func testPausedStillShowsArtwork() {
        let state = PlaybackState(isRunning: true, isPlaying: false, artworkURL: url)
        XCTAssertEqual(StatusDisplay.from(state), .artwork(url))
    }

    func testNoArtworkShowsPlaceholder() {
        XCTAssertEqual(StatusDisplay.from(PlaybackState(isRunning: true)), .placeholder)
    }

    func testNotRunningAndPermissionDeniedShowPlaceholder() {
        XCTAssertEqual(StatusDisplay.from(.notRunning), .placeholder)
        XCTAssertEqual(StatusDisplay.from(.permissionDenied), .placeholder)
    }

    func testPopoverModes() {
        XCTAssertEqual(PopoverMode.from(.notRunning), .notRunning)
        XCTAssertEqual(PopoverMode.from(.permissionDenied), .permissionDenied)
        XCTAssertEqual(PopoverMode.from(PlaybackState(isRunning: true)), .track)
    }
}
