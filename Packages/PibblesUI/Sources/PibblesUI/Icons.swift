import SwiftUI
import PibblesCore

// Icons drawn as paths, so iOS and Android show exactly the same shape (SF Symbols have
// no Android twin). Each draws in its rect; colours come from the caller.

/// Four rounded squares in a 2×2 grid: Blocks and the Blocks stall.
struct GridIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gap = rect.width * 0.12
        let side = (rect.width - gap) / 2.0
        let radius = side * 0.28
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: side, height: side), cornerSize: CGSize(width: radius, height: radius))
        path.addRoundedRect(in: CGRect(x: rect.minX + side + gap, y: rect.minY, width: side, height: side), cornerSize: CGSize(width: radius, height: radius))
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + side + gap, width: side, height: side), cornerSize: CGSize(width: radius, height: radius))
        path.addRoundedRect(in: CGRect(x: rect.minX + side + gap, y: rect.minY + side + gap, width: side, height: side), cornerSize: CGSize(width: radius, height: radius))
        return path
    }
}

/// Two circles side by side: Duo.
struct DuoIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let d = rect.width * 0.46
        let y = rect.midY - d / 2.0
        path.addEllipse(in: CGRect(x: rect.minX, y: y, width: d, height: d))
        path.addEllipse(in: CGRect(x: rect.maxX - d, y: y, width: d, height: d))
        return path
    }
}

/// A small pixel picture (a heart): Pixels.
struct PixelsIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cells = [1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 16, 17, 18, 22]
        let unit = rect.width / 5.0
        for cell in cells {
            let x = rect.minX + Double(cell % 5) * unit
            let y = rect.minY + Double(cell / 5) * unit
            path.addRoundedRect(in: CGRect(x: x + unit * 0.08, y: y + unit * 0.08, width: unit * 0.84, height: unit * 0.84), cornerSize: CGSize(width: unit * 0.2, height: unit * 0.2))
        }
        return path
    }
}

/// Four diamonds in a cross: the Patterns stall.
struct DiamondsIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width * 0.2
        let centers = [CGPoint(x: rect.midX, y: rect.minY + r), CGPoint(x: rect.minX + r, y: rect.midY),
                       CGPoint(x: rect.maxX - r, y: rect.midY), CGPoint(x: rect.midX, y: rect.maxY - r)]
        for c in centers {
            path.move(to: CGPoint(x: c.x, y: c.y - r))
            path.addLine(to: CGPoint(x: c.x + r, y: c.y))
            path.addLine(to: CGPoint(x: c.x, y: c.y + r))
            path.addLine(to: CGPoint(x: c.x - r, y: c.y))
            path.closeSubpath()
        }
        return path
    }
}

/// "<" and ">" (stroked): Signs.
struct SignsIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + w * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.42, y: rect.maxY - w * 0.18))
        path.move(to: CGPoint(x: rect.maxX - w * 0.42, y: rect.minY + w * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.42, y: rect.maxY - w * 0.18))
        return path
    }
}

/// A five-pointed star: Stars.
struct StarIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let outer = rect.width / 2.0
        let inner = outer * 0.45
        var index = 0
        while index < 10 {
            let angle = Double.pi * Double(index) / 5.0 - Double.pi / 2.0
            let radius = index % 2 == 0 ? outer : inner
            let point = CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius * 1.0 + outer * 0.08)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            index += 1
        }
        path.closeSubpath()
        return path
    }
}

/// Two dots joined by a winding line (stroked): Links.
struct LinksIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: rect.minX + w * 0.15, y: rect.minY + w * 0.2))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.15, y: rect.minY + w * 0.55))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + w * 0.55), control: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + w * 0.85))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.85, y: rect.minY + w * 0.5), control: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + w * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.85, y: rect.minY + w * 0.8))
        return path
    }
}

/// The two end dots of LinksIcon.
struct LinksDots: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let d = w * 0.26
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.15 - d / 2.0, y: rect.minY + w * 0.2 - d / 2.0, width: d, height: d))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.85 - d / 2.0, y: rect.minY + w * 0.8 - d / 2.0, width: d, height: d))
        return path
    }
}

