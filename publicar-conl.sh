#!/bin/zsh
# Publica los productos de la corrida NL al Drive de CoNL. Solo entregables, nunca el motor.
ORIGEN="$HOME/CIEP_Simuladores/SimuladorCIEP-NL/users/ricardo"
DESTINO="/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL"
rsync -av --delete "$ORIGEN/nodos/" "$DESTINO/nodos/"
rsync -av "$ORIGEN/output.txt" "$ORIGEN/procedencia.log" "$DESTINO/" 2>/dev/null
echo "Publicado a CoNL: $(date)"
