<#
================================================================================
  BAUT  CoD-Fix.cmd  AUS  source\header.cmd  +  source\CoD-Fix.ps1

  Aufruf:   powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1

  Warum es das gibt: CoD-Fix.cmd enthaelt eine Kopie des PowerShell-Skripts.
  Zwei Kopien von Hand synchron zu halten geht eine Weile gut und dann
  irgendwann nicht mehr - der Fehler faellt erst beim Nutzer auf, weil die
  ausgelieferte Datei etwas anderes tut als die lesbare Quelle.

  Vor dem Schreiben wird geprueft:
    1. Das PowerShell-Skript ist syntaktisch fehlerfrei
    2. Es enthaelt nur ASCII-Zeichen (Windows PowerShell 5.1 liest Dateien
       ohne Byte-Order-Mark sonst als ANSI und verstuemmelt Umlaute)
    3. Die Markierung :::PSCODE::: kommt genau einmal vor
    4. Aus der fertigen .cmd laesst sich die Quelle Zeichen fuer Zeichen
       wieder herausloesen
================================================================================
#>

$ErrorActionPreference = 'Stop'

$Wurzel   = Split-Path -Parent $MyInvocation.MyCommand.Path
$HeadPfad = Join-Path $Wurzel 'source\header.cmd'
$PsPfad   = Join-Path $Wurzel 'source\CoD-Fix.ps1'
$ZielPfad = Join-Path $Wurzel 'CoD-Fix.cmd'

function Schritt { param([string]$t) Write-Host "  $t" -ForegroundColor Gray }
function Gut     { param([string]$t) Write-Host "  [ok]   $t" -ForegroundColor Green }
function Schlimm { param([string]$t) Write-Host "  [FEHL] $t" -ForegroundColor Red }

Write-Host ""
Write-Host "  CoD-Fix bauen" -ForegroundColor Cyan
Write-Host "  -------------" -ForegroundColor DarkGray

foreach ($p in @($HeadPfad, $PsPfad)) {
    if (-not (Test-Path $p)) { Schlimm "Fehlt: $p"; exit 1 }
}

# --- 1. Syntax ---------------------------------------------------------------
Schritt 'Syntax pruefen...'
$fehler = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($PsPfad, [ref]$null, [ref]$fehler)
if ($fehler -and $fehler.Count -gt 0) {
    Schlimm "$($fehler.Count) Syntaxfehler in CoD-Fix.ps1:"
    foreach ($f in $fehler) {
        Write-Host ("         Zeile {0}: {1}" -f $f.Extent.StartLineNumber, $f.Message) -ForegroundColor DarkGray
    }
    exit 1
}
Gut 'Syntax in Ordnung'

# --- 2. Nur ASCII ------------------------------------------------------------
Schritt 'Zeichensatz pruefen...'
$psText = [System.IO.File]::ReadAllText($PsPfad)
if ($psText -cmatch '[^\x00-\x7F]') {
    $zeilen = ($psText -split "`r?`n")
    Schlimm 'Nicht-ASCII-Zeichen gefunden - bitte durch ae/oe/ue/ss ersetzen:'
    for ($i = 0; $i -lt $zeilen.Count; $i++) {
        if ($zeilen[$i] -cmatch '[^\x00-\x7F]') {
            Write-Host ("         Zeile {0}: {1}" -f ($i+1), $zeilen[$i].Trim()) -ForegroundColor DarkGray
        }
    }
    exit 1
}
Gut 'Nur ASCII'

# --- 3. Markierung -----------------------------------------------------------
Schritt 'Markierung pruefen...'
$marke   = ':::PS' + 'CODE:::'
$headTxt = [System.IO.File]::ReadAllText($HeadPfad)
$imHead  = ([regex]::Matches($headTxt, [regex]::Escape($marke))).Count
$imPs    = ([regex]::Matches($psText,  [regex]::Escape($marke))).Count
if ($imHead -ne 1) { Schlimm "header.cmd enthaelt die Markierung $imHead mal, erwartet: genau 1"; exit 1 }
if ($imPs   -ne 0) { Schlimm "CoD-Fix.ps1 enthaelt die Markierung - das wuerde das Herausschneiden zerreissen"; exit 1 }
Gut 'Markierung genau einmal im Kopf'

# --- 4. Zusammenbauen --------------------------------------------------------
Schritt 'Zusammenbauen...'
$text = $headTxt.TrimEnd("`r", "`n") + "`r`n" + $psText
# Durchgehend CRLF: cmd.exe fuehrt Dateien mit reinen LF-Zeilenenden nicht
# zuverlaessig aus.
$text = ($text -replace "`r`n", "`n") -replace "`n", "`r`n"
[System.IO.File]::WriteAllText($ZielPfad, $text, (New-Object System.Text.UTF8Encoding $false))

# --- 5. Gegenprobe -----------------------------------------------------------
Schritt 'Gegenprobe...'
$fertig = [System.IO.File]::ReadAllText($ZielPfad)
$i = $fertig.IndexOf($marke)
if ($i -lt 0) { Schlimm 'Markierung in der fertigen Datei nicht gefunden'; exit 1 }
$zurueck = $fertig.Substring($i + $marke.Length).TrimStart("`r", "`n")
$erwartet = ($psText -replace "`r`n", "`n") -replace "`n", "`r`n"
if ($zurueck -cne $erwartet) {
    Schlimm 'Das Herausgeschnittene stimmt nicht mit der Quelle ueberein'
    exit 1
}
Gut 'Eingebettetes Skript stimmt mit der Quelle ueberein'

$kb = [math]::Round((Get-Item $ZielPfad).Length / 1KB)
Write-Host ""
Write-Host "  Fertig: CoD-Fix.cmd  ($kb KB, $(($psText -split "`r?`n").Count) Zeilen PowerShell)" -ForegroundColor Green
Write-Host ""
