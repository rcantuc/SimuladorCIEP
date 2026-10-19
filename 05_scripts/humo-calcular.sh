#!/usr/bin/env bash
# =============================================================================
# humo-calcular.sh — el «Calcular» de humo, como lo dispara el sitio (v8.12.1)
# =============================================================================
# Reproduce el clic «Calcular» del escenario default contra un sitio servido y
# exige que el run interactivo termine con números y con sankeys de la sesión:
#
#   1. GET  cargaDefault.php            -> escenario default ({NOMBRE: [valores]})
#   2.      perfilar-web.py escenario   -> los campos del formulario, con el mismo
#                                          mapeo que stataCalcula.js
#   3. POST calculaStata.php            -> como el JS: síncrono (Stata corre dentro
#                                          de la petición); mientras, se sondea
#                                          checkStataStatus.php como señal de vida
#   4.      output.txt de la sesión     -> el JSON de respuesta trae INGRESOS, GASTOS,
#                                          PIBY… (del output.txt); vacío = fallo
#   5. GET  jsonSankey*.php?idSession   -> los 5 cortes responden 200 con nodes/links
#                                          y "nombre" apunta a users/<idSession>/
#                                          (no al fallback users/ciepmx/)
#
# Lo llama publicar-vps.sh en la Fase 6 (tras el swap y la espera del caché de
# realpath de PHP); si falla, publicar-vps.sh hace rollback. También corre a mano:
#   bash 05_scripts/humo-calcular.sh https://simuladorfiscal.ciep.mx [--timeout 120] [--evidencia <dir>]
#   bash 05_scripts/humo-calcular.sh http://localhost:8123                     (harness local)
# Salida: 0 = humo verde; 1 = algún aserto falló (imprime el motivo y la cola del
# log de la sesión que devuelva checkStataStatus.php); 2 = uso.
# Incidente que lo motiva (2026-10-18): el deploy v8.12 pasó health check y
# esqueleto del sitio, pero «Calcular» abortaba con r(601) (05_scripts/manifest.json
# no embarcado). Segundo deploy consecutivo que rompe el run interactivo y solo lo
# cacha un clic humano: desde v8.12.1 el clic lo da este script.
# =============================================================================
set -uo pipefail

BASE=""; TIMEOUT=120; EVID=""; ID=""; CORTES="decil escol grupoedad rural sexo"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --evidencia) EVID="$2"; shift 2 ;;
        --id) ID="$2"; shift 2 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 2 ;;
        *) if [[ -z "$BASE" ]]; then BASE="${1%/}"; shift; else echo "argumento inesperado: $1" >&2; exit 2; fi ;;
    esac
