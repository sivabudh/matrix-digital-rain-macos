# Matrix Rain — frozen requirements v1

Frozen at the owner's request on 4 November 2026. This is the product contract for the refactor, reconstructed from the accepted changes in this chat. Changes to this document require a new explicit product decision; a refactor must preserve this behavior.

## Vocabulary

- **Locked**: rain sits above the wallpaper and below desktop icons; it cannot be dragged or resized and its surface passes mouse clicks through.
- **Unlocked**: borderless rain window comes forward for moving and resizing. No title bar, traffic-light window buttons, maximize, full-screen, or fill-display command.
- **Lock / Unlock**: the exact symmetric labels in the menu bar and on the bottom-right controls. No alternate wording such as “Move & Resize” or “Lock to Desktop”.

## Acceptance requirements

| ID | Required behavior |
| --- | --- |
| R01 | A native local macOS app renders green Matrix-style digital rain inside a rounded, dark, resizable rectangular region. The existing wallpaper is preserved. |
| R02 | Start visible and locked. Only one normal instance runs. Reopening the running app unlocks it. |
| R03 | In locked mode, the rain stays behind Finder icons and above wallpaper; clicks pass through its surface. Neither left-click nor right-click on the rain unlocks it. |
| R04 | Hovering over locked rain reveals **Unlock** at its bottom right. Moving the pointer away hides it. Clicking the button unlocks. The button must receive clicks independently of Finder's desktop event layer. |
| R05 | In unlocked mode, drag anywhere on the rain to move it and drag its edges/corners to resize it. Keep the window borderless. |
| R06 | Right-clicking unlocked rain reveals **Lock** at the bottom right. It remains available until locking; clicking it locks. No context menu at the pointer. |
| R07 | Lock and Unlock controls share the same location: 100 × 32 points, inset 12 points from the right and bottom. Locking/unlocking must preserve the rain area's exact screen position and size. |
| R08 | The menu bar offers **Unlock** when locked, **Lock** when unlocked, **Hide Overlay / Show Overlay**, and **Quit Matrix Rain**. Hide locks the overlay and hides all controls. Unlock from the menu also shows a hidden overlay. |
| R09 | No app keyboard shortcuts, including Escape. No pause/resume feature. No full-screen, zoom/maximize, fill-display, click-to-unlock gesture, or locked-mode right-click menu. |
| R10 | Rain is zoomed out and scales uniformly with the window: a 960 × 630 logical reference scene fits the rain area; reference glyph cells are 17 × 23 points. Preserve aspect ratio, extending the scene along the other axis for differently shaped windows. |
| R11 | Target 30 animation frames per second. Animation runs while visible and awake; suspend work while hidden or the display/computer sleeps. Timers must not restart on every hover or unrelated UI event. |
| R12 | Save the rain content rectangle automatically when moving/resizing. Restore it across quit/reopen, including updates of the app. Preserve the existing preferences identity and key. Do not persist unlocked mode or transient button visibility. |
| R13 | Minimum rain area 240 × 180 points when the display allows it. Leave at least 96 points of display size outside the maximum rain area. Default to 640 × 420 when possible. Recover invalid or disconnected-display placements to a usable display. No saved window may be stranded off-screen. |
| R14 | Join desktop Spaces. Ordinary windows and full-screen apps cover locked rain and its Unlock control. The Unlock control sits just above the desktop icon layer, not above normal application windows. |
| R15 | No network, AI service, external package dependency, Accessibility permission, Screen Recording permission, global click interception, or automatic login-item installation. |

## Refactor boundary

Retain `local.pac.matrix-rain`, `overlayContentRect`, the app name, and installation at `~/Applications/Matrix Rain.app`. Diagnostic snapshots remain local and are not a product control. Build and verification commands may exist for developers; the installed app has no test controls or keyboard shortcuts.

Existing compatibility details are implementation constraints, not new features. Tests of domain transitions or a button action do not establish that a person can click that button on the actual desktop. Record automated checks and actual Mac interaction evidence separately.

## Owner amendment — 7 November 2026

The menu bar includes a Speed submenu: 25%, 50%, 64%, 80%, 100%, 125%, and 200% of the original falling speed. Changes apply immediately and persist across launches; the default is 64%. Frame rate and glyph mutation timing remain unchanged. This adds a speed preference to R08/R12.
