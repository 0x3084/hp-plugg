# HP-plugg – lokal version

Pluggappen för högskoleprovet som fristående webbapp. Den fungerar utan Claude, offline efter första
besöket och går att installera på hemskärmen. All data sparas i webbläsaren på enheten.

## Köra på datorn

Du kan dubbelklicka på `index.html`, men då fungerar inte offlineläget. Kör hellre en lokal server:

```bash
cd hp-plugg-lokal
npx serve .
```

Öppna sedan adressen som visas, till exempel http://localhost:3000.

## Få den på iPhone som app

Mobilen kommer inte åt filerna på datorn, så appen behöver ligga på nätet. Enklast är GitHub Pages (gratis):

1. Skapa ett konto på github.com och ett nytt **publikt** repo, till exempel `hp-plugg`.
2. Ladda upp alla filer i den här mappen via **Add file → Upload files**.
3. Gå till **Settings → Pages** och välj **Deploy from a branch** med grenen `main` och mappen `/ (root)`.
4. Efter någon minut ligger appen på `https://<ditt-namn>.github.io/hp-plugg/`.
5. Öppna adressen i **Safari** på iPhone, tryck på dela-knappen och välj **Lägg till på hemskärmen**.

Appen öppnas då i helskärm med egen ikon och fungerar offline.

## Flytta över din data från claude.ai

1. Öppna appen på claude.ai och gå till **Plan → Visa säkerhetskopia**.
2. Kopiera all text i rutan.
3. I den lokala versionen: gå till **Plan → Visa säkerhetskopia**, klistra in och tryck **Läs in från rutan**.

## Säkerhetskopiera

Datan finns bara i webbläsaren på enheten. Om du rensar Safaris data försvinner den. Tryck därför
**Plan → Ladda ner som fil** då och då och spara filen i iCloud Drive eller på datorn.

## Bygga vidare med Claude Code

Öppna mappen i Claude Code. `CLAUDE.md` förklarar hur appen är uppbyggd.
