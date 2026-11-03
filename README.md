# MenuTerm

A terminal emulator that integrates seamlessly with the macOS notch.

## Features

- Terminal that fits the macOS notch
- Global hotkey `Ctrl + `` to show or hide
- Auto-hide when the window loses focus
- Mouse wheel and trackpad two-finger scrolling, including history scrollback and in-terminal interactive programs
- Light and dark themes
- Adjustable height and opacity (Settings: `Cmd + ,`)

## Building

### Build script (recommended)

```bash
# Build Debug
./build.sh

# Build Release
./build.sh -c Release

# Clean and build Release
./build.sh -c Release -C

# Create an archive
./build.sh -c Release -a

# Show help
./build.sh -h
```

### Environment variables

```bash
CONFIG=Release ./build.sh
CLEAN=true ./build.sh -c Release
ARCHIVE=true ./build.sh
```

### Using xcodebuild directly

```bash
xcodebuild -project MenuTerm.xcodeproj -scheme MenuTerm -configuration Debug build
```

### Build output

| Configuration | Path |
|------|------|
| Debug | `build/Debug/MenuTerm.app` |
| Release | `build/Release/MenuTerm.app` |
| Archive | `build/MenuTerm.xcarchive` |

## Scroll and layout regression tests

```bash
./Tests/run-scroll-tests.sh
# Skip rebuild if you already ran ./build.sh
./Tests/run-scroll-tests.sh --skip-build
```

Tests synthesize mouse and trackpad events in-process. They cover window event forwarding, history scrollback, mouse reporting, arrow-key fallback for fullscreen programs, and trackpad small-move plus inertial scrolling. Accessibility permission is not required. Layout tests check left/right content insets, last-column hit testing, and hidden scrollbar reservation across window widths, font sizes, and fullscreen mode.

Manual checks:

- Run `seq 1 200` and scroll with the wheel or two fingers through history.
- Run `seq 1 200 | less` and confirm the fullscreen pager scrolls; press `q` to quit.
- In a mouse-aware TUI (for example Vim with `:set mouse=a`) confirm the program handles scrolling.
- Resize the window and change font size; confirm TUI side margins stay even and the right scrollbar aligns with the last content column.

## GitHub Releases

This repository publishes ad-hoc signed macOS app bundles to GitHub Releases.
The bundle signature seals the executable, Info.plist, and resources; it is
**not** a Developer ID signature and the app is **not notarized by Apple**.

- Trigger: push a tag like `v1.0.0`, or run the `Release` workflow manually.
- Manual runs derive the tag from `MARKETING_VERSION` in `project.yml`, for example `1.0.0` -> `v1.0.0`.
- Output: `MenuTerm-<tag>-macos-adhoc.zip`
- Extra file: `MenuTerm-<tag>-macos-adhoc.zip.sha256`
- CI verifies the bundle signature and app icon before packaging and after extracting the ZIP.

### First launch of a downloaded build

Ad-hoc signing only checks bundle integrity. It does not provide Apple trust or notarization. macOS may still block the first launch. This distribution is for people who trust this project; it is not the same as a Developer ID + notarized release.

1. Download the ZIP and `.sha256` from this repository's Releases. In the same directory run
   `shasum -a 256 -c MenuTerm-<tag>-macos-adhoc.zip.sha256` and confirm it passes.
2. Unzip and move `MenuTerm.app` into `/Applications`.
3. Verify the bundle: `codesign --verify --deep --strict --verbose=2 /Applications/MenuTerm.app`.
   If verification fails, do not bypass it — re-download or report the issue.
4. Try to open the app, then in **System Settings → Privacy & Security** choose **Open Anyway** if prompted.
   If it is still blocked and you trust the app, remove only this app's quarantine flag:

   ```bash
   xattr -dr com.apple.quarantine /Applications/MenuTerm.app
   open /Applications/MenuTerm.app
   ```

This bypasses the first-launch quarantine check for that app only; it does not turn off Gatekeeper system-wide. Do not run it on apps from unknown sources.
To open downloads without manual approval, you need a valid Developer ID Application certificate and Apple notarization credentials.

### “Damaged” alert on old v1.0.8 builds

Older CI disabled app signing. The ARM linker only ad-hoc-signed the executable and not the bundle resources, which produces `code has no resources but signature indicates they must be present`.
If you must use that old build and have confirmed it came from this repository, re-sign locally, then clear quarantine for this app only:

```bash
APP="/Applications/MenuTerm.app"
codesign --force --sign - --timestamp=none "$APP" &&
codesign --verify --deep --strict "$APP" &&
xattr -dr com.apple.quarantine "$APP" &&
open "$APP"
```

Re-signing does not prove the original download is trustworthy and is not Apple notarization. Do not use it to skip integrity failures on unknown files.

## App Icon

`logo.icon` is the Icon Composer source used by newer Xcode versions.
`MenuTerm/Assets.xcassets/logo.appiconset` contains a checked-in PNG fallback
with the same name for older Xcode versions (including Xcode 15.4 on the
`macos-14` release runner). Both build paths produce a compiled app icon.

The fallback is rendered from the SVG artwork and its scale/position in
`logo.icon/icon.json`, using a flat rounded black tile, soft drop shadow and
transparent macOS margins. The glyph stays RGB cool-white rather than exact
grayscale: the grayscale catalog representation can acquire an unwanted white
backing tile on macOS 27. Do **not** generate it by resizing an
`ictool --export-image` preview:
that preview bakes in a full-bleed glass edge/mask, which macOS's legacy-icon
rendering can turn into short bright vertical seams on both sides. Native
Icon Composer builds keep their layered material rendering.

After changing the artwork, regenerate the fallback on a Mac with Xcode:

```bash
./scripts/generate-app-icon.sh
```

The generator uses AppKit, without Icon Composer or third-party dependencies.
It currently supports this icon's single visible SVG layer on a black tile;
revisit the generator when changing the layer structure or background color.

The release workflow validates the icon metadata, decodes the packaged `.icns`,
and runs icon regression tests before publishing. To run these checks locally:

```bash
./scripts/verify-app-icon.sh build/Release/MenuTerm.app
./Tests/run-icon-tests.sh build/Release/MenuTerm.app
# Source + legacy ICNS/catalog tests, without building the app:
./Tests/run-icon-tests.sh
```

The tests check all ten PNG sizes for transparent margins and unlit edges,
then render an ICNS-only fixture, an `actool`-compiled legacy asset catalog, and
the supplied app through `NSWorkspace` at 64/128/256/512 pixels. Previews are
saved in `build/icon-tests/`.
The side-highlight assertion runs on macOS 27, where the issue was reproduced;
other OS versions still check the PNGs and export system-rendered previews.
Inspect these previews when changing the icon or upgrading the build tools.
