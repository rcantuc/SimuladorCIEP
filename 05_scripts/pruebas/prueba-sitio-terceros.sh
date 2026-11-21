#!/usr/bin/env bash
# =============================================================================
# prueba-sitio-terceros.sh — scripts de terceros: versión fija, SRI y ningún «latest»
# =============================================================================
# Incidente que lo motiva (2026-11-20): el download.js de danml.com que cargaba el simulador de tabaco traía código
# malicioso. Este sitio cargaba FusionCharts desde .../fusioncharts/latest/... sin integrity: el navegador ejecutaba lo que
# el proveedor publicara ese día. Ahora la versión y los hashes viven en 04_1/terceros.php y este gate exige:
#   1. estático: ningún `/latest/` ni comentario condicional `<!--[if …]>` en el docroot fuera de plugins/, y ninguna
#      etiqueta <script src> o <link> de CSS con URL de otro origen escrita a mano en un PHP, salvo Google Tag Manager y
#      Google Fonts (FusionCharts sale solo de fusioncharts_scripts(), con su integrity);
#   2. Chrome headless (prueba-sitio-terceros.js) sobre las páginas de prueba-sitio-sellos.sh, en español y en inglés: cero
#      peticiones `/latest/`, todo script o CSS de otro origen con integrity + crossorigin="anonymous" (salvo GTM y el CSS de
#      Google Fonts), ningún host fuera de la lista, a cdn.fusioncharts.com solo lo que terceros.php fija, ninguna petición
#      fallida ni error de JS, FusionCharts en la versión fijada y dibujando;
#   3. control negativo: una copia con un hash de terceros.php alterado y otra con la versión «latest» SÍ fallan.
#   bash 05_scripts/pruebas/prueba-sitio-terceros.sh [--puerto N] [--conservar] [--sin-control]
# Sin Stata. Usa la red (el CDN de FusionCharts). Requiere php, curl, node, npm y Chrome (CHROME_PATH o ruta por defecto);
# instala puppeteer-core fijo en un directorio temporal si no está disponible.
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
FIX="$REPO_ROOT/05_scripts/pruebas/fixtures"
PUERTO=8495; CONSERVAR=false; CONTROL=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        --sin-control) CONTROL=false; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
for c in php curl node npm python3; do command -v "$c" >/dev/null || { echo "falta $c" >&2; exit 2; }; done
if [[ -z "${CHROME_PATH:-}" ]]; then
    for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
        if [[ -x "$c" ]]; then CHROME_PATH="$c"; break; elif command -v "$c" >/dev/null 2>&1; then CHROME_PATH="$(command -v "$c")"; break; fi
    done
fi
[[ -n "${CHROME_PATH:-}" ]] || { echo "no encuentro Chrome (define CHROME_PATH)" >&2; exit 2; }
export CHROME_PATH

H="$(mktemp -d -t sitio-terceros-XXXXXX)"
PHP_PID=""
detener() { if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; PHP_PID=""; fi; }
limpiar() { detener; if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi; }
trap limpiar EXIT

fallos=0

echo "## 1. estático: ningún /latest/, ningún <!--[if …]>, ningún script o CSS de terceros escrito a mano"
estatico="$(cd "$SITE" && grep -rnI --exclude-dir=plugins -E '/latest/' . ; cd "$SITE" && grep -rnI --exclude-dir=plugins -E '<!--\[if' .)"
if [[ -n "$estatico" ]]; then echo "FALLO  en el docroot (fuera de plugins/):"; printf '%s\n' "$estatico" | sed 's/^/         /' | cut -c1-200; fallos=$((fallos+1))
else echo "OK     ningún /latest/ ni <!--[if …]> en el docroot fuera de plugins/"; fi
amano="$(cd "$SITE" && grep -rnI --exclude-dir=plugins --include='*.php' -E "<script[^>]*src=['\"](https?:)?//|<link[^>]*href=['\"](https?:)?//[^'\"]*\.css" . \
    | grep -vE "src=['\"]https://www\.googletagmanager\.com/gtag/js\?id=" )"
if [[ -n "$amano" ]]; then echo "FALLO  script o CSS de terceros escrito a mano (va por terceros.php, con integrity):"; printf '%s\n' "$amano" | sed 's/^/         /' | cut -c1-200; fallos=$((fallos+1))
else echo "OK     ningún <script src> ni CSS de otro origen escrito a mano (salvo Google Tag Manager; Google Fonts no termina en .css)"; fi

if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
    ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
    NODE_PATH_EXTRA="$H/node_modules"
fi
export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"

