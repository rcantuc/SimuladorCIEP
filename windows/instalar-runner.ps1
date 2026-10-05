<#
.SYNOPSIS
  instalar-runner.ps1 — instala (idempotente) el runner Windows de la capa NL del Simulador Fiscal CIEP.
.DESCRIPTION
  1. Verifica prerrequisitos (git, core.autocrlf=false, Drive de CoNL montado y sincronizando, Stata detectado, OpenSSH).
  2. Crea una deploy key ed25519 de SOLO LECTURA (%USERPROFILE%\.ssh\simulador_nl_deploy) y configura ~/.ssh/config.
  3. Clona/actualiza SOLO la rama feature/entidad-nl en C:\Users\<user>\SimuladorCIEP-NL.
  4. Genera windows\config-runner.ps1 desde la plantilla.
  5. Registra la tarea programada SimuladorNL-Actualizar (mensual, día 5, 03:00; si se omitió, corre en cuanto pueda).
  Correrlo dos veces deja el mismo estado. Cada paso se reporta en verde/rojo con el siguiente paso accionable.
.PARAMETER Repo       Carpeta del clon (default: $env:USERPROFILE\SimuladorCIEP-NL)
.PARAMETER Drive      Carpeta del Drive de CoNL (default: G:\Mi unidad\2. Simuladores CoNL\SimuladorCoNL)
.PARAMETER Rama       Rama a clonar (default: feature/entidad-nl)
.PARAMETER SinTarea   No registra la tarea programada.
#>
param(
    [string]$Repo = (Join-Path $env:USERPROFILE 'SimuladorCIEP-NL'),
    [string]$Drive = 'G:\Mi unidad\2. Simuladores CoNL\SimuladorCoNL',
    [string]$Rama = 'feature/entidad-nl',
    [string]$RepoGitHub = 'rcantuc/SimuladorCIEP',
    [switch]$SinTarea
)
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'runner-common.ps1')
$SshHost = 'github-simulador-nl'
$RepoSsh = 'git@' + $SshHost + ':' + $RepoGitHub + '.git'
$KeyPath = Join-Path $env:USERPROFILE '.ssh\simulador_nl_deploy'
$Bloqueante = $false

Write-Host "Simulador Fiscal NL — instalador del runner Windows" -ForegroundColor Cyan
Write-Host ("Usuario: " + $env:USERNAME + "  Equipo: " + $env:COMPUTERNAME + "  PowerShell: " + $PSVersionTable.PSVersion)

# ---------- 1. Prerrequisitos ----------
Write-Paso "1. Prerrequisitos"
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) { Write-Ok ("git: " + (& git --version)) } else { Write-Fail "git no está en el PATH. Instala Git para Windows (https://git-scm.com) y vuelve a correr."; $Bloqueante = $true }
if ($git) {
    $crlf = ((Invoke-Native 'git config --global --get core.autocrlf').Out).Trim()
    if ($crlf -eq 'false') { Write-Ok "git core.autocrlf = false" }
    elseif ([string]::IsNullOrEmpty($crlf)) { & git config --global core.autocrlf false; Write-Ok "git core.autocrlf no estaba definido: se fijó en false" }
    elseif ($crlf -eq 'false') { Write-Ok "git core.autocrlf = false" }
    else { Write-Fail ("git core.autocrlf = '" + $crlf + "'. Debe ser false (el runner no convierte finales de línea). Corre: git config --global core.autocrlf false"); $Bloqueante = $true }
}
$ssh = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if ($ssh) { Write-Ok "OpenSSH (ssh-keygen) disponible" } else { Write-Fail "ssh-keygen no está disponible. Configuración > Aplicaciones > Características opcionales > 'Cliente de OpenSSH'."; $Bloqueante = $true }

