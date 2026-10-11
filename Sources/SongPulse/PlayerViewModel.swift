import AppKit
import MenuBarKit

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var state = PlaybackState.notRunning
    @Published var artwork: NSImage?
    @Published var launchAtLogin: Bool

    private let client: SpotifyControlling
    private let monitor: PlaybackMonitor
    private let artworkLoader: ArtworkLoader
    private let loginItem: LoginItemController
    private var loadingURL: URL?

    init(client: SpotifyControlling, monitor: PlaybackMonitor,
         artworkLoader: ArtworkLoader, loginItem: LoginItemController) {
        self.client = client
        self.monitor = monitor
        self.artworkLoader = artworkLoader
        self.loginItem = loginItem
        self.launchAtLogin = loginItem.isEnabled
    }

    func apply(_ newState: PlaybackState) {
        let previousURL = state.artworkURL
        state = newState
        guard let url = newState.artworkURL, newState.isRunning else {
            artwork = nil
            loadingURL = nil
            return
        }
        if url == previousURL, artwork != nil || loadingURL == url { return }
        loadingURL = url
        Task {
            let image = await artworkLoader.image(for: url)
            if state.artworkURL == url { artwork = image }
            if loadingURL == url { loadingURL = nil }
        }
    }

    func togglePlayPause() async {
        state.isPlaying.toggle()
        await client.playPause()
        await monitor.refresh(force: true)
    }

    func next() async {
        await client.next()
        await monitor.refresh(force: true)
    }

    func previous() async {
        await client.previous()
        await monitor.refresh(force: true)
    }

    func toggleShuffle() async {
        let target = !state.shuffling
        state.shuffling = target
        await client.setShuffling(target)
        await monitor.refresh(force: true)
    }

    func toggleRepeat() async {
        let target = !state.repeating
        state.repeating = target
        await client.setRepeating(target)
        await monitor.refresh(force: true)
    }

    func toggleLaunchAtLogin() {
        if loginItem.setEnabled(!launchAtLogin) { launchAtLogin.toggle() }
    }

    func openSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: PlaybackMonitor.spotifyBundleID)
        else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
