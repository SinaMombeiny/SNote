# Hello C++ + SwiftUI

A minimal macOS app whose text comes from a C++ helper.

## Run

Install Xcode on macOS, open Terminal, and run:

```sh
cd /path/to/HelloCppSwift
swift run
```

The app window should display **Hello, world!**.

To build a release executable:

```sh
swift build -c release
```

## macOS download

Download `HelloCppSwift-macOS.dmg` or `HelloCppSwift-macOS.zip` from
[GitHub Releases](https://github.com/SinaMombeiny/HelloCppSwift/releases).

Open the DMG and drag `HelloCppSwift.app` to the Applications folder.
If macOS says Apple could not verify the app, remove the downloaded app
quarantine flag, then open it:

```sh
xattr -cr /Applications/HelloCppSwift.app
open /Applications/HelloCppSwift.app
```

For a warning-free download, this repository supports Apple Developer
ID signing and notarization. Configure these GitHub Actions secrets:
`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`,
`NOTARIZATION_APPLE_ID`, `NOTARIZATION_PASSWORD`, and
`NOTARIZATION_TEAM_ID`.
