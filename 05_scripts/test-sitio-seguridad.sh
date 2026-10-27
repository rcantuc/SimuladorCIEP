#!/usr/bin/env bash
# test-sitio-seguridad.sh — el harness de seguridad de los PHP del sitio (v8.11a), como gate.
#
# Levanta el sitio (04_1_simuladorfiscal.ciep.mx/) con `php -S` en una copia temporal, con un
# Stata FALSO en lugar de Stata (config.php de la copia: el falso registra la llamada y deja un
# output.txt mínimo; el .do generado NUNCA se ejecuta), y dispara contra calculaStata.php los
# payloads de inyección de código Stata / path traversal que v8.11a cerró. Cada payload debe
# responder 400 sin que Stata corra; la petición válida debe responder 200, correr Stata UNA
# vez y dejar un .do sin `shell`/`!`. También checkStataStatus, jsonSankey*, cargaDefault y
# logCalcular (mismos casos que diag-v8.11a-fantasmas-2026-10-16/seguridad-php-pruebas.txt).
#
# Sin Stata, sin assets, sin red: corre en GitHub Actions (.github/workflows/gates-sin-stata.yml)
# y en cualquier máquina con php y curl. No toca el repo ni users/.
#
# Uso: bash 05_scripts/test-sitio-seguridad.sh [--puerto N] [--conservar]
# Exit 0 si todos los casos pasan; 1 si alguno falla; 2 si no se pudo levantar php -S.
set -uo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
[[ -z "$REPO_ROOT" ]] && { echo "No se pudo detectar root del repo Git." >&2; exit 2; }
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
PUERTO=8471; CONSERVAR=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
command -v php >/dev/null || { echo "falta php" >&2; exit 2; }
command -v curl >/dev/null || { echo "falta curl" >&2; exit 2; }

