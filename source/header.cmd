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
