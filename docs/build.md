# Build and Run Guide

## 1. Project overview

QrScan is a native iOS QR utility built as one Xcode project. The application UI is primarily SwiftUI, while camera capture, photo selection, and barcode recognition are implemented through UIKit controllers and Apple media frameworks.

The repository has no Swift Package Manager, CocoaPods, or Carthage dependencies. All runtime dependencies are Apple system frameworks supplied by the selected Xcode SDK.

The main capabilities are:

- Generate a QR code from text with a selectable error-correction level.
- Preload short text from the system clipboard.
- Save a generated QR image to Photos.
- Scan QR codes with the camera through AVFoundation.
- Detect QR codes in existing images through Vision.
- Store up to 200 scan results in `UserDefaults` and expose copy/clear actions.
- Open the scanner from an application Home Screen quick action.
- Display English or Simplified Chinese strings according to the device region.

## 2. Repository and target layout

| Path or target         | Role                                                                                    |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `QrScan.xcodeproj`     | Xcode project, build settings, target graph, and the available `QrScan` scheme.         |
| `QrScan` target        | The iOS application bundle.                                                             |
| `QrScanTests` target   | Host-based unit tests written with Apple `Testing`.                                     |
| `QrScanUITests` target | UI, launch, and performance tests written with `XCTest`.                                |
| `QrScan/`              | Application source, property lists, localized strings, storyboards, and asset catalogs. |
| `QrScanTests/`         | Unit-test sources.                                                                      |
| `QrScanUITests/`       | UI-test sources.                                                                        |
| `QrScan/icon/`         | App icon SVG source and an optional PNG conversion script.                              |

The project uses Xcode file-system-synchronized root groups. Files placed under `QrScan/`, `QrScanTests/`, or `QrScanUITests/` are discovered from the corresponding directory instead of being listed one by one in `project.pbxproj`. `QrScan/Info.plist` is explicitly excluded from normal target membership because it is consumed as the app's Info property list and must not also be copied as a resource.

## 3. Toolchain and platform requirements

The checked-in project was created with Xcode 26.1.1 and currently has the following effective requirements:

| Setting                 | Value                                            |
| ----------------------- | ------------------------------------------------ |
| iOS deployment target   | 26.1                                             |
| Supported devices       | iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Swift language mode     | Swift 5                                          |
| Build configurations    | Debug and Release                                |
| App bundle identifier   | `com.github.QrScan`                              |
| Marketing version       | 1.0                                              |
| Build number            | 1                                                |
| Code signing            | Automatic, configured team `8QKJD4CQTN`          |
| Default actor isolation | `MainActor` for the app target                   |
| Localizations           | English, Base, and Simplified Chinese            |

Use Xcode 26.1.1 or later with an iOS 26.1-or-later SDK and Simulator runtime. A newer Xcode can build the project as long as it still supplies a compatible SDK.

Check the selected toolchain with:

```sh
xcode-select -p
xcodebuild -version
xcrun simctl list devices available
```

If command-line tools point to a different Xcode installation, select the intended Xcode before building. Installing or switching Xcode may require administrator access.

## 4. Source architecture and runtime flow

### 4.1 Application lifecycle

`QrScanApp.swift` is the executable entry point through the SwiftUI `@main` attribute. It:

1. Adapts `AppDelegate` into the SwiftUI lifecycle with `@UIApplicationDelegateAdaptor`.
2. Resolves one `AppLanguage` for the process.
3. Owns the Boolean state that presents the scanner sheet.
4. Creates `ContentView` inside a `WindowGroup`.
5. Opens the scanner when a launch-time or runtime quick-action event is received.

`AppDelegate.swift` creates a localized dynamic Home Screen quick action and installs `ShortcutSceneDelegate` for connected scenes. `ShortcutSceneDelegate.swift` handles both cold-start and already-running quick-action paths. A cold-start action is held in `ShortcutActionState` until `ContentView` appears; a runtime action is delivered through `NotificationCenter`.

