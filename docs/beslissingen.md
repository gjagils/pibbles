# Beslissingen

Keuzes die zonder de eigenaar zijn gemaakt (nacht van 22 op 23 november 2026). Elk punt
mag worden teruggedraaid; de reden staat erbij.

1. **"netflix" gelezen als Android.** De opdracht zei "ios als netflix"; `HANDOFF.md`
   noemt App Store en Google Play. Er is gebouwd voor iOS en Android.
2. **Zeven puzzels in vier kramen.** De eigenaar speelde zes opties (`docs/keuze/`) en
   koos ze alle zes. De kramen van het stijlbord zijn groepen: Blocks (Blocks), Logic
   (Duo, Stars), Patterns (Pixels, Links), Numbers (Signs, Sums). Het zijn bekende genres
   (binaire puzzel, Star Battle, plaatjespuzzel, Numberlink, getallenvierkant met tekens of
   sommen) met eigen namen, eigen uiterlijk en eigen code. Duo lijkt op LinkedIns Tango en
   Stars op LinkedIns Queens: spelregels zijn niet beschermd, namen en vormgeving wel, dus
   die zijn eigen (geen zon/maan, geen kroontjes). Geen juridisch advies; laat dit nakijken
   voor de lancering. Details in `docs/puzzels.md`.
3. **App-taal Engels** (de naam en het stijlbord zijn Engels); documentatie Nederlands.
4. **Bundle-id en applicationId `app.pibbles`**, afgeleid van het domein pibbles.app.
5. **Puzzel van de dag volgt uit de datum**: zelfde datum, zelfde puzzel op elk toestel,
   ook zonder internet. De server kent dezelfde puzzels via een weekpakket dat
   `Tools/PackBuilder` maakt; de beheerder bekijkt het vooraf op
   `/admin/week/<maandag>?key=…`. De app haalt nog niets van de server op behalve de
   ranglijst: dezelfde datum geeft toch dezelfde puzzel. Het automatisch maken op zondag
   (een geplande taak op de Mac of in CI) is nog niet ingericht.
6. **Reeks**: een dag telt als je minstens één puzzel van die dag oplost.
7. **Blocks: slepen, met tikken als reserve** (aangepast 23 november op verzoek). Eén
   sleepgebaar over veld en bak, het blok zweeft boven de vinger; werkt op iOS en Android.
8. **Poppins en Inter** (aangepast 23 november): de bestanden uit `docs/brand/` staan in
   de pakketbronnen en op de website.
9. **Eén Cloudflare Worker voor pibbles.app**: website, API (`/api/...`) en ranglijst
   in D1. Niet uitgerold: uitrollen naar het echte domein laat ik aan de eigenaar.
10. **Geen advertenties en geen aankoop in deze ronde**; het onderzoek daarnaar staat in
    `docs/verdienmodel.md` (aparte sessie).
11. **App-icoon en logo: het icoon dat de eigenaar stuurde** (`docs/brand/`); de hoeken
    zijn door mij met paars opgevuld. De overige iconen en het landschap zijn vormen in
    code, tot er echt ontwerp is (`docs/beeldmateriaal.md`).
12. **Links: een lijn mag zichzelf niet raken** (geen 2×2-blok van één kleur). Zo is de
    oplossing uniek; een volle maar "kronkelende" lijn telt niet als oplossing.
13. **Ranglijstnaam standaard "Player"/"Speler"**; aanpasbaar op het tabblad Ranglijst.
    Uitslagen die niet verstuurd konden worden, gaan later alsnog (alleen vandaag/gisteren
    telt voor de server).
14. **Hint = één goed stuk erbij** (Blocks: een blok op een goede plek; Stars: een ster;
    Links: een hele lijn; de rest: één vak). Elke hint kost 30 s in de ranglijst.
15. **Kleuren in donkere modus** volgen het stijlbord (donkere kolom). Kraam Numbers en
    Signs zijn blauw, zoals de Numbers-tegel op het stijlbord.
16. **Gepusht en de website uitgerold op verzoek van de eigenaar** (23 november); de
    winkels blijven bij hem.
17. **Regels alleen de eerste keer per puzzelsoort**; daarna via de knop Regels. De klok
    loopt pas als de regels dicht zijn en staat stil zolang ze open zijn.
18. **Een begonnen puzzel wordt bewaard** (bord, hints en tijd per soort en dag). Weggaan of
    de app op de achtergrond zetten pauzeert de klok; terugkomen gaat verder.
19. **Stars: dubbeltik is een ster, enkel tikken of slepen zet een stip** (op verzoek).
20. **Eén beginscherm Vandaag, geen tab Markt** (23 november, met de eigenaar). Het scherm houdt
    het panorama en de kraamkaarten uit de markt; in elke kaart staan de puzzels van vandaag
    met hun stand (Speel, Verder, tijd). De kaart "Puzzel van vandaag" is weg: de puzzel om
    mee verder te gaan (begonnen, anders de eerste open) krijgt een rand en een gevulde knop.
    "Week ›" opent de kraam met weekoverzicht en regels. Puzzeltegels krijgen hier de kleur
    van hun kraam. Reeks en jokers blijven één geheel voor de hele app.
21. **Eerste testversies 0.1 (1)** (23 november, op verzoek van de eigenaar).
    - App Store Connect: app "Pibbles", bundle-ID `app.pibbles`, SKU `pibbles`, hoofdtaal
      Engels (VS); Nederlands komt als vertaling. Upload naar TestFlight via Xcode (Apple-account
      in Xcode → Settings → Accounts).
    - Google Play: app "Pibbles", pakket `app.pibbles`, Game, kosteloos (past bij het
      verdienmodel: gratis met advertenties of aankoop), Engels (VS). Interne test met de
      testerslijst "Pibbles". Uploadsleutel `~/.android-keys/pibbles-upload.jks`, wachtwoorden
      in `~/.gradle/gradle.properties` (zoals Hoeveelishet). Bewaar die sleutel: zonder kan er
      geen update meer naar Google Play.
    - Persoonlijk Play-account: openbaar publiceren vraagt eerst een gesloten test van 14 dagen
      met minstens 12 testers.
22. **Na het oplossen: uitslag met penseelcirkel en ranglijst** (23 november, met de eigenaar).
    De penseelring uit het logo schildert zich (masker dat met de klok mee groeit vanaf
    linksonder), met je plaats van vandaag erin; daaronder tijd, hints, reeks en de top 4
    (of top 3 plus jouw rij). Offline staat je tijd in de ring. Knoppen: "Hele ranglijst"
    (opent die puzzel op het tabblad Ranglijst) en "Volgende: …". "Bekijk bord" sluit de
    uitslag; een balk opent hem weer. Archiefdagen hebben geen ranglijst.
