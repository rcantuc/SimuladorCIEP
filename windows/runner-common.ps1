# runner-common.ps1 — funciones compartidas del runner Windows de la capa NL (NL-0.3.0).
# Se carga con dot-source desde instalar-runner.ps1, actualizar-nl.ps1 y verificar-runner.ps1.
# PowerShell 5.1 (Windows 11). Codificación: UTF-8 con BOM.

$script:RunnerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:RunnerDir 'config-runner.ps1'
$script:Resultados = New-Object System.Collections.ArrayList

function Write-Ok   { param([string]$Msg) Write-Host ("  [OK]    " + $Msg) -ForegroundColor Green;  [void]$script:Resultados.Add([pscustomobject]@{Estado='OK';   Detalle=$Msg}) }
function Write-Fail { param([string]$Msg) Write-Host ("  [ROJO]  " + $Msg) -ForegroundColor Red;    [void]$script:Resultados.Add([pscustomobject]@{Estado='ROJO'; Detalle=$Msg}) }
function Write-Warn { param([string]$Msg) Write-Host ("  [AVISO] " + $Msg) -ForegroundColor Yellow; [void]$script:Resultados.Add([pscustomobject]@{Estado='AVISO';Detalle=$Msg}) }
function Write-Paso { param([string]$Msg) Write-Host ""; Write-Host ("== " + $Msg) -ForegroundColor Cyan }

function Get-RunnerConfig {
    # Devuelve $RunnerConfig (hashtable) leído de config-runner.ps1; termina con mensaje accionable si falta.
    if (-not (Test-Path -LiteralPath $script:ConfigPath)) {
        throw ("No existe " + $script:ConfigPath + ". Corre primero windows\instalar-runner.ps1 (genera la configuración desde la plantilla).")
    }
    . $script:ConfigPath
    foreach ($k in 'Repo','Stata','Drive','Rama','RepoSsh','SshHost') {
        if (-not $RunnerConfig.ContainsKey($k) -or [string]::IsNullOrWhiteSpace([string]$RunnerConfig[$k])) {
            throw ("config-runner.ps1 sin la clave '" + $k + "'. Vuelve a correr instalar-runner.ps1 o edítala a mano.")
        }
    }
    return $RunnerConfig
}

function Find-Stata {
    # Autodetección del ejecutable de Stata: C:\Program Files\Stata19\ (MP > SE > BE), luego StataNow*.
    $cands = @()
    $base = 'C:\Program Files\Stata19'
    foreach ($n in 'StataMP-64.exe','StataSE-64.exe','StataBE-64.exe') {
        $p = Join-Path $base $n
        if (Test-Path -LiteralPath $p) { $cands += $p }
    }
    $dirs = Get-ChildItem -Path 'C:\Program Files' -Directory -Filter 'Stata*' -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $exes = Get-ChildItem -Path $d.FullName -Filter '*.exe' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^Stata(Now)?(MP|SE|BE|IC)?-64\.exe$' -or $_.Name -like 'StataNow*' }
        foreach ($e in $exes) { if ($cands -notcontains $e.FullName) { $cands += $e.FullName } }
    }
    # Orden de preferencia: MP, SE, BE, luego el resto (StataNow*)
    $ordenado = @()
    foreach ($pat in 'MP-64','SE-64','BE-64') { $ordenado += ($cands | Where-Object { $_ -like ('*' + $pat + '*') }) }
    $ordenado += ($cands | Where-Object { $ordenado -notcontains $_ })
    if ($ordenado.Count -eq 0) { return $null }
    return $ordenado[0]
}

function Invoke-StataBatch {
    # Ejecuta un do-file en batch (/e) con el directorio de trabajo indicado y devuelve la ruta del log.
    param([string]$Stata, [string]$DoFile, [string]$WorkDir, [int]$TimeoutMin = 90)
    $logName = [System.IO.Path]::GetFileNameWithoutExtension($DoFile) + '.log'
    $logEnCwd = Join-Path $WorkDir $logName
    $logEnDo  = Join-Path (Split-Path -Parent $DoFile) $logName
    foreach ($l in $logEnCwd, $logEnDo) { if (Test-Path -LiteralPath $l) { Remove-Item -LiteralPath $l -Force } }
    $p = Start-Process -FilePath $Stata -ArgumentList @('/e', 'do', ('"' + $DoFile + '"')) -WorkingDirectory $WorkDir -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit($TimeoutMin * 60 * 1000)) {
        try { $p.Kill() } catch {}
        throw ("Stata no terminó en " + $TimeoutMin + " minutos; proceso detenido.")
    }
    foreach ($l in $logEnCwd, $logEnDo) { if (Test-Path -LiteralPath $l) { return $l } }
    throw ("Stata no dejó log (" + $logEnCwd + " ni " + $logEnDo + "). Código de salida: " + $p.ExitCode)
}

function Test-StataLogError {
    # Devuelve la primera línea r(###); del log de Stata (o $null si no hay error).
    param([string]$LogPath)
    $m = Select-String -LiteralPath $LogPath -Pattern '^r\(\d+\);' | Select-Object -First 1
    if ($m) { return $m } else { return $null }
}

function Invoke-Native {
    # Ejecuta un comando nativo (git, ssh, robocopy) capturando stdout+stderr SIN que PowerShell 5.1
    # convierta stderr en excepción bajo $ErrorActionPreference = 'Stop' (git y ssh escriben progreso a stderr).
    # Devuelve @{ Out = texto; Code = código de salida }.
    param([string]$CommandLine)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & cmd.exe /d /c ($CommandLine + ' 2>&1')
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prev }
    return @{ Out = (($out | ForEach-Object { [string]$_ }) -join "`r`n"); Code = $code }
}

function Write-Bitacora {
    param([string]$Ruta, [string]$Linea)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $Ruta -Value ($ts + ' ' + $Linea) -Encoding UTF8
}

function Show-Resumen {
    param([string]$Titulo, [string]$LogSalida)
    Write-Host ""; Write-Host ("==== " + $Titulo + " ====") -ForegroundColor Cyan
    $script:Resultados | Format-Table -AutoSize | Out-String | Write-Host
    $rojos = @($script:Resultados | Where-Object { $_.Estado -eq 'ROJO' })
    if ($LogSalida) {
        $script:Resultados | Format-Table -AutoSize | Out-String | Set-Content -LiteralPath $LogSalida -Encoding UTF8
    }
    if ($rojos.Count -gt 0) {
        Write-Host ("Hay " + $rojos.Count + " punto(s) en ROJO.") -ForegroundColor Red
        if ($LogSalida) { Write-Host ("Pega a Devin/Claude el contenido de: " + $LogSalida) -ForegroundColor Yellow }
        return $false
    }
    Write-Host "Todo en verde." -ForegroundColor Green
    return $true
}
