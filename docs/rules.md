# Swift Coding Rules

## 1. Purpose and scope

This document defines the Swift coding rules for QrScan. It applies to application code in `QrScan/`, unit tests in `QrScanTests/`, and UI tests in `QrScanUITests/`.

The goals are to keep the code safe, readable, testable, and consistent with the current architecture: SwiftUI owns the main application UI and view state, while UIKit, AVFoundation, Vision, and photo-picker integration remain in the scanner layer.

The terms **MUST**, **SHOULD**, and **MAY** are normative:

- **MUST** means a requirement that can be waived only with an explicit explanation in the code review.
- **SHOULD** means the default choice; deviations need a concrete technical reason.
- **MAY** means an acceptable option chosen according to the local context.

New and modified code MUST follow these rules. Unrelated legacy code does not need to be reformatted or refactored as part of a focused change.

## 2. Language and platform baseline

- Code MUST compile with the Swift language version and deployment target configured in `QrScan.xcodeproj`. At the time of writing, these are Swift 5 language mode and iOS 26.1.
- Code MUST use Apple SDK APIs available at the configured deployment target. Do not add unnecessary availability branches for older OS versions that the project cannot run on.
- The project currently has no third-party runtime dependencies. Adding one MUST be justified by a clear maintenance or capability benefit and reviewed before it is committed.
- Application code, identifiers, comments, documentation, test names, and commit-facing technical text MUST be written in English. User-facing text MAY be localized into supported languages through the localization files.
- Compiler warnings MUST be treated as defects. New code MUST not introduce warnings in the app or test targets.

## 3. Source-file organization

### 3.1 Project boundaries

Keep responsibilities in the established locations:

| Area                                                | Responsibility                                                                                                  |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `QrScanApp.swift`                                   | Application entry point, root dependencies, locale injection, and app-wide presentation triggers.               |
| `ContentView.swift`                                 | Main SwiftUI QR generation workflow and screen-level state.                                                     |
| `ScanHistorySection.swift`                          | Scan-history storage helpers and history UI.                                                                    |
| `ScannerView.swift`                                 | SwiftUI-to-UIKit bridge, camera capture, photo selection, Vision detection, torch control, and scan completion. |
| `AppLanguage.swift`                                 | Language resolution and localized-string lookup.                                                                |
| `AppDelegate.swift` / `ShortcutSceneDelegate.swift` | Application and scene lifecycle integration, including Home Screen quick actions.                               |

- UI state MUST remain in SwiftUI views unless it represents scanner-controller lifecycle or UIKit state.
- Camera, photo picker, torch, and barcode-recognition pipeline code MUST remain in `ScannerView.swift` or in focused scanner-specific types extracted from it.
- Pure QR generation, storage, parsing, and localization logic SHOULD be separated from views when it becomes large enough to test independently.
- A change MUST NOT introduce a second implementation of an existing responsibility. Reuse or extend the current storage, localization, and scanner paths.

### 3.2 File layout

Use this order when applicable:

1. Imports.
2. Primary type.
3. Closely related private helper types.
4. Extensions.
5. SwiftUI previews.

- Prefer one primary top-level type per file. Small private helpers that exist only for that type MAY share the file.
- Extensions SHOULD group protocol conformances or a coherent capability, not serve only to bypass a large type.
- Generated Xcode header comments are optional. Do not add author or creation-date headers to new files.
- Source files MUST end with exactly one newline and MUST NOT contain trailing whitespace.

### 3.3 Imports

- Use one module per `import` line.
- Import only modules referenced by the file.
- Sort normal imports alphabetically. Put `@testable import QrScan` after system/test-framework imports, separated by one blank line.
- Do not add blank lines between related Apple framework imports.

Example:

```swift
import AVFoundation
import SwiftUI
import UIKit
import Vision
```

## 4. Formatting

- Use 4 spaces for indentation. Tabs MUST NOT be used for indentation.
- Opening braces stay on the declaration or control-flow line.
- Do not use semicolons.
- Aim for a maximum line length of 120 characters. A longer line MAY be used when splitting it would make an Apple API signature or string less readable.
- Break long function declarations, calls, collection literals, and conditions across multiple lines with one argument or condition per line.
- Multiline collection literals and argument lists SHOULD include a trailing comma to produce stable diffs.
- Put one blank line between logical sections of a type. Do not use multiple consecutive blank lines.
- Use Xcode's standard spacing around operators, after commas, and after colons.
- Prefer trailing-closure syntax when the closure is the final argument and the result stays clear. Use labeled closure arguments when a call has multiple closures or the label explains intent.
- Keep SwiftUI modifier chains one modifier per line. Order modifiers by purpose where practical: content/configuration, layout, appearance, interaction, accessibility, then lifecycle.

