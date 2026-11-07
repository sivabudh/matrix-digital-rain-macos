import AppKit
import Foundation
import RainCore
@testable import MatrixRainUI

// Run native checks synchronously on the main thread, without a generic UI test host.
@MainActor
private struct NativeChecks {
    func run() throws {
        _ = NSApplication.shared
        // This development executable has no app bundle Info.plist. Keep it alive
        // until all checks finish and the explicit success/failure exit runs.
        ProcessInfo.processInfo.disableAutomaticTermination("Native adapter verification")
        try bottomRightControlsDriveTheRealAdapters()
        try menuLabelsAndForbiddenFeatures()
        try speedMenuAppliesAndPersists()
        try placementCompatibilityAndMalformedPreferences()
        try windowChangesPersistWithoutDecorationDrift()
    }

    private func withController(_ action: (OverlayController, UserDefaults) throws -> Void) throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let suite = "local.pac.matrix-rain.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        let controller = OverlayController(store: PlacementStore(defaults: defaults),
            statusWriter: StatusWriter(directory: directory), seed: 42)
        defer {
            controller.stop()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        try action(controller, defaults)
    }

    private func bottomRightControlsDriveTheRealAdapters() throws {
        try withController { controller, _ in
            controller.start()
            let surface = controller.surface
            let rect = surface.contentFrame.rect
            controller.samplePointer(at: CGPoint(x: rect.maxX + 30, y: rect.maxY + 30))
            expect(!surface.unlockPanel.isVisible)
            controller.samplePointer(at: CGPoint(x: rect.midX, y: rect.midY))
            expect(surface.unlockPanel.isVisible)
            expect(surface.unlockPanel.frame == OverlayLayout.controlRect(in: surface.contentFrame))
            expect(surface.unlockPanel.level.rawValue > CGWindowLevelForKey(.desktopIconWindow))
            expect(surface.unlockPanel.level.rawValue < 0)
            surface.unlockButton.performClick(nil)
            expect(!controller.state.mode.isLocked && !surface.unlockPanel.isVisible)
            expect(surface.window.styleMask.contains(.resizable))
            expect(!surface.window.styleMask.contains(.titled))
            expect(surface.window.standardWindowButton(.closeButton) == nil)
            expect(surface.window.isMovableByWindowBackground && surface.rain.mouseDownCanMoveWindow)
            expect(surface.contentFrame.rect == rect)
            let event = NSEvent.mouseEvent(with: .rightMouseDown, location: CGPoint(x: 30, y: 30),
                modifierFlags: [], timestamp: 0, windowNumber: surface.window.windowNumber,
                context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
            surface.rain.rightMouseDown(with: event)
            surface.rain.layoutSubtreeIfNeeded()
            expect(!surface.lockButton.isHidden && surface.lockButton.title == "Lock")
            let lockFrame = surface.window.convertToScreen(surface.lockButton.convert(surface.lockButton.bounds, to: nil))
            expect(abs(lockFrame.minX - surface.unlockPanel.frame.minX) < 1)
            expect(abs(lockFrame.minY - surface.unlockPanel.frame.minY) < 1)
            surface.lockButton.performClick(nil)
            expect(controller.state.mode.isLocked && surface.window.ignoresMouseEvents)
            expect(surface.lockButton.isHidden)
            expect(surface.contentFrame.rect == rect)
        }
    }

    private func menuLabelsAndForbiddenFeatures() throws {
        try withController { controller, _ in
            controller.start()
            expect(controller.menu.items.map(\.title).contains("Unlock"))
            controller.send(.unlock)
            expect(controller.menu.items.map(\.title).contains("Lock"))
            expect(!controller.menu.items.map(\.title).contains("Unlock"))
            expect(controller.menu.items.allSatisfy { $0.keyEquivalent.isEmpty })
            expect(!controller.menu.items.contains { item in ["Pause", "Resume", "Fill", "Move & Resize"].contains { item.title.contains($0) } })
            let frame = controller.surface.contentFrame
            controller.surface.window.zoom(nil)
            controller.surface.window.toggleFullScreen(nil)
            expect(controller.surface.contentFrame == frame)
            expect(controller.surface.window.collectionBehavior.contains(.fullScreenNone))
            expect(!controller.surface.window.styleMask.contains(.fullScreen))
            controller.send(.toggleVisibility)
            expect(!controller.surface.window.isVisible && controller.state.mode.isLocked)
            expect(!controller.surface.unlockPanel.isVisible && controller.surface.lockButton.isHidden)
            controller.send(.unlock)
            expect(controller.surface.window.isVisible)
        }
    }

    private func speedMenuAppliesAndPersists() throws {
        try withController { controller, defaults in
            controller.start()
            expect(controller.state.speed == .relaxed)
            let submenu = controller.menu.items.first { $0.title == "Speed" }!.submenu!
            for speed in RainSpeed.allCases {
                let index = submenu.items.firstIndex { $0.tag == speed.rawValue }!
                submenu.performActionForItem(at: index)
                expect(controller.state.speed == speed)
                expect(controller.surface.rain.speed == speed)
                expect(submenu.items.filter { $0.state == .on }.map(\.tag) == [speed.rawValue])
                expect(PlacementStore(defaults: defaults).loadSpeed() == speed)
            }
            defaults.set(999, forKey: "rainSpeedPercent")
            expect(PlacementStore(defaults: defaults).loadSpeed() == .relaxed)
        }
    }

    private func placementCompatibilityAndMalformedPreferences() throws {
        _ = NSApplication.shared
        let suite = "local.pac.matrix-rain.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let store = PlacementStore(defaults: defaults)
        let saved = OverlayFrame(CGRect(x: 150, y: 200, width: 560, height: 350))!
        defaults.set(NSStringFromRect(saved.rect), forKey: "overlayContentRect")
        expect(store.load(screens: [screen]) == saved)
        defaults.set("garbage", forKey: "overlayContentRect")
        expect(store.load(screens: [screen]).rect.size == OverlayLayout.defaultSize)
        store.save(saved)
        store.flush()
        expect(PlacementStore(defaults: UserDefaults(suiteName: suite)!).load(screens: [screen]) == saved)
    }

    private func windowChangesPersistWithoutDecorationDrift() throws {
        try withController { controller, defaults in
            controller.start()
            controller.send(.unlock)
            let old = controller.surface.contentFrame.rect
            let changed = OverlayFrame(CGRect(x: old.minX + 20, y: old.minY + 10, width: 560, height: 350))!
            controller.surface.setContentFrame(changed)
            controller.send(.lock)
            expect(controller.surface.contentFrame == changed)
            let store = PlacementStore(defaults: defaults)
            expect(store.load(screens: NSScreen.screens.map(\.visibleFrame)) == changed)
            expect(controller.surface.window.level == OverlaySurface.desktopLevel)
            expect(controller.surface.window.level.rawValue > CGWindowLevelForKey(.desktopWindow))
            expect(controller.surface.window.level.rawValue < CGWindowLevelForKey(.desktopIconWindow))
        }
    }
}

@MainActor
private func expect(_ condition: @autoclosure () -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    guard condition() else {
        fputs("FAIL: native expectation at \(file):\(line)\n", stderr)
        exit(1)
    }
}

do {
    try NativeChecks().run()
    print("PASS: native adapter checks completed (5 scenarios).")
    exit(0)
} catch {
    fputs("FAIL: native adapter checks: \(error)\n", stderr)
    exit(1)
}
