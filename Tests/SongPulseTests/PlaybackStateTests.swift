import XCTest
@testable import SongPulse

final class PlaybackStateTests: XCTestCase {
    private let us = "\u{1F}"

    private func line(_ fields: String...) -> String {
        fields.joined(separator: us)
    }

    func testParsesPlayingTrack() {
        let art = "https://i.scdn.co/image/abc"
        let state = PlaybackState.parse(line("playing", "Song", "Artist", art, "true", "false"))
        XCTAssertTrue(state.isRunning)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.title, "Song")
        XCTAssertEqual(state.artist, "Artist")
        XCTAssertEqual(state.artworkURL, URL(string: "https://i.scdn.co/image/abc"))
        XCTAssertTrue(state.shuffling)
        XCTAssertFalse(state.repeating)
    }

    func testPausedIsNotPlaying() {
        let state = PlaybackState.parse(line("paused", "S", "A", "", "false", "true"))
        XCTAssertTrue(state.isRunning)
        XCTAssertFalse(state.isPlaying)
        XCTAssertTrue(state.repeating)
    }

    func testNotRunning() {
        XCTAssertEqual(PlaybackState.parse("NOT_RUNNING"), .notRunning)
        XCTAssertFalse(PlaybackState.notRunning.isRunning)
    }

    func testEmptyTrackFieldsAndArtworkParseWithoutCrash() {
        let state = PlaybackState.parse(line("playing", "", "", "", "false", "false"))
        XCTAssertTrue(state.isRunning)
        XCTAssertEqual(state.title, "")
        XCTAssertNil(state.artworkURL)
    }

    func testUnicodeQuotesAndEmojiInTitle() {
        let state = PlaybackState.parse(line("playing", "He said \"hi\" 🎵 — 日本語", "Ä & B", "", "false", "false"))
        XCTAssertEqual(state.title, "He said \"hi\" 🎵 — 日本語")
        XCTAssertEqual(state.artist, "Ä & B")
    }

    func testMalformedInputIsNotRunning() {
        XCTAssertEqual(PlaybackState.parse(""), .notRunning)
        XCTAssertEqual(PlaybackState.parse("garbage"), .notRunning)
        XCTAssertEqual(PlaybackState.parse("playing\(us)only\(us)three"), .notRunning)
    }

    func testPermissionDeniedConstant() {
        XCTAssertTrue(PlaybackState.permissionDenied.permissionDenied)
        XCTAssertFalse(PlaybackState.notRunning.permissionDenied)
    }
}
