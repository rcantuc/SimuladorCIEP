#!/usr/bin/env bash
# =============================================================================
# test-sitio-nta.sh — la página de método /NTA (Sankey NTA v3 de la cuenta por individuo + panel grupo × sexo) como gate
# =============================================================================
# Levanta el sitio (04_1_simuladorfiscal.ciep.mx/) con php -S en una copia temporal, con lo que el motor
# emite para esta página en el lugar del escenario default (users/ciepmx/):
#   - el Sankey v3 (users/<id>/SankeyNTA/sankey-v3-grupoedad.json, NTA.do §7b, contrato v3: edades solo al inicio y al final;
#     NTA-4: cada enlace con value en MXN y pctpib en % del PIB, un solo Desahorro / Futuro / ajuste S.14, especie fundida),
#   - la cuenta NTA por grupo (users/<id>/NTA/nta-grupoedad.json, NTA.do §6.2) + nta-identidad.txt, y
#   - el panel por grupo de edad × sexo (users/<id>/NTA/nta-panel-grupoedad-sexo.json, NTA.do §7c, esquema nta-panel/v2),
# y comprueba:
#   1. HTTP: /NTA y /NTA/ responden 200; jsonSankeyNTA.php sirve el v3 por default y con corte=v3-grupoedad, con el MISMO
#      número de nodos y enlaces que el JSON de origen (35/99 cuando el origen es el fixture; el conteo del v3 queda fijado
#      aquí) y cada enlace idéntico (from, to, value, pctpib) al de origen, chart.unidad = pctpib; corte fuera de la lista
#      blanca → 400; idSession con traversal → cae al default ciepmx; el v2 y el v1 sin archivo → 404 con pista de deploy;
#      ?cuenta=grupoedad y ?cuenta=panel-grupoedad-sexo se sirven byte a byte; ?cuenta=identidad sirve el reporte de texto;
#      cuenta fuera de la lista → 400; el panel trae 15 celdas balanceadas en ambas unidades, pib.valor y nacional_pctpib.
#   2. Cero números en la página: ni NTA/index.php, ni js/metodo-sankey.js, ni metodo/plantilla.php, ni
#      css/metodo.css, ni jsonSankeyNTA.php traen un literal de 4+ dígitos (todo valor dibujado o escrito
#      viene de los JSON del motor).
#   3. Chrome headless (test-sitio-nta.js): el Sankey v3 se dibuja y cada enlace que recibe el navegador es
#      idéntico, como cadena, al del JSON de origen (value y pctpib); nodos iguales y en el mismo orden; FusionCharts
#      dibuja con pctpib como value y conserva el MXN (mxn) y un tooltext con ambas unidades; el tooltip de un enlace
#      muestra «% of GDP» y «bn MXN»; las cifras de «Anchoring and residual» se llenaron desde la cuenta (bn) y desde el
#      panel (% del PIB, nacional_pctpib / v3_mxn), incluido el año del encabezado de unidad; los cinco mini-Sankeys del
#      panel se dibujan con las celdas Total (cintas con data-value y data-pctpib), los pies traen ambas unidades, y el
#      selector Hombres / Mujeres cambia los cinco sin recargar; y, si se pide, las capturas PNG (página completa, Sankey
#      v3 solo y panel en Total: la evidencia del PR).
# Origen del Sankey: --json <ruta>; si no, users/ricardo/SankeyNTA/sankey-v3-grupoedad.json del repo si
# existe; si no, el fixture 05_scripts/fixtures/sankey-nta-grupoedad.json (el v3 real de la corrida completa
# de SIM.do, CI sin corrida local). Origen de la cuenta: --cuenta <ruta>; si no, users/ricardo/NTA/
# nta-grupoedad.json (+ nta-identidad.txt y nta-panel-grupoedad-sexo.json a su lado); si no, los fixtures nta-grupoedad.json,
# nta-identidad.txt y nta-panel-grupoedad-sexo.json. Con --json se espera --cuenta de la MISMA corrida (si no, se usan los
# fixtures y se avisa). --panel <ruta> fuerza el JSON del panel.
#   bash 05_scripts/test-sitio-nta.sh [--json <ruta>] [--cuenta <ruta>] [--panel <ruta>] [--png <salida.png>] [--puerto N] [--conservar]
# Requiere php, curl, node, npm, python3 y Chrome (CHROME_PATH o ruta por defecto); instala puppeteer-core
# fijo en un directorio temporal si no está disponible (red solo para eso).
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
FIX="$REPO_ROOT/05_scripts/fixtures"
PUERTO=8495; CONSERVAR=false; PNG=""; JSON=""; CUENTA=""; PANEL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON="$2"; shift 2 ;;
        --cuenta) CUENTA="$2"; shift 2 ;;
        --panel) PANEL="$2"; shift 2 ;;
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

