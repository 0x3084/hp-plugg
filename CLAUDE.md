# HP-plugg – studieapp för högskoleprovet

En personlig pluggapp för högskoleprovet 10 april 2027. Mål: över 1,55 (arbetsmål 1,60).
Användaren pluggar ca 30 h/vecka (ca 65 % verbalt) och jobbar skift som roterar mellan
vecka A (förmiddag) och vecka B (eftermiddag). Allt UI är på svenska.

## Filer

- `index.html` – hela appen i en fil: HTML, CSS och vanilla JavaScript. Inga byggsteg, inga beroenden.
- `manifest.webmanifest`, `sw.js`, `icon-*.png`, `apple-touch-icon.png` – gör appen installerbar (PWA) och offlinekapabel. Höj `CACHE` i `sw.js` när filer byts ut.
- `README.md` – instruktioner för användaren.
  Enda externa resursen är Google Fonts (Bricolage Grotesque, Atkinson Hyperlegible).

## Köra lokalt

Starta en lokal server (krävs för offlineläget):

```bash
npx serve .
```

## Struktur i `index.html`

Skriptet är uppdelat i block med kommentarer `/* ---------- namn ---------- */`:

1. **Data**: `SUBJ` (de 8 delproven med veckobudget i timmar), `SCHED` (dagsscheman för vecka A, B och söndag),
   `PERIODS` (sexmånadersplanen), `FIRSTWEEK`, `MATH`, `LEIT` (Leitner-intervall i dagar),
   `FORMAT` (provformat), `GUIDE` (passinstruktion per ämne och fas), `DELPROV` (strategier),
   `MATHSHEET`, `MORE` + `STARTWORDS` (ORD-paketet, ca 450 ord, format `ord|betydelse;`),
   `OLDEXAMS`, `GEN` (generatorer för snabbräkning).
2. **Datumhjälp**: `ymd`, `parse`, `isoWeek`, `monday` med flera. Datum lagras som `"YYYY-MM-DD"` i lokal tid.
3. **State**: allt ligger i objektet `S`, se datamodellen nedan.
4. **Vyer**: `vIdag`, `vVecka`, `vOrd`, `vMaterial`, `vLogg`, `vPlan`. Varje vy returnerar en HTML-sträng.
5. **Render**: `render()` skriver om `#app` helt. Flikarna styrs av `location.hash` (`#idag`, `#vecka` …).
6. **Händelser**: en delegerad `click`- och en `change`-lyssnare på `#app` som går på `id` och `data-*`-attribut.

## Datamodell (`S`)

```js
{
  v: 1, updated: <ms>,
  sessions: [{id, date, subj, min}],          // loggad studietid; subj är en nyckel i SUBJ
  errors:   [{id, date, s, t, n}],            // felanalys: ämne, feltyp (ERRT), anteckning
  results:  [{date, kv, ve, typ, act}],       // uppföljning varannan söndag, rätt av 80
  cards:    [{id, w, m, box, due}],           // ORD-kort; box 0 = ej påbörjat, 1–5 = Leitner-låda
  first: {index: bool}, math: {namn: {seen, done}},
  settings: {exam, override: {"<måndag YYYY-MM-DD>": "A"|"B"}, sound, perDay},
  timer: {subj, start, plan, rang} | null,
  exams: {"<provdatum>": {done, kv, ve}},
  drill: {rounds, best: {score, sec}},
  pack, packAuto, newDay, newCount
}
```

- Veckotyp: udda ISO-vecka = A, jämn = B, om inte `settings.override` säger annat.
- Nya ORD-kort släpps in med `settings.perDay` per dag (standard 20), räknat i `newDay` och `newCount`.
- `fix()` migrerar äldre state och lägger in ORD-paketet automatiskt första gången.

## Lagring

- Sparas alltid i `localStorage` under nyckeln `hp-plugg-v1`.
- På claude.ai finns dessutom `window.claude` med en `db`- och en `user`-funktion. Då synkas hela `S`
  som JSON-sträng till dokumentet `data/users/<id>/plugg`. Utanför claude.ai finns inte `window.claude`.
  Koden hoppar då över synken och kör bara på `localStorage`. Behåll den kontrollen.
- Ändras datamodellen ska `defaults()` och `fix()` uppdateras så att gammal data fortfarande laddas.

## Konventioner

- Färger är CSS-variabler på `:root` med mörkt läge via `prefers-color-scheme` och `data-theme`.
  Verbalt är blått (`--verb`), kvant är grönt (`--kvant`), gult (`--pencil`) är accent.
- Bubbelraderna under Vecka ser ut som ett svarsformulär: varje ring är 30 minuter.
- Svensk typografi i synlig text: ’ för apostrof och ” ” för citat. Raka citattecken bara i kod.
- Escapa all användartext med `esc()` innan den hamnar i HTML.
- Ingen provtext från riktiga högskoleprov får läggas in. Den är upphovsrättsskyddad. Länka till studera.nu i stället.

## Idéer för vidare arbete

- Synk mellan enheter (t.ex. en liten egen backend), eftersom datan nu bara finns i webbläsaren.
- Diagram över studietid per vecka.
- Fler ord i `MORE` (håll formatet `ord|betydelse;` och inga dubbletter).
