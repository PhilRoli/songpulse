import XCTest
@testable import SongPulse

@MainActor
final class PlaybackMonitorTests: XCTestCase {
    final class FakeClient: SpotifyControlling {
        var state = PlaybackState.notRunning
        private(set) var fetches = 0
        func fetchState() async -> PlaybackState {
            fetches += 1
            return state
        }
        func playPause() async {}
        func next() async {}
        func previous() async {}
        func setShuffling(_ on: Bool) async {}
        func setRepeating(_ on: Bool) async {}
    }

    func testRefreshPublishesChangedState() async {
        let client = FakeClient()
        let monitor = PlaybackMonitor(client: client)
        var received: [PlaybackState] = []
        monitor.onChange = { received.append($0) }
        client.state = PlaybackState(isRunning: true, isPlaying: true, title: "T")
        await monitor.refresh()
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(monitor.state.title, "T")
    }

    func testIdenticalStateIsNotRepublished() async {
        let client = FakeClient()
        let monitor = PlaybackMonitor(client: client)
        var count = 0
        monitor.onChange = { _ in count += 1 }
        client.state = PlaybackState(isRunning: true, title: "T")
        await monitor.refresh()
        await monitor.refresh()
        await monitor.refresh()
        XCTAssertEqual(count, 1)
        XCTAssertEqual(client.fetches, 3)
    }

    func testForcedRefreshRepublishesIdenticalState() async {
        let client = FakeClient()
        let monitor = PlaybackMonitor(client: client)
        var count = 0
        monitor.onChange = { _ in count += 1 }
        client.state = PlaybackState(isRunning: true, title: "T")
        await monitor.refresh()
        await monitor.refresh(force: true)
        XCTAssertEqual(count, 2)
    }

    func testOpeningPopoverTriggersRefresh() async {
        let client = FakeClient()
        let monitor = PlaybackMonitor(client: client, pollInterval: 3600)
        monitor.setPopoverOpen(true)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertGreaterThanOrEqual(client.fetches, 1)
        monitor.setPopoverOpen(false)
    }
}