ES_FIXTURE=false
if [[ -z "$JSON" ]]; then
    if [[ -f "$REPO_ROOT/users/ricardo/SankeyNTA/sankey-v3-grupoedad.json" ]]; then
        JSON="$REPO_ROOT/users/ricardo/SankeyNTA/sankey-v3-grupoedad.json"
    else
        JSON="$FIX/sankey-nta-grupoedad.json"; ES_FIXTURE=true
    fi
fi
[[ -f "$JSON" ]] || { echo "no existe el JSON de origen: $JSON" >&2; exit 2; }
if [[ -z "$CUENTA" ]]; then
    if $ES_FIXTURE; then
        CUENTA="$FIX/nta-grupoedad.json"
    elif [[ "$JSON" == "$REPO_ROOT/users/ricardo/SankeyNTA/sankey-v3-grupoedad.json" && -f "$REPO_ROOT/users/ricardo/NTA/nta-grupoedad.json" ]]; then
        CUENTA="$REPO_ROOT/users/ricardo/NTA/nta-grupoedad.json"
    else
        CUENTA="$FIX/nta-grupoedad.json"
        echo "# aviso: --cuenta no dado; las cifras se toman del fixture $CUENTA (no de la corrida de $JSON)"
    fi
fi
[[ -f "$CUENTA" ]] || { echo "no existe el JSON de la cuenta: $CUENTA" >&2; exit 2; }
IDENT="$(dirname "$CUENTA")/nta-identidad.txt"
[[ -f "$IDENT" ]] || IDENT="$FIX/nta-identidad.txt"
if [[ -z "$PANEL" ]]; then
    PANEL="$(dirname "$CUENTA")/nta-panel-grupoedad-sexo.json"
    [[ -f "$PANEL" ]] || { PANEL="$FIX/nta-panel-grupoedad-sexo.json"; echo "# aviso: el panel se toma del fixture $PANEL"; }
fi
[[ -f "$PANEL" ]] || { echo "no existe el JSON del panel: $PANEL" >&2; exit 2; }
echo "# Sankey de origen: $JSON"
echo "# cuenta de origen: $CUENTA (reporte: $IDENT)"
echo "# panel de origen: $PANEL"

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

# --- la copia: <H>/site (04_1) + <H>/users/ciepmx/{SankeyNTA,NTA}/ (TMP_PATH local = dirname(dirname(__FILE__))/users/)
#     y un DEPLOYED_COMMIT de prueba para que el pie pinte versión, fecha y vintage como en el VPS ---
mkdir -p "$H/users/ciepmx/SankeyNTA" "$H/users/ciepmx/NTA"
cp -R "$SITE" "$H/site"; rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs"
cp "$JSON" "$H/users/ciepmx/SankeyNTA/sankey-v3-grupoedad.json"
cp "$CUENTA" "$H/users/ciepmx/NTA/nta-grupoedad.json"
cp "$IDENT" "$H/users/ciepmx/NTA/nta-identidad.txt"
cp "$PANEL" "$H/users/ciepmx/NTA/nta-panel-grupoedad-sexo.json"
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
    printf '%-6s %-56s -> %s (esperado %s) | %s\n' "$r" "$desc" "$code" "$esp" "$(head -c 90 "$H/body" | tr -d '\n')"
}
aserta() { if eval "$1"; then printf 'OK     %s\n' "$2"; else printf 'FALLO  %s\n' "$2"; fallos=$((fallos+1)); fi; }