## 5. Naming

Follow the Swift API Design Guidelines in addition to the following project rules:

- Types and protocols use `UpperCamelCase`.
- Functions, methods, properties, local variables, enum cases, and argument labels use `lowerCamelCase`.
- Acronyms are treated as words in Swift identifiers: use `QrScanApp`, `qrCode`, and `generateQRCode`, following the existing public names in the project. Do not create new variants such as `QRcode` or `qRCode`.
- Boolean names SHOULD read as assertions or describe UI state, for example `isSessionRunning`, `hasCameraAccess`, or `isScannerPresented`.
- Function names MUST describe the observable action or returned value. Avoid vague names such as `process`, `handleData`, or `doWork` without a domain qualifier.
- Collection names SHOULD be plural. A single value MUST use a singular name.
- Avoid abbreviations except established platform or domain terms such as `QR`, `URL`, `ID`, `UI`, and `CGImage`.
- Name closure parameters by outcome, such as `completion`, `onCopy`, or `onScan`, and document whether they may run more than once when that is not obvious.
- Localization keys MUST use dot-separated, lower-case domain names such as `scanner.no_qr.title`. Keep action keys reusable only when their wording and context are truly identical.

## 6. Declarations and access control

- Declare the narrowest access level that works. Implementation details SHOULD be `private` or `fileprivate`.
- Types not designed for subclassing SHOULD be `final`. UIKit delegates and controllers SHOULD be `final` unless subclassing is required.
- Prefer `let` over `var`. A value MUST be mutable only when its lifecycle requires mutation.
- Put property wrappers directly on the property declaration. SwiftUI-owned state MUST be `private` unless another type genuinely needs direct access.
- Group stored properties by role: immutable dependencies, bindings/environment, owned state, derived properties, then methods.
- Avoid global mutable state. Existing app-wide coordination such as `ShortcutActionState.shared` MUST have a narrow API and a single documented responsibility.
- Constants shared by a domain SHOULD live in an enum namespace or a focused type, as `ScanHistoryStorage` and `ShortcutAction` do.
- Magic strings and numbers that encode behavior MUST be named. Examples include history limits, storage keys, QR correction levels, notification names, and timing durations.

## 7. Type design and Swift language usage

- Prefer value types (`struct` and `enum`) for models, configuration, and stateless behavior.
- Use classes only when identity, shared mutable state, Objective-C interoperability, or UIKit inheritance requires them.
- Model a closed set of values with an enum instead of raw strings. New QR correction-level logic SHOULD use a typed enum that owns its Core Image value and localization key.
- Prefer computed properties for cheap deterministic derivations. Do not use a computed property for expensive image processing or I/O.
- Use type inference when the type is obvious from the right-hand side. Add an explicit type when it clarifies an API boundary or prevents an unintended overload.
- Avoid `Any`, unchecked casts, and stringly typed APIs in application-owned code. When Apple APIs return untyped dictionaries or Objective-C values, validate and convert them at the boundary.
- Do not use force unwraps or force casts in new code. An implicitly unwrapped optional MAY be used only where a framework lifecycle guarantees initialization before use; prefer regular optionals or initialized stored properties when possible.
- Use `guard` for required preconditions and early exits. Use `if` when both branches represent normal behavior.
- Avoid deeply nested control flow. Extract a focused method when nesting exceeds roughly three levels or mixes unrelated responsibilities.
- Do not add protocol abstractions for a single implementation unless they enable testing, isolate a platform boundary, or express a real domain contract.

## 8. Optionals and errors