# fijados <docroot> <salida.json>: versión y {url: sri} que terceros.php fija (la única fuente de verdad)
fijados() {
    php -r 'require $argv[1]; $b = "https://cdn.fusioncharts.com/fusioncharts/" . fusioncharts_version() . "/"; $u = array();
            foreach (fusioncharts_archivos() as $a => $s) { $u[$b . $a] = $s; }
            echo json_encode(array("version" => fusioncharts_version(), "urls" => $u), JSON_UNESCAPED_SLASHES);' "$1/terceros.php" > "$2"
}
# arma_sitio <destino>: la misma copia que prueba-sitio-sellos.sh (portada, /NTA y /entidades con fixtures reales)
arma_sitio() {
    local d="$1"
    mkdir -p "$d/users/ciepmx/SankeyNTA" "$d/users/ciepmx/NTA" "$d/users/ciepmx/NL"
    cp -R "$SITE" "$d/site"; rm -rf "$d/site/logs" "$d/site/ssl"; mkdir -p "$d/site/logs"
    cp "$FIX/output-default.txt" "$d/users/ciepmx/output.txt"
    cp "$FIX/sankeys-default/SankeySF/"* "$d/users/ciepmx/"
    for f in "$FIX"/sankey-nta-*.json; do
        b="${f##*/}"; b="${b#sankey-nta-}"
        case "$b" in v4-*) n="sankey-$b" ;; *) n="sankey-v3-$b" ;; esac
        cp "$f" "$d/users/ciepmx/SankeyNTA/$n"
    done
    cp "$FIX"/nta-*.json "$FIX"/nta-*.txt "$d/users/ciepmx/NTA/"
    cp "$FIX/entidades/NL/"*.json "$d/users/ciepmx/NL/"
    cp "$FIX/entidades/entidades.json" "$d/users/ciepmx/entidades.json"
    printf 'Commit: test\nDeployment: test-terceros\nVersion: vTEST\nDataUpdated: 2026-01-01\nReleaseUrl: https://github.com/rcantuc/SimuladorCIEP/releases/tag/vTEST\nEnighVintage: TEST\n' > "$d/site/DEPLOYED_COMMIT"
}
levanta() { # levanta <docroot>
    if curl -s -o /dev/null "http://localhost:$PUERTO/"; then echo "el puerto $PUERTO ya está ocupado; usa --puerto N" >&2; exit 2; fi
    ( cd "$1" && exec php -S "localhost:$PUERTO" > "$H/php.log" 2>&1 ) &
    PHP_PID=$!
    disown "$PHP_PID" 2>/dev/null || true
    for _ in $(seq 1 30); do curl -s -o /dev/null "http://localhost:$PUERTO/health.php" && break; sleep 0.2; done
    curl -s -o /dev/null "http://localhost:$PUERTO/health.php" || { echo "php -S no levantó en $PUERTO:"; cat "$H/php.log"; exit 2; }
}
U="http://localhost:$PUERTO"
JS="$REPO_ROOT/05_scripts/pruebas/prueba-sitio-terceros.js"

echo
echo "## 2. cada página: versión fija, SRI, ningún /latest/, ningún host fuera de la lista (Chrome headless)"
arma_sitio "$H/a"; fijados "$H/a/site" "$H/fijados-a.json"
echo "       FusionCharts fijado: $(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["version"], "+", len(d["urls"]), "archivos")' "$H/fijados-a.json")"
levanta "$H/a/site"
node "$JS" "$U" "$H/fijados-a.json" || fallos=$((fallos+1))
detener

if $CONTROL; then
    echo
    echo "## 3. control negativo"
    # (a) un hash alterado: el navegador bloquea fusioncharts.js y el gate lo nombra
    arma_sitio "$H/b"
    python3 -I - "$H/b/site/terceros.php" <<'PYEOF'
import re, sys
p = sys.argv[1]; t = open(p, encoding='utf-8').read()
m = re.search(r"'fusioncharts\.js' => 'sha384-([A-Za-z0-9+/=]+)'", t)
if not m: sys.exit('control negativo: terceros.php ya no fija fusioncharts.js con un sha384')
h = m.group(1); malo = ('A' if h[0] != 'A' else 'B') + h[1:]
open(p, 'w', encoding='utf-8').write(t.replace(h, malo))
PYEOF
    fijados "$H/b/site" "$H/fijados-b.json"
    levanta "$H/b/site"
    node "$JS" "$U" "$H/fijados-b.json" --solo /NTA/ > "$H/control-b.txt" 2>&1; rc=$?
    detener
    if [[ $rc -ne 0 ]] && grep -qi 'integrity' "$H/control-b.txt" && grep -q 'ninguna gráfica' "$H/control-b.txt"; then
        echo "OK     con un integrity alterado el gate falla (rc=$rc): el navegador bloquea fusioncharts.js y no se dibuja nada"
    else
        echo "FALLO  con un integrity alterado el gate NO falló como debía (rc=$rc):"; grep -E 'FALLO|RESUMEN' "$H/control-b.txt" | head | sed 's/^/         /'
        fallos=$((fallos+1))
    fi
    # (b) la versión «latest» (hoy sirve los mismos bytes que la fijada, así que el SRI pasa): el gate la detecta por la URL
    arma_sitio "$H/c"
    python3 -I - "$H/c/site/terceros.php" <<'PYEOF'
import re, sys
p = sys.argv[1]; t = open(p, encoding='utf-8').read()
t2, n = re.subn(r"(function fusioncharts_version\(\) \{\s*return ')[^']+(';)", r"\1latest\2", t)
if n != 1: sys.exit('control negativo: terceros.php ya no define fusioncharts_version() como se espera')
open(p, 'w', encoding='utf-8').write(t2)
PYEOF
    fijados "$H/c/site" "$H/fijados-c.json"
    levanta "$H/c/site"
    node "$JS" "$U" "$H/fijados-c.json" --solo /NTA/ > "$H/control-c.txt" 2>&1; rc=$?
    detener
    if [[ $rc -ne 0 ]] && grep -q 'petición a «latest»' "$H/control-c.txt"; then
        echo "OK     con la versión «latest» el gate falla (rc=$rc) y nombra la petición"
    else
        echo "FALLO  con la versión «latest» el gate NO falló como debía (rc=$rc):"; grep -E 'FALLO|RESUMEN' "$H/control-c.txt" | head | sed 's/^/         /'
        fallos=$((fallos+1))
    fi
fi

echo
if (( fallos == 0 )); then echo "RESULTADO: terceros OK (0 fallos)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en los scripts de terceros"
exit 1
