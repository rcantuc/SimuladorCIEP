<#
.SYNOPSIS
  actualizar-nl.ps1 — port Windows de actualizar-nl.sh: actualiza el clon, corre los drivers NL en Stata batch y publica al Drive de CoNL.
.DESCRIPTION
  Runner de SOLO LECTURA: git fetch + reset --hard a origin/<rama> (aborta si el working tree está sucio).
  Corre PoblacionNL.do + PIBDeflactorNL.do (nl-assets\actualizar-nl.do) con Stata /e desde la raíz del repo (carga profile.do).
  FALLO SEGURO: cualquier r(#) de Stata, compuerta fallida, descarga inválida, producto faltante o HTML sin datos
  válidos (compuerta de publicación: sin marcas de inyección, con componente y JSON parseable) → NO toca el Drive,
  restaura los últimos productos buenos y registra el motivo en windows\bitacora-runner.log. Nunca publica a medias.
  Éxito: robocopy /E (sin borrado) sobre <Drive>\nodos, copia de los HTML a la raíz, bitácora y latido ultimo-exito.txt (local + Drive).
.PARAMETER RetryOnce  Si el fallo parece de INEGI (descarga), espera 30 min y reintenta una vez.
.PARAMETER Offline    Reutiliza la caché INEGI (desarrollo/diagnóstico).
.PARAMETER Manual     Modo manual (verificación): misma lógica, salida más verbosa.
#>
param([switch]$RetryOnce, [switch]$Offline, [switch]$Manual)
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'runner-common.ps1')
$Bitacora = Join-Path $script:RunnerDir 'bitacora-runner.log'
$Latido   = Join-Path $script:RunnerDir 'ultimo-exito.txt'

function Abortar { param([string]$Motivo, [string]$Bak, [string]$Nodos)
    Write-Bitacora $Bitacora ("ABORTA: " + $Motivo)
    Write-Host ("ABORTA: " + $Motivo) -ForegroundColor Red
    if ($Bak -and (Test-Path -LiteralPath $Bak)) {
        Get-ChildItem -LiteralPath $Nodos -Include *.json,*.html -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Copy-Item -Path (Join-Path $Bak '*') -Destination $Nodos -Force -ErrorAction SilentlyContinue
        Write-Bitacora $Bitacora ("Restaurados los últimos JSON/HTML buenos en " + $Nodos + " (el Drive no se tocó).")
    }
    exit 1
}

try { $C = Get-RunnerConfig } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
$Repo = $C.Repo; $Stata = $C.Stata; $Drive = $C.Drive; $Rama = $C.Rama
Write-Bitacora $Bitacora ("== actualizar-nl inicio (RetryOnce=" + [bool]$RetryOnce + ", Offline=" + [bool]$Offline + ", Manual=" + [bool]$Manual + ") ==")
foreach ($p in @($Repo, $Stata)) { if (-not (Test-Path -LiteralPath $p)) { Abortar ("No existe " + $p + " (revisa config-runner.ps1 o corre instalar-runner.ps1)") $null $null } }

# ---------- 1. Clon de solo lectura: limpio y en la rama ----------
Push-Location $Repo
try {
    $sucio = (& git status --porcelain)
    if ($sucio) { Pop-Location; Abortar ("El working tree del runner está SUCIO (alguien editó donde no debía):`r`n" + ($sucio -join "`r`n") + "`r`nEl runner nunca desarrolla. Descarta los cambios (git checkout -- . / git clean -fd) o vuelve a clonar.") $null $null }
    $r = Invoke-Native ('git fetch origin ' + $Rama)
    if ($r.Code -ne 0) { Pop-Location; Abortar ("git fetch falló (¿sin red o deploy key revocada?): " + $r.Out) $null $null }
    $r = Invoke-Native ('git checkout -q ' + $Rama)
    if ($r.Code -ne 0) { Pop-Location; Abortar ("git checkout falló: " + $r.Out) $null $null }
    $r = Invoke-Native ('git reset -q --hard origin/' + $Rama)
    if ($r.Code -ne 0) { Pop-Location; Abortar ("git reset --hard falló: " + $r.Out) $null $null }
    $head = (& git rev-parse --short HEAD)
    Write-Bitacora $Bitacora ("Clon en origin/" + $Rama + " @ " + $head)
} finally { Pop-Location }

