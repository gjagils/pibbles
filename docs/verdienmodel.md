# Verdienmodel van Pibbles: aanpak

Onderzoek van 22 november 2026. Alle bronnen zijn die dag opgehaald; de datum achter een
bron is de datum die de pagina zelf noemt ("z.d." = de pagina toont geen datum). Er is
niets gebouwd en er zijn geen accounts aangemaakt. Wat niet is nagekeken staat in
[hoofdstuk 8](#8-niet-geverifieerd).

## 1. Aanbeveling

1. **Gratis app met advertenties van Google AdMob**, zonder tweede netwerk. Eén
   schermvullende advertentie nadat de puzzel is opgelost, en een vrijwillige
   beloningsadvertentie voor een extra hint of een archiefpuzzel. Geen advertentie bij het
   openen van de app en geen banner tijdens het puzzelen.
2. **Eén eenmalige aankoop "Geen advertenties + archief"** (voorstel: € 2,99) via de
   App Store en Google Play. Meld je aan voor het kleinebedrijventarief van Apple (15%).
3. **Vrienden krijgen een code van de winkel zelf**: bij Apple een gratis *offer code*
   op de aankoop, bij Google een promotiecode. De aankoop komt dan gewoon via de winkel
   binnen, dus de app en de server hoeven vrienden niet apart te kennen. **Bouw geen eigen
   codeveld**: Apple wijst dat af (richtlijn 3.1.1).
4. **Verwacht weinig van de advertenties.** Bij 100 dagelijkse spelers gaat het om
   ongeveer € 15 per maand, bij 1.000 om ongeveer € 150. De aankoop levert bij deze
   aantallen waarschijnlijk meer op dan de advertenties. Het werk zit vooral in de
   verplichte toestemmingsmelding, de privacyverklaring en de formulieren van de winkels.
5. **Zakelijk**: zodra de app geld verdient, sta je in de EU als handelaar in beide
   winkels met een openbaar adres, en speelt de vraag over KvK en btw. Leg dat één keer
   voor aan een boekhouder voordat je de overeenkomsten tekent.

## 2. Stappen in volgorde

### A. Zelf regelen, kan nu al (geen code nodig)

| # | Wat | Waarom / toelichting |
|---|---|---|
| A1 | Beslis over KvK en btw (zie 4.4) en vraag een boekhouder naar de btw-behandeling | Apple en Google vragen je handelaarsstatus; inkomsten zijn belast |
| A2 | Kies het adres dat openbaar wordt | Google toont bij een persoonlijk account dat geld verdient je volledige adres; Apple toont adres of postbus, telefoon en e-mail op de EU-productpagina |
| A3 | Apple: teken de *Paid Apps Agreement* in App Store Connect, vul bank- en belastinggegevens in (W-8BEN), geef de DSA-handelaarsstatus op | Zonder deze overeenkomst kun je geen aankoop aanmaken |
| A4 | Apple: meld je aan voor het *App Store Small Business Program* | 15% in plaats van 26% commissie; aanmelden is verplicht, het gaat niet vanzelf |
| A5 | Google Play: betalingsprofiel aanmaken, aanmelden voor de 15%-regeling | Nodig om iets te verkopen; welk tarief in de EU geldt is onduidelijk (zie 4.2) |
| A6 | AdMob-account aanmaken (persoon of organisatie, land staat daarna vast), betaalgegevens invullen | Identiteitscontrole en later een pincode per post op je adres |
| A7 | Website op pibbles.app met privacyverklaring (Nederlands en Engels) | Verplicht voor Google Play, voor de toestemmingsmelding en voor AdMob |

### B. Bouwen (na het speelscherm en de server, zoals in `HANDOFF.md`)

| # | Wat |
|---|---|
| B1 | In `PibblesCore`, tests eerst: de toestand "gekocht / niet gekocht / onbekend" en de regels "mag er een advertentie komen" en "mag dit archief open" |
| B2 | Aankoop in `PibblesUI` met de Skip-module `skip-marketplace`: kopen, herstellen, bij elke start de aankopen opvragen |
| B3 | Knop "Code inwisselen" in de instellingen: op iOS het inwisselscherm van Apple, op Android een link naar Google Play |
| B4 | AdMob, de toestemmingsmelding (UMP) en op iOS de trackingvraag (ATT) in de app-schillen `iOS/` en `Android/`, met testadvertenties |
| B5 | Knop "Privacykeuzes" in de instellingen (verplicht als de toestemmingsmelding dat aangeeft) |

### C. Bij de eerste release

| # | Wat |
|---|---|
| C1 | Aankoop aanmaken in App Store Connect en Play Console en laten goedkeuren |
| C2 | Winkelpagina's: pibbles.app als website van de ontwikkelaar; bij Google "Bevat advertenties: ja", het formulier Gegevensveiligheid en de doelgroep (13+ of 16+); bij Apple de privacylabels en de leeftijdsvragenlijst |
| C3 | App in AdMob koppelen aan de winkelpagina (controle duurt meestal 2 tot 3 dagen), daarna `app-ads.txt` op `https://pibbles.app/app-ads.txt` zetten met de regel die AdMob geeft |
| C4 | Codes voor vrienden aanmaken: minstens drie dagen voor het uitdelen (zie 5.1) |

## 3. Advertenties

### 3.1 Welk netwerk

| Netwerk | Drempel om te beginnen | Uitbetaling vanaf | Los te gebruiken |
|---|---|---|---|
| **Google AdMob** | Geen minimale omvang; elke app wordt beoordeeld en moet in een winkel staan | **€ 70** | Ja |
| AppLovin MAX | Account moet worden goedgekeurd; W-8-belastingformulier verplicht | $ 100 | Ja, maar bedoeld om meerdere netwerken te bundelen |
| Unity Ads / LevelPlay | Geen drempel gevonden | $ 100, 60 dagen later | Ja |
| Meta Audience Network | Werkt alleen via een bundelaar (MAX, LevelPlay, AdMob) | niet nagekeken | Nee |

AdMob is de keuze: laagste uitbetaalgrens, één SDK en een eigen toestemmingsmelding.
Meerdere netwerken bundelen loont pas bij veel meer spelers.

Bronnen: [AdMob-betaalgrenzen](https://support.google.com/admob/answer/2772208) (z.d.,
steekproef bevestigd: € 70), [AdMob app-gereedheid](https://support.google.com/admob/answer/10564477)
(z.d.), [AppLovin-betalingen](https://support.applovin.com/en/max/faq/faq-applovin-monetization-payment)
(z.d.), [Unity-betalingen](https://support.unity.com/hc/en-us/articles/6192555249940)
(25 juli 2025).

### 3.2 Wat je nodig hebt voor AdMob

- **Account**: Google-account, land (later niet te wijzigen), persoon of organisatie,
  naam en betaaladres, telefooncontrole. Identiteitscontrole direct; een pincode per post
  zodra er ongeveer $ 10 verdiend is. ([aanmelden](https://support.google.com/admob/answer/7356219),
  [verificatie](https://support.google.com/admob/answer/2772513), z.d.)
- **Belasting**: Google zegt dat niet elke uitgever belastinggegevens hoeft op te geven;
  het account laat zien of jij een W-8BEN moet invullen.
  ([Payments Center](https://support.google.com/paymentscenter/answer/10349995), z.d.)
- **App in een winkel**: volledige advertenties pas als de app in de App Store of Google
  Play staat en door AdMob is beoordeeld. Tot die tijd testadvertenties.
- **`app-ads.txt`**: tekstbestand in de hoofdmap van de website die op de winkelpagina
  als website van de ontwikkelaar staat, dus `https://pibbles.app/app-ads.txt`. Eén regel
  in de vorm `google.com, pub-…, DIRECT, …`; AdMob geeft de exacte regel. Controle binnen
  24 uur. ([app-ads.txt](https://support.google.com/admob/answer/9363762), z.d.)
- **Privacyverklaring**: openbare webpagina (geen pdf), gelinkt op de winkelpagina en in
  de app, die elke partij noemt die persoonsgegevens krijgt.
  ([Play-beleid gebruikersgegevens](https://support.google.com/googleplay/android-developer/answer/9859455), z.d.)
- **Btw op advertentie-inkomsten**: Google Ireland betaalt uit en zegt dat de btw is
  verlegd naar de ontvanger. ([AdMob over btw](https://support.google.com/admob/answer/4382717), z.d.)

### 3.3 Verplichte toestemming in de EU

- **Toestemmingsmelding**: Googles EU-beleid eist geldige toestemming voor het opslaan
  van gegevens op het toestel en voor gepersonaliseerde advertenties. Sinds 16 januari
  2024 levert Google in de EU alleen gepersonaliseerde advertenties via een gecertificeerde
  toestemmingsmelding; zonder krijg je hooguit "beperkte advertenties" (minder opbrengst).
  ([EU-toestemmingsbeleid](https://www.google.com/about/company/user-consent-policy/),
  [eis gecertificeerde melding](https://support.google.com/admob/answer/13554116), z.d.)
- **Googles eigen melding (UMP)** is gecertificeerd en zit in AdMob onder *Privacy &
  messaging*. Zet de knop "Geen toestemming" op het eerste scherm aan: weigeren moet even
  makkelijk zijn als toestaan. ([UMP](https://support.google.com/admob/answer/10113207), z.d.)
- **Apple App Tracking Transparency**: de vraag is alleen verplicht als je de gebruiker
  wilt volgen of het advertentie-ID wilt lezen. Niet vragen mag; advertenties worden dan
  nog steeds getoond, zonder advertentie-ID. Google raadt aan eerst de toestemmingsmelding
  te tonen en daarna de vraag van Apple.
  ([Apple privacy](https://developer.apple.com/app-store/user-privacy-and-data-use/), z.d.;
  [Google iOS-strategie](https://developers.google.com/admob/ios/privacy/strategies), z.d.)
- **Winkelformulieren**: Apple-privacylabels (ook voor wat de advertentie-SDK verzamelt:
  toestel-ID, advertentiegegevens, grove locatie, gebruik), Google Gegevensveiligheid,
  "Bevat advertenties" en de doelgroep.
  ([Google over iOS-gegevens](https://developers.google.com/admob/ios/privacy/data-disclosure), z.d.)
- **Kinderen**: richt de app op 13+ of 16+. Met kinderen in de doelgroep geldt het
  gezinsbeleid van Google Play, met strengere eisen aan advertenties.
  ([Play-gezinsbeleid](https://support.google.com/googleplay/android-developer/answer/9893335), z.d.)

Keuze voor de eigenaar (zie hoofdstuk 7): met toestemming gepersonaliseerde advertenties,
of altijd alleen niet-gepersonaliseerde. Het tweede is eenvoudiger uit te leggen, maar de
melding blijft nodig en de opbrengst is lager.

### 3.4 Advertentievormen bij één puzzel per dag

| Vorm | Past het? | Regel |
|---|---|---|
| Schermvullend na het oplossen | Ja, bij de overgang naar het resultaat | Alleen op een natuurlijk rustpunt, niet bij starten of afsluiten, niet midden in een taak |
| Beloning (vrijwillig) | Ja, voor een hint of een archiefpuzzel | Speler kiest zelf, beloning vooraf duidelijk, weigeren mag het spel niet hinderen |
| Bij openen van de app | Nee | Google raadt het aan voor apps die vaker dan eens per vier uur opengaan |
| Banner | Hooguit op het resultaatscherm | Mag, levert het minst op |

Bronnen: [beleid schermvullend](https://support.google.com/admob/answer/6201362),
[beloningsadvertenties](https://support.google.com/admob/answer/7313578),
[app-open](https://support.google.com/admob/answer/9341964),
[Play-advertentiebeleid](https://support.google.com/googleplay/android-developer/answer/9857753)
(alle z.d.).

Let op: als een beloningsadvertentie een archiefpuzzel opent, is het archief niet meer
alleen voor kopers. Dat is een keuze (hoofdstuk 7).

### 3.5 Wat het oplevert

Cijfers over opbrengst per duizend vertoningen komen alleen van leveranciersblogs en gaan
vooral over spellen; er is geen Nederlands cijfer gevonden.

| Bron | Regio | Schermvullend | Beloning | Banner |
|---|---|---|---|---|
| Appodeal Q4 2024 via [Playio](https://blog.playio.co/mobile-game-ecpm-benchmarks-2026) (5 okt 2026) | Europa | ca. $ 5,3 iOS / $ 3,6 Android | ca. $ 8,9 / $ 5,1 | niet gegeven |
| [Playwire](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect) (17 sep 2025) | wereldwijd | $ 2,50 – 5 | $ 8 – 18 | $ 0,20 – 0,80 |

Eigen rekensom (aanname: één schermvullende advertentie per speler per dag à $ 4,50 per
duizend, plus drie bannervertoningen à $ 0,30; marge voor weigeraars en lege vertoningen):

| Dagelijkse spelers | Per maand | Marge |
|---|---|---|
| 100 | ca. $ 15 | $ 6 – 24 |
| 1.000 | ca. $ 150 | $ 60 – 240 |
| 10.000 | ca. $ 1.500 | $ 600 – 2.400 |

Bij 100 spelers duurt het 3 tot 12 maanden voordat de uitbetaalgrens van € 70 is bereikt.

## 4. Afkopen: de eenmalige aankoop

### 4.1 Apple

- Eenmalige, blijvende aankoop (*non-consumable*) via StoreKit 2. Vereist: de *Paid Apps
  Agreement*, bankgegevens en een Amerikaans belastingformulier (buiten de VS: W-8BEN).
  ([overeenkomsten](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/),
  [belastinggegevens](https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information/), z.d.)
- Een knop **"Aankopen herstellen"** hoort erbij (richtlijn 3.1.1,
  [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
  bijgewerkt 16 okt 2026).
- **Commissie in de EU sinds 1 oktober 2026**: 26% standaard, 15% voor deelnemers aan het
  Small Business Program (tot $ 1 miljoen per jaar; aanmelden verplicht).
  ([Apple Newsroom](https://www.apple.com/newsroom/2026/08/apple-announces-changes-for-apps-in-the-european-union/),
  18 aug 2026, steekproef bevestigd; [Small Business Program](https://developer.apple.com/app-store/small-business-program/), z.d.)
- **Handelaarsstatus (DSA)**: wie in de EU geld verdient met aankopen of advertenties
  geldt als handelaar; adres of postbus, telefoonnummer en e-mail staan dan op de
  productpagina.
  ([DSA bij Apple](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/), z.d.)
- Gezinsdeling kan per aankoop aan en is daarna niet meer uit te zetten (niet rechtstreeks
  nagekeken).

### 4.2 Google Play

- Eenmalig product via de Play Billing Library; nieuwe apps moeten minimaal versie 8
  gebruiken, de nieuwste is 9.1.0 (18 juni 2026).
  ([release notes](https://developer.android.com/google/play/billing/release-notes),
  [uitfaseren](https://developer.android.com/google/play/billing/deprecation-faq))
- **Tarief: onduidelijk, 15% of 25%.** Sinds 30 juni 2026 rekent Google in de EU een
  servicetarief plus 5% betaalkosten. De tabel noemt "10% + 5%" bij de eerste $ 1 miljoen,
  maar volgens de kolomkoppen geldt dat voor abonnementen; voor andere aankopen staat er
  "20% + 5%" bij nieuwe installaties. Twee lezingen van dezelfde pagina kwamen verschillend
  uit. Reken voorzichtig met 25% en kijk het na in Play Console.
  ([servicetarieven](https://support.google.com/googleplay/android-developer/answer/112622), z.d.;
  [Android-blog](https://android-developers.googleblog.com/2026/06/play-expanded-billing.html), 24 juni 2026)
- **Openbaar adres**: "If you monetize on Google Play, Google displays your full address"
  bij een persoonlijk account.
  ([accounttypen](https://support.google.com/googleplay/android-developer/answer/13628312), z.d., steekproef bevestigd)
- Persoonlijke accounts van na 13 november 2023 moeten eerst een gesloten test met 12
  testers gedurende 14 dagen doen.
  ([testeis](https://support.google.com/googleplay/android-developer/answer/14151465), z.d.)
- De aankoop moet binnen drie dagen door de app worden bevestigd, anders betaalt Google
  hem terug. ([Billing integreren](https://developer.android.com/google/play/billing/integrate), z.d.)

### 4.3 Wat blijft er over van € 2,99

| | Apple (15%) | Google (15% of 25%) |
|---|---|---|
| Prijs | € 2,99 | € 2,99 |
| Zonder 21% btw | € 2,47 | € 2,47 |
| Voor jou | ca. € 2,10 | ca. € 2,10 of € 1,85 |

Over prijs en het aandeel kopers is geen actueel cijfer gevonden. Eén oud voorbeeld
(Breakout Ninja, [Game Developer](https://www.gamedeveloper.com/business/-i-breakout-ninja-i-dev-highlights-the-waning-appeal-of-ad-removal-iaps),
18 jan 2017): 0,08% van de downloads kocht de advertenties af. Het archief erbij maakt
het aanbod sterker dan alleen "geen advertenties".

### 4.4 Zakelijk in Nederland

- **KvK**: inschrijven moet als je zelfstandig werkt, er geld voor vraagt en regelmatig
  levert aan anderen dan familie en vrienden; er is geen omzetgrens. Een app die
  doorlopend verkoopt valt daar waarschijnlijk onder (eigen lezing). Kosten: € 85,15
  eenmalig. ([KvK: moet ik inschrijven](https://www.kvk.nl/starten/moet-ik-mijn-bedrijf-inschrijven-bij-kvk/),
  30 okt 2026; [inschrijfvergoeding](https://www.kvk.nl/inschrijven/inschrijfvergoeding/), 11 juni 2026)
- **Inkomstenbelasting**: de Belastingdienst beoordeelt per geval of je ondernemer bent;
  anders zijn het "inkomsten uit overig werk". Je kunt btw-ondernemer zijn zonder
  ondernemer voor de inkomstenbelasting te zijn.
  ([Belastingdienst](https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/ondernemen/onderneming_starten/weet-wanneer-u-ondernemer-bent), z.d.)
- **Btw**: Google int en betaalt de btw van EU-klanten zelf af
  ([Google over btw](https://support.google.com/googleplay/android-developer/answer/138000), z.d.).
  Een Nederlands adviesblog ([Holdwise](https://holdwise.nl/kennisbank/app-store-google-play-belasting),
  7 okt 2026) beschrijft de winkel als verkoper aan de klant en jou als leverancier van
  een dienst aan de winkel in Ierland: btw verlegd, opnemen in de aangifte en meestal een
  opgaaf ICP ([Ondernemersplein](https://ondernemersplein.overheid.nl/internationaal-ondernemen/douane-en-belastingen/btw-bij-diensten-in-het-buitenland/), z.d.).
  De Belastingdienst heeft geen pagina over appwinkels.
- **Kleineondernemersregeling**: grens € 20.000 per jaar. Voegt weinig toe als bijna alle
  omzet naar Ierland is verlegd (eigen inschatting).
  ([KOR](https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/btw/hoe_werkt_de_btw/nieuwe-kleineondernemersregeling/kleineondernemersregeling), z.d.)

## 5. Vrienden gratis

### 5.1 Wat de winkels bieden

| Weg | Platform | Aantal | Geldigheid | Oordeel |
|---|---|---|---|---|
| **Gratis offer code, eenmalig te gebruiken** | iOS | partijen van 500 tot 25.000; 1 miljoen per app per kwartaal | hooguit 6 maanden | **Aanbevolen** |
| Gratis offer code, eigen woord (bv. `VRIENDEN`) | iOS | tot 25.000 keer per partij | geen einddatum mogelijk | Eenvoudig, maar lekt: iedereen met de code kan hem inwisselen |
| Promotiecodes voor aankopen | iOS | – | – | **Gestopt op 26 maart 2026** |
| **Promotiecode, eenmalig te gebruiken** | Android | 500 per kwartaal per app | zelf te kiezen, hooguit 1 jaar | **Aanbevolen** |
| TestFlight / testers bij Google | beide | 10.000 / 2.000 | builds vervallen na 90 dagen; aankopen zijn testaankopen | Alleen om te testen |
| Gezinsdeling | iOS | het gezin van een koper | – | Aardige bijkomstigheid |

- Apple: offer codes gelden sinds eind 2025 voor alle soorten aankopen en mogen gratis
  zijn. De vriend heeft iOS 16.3 of nieuwer nodig, krijgt een link en wisselt in via de
  App Store of in de app. De app moet in de winkel staan en de aankoop moet zijn
  goedgekeurd. Daarna gedraagt de code zich als een echte aankoop: herstellen en opnieuw
  installeren werken.
  ([Apple-nieuws](https://developer.apple.com/news/?id=gf6mgrs6), 29 okt 2025, steekproef bevestigd;
  [offer codes aanmaken](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-offer-codes-for-in-app-purchases/), z.d.;
  [offer codes in de app](https://developer.apple.com/documentation/storekit/supporting-offer-codes-in-your-app), z.d.)
- Een forumbericht van april 2026 meldt dat gratis codes de eerste 48 tot 72 uur na het
  aanmaken een foutmelding gaven ([forum](https://developer.apple.com/forums/thread/824524),
  niet door Apple bevestigd). Maak ze dus een paar dagen vooraf aan.
- Google: codes voor eenmalige producten zijn altijd eenmalig te gebruiken; een eigen
  woord kan alleen bij abonnementen. Inwisselen via Google Play of
  `https://play.google.com/redeem?code=…`.
  ([promotiecodes](https://support.google.com/googleplay/android-developer/answer/6321495), z.d., steekproef bevestigd;
  [technische uitleg](https://developer.android.com/google/play/billing/promo), z.d.)

### 5.2 Mag een eigen uitnodigingscode via de eigen server?

- **Apple: nee.** Richtlijn 3.1.1: "Apps may not use their own mechanisms to unlock
  content or functionality, such as license keys". Er zijn afwijzingen bekend van apps met
  een eigen codeveld ([2023](https://developer.apple.com/forums/thread/736622),
  [februari 2026](https://developer.apple.com/forums/thread/817176); forumberichten).
  Een onzichtbare vlag op de server voor het toestel van een vriend valt bij de
  beoordeling niet op, maar is nog steeds een eigen manier om iets te ontgrendelen dat
  ook te koop is, en botst met het verbod op verborgen functies (2.5.19). Geen bron zegt
  uitdrukkelijk dat het mag of niet mag; dit is een inschatting.
- **Google: laag risico.** Het betalingsbeleid gaat over het aannemen van betaling voor
  functies; over gratis weggeven zegt het niets
  ([betalingsbeleid](https://support.google.com/googleplay/android-developer/answer/9858738), z.d.,
  pagina deels gelezen).

### 5.3 Aanbeveling

Gebruik op beide platforms de codes van de winkel. iOS: één partij van 500 gratis,
eenmalige codes (elk half jaar vernieuwen) en elke vriend een eigen link. Android: per
kwartaal zoveel codes als nodig uit de 500. In de app alleen een rij "Code inwisselen"
die het scherm van de winkel opent. Geen eigen codeveld en geen servervlag.

Gevolg: een vriend met Android en een vriend met iPhone krijgen elk een ander soort code,
en bij meer dan 500 Android-vrienden per kwartaal moet je wachten.

## 6. Techniek

### 6.1 Skip

- Skip is sinds 21 januari 2026 gratis en open source
  ([Skip-blog](https://skip.dev/blog/skip-is-free/), 21 jan 2026).
- **Aankopen**: de module [`skip-marketplace`](https://github.com/skiptools/skip-marketplace)
  (0.4.1, Apache-2.0) verpakt StoreKit 2 en Play Billing 9 en is volgens de eigen
  beschrijving het meest geschikt voor een eenmalige, blijvende aankoop. Herstellen is
  het opnieuw opvragen van de aankopen. Het inwisselen van codes zit er niet in.
- **Advertenties**: er is geen AdMob-module van Skip (wel `skip-applovin`). AdMob komt
  daarom in de handgeschreven app-schillen, zoals Firebase nu bij Hoeveelishet
  (`~/Github/hoeveelishet/Android/app/build.gradle.kts`, `MainActivity.kt`): Core biedt
  een aansluitpunt, de schil vult het in. Dat houdt de advertentie-SDK (die niet op macOS
  bouwt) buiten de pakketten die Skip eerst voor macOS bouwt.
  ([Skip: platformaanpassing](https://skip.dev/docs/platformcustomization/), z.d.)
- **Versies**: Google Mobile Ads voor iOS 13.13.0 (16 nov 2026, vraagt Xcode 26.2); op
  Android heet `play-services-ads` inmiddels "Legacy" en is er een opvolger
  (`ads-mobile-sdk`). Welke van de twee te nemen is nog niet uitgezocht.
  ([iOS release notes](https://developers.google.com/admob/ios/rel-notes),
  [Android next-gen](https://developers.google.com/admob/android/next-gen/quick-start))

### 6.2 Indeling

| Waar | Wat |
|---|---|
| `Packages/PibblesCore` | Toestand van de aankoop en de regels: wanneer een advertentie mag, wanneer het archief open mag. Tests eerst. Aansluitpunten voor "toon advertentie" en "aankoopstatus". |
| `Packages/PibblesUI` | Aankoopscherm via `skip-marketplace`, knoppen "Herstellen", "Code inwisselen" en "Privacykeuzes". Vraagt de regels aan Core. |
| `iOS/` en `Android/` | AdMob, toestemmingsmelding, trackingvraag van Apple; vullen de aansluitpunten in. |
| Website (pibbles.app) | Privacyverklaring en `app-ads.txt`. |

### 6.3 Wat de server bijhoudt

- **Eerste versie: niets over aankopen.** De winkel op het toestel zegt of de aankoop er
  is; terugbetaalde aankopen verdwijnen daar vanzelf. Vrienden met een code zijn voor de
  app gewone kopers.
- De server houdt bij wat `HANDOFF.md` al noemt: weekpakket, ranglijst, controle van
  tijden, met een anoniem toestel-ID zoals bij Hoeveelishet.
- Alleen als het archief door de server wordt uitgeleverd en dus daar beschermd moet
  worden: een tabel met toestel-ID, platform, aankoopkenmerk en status, gecontroleerd bij
  Apple en Google. De code om daarvoor te ondertekenen bestaat al in
  `~/Github/hoeveelishet/server/worker/src/push.js`.
- Als de puzzels uit de datum en een seed volgen, kan het archief ook op het toestel
  worden berekend en is die tabel niet nodig.

## 7. Open keuzes voor de eigenaar

1. **Prijs** van de aankoop (voorstel € 2,99) en of gezinsdeling aan gaat (niet terug te draaien).
2. **Wat het archief is voor niet-kopers**: helemaal dicht, of per puzzel te openen met een beloningsadvertentie.
3. **Banner** op het resultaatscherm: wel of niet.
4. **Gepersonaliseerde advertenties** met toestemming, of altijd niet-gepersonaliseerd.
5. **Trackingvraag van Apple** stellen (hogere opbrengst bij "ja") of weglaten.
6. **KvK-inschrijving** en welk **adres** openbaar wordt in beide winkels; eventueel een postbus.
7. **Doelgroep**: 13+ of 16+.
8. **Vrienden met een eigen woord** (makkelijk, alleen iOS, kan uitlekken) of met persoonlijke codes (aanbevolen).
9. Of de aankoop **later ook voor nieuwe puzzelsoorten** geldt; dat bepaalt de naam en de omschrijving van het product.

## 8. Niet geverifieerd

- **Googles tarief** voor een eenmalige aankoop in de EU (15% of 25%), en of de aanmelding voor de 15%-regeling daar nog iets doet.
- **Btw**: of Apple zelf de btw van EU-klanten afdraagt (geen Apple-pagina gevonden die het zegt), de precieze Nederlandse behandeling (rubriek, ICP, samenloop met de KOR). Alleen een adviesblog en de algemene regel; vraag een boekhouder.
- Of een Nederlandse AdMob-uitgever een **W-8BEN** moet invullen, en of Apple of Google van een particulier een btw- of KvK-nummer vragen.
- Of de bestaande Apple- en Google-accounts (van Hoeveelishet en SquashAnalyzer) al overeenkomsten voor betaalde apps, bank- en belastinggegevens hebben, en of het Google-account onder de testeis van 12 testers valt.
- Of het aanvaarden van Apples nieuwe EU-voorwaarden verplicht is; de laagste europrijs bij Apple; de pagina over gezinsdeling (gaf een fout).
- De regel "weigeren even makkelijk als toestaan" rechtstreeks bij de Autoriteit Persoonsgegevens (pagina's gaven een fout; alleen zoekresultaten gezien), en of die letterlijk voor apps geldt.
- Dat de toestemmingsmelding van Google gratis is (staat nergens uitdrukkelijk), en hoeveel opbrengst wegvalt zonder toestemming of zonder trackingvraag.
- **Opbrengstcijfers**: leveranciersblogs, vooral spellen, deels uit grafieken afgelezen; geen Nederlands cijfer. De rekensom is een eigen schatting.
- **Offer codes**: de pagina van Apple is deels via een samenvatting gelezen; dat een gratis code voor een blijvende aankoop werkt volgt uit het nieuwsbericht en de stap "Paid Offer or Free Offer", niet uit één zin. De vertraging van 48 tot 72 uur is een forumbericht. Of er commissie of kosten zijn bij een gratis code is niet gevonden (vermoedelijk niet).
- De risico-inschatting van een **servervlag** is een eigen lezing van de richtlijnen.
- **Techniek**: `skip-marketplace` is niet geprobeerd in deze repo en heeft versie 0.x; hoe "Code inwisselen" op Android precies vanuit de app opent; welke Android-advertentie-SDK (oud of opvolger); de volgorde van toestemming en het starten van de SDK.
- Beweringen met "steekproef bevestigd" zijn een tweede keer op de bron nagekeken; de overige berusten op één lezing.
