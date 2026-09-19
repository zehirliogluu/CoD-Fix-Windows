<div align="center">

# 🎮 CoD-Fix

### Behebt die häufigsten Call-of-Duty-Probleme unter Windows

**Eine Datei. Ein Menü. Backup und Rückgängig für jede Änderung.**

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Version](https://img.shields.io/badge/Version-3.2-brightgreen?style=for-the-badge)
![Lizenz](https://img.shields.io/badge/Lizenz-MIT-blue?style=for-the-badge)

![Steam](https://img.shields.io/badge/Steam-✓-000000?style=flat-square&logo=steam&logoColor=white)
![Battle.net](https://img.shields.io/badge/Battle.net-✓-00AEFF?style=flat-square&logo=battle.net&logoColor=white)
![Warzone](https://img.shields.io/badge/Warzone-✓-orange?style=flat-square)
![Black Ops 6/7](https://img.shields.io/badge/Black%20Ops%206%20%7C%207-✓-orange?style=flat-square)

</div>

---

> [!CAUTION]
> **Benutzung auf eigene Gefahr.** Das Werkzeug ändert Systemeinstellungen und löscht Spieldateien.
> Es sichert vorher alles — eine Garantie gibt es trotzdem nicht.
> Siehe [Haftungsausschluss](#haftung).

---

## ⬇️ Herunterladen

<div align="center">

### **[➜ CoD-Fix.cmd herunterladen](https://github.com/zehirliogluu/CoD-Fix-Windows/releases/latest/download/CoD-Fix.cmd)**

<sub>Eine Datei · rund 130 KB · keine Installation</sub>

</div>

> [!WARNING]
> **Lade die Datei nur über den Knopf oben oder über [Releases](https://github.com/zehirliogluu/CoD-Fix-Windows/releases/latest).**
>
> Wer stattdessen in der Dateiliste oben auf `CoD-Fix.cmd` klickt und die Seite speichert, bekommt eine **HTML-Seite statt des Skripts** — die Datei startet dann nicht oder öffnet nur ein schwarzes Fenster, das sofort wieder zugeht.
>
> Woran du eine kaputte Datei erkennst: Sie ist **viel kleiner als 100 KB**, oder sie beginnt beim Öffnen im Editor mit `<!DOCTYPE html>` statt mit `@echo off`.

---

## ⚡ Schnellstart

```
1.  CoD-Fix.cmd herunterladen  (Knopf oben)
2.  Doppelklick  →  Adminrechte bestätigen
3.  Kategorie wählen  →  Problem wählen
4.  Fertig
```

> [!NOTE]
> **Windows warnt bei heruntergeladenen Skripten.**
> „Weitere Informationen" → „Trotzdem ausführen".
> Die Datei ist reiner Klartext — du kannst sie vorher mit jedem Editor öffnen und komplett nachlesen.

---

## 📋 Das Menü

```
  ================================================================

      C A L L   O F   D U T Y   -   F I X - W E R K Z E U G
                                                        v3.2
  ================================================================

    WO LIEGT DAS PROBLEM?
    ------------------------------------------------------------

      1  BILD / GRAFIK
         Schwarzbild, Grafikfehler, Ruckeln

      2  TON / MIKROFON
         Kein Ton, Knacken, Voice-Chat, Bluetooth

      3  LOGIN / ANMELDUNG
         Anmeldung haengt oder dreht sich im Kreis

      4  VERBINDUNG / INTERNET
         haengt beim Update, Download-Fehler, Disconnects

      5  ABSTUERZE / STARTPROBLEME
         Spiel stuerzt ab oder startet gar nicht

      6  LEISTUNG / RUCKELN
         Ruckeln, FPS-Einbrueche, Verzoegerung

    ------------------------------------------------------------

      D  Diagnose      H  Hilfe      A  Alles zurueck      0  Ende

    H  Hilfe  -  ich oeffne dir das richtige Windows-Fenster
```

Das Untermenü ist **genauso aufgebaut** — Zahl, Überschrift, darunter grau die Erkennungsmerkmale. Wer das Hauptmenü verstanden hat, versteht auch dieses:

```
  ================================================================

      C A L L   O F   D U T Y   -   F I X - W E R K Z E U G
                                                        v3.2
  ================================================================

    TON / MIKROFON
    ------------------------------------------------------------

    WAS PASST AM BESTEN?

      1  Kein Ton, Knacken, Aussetzer
         gar kein Ton, Knistern, auch nach dem Spiel kaputt

      2  Mikrofon geht nicht, Voice-Chat
         keiner hoert dich, Mikro wird nicht erkannt

      3  Bluetooth-Headset rauscht
         dumpf oder blechern, klingt wie ein Telefon

      4  Zu viele oder falsche Audiogeraete
         Ton aus dem falschen Geraet, mehrere Mikrofone

    ------------------------------------------------------------

      0  Zurueck zum Hauptmenue

    ------------------------------------------------------------
     Zahl repariert  -  Zahl mit b macht rueckgaengig (z.B. 1b)
    ------------------------------------------------------------
```

**Zwei Bildschirme, dann passiert etwas.** Die Erkennungsmerkmale stehen bewusst *im Menü* statt in der Aktion — dort helfen sie beim Auswählen, danach wären sie nur noch Text, den niemand liest. Kein Zwischenbildschirm mit „Taste drücken".

> [!TIP]
> **Du musst nichts über Windows wissen.** Wo etwas von Hand erledigt werden muss,
> öffnet das Werkzeug das richtige Fenster von selbst und zeigt daneben eine
> nummerierte Klickanleitung — Schritt 1, 2, 3, fertig.

---

## 🔧 Was die Fixes machen

<details>
<summary><b>1 · Bild / Grafik</b> — Schwarzbild, Grafikfehler, Dev-Error</summary>

<br>

| Problem | Was passiert |
|---|---|
| **Schwarzbild, Grafikfehler, Dev-Error** | Löscht Shader-Caches: Steam (alle Bibliotheken), Spielordner, Windows-`D3DSCache`, NVIDIA- und AMD-Treibercaches |
| **Bild schwarz, aber Ton läuft** | Anzeigemodus auf Fenster 1600×900 an Position 50/50, HDR aus, `GPUUploadHeaps` aus, Reflex / NIS / Frame-Generation aus |

Der zweite Punkt hilft, wenn das Spielfenster auf einen **nicht vorhandenen Monitor** oder auf Koordinaten außerhalb des Bildschirms gesetzt wurde — ein typischer Zustand nach einem Monitorwechsel.

</details>

<details>
<summary><b>2 · Ton / Mikrofon</b> — Kein Ton, Knacken, Voice-Chat, Bluetooth</summary>

<br>

| Problem | Was passiert |
|---|---|
| **Kein Ton, Knacken, Aussetzer** | Exklusivmodus und Raumklang für alle Geräte aus, `WindowsSonicEnable` aus, Audiodienste neu starten |
| **Mikrofon geht nicht, Voice-Chat** | Windows-Datenschutz freischalten (inkl. `NonPackaged` für Desktop-Apps), deaktivierte Mikrofone reaktivieren, `MicThreshold` auf Minimum |
| **Bluetooth-Headset rauscht** | Hands-Free abschalten — auf Geräte-Manager-Ebene, hält also auch nach dem nächsten Verbinden |
| **Zu viele/falsche Audiogeräte** | Geräteliste auf **zwei Ebenen** zum An- und Abschalten, Exklusivmodus je Ein-/Ausgang |

> **`MicThreshold`** ist im Spiel der „Open Mic Recording Threshold". Steht er zu hoch, überträgt das Mikro erst bei lauter Stimme — die häufigste Ursache für *„keiner hört mich"*.

**Warum Bluetooth-Kopfhörer im Spiel plötzlich rauschen:** Ein Headset meldet sich mit **zwei** Profilen an — *A2DP* (Stereo, voller Klang, **kein** Mikrofon) und *Hands-Free/HFP* (mit Mikrofon, dafür Telefonqualität). Beides gleichzeitig kann Bluetooth nicht. Sobald etwas das Headset-Mikrofon öffnet, schaltet Windows auf Hands-Free — und der Ton bricht hörbar ein. Das Werkzeug schaltet Hands-Free ab; für den Voice-Chat brauchst du dann ein anderes Mikrofon, der Klang bleibt dafür durchgehend gut.

**Die Geräteliste arbeitet auf zwei Ebenen** — weil Windows das auch tut:

```
     GANZE GERAETE
     schaltet die Soundkarte oder das Headset KOMPLETT ab -
     dasselbe wie im Geraete-Manager. Wirkt am gruendlichsten.

       1  [ AN  ] NVIDIA High Definition Audio
       2  [ AN  ] Realtek USB Audio  [1 von 2]
       3  [ AUS ] Bose Hands-Free

     EINZELNE EIN- UND AUSGAENGE
     die Liste, die du auch in den Sound-Einstellungen siehst.

      WIEDERGABE
       4  [ AN  ] Realtek Digital Output (Realtek USB Audio) Exklusiv: AN
      AUFNAHME
       5  [ AN  ] Mikrofon (USB PnP Audio Device)            Exklusiv: AN

     NICHT VERBUNDEN  (26 alte Eintraege, nur zur Information)
```

Oben das **ganze Gerät** (Geräte-Manager-Ebene, `Disable-PnpDevice`) — das ist der gründliche Weg, den erfahrene Nutzer von Hand gehen. Unten die **einzelnen Ein- und Ausgänge** (Sound-Einstellungen), jeweils mit dem Haken *„Anwendungen haben alleinige Kontrolle"*.

Melden mehrere Geräte denselben Namen, werden sie durchnummeriert (`[1 von 2]`) — sonst wüsste man nicht, welches man gerade erwischt.

> [!IMPORTANT]
> **Schutz gegen Aussperren:** Wer seinen letzten eingeschalteten Tonausgang abschalten will, bekommt eine ausdrückliche Warnung und muss zusätzlich bestätigen. Angeboten werden ausschließlich Geräte der Windows-Klasse `MEDIA` — Festplatten, Grafikkarte oder Netzwerkadapter tauchen in der Liste nicht auf und können nicht getroffen werden.

Alte, nicht mehr verbundene Einträge werden **nur angezeigt** und nicht angefasst — auf diesen Registry-Schlüsseln haben Administratoren Schreib-, aber kein Löschrecht.

Tonformat (16 Bit / 48000 Hz), Pegel und Standardgerät lassen sich nicht zuverlässig automatisch setzen — dort öffnet das Werkzeug den Windows-Dialog und führt mit nummerierten Schritten hindurch.

</details>

<details>
<summary><b>3 · Login / Anmeldung</b> — Anmeldung hängt endlos</summary>

<br>

Löscht `%LOCALAPPDATA%\Activision` **komplett — einschließlich `bootstrapper`** — sowie `Dokumente\Call of Duty`.

> [!IMPORTANT]
> Der Unterordner **`bootstrapper` enthält den Anmelde-Cache.** Anleitungen, die nur
> `Activision\Call of Duty` löschen, greifen deshalb oft nicht.

Beendet vorher Spiel **und** Launcher, damit nichts zurückgeschrieben wird.

</details>

<details>
<summary><b>4 · Verbindung / Internet</b> — hängt beim Update, Download-Fehler, Disconnects</summary>

<br>

| Problem | Was passiert |
|---|---|
| **Download fehlgeschlagen (HILLCAT)** | Prüft VPN, DNS-Filter, `hosts`-Datei und zwölf Spieladressen — und stellt den DNS nur um, wenn das sicher geht |
| **Verbindungsfehler, Disconnects** | DNS-Cache leeren, Winsock zurücksetzen, TCP/IP-Stack zurücksetzen, IP erneuern |
| **Firewall blockiert das Spiel** | Blockierende Regeln zeigen und **nach Rückfrage** entfernen, Freigaben für alle Spiel-EXEs anlegen (ein- und ausgehend) |

**Warum „Prüfung auf Update" hängen bleibt:** Nach dem Start lädt Call of Duty eigene Datenpakete nach — unabhängig von Steam oder Battle.net. Scheitert das, bleibt der Balken stehen oder es erscheint **Fehlercode HILLCAT**. Eine Neuinstallation hilft dann fast nie, denn es liegt am **Weg** zu den Activision-Servern. Die Aktion prüft ihn der Reihe nach:

| Prüfung | Befund | Was passiert |
|---|---|---|
| `hosts`-Datei | Spieladressen umgeleitet | Zeigt die Zeilen, öffnet die Datei im Editor — gelöscht wird nichts automatisch |
| VPN | aktiv (erkannt an der Umleitung des gesamten Verkehrs) | Anleitung für den Vergleich mit und ohne VPN. **Der DNS wird dann nicht angefasst** — das VPN hat ihn selbst gesetzt |
| DNS-Filter (AdGuard, Pi-hole, NextDNS) | sperrt Spieladressen | Nennt genau diese Adressen, samt Schreibweise für die Freigabeliste |
| DNS-Filter | sperrt keine bekannte Adresse | Anleitung, im Abfrageprotokoll des Filters nach der Sperre zu suchen |
| DNS | von Hand gesetzt, antwortet nicht | Bietet an, ihn auf „automatisch" zurückzusetzen — oft Rest eines getrennten VPNs |
| alles unauffällig | — | Bietet Cloudflare (1.1.1.1) als DNS an — der häufigste Fix für HILLCAT |

Beim Umstellen merkt sich das Werkzeug, ob dein DNS vorher **von Hand eingetragen** war oder **automatisch** vom Router kam, und stellt mit **4 → 1b** exakt diesen Zustand wieder her. Löst nach der Umstellung nichts mehr auf, wird **sofort automatisch zurückgestellt**.

Vor jeder Firewall-Änderung wird die **komplette Regelsammlung** gesichert — damit lässt sich das Entfernen einer Blockade später wirklich zurücknehmen.

Nach dem Netzwerk-Reset ist ein Neustart nötig — das Werkzeug weist darauf hin.

</details>

<details>
<summary><b>5 · Abstürze / Startprobleme</b> — Spiel startet nicht oder stürzt ab</summary>

<br>

| Problem | Was passiert |
|---|---|
| **Absturz beim Start** | Beendet NVIDIA-Overlay, Discord, RTSS, MSI Afterburner, OBS |
| **Spiel startet gar nicht** | Entfernt Kompatibilitäts-Flags (`RUNASADMIN`, Kompatibilitätsmodi), löscht Debugger-Blockaden, prüft Visual C++ und DirectX 12, warnt vor Anti-Cheat-Konflikten |

> [!TIP]
> **Wenig bekannt, aber entscheidend:** Der Launcher darf als Administrator laufen — **das Spiel selbst nicht.**
> Ist `cod.exe` auf „Als Administrator ausführen" gesetzt, startet CoD teilweise überhaupt nicht.

</details>

<details>
<summary><b>6 · Leistung / Ruckeln</b> — FPS-Einbrüche, Mikroruckler</summary>

<br>

- **Xbox Game Bar und Spielaufzeichnung aus** — kosten 200–400 MB RAM und bis zu 20 ms Eingabeverzögerung, auch ohne Aufnahme
- **Windows-Spielmodus an**
- **Hardwarebeschleunigte GPU-Planung an** (wirkt nach Neustart)
- **Energieplan prüfen** — steht Windows im Energiesparmodus, wird auf *Ausbalanciert* umgestellt (der alte Plan wird gemerkt und ist rücknehmbar)
- **Prozesspriorität auf Normal** — CoD setzt sich teils selbst auf „Hoch" und lässt dadurch das ganze System stottern

</details>

<details>
<summary><b>D · Diagnose</b> — prüft alles, ändert nichts</summary>

<br>

Prüft System, Grafiktreiber, **Secure Boot und TPM** (Ricochet-Anti-Cheat setzt beides voraus), Installation samt **freiem Speicherplatz**, Profildaten, Netzwerk und Erreichbarkeit der Activision-Server, gleicht die **Uhrzeit gegen echte Zeitgeber ab** und listet laufende Overlays.

Ändert nichts, legt nichts an und ist in Sekunden durch.

Ein guter Startpunkt, wenn du nicht weißt, wo es klemmt.

</details>

<details>
<summary><b>H · Hilfe</b> — bringt dich hin, statt dich suchen zu lassen</summary>

<br>

**Du wählst eine Zahl, das passende Windows-Fenster geht von selbst auf** — und daneben steht, was du darin anklicken musst. Kein Suchen in den Einstellungen, keine kryptischen Befehle.

```
    WOHIN SOLL ICH DICH BRINGEN?

      1  Sound - Wiedergabe (Lautsprecher, Kopfhoerer)
         Geraet -> Als Standard. Eigenschaften -> Erweitert -> 16 Bit, 48000 Hz.
      2  Sound - Aufnahme (Mikrofon)
      3  Bluetooth-Einstellungen
      4  Geraete und Drucker (Bluetooth-Dienste)
      5  Geraete-Manager
      6  Datum und Uhrzeit
      7  Energieoptionen
      8  Programme und Features
      9  Visual C++ Runtime herunterladen
     10  Activision - Kontoverknuepfung
     11  Activision - Kontosperre pruefen
     12  Activision - Serverstatus
```

Danach folgt der Hilfetext zu allem, was sich gar nicht automatisieren lässt: Integritätsprüfung der Spieldateien, Treiber-Downgrade per DDU, XMP/EXPO im BIOS, Bluetooth-Grundlagen.

</details>

---

## 💾 Backups & Rückgängig

Vor **jeder** Änderung entsteht ein Ordner unter:

```
Desktop\CoD-Fix-Backups\<Aktion>_<Datum-Uhrzeit>\
```

Darin: die Originaldateien samt `.pfad`-Datei mit dem Ursprungsort, Registry-Werte als Textdatei, bei Firewall-Änderungen zusätzlich die **komplette Windows-Firewall-Richtlinie** als `.wfw` — und ein durchgehendes Protokoll in `CoD-Fix-Log.txt`.

| | |
|---|---|
| **`A` im Hauptmenü** | macht alle Änderungen rückgängig |
| **`b`-Optionen** | machen einzelne Änderungen rückgängig |

Auch Werte, die es vorher **gar nicht gab**, werden vermerkt — beim Rückgängigmachen werden sie wieder entfernt statt auf einem erfundenen Standardwert stehenzubleiben.

> [!NOTE]
> Der Ordner entsteht erst, wenn tatsächlich etwas gesichert wird.
> Eine reine **Diagnose** ändert nichts und hinterlässt deshalb auch nichts auf dem Desktop.

Zwei Dinge lassen sich nicht zurücknehmen — und das Werkzeug sagt das ehrlich, statt so zu tun:

- **Shader-Cache** → baut sich beim nächsten Spielstart automatisch neu auf
- **Netzwerk-Reset** → stellt Windows-Standardwerte her, das *ist* bereits der Ausgangszustand

---

## ⏳ Wichtig nach dem ersten Fix

> [!WARNING]
> **Nach dem Löschen von Profildaten oder Shader-Cache dauert der erste Spielstart deutlich länger.**
> Das Bild kann **minutenlang schwarz bleiben**, während der Shader-Cache über 100+ GB neu aufgebaut wird.
> **Nicht abbrechen** — sonst beginnt der Vorgang beim nächsten Mal von vorn.

Ob das Spiel wirklich arbeitet oder hängt, erkennst du im Task-Manager:
Läuft `cod.exe` mit **dauerhafter CPU-Last und steigendem Speicherverbrauch**, lädt es.

---

## 💻 Kompatibilität

<div align="center">

| | |
|---|---|
| **Betriebssystem** | Windows 10 · Windows 11 (64-Bit) |
| **Voraussetzung** | Windows PowerShell 5.1 *(bei Windows dabei)* |
| **Launcher** | Steam · Battle.net |
| **Spiele** | Warzone · Black Ops 6 · Black Ops 7 · Modern Warfare |

</div>

**Nichts ist fest verdrahtet.** Alle Pfade werden zur Laufzeit ermittelt:

- Steam aus der Registry, weitere Bibliotheken aus `libraryfolders.vdf` → Spiel auf Laufwerk D funktioniert
- Steam-App-IDs aus den `appmanifest`-Dateien → auch künftige Teile werden erkannt
- Battle.net-Orte über alle **fest eingebauten** Laufwerke (Netzlaufwerke werden übersprungen, sonst hängt die Suche)
- `Dokumente` und `Desktop` über die Windows-API → funktioniert auch bei OneDrive-Umleitung
- Netzwerkadapter über die aktive Standardroute

---

## 🏗️ Aufbau

`CoD-Fix.cmd` enthält beides in einer Datei:

```
┌─────────────────────────────────────┐
│  Batch-Kopf                         │  fordert Adminrechte an
│  exit /b                            │  ← alles danach liest cmd nie
├─────────────────────────────────────┤
│  :::PSCODE:::                       │  Markierung
│  PowerShell-Skript (~1700 Zeilen)   │  die eigentliche Logik
└─────────────────────────────────────┘
```

PowerShell schneidet sich seinen Teil aus der Datei, legt ihn in einem **frisch angelegten Ordner mit Zufallsnamen** unter `%TEMP%` ab, führt ihn aus und räumt ihn danach zuverlässig wieder weg — auch dann, wenn unterwegs ein Fehler auftritt.

### Bearbeiten und bauen

**`CoD-Fix.cmd` wird nicht von Hand bearbeitet.** Sie entsteht aus zwei Quellen:

```
source/header.cmd    Batch-Kopf (Adminrechte, Extraktion)
source/CoD-Fix.ps1   das eigentliche Skript
        │
        ├── build.ps1
        ▼
   CoD-Fix.cmd       das, was ausgeliefert wird
```

```
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
```

`build.ps1` baut nicht nur zusammen, sondern **weigert sich bei Problemen**: es prüft die PowerShell-Syntax, verbietet Nicht-ASCII-Zeichen (Windows PowerShell 5.1 würde Umlaute in einer Datei ohne BOM verstümmeln), kontrolliert die Markierung und schneidet zum Schluss das Ergebnis wieder auseinander, um es Zeichen für Zeichen mit der Quelle zu vergleichen.

Neue Fixes ergänzt man über die Liste `$Script:Kategorien` — **das Menü baut sich daraus selbst auf.**

---

## 🔒 Sicherheit

Das Skript ist **nicht signiert**, deshalb warnt Windows bei heruntergeladenen Kopien.
Es ist reiner Klartext **ohne Verschleierung oder Kodierung** — lies es vor dem Ausführen durch. Das ist bei jedem Skript aus dem Internet die richtige Gewohnheit.

**Administratorrechte** sind nötig für: Registry-Werte unter `HKLM` (Audio, GPU-Planung, Kompatibilitäts-Flags), Firewall-Regeln, Netzwerk-Reset, Neustart der Audiodienste und Löschen von Caches unter `Programme`.

Das Werkzeug **lädt nichts herunter** — außer bei der Diagnose einen einzelnen HTTP-HEAD-Aufruf zum Abgleich der Uhrzeit. Es **sendet keinerlei Daten**.

Es **öffnet Windows-Fenster** (Sound, Bluetooth, Geräte-Manager, Datum/Uhrzeit), damit niemand danach suchen muss — das ändert nichts, es zeigt nur hin. **Internetseiten** öffnet es ausschließlich nach ausdrücklicher Rückfrage und dann in deinem Browser: die Activision-Seiten und den Microsoft-Download der Visual-C++-Runtime, falls die fehlt.

---

<a id="haftung"></a>

## ⚖️ Haftungsausschluss

> [!CAUTION]
> **Die Benutzung erfolgt vollständig auf eigene Gefahr.**
>
> Diese Software wird kostenlos und **ohne jede Gewährleistung** bereitgestellt. Der Autor übernimmt
> **keinerlei Verantwortung oder Haftung** für Schäden, Datenverluste, Fehlfunktionen oder sonstige
> Folgen, die aus der Benutzung oder der versuchten Benutzung entstehen — weder direkt noch indirekt.

Konkret bedeutet das:

- Das Werkzeug ändert **Registry-Werte, Systemeinstellungen, Firewall-Regeln und Netzwerkeinstellungen** und löscht Spieldateien. Es erstellt zwar vor jeder Änderung ein Backup, aber es wird **nicht garantiert**, dass eine Wiederherstellung in jedem Fall gelingt.
- Es gibt **keine Garantie**, dass ein Problem behoben wird. Manche Ursachen liegen außerhalb dessen, was ein Skript beheben kann.
- Es gibt **keine Zusicherung**, dass das Werkzeug fehlerfrei ist oder auf jedem System funktioniert.
- **Lege vor der Benutzung eine eigene Sicherung an**, wenn dir deine Einstellungen wichtig sind — insbesondere Tastenbelegungen und Grafikeinstellungen.
- **Prüfe den Quellcode**, bevor du das Werkzeug mit Administratorrechten ausführst.

Wer das Werkzeug ausführt, erklärt sich damit einverstanden. Wer damit nicht einverstanden ist, sollte es nicht benutzen.
Es besteht **keine Verpflichtung zu Support, Wartung oder Fehlerbehebung.**

---

## 💬 Fragen, Rückmeldungen, Probleme

Du brauchst dafür ein kostenloses GitHub-Konto — sonst nichts.

<div align="center">

| | |
|---|---|
| **[➜ Frage stellen oder Rückmeldung geben](https://github.com/zehirliogluu/CoD-Fix-Windows/discussions)** | Hat es geholfen? Etwas unklar? Ein Wunsch? Hier ist alles willkommen. |
| **[➜ Fehler melden](https://github.com/zehirliogluu/CoD-Fix-Windows/issues)** | Etwas funktioniert nicht oder bricht ab. |

</div>

**Damit dir geholfen werden kann, schreib bitte dazu:**

```
1.  Welchen Punkt im Menü hast du gewählt?  (z.B. "2, dann 3")
2.  Was ist passiert, was hast du erwartet?
3.  Windows 10 oder 11?  Steam oder Battle.net?
4.  Die Datei CoD-Fix-Log.txt aus dem Ordner
    Desktop\CoD-Fix-Backups\  — die enthält das Protokoll.
```

> [!NOTE]
> Das Protokoll enthält Gerätenamen und Pfade von deinem PC. Sieh es kurz durch, bevor du es öffentlich anhängst — es ist eine reine Textdatei und lässt sich mit jedem Editor öffnen und kürzen.

---

## 📜 Änderungen

Was sich in welcher Fassung geändert hat, steht in [CHANGELOG.md](CHANGELOG.md).

---

## 📄 Lizenz

**MIT** — siehe [LICENSE](LICENSE). Die MIT-Lizenz schließt jede Gewährleistung ausdrücklich aus; die Software wird „wie besehen" (*as is*) bereitgestellt.

<div align="center">

<sub>Kein offizielles Produkt von Activision oder Blizzard und in keiner Weise mit diesen verbunden<br>
oder von ihnen unterstützt. Call of Duty ist eine Marke von Activision Publishing, Inc.</sub>

</div>
