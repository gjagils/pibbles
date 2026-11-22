# pibbles.app: Worker voor website en API

Eén Cloudflare Worker (`wrangler.toml`) voor het domein pibbles.app:

- **Website**: alles in `public/` wordt als statisch bestand geserveerd (landingspagina,
  `/privacy/`, `/support/`, `favicon.svg`, `404.html`). Beveiligingskoppen staan in
  `public/_headers`. Geen scripts en geen lettertypen van buiten.
- **API** onder `/api/` en de **voorbeeldpagina** onder `/admin/`: alleen die paden
  starten de Worker (`run_worker_first`); de rest gaat rechtstreeks naar de bestanden.
- **D1** (`DB`): weekpakketten (`weeks`, `days`) en ranglijsten (`scores`). Schema in
  `migrations/`.

Zeven puzzelsoorten (`docs/puzzels.md`): `blocks`, `logic` (Duo), `stars`, `patterns`
(Pixels), `links`, `numbers` (Signs), `sums`. De JSON-sleutels zijn de soort-id's.

## Endpoints

| | |
|---|---|
| `GET /api/health` | `{"ok":true}` |
| `PUT /api/admin/week` | Weekpakket opslaan. Kop `Authorization: Bearer <ADMIN_KEY>`. 201 nieuw, 200 vervangen, 400 ongeldig (met reden), 401 verkeerde sleutel, 409 week al begonnen (vervangen kan dan met `?force=1`). |
| `GET /api/day/<datum>` | De zeven puzzels van die dag zonder `solution`. 403 als de dag nog nergens op aarde begonnen is (UTC+14), 404 als geen pakket de dag bevat; de app maakt de puzzel dan zelf. |
| `POST /api/scores` | `{date, kind, deviceId, name, ms, hints, solution}`. 201 opgeslagen, 200 als dit toestel al een resultaat had (dat blijft staan, `accepted:false`), 422 fout antwoord, 400/403 ongeldig. Antwoord: `{accepted, rank, name, ms, hints, score, verified}`. |
| `GET /api/scores/<datum>/<soort>?deviceId=…` | `{date, kind, total, top:[{rank,name,ms,hints,score,verified}], me}` (top 50; `me` is je eigen plaats of `null`). |
| `GET /admin/week/<maandag>?key=<ADMIN_KEY>` | HTML-voorbeeld van alle 49 puzzels van de week, met een schakelaar voor de oplossingen. |

Regels bij scores: score = ms + 30 000 × hints; tijden onder 3 s of boven 24 uur worden
geweigerd; alleen vandaag of gisteren (ruim genomen over alle tijdzones); alleen het eerste
resultaat per toestel, datum en soort telt. Staat de dag in een pakket, dan wordt het
antwoord nagerekend (`verified: true`); zonder pakket wordt de score bewaard met
`verified: false`. Naam: ingekort tot 20 tekens, leeg wordt "Player". `deviceId`: 8–64
tekens `A-Z a-z 0-9 -`.

## Lokaal

```bash
cd server
npm install
npm test                                     # node --test, met een nep-D1 op node:sqlite
echo 'ADMIN_KEY="lokaal-geheim-van-16+-tekens"' > .dev.vars
npx wrangler d1 migrations apply pibbles --local
npx wrangler dev                             # http://localhost:8787
```

`ADMIN_KEY` moet minstens 16 tekens zijn; korter wordt altijd geweigerd.

## Live zetten (eenmalig, door de eigenaar)

Er is nog niets aangemaakt of uitgerold; `database_id` in `wrangler.toml` is een
placeholder.

1. Inloggen: `cd server && npx wrangler login`
2. Database maken: `npx wrangler d1 create pibbles`
3. De `database_id` uit de uitvoer in `wrangler.toml` zetten (in plaats van de nullen).
4. Schema toepassen: `npx wrangler d1 migrations apply pibbles --remote`
5. Geheime sleutel zetten (lang en willekeurig, bijvoorbeeld uit `openssl rand -hex 24`):
   `npx wrangler secret put ADMIN_KEY`
6. Uitrollen: `npx wrangler deploy`
7. Domein: `wrangler.toml` vraagt pibbles.app al als custom domain aan (`routes`); de
   deploy koppelt het als de zone pibbles.app in hetzelfde Cloudflare-account staat.
   Controleer in het dashboard onder Workers & Pages → pibbles → Settings → Domains &
   Routes. Wil je ook `www.pibbles.app`, voeg dan een tweede route toe of maak een
   doorverwijsregel.
8. Het e-mailadres `hello@pibbles.app` op de site is een placeholder: zet mail op voor het
   domein (bijvoorbeeld Cloudflare Email Routing) of pas het aan in `public/`.

## Een weekpakket uploaden

Het pakket (`{"weekStart":"2026-11-23","days":[…7 dagen…]}`, vorm zoals in
`test/fixtures/week-2026-11-23.json`) komt straks uit `Tools/PackBuilder`.

```bash
curl -X PUT https://pibbles.app/api/admin/week \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "content-type: application/json" \
  --data-binary @week-2026-11-30.json
```

Daarna bekijken: `https://pibbles.app/admin/week/2026-11-30?key=<ADMIN_KEY>`. De sleutel
staat dan in de adresbalk en de browsergeschiedenis; de pagina stuurt geen referrer mee
en wordt niet geïndexeerd. Een week vervangen die al begonnen is kan alleen met
`?force=1` achter de upload-URL; scores die al zijn ingestuurd blijven dan staan.

## Controle bij upload

Maandag als `weekStart`, zeven opeenvolgende datums, per dag alle zeven soorten met de
velden uit `docs/puzzels.md` (extra velden worden weggelaten), en de meegestuurde
`solution` moet door de controle van de soort komen. Uniciteit van de oplossing wordt
niet gecontroleerd; dat bewijst de generator.

De fixture in `test/fixtures/` is met de hand gemaakt (Blocks uit de generator van
`prototype/logic.js`, de rest klein en willekeurig); de andere soorten zijn geldig maar
niet per se uniek oplosbaar.