The application does not start from a storyboard. `Info.plist` leaves `UIMainStoryboardFile` empty, and the SwiftUI `@main` type creates the window content. `Main.storyboard` is still compiled as a synchronized resource but is not the application entry point.

### 4.2 Main UI and QR generation

`ContentView.swift` owns the main SwiftUI state:

- The editable or scanned text.
- The generated `UIImage`.
- The QR correction level.
- Scanner-sheet presentation.
- Copy/save status messages.
- Which history row currently exposes its copy button.

When the input text or correction level changes, `CIFilter.qrCodeGenerator()` creates a Core Image QR code. A `CIContext` converts the scaled output into a `UIImage` for display and saving. Empty input produces no QR image and disables the save action.

On first appearance, clipboard text is loaded only when its length is at most 100 characters. Saving calls `UIImageWriteToSavedPhotosAlbum`; copying uses `UIPasteboard`.

### 4.3 Scanning pipeline

`ScannerView.swift` bridges a UIKit `ScannerViewController` into SwiftUI with `UIViewControllerRepresentable`.

The live camera path is:

1. Obtain the default video capture device.
2. Add an `AVCaptureDeviceInput` and `AVCaptureMetadataOutput` to an `AVCaptureSession`.
3. Restrict metadata recognition to QR codes.
4. Display an `AVCaptureVideoPreviewLayer`.
5. Stop the session after the first QR payload and return it to `ContentView`.

The photo-library path presents `UIImagePickerController`, converts the selected image to `CGImage`, and runs a `VNDetectBarcodesRequest` restricted to QR symbology. If no QR code is found, the camera session resumes and a localized alert is shown.

The scanner also exposes cancel, photo-library, and torch controls. A successful scan replaces the editor text and appends the payload to scan history.

### 4.4 History, localization, and persistence

`ScanHistorySection.swift` stores history as a JSON-encoded string in `UserDefaults` under `devtools_scan_history`. `@AppStorage` keeps the SwiftUI view synchronized with that value. New entries are appended, the oldest entries are removed when the count exceeds 200, and the UI displays newest entries first.

`AppLanguage.swift` chooses Simplified Chinese only when the device region code is `CN`; all other or missing region codes use English. This is region-based behavior, not a direct check of the user's preferred language list. `L10n` loads strings from the matching `.lproj` bundle. `InfoPlist.strings` localizes camera/photo permission prompts and static shortcut labels.

`Item.swift` declares a SwiftData model left over from the project template. No model container is attached to `QrScanApp`, and the model is not used by the current application or scan-history pipeline.

## 5. Framework dependencies

The project imports and links only SDK frameworks:

| Framework or module              | Use                                                                               |
| -------------------------------- | --------------------------------------------------------------------------------- |
| SwiftUI                          | Main UI, state, sheets, previews, and `@AppStorage`.                              |
| UIKit                            | Clipboard, image saving, scanner controls, image picker, and app/scene delegates. |
| CoreImage and `CIFilterBuiltins` | QR code generation.                                                               |
| AVFoundation                     | Camera session, QR metadata output, preview, and torch.                           |
| Vision                           | QR detection in selected photos.                                                  |
| Foundation                       | Localization, JSON encoding, notifications, and general data types.               |
| SwiftData                        | Currently only the unused template `Item` model.                                  |
| Testing                          | Unit-test declarations and expectations.                                          |
| XCTest                           | UI, launch, and performance testing.                                              |

There is no dependency-resolution step before a normal build.

## 6. How Xcode builds the application

Building the `QrScan` scheme performs these main stages:

