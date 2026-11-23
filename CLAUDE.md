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
(cd iOS && xcodegen)                             # Xcode-project genereren (iOS/project.yml)
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
(cd Android && ./gradlew assembleDebug)          # Android (draait eerst swift build van de UI)
(cd server && npm install && npm test)           # Worker-tests; npx wrangler dev voor lokaal
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
- **Een array die een klasse vasthoudt (`var` property) wordt bij elke schrijfactie gekopieerd**
  (Skip zet er `sref()` in de getter en setter). In een zoeklus maakte dat de Blocks-oplosser op
  Android honderd keer trager (16 s voor een zondagpuzzel). Houd zoektoestand in lokale
  variabelen of in `Int64`-getallen (`Solver.swift`), en maak vaste tabellen `let`.
- **`Task.detached { … }.value` levert in de Android-build niets op.** Zwaar werk gaat daar via
  `kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) { … }` in `#if SKIP`
  (`PlayModel.load`).
- **Start geen werk in de `init` van een view of in `State(initialValue:)`**: SwiftUI maakt
  views vaak opnieuw aan (elke `NavigationLink`-bestemming). Start bij `onAppear`.
- **Niet elk SF Symbol heeft een Android-tegenhanger**: `star` wordt een waarschuwingsdriehoek,
  `star.fill` werkt. Zie de tabel in SkipUI `Image.swift`; liever eigen vormen (`Icons.swift`).
- **`.contentShape` en `.monospacedDigit()` bestaan niet in SkipUI.**
- **Argumentlabels worden in Kotlin parameternamen** en verbergen een property met dezelfde
  naam (`restore(positions saved:)` → "'val' cannot be reassigned"). Schrijf `self.positions`.
- **Een `NavigationLink`-bestemming wordt meteen gebouwd**, ook zonder tikken: een keuze in
  `State(initialValue:)` (zoals "regels tonen?") valt dan te vroeg. Beslis in `onAppear`.
- **Tab-iconen uit de catalogus**: op iOS bepaalt de schaal (3x) de maat; Android toont het
  plaatje op pixelmaat en krijgt een vaste `frame` (`tabIcon` in `RootView.swift`).
- **Een breed plaatje (panorama) duwt de pagina breder** met `.scaledToFill()`. Gebruik
  `Color.clear.frame(height:)` met het plaatje als `overlay` en `.clipped()` (`Landscape`).
- **`Long shl Long` bestaat niet in Kotlin**: schuif een `Int64` over een `Int` (`one << square`),
  en vergelijk een `Int64` met een getypte nul (`let empty: Int64 = 0`).

## Website testen

Headless Chrome legt een pagina op minstens 500 px breed uit; een schermafdruk op 390 px is
daardoor afgesneden. Test smalle schermen op 500 px of in een echte browser.

## Emulator

Een traag of hangend Android-toestel (ANR's, ook bij systeemapps) kwam door de Mac: swap vol en
de emulator met software-rendering. Start hem met
`emulator -avd Medium_Phone_API_36.1 -gpu host -memory 2048 -cores 4` en test ook met
`assembleRelease`; een debug-build van Compose is veel trager.