H="$(mktemp -d -t sitio-seg-XXXXXX)"
PHP_PID=""
limpiar() {
    if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; fi
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT

# --- la copia: <H>/site (04_1), <H>/users (TMP_PATH local = dirname(dirname(__FILE__))/users/),
#     <H>/Web.Stata.do (calcula_ruta local), Stata falso en vez del real -----------------------
mkdir -p "$H/users/ciepmx"
cp -R "$SITE" "$H/site"
rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs"
cp "$REPO_ROOT/01_modulos/Web.Stata.do" "$H/Web.Stata.do"
cat > "$H/fake-stata" <<'EOF'
#!/usr/bin/env bash
# Stata falso: imita `stata -b do <id>.do` desde users/<id>/ sin ejecutar nada del .do.
H="$FAKE_H"; ID="$(basename "$PWD")"
echo "$(date +%H:%M:%S) start id=$ID args=$*" >> "$H/fake-stata.log"
cp "$H/canned-output.txt" ./output.txt
echo 0 > "$ID.done"
EOF
chmod +x "$H/fake-stata"
# output.txt mínimo con la forma que parsea el PHP (NOMBRE:[a,b] por línea)
printf 'INGRESOS:[3.855,0.244]\nGASTOS:[0.000,2.080]\nPIBY:[39415135710357.34]\n' > "$H/canned-output.txt"
cp "$H/canned-output.txt" "$H/users/ciepmx/output.txt"
for k in decil escol grupoedad rural sexo; do printf '{"chart": {"caption": " "}, "nodes": [], "links": []}\n' > "$H/users/ciepmx/sankey-$k.json"; done
# Sankey NTA (/NTA, jsonSankeyNTA.php): users/ciepmx/SankeyNTA/sankey-<corte>.json, con la forma que escribe SankeySumSim
mkdir -p "$H/users/ciepmx/SankeyNTA"
printf '$(document).ready(function() {const dataSource={chart:{caption:""},\nnodes:[{label:"De 0 a 4"},{label:"Ing Laboral"}],\nlinks:[{to:"Ing Laboral",value:"28803723154.81406",from:"De 0 a 4"}]};\nFusionCharts.ready(function() {});});\n' > "$H/users/ciepmx/SankeyNTA/sankey-grupoedad.json"
# config.php de la COPIA: cualquier ruta de Stata que config.php conozca -> el falso. La detección
# local/VPS de config.php es por HTTP_HOST (localhost) y la primera rama exige que exista el
# binario de StataNow: se sustituye la ruta de esa rama por el falso, que sí existe.
python3 - "$H/site/config.php" "$H/fake-stata" <<'PYEOF'
import re, sys
p, fake = sys.argv[1], sys.argv[2]
t = open(p, encoding='utf-8', newline='').read()
t2 = re.sub(r"/Applications/StataNow/StataSE\.app/Contents/MacOS/stata-se", fake, t)
if t2 == t:
    sys.exit("test-sitio-seguridad: no se encontró la ruta de StataNow en config.php (cambió la detección de Stata)")
open(p, 'w', encoding='utf-8', newline='').write(t2)
PYEOF

if curl -s -o /dev/null "http://localhost:$PUERTO/"; then
    echo "el puerto $PUERTO ya está ocupado (¿otro php -S?); usa --puerto N" >&2; exit 2
fi
( cd "$H/site" && exec env FAKE_H="$H" php -S "localhost:$PUERTO" > "$H/php.log" 2>&1 ) &
PHP_PID=$!
disown "$PHP_PID" 2>/dev/null || true
U="http://localhost:$PUERTO"
for _ in $(seq 1 30); do curl -s -o /dev/null "$U/health.php" && break; sleep 0.2; done
curl -s -o /dev/null "$U/health.php" || { echo "php -S no levantó en $PUERTO:"; cat "$H/php.log"; exit 2; }

fallos=0
chk() { # chk <codigo esperado> <descripcion> <args de curl...>
    local esp="$1" desc="$2"; shift 2
    local code
    code="$(curl -s -o "$H/body" -w '%{http_code}' "$@")"
    local r=OK; [[ "$code" == "$esp" ]] || { r=FALLO; fallos=$((fallos+1)); }
    printf '%-6s %-46s -> %s (esperado %s) | %s\n' "$r" "$desc" "$code" "$esp" "$(head -c 100 "$H/body" | tr -d '\n')"
}
aserta() { # aserta <condicion> <descripcion>
    if eval "$1"; then printf 'OK     %s\n' "$2"; else printf 'FALLO  %s\n' "$2"; fallos=$((fallos+1)); fi
}
corridas() { grep -c ' start ' "$H/fake-stata.log" 2>/dev/null || echo 0; }

echo "## calculaStata.php — payloads de inyección / traversal (v8.11a): todos 400, Stata no corre"
chk 400 "idSession=../ciepmx (traversal)"           -d 'idSession=../ciepmx' "$U/calculaStata.php"
chk 400 "idSession='0abc;rm -rf /'"                 -d 'idSession=0abc;rm -rf /' "$U/calculaStata.php"
chk 400 "INGRESOS0 con salto de línea + shell"      --data-urlencode idSession=0abcD --data-urlencode $'INGRESOS0=3.5\nshell rm -rf /' "$U/calculaStata.php"
chk 400 "moduloCambio con comillas/llaves/!"        --data-urlencode idSession=0abcD --data-urlencode $'moduloCambio=1" { } \n !id \n if "1' "$U/calculaStata.php"
chk 400 "CRECPIB2026=\`shell id\`"                  --data-urlencode idSession=0abcD --data-urlencode 'CRECPIB2026=`shell id`' "$U/calculaStata.php"
chk 400 "GET ISRTASA0=0x41 (hex no es numérico)"    "$U/calculaStata.php?idSession=0abcD&DEUDA0=10.8%25&ISRTASA0=0x41"
chk 400 "GET sin idSession"                         "$U/calculaStata.php"
aserta '[[ "$(corridas)" == "0" ]]' "Stata (falso) no corrió con ningún payload inválido ($(corridas) corridas)"
aserta '[[ ! -e "$H/ciepmx" && ! -d "$H/users/../ciepmx" ]]' "el traversal no creó directorios fuera de users/"

echo "## calculaStata.php — petición válida: 200, Stata corre una vez, .do limpio"
chk 200 "válida (INGRESOS0=3.5, IVAT0=16%, moduloCambio=1)" -d idSession=0abcD -d INGRESOS0=3.5 -d IVAT0=16% -d moduloCambio=1 "$U/calculaStata.php"
# shellcheck disable=SC2034  # DO se usa dentro de las condiciones de aserta (eval)
DO="$H/users/0abcD/0abcD.do"
aserta '[[ "$(corridas)" == "1" ]]' "Stata (falso) corrió exactamente 1 vez"
aserta '[[ -f "$DO" ]]' "se generó users/0abcD/0abcD.do"
aserta '! grep -qiE "^[[:space:]]*(shell|!)" "$DO"' ".do sin líneas shell/! (inyección)"
aserta 'grep -q "^scalar ISRASPIB *= 3.5" "$DO"' ".do: INGRESOS0 -> 'scalar ISRASPIB = 3.5'"
aserta 'grep -q "^matrix IVAT = (16 " "$DO"' ".do: IVAT0=16% -> 'matrix IVAT = (16' (el % se quita)"
aserta 'grep -q "^global id = \"0abcD\"" "$DO"' ".do: global id = \"0abcD\""
aserta '! grep -q "{{" "$DO"' ".do sin placeholders {{...}} sin sustituir"
aserta 'grep -q "\"idSession\":\"0abcD\"" "$H/body"' "la respuesta es el JSON de la corrida"

echo "## checkStataStatus.php"
chk 200 "idSession=0abcD"                           "$U/checkStataStatus.php?idSession=0abcD"
chk 400 "idSession=../../etc"                       "$U/checkStataStatus.php?idSession=../../etc"
chk 400 "sin idSession"                             "$U/checkStataStatus.php"

echo "## jsonSankey*.php (solo lectura: inválido cae al escenario default ciepmx)"
chk 200 "jsonSankey.php?idSession=ciepmx"           "$U/jsonSankey.php?idSession=ciepmx"
chk 200 "jsonSankey.php traversal con %00"          "$U/jsonSankey.php?idSession=../../../../etc/passwd%00"
aserta 'grep -q "ciepmx/sankey-decil.json" "$H/body"' "el traversal sirvió users/ciepmx/, no otra ruta"
chk 200 "jsonSankeyEscol.php?idSession=0noexiste"   "$U/jsonSankeyEscol.php?idSession=0noexiste"
chk 200 "jsonSankeyRural.php sin idSession"         "$U/jsonSankeyRural.php"

echo "## jsonSankeyNTA.php (/NTA: corte en lista blanca; idSession inválido cae al default ciepmx)"
chk 200 "jsonSankeyNTA.php?corte=grupoedad"         "$U/jsonSankeyNTA.php?corte=grupoedad"
aserta 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); assert d[\"links\"][0][\"value\"] == \"28803723154.81406\"" "$H/body"' "la respuesta es JSON válido y el valor viaja sin transformar"
chk 400 "jsonSankeyNTA.php?corte=../../etc/passwd"  "$U/jsonSankeyNTA.php?corte=../../etc/passwd"
chk 400 "jsonSankeyNTA.php?corte=grupoedad%00"       "$U/jsonSankeyNTA.php?corte=grupoedad%00"
chk 200 "jsonSankeyNTA.php traversal en idSession"   "$U/jsonSankeyNTA.php?corte=grupoedad&idSession=../../../../etc/passwd%00"
aserta 'grep -q "ciepmx/SankeyNTA/sankey-grupoedad.json" "$H/body"' "el traversal sirvió users/ciepmx/SankeyNTA/, no otra ruta"
chk 404 "jsonSankeyNTA.php?corte=sexo (sin archivo)"  "$U/jsonSankeyNTA.php?corte=sexo"
chk 200 "GET /NTA/ (página de método)"               "$U/NTA/"

echo "## cargaDefault.php (sin eval) y logCalcular.php (sin inyección de renglones)"
chk 200 "cargaDefault.php"                          "$U/cargaDefault.php"
aserta 'grep -q "\"INGRESOS\":\[3.855,0.244\]" "$H/body"' "cargaDefault parsea output.txt a JSON tipado"
chk 200 "cargaDefault.php?idSession=../x"           "$U/cargaDefault.php?idSession=../x"
chk 200 "logCalcular.php con salto de línea en sessionId" --data-urlencode $'sessionId=0abcD\n[FAKE] IP: 1.2.3.4 | Session: inyectada' --data-urlencode pageVersion=es "$U/logCalcular.php"
aserta '! grep -q "FAKE" "$H/site/logs/calcular_clicks.log" 2>/dev/null' "la bitácora no recibió el renglón inyectado"
aserta 'grep -q "Session: invalid" "$H/site/logs/calcular_clicks.log" 2>/dev/null' "la bitácora registró 'Session: invalid'"

echo
if (( fallos == 0 )); then
    echo "RESULTADO: harness de seguridad del sitio OK (0 fallos)"
    exit 0
fi
echo "RESULTADO: $fallos fallo(s) — las validaciones de v8.11a se regresaron o el sitio cambió de contrato"
exit 1