done
[[ -n "$BASE" ]] || { echo "Uso: $0 <https://sitio> [--timeout SEG] [--evidencia DIR] [--id IDSESSION]" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
[[ -n "$ID" ]] || ID="humo$(date +%Y%m%d%H%M%S)"
[[ "$ID" =~ ^[A-Za-z0-9]+$ ]] || { echo "idSession debe ser alfanumérico: $ID" >&2; exit 2; }
W="$(mktemp -d /tmp/humo-calcular.XXXXXX)"
[[ -n "$EVID" ]] && { mkdir -p "$EVID"; W="$EVID"; }
FALLAS=()
log() { printf '%s humo-calcular: %s\n' "$(date +%H:%M:%S)" "$*"; }
falla() { FALLAS+=("$*"); log "FALLO: $*"; }
t0=$(date +%s)

# --- 1. escenario default, como lo sirve el sitio -------------------------------------------
code=$(curl -sL -o "$W/cargaDefault.json" -w '%{http_code}' --max-time 30 "$BASE/cargaDefault.php" || echo 000)
if [[ "$code" != "200" ]] || ! python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert isinstance(d,dict) and "INGRESOS" in d' "$W/cargaDefault.json" 2>/dev/null; then
    falla "cargaDefault.php -> HTTP $code o sin la llave INGRESOS (el escenario default no se sirve)"
    printf '%s\n' "${FALLAS[@]}"; exit 1
fi
if ! python3 "$HERE/perfilar-web.py" escenario "$W/cargaDefault.json" > "$W/escenario.json" 2> "$W/escenario.err"; then
    falla "no se pudo armar el escenario default desde cargaDefault.php: $(cat "$W/escenario.err")"
    printf '%s\n' "${FALLAS[@]}"; exit 1
fi
NCAMPOS=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$W/escenario.json")
log "escenario default armado desde $BASE/cargaDefault.php ($NCAMPOS campos); idSession=$ID"

# --- 2. POST calculaStata.php (síncrono, como el JS) + sondeo de checkStataStatus.php -----------
ARGS=()
while IFS=$'\t' read -r k v; do ARGS+=(--data-urlencode "$k=$v"); done < <(python3 -c '
import json,sys
for k,v in sorted(json.load(open(sys.argv[1])).items()): print(k+"\t"+str(v))' "$W/escenario.json")
ARGS+=(--data-urlencode "idSession=$ID")
tpost=$(date +%s)
curl -s -o "$W/calculaStata.json" -D "$W/calculaStata.hdr" -w '%{http_code}' --max-time "$TIMEOUT" "${ARGS[@]}" "$BASE/calculaStata.php" > "$W/calculaStata.code" 2>/dev/null &
PID_CURL=$!
VIVO=""; SONDEOS=0
while kill -0 "$PID_CURL" 2>/dev/null; do
    sleep 3
    SONDEOS=$((SONDEOS + 1))
    st=$(curl -s --max-time 10 "$BASE/checkStataStatus.php?idSession=$ID" 2>/dev/null || true)
    echo "$(date +%H:%M:%S) $st" >> "$W/checkStataStatus.log"
    [[ "$st" == *'"process_alive":true'* ]] && VIVO="sí"
done
wait "$PID_CURL" 2>/dev/null || true
code=$(cat "$W/calculaStata.code" 2>/dev/null || echo 000)
tfin=$(date +%s)
log "calculaStata.php -> HTTP $code en $((tfin - tpost)) s ($SONDEOS sondeos a checkStataStatus.php; Stata visto vivo: ${VIVO:-no})"
if [[ "$code" != "200" ]]; then
    falla "calculaStata.php respondió HTTP $code (000 = timeout de $TIMEOUT s o sin conexión). Cuerpo: $(head -c 400 "$W/calculaStata.json" 2>/dev/null)"
fi

# --- 3. el output.txt de la sesión, vía la respuesta (es lo que pinta el sitio) -------------------
python3 - "$W/calculaStata.json" > "$W/resultado.txt" 2>&1 <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception as e:
    sys.exit('la respuesta no es JSON: %s' % e)
if d.get('status') == 'error' or 'error' in d:
    sys.exit('el sitio devolvió error: %s' % (d.get('error') or d))
claves = [k for k in ('INGRESOS', 'GASTOS', 'PIBY', 'DEUDAPARAM', 'CRECPIB') if isinstance(d.get(k), list) and len(d[k]) > 0]
if len(claves) < 3:
    sys.exit('la respuesta no trae los numeros del output.txt (llaves con lista: %s). Llaves: %s' % (claves, sorted(d)[:12]))
nums = sum(1 for k, v in d.items() if isinstance(v, list))
print('OK output.txt de la sesion con contenido: %d llaves-lista, p. ej. INGRESOS[0]=%s PIBY=%s' % (nums, d['INGRESOS'][0], d.get('PIBY')))
PYEOF
if [[ $? -eq 0 ]]; then log "$(cat "$W/resultado.txt")"; else falla "$(cat "$W/resultado.txt")"; fi

# --- 4. los 5 sankeys de ESA sesión (no el fallback ciepmx) ---------------------------------------
for c in $CORTES; do
    case "$c" in decil) php="jsonSankey.php" ;; escol) php="jsonSankeyEscol.php" ;; grupoedad) php="jsonSankeyGrupoedad.php" ;; rural) php="jsonSankeyRural.php" ;; sexo) php="jsonSankeySexo.php" ;; esac
    code=$(curl -s -o "$W/sankey-$c.json" -w '%{http_code}' --max-time 30 --data-urlencode "idSession=$ID" "$BASE/$php" 2>/dev/null || echo 000)
    if [[ "$code" != "200" ]]; then falla "$php -> HTTP $code"; continue; fi
    if ! grep -q '"nodes"' "$W/sankey-$c.json" || ! grep -q '"links"' "$W/sankey-$c.json"; then falla "$php sin nodes/links"; continue; fi
    if ! grep -q "/users/$ID/sankey-$c.json" "$W/sankey-$c.json"; then
        falla "$php no sirvió el sankey de la sesión $ID (nombre: $(grep -o '"nombre":"[^"]*"' "$W/sankey-$c.json" | head -1)); la sesión no produjo sankey-$c.json y el PHP cayó al default ciepmx"
    fi
done
(( ${#FALLAS[@]} == 0 )) && log "5/5 sankeys de la sesión $ID responden 200 con nodes/links"

# --- 5. veredicto ---------------------------------------------------------------------------------
t1=$(date +%s)
if (( ${#FALLAS[@]} == 0 )); then
    log "VERDE: «Calcular» de humo completo en $((t1 - t0)) s (Stata $((tfin - tpost)) s). Evidencia: $W"
    exit 0
fi
log "ROJO: ${#FALLAS[@]} fallo(s) en $((t1 - t0)) s:"
for f in "${FALLAS[@]}"; do echo "  - $f"; done
# cola del log de la sesión, si checkStataStatus.php lo devolvió (lo hace cuando falta output.txt)
if [[ -s "$W/checkStataStatus.log" ]]; then
    python3 - "$W/checkStataStatus.log" <<'PYEOF'
import json, sys
ult = None
for linea in open(sys.argv[1], encoding='utf-8', errors='replace'):
    try: ult = json.loads(linea.split(' ', 1)[1])
    except Exception: pass
if ult:
    print('  último checkStataStatus.php:', {k: v for k, v in ult.items() if k != 'log'})
    if ult.get('log'):
        print('  --- cola del log de la sesión ---')
        print('\n'.join('  ' + l for l in ult['log'].splitlines()[-25:]))
PYEOF
fi
echo "  evidencia: $W"
exit 1
