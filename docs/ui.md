# UI Design and Layout

## 1. Overview

QrScan uses a deliberately small, utility-oriented interface. The root interface contains two horizontally paged screens: a default generator page and a history page immediately to its right. The generator keeps the primary workflow together, while a leftward swipe reveals scan history without adding a navigation destination or top tab bar.

The UI is hybrid:

- SwiftUI builds the application shell, generator screen, action buttons, transient status messages, history section, and scanner presentation.
- UIKit builds the live scanner controller and its overlay controls.
- Apple-provided UI supplies the camera preview, photo picker, permission prompts, and alerts.

The application does not define a custom design system. It relies on system fonts, semantic colors, standard button styles, SF Symbols, and native controls so that most visual details follow the active iOS version and light or dark appearance.

## 2. UI source map

| File                                                                | UI responsibility                                                                                                   |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `QrScan/QrScanApp.swift`                                            | Creates the window, injects the resolved locale, owns scanner presentation state, and handles scan quick actions.   |
| `QrScan/ContentView.swift`                                          | Builds the two-page container, generator screen, QR preview, primary actions, feedback, and scanner sheet.          |
| `QrScan/ScanHistorySection.swift`                                   | Builds the history header and expandable copy rows.                                                                 |
| `QrScan/ScannerView.swift`                                          | Bridges UIKit into SwiftUI and builds the camera/photo scanner UI.                                                  |
| `QrScan/AppLanguage.swift`                                          | Selects English or Simplified Chinese and loads localized UI strings.                                               |
| `QrScan/AppDelegate.swift` and `QrScan/ShortcutSceneDelegate.swift` | Define and route the Home Screen quick action that opens the scanner.                                               |
| `QrScan/Base.lproj/LaunchScreen.storyboard`                         | Provides a blank, system-background launch screen.                                                                  |
| `QrScan/Base.lproj/Main.storyboard`                                 | Contains an empty view controller but is not the application entry point.                                           |
| `QrScan/Assets.xcassets`                                            | Supplies the app icon and an unspecified universal accent color, leaving controls to use the effective system tint. |

## 3. Application shell and presentation model

`QrScanApp` creates one `WindowGroup` containing `ContentView`. The root view is wrapped in a `NavigationView`, but it has no navigation title, navigation buttons, or pushed destinations. A page-styled `TabView` inside the navigation container provides two horizontally adjacent pages. The generator is selected at launch; swiping left opens the history page, and swiping right returns to the generator. A native page control with an always-visible background appears at the bottom.

The scanner is presented with SwiftUI's `.sheet` modifier. Its exact modal chrome and detent behavior are therefore determined by the current iOS device and presentation environment. Inside that modal, the scanner controller fills all available sheet content.

The app can also enter the scanner directly from the **Scan QR** Home Screen quick action. Both cold-start and already-running paths update the same `showScanner` state, so they lead to the same scanner presentation as the main **Scan** button.

## 4. Main screen hierarchy

Each page owns an independent vertical `ScrollView`. The generator page contains a `VStack` with 16-point spacing and standard outer padding. Both pages add an 8-point safe-area spacer at the top and 32 points of bottom padding so scrollable content does not collide with the page control. There is no explicit maximum content width, so page content expands with the window on iPad and in landscape.

The visible order is:

```text
NavigationView
└── TabView (horizontal page style with bottom page control)
    ├── Generator ScrollView
    │   └── VStack (16-point spacing, standard padding)
    │       ├── Text editor
    │       ├── Error-correction controls
    │       ├── QR preview or empty placeholder
    │       ├── Save / Scan / Copy action row
    │       └── Conditional status messages
    └── History ScrollView
        └── Scan history section
```

### 4.1 Text editor

The first element is an unlabeled `TextEditor` bound to the current QR payload.

- Height: 140 points in a regular vertical size class and 100 points in a compact vertical size class.
- Internal padding: 6 points.
- Border: 1-point gray stroke with an 8-point corner radius.
- Background: `systemBackground`, which adapts to light and dark appearance.
- Behavior: every text change immediately regenerates the QR image.

On first appearance, the app reads the system clipboard and preloads it when the clipboard contains a string of at most 100 characters. On recent iOS versions, this read can display the system paste-permission prompt before the main screen becomes interactive. Longer clipboard strings are ignored, but text entered or returned by the scanner is not limited to 100 characters.

The editor has no placeholder, caption, or explicit accessibility label. Its purpose is inferred from the QR controls and preview below it.

### 4.2 Error-correction controls

A leading-aligned `VStack` with 4-point spacing contains:

1. A subheadline label, **Error Correction:** or **纠错级别：**.
2. A segmented picker with four localized choices.

| Segment | Core Image value | Selection behavior                           |
| ------- | ---------------- | -------------------------------------------- |
| Low     | `L`              | Regenerates the QR image.                    |
| Medium  | `M`              | Default selection; regenerates the QR image. |
| High    | `H`              | Regenerates the QR image.                    |
| Max     | `Q`              | Regenerates the QR image.                    |

