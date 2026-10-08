# SongPulse

Menu bar app that shows the album art of your current Spotify song. Click it for a larger cover, title, artist and controls: play/pause, previous, next, shuffle and repeat.

## Installation

### Homebrew

```bash
brew tap PhilRoli/tap
brew install --cask songpulse
```

SongPulse is ad-hoc signed (not notarized). On first launch, right-click the app in Finder and choose "Open" to bypass Gatekeeper, or run:

```bash
xattr -dr com.apple.quarantine /Applications/SongPulse.app
```

## Permissions

SongPulse controls the Spotify desktop app through AppleScript, so it needs no login or API keys. macOS asks once whether SongPulse may control Spotify; if you declined, re-enable it under System Settings › Privacy & Security › Automation. Spotify must be installed and running.

Because the app is ad-hoc signed, macOS may forget the permission after an upgrade. If the popover asks for permission although SongPulse is already enabled, run `tccutil reset AppleEvents com.philipp.SongPulse` and relaunch.

## How it works

- Updates instantly from Spotify's own playback notifications; no polling while idle.
- While the popover is open, state is refreshed every 5 s so shuffle/repeat changes made inside Spotify show up.
- Menu bar: album art while Spotify is running, a music-note icon otherwise.

## Development

- Build + install locally: `./rebuild.sh` (installs to /Applications, ad-hoc signed; macOS may re-ask for the Automation permission after each rebuild).
- Tests: `swift test`. Lint: `swiftlint --strict`.
- Release: push a tag `vX.Y.Z`. The Release workflow builds a universal app, publishes `SongPulse-X.Y.Z.app.zip` and updates `Casks/songpulse.rb` in `PhilRoli/homebrew-tap` (needs the `HOMEBREW_TAP_TOKEN` repo secret).
- Regenerate the icon: `scripts/make-icon.sh`.

## License

MIT
