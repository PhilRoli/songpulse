import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let client = SpotifyClient()
    private lazy var monitor = PlaybackMonitor(client: client)
    private let statusBar = StatusBarController()
    private let popover = NSPopover()
    private var model: PlayerViewModel?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = PlayerViewModel(
            client: client, monitor: monitor,
            artworkLoader: ArtworkLoader(), loginItem: LoginItemController()
        )
        self.model = model

        popover.behavior = .transient
        popover.contentSize = PopoverView.size
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))

        monitor.onChange = { state in model.apply(state) }
        // Artwork loads asynchronously after apply(), so redraw the status item whenever either changes.
        Publishers.CombineLatest(model.$state, model.$artwork)
            .removeDuplicates { StatusDisplay.from($0.0) == StatusDisplay.from($1.0) && $0.1 === $1.1 }
            .receive(on: RunLoop.main)
            .sink { [unowned self] state, artwork in self.statusBar.update(state, artwork: artwork) }
            .store(in: &cancellables)

        statusBar.onToggle = { [unowned self] in self.togglePopover() }
        monitor.start()
    }

    private func togglePopover() {
        guard let button = statusBar.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            monitor.setPopoverOpen(true)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        monitor.setPopoverOpen(false)
    }
}
