# SNote

A simple native macOS notes app built with SwiftUI and C++.

## Run

Install Xcode on macOS, open Terminal, and run:

```sh
cd /path/to/HelloCppSwift
swift run
```

SNote opens with a notes sidebar and a text editor.

To build a release executable:

```sh
swift build -c release
```

## macOS download

Download `SNote-macOS.dmg` or `SNote-macOS.zip` from
[GitHub Releases](https://github.com/SinaMombeiny/HelloCppSwift/releases).

Open the DMG and drag `SNote.app` to the Applications folder.
If macOS says Apple could not verify the app, remove the downloaded app
quarantine flag, then open it:

```sh
xattr -cr /Applications/SNote.app
open /Applications/SNote.app
```

For a warning-free download, this repository supports Apple Developer
ID signing and notarization. Configure these GitHub Actions secrets:
`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`,
`NOTARIZATION_APPLE_ID`, `NOTARIZATION_PASSWORD`, and
`NOTARIZATION_TEAM_ID`.
