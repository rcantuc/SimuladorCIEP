#!/bin/zsh
# Publica los productos de la corrida NL al Drive de CoNL. Solo entregables, nunca el motor.
#   nodos/   -> JSON de contratos (statajson_entidad-nl.json, poblacion-nl.json, actividad-nl.json),
#               logs de procedencia y los HTML autocontenidos (poblacion-nl.html, actividad-nl.html).
#   raíz     -> output.txt del contrato web (si existe) y una copia de cada HTML para abrirlos con
#               doble clic sin entrar a nodos/.
# COMPUERTA DE PUBLICACIÓN (NL-0.3.1): antes de copiar nada, cada HTML debe (a) no conservar ninguna
# marca de inyección /*__NL..__*/, (b) traer el componente nl-datos.js y (c) traer el bloque
# <script type="application/json" id="nl-data"> con JSON válido y procedencia. Si falla, se aborta
# sin tocar el Drive: lo vigente ahí se conserva. Un artefacto fallido nunca vuelve a cruzar.
set -u
ORIGEN="$HOME/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo"
DESTINO="/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL"
HTMLS=(poblacion-nl.html actividad-nl.html)

verificar_html() {
  local f="$1"
  [[ -s "$f" ]] || { echo "COMPUERTA: no existe o está vacío $f"; return 1; }
  if grep -q -E '/\*__NL[A-Z_]*__\*/' "$f"; then echo "COMPUERTA: $f conserva una marca de inyección sin reemplazar (es la plantilla, no el endpoint)"; return 1; fi
  grep -q 'window.NLDatos = (function' "$f" || { echo "COMPUERTA: $f no trae el componente nl-datos.js"; return 1; }
  python3 - "$f" <<'PY' || return 1
import re, sys, json
h = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'<script type="application/json" id="nl-data">(.*?)</script>', h, re.S)
if not m: sys.exit("COMPUERTA: %s sin bloque <script type=application/json id=nl-data>" % sys.argv[1])
try:
    j = json.loads(m.group(1))
except Exception as e:
    sys.exit("COMPUERTA: %s con JSON inválido en nl-data: %s" % (sys.argv[1], e))
if not isinstance(j, dict) or "procedencia" not in j or not j["procedencia"].get("generado_en"):
    sys.exit("COMPUERTA: %s con JSON sin procedencia.generado_en" % sys.argv[1])
print("  compuerta OK: %s (%d bytes de JSON, corrida %s, capa %s)" % (sys.argv[1].split('/')[-1], len(m.group(1)), j["procedencia"]["generado_en"], j["procedencia"].get("version_capa_nl", "?")))
PY
}

[[ -d "${DESTINO:h}" ]] || { echo "publicar-conl: no existe ${DESTINO:h} (¿Drive de CoNL montado?)"; exit 1; }
echo "Compuerta de publicación:"
for h in "${HTMLS[@]}"; do
  verificar_html "$ORIGEN/nodos/$h" || { echo "publicar-conl: ABORTA sin publicar; el Drive conserva lo vigente."; exit 2; }
done
mkdir -p "$DESTINO/nodos"
rsync -av --delete "$ORIGEN/nodos/" "$DESTINO/nodos/"
for f in output.txt procedencia.log; do
  [[ -f "$ORIGEN/$f" ]] && rsync -av "$ORIGEN/$f" "$DESTINO/"
done
for h in "${HTMLS[@]}"; do
  rsync -av "$ORIGEN/nodos/$h" "$DESTINO/$h"
done
echo "Publicado a CoNL: $(date)"
ls -la "$DESTINO" "$DESTINO/nodos"