/// A plus inside a bracketed block (stroked): Sums.
struct SumsIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.addRoundedRect(in: CGRect(x: rect.minX + w * 0.06, y: rect.minY + w * 0.06, width: w * 0.88, height: w * 0.88), cornerSize: CGSize(width: w * 0.18, height: w * 0.18))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + w * 0.28))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - w * 0.28))
        path.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.midY))
        return path
    }
}

/// An outlined cube: the Logic stall and the jokers.
struct CubeIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let top = CGPoint(x: rect.midX, y: rect.minY + w * 0.04)
        let upperRight = CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + w * 0.27)
        let lowerRight = CGPoint(x: rect.maxX - w * 0.08, y: rect.maxY - w * 0.27)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY - w * 0.04)
        let lowerLeft = CGPoint(x: rect.minX + w * 0.08, y: rect.maxY - w * 0.27)
        let upperLeft = CGPoint(x: rect.minX + w * 0.08, y: rect.minY + w * 0.27)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: top)
        path.addLine(to: upperRight)
        path.addLine(to: lowerRight)
        path.addLine(to: bottom)
        path.addLine(to: lowerLeft)
        path.addLine(to: upperLeft)
        path.closeSubpath()
        path.move(to: upperLeft)
        path.addLine(to: center)
        path.addLine(to: upperRight)
        path.move(to: center)
        path.addLine(to: bottom)
        return path
    }
}

/// A flame: the streak.
struct FlameIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.1, y: rect.minY + w * 0.62), control: CGPoint(x: rect.maxX, y: rect.minY + w * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX - w * 0.1, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + w * 0.62), control: CGPoint(x: rect.minX + w * 0.1, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + w * 0.3), control: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + w * 0.42))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + w * 0.15))
        path.closeSubpath()
        return path
    }
}

/// A trophy cup (stroked): today's tally and the ranking.
struct TrophyIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + w * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.25, y: rect.minY + w * 0.1))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + w * 0.62), control: CGPoint(x: rect.maxX - w * 0.25, y: rect.minY + w * 0.6))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + w * 0.1), control: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + w * 0.6))
        path.move(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + w * 0.2))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + w * 0.45), control: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + w * 0.25))
        path.move(to: CGPoint(x: rect.maxX - w * 0.25, y: rect.minY + w * 0.2))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.32, y: rect.minY + w * 0.45), control: CGPoint(x: rect.maxX - w * 0.02, y: rect.minY + w * 0.25))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + w * 0.62))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + w * 0.8))
        path.move(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + w * 0.88))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + w * 0.88))
        return path
    }
}

/// A light bulb (stroked): hints.
struct BulbIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.2, y: rect.minY + w * 0.02, width: w * 0.6, height: w * 0.6))
        path.move(to: CGPoint(x: rect.minX + w * 0.36, y: rect.minY + w * 0.74))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.36, y: rect.minY + w * 0.74))
        path.move(to: CGPoint(x: rect.minX + w * 0.4, y: rect.minY + w * 0.9))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.4, y: rect.minY + w * 0.9))
        return path
    }
}

/// A circular arrow (stroked): start over.
struct RestartIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: w * 0.38, startAngle: Angle.degrees(-60.0), endAngle: Angle.degrees(220.0), clockwise: false)
        let tip = CGPoint(x: rect.midX + w * 0.19, y: rect.midY - w * 0.33)
        path.move(to: CGPoint(x: tip.x - w * 0.2, y: tip.y - w * 0.08))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: tip.x - w * 0.02, y: tip.y + w * 0.2))
        return path
    }
}

