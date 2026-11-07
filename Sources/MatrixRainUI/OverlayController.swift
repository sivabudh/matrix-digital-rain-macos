import AppKit
import RainCore

/// Main-thread shell: translates Mac input to domain events, then applies the result.
@MainActor
final class OverlayController: NSObject, NSWindowDelegate {
    private(set) var state = OverlayState()
    let surface: OverlaySurface
    let menu: MenuBar
    private let store: PlacementStore
    private let statusWriter: StatusWriter
    private var rendering = false
    private var hoverTimer: Timer?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(store: PlacementStore, statusWriter: StatusWriter, seed: UInt64) {
        self.store = store
        self.statusWriter = statusWriter
        surface = OverlaySurface(frame: store.load(screens: NSScreen.screens.map(\.visibleFrame)), seed: seed)
        menu = MenuBar()
        super.init()
        state = state.applying(.speedChanged(store.loadSpeed()))
        surface.window.delegate = self
        surface.onEvent = { [weak self] in self?.send($0) }
        menu.onEvent = { [weak self] in self?.send($0) }
        menu.onQuit = { NSApp.terminate(nil) }
        updateSizeLimits()
    }

    func start() {
        render(previous: nil)
        savePlacement()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.samplePointer() }
        }
        timer.tolerance = 0.02
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.willSleepNotification, in: workspace) { $0.send(.displayChanged(.asleep)) }
        observe(NSWorkspace.screensDidSleepNotification, in: workspace) { $0.send(.displayChanged(.asleep)) }
        observe(NSWorkspace.didWakeNotification, in: workspace) { $0.send(.displayChanged(.awake)) }
        observe(NSWorkspace.screensDidWakeNotification, in: workspace) { $0.send(.displayChanged(.awake)) }
        observe(NSApplication.didChangeScreenParametersNotification, in: .default) { $0.recoverPlacement() }
    }

    func send(_ event: OverlayEvent) {
        let previous = state
        let next = state.applying(event)
        guard next != previous else { return }
        state = next
        render(previous: previous)
        if case .speedChanged(let speed) = event { store.saveSpeed(speed) }
        if event == .lock || event == .toggleVisibility { savePlacement() }
    }

    private func render(previous: OverlayState?) {
        rendering = true
        defer { rendering = false }
        surface.rain.speed = state.speed
        surface.apply(state, previous: previous)
        menu.apply(state)
        writeStatus()
    }

    func samplePointer(at point: CGPoint? = nil) {
        let point = point ?? NSEvent.mouseLocation
        send(.pointerChanged(surface.contentFrame.rect.contains(point) ? .inside : .outside))
    }

    func stop() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        for (center, observer) in observers { center.removeObserver(observer) }
        observers.removeAll()
        savePlacement()
        store.flush()
        surface.stop()
        menu.remove()
    }

    func savePlacement() {
        store.save(surface.contentFrame)
        surface.refreshControls(for: state)
        writeStatus()
    }
    private func writeStatus() { statusWriter.write(state: state, surface: surface) }

    private func updateSizeLimits() {
        let screen = surface.window.screen?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let maximum = OverlayLayout.maximumSize(on: screen)
        surface.window.contentMinSize = CGSize(width: min(OverlayLayout.minimumSize.width, maximum.width),
                                              height: min(OverlayLayout.minimumSize.height, maximum.height))
        surface.window.contentMaxSize = maximum
    }

    func recoverPlacement() {
        rendering = true
        updateSizeLimits()
        surface.setContentFrame(OverlayLayout.restore(surface.contentFrame, screens: NSScreen.screens.map(\.visibleFrame)))
        rendering = false
        samplePointer()
        savePlacement()
    }

    private func observe(_ name: Notification.Name, in center: NotificationCenter,
                         action: @escaping @MainActor (OverlayController) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let self { action(self) } }
        }
        observers.append((center, token))
    }

    func windowDidMove(_ notification: Notification) { if !rendering { samplePointer(); savePlacement() } }
    func windowDidResize(_ notification: Notification) { if !rendering { samplePointer(); savePlacement() } }
    func windowDidChangeScreen(_ notification: Notification) { if !rendering { updateSizeLimits() } }
    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool { false }
    func windowShouldClose(_ sender: NSWindow) -> Bool { send(.lock); return false }
}
