@echo off
title Call of Duty - Fix-Werkzeug

rem ============================================================================
rem  Diese Datei ist der Batch-Kopf von CoD-Fix.cmd.
rem  CoD-Fix.cmd wird aus header.cmd + CoD-Fix.ps1 erzeugt: build.ps1 ausfuehren.
rem  Niemals CoD-Fix.cmd von Hand bearbeiten - die Aenderung waere beim
rem  naechsten Build wieder weg.
rem ============================================================================

rem ---- Eigenen Pfad merken. Ueber die Umgebungsvariable braucht der
rem ---- PowerShell-Aufruf weiter unten keine Anfuehrungszeichen-Akrobatik,
rem ---- und Sonderzeichen im Pfad koennen nichts kaputt machen.
set "SELF=%~f0"

rem ---- Adminrechte anfordern ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   Starte mit Administratorrechten neu...
    echo   Bitte die Windows-Abfrage mit JA bestaetigen.
    echo.
    powershell -NoProfile -Command "try { Start-Process -FilePath cmd -ArgumentList ('/c \"\"' + $env:SELF + '\"\"') -Verb RunAs -ErrorAction Stop } catch { Write-Host ''; Write-Host '  Abgebrochen - ohne Administratorrechte kann das Werkzeug nichts reparieren.' -ForegroundColor Red; Write-Host '  Einfach neu starten und die Windows-Abfrage mit JA bestaetigen.' -ForegroundColor Yellow; Write-Host ''; Start-Sleep -Seconds 6 }"
    exit /b
)

rem ---- PowerShell-Teil aus dieser Datei herausschneiden und starten ----
rem ---- Eigener Ordner mit Zufallsnamen: so kann kein anderer Prozess die
rem ---- Datei zwischen Schreiben und Starten austauschen. try/finally raeumt
rem ---- ihn auch dann weg, wenn das Skript mit einem Fehler endet.
rem ----
rem ---- Aufgeraeumt wird bewusst ueber [IO.Directory]::Delete und NICHT ueber
rem ---- Remove-Item: %TEMP% enthaelt bei Benutzernamen mit Leerzeichen den
rem ---- 8.3-Kurznamen (z.B. C:\Users\MAXMUS~1\...). An der Tilde darin
rem ---- scheitert Remove-Item - der Ordner bliebe bei jedem Start liegen.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=':::PS'+'CODE:::'; $s=[IO.File]::ReadAllText($env:SELF); $i=$s.IndexOf($m); if($i -lt 0){ Write-Host ''; Write-Host '  FEHLER: Die Datei ist unvollstaendig.' -ForegroundColor Red; Write-Host '  Bitte CoD-Fix.cmd noch einmal herunterladen.' -ForegroundColor Yellow; $null=Read-Host '  Enter zum Beenden'; exit 1 }; $d=Join-Path $env:TEMP ('CoD-Fix-'+[guid]::NewGuid().ToString('N')); $null=New-Item -ItemType Directory -Path $d -Force; $t=Join-Path $d 'CoD-Fix.ps1'; [IO.File]::WriteAllText($t,$s.Substring($i+$m.Length),(New-Object Text.UTF8Encoding $false)); try { & $t } finally { try { [IO.Directory]::Delete($d,$true) } catch {} }"
exit /b

:::PSCODE:::
<#
================================================================================
  CALL OF DUTY - FIX-WERKZEUG  v3.2
  Behebt die haeufigsten PC-Probleme: haengender Login, Schwarzbild,
  Tonprobleme, Dev-/DirectX-Fehler, Verbindungsabbrueche.

  - Laeuft auf jedem Windows 10/11, alle Pfade werden automatisch gesucht
  - Jede Aktion legt vorher ein Backup an und ist einzeln rueckgaengig machbar
  - Funktioniert mit Steam UND Battle.net

  --------------------------------------------------------------------------
  HAFTUNGSAUSSCHLUSS

  Die Benutzung erfolgt VOLLSTAENDIG AUF EIGENE GEFAHR.

  Diese Software wird kostenlos und OHNE JEDE GEWAEHRLEISTUNG bereitgestellt.
  Der Autor uebernimmt KEINERLEI HAFTUNG fuer Schaeden, Datenverluste oder
  Fehlfunktionen, die aus der Benutzung entstehen - weder direkt noch
  indirekt.

  Das Werkzeug aendert Registry-Werte, Systemeinstellungen, Firewall-Regeln
  und Netzwerkeinstellungen und loescht Spieldateien. Vor jeder Aktion wird
  ein Backup angelegt, eine erfolgreiche Wiederherstellung wird jedoch
  NICHT GARANTIERT.

  Lizenz: MIT. Kein offizielles Produkt von Activision oder Blizzard.
  --------------------------------------------------------------------------
================================================================================
#>

$ErrorActionPreference = 'Continue'
$Script:Version = '3.2'

# ============================== GRUNDLAGEN ====================================

$Script:BackupRoot = Join-Path ([Environment]::GetFolderPath('Desktop')) 'CoD-Fix-Backups'
$Script:LogFile    = Join-Path $Script:BackupRoot 'CoD-Fix-Log.txt'
$Script:LogPuffer  = New-Object System.Collections.Generic.List[string]

function Write-LogPuffer {
    # Schreibt gesammelte Zeilen weg. Bewusst nur, wenn der Backup-Ordner
    # schon existiert: eine reine Diagnose aendert nichts am System und soll
    # deshalb auch keinen Ordner auf dem Desktop hinterlassen.
    if ($Script:LogPuffer.Count -eq 0) { return }
    if (-not (Test-Path $Script:BackupRoot)) { return }
    try {
        ($Script:LogPuffer -join "`r`n") | Out-File -FilePath $Script:LogFile -Append -Encoding utf8
        $Script:LogPuffer.Clear()
    } catch {}
}

function Ensure-BackupRoot {
    if (-not (Test-Path $Script:BackupRoot)) {
        New-Item -ItemType Directory -Path $Script:BackupRoot -Force | Out-Null
    }
    Write-LogPuffer
}

