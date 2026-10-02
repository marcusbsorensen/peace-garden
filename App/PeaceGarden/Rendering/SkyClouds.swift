import CoreImage
import SwiftUI
import UIKit

/// The day's clouds.
///
/// **The same sky for everyone on a given day.** Which weather it is, how
/// many clouds and of what shapes are all dealt from the local date, and
/// where each one is comes from the time since midnight. Two people opening
/// their gardens in the same town at the same minute see the same clouds in
/// the same places. Some days are clear, and that is part of it: a sky that
/// always has clouds in it is a wallpaper.
///
/// **Few, soft and slow.** Fair-weather heaps lit from the sun's side, or
/// high wisps of ice, or one of each — never a covered sky, which would be
/// weather to have an opinion about. A heap takes a quarter of an hour to
/// cross the screen. When one goes off one side, the one that comes back on
/// the other is a new shape, so nobody watching for twenty minutes sees the
/// same cloud come round again.
///
/// **Drawn once and slid.** Each cloud is painted into a small picture when
/// it first appears, or when the sun has moved enough to light it from
/// somewhere else, and every frame after that is that picture moved a
/// fraction of a point. The cost a frame is a handful of image draws.
enum SkyClouds {

    enum Weather: String, Sendable {
        case clear, fair, high, mixed
    }

    struct Cloud: Sendable {
        enum Kind: Sendable { case heap, wisp }
        var kind: Kind
        /// Where along its first lap it is at midnight, `0..<1`.
        var start: Double
        /// Its middle, as a fraction of the screen's height.
        var y: Double
        /// As a fraction of the screen's width.
        var width: Double
        /// Its height as a fraction of its width.
        var tall: Double
        /// Points a second, signed: the day's wind.
        var speed: Double
        var opacity: Double
        var seed: UInt64
    }

    struct Day: Sendable {
        var weather: Weather
        var clouds: [Cloud]
    }

    /// The local day, counted from 1970: what the weather is dealt from.
    static func dayNumber(_ date: Date) -> Int {
        let local = date.timeIntervalSince1970 + Double(TimeZone.current.secondsFromGMT(for: date))
        return Int(floor(local / 86_400))
    }

    /// Seconds since local midnight.
    static func secondsIntoDay(_ date: Date) -> Double {
        let local = date.timeIntervalSince1970 + Double(TimeZone.current.secondsFromGMT(for: date))
        return local - floor(local / 86_400) * 86_400
    }

    /// The day's weather and its clouds.
    static func day(_ date: Date) -> Day {
        var dice = SkyDice(dayNumber(date), 0xC10D)
        let roll = dice.next()
        let weather: Weather = roll < 0.2 ? .clear : roll < 0.65 ? .fair : roll < 0.82 ? .high : .mixed
        let wind = (0.45 + 0.55 * dice.next()) * (dice.next() < 0.5 ? -1 : 1)

        var clouds: [Cloud] = []
        func heap(below: Bool = false) {
            let lane = clouds.count
            clouds.append(Cloud(
                kind: .heap,
                start: dice.next(),
                y: below ? 0.73 + 0.10 * dice.next() : 0.18 + 0.20 * dice.next(),
                width: below ? 0.17 + 0.10 * dice.next() : 0.24 + 0.16 * dice.next(),
                tall: below ? 0.30 + 0.06 * dice.next() : 0.40 + 0.14 * dice.next(),
                speed: wind * (below ? 1.25 : 0.8 + 0.4 * dice.next()),
                opacity: below ? 0.5 : 0.72 + 0.12 * dice.next(),
                seed: UInt64(dayNumber(date)) &* 1_000 &+ UInt64(lane)
            ))
        }
        func wisp() {
            let lane = clouds.count
            clouds.append(Cloud(
                kind: .wisp,
                start: dice.next(),
                y: 0.19 + 0.15 * dice.next(),
                width: 0.55 + 0.35 * dice.next(),
                tall: 0.26 + 0.10 * dice.next(),
                speed: wind * 0.55,
                opacity: 0.55 + 0.2 * dice.next(),
                seed: UInt64(dayNumber(date)) &* 1_000 &+ UInt64(lane)
            ))
        }

        switch weather {
        case .clear:
            // Near-clear rather than empty, most days: one small heap far off.
            if dice.next() < 0.45 { heap() }
        case .fair:
            for _ in 0..<(2 + Int(dice.next() * 2.99)) { heap() }
            if dice.next() < 0.5 { for _ in 0..<(1 + Int(dice.next() * 1.99)) { heap(below: true) } }
        case .high:
            for _ in 0..<(2 + Int(dice.next() * 1.99)) { wisp() }
        case .mixed:
            for _ in 0..<(1 + Int(dice.next() * 1.99)) { heap() }
            for _ in 0..<(1 + Int(dice.next() * 1.99)) { wisp() }
        }
        return Day(weather: weather, clouds: clouds)
    }

