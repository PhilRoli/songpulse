import AppKit

@MainActor
final class PlaybackMonitor {
    static let spotifyBundleID = "com.spotify.client"
    static let notificationName = Notification.Name("com.spotify.client.PlaybackStateChanged")

    var onChange: ((PlaybackState) -> Void)?
    private(set) var state = PlaybackState.notRunning

    private let client: SpotifyControlling
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    init(client: SpotifyControlling, pollInterval: TimeInterval = 5) {
        self.client = client
        self.pollInterval = pollInterval
    }

    func start() {
        observe(DistributedNotificationCenter.default(), Self.notificationName)
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didLaunchApplicationNotification)
        observe(workspace, NSWorkspace.didTerminateApplicationNotification)
        Task { await refresh() }
    }

    func refresh(force: Bool = false) async {
        let fresh = await client.fetchState()
        guard force || fresh != state else { return }
        state = fresh
        onChange?(fresh)
    }

    /// Refreshes once after each delay in turn (used while Spotify is still starting up).
    func refresh(afterDelays delays: [TimeInterval]) async {
        for delay in delays {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await refresh()
        }
    }

    func setPopoverOpen(_ open: Bool) {
        timer?.invalidate()
        timer = nil
        guard open else { return }
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
            if name != Self.notificationName,
               let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier != Self.spotifyBundleID { return }
            let launched = name == NSWorkspace.didLaunchApplicationNotification
            Task { @MainActor in
                await self?.refresh()
                if launched { await self?.refresh(afterDelays: [1, 2, 5]) }
            }
        }
        observers.append((center, token))
    }

    deinit {
        for (center, token) in observers { center.removeObserver(token) }
    }
}
