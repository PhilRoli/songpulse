import AppKit

@MainActor
final class StatusBarController: NSObject {
    var onToggle: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var button: NSStatusBarButton? { statusItem.button }

    override init() {
        super.init()
        showPlaceholder()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(clicked)
    }

    func update(_ state: PlaybackState, artwork: NSImage?) {
        switch StatusDisplay.from(state) {
        case .artwork where artwork != nil:
            statusItem.button?.image = artwork?.rounded(size: NSSize(width: 18, height: 18), radius: 4)
        default:
            showPlaceholder()
        }
    }

    private func showPlaceholder() {
        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "SongPulse")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    @objc private func clicked() {
        onToggle?()
    }
}
