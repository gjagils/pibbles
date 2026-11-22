# Pibbles

Dagelijkse puzzels voor de App Store en Google Play. Lees eerst [HANDOFF.md](HANDOFF.md):
regels van de eerste puzzel (Randsom, werknaam), weekritme, reeks en jokers, opzet.

- Taal: Nederlands in documentatie; code en identifiers in het Engels.
- `Packages/PibblesCore` wordt door Skip naar Kotlin getranspileerd. Houd je aan de
  Skip-valkuilen van SquashAnalyzer (`~/Github/squash-court-analyzer/docs/skip-valkuilen.md`)
  en de lijst hieronder.
- Regels (generator, oplosser, bord, reeks, score) horen in Core, met tests eerst. UI
  dupliceert geen regels: het speelscherm vraagt `PuzzleRules`.
- Zelfde seed, zelfde puzzel: Swift, de Kotlin-vertaling en `prototype/logic.js` moeten
  voor een niveau en seed dezelfde puzzel geven. `PuzzleGeneratorTests` bewaakt dat met
  waarden uit het prototype. Wie de generator, de vormenlijst of de volgorde daarvan
  wijzigt, verandert alle puzzels en moet die waarden opnieuw uit het prototype halen.
- Zustersapps: Hoeveelishet (`~/Github/hoeveelishet`) en SquashAnalyzer. Opzet (Skip,
  Cloudflare Worker) komt daar vandaan. Domein: pibbles.app (Cloudflare).

## Commando's

```bash
swift test --package-path Packages/PibblesCore   # Core-tests: Swift en, via Skip, Kotlin
(cd prototype && node t.js)                      # prototype: generator per weekdag meten
```

## Skip-valkuilen die hier gevonden zijn

- **`String.utf16` geeft in Kotlin bytes met een byte order mark**, dus een andere hash
  dan in Swift. `StringHash` loopt over `utf8`; seeds blijven ASCII.
- **Een kale literal naast een `Int64`** (`1 | state`) wordt `1 or state` en compileert
  niet (Int tegen Long). Geef de constante een type: `let one: Int64 = 1`.
- **Swifts `Int` is in Kotlin 32 bits** en Kotlin loopt stil over waar Swift stopt.
  32-bits rekenwerk (de randomgenerator) staat daarom in `Int64` met een masker.
- **Een `[Int]` doorgeven waar `[Int?]` gevraagd is** compileert in Swift, niet in Kotlin.
