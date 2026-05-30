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
# Si NO se define, publicar.sh auto-detecta Dropbox-CIEP/SimuladorCIEP dentro
# de $HOME (busca recursivamente hasta 6 niveles de profundidad). El sufijo
# "Dropbox-CIEP/SimuladorCIEP" es estable; lo que varía entre usuarios/sistemas
# es el path raíz (Mac usa Library/CloudStorage/, Linux usa directamente $HOME/,
# Windows con WSL puede tener variaciones).
#
# Solo descomenta y rellena esta variable si necesitas override
# (e.g., Dropbox sincronizado en path no-estándar, o múltiples instancias
# de SimuladorCIEP en disco).
# export CARPETA_INVESTIGADORES_PATH=""