- `nil` MUST have one clear meaning. Do not overload it to represent several failure states when callers need to distinguish them.
- Use `Result`, `throws`, or a domain error type when a caller needs failure details. A simple optional is acceptable for expected absence, such as an empty QR input producing no image.
- Do not silently discard errors from user-initiated operations. Camera setup, image saving, photo decoding, and Vision failures SHOULD produce a recoverable state or localized feedback where the user can act on the result.
- `try?` MAY be used only when failure is expected and a documented fallback is correct, such as treating corrupt persisted history as empty. Otherwise, use `do`/`catch` or propagate the error.
- Catch the narrowest useful error and preserve its context for diagnostics. Do not expose internal error descriptions directly as user-facing copy.
- Completion handlers MUST be invoked exactly once unless their API explicitly documents repeated events.
- Cleanup MUST happen on every exit path. Use `defer` for paired operations such as device configuration locks when it makes this guarantee clearer.

## 9. Closures and memory management

- Escaping closures MUST be reviewed for retain cycles.
- Use `[weak self]` when an owner retains a closure or asynchronous operation that also captures the owner. Safely unwrap `self` before accessing state.
- Do not use `[unowned self]` unless the lifetime relationship is guaranteed and documented.
- A stored completion closure SHOULD be cleared after a one-shot operation completes.
- Capture immutable local values instead of an entire object when only one value is needed.
- Closure bodies longer than a small, single-purpose action SHOULD be extracted into named methods.

## 10. Concurrency and thread safety

- UIKit and SwiftUI state changes MUST occur on the main actor/main queue.
- UI-owning types and methods SHOULD use `@MainActor` when doing so makes the isolation contract explicit and compiles cleanly in the configured Swift mode.
- Camera session configuration and `startRunning()`/`stopRunning()` SHOULD execute on one dedicated serial session queue because these operations can block and must not race.
- Vision and image-processing work SHOULD run off the main thread. Results MUST return to the main actor before presenting, dismissing, or mutating UI.
- Use a named, owned queue rather than `DispatchQueue.global()` for long-lived subsystem work so ordering and quality of service are explicit.
- Delayed UI feedback work MUST not leave stale state after the view disappears or a newer action supersedes it. Prefer cancellable `Task` values for new asynchronous UI flows when practical.
- Do not introduce detached tasks unless work is intentionally independent of the caller's lifetime.
- Shared mutable state MUST be isolated by the main actor, an actor, or a serial queue. Do not rely on timing assumptions.
- New concurrency code SHOULD be ready for stricter Swift concurrency checking: avoid transferring non-`Sendable` mutable objects across isolation boundaries.

## 11. SwiftUI rules

### 11.1 State ownership

- Use `@State` only for transient state owned by the view, and make it `private`.
- Use `@Binding` when a child edits state owned by its parent. A binding MUST represent a real two-way relationship, not a shortcut for passing events.
- Use immutable `let` properties for dependencies and callbacks supplied by a parent.
- Use `@AppStorage` only for small `UserDefaults`-backed preferences or bounded data already represented there. Keep encoding and validation outside `body`.
- Derived view data SHOULD be a read-only computed property.
- Do not copy a binding or dependency into `@State` unless the view intentionally owns a separate editable snapshot.

### 11.2 View composition

- `body` MUST remain declarative and free of blocking work, storage writes, camera setup, or heavy image processing.
- Extract a subview when a section has independent state, is reused, or makes the parent view difficult to scan. Do not extract trivial wrappers that hide layout without improving clarity.
- Button actions SHOULD call named methods when they perform more than a few state changes or invoke multiple services.
- Use semantic system colors, standard text styles, SF Symbols, and native controls unless `docs/ui.md` defines a custom treatment.
- New layout MUST work in light and dark appearances, compact widths, iPad widths, landscape, and larger Dynamic Type sizes.
- Avoid fixed dimensions for text-bearing controls. When a fixed size is necessary for QR fidelity or camera layout, document the reason in `docs/ui.md`.
- `ForEach` MUST use a stable domain identifier when rows can be inserted, deleted, or reordered. Array indices are acceptable only for immutable, position-identified content.
- Side effects in `onAppear` and `onChange` MUST be idempotent or explicitly guarded against repeated invocation.
- Every meaningful SwiftUI screen or reusable component SHOULD have a preview covering at least its normal state; significant empty, error, and localized states SHOULD be added when practical.

### 11.3 Accessibility