The picker has 16 points of trailing padding but no matching custom leading padding. The labels describe the implementation exactly; note that the displayed **High**/`H` and **Max**/`Q` order does not match the usual QR correction-capacity order, in which `H` is stronger than `Q`.

### 4.3 QR preview

The preview area is centered across the full available width. It reserves a 240-by-240-point square in a regular vertical size class and a 180-by-180-point square in a compact vertical size class.

Empty state:

- A rectangle filled with a low-opacity secondary color.
- Centered secondary-colored **QR Preview** text.
- No QR image is generated for an empty payload.

Generated state:

- The QR `UIImage` is resizable and aspect-fitted into the same adaptive square as the empty state.
- `.interpolation(.none)` keeps module edges sharp when the image is scaled.
- A faint secondary background and 8-point corner radius visually separate the image from the page.

The preview container adds 8 points of bottom padding before the action row. It switches to its compact size in iPhone landscape and other compact-height environments. iPad continues to use the regular size without an additional large-screen variant.

### 4.4 Primary action row

Three buttons appear in one centered `HStack` with 16-point spacing:

| Action | Symbol                  | Style              | Enabled state                              |
| ------ | ----------------------- | ------------------ | ------------------------------------------ |
| Save   | `square.and.arrow.down` | Bordered           | Enabled only when a QR image exists.       |
| Scan   | `qrcode.viewfinder`     | Bordered prominent | Always enabled.                            |
| Copy   | `doc.on.doc`            | Bordered           | Enabled only when the editor is non-empty. |

The prominent scan action creates the strongest visual emphasis and acts as the center button. Save and Copy use equal secondary styling on either side. The row does not wrap or switch to a vertical layout for compact widths or large text sizes.

Save and Copy explicitly dismiss the keyboard before finishing. Save writes the generated image to Photos; Copy writes the payload to the clipboard. Scan opens the scanner sheet.

### 4.5 Transient feedback

Status messages are inserted below the action row as separate conditional `Text` views:

- **Copied!** in green for 2 seconds after copying the editor.
- **Saved!** in green for 2 seconds after a successful save.
- A localized failure message in red for 2 seconds after a failed save.

Each message adds 8 points of top padding. The views specify opacity transitions, but no explicit animation is attached to the state changes. More than one message can technically be visible at the same time because each status has independent state. History-copy feedback is managed separately on the history page.

## 5. Scan history layout

The scan history occupies the second horizontal page instead of appearing below the generator. It has its own vertical scrolling position and remains present even when it contains no rows; there is no dedicated empty-state message. The page uses the same standard outer padding as the generator.

### 5.1 Header

The header is an `HStack` with 8 points of top padding:

- A leading headline, **History** or **历史记录**.
- Flexible space.
- A trailing destructive bordered button containing the trash symbol and localized **Clear** label.

Clear is always displayed, including when history is already empty. Activating it removes all stored entries and closes any exposed row action.

### 5.2 Rows

History is stored oldest-first but rendered newest-first. Up to 200 scanned payloads are retained. Only successful camera or photo scans are added; manually entered and generated values are not.

Each row is an `HStack` with 12-point spacing, 8-point internal padding, a `secondarySystemBackground` fill, and a 6-point corner radius.

- Payload text occupies the available leading width.
- Text is limited to two lines and truncates in the middle, preserving both the beginning and end of long values.
- Tapping a row toggles a bordered **Copy** button on its trailing edge.
- Only one row can expose its copy button at a time.
- The appearance change is wrapped in `withAnimation`.
- Copying closes the row action and displays the localized green copy-success message immediately below the history header for 1.5 seconds.

Rows form a simple vertical stack with 8-point gaps. There are no dates, payload-type icons, swipe actions, disclosure destinations, or deduplication.

## 6. Scanner interface

`ScannerView` embeds `ScannerViewController` through `UIViewControllerRepresentable`. The scanner has an edge-to-edge black base with an `AVCaptureVideoPreviewLayer` resized to the controller's full bounds using `.resizeAspectFill`. Camera content can therefore be cropped to fill the available area.

There is no custom scan frame, targeting reticle, instruction label, result overlay, or navigation bar. Three text buttons float above the preview:

| Control | Position and constraints                                                                                               | Visual treatment                                    |
| ------- | ---------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| Cancel  | 20 points below the top safe area and 20 points from the trailing edge; at least 64 points wide and 40 points high.    | White text, black at 60% opacity, 6-point corners.  |
| Torch   | 20 points above the bottom safe area and 20 points from the leading edge; at least 64 points wide and 40 points high.  | Same treatment; label changes when the torch is on. |
| Photos  | 20 points above the bottom safe area and 20 points from the trailing edge; at least 64 points wide and 40 points high. | Same treatment.                                     |

The preview extends behind safe areas, while the three controls are positioned relative to safe-area anchors. `viewDidLayoutSubviews` updates the preview layer frame after size changes.

### 6.1 Live camera flow

The capture session recognizes QR metadata only. The first QR result stops the session, dismisses the scanner, replaces the main editor text, regenerates the preview, and appends the payload to history. Cancel dismisses without changing the editor or history.

If no camera device or usable camera input exists, the scanner immediately completes with no result. This is the expected live-scanner behavior in a Simulator without camera support.

