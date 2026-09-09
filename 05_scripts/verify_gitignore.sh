#!/bin/bash
# =============================================================================
# 05_scripts/verify_gitignore.sh
# =============================================================================
# Verificación obligatoria del .gitignore antes de cualquier merge a master
# que modifique reglas de ignorado.
#
# Define un conjunto de referencia de paths que DEBEN y NO deben estar ignorados, y
# reporta divergencia. Justificación e historial de la regla: ver
#   02_governance/versionado-y-git.md §6 (Parte I)
#
# USO:
#   bash 05_scripts/verify_gitignore.sh
#
# EXIT CODES:
#   0 — todos los casos pasan; .gitignore es seguro de mergear.
#   1 — uno o más casos fallan; NO mergear hasta corregir.
#   2 — error de invocación (no estás en raíz del repo, etc.)
#
# AÑADIR CASOS NUEVOS:
#   Cuando se añada una regla al .gitignore, añadir al menos un assert_ignored
#   y al menos un assert_not_ignored relacionados, en la sección correspondiente.
#
# CASOS YA TRACKED (excepción documentada):
#   `git check-ignore` sin --no-index no reporta archivos ya tracked como
#   ignorados (las reglas de gitignore sólo aplican a untracked). El script
#   no marca esto como FAIL; se documenta donde aplica (e.g. raw/* legacy).
# =============================================================================

set -u

# --- Verificar que estamos en raíz del repo ---
if [ ! -f ".gitignore" ] || [ ! -d ".git" ]; then
    echo "ERROR: este script debe correrse desde la raíz del repositorio." >&2
    echo "       cd a la raíz y ejecuta: bash 05_scripts/verify_gitignore.sh" >&2
    exit 2
fi

# --- Contadores ---
passed=0
failed=0
total=0
fail_log=""

# --- Helpers ---
assert_ignored() {
    local path="$1"
    local description="$2"
    total=$((total+1))
    if git check-ignore -q "$path" 2>/dev/null; then
        printf "  [OK ignored] %-58s — %s\n" "$path" "$description"
        passed=$((passed+1))
    else
        printf "  [FAIL]       %-58s — DEBE estar ignorado: %s\n" "$path" "$description"
        failed=$((failed+1))
        fail_log+="    - $path: $description"$'\n'
    fi
}

assert_not_ignored() {
    local path="$1"
    local description="$2"
    total=$((total+1))
    if git check-ignore -q "$path" 2>/dev/null; then
        printf "  [FAIL]       %-58s — NO debe estar ignorado: %s\n" "$path" "$description"
        failed=$((failed+1))
        fail_log+="    - $path: $description"$'\n'
    else
        printf "  [OK passed]  %-58s — %s\n" "$path" "$description"
        passed=$((passed+1))
    fi
}

# =============================================================================
# 1. CASOS POSITIVOS — paths que DEBEN estar ignorados
# =============================================================================
echo "=========================================================="
echo "1. Paths que DEBEN estar ignorados"
echo "=========================================================="

echo "--- macOS ---"
assert_ignored ".DS_Store" "macOS metadata raíz"
assert_ignored "03_help/.DS_Store" "macOS metadata subdir"
assert_ignored "raw/LIFs/.DS_Store" "macOS metadata profundo"

echo "--- Windows ---"
assert_ignored "Thumbs.db" "Windows thumbnail"
assert_ignored "subdir/Desktop.ini" "Windows folder config"

echo "--- Stata ---"
assert_ignored "test.smcl" "Stata SMCL log"
assert_ignored "test.log" "Stata plain log"
assert_ignored "test.stswp" "Stata swap"
assert_ignored "test.stbak" "Stata backup"
assert_ignored "test.stsem" "Stata semaphore"
assert_ignored "hs_err_pid12345.log" "Stata crash log"
assert_not_ignored "simulador.stpr" "Proyecto del Project Manager de Stata (decisión v1.14: se trackea como mapa del proyecto)"
assert_ignored "ado/personal/foo.ado" "User-installed ado"
assert_ignored "ado/plus/x.ado" "User-installed ado plus"

echo "--- Dropbox conflict files (lowercase y Title Case) ---"
assert_ignored "SIM (ServidorCIEP's conflicted copy 2021-05-28).do" "Dropbox lowercase raíz"
assert_ignored "MyFile (Ricardo's Conflicted Copy 2025-01-15).do" "Dropbox Title Case raíz"
assert_ignored "subdir/foo (X conflicted copy 2024-01-15).dta" "Dropbox lowercase subdir"
assert_ignored "subdir/bar (Y Conflicted Copy 2024).xlsx" "Dropbox Title Case subdir"