1. Xcode loads the synchronized source/resource directories and evaluates Debug or Release settings.
2. Interface Builder compiles `Main.storyboard` and `LaunchScreen.storyboard`.
3. Asset Catalog Compiler processes `Assets.xcassets`, including `AppIcon` and `AccentColor`.
4. English and Simplified Chinese `.strings` resources are copied into the app bundle.
5. The Swift compiler builds the source files in Swift 5 language mode against the selected iOS SDK.
6. The linker produces the `QrScan` executable and links required Apple frameworks.
7. Xcode expands `QrScan/Info.plist`, combines generated storyboard/asset metadata, copies the Swift runtime when required, validates the bundle, and signs it for the selected destination.

Debug builds use `-Onone`, define `DEBUG`, enable testability, and normally build only the active architecture in Xcode. Release builds use whole-module compilation, disable assertions, generate dSYM debug information, and validate the final product.

With `-derivedDataPath .derivedData`, the Simulator app is written to:

```text
.derivedData/Build/Products/Debug-iphonesimulator/QrScan.app
```

The repository ignores `.derivedData/`.

## 7. Build commands

Run commands from the repository root.

### 7.1 Inspect the project

```sh
xcodebuild -project QrScan.xcodeproj -list
xcodebuild -project QrScan.xcodeproj -scheme QrScan -showdestinations
```

### 7.2 Reproducible Simulator build

This command verifies compilation without requiring an Apple Developer signing identity or a booted Simulator:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### 7.3 Signed device build

A physical-device build uses automatic signing:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .derivedData \
  build
```

The configured development team must be available in Xcode. If it is not, select your team in **QrScan target > Signing & Capabilities** and change `com.github.QrScan` to a bundle identifier owned by that team.

### 7.4 Release archive

Archiving also requires valid device signing:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath .derivedData/QrScan.xcarchive \
  archive
```

Exporting an IPA is a separate signing/distribution step and requires an export-options property list appropriate for the selected Apple Developer account.

## 8. Run the application

### 8.1 Run from Xcode

1. Open `QrScan.xcodeproj` in Xcode.
2. Select the `QrScan` scheme.
3. Choose an iOS 26.1-or-later Simulator or a provisioned iPhone/iPad.
4. For a physical device, confirm the signing team and bundle identifier.
5. Press **Run** or use `Command-R`.
6. Grant camera and Photos permissions when the related feature is first used.

A physical device is required for meaningful live-camera and torch verification. A Simulator can run the main UI, generate/copy/save QR codes, exercise history, and test photo-library detection, but it does not provide the app with a normal physical camera feed.

### 8.2 Run from the command line on a Simulator

First select an available Simulator whose runtime is at least iOS 26.1:

```sh
xcrun simctl list devices available
```

Then assign its identifier to `UDID`:

```sh
UDID='<simulator-udid>'
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b

xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath .derivedData \
  build

xcrun simctl install \
  "$UDID" \
  .derivedData/Build/Products/Debug-iphonesimulator/QrScan.app

xcrun simctl launch "$UDID" com.github.QrScan
```

Replace `<simulator-udid>` with a real UDID; angle-bracket placeholders are not accepted literally.

## 9. Permissions and system integration

`QrScan/Info.plist` declares:

- `NSCameraUsageDescription` for live QR scanning.
- `NSPhotoLibraryUsageDescription` for selecting images to scan.
- `NSPhotoLibraryAddUsageDescription` for saving generated QR images.
- A `UIApplicationShortcutItems` entry with type `com.github.QrScan.scan`.

The permission text and shortcut title/subtitle are localized through `en.lproj/InfoPlist.strings` and `zh-Hans.lproj/InfoPlist.strings`. Keep these keys aligned with actual behavior when scanner, photo, or shortcut functionality changes.

At launch, `AppDelegate` also creates the scan shortcut dynamically so its text follows the app's resolved language. Selecting the shortcut opens the scanner directly whether the app is launching or already running.

## 10. Tests

Choose an installed Simulator with iOS 26.1 or later. Device names vary by Xcode installation, so replace `<Device>` and optionally `<OS>` with values from `xcrun simctl list devices available`.

Run all tests:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -destination 'platform=iOS Simulator,name=<Device>,OS=<OS>' \
  -derivedDataPath .derivedData \
  test
