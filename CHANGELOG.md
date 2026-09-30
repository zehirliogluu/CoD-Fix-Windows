# Änderungen

Alle nennenswerten Änderungen an CoD-Fix. Neueste Fassung zuerst.

---

## v3.4

### Neu

- **Gesperrte Auskunftsserver als Ursache für HILLCAT.** Windows prüft bei jeder verschlüsselten Verbindung, ob das Zertifikat der Gegenstelle zurückgezogen wurde, und fragt dafür bei einem **eigenen** Server nach — etwa `status.geotrust.com` für die Anmeldeserver von Demonware. Diese Adressen gehören nicht dem Spiel und stehen auf keiner Spieladressen-Liste. Sperrt ein DNS-Filter eine davon, bricht die Verbindung ab, obwohl **alle** Spieladressen einwandfrei auflösen — der Grund ist praktisch unauffindbar. Punkt **4 → 1** prüft diese Adressen jetzt mit: sowohl die aus den Zertifikaten der erreichbaren Server gelesenen als auch eine feste Liste der großen Zertifizierungsstellen. Gemeldet wird nur, was ein unabhängiger DNS kennt.
- **Abgelaufene gespeicherte Auskünfte.** Windows merkt sich jede Antwort. Ist die gespeicherte abgelaufen und der Auskunftsserver gerade nicht erreichbar, verwirft Windows sie und meldet in Millisekunden „Sperrserver offline" — ohne es noch einmal zu versuchen. Nach einer Freigabe im Filter bleibt es deshalb kaputt, bis der Eintrag weg ist. Das Werkzeug bietet an, ihn zu verwerfen; Windows holt die Auskunft beim nächsten Bedarf neu.
- **Zertifikate der Spielserver werden selbst geprüft.** Das füllt zugleich den Zwischenspeicher von Windows, sodass die Prüfung beim nächsten Spielstart sofort erledigt ist.
- **Fehlversuche werden gezählt.** Windows schreibt jeden ins Systemprotokoll (Quelle Schannel, Ereignis 36876). Gezählt werden nur die des Spiels. Auf Wunsch verlängert das Werkzeug zusätzlich die Frist für die Prüfung auf 30 bzw. 60 Sekunden (Standard: 15 und 20) — abgeschaltet wird nichts, geprüft wird weiterhin alles. Zurücknehmbar über **4 → 1b**.
- **Ursache aufzeichnen (4 → 4).** Der Ausweg, wenn Punkt 1 nichts findet und HILLCAT trotzdem kommt. Schaltet Windows' ausführliches Zertifikatsprotokoll (`CAPI2`) ein, du stellst den Fehler nach, das Werkzeug wertet aus und schaltet es wieder aus. Es verknüpft dabei zwei Protokolle: das Systemprotokoll sagt, **wann** das Spiel gescheitert ist, das CAPI2-Protokoll sagt, **was** in derselben Sekunde geprüft wurde — die Prüfung läuft nämlich nicht im Spiel, sondern in `lsass`. Ergebnis ist ein Satz statt eines Rätsels: welches Zertifikat, welcher Auskunftsserver, welcher Grund — und ob dieser PC den Server überhaupt erreicht. Verändert wird nichts. Der Bericht landet im Backup-Ordner.
- **Diagnose** zählt die fehlgeschlagenen Zertifikatsprüfungen der letzten 14 Tage.

### Geändert

- **„Rückgängig" für Punkt 4 → 1 findet jetzt beides.** Die Aktion ändert zweierlei, selten beides am selben Tag. Gesucht wird deshalb je Änderung die jüngste Sicherung, die sie wirklich enthält — nicht mehr pauschal die jüngste Sicherung.
- Ein Durchlauf legt höchstens **eine** Sicherung an, auch wenn er mehreres ändert.
- **Mit aktivem VPN endete Punkt 4 → 1 bisher nach dem VPN-Hinweis.** Jetzt entfällt nur der DNS-Schritt, alles andere läuft weiter — die Zertifikatsprüfung hat mit dem DNS nichts zu tun und ist gerade mit VPN aufschlussreich.

---

## v3.3

### Behobene Fehler

