import Foundation
import CoreGraphics

/// A validated content rectangle in AppKit screen coordinates, excluding chrome.
public struct OverlayFrame: Equatable, Sendable {
    public let rect: CGRect

    public init?(_ rect: CGRect) {
        guard rect.origin.x.isFinite, rect.origin.y.isFinite,
              rect.size.width.isFinite, rect.size.height.isFinite,
              rect.size.width > 0, rect.size.height > 0,
              rect.maxX.isFinite, rect.maxY.isFinite else { return nil }
        self.rect = rect
    }
}

public enum OverlayLayout {
    public static let minimumSize = CGSize(width: 240, height: 180)
    public static let defaultSize = CGSize(width: 640, height: 420)
    public static let controlSize = CGSize(width: 100, height: 32)
    public static let controlInset: CGFloat = 12

    public static func maximumSize(on screen: CGRect) -> CGSize {
        CGSize(width: min(screen.width, max(minimumSize.width, screen.width - 96)),
               height: min(screen.height, max(minimumSize.height, screen.height - 96)))
    }

    public static func controlRect(in frame: OverlayFrame) -> CGRect {
        CGRect(x: frame.rect.maxX - controlSize.width - controlInset,
               y: frame.rect.minY + controlInset,
               width: controlSize.width, height: controlSize.height)
    }

    public static func restore(_ saved: OverlayFrame?, screens: [CGRect]) -> OverlayFrame {
        let usable = screens.filter { OverlayFrame($0) != nil }
        let primary = usable.first ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let proposed = saved?.rect ?? CGRect(x: primary.minX + 60, y: primary.maxY - 500,
                                            width: defaultSize.width, height: defaultSize.height)
        // Preserve the first display on an intersection tie, including disconnection.
        let screen = usable.reduce(primary) { best, candidate in
            intersectionArea(candidate, proposed) > intersectionArea(best, proposed) ? candidate : best
        }
        let maximum = maximumSize(on: screen)
        let size = CGSize(width: min(max(proposed.width, minimumSize.width), maximum.width),
                          height: min(max(proposed.height, minimumSize.height), maximum.height))
        let rect = CGRect(x: min(max(proposed.minX, screen.minX), screen.maxX - size.width),
                          y: min(max(proposed.minY, screen.minY), screen.maxY - size.height),
                          width: size.width, height: size.height)
        // Every coordinate came from validated screen geometry or fixed constants.
        return OverlayFrame(rect)!
    }

    private static func intersectionArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        return intersection.isNull ? 0 : intersection.width * intersection.height
    }
}
