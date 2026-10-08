import AppKit
import XCTest
@testable import SongPulse

@MainActor
final class PlayerViewModelTests: XCTestCase {
    final class FakeClient: SpotifyControlling {
        var state = PlaybackState.notRunning
        private(set) var commands: [String] = []
        func fetchState() async -> PlaybackState { state }
        func playPause() async { commands.append("playpause") }
        func next() async { commands.append("next") }
        func previous() async { commands.append("previous") }
        func setShuffling(_ on: Bool) async { commands.append("shuffle=\(on)") }
        func setRepeating(_ on: Bool) async { commands.append("repeat=\(on)") }
    }

    struct NoFetch: DataFetching {
        func data(from url: URL) async throws -> Data { throw URLError(.badURL) }
    }

    final class NoopLogin: LoginItemManaging {
        var isEnabled = false
        func register() throws { isEnabled = true }
        func unregister() throws { isEnabled = false }
    }

    private func makeModel(_ client: FakeClient) -> PlayerViewModel {
        PlayerViewModel(
            client: client,
            monitor: PlaybackMonitor(client: client),
            artworkLoader: ArtworkLoader(fetcher: NoFetch()),
            loginItem: LoginItemController(manager: NoopLogin())
        )
    }

    func testPlayPauseFlipsOptimisticallyAndSendsCommand() async {
        let client = FakeClient()
        client.state = PlaybackState(isRunning: true, isPlaying: false)
        let model = makeModel(client)
        model.apply(client.state)
        await model.togglePlayPause()
        XCTAssertEqual(client.commands, ["playpause"])
    }

    func testOptimisticFlipIsVisibleBeforeRefreshSettles() async {
        let client = FakeClient()
        let model = makeModel(client)
        model.apply(PlaybackState(isRunning: true, isPlaying: false))
        let task = Task { await model.togglePlayPause() }
        await Task.yield()
        XCTAssertTrue(model.state.isPlaying)
        await task.value
    }

    func testShuffleAndRepeatSendTargetValue() async {
        let client = FakeClient()
        client.state = PlaybackState(isRunning: true, shuffling: false, repeating: true)
        let model = makeModel(client)
        model.apply(client.state)
        await model.toggleShuffle()
        await model.toggleRepeat()
        XCTAssertEqual(client.commands, ["shuffle=true", "repeat=false"])
    }

    func testNextAndPrevious() async {
        let client = FakeClient()
        let model = makeModel(client)
        model.apply(PlaybackState(isRunning: true))
        await model.next()
        await model.previous()
        XCTAssertEqual(client.commands, ["next", "previous"])
    }

    func testApplyClearsArtworkWhenURLIsNil() {
        let model = makeModel(FakeClient())
        model.artwork = NSImage(size: NSSize(width: 1, height: 1))
        model.apply(PlaybackState(isRunning: true))
        XCTAssertNil(model.artwork)
    }
}
