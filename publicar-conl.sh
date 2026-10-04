#!/bin/zsh
# Publica los productos de la corrida NL al Drive de CoNL. Solo entregables, nunca el motor.
#   nodos/   -> JSON de contratos (statajson_entidad-nl.json, poblacion-nl.json, actividad-nl.json),
#               logs de procedencia y los HTML autocontenidos (poblacion-nl.html, actividad-nl.html).
#   raíz     -> output.txt del contrato web (si existe) y una copia de cada HTML para abrirlos con
#               doble clic sin entrar a nodos/ (capa NL-0.2.0).
set -u
ORIGEN="$HOME/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo"
DESTINO="/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL"
[[ -d "${DESTINO:h}" ]] || { echo "publicar-conl: no existe ${DESTINO:h} (¿Drive de CoNL montado?)"; exit 1; }
mkdir -p "$DESTINO/nodos"
rsync -av --delete "$ORIGEN/nodos/" "$DESTINO/nodos/"
for f in output.txt procedencia.log; do
  [[ -f "$ORIGEN/$f" ]] && rsync -av "$ORIGEN/$f" "$DESTINO/"
done
for h in poblacion-nl.html actividad-nl.html; do
  [[ -f "$ORIGEN/nodos/$h" ]] && rsync -av "$ORIGEN/nodos/$h" "$DESTINO/$h"
done
echo "Publicado a CoNL: $(date)"
ls -la "$DESTINO" "$DESTINO/nodos"
