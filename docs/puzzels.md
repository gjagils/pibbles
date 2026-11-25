# Puzzels: regels, generator, gegevens

Alle puzzels staan in `Packages/PibblesCore`, met tests, en volgen deze afspraken.

Zeven soorten, in vier kramen: Blocks (Blocks), Logic (Duo = `logic`, Stars), Patterns
(Pixels = `patterns`, Links), Numbers (Signs = `numbers`, Sums).

## Gemeenschappelijk

- **Dag**: `PuzzleCalendar.dayNumber` telt dagen sinds maandag 5 januari 2026 (dag 0).
  Weekdag = dag mod 7, maandag 0, zondag 6. Datumsleutel `yyyy-MM-dd`.
- **Moeilijkheid** loopt op van maandag naar zondag; per soort een tabel van zeven niveaus.
- **Seed**: Blocks gebruikt de datumsleutel (gelijk aan het prototype); de andere soorten
  `"<soort>|<datumsleutel>"`, bijvoorbeeld `logic|2026-11-23`.
- **Zelfde seed, zelfde puzzel op iOS en Android.** Alleen `SeededRandom` gebruiken; geen
  `Set`/`Dictionary`-volgorde laten meetellen (Swift husselt die per proces); geen
  `Double`-rekenwerk behalve `random.next() < x` en `random.nextInt(n)`. Een test legt
  per soort en niveau de uitkomst van een vaste seed vast; die test draait ook in Kotlin.
- **Precies één oplossing**, bewezen door de eigen oplosser van de soort.
- **Ranglijstscore**: tijd in ms + 30 000 per hint (`Ranking.score`).
- **JSON** (weekpakket, server): elk puzzeltype is `Codable` met precies de velden
  hieronder; cellen rij voor rij, index = rij × breedte + kolom.

## Blocks (Randsom)

Zie `HANDOFF.md`. JSON: `{"size":5,"pieces":["I4v",...],"rows":[...],"cols":[...],"solution":[...]}`.
Controle: elk blok ligt binnen het veld op `solution[i]`, geen overlap, tellingen kloppen.

## Logic (binaire puzzel)

Vul elk vak met 0 of 1. Per rij en kolom evenveel nullen als enen; nergens drie gelijke
naast of onder elkaar. Niveaus: 6, 6, 8, 8, 8, 8, 8. JSON:
`{"size":6,"givens":[-1,0,1,...],"solution":[0,1,...]}` (`-1` = leeg).

## Patterns (plaatjespuzzel)

Kleur vakken; per rij en kolom staan de lengtes van de aaneengesloten gekleurde stukken,
op volgorde. Niveaus (vierkant): 5, 5, 6, 6, 6, 6, 6. JSON:
`{"size":5,"rowClues":[[2,1],[5],[]...],"colClues":[...],"solution":[0,1,...]}`.
Een lege rij heeft `[]`.

## Numbers (getallenvierkant met tekens)

Vul een n×n-veld met 1..n, in elke rij en kolom elk getal één keer. Tussen sommige
buurvakken staat een teken: `{"lo":3,"hi":4}` betekent waarde(vak 3) < waarde(vak 4).
Niveaus: 4, 4, 5, 5, 5, 6, 6. JSON:
`{"size":4,"givens":[0,2,0,...],"relations":[{"lo":3,"hi":4}],"solution":[...]}` (`0` = leeg).

## Stars

Zet in elke rij, elke kolom en elk gebied precies één ster; sterren raken elkaar nergens,
ook niet schuin. Het veld is n×n met n gebieden. Niveaus: 5, 5, 6, 6, 6, 7, 7. JSON:
`{"size":6,"regions":[0,0,1,...],"solution":[5,2,4,1,3,0]}` (`regions`: gebied per vak,
0..n-1; `solution`: de kolom van de ster per rij).

## Links

Verbind de twee stippen van elke kleur met een pad van buurvakken (horizontaal of
verticaal); paden kruisen niet en vullen samen het hele veld. Niveaus: 5, 5, 6, 6, 6, 7, 7.
JSON: `{"size":6,"ends":[-1,0,...],"solution":[[9,3,4,5],[7,13,...],...]}` (`ends`: kleur
van de stip per vak, -1 = geen stip, elke kleur precies twee keer; `solution`: per kleur de
vakken van het pad, van stip tot stip).

## Sums

Vul een n×n-veld met 1..n, in elke rij en kolom elk getal één keer; de getallen in een
omlijnd blok tellen op tot de som van dat blok, en in een blok staat elk getal hooguit één
keer (sinds 25 november 2026). Niveaus: 4, 4, 5, 5, 5, 6, 6. JSON:
`{"size":5,"cages":[4,4,9,...],"sums":[11,4,...],"solution":[...]}` (`cages`: bloknummer
per vak, 0..k-1; `sums`: som per blok).
