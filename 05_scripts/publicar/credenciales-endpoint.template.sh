#!/usr/bin/env bash
# credenciales-endpoint.template.sh — PLANTILLA con placeholders.
#
# Copia este archivo como credenciales-endpoint.sh (gitignored) y rellena con
# valores reales. El script publicar-endpoint.sh hace `source` de
# credenciales-endpoint.sh al inicio.
#
# IMPORTANTE: NUNCA reemplaces los valores en esta plantilla. La plantilla vive
# en Git como referencia; los valores reales viven en credenciales-endpoint.sh
# (gitignored).

# Alias SSH (configurado en ~/.ssh/config local)
export SSH_ALIAS=""

# Path absoluto del directorio del endpoint en el servidor
export REMOTE_PATH=""

# URL pública del endpoint (para verificación post-deploy)
export ENDPOINT_URL=""

