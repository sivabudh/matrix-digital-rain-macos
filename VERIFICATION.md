# Refactor verification — 4 November 2026

Release: **1.1 (build 2)**. Contract: **frozen requirements v1**. Environment: Apple Silicon, macOS 27.2 (26B123), Apple Swift 6.4.2 Command Line Tools. All checks below were performed by Codex; this is not an independent review or new user acceptance.

## Executed automated checks

| Check | Result | Evidence and scope |
| --- | --- | --- |
| Domain verification | PASS | `zsh test.sh`: all **7 Swift Testing tests** completed with a passing summary. Includes every reachable interaction state, Lock/Unlock workflow, hide/show, sleep/wake decisions, invalid placement, display recovery, uniform scaling, deterministic simulation and glyph validity. |
| Native adapter verification | PASS | Same script: **4 synchronous native scenarios** completed and the executable returned 0. Exercises native button actions, first-click configuration, actual window properties, matching bottom-right screen rectangles, drag/resize configuration, menu labels, absent keyboard equivalents, zoom/full-screen guards, preference compatibility, malformed stored data and placement persistence. These are native API/action checks, not synthetic claims of human click delivery. |
| Optimized release build | PASS | `zsh build.sh` selected only product `MatrixRain`; Swift compiler warnings treated as errors. Swift Build's linker reports nonexistent optional Command Line Tools search directories on this machine; linking succeeds. No compiler-source warning was accepted. |
| Bundle signature | PASS | `codesign --verify --strict` on the installed app. Local ad-hoc signing only; no notarization or distribution approval. |
| Release runtime dependencies | PASS | `otool -L` shows system frameworks and Swift runtime libraries. No Testing framework, third-party library or development test runner is linked into the installed executable. |
| Saved placement during update | PASS | Before/after diagnostic snapshots show the exact same rain rectangle (personal screen coordinates omitted from the repository). Replacement starts locked, visible, click-through and animation-active. Existing preferences identity/key retained. |
| Single instance | PASS | Launching the installed executable again while it is running returns without creating a second matching app process. |
| Boundary/source inspection | PASS | No AppKit, preference, clock, system-randomness, timer, file or mouse-position reads in RainCore. No keyboard actions, nonempty key equivalents, pause/fill commands or global click interception in production sources. |

## Live Mac observations

| Observation | Result |
| --- | --- |
| Running release renders smaller green rain in a rounded borderless region with no title bar or window buttons | OBSERVED through the native app screenshot |
| Opening the already-running app enters unlocked mode | OBSERVED in native accessibility state and live window |
| Right-clicking unlocked rain reveals a button labelled **Lock** | OBSERVED using actual computer input and accessibility state |
| Clicking that Lock button returns the window to desktop mode | OBSERVED using actual computer input; accessibility state returns to a desktop window and diagnostics report locked/click-through |
| Saved rectangle survives those mode changes | OBSERVED unchanged in running-app diagnostic snapshot |

The physical hover-to-Unlock interaction was not separately automated in this refactor. Its state transitions, panel level, geometry and native button action were verified. Neither those checks nor earlier user use prove all desktop/input configurations. A real disconnect/reconnect of monitors, movement across every Space or Stage Manager layout, physical display sleep, measured frame rate, battery use and long-term reliability were **NOT RUN**. No production or security certification is claimed.

## Defects and verification tooling resolved

- The new same-position native check exposed NSButton alignment-rectangle insets: Auto Layout's alignment box did not equal the button's actual frame. Both buttons now derive from one screen rectangle, converted explicitly for the flipped rain view. The native check passes for actual frame equality.
- The selected Command Line Tools install Testing macros in `host/plugins/testing`; `test.sh` discovers that directory from the selected compiler instead of hardcoding this Mac's path.
- Generic Swift Testing/AppKit-host runs ended without complete native summaries. Those incomplete runs were not accepted. Native verification was moved to a synchronous development executable that stops with exit 1 on a failed expectation and prints completion only after all scenarios finish. It is outside the installed application.
- AppDelegate lifetime is held explicitly across `NSApplication.run()`, keeping the composed controller and its resources alive in optimized builds.

## Retained evidence and rollback

Local development evidence is under `work/`: final `tests.log`, `build.log`, `pre-install-status.json` and `post-install-status.json`. Earlier failed/incomplete test logs are superseded by the completed run described above. The pre-refactor source and app bundle are under `work/pre-refactor/` for rollback. Neither logs nor tests are part of the installed app.

The source archive accompanying this refactor contains the frozen requirements, architecture, source, developer tests, scripts and SHA-256 manifest. Generated build caches and historical scratch files are excluded.

## Speed selection — 7 November 2026

`zsh test.sh` passed all 7 core tests and native adapter checks, including invoking every Speed submenu action, checking the selected item and live render speed, preference round trips, and invalid-preference fallback. These automated menu actions do not establish manual desktop interaction.