/// A calendar page (stroked): today's puzzles.
struct CalendarIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.addRoundedRect(in: CGRect(x: rect.minX + w * 0.06, y: rect.minY + w * 0.14, width: w * 0.88, height: w * 0.8), cornerSize: CGSize(width: w * 0.14, height: w * 0.14))
        path.move(to: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + w * 0.38))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.06, y: rect.minY + w * 0.38))
        path.move(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + w * 0.04))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + w * 0.22))
        path.move(to: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + w * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + w * 0.22))
        return path
    }
}

/// A play triangle.
struct PlayIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A one-colour icon from the asset catalog (docs/brand 2–4: white on transparent, kept as
/// template images so they take any colour, on iOS and Android).
struct AssetIcon: View {
    let name: String
    let size: Double
    var color: Color = Color.white

    var body: some View {
        Image(name, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}

/// The icon of a puzzle (docs/brand 2.1–2.7), in one colour.
struct KindIcon: View {
    let kind: PuzzleKind
    let size: Double
    var color: Color = Color.white

    var body: some View {
        AssetIcon(name: KindIcon.assetName(kind), size: size, color: color)
    }

    static func assetName(_ kind: PuzzleKind) -> String {
        switch kind {
        case PuzzleKind.blocks: return "kind-blocks"
        case PuzzleKind.logic: return "kind-duo"
        case PuzzleKind.patterns: return "kind-pixels"
        case PuzzleKind.numbers: return "kind-signs"
        case PuzzleKind.stars: return "kind-stars"
        case PuzzleKind.links: return "kind-links"
        case PuzzleKind.sums: return "kind-sums"
        }
    }
}

/// The icon of a stall (docs/brand 3.1–3.4), in one colour.
struct StallIcon: View {
    let stall: String
    let size: Double
    var color: Color = Color.white

    var body: some View {
        AssetIcon(name: "stall-" + stall.lowercased(), size: size, color: color)
    }
}

/// A header illustration (docs/brand 5.1 and 5.2), light and dark.
struct Landscape: View {
    var name: String = "panorama-home"
    var height: Double = 120.0

    var body: some View {
        // The frame sets the size; the picture fills it. A filling image as the base view
        // would make the whole page wider than the screen.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Image(name, bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .clipped()
    }
}

/// Soft hills: `peaks` are heights (0 top … 1 bottom) spread evenly over the width.
struct Hills: Shape {
    let peaks: [Double]
    let baseline: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / Double(max(1, peaks.count - 1))
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * (baseline - 0.25 * (1.0 - peaks[0]))))
        var index = 1
        while index < peaks.count {
            let previousX = rect.minX + step * Double(index - 1)
            let x = rect.minX + step * Double(index)
            let y = rect.minY + rect.height * (baseline - 0.25 * (1.0 - peaks[index]))
            let control = CGPoint(x: (previousX + x) / 2.0, y: rect.minY + rect.height * (baseline - 0.35))
            path.addQuadCurve(to: CGPoint(x: x, y: y), control: control)
            index += 1
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A blossom branch in the top left corner.
struct Blossom: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack(alignment: .topLeading) {
                BranchShape()
                    .stroke(PibblesStyle.ink.opacity(0.45), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                flower(x: w * 0.42, y: h * 0.32, size: w * 0.13)
                flower(x: w * 0.7, y: h * 0.52, size: w * 0.1)
                flower(x: w * 0.2, y: h * 0.18, size: w * 0.09)
                flower(x: w * 0.85, y: h * 0.8, size: w * 0.08)
            }
        }
    }

    func flower(x: Double, y: Double, size: Double) -> some View {
        ZStack {
            Circle().fill(PibblesStyle.rose.opacity(0.85)).frame(width: size, height: size)
            Circle().fill(PibblesStyle.orange).frame(width: size * 0.35, height: size * 0.35)
        }
        .offset(x: x - size / 2.0, y: y - size / 2.0)
    }
}

struct BranchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.05))
        path.addQuadCurve(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.85), control: CGPoint(x: rect.width * 0.55, y: rect.height * 0.15))
        path.move(to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.45, y: rect.height * 0.0), control: CGPoint(x: rect.width * 0.45, y: rect.height * 0.15))
        return path
    }
}
