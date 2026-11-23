import SwiftUI
import PibblesCore
#if os(iOS) && !SKIP
import CoreText
#endif

/// Colors from the Pibbles style board (docs/stijl.md), light and dark in the asset catalog.
public enum PibblesStyle {
    public static let background = Color("Background", bundle: .module)
    public static let surface = Color("Surface", bundle: .module)
    public static let sand = Color("Sand", bundle: .module)
    public static let sage = Color("Sage", bundle: .module)
    public static let teal = Color("Teal", bundle: .module)
    public static let purple = Color("Purple", bundle: .module)
    public static let orange = Color("Orange", bundle: .module)
    public static let ink = Color("Ink", bundle: .module)
    public static let muted = Color("Muted", bundle: .module)
    public static let line = Color("Line", bundle: .module)
    public static let bad = Color("Bad", bundle: .module)
    public static let good = Color("Good", bundle: .module)
    /// The dark purple of the app icon, the same in light and dark.
    public static let plum = Color("Plum", bundle: .module)
    /// An empty board square.
    public static let cell = Color("Cell", bundle: .module)

    /// iOS does not load the package fonts by itself: register them once at launch.
    /// Android has them in res/font (poppins_semibold, poppins_bold, inter).
    public static func registerFonts() {
        #if os(iOS) && !SKIP
        for name in ["Poppins-SemiBold", "Poppins-Bold", "Inter"] {
            if let url = Bundle.module.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        #endif
    }

    /// Titles: Poppins Bold (style board).
    public static func title(_ size: Double) -> Font {
        return Font.custom("Poppins Bold", size: size)
    }

    /// Text: Inter; semibold and bold use Poppins SemiBold, because Skip ignores the weight
    /// of a custom font on Android (one font file per weight there).
    public static func text(_ size: Double, _ weight: Font.Weight = .regular) -> Font {
        if weight == Font.Weight.semibold || weight == Font.Weight.bold {
            return Font.custom("Poppins SemiBold", size: size)
        }
        #if SKIP
        return Font.custom("Inter", size: size)
        #else
        return Font.custom("Inter", size: size).weight(weight)
        #endif
    }

    public static let rose = Color("Rose", bundle: .module)
    public static let mustard = Color("Mustard", bundle: .module)
    public static let sky = Color("Sky", bundle: .module)
    public static let berry = Color("Berry", bundle: .module)
    public static let leaf = Color("Leaf", bundle: .module)

    /// Piece and line colors by number: eight that stay apart next to each other.
    public static func pieceColor(_ index: Int) -> Color {
        let palette = [purple, orange, teal, rose, sky, mustard, berry, leaf]
        return palette[index % palette.count]
    }

    public static func kindColor(_ kind: PuzzleKind) -> Color {
        switch kind {
        case PuzzleKind.blocks, PuzzleKind.sums: return purple
        case PuzzleKind.logic, PuzzleKind.links: return teal
        case PuzzleKind.patterns, PuzzleKind.stars: return orange
        case PuzzleKind.numbers: return sky
        }
    }

    public static func stallColor(_ stall: String) -> Color {
        if stall == "Blocks" { return purple }
        if stall == "Logic" { return teal }
        if stall == "Patterns" { return orange }
        return sky
    }
}

/// What the market shows for each kind. Names are the stall names of the style board.
public enum KindInfo {
    /// The four stalls of the market, in order.
    public static let stalls = ["Blocks", "Logic", "Patterns", "Numbers"]

    public static func kinds(stall: String) -> [PuzzleKind] {
        var result = [PuzzleKind]()
        for kind in PuzzleKind.allCases {
            if kind.stall == stall { result.append(kind) }
        }
        return result
    }

    public static func stallTagline(_ stall: String) -> String {
        if stall == "Blocks" { return T.s("Classic block puzzles", "Klassieke blokpuzzels") }
        if stall == "Logic" { return T.s("Reasoning, one step at a time", "Stap voor stap redeneren") }
        if stall == "Patterns" { return T.s("Shapes, lines and pictures", "Vormen, lijnen en plaatjes") }
        return T.s("Puzzles with numbers", "Puzzels met getallen")
    }

    public static func name(_ kind: PuzzleKind) -> String {
        switch kind {
        case PuzzleKind.blocks: return "Blocks"
        case PuzzleKind.logic: return "Duo"
        case PuzzleKind.patterns: return "Pixels"
        case PuzzleKind.numbers: return "Signs"
        case PuzzleKind.stars: return "Stars"
        case PuzzleKind.links: return "Links"
        case PuzzleKind.sums: return "Sums"
        }
    }

