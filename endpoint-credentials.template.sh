#!/usr/bin/env bash
# endpoint-credentials.template.sh — PLANTILLA con placeholders.
#
# Copia este archivo como endpoint-credentials.sh (gitignored) y rellena con
# valores reales. El script publicar-endpoint.sh hace `source` de
# endpoint-credentials.sh al inicio.
#
# IMPORTANTE: NUNCA reemplaces los valores en esta plantilla. La plantilla vive
# en Git como referencia; los valores reales viven en endpoint-credentials.sh
# (gitignored).

# Alias SSH (configurado en ~/.ssh/config local)
export SSH_ALIAS=""

# Path absoluto del directorio del endpoint en el servidor
export REMOTE_PATH=""

# URL pública del endpoint (para verificación post-deploy)
export ENDPOINT_URL=""

# Path absoluto a la Carpeta del Simulador para investigadores (OPCIONAL).
#
# Si NO se define, publicar.sh auto-detecta probando ubicaciones típicas:
#   - $HOME/Library/CloudStorage/Dropbox-CIEP/SimuladorCIEP  (Mac moderno)
#   - $HOME/Dropbox-CIEP/SimuladorCIEP                       (Linux / Mac clásico)
#
# Solo descomenta y rellena esta variable si tu Dropbox está en path
# no-estándar o tienes múltiples instancias de SimuladorCIEP en disco.
# export CARPETA_INVESTIGADORES_PATH=""