```

Run only unit tests:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -destination 'platform=iOS Simulator,name=<Device>,OS=<OS>' \
  -derivedDataPath .derivedData \
  -only-testing:QrScanTests \
  test
```

Run only UI tests:

```sh
xcodebuild \
  -project QrScan.xcodeproj \
  -scheme QrScan \
  -destination 'platform=iOS Simulator,name=<Device>,OS=<OS>' \
  -derivedDataPath .derivedData \
  -only-testing:QrScanUITests \
  test
```

The current unit suite contains four tests for `AppLanguage.resolve`: `CN`, lowercase `cn`, `US`, and a missing region. The current UI suite is mostly the Xcode template: it verifies that the app can be launched, measures launch performance, and captures a launch screenshot. It does not yet assert the QR generation, scanning, history, or quick-action flows.

Camera scanning and torch behavior should be manually verified on a physical device even when Simulator tests pass.

## 11. App icon generation

`QrScan/icon/QrScanIcon.svg` is the source artwork. `QrScanIcon_svg_to_png.sh` invokes Bash, Inkscape, `bc`, and `awk` to generate multiple PNG sizes.

The script resolves its input and output paths relative to its current working directory, so run it from `QrScan/icon`:

```sh
(
  cd QrScan/icon
  bash QrScanIcon_svg_to_png.sh
)
```

Generated PNG files under `QrScan/Assets.xcassets/AppIcon.appiconset/` are ignored by Git. In addition, the current `Contents.json` assigns filenames to only a subset of the declared icon slots. Consequently, a clean build may report missing required icon sizes and unassigned icon children. These are asset-catalog warnings rather than Swift compilation errors, but the icon set should be corrected before distribution.

The icon conversion script is optional and is not an Xcode build phase; normal builds never run Inkscape automatically.

## 12. Known build and runtime considerations

- The minimum OS is iOS 26.1. Older installed Simulators cannot be selected for this project.
- A generic Simulator build can compile without signing, but installing/running an app or test bundle requires the normal local Simulator signature produced by a destination-specific build.
- Physical-device builds require a valid development team, provisioning profile, and usually a team-owned unique bundle identifier.
- The App Icon catalog currently emits missing/unassigned icon warnings as described above.
- `Main.storyboard` is compiled but unused because the app starts through `QrScanApp` and the main storyboard name is empty.
- `Item.swift` imports SwiftData, but no persistent SwiftData store is constructed. Scan history is stored only in `UserDefaults`.
- Language selection is based on region (`CN`) rather than the preferred-language order.
- Live camera and torch paths require physical hardware; use photo-library scanning for repeatable Simulator checks.

## 13. Troubleshooting

### No eligible Simulator destination

Install an iOS 26.1-or-later runtime in Xcode, then confirm it appears in:

```sh
xcrun simctl list devices available
```

### Simulator service or test runner is stuck

Open Simulator once from Xcode, boot the chosen device, wait for `bootstatus` to finish, and retry with its exact UDID. A test cannot start while the selected Simulator is still completing first-boot data migration.

### Signing or provisioning failure

Open the app target's **Signing & Capabilities** pane, select an available team, and use a unique bundle identifier. Simulator-only builds can use the unsigned generic build command from Section 7.2.

### Camera scanner immediately closes in Simulator

This occurs when `AVCaptureDevice.default(for: .video)` returns no video device. Use a physical iPhone/iPad for live scanning, or use the scanner's photo-library path where supported.

### Permission behavior is unexpected

Verify all three privacy keys in `QrScan/Info.plist` and their localized values in both `InfoPlist.strings` files. Delete the app from the destination or reset its privacy permissions before retesting first-launch prompts.

### Stale build artifacts

The documented commands keep generated data in `.derivedData`. Remove that directory and rebuild when changing Xcode versions or when cached build metadata appears inconsistent:

```sh
rm -rf .derivedData
```