### 6.2 Photo flow

The **Photos** button stops the capture session and presents a full-screen system `UIImagePickerController`. After a photo is selected, Vision searches it for QR codes.

- A successful result follows the same dismissal and history flow as a live scan.
- If no QR code is found, the camera resumes and a localized system alert offers one **OK** action.
- Canceling the picker returns to the scanner and restarts the camera.

Camera, photo-library read, and photo-library add permissions use system prompts with localized English and Simplified Chinese descriptions from `InfoPlist.strings`.

## 7. Visual language

The interface is intentionally native and restrained:

- Typography uses system body, subheadline, and headline styles rather than custom fonts.
- The effective tint is the system accent because the asset catalog does not define a concrete accent color value.
- Primary emphasis comes from `.borderedProminent` on Scan.
- Destructive emphasis comes from the red Clear role.
- Success and failure feedback use semantic green and red.
- Secondary surfaces use semantic system colors, allowing automatic light/dark adaptation.
- SF Symbols pair recognizable icons with text labels instead of replacing labels.
- Repeated small corner radii—6 or 8 points—soften editors, preview surfaces, scanner controls, and history rows.

The generated QR image itself remains black and white in either appearance, preserving scan contrast.

The app icon is based on `QrScan/icon/QrScanIcon.svg`. It uses an opaque warm-white canvas, a near-black simplified QR tile, four scanner-corner marks, and a horizontal scan beam. A short neutral-gray card offset and beam shadow add restrained depth while keeping black and white as the dominant colors. The QR pattern is symbolic rather than scannable. The scanner motif is also reflected in the scan button and quick-action SF Symbol.

## 8. Localization

All application-owned visible strings are available in English and Simplified Chinese. The language is resolved once at startup from the device region:

- Region `CN` selects Simplified Chinese.
- Any other or missing region selects English.

This is region-based rather than preferred-language-based selection. The chosen locale is injected into SwiftUI, while UIKit strings are loaded explicitly through `L10n`. The scanner controls, alerts, action labels, correction-level segments, history labels, status messages, permission descriptions, and Home Screen quick action are localized.

The current two languages use short labels that fit the three-button action row. No right-to-left-specific layout logic exists, although standard SwiftUI leading/trailing alignment would provide some automatic mirroring if another localization were added.

## 9. Adaptivity and accessibility characteristics

### 9.1 Device and orientation support

The target supports iPhone and iPad. iPhone declares portrait and both landscape orientations; iPad also declares portrait upside down. The two pages each use a vertical `ScrollView`, which protects their content from short vertical space, while the enclosing `TabView` reserves horizontal gestures for page changes.

The implementation uses the vertical size class only to adapt the editor and QR preview. It has no maximum readable width, `ViewThatFits`, adaptive grid, or alternate iPad composition. As a result:

- The editor, segmented picker, and history rows stretch across large windows.
- The generator and history keep independent vertical scroll positions while moving between pages.
- The native page control stays at the bottom of the paged container, with content padding preventing overlap.
- The editor and QR preview use 140/240 points in regular height and 100/180 points in compact height.
- The primary actions remain one horizontal row.
- The scanner buttons remain pinned to three safe-area corners.
- Multitasking, compact landscape widths, long future translations, or large Dynamic Type sizes can compress the action row and segmented control.

### 9.2 Dynamic appearance and type

Semantic backgrounds and standard controls adapt to light and dark appearance. System text styles participate in Dynamic Type, while the editor and preview respond to vertical size class rather than text size. Scanner buttons remain 40 points high. There is no explicit minimum scale factor or multiline policy for button labels.

### 9.3 Accessibility surface

The use of `Label` gives the three main actions both text and symbol content, and native buttons/pickers retain standard accessibility behavior. Stable identifiers cover the pager, generator editor, QR preview, history title, and clear action for UI testing. The blank editor still has no visible or explicit accessibility label, and history-row expansion is attached to a general tap gesture without an explanatory affordance. These are current implementation characteristics rather than separate accessibility designs.

## 10. Launch and external system UI

The launch screen is intentionally blank and uses only `systemBackground`. It has no logo, progress indicator, or branded transition. `Main.storyboard` is not used to start the app because `UIMainStoryboardFile` is empty and the SwiftUI `@main` entry point creates the window.

Several visible experiences are owned by iOS and may change across OS versions:

- Clipboard paste permission.
- Camera and Photos permission prompts.
- SwiftUI sheet appearance.
- Photo picker presentation.
- Save-to-Photos authorization behavior.
- Home Screen quick-action menu.
- Native button, picker, alert, and navigation styling.

## 11. Current design summary

QrScan's UI prioritizes direct access and low navigation overhead. Its central design is a two-page utility surface with immediate QR regeneration on the default page and scan history one horizontal swipe away. Native page indicators, controls, colors, and typography provide platform consistency and localization with little custom visual code. The tradeoff is that large-screen composition, Dynamic Type behavior, editor discoverability, history affordances, and scanner guidance remain minimal and are not specialized beyond the default adaptive behavior of SwiftUI and UIKit.
