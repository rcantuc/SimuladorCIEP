#!/usr/bin/env bash
# =============================================================================
# prueba-sitio-sellos.sh — todo recurso propio de datos, CSS y JavaScript lleva sello de versión
# =============================================================================
# Un recurso sin sello (`?v=…`) lo guarda el navegador o el proxy con el contenido de la visita anterior: tras un deploy, la
# página nueva puede armarse con un CSS, un JS o un JSON viejos. Este gate abre con Chrome headless la portada, /metodo
# (índice, cap0 y un capítulo), /NTA, /entidades y una entidad, en español y en inglés (prueba-sitio-sellos.js), anota cada
# petición propia y exige:
#   1. cada GET propio de datos, CSS o JavaScript lleva `?v=`;
#   2. el sello corresponde: archivo estático del docroot → sha1 de su contenido (10 hex); dato servido por un PHP →
#      sha1 de DEPLOYED_COMMIT (10 hex, el build). Un sello a mano («?v=17») no pasa.
# Quedan fuera plugins/ (terceros), las peticiones que no son GET (los POST de la portada: no se cachean), imágenes, fuentes e íconos.
#   3. control negativo: en una copia del sitio con un CSS y un JSON propios sin sello, el gate SÍ falla y los nombra.
#   bash 05_scripts/pruebas/prueba-sitio-sellos.sh [--puerto N] [--conservar] [--json salida.json] [--sin-control]
# Sin Stata. Requiere php, curl, node, npm y Chrome (CHROME_PATH o ruta por defecto); instala puppeteer-core fijo en un
# directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
FIX="$REPO_ROOT/05_scripts/pruebas/fixtures"
PUERTO=8493; CONSERVAR=false; JSON=""; CONTROL=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        --json) JSON="$2"; shift 2 ;;
        --sin-control) CONTROL=false; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
for c in php curl node npm; do command -v "$c" >/dev/null || { echo "falta $c" >&2; exit 2; }; done
if [[ -z "${CHROME_PATH:-}" ]]; then
    for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
        if [[ -x "$c" ]]; then CHROME_PATH="$c"; break; elif command -v "$c" >/dev/null 2>&1; then CHROME_PATH="$(command -v "$c")"; break; fi
    done
fi
[[ -n "${CHROME_PATH:-}" ]] || { echo "no encuentro Chrome (define CHROME_PATH)" >&2; exit 2; }
export CHROME_PATH

H="$(mktemp -d -t sitio-sellos-XXXXXX)"
PHP_PID=""
detener() { if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; PHP_PID=""; fi; }
limpiar() { detener; if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi; }
trap limpiar EXIT

if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
    ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
    NODE_PATH_EXTRA="$H/node_modules"
fi
export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"

# arma_sitio <destino>: copia del sitio + users/ciepmx con los fixtures reales (portada, /NTA, /entidades) + DEPLOYED_COMMIT de prueba
arma_sitio() {
    local d="$1"
    mkdir -p "$d/users/ciepmx/SankeyNTA" "$d/users/ciepmx/NTA" "$d/users/ciepmx/NL"
    cp -R "$SITE" "$d/site"; rm -rf "$d/site/logs" "$d/site/ssl"; mkdir -p "$d/site/logs"
    # (los archivos se copian por patrón, sin nombrarlos: metodo.py lista como «check» de cada salida a todo script que
    # nombre su archivo, y este gate no protege el contenido de ninguna salida, solo sus sellos de versión)
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
    printf 'Commit: test\nDeployment: test-sellos\nVersion: vTEST\nDataUpdated: 2026-01-01\nReleaseUrl: https://github.com/rcantuc/SimuladorCIEP/releases/tag/vTEST\nEnighVintage: TEST\n' > "$d/site/DEPLOYED_COMMIT"
}
levanta() { # levanta <docroot>
    if curl -s -o /dev/null "http://localhost:$PUERTO/"; then echo "el puerto $PUERTO ya está ocupado; usa --puerto N" >&2; exit 2; fi
    ( cd "$1" && exec php -S "localhost:$PUERTO" > "$H/php.log" 2>&1 ) &
    PHP_PID=$!
    disown "$PHP_PID" 2>/dev/null || true
    for _ in $(seq 1 30); do curl -s -o /dev/null "http://localhost:$PUERTO/health.php" && break; sleep 0.2; done
    curl -s -o /dev/null "http://localhost:$PUERTO/health.php" || { echo "php -S no levantó en $PUERTO:"; cat "$H/php.log"; exit 2; }
}

fallos=0
U="http://localhost:$PUERTO"

echo "## 1. los recursos propios de datos, CSS y JS de cada página llevan sello (Chrome headless)"
arma_sitio "$H/a"
BUILD="$(python3 -I -c 'import hashlib,sys; print(hashlib.sha1(open(sys.argv[1],"rb").read()).hexdigest()[:10])' "$H/a/site/DEPLOYED_COMMIT")"
levanta "$H/a/site"
ARGS_JSON=(); [[ -n "$JSON" ]] && ARGS_JSON=(--json "$JSON")
node "$REPO_ROOT/05_scripts/pruebas/prueba-sitio-sellos.js" "$U" "$H/a/site" "$BUILD" ${ARGS_JSON[@]+"${ARGS_JSON[@]}"} || fallos=$((fallos+1))
detener

if $CONTROL; then
    echo
    echo "## 2. control negativo: con un CSS y un JSON propios sin sello el gate falla y los nombra"
    arma_sitio "$H/b"
    python3 -I - "$H/b/site/plantilla-metodo.php" <<'PYEOF'
import sys
p = sys.argv[1]
t = open(p, encoding='utf-8', newline='').read()
inyeccion = '\t<link href="/css/animations.css" rel="stylesheet">\n\t<script>fetch("/metodo/metodo-en.json");</script>\n</head>'
if t.count('</head>') != 1:
    sys.exit('control negativo: plantilla-metodo.php ya no trae un único </head>')
open(p, 'w', encoding='utf-8', newline='').write(t.replace('</head>', inyeccion))
PYEOF
    levanta "$H/b/site"
    node "$REPO_ROOT/05_scripts/pruebas/prueba-sitio-sellos.js" "$U" "$H/b/site" "$BUILD" --solo /metodo/PEF > "$H/control.txt" 2>&1; rc=$?
    detener
    if [[ $rc -ne 0 ]] && grep -q 'SIN SELLO' "$H/control.txt" && grep -q '/css/animations.css' "$H/control.txt" && grep -q '/metodo/metodo-en.json' "$H/control.txt"; then
        echo "OK     el control negativo falla (rc=$rc) y nombra /css/animations.css y /metodo/metodo-en.json"
    else
        echo "FALLO  el control negativo NO falló como debía (rc=$rc):"; sed 's/^/         /' "$H/control.txt" | grep -E 'FALLO|RESUMEN' | head
        fallos=$((fallos+1))
    fi
fi

echo
if (( fallos == 0 )); then echo "RESULTADO: sellos de versión OK (0 fallos)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en los sellos de versión"
exit 1
