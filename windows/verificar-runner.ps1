<#
.SYNOPSIS
  verificar-runner.ps1 — chequeo integral post-instalación del runner Windows (lo corre Ricardo a mano).
.DESCRIPTION
  Prerrequisitos, clon sano y en la rama, Stata ejecuta un do-file batch (display "ok" + Python + requests/bs4),
  escritura de prueba al Drive, tarea registrada con próxima ejecución, y una corrida completa de prueba
  (actualizar-nl.ps1 -Manual). Salida: tabla verde/rojo + qué pegar a Devin/Claude si algo sale rojo.
.PARAMETER SinCorrida   Omite la corrida completa de prueba (solo chequeos).
.PARAMETER Offline      La corrida de prueba reutiliza la caché INEGI.
#>
param([switch]$SinCorrida, [switch]$Offline)
$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'runner-common.ps1')
$Salida = Join-Path $script:RunnerDir 'verificacion-runner.log'
Write-Host "Simulador Fiscal NL — verificación del runner Windows" -ForegroundColor Cyan
Write-Host ("Fecha: " + (Get-Date) + "  Usuario: " + $env:USERNAME + "  Equipo: " + $env:COMPUTERNAME + "  PowerShell: " + $PSVersionTable.PSVersion)

Write-Paso "1. Configuración"
try { $C = Get-RunnerConfig; Write-Ok ("config-runner.ps1 leído: repo=" + $C.Repo + " | stata=" + $C.Stata + " | drive=" + $C.Drive + " | rama=" + $C.Rama) }
catch { Write-Fail $_.Exception.Message; [void](Show-Resumen "Verificación" $Salida); exit 1 }

Write-Paso "2. Prerrequisitos"
if (Get-Command git -ErrorAction SilentlyContinue) { Write-Ok ("git: " + (& git --version)) } else { Write-Fail "git no está en el PATH" }
$crlf = ((Invoke-Native 'git config --global --get core.autocrlf').Out).Trim(); if ($crlf -eq 'false') { Write-Ok "core.autocrlf = false" } else { Write-Fail ("core.autocrlf = '" + $crlf + "' (debe ser false)") }
if (Test-Path -LiteralPath $C.Stata) { Write-Ok ("Stata: " + $C.Stata) } else { Write-Fail ("No existe el ejecutable de Stata: " + $C.Stata) }
$gd = Get-Process -Name 'GoogleDriveFS' -ErrorAction SilentlyContinue; if ($gd) { Write-Ok "Google Drive Desktop en ejecución" } else { Write-Warn "GoogleDriveFS no está corriendo: el Drive puede no sincronizar" }

Write-Paso "3. Clon de solo lectura"
if (Test-Path -LiteralPath (Join-Path $C.Repo '.git')) {
    Push-Location $C.Repo
    $rama = (& git rev-parse --abbrev-ref HEAD).Trim()
    if ($rama -eq $C.Rama) { Write-Ok ("Rama actual: " + $rama) } else { Write-Fail ("Rama actual '" + $rama + "' ≠ '" + $C.Rama + "'") }
    $sucio = (& git status --porcelain); if ($sucio) { Write-Fail ("Working tree SUCIO (el runner nunca desarrolla):`r`n" + ($sucio -join "`r`n")) } else { Write-Ok "Working tree limpio" }
    $rf = Invoke-Native ('git fetch origin ' + $C.Rama)
    if ($rf.Code -eq 0) {
        $local = (& git rev-parse HEAD).Trim(); $remoto = (& git rev-parse ("origin/" + $C.Rama)).Trim()
        if ($local -eq $remoto) { Write-Ok ("Al día con origin/" + $C.Rama + " @ " + $local.Substring(0,7)) } else { Write-Warn ("HEAD " + $local.Substring(0,7) + " ≠ origin " + $remoto.Substring(0,7) + " (actualizar-nl.ps1 lo alinea con reset --hard)") }
    } else { Write-Fail "git fetch falló: ¿sin red o deploy key no registrada/revocada? Revisa ssh -T git@github-simulador-nl" }
    $ro = (& git remote get-url origin).Trim(); if ($ro -like 'git@github-simulador-nl:*') { Write-Ok ("Remoto por deploy key: " + $ro) } else { Write-Warn ("Remoto inesperado: " + $ro) }
    Pop-Location
    foreach ($f in '01_modulos\PoblacionNL.do','01_modulos\PIBDeflactorNL.do','01_modulos\FederacionNL.do','01_modulos\nl-assets\nl-fed.do','01_modulos\nl-assets\nl_fed.py','01_modulos\nl-assets\federacion-sello.json','01_modulos\nl-assets\federacion-nl.html','01_modulos\nl-assets\actualizar-nl.do','profile.do','01_modulos\nl-assets\pobproy_quinq1.csv') { if (Test-Path -LiteralPath (Join-Path $C.Repo $f)) { Write-Ok ("Existe " + $f) } else { Write-Fail ("Falta " + $f + " en el clon") } }
} else { Write-Fail ("No hay clon en " + $C.Repo + ". Corre instalar-runner.ps1.") }