    // MARK: Drawing

    /// Every cloud of the day where it is at `date`.
    @MainActor
    static func draw(at date: Date, in context: inout GraphicsContext, size: CGSize,
                     palette: SkyPalette, sun: CGPoint?, up: Double, keepClear: [CGRect]) {
        let today = day(date)
        guard !today.clouds.isEmpty else { return }
        let seconds = secondsIntoDay(date)
        // Clouds come up with the light rather than being switched on at six.
        let dawn = SkyPalette.smooth(up / 0.08)
        guard dawn > 0.01 else { return }

        // Lit from where the sun is, as seen from the middle of the clouds'
        // band. Quantised, so a picture is painted again only when the sun
        // has moved far enough to light it from somewhere new.
        let band = CGPoint(x: size.width / 2, y: size.height * 0.28)
        let towards = sun.map { atan2($0.y - band.y, $0.x - band.x) } ?? -.pi / 2
        let sector = Int((towards / (2 * .pi) * 16).rounded())
        let tone = Int((palette.low * 12).rounded())
        let lightKey = "\(sector)-\(tone)"
        let angle = Double(sector) / 16 * 2 * .pi

        for (index, cloud) in today.clouds.enumerated() {
            let wide = cloud.width * size.width
            let high = wide * cloud.tall
            let margin = wide * 0.65
            let lap = size.width + margin * 2
            let travelled = cloud.start * lap + cloud.speed * seconds
            let round = Int(floor(travelled / lap))
            let x = travelled - Double(round) * lap - margin
            let rect = CGRect(x: x, y: cloud.y * size.height - high / 2, width: wide, height: high)
            guard rect.maxX > -8, rect.minX < size.width + 8 else { continue }

            let fade = clearance(of: rect, from: keepClear)
            guard fade > 0.02 else { continue }

            let key = "\(cloud.seed)-\(round)-\(Int(wide))-\(lightKey)" as NSString
            let image: UIImage
            if let kept = cache.object(forKey: key) {
                image = kept
            } else {
                image = paint(cloud, round: round, size: CGSize(width: wide, height: high),
                              light: angle, palette: palette)
                cache.setObject(image, forKey: key)
            }

            // A cloud breathes, very slowly: a few per cent over minutes.
            let breath = 1 + 0.025 * sin(seconds / 70 + Double(index) * 1.9)
            let drawn = CGRect(x: rect.minX - pad, y: rect.maxY + pad - (high + pad * 2) * breath,
                               width: wide + pad * 2, height: (high + pad * 2) * breath)
            var layer = context
            layer.opacity = cloud.opacity * fade * dawn
            layer.draw(Image(uiImage: image), in: drawn)
        }
    }

    /// How much of a cloud is kept near the screen's words: all of it in open
    /// sky, and less the more of it is behind them. A cloud drifting under the
    /// heading thins out, which is a thing clouds do anyway.
    static func clearance(of rect: CGRect, from words: [CGRect]) -> Double {
        var kept = 1.0
        for box in words where !box.isNull && !box.isEmpty {
            let near = box.insetBy(dx: -24, dy: -18)
            let overlap = near.intersection(rect)
            guard !overlap.isNull else { continue }
            let share = (overlap.width * overlap.height) / max(1, rect.width * rect.height)
            kept = min(kept, max(0, 1 - share * 2.2))
        }
        return kept
    }

    /// Room round a picture for its soft edge.
    private static let pad: CGFloat = 6

