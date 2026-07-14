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

## UI design specifications

- Read the UI design and layout in: [docs/ui.md](docs/ui.md).
- You MUST update the UI design document whenever the project UI changes.

## Build, Test, and Development Commands

- Read the build and run guide in: [docs/build.md](docs/build.md).
- You MUST update this guide whenever the build, run, or test steps for the project change.

## Coding Style & Naming Conventions
- Use 4-space indentation and follow Swift API Design Guidelines.
- Use `UpperCamelCase` for types and `lowerCamelCase` for functions/properties.
- Keep UI state in SwiftUI views; keep camera, photo picker, and scan pipeline logic in `ScannerView.swift`.
- Prefer small, focused changes. Avoid mixing refactors with feature fixes.

## Commit & Pull Request Guidelines
- Current history uses short, single-line subjects (for example, `Initial Commit`, `添加初始版本代码`); keep that style.
- Recommended format: `module: summary` (example: `scanner: improve photo QR fallback alert`).
- PRs should include purpose, key files changed, test evidence (command output or screenshots), and UI screenshots when relevant.

## Security & Configuration Tips
- Keep camera/photo permission messages in `QrScan/Info.plist` aligned with actual behavior.
- Do not commit screenshots or logs containing sensitive QR payloads.
- Call out changes to `UIApplicationShortcutItems`, bundle identifiers, or permissions in the PR impact summary.