# ---------- 2. Respaldo de los últimos productos buenos ----------
$Nodos = Join-Path $Repo ('users\' + $env:USERNAME + '\nodos')
if (-not (Test-Path -LiteralPath $Nodos)) { New-Item -ItemType Directory -Path $Nodos -Force | Out-Null }
$Bak = Join-Path $env:TEMP ('nl-nodos-bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $Bak -Force | Out-Null
Get-ChildItem -LiteralPath $Nodos -Include *.json,*.html -File -Recurse -ErrorAction SilentlyContinue | Copy-Item -Destination $Bak -Force
Write-Bitacora $Bitacora ("Respaldo de productos previos en " + $Bak)

# ---------- 3. Stata en batch (con reintento opcional si falla INEGI) ----------
$wrapDir = Join-Path $Repo ('users\' + $env:USERNAME)
$wrap = Join-Path $wrapDir 'actualizar-nl-stata.do'
$lineas = @()
if ($Offline) { $lineas += 'global nlbie_offline 1' }
$lineas += ('do "' + (Join-Path $Repo '01_modulos\nl-assets\actualizar-nl.do') + '"')
Set-Content -LiteralPath $wrap -Value ($lineas -join "`r`n") -Encoding ASCII

$intento = 0
while ($true) {
    $intento++
    Write-Host ("Stata batch (intento " + $intento + "): " + $Stata) -ForegroundColor Cyan
    try { $log = Invoke-StataBatch -Stata $Stata -DoFile $wrap -WorkDir $Repo -TimeoutMin 90 } catch { Abortar $_.Exception.Message $Bak $Nodos }
    $err = Test-StataLogError $log
    $faltan = @()
    foreach ($m in 'PoblacionNL: listo', 'PIBDeflactorNL: listo', 'FederacionNL: listo', 'LOS TRES DRIVERS TERMINARON') { if (-not (Select-String -LiteralPath $log -Pattern ([regex]::Escape($m)) -Quiet)) { $faltan += $m } }
    if (-not $err -and $faltan.Count -eq 0) { break }
    $ctx = ''
    if ($err) { $ctx = ((Get-Content -LiteralPath $log)[([Math]::Max(0, $err.LineNumber - 6))..($err.LineNumber - 1)] -join ' | ') }
    $esINEGI = ($ctx -match 'nl-bie|nl_bie|INPC|AccesoBIE|inegi|BIE:|RuntimeError|urlopen|timed out')
    $motivo = "Stata no terminó bien: " + $(if ($err) { $err.Line } else { 'sin error r(), faltan marcadores: ' + ($faltan -join ', ') }) + " | contexto: " + $ctx + " | log: " + $log
    if ($RetryOnce -and $esINEGI -and $intento -eq 1) {
        Write-Bitacora $Bitacora ("Fallo aparente de INEGI; reintento único en 30 min. " + $motivo)
        Write-Host "Fallo aparente de INEGI: reintento en 30 minutos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1800
        continue
    }
    Abortar $motivo $Bak $Nodos
}
foreach ($f in 'poblacion-nl.json','poblacion-nl.html','actividad-nl.json','actividad-nl.html','federacion-nl.json','federacion-nl.html') {
    $pf = Join-Path $Nodos $f
    if (-not (Test-Path -LiteralPath $pf) -or (Get-Item -LiteralPath $pf).Length -eq 0) { Abortar ("Falta o está vacío el producto " + $pf) $Bak $Nodos }
}
Copy-Item -LiteralPath $log -Destination (Join-Path $Nodos 'actualizar-nl-stata.log') -Force
Write-Bitacora $Bitacora "Stata OK: compuertas en verde, 6 productos generados"

# ---------- 3b. Compuerta de publicación (NL-0.3.1): el HTML debe ser el endpoint generado, no la plantilla ----------
foreach ($h in 'poblacion-nl.html','actividad-nl.html','federacion-nl.html') {
    $ph = Join-Path $Nodos $h
    $txt = Get-Content -LiteralPath $ph -Raw -Encoding UTF8
    if ($txt -match '/\*__NL[A-Z_]*__\*/') { Abortar ("COMPUERTA: " + $h + " conserva una marca de inyección sin reemplazar (es la plantilla, no el endpoint)") $Bak $Nodos }
    if ($txt -match '"inventario_habilitado": *true') { Abortar ("COMPUERTA: " + $h + " trae el modo inventario del render habilitado (inventario_habilitado = true: BORRADOR con anclas sin fijar, no publicable)") $Bak $Nodos }
    if ($txt -notmatch 'window\.NLDatos = \(function') { Abortar ("COMPUERTA: " + $h + " no trae el componente nl-datos.js") $Bak $Nodos }
    $m = [regex]::Match($txt, '(?s)<script type="application/json" id="nl-data">(.*?)</script>')
    if (-not $m.Success) { Abortar ("COMPUERTA: " + $h + " sin bloque <script type=application/json id=nl-data>") $Bak $Nodos }
    try { $j = $m.Groups[1].Value | ConvertFrom-Json } catch { Abortar ("COMPUERTA: " + $h + " con JSON inválido en nl-data: " + $_.Exception.Message) $Bak $Nodos }
    if (-not $j.procedencia -or -not $j.procedencia.generado_en) { Abortar ("COMPUERTA: " + $h + " con JSON sin procedencia.generado_en") $Bak $Nodos }
    Write-Bitacora $Bitacora ("Compuerta de publicación OK: " + $h + " (" + $m.Groups[1].Value.Length + " caracteres de JSON, corrida " + $j.procedencia.generado_en + ", capa " + $j.procedencia.version_capa_nl + ")")
}

# ---------- 4. Publicación al Drive (copia SIN borrado sobre nodos\; NL-0.4.0) ----------
# Antes era robocopy /MIR: habría borrado del Drive los productos que solo produce el Mac
# (statajson_entidad-nl.json, entidad-nl.log). El Mac sí espeja con --delete porque produce el conjunto completo.
$DrivePadre = Split-Path -Parent $Drive
if (-not (Test-Path -LiteralPath $DrivePadre)) { Abortar ("Drive de CoNL no montado (" + $DrivePadre + "); no se publica") $Bak $Nodos }
if (-not (Test-Path -LiteralPath $Drive)) { New-Item -ItemType Directory -Path $Drive -Force | Out-Null }
$DriveNodos = Join-Path $Drive 'nodos'
$r = Invoke-Native ('robocopy "' + $Nodos + '" "' + $DriveNodos + '" /E /R:2 /W:5 /NFL /NDL /NJH /NJS /NP')
$rc = $r.Code
if ($rc -ge 8) { Abortar ("robocopy /E a " + $DriveNodos + " devolvió " + $rc) $Bak $Nodos }
foreach ($h in 'poblacion-nl.html','actividad-nl.html','federacion-nl.html') { Copy-Item -LiteralPath (Join-Path $Nodos $h) -Destination (Join-Path $Drive $h) -Force }
foreach ($h in 'poblacion-nl.html','actividad-nl.html','federacion-nl.html') { if (-not (Test-Path -LiteralPath (Join-Path $Drive $h))) { Abortar ("No quedó " + $h + " en el Drive") $Bak $Nodos } }

# ---------- 5. Bitácora y latido ----------
$pob = Get-Content -LiteralPath (Join-Path $Nodos 'poblacion-nl.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$act = Get-Content -LiteralPath (Join-Path $Nodos 'actividad-nl.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$ser = @{}; foreach ($s in $act.procedencia.series) { $ser[$s.variable] = $s }
function U([string]$k) { $s = $ser[$k]; $t = $s.ultimo; if ($s.sello_ultimo) { $t += ' ' + $s.sello_ultimo }; return $t }
$shas = @()
$fed = Get-Content -LiteralPath (Join-Path $Nodos 'federacion-nl.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$fedF = @{}; foreach ($x in $fed.procedencia.fuentes) { $fedF[$x.id] = $x }
foreach ($f in @((Join-Path $Drive 'poblacion-nl.html'), (Join-Path $Drive 'actividad-nl.html'), (Join-Path $Drive 'federacion-nl.html'), (Join-Path $DriveNodos 'poblacion-nl.json'), (Join-Path $DriveNodos 'actividad-nl.json'), (Join-Path $DriveNodos 'federacion-nl.json'))) {
    $shas += ((Split-Path -Leaf $f) + '=' + (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.Substring(0, 12).ToLower())
}
$linea = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') + ' runner=' + $env:COMPUTERNAME + ' capa=' + $pob.procedencia.version_capa_nl + ' motor=' + $pob.procedencia.version_motor + ' git=' + $head +
    ' | pob: ' + $pob.procedencia.cobertura_estatal + '; mun ' + ($pob.procedencia.cobertura_municipal -split ',')[0] + '; corrida ' + $pob.procedencia.generado_en +
    ' | act: PIBE hasta ' + (U 'pibeNnl') + '; ITAEE ' + (U 'itaeenl') + '; INPC NL ' + (U 'inpcnl') + '; INPC nac ' + (U 'inpcnac') + '; consulta INEGI ' + $ser['pibeNnl'].consulta + '; corrida ' + $act.procedencia.generado_en +
    ' | fed: modo ' + $fed.procedencia.modo + '; EOFP hasta ' + $fedF['eopf_transferencias'].periodo_final + '; ref ' + $fed.anio_referencia + '; sello ' + $fedF['sello'].generado_en + '; corrida ' + $fed.procedencia.generado_en +
    ' | sha256(12): ' + ($shas -join ' ')
Add-Content -LiteralPath $Bitacora -Value $linea -Encoding UTF8
$latidoTxt = @(
    'Simulador Fiscal NL — runner Windows: última publicación exitosa',
    ('fecha: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') + '  equipo: ' + $env:COMPUTERNAME + '  usuario: ' + $env:USERNAME),
    ('capa NL: ' + $pob.procedencia.version_capa_nl + '  motor: ' + $pob.procedencia.version_motor + '  git: ' + $head + '  rama: ' + $Rama),
    ('población: ' + $pob.procedencia.cobertura_estatal + ' | municipios ' + $pob.procedencia.cobertura_municipal + ' | corrida ' + $pob.procedencia.generado_en),
    ('actividad: PIBE hasta ' + (U 'pibeNnl') + ' | ITAEE ' + (U 'itaeenl') + ' | INPC NL ' + (U 'inpcnl') + ' | INPC nacional ' + (U 'inpcnac') + ' | consulta INEGI ' + $ser['pibeNnl'].consulta + ' | corrida ' + $act.procedencia.generado_en),
    ('sha256(12): ' + ($shas -join '  ')),
    ('próximo ciclo: tarea programada SimuladorNL-Actualizar (mensual, día 5, 03:00; si se omitió, en cuanto haya sesión)')
)
Set-Content -LiteralPath $Latido -Value ($latidoTxt -join "`r`n") -Encoding UTF8
Copy-Item -LiteralPath $Latido -Destination (Join-Path $Drive 'ultimo-exito.txt') -Force
Remove-Item -LiteralPath $Bak -Recurse -Force -ErrorAction SilentlyContinue
Write-Bitacora $Bitacora ("Publicado: " + $linea)
Write-Bitacora $Bitacora "== actualizar-nl fin OK =="
Write-Host "Publicado al Drive de CoNL y registrado en la bitácora." -ForegroundColor Green
if ($Manual) { Write-Host $linea }
exit 0
