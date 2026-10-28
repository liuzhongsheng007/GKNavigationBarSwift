# Dynamic window layout patch

Base: master a411b9b. Scope: custom navigation bar sizing, owning-window safe top inset,
uncached compatibility dimensions, safe-area and scene lookup. Existing singleton and
physical device identity caches remain. No CI redesign or deployment-target increase.

## Behavior and compatibility

- Internal bar layout uses the controller view width, the owning window safe area in
  view coordinates, and UIKit sizeThatFits on every layout. It no longer chooses
  current bar height from model lists or global orientation. Fullscreen and sheet layouts use the same fitting height; safe top padding is
  converted into the controller coordinate space and clamped at zero. No 56pt override remains.
- width/height remain normalized short/long edges, now from the unique active key
  window. They return zero before a window exists or when multiple scenes are ambiguous.
  Use layoutSize(in:) for actual ordered dimensions and safeAreaInsets(in:) for a view.
- Safe-area APIs no longer create temporary windows or replace zero with model data.
  iOS 13+ statusBarFrame preserves zero; legacy iOS uses UIApplication status bar.
- Model/physical-size compatibility classifiers remain public but are not used by
  navigation height APIs. All old navigation height methods now delegate to current
  UIKit fitting; portrait-specific aliases are deprecated. New controller overloads
  avoid global scene selection. Without a measurable existing bar they return zero
  and do not create views. tabBarHeight reads the current UIKit bar bounds; no model
  table or 49/65pt formula remains. The safe-area model table has been removed. Public let-to-var changes keep
  read syntax but binary clients should rebuild. UIKit helpers require the main thread.

## Executed here (Linux)

- git diff --check: passed.
- swift test: could not run, swift executable absent (exit 127).
- xcrun agent skills export: could not run, xcrun absent (exit 127).
- Xcode compilation, XCTest, simulator, and physical folding: NOT VERIFIED.

## Run on a Mac

1. Select Xcode 27.1 with xcode-select. Run xcrun agent skills export and read the
   exported App Resizability Skill; review its findings against this patch. A clean
   report is not a test result.
2. Open Package.swift in Xcode; select the GKNavigationBarSwift package scheme and
   an iOS simulator. Run Test (Cmd-U). For CLI first run xcodebuild -list, then
   xcodebuild -scheme GKNavigationBarSwift -showdestinations and use an available
   destination ID with xcodebuild -scheme GKNavigationBarSwift -destination
   'id=<SIMULATOR_ID>' test. Do not run plain macOS swift test for this UIKit package.
3. Run the Demo against this checkout. In Device Hub exercise iPhone Duo closed,
   open, rotated, and split-screen, repeatedly without relaunching. Also test a
   non-notched older iPhone simulator and iPad, status bar hidden/shown, sheet
   presentation/dismissal, navigation push/pop, and two active scenes.
4. Accept only if navigation title/buttons remain visible and tappable, no stale
   width or accumulated top inset appears, the bar follows its own window, zero
   insets are preserved, and no new Auto Layout warnings occur. Compare old-device
   bar height and spacing against master; UIKit fitting replaces model corrections.
5. Repeat fold/unfold during a navigation gesture on a physical Duo.

## Remaining release blockers / risks

- P0: build and run XCTest on Xcode 27.1; tests were authored but not executed here.
- P0: iOS 27.1 vertical bars and side status area require simulator/device acceptance.
  This patch retains a custom horizontal UINavigationBar and private UIKit subview
  positioning; it does not implement a vertical navigation system. Side-only insets
  are not converted to fake top padding, but button avoidance still needs visual QA.
- P1: confirm UIKit sizeThatFits and existing private subview overrides agree on every
  supported OS, including iPad and dynamic status bar changes.
- P1: legacy context-free APIs cannot identify an intended scene when several are active;
  returning nil/zero intentionally replaces arbitrary cross-scene selection.
- P2: remaining legacy device classification, item spacing heuristics, and external clients of
  old height helpers need a separate migration if acceptance exposes issues.

Reference: https://developer.apple.com/iphone-duo/prepare/ (read 2026-10-28).

## Follow-up regression coverage

Six XCTest methods now cover repeated window dimensions, owning-window changes,
zero/side insets, current fitting widths, identical sheet/fullscreen fitting, public
controller overloads, and absence of unintended bar creation. The sheet test uses
width-dependent stub fitting to detect any reintroduced 56pt or model-height branch;
it does not prove real UIKit fitting is correct. XCTest remains NOT RUN here.

Compatibility changes requiring consumer review: portrait aliases now report current
layout, not predicted portrait geometry; no-context height APIs return zero if the
existing bar/window cannot be identified; tabBarHeight returns the actual laid-out
vertical extent (not a promise that a future vertical bar is horizontal).