- Interactive elements MUST have a clear accessible label. An SF Symbol alone is not sufficient unless an explicit label is provided.
- Text editors, QR previews, expandable history rows, and custom scanner controls MUST expose labels or hints that explain their purpose.
- Important UI elements used by UI tests SHOULD have stable accessibility identifiers. Identifiers are developer-facing constants and MUST NOT be localized.
- Do not communicate success or failure by color alone. Provide text and, when appropriate, an accessibility announcement.
- Tap targets SHOULD be at least 44 by 44 points.

## 12. UIKit, camera, and Vision rules

- `UIViewControllerRepresentable` MUST keep the bridge thin. Controller construction belongs in `makeUIViewController`; repeated SwiftUI-driven updates belong in `updateUIViewController`.
- UIKit view creation SHOULD be split into focused setup methods when `viewDidLoad` becomes difficult to scan.
- Programmatic UIKit layout MUST set `translatesAutoresizingMaskIntoConstraints = false` and activate complete, non-ambiguous constraints.
- UI controls MUST be positioned relative to safe-area anchors unless intentionally edge-to-edge, as with the camera preview.
- Capture inputs and outputs MUST be checked with `canAddInput` and `canAddOutput`. A failed check MUST not be followed by configuration that assumes the object was added.
- Capture-session start, stop, pause, and resume operations MUST be idempotent and coordinated through one lifecycle path.
- The scanner MUST stop capture when it completes or is no longer visible. Torch state SHOULD be reset before the owning controller is released.
- Scanner completion MUST be protected from duplicate metadata callbacks, repeated cancellation, and picker callbacks arriving after completion.
- Metadata and Vision results MUST validate the barcode symbology and non-empty payload before treating a scan as successful.
- Photo-picker cancellation and a no-result scan SHOULD return the scanner to a usable state rather than leave the camera stopped.
- Objective-C selectors MUST expose only the methods required by UIKit callbacks.
- Permission handling and failure UI MUST stay aligned with the actual camera, photo-read, and photo-write behavior.

## 13. QR generation and image handling

- Convert input text to UTF-8 explicitly before passing it to Core Image.
- Empty input MUST produce no QR image and MUST disable actions that require an image.
- QR error-correction values MUST be limited to values supported by `CIQRCodeGenerator` (`L`, `M`, `Q`, and `H`). Do not accept unchecked arbitrary strings at application-owned boundaries.
- QR images MUST preserve sharp module edges. Use nearest-neighbor/no interpolation when presenting or resizing generated codes.
- Keep the rendered QR code high contrast and avoid decorative overlays that can reduce scan reliability.
- Core Image contexts SHOULD be reused when generation becomes frequent enough for allocation cost to matter; do not construct unnecessary rendering resources inside tight loops.
- Image conversion and Vision detection MUST account for invalid or unavailable `CGImage` data without crashing.
- Saving an image MUST report success or a localized failure and MUST respect photo-library permission behavior.

## 14. Localization

- User-visible application text MUST NOT be hard-coded in Swift. Add keys to both `QrScan/en.lproj/Localizable.strings` and `QrScan/zh-Hans.lproj/Localizable.strings` in the same change.
- UIKit-owned application text MUST be loaded through `L10n.tr(_:language:)` so it follows the app's resolved language.
- Permission descriptions and static shortcut strings MUST be kept in both `InfoPlist.strings` files and aligned with `Info.plist`.
- Localization keys MUST be grouped by feature and kept in the same order across languages.
- Do not build user-facing sentences by concatenating localized fragments. Use a format string with documented placeholders.
- Format dates, numbers, and lists with locale-aware formatters rather than manual string construction.
- New copy MUST be checked in English and Simplified Chinese for truncation, button fit, and meaning.
- Changes to language-resolution behavior MUST include unit tests and an update to `docs/ui.md` and `docs/build.md` where their descriptions are affected.

## 15. Persistence, privacy, and security

- `UserDefaults` is suitable only for small, local, non-relational values. Scan history MUST remain bounded and decoding MUST tolerate missing or corrupt data.
- A persistent schema or key change MUST define migration or backward-compatible fallback behavior. Do not silently strand existing user data.
- QR payloads may contain sensitive information. Do not print, log, attach to tests, or include real payloads in screenshots.
- If diagnostics are added, use Apple's `Logger` APIs and mark payload-like values private. Do not use `print` for production diagnostics.
- Clipboard reads and writes SHOULD be tied to an explicit user action. Any automatic clipboard access is product behavior and MUST be documented in `docs/ui.md` with its privacy implications.
- Store no camera frames or selected photos unless a feature explicitly requires it and the retention behavior has been reviewed and documented.
- Permission usage descriptions MUST explain the actual user benefit in plain language.
- Changes to permissions, bundle identifiers, quick-action types, or external data handling MUST be called out in review notes.

