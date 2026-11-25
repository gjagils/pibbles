# Pibbles: overdracht

Deze map is alleen een transportmiddel. Hij hoort niet in Hoeveelishet en mag weg
zodra de inhoud in de repo `pibbles` staat. Deze branch wordt niet gemerged.

## Wat Pibbles is

Een app met dagelijkse puzzels voor de App Store en Google Play. Engelstalige naam,
gekozen door de eigenaar. Er komen later meer puzzelsoorten bij; het idee voor het
startscherm is een markt met per puzzelsoort een kraam. De eerste puzzel heet
**Randsom** (werknaam). Verdienmodel: advertenties, of een kleine aankoop die ze
weghaalt en het archief opent.

Speelbaar prototype: https://claude.ai/artifact/ABC9MUti6zUkWaT3QbFj8A
(privé; dezelfde code staat in `prototype/randsom.html`).

## Regels van Randsom

- Veld van n×n. Langs de rand staat per rij en kolom het aantal gevulde vakjes.
- De speler sleept een vaste set blokken het veld in. Draaien kan niet. Alle
  blokken moeten liggen en elk getal moet kloppen.
- Elke puzzel heeft precies één oplossing. De generator legt willekeurig blokken
  neer, leidt de getallen af en keurt de puzzel alleen goed als de oplosser bewijst
  dat er één oplossing is (gelijke blokken zijn onderling verwisselbaar).
- Kwaliteitsfilters: hooguit twee keer dezelfde vorm, geen lege rij of kolom
  (bij 4 blokken hooguit één).

## Weekritme

Elke dag één puzzel, oplopend van maandag naar zondag:

| ma | di | wo | do | vr | za | zo |
|---|---|---|---|---|---|---|
| 5×5, 4 | 5×5, 5 | 6×6, 5 | 6×6, 6 | 6×6, 7 | 6×6, 7 | 6×6, 8 |

Wens van de eigenaar: op zondag wordt het pakket van zeven puzzels voor de komende
week aangemaakt en klaargezet, zodat het vooraf te bekijken is. Het prototype
berekent de puzzel nog uit de datum.

## Reeks, jokers, ranglijst

- Elke opgeloste dag telt voor de reeks, ook met hints.
- Per 5 dagen reeks één joker, maximaal 3. Een gemiste dag kost een joker. Zijn er
  te weinig jokers, dan begint de reeks opnieuw; de jokers blijven.
- Ranglijst van vandaag: tijd plus 30 seconden per hint, laagste wint. Het
  resultaat van de dag staat vast na de eerste oplossing.
- De getallen 5, 3 en 30 zijn voorstellen en nog niet door de eigenaar bevestigd.

## Bestanden

- `prototype/logic.js`: vormen, weekschema, generator, oplosser, reeksregels. Puur,
  zonder DOM. Dit is wat naar Swift moet.
- `prototype/ui.js` en `prototype/head.html`: het speelscherm (slepen, hints,
  weekstrook, ranglijst via de opslag van de Claude-artifact).
- `prototype/randsom.html`: de samengevoegde pagina zoals gepubliceerd.
- `prototype/t.js`: `node t.js` meet de generator per weekdag en toont de reeksregels.
- `prototype/shot.js`: browsertest met Playwright en een nagebootste ranglijst.

## Voorgestelde opzet van de repo

Zelfde aanpak als Hoeveelishet en SquashAnalyzer:

1. `Packages/PibblesCore`: regels, generator, oplosser, weekschema en reeks in
   Swift, met tests eerst. Via Skip naar Kotlin, dus let op de Skip-valkuilen.
2. `Packages/PibblesUI`: het speelscherm. UI dupliceert geen regels.
3. Server (Cloudflare Worker, zoals bij Hoeveelishet): weekpakket, ranglijst en
   controle van ingestuurde tijden.
4. Daarna reeksen en statistieken in de app, en als laatste advertenties en de aankoop.

## Wat is getest en wat niet

- Getest: generator en uniciteit voor alle zeven niveaus (40 puzzels per niveau,
  geen mislukkingen; zondag duurt gemiddeld 0,2 s en hooguit ongeveer 1 s), de
  reeks- en jokerregels, en het scherm in een browser op telefoonformaat met een
  nagebootste ranglijst.
- Niet getest: slepen met een echte vinger, en de gedeelde opslag met een echte score.
- De moeilijkheid wordt gestuurd met veldgrootte en aantal blokken, niet gemeten.
- Tijden worden op het toestel gemeten en zijn te vervalsen.

## Nog open

- Naam: geen bestaande app of merk "Pibbles" gevonden via een zoekmachine;
  pibbles.app en playpibbles.com leken vrij. Nog zelf nakijken in App Store,
  Google Play, BOIP en EUIPO. "Pibble" is in het Engels een koosnaam voor een pitbull.
- De eigenaar vond de moeilijkheid goed; draaien van blokken is niet besproken.
- Randsom is een Nederlandse werknaam; voor een Engelse app is een Engelse
  puzzelnaam nodig.