echo "--- Stata recovered files (corchetes escapados) ---"
assert_ignored "Do_Medio_ambiente [Recovered].do" "Stata recovered raíz"
assert_ignored "01_modulos/Sankey_Salud_2024 [Recovered].do" "Stata recovered subdir"

echo "--- Secretos y credenciales ---"
assert_ignored "test.key" "Llave privada raíz"
assert_ignored "04_1_simuladorfiscal.ciep.mx/ssl/foo.key" "Llave bajo ssl/"
assert_ignored "test.pem" "Certificado PEM"
assert_ignored "test.p12" "Certificado P12"
assert_ignored "test.pfx" "Certificado PFX"
assert_ignored "test.crt" "Certificado CRT"
assert_ignored ".env" "Env file raíz"
assert_ignored ".env.production" "Env variant"
assert_ignored "set_token.do" "Token de usuario del BIE/INEGI (debe estar gitignored, nunca trackeado)"
assert_ignored "05_scripts/endpoint-credentials.sh" "Credenciales reales del endpoint Stata (debe estar gitignored, nunca trackeado)"
assert_ignored "wp-config.php" "Config WordPress con credenciales MySQL (raíz)"
assert_ignored "cualquier/ruta/wp-config.php" "Config WordPress con credenciales MySQL (cualquier profundidad)"
assert_ignored "wp-salt.php" "Salts de WordPress (raíz)"
assert_ignored "cualquier/ruta/wp-salt.php" "Salts de WordPress (cualquier profundidad)"
assert_ignored "cualquier/ruta/.env" "Env file a cualquier profundidad"

echo "--- Paquete Económico (contenido Dropbox, Entrega 1.5) ---"
# 2026-09-08: la semilla 04_1_paqueteeconomico.ciep.mx/ se retiró del repo
# (vive en ../CIEP_Micrositios/Paquete Económico/, fuera del árbol); sus
# aserciones y las del render de nodos bajo su docroot se retiraron con ella.
# El slot 04_1 lo ocupa ahora el sitio del Simulador (sección "operación local").
assert_ignored "04_2_documentos_latex/cualquier.tex" "Archivo histórico LaTeX 2013-2027"

echo "--- Semillas de sitios (2026-08-02) ---"
assert_ignored "04_4_libro.ciep.mx/public_html/wp-config.php" "wp-config de la semilla del libro (doble cinturón)"
assert_ignored "04_4_libro.ciep.mx/public_html/wp-salt.php" "wp-salt de la semilla del libro (doble cinturón)"
assert_ignored "04_4_libro.ciep.mx/db/libro_20260802.sql" "Dump de BD del libro (pedidos WooCommerce; nunca a git)"
assert_ignored "04_5_ciep.mx/wp-config.php" "wp-config de la copia de ciep.mx (doble cinturón)"

echo "--- Datos asociados en raw/ (ignorado) ---"
assert_ignored "raw/PEFs/CP_2024.xlsx" "Asset binario en raw/"
assert_ignored "raw/PEFs/algo.dta" "Cualquier archivo en raw/"
assert_ignored "raw/nuevo_subdir/foo.csv" "Subdirectorio nuevo en raw/"

echo "--- Carpetas de operación local ---"
assert_ignored "raw/temp/output.csv" "raw/temp/"
assert_ignored "master/2024/foo.dta" "master/"
assert_ignored "graphs/grafica.png" "graphs/"
assert_ignored "users/ricardo/algo" "users/"
assert_ignored "04_1_simuladorfiscal.ciep.mx/index.html" "servidor producción (clon local del sitio; renombrado desde 04_ el 2026-09-08)"
assert_ignored "04_1_simuladorfiscal.ciep.mx/config.php" "config.php del servidor de producción (credenciales; el susto de v1.15)"

echo ""

# =============================================================================
# 2. CASOS NEGATIVOS — paths que NO deben estar ignorados
# =============================================================================
echo "=========================================================="
echo "2. Paths que NO deben estar ignorados"
echo "=========================================================="

echo "--- Código del Simulador ---"
assert_not_ignored "SIM.do" "Master do-file"
assert_not_ignored "FiscalGap.ado" "Ado-file principal"
assert_not_ignored "AccesoBIE.ado" "Ado de acceso BIE"
assert_not_ignored "Stata net/SIM.ado" "Stata net (legacy)"
assert_not_ignored "01_modulos/IVA_Mod.do" "Módulo de impuesto"

echo "--- Plantillas de secretos (deben versionarse) ---"
assert_not_ignored "set_token.template.do" "Plantilla de set_token (debe versionarse para guiar a usuarios)"
assert_not_ignored "05_scripts/endpoint-credentials.template.sh" "Plantilla de credenciales del endpoint (debe versionarse para guiar a operadores)"
assert_not_ignored "05_scripts/publicar-vps-credentials.template.sh" "Plantilla de credenciales del VPS (debe versionarse; la real está ignorada)"

