# Personal source-sharing review — 4 November 2026

**Assessment: the reviewed snapshot is suitable for publication as a personal MIT-licensed source project.** No credential exposure, covert collection, remote execution or other publication-blocking security issue was identified in this review. This is a scoped author review, not a claim that software can be proved free of every defect.

Repository visibility remains private during preparation. A future public repository should receive only the reviewed current files in a new initial commit; no development history, logs, preferences, build caches, application bundles or scratch files need to be copied.

## Scope

Reviewed all application source files, the Swift package manifest, developer tests, build/test scripts and repository documentation. The source inventory consists of native Swift code, documentation and scripts. The bundle identifier `local.pac.matrix-rain` is retained for preference compatibility; it is not a credential. The MIT copyright holder is the repository owner, identified by GitHub username `sivabudh`.

## Findings

| Area | Finding |
| --- | --- |
| Secrets and personal data | Gitleaks 8.30.1 found no leaks in the initial Git history. A separate Gitleaks scan of the staged source-only export also completed with no leaks found. Personal absolute home paths, personal screen coordinates and unrelated internal-project discussion were removed before the original private push. Commit attribution uses a GitHub noreply address. |
| Runtime communication | No networking client, telemetry, updater, downloaded code, subprocess execution or remote input path is present in the application. The Swift package has no external dependencies or build plugins. Build scripts use the local Swift tools and ad-hoc signing; they do not fetch executable scripts. |
| Input and permissions | Hover detection samples current mouse position locally at 10 Hz; it does not store mouse history. No keystroke monitoring, global click interception, clipboard access, screen capture, Accessibility request or Screen Recording request is present. Native drag and right-click handling belong to the app's own unlocked view. |
| Local storage | Window geometry uses macOS preferences; a current diagnostic snapshot includes geometry, process ID and UI state under the user's Application Support directory. No secrets are stored by this app. It is an ordinary unsandboxed app, with normal user filesystem permissions; protection against a hostile process already running as the same OS user is not claimed. |
| Boundaries and behavior | Persisted rectangles are validated and recovered against current screens. Interaction state is represented by explicit alternatives and tested transitions. Native UI runs on the main actor. Animation randomness is not used for security. |
| Developer tests | Test preferences and diagnostic output use generated temporary names. Cleanup is limited to those test-owned paths. Test code is outside the installed app. |
| Assets and reuse | The rain uses installed system fonts. No movie clips, artwork, logos or font files are included. Book material is linked as a design reference, not copied into the implementation. The source carries the MIT license. |

## Executed evidence

- Fresh `zsh test.sh`: **PASS — 7 domain tests and 4 native adapter scenarios**, with explicit native-check completion and exit 0.
- Optimized release build and ad-hoc signature verification: passed during refactor, and checked again during source-sharing preparation.
- Gitleaks history and source-only snapshot scans: **PASS — no leaks found**; results retained locally under ignored `work/` paths. Scanner findings are redacted.
- Prior live Mac verification observed rendering, reopen-to-Unlock and actual right-click → Lock behavior. The exact saved content rectangle survived the refactor update.

No fresh-clone or third-party-machine build was required by the owner for this publication review. The README names the tested Apple Silicon/macOS 27.2/Swift 6.4.2 environment and separates the macOS 14 deployment target from verified compatibility. Physical hover interaction, every Space/Stage Manager arrangement, monitor reconnect, physical sleep/wake, measured frame rate and long-term stability have not all been independently verified. These remain ordinary documented limitations of a personal project, not withheld promises of broad platform support.

## Release boundary

The approval is for sharing source with accurate documentation under MIT. It does not certify a notarized downloadable app or guarantee absence of defects. There is no warranty or guaranteed maintenance commitment. Another review may increase confidence, but it is not imposed as a mandatory condition for this owner's personal source release.
