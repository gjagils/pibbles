# Beslissingen

Keuzes die zonder de eigenaar zijn gemaakt (nacht van 22 op 23 november 2026). Elk punt
mag worden teruggedraaid; de reden staat erbij.

1. **"netflix" gelezen als Android.** De opdracht zei "ios als netflix"; `HANDOFF.md`
   noemt App Store en Google Play. Er is gebouwd voor iOS en Android.
2. **Vier puzzelsoorten, genoemd naar de kramen op het stijlbord**: Blocks (Randsom),
   Logic, Patterns, Numbers. Logic is een binaire puzzel, Patterns een plaatjespuzzel met
   getallen langs de rand, Numbers een getallenvierkant met groter-dan-tekens. Het zijn
   bekende genres met eigen regels en eigen code; geen bestaande app nagebouwd.
   Details in `docs/puzzels.md`.
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