$DrivePadre = Split-Path -Parent $Drive
if (Test-Path -LiteralPath $DrivePadre) {
    Write-Ok ("Drive de CoNL montado: " + $DrivePadre)
    if (-not (Test-Path -LiteralPath $Drive)) { New-Item -ItemType Directory -Path $Drive | Out-Null; Write-Ok ("Creada la carpeta destino: " + $Drive) }
    try {
        $probe = Join-Path $Drive ('.runner-probe-' + [guid]::NewGuid().ToString('N') + '.tmp')
        Set-Content -LiteralPath $probe -Value 'probe' -Encoding ASCII; Remove-Item -LiteralPath $probe -Force
        Write-Ok "Escritura de prueba en el Drive: correcta"
    } catch { Write-Fail ("No se pudo escribir en " + $Drive + ": " + $_.Exception.Message); $Bloqueante = $true }
    $gd = Get-Process -Name 'GoogleDriveFS' -ErrorAction SilentlyContinue
    if ($gd) { Write-Ok "Google Drive Desktop en ejecución (GoogleDriveFS)" } else { Write-Warn "No se ve el proceso GoogleDriveFS: la carpeta existe pero quizá no sincroniza. Abre Google Drive Desktop." }
} else { Write-Fail ("No existe " + $DrivePadre + ". Instala/abre Google Drive Desktop con la cuenta de CoNL y verifica la letra de unidad (G:)."); $Bloqueante = $true }

$Stata = Find-Stata
if ($Stata) { Write-Ok ("Stata detectado: " + $Stata) } else { Write-Fail "No se encontró Stata en C:\Program Files\Stata19\ (StataMP-64.exe / StataSE-64.exe / StataBE-64.exe) ni StataNow*. Instálalo o edita config-runner.ps1 a mano."; $Bloqueante = $true }

if ($Bloqueante) { [void](Show-Resumen "Instalación detenida por prerrequisitos" (Join-Path $script:RunnerDir 'instalacion-runner.log')); exit 1 }

