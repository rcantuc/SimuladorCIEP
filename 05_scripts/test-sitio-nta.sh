#!/usr/bin/env bash
# =============================================================================
# test-sitio-nta.sh — la página de método /NTA (Sankey NTA de los hogares) como gate
# =============================================================================
# Levanta el sitio (04_1_simuladorfiscal.ciep.mx/) con php -S en una copia temporal, con el JSON
# que el motor emite para este Sankey (users/<id>/SankeyNTA/sankey-grupoedad.json) en el lugar
# del escenario default (users/ciepmx/SankeyNTA/), y comprueba:
#   1. HTTP: /NTA y /NTA/ responden 200; jsonSankeyNTA.php sirve JSON válido para el corte;
#      corte fuera de la lista blanca → 400; idSession con traversal → cae al default ciepmx.
#   2. Cero números en la página: ni NTA/index.php, ni js/metodo-sankey.js, ni metodo/plantilla.php
#      traen un literal de 4+ dígitos (todo valor dibujado viene del JSON del motor).
#   3. Chrome headless (test-sitio-nta.js): el Sankey se dibuja y cada enlace que recibe el navegador
#      es idéntico, como cadena, al del JSON de origen; nodos iguales y en el mismo orden; y, si se
#      pide, la captura PNG de la página completa (la evidencia del PR).
# Origen del JSON: --json <ruta>; si no, users/ricardo/SankeyNTA/sankey-grupoedad.json del repo si
# existe; si no, el fixture 05_scripts/fixtures/sankey-nta-grupoedad.json (CI, sin corrida local).
#   bash 05_scripts/test-sitio-nta.sh [--json <ruta>] [--png <salida.png>] [--puerto N] [--conservar]
# Requiere php, curl, node, npm y Chrome (CHROME_PATH o ruta por defecto); instala puppeteer-core
# fijo en un directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
PUERTO=8495; CONSERVAR=false; PNG=""; JSON=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON="$2"; shift 2 ;;
        --png) PNG="$2"; shift 2 ;;
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
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

if [[ -z "$JSON" ]]; then
    if [[ -f "$REPO_ROOT/users/ricardo/SankeyNTA/sankey-grupoedad.json" ]]; then
        JSON="$REPO_ROOT/users/ricardo/SankeyNTA/sankey-grupoedad.json"
    else
        JSON="$REPO_ROOT/05_scripts/fixtures/sankey-nta-grupoedad.json"
    fi
fi
[[ -f "$JSON" ]] || { echo "no existe el JSON de origen: $JSON" >&2; exit 2; }
echo "# JSON de origen: $JSON"

