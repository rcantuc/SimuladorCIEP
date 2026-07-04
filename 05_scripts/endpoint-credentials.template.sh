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

