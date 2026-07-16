# Repository Guidelines

## Basic Rules

- All documents must be written in English.
- Coding rules defined in: [docs/rules.md](docs/rules.md), you MUST adhere these rules during development.
- Git commit guidelines defined in: [docs/git.md](docs/git.md), you MUST adhere these rules while committing code.

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
