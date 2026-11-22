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
   ook zonder internet. De server kent dezelfde puzzels via een weekpakket dat een
   Swift-commando maakt (`Tools/PackBuilder`) en dat de beheerder vooraf kan bekijken.
6. **Reeks**: een dag telt als je minstens één puzzel van die dag oplost.
7. **Bediening met tikken, niet slepen**: een blok kiezen en op het veld tikken. Slepen
   met een vinger werkt via Skip op Android niet zeker en was in het prototype ongetest.
8. **Systeemlettertype (afgerond) in plaats van Poppins en Inter**: geen bestanden van
   buiten gedownload. Poppins en Inter kunnen later in de pakketbronnen.
9. **Eén Cloudflare Worker voor pibbles.app**: website, API (`/api/...`) en ranglijst
   in D1. Niet uitgerold: uitrollen naar het echte domein laat ik aan de eigenaar.
10. **Geen advertenties en geen aankoop in deze ronde**; het onderzoek daarnaar staat in
    `docs/verdienmodel.md` (aparte sessie).
