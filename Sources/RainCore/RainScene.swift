import Foundation
import CoreGraphics

public enum RainStyle {
    public static let referenceSize = CGSize(width: 960, height: 630)
    public static let cell = CGSize(width: 17, height: 23)
    public static let framesPerSecond = 30.0
    public static let alphabet = Array("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン012345789:+=<>[]")
}

public struct RainLayout: Equatable, Sendable {
    public let scale: CGFloat
    public let sceneSize: CGSize
    public init(viewport: CGSize) {
        scale = max(0.01, min(viewport.width / RainStyle.referenceSize.width,
                              viewport.height / RainStyle.referenceSize.height))
        sceneSize = CGSize(width: max(0, viewport.width) / scale,
                           height: max(0, viewport.height) / scale)
    }
}

public struct RainGlyph: Equatable, Sendable {
    public let character: Int
    public let brightness: Int
    /// Top-left coordinates in the logical scene, before viewport scaling.
    public let rect: CGRect
}

/// Small deterministic generator. Randomness is an explicit input to the model.
private struct RainRandom: Equatable, Sendable {
    var seed: UInt64
    mutating func next() -> UInt64 {
        seed &+= 0x9e3779b97f4a7c15
        var value = seed
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / 9_007_199_254_740_992 }
    mutating func index(_ count: Int) -> Int { Int(next() % UInt64(count)) }
}

public struct RainScene: Equatable, Sendable {
    private struct Stream: Equatable, Sendable {
        var head: Double
        let speed: Double
        let length: Int
        var glyphs: [Int]
    }
    private var random: RainRandom
    private var streams: [Stream] = []
    private var mutationTime = 0.0

    public init(seed: UInt64) { random = RainRandom(seed: seed) }

    /// Deterministic and free of clocks or drawing calls. The old scene is unchanged.
    public func advanced(by elapsed: Double, viewport: CGSize) -> Self {
        guard elapsed.isFinite, elapsed >= 0 else { return self }
        var next = self
        next.advance(by: min(elapsed, 0.1), layout: RainLayout(viewport: viewport))
        return next
    }

    private mutating func makeStream(rows: Double) -> Stream {
        let head = -35 + random.unit() * (max(1, rows) + 35)
        let speed = 5 + random.unit() * 10
        let length = 9 + random.index(18)
        let glyphs = (0..<100).map { _ in random.index(RainStyle.alphabet.count) }
        return Stream(head: head, speed: speed, length: length, glyphs: glyphs)
    }

    private mutating func advance(by delta: Double, layout: RainLayout) {
        let count = max(1, Int(ceil(layout.sceneSize.width / RainStyle.cell.width)))
        let rows = Double(layout.sceneSize.height / RainStyle.cell.height)
        while streams.count < count { streams.append(makeStream(rows: rows)) }
        if streams.count > count { streams.removeLast(streams.count - count) }
        mutationTime += delta
        for index in streams.indices {
            streams[index].head += delta * streams[index].speed
            if streams[index].head - Double(streams[index].length) > rows {
                streams[index] = makeStream(rows: rows)
                streams[index].head = -18 + random.unit() * 17
            }
            if mutationTime > 0.09 {
                let slot = random.index(streams[index].glyphs.count)
                streams[index].glyphs[slot] = random.index(RainStyle.alphabet.count)
            }
        }
        if mutationTime > 0.09 { mutationTime = 0 }
    }

    public func glyphs(in viewport: CGSize) -> [RainGlyph] {
        let layout = RainLayout(viewport: viewport)
        var result: [RainGlyph] = []
        result.reserveCapacity(streams.count * 20)
        for (column, stream) in streams.enumerated() {
            for offset in 0..<stream.length {
                let row = floor(stream.head) - Double(offset)
                let y = row * RainStyle.cell.height
                guard y > -RainStyle.cell.height, y < layout.sceneSize.height else { continue }
                let brightness = offset == 0 ? 11 : max(0, min(10, Int((1 - Double(offset) / Double(stream.length)) * 10)))
                let slot = (Int(row) % stream.glyphs.count + stream.glyphs.count) % stream.glyphs.count
                result.append(RainGlyph(character: stream.glyphs[slot], brightness: brightness,
                    rect: CGRect(x: CGFloat(column) * RainStyle.cell.width, y: y,
                                 width: RainStyle.cell.width, height: RainStyle.cell.height)))
            }
        }
        return result
    }
}
