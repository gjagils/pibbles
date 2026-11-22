# Beeldmateriaal dat nog gemaakt moet worden

Nu staat er in de app zelfgetekend materiaal: vormen in code, zodat iOS en Android
hetzelfde tonen. Hieronder staat wat beter kan als echt ontwerp. Per item: waar het
staat, wat het nu is, en wat er moet komen.

**Algemene eisen**
- Stijl van het stijlbord (`docs/stijl.md`): rustig, licht oosters, afgeronde vormen,
  palet paars `#6D5B8C`, oranje `#E9A36A`, teal `#7CAEA6`, salie `#C9D8D1`, zand `#E8E1D9`,
  achtergrond `#FAF7F2` (licht) en `#1F1E2E` (donker).
- **Iconen**: PNG met transparante achtergrond. Lever ook een SVG als dat kan; dat
  houdt ze scherp. Eén kleur (wit) als ze op een gekleurd vlak staan.
- **Licht en donker**: alles wat op de achtergrond staat (illustraties, landschap) in
  twee versies, of zo dat het op beide achtergronden werkt.
- **Geen tekst in plaatjes**: de app is Nederlands en Engels.
- **Geen gelijkenis met bestaande merken**: niet met LinkedIn (Tango, Queens) of met
  andere puzzelapps. Dus geen zon en maan bij Duo en geen kroontjes bij Stars.

## 1. Merk

| # | Element | Nu | Gewenst |
|---|---|---|---|
| 1.1 | App-icoon | Jouw icoon (`docs/brand/pibbles-icon-origineel.png`), hoeken door mij met paars opgevuld | 1024×1024 PNG zonder afgeronde hoeken en zonder transparantie (iOS rondt zelf af). Paarse achtergrond tot in de hoeken |
| 1.2 | Android adaptief icoon | Hetzelfde icoon, verkleind | Twee lagen van 432×432: (a) een **voorgrond** met alleen de penseelring en de vier vormen, op transparant, binnen de middelste 66% (veilige zone); (b) een **achtergrond**: effen paars of de paarse verloop |
| 1.3 | Android monochroom icoon | Ontbreekt | Voorgrond in één kleur (wit op transparant), voor Android 13+ thema-iconen |
| 1.4 | Logo in de app | Het app-icoon, verkleind | Het teken zonder de vierkante achtergrond (ring en vier vormen) op transparant, ongeveer 600×600, voor naast de naam "Pibbles" |
| 1.5 | Woordmerk "Pibbles" en "DAILY PUZZLES" | Systeemlettertype | Optioneel: woordmerk als SVG. Anders de lettertypes Poppins en Inter (Google Fonts, OFL) als bestanden in het project |
| 1.6 | Favicon website | Door de server-agent getekend (`server/public/favicon.svg`) | SVG en 32×32/180×180 PNG van het teken |

## 2. Puzzeliconen (zeven)

Te zien op de gekleurde tegels (startscherm, markt, ranglijst, statistiek). Nu
eenvoudige vormen in code (`Packages/PibblesUI/Sources/PibblesUI/Icons.swift`).
Gewenst: wit op transparant, 256×256 PNG en SVG, met dezelfde lijndikte en
afronding voor alle zeven.

| # | Puzzel (kraam) | Nu | Idee |
|---|---|---|---|
| 2.1 | Blocks (Blocks) | 2×2 afgeronde vierkantjes | Een paar blokvormen (T, L) die in elkaar passen |
| 2.2 | Duo (Logic) | Twee rondjes | Twee rondjes, een gevuld en een open, of een rijtje van drie |
| 2.3 | Stars (Logic) | Vijfpuntige ster | Een ster in een vak van een raster |
| 2.4 | Pixels (Patterns) | Hartje van blokjes | Een klein plaatje van blokjes (een blad of een vis) |
| 2.5 | Links (Patterns) | Twee stippen met een kronkellijn | Twee stippen verbonden door een lijn met haakse bochten |
| 2.6 | Signs (Numbers) | Tekens `<` en `>` | Een `<` tussen twee vakjes |
| 2.7 | Sums (Numbers) | Plusje in een kader | Een omlijnd blok met een plusje of een klein somgetal in de hoek |