- **Rückgängig war im Menü unsichtbar.** Die Fixes sagen am Ende „Menü 4, dann 1b" — im Untermenü stand `1b` aber nirgends, nur ein grauer Hinweis in der Fußzeile. Wer ihn übersah, hielt den Punkt für nicht vorhanden und drückte `1`, also die Reparatur noch einmal. Jetzt steht unter jedem Punkt eine eigene Zeile `1b  RUECKGAENGIG - zurueck auf den Stand vom …`, sobald es dafür ein Backup gibt. Leere Backup-Ordner (Fix abgebrochen) zählen nicht.
- **Von Hand gesetzter DNS ließ sich nicht zurückstellen, wenn er per PowerShell eingetragen war.** Windows füllt den Registry-Wert dann mit NUL-Zeichen auf, und die letzte Adresse wurde mitsamt diesen Zeichen gelesen — ungültig. Das Zurückstellen setzte erst auf „automatisch" und scheiterte dann am Wiedereintragen. Jetzt werden NUL-Zeichen als Trenner behandelt, auch in Sicherungen, die v3.2 bereits geschrieben hat.
- Der Hinweis beim Abschalten des letzten Tonausgangs nennt jetzt den echten Weg („Menü 2, dann 4b").

### Geändert

- `1 b` (mit Leerzeichen) wird genauso verstanden wie `1b`.

---

## v3.2

### Behobene Fehler

- **Jede Reparatur beendete Visual Studio Code — samt ungespeicherter Arbeit.** Die Prozesssuche prüfte mit `'^cod'` nur den Namensanfang, und VS Code heißt als Prozess `Code`. Betroffen war fast jede Aktion, weil fast jede vorher das Spiel beendet. Gefunden wird jetzt in erster Linie über den **Pfad** (alles, was aus einem CoD-Spielordner läuft); die Namensliste ist nur noch Rückfallebene und exakt verankert.
- **Der Launcher-Name `Agent` traf fremde Programme.** Beendet wird jetzt nur noch der `Agent` aus dem Battle.net-Ordner.
- **Das Firewall-Suchmuster traf `Code.exe` und `codec.exe`.** Nach `cod` muss jetzt direkt `.exe`, eine Ziffer oder ein Bindestrich folgen.

### Neu

- **Download fehlgeschlagen (HILLCAT) / hängt bei „Prüfung auf Update".** Prüft der Reihe nach `hosts`-Datei, VPN, DNS-Filter (AdGuard, Pi-hole, NextDNS) und zwölf Spieladressen gegen einen unabhängigen DNS. Stellt den DNS auf Cloudflare nur um, wenn das sicher geht — bei aktivem VPN bewusst nicht, weil das VPN ihn selbst gesetzt hat. Merkt sich, ob der DNS vorher von Hand gesetzt oder automatisch war, und rollt sofort zurück, falls danach nichts mehr auflöst.
- **Diagnose** zeigt jetzt auch VPN, DNS-Filter, gesperrte Spieladressen und Einträge in der `hosts`-Datei.
- **Hilfe-Menü:** Steam-Dateiprüfung direkt startbar (`steam://validate/1938090`).

---

## v3.1

### Behobene Fehler

Sieben Fehler, davon zwei, die das Backup-Versprechen gebrochen haben:

- **„Alles rückgängig" überschrieb wiederhergestellte Dateien.** Der komplette Profilordner wurde *nach* den einzelnen Konfigurationsdateien zurückgespielt und hat sie dabei wieder mit dem älteren Stand überschrieben. Reihenfolge korrigiert: erst das Grobe, dann das Feine.
- **Gleichnamige Konfigurationsdateien überschrieben sich im Backup.** `s.1.0.txt` kann in mehreren Profilordnern liegen; im Backup landete nur die zuletzt kopierte — samt falscher Pfadangabe. Beim Wiederherstellen wäre der falsche Inhalt am falschen Ort gelandet. Dateien werden jetzt durchnummeriert.
- **Profildaten wurden auch dann gelöscht, wenn ihr Backup fehlschlug.** Jetzt wird nur gelöscht, was nachweislich gesichert wurde. Zusätzlich prüft das Werkzeug vorher Größe und freien Speicherplatz.
- **Deaktivierte Mikrofone wurden nie gefunden.** `DeviceState` ist eine Bitmaske — auf einem echten PC steht dort `0x10000001`, nicht `1`. Die Prüfung auf `1` bzw. `2` traf deshalb praktisch nie zu, und das Schreiben von `1` hätte die Windows-Flags in den oberen Bits gelöscht.
- **Die Prozesssuche übersah `Bootstrapper`.** Sie war groß-/kleinschreibungsabhängig — ausgerechnet bei dem Prozess, der den Anmelde-Cache zurückschreibt, den der Login-Fix löscht.
- **`netsh`, `ipconfig` und `powercfg` meldeten immer Erfolg.** `try/catch` greift bei Programmen nicht; Fehler kommen über den Exit-Code. Der wird jetzt geprüft, und nicht anwendbare Schritte melden ehrlich „übersprungen".
- **Registry-Werte ohne Vorgeschichte blieben für immer stehen.** Werte, die es vorher gar nicht gab, wurden nicht vermerkt und ließen sich deshalb nicht zurücknehmen.

### Neu

- **Bluetooth-Headset rauscht.** Schaltet das Hands-Free-Profil ab — auf Geräte-Manager-Ebene, hält damit auch nach dem nächsten Verbinden. Erkennung über die feste Profil-UUID statt über Gerätenamen.
- **Audiogeräte an- und abschalten**, auf zwei Ebenen: das ganze Gerät (Geräte-Manager) und einzelne Ein-/Ausgänge (Sound-Einstellungen). Exklusivmodus je Gerät umschaltbar. Mit Schutz gegen das Abschalten des letzten Tonausgangs.
- **Windows-Dialoge öffnen sich von selbst**, mit nummerierter Klickanleitung daneben — statt eines Hinweises auf `mmsys.cpl`.
- **Firewall-Blockaden sind wirklich zurückholbar.** Vor jeder Änderung wird die vollständige Regelsammlung gesichert. Das Suchmuster ist enger gefasst: das alte traf über „steam" auch `ms-teams.exe`.
- **Energieplan** wird sprachunabhängig über die GUID erkannt und ist zurücknehmbar.

### Geändert

- Untermenü genauso aufgebaut wie das Hauptmenü. Die Erkennungsmerkmale stehen jetzt **im Menü** statt in der Aktion, wo sie erst nach der Auswahl kamen. Kein Zwischenbildschirm mit „Taste drücken" mehr.
- Diagnose läuft nicht mehr durch die gesamte Installation (das dauerte bei über 100 GB minutenlang), zeigt dafür den freien Speicherplatz. Erreichbarkeitstests haben ein Zeitlimit.
- Steam-App-IDs werden aus den `appmanifest`-Dateien gelesen statt fest verdrahtet.
- Bei der Suche nach Installationen werden Netzlaufwerke übersprungen — dort konnte `Test-Path` minutenlang hängen.
- Der Backup-Ordner auf dem Desktop entsteht erst, wenn wirklich etwas gesichert wird. Eine reine Diagnose hinterlässt nichts.

### Aufbau

- **`CoD-Fix.cmd` wird nicht mehr von Hand bearbeitet.** `build.ps1` erzeugt sie aus `source/header.cmd` und `source/CoD-Fix.ps1` und prüft dabei Syntax, Zeichensatz, Markierung und Zeichengleichheit mit der Quelle.
- Das Skript entpackt sich nach `%TEMP%` in einen Ordner mit Zufallsnamen und räumt ihn über .NET wieder weg. `Remove-Item` scheitert an der Tilde in Kurznamen-Pfaden, wie sie bei Benutzernamen mit Leerzeichen entstehen.
- Eine abgelehnte Rechteanforderung wird erklärt, statt das Fenster kommentarlos zu schließen.

---

## v3.0

- Zweistufiges Menü: erst die Kategorie, dann das genaue Problem
- Backup und Rückgängig für jede einzelne Änderung
- Diagnose, Hilfe und „Alles rückgängig" im Hauptmenü
- Alle Pfade werden zur Laufzeit ermittelt (Steam-Bibliotheken, Battle.net, OneDrive-Umleitung)
