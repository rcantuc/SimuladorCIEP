#!/usr/bin/env bash
# =============================================================================
# test-sitio-entidades.sh — el andamiaje de las 32 entidades (/entidades, /entidades/<ABREV>, jsonEntidad.php) como gate (v8.13.0)
# =============================================================================
# Cinco comprobaciones, sin Stata:
#   0. generado == commiteado: 05_scripts/generar-entidades.py paginas --check regenera las 32 páginas y el catálogo
#      desde SIMentidad.ado y exige bytes idénticos a lo commiteado (y ninguna carpeta <ABREV>/ sobrante).
#   1. Las 32 páginas, la plantilla, el índice y el endpoint parsean (php -l).
#   2. HTTP (php -S sobre una copia del sitio, con los JSON de las entidades de prueba en users/ciepmx/<ABREV>/ y el
#      índice en users/ciepmx/entidades.json): /entidades y /entidades/<ABREV> responden 200 con su esqueleto;
#      jsonEntidad.php sirve ciclo, tasas, meta (= neto) y el índice BYTE A BYTE, y el Sankey de cada corte con los mismos
#      nodos y enlaces que el archivo del motor (los enlaces con sello=1 llevan toolText); harness de seguridad:
#      abrev fuera del catálogo (minúsculas, clave numérica, traversal, %00) → 400, producto o corte fuera de la lista → 400,
#      idSession con traversal → cae al default ciepmx, entidad del catálogo sin archivos → 404 con la pista del deploy.
#   3. Cero números: ni la plantilla, ni el índice, ni las 32 páginas generadas, ni el catálogo, ni jsonEntidad.php, ni
#      js/entidad.js, ni metodo/plantilla.php, ni css/metodo.css traen un literal de 4+ dígitos.
#   4. Chrome headless (test-sitio-entidades.js) sobre las entidades de prueba (default NL, Jal y Col: un estado grande,
#      uno medio y uno chico) y sobre el índice: los cuatro productos se dibujan; los enlaces del Sankey son idénticos como
#      cadena al JSON del motor (quintil y, tras el selector, grupoedad); las series del ciclo de vida son los pct del JSON;
#      cada barra de tasas lleva el te del JSON; el neto/PIBE de la página es el de meta.json; los sellos aparecen (marca,
#      lista y nota al pie numerada con su n) exactamente donde meta.json y los JSON del motor dicen sello=1 y en ningún
#      otro lado; las cifras del encabezado se llenaron; sin errores de JS; y, si se pide, las capturas PNG.
# Origen de los JSON: --users <dir> con <ABREV>/{sankey-*.json, ciclo-vida.json, tasas-efectivas.json, meta.json} y
# entidades.json (p. ej. users/ricardo tras contrato-32.sh); default 05_scripts/fixtures/entidades (NL, Jal, Col reales
# de una corrida completa; CI sin corrida local). --entidades "NL Jal Col" elige cuáles probar (deben existir en --users).
#   bash 05_scripts/test-sitio-entidades.sh [--users <dir>] [--entidades "NL Jal Col"] [--png <dir>] [--puerto N] [--conservar] [--sin-chrome]
# Requiere php, curl, node, npm, python3 y Chrome (CHROME_PATH o ruta por defecto); instala puppeteer-core fijo en un
# directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
FIX="$REPO_ROOT/05_scripts/fixtures/entidades"
PUERTO=8497; CONSERVAR=false; PNG=""; USERS=""; ENTIDADES="NL Jal Col"; SIN_CHROME=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --users) USERS="$2"; shift 2 ;;
        --entidades) ENTIDADES="$2"; shift 2 ;;
        --png) PNG="$2"; shift 2 ;;
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
[[ -n "$USERS" ]] || USERS="$FIX"
[[ -d "$USERS" ]] || { echo "no existe el directorio de JSON de entidades: $USERS" >&2; exit 2; }
for e in $ENTIDADES; do
    for f in sankey-quintil.json sankey-grupoedad.json sankey-sexo.json sankey-rural.json sankey-escol.json ciclo-vida.json tasas-efectivas.json meta.json; do
        [[ -f "$USERS/$e/$f" ]] || { echo "falta $USERS/$e/$f (corre contrato-32.sh o generar-entidades.py meta)" >&2; exit 2; }
    done
