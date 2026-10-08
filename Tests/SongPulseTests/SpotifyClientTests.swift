import XCTest
@testable import SongPulse

final class SpotifyClientTests: XCTestCase {
    final class FakeRunner: ScriptRunning {
        var result: Result<String, Error> = .success("NOT_RUNNING")
        private(set) var sources: [String] = []
        func run(_ source: String) async throws -> String {
            sources.append(source)
            return try result.get()
        }
    }

    func testFetchStateParsesRunnerOutput() async {
        let runner = FakeRunner()
        runner.result = .success(["playing", "T", "A", "", "false", "false"].joined(separator: "\u{1F}"))
        let state = await SpotifyClient(runner: runner).fetchState()
        XCTAssertEqual(state.title, "T")
        XCTAssertTrue(state.isPlaying)
    }

    func testPermissionDeniedMapsToPermissionState() async {
        let runner = FakeRunner()
        runner.result = .failure(ScriptError(code: -1743))
        let state = await SpotifyClient(runner: runner).fetchState()
        XCTAssertEqual(state, .permissionDenied)
    }

    func testOtherErrorsMapToNotRunning() async {
        let runner = FakeRunner()
        runner.result = .failure(ScriptError(code: -600))
        let state = await SpotifyClient(runner: runner).fetchState()
        XCTAssertEqual(state, .notRunning)
    }

    func testCommandsAreGuardedAgainstLaunchingSpotify() async {
        let runner = FakeRunner()
        let client = SpotifyClient(runner: runner)
        await client.playPause()
        await client.next()
        await client.previous()
        await client.setShuffling(true)
        await client.setRepeating(false)
        XCTAssertEqual(runner.sources.count, 5)
        for source in runner.sources {
            XCTAssertTrue(source.contains("application \"Spotify\" is running"), source)
        }
        XCTAssertTrue(runner.sources[0].contains("playpause"))
        XCTAssertTrue(runner.sources[1].contains("next track"))
        XCTAssertTrue(runner.sources[2].contains("previous track"))
        XCTAssertTrue(runner.sources[3].contains("set shuffling to true"))
        XCTAssertTrue(runner.sources[4].contains("set repeating to false"))
    }

    func testStateScriptIsGuardedAndUsesSeparator() {
        XCTAssertTrue(SpotifyScripts.state.contains("application \"Spotify\" is running"))
        XCTAssertTrue(SpotifyScripts.state.contains("ASCII character 31"))
    }

    func testStateScriptConvertsMissingValueToEmptyText() {
        XCTAssertTrue(SpotifyScripts.state.contains("is missing value"))
    }

    func testScriptsUseATimeout() {
        XCTAssertTrue(SpotifyScripts.state.contains("with timeout of 5 seconds"))
        XCTAssertTrue(SpotifyScripts.playPause.contains("with timeout of 5 seconds"))
    }

    func testTimeoutKeepsLastKnownState() async {
        let runner = FakeRunner()
        runner.result = .success(["playing", "T", "A", "", "false", "false"].joined(separator: "\u{1F}"))
        let client = SpotifyClient(runner: runner)
        let before = await client.fetchState()
        runner.result = .failure(ScriptError(code: -1712))
        let after = await client.fetchState()
        XCTAssertEqual(before, after)
        XCTAssertTrue(after.isRunning)
    }

    func testCommandErrorsAreSwallowed() async {
        let runner = FakeRunner()
        runner.result = .failure(ScriptError(code: -1743))
        await SpotifyClient(runner: runner).playPause()
    }
}
