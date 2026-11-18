#!/usr/bin/env bash
# Plantilla de credenciales para publicar-vps.sh — PLANTILLA con marcadores.
# Copia este archivo como publicar-vps-credentials.sh (sin .template) y
# sustituye cada <MARCADOR> por tu valor real. El archivo real está gitignored.
#
# IMPORTANTE: NUNCA escribas valores reales en esta plantilla. Vive en Git, en
# un repositorio público; los valores reales viven solo en
# publicar-vps-credentials.sh.

# Usuario SSH del VPS
export VPS_USER="<USUARIO>"

# Host o IP del VPS
export VPS_HOST="<IP_VPS>"

# Path base del sitio en el VPS (sin trailing slash)
export VPS_HTML_ROOT="/var/www/html"

# Path base del canon Stata en el VPS (sin trailing slash)
export VPS_SIM_ROOT="/SIM/OUT"

# URL del health check para verificación post-deploy
export VPS_HEALTH_URL="https://simuladorfiscal.ciep.mx/health.php"

# Path absoluto, en tu máquina, al clon local del sitio
# (fuente de verdad para el rsync del PHP). Carpeta renombrada de
# 04_simuladorfiscal.ciep.mx a 04_1_simuladorfiscal.ciep.mx el 2026-09-08:
# si tu publicar-vps-credentials.sh es anterior, actualiza esta línea (el
# Gate 5 de publicar-vps.sh aborta si la carpeta no existe).
export LOCAL_SITE_ROOT="<RUTA_AL_REPO>/04_1_simuladorfiscal.ciep.mx"

# Path absoluto al repo del Simulador (para localizar .ado y master/)
export LOCAL_REPO_ROOT="<RUTA_AL_REPO>"

# Directorio raíz de backups del VPS (Dropbox u otro storage local)
# Lo usa backup-vps.sh (Fase 0 del deploy y modo standalone)
# PRECAUCIÓN: si el path tiene espacios, no quitar las comillas
export BACKUP_ROOT="/ruta/a/tu/carpeta/de/backups"

# Path a las llaves SSH si aplica (opcional)
# export SSH_KEY_PATH="$HOME/.ssh/<LLAVE_SSH>"
