#!/usr/bin/env bash
# =============================================================================
# test-sitio-transitorios.sh — efectos TRANSITORIOS del «Calcular» (v8.12.3)
# =============================================================================
# Lección de v8.12.2: un parpadeo de un segundo (y el refresco de los Sankeys) se perdió sin que
# el gate visual lo notara — comparaba capturas del estado FINAL. Este test muestrea el DOM cada
# ~100 ms con Chrome headless (puppeteer-core) contra el sitio servido por php -S con Stata falso:
# parpadeo blink-1 de las tablas (adquirir/perder, ~1.5 s), refresco de los 5 Sankeys, reinicio de
# flags, cronómetro (valor por flujo, «Finalizando…») y 429 sin spinner eterno.
#   bash 05_scripts/test-sitio-transitorios.sh [--sitio <dir 04_1>] [--puerto N] [--conservar]
# --sitio apunta a otra copia del sitio (p. ej. `git archive c921bf6` para probarlo en ROJO).
# Requiere Chrome (CHROME_PATH o ruta por defecto) y node; instala puppeteer-core@25.13.0 en un
# directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
PUERTO=8481; CONSERVAR=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sitio) SITE="$2"; shift 2 ;;
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
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

H="$(mktemp -d -t sitio-trans-XXXXXX)"
PIDS=()
limpiar() {
    for p in ${PIDS[@]+"${PIDS[@]}"}; do kill "$p" 2>/dev/null; wait "$p" 2>/dev/null; done
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT

# puppeteer-core: el del repo/entorno si existe; si no, instalación temporal con versión fija
if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
    ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
    NODE_PATH_EXTRA="$H/node_modules"
fi
export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"

# --- Stata falso: duerme $H/fake-sleep y deja el output.txt real del escenario default + 5 sankeys ---
cp "$REPO_ROOT/05_scripts/fixtures/output-default.txt" "$H/canned-output.txt"
for k in decil escol grupoedad rural sexo; do
    printf '{"chart":{"caption":" "},\nnodes:[{label:"I"},{label:"Imp al trabajo"}],\nlinks:[{to:"Imp al trabajo",value:"49197860719.77805",from:"I"}]};\n' > "$H/canned-sankey-$k.json"
done
cat > "$H/fake-stata" <<'FEOF'
#!/usr/bin/env bash
H="$FAKE_H"; ID="$(basename "$PWD")"
sleep "$(cat "$H/fake-sleep" 2>/dev/null || echo 2)"
cp "$H/canned-output.txt" ./output.txt
for k in decil escol grupoedad rural sexo; do cp "$H/canned-sankey-$k.json" "./sankey-$k.json"; done
echo 0 > "$ID.done"
FEOF
chmod +x "$H/fake-stata"; echo 4 > "$H/fake-sleep"

# --- dos copias del sitio: normal y con el freno de simultáneos en 0 (todo es 429) ---
montar() { # montar <nombre> <puerto> [sed de config.php]
    local R="$H/$1"; mkdir -p "$R/users/ciepmx"
    cp -R "$SITE" "$R/site"; rm -rf "$R/site/logs" "$R/site/ssl"; mkdir -p "$R/site/logs"
    cp "$REPO_ROOT/01_modulos/Web.Stata.do" "$R/Web.Stata.do"
    cp "$H/canned-output.txt" "$R/users/ciepmx/output.txt"; for k in decil escol grupoedad rural sexo; do cp "$H/canned-sankey-$k.json" "$R/users/ciepmx/sankey-$k.json"; done
    python3 - "$R/site/config.php" "$H/fake-stata" "${3:-}" <<'PYEOF'
import re, sys
p, fake, extra = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(p, encoding='utf-8', newline='').read()
t2 = re.sub(r"/Applications/StataNow/StataSE\.app/Contents/MacOS/stata-se", fake, t)
if t2 == t: sys.exit("no se encontró la ruta de StataNow en config.php (cambió la detección de Stata)")
if extra:
    t3 = re.sub(r"define\('MAX_STATA_SIMULTANEOS', 3\)", "define('MAX_STATA_SIMULTANEOS', 0)", t2)
    if t3 == t2: sys.exit("no se encontró MAX_STATA_SIMULTANEOS en config.php")
    t2 = t3
open(p, 'w', encoding='utf-8', newline='').write(t2)
PYEOF
    ( cd "$R/site" && exec env FAKE_H="$H" PHP_CLI_SERVER_WORKERS=4 php -S "localhost:$2" > "$R/php.log" 2>&1 ) &
    PIDS+=("$!"); disown "$!" 2>/dev/null || true
    for _ in $(seq 1 40); do curl -s -o /dev/null "http://localhost:$2/health.php" && return 0; sleep 0.2; done
    echo "php -S no levantó en $2:"; cat "$R/php.log"; exit 2
}
montar normal "$PUERTO"
montar freno "$((PUERTO + 1))" 429

node "$REPO_ROOT/05_scripts/test-sitio-transitorios.js" "http://localhost:$PUERTO" "http://localhost:$((PUERTO + 1))"
