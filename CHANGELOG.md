# Changelog

Alle nennenswerten Änderungen an BuLi Tabelle werden hier festgehalten.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung an [Semantic Versioning](https://semver.org/lang/de/).

## [Unveröffentlicht]

## [1.3.0] – 2026-08-08

### Hinzugefügt

- **Live-Ticker.** Während gespielt wird, zeigt die App den laufenden Spielstand
  statt „– : –“ und aktualisiert sich von selbst.
  - Eine **Live-Leiste** tritt an die Stelle des Infobands: Sie sagt, wie viele
    Spiele laufen bzw. wie weit die einzelne Partie ist, und wann zuletzt
    nachgefragt wurde. Sie nimmt keine zusätzliche Höhe weg.
  - Im **Spieltag-Bereich** steht links statt der Anstoßzeit ein rotes
    LIVE-Schild mit der Spielminute, der Spielstand steht rot und fett. Fällt
    ein Tor, leuchtet die Zeile kurz auf. Läuft etwas auf dem gezeigten
    Spieltag, klappt der Bereich beim ersten Mal von selbst auf.
  - Die **Tabelle rechnet mit:** Laufende Spiele zählen wie abgepfiffene, ein
    Pfeil zeigt die Bewegung gegenüber der offiziellen Tabelle, der Punkt vor
    dem Platz blinkt bei den Mannschaften, die gerade spielen, und das letzte
    Kästchen der Formkurve bekommt einen kräftigen Rand. Über die Live-Leiste
    oder die Einstellungen lässt sich das abschalten.
  - **Export, Kopieren und Drucken** kennzeichnen eine solche Tabelle als
    „Zwischenstand“ – amtlich ist sie erst nach dem Abpfiff.
  - Das **Menüleisten-Panel** stellt die laufenden Spiele nach oben, das Symbol
    in der Menüleiste bekommt einen roten Punkt.
  - Auf Wunsch **meldet die App Tore des Lieblingsvereins** als Mitteilung
    (standardmäßig aus).
  - Der **DFB-Pokal** ist mit dabei: Live-Schild und Zwischenstand stehen auch
    in den Paarungen der Runde.
- Beim Öffnen springt die App auf den Spieltag, auf dem **gerade gespielt wird**
  – vorher war es der letzte Spieltag mit einem abgepfiffenen Spiel.

### Geändert

- Anstoßzeiten werden aus der **UTC-Angabe** der API gelesen, wenn sie vorhanden
  ist. Für Deutschland ändert sich nichts; in anderen Zeitzonen stimmt die
  angezeigte Uhrzeit jetzt.
- Während der Spiele fragt die App höchstens alle 30 Sekunden nach und prüft
  vorher über den Änderungsstempel von OpenLigaDB, ob es überhaupt etwas Neues
  gibt.

## [1.2.1] – 2026-07-31

### Geändert

- Die Auswahlfelder für Liga, Saison und Spieltag markieren den aktuell
  gewählten Eintrag im aufgeklappten Menü mit einem Häkchen.

## [1.2.0] – 2026-07-31

### Hinzugefügt

- **DFB-Pokal** als vierter Wettbewerb in der Ligaauswahl. Der Pokal ist
  rundenbasiert statt tabellenbasiert, deshalb zeigt die App hier keine Tabelle,
  sondern die Paarungen der gewählten Runde — von der 1. Runde bis zum Finale.
  - Der **Sieger** jeder Partie steht fett, der Ausgeschiedene wird abgeblendet.
    Entscheidet erst die Verlängerung oder das Elfmeterschießen, wird das mit
    „n. V.“ bzw. „i. E.“ gekennzeichnet und der Spielstand entsprechend gezeigt.
  - Zwischen den Runden wird **ausgelost**. Eine Runde ohne Paarungen ist deshalb
    kein Fehler, sondern wird als „Die Auslosung für diese Runde steht noch aus“
    ausgewiesen.
  - Der Rundenkopf zeigt den Fortschritt („5 von 8 Spielen gespielt“), nach
    Abschluss einer Runde stehen die weitergekommenen Mannschaften darunter.
  - **Kopieren, HTML-Export und Drucken** geben im Pokalmodus die Paarungen der
    Runde aus statt einer Tabelle.
  - Das **Menüleisten-Panel** zeigt im Pokalmodus ebenfalls die Runde.
  - Beim Öffnen springt die App auf die **laufende Runde** — im Pokal liegen
    zwischen den Runden Wochen, deshalb ist sie interessanter als die zuletzt
    gespielte.

### Geändert

- Beschriftungen richten sich nach dem Wettbewerb: „Spieltag“ wird im Pokal zu
  „Runde“, „Aktuelle Tabelle“ zu „Aktuelle Runde“. Heim- und Auswärtstabelle
  entfallen dort, ebenso die Auf- und Abstiegszonen.

## [1.1.0] – 2026-07-31

### Hinzugefügt

- Die anonyme Nutzungsstatistik erfasst jetzt auch **einzelne Ereignisse** statt
  nur den Programmstart: Ligawechsel, Spieltagsnavigation, Export, Kopieren,
  Drucken, geöffnete Fenster, Update-Suche und Ladefehler. Weiterhin ohne
  personenbezogene Daten und weiterhin in den Einstellungen abschaltbar — wer
  den Schalter umlegt, sendet ab diesem Moment nichts mehr.

### Geändert

- **Neues App-Icon** aus dem Icon Composer: weißer Fußball auf Bundesliga-rotem
  Verlauf. Es liegt allen Größen zugrunde — Programmsymbol, Downloadseite und
  Favicons.
- **Bundesliga-Rot** als dezenter Akzent durch die ganze App und die
  Downloadseite: roter Abschluss unter den Titelleisten und Tabellenköpfen,
  rote Rubriken in der Aktionsspalte, rot umrandete Hauptschaltflächen. Die
  Zonenfarben und die Formkurve bleiben unangetastet, damit Rot dort weiter
  „Abstieg“ bzw. „Niederlage“ heißt.
- Das **Menüleisten-Symbol** ist jetzt der Fußball statt der
  Deutschland-Flagge — als Template-Image, das sich heller und dunkler
  Menüleiste selbst anpasst. Auch die Titelleisten tragen den Ball.
- Das App-Bundle heißt jetzt **„BuLi Tabelle.app“** mit Leerzeichen. Der Name
  der Download-Datei bleibt `BuLiTabelle-<Version>.zip`.

## [1.0.0] – 2026-07-31

### Hinzugefügt

- **Live-Tabellen** der 1. Bundesliga, 2. Bundesliga und 3. Liga über
  [OpenLigaDB](https://www.openligadb.de).
- **Zeitreise:** die Tabelle jedes Spieltags jeder Saison seit 2004/05, lokal
  aus den Spielergebnissen berechnet (Punkte → Tordifferenz → erzielte Tore).
- **Filterleiste** über der Tabelle: Liga, Saison und Spieltag nebeneinander,
  mit Pfeiltasten direkt am Spieltagsfeld.
- **Aktionsspalte** links, gegliedert in „Ansehen“, „Daten“ und „Programm“.
- Farbig markierte **Auf- und Abstiegszonen** (Champions League, Europa League,
  Conference League, Relegation, Abstieg), abschaltbar.
- **Heim- und Auswärtstabelle** sowie eine **Formkurve** der letzten fünf Spiele.
- Ausklappbarer **Spieltag-Bereich** mit allen Paarungen und Ergebnissen.
- **Torjägerliste** der gewählten Saison.
- **Lieblingsverein** per Rechtsklick markieren; er wird in der Tabelle
  hervorgehoben.
- Tabelle **kopieren**, als **HTML exportieren** oder **drucken**.
- **Menüleisten-Modus** mit kompakter Tabelle. Wer das Fenster schließt, behält
  die App in der Menüleiste; „Fenster öffnen“ holt sie zurück.
- **Automatische Updates** über [Sparkle](https://sparkle-project.org) mit
  signiertem Appcast.
- Optionale, anonyme Nutzungsstatistik — abschaltbar in den Einstellungen.

### Aussehen

- Handgezeichnetes Retro-Chrome im Stil der frühen 2000er: Luna-Farbverläufe,
  doppelte 1-Pixel-Bevel-Kanten, Tahoma, gezeichnete Titelleiste und
  Retro-Auswahlfelder.
- App-Icon und die Icons der Downloadseite werden aus den Bauteilen der App
  selbst gezeichnet — Luna-Verlauf, schwarze Kopfzeile, Zonenfarben.
  (Ab 1.1.0 durch das Icon-Composer-Icon ersetzt.)

[Unveröffentlicht]: https://github.com/dmnktoe/buli-tabelle/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/dmnktoe/buli-tabelle/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/dmnktoe/buli-tabelle/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/dmnktoe/buli-tabelle/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dmnktoe/buli-tabelle/releases/tag/v1.0.0
