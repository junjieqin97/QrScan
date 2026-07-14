# Repository Guidelines

## Basic Rules
- All documents must be written in English.

## Project Structure & Module Organization
This repository contains an iOS QR utility app built with SwiftUI and UIKit.

- `QrScan/`: app source and resources. Core files include `ContentView.swift` (main UI + QR generation), `ScannerView.swift` (camera/photo scanning), and `QrScanApp.swift` (entry point).
- `QrScan/Assets.xcassets/` and `QrScan/Base.lproj/`: image and interface resources.
- `QrScan/icon/`: icon source files and conversion script.
- `QrScanTests/`: unit tests using Apple `Testing`.
- `QrScanUITests/`: UI automation tests using `XCTest`.
- `QrScan.xcodeproj/`: project and build configuration.

## Build, Test, and Development Commands
- `open QrScan.xcodeproj`: open the project in Xcode for local development.
- `xcodebuild -project QrScan.xcodeproj -scheme QrScan -configuration Debug build`: command-line debug build.
- `xcodebuild -project QrScan.xcodeproj -scheme QrScan -destination 'platform=iOS Simulator,name=<Device>' test`: run all tests.
- `xcodebuild ... -only-testing:QrScanTests`: run unit tests only.
- `xcodebuild ... -only-testing:QrScanUITests`: run UI tests only.
- `bash QrScan/icon/QrScanIcon_svg_to_png.sh`: regenerate icon assets from SVG.

## Coding Style & Naming Conventions
- Use 4-space indentation and follow Swift API Design Guidelines.
- Use `UpperCamelCase` for types and `lowerCamelCase` for functions/properties.
- Keep UI state in SwiftUI views; keep camera, photo picker, and scan pipeline logic in `ScannerView.swift`.
- Prefer small, focused changes. Avoid mixing refactors with feature fixes.

## Testing Guidelines
- Unit tests use `Testing` (`@Test`); UI tests use `XCTest` (`test...` naming).
- Add at least one reproducible test or a clear manual verification step for every feature change.
- Prioritize UI assertions for scan flow, history behavior, and quick-action entry points.

## Commit & Pull Request Guidelines
- Current history uses short, single-line subjects (for example, `Initial Commit`, `添加初始版本代码`); keep that style.
- Recommended format: `module: summary` (example: `scanner: improve photo QR fallback alert`).
- PRs should include purpose, key files changed, test evidence (command output or screenshots), and UI screenshots when relevant.

## Security & Configuration Tips
- Keep camera/photo permission messages in `QrScan/Info.plist` aligned with actual behavior.
- Do not commit screenshots or logs containing sensitive QR payloads.
- Call out changes to `UIApplicationShortcutItems`, bundle identifiers, or permissions in the PR impact summary.