function Say {
    param([string]$Text, [string]$Color = 'Gray')
    Write-Host $Text -ForegroundColor $Color
    $Script:LogPuffer.Add(("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Text))
    Write-LogPuffer
}

function Ok    { param([string]$t) Say "      [OK]   $t" 'Green' }
function Warn  { param([string]$t) Say "      [!]    $t" 'Yellow' }
function Fail  { param([string]$t) Say "      [FEHL] $t" 'Red' }
function Info  { param([string]$t) Say "      $t" 'DarkGray' }

function Titel {
    param([string]$Nr, [string]$Text)
    # Breite genau passend zum Rahmen (62 Zeichen innen) berechnen, sonst
    # steht der rechte Rand je nach Laenge von Nummer und Titel schief.
    $breite = 56 - $Nr.Length
    if ($Text.Length -gt $breite) { $Text = $Text.Substring(0, $breite) }
    Write-Host ""
    Write-Host "  +--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ("  |  [{0}]  {1}" -f $Nr, $Text.PadRight($breite)) -ForegroundColor Cyan -NoNewline
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "  +--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Key {
    Write-LogPuffer
    Write-Host ""
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   Taste druecken um zum Menue zurueckzukehren..." -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
    catch { $null = Read-Host }   # Falls die Konsole keine Einzeltasten kann
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Frage-JaNein {
    param([string]$Text)
    $a = Read-Host $Text
    return ($a -match '^\s*[jJyY]')
}

# ---- Windows-Dialoge oeffnen ------------------------------------------------
# Der Weg von Hand wird IMMER mit ausgegeben. Zum einen weiss der Nutzer dann
# beim naechsten Mal selbst, wohin - zum anderen bleibt ein Ausweg, falls das
# Oeffnen scheitert (Gruppenrichtlinie, ausgeblendete Einstellungsseite).
function Oeffne-Windows {
    param([string]$Was, [string]$Datei, [string[]]$Argumente, [string]$VonHand = '')
    if (-not $Argumente) { $Argumente = @() }
    if ($VonHand) { Info "Von Hand:  $VonHand" }
    try {
        if ($Argumente.Count -gt 0) { Start-Process -FilePath $Datei -ArgumentList $Argumente -ErrorAction Stop }
        else                        { Start-Process -FilePath $Datei -ErrorAction Stop }
        Ok "geoeffnet: $Was"
        return $true
    } catch {
        Fail "$Was liess sich nicht oeffnen."
        if ($VonHand) { Warn "Bitte von Hand oeffnen:  $VonHand" }
        return $false
    }
}

# Alle Orte, an die das Werkzeug den Nutzer schicken kann - an einer Stelle,
# damit Menue und Einzelaktionen dieselben Wege benutzen.
$Script:Ziele = @(
    @{ Nr='1'; Was='Sound - Wiedergabe (Lautsprecher, Kopfhoerer)'
       Datei='control'; Arg=@('mmsys.cpl,,0'); Hand='Win+R  ->  mmsys.cpl'
       Tipp='Geraet -> Als Standard. Eigenschaften -> Erweitert -> 16 Bit, 48000 Hz.' },
    @{ Nr='2'; Was='Sound - Aufnahme (Mikrofon)'
       Datei='control'; Arg=@('mmsys.cpl,,1'); Hand='Win+R  ->  mmsys.cpl  ->  Reiter Aufnahme'
       Tipp='Mikro als Standard UND als Standard-Kommunikationsgeraet. Pegel nicht 0.' },
    @{ Nr='3'; Was='Bluetooth-Einstellungen'
       Datei='ms-settings:bluetooth'; Arg=@(); Hand='Einstellungen  ->  Bluetooth und Geraete'
       Tipp='Headset trennen und neu verbinden, damit Windows auf Stereo umschaltet.' },
    @{ Nr='4'; Was='Geraete und Drucker (Bluetooth-Dienste)'
       Datei='control'; Arg=@('printers'); Hand='Win+R  ->  control printers'
       Tipp='Rechtsklick aufs Headset -> Eigenschaften -> Dienste -> "Freisprechtelefonie".' },
    @{ Nr='5'; Was='Geraete-Manager'
       Datei='devmgmt.msc'; Arg=@(); Hand='Win+X  ->  Geraete-Manager'
       Tipp='Unter "Audioeingaenge und -ausgaenge" stehen die Kopfhoerer und Mikrofone.' },
    @{ Nr='6'; Was='Datum und Uhrzeit'
       Datei='ms-settings:dateandtime'; Arg=@(); Hand='Einstellungen  ->  Zeit und Sprache'
       Tipp='"Jetzt synchronisieren". Eine falsche Uhr bricht die CoD-Anmeldung.' },
    @{ Nr='7'; Was='Energieoptionen'
       Datei='powercfg.cpl'; Arg=@(); Hand='Win+R  ->  powercfg.cpl'
       Tipp='Energiesparmodus bremst die CPU. Ausbalanciert oder Hoechstleistung waehlen.' },
    @{ Nr='8'; Was='Programme und Features'
       Datei='appwiz.cpl'; Arg=@(); Hand='Win+R  ->  appwiz.cpl'
       Tipp='Hier steht, ob "Visual C++ 2015-2022 Redistributable (x64)" installiert ist.' },
    @{ Nr='9'; Was='Visual C++ Runtime herunterladen'
       Datei='https://aka.ms/vs/17/release/vc_redist.x64.exe'; Arg=@(); Hand='aka.ms/vs/17/release/vc_redist.x64.exe'
       Tipp='Oeffnet den Download im Browser. Danach installieren und PC neu starten.' },
    @{ Nr='10'; Was='Activision - Kontoverknuepfung'
       Datei='https://profile.callofduty.com/cod/login'; Arg=@(); Hand='profile.callofduty.com'
       Tipp='Einstellungen -> Verknuepfte Konten: Steam bzw. Battle.net muss dort stehen.' },
    @{ Nr='11'; Was='Activision - Kontosperre pruefen'
       Datei='https://support.activision.com/de/enforcement'; Arg=@(); Hand='support.activision.com/de/enforcement'
       Tipp='Eine Sperre zeigt sich oft als stumm haengender Login.' },
    @{ Nr='12'; Was='Activision - Serverstatus'
       Datei='https://support.activision.com/onlineservices'; Arg=@(); Hand='support.activision.com/onlineservices'
       Tipp='Liegt es an den Servern, hilft am eigenen PC gar nichts.' },
    @{ Nr='13'; Was='Steam - Spieldateien pruefen (Call of Duty)'
       Datei='steam://validate/1938090'; Arg=@(); Hand='Steam -> Rechtsklick aufs Spiel -> Eigenschaften -> Installierte Dateien'
       Tipp='Laedt kaputte oder fehlende Dateien nach. Dauert je nach Platte 5 bis 20 Minuten.' }
)

function Oeffne-Ziel {
    param([string]$Nr)
    $z = $Script:Ziele | Where-Object { $_.Nr -eq $Nr } | Select-Object -First 1
    if (-not $z) { return $false }
    return (Oeffne-Windows -Was $z.Was -Datei $z.Datei -Argumente $z.Arg -VonHand $z.Hand)
}

# Fragt vorher. Nur fuer Dinge, die nach aussen wirken - etwa einen Download
# starten. Windows-Fenster werden ohne Rueckfrage geoeffnet.
function Frage-Oeffnen {
    param([string]$Nr, [string]$Frage)
    $z = $Script:Ziele | Where-Object { $_.Nr -eq $Nr } | Select-Object -First 1
    if (-not $z) { return }
    Write-Host ""
    if (Frage-JaNein "     $Frage (j/n)") { $null = Oeffne-Ziel -Nr $Nr }
    else { Info "Spaeter von Hand:  $($z.Hand)" }
}

# Nummerierte Klickanleitung in einem auffaelligen Kasten. Leerstring in der
# Liste erzeugt eine Leerzeile und zaehlt nicht mit.
function Zeige-Schritte {
    param([string]$Ueberschrift, [string[]]$Schritte)
    if ($Ueberschrift.Length -gt 58) { $Ueberschrift = $Ueberschrift.Substring(0,58) }
    Write-Host ""
    Write-Host "   +------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ("   |  {0}|" -f $Ueberschrift.PadRight(58)) -ForegroundColor Yellow
    Write-Host "   +------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    $i = 0
    foreach ($s in $Schritte) {
        if ([string]::IsNullOrEmpty($s)) { Write-Host ""; continue }
        $i++
        Write-Host ("     {0,2}.  " -f $i) -ForegroundColor Cyan -NoNewline
        Write-Host $s -ForegroundColor White
    }
    Write-Host ""
}

# Zeigt die Anleitung und oeffnet das passende Fenster gleich mit. Bewusst
# OHNE Rueckfrage: wer hier gelandet ist, muss ohnehin dorthin - und soll
# nicht selbst suchen muessen, wo in Windows das steht.
function Oeffne-Mit-Anleitung {
    param([string]$Nr, [string]$Ueberschrift, [string[]]$Schritte)
    $z = $Script:Ziele | Where-Object { $_.Nr -eq $Nr } | Select-Object -First 1
    if (-not $z) { return }
    Zeige-Schritte -Ueberschrift $Ueberschrift -Schritte $Schritte
    Say "      Das Fenster geht jetzt von selbst auf..." 'Gray'
    Start-Sleep -Seconds 2
    $null = Oeffne-Windows -Was $z.Was -Datei $z.Datei -Argumente $z.Arg -VonHand $z.Hand
    Write-Host ""
    Info 'Findest du das Fenster nicht? Es kann HINTER diesem hier liegen -'
    Info 'unten in der Taskleiste nachsehen oder Alt+Tab druecken.'
}

# Ruft ein Windows-Programm auf und prueft den Rueckgabewert. Wichtig, weil
# try/catch bei Programmen wie netsh oder powercfg NICHT greift - die melden
# Fehler ueber den Exit-Code, nicht ueber eine PowerShell-Ausnahme.
function Invoke-Tool {
    param(
        [string]$Was,
        [string]$Datei,
        [string[]]$Argumente = @(),
        [switch]$Weich          # Fehler nur als Hinweis, nicht als Fehlschlag
    )
    try {
        $null = & $Datei @Argumente
    } catch {
        Fail ("{0} - {1}" -f $Was, $_.Exception.Message)
        return $false
    }
    if ($LASTEXITCODE -eq 0) { Ok $Was; return $true }
    if ($Weich) { Warn ("{0} - uebersprungen (Code {1})" -f $Was, $LASTEXITCODE) }
    else        { Fail ("{0} - fehlgeschlagen (Code {1})" -f $Was, $LASTEXITCODE) }
    return $false
}

function Get-FolderSize {
    param([string]$Pfad)
    try {
        $s = (Get-ChildItem $Pfad -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum
        if ($s) { return [long]$s }
    } catch {}
    return 0L
}

function Get-FreeSpace {
    param([string]$Pfad)
    try {
        $q = (Split-Path $Pfad -Qualifier)          # z.B. "C:"
        return [long](New-Object System.IO.DriveInfo($q)).AvailableFreeSpace
    } catch { return 0L }
}

# Erreichbarkeitstest mit hartem Zeitlimit. Test-NetConnection kennt keins und
# laesst die Diagnose bei einem toten Host sehr lange haengen.
function Test-Port {
    param([string]$Ziel, [int]$Port = 443, [int]$TimeoutMs = 3000)
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $c.BeginConnect($Ziel, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        $c.EndConnect($iar)
        return $true
    } catch { return $false }
    finally { try { $c.Close() } catch {} }
}

# ========================= PFADE AUTOMATISCH FINDEN ===========================

function Get-SteamPath {
    foreach ($k in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')) {
        $v = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
        foreach ($n in @('SteamPath','InstallPath')) {
            if ($v.$n -and (Test-Path $v.$n)) { return (Resolve-Path $v.$n).Path }
        }
    }
    return $null
}

function Get-SteamLibraries {
    $steam = Get-SteamPath
    if (-not $steam) { return @() }
    $libs = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $p = $m.Groups[1].Value -replace '\\\\','\'
            if ((Test-Path $p) -and ($libs -notcontains $p)) { $libs += $p }
        }
    }
    return $libs
}

# Ordnernamen, unter denen Call of Duty installiert sein kann.
$Script:CodOrdner = @(
    'Call of Duty HQ','Call of Duty','Call of Duty Black Ops 6',
    'Call of Duty Black Ops 7','Call of Duty Warzone','Call of Duty Modern Warfare'
)

function Get-CodInstallPaths {
    $found = @()
    foreach ($lib in Get-SteamLibraries) {
        foreach ($n in $Script:CodOrdner) {
            $p = Join-Path $lib "steamapps\common\$n"
            if ((Test-Path $p) -and ($found -notcontains $p)) { $found += $p }
        }
    }
    # Battle.net und Handinstallationen: nur feste Laufwerke ansehen.
    # Netzlaufwerke koennen bei Test-Path minutenlang haengen.
    $unter = @()
    foreach ($basis in @('Program Files (x86)\','Program Files\','Games\','')) {
        foreach ($n in $Script:CodOrdner) { $unter += ($basis + $n) }
    }
    foreach ($dr in [System.IO.DriveInfo]::GetDrives()) {
        if ($dr.DriveType -ne [System.IO.DriveType]::Fixed) { continue }
        if (-not $dr.IsReady) { continue }
        foreach ($u in $unter) {
            $p = Join-Path $dr.RootDirectory.FullName $u
            if ((Test-Path $p) -and ($found -notcontains $p)) { $found += $p }
        }
    }
    return $found
}

# Steam-App-IDs der installierten CoD-Titel. Wird aus den appmanifest-Dateien
# gelesen, damit auch kuenftige Teile automatisch erkannt werden; die bekannten
# IDs bleiben als Rueckfallebene stehen.
function Get-CodSteamAppIds {
    param([string]$Library)
    $ids = @('1938090','1962663','2933620','3564780','2820290')
    $apps = Join-Path $Library 'steamapps'
    if (-not (Test-Path $apps)) { return $ids }
    foreach ($f in (Get-ChildItem $apps -Filter 'appmanifest_*.acf' -File -ErrorAction SilentlyContinue)) {
        $txt = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($txt -notmatch '"name"\s+"[^"]*Call of Duty') { continue }
        if ($f.BaseName -match '^appmanifest_(\d+)$') {
            $id = $Matches[1]
            if ($ids -notcontains $id) { $ids += $id }
        }
    }
    return $ids
}

function Get-CodDataPaths {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    @( (Join-Path $env:LOCALAPPDATA 'Activision'), (Join-Path $docs 'Call of Duty') ) |
        Where-Object { Test-Path $_ }
}

function Get-ActiveAdapter {
    $r = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
         Sort-Object RouteMetric | Select-Object -First 1
    if ($r) { return $r.InterfaceAlias }
    return $null
}

function Get-CodConfigFiles {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $dirs = @(
        (Join-Path $env:LOCALAPPDATA 'Activision\Call of Duty\players'),
        (Join-Path $docs 'Call of Duty\players')
    )
    $files = @()
    foreach ($d in $dirs) {
        if (Test-Path $d) {
            $files += Get-ChildItem $d -Filter 's.*.txt*' -File -ErrorAction SilentlyContinue |
                      Select-Object -ExpandProperty FullName
        }
    }
    return $files
}

# ========================= BACKUP / WIEDERHERSTELLEN ==========================

function New-BackupSet {
    param([string]$Name)
    Ensure-BackupRoot
    $dir = Join-Path $Script:BackupRoot ("{0}_{1}" -f $Name, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Get-LatestBackup {
    param([string]$Name)
    if (-not (Test-Path $Script:BackupRoot)) { return $null }
    Get-ChildItem $Script:BackupRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$Name`_*" } |
        Sort-Object Name -Descending | Select-Object -First 1
}

function Backup-Folder {
    param([string]$Source, [string]$BackupDir)
    if (-not (Test-Path $Source)) { return $false }
    $safe = ($Source -replace '[\\/:*?"<>|]','_')
    try {
        Copy-Item -Path $Source -Destination (Join-Path $BackupDir $safe) -Recurse -Force -ErrorAction Stop
        $Source | Out-File -FilePath (Join-Path $BackupDir "$safe.pfad") -Encoding utf8
        return $true
    } catch { Fail "Backup fehlgeschlagen: $Source"; return $false }
}

function Backup-Files {
    param([string[]]$Files, [string]$BackupDir)
    # Der reine Dateiname reicht nicht: dieselbe Datei (z.B. s.1.0.txt) liegt
    # oft in mehreren Profilordnern. Ohne laufende Nummer wuerde die zweite
    # die erste samt Pfadangabe ueberschreiben - und beim Wiederherstellen
    # landete der falsche Inhalt am falschen Ort.
    $i = 0
    foreach ($f in $Files) {
        $i++
        $name = '{0:d2}_{1}' -f $i, (Split-Path $f -Leaf)
        try {
            Copy-Item $f (Join-Path $BackupDir $name) -Force -ErrorAction Stop
            $f | Out-File -FilePath (Join-Path $BackupDir "$name.pfad") -Encoding utf8
        } catch { Fail "Backup fehlgeschlagen: $f" }
    }
}

function Restore-Files {
    param([string]$BackupDir)
    $n = 0
    foreach ($p in Get-ChildItem $BackupDir -Filter '*.pfad' -ErrorAction SilentlyContinue) {
        $ziel   = (Get-Content $p.FullName -Raw).Trim()
        $quelle = Join-Path $BackupDir $p.BaseName
        if (-not (Test-Path $quelle)) { continue }
        try {
            if (Test-Path $quelle -PathType Container) {
                if (Test-Path $ziel) { Remove-Item $ziel -Recurse -Force -ErrorAction Stop }
                $par = Split-Path $ziel -Parent
                if (-not (Test-Path $par)) { New-Item -ItemType Directory -Path $par -Force | Out-Null }
            }
            Copy-Item -Path $quelle -Destination $ziel -Recurse -Force -ErrorAction Stop
            Ok "wiederhergestellt: $(Split-Path $ziel -Leaf)"
            $n++
        } catch { Fail "$ziel  -  $($_.Exception.Message)" }
    }
    return $n
}

# --- Registry-Werte sichern und zurueckspielen -------------------------------
# Die Zeile wird IMMER geschrieben, auch wenn der Wert vorher gar nicht
# existierte. Genau daran erkennt das Zurueckspielen, dass der Wert nicht
# gesetzt, sondern wieder entfernt werden muss. Fehlt die Zeile, bliebe eine
# von uns angelegte Einstellung fuer immer stehen - "rueckgaengig" waere
# dann nur die halbe Wahrheit.
function Save-RegValue {
    param([string]$Pfad, [string]$Name, [string]$Datei)
    $alt = (Get-ItemProperty -Path $Pfad -Name $Name -ErrorAction SilentlyContinue).$Name
    ("{0}`t{1}`t{2}" -f $Pfad, $Name, $alt) | Out-File -FilePath $Datei -Append -Encoding utf8
}

function Restore-RegValues {
    param(
        [string]$Datei,
        [ValidateSet('DWord','String')][string]$Typ = 'DWord'
    )
    if (-not (Test-Path $Datei)) { return 0 }
    $n = 0
    foreach ($z in (Get-Content $Datei -ErrorAction SilentlyContinue)) {
        $t = $z -split "`t"
        if ($t.Count -lt 3) { continue }
        $ziel = $t[0]
        # Sicherungen aelterer Versionen hielten bei Audiogeraeten den
        # Geraeteschluessel fest statt des Unterschluessels "Properties".
        # Werte der Form {GUID},N liegen immer dort - also nachziehen.
        if (($t[1] -match '^\{[0-9a-fA-F-]+\},\d+$') -and ($ziel -notmatch '\\Properties$')) {
            $ziel = Join-Path $ziel 'Properties'
        }
        try {
            if ([string]::IsNullOrWhiteSpace($t[2])) {
                Remove-ItemProperty -Path $ziel -Name $t[1] -ErrorAction SilentlyContinue
            } else {
                if (-not (Test-Path $ziel)) { New-Item -Path $ziel -Force | Out-Null }
                if ($Typ -eq 'DWord') {
                    Set-ItemProperty -Path $ziel -Name $t[1] -Value ([int]$t[2]) -Type DWord -ErrorAction Stop
                } else {
                    Set-ItemProperty -Path $ziel -Name $t[1] -Value $t[2] -Type String -ErrorAction Stop
                }
            }
            $n++
        } catch {}
    }
    return $n
}

# Setzt Werte in einer CoD-Konfigurationsdatei. So sehen die Zeilen wirklich
# aus (nachgesehen in s.1.0.cod25.txt0):
#
#     DisplayMode@0;22564;43096 = Fullscreen borderless window // one of Windowed, ...
#     WindowWidth@0;64387;12850 = 640 // 0 to 32767
#     VoiceOutputDevice@0;2059;35888 =
#     ^ Name      ^ Pruefsumme      ^ Wert                     ^ Kommentar
#
# Wichtig dabei:
#   - Werte stehen OHNE Anfuehrungszeichen und duerfen Leerzeichen enthalten
#   - die Pruefsumme hinter dem @ enthaelt Semikolons
#   - ein leerer Wert ist zulaessig
#   - der Kommentar hinter // ist optional
#
# Sollte eine kuenftige Fassung Werte doch einmal in Anfuehrungszeichen
# setzen, wird diese Schreibweise uebernommen statt sie plattzumachen.
function Set-ConfigValues {
    param([string]$File, [hashtable]$Values)

    $roh = [System.IO.File]::ReadAllText($File)
    # Zeilenenden der Datei beibehalten, statt sie pauschal umzuschreiben.
    $ende = "`n"
    if ($roh.Contains("`r`n")) { $ende = "`r`n" }
    $zeilen = $roh -split "`r?`n"

    $n = 0
    for ($i = 0; $i -lt $zeilen.Count; $i++) {
        foreach ($k in $Values.Keys) {
            if ($zeilen[$i] -notmatch "^(\s*$([regex]::Escape($k))(?:@\S+)?\s*=\s*)(.*)$") { continue }
            $kopf = $Matches[1]
            $rest = $Matches[2]

            # Kommentar abtrennen: er beginnt beim ersten "//". Steht der Wert
            # ausnahmsweise in Anfuehrungszeichen, wird erst dahinter gesucht,
            # damit ein "//" im Wert nicht faelschlich als Kommentar gilt.
            # Der Abstand vor dem "//" bleibt erhalten, damit die Datei
            # ausgerichtet bleibt wie zuvor.
            $wertAlt = $rest
            $komm    = ''
            $ab = 0
            if ($rest -match '^\s*"[^"]*"') { $ab = $Matches[0].Length }
            $j = $rest.IndexOf('//', $ab)
            if ($j -ge 0) {
                $wertAlt = $rest.Substring(0, $j)
                $komm    = $rest.Substring($j)
            }
            $abstand = $wertAlt.Length - $wertAlt.TrimEnd().Length
            $wertAlt = $wertAlt.TrimEnd()
            if ($komm) { $komm = (' ' * $abstand) + $komm }

            $wertNeu = [string]$Values[$k]
            if (($wertAlt -match '^".*"$') -and ($wertNeu -notmatch '^".*"$')) {
                $wertNeu = '"' + ($wertNeu -replace '"','') + '"'
            }

            $zeilen[$i] = $kopf + $wertNeu + $komm
            $n++
            break
        }
    }
    [System.IO.File]::WriteAllText($File, ($zeilen -join $ende), (New-Object System.Text.UTF8Encoding $false))
    return $n
}

# ============================ PROZESSE BEENDEN ================================

function Stop-GameAndLaunchers {
    param([switch]$LaunchersToo)
    Say "      Beende Call of Duty..." 'Gray'
    $codPaths = Get-CodInstallPaths
    # Gefunden wird in erster Linie ueber den PFAD: alles, was aus einem
    # CoD-Spielordner laeuft (cod.exe, bootstrapper.exe, CODBrokerService ...).
    #
    # Die Namensliste ist nur die Rueckfallebene fuer ein Spiel in einem
    # Ordner, den Get-CodInstallPaths nicht kennt - und sie ist bewusst
    # VERANKERT (^...$). Der fruehere Filter '^cod' traf auch "Code", also
    # Visual Studio Code, und hat es bei jeder Reparatur beendet, samt
    # ungespeicherter Arbeit. "bootstrapper" fehlt absichtlich: so heissen
    # viele fremde Installer; der von CoD liegt im Spielordner.
    $namen = '^(cod|cod\d+-cod|codCrashHandler|CODBrokerService|BlackOps\w*|ModernWarfare\w*)$'
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $pp = $null; try { $pp = $_.Path } catch {}
        if ($pp) {
            foreach ($c in $codPaths) {
                # StartsWith statt -like: Klammern im Pfad ("Program Files (x86)")
                # sind fuer -like Platzhalter. Der abschliessende \ verhindert,
                # dass "...\Call of Duty" auch "...\Call of DutyXYZ" trifft.
                if ($pp.StartsWith($c.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { return $true }
            }
        }
        return ($_.ProcessName -match $namen)
    }
    if ($procs) {
        foreach ($p in $procs) {
            Info "- $($p.ProcessName) (PID $($p.Id))"
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch {}
        }
        Start-Sleep -Seconds 4
        Ok "Spiel beendet"
    } else { Ok "Spiel laeuft nicht" }

    if ($LaunchersToo) {
        Say "      Beende Launcher (Steam / Battle.net)..." 'Gray'
        $lp = @()
        foreach ($n in @('steam','steamwebhelper','steamservice','Battle.net','Agent','BlizzardBrowser','Blizzard Error Handler')) {
            foreach ($p in (Get-Process -Name $n -ErrorAction SilentlyContinue)) {
                # "Agent" ist ein Allerweltsname - nur den von Battle.net nehmen.
                if ($n -eq 'Agent') {
                    $pp = $null; try { $pp = $p.Path } catch {}
                    if ("$pp" -notmatch 'Battle\.net|Blizzard') { continue }
                }
                $lp += $p
            }
        }
        # Namen vorher merken - nach dem Beenden lassen sie sich nicht mehr
        # zuverlaessig vom Prozessobjekt lesen.
        $namen = @{}
        foreach ($p in $lp) { $namen[$p.Id] = $p.ProcessName }

        # Erst hoeflich schliessen lassen: Steam und Battle.net schreiben beim
        # Beenden ihre Konfiguration weg. Hart abgeschossen kann sie beschaedigt
        # zurueckbleiben - ein Problem, das der Nutzer vorher nicht hatte.
        foreach ($p in $lp) { try { $null = $p.CloseMainWindow() } catch {} }
        if ($lp) { Start-Sleep -Seconds 5 }
        foreach ($p in $lp) {
            Info "- $($namen[$p.Id])"
            try {
                $p.Refresh()
                if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction Stop }
            } catch {}
        }
        if ($lp) { Start-Sleep -Seconds 2; Ok "Launcher beendet" } else { Ok "Kein Launcher aktiv" }
    }
}

# ============================== 1  LOGIN ======================================

function Action-1 {
    Titel '1' 'LOGIN-CACHE UND PROFIL ZURUECKSETZEN'
    Warn 'Grafik- und Tasteneinstellungen werden zurueckgesetzt.'
    Warn 'Ein Backup wird vorher automatisch angelegt.'
    Write-Host ""

    Stop-GameAndLaunchers -LaunchersToo

    # Groesse und freien Platz pruefen, BEVOR kopiert wird. Der Ordner
    # "Activision" kann mehrere Gigabyte gross sein - ein Backup, das
    # mittendrin die Systemplatte volllaeuft, waere schlimmer als das
    # urspruengliche Problem.
    $quellen = @(Get-CodDataPaths)
    $gross = 0L
    foreach ($p in $quellen) { $gross += Get-FolderSize -Pfad $p }
    if ($gross -gt 0) {
        Info ("Zu sichern: {0:N1} GB" -f ($gross/1GB))
        $frei = Get-FreeSpace -Pfad $Script:BackupRoot
        if (($frei -gt 0) -and ($frei -lt ($gross * 1.2))) {
            Fail ("Zu wenig Platz fuer das Backup - frei: {0:N1} GB, noetig: rund {1:N1} GB." -f ($frei/1GB), ($gross*1.2/1GB))
            Warn 'Bitte Platz schaffen und erneut versuchen. Es wurde nichts geaendert.'
            return
        }
        if ($gross -gt 2GB) {
            Warn ("Das Backup ist {0:N1} GB gross und dauert entsprechend." -f ($gross/1GB))
            if (-not (Frage-JaNein "     Trotzdem fortfahren? (j/n)")) {
                Info 'Abgebrochen - es wurde nichts geaendert.'
                return
            }
        }
    }

    $bk = New-BackupSet -Name '1_Profil'

    Say "      Backup anlegen..." 'Gray'
    $gesichert = @()
    foreach ($p in $quellen) {
        if (Backup-Folder -Source $p -BackupDir $bk) { Ok "gesichert: $p"; $gesichert += $p }
    }
    if ($gesichert.Count -eq 0) { Info "nichts zu sichern gefunden" }

    # Nur loeschen, was auch wirklich gesichert wurde. Alles andere waere
    # ein Datenverlust ohne Rueckweg.
    Say "      Profildaten loeschen..." 'Gray'
    foreach ($p in $quellen) {
        if ($gesichert -notcontains $p) {
            Warn "uebersprungen (kein Backup): $p"
            continue
        }
        try { Remove-Item $p -Recurse -Force -ErrorAction Stop; Ok "geloescht: $p" }
        catch { Fail $p }
    }

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"
    Write-Host ""
    Warn 'Jetzt Steam/Battle.net starten und das Spiel starten.'
    Warn 'Der erste Start dauert LANGE (Shader werden neu gebaut) -'
    Warn 'auch wenn das Bild minutenlang schwarz bleibt: NICHT abbrechen!'
}

function Action-1b {
    Titel '1b' 'PROFIL-RESET RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '1_Profil'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }
    Info "Backup: $($bk.Name)"
    Stop-GameAndLaunchers
    $n = Restore-Files -BackupDir $bk.FullName
    if ($n -gt 0) { Ok "$n Ordner wiederhergestellt." } else { Warn "Nichts wiederhergestellt." }
}

# ============================== 2  SHADER =====================================

function Action-2 {
    Titel '2' 'SHADER-CACHE LOESCHEN'
    Write-Host ""

    Stop-GameAndLaunchers

    Say "      Steam Shader-Cache..." 'Gray'
    $g = 0
    foreach ($lib in Get-SteamLibraries) {
        $sc = Join-Path $lib 'steamapps\shadercache'
        if (-not (Test-Path $sc)) { continue }
        $ids = Get-CodSteamAppIds -Library $lib
        foreach ($d in Get-ChildItem $sc -Directory -ErrorAction SilentlyContinue) {
            if ($ids -notcontains $d.Name) { continue }
            try { Remove-Item $d.FullName -Recurse -Force -ErrorAction Stop; Ok "geloescht: $($d.Name)"; $g++ } catch {}
        }
    }
    if ($g -eq 0) { Info "keiner vorhanden" }

    Say "      Spiel-Caches..." 'Gray'
    foreach ($inst in Get-CodInstallPaths) {
        foreach ($n in @('shadercache','xpak_cache','telescopeCache','D3D12')) {
            $p = Join-Path $inst $n
            if (Test-Path $p) { try { Remove-Item $p -Recurse -Force -ErrorAction Stop; Ok "geloescht: $n" } catch {} }
        }
    }

    Say "      Windows- und Treiber-Caches..." 'Gray'
    $dx = Join-Path $env:LOCALAPPDATA 'D3DSCache'
    if (Test-Path $dx) {
        try { Remove-Item $dx -Recurse -Force -ErrorAction Stop; Ok "DirectX-Shader-Cache geleert" }
        catch { Info "DirectX-Cache teilweise gesperrt (unkritisch)" }
    }
    foreach ($p in @('NVIDIA\DXCache','NVIDIA\GLCache','AMD\DxCache','AMD\GLCache')) {
        $full = Join-Path $env:LOCALAPPDATA $p
        if (Test-Path $full) { try { Remove-Item "$full\*" -Recurse -Force -ErrorAction Stop; Ok "geleert: $p" } catch {} }
    }

    Write-Host ""
    Ok "FERTIG"
    Write-Host ""
    Warn 'Der naechste Spielstart dauert DEUTLICH laenger als sonst.'
    Warn 'Das Bild kann dabei minutenlang schwarz bleiben - das ist'
    Warn 'normal. NICHT abbrechen, sonst faengt alles von vorne an!'
}

function Action-2b {
    Titel '2b' 'SHADER-CACHE'
    Ok 'Hier ist kein Rueckgaengig noetig.'
    Info 'Die Caches bauen sich beim naechsten Spielstart'
    Info 'automatisch komplett neu auf.'
}

# ============================== 3  BILD =======================================

function Action-3 {
    Titel '3' 'BILD SCHWARZ - GRAFIK AUF SICHERE WERTE'
    Write-Host ""

    Stop-GameAndLaunchers
    $files = Get-CodConfigFiles
    if (-not $files) { Fail "Keine Konfigurationsdateien gefunden."; Info "Starte das Spiel einmal, dann erneut versuchen."; return }

    $bk = New-BackupSet -Name '3_Grafik'
    Backup-Files -Files $files -BackupDir $bk
    Info "Backup: $bk"

    $werte = @{
        'DisplayMode'='Windowed'; 'WindowX'='50'; 'WindowY'='50'
        'WindowWidth'='1600'; 'WindowHeight'='900'; 'WindowMaximized'='false'
        'HDR'='Off'; 'GPUUploadHeaps'='false'; 'NvidiaReflex'='Disabled'
        'NVIDIAImageScalingMP'='false'; 'DLSSFrameGeneration'='false'
        'DynamicSceneResolution'='false'; 'VolumetricQuality'='QUALITY_LOW'
    }
    foreach ($f in $files) { Ok "$(Set-ConfigValues -File $f -Values $werte) Werte gesetzt in $(Split-Path $f -Leaf)" }

    Write-Host ""
    Ok "FERTIG"
    Write-Host ""
    Warn 'Das Spiel startet jetzt als kleines Fenster (1600x900).'
    Warn 'Sobald du ein Bild hast: im Spielmenue unter Grafik wieder'
    Warn 'auf Vollbild und deine Wunschqualitaet stellen.'
}

function Action-3b {
    Titel '3b' 'GRAFIK-EINSTELLUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '3_Grafik'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }
    Stop-GameAndLaunchers
    Ok "$(Restore-Files -BackupDir $bk.FullName) Dateien wiederhergestellt."
}

# ============================== 4  AUDIO ======================================

$Script:AudioRender  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
$Script:AudioCapture = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture'

$Script:AudioKeys = @(
    '{b3f8fa53-0004-438e-9003-51a46e139bfc},3',   # Exklusivmodus erlauben
    '{b3f8fa53-0004-438e-9003-51a46e139bfc},4',   # Exklusivmodus hat Vorrang
    '{e4870e26-3cc5-4cd2-ba46-ca0a9a70ed04},6'    # Raumklang / Spatial
)

# Die beiden Haken aus dem Reiter "Erweitert" eines Geraetes:
#   ,3 = "Anwendungen haben alleinige Kontrolle ueber dieses Geraet"
#   ,4 = "Anwendungen im Exklusivmodus Vorrang geben"
# Windows hat beide standardmaessig AN. Steht ein Spiel oder Discord im
# Exklusivmodus, bekommt der Rest keinen Ton mehr - eine der haeufigsten
# Ursachen fuer Knacken und Aussetzer.
$Script:ExklusivKeys = @(
    '{b3f8fa53-0004-438e-9003-51a46e139bfc},3',
    '{b3f8fa53-0004-438e-9003-51a46e139bfc},4'
)

# Eigenschaften eines Endpunktes
$Script:PropEndpunkt = '{a45c254e-df1c-4efd-8020-67d146a850e0},2'   # "Kopfhoerer"
$Script:PropGeraet   = '{b3f8fa53-0004-438e-9003-51a46e139bfc},6'   # "Bose Hands-Free"

# DeviceState ist eine BITMASKE, kein einfacher Wert. In den oberen Bits legt
# Windows eigene Flags ab - auf einem normalen PC steht dort z.B. 0x10000001
# statt 1. Wer auf "-eq 1" oder "-eq 2" prueft, findet deshalb gar nichts, und
# wer einfach 1 hineinschreibt, loescht die oberen Flags mit weg.
# Nur die unteren vier Bit beschreiben den Zustand:
$Script:ZustandMaske = 0xF
$Script:ZustandText  = @{ 1 = 'aktiv'; 2 = 'deaktiviert'; 4 = 'nicht vorhanden'; 8 = 'nicht verbunden' }

# Bluetooth-Freisprechprofil (Hands-Free Audio Gateway). Die UUID ist fest
# vergeben und damit ein verlaesslicheres Merkmal als jeder Geraetename.
$Script:HfpUuid    = '{0000111E-0000-1000-8000-00805F9B34FB}'
$Script:HfpMuster  = 'hands.?free|freisprech|hfp\b|headset ag'

function Get-RegProp {
    param($Objekt, [string]$Name)
    if (-not $Objekt) { return $null }
    $p = $Objekt.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

function Get-AudioDevices {
    $keys = @()
    foreach ($r in @($Script:AudioRender, $Script:AudioCapture)) {
        if (Test-Path $r) { $keys += (Get-ChildItem $r -ErrorAction SilentlyContinue).PSPath }
    }
    return $keys
}

function Get-AudioName {
    param([string]$Dev)
    $v = Get-ItemProperty -Path (Join-Path $Dev 'Properties') -ErrorAction SilentlyContinue
    $n = Get-RegProp $v $Script:PropEndpunkt
    if ($n) { return $n }
    return '(unbenannt)'
}

# Liefert alle Audio-Endpunkte mit Name, Zustand und Exklusivmodus.
function Get-AudioEndpoints {
    $liste = @()
    foreach ($w in @(@{ Art = 'WIEDERGABE'; Pfad = $Script:AudioRender },
                     @{ Art = 'AUFNAHME';   Pfad = $Script:AudioCapture })) {
        if (-not (Test-Path $w.Pfad)) { continue }
        foreach ($d in (Get-ChildItem $w.Pfad -ErrorAction SilentlyContinue)) {
            $roh = (Get-ItemProperty $d.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
            if ($null -eq $roh) { continue }
            $eigen = Join-Path $d.PSPath 'Properties'
            $p     = Get-ItemProperty $eigen -ErrorAction SilentlyContinue

            $name   = Get-RegProp $p $Script:PropEndpunkt ; if (-not $name)   { $name   = '(unbenannt)' }
            $geraet = Get-RegProp $p $Script:PropGeraet   ; if (-not $geraet) { $geraet = '(unbekannt)' }

            # Exklusivmodus: fehlt der Wert, ist er bei Windows AN.
            $ex = $true
            foreach ($k in $Script:ExklusivKeys) {
                if ((Get-RegProp $p $k) -eq 0) { $ex = $false }
            }

            $z   = [int]$roh -band $Script:ZustandMaske
            $txt = $Script:ZustandText[$z] ; if (-not $txt) { $txt = "unbekannt ($z)" }

            $liste += [pscustomobject]@{
                Art        = $w.Art
                Schluessel = $d.PSPath
                Eigen      = $eigen
                Name       = $name
                Geraet     = $geraet
                Anzeige    = "$name ($geraet)"
                RohZustand = [int]$roh
                Zustand    = $z
                ZustandTxt = $txt
                Exklusiv   = $ex
            }
        }
    }
    return $liste
}

# Schaltet einen Endpunkt an oder aus. Die oberen Bits von DeviceState bleiben
# dabei unangetastet - dort stehen Flags, die Windows selbst verwaltet.
function Set-AudioEndpointState {
    param($Endpunkt, [ValidateSet('An','Aus')][string]$Auf, [string]$Datei)
    $ziel = 2
    if ($Auf -eq 'An') { $ziel = 1 }
    if ($Datei) { Save-RegValue -Pfad $Endpunkt.Schluessel -Name 'DeviceState' -Datei $Datei }
    $neu = ($Endpunkt.RohZustand -band (-bnot $Script:ZustandMaske)) -bor $ziel
    try {
        Set-ItemProperty -Path $Endpunkt.Schluessel -Name 'DeviceState' -Value $neu -Type DWord -ErrorAction Stop
        return $true
    } catch {
        Fail "kein Zugriff: $($Endpunkt.Anzeige)"
        return $false
    }
}

function Set-AudioExklusiv {
    param($Endpunkt, [ValidateSet('An','Aus')][string]$Auf, [string]$Datei)
    $wert = 0
    if ($Auf -eq 'An') { $wert = 1 }
    $ok = $true
    foreach ($k in $Script:ExklusivKeys) {
        if ($Datei) { Save-RegValue -Pfad $Endpunkt.Eigen -Name $k -Datei $Datei }
        try { Set-ItemProperty -Path $Endpunkt.Eigen -Name $k -Value $wert -Type DWord -ErrorAction Stop }
        catch { $ok = $false }
    }
    if (-not $ok) { Fail "kein Zugriff: $($Endpunkt.Anzeige)" }
    return $ok
}

# ---- Geraete-Manager-Ebene --------------------------------------------------
# Der Geraete-Manager schaltet das GANZE Geraet ab, die Sound-Einstellungen nur
# einen einzelnen Ein- oder Ausgang davon. Deshalb wirkt der Geraete-Manager
# gruendlicher - und deshalb kann man hier auch mehr kaputt machen.
#
# Der Zustand steht in "Problem" und ist eindeutig:
#   CM_PROB_NONE      Geraet laeuft
#   CM_PROB_DISABLED  von Hand abgeschaltet
#   CM_PROB_PHANTOM   Karteileiche: war mal da, ist nicht mehr angeschlossen
#
# Bewusst NUR die Klasse MEDIA: das sind die eigentlichen Geraete (Soundkarte,
# Headset, USB-Mikrofon). Die Klasse AudioEndpoint waeren dieselben Ein- und
# Ausgaenge, die weiter unten ohnehin schon stehen - sie doppelt anzuzeigen
# verwirrt nur.
$Script:AudioKlassen = @('MEDIA')

function Get-AudioPnpDevices {
    $liste = @()
    $roh = @()
    try { $roh = @(Get-PnpDevice -ErrorAction Stop | Where-Object { $_.Class -in $Script:AudioKlassen }) }
    catch { return @() }

    foreach ($d in $roh) {
        # "Problem" gibt es erst ab Windows 10 1809. Fehlt es, muss der
        # Status herhalten - der ist gruober, aber immer vorhanden.
        $prob = Get-RegProp $d 'Problem'
        $zustand = ''
        if ($prob) {
            switch ("$prob") {
                'CM_PROB_PHANTOM'  { $zustand = 'weg' }
                'CM_PROB_DISABLED' { $zustand = 'aus' }
                'CM_PROB_NONE'     { $zustand = 'an'  }
                default            { $zustand = 'stoerung' }
            }
        } else {
            switch ("$($d.Status)") {
                'OK'      { $zustand = 'an'  }
                'Error'   { $zustand = 'aus' }
                'Unknown' { $zustand = 'weg' }
                default   { $zustand = 'stoerung' }
            }
        }
        if ($zustand -eq 'weg') { continue }   # Karteileichen nicht anbieten

        $liste += [pscustomobject]@{
            Name       = $d.FriendlyName
            Klasse     = $d.Class
            InstanceId = $d.InstanceId
            Zustand    = $zustand
        }
    }

    # Manche Treiber melden mehrere Geraete unter demselben Namen. Ohne
    # Unterscheidung waeren zwei identische Zeilen in der Liste - der Nutzer
    # koennte nicht sagen, welche er gerade erwischt hat.
    foreach ($gruppe in ($liste | Group-Object Name | Where-Object { $_.Count -gt 1 })) {
        $i = 0
        foreach ($d in $gruppe.Group) {
            $i++
            $d.Name = "$($d.Name)  [$i von $($gruppe.Count)]"
        }
    }
    return $liste
}

function Set-AudioPnpState {
    param($Geraet, [ValidateSet('An','Aus')][string]$Auf, [string]$Datei)
    if ($Datei) {
        ("{0}`t{1}`t{2}" -f $Geraet.InstanceId, $Geraet.Zustand, $Geraet.Name) |
            Out-File -FilePath $Datei -Append -Encoding utf8
    }
    try {
        if ($Auf -eq 'An') { Enable-PnpDevice  -InstanceId $Geraet.InstanceId -Confirm:$false -ErrorAction Stop }
        else               { Disable-PnpDevice -InstanceId $Geraet.InstanceId -Confirm:$false -ErrorAction Stop }
        return $true
    } catch {
        Fail "$($Geraet.Name) - $($_.Exception.Message)"
        return $false
    }
}

function Restart-AudioDienste {
    Say "      Audiodienste neu starten..." 'Gray'
    # Reihenfolge zaehlt: AudioEndpointBuilder zuerst, denn Audiosrv haengt
    # davon ab und wird beim Neustart des Ersteren mit gestoppt.
    foreach ($s in @('AudioEndpointBuilder','Audiosrv')) {
        try { Restart-Service -Name $s -Force -ErrorAction Stop; Ok "neu gestartet: $s" }
        catch { Fail "$s - $($_.Exception.Message)" }
    }
}

function Action-4 {
    Titel '4' 'TON REPARIEREN'
    Write-Host ""

    Stop-GameAndLaunchers
    $bk = New-BackupSet -Name '4_Audio'

    # 1. Exklusivmodus + Raumklang abschalten
    Say "      Exklusivmodus und Raumklang abschalten..." 'Gray'
    $regDatei = Join-Path $bk 'audio-registry.txt'
    $n = 0; $d = 0
    foreach ($dev in Get-AudioDevices) {
        $prop = Join-Path $dev 'Properties'
        if (-not (Test-Path $prop)) { continue }
        $treffer = $false
        foreach ($k in $Script:AudioKeys) {
            Save-RegValue -Pfad $prop -Name $k -Datei $regDatei
            try { Set-ItemProperty -Path $prop -Name $k -Value 0 -Type DWord -ErrorAction Stop; $n++; $treffer = $true } catch {}
        }
        if ($treffer) { Info "- $(Get-AudioName -Dev $dev)"; $d++ }
    }
    Ok "$d Geraete bearbeitet, $n Werte gesetzt"
    if ($n -eq 0) { Warn 'Keine Aenderung moeglich - fehlen die Adminrechte?' }

    # 2. Spiel-Audioeinstellungen
    Say "      Spiel-Audioeinstellungen zuruecksetzen..." 'Gray'
    $files = Get-CodConfigFiles
    if ($files) {
        Backup-Files -Files $files -BackupDir $bk
        $audio = @{
            'WindowsSonicEnable'='false'
            'AudioMix'='Home Theater'
            'VoiceVolume'='1.000000'
        }
        foreach ($f in $files) { Ok "$(Set-ConfigValues -File $f -Values $audio) Werte in $(Split-Path $f -Leaf)" }
    } else { Info "keine Spielkonfiguration gefunden" }

    # 3. Audiodienste neu starten
    Restart-AudioDienste

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"
    Write-Host ""
    Warn 'EIN SCHRITT FEHLT NOCH - und der ist der wichtigste.'
    Info 'Das Tonformat muss auf 16 Bit / 48000 Hz stehen. Das ist DER'
    Info 'Standardfix gegen Knacken bei Call of Duty. Automatisch laesst'
    Info 'es sich nicht sicher setzen - aber ich zeige dir genau, wo.'

    Oeffne-Mit-Anleitung -Nr '1' -Ueberschrift 'TONFORMAT EINSTELLEN - so gehst du vor' -Schritte @(
        'Warte, bis das Fenster "Sound" aufgeht',
        'Klicke deinen Kopfhoerer oder Lautsprecher an (einmal, blau markiert)',
        'Klicke unten rechts auf "Eigenschaften"',
        'Klicke oben auf den Reiter "Erweitert"',
        'Waehle im Auswahlfeld:  16 Bit, 48000 Hz (DVD-Qualitaet)',
        'Klicke "Uebernehmen", dann "OK", dann nochmal "OK"'
    )
}

function Action-4b {
    Titel '4b' 'TON-AENDERUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '4_Audio'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }

    $reg = Join-Path $bk.FullName 'audio-registry.txt'
    if (Test-Path $reg) {
        Ok "$(Restore-RegValues -Datei $reg -Typ DWord) Registry-Werte zurueckgesetzt"
    } else { Warn "Keine Registry-Sicherung vorhanden" }

    Ok "$(Restore-Files -BackupDir $bk.FullName) Konfigurationsdateien wiederhergestellt"
    Restart-AudioDienste
    Write-Host ""
    Warn 'Das Tonformat (16 Bit / 48000 Hz) musst du bei Bedarf'
    Warn 'selbst zuruecksetzen:  Win+R -> mmsys.cpl'
}

# ============================== 5  MIKROFON ===================================

$Script:MicPrivacyKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\NonPackaged',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone\NonPackaged'
)

function Action-5 {
    Titel '5' 'MIKROFON / VOICE-CHAT REPARIEREN'
    Write-Host ""

    Stop-GameAndLaunchers
    $bk = New-BackupSet -Name '5_Mikrofon'

    # --- 1. Windows-Datenschutz: Mikrofonzugriff erlauben ---
    Say "      Windows-Datenschutz: Mikrofonzugriff erlauben..." 'Gray'
    foreach ($k in $Script:MicPrivacyKeys) {
        if (-not (Test-Path $k)) {
            try { New-Item -Path $k -Force | Out-Null } catch { continue }
        }
        $alt = (Get-ItemProperty -Path $k -Name Value -ErrorAction SilentlyContinue).Value
        Save-RegValue -Pfad $k -Name 'Value' -Datei (Join-Path $bk 'mic-privacy.txt')
        try {
            Set-ItemProperty -Path $k -Name Value -Value 'Allow' -Type String -ErrorAction Stop
            $wo = 'Apps'
            if ($k -like '*NonPackaged') { $wo = 'Desktop-Apps (wichtig fuer CoD!)' }
            if ($alt -ne 'Allow') { Ok "freigeschaltet: $wo" } else { Info "war schon frei: $wo" }
        } catch { Fail "kein Zugriff auf $k" }
    }

    # --- 2. Deaktivierte Mikrofone wieder aktivieren ---
    # Der Zustand steht in den unteren vier Bit von DeviceState, der Rest sind
    # Windows-Flags. Frueher wurde hier direkt auf 1 bzw. 2 verglichen - das
    # trifft auf einem echten PC praktisch nie zu (dort steht z.B. 0x10000001),
    # weshalb nie ein deaktiviertes Mikrofon gefunden wurde.
    Say "      Deaktivierte Mikrofone suchen..." 'Gray'
    $akt = 0
    foreach ($e in (Get-AudioEndpoints | Where-Object { $_.Art -eq 'AUFNAHME' })) {
        if ($e.Zustand -eq 2) {
            if (Set-AudioEndpointState -Endpunkt $e -Auf 'An' -Datei (Join-Path $bk 'mic-state.txt')) {
                Ok "aktiviert: $($e.Anzeige)"; $akt++
            }
        } elseif ($e.Zustand -eq 1) {
            Info "aktiv: $($e.Anzeige)"
        }
    }
    if ($akt -eq 0) { Info "kein deaktiviertes Mikrofon gefunden" }

    # --- 3. Exklusivmodus fuer Aufnahmegeraete abschalten ---
    Say "      Exklusivmodus fuer Mikrofone abschalten..." 'Gray'
    $n = 0
    foreach ($e in (Get-AudioEndpoints | Where-Object { $_.Art -eq 'AUFNAHME' })) {
        if (Set-AudioExklusiv -Endpunkt $e -Auf 'Aus' -Datei (Join-Path $bk 'mic-exclusive.txt')) { $n++ }
    }
    Ok "$n Geraete auf gemeinsame Nutzung gestellt"

    # --- 4. Spiel: Mikrofon-Schwelle und Push-to-Talk ---
    Say "      Spiel-Voicechat einstellen..." 'Gray'
    $files = Get-CodConfigFiles
    if ($files) {
        Backup-Files -Files $files -BackupDir $bk
        # MicThreshold niedrig = Mikro reagiert auch bei leiser Stimme
        $voice = @{
            'MicThreshold'      = '0.001000'
            'VoicePushToTalk'   = 'false'
            'VoiceVolume'       = '1.000000'
            'VoiceOutputDevice' = ''
        }
        foreach ($f in $files) { Ok "$(Set-ConfigValues -File $f -Values $voice) Werte in $(Split-Path $f -Leaf)" }
        Info 'MicThreshold auf Minimum - das Mikro reagiert jetzt auch'
        Info 'bei leiser Stimme (haeufigste Ursache fuer "keiner hoert mich").'
    } else { Info "keine Spielkonfiguration gefunden" }

    # --- 5. Dienste neu starten ---
    Restart-AudioDienste

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"
    Write-Host ""
    Warn 'ZWEI DINGE MUSST DU NOCH SELBST PRUEFEN.'
    Info 'Beides laesst sich nicht zuverlaessig automatisch setzen.'

    Oeffne-Mit-Anleitung -Nr '2' -Ueberschrift 'MIKROFON PRUEFEN - so gehst du vor' -Schritte @(
        'Warte, bis das Fenster "Sound" mit dem Reiter "Aufnahme" aufgeht',
        'Klicke dein Mikrofon an (einmal, blau markiert)',
        'Klicke unten auf "Als Standard" - es bekommt einen gruenen Haken',
        'Klicke nochmal darauf und dann auf den kleinen Pfeil neben "Als Standard"',
        'Waehle dort ausserdem "Standard-Kommunikationsgeraet"',
        '',
        'Jetzt der Pegel: Mikrofon anklicken, unten auf "Eigenschaften"',
        'Reiter "Pegel" - der Schieber muss WEIT RECHTS stehen, nicht auf 0',
        'Durchgestrichenes Lautsprechersymbol daneben? Einmal draufklicken - dann ist das Mikro nicht mehr stumm',
        'Klicke "Uebernehmen", dann "OK", dann nochmal "OK"'
    )
    Write-Host ""
    Warn 'Zum Schluss noch im Spiel:'
    Info '  Einstellungen -> Audio -> Voicechat auf AN'
}

function Action-5b {
    Titel '5b' 'MIKROFON-AENDERUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '5_Mikrofon'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }

    # Datenschutz-Werte (Text)
    $f = Join-Path $bk.FullName 'mic-privacy.txt'
    if (Test-Path $f) { Ok "$(Restore-RegValues -Datei $f -Typ String) Datenschutz-Werte zurueckgesetzt" }

    # Geraetestatus und Exklusivmodus (DWORD)
    foreach ($name in @('mic-state.txt','mic-exclusive.txt')) {
        $f = Join-Path $bk.FullName $name
        if (Test-Path $f) { Ok "$(Restore-RegValues -Datei $f -Typ DWord) Werte aus $name zurueckgesetzt" }
    }

    Ok "$(Restore-Files -BackupDir $bk.FullName) Konfigurationsdateien wiederhergestellt"
    Restart-AudioDienste
}

# ====================== 11  BLUETOOTH-HEADSET RAUSCHT =========================

function Action-11 {
    Titel '11' 'BLUETOOTH-HEADSET RAUSCHT (HANDS-FREE)'
    Info 'Ein Bluetooth-Headset meldet sich mit ZWEI Profilen an:'
    Info ''
    Info '   A2DP (Stereo)      volle Klangqualitaet - aber ohne Mikrofon'
    Info '   Hands-Free (HFP)   mit Mikrofon - dafuer Telefonqualitaet'
    Info ''
    Info 'Beides gleichzeitig kann Bluetooth nicht. Sobald irgendetwas das'
    Info 'Headset-Mikrofon oeffnet, schaltet Windows auf Hands-Free um -'
    Info 'und der Ton wird schlagartig schlecht. Genau das passiert beim'
    Info 'Start des Voice-Chats.'
    Write-Host ""
    Warn 'Danach funktioniert das Mikrofon IM HEADSET nicht mehr.'
    Warn 'Fuer den Voice-Chat brauchst du dann ein anderes Mikrofon.'
    Warn 'Der Klang ueber die Kopfhoerer bleibt dafuer immer gut.'
    Write-Host ""

    # 1. Hands-Free-Endpunkte in der Registry
    $endpunkte = @(Get-AudioEndpoints | Where-Object {
        ($_.Zustand -eq 1) -and (("$($_.Geraet) $($_.Name)") -match $Script:HfpMuster)
    })

    # 2. Die Hands-Free-Geraete selbst, auf Geraete-Manager-Ebene. Genau das
    #    macht man von Hand im Geraete-Manager - und nur so bleibt es auch
    #    nach dem naechsten Verbinden abgeschaltet.
    #      BTHENUM\{0000111E-...}   das Freisprechprofil (fester UUID-Wert,
    #                               verlaesslicher als jeder Geraetename)
    #      BTHHFENUM\BTHHFPAUDIO    der zugehoerige Audiotreiber
    $dienste = @()
    try {
        $dienste = @(Get-PnpDevice -ErrorAction Stop | Where-Object {
            $laeuft = $false
            if ($_.Problem) { $laeuft = ("$($_.Problem)" -eq 'CM_PROB_NONE') }
            else            { $laeuft = ($_.Status -eq 'OK') }
            $laeuft -and (
                ($_.InstanceId -like "BTHENUM\$($Script:HfpUuid)*") -or
                ($_.InstanceId -like 'BTHHFENUM\BTHHFPAUDIO*')
            )
        })
    } catch { Info 'Geraeteliste nicht abfragbar - ueberspringe diesen Teil.' }

    if ((-not $endpunkte) -and (-not $dienste)) {
        Ok 'Kein aktives Hands-Free-Geraet gefunden.'
        Write-Host ""
        Info 'Moegliche Gruende:'
        Info '  - das Headset ist gerade nicht verbunden'
        Info '  - Hands-Free ist bereits abgeschaltet'
        Info '  - es ist kein Bluetooth-Headset (dann ist das hier nicht dein Problem)'
        Write-Host ""
        Info 'Schalte das Headset ein, verbinde es und versuche es erneut.'
        return
    }

    Say "      Gefunden:" 'Gray'
    foreach ($e in $endpunkte) { Info "- $($e.Art): $($e.Anzeige)" }
    foreach ($d in $dienste)   { Info "- Bluetooth-Dienst: $($d.FriendlyName)" }
    Write-Host ""
    if (-not (Frage-JaNein "     Hands-Free jetzt abschalten? (j/n)")) {
        Info 'Abgebrochen - es wurde nichts geaendert.'
        return
    }

    $bk = New-BackupSet -Name '11_HandsFree'

    Say "      Hands-Free-Endpunkte abschalten..." 'Gray'
    $n = 0
    foreach ($e in $endpunkte) {
        if (Set-AudioEndpointState -Endpunkt $e -Auf 'Aus' -Datei (Join-Path $bk 'hf-state.txt')) {
            Ok "abgeschaltet: $($e.Anzeige)"; $n++
        }
    }
    if ($n -eq 0 -and $endpunkte) { Warn 'Kein Endpunkt liess sich abschalten.' }

    Say "      Hands-Free-Geraete abschalten..." 'Gray'
    Info 'Das ist derselbe Schritt wie im Geraete-Manager von Hand.'
    Info 'Er haelt auch nach dem naechsten Verbinden - anders als das'
    Info 'blosse Abschalten in den Sound-Einstellungen.'
    foreach ($d in $dienste) {
        try {
            Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction Stop
            $d.InstanceId | Out-File (Join-Path $bk 'hf-pnp.txt') -Append -Encoding utf8
            Ok "abgeschaltet: $($d.FriendlyName)"
        } catch { Fail "$($d.FriendlyName) - $($_.Exception.Message)" }
    }

    Restart-AudioDienste

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"

    Oeffne-Mit-Anleitung -Nr '3' -Ueberschrift 'JETZT NOCH DAS HEADSET NEU VERBINDEN' -Schritte @(
        'Warte, bis die Bluetooth-Einstellungen aufgehen',
        'Suche dein Headset in der Liste',
        'Klicke auf die drei Punkte daneben und dann auf "Trennen"',
        'Warte kurz und klicke dann auf "Verbinden"',
        'Der Ton sollte jetzt deutlich besser klingen'
    )
    Write-Host ""
    Warn 'Und zum Schluss im Spiel:'
    Info '  Einstellungen -> Audio -> Mikrofon: dein ANDERES Mikrofon'
    Info '  auswaehlen (USB-Mikro, Webcam oder Klinkenanschluss).'
    Info '  Das Headset-Mikro steht ab jetzt nicht mehr zur Verfuegung -'
    Info '  dafuer klingt der Ton durchgehend gut.'
}

function Action-11b {
    Titel '11b' 'HANDS-FREE WIEDER EINSCHALTEN'
    $bk = Get-LatestBackup -Name '11_HandsFree'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }

    $f = Join-Path $bk.FullName 'hf-state.txt'
    if (Test-Path $f) { Ok "$(Restore-RegValues -Datei $f -Typ DWord) Endpunkte zurueckgesetzt" }

    $p = Join-Path $bk.FullName 'hf-pnp.txt'
    if (Test-Path $p) {
        foreach ($id in (Get-Content $p -ErrorAction SilentlyContinue)) {
            if ([string]::IsNullOrWhiteSpace($id)) { continue }
            try { Enable-PnpDevice -InstanceId $id.Trim() -Confirm:$false -ErrorAction Stop; Ok "eingeschaltet: $id" }
            catch { Fail "$id - $($_.Exception.Message)" }
        }
    }

    Restart-AudioDienste
    Write-Host ""
    Warn 'Headset einmal trennen und neu verbinden.'
}

# ====================== 12  AUDIOGERAETE AN- UND ABSCHALTEN ===================

function Show-AudioListe {
    param($Endpunkte, $Geraete)
    $i = 0
    $zuordnung = @{}

    # --- Ebene 1: ganze Geraete (wie im Geraete-Manager) ---
    Write-Host ""
    Write-Host "     GANZE GERAETE" -ForegroundColor Yellow
    Write-Host "     schaltet die Soundkarte oder das Headset KOMPLETT ab -" -ForegroundColor DarkGray
    Write-Host "     dasselbe wie im Geraete-Manager. Wirkt am gruendlichsten." -ForegroundColor DarkGray
    Write-Host ""
    foreach ($g in (@($Geraete) | Sort-Object Zustand, Name)) {
        $i++
        $zuordnung[$i] = @{ Typ = 'Geraet'; Obj = $g }
        $marke = '[ AUS ]'; $farbe = 'DarkGray'
        if ($g.Zustand -eq 'an') { $marke = '[ AN  ]'; $farbe = 'Green' }
        if ($g.Zustand -eq 'stoerung') { $marke = '[ ??? ]'; $farbe = 'Red' }
        $txt = $g.Name
        if ($txt.Length -gt 50) { $txt = $txt.Substring(0,47) + '...' }
        Write-Host ("      {0,2}  " -f $i) -ForegroundColor Cyan -NoNewline
        Write-Host "$marke " -ForegroundColor $farbe -NoNewline
        Write-Host $txt -ForegroundColor Gray
    }
    if (-not $Geraete) { Write-Host "       (keine gefunden)" -ForegroundColor DarkGray }

    # --- Ebene 2: einzelne Ein-/Ausgaenge (wie in den Sound-Einstellungen) ---
    Write-Host ""
    Write-Host "     EINZELNE EIN- UND AUSGAENGE" -ForegroundColor Yellow
    Write-Host "     die Liste, die du auch in den Sound-Einstellungen siehst." -ForegroundColor DarkGray
    foreach ($art in @('WIEDERGABE','AUFNAHME')) {
        $teil = @($Endpunkte | Where-Object { ($_.Art -eq $art) -and (($_.Zustand -eq 1) -or ($_.Zustand -eq 2)) })
        Write-Host ""
        Write-Host "      $art" -ForegroundColor White
        if (-not $teil) { Write-Host "       (keine)" -ForegroundColor DarkGray; continue }
        foreach ($e in ($teil | Sort-Object Zustand, Name)) {
            $i++
            $zuordnung[$i] = @{ Typ = 'Endpunkt'; Obj = $e }
            $marke = '[ AUS ]'; $farbe = 'DarkGray'
            if ($e.Zustand -eq 1) { $marke = '[ AN  ]'; $farbe = 'Green' }
            $ex = 'Exklusiv: aus'
            if ($e.Exklusiv) { $ex = 'Exklusiv: AN' }
            $txt = $e.Anzeige
            if ($txt.Length -gt 42) { $txt = $txt.Substring(0,39) + '...' }
            Write-Host ("      {0,2}  " -f $i) -ForegroundColor Cyan -NoNewline
            Write-Host "$marke " -ForegroundColor $farbe -NoNewline
            Write-Host $txt.PadRight(43) -ForegroundColor Gray -NoNewline
            Write-Host $ex -ForegroundColor DarkGray
        }
    }

    # Karteileichen nur zur Information. Loeschen geht nicht: auf diesen
    # Registry-Schluesseln haben Administratoren Schreib-, aber kein
    # Loeschrecht. Windows blendet sie aus, sobald man in den Sound-
    # Einstellungen "Getrennte Geraete anzeigen" abwaehlt.
    $alt = @($Endpunkte | Where-Object { ($_.Zustand -ne 1) -and ($_.Zustand -ne 2) })
    if ($alt) {
        Write-Host ""
        Write-Host "     NICHT VERBUNDEN  ($($alt.Count) alte Eintraege, nur zur Information)" -ForegroundColor DarkGray
        foreach ($e in ($alt | Select-Object -First 4)) {
            Write-Host "          $($e.Anzeige)" -ForegroundColor DarkGray
        }
        if ($alt.Count -gt 4) { Write-Host "          ... und $($alt.Count - 4) weitere" -ForegroundColor DarkGray }
    }

    Write-Host ""
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "      Zahl       an- oder abschalten" -ForegroundColor Gray
    Write-Host "      Zahl + e   Exklusivmodus umschalten, z.B. 5e" -ForegroundColor Gray
    Write-Host "                 (Haken 'Anwendungen haben alleinige Kontrolle'." -ForegroundColor DarkGray
    Write-Host "                  Steht er AN, kann ein Programm das Geraet fuer" -ForegroundColor DarkGray
    Write-Host "                  sich sperren - haeufige Ursache fuer Knacken.)" -ForegroundColor DarkGray
    Write-Host "      0          fertig" -ForegroundColor Gray
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    return $zuordnung
}

function Action-12 {
    # Kein Vorschaltbildschirm mit Erklaerung und "Taste druecken": das waere
    # eine Sackgasse zwischen Auswahl und Liste. Was man wissen muss, steht
    # direkt in der Liste an der Stelle, wo es gebraucht wird.
    $bk = $null   # Backup wird erst bei der ersten echten Aenderung angelegt

    while ($true) {
        $alle = @(Get-AudioEndpoints)
        $pnp  = @(Get-AudioPnpDevices)
        if ((-not $alle) -and (-not $pnp)) {
            Titel '12' 'AUDIOGERAETE AN- UND ABSCHALTEN'
            Fail 'Keine Audiogeraete gefunden.'
            return
        }

        Show-Kopf
        Write-Host "    AUDIOGERAETE AN- UND ABSCHALTEN" -ForegroundColor Yellow
        Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "     Abgeschaltete Geraete verschwinden aus Windows UND aus dem" -ForegroundColor DarkGray
        Write-Host "     Spiel. Bleibt nur eins uebrig, nimmt Windows automatisch das." -ForegroundColor DarkGray
        $zuordnung = Show-AudioListe -Endpunkte $alle -Geraete $pnp
        $w = (Read-Host "     Deine Wahl").Trim().ToLower()
        if (($w -eq '0') -or ($w -eq '')) { break }

        $exklusiv = $false
        $nr = $w
        if ($w -match '^(\d+)e$') { $exklusiv = $true; $nr = $Matches[1] }

        $idx = 0
        if (-not ([int]::TryParse($nr, [ref]$idx)) -or (-not $zuordnung.ContainsKey($idx))) {
            Write-Host ""
            Write-Host "     '$w' gibt es hier nicht. Bitte eine Zahl aus der Liste." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }

        $eintrag = $zuordnung[$idx]
        $obj     = $eintrag.Obj

        # --- Exklusivmodus gibt es nur bei einzelnen Ein-/Ausgaengen ---
        if ($exklusiv -and ($eintrag.Typ -ne 'Endpunkt')) {
            Write-Host ""
            Warn 'Den Exklusivmodus gibt es nur bei einzelnen Ein- und Ausgaengen,'
            Warn 'nicht beim ganzen Geraet. Waehle eine Zahl aus dem unteren Teil.'
            Start-Sleep -Seconds 3
            continue
        }

        # --- Schutz: nicht den letzten Lautsprecher abschalten ---
        if (-not $exklusiv) {
            $schaltetAb = $false
            if ($eintrag.Typ -eq 'Endpunkt') { $schaltetAb = ($obj.Zustand -eq 1) }
            else                             { $schaltetAb = ($obj.Zustand -eq 'an') }

            if ($schaltetAb) {
                $aktiveAusgaenge = @($alle | Where-Object { ($_.Art -eq 'WIEDERGABE') -and ($_.Zustand -eq 1) })
                $letzter = ($aktiveAusgaenge.Count -le 1)
                if ($eintrag.Typ -eq 'Endpunkt') { $letzter = ($letzter -and ($obj.Art -eq 'WIEDERGABE')) }

                if ($letzter) {
                    Write-Host ""
                    Warn 'ACHTUNG: Das ist dein LETZTER eingeschalteter Tonausgang.'
                    Warn 'Wenn du ihn abschaltest, hat der PC gar keinen Ton mehr -'
                    Warn 'auch nicht ausserhalb des Spiels.'
                    Info 'Rueckgaengig geht das jederzeit ueber Punkt 4b im Menue TON.'
                    Write-Host ""
                    if (-not (Frage-JaNein "     Wirklich abschalten? (j/n)")) {
                        Info 'Abgebrochen - nichts geaendert.'
                        Start-Sleep -Seconds 2
                        continue
                    }
                }
            }
        }

        if (-not $bk) { $bk = New-BackupSet -Name '12_Geraete' }
        Write-Host ""

        if ($exklusiv) {
            $ziel = 'Aus'; if (-not $obj.Exklusiv) { $ziel = 'An' }
            if (Set-AudioExklusiv -Endpunkt $obj -Auf $ziel -Datei (Join-Path $bk 'exklusiv.txt')) {
                Ok "Exklusivmodus $($ziel.ToLower()): $($obj.Anzeige)"
            }
        }
        elseif ($eintrag.Typ -eq 'Geraet') {
            $ziel = 'Aus'; if ($obj.Zustand -ne 'an') { $ziel = 'An' }
            Say "      Das kann ein paar Sekunden dauern..." 'Gray'
            if (Set-AudioPnpState -Geraet $obj -Auf $ziel -Datei (Join-Path $bk 'pnp.txt')) {
                Ok "Geraet $($ziel.ToLower()): $($obj.Name)"
            }
        }
        else {
            $ziel = 'Aus'; if ($obj.Zustand -ne 1) { $ziel = 'An' }
            if (Set-AudioEndpointState -Endpunkt $obj -Auf $ziel -Datei (Join-Path $bk 'endpunkte.txt')) {
                Ok "$($ziel.ToLower())geschaltet: $($obj.Anzeige)"
                Restart-AudioDienste
            }
        }
        Start-Sleep -Seconds 2
    }

    if ($bk) {
        Restart-AudioDienste
        Write-Host ""
        Ok "FERTIG"
        Info "Backup: $bk"
        Write-Host ""
        Warn 'EIN SCHRITT FEHLT NOCH.'
        Info 'Welches Geraet Windows benutzen SOLL, kann das Werkzeug nicht'
        Info 'fuer dich festlegen - das musst du einmal anklicken.'

        Oeffne-Mit-Anleitung -Nr '1' -Ueberschrift 'RICHTIGES GERAET AUSWAEHLEN' -Schritte @(
            'Warte, bis das Fenster "Sound" aufgeht',
            'Reiter "Wiedergabe": klicke das Geraet an, aus dem du hoeren willst',
            'Klicke unten auf "Als Standard" - es bekommt einen gruenen Haken',
            'Wechsle oben auf den Reiter "Aufnahme"',
            'Klicke dein Mikrofon an und wieder unten auf "Als Standard"',
            'Klicke "OK"'
        )
    } else {
        Info 'Es wurde nichts geaendert.'
    }
}

function Action-12b {
    Titel '12b' 'GERAETE-AENDERUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '12_Geraete'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }

    # 1. Ganze Geraete (Geraete-Manager-Ebene)
    $p = Join-Path $bk.FullName 'pnp.txt'
    if (Test-Path $p) {
        Say "      Ganze Geraete zuruecksetzen..." 'Gray'
        foreach ($z in (Get-Content $p -ErrorAction SilentlyContinue)) {
            $t = $z -split "`t"
            if ($t.Count -lt 2) { continue }
            $name = $t[0]; if ($t.Count -gt 2) { $name = $t[2] }
            try {
                # t[1] ist der Zustand VOR der Aenderung - genau dorthin zurueck.
                if ($t[1] -eq 'an') { Enable-PnpDevice  -InstanceId $t[0] -Confirm:$false -ErrorAction Stop }
                else                { Disable-PnpDevice -InstanceId $t[0] -Confirm:$false -ErrorAction Stop }
                Ok "zurueckgesetzt auf '$($t[1])': $name"
            } catch { Fail "$name - $($_.Exception.Message)" }
        }
    }

    # 2. Einzelne Ein-/Ausgaenge und Exklusivmodus (Registry)
    $n = 0
    foreach ($datei in @('endpunkte.txt','geraete.txt','exklusiv.txt')) {
        $n += Restore-RegValues -Datei (Join-Path $bk.FullName $datei) -Typ DWord
    }
    if ($n -gt 0) { Ok "$n Registry-Werte zurueckgesetzt" }

    if ((Test-Path $p) -or ($n -gt 0)) { Restart-AudioDienste }
    else { Info 'Nichts zurueckzusetzen.' }
}

# ============================== 6  NETZWERK ===================================

function Action-6 {
    Titel '6' 'NETZWERK ZURUECKSETZEN'
    Warn 'Danach ist ein NEUSTART des PCs noetig.'
    Write-Host ""

    Say "      DNS-Cache leeren..." 'Gray'
    try { Clear-DnsClientCache -ErrorAction Stop; Ok "DNS-Cache geleert" }
    catch { $null = Invoke-Tool -Was "DNS-Cache geleert" -Datei 'ipconfig' -Argumente @('/flushdns') }

    Say "      Winsock zuruecksetzen..." 'Gray'
    $null = Invoke-Tool -Was "Winsock zurueckgesetzt" -Datei 'netsh' -Argumente @('winsock','reset')

    Say "      TCP/IP-Stack zuruecksetzen..." 'Gray'
    Ensure-BackupRoot
    $log = Join-Path $Script:BackupRoot 'netsh-ip-reset.log'
    # Weich: netsh meldet hier auf manchen Systemen einen Fehler fuer einzelne
    # Registry-Schluessel, obwohl der Reset insgesamt greift.
    $null = Invoke-Tool -Was "TCP/IP zurueckgesetzt" -Datei 'netsh' -Argumente @('int','ip','reset',$log) -Weich
    Info "Protokoll: $log"

    Say "      IP-Adresse erneuern..." 'Gray'
    # Weich: bei fester IP oder ohne DHCP-Server schlagen release/renew fehl.
    # Das ist kein Problem, sondern schlicht nicht anwendbar.
    $null = Invoke-Tool -Was "IP freigegeben"   -Datei 'ipconfig' -Argumente @('/release')     -Weich
    $null = Invoke-Tool -Was "IP neu bezogen"   -Datei 'ipconfig' -Argumente @('/renew')       -Weich
    $null = Invoke-Tool -Was "DNS registriert"  -Datei 'ipconfig' -Argumente @('/registerdns') -Weich

    Write-Host ""
    Ok "FERTIG"
    Write-Host ""
    Warn 'Bitte den PC jetzt NEU STARTEN.'
}

function Action-6b {
    Titel '6b' 'NETZWERK-RESET'
    Ok 'Ein Rueckgaengig gibt es hier nicht - und es ist auch'
    Ok 'nicht noetig.'
    Write-Host ""
    Info 'Der Reset stellt die Windows-Standardwerte wieder her,'
    Info 'das IST bereits der Ausgangszustand. Deine Router- und'
    Info 'DNS-Einstellungen wurden nicht angefasst.'
    Write-Host ""
    Warn 'Falls das Internet danach klemmt: PC neu starten.'
}

# ================== 13  DOWNLOAD FEHLGESCHLAGEN (HILLCAT) =====================
#
# HILLCAT heisst: das Spiel konnte seine EIGENEN Daten nicht von Activision
# laden. Das ist nicht Steams Download - CoD holt nach dem Start eigene Pakete
# nach, und genau dabei steht "Pruefung auf Update". Deshalb hilft eine
# Neuinstallation fast nie. Es liegt am Weg zu den Servern:
#
#   - ein VPN leitet den gesamten Download ueber einen fremden Server
#   - ein DNS-Filter (AdGuard, Pi-hole, NextDNS) sperrt eine Adresse,
#     auf die das Spiel wartet
#   - eine Zeile in der hosts-Datei leitet eine Spieladresse ins Leere
#   - der DNS des Anbieters schickt zu einem Verteilknoten, der klemmt
#
# Die Aktion prueft das der Reihe nach und aendert nur, was sie selbst
# exakt zuruecknehmen kann.

# Adressen, die das Spiel beim Start und beim Nachladen braucht. Alle sind
# gegen oeffentliche DNS-Server geprueft - sie existieren wirklich. Liefert
# der eigene DNS dafuer "gibt es nicht", ist das eine Sperre.
$Script:SpielAdressen = @(
    'activision.com','s.activision.com','profile.callofduty.com','www.callofduty.com',
    'cdn.callofduty.com','telescope.callofduty.com','my.callofduty.com','demonware.net',
    'level3.blizzard.com','eu.patch.battle.net','cdn.blz-contentstack.com','blzddist1-a.akamaihd.net'
)
# Werbeadressen als Probe: ein DNS-Filter antwortet darauf mit 0.0.0.0 oder
# "gibt es nicht", ein gewoehnlicher DNS mit einer echten Adresse.
$Script:FilterProbe = @('doubleclick.net','googleadservices.com')
$Script:VpnMuster   = 'WireGuard|Wintun|TAP-Windows|OpenVPN|VPN|Tailscale|ZeroTier|NordLynx|AnyConnect|Fortinet|PANGP|Pulse Secure|Proton|Mullvad|Surfshark|CyberGhost|ExpressVPN'
$Script:Cloudflare4 = @('1.1.1.1','1.0.0.1')
$Script:Cloudflare6 = @('2606:4700:4700::1111','2606:4700:4700::1001')

# Fragt eine Adresse ab und ordnet die Antwort ein:
#   eine IP     aufgeloest
#   'gesperrt'  0.0.0.0 oder 127.x - so antworten DNS-Filter und hosts-Sperren
#   'fehlt'     "gibt es nicht" (NXDOMAIN)
#   'fehler'    keine Antwort, abgelehnt, Zeitueberschreitung
# Ohne -Server wird der DNS gefragt, den Windows gerade benutzt - also genau
# der, den auch das Spiel bekommt.
function Resolve-Probe {
    param([string]$Name, [string]$Server = '')
    try {
        $p = @{ Name = $Name; Type = 'A'; DnsOnly = $true; QuickTimeout = $true; ErrorAction = 'Stop' }
        if ($Server) { $p.Server = $Server }
        $r = Resolve-DnsName @p | Where-Object { $_.IPAddress } | Select-Object -First 1
        if (-not $r) { return 'fehler' }
        if (($r.IPAddress -eq '0.0.0.0') -or ($r.IPAddress -match '^127\.')) { return 'gesperrt' }
        return $r.IPAddress
    } catch {
        if ($_.Exception.Message -match 'nicht vorhanden|does not exist|NXDOMAIN|9003') { return 'fehlt' }
        return 'fehler'
    }
}

# Ein unabhaengiger Vergleichsserver: erst Cloudflare, dann Google - manche
# Netze sperren einen der beiden.
function Get-KontrollDns {
    foreach ($s in '1.1.1.1','8.8.8.8') {
        if ((Resolve-Probe -Name 'www.microsoft.com' -Server $s) -match '^\d') { return $s }
    }
    return ''
}

# Ein VPN, das den ganzen Verkehr umleitet, erkennt man an seinen Routen:
# WireGuard und OpenVPN legen 0.0.0.0/1 und 128.0.0.0/1 an und verdraengen so
# die normale Standardroute, ohne sie zu loeschen. Ein VPN, das nur einzelne
# Netze umleitet, betrifft das Spiel nicht und wird uebergangen.
function Get-VpnAdapter {
    $treffer = @()
    $routen = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object { $_.DestinationPrefix -in '0.0.0.0/0','0.0.0.0/1','128.0.0.0/1' })
    foreach ($r in $routen) {
        $nic = Get-NetAdapter -InterfaceIndex $r.InterfaceIndex -IncludeHidden -ErrorAction SilentlyContinue
        if ((-not $nic) -or ($nic.Status -ne 'Up')) { continue }
        if ("$($nic.Name) $($nic.InterfaceDescription)" -match $Script:VpnMuster) { $treffer += $nic.Name }
    }
    return @($treffer | Select-Object -Unique)
}

# Prueft alle Wege und liefert nur einen Befund - aendert selbst nichts.
# Wird von Aktion 13 und von der Diagnose benutzt.
function Test-SpielVerbindung {
    param([switch]$CacheLeeren)
    # Nur in Aktion 13: sonst antwortet womoeglich der Zwischenspeicher mit
    # einer alten Adresse. Die Diagnose laesst ihn in Ruhe - sie aendert nichts.
    if ($CacheLeeren) { Clear-DnsClientCache -ErrorAction SilentlyContinue }

    $kontrolle = Get-KontrollDns
    $dnsLebt   = ((Resolve-Probe -Name 'www.microsoft.com') -match '^\d')

    $filter = $false
    if ($dnsLebt) {
        foreach ($h in $Script:FilterProbe) {
            if ((Resolve-Probe -Name $h) -notmatch '^\d') { $filter = $true }
        }
    }

    $gesperrt = @()
    if ($dnsLebt) {
        foreach ($h in $Script:SpielAdressen) {
            $a = Resolve-Probe -Name $h
            if ($a -match '^\d') { continue }
            # Nur als gesperrt werten, wenn ein unabhaengiger Server die Adresse
            # kennt - sonst koennte sie schlicht nicht mehr existieren.
            if ($a -eq 'gesperrt') { $gesperrt += $h }
            elseif ($kontrolle -and ((Resolve-Probe -Name $h -Server $kontrolle) -match '^\d')) { $gesperrt += $h }
        }
    }

    $hostsPfad = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
    $hosts = @(Get-Content $hostsPfad -ErrorAction SilentlyContinue | Where-Object {
        ($_ -notmatch '^\s*#') -and ($_ -match 'activision|callofduty|demonware|blizzard|battle\.net|blz')
    })

    return [pscustomobject]@{
        Vpn       = @(Get-VpnAdapter)
        DnsLebt   = $dnsLebt
        Filter    = $filter
        Gesperrt  = $gesperrt
        Hosts     = $hosts
        HostsPfad = $hostsPfad
        Kontrolle = $kontrolle
    }
}

# --- DNS eines Adapters sichern, umstellen und exakt zurueckstellen ----------
# Ob der DNS von Hand gesetzt oder automatisch vom Router kommt, steht in der
# Registry unter "NameServer": leer = automatisch. Genau diesen Unterschied
# braucht das Zurueckstellen - wer seinen DNS von Hand eingetragen hat (oder
# ein VPN, das ihn gesetzt hat), darf ihn danach nicht als "automatisch"
# wiederbekommen.
function Get-DnsEinstellung {
    param([string]$Adapter)
    $nic = Get-NetAdapter -Name $Adapter -ErrorAction SilentlyContinue
    if (-not $nic) { return $null }
    $g  = $nic.InterfaceGuid
    $v4 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$g"  -Name NameServer -ErrorAction SilentlyContinue).NameServer
    $v6 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$g" -Name NameServer -ErrorAction SilentlyContinue).NameServer
    return [pscustomobject]@{
        Adapter = $Adapter
        V4      = @("$v4" -split '[,\s]+' | Where-Object { $_ })
        V6      = @("$v6" -split '[,\s]+' | Where-Object { $_ })
    }
}

function Save-DnsEinstellung {
    param($Einstellung, [string]$Datei)
    @("Adapter`t$($Einstellung.Adapter)",
      "IPv4`t$($Einstellung.V4 -join ',')",
      "IPv6`t$($Einstellung.V6 -join ',')") | Out-File -FilePath $Datei -Encoding utf8
}

function Restore-DnsEinstellung {
    param([string]$Datei)
    $w = @{}
    foreach ($z in (Get-Content $Datei -ErrorAction SilentlyContinue)) {
        $t = $z -split "`t", 2
        if ($t.Count -eq 2) { $w[$t[0]] = $t[1] }
    }
    if (-not $w['Adapter']) { Fail 'Sicherung unvollstaendig - der Adapter fehlt.'; return $false }
    $statisch = @("$($w['IPv4']),$($w['IPv6'])" -split '[,\s]+' | Where-Object { $_ })
    try {
        # Erst alles auf "automatisch", dann die frueher von Hand gesetzten
        # Server wieder eintragen. So stimmt der Zustand auch dann exakt, wenn
        # vorher nur IPv4 von Hand gesetzt war.
        Set-DnsClientServerAddress -InterfaceAlias $w['Adapter'] -ResetServerAddresses -ErrorAction Stop
        if ($statisch) { Set-DnsClientServerAddress -InterfaceAlias $w['Adapter'] -ServerAddresses $statisch -ErrorAction Stop }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        if ($statisch) { Ok "DNS zurueckgestellt auf: $($statisch -join ', ')" }
        else           { Ok 'DNS zurueckgestellt auf: automatisch (vom Router)' }
        return $true
    } catch {
        Fail "DNS liess sich nicht zurueckstellen - $($_.Exception.Message)"
        return $false
    }
}

function Set-DnsZiel {
    param([string]$Adapter, [ValidateSet('Cloudflare','Automatisch')][string]$Ziel, [string]$Datei)
    $vorher = Get-DnsEinstellung -Adapter $Adapter
    if (-not $vorher) { Fail "Adapter '$Adapter' nicht gefunden."; return $false }
    Save-DnsEinstellung -Einstellung $vorher -Datei $Datei
    try {
        if ($Ziel -eq 'Automatisch') {
            Set-DnsClientServerAddress -InterfaceAlias $Adapter -ResetServerAddresses -ErrorAction Stop
        } else {
            $neu = @($Script:Cloudflare4)
            $v6  = Get-NetAdapterBinding -Name $Adapter -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            if ($v6 -and $v6.Enabled) { $neu += $Script:Cloudflare6 }
            Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses $neu -ErrorAction Stop
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
    } catch {
        Fail "DNS liess sich nicht umstellen - $($_.Exception.Message)"
        $null = Restore-DnsEinstellung -Datei $Datei
        return $false
    }
    # Gegenprobe. Loest danach nichts mehr auf, wird SOFORT zurueckgestellt:
    # ein PC ohne funktionierenden DNS hat praktisch kein Internet mehr.
    Start-Sleep -Seconds 2
    if ((Resolve-Probe -Name 'www.callofduty.com') -match '^\d') {
        Ok "DNS umgestellt ($Ziel) - Spieladressen loesen auf"
        return $true
    }
    Fail 'Nach der Umstellung loest nichts mehr auf - ich stelle sofort zurueck.'
    $null = Restore-DnsEinstellung -Datei $Datei
    return $false
}

function Action-13 {
    Titel '13' 'DOWNLOAD FEHLGESCHLAGEN (HILLCAT)'
    Info 'HILLCAT heisst: das Spiel konnte seine EIGENEN Daten nicht laden.'
    Info 'Das ist nicht der Steam-Download - deshalb hilft neu installieren'
    Info 'fast nie. Es liegt am Weg zu den Activision-Servern.'
    Write-Host ""

    Stop-GameAndLaunchers

    Say "      Verbindungsweg pruefen..." 'Gray'
    $e = Test-SpielVerbindung -CacheLeeren

    # --- Befund ---
    if ($e.Vpn.Count -gt 0) { Warn "VPN an: $($e.Vpn -join ', ')" } else { Ok 'kein VPN aktiv' }
    if (-not $e.DnsLebt)    { Fail 'DNS antwortet nicht - es wird gar nichts aufgeloest!' }
    elseif ($e.Filter)      { Info 'DNS-Filter aktiv (AdGuard, Pi-hole, NextDNS o.ae.)' }
    else                    { Ok 'DNS antwortet normal, kein Filter' }
    if ($e.Gesperrt.Count -gt 0) { Fail ("gesperrt: " + ($e.Gesperrt -join ', ')) }
    elseif ($e.DnsLebt)          { Ok "alle $($Script:SpielAdressen.Count) Spieladressen erreichbar" }
    if ($e.Hosts.Count -gt 0) { Fail "hosts-Datei leitet $($e.Hosts.Count) Spieladresse(n) um" }
    else                      { Ok 'hosts-Datei sauber' }

    # --- 1. hosts-Datei: eine eindeutige Ursache, aber eine bewusste Aenderung ---
    if ($e.Hosts.Count -gt 0) {
        Write-Host ""
        Warn 'In der hosts-Datei stehen Eintraege fuer Spieladressen:'
        foreach ($z in $e.Hosts) { Info "  $($z.Trim())" }
        Info 'Die hat jemand von Hand eingetragen - oft, um Telemetrie zu'
        Info 'sperren. Ich loesche sie nicht selbst, ich zeige dir, wo.'
        Zeige-Schritte -Ueberschrift 'HOSTS-DATEI BEREINIGEN' -Schritte @(
            'Warte, bis der Editor mit der hosts-Datei aufgeht',
            'Setze vor jede der oben genannten Zeilen ein # (Raute)',
            'Speichern mit Strg+S, Editor schliessen',
            'Das Spiel neu starten'
        )
        if (Frage-JaNein "     hosts-Datei jetzt im Editor oeffnen? (j/n)") {
            $null = Oeffne-Windows -Was 'hosts-Datei' -Datei 'notepad.exe' -Argumente @("`"$($e.HostsPfad)`"") -VonHand "Editor als Administrator -> $($e.HostsPfad)"
        }
    }

    # --- 2. VPN: den DNS dann bewusst NICHT anfassen ---
    if ($e.Vpn.Count -gt 0) {
        Write-Host ""
        Info 'Mit VPN laeuft der GANZE Download ueber den VPN-Server - eine'
        Info 'haeufige Ursache fuer HILLCAT. Manchmal hilft ein VPN auch, wenn'
        Info 'der eigene Anbieter klemmt. Klarheit bringt nur der Vergleich.'
        Zeige-Schritte -Ueberschrift 'SO FINDEST DU ES HERAUS' -Schritte @(
            'Oeffne dein VPN-Programm und TRENNE die Verbindung',
            'Starte das Spiel',
            'Laeuft es? Dann war es das VPN - zum Spielen einfach aus lassen',
            'Laeuft es nicht? Starte diese Aktion ohne VPN noch einmal'
        )
        Info 'Den DNS stelle ich bei aktivem VPN bewusst NICHT um: das VPN hat'
        Info 'ihn selbst gesetzt, eine Aenderung wuerde mit ihm kollidieren.'
        return
    }

    # --- 3. Gesperrte Spieladressen in einem DNS-Filter ---
    if ($e.Gesperrt.Count -gt 0) {
        Write-Host ""
        Warn 'Dein DNS sperrt Adressen, die das Spiel braucht.'
        Zeige-Schritte -Ueberschrift 'IN DEINEM DNS-FILTER FREIGEBEN' -Schritte @(
            'Oeffne die Oberflaeche deines Filters (AdGuard Home, Pi-hole ...)',
            'Gehe zu den eigenen Filterregeln oder zur Freigabeliste (Allowlist)',
            ('Gib diese Adressen frei: ' + ($e.Gesperrt -join ', ')),
            'Speichern und das Spiel neu starten'
        )
        Info 'Schreibweise fuer AdGuard Home, je Adresse eine Zeile:'
        foreach ($h in $e.Gesperrt) { Info "  @@||$h^`$important" }
    } elseif ($e.Filter) {
        Write-Host ""
        Info 'Dein DNS-Filter sperrt keine der bekannten Spieladressen. Er kann'
        Info 'aber eine sperren, die hier nicht geprueft wird - etwa eine fuer'
        Info 'Telemetrie, auf die das Spiel beim Start wartet. Das sieht man nur'
        Info 'im Abfrageprotokoll des Filters:'
        Zeige-Schritte -Ueberschrift 'IM FILTER-PROTOKOLL NACHSEHEN' -Schritte @(
            'Oeffne das Abfrageprotokoll deines Filters (AdGuard: "Abfrageprotokoll")',
            'Starte das Spiel und warte auf den Fehler',
            'Filtere im Protokoll nach "Blockiert"',
            'Suche nach activision, callofduty, demonware oder blizzard',
            'Genau diese Adressen in der Freigabeliste eintragen'
        )
    }

    # --- 4. DNS umstellen - zum Testen oder als eigentliche Loesung ---
    $ad = Get-ActiveAdapter
    if (-not $ad) { Fail 'Kein aktiver Netzwerkadapter gefunden.'; return }
    $jetzt = Get-DnsEinstellung -Adapter $ad
    $istCloudflare = ($jetzt -and ($jetzt.V4 -contains '1.1.1.1'))

    Write-Host ""
    if ($istCloudflare) {
        # Nicht ein zweites Mal umstellen: die zweite Sicherung wuerde den
        # Cloudflare-Stand festhalten - und das Original waere verloren.
        Ok 'DNS steht bereits auf Cloudflare (1.1.1.1).'
        Info 'Zurueck zum vorherigen Stand mit 13b.'
    } elseif ((-not $e.DnsLebt) -and ($jetzt.V4.Count -gt 0)) {
        # Von Hand eingetragener DNS, der nicht antwortet - typischer Rest
        # eines VPNs, das beim Trennen nicht aufgeraeumt hat.
        Warn "Von Hand eingetragen ist $($jetzt.V4 -join ', ') - und der antwortet nicht."
        Info 'Das ist oft ein Rest eines VPNs, das beim Trennen nicht'
        Info 'aufgeraeumt hat. Richtig ist dann: DNS wieder automatisch'
        Info 'vom Router beziehen.'
        if (Frage-JaNein "     DNS auf automatisch zuruecksetzen? (j/n)") {
            $bk = New-BackupSet -Name '13_Download'
            $null = Set-DnsZiel -Adapter $ad -Ziel 'Automatisch' -Datei (Join-Path $bk 'dns.txt')
        }
    } else {
        $aktuell = 'automatisch (vom Router)'
        if ($jetzt.V4.Count -gt 0) { $aktuell = ($jetzt.V4 -join ', ') + ' (von Hand eingetragen)' }
        Info "Dein DNS jetzt: $aktuell"
        Info 'Der haeufigste Fix fuer HILLCAT ist ein anderer DNS-Server. Dein'
        Info 'Anbieter schickt dich sonst zu einem Verteilknoten, der klemmen'
        Info 'kann. Cloudflare (1.1.1.1) ist schnell und protokolliert nichts.'
        if ($e.Filter) {
            Warn 'Achtung: damit umgehst du deinen DNS-Filter an diesem PC.'
            Info 'Als Test ist das ideal - laeuft es danach, liegt es am Filter.'
        }
        Info 'Rueckgaengig jederzeit mit 13b - exakt auf den jetzigen Stand.'
        if (Frage-JaNein "     DNS auf Cloudflare umstellen? (j/n)") {
            $bk = New-BackupSet -Name '13_Download'
            $null = Set-DnsZiel -Adapter $ad -Ziel 'Cloudflare' -Datei (Join-Path $bk 'dns.txt')
        }
    }

    # --- 5. Spieldateien von Steam pruefen lassen ---
    $steamCod = $false
    foreach ($lib in Get-SteamLibraries) {
        if (Test-Path (Join-Path $lib 'steamapps\appmanifest_1938090.acf')) { $steamCod = $true }
    }
    if ($steamCod) {
        Write-Host ""
        Info 'Zusaetzlich hilft oft, die Spieldateien pruefen zu lassen. Steam'
        Info 'laedt dabei kaputte oder fehlende Dateien nach (5-20 Minuten).'
        Frage-Oeffnen -Nr '13' -Frage 'Spieldateien jetzt von Steam pruefen lassen?'
    }

    Write-Host ""
    Ok "FERTIG"
    Info 'Jetzt das Spiel starten. "Pruefung auf Update" kann beim ersten'
    Info 'Mal mehrere Minuten stehen bleiben - das ist normal, nicht abbrechen.'
}

function Action-13b {
    Titel '13b' 'DNS WIEDER ZURUECKSTELLEN'
    $bk = Get-LatestBackup -Name '13_Download'
    if (-not $bk) { Info 'Der DNS wurde von diesem Werkzeug nie umgestellt.'; return }
    $f = Join-Path $bk.FullName 'dns.txt'
    if (-not (Test-Path $f)) { Info 'In der letzten Sicherung wurde der DNS nicht veraendert.'; return }
    $null = Restore-DnsEinstellung -Datei $f
    Info 'Eine hosts-Datei und ein VPN hat diese Aktion nie angefasst.'
}

# ============================== 7  OVERLAYS ===================================

function Action-7 {
    Titel '7' 'OVERLAYS BEENDEN'
    Info 'Overlays von NVIDIA, Discord & Co. sind eine der'
    Info 'haeufigsten Absturzursachen bei Call of Duty.'
    Write-Host ""

    $g = 0
    foreach ($n in @('NVIDIA Overlay','NVIDIA Share','Discord','RTSSHooksLoader64','RTSS',
                     'MSIAfterburner','EVGAPrecisionX1','obs64','XSplit.Core','Rivatuner')) {
        foreach ($p in (Get-Process -Name $n -ErrorAction SilentlyContinue)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Ok "beendet: $($p.ProcessName)"; $g++ } catch {}
        }
    }
    if ($g -eq 0) { Ok "Keine laufenden Overlays gefunden." }

    Write-Host ""
    Warn 'Dauerhaft abschalten (empfohlen):'
    Info '  NVIDIA App -> Einstellungen -> In-Game-Overlay AUS'
    Info '  Discord    -> Einstellungen -> Spiel-Overlay AUS'
    Info '  Steam      -> Einstellungen -> Im Spiel'
    Info '                (fuer die CoD-Anmeldung besser AN lassen!)'
}

function Action-7b {
    Titel '7b' 'OVERLAYS WIEDER STARTEN'
    Ok 'Overlays starten beim naechsten Windows-Neustart'
    Ok 'automatisch wieder.'
    Write-Host ""
    Info 'Oder einfach die jeweilige App oeffnen (NVIDIA App, Discord).'
}

# ============================== 8  FIREWALL ===================================

function Action-8 {
    Titel '8' 'FIREWALL-REGELN REPARIEREN'
    Write-Host ""

    $bk = New-BackupSet -Name '8_Firewall'

    # Komplette Firewall-Richtlinie sichern. Erst dadurch laesst sich das
    # Entfernen einer Blockade spaeter wirklich rueckgaengig machen.
    Say "      Firewall-Regeln sichern..." 'Gray'
    $wfw = Join-Path $bk 'firewall-komplett.wfw'
    $null = Invoke-Tool -Was "Sicherung angelegt" -Datei 'netsh' -Argumente @('advfirewall','export',$wfw) -Weich

    Say "      Suche blockierende Regeln..." 'Gray'
    # Umgekehrte Richtung als frueher: erst die wenigen passenden Programm-
    # filter holen, dann deren Regeln. Andersherum wird jede einzelne
    # Blockade-Regel abgefragt - auf einem normalen Windows dauert das lange.
    #
    # Das Muster ist bewusst eng gefasst: ein blosses "cod" wuerde auch
    # Codec- oder Encoder-Pfade treffen und fremde Regeln loeschen. Nach
    # "cod" muss deshalb direkt ".exe", eine Ziffer oder ein Bindestrich
    # folgen - sonst traefe es auch Code.exe (Visual Studio Code).
    $muster = '\\cod(?:\.exe|[0-9-][^\\]*\.exe)$|\\Call of Duty\b|\\steam(webhelper)?\.exe$|\\Battle\.net\.exe$|\\bootstrapper[^\\]*\.exe$'
    $blocker = @()
    foreach ($af in (Get-NetFirewallApplicationFilter -All -ErrorAction SilentlyContinue)) {
        if (-not $af.Program) { continue }
        if ($af.Program -notmatch $muster) { continue }
        $r = $af | Get-NetFirewallRule -ErrorAction SilentlyContinue
        if ($r -and $r.Action -eq 'Block' -and $r.Enabled -eq 'True') {
            $blocker += [pscustomobject]@{ Regel = $r; Programm = $af.Program }
        }
    }

    if ($blocker) {
        Write-Host ""
        Warn 'Folgende Regeln blockieren das Spiel:'
        foreach ($b in $blocker) {
            Info "- $($b.Regel.DisplayName)"
            Info "    $($b.Programm)"
        }
        Write-Host ""
        if (Frage-JaNein "     Diese Regeln entfernen? (j/n)") {
            foreach ($b in $blocker) {
                ("{0}`t{1}" -f $b.Regel.DisplayName, $b.Programm) |
                    Out-File (Join-Path $bk 'entfernte-regeln.txt') -Append -Encoding utf8
                try { Remove-NetFirewallRule -Name $b.Regel.Name -ErrorAction Stop; Ok "entfernt: $($b.Regel.DisplayName)" }
                catch { Fail "konnte nicht entfernt werden: $($b.Regel.DisplayName)" }
            }
        } else { Info 'Regeln bleiben unveraendert.' }
    } else { Ok "keine blockierenden Regeln - gut" }

    Say "      Freigaben anlegen..." 'Gray'
    $exes = @()
    foreach ($inst in Get-CodInstallPaths) {
        $exes += Get-ChildItem $inst -Filter '*.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -match '^(cod|bootstrapper)' } | Select-Object -ExpandProperty FullName
    }
    $n = 0
    foreach ($e in ($exes | Select-Object -Unique)) {
        foreach ($dir in @('Inbound','Outbound')) {
            $rn = "CoD-Fix $dir $(Split-Path $e -Leaf)"
            if (-not (Get-NetFirewallRule -DisplayName $rn -ErrorAction SilentlyContinue)) {
                try { New-NetFirewallRule -DisplayName $rn -Direction $dir -Program $e -Action Allow -Profile Any -ErrorAction Stop | Out-Null; $n++ } catch {}
            }
        }
    }
    Ok "$n Freigaben angelegt"
    Write-Host ""
    Ok "FERTIG"
}

function Action-8b {
    Titel '8b' 'FIREWALL-REGELN ENTFERNEN'
    $n = 0
    foreach ($r in (Get-NetFirewallRule -DisplayName 'CoD-Fix *' -ErrorAction SilentlyContinue)) {
        try { Remove-NetFirewallRule -Name $r.Name -ErrorAction Stop; $n++ } catch {}
    }
    Ok "$n selbst angelegte Regeln entfernt"

    $bk = Get-LatestBackup -Name '8_Firewall'
    if (-not $bk) { return }

    $liste = Join-Path $bk.FullName 'entfernte-regeln.txt'
    $wfw   = Join-Path $bk.FullName 'firewall-komplett.wfw'
    if (-not (Test-Path $liste)) { return }

    Write-Host ""
    Warn 'Damals entfernte Blockade-Regeln:'
    foreach ($z in (Get-Content $liste -ErrorAction SilentlyContinue)) {
        $t = $z -split "`t"
        Info "- $($t[0])"
        if ($t.Count -gt 1) { Info "    $($t[1])" }
    }

    if (-not (Test-Path $wfw)) {
        Write-Host ""
        Warn 'Ohne vollstaendige Sicherung lassen sie sich nicht'
        Warn 'automatisch zurueckholen. Liste siehe oben.'
        return
    }

    Write-Host ""
    Warn 'Die vollstaendige Sicherung kann eingespielt werden.'
    Warn 'ACHTUNG: Damit kehrt die GESAMTE Firewall auf den Stand von'
    Warn 'damals zurueck - auch Regeln, die du seitdem selbst angelegt'
    Warn 'hast, sind dann weg.'
    Info "Sicherung: $wfw"
    Write-Host ""
    if (Frage-JaNein "     Vollstaendige Firewall-Sicherung einspielen? (j/n)") {
        $null = Invoke-Tool -Was "Firewall-Sicherung eingespielt" -Datei 'netsh' -Argumente @('advfirewall','import',$wfw)
    } else {
        Info 'Nichts eingespielt - die Firewall bleibt wie sie ist.'
    }
}

# ============================== 9  STARTPROBLEME ==============================
# Spiel startet gar nicht / stuerzt sofort ab

$Script:LayerKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
)

function Action-9 {
    Titel '9' 'SPIEL STARTET NICHT'
    Write-Host ""

    Stop-GameAndLaunchers
    $bk = New-BackupSet -Name '9_Start'

    # --- 1. Kompatibilitaets-Flags entfernen ---
    Say "      Kompatibilitaets-Einstellungen pruefen..." 'Gray'
    Info 'CoD laeuft NICHT mit "Als Administrator ausfuehren" oder'
    Info 'im Kompatibilitaetsmodus - das verhindert den Start.'
    $ent = 0
    foreach ($k in $Script:LayerKeys) {
        if (-not (Test-Path $k)) { continue }
        $props = (Get-ItemProperty $k -ErrorAction SilentlyContinue).PSObject.Properties |
                 Where-Object { $_.Name -match '\\(cod|bootstrapper)[^\\]*\.exe$' -or $_.Name -match 'Call of Duty' }
        foreach ($pr in $props) {
            ("{0}`t{1}`t{2}" -f $k, $pr.Name, $pr.Value) | Out-File (Join-Path $bk 'layers.txt') -Append -Encoding utf8
            try {
                Remove-ItemProperty -Path $k -Name $pr.Name -ErrorAction Stop
                Ok "entfernt: $(Split-Path $pr.Name -Leaf)  [war: $($pr.Value)]"
                $ent++
            } catch { Fail "kein Zugriff: $($pr.Name)" }
        }
    }
    if ($ent -eq 0) { Ok "keine stoerenden Kompatibilitaets-Flags gesetzt" }

    # --- 2. Image File Execution Options (Debugger-Eintraege) ---
    Say "      Pruefe auf blockierende Debugger-Eintraege..." 'Gray'
    $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
    $gef = 0
    if (Test-Path $ifeo) {
        foreach ($d in (Get-ChildItem $ifeo -ErrorAction SilentlyContinue)) {
            if ($d.PSChildName -match '^(cod|bootstrapper)') {
                $dbg = (Get-ItemProperty $d.PSPath -Name Debugger -ErrorAction SilentlyContinue).Debugger
                if ($dbg) {
                    ("{0}`tDebugger`t{1}" -f $d.PSPath, $dbg) | Out-File (Join-Path $bk 'ifeo.txt') -Append -Encoding utf8
                    try { Remove-ItemProperty -Path $d.PSPath -Name Debugger -ErrorAction Stop; Ok "Debugger-Blockade entfernt: $($d.PSChildName)"; $gef++ } catch {}
                }
            }
        }
    }
    if ($gef -eq 0) { Ok "keine Debugger-Blockaden" }

    # --- 3. Laufzeitbibliotheken pruefen ---
    Say "      Laufzeitbibliotheken pruefen..." 'Gray'
    $vc = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
          ForEach-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName } |
          Where-Object { $_ -match 'Visual C\+\+ 20(1[5-9]|2\d).*(x64|64-bit)' }
    $vcFehlt = $false
    if ($vc) { Ok "Visual C++ Runtime (x64) vorhanden" }
    else {
        $vcFehlt = $true
        Fail 'Visual C++ Runtime (x64) fehlt oder ist beschaedigt!'
        Warn 'Ohne sie startet Call of Duty nicht. Das ist ein kostenloses'
        Warn 'Microsoft-Paket und in einer Minute installiert.'
    }
    if (Test-Path (Join-Path $env:SystemRoot 'System32\d3d12.dll')) { Ok "DirectX 12 vorhanden" }
    else { Fail 'DirectX 12 fehlt - Windows Update ausfuehren' }

    # --- 4. Eingabe-Software warnen ---
    Say "      Pruefe auf Anti-Cheat-Konflikte..." 'Gray'
    $konflikt = @('reWASD','DS4Windows','XOutput','AntiMicro','JoyToKey','Cheat Engine','MSIAfterburner','RTSS')
    $tref = @()
    foreach ($n in $konflikt) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { $tref += $n }
    }
    if ($tref) {
        foreach ($t in $tref) { Warn "laeuft: $t" }
        Warn 'Der CoD-Anticheat blockiert Tastenbelegungs- und'
        Warn 'Overlay-Software. Bitte beenden und neu testen.'
    } else { Ok "keine bekannte Konfliktsoftware aktiv" }

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"
    Write-Host ""
    Warn 'Wichtig: Der Launcher (Steam / Battle.net) DARF als'
    Warn 'Administrator laufen - das Spiel selbst aber NICHT.'

    if ($vcFehlt) {
        Write-Host ""
        Warn 'ABER ZUERST: die fehlende Visual C++ Runtime installieren.'
        Info 'Ohne sie startet das Spiel nicht - alles andere hilft dann nichts.'
        Zeige-Schritte -Ueberschrift 'VISUAL C++ NACHINSTALLIEREN' -Schritte @(
            'Ich oeffne gleich den Download im Browser',
            'Die Datei "vc_redist.x64.exe" speichern und danach doppelklicken',
            'Haken bei "Zustimmen" setzen und auf "Installieren" klicken',
            'Nach der Installation den PC neu starten'
        )
        Frage-Oeffnen -Nr '9' -Frage 'Download jetzt im Browser oeffnen?'
    }
}

function Action-9b {
    Titel '9b' 'STARTPROBLEM-AENDERUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '9_Start'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }
    $n = 0
    foreach ($datei in @('layers.txt','ifeo.txt')) {
        $n += Restore-RegValues -Datei (Join-Path $bk.FullName $datei) -Typ String
    }
    if ($n -gt 0) { Ok "$n Eintraege wiederhergestellt" } else { Info "nichts wiederherzustellen" }
}

# ============================== 10  LEISTUNG ==================================
# Ruckeln, FPS-Einbrueche, Stottern

function Action-10 {
    Titel '10' 'LEISTUNG VERBESSERN (RUCKELN, FPS)'
    Write-Host ""

    $bk = New-BackupSet -Name '10_Leistung'
    $regDatei = Join-Path $bk 'leistung.txt'

    # --- 1. Xbox Game Bar / Game DVR ---
    Say "      Xbox Game Bar und Spielaufzeichnung abschalten..." 'Gray'
    Info 'Kostet 200-400 MB RAM und bis zu 20 ms Eingabeverzoegerung,'
    Info 'auch wenn gar nicht aufgezeichnet wird.'
    $dvr = @(
        @{P='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; N='AppCaptureEnabled';        V=0},
        @{P='HKCU:\System\GameConfigStore';                            N='GameDVR_Enabled';          V=0},
        @{P='HKCU:\SOFTWARE\Microsoft\GameBar';                        N='UseNexusForGameBarEnabled';V=0},
        @{P='HKCU:\SOFTWARE\Microsoft\GameBar';                        N='ShowStartupPanel';         V=0}
    )
    foreach ($e in $dvr) {
        if (-not (Test-Path $e.P)) { try { New-Item -Path $e.P -Force | Out-Null } catch { continue } }
        Save-RegValue -Datei $regDatei -Pfad $e.P -Name $e.N
        try { Set-ItemProperty -Path $e.P -Name $e.N -Value $e.V -Type DWord -ErrorAction Stop; Ok "abgeschaltet: $($e.N)" } catch { Fail $e.N }
    }

    # --- 2. Windows-Spielmodus ---
    Say "      Windows-Spielmodus aktivieren..." 'Gray'
    $gm = 'HKCU:\SOFTWARE\Microsoft\GameBar'
    if (-not (Test-Path $gm)) { New-Item -Path $gm -Force | Out-Null }
    Save-RegValue -Datei $regDatei -Pfad $gm -Name 'AllowAutoGameMode'
    try { Set-ItemProperty -Path $gm -Name 'AllowAutoGameMode' -Value 1 -Type DWord -ErrorAction Stop; Ok "Spielmodus an" } catch {}

    # --- 3. Hardwarebeschleunigte GPU-Planung ---
    Say "      Hardwarebeschleunigte GPU-Planung (HAGS)..." 'Gray'
    $gd = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    $hags = (Get-ItemProperty -Path $gd -Name HwSchMode -ErrorAction SilentlyContinue).HwSchMode
    Save-RegValue -Datei $regDatei -Pfad $gd -Name 'HwSchMode'
    if ($hags -eq 2) { Ok "war bereits aktiv" }
    else {
        try { Set-ItemProperty -Path $gd -Name 'HwSchMode' -Value 2 -Type DWord -ErrorAction Stop
              Ok "aktiviert (wirkt nach dem Neustart)" } catch { Fail "HAGS konnte nicht gesetzt werden" }
    }

    # --- 4. Energieplan ---
    # Erkennung ueber die GUID, nicht ueber den angezeigten Namen: der ist
    # uebersetzt und heisst je nach Windows-Sprache anders.
    Say "      Energieplan pruefen..." 'Gray'
    $sparsam  = 'a1841308-3541-4fab-bc81-f71556f20b4a'   # Energiesparmodus
    $normal   = '381b4222-f694-41f0-9685-ff5bb260df2e'   # Ausbalanciert
    $akt      = (powercfg /getactivescheme) -join ' '
    $aktGuid  = ''
    if ($akt -match '([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})') { $aktGuid = $Matches[1] }
    $aktName  = ''
    if ($akt -match '\(([^)]+)\)') { $aktName = $Matches[1] }

    if ($aktGuid -eq $sparsam) {
        Warn 'Energiesparplan aktiv - bremst die CPU stark!'
        # Alten Plan merken, damit 10b ihn wiederherstellen kann.
        $aktGuid | Out-File (Join-Path $bk 'energieplan.txt') -Encoding utf8
        $null = Invoke-Tool -Was "auf Ausbalanciert umgestellt" -Datei 'powercfg' -Argumente @('/setactive', $normal)
    } elseif ($aktGuid) {
        Ok "Energieplan in Ordnung ($aktName)"
    } else {
        Info 'Energieplan nicht lesbar - uebersprungen.'
    }

    # --- 5. Prozessprioritaet normalisieren ---
    Say "      Prozessprioritaet des Spiels normalisieren..." 'Gray'
    Info 'CoD setzt sich teils auf "Hoch" und laesst Windows'
    Info 'dadurch stottern.'
    $n = 0
    foreach ($inst in Get-CodInstallPaths) {
        foreach ($e in (Get-ChildItem $inst -Filter '*.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -match '^cod' })) {
            $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($e.Name)\PerfOptions"
            try {
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
                Save-RegValue -Datei $regDatei -Pfad $k -Name 'CpuPriorityClass'
                Set-ItemProperty -Path $k -Name 'CpuPriorityClass' -Value 3 -Type DWord -ErrorAction Stop
                Ok "auf Normal gesetzt: $($e.Name)"; $n++
            } catch {}
        }
    }
    if ($n -eq 0) { Info "keine Spiel-EXE gefunden" }

    Write-Host ""
    Ok "FERTIG"
    Info "Backup: $bk"
    Write-Host ""
    Warn 'Fuer HAGS ist ein NEUSTART noetig.'
    Write-Host ""
    Info 'Zusaetzlich im Spiel (Grafik-Einstellungen):'
    Info '  - Bewegungsunschaerfe AUS'
    Info '  - V-Sync AUS'
    Info '  - Bildrate begrenzen: Custom, ca. 3 unter deiner Hz-Zahl'
    Info '  - Waehrend des Spielens keine Downloads laufen lassen'
}

function Action-10b {
    Titel '10b' 'LEISTUNGS-AENDERUNGEN RUECKGAENGIG'
    $bk = Get-LatestBackup -Name '10_Leistung'
    if (-not $bk) { Fail "Kein Backup gefunden."; return }
    $f = Join-Path $bk.FullName 'leistung.txt'
    if (-not (Test-Path $f)) { Fail "Keine Sicherung vorhanden."; return }
    Ok "$(Restore-RegValues -Datei $f -Typ DWord) Werte zurueckgesetzt"

    # Energieplan, falls damals umgestellt wurde
    $ep = Join-Path $bk.FullName 'energieplan.txt'
    if (Test-Path $ep) {
        $guid = (Get-Content $ep -Raw -ErrorAction SilentlyContinue).Trim()
        if ($guid -match '^[0-9a-fA-F-]{36}$') {
            $null = Invoke-Tool -Was "Energieplan zurueckgestellt" -Datei 'powercfg' -Argumente @('/setactive', $guid) -Weich
        }
    } else {
        Info 'Der Energieplan wurde damals nicht veraendert.'
    }
    Write-Host ""
    Warn 'Fuer die GPU-Planung (HAGS) ist ein NEUSTART noetig.'
}

# ============================== D  DIAGNOSE ===================================

function Action-D {
    Titel 'D' 'DIAGNOSE - SYSTEM PRUEFEN'
    $zeitFalsch = $false

    Write-Host "   SYSTEM" -ForegroundColor White
    $os = Get-CimInstance Win32_OperatingSystem
    Info "$($os.Caption)  Build $($os.BuildNumber)"
    Info "Arbeitsspeicher: $([math]::Round($os.TotalVisibleMemorySize/1MB)) GB"
    Write-Host ""

    Write-Host "   GRAFIKKARTE" -ForegroundColor White
    foreach ($g in (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)) {
        Info "$($g.Name)"
        Info "  Treiber $($g.DriverVersion)"
    }
    Write-Host ""

    Write-Host "   ANTI-CHEAT (Ricochet braucht beides!)" -ForegroundColor White
    try { $sb = Confirm-SecureBootUEFI; if ($sb) { Ok "Secure Boot: AN" } else { Fail "Secure Boot: AUS - Spiel startet evtl. nicht!" } }
    catch { Warn "Secure Boot: nicht lesbar (evtl. Legacy-BIOS)" }
    try { $t = Get-Tpm; if ($t.TpmReady) { Ok "TPM: bereit" } else { Fail "TPM: nicht bereit" } }
    catch { Warn "TPM: nicht lesbar" }
    Write-Host ""

    Write-Host "   INSTALLATION" -ForegroundColor White
    $inst = Get-CodInstallPaths
    if ($inst) {
        # Bewusst KEINE Groessenberechnung: die haette jede Datei einer ueber
        # 100 GB grossen Installation anfassen muessen und die Diagnose
        # minutenlang blockiert. Der freie Platz ist ohnehin aussagekraeftiger -
        # fehlt er, bricht der Shader-Aufbau ab.
        foreach ($i in $inst) {
            Ok $i
            $frei = Get-FreeSpace -Pfad $i
            if ($frei -le 0) { continue }
            if ($frei -lt 20GB) { Fail ("  nur {0:N1} GB frei - fuer den Shader-Cache zu wenig!" -f ($frei/1GB)) }
            else                { Info ("  {0:N1} GB frei" -f ($frei/1GB)) }
        }
    } else { Fail "Keine CoD-Installation gefunden" }
    Write-Host ""

    Write-Host "   PROFILDATEN" -ForegroundColor White
    $dp = Get-CodDataPaths
    if ($dp) { foreach ($d in $dp) { Info $d } } else { Info "keine (bereits zurueckgesetzt)" }
    Write-Host ""

    Write-Host "   NETZWERK" -ForegroundColor White
    $ad = Get-ActiveAdapter
    if ($ad) {
        Info "Adapter: $ad"
        $dns = (Get-DnsClientServerAddress -InterfaceAlias $ad -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        if ($dns) { Info "DNS: $($dns -join ', ')" }
    } else {
        Fail "Kein aktiver Netzwerkadapter gefunden"
    }
    foreach ($h in @('profile.callofduty.com','s.activision.com')) {
        # Eigener Test mit Zeitlimit statt Test-NetConnection: das kennt keins
        # und laesst die Diagnose bei einem toten Host sehr lange stehen.
        if (Test-Port -Ziel $h -Port 443) { Ok "$h erreichbar" } else { Fail "$h NICHT erreichbar" }
    }
    # Die Wege, an denen HILLCAT und "Pruefung auf Update" meist haengen.
    # Ohne -CacheLeeren: die Diagnose aendert nichts, auch nicht den Cache.
    $sv = Test-SpielVerbindung
    if ($sv.Vpn.Count -gt 0) { Warn "VPN an: $($sv.Vpn -join ', ') - leitet auch den Spiel-Download um" }
    else                     { Ok 'kein VPN aktiv' }
    if (-not $sv.DnsLebt)    { Fail 'DNS antwortet nicht!' }
    elseif ($sv.Filter)      { Info 'DNS-Filter aktiv (AdGuard, Pi-hole o.ae.)' }
    if ($sv.Gesperrt.Count -gt 0) { Fail ('gesperrte Spieladressen: ' + ($sv.Gesperrt -join ', ')) }
    elseif ($sv.DnsLebt)          { Ok "alle $($Script:SpielAdressen.Count) Spieladressen loesen auf" }
    if ($sv.Hosts.Count -gt 0)    { Warn "hosts-Datei leitet $($sv.Hosts.Count) Spieladresse(n) um" }
    if (($sv.Vpn.Count -gt 0) -or ($sv.Gesperrt.Count -gt 0) -or ($sv.Hosts.Count -gt 0) -or (-not $sv.DnsLebt)) {
        Info '  -> Hilfe dazu: Menue 4, Punkt 1 (Download fehlgeschlagen)'
    }
    Write-Host ""

    Write-Host "   UHRZEIT" -ForegroundColor White
    Info ((Get-Date).ToString('dddd, dd.MM.yyyy  HH:mm:ss') + '  (UTC' + (Get-Date).ToString('zzz') + ')')
    # Gegen einen echten Zeitgeber pruefen - nur eine Abweichung ist ein Problem
    $abw = $null
    foreach ($u in @('https://www.google.com','https://www.microsoft.com')) {
        try {
            $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            if ($r.Headers['Date']) {
                $srv = [datetime]::Parse($r.Headers['Date']).ToUniversalTime()
                $abw = ((Get-Date).ToUniversalTime() - $srv).TotalSeconds
                break
            }
        } catch {}
    }
    if ($null -eq $abw) {
        Info 'Abgleich nicht moeglich (keine Internetverbindung).'
    } elseif ([math]::Abs($abw) -lt 60) {
        Ok ("Zeit stimmt (Abweichung {0:N1} Sekunden)" -f $abw)
    } else {
        $zeitFalsch = $true
        Fail ("Zeit weicht um {0:N0} Sekunden ab - DAS bricht den Login!" -f $abw)
    }
    # Zeitdienst nur erwaehnen, wenn die Zeit tatsaechlich falsch ist
    if (($null -ne $abw) -and ([math]::Abs($abw) -ge 60)) {
        $w = Get-Service w32time -ErrorAction SilentlyContinue
        if ($w -and $w.Status -ne 'Running') { Warn 'Zeitdienst w32time laeuft nicht.' }
    }
    Write-Host ""

    Write-Host "   AKTIVE OVERLAYS" -ForegroundColor White
    $ov = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'NVIDIA Overlay|Discord|RTSS|Afterburner' }
    if ($ov) { foreach ($o in ($ov | Select-Object -ExpandProperty ProcessName -Unique)) { Warn $o } }
    else { Ok "keine" }

    # Erst ganz am Ende, damit die Anleitung nicht mitten in der Diagnose
    # steht und der Nutzer sie nicht mehr wegscrollt.
    if ($zeitFalsch) {
        Write-Host ""
        Warn 'DEIN WICHTIGSTES PROBLEM: die Uhrzeit stimmt nicht.'
        Info 'Bei einer falschen Uhr lehnen die Activision-Server die Anmeldung'
        Info 'ab - ohne verstaendliche Fehlermeldung. Das laesst sich in einer'
        Info 'halben Minute beheben.'
        Oeffne-Mit-Anleitung -Nr '6' -Ueberschrift 'UHRZEIT RICHTIGSTELLEN' -Schritte @(
            'Warte, bis die Einstellungen aufgehen',
            'Schalte "Uhrzeit automatisch festlegen" AUS und wieder AN',
            'Schalte "Zeitzone automatisch festlegen" ebenfalls AN',
            'Klicke weiter unten auf "Jetzt synchronisieren"',
            'Pruefe oben, ob die Uhrzeit jetzt stimmt'
        )
    }
}

# ============================== A  ALLES ======================================

function Action-A {
    Titel 'A' 'ALLE AENDERUNGEN RUECKGAENGIG'
    # Reihenfolge ist entscheidend: 1b spielt den KOMPLETTEN Profilordner
    # zurueck und wuerde einzeln wiederhergestellte Konfigurationsdateien
    # sonst wieder mit dem aelteren Stand ueberschreiben. Also erst das
    # Grobe, dann das Feine.
    Action-1b
    Action-3b
    Action-4b
    Action-5b
    Action-11b
    Action-12b
    Action-13b
    Action-8b
    Action-9b
    Action-10b
    Write-Host ""
    Ok "Fertig."
    Info 'Shader-Cache und Netzwerk-Reset brauchen kein'
    Info 'Rueckgaengig - sie stellen bereits Standardwerte her.'
}

# ============================== H  HILFE ======================================

# Statt den Nutzer suchen zu lassen, wo in Windows etwas steht: auswaehlen,
# und das Fenster geht auf - mit Anleitung, was darin zu tun ist.
function Menue-Oeffnen {
    while ($true) {
        Show-Kopf
        Write-Host "    WOHIN SOLL ICH DICH BRINGEN?" -ForegroundColor White
        Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "     Zahl eingeben - das passende Fenster geht dann von selbst" -ForegroundColor DarkGray
        Write-Host "     auf, und hier steht, was du darin anklicken musst." -ForegroundColor DarkGray
        Write-Host ""
        foreach ($z in $Script:Ziele) {
            Write-Host ("     {0,2}  " -f $z.Nr) -ForegroundColor Green -NoNewline
            Write-Host $z.Was -ForegroundColor White
            if ($z.Tipp) { Write-Host "         $($z.Tipp)" -ForegroundColor DarkGray }
        }
        Write-Host ""
        Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "      0  " -ForegroundColor Cyan -NoNewline
        Write-Host "weiter zum Hilfetext" -ForegroundColor Gray
        Write-Host ""

        $w = (Read-Host "     Deine Wahl").Trim()
        if (($w -eq '0') -or ($w -eq '')) { return }

        $z = $Script:Ziele | Where-Object { $_.Nr -eq $w } | Select-Object -First 1
        if (-not $z) {
            Write-Host ""
            Write-Host "     '$w' gibt es hier nicht. Bitte eine Zahl aus der Liste." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }

        Titel $z.Nr $z.Was
        if ($z.Tipp) { Info $z.Tipp; Write-Host "" }
        Say "      Das Fenster geht jetzt von selbst auf..." 'Gray'
        Start-Sleep -Seconds 2
        $null = Oeffne-Windows -Was $z.Was -Datei $z.Datei -Argumente $z.Arg -VonHand $z.Hand
        Write-Host ""
        Info 'Findest du das Fenster nicht? Es kann HINTER diesem hier liegen -'
        Info 'unten in der Taskleiste nachsehen oder Alt+Tab druecken.'
        Pause-Key
    }
}

function Action-H {
    # Erst die Liste zum Anklicken - wer Hilfe sucht, will hin, nicht lesen.
    Menue-Oeffnen
    Titel 'H' 'WAS DU SELBST MACHEN MUSST'

    Write-Host "   SPIELDATEIEN PRUEFEN  (behebt beschaedigte Dateien)" -ForegroundColor Yellow
    Info 'Steam      : Rechtsklick aufs Spiel -> Eigenschaften ->'
    Info '             Installierte Dateien -> Integritaet pruefen'
    Info 'Battle.net : Zahnrad neben SPIELEN -> Scan und Reparatur'
    Write-Host ""

    Write-Host "   GRAFIKTREIBER" -ForegroundColor Yellow
    Info 'Ein ZU NEUER Treiber verursacht bei CoD haeufig Schwarzbild.'
    Info 'Sauber neu installieren: DDU im abgesicherten Modus, danach'
    Info 'die vom Spiel empfohlene Version von nvidia.com / amd.com.'
    Write-Host ""

    Write-Host "   UEBERTAKTUNG / XMP / EXPO" -ForegroundColor Yellow
    Info 'Im BIOS testweise abschalten. Haeufige Ursache fuer DirectX-'
    Info 'und Dev-Fehler, obwohl das System sonst voellig stabil laeuft.'
    Write-Host ""

    Write-Host "   TONFORMAT" -ForegroundColor Yellow
    Info 'Win+R -> mmsys.cpl -> Geraet -> Eigenschaften -> Erweitert'
    Info 'Standardformat: 16 Bit, 48000 Hz (DVD-Qualitaet)'
    Write-Host ""

    Write-Host "   BLUETOOTH-HEADSET" -ForegroundColor Yellow
    Info 'Ein Bluetooth-Headset kann NIE gleichzeitig gut klingen und sein'
    Info 'Mikrofon anbieten - das ist eine Grenze von Bluetooth selbst,'
    Info 'kein Windows-Fehler und mit keiner Einstellung zu umgehen.'
    Info 'Fuer Spiele deshalb: Hands-Free abschalten (Punkt 3 unter TON)'
    Info 'und ein separates Mikrofon benutzen.'
    Info 'Dauerhaft im System: Einstellungen -> Bluetooth -> Geraet ->'
    Info '  Geraeteeigenschaften -> Haken bei "Freisprechtelefonie" weg.'
    Info 'Wer das Headset-Mikro doch braucht: dann bewusst Hands-Free'
    Info '  waehlen und den schlechteren Klang in Kauf nehmen.'
    Write-Host ""

    Write-Host "   MIKROFON-PEGEL UND STANDARDGERAET" -ForegroundColor Yellow
    Info 'Win+R -> mmsys.cpl -> Reiter Aufnahme'
    Info '  - Mikro als Standard UND als Standard-Kommunikationsgeraet'
    Info '  - Eigenschaften -> Pegel: nicht 0, nicht stummgeschaltet'
    Info '  - Eigenschaften -> Erweitert: 16 Bit, 48000 Hz'
    Info 'Headset mit eigener Software (SteelSeries, Logitech, Razer):'
    Info '  dort pruefen, ob das Mikro dort stummgeschaltet ist.'
    Info 'Im Spiel: Einstellungen -> Audio -> Voicechat AN,'
    Info '  Mikrofon-Modus auf "Offenes Mikrofon" oder Push-to-Talk-Taste.'
    Write-Host ""

    Write-Host "   KONTOVERKNUEPFUNG" -ForegroundColor Yellow
    Info 'profile.callofduty.com -> Einstellungen -> Verknuepfte Konten'
    Info 'Steam bzw. Battle.net muss dort eingetragen sein.'
    Write-Host ""

    Write-Host "   KONTOSPERRE PRUEFEN" -ForegroundColor Yellow
    Info 'support.activision.com/de/enforcement'
    Info 'Eine Sperre zeigt sich oft als stumm haengender Login.'
    Write-Host ""

    Write-Host "   SERVERSTATUS" -ForegroundColor Yellow
    Info 'support.activision.com/onlineservices'
}

# ================================ MENUE =======================================
# Zweistufig: erst die Kategorie, dann das konkrete Problem.

# "Wann" beschreibt in einer Zeile, woran man erkennt, dass dieser Punkt der
# richtige ist. Bewusst hier und nicht in der Aktion: die Beschreibung hilft
# beim AUSWAEHLEN - danach ist sie nur noch Text, den niemand liest.
$Script:Kategorien = @(
    @{
        Key    = '1'
        Name   = 'BILD / GRAFIK'
        Kurz   = 'Schwarzbild, Grafikfehler, Ruckeln'
        Punkte = @(
            @{ Text = 'Schwarzbild, Grafikfehler, Dev-Error'
               Wann = 'seit einem Update, Dev-Error, Texturen fehlen'
               Fix  = 'Action-2';  Undo = 'Action-2b' },
            @{ Text = 'Bild schwarz, aber Ton laeuft'
               Wann = 'Menuegeraeusche hoerbar, falscher Monitor'
               Fix  = 'Action-3';  Undo = 'Action-3b' }
        )
    },
    @{
        Key    = '2'
        Name   = 'TON / MIKROFON'
        Kurz   = 'Kein Ton, Knacken, Voice-Chat, Bluetooth'
        Punkte = @(
            @{ Text = 'Kein Ton, Knacken, Aussetzer'
               Wann = 'gar kein Ton, Knistern, auch nach dem Spiel kaputt'
               Fix  = 'Action-4';  Undo = 'Action-4b'  },
            @{ Text = 'Mikrofon geht nicht, Voice-Chat'
               Wann = 'keiner hoert dich, Mikro wird nicht erkannt'
               Fix  = 'Action-5';  Undo = 'Action-5b'  },
            @{ Text = 'Bluetooth-Headset rauscht'
               Wann = 'dumpf oder blechern, klingt wie ein Telefon'
               Fix  = 'Action-11'; Undo = 'Action-11b' },
            @{ Text = 'Zu viele oder falsche Audiogeraete'
               Wann = 'Ton aus dem falschen Geraet, mehrere Mikrofone'
               Fix  = 'Action-12'; Undo = 'Action-12b' }
        )
    },
    @{
        Key    = '3'
        Name   = 'LOGIN / ANMELDUNG'
        Kurz   = 'Anmeldung haengt oder dreht sich im Kreis'
        Punkte = @(
            @{ Text = 'Login haengt, Anmeldung endlos'
               Wann = 'dreht sich im Kreis, Profil wird nicht geladen'
               Fix  = 'Action-1';  Undo = 'Action-1b' }
        )
    },
    @{
        Key    = '4'
        Name   = 'VERBINDUNG / INTERNET'
        Kurz   = 'haengt beim Update, Download-Fehler, Disconnects'
        Punkte = @(
            @{ Text = 'Download fehlgeschlagen (HILLCAT)'
               Wann = 'haengt bei "Pruefung auf Update", Fehlercode HILLCAT'
               Fix  = 'Action-13'; Undo = 'Action-13b' },
            @{ Text = 'Verbindungsfehler, Disconnects'
               Wann = 'Verbindung zum Host verloren, Warteschleife'
               Fix  = 'Action-6';  Undo = 'Action-6b' },
            @{ Text = 'Firewall blockiert das Spiel'
               Wann = 'kein Multiplayer, Onlinedienst nicht erreichbar'
               Fix  = 'Action-8';  Undo = 'Action-8b' }
        )
    },
    @{
        Key    = '5'
        Name   = 'ABSTUERZE / STARTPROBLEME'
        Kurz   = 'Spiel stuerzt ab oder startet gar nicht'
        Punkte = @(
            @{ Text = 'Absturz beim Start (Overlays)'
               Wann = 'Absturz direkt beim Start, friert im Menue ein'
               Fix  = 'Action-7';  Undo = 'Action-7b' },
            @{ Text = 'Spiel startet gar nicht'
               Wann = 'nichts passiert, Fenster geht auf und sofort zu'
               Fix  = 'Action-9';  Undo = 'Action-9b' }
        )
    },
    @{
        Key    = '6'
        Name   = 'LEISTUNG / RUCKELN'
        Kurz   = 'Ruckeln, FPS-Einbrueche, Verzoegerung'
        Punkte = @(
            @{ Text = 'Ruckeln, FPS-Einbrueche, Stottern'
               Wann = 'Mikroruckler, Eingabe verzoegert, System stottert'
               Fix  = 'Action-10'; Undo = 'Action-10b' }
        )
    }
)

function Show-Kopf {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "                                                                  " -BackgroundColor DarkCyan
    Write-Host "      C A L L   O F   D U T Y   -   F I X - W E R K Z E U G       " -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host ("                                                     v{0}          " -f $Script:Version) -ForegroundColor Gray -BackgroundColor DarkCyan
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Show-Kopf
    Write-Host "    WO LIEGT DAS PROBLEM?" -ForegroundColor White
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($k in $Script:Kategorien) {
        Write-Host "      $($k.Key)  " -ForegroundColor Green -NoNewline
        Write-Host $k.Name -ForegroundColor White
        Write-Host "         $($k.Kurz)" -ForegroundColor DarkGray
        Write-Host ""
    }
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "      D  " -ForegroundColor Cyan -NoNewline; Write-Host "Diagnose  -  System pruefen, Fehlerquellen finden" -ForegroundColor Gray
    Write-Host "      H  " -ForegroundColor Cyan -NoNewline; Write-Host "Hilfe  -  ich oeffne dir das richtige Windows-Fenster" -ForegroundColor Gray
    Write-Host "      A  " -ForegroundColor Cyan -NoNewline; Write-Host "ALLES rueckgaengig machen" -ForegroundColor Gray
    Write-Host "      0  " -ForegroundColor Cyan -NoNewline; Write-Host "Beenden" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "     Keine Ahnung wo es klemmt?  Starte mit D (Diagnose)." -ForegroundColor DarkGray
    Write-Host "     Vor jeder Aktion wird automatisch ein Backup angelegt." -ForegroundColor DarkGray
    Write-Host "     Benutzung auf eigene Gefahr - keine Haftung. Siehe README." -ForegroundColor DarkYellow
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# Bewusst genauso aufgebaut wie das Hauptmenue: Zahl, Ueberschrift, darunter
# grau die Erkennungsmerkmale. Wer das Hauptmenue verstanden hat, versteht
# auch dieses - ohne umzudenken.
function Show-SubMenu {
    param($Kategorie)
    Show-Kopf
    Write-Host "    $($Kategorie.Name)" -ForegroundColor Yellow
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    WAS PASST AM BESTEN?" -ForegroundColor White
    Write-Host ""
    $i = 1
    foreach ($p in $Kategorie.Punkte) {
        Write-Host "      $i  " -ForegroundColor Green -NoNewline
        Write-Host $p.Text -ForegroundColor White
        if ($p.Wann) { Write-Host "         $($p.Wann)" -ForegroundColor DarkGray }
        Write-Host ""
        $i++
    }
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "      0  " -ForegroundColor Cyan -NoNewline; Write-Host "Zurueck zum Hauptmenue" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "     Zahl repariert  -  Zahl mit b macht rueckgaengig (z.B. 1b)" -ForegroundColor DarkGray
    Write-Host "    ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Run-SubMenu {
    param($Kategorie)
    while ($true) {
        Show-SubMenu -Kategorie $Kategorie
        $w = (Read-Host "     Deine Wahl").Trim().ToLower()
        if ($w -eq '0') { return }

        $undo = $false
        $nr   = $w
        if ($w -match '^(\d+)b$') { $undo = $true; $nr = $Matches[1] }

        $idx = 0
        if ([int]::TryParse($nr, [ref]$idx) -and $idx -ge 1 -and $idx -le $Kategorie.Punkte.Count) {
            $punkt = $Kategorie.Punkte[$idx - 1]
            if ($undo) { & $punkt.Undo } else { & $punkt.Fix }
            Pause-Key
        } else {
            Write-Host ""
            Write-Host "     '$w' gibt es hier nicht. Bitte 1-$($Kategorie.Punkte.Count), 1b-$($Kategorie.Punkte.Count)b oder 0." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

# ================================ START =======================================

if (-not (Test-Admin)) {
    Write-Host ""
    Write-Host "   Dieses Werkzeug braucht Administratorrechte." -ForegroundColor Red
    Write-Host "   Bitte CoD-Fix.cmd per Rechtsklick als Administrator starten." -ForegroundColor Yellow
    Write-Host ""
    Pause-Key
    exit
}

try { $Host.UI.RawUI.WindowTitle = "Call of Duty - Fix-Werkzeug v$Script:Version" } catch {}
# Kein Ensure-BackupRoot beim Start: der Ordner entsteht erst, wenn wirklich
# etwas gesichert wird. Bis dahin sammelt Say die Protokollzeilen.
Say "=== CoD-Fix v$Script:Version gestartet ==="

while ($true) {
    Show-MainMenu
    $wahl = (Read-Host "     Deine Wahl").Trim().ToLower()

    $kat = $Script:Kategorien | Where-Object { $_.Key -eq $wahl } | Select-Object -First 1
    if ($kat) { Run-SubMenu -Kategorie $kat; continue }

    switch ($wahl) {
        'd'  { Action-D; Pause-Key }
        'a'  { Action-A; Pause-Key }
        'h'  { Action-H; Pause-Key }
        '0'  {
            Write-LogPuffer
            Write-Host ""
            if (Test-Path $Script:BackupRoot) {
                Write-Host "     Backups und Protokoll liegen in:" -ForegroundColor DarkGray
                Write-Host "     $Script:BackupRoot" -ForegroundColor DarkGray
                Write-Host ""
            }
            Write-Host "     Viel Spass beim Spielen!" -ForegroundColor Green
            Write-Host ""
            Start-Sleep -Seconds 2
            exit
        }
        default {
            # Auswahl aus der Kategorienliste ableiten, damit der Hinweis
            # nicht veraltet, sobald eine Kategorie dazukommt.
            $gueltig = ($Script:Kategorien | ForEach-Object { $_.Key }) -join ', '
            Write-Host ""
            Write-Host "     '$wahl' kenne ich nicht. Bitte $gueltig oder D/H/A/0." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
