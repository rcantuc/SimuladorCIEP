#!/usr/bin/env bash
# =============================================================================
# test-sitio-metodo.sh — /metodo (índice, capítulo 0 y un capítulo por módulo) como gate (8.18)
# =============================================================================
# El método publicado es SIEMPRE el del repo: 05_scripts/metodo.py lo genera (metodo.json + páginas) leyendo headers,
# SIM.do §0.8, memos CUAD, scn-celdas.md, manifest y fixtures; aquí se comprueba, sin Stata:
#   0. generado == commiteado: `metodo.py --check` regenera a un temporal y exige bytes idénticos a
#      04_1_simuladorfiscal.ciep.mx/metodo/ (metodo.json, index.php, cap0/index.php, <Modulo>/index.php; ninguna página sobrante).
#   1. php -l de las páginas generadas y de plantilla-metodo.php.
#   2. HTTP (php -S sobre una copia del sitio): /metodo y /metodo/ responden 200; /metodo/metodo.json es JSON válido con tantos
#      capítulos como carpetas <Modulo>/; cada /metodo/<Modulo>/ y /metodo/cap0/ responde 200 con su cascarón.
#   3. Cero números: ni las páginas generadas, ni js/metodo-capitulo.js, ni plantilla-metodo.php, ni css/metodo.css traen un
#      literal de 4+ dígitos (toda cifra y toda frase viene de metodo.json).
#   4. Chrome headless (test-sitio-metodo.js): cada página carga y marca data-metodo-estado="ok"; en el índice cada <span data-metodo>
#      se llenó y hay una fila por capítulo con su sello; en cada capítulo están las diez secciones de la plantilla, las no vacías
#      traen tabla o párrafo y las vacías su FLAG; el capítulo 0 trae sus secciones y la bibliografía con la columna «Otro país»
#      vacía; cero errores de JS; y todo enlace interno (href que empieza con «/») de esas páginas responde 200.
#   bash 05_scripts/test-sitio-metodo.sh [--puerto N] [--conservar] [--sin-chrome]
# Requiere php, curl, python3 y, salvo --sin-chrome, node, npm y Chrome (CHROME_PATH o ruta por defecto); instala
# puppeteer-core fijo en un directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
PUERTO=8498; CONSERVAR=false; SIN_CHROME=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        --sin-chrome) SIN_CHROME=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
for c in php curl python3; do command -v "$c" >/dev/null || { echo "falta $c" >&2; exit 2; }; done
if ! $SIN_CHROME; then
    for c in node npm; do command -v "$c" >/dev/null || { echo "falta $c" >&2; exit 2; }; done
    if [[ -z "${CHROME_PATH:-}" ]]; then
        for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
            if [[ -x "$c" ]]; then CHROME_PATH="$c"; break; elif command -v "$c" >/dev/null 2>&1; then CHROME_PATH="$(command -v "$c")"; break; fi
        done
    fi
    [[ -n "${CHROME_PATH:-}" ]] || { echo "no encuentro Chrome (define CHROME_PATH o usa --sin-chrome)" >&2; exit 2; }
    export CHROME_PATH
fi

fallos=0
aserta() { if eval "$1"; then printf 'OK     %s\n' "$2"; else printf 'FALLO  %s\n' "$2"; fallos=$((fallos+1)); fi; }

echo "## 0. generado == commiteado (metodo.py --check)"
if python3 -I "$REPO_ROOT/05_scripts/metodo.py" --check; then echo "OK     metodo.json y las páginas son lo que el repo genera"; else echo "FALLO  lo commiteado difiere de lo generado (regenera con python3 -I 05_scripts/metodo.py)"; fallos=$((fallos+1)); fi