## 3. Kraamiconen (vier)

Op de markt (startscherm en tabblad Markt), wit op een gekleurde tegel. Nu: raster,
kubus, vier ruitjes en de tekst "123".

| # | Kraam | Gewenst |
|---|---|---|
| 3.1 | Blocks | Raster van vier blokken (zoals het stijlbord) |
| 3.2 | Logic | Kubus (zoals het stijlbord) |
| 3.3 | Patterns | Vier ruitjes (zoals het stijlbord) |
| 3.4 | Numbers | "123" als vorm, niet als tekst, of een ander getallenteken |

Bonus: een **kraampje** (luifel, toonbank) per kraam, als grotere illustratie bovenaan
het kraamscherm. Dat sluit aan bij het idee "een markt met kramen" uit `HANDOFF.md`.

## 4. Kleine iconen in de app

Wit of in de themakleur, 96×96 PNG en SVG.

| # | Waar | Nu | Gewenst |
|---|---|---|---|
| 4.1 | Tegel Reeks | Vlammetje (code) | Vlammetje |
| 4.2 | Tegel Jokers | Kubus (code) | Een joker-teken: een kaart of een kubusje met ster |
| 4.3 | Tegel Vandaag / ranglijst | Bekertje (code) | Beker |
| 4.4 | Hintknop | Gloeilamp (code) | Gloeilamp |
| 4.5 | Opnieuw-knop | Draaiende pijl (code) | Draaiende pijl |
| 4.6 | Dagkaart | Kalender (code) | Kalender |
| 4.7 | Tabbalk: Home, Markt, Ranglijst, Statistiek | Systeemsymbolen (op Android Material-iconen) | Een eigen set van vier, in dezelfde lijnstijl als 2 en 3 |

## 5. Illustraties

| # | Waar | Nu | Gewenst |
|---|---|---|---|
| 5.1 | Kop van startscherm en markt | Heuvels, zon en bloesemtak in code (grof) | Panorama van bergen met zon en bloesemtak in de stijl van het stijlbord: 1290×450 PNG, licht en donker. De onderrand loopt uit in de achtergrondkleur |
| 5.2 | Markt-kop | Hetzelfde landschap | Variant met een pagode of kraampjes (zoals op het stijlbord rechts) |
| 5.3 | Kaarten van de kramen | Een getekende heuvel rechtsonder | Kleine heuvelsilhouet per kraam in de kraamkleur, 300×120 PNG |
| 5.4 | "Opgelost!"-kaart | Alleen tekst | Kleine viering: bloesemblaadjes of confetti in het palet, 600×300 PNG |
| 5.5 | Golfpatroon | Ontbreekt | Het golfpatroon van het stijlbord als naadloze tegel (256×256 PNG), voor onderin het puzzelscherm |
| 5.6 | Penseelcirkel | Ontbreekt in de app | De ring uit het logo los, voor achter een getal of op het startscherm |

## 6. Winkels en website

| # | Element | Maat |
|---|---|---|
| 6.1 | App Store-schermafbeeldingen | 1320×2868 (iPhone 6,9"), 3 tot 10 stuks; ik kan ruwe schermafbeeldingen uit de simulator leveren |
| 6.2 | Google Play-schermafbeeldingen | 1080×1920 of hoger, 2 tot 8 stuks |
| 6.3 | Google Play feature graphic | 1024×500 PNG/JPG |
| 6.4 | Google Play icoon | 512×512 PNG |
| 6.5 | Website: kopbeeld en deelplaatje (Open Graph) | 1200×630 PNG |
| 6.6 | Website: illustraties van de zeven puzzels | Zelfde set als 2, groter |

## Aanleveren

Zet de bestanden in `docs/brand/` met de nummers hierboven in de naam (bijvoorbeeld
`2.3-stars.svg`). Daarna kan ik ze inbouwen: SVG wordt een vorm in code, of PNG
komt in de asset-catalogus van `PibblesUI` en in `Android/app/src/main/res`.