    public static func tagline(_ kind: PuzzleKind) -> String {
        switch kind {
        case PuzzleKind.blocks: return T.s("Fit the blocks to the counts", "Leg de blokken op de getallen")
        case PuzzleKind.logic: return T.s("Balance two colours", "Twee kleuren in evenwicht")
        case PuzzleKind.patterns: return T.s("Reveal the picture", "Onthul het plaatje")
        case PuzzleKind.numbers: return T.s("Numbers with signs", "Getallen met tekens")
        case PuzzleKind.stars: return T.s("One star per row, column and area", "Eén ster per rij, kolom en gebied")
        case PuzzleKind.links: return T.s("Connect the colours", "Verbind de kleuren")
        case PuzzleKind.sums: return T.s("Numbers that add up", "Getallen die optellen")
        }
    }

    public static func rules(_ kind: PuzzleKind) -> [String] {
        switch kind {
        case PuzzleKind.blocks:
            return [T.s("Place every block on the board. Blocks cannot be turned.", "Leg alle blokken op het veld. Blokken draaien kan niet."),
                    T.s("The numbers say how many squares are filled in each row and column.", "De getallen zeggen hoeveel vakken per rij en kolom gevuld zijn."),
                    T.s("Drag a block onto the board, or tap a block and then the square for its top left corner.", "Sleep een blok naar het veld, of tik een blok en dan het vak voor de linkerbovenhoek.")]
        case PuzzleKind.logic:
            return [T.s("Fill every square with teal or purple.", "Vul elk vak met groen of paars."),
                    T.s("Each row and column has as many teal as purple.", "Elke rij en kolom heeft evenveel groen als paars."),
                    T.s("Never three of the same next to or below each other.", "Nooit drie dezelfde naast of onder elkaar.")]
        case PuzzleKind.patterns:
            return [T.s("The numbers are the lengths of the filled runs in each row and column, in order.", "De getallen zijn de lengtes van de gekleurde stukken per rij en kolom, op volgorde."),
                    T.s("Runs are separated by at least one empty square.", "Tussen twee stukken zit minstens één leeg vak."),
                    T.s("Switch to × to mark squares you know are empty.", "Kies × om vakken te markeren waarvan je weet dat ze leeg zijn.")]
        case PuzzleKind.numbers:
            return [T.s("Fill every square with a number from 1 up to the size of the board.", "Vul elk vak met een getal van 1 tot de grootte van het veld."),
                    T.s("Each number appears once in every row and column.", "Elk getal staat één keer in elke rij en kolom."),
                    T.s("A sign between two squares points at the smaller number.", "Een teken tussen twee vakken wijst naar het kleinste getal.")]
        case PuzzleKind.stars:
            return [T.s("Place one star in every row, every column and every coloured area.", "Zet één ster in elke rij, elke kolom en elk gekleurd gebied."),
                    T.s("Stars never touch, not even diagonally.", "Sterren raken elkaar nooit, ook niet schuin."),
                    T.s("Double-tap for a star. Tap or drag to mark squares without a star.", "Dubbeltik voor een ster. Tik of sleep om vakken zonder ster te markeren.")]
        case PuzzleKind.links:
            return [T.s("Draw a line between the two dots of each colour.", "Trek een lijn tussen de twee stippen van elke kleur."),
                    T.s("Lines never cross or share a square.", "Lijnen kruisen niet en delen geen vak."),
                    T.s("Together the lines fill the whole board.", "Samen vullen de lijnen het hele veld.")]
        case PuzzleKind.sums:
            return [T.s("Fill every square with a number from 1 up to the size of the board.", "Vul elk vak met een getal van 1 tot de grootte van het veld."),
                    T.s("Each number appears once in every row and column.", "Elk getal staat één keer in elke rij en kolom."),
                    T.s("The numbers in an outlined block add up to its small number.", "De getallen in een omlijnd blok tellen op tot het kleine getal.")]
        }
    }
}

extension View {
    /// A screen on the app background.
    public func pibblesScreen() -> some View {
        self.background(PibblesStyle.background.ignoresSafeArea())
    }

    /// A rounded card on the surface color.
    public func card(_ padding: Double = 16.0) -> some View {
        self.padding(padding)
            .background(PibblesStyle.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }

    /// Hides the navigation bar (home). The macOS prebuild of Skip lacks the modifier.
    public func hiddenNavigationBar() -> some View {
        #if os(iOS) || SKIP
        return self.toolbar(.hidden, for: .navigationBar)
        #else
        return self
        #endif
    }
}
