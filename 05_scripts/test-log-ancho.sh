#!/usr/bin/env bash
# test-log-ancho.sh — el log del motor se lee en una terminal de 110 columnas (sesión log-legible, 2026-11-09).
#
# Falla si alguna línea del wrap.log de correr-sim.sh supera 110 CARACTERES (no bytes: los acentos y «Σ» cuentan uno) o si
# contiene una continuación de Stata («> » al inicio: una línea que no cupo en linesize y se partió). Cuenta también las
# líneas vacías consecutivas (> 2) como aviso, no como falla.
#
# Exentas, declaradas: las líneas del contrato output.txt que Simulador.ado, FiscalGap.ado y output.do imprimen con
# `log on output` (47 llaves: `LLAVE: [ … ]`, p. ej. INCD, APORTHIV, GASTOS, PROYLABOR) y sus continuaciones «> » (GASTOS y
# GASTOSPC rebasan los 255 de linesize). Su forma la fija cargaDefault.php (unión de continuaciones) y gate-numeros.sh las
# vigila byte a byte: no son parte del log legible. Nada más queda exento.
#
# Uso: bash 05_scripts/test-log-ancho.sh <wrap.log> [--max 110] [--mostrar 20]
#      Exit 0 = VERDE; 1 = ROJO (imprime las primeras líneas que fallan, con número de línea y ancho); 2 = falta el archivo.
set -uo pipefail
LOG="${1:-}"; MAX=110; MOSTRAR=20
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max) MAX="$2"; shift 2 ;;
        --mostrar) MOSTRAR="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
    esac
done
[[ -n "$LOG" && -f "$LOG" ]] || { echo "test-log-ancho: falta el log (uso: $0 <wrap.log>)" >&2; exit 2; }
python3 -I - "$LOG" "$MAX" "$MOSTRAR" <<'PY'
import re, sys
log, mx, mostrar = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
llave = re.compile(r'^[A-Z][A-Z0-9]*: \[')
anchas, cont, exentas, vacias, maxvac, n, eco = [], [], 0, 0, 0, 0, 0
en_llave = False
with open(log, encoding='utf-8', errors='replace') as f:
    for i, raw in enumerate(f, 1):
        n += 1
        l = raw.rstrip('\n')
        if l.strip() == '':
            vacias += 1; maxvac = max(maxvac, vacias); continue
        vacias = 0
        if llave.match(l):
            en_llave = True; exentas += 1; continue
        if l.startswith(('. do ', '. run ')):
            # eco del lanzador (Stata lo escribe antes de `set linesize`, partido a 80): no es salida del motor
            en_llave = True; eco += 1; continue
        if l.startswith('> '):
            if en_llave: exentas += 1; continue
            cont.append((i, len(l), l))
            continue
        en_llave = False
        if len(l) > mx:
            anchas.append((i, len(l), l))
print(f'test-log-ancho: {n} líneas; exentas (contrato output.txt): {exentas}; eco del lanzador: {eco}; máximo de vacías seguidas: {maxvac}')
for k, v, l in anchas[:mostrar]:
    print(f'ROJO   línea {k}: {v} caracteres: {l[:90]}…')
for k, v, l in cont[:mostrar]:
    print(f'ROJO   línea {k}: continuación «> » de Stata: {l[:90]}…')
if anchas or cont:
    print(f'RESULTADO: test-log-ancho ROJO ({len(anchas)} línea(s) > {mx} columnas; {len(cont)} continuación(es) «> »)')
    sys.exit(1)
print(f'RESULTADO: test-log-ancho VERDE (ninguna línea > {mx} columnas; sin continuaciones «> »)')
PY