# conteo nodos/enlaces del JSON de origen (gramática de SankeySumSim) y del JSON servido (FusionCharts)
read -r N_ORI L_ORI < <(python3 -c '
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
print(len(re.findall(r"\{label:\"([^\"]*)\"\}",t)), len(re.findall(r"\{to:\"([^\"]*)\",value:\"([^\"]*)\",from:\"([^\"]*)\"(?:,pctpib:\"([^\"]*)\")?\}",t)))' "$JSON")
echo "# origen: $N_ORI nodos / $L_ORI enlaces"
if $ES_FIXTURE; then
    aserta '[[ "$N_ORI" == 35 && "$L_ORI" == 99 ]]' "el fixture es el v3 real (NTA-4): 35 nodos / 99 enlaces ($N_ORI/$L_ORI)"
fi
aserta 'python3 -c "import re,sys; t=open(sys.argv[1],encoding=\"utf-8\").read(); L=re.findall(r\"\\{to:\\\"[^\\\"]*\\\",value:\\\"[^\\\"]*\\\",from:\\\"[^\\\"]*\\\"(,pctpib:\\\"[^\\\"]*\\\")?\\}\", t); assert L and all(p for p in L)" "$JSON"' "cada enlace del v3 de origen trae pctpib (NTA-4: value en MXN y % del PIB, dividido en Stata)"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"esquema\"]==\"nta-panel/v2\" and len(d[\"celdas\"])==15 and d[\"pib\"][\"valor\"]>0 and \"nacional_pctpib\" in d and \"v3_mxn\" in d and all(abs(sum(c[\"entradas_flujos\"].values())-sum(c[\"salidas_flujos\"].values()))/c[\"C\"]<=1e-9 and abs(sum(c[\"pctpib\"][\"entradas_flujos\"].values())-sum(c[\"pctpib\"][\"salidas_flujos\"].values()))/c[\"pctpib\"][\"C\"]<=1e-9 for c in d[\"celdas\"])" "$PANEL"' "el panel de origen es nta-panel/v2 con 15 celdas balanceadas en MXN y en % del PIB (1e-9 relativo a C), pib.valor, nacional_pctpib y v3_mxn"

echo "## 1. HTTP"
chk 200 "GET /NTA (la ruta)"                                  "$U/NTA"
chk 200 "GET /NTA/"                                           "$U/NTA/"
aserta 'grep -q "id=\"sankey-nta\"" "$H/body"' "la página trae el contenedor #sankey-nta"
aserta 'grep -q "jsonSankeyNTA.php?corte=v3-grupoedad" "$H/body"' "la página pide /jsonSankeyNTA.php?corte=v3-grupoedad"
aserta 'grep -q "jsonSankeyNTA.php?cuenta=grupoedad" "$H/body"' "la página pide /jsonSankeyNTA.php?cuenta=grupoedad (cifras)"
aserta 'grep -q "jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo" "$H/body"' "la página pide /jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo (panel)"
aserta '[[ $(grep -c "id=\"nta-panel-[1-5]\"" "$H/body") == 5 ]]' "la página trae los cinco contenedores del panel (#nta-panel-1 … -5)"
aserta '[[ $(grep -c "name=\"nta-sexo\"" "$H/body") == 3 ]]' "la página trae el selector Total / Men / Women (tres radios nta-sexo)"
aserta '! grep -q "corte=grupoedad\"" "$H/body" && ! grep -q "renderAt.*corte=v2-grupoedad" "$H/body"' "la página ya no dibuja el v1 ni el v2 (sin url corte=grupoedad ni Sankey con corte=v2-grupoedad)"
aserta 'grep -q "split household-level items among the members of each household<sup" "$H/body"' "la frase del reparto intra-hogar lleva el superíndice de la nota"
aserta 'grep -q "id=\"nota-1\"" "$H/body" && grep -q "Within-household allocation" "$H/body"' "la nota al pie 1 existe (Within-household allocation)"
chk 200 "jsonSankeyNTA.php (sin corte: default v3)"            "$U/jsonSankeyNTA.php"
aserta 'grep -q "ciepmx/SankeyNTA/sankey-v3-grupoedad.json" "$H/body"' "el default sirve users/ciepmx/SankeyNTA/sankey-v3-grupoedad.json"
chk 200 "jsonSankeyNTA.php?corte=v3-grupoedad"                 "$U/jsonSankeyNTA.php?corte=v3-grupoedad"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"nodes\"] and d[\"links\"]" "$H/body"' "la respuesta es JSON válido con nodes y links"
read -r N_SRV L_SRV < <(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d["nodes"]), len(d["links"]))' "$H/body" 2>/dev/null || echo "0 0")
aserta '[[ "$N_SRV" == "$N_ORI" && "$L_SRV" == "$L_ORI" ]]' "el JSON servido tiene los mismos nodos/enlaces que el origen ($N_SRV/$L_SRV vs $N_ORI/$L_ORI)"
aserta 'python3 -c "
import json,re,sys
d=json.load(open(sys.argv[1])); t=open(sys.argv[2],encoding=\"utf-8\").read()
O=re.findall(r\"\\{to:\\\"([^\\\"]*)\\\",value:\\\"([^\\\"]*)\\\",from:\\\"([^\\\"]*)\\\",pctpib:\\\"([^\\\"]*)\\\"\\}\", t)
assert len(O)==len(d[\"links\"]) and all(l[\"to\"]==o[0] and l[\"value\"]==o[1] and l[\"from\"]==o[2] and l[\"pctpib\"]==o[3] for l,o in zip(d[\"links\"],O))
assert d[\"chart\"][\"unidad\"]==\"pctpib\"
" "$H/body" "$JSON"' "cada enlace servido es idéntico (from, to, value, pctpib) al de origen y el chart declara unidad = pctpib"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); g=[n for n in d[\"nodes\"] if n[\"label\"] in (\"Ing nacional\",\"Gobierno\",\"Activos\",\"Transferencias en efectivo\")]; assert len(g)==4 and all(\"toolText\" in n for n in g) and not any(\"toolText\" in n for n in d[\"nodes\"] if n not in g)" "$H/body"' "solo los cuatro hubs (Ing nacional, Gobierno, Activos, Transferencias en efectivo) llevan el toolText «inflows = outflows»"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); L=[n[\"label\"] for n in d[\"nodes\"]]; assert not any(l.startswith((\"Ingreso \",\"Consumo \",\"Desahorro \",\"Futuro \",\"Ancla S14\")) or l in (\"Familias\",\"Salud pública\",\"Educación pública\",\"Otros en especie\") for l in L) and sum(l.startswith(\"De \") for l in L)==5 and sum(l.startswith(\" De \") for l in L)==5 and all(x in L for x in (\"Desahorro\",\"Futuro\",\"Colectivo\",\"Ajuste a cuentas nacionales S14\"))" "$H/body"' "el v3 servido (NTA-4): 5 grupos perceptores y 5 consumidores; Desahorro, Futuro, Colectivo y Ajuste a cuentas nacionales S14 únicos; sin Ingreso g / Consumo g / Familias / Desahorro g / Futuro g / especie aparte / Ancla recorte+complemento"
chk 400 "jsonSankeyNTA.php?corte=../x (fuera de lista)"       "$U/jsonSankeyNTA.php?corte=../x"
chk 400 "jsonSankeyNTA.php?corte=v3-grupoedad%00"             "$U/jsonSankeyNTA.php?corte=v3-grupoedad%00"
chk 200 "jsonSankeyNTA.php traversal en idSession"            "$U/jsonSankeyNTA.php?corte=v3-grupoedad&idSession=../../../../etc/passwd%00"
aserta 'grep -q "ciepmx/SankeyNTA/sankey-v3-grupoedad.json" "$H/body"' "el traversal cayó al default ciepmx"
chk 404 "jsonSankeyNTA.php?corte=v2-grupoedad (v2 sin archivo)" "$U/jsonSankeyNTA.php?corte=v2-grupoedad"
chk 404 "jsonSankeyNTA.php?corte=grupoedad (v1 sin archivo)"  "$U/jsonSankeyNTA.php?corte=grupoedad"
aserta 'grep -q "Fase 3b-ter" "$H/body"' "el 404 explica qué falta (NTA/ y SankeyNTA/ en el deploy)"
chk 200 "jsonSankeyNTA.php?cuenta=grupoedad"                  "$U/jsonSankeyNTA.php?cuenta=grupoedad"
aserta 'cmp -s "$H/body" "$CUENTA"' "la cuenta se sirve byte a byte (users/ciepmx/NTA/nta-grupoedad.json)"
chk 200 "jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo"       "$U/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo"
aserta 'cmp -s "$H/body" "$PANEL"' "el panel se sirve byte a byte (users/ciepmx/NTA/nta-panel-grupoedad-sexo.json)"
chk 200 "jsonSankeyNTA.php?cuenta=identidad (texto)"          "$U/jsonSankeyNTA.php?cuenta=identidad"
aserta 'cmp -s "$H/body" "$IDENT"' "nta-identidad.txt se sirve byte a byte"
chk 400 "jsonSankeyNTA.php?cuenta=../x (fuera de lista)"      "$U/jsonSankeyNTA.php?cuenta=../x"
chk 404 "jsonSankeyNTA.php?cuenta=quinquenio-sexo (sin arch.)" "$U/jsonSankeyNTA.php?cuenta=quinquenio-sexo"

echo "## 2. cero números en la página (los valores vienen de los JSON del motor)"
# (se descartan antes las entidades HTML &#NNNN; y los colores CSS #rrggbb, que no son números)
for f in NTA/index.php js/metodo-sankey.js metodo/plantilla.php css/metodo.css jsonSankeyNTA.php; do
    aserta '! sed -E "s/&#[0-9]+;//g; s/#[0-9a-fA-F]{3,8}//g" "$SITE/'"$f"'" | grep -qE "[0-9]{4,}"' "$f sin literales de 4+ dígitos"
done

echo "## 3. Chrome headless: se dibuja, los números son los del motor, las cifras se llenaron y el panel cambia con el selector"
node "$REPO_ROOT/05_scripts/test-sitio-nta.js" "$U" "$JSON" "$CUENTA" "$PANEL" ${PNG:+"$PNG"} || fallos=$((fallos+1))

echo
if (( fallos == 0 )); then echo "RESULTADO: /NTA OK (0 fallos; Sankey v3 $N_ORI nodos / $L_ORI enlaces; panel 15 celdas)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en /NTA"
exit 1