## 16. Tests

### 16.1 Unit tests

- Use Apple's `Testing` framework for new unit tests in `QrScanTests` unless an API requires XCTest.
- Test names MUST state behavior and conditions, for example `appendTrimsHistoryToMaximumCount` or `resolveNilRegionAsEnglish`.
- Do not declare a test `async` or `throws` unless it actually awaits or throws.
- Each test MUST be deterministic, isolated, and independent of execution order.
- Storage tests MUST use an isolated `UserDefaults` suite and remove it after the test. They MUST NOT modify `.standard`.
- Prefer testing pure inputs and outputs over internal implementation details.
- Bug fixes MUST add a regression test when the affected behavior can be exercised without physical hardware.
- New domain logic SHOULD cover normal, empty, boundary, malformed, and failure cases as applicable.

At minimum, changes in these areas SHOULD cover:

- App language resolution and localization fallback.
- Scan-history encoding, corrupt input, maximum count, and ordering.
- QR correction-level validation and empty input.
- One-shot completion and duplicate-result prevention in extracted scanner logic.

### 16.2 UI tests and hardware checks

- Use XCTest for `QrScanUITests`.
- UI tests MUST set required launch state explicitly and MUST NOT depend on the developer's clipboard, photo library, locale, or existing history.
- Add stable accessibility identifiers before selecting custom application UI in a test.
- UI tests SHOULD cover generation, copy/save enablement, history clearing, scanner presentation/cancellation, and both supported localizations when those flows change.
- Live camera scanning and torch behavior MUST be manually verified on a physical device when their code changes.
- Photo-library scanning MAY be verified on a Simulator with deterministic fixture images, provided fixtures contain no sensitive payloads.

## 17. Comments and documentation

- Prefer code that explains itself through types and names. Comments SHOULD explain why a decision exists, an API constraint, a non-obvious invariant, or a safety requirement.
- Comments MUST be written in English and kept current with the code.
- Public or non-obvious reusable APIs SHOULD use Swift documentation comments (`///`) describing behavior, important parameters, return values, errors, threading, and callback guarantees.
- Do not narrate obvious statements such as assignment or simple control flow.
- `TODO` and `FIXME` comments MUST include a concrete reason and a tracking reference when one exists. Do not leave open-ended placeholders.
- A UI or interaction change MUST update `docs/ui.md` in the same change.
- A build, run, test, dependency, deployment-target, or tooling change MUST update `docs/build.md` in the same change.
- A change to these coding rules MUST update this document and explain any migration impact in review notes.

## 18. Prohibited patterns

New code MUST NOT introduce:

- Force unwraps or force casts without a framework-guaranteed, documented invariant.
- Empty `catch` blocks or ignored failures from user-initiated operations.
- Blocking camera, Vision, file, or image-processing work on the main thread.
- Unbounded scan-history or image retention.
- Hard-coded user-visible strings in Swift.
- Sensitive QR payloads in logs, fixtures, screenshots, or assertions.
- Broad mutable singletons used as general application state.
- Duplicate localization, persistence, camera, or QR-generation implementations.
- New third-party dependencies without prior justification and review.
- Drive-by reformatting or unrelated refactors in a focused feature or bug-fix change.

## 19. Definition of done

Before a Swift change is considered complete, its author MUST verify the applicable items:

- The app builds without new warnings using the reproducible Simulator build command in `docs/build.md`.
- Relevant unit and UI tests pass, or any environment limitation is recorded.
- New logic has proportionate automated test coverage.
- UI behavior has been checked in both supported languages and relevant appearances/sizes.
- Camera or torch changes have been checked on physical hardware.
- All user-visible strings and permission descriptions are localized.
- Accessibility labels, identifiers, tap targets, and Dynamic Type behavior have been considered.
- No sensitive QR content is present in logs, screenshots, tests, or commits.
- `docs/ui.md`, `docs/build.md`, and this document have been updated when their documented behavior changed.
- The diff contains only changes required for the stated purpose.