# ---------- 2. Deploy key de solo lectura ----------
Write-Paso "2. Deploy key (solo lectura)"
$sshDir = Join-Path $env:USERPROFILE '.ssh'
if (-not (Test-Path -LiteralPath $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
if (-not (Test-Path -LiteralPath $KeyPath)) {
    # -N '""' es el modo documentado en Windows PowerShell 5.1 para pasar una passphrase vacía a ssh-keygen
    $r = Invoke-Native ('ssh-keygen -t ed25519 -N "" -f "' + $KeyPath + '" -C "simulador-nl-runner@' + $env:COMPUTERNAME + '"')
    if ($r.Code -ne 0 -or -not (Test-Path -LiteralPath $KeyPath)) { Write-Fail ("ssh-keygen falló: " + $r.Out); exit 2 }
    Write-Ok ("Llave creada: " + $KeyPath)
} else { Write-Ok ("Llave existente: " + $KeyPath) }
$pub = Get-Content -LiteralPath ($KeyPath + '.pub') -Raw
Write-Host ""
Write-Host "  Registra ESTA llave pública en GitHub (una sola vez):" -ForegroundColor Yellow
Write-Host ("  https://github.com/" + $RepoGitHub + "/settings/keys  →  Add deploy key  →  Title: runner-conl-" + $env:COMPUTERNAME + "  →  SIN 'Allow write access'") -ForegroundColor Yellow
Write-Host ""; Write-Host ("  " + $pub.Trim()) -ForegroundColor White; Write-Host ""
$cfg = Join-Path $sshDir 'config'
$bloque = @("Host $SshHost", "    HostName github.com", "    User git", "    IdentityFile $KeyPath", "    IdentitiesOnly yes", "")
$existe = (Test-Path -LiteralPath $cfg) -and ((Get-Content -LiteralPath $cfg -Raw) -match ('(?m)^Host\s+' + [regex]::Escape($SshHost) + '\s*$'))
if (-not $existe) { Add-Content -LiteralPath $cfg -Value ($bloque -join "`r`n") -Encoding ASCII; Write-Ok ("Alias SSH agregado a " + $cfg) } else { Write-Ok ("Alias SSH ya existía en " + $cfg) }
$kh = Join-Path $sshDir 'known_hosts'
if (-not ((Test-Path -LiteralPath $kh) -and ((Get-Content -LiteralPath $kh -Raw) -match 'github\.com'))) {
    $r = Invoke-Native 'ssh-keyscan -t ed25519 github.com'
    $scan = ($r.Out -split "`r`n") | Where-Object { $_ -match '^github\.com\s+ssh-ed25519' }
    if ($scan) { Add-Content -LiteralPath $kh -Value $scan -Encoding ASCII; Write-Ok "github.com agregado a known_hosts" } else { Write-Warn "No se pudo hacer ssh-keyscan de github.com (¿sin red?); el primer clone pedirá confirmación." }
} else { Write-Ok "github.com ya está en known_hosts" }
# Prueba de autenticación (GitHub devuelve código 1 con 'successfully authenticated' cuando la llave es válida)
$auth = (Invoke-Native ('ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@' + $SshHost)).Out
if ($auth -match 'successfully authenticated') { Write-Ok "GitHub acepta la deploy key" }
else { Write-Fail "GitHub aún NO acepta la llave (registra la clave pública de arriba como Deploy key de solo lectura y vuelve a correr este instalador). Respuesta: $auth"; [void](Show-Resumen "Instalación pendiente: falta registrar la deploy key" (Join-Path $script:RunnerDir 'instalacion-runner.log')); exit 2 }

# ---------- 3. Clon de solo lectura (una sola rama) ----------
Write-Paso "3. Clon de la rama $Rama"
# 04_3_anteriores/ trae archivos históricos con '?' en el nombre (p. ej. TweenMax.min.js?ver=3.9.3), inválidos en
# Windows; ni el motor ni la capa NL los usan. Se excluyen con sparse-checkout (sin tocar el repo).
$g = '"' + $Repo + '"'
if (-not (Test-Path -LiteralPath (Join-Path $Repo '.git'))) {
    $r = Invoke-Native ('git clone --no-checkout --branch ' + $Rama + ' --single-branch ' + $RepoSsh + ' "' + $Repo + '"')
    Write-Host $r.Out
    if ($r.Code -ne 0) { Write-Fail ("git clone falló (código " + $r.Code + "). Revisa la salida anterior."); exit 3 }
    Write-Ok ("Clonado (sin checkout) en " + $Repo)
} else {
    $r = Invoke-Native ('git -C ' + $g + ' remote set-url origin ' + $RepoSsh); if ($r.Code -ne 0) { Write-Fail ("Falló remote set-url: " + $r.Out); exit 3 }
    $r = Invoke-Native ('git -C ' + $g + ' fetch origin ' + $Rama); if ($r.Code -ne 0) { Write-Fail ("Falló fetch: " + $r.Out); exit 3 }
    Write-Ok "Clon existente: fetch correcto"
}
# Patrones escritos directo al archivo (sin pasar por cmd.exe, que puede mutilar las comillas y el '!')
$infoDir = Join-Path $Repo '.git\info'
if (-not (Test-Path -LiteralPath $infoDir)) { New-Item -ItemType Directory -Path $infoDir -Force | Out-Null }
Set-Content -LiteralPath (Join-Path $infoDir 'sparse-checkout') -Value @('/*', '!/04_3_anteriores/') -Encoding ASCII
$pasos = @(
    ('git -C ' + $g + ' config core.sparseCheckout true'),
    ('git -C ' + $g + ' checkout -q -f -B ' + $Rama + ' origin/' + $Rama)
)
foreach ($cmdl in $pasos) { $r = Invoke-Native $cmdl; if ($r.Code -ne 0) { Write-Fail ("Falló: " + $cmdl + " -> " + $r.Out); exit 3 } }
if (Test-Path -LiteralPath (Join-Path $Repo '04_3_anteriores')) { Write-Fail "04_3_anteriores/ sigue presente: el sparse-checkout no se aplicó"; exit 3 }
Write-Ok ("Rama " + $Rama + " en origin/" + $Rama + " (sin 04_3_anteriores/, inválido en Windows)")
$runnerEnRepo = Join-Path $Repo 'windows'
if (-not (Test-Path -LiteralPath (Join-Path $runnerEnRepo 'actualizar-nl.ps1'))) { Write-Fail "El clon no trae windows\actualizar-nl.ps1: ¿rama correcta?"; exit 3 }

# ---------- 4. Configuración ----------
Write-Paso "4. config-runner.ps1"
$tpl = Join-Path $runnerEnRepo 'config-runner.ps1.template'
$cfgOut = Join-Path $runnerEnRepo 'config-runner.ps1'
$txt = Get-Content -LiteralPath $tpl -Raw
$txt = $txt.Replace('__REPO__', $Repo).Replace('__STATA__', $Stata).Replace('__DRIVE__', $Drive).Replace('__RAMA__', $Rama).Replace('__SSHHOST__', $SshHost).Replace('__REPOSSH__', $RepoSsh)
Set-Content -LiteralPath $cfgOut -Value $txt -Encoding UTF8
Write-Ok ("Generado " + $cfgOut + " (fuera de git)")

# ---------- 5. Tarea programada ----------
if (-not $SinTarea) {
    Write-Paso "5. Tarea programada SimuladorNL-Actualizar"
    $script = Join-Path $runnerEnRepo 'actualizar-nl.ps1'
    $cmd = 'powershell.exe'
    $args = '-NoProfile -ExecutionPolicy Bypass -File "' + $script + '" -RetryOnce'
    $user = $env:USERDOMAIN + '\' + $env:USERNAME
    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Simulador Fiscal NL: actualiza y publica los endpoints NL al Drive de CoNL (runner de solo lectura). Mensual, día 5, 03:00.</Description></RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-01-05T03:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByMonth>
        <DaysOfMonth><Day>5</Day></DaysOfMonth>
        <Months><January/><February/><March/><April/><May/><June/><July/><August/><September/><October/><November/><December/></Months>
      </ScheduleByMonth>
    </CalendarTrigger>
  </Triggers>
  <Principals><Principal id="Author"><UserId>$user</UserId><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <WakeToRun>true</WakeToRun>
    <ExecutionTimeLimit>PT3H</ExecutionTimeLimit>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
  </Settings>
  <Actions Context="Author"><Exec><Command>$cmd</Command><Arguments>$args</Arguments><WorkingDirectory>$runnerEnRepo</WorkingDirectory></Exec></Actions>
</Task>
"@
    try {
        Unregister-ScheduledTask -TaskName 'SimuladorNL-Actualizar' -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName 'SimuladorNL-Actualizar' -Xml $xml -Force | Out-Null
        $info = Get-ScheduledTaskInfo -TaskName 'SimuladorNL-Actualizar'
        Write-Ok ("Tarea registrada. Próxima ejecución: " + $info.NextRunTime)
        Write-Warn "Limitación: la tarea corre con la sesión iniciada (InteractiveToken) porque G:\ (Google Drive Desktop) solo existe dentro de la sesión del usuario. Puede estar bloqueada, pero no cerrada. No guarda contraseña: cambiarla no la afecta."
    } catch { Write-Fail ("No se pudo registrar la tarea: " + $_.Exception.Message + ". Corre PowerShell como administrador o registra la tarea con windows\\README-runner.md §Tarea."); }
}

$ok = Show-Resumen "Instalación del runner" (Join-Path $script:RunnerDir 'instalacion-runner.log')
Write-Host ""
Write-Host ("Siguiente paso: powershell -ExecutionPolicy Bypass -File `"" + (Join-Path $runnerEnRepo 'verificar-runner.ps1') + "`"") -ForegroundColor Cyan
if (-not $ok) { exit 1 }