Write-Paso "4. Stata en batch (display, Python, requests/bs4)"
if (Test-Path -LiteralPath $C.Stata) {
    $tdir = Join-Path $env:TEMP 'nl-runner-test'; New-Item -ItemType Directory -Path $tdir -Force | Out-Null
    $tdo = Join-Path $tdir 'prueba-stata.do'
    @('version 17', 'display "STATA_OK"', 'display c(stata_version) " " c(edition)', 'capture python which sys', 'if _rc di "PYTHON_NO"', 'else {', '  python: print("PYTHON_OK")', '  capture python: import requests, bs4', '  if _rc di "REQUESTS_NO"', '  else di "REQUESTS_OK"', '}', 'capture noisily SIMroot', 'di "SIMROOT=${SIMROOT}"') | Set-Content -LiteralPath $tdo -Encoding ASCII
    try {
        $log = Invoke-StataBatch -Stata $C.Stata -DoFile $tdo -WorkDir $C.Repo -TimeoutMin 5
        $txt = Get-Content -LiteralPath $log -Raw
        if ($txt -match 'STATA_OK') { Write-Ok ("Stata ejecuta do-files en batch (" + (([regex]::Match($txt, '(?m)^\s*(1[0-9]\.\d+ \w+)').Groups[1].Value)) + ")") } else { Write-Fail ("Stata corrió pero no imprimió STATA_OK; log: " + $log) }
        if ($txt -match 'PYTHON_OK') { Write-Ok "Python de Stata inicializa" } elseif ($txt -match 'PYTHON_NO') { Write-Fail "Stata no inicializa Python: en Stata corre 'python search' y luego 'python set exec <ruta\python.exe>, permanently' (Python 3.9–3.12). Sin Python no hay descargas INEGI." } else { Write-Warn "No se pudo determinar el estado de Python (ver log)" }
        if ($txt -match 'REQUESTS_OK') { Write-Ok "Módulos requests y bs4 disponibles (AccesoBIE del motor)" } elseif ($txt -match 'REQUESTS_NO') { Write-Fail "Faltan requests/beautifulsoup4 en el Python de Stata: <ruta\python.exe> -m pip install requests beautifulsoup4" }
        if ($txt -match '(?m)^SIMROOT=([^\$\s"][^\r\n]*?)\r?$') { Write-Ok ("SIMroot resuelve la raíz: " + $Matches[1].Trim()) } else { Write-Fail "SIMroot no resolvió la raíz (¿profile.do no cargó desde el directorio del repo?). Líneas con SIMROOT en el log: " + ((Select-String -LiteralPath $log -Pattern "SIMROOT|r\(\d+\)" | Select-Object -First 4 | ForEach-Object { $_.Line.Trim() }) -join " | ") + " (log: " + $log + ")" }
    } catch { Write-Fail ("Stata batch falló: " + $_.Exception.Message) }
}

Write-Paso "5. Drive de CoNL"
$DrivePadre = Split-Path -Parent $C.Drive
if (Test-Path -LiteralPath $DrivePadre) {
    Write-Ok ("Montado: " + $DrivePadre)
    try { $probe = Join-Path $C.Drive ('.runner-probe-' + [guid]::NewGuid().ToString('N') + '.tmp'); if (-not (Test-Path -LiteralPath $C.Drive)) { New-Item -ItemType Directory -Path $C.Drive -Force | Out-Null }; Set-Content -LiteralPath $probe -Value 'probe' -Encoding ASCII; Remove-Item -LiteralPath $probe -Force; Write-Ok "Escritura y borrado de prueba en el Drive: correctos" } catch { Write-Fail ("No se pudo escribir en " + $C.Drive + ": " + $_.Exception.Message) }
    $lat = Join-Path $C.Drive 'ultimo-exito.txt'; if (Test-Path -LiteralPath $lat) { Write-Ok ("Latido previo: " + ((Get-Content -LiteralPath $lat -TotalCount 2)[1])) } else { Write-Warn "Aún no hay ultimo-exito.txt en el Drive (normal antes de la primera corrida)" }
} else { Write-Fail ("Drive no montado: " + $DrivePadre) }

Write-Paso "6. Tarea programada"
$t = Get-ScheduledTask -TaskName 'SimuladorNL-Actualizar' -ErrorAction SilentlyContinue
if ($t) {
    $i = Get-ScheduledTaskInfo -TaskName 'SimuladorNL-Actualizar'
    Write-Ok ("Registrada; estado " + $t.State + "; próxima ejecución " + $i.NextRunTime + "; último resultado " + $i.LastTaskResult + " (" + $i.LastRunTime + ")")
    if (-not $i.NextRunTime -or $i.NextRunTime -lt (Get-Date)) { Write-Warn "La tarea no tiene próxima ejecución futura; revisa que esté habilitada" }
    Write-Warn "Recuerda: corre solo con la sesión iniciada (puede estar bloqueada), porque G:\ existe solo dentro de la sesión."
} else { Write-Fail "La tarea SimuladorNL-Actualizar no está registrada. Corre instalar-runner.ps1 (como administrador si falla el registro)." }

if (-not $SinCorrida) {
    Write-Paso "7. Corrida completa de prueba (actualizar-nl.ps1 -Manual)"
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $script:RunnerDir 'actualizar-nl.ps1') + '"'), '-Manual'); if ($Offline) { $args += '-Offline' }
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -eq 0) { Write-Ok "Corrida completa OK: publicado y bitácora actualizada" } else { Write-Fail ("La corrida de prueba falló (código " + $p.ExitCode + "). Revisa windows\bitacora-runner.log y users\" + $env:USERNAME + "\nodos\actualizar-nl-stata.log") }
}

$ok = Show-Resumen "Verificación del runner" $Salida
Write-Host ""
if ($ok) { Write-Host "Runner listo. El latido está en el Drive: ultimo-exito.txt" -ForegroundColor Green } else { Write-Host ("Si algo salió en ROJO: pega a Devin/Claude el archivo " + $Salida + " y, si aplica, windows\bitacora-runner.log y la cola del log de Stata.") -ForegroundColor Yellow }
if (-not $ok) { exit 1 }