    @MainActor private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 24
        return cache
    }()

    @MainActor private static let soften = CIContext(options: [.cacheIntermediates: false])

    // MARK: Painting one

    /// One cloud, lit from `light` (an angle on the screen, towards the sun).
    @MainActor
    static func paint(_ cloud: Cloud, round: Int, size: CGSize, light: Double,
                      palette: SkyPalette) -> UIImage {
        var dice = SkyDice(Int(truncatingIfNeeded: cloud.seed), round &+ 77)
        let canvas = CGSize(width: size.width + pad * 2, height: size.height + pad * 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false

        // The lit side takes the sun's colour, more of it the lower the sun;
        // the shaded side is mostly the sky's own blue seen through thinner
        // cloud, which is what keeps a heap from reading as a sticker.
        let lit = SkyPalette.mix(SIMD3(0.95, 0.95, 0.96), palette.glow, 0.18 + 0.62 * palette.low)
        let shade = SkyPalette.mix(SkyPalette.mix(palette.zenith, palette.horizon, 0.62),
                                   SIMD3(0.52, 0.45, 0.57), 0.5 * palette.low)
        let sun = CGVector(dx: cos(light), dy: sin(light))

        let picture = UIGraphicsImageRenderer(size: canvas, format: format).image { drawing in
            let cg = drawing.cgContext
            switch cloud.kind {
            case .heap:
                heap(in: cg, size: size, dice: &dice, lit: lit, shade: shade, sun: sun,
                     high: 1 - palette.low)
            case .wisp:
                wisp(in: cg, size: size, dice: &dice, lit: lit, sun: sun)
            }
        }
        return softened(picture, radius: cloud.kind == .heap ? 3.0 : 3.6)
    }

    /// A fair-weather cumulus: a heaped top of rounded towers, the tallest
    /// near the middle, over a base that is nearly level and dissolves
    /// rather than stopping.
    ///
    /// **Laid out first and fitted after**, so no tower can run off the top
    /// of its picture and be cut flat there: a cut is a ruled line.
    private static func heap(in cg: CGContext, size: CGSize, dice: inout SkyDice,
                             lit: SIMD3<Double>, shade: SIMD3<Double>, sun: CGVector, high: Double) {
        let w = Double(size.width), h = Double(size.height)

        // In the cloud's own units: x across, y up from the base.
        var puffs: [(x: Double, y: Double, r: Double)] = []
        let count = 5 + Int(dice.next() * 4.99)
        let peak = 0.32 + 0.36 * dice.next()
        for k in 0..<count {
            let t = (Double(k) + 0.5) / Double(count)
            let rise = pow(max(0, 1 - abs(t - peak) * 1.6), 0.9)
            let r = 0.11 + 0.15 * rise * (0.8 + 0.4 * dice.next())
            let x = 0.10 + 0.80 * t + (dice.next() - 0.5) * 0.06
            puffs.append((x, r * 0.7 + 0.22 * rise, r))
        }
        // Smaller towers on the big ones, which is what makes a heap read as
        // a heap rather than a row of balls.
        for _ in 0..<(2 + Int(dice.next() * 3.99)) {
            let on = puffs[Int(dice.next() * Double(puffs.count))]
            let r = on.r * (0.45 + 0.25 * dice.next())
            puffs.append((on.x + (dice.next() - 0.5) * on.r * 1.2, on.y + on.r * 0.6, r))
        }
        // And a scatter of small ones along the top edge: the cauliflower.
        let towers = puffs
        for _ in 0..<(4 + Int(dice.next() * 4.99)) {
            let on = towers[Int(dice.next() * Double(towers.count))]
            let angle = .pi * (0.15 + 0.7 * dice.next())
            let r = on.r * (0.28 + 0.18 * dice.next())
            puffs.append((on.x + cos(angle) * on.r * 0.85, on.y + sin(angle) * on.r * 0.85, r))
        }
        let low = puffs.map { $0.x - $0.r }.min() ?? 0
        let wide = (puffs.map { $0.x + $0.r }.max() ?? 1) - low
        let tall = (puffs.map { $0.y + $0.r }.max() ?? 1)
        let scale = min(w / wide, h / tall)
        let base = Double(pad) + h
        let left = Double(pad) + (w - wide * scale) / 2
        func place(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: left + (x - low) * scale, y: base - y * scale)
        }

        let shape = CGMutablePath()
        for puff in puffs {
            let centre = place(puff.x, puff.y)
            let r = puff.r * scale
            shape.addEllipse(in: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2))
        }
        let floorLeft = place(0.06, 0), floorRight = place(0.94, 0)
        shape.addEllipse(in: CGRect(x: floorLeft.x, y: base - 0.16 * scale,
                                    width: floorRight.x - floorLeft.x, height: 0.2 * scale))

        // The base: nearly level, the way the condensation level makes it,
        // waved so it is never ruled.
        let level = CGMutablePath()
        let wave = dice.next() * 6
        let across = Double(size.width + pad * 2)
        level.move(to: .zero)
        level.addLine(to: CGPoint(x: across, y: 0))
        for step in stride(from: 32, through: 0, by: -1) {
            let x = across * Double(step) / 32
            let from = (x - Double(pad) - w / 2) / (w / 2)
            let y = base - 0.03 * scale + 0.05 * scale * sin(x / w * 9 + wave)
                - 0.08 * scale * pow(min(1, abs(from)), 3)
            level.addLine(to: CGPoint(x: x, y: y))
        }
        level.closeSubpath()

        cg.saveGState()
        cg.addPath(shape)
        cg.clip(using: .winding)
        cg.addPath(level)
        cg.clip()

        let space = CGColorSpaceCreateDeviceRGB()
        let middle = place(0.5, tall / 2)
        let reach = CGVector(dx: sun.dx * wide * scale * 0.55, dy: sun.dy * tall * scale * 0.55)

        // Lit from the sun's side, wherever on the screen the sun is: a low
        // sun under the clouds lights their undersides, as it does at dusk.
        fill(cg, from: CGPoint(x: middle.x + reach.dx, y: middle.y + reach.dy),
             to: CGPoint(x: middle.x - reach.dx, y: middle.y - reach.dy),
             colours: [cgColour(lit, 1), cgColour(SkyPalette.mix(lit, shade, 0.5), 1), cgColour(shade, 1)],
             at: [0, 0.5, 1], space: space)
        // And, with the sun high, brighter on top than underneath.
        if high > 0.01 {
            fill(cg, from: place(0.5, tall), to: place(0.5, 0),
                 colours: [cgColour(lit, 0.5 * high), cgColour(lit, 0), cgColour(shade, 0.6 * high)],
                 at: [0, 0.5, 1], space: space)
        }

        // Each tower lit on its sunward side and shaded on the other.
        for puff in puffs {
            let centre = place(puff.x, puff.y)
            let r = puff.r * scale
            radial(cg, at: CGPoint(x: centre.x + sun.dx * r * 0.42, y: centre.y + sun.dy * r * 0.42),
                   radius: r * 0.9, colours: [cgColour(lit, 0.42), cgColour(lit, 0)], space: space)
            radial(cg, at: CGPoint(x: centre.x - sun.dx * r * 0.55, y: centre.y - sun.dy * r * 0.55 + r * 0.2),
                   radius: r * 0.8, colours: [cgColour(shade, 0.24), cgColour(shade, 0)], space: space)
        }

        // The base thins out rather than stopping.
        cg.setBlendMode(.destinationOut)
        fill(cg, from: CGPoint(x: 0, y: base - 0.22 * scale), to: CGPoint(x: 0, y: base),
             colours: [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.7).cgColor],
             at: [0, 1], space: space)
        cg.restoreGState()
    }

    /// High ice cloud: a few long strands, each trailing fine hooks — mares'
    /// tails — and nothing with an edge.
    private static func wisp(in cg: CGContext, size: CGSize, dice: inout SkyDice,
                             lit: SIMD3<Double>, sun: CGVector) {
        let w = size.width, h = size.height
        cg.setLineCap(.round)
        let strands = 3 + Int(dice.next() * 2.99)
        let lean = dice.next() < 0.5 ? -1.0 : 1.0
        for _ in 0..<strands {
            // Staggered and bowed, so a sky of them is never a set of
            // parallel rules: each strand starts and stops somewhere of its
            // own, and swings up and then down along its length.
            let y0 = pad + h * (0.30 + 0.22 * dice.next())
            let y1 = pad + h * (0.30 + 0.22 * dice.next())
            let from = 0.22 * dice.next()
            let to = min(1, from + 0.55 + 0.3 * dice.next())
            let start = CGPoint(x: pad + w * from, y: y0)
            let end = CGPoint(x: pad + w * to, y: y1)
            let length = end.x - start.x
            let c1 = CGPoint(x: start.x + length * 0.33, y: y0 - h * (0.25 + 0.15 * dice.next()))
            let c2 = CGPoint(x: start.x + length * 0.70, y: y1 + h * (0.20 + 0.15 * dice.next()))
            let thick = 1.2 + 2.2 * dice.next()

            func at(_ t: Double) -> CGPoint {
                let u = 1 - t
                let x = u * u * u * start.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * end.x
                let y = u * u * u * start.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * end.y
                return CGPoint(x: x, y: y)
            }

            let segments = 36
            for s in 0..<segments {
                let t0 = Double(s) / Double(segments), t1 = Double(s + 1) / Double(segments)
                let taper = pow(sin(.pi * (t0 + t1) / 2), 0.8)
                cg.setStrokeColor(cgColour(lit, 0.55 * taper))
                cg.setLineWidth(thick * taper + 0.3)
                cg.move(to: at(t0))
                cg.addLine(to: at(t1))
                cg.strokePath()
            }

            // The hooks: short fibres falling away behind the strand.
            for _ in 0..<(2 + Int(dice.next() * 3.99)) {
                let t = 0.15 + 0.7 * dice.next()
                let from = at(t)
                // Kept inside the picture: a hook cut off at its edge would
                // end in a ruled line.
                let fall = min(h * (0.2 + 0.3 * dice.next()), pad + h * 0.95 - from.y)
                let back = w * 0.06 * lean * (0.5 + dice.next())
                let hook = CGMutablePath()
                hook.move(to: from)
                hook.addQuadCurve(to: CGPoint(x: from.x - back, y: from.y + fall),
                                  control: CGPoint(x: from.x - back * 0.1, y: from.y + fall * 0.8))
                cg.setStrokeColor(cgColour(lit, 0.24))
                cg.setLineWidth(0.6 + 0.8 * dice.next())
                cg.addPath(hook)
                cg.strokePath()
            }
        }
    }

    private static func fill(_ cg: CGContext, from: CGPoint, to: CGPoint, colours: [CGColor],
                             at locations: [CGFloat], space: CGColorSpace) {
        guard let gradient = CGGradient(colorsSpace: space, colors: colours as CFArray,
                                        locations: locations) else { return }
        cg.drawLinearGradient(gradient, start: from, end: to,
                              options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    private static func radial(_ cg: CGContext, at centre: CGPoint, radius: CGFloat,
                               colours: [CGColor], space: CGColorSpace) {
        guard let gradient = CGGradient(colorsSpace: space, colors: colours as CFArray,
                                        locations: [0, 1]) else { return }
        cg.drawRadialGradient(gradient, startCenter: centre, startRadius: 0,
                              endCenter: centre, endRadius: radius, options: [])
    }

    private static func cgColour(_ rgb: SIMD3<Double>, _ alpha: Double) -> CGColor {
        CGColor(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: alpha)
    }

    /// A little blur, so a cloud's edge is soft without being fuzzy.
    @MainActor
    private static func softened(_ image: UIImage, radius: Double) -> UIImage {
        guard let input = CIImage(image: image),
              let blur = CIFilter(name: "CIGaussianBlur") else { return image }
        blur.setValue(input.clampedToExtent(), forKey: kCIInputImageKey)
        blur.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = blur.outputImage?.cropped(to: input.extent),
              let cg = soften.createCGImage(output, from: input.extent) else { return image }
        // `clampedToExtent` smears the edge pixels outwards, and the edge is
        // transparent, so nothing is smeared in.
        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
    }
}

/// A small, fast, reproducible source of chance: SplitMix64.
///
/// The same two numbers in give the same sequence out on every phone, which is
/// the whole point — the sky is dealt, not rolled.
struct SkyDice {
    private var state: UInt64

    init(_ a: Int, _ b: Int) {
        state = UInt64(bitPattern: Int64(a)) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(bitPattern: Int64(b)) &* 0xBF58_476D_1CE4_E5B9
        _ = next()
    }

    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}
