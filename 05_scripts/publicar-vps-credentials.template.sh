#!/usr/bin/env bash
# Plantilla de credenciales para publicar-vps.sh
# Copia este archivo como publicar-vps-credentials.sh (sin .template) y
# rellena con tus valores reales. El archivo real está gitignored.

# Usuario SSH del VPS
export VPS_USER="ciepmx"

# Host o IP del VPS
export VPS_HOST="66.179.250.191"

# Path base del sitio en el VPS (sin trailing slash)
export VPS_HTML_ROOT="/var/www/html"

# Path base del canon Stata en el VPS (sin trailing slash)
export VPS_SIM_ROOT="/SIM/OUT"

# URL del health check para verificación post-deploy
export VPS_HEALTH_URL="https://simuladorfiscal.ciep.mx/health.php"

# Path absoluto en la Mac de Ricardo al clon local del sitio
# (fuente de verdad para el rsync del PHP)
export LOCAL_SITE_ROOT="/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/04_simuladorfiscal.ciep.mx"

# Path absoluto al repo del Simulador (para localizar .ado y master/)
export LOCAL_REPO_ROOT="/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP"

# Directorio raíz de backups del VPS (Dropbox u otro storage local)
# Lo usa backup-vps.sh (Fase 0 del deploy y modo standalone)
# PRECAUCIÓN: si el path tiene espacios, no quitar las comillas
export BACKUP_ROOT="/ruta/a/tu/carpeta/de/backups"

# Path a las llaves SSH si aplica (opcional)
# export SSH_KEY_PATH="$HOME/.ssh/ionos_ciepmx"
