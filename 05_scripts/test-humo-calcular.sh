#!/usr/bin/env bash
# =============================================================================
# test-humo-calcular.sh — rojo/verde de humo-calcular.sh con php -S + Stata falso
# =============================================================================
# Sin Stata, sin red: corre en GitHub Actions (job sitio-seguridad). Monta una copia
# del sitio como test-sitio-seguridad.sh (Stata falso en vez del real) y prueba que
# humo-calcular.sh:
#   VERDE  acepta un «Calcular» que deja output.txt con números y los 5 sankeys de
#          la sesión (el Stata falso copia un output.txt y 5 sankeys de forma real);
#   ROJO 1 rechaza un motor que aborta sin output.txt (el incidente v8.12: r(601) del
#          candado del cache -> calculaStata.php responde sin números);
#   ROJO 2 rechaza un motor que deja output.txt pero ningún sankey (jsonSankey.php
#          cae al default ciepmx y el humo lo detecta por "nombre").
# Uso: bash 05_scripts/test-humo-calcular.sh [--puerto N] [--conservar]
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$REPO_ROOT/04_1_simuladorfiscal.ciep.mx"
PUERTO=8473; CONSERVAR=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --puerto) PUERTO="$2"; shift 2 ;;
        --conservar) CONSERVAR=true; shift ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
command -v php >/dev/null || { echo "falta php" >&2; exit 2; }
command -v curl >/dev/null || { echo "falta curl" >&2; exit 2; }

H="$(mktemp -d -t humo-calc-XXXXXX)"
PHP_PID=""
limpiar() {
    if [[ -n "$PHP_PID" ]]; then kill "$PHP_PID" 2>/dev/null; wait "$PHP_PID" 2>/dev/null; fi
    if $CONSERVAR; then echo "(copia conservada en $H)"; else rm -rf "$H"; fi
}
trap limpiar EXIT

mkdir -p "$H/users/ciepmx" "$H/canned"
cp -R "$SITE" "$H/site"
rm -rf "$H/site/logs" "$H/site/ssl"; mkdir -p "$H/site/logs"
cp "$REPO_ROOT/01_modulos/Web.Stata.do" "$H/Web.Stata.do"

# output.txt y sankeys "de forma real": las llaves que el JS llena (cargaDefault) y los 5 cortes
python3 - "$H/canned" <<'PYEOF'
import os, sys
d = sys.argv[1]
filas = {
    'INGRESOS': [3.855, 0.244, 3.556, 0, 0.628, 0.149, 0, 0.871, 0.183, 2.306, 0.049, 0.339, 0, 0.133, 0.512, 0.0, 0.0, 0.0],
    'GASTOS': [0.0, 2.08, 0.6, 0.6, 0.5, 0.1, 0.1, 0.1, 0.1, 0.3, 0.3, 1.0, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
    'GASTOSPC': [0.0] * 42,
    'CRECPIB': [1.4, 2.0, 2.4, 2.5, 2.5, 2.5, 2.5], 'CRECDEF': [3.8, 4.0, 3.5, 3.0, 3.0, 3.0, 3.0],
    'DEUDAPARAM': [52.3, 2.0], 'ISRSUBS': [0] * 11, 'ISRDEDU': [0, 0, 0, 0], 'ISRMORA': [0, 0],
    'CSSIMSS': [0] * 21, 'CSSISSSTE': [0] * 24, 'IVA': [16, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8],
    'PIBY': [39415135710357.34], 'INCD': [96677, 168553],
}
with open(os.path.join(d, 'output.txt'), 'w') as f:
    f.write('.quietlylogoffoutput\n')
    for k, v in filas.items():
        f.write('%s: [%s]\n' % (k, ', '.join(str(x) for x in v)))
for c in ('decil', 'escol', 'grupoedad', 'rural', 'sexo'):
    with open(os.path.join(d, 'sankey-%s.json' % c), 'w') as f:
        f.write('{"chart":{"caption":" "},\nnodes:[{label:"I"},{label:"Imp al trabajo"}],\nlinks:[{to:"Imp al trabajo",value:"49197860719.77805",from:"I"}]};\n')
PYEOF
cp "$H/canned/output.txt" "$H/users/ciepmx/output.txt"
cp "$H/canned/"sankey-*.json "$H/users/ciepmx/"

# Stata falso con tres modos (archivo $H/modo): verde | sin-output | sin-sankeys
cat > "$H/fake-stata" <<'EOF'
#!/usr/bin/env bash
H="$FAKE_H"; ID="$(basename "$PWD")"; MODO="$(cat "$H/modo")"
echo "$(date +%H:%M:%S) start id=$ID modo=$MODO" >> "$H/fake-stata.log"
sleep 2
case "$MODO" in
    verde)       cp "$H/canned/output.txt" ./output.txt; cp "$H/canned/"sankey-*.json . ;;
    sin-output)  echo "r(601);" > "./$ID.log" ;;                      # el candado del cache abortó: nada de output.txt
    sin-sankeys) cp "$H/canned/output.txt" ./output.txt ;;
esac
EOF
chmod +x "$H/fake-stata"
python3 - "$H/site/config.php" "$H/fake-stata" <<'PYEOF'
import re, sys
p, fake = sys.argv[1], sys.argv[2]
t = open(p, encoding='utf-8', newline='').read()
t2 = re.sub(r"/Applications/StataNow/StataSE\.app/Contents/MacOS/stata-se", fake, t)
if t2 == t:
    sys.exit("test-humo-calcular: no se encontró la ruta de StataNow en config.php (cambió la detección de Stata)")
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
caso() { # caso <modo> <rc esperado> <descripción> [texto que debe aparecer]
    local modo="$1" esp="$2" desc="$3" debe="${4:-}" rc salida
    echo "$modo" > "$H/modo"
    salida="$(bash "$REPO_ROOT/05_scripts/humo-calcular.sh" "$U" --timeout 60 --id "h${modo//-/}$$" --evidencia "$H/evid-$modo" 2>&1)"; rc=$?
    local r=OK; [[ $rc -eq $esp ]] || { r=FALLO; fallos=$((fallos+1)); }
    if [[ -n "$debe" && "$salida" != *"$debe"* ]]; then r=FALLO; fallos=$((fallos+1)); fi
    printf '%-6s %-58s -> rc=%s (esperado %s)\n' "$r" "$desc" "$rc" "$esp"
    printf '%s\n' "$salida" | sed 's/^/         /' | grep -E "VERDE|ROJO|FALLO|- " | head -6
}
echo "== humo-calcular.sh contra php -S ($U) + Stata falso"
caso verde       0 "VERDE: output.txt con números + 5 sankeys de la sesión" "VERDE"
caso sin-output  1 "ROJO 1: el motor aborta sin output.txt (incidente v8.12, r(601))" "no trae los numeros"
caso sin-sankeys 1 "ROJO 2: output.txt sí, sankeys no (jsonSankey cae a ciepmx)" "cayó al default ciepmx"
aserta_corridas="$(grep -c ' start ' "$H/fake-stata.log")"
[[ "$aserta_corridas" == "3" ]] && printf 'OK     Stata falso corrió 3 veces (una por caso)\n' || { printf 'FALLO  Stata falso corrió %s veces (esperaba 3)\n' "$aserta_corridas"; fallos=$((fallos+1)); }

if [[ $fallos -eq 0 ]]; then echo "RESULTADO: humo-calcular.sh distingue verde de rojo (0 fallos)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en el rojo/verde de humo-calcular.sh"; exit 1