done
[[ -f "$USERS/entidades.json" ]] || { echo "falta $USERS/entidades.json (generar-entidades.py meta)" >&2; exit 2; }
echo "# JSON de origen: $USERS (entidades: $ENTIDADES)"

fallos=0
aserta() { if eval "$1"; then printf 'OK     %s\n' "$2"; else printf 'FALLO  %s\n' "$2"; fallos=$((fallos+1)); fi; }

echo "## 0. generado == commiteado (generar-entidades.py paginas --check)"
if python3 "$REPO_ROOT/05_scripts/generar-entidades.py" paginas --check; then echo "OK     las 32 páginas y _catalogo.php son lo que genera SIMentidad.ado"; else echo "FALLO  lo commiteado difiere de lo generado"; fallos=$((fallos+1)); fi

echo "## 1. php -l"
n_php=0; f_php=0
for f in "$SITE"/entidades/*.php "$SITE"/entidades/*/index.php "$SITE/jsonEntidad.php" "$SITE/metodo/plantilla.php"; do
    n_php=$((n_php+1)); php -l "$f" >/dev/null 2>&1 || { f_php=$((f_php+1)); echo "       sintaxis: $f"; }
done
aserta '[[ $f_php -eq 0 ]]' "$n_php PHP parsean ($f_php con errores)"
aserta '[[ $(ls -d "$SITE"/entidades/*/ | wc -l | tr -d " ") -eq 32 ]]' "hay exactamente 32 carpetas /entidades/<ABREV>/"

