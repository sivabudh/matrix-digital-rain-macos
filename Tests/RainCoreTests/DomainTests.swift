import Foundation
import CoreGraphics
import Testing
@testable import RainCore

@Test func lockUnlockWorkflow() {
    let initial = OverlayState()
    #expect(initial.mode.actionLabel == "Unlock")
    #expect(initial.applying(.rightClick) == initial)
    let hovered = initial.applying(.pointerChanged(.inside))
    #expect(hovered.showsUnlock && !hovered.showsLock)
    let unlocked = hovered.applying(.unlock)
    #expect(unlocked.mode.actionLabel == "Lock")
    #expect(!unlocked.showsUnlock && !unlocked.showsLock)
    let revealed = unlocked.applying(.rightClick)
    #expect(revealed.showsLock)
    #expect(revealed.applying(.pointerChanged(.outside)).showsLock)
    #expect(revealed.applying(.lock).showsUnlock)
    #expect(!hovered.applying(.pointerChanged(.outside)).showsUnlock)
}

@Test func visibilitySleepAndReopen() {
    let unlocked = OverlayState().applying(.unlock).applying(.rightClick)
    let hidden = unlocked.applying(.toggleVisibility)
    #expect(hidden.mode == .locked)
    #expect(!hidden.animationActive && !hidden.showsLock && !hidden.showsUnlock)
    #expect(hidden.visibilityLabel == "Show Overlay")
    #expect(hidden.applying(.unlock).isVisible)
    #expect(hidden.applying(.toggleVisibility).mode == .locked)
    let sleeping = unlocked.applying(.displayChanged(.asleep))
    #expect(!sleeping.animationActive && !sleeping.showsLock)
    #expect(sleeping.applying(.displayChanged(.awake)).showsLock)
    #expect(sleeping.applying(.toggleVisibility).applying(.displayChanged(.awake)).animationActive == false)
    #expect(unlocked.applying(.unlock) == unlocked) // Reopen must not hide an existing Lock control.
}

@Test func invariantsAcrossEveryReachableState() {
    let events: [OverlayEvent] = [.unlock, .lock, .rightClick, .toggleVisibility,
        .pointerChanged(.inside), .pointerChanged(.outside), .displayChanged(.awake), .displayChanged(.asleep)]
    var states = [OverlayState()]
    var index = 0
    while index < states.count {
        let state = states[index]
        #expect(!(state.showsLock && state.showsUnlock))
        #expect(!state.showsLock || (!state.mode.isLocked && state.animationActive))
        #expect(!state.showsUnlock || (state.mode.isLocked && state.animationActive && state.pointer == .inside))
        #expect(state.isVisible || state.mode.isLocked)
        for event in events {
            let next = state.applying(event)
            if !states.contains(next) { states.append(next) }
        }
        index += 1
    }
    #expect(states.count >= 12)
}

@Test func invalidPlacementCannotEnterDomain() {
    for rect in [CGRect(x: CGFloat.nan, y: 0, width: 300, height: 200),
                 CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 200),
                 CGRect(x: 0, y: 0, width: 0, height: 200),
                 CGRect(x: 0, y: 0, width: -1, height: 200)] {
        #expect(OverlayFrame(rect) == nil)
    }
}

@Test func placementRestoresAndRecoversDisplays() {
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let left = CGRect(x: -1440, y: 100, width: 1440, height: 900)
    let saved = OverlayFrame(CGRect(x: -1200, y: 200, width: 600, height: 400))!
    #expect(OverlayLayout.restore(saved, screens: [screen, left]) == saved)
    let recovered = OverlayLayout.restore(saved, screens: [screen])
    #expect(screen.contains(recovered.rect))
    #expect(recovered.rect.size == saved.rect.size)
    let tooLarge = OverlayFrame(CGRect(x: 5000, y: -2000, width: 10000, height: 10000))!
    let clamped = OverlayLayout.restore(tooLarge, screens: [screen])
    #expect(screen.contains(clamped.rect))
    #expect(clamped.rect.size == OverlayLayout.maximumSize(on: screen))
    #expect(OverlayLayout.restore(nil, screens: [screen]).rect.size == OverlayLayout.defaultSize)
    let tiny = CGRect(x: 0, y: 0, width: 200, height: 150)
    #expect(tiny.contains(OverlayLayout.restore(nil, screens: [tiny]).rect))
    #expect(OverlayLayout.restore(nil, screens: []).rect.width > 0)
}

@Test func controlsAndAnimationScaleWithGeometry() {
    let frame = OverlayFrame(CGRect(x: -500, y: 200, width: 640, height: 420))!
    let control = OverlayLayout.controlRect(in: frame)
    #expect(frame.rect.contains(control))
    #expect(control.maxX == frame.rect.maxX - 12 && control.minY == frame.rect.minY + 12)
    let small = RainLayout(viewport: CGSize(width: 320, height: 210))
    let large = RainLayout(viewport: CGSize(width: 640, height: 420))
    #expect(small.scale * 2 == large.scale)
    #expect(small.sceneSize == large.sceneSize)
    #expect(large.scale < 1)
    let wide = RainLayout(viewport: CGSize(width: 900, height: 210))
    #expect(wide.scale == small.scale && wide.sceneSize.width > small.sceneSize.width)
}

@Test func animationIsDeterministicAndProducesValidGlyphs() {
    let viewport = CGSize(width: 640, height: 420)
    let original = RainScene(seed: 42)
    var first = original
    var second = RainScene(seed: 42)
    for _ in 0..<90 {
        first = first.advanced(by: 1 / 30, viewport: viewport)
        second = second.advanced(by: 1 / 30, viewport: viewport)
    }
    #expect(first == second)
    #expect(original == RainScene(seed: 42))
    #expect(first != original)
    let glyphs = first.glyphs(in: viewport)
    #expect(!glyphs.isEmpty)
    for glyph in glyphs {
        #expect((0..<RainStyle.alphabet.count).contains(glyph.character))
        #expect((0...11).contains(glyph.brightness))
        #expect(glyph.rect.width > 0 && glyph.rect.height > 0)
    }
    #expect(original.advanced(by: -1, viewport: viewport) == original)
    #expect(original.advanced(by: .infinity, viewport: viewport) == original)
    #expect(original.advanced(by: 10, viewport: viewport) == original.advanced(by: 0.1, viewport: viewport))
}
