# ⚽ BuLi Tabelle – Bundesliga-Tabellen und DFB-Pokal für macOS

[![Version](https://img.shields.io/github/v/release/dmnktoe/buli-tabelle?label=Version&color=D20515&labelColor=1D1D1B)](https://github.com/dmnktoe/buli-tabelle/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/dmnktoe/buli-tabelle/total?label=Downloads&color=D20515&labelColor=1D1D1B)](https://github.com/dmnktoe/buli-tabelle/releases)
[![macOS](https://img.shields.io/badge/macOS-13%2B-D20515?logo=apple&labelColor=1D1D1B)](https://dmnktoe.github.io/buli-tabelle/)

**BuLi Tabelle** zeigt Bundesliga-Tabellen und den DFB-Pokal als native macOS-App
in Swift & SwiftUI — im Liquid-Glass-Look: durchscheinende Flächen über echtem
Fenster-Blur, Systemschrift, weiche Federn und voller Dunkelmodus.

## Was die App kann

- **Live-Tabellen** der 1. Bundesliga, 2. Bundesliga und 3. Liga über
  [OpenLigaDB](https://www.openligadb.de)
- **DFB-Pokal** als eigener Modus: alle Runden von der 1. Runde bis zum Finale,
  mit Paarungen, Ergebnissen und dem Sieger jeder Partie — auch wenn erst die
  Verlängerung oder das Elfmeterschießen entschieden hat. Noch nicht ausgeloste
  Runden werden als solche ausgewiesen.
- **Zeitreise:** Tabelle für jeden Spieltag jeder Saison seit 2004/05 — lokal aus
  den Spielergebnissen berechnet (Punkte, Tordifferenz, erzielte Tore)
- **Auf- und Abstiegszonen** als farbige Balken am Zeilenrand, mit Legende
  (Champions League, Europa League, Relegation, Abstieg)
- Ausklappbarer **Spieltag-Bereich** mit allen Paarungen und Ergebnissen
- **Torjägerliste** der gewählten Saison
- Tabelle als **HTML exportieren**, **kopieren** oder direkt **drucken**
- **Menüleisten-Modus:** Das ⚽-Symbol zeigt eine Kompakt-Tabelle.
  Wer das Fenster schließt, behält die App in der Menüleiste (das Dock-Icon
  verschwindet) — „Fenster öffnen" holt sie zurück, „Beenden" beendet wirklich.
  Beides lässt sich in den Einstellungen abschalten.
- **Automatische Updates** über [Sparkle](https://sparkle-project.org):
  „Update suchen…" prüft einen signierten Appcast und installiert neue
  Versionen von selbst

## Download

Fertige Builds gibt es auf der **[Downloadseite](https://dmnktoe.github.io/buli-tabelle/)**
— automatisch gespeist aus dem neuesten Release — oder direkt unter
[Releases](https://github.com/dmnktoe/buli-tabelle/releases).
Die App ist signiert und notarisiert; einfach nach `/Applications` ziehen.

## Entwicklung

BuLi Tabelle ist ein reines Swift Package — kein Xcode-Projekt nötig, Ziel ist macOS 13+.

```bash
swift run
```

Ein installierbares App-Bundle (Universal Binary, ad-hoc-signiert, mit Icon und
eingebettetem Sparkle) entsteht mit:

```bash
./build-app.sh
open "build/BuLi Tabelle.app"
```

### Release veröffentlichen

Die Versionsnummer lebt an genau einer Stelle:
[`Sources/BuLiTabelle/Version.swift`](Sources/BuLiTabelle/Version.swift). `build-app.sh` schreibt
sie in die Info.plist, die Build-Nummer wird beim Release aus der Commit-Anzahl
abgeleitet — Code und Bundle bleiben so immer synchron.

Ein Release ist ein Versions-Bump: Version in `Version.swift` anheben,
CHANGELOG-Abschnitt ergänzen und auf `main` pushen bzw. mergen.
[GitHub Actions](.github/workflows/release.yml) erkennt die neue Version, baut,
signiert und notarisiert die App, legt Tag und GitHub-Release an und
aktualisiert Appcast und Downloadseite. Ein Tag-Push
(`git tag v1.3.2 && git push origin v1.3.2`) stößt denselben Workflow bei
Bedarf manuell an. Alternativ geht es lokal auf einem Mac:

```bash
SIGN_IDENTITY="Developer ID Application: … (TEAMID)" \
NOTARY_PROFILE="buli-notary" ./release.sh
```

## Unter der Haube

- **Ein Glas-System für alles** (`GlassKit.swift`): `.glass()` legt eine
  Glasfläche hinter beliebige Inhalte. Ab macOS 26 übernimmt das echte Liquid
  Glass des Systems (`glassEffect`), darunter tritt eine handgebaute Scheibe aus
  `Material`, Lichtkante und Schatten an seine Stelle — der Umschaltpunkt steckt
  an genau einer Stelle im Code
- **Echter Fenster-Blur:** `NSVisualEffectView` mit `behindWindow` als
  Untergrund, darüber zwei weiche Farblichter — erst dadurch hat das Glas etwas
  zum Brechen
- **Design-Tokens** in `Theme.swift`: Akzent, Zonen- und Ergebnisfarben je einmal
  für hell und dunkel (`Color.adaptive`), dazu Radien und Federn
- **Native Fenster-Chrome:** transparente Titelleiste mit
  `fullSizeContentView` — die Ampel gehört wieder macOS, die App zeichnet keine
  eigenen Fensterknöpfe mehr
- **Robuste API-Anbindung:** OpenLigaDB-JSON wird case-unabhängig dekodiert
  (`Models.swift`) und funktioniert daher mit der alten PascalCase- wie der
  neuen camelCase-API
- **App-Icon:** `scripts/icon.swift` zeichnet es aus den Bauteilen der App
  selbst — Farbverlauf, Kopfzeile, Zonenfarben —, `scripts/make-icon.sh`
  baut daraus die `.icns`-Datei. Liegt ein eigenes `Resources/AppIconSource.png`
  vor, hat das Vorrang. Die Icons der Downloadseite zeichnet
  `scripts/make-web-icons.py` (benötigt Pillow) mit demselben Motiv — AppKit gibt
  es nur auf macOS, deshalb zwei Fassungen; wer eine ändert, zieht die andere nach

### Selbst-Screenshot für die Layout-Arbeit

```bash
BULI_SCREENSHOT=/tmp/tabelle.png swift run
```

Rendert das Hauptfenster nach 2,5 Sekunden in die angegebene PNG-Datei —
praktisch, um Layout-Probleme ohne Bildschirmaufnahme-Rechte zu untersuchen.
Standardmäßig scharf in 2× und mittig auf einem generierten 16:9-Hintergrund
(`Screenshot.swift`). Über Umgebungsvariablen steuerbar:

- `BULI_SCREENSHOT_SCALE` – Renderfaktor (Standard `2`)
- `BULI_SCREENSHOT_BG` – `aurora` (Standard) · `gray` · `none` (nur Fenster)

`cacheDisplay(in:to:)` zeichnet keine Echtzeit-Blur-Ebenen mit. Sobald
`BULI_SCREENSHOT` gesetzt ist, ersetzt die App die Materialien deshalb durch
deckende Ersatzflächen (`Theme.capturing`) — das Bild entspricht dann dem, was
man auf dem Schirm sieht.

Denselben Screenshot nimmt der [Screenshot-Workflow](.github/workflows/screenshot.yml)
manuell und der Release-Workflow bei jeder Veröffentlichung automatisch auf.

## Dank

An [OpenLigaDB](https://www.openligadb.de) für die frei zugänglichen Spieldaten.