H="$(mktemp -d -t sitio-ent-XXXXXX)"
PHP_PID=""
limpiar() {
    if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; fi
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT

if ! $SIN_CHROME; then
    if node -e "require.resolve('puppeteer-core')" 2>/dev/null; then NODE_PATH_EXTRA=""; else
        ( cd "$H" && npm install --silent --no-audit --no-fund puppeteer-core@25.13.0 >/dev/null 2>&1 ) || { echo "no pude instalar puppeteer-core" >&2; exit 2; }
        NODE_PATH_EXTRA="$H/node_modules"
    fi
    export NODE_PATH="${NODE_PATH_EXTRA}${NODE_PATH:+:$NODE_PATH}"
fi

# --- la copia: <H>/site (04_1) + <H>/users/ciepmx/<ABREV>/ + entidades.json; DEPLOYED_COMMIT de prueba ---
mkdir -p "$H/users/ciepmx"
cp -R "$SITE" "$H/site"; rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs"
for e in $ENTIDADES; do mkdir -p "$H/users/ciepmx/$e"; cp "$USERS/$e"/*.json "$H/users/ciepmx/$e/"; done
cp "$USERS/entidades.json" "$H/users/ciepmx/entidades.json"
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

chk() { # chk <codigo esperado> <descripcion> <args de curl...>
    local esp="$1" desc="$2"; shift 2
    local code
    code="$(curl -sL -o "$H/body" -w '%{http_code}' "$@")"
    local r=OK; [[ "$code" == "$esp" ]] || { r=FALLO; fallos=$((fallos+1)); }
    printf '%-6s %-60s -> %s (esperado %s) | %s\n' "$r" "$desc" "$code" "$esp" "$(head -c 80 "$H/body" | tr -d '\n')"
}
# nodos / enlaces / enlaces con sello=1 del archivo del motor (gramática de SankeySF.do) y del JSON servido
cuenta_origen() { python3 -c '
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
print(len(re.findall(r"\{label:\"([^\"]*)\"\}",t)), len(re.findall(r"\{to:\"[^\"]*\",value:\"[^\"]*\",from:\"[^\"]*\"",t)), len(re.findall(r"sello:\"1\"",t)))' "$1"; }
cuenta_servido() { python3 -c '
import json,sys
d=json.load(open(sys.argv[1])); print(len(d["nodes"]), len(d["links"]), sum(1 for l in d["links"] if l.get("sello")=="1"), sum(1 for l in d["links"] if "toolText" in l))' "$1" 2>/dev/null || echo "0 0 0 0"; }

echo "## 2. HTTP"
chk 200 "GET /entidades (la ruta)"                            "$U/entidades"
chk 200 "GET /entidades/"                                     "$U/entidades/"
aserta '[[ $(grep -c "<tr data-abrev=" "$H/body") == 32 ]]' "el índice trae 32 filas (una por entidad del catálogo)"
aserta 'grep -q "jsonEntidad.php?producto=indice" "$H/body"' "el índice pide /jsonEntidad.php?producto=indice"
aserta 'grep -q "entidadIndice(" "$H/body"' "el índice llama entidadIndice(…)"
for e in $ENTIDADES; do
    chk 200 "GET /entidades/$e/"                              "$U/entidades/$e/"
    aserta 'grep -q "id=\"ent-sankey\"" "$H/body" && grep -q "id=\"ent-ciclo-H\"" "$H/body" && grep -q "id=\"ent-ciclo-M\"" "$H/body" && grep -q "id=\"ent-tasas\"" "$H/body" && grep -q "id=\"ent-neto\"" "$H/body"' "$e: la página trae los contenedores de los cuatro productos"
    aserta '[[ $(grep -c "name=\"ent-corte\"" "$H/body") == 5 ]]' "$e: selector de corte con cinco radios"
    aserta 'grep -q "\"abrev\":\"'"$e"'\"" "$H/body" && grep -q "entidadPagina(" "$H/body"' "$e: la página llama entidadPagina({abrev: $e, …})"
    aserta 'grep -q "jsonEntidad.php?abrev='"$e"'&producto=meta" "$H/body"' "$e: pide /jsonEntidad.php?abrev=$e&producto=meta"
    aserta '[[ $(grep -c "id=\"nota-[1-5]\"" "$H/body") == 5 ]]' "$e: las cinco notas de método (los sellos se agregan en runtime)"
    chk 200 "jsonEntidad.php?abrev=$e&producto=ciclo"          "$U/jsonEntidad.php?abrev=$e&producto=ciclo"
    aserta 'cmp -s "$H/body" "$USERS/'"$e"'/ciclo-vida.json"' "$e: ciclo-vida.json se sirve byte a byte"
    chk 200 "jsonEntidad.php?abrev=$e&producto=tasas"          "$U/jsonEntidad.php?abrev=$e&producto=tasas"
    aserta 'cmp -s "$H/body" "$USERS/'"$e"'/tasas-efectivas.json"' "$e: tasas-efectivas.json se sirve byte a byte"
    chk 200 "jsonEntidad.php?abrev=$e&producto=meta"           "$U/jsonEntidad.php?abrev=$e&producto=meta"
    aserta 'cmp -s "$H/body" "$USERS/'"$e"'/meta.json"' "$e: meta.json se sirve byte a byte"
    chk 200 "jsonEntidad.php?abrev=$e&producto=neto (alias)"   "$U/jsonEntidad.php?abrev=$e&producto=neto"
    aserta 'cmp -s "$H/body" "$USERS/'"$e"'/meta.json"' "$e: producto=neto es meta.json"
    chk 200 "jsonEntidad.php?abrev=$e&producto=sankey (default quintil)" "$U/jsonEntidad.php?abrev=$e&producto=sankey"
    aserta 'grep -q "ciepmx/'"$e"'/sankey-quintil.json" "$H/body"' "$e: el default del Sankey es sankey-quintil.json (quintil estatal)"
    for k in quintil grupoedad sexo rural escol; do
        chk 200 "jsonEntidad.php?abrev=$e&producto=sankey&corte=$k" "$U/jsonEntidad.php?abrev=$e&producto=sankey&corte=$k"
        read -r N_ORI L_ORI S_ORI < <(cuenta_origen "$USERS/$e/sankey-$k.json")
        read -r N_SRV L_SRV S_SRV T_SRV < <(cuenta_servido "$H/body")
        aserta '[[ "$N_SRV" == "$N_ORI" && "$L_SRV" == "$L_ORI" && "$N_SRV" != "0" ]]' "$e/$k: mismos nodos/enlaces que el motor ($N_SRV/$L_SRV vs $N_ORI/$L_ORI)"
        aserta '[[ "$S_SRV" == "$S_ORI" && "$T_SRV" == "$S_ORI" ]]' "$e/$k: $S_SRV enlaces con sello=1 y los mismos $T_SRV con toolText de sello (origen $S_ORI)"
    done
done
chk 200 "jsonEntidad.php?producto=indice"                     "$U/jsonEntidad.php?producto=indice"
aserta 'cmp -s "$H/body" "$USERS/entidades.json"' "entidades.json se sirve byte a byte"
echo "## 2b. harness de seguridad"
E1="$(echo "$ENTIDADES" | awk '{print $1}')"
chk 400 "abrev=xx (fuera del catálogo)"                        "$U/jsonEntidad.php?abrev=xx&producto=meta"
chk 400 "abrev en minúsculas (estricto)"                      "$U/jsonEntidad.php?abrev=$(echo "$E1" | tr 'A-Z' 'a-z')&producto=meta"
chk 400 "abrev=19 (clave numérica, no abreviatura)"           "$U/jsonEntidad.php?abrev=19&producto=meta"
chk 400 "abrev=../$E1 (traversal)"                            "$U/jsonEntidad.php?abrev=../$E1&producto=meta"
chk 400 "abrev=$E1%00 (nulo)"                                 "$U/jsonEntidad.php?abrev=$E1%00&producto=meta"
chk 400 "abrev ausente con producto=meta"                     "$U/jsonEntidad.php?producto=meta"
chk 400 "producto=../x (fuera de lista)"                      "$U/jsonEntidad.php?abrev=$E1&producto=../x"
chk 400 "producto ausente"                                    "$U/jsonEntidad.php?abrev=$E1"
chk 400 "corte=../x (fuera de lista)"                         "$U/jsonEntidad.php?abrev=$E1&producto=sankey&corte=../x"
chk 400 "corte=decil (nacional, no es corte de entidad)"      "$U/jsonEntidad.php?abrev=$E1&producto=sankey&corte=decil"
chk 200 "idSession con traversal → cae al default ciepmx"     "$U/jsonEntidad.php?abrev=$E1&producto=meta&idSession=../../../../etc/passwd%00"
aserta 'cmp -s "$H/body" "$USERS/'"$E1"'/meta.json"' "el traversal en idSession sirvió users/ciepmx/$E1/meta.json"
FALTANTE=""
for e in Zac Ags BC Yuc; do if ! echo " $ENTIDADES " | grep -q " $e "; then FALTANTE="$e"; break; fi; done
if [[ -n "$FALTANTE" ]]; then
    chk 404 "abrev=$FALTANTE del catálogo pero sin archivos → 404" "$U/jsonEntidad.php?abrev=$FALTANTE&producto=meta"
    aserta 'grep -q "Fase 3b-ter" "$H/body"' "el 404 explica qué falta (users/ricardo/<ABREV>/ en la Fase 3b-ter)"
    chk 200 "GET /entidades/$FALTANTE/ (la página existe aunque falten sus JSON)" "$U/entidades/$FALTANTE/"
fi
code_xx="$(curl -sL -o "$H/body" -w '%{http_code}' "$U/entidades/XX/")"
aserta '[[ "$code_xx" == "404" ]] || ! grep -q "entidadPagina(" "$H/body"' "GET /entidades/XX/ (fuera del catálogo): no hay página de entidad (HTTP $code_xx; Apache da 404, php -S puede caer al índice)"

echo "## 3. cero números en el sitio (los valores vienen de los JSON del motor y de meta.json)"
# (se descartan antes las entidades HTML &#NNNN; y los colores CSS #rrggbb, que no son números)
for f in entidades/_entidad.php entidades/index.php entidades/_catalogo.php jsonEntidad.php js/entidad.js metodo/plantilla.php css/metodo.css; do
    aserta '! sed -E "s/&#[0-9]+;//g; s/#[0-9a-fA-F]{3,8}//g" "$SITE/'"$f"'" | grep -qE "[0-9]{4,}"' "$f sin literales de 4+ dígitos"
done
n_lit=0
for f in "$SITE"/entidades/*/index.php; do grep -qE "[0-9]{4,}" "$f" && n_lit=$((n_lit+1)); done
aserta '[[ $n_lit -eq 0 ]]' "las 32 páginas generadas sin literales de 4+ dígitos ($n_lit con alguno)"

if $SIN_CHROME; then
    echo "## 4. Chrome headless: SALTADO (--sin-chrome)"
else
    echo "## 4. Chrome headless: los cuatro productos se dibujan con los números del motor y los sellos donde meta.json dice"
    node "$REPO_ROOT/05_scripts/test-sitio-entidades.js" "$U" "$USERS" "$ENTIDADES" ${PNG:+"$PNG"} || fallos=$((fallos+1))
fi

echo
if (( fallos == 0 )); then echo "RESULTADO: /entidades OK (0 fallos; entidades probadas: $ENTIDADES)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en /entidades"
exit 1