echo "## 1. php -l"
n_php=0; f_php=0
for f in "$SITE"/metodo/index.php "$SITE"/metodo/*/index.php "$SITE/plantilla-metodo.php"; do
    n_php=$((n_php+1)); php -l "$f" >/dev/null 2>&1 || { f_php=$((f_php+1)); echo "       sintaxis: $f"; }
done
aserta '[[ $f_php -eq 0 ]]' "$n_php PHP parsean ($f_php con errores)"

H="$(mktemp -d -t sitio-metodo-XXXXXX)"
PHP_PID=""
limpiar() {
    if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; fi
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT
cp -R "$SITE" "$H/site"; rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs" "$H/users/ciepmx"
printf 'Commit: test\nDeployment: test\nVersion: vTEST\nDataUpdated: 2026-01-01\nReleaseUrl: https://github.com/rcantuc/SimuladorCIEP/releases/tag/vTEST\nEnighVintage: TEST\n' > "$H/site/DEPLOYED_COMMIT"
if curl -s -o /dev/null "http://localhost:$PUERTO/"; then echo "el puerto $PUERTO ya está ocupado; usa --puerto N" >&2; exit 2; fi
( cd "$H/site" && exec php -S "localhost:$PUERTO" > "$H/php.log" 2>&1 ) &
PHP_PID=$!
disown "$PHP_PID" 2>/dev/null || true
U="http://localhost:$PUERTO"
for _ in $(seq 1 30); do curl -s -o /dev/null "$U/health.php" && break; sleep 0.2; done
curl -s -o /dev/null "$U/health.php" || { echo "php -S no levantó en $PUERTO:"; cat "$H/php.log"; exit 2; }

chk() { # chk <codigo esperado> <descripcion> <url>
    local esp="$1" desc="$2" url="$3" code
    code="$(curl -sL -o "$H/body" -w '%{http_code}' "$url")"
    local r=OK; [[ "$code" == "$esp" ]] || { r=FALLO; fallos=$((fallos+1)); }
    printf '%-6s %-58s -> %s (esperado %s)\n' "$r" "$desc" "$code" "$esp"
}

echo "## 2. HTTP"
chk 200 "GET /metodo (la ruta)" "$U/metodo"
chk 200 "GET /metodo/" "$U/metodo/"
aserta 'grep -q "data-metodo-pagina=\"indice\"" "$H/body" && grep -q "/js/metodo-capitulo.js" "$H/body" && grep -q "/metodo/metodo.json" "$H/body"' "el índice es el cascarón: pide /metodo/metodo.json y carga js/metodo-capitulo.js"
chk 200 "GET /metodo/metodo.json" "$U/metodo/metodo.json"
cp "$H/body" "$H/metodo.json"
N_CAP="$(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1], encoding="utf-8")); print(len(d["capitulos"]))' "$H/metodo.json" 2>/dev/null || echo 0)"
N_DIR="$(find "$SITE/metodo" -mindepth 1 -maxdepth 1 -type d ! -name cap0 | wc -l | tr -d ' ')"
aserta '[[ "$N_CAP" -gt 0 && "$N_CAP" == "$N_DIR" ]]' "metodo.json es JSON válido con $N_CAP capítulos = $N_DIR carpetas <Modulo>/ (+ cap0)"
aserta 'python3 -I -c "
import json,sys
d=json.load(open(sys.argv[1], encoding=\"utf-8\"))
assert d[\"version\"] and d[\"baseline\"] and len(d[\"secciones\"])==10 and d[\"cap0\"][\"secciones\"] and d[\"bibliografia\"][\"filas\"]
orden=[c[\"orden_en_SIM\"] for c in d[\"capitulos\"]]; assert orden==sorted(orden)==list(range(1,len(orden)+1))
assert all(set(c[\"secciones\"])=={str(n) for n in range(1,11)} for c in d[\"capitulos\"])
assert all(c[\"sello\"] in (\"verde\",\"amarillo\",\"rojo\",\"sin sello\") for c in d[\"capitulos\"])
assert all(c[\"sello\"]==\"rojo\" for c in d[\"capitulos\"] if c[\"flags\"])
" "$H/metodo.json"' "metodo.json: version, baseline, 10 secciones de la plantilla, capítulos en el orden de SIM.do con sus 10 secciones, sellos válidos (rojo si hay FLAG), cap0 y bibliografía"
chk 200 "GET /metodo/cap0/" "$U/metodo/cap0/"
aserta 'grep -q "data-metodo-pagina=\"cap0\"" "$H/body"' "cap0 es el cascarón del capítulo 0"
for s in $(python3 -I -c 'import json,sys; print(" ".join(c["modulo"] for c in json.load(open(sys.argv[1], encoding="utf-8"))["capitulos"]))' "$H/metodo.json"); do
    chk 200 "GET /metodo/$s/" "$U/metodo/$s/"
    aserta 'grep -q "data-metodo-capitulo=\"'"$s"'\"" "$H/body"' "  cascarón del capítulo $s"
done

echo "## 3. cero números en las páginas (toda cifra y toda frase viene de metodo.json)"
# (se descartan antes las entidades HTML &#NNNN; y los colores CSS #rrggbb, que no son números)
for f in metodo/index.php metodo/cap0/index.php js/metodo-capitulo.js plantilla-metodo.php css/metodo.css; do
    aserta '! sed -E "s/&#[0-9]+;//g; s/#[0-9a-fA-F]{3,8}//g" "$SITE/'"$f"'" | grep -qE "[0-9]{4,}"' "$f sin literales de 4+ dígitos"
done
n_lit=0
for f in "$SITE"/metodo/*/index.php; do
    sed -E 's/&#[0-9]+;//g; s/#[0-9a-fA-F]{3,8}//g' "$f" | grep -qE "[0-9]{4,}" && { n_lit=$((n_lit+1)); echo "       literal en $f"; }
done
aserta '[[ $n_lit -eq 0 ]]' "las $N_CAP páginas de capítulo sin literales de 4+ dígitos"

if $SIN_CHROME; then
    echo "## 4. Chrome headless: SALTADO (--sin-chrome)"
else
    echo "## 4. Chrome headless: cada página pinta desde metodo.json, sin errores, y los enlaces internos resuelven"
    if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
        ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
        NODE_PATH_EXTRA="$H/node_modules"
    fi
    export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"
    node "$REPO_ROOT/05_scripts/test-sitio-metodo.js" "$U" "$H/metodo.json" || fallos=$((fallos+1))
fi

echo
if (( fallos == 0 )); then echo "RESULTADO: /metodo OK (0 fallos; $N_CAP capítulos + cap0; generado = commiteado)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en /metodo"
exit 1