echo "--- Excepción del sitio: health.php SÍ se versiona ---"
assert_not_ignored "04_1_simuladorfiscal.ciep.mx/health.php" "health.php del pipeline VPS (única pieza versionada del clon del sitio)"

echo "--- Governance y meta ---"
assert_not_ignored ".mailmap" "Normalización de identidad"
assert_not_ignored ".windsurfrules" "Contrato de governance Windsurf"
assert_not_ignored ".gitignore" ".gitignore mismo (sí se versiona)"
assert_not_ignored "02_governance/historico/fase-0-reconocimiento.md" "Doc governance"
assert_not_ignored "02_governance/historico/fase-0-5-git-hygiene-audit.md" "Doc governance"
assert_not_ignored "02_governance/versionado-y-git.md" "Este documento"
assert_not_ignored "05_scripts/verify_gitignore.sh" "Este script"

echo "--- Manifest del Catálogo de datos asociados (vive en 05_scripts/) ---"
assert_not_ignored "05_scripts/manifest.json" "Manifest del Catálogo de datos asociados"

echo "--- Help y docs ---"
assert_not_ignored "03_help/FiscalGap.md" "Help file Markdown"
assert_not_ignored "03_help/Stata/AccesoBIE.sthlp" "Help Stata sthlp"
assert_not_ignored "README.md" "README"

echo "--- Archivos con caracteres del falso character class [Recovered] ---"
# Estos paths contienen R, e, c, o, v, r, d (el character class roto).
# Verificación de regresión del bug de 2026-05-09: con el patrón mal escapado,
# todos estos quedaban marcados como ignorados.
assert_not_ignored "scheme-ciep.scheme" "Scheme color"
assert_not_ignored "01_modulos/visualizations/SankeySF.do" "Sankey SF"
assert_not_ignored "PIBDeflactor.ado" "Deflactor PIB"

echo ""

# =============================================================================
# 3. ESCANEO REAL — archivos con patrones de credenciales en el working tree
# =============================================================================
# A diferencia de las secciones 1-2 (paths hipotéticos contra las reglas),
# esta sección recorre el árbol REAL: todo archivo existente que matchee un
# patrón de credenciales debe estar ignorado y NO trackeado. Añadido en la
# Entrega 1.5 del boceto Paquete 2027 (2026-08-01), tras encontrar dos
# wp-config.php reales dentro de carpetas untracked-y-sin-ignorar.
# Se excluyen plantillas (*.template.*) y ejemplos (*.example): esas SÍ se
# versionan por diseño (sección 2).
echo "=========================================================="
echo "3. Escaneo real de archivos de credenciales en el árbol"
echo "=========================================================="

cred_finds=$(find . -path ./.git -prune -o -type f \( \
    -name "wp-config.php" -o -name "wp-salt.php" \
    -o -name ".env" -o -name ".env.*" \
    -o -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.pfx" \
    -o -name "set_token.do" -o -name "*credentials.sh" \) -print 2>/dev/null \
    | sed 's|^\./||' | LC_ALL=C sort | grep -v -E '\.template\.|\.example$')

if [ -z "$cred_finds" ]; then
    echo "  (no se encontraron archivos con patrones de credenciales)"
else
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        total=$((total+1))
        if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
            printf "  [FAIL]       %-58s — credencial TRACKEADA en git: sacar del índice y rotar\n" "$f"
            failed=$((failed+1))
            fail_log+="    - $f: credencial trackeada en git"$'\n'
        elif git check-ignore -q "$f" 2>/dev/null; then
            printf "  [OK ignored] %-58s — credencial real presente pero ignorada\n" "$f"
            passed=$((passed+1))
        else
            printf "  [FAIL]       %-58s — credencial real SIN ignorar (riesgo de git add .)\n" "$f"
            failed=$((failed+1))
            fail_log+="    - $f: credencial real sin ignorar"$'\n'
        fi
    done <<< "$cred_finds"
fi

echo ""

# =============================================================================
# RESUMEN
# =============================================================================
echo "=========================================================="
printf "RESUMEN: %d/%d casos OK; %d FAILS\n" "$passed" "$total" "$failed"
echo "=========================================================="

if [ $failed -gt 0 ]; then
    echo ""
    echo "FALLAS DETECTADAS:"
    echo "$fail_log"
    echo "Acción: corregir el .gitignore. NO mergear esta rama hasta que"
    echo "el script salga con 0 FAILS."
    echo ""
    echo "Para diagnosticar un caso específico:"
    echo "  git check-ignore -v <path>"
    exit 1
fi

echo ""
echo "✓ .gitignore verificado. Apto para merge a master."
exit 0
