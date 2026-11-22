# Pibbles

Dagelijkse puzzels voor iOS en Android: zeven puzzels in vier kramen (Blocks; Logic: Duo,
Stars; Patterns: Pixels, Links; Numbers: Signs, Sums). Swift + Skip: één code voor beide
apps. Server en website op pibbles.app (Cloudflare Worker).

| Map | Wat |
|---|---|
| `Packages/PibblesCore` | Regels, generatoren, oplossers, reeks; getest in Swift én Kotlin |
| `Packages/PibblesUI` | Alle schermen (SwiftUI, via Skip ook Compose) |
| `iOS/` | Dunne iOS-app (`project.yml` → `xcodegen`) |
| `Android/` | Dunne Android-app (Gradle, gebruikt de Skip-uitvoer) |
| `server/` | Worker: website, weekpakket, ranglijst (`server/README.md`) |
| `Tools/PackBuilder` | Maakt het weekpakket voor de server |
| `docs/` | Puzzelregels, stijl, beslissingen, verdienmodel, beeldmateriaal, rapporten |
| `prototype/` | Het oorspronkelijke webprototype van Randsom |

Begin bij [CLAUDE.md](CLAUDE.md) (commando's en Skip-valkuilen) en
[docs/beslissingen.md](docs/beslissingen.md).
