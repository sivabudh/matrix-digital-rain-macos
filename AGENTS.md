# Matrix Rain engineering guidance

Read REQUIREMENTS.md and ARCHITECTURE.md before changing behavior. Requirements v1 are frozen; only an explicit user change revises them. Keep Lock / Unlock wording symmetric. Do not reintroduce title bars, full-screen/fill/zoom, pause, shortcuts, click-to-unlock or locked-mode context menus.

Keep RainCore deterministic and independent of AppKit, screen enumeration, clocks, system randomness, preferences, files and event monitoring. Use value types and associated-value enums for domain alternatives. Pass elapsed time, seed and geometry explicitly. Validate persisted rectangles before treating them as domain frames.

Native UI and effects belong in the main-actor AppKit shell. Views emit typed events; OverlayController owns domain state. Do not add product decisions as independent view flags. Preserve bundle identity and placement preference compatibility. The separate hover Unlock panel is intentional: rain stays below icons and click-through, while only that control sits above Finder's desktop layer.

Use proportionate design: no external framework or generic abstraction without a requirement. Run the domain/native adapter tests and release build after structural changes. Record actual Mac interaction evidence separately from button/action tests. Preserve the user's saved frame during updates. Do not add test entry points to the installed app.
