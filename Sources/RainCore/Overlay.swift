/// The Lock control only exists as part of an unlocked state.
public enum LockControl: Equatable, Sendable { case hidden, revealed }
public enum OverlayMode: Equatable, Sendable {
    case locked
    case unlocked(LockControl)

    public var isLocked: Bool { self == .locked }
    public var actionLabel: String { isLocked ? "Unlock" : "Lock" }
}

public enum OverlayVisibility: Equatable, Sendable { case visible, hidden }
public enum DisplayActivity: Equatable, Sendable { case awake, asleep }
public enum PointerRegion: Equatable, Sendable { case inside, outside }

public enum OverlayEvent: Equatable, Sendable {
    case unlock, lock, toggleVisibility, rightClick
    case pointerChanged(PointerRegion)
    case displayChanged(DisplayActivity)
    case speedChanged(RainSpeed)
}

/// Product state has no window, timer, preferences or rendering dependency.
public struct OverlayState: Equatable, Sendable {
    public private(set) var speed: RainSpeed = .relaxed
    public private(set) var mode: OverlayMode = .locked
    public private(set) var visibility: OverlayVisibility = .visible
    public private(set) var display: DisplayActivity = .awake
    public private(set) var pointer: PointerRegion = .outside

    public init() {}
    public var isVisible: Bool { visibility == .visible }
    public var animationActive: Bool { isVisible && display == .awake }
    public var showsUnlock: Bool { mode.isLocked && animationActive && pointer == .inside }
    public var showsLock: Bool { mode == .unlocked(.revealed) && animationActive }
    public var visibilityLabel: String { isVisible ? "Hide Overlay" : "Show Overlay" }

    /// A value in, a value out. Window changes and storage happen in the shell.
    public func applying(_ event: OverlayEvent) -> Self {
        var next = self
        switch event {
        case .speedChanged(let speed):
            next.speed = speed
        case .unlock:
            if mode.isLocked { next.mode = .unlocked(.hidden) }
            next.visibility = .visible
        case .lock:
            next.mode = .locked
        case .rightClick:
            if !mode.isLocked { next.mode = .unlocked(.revealed) }
        case .toggleVisibility:
            next.mode = .locked
            next.visibility = isVisible ? .hidden : .visible
        case .pointerChanged(let region):
            next.pointer = region
        case .displayChanged(let activity):
            next.display = activity
        }
        return next
    }
}
