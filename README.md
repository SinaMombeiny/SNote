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
The app is ad-hoc signed for this repository, so macOS Gatekeeper may
display a warning on first launch. Control-click the app, choose **Open**, then
choose **Open** again in the confirmation dialog.
