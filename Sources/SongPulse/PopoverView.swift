import SwiftUI

struct PopoverView: View {
    /// Fixed so the popover never resizes after it is shown: NSPopover keeps its bottom edge when content grows,
    /// which pushes it over the menu bar.
    static let size = NSSize(width: 260, height: 372)

    @ObservedObject var model: PlayerViewModel

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            footer
        }
        .padding(16)
        .frame(width: Self.size.width, height: Self.size.height)
    }

    @ViewBuilder private var content: some View {
        switch PopoverMode.from(model.state) {
        case .track:
            trackView
        case .notRunning:
            messageView("Spotify isn't running", button: "Open Spotify", action: model.openSpotify)
        case .permissionDenied:
            messageView(
                "Allow SongPulse to control Spotify in System Settings › Privacy & Security › Automation",
                button: "Open Settings", action: model.openAutomationSettings
            )
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Menu {
                Toggle("Launch at Login", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { _ in model.toggleLaunchAtLogin() }
                ))
                Divider()
                Button("Quit SongPulse") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var trackView: some View {
        VStack(spacing: 12) {
            artworkView
            VStack(spacing: 2) {
                Text(model.state.title.isEmpty ? "Unknown" : model.state.title)
                    .font(.headline).lineLimit(1)
                Text(model.state.artist)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            controls
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            toggleButton("shuffle", on: model.state.shuffling) { await model.toggleShuffle() }
            button("backward.fill") { await model.previous() }
            button(model.state.isPlaying ? "pause.fill" : "play.fill", size: 26) { await model.togglePlayPause() }
            button("forward.fill") { await model.next() }
            toggleButton("repeat", on: model.state.repeating) { await model.toggleRepeat() }
        }
    }

    private var artworkView: some View {
        Group {
            if let image = model.artwork {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "music.note").font(.system(size: 48)).foregroundStyle(.secondary)
            }
        }
        .frame(width: 228, height: 228)
        .background(Color.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func button(_ symbol: String, size: CGFloat = 18, action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
            Image(systemName: symbol).font(.system(size: size))
        }
        .buttonStyle(.plain)
    }

    private func toggleButton(_ symbol: String, on: Bool, action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
            Image(systemName: symbol).font(.system(size: 15))
                .foregroundStyle(on ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func messageView(_ text: String, button title: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note").font(.system(size: 40)).foregroundStyle(.secondary)
            Text(text).multilineTextAlignment(.center)
            Button(title, action: action)
        }
        .padding(.vertical, 12)
    }
}