H="$(mktemp -d -t sitio-nta-XXXXXX)"
PHP_PID=""
limpiar() {
    if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; fi
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT

if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
    ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
    NODE_PATH_EXTRA="$H/node_modules"
fi
export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"

# --- la copia: <H>/site (04_1) + <H>/users/ciepmx/SankeyNTA/ (TMP_PATH local = dirname(dirname(__FILE__))/users/)
#     y un DEPLOYED_COMMIT de prueba para que el pie pinte versión, fecha y vintage como en el VPS ---
mkdir -p "$H/users/ciepmx/SankeyNTA"
cp -R "$SITE" "$H/site"; rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs"
cp "$JSON" "$H/users/ciepmx/SankeyNTA/sankey-grupoedad.json"
printf 'Commit: test\nDeployment: test\nVersion: vTEST\nDataUpdated: 2026-01-01\nReleaseUrl: https://github.com/rcantuc/SimuladorCIEP/releases/tag/vTEST\nEnighVintage: TEST\n' > "$H/site/DEPLOYED_COMMIT"

if curl -s -o /dev/null "http://localhost:$PUERTO/"; then
    echo "el puerto $PUERTO ya está ocupado (¿otro php -S?); usa --puerto N" >&2; exit 2
fi
( cd "$H/site" && exec php -S "localhost:$PUERTO" > "$H/php.log" 2>&1 ) &
PHP_PID=$!
disown "$PHP_PID" 2>/dev/null || true
U="http://localhost:$PUERTO"
for _ in $(seq 1 30); do curl -s -o /dev/null "$U/health.php" && break; sleep 0.2; done
curl -s -o /dev/null "$U/health.php" || { echo "php -S no levantó en $PUERTO:"; cat "$H/php.log"; exit 2; }

fallos=0
chk() { # chk <codigo esperado> <descripcion> <args de curl...>
    local esp="$1" desc="$2"; shift 2
    local code
    code="$(curl -sL -o "$H/body" -w '%{http_code}' "$@")"
    local r=OK; [[ "$code" == "$esp" ]] || { r=FALLO; fallos=$((fallos+1)); }
    printf '%-6s %-52s -> %s (esperado %s) | %s\n' "$r" "$desc" "$code" "$esp" "$(head -c 90 "$H/body" | tr -d '\n')"
}
aserta() { if eval "$1"; then printf 'OK     %s\n' "$2"; else printf 'FALLO  %s\n' "$2"; fallos=$((fallos+1)); fi; }

echo "## 1. HTTP"
chk 200 "GET /NTA (la ruta)"                              "$U/NTA"
chk 200 "GET /NTA/"                                       "$U/NTA/"
aserta 'grep -q "id=\"sankey-nta\"" "$H/body"' "la página trae el contenedor #sankey-nta"
aserta 'grep -q "jsonSankeyNTA.php?corte=grupoedad" "$H/body"' "la página pide /jsonSankeyNTA.php?corte=grupoedad"
chk 200 "jsonSankeyNTA.php?corte=grupoedad"               "$U/jsonSankeyNTA.php?corte=grupoedad"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"nodes\"] and d[\"links\"]" "$H/body"' "la respuesta es JSON válido con nodes y links"
aserta 'grep -q "ciepmx/SankeyNTA/sankey-grupoedad.json" "$H/body"' "sirvió users/ciepmx/SankeyNTA/ (default)"
chk 400 "jsonSankeyNTA.php?corte=../x (fuera de lista)"   "$U/jsonSankeyNTA.php?corte=../x"
chk 400 "jsonSankeyNTA.php?corte=grupoedad%00"            "$U/jsonSankeyNTA.php?corte=grupoedad%00"
chk 200 "jsonSankeyNTA.php traversal en idSession"        "$U/jsonSankeyNTA.php?corte=grupoedad&idSession=../../../../etc/passwd%00"
aserta 'grep -q "ciepmx/SankeyNTA/sankey-grupoedad.json" "$H/body"' "el traversal cayó al default ciepmx"
chk 404 "jsonSankeyNTA.php?corte=decil (sin archivo)"     "$U/jsonSankeyNTA.php?corte=decil"
aserta 'grep -q "Fase 3b-ter" "$H/body"' "el 404 explica qué falta (SankeyNTA/ en el deploy)"

echo "## 2. cero números en la página (los valores vienen del JSON del motor)"
# (se descartan antes las entidades HTML &#NNNN; y los colores CSS #rrggbb, que no son números)
for f in NTA/index.php js/metodo-sankey.js metodo/plantilla.php css/metodo.css; do
    aserta '! sed -E "s/&#[0-9]+;//g; s/#[0-9a-fA-F]{3,8}//g" "$SITE/'"$f"'" | grep -qE "[0-9]{4,}"' "$f sin literales de 4+ dígitos"
done

echo "## 3. Chrome headless: se dibuja y los números son los del motor"
node "$REPO_ROOT/05_scripts/test-sitio-nta.js" "$U" "$JSON" ${PNG:+"$PNG"} || fallos=$((fallos+1))

echo
if (( fallos == 0 )); then echo "RESULTADO: /NTA OK (0 fallos)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en /NTA"
exit 1
