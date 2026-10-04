#!/bin/zsh
# Publica los productos de la corrida NL al Drive de CoNL. Solo entregables, nunca el motor.
#   nodos/   -> JSON de contratos (statajson_entidad-nl.json, poblacion-nl.json), logs de procedencia
#               y el HTML autocontenido de Población (poblacion-nl.html).
#   raíz     -> output.txt del contrato web (si existe) y una copia de poblacion-nl.html para
#               abrirla con doble clic sin entrar a nodos/ (F2, capa NL-0.1.0).
set -u
ORIGEN="$HOME/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo"
DESTINO="/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL"
[[ -d "${DESTINO:h}" ]] || { echo "publicar-conl: no existe ${DESTINO:h} (¿Drive de CoNL montado?)"; exit 1; }
mkdir -p "$DESTINO/nodos"
rsync -av --delete "$ORIGEN/nodos/" "$DESTINO/nodos/"
for f in output.txt procedencia.log; do
  [[ -f "$ORIGEN/$f" ]] && rsync -av "$ORIGEN/$f" "$DESTINO/"
done
if [[ -f "$ORIGEN/nodos/poblacion-nl.html" ]]; then
  rsync -av "$ORIGEN/nodos/poblacion-nl.html" "$DESTINO/poblacion-nl.html"
fi
echo "Publicado a CoNL: $(date)"
ls -la "$DESTINO" "$DESTINO/nodos"
