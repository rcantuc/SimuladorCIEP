#!/bin/bash
# =============================================================================
# governance/scripts/verify_gitignore.sh
# =============================================================================
# Verificación obligatoria del .gitignore antes de cualquier merge a master
# que modifique reglas de ignorado.
#
# Define un conjunto de referencia de paths que DEBEN y NO deben estar ignorados, y
# reporta divergencia. Justificación e historial de la regla: ver
#   governance/convenciones-git.md §6
#
# USO:
#   bash governance/scripts/verify_gitignore.sh
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
    echo "       cd a la raíz y ejecuta: bash governance/scripts/verify_gitignore.sh" >&2
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
assert_ignored "help/.DS_Store" "macOS metadata subdir"
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
assert_ignored "simulador.stpr" "Stata project (paths absolutos)"
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
assert_ignored "simuladorfiscal.ciep.mx/ssl/foo.key" "Llave bajo ssl/"
assert_ignored "test.pem" "Certificado PEM"
assert_ignored "test.p12" "Certificado P12"
assert_ignored "test.pfx" "Certificado PFX"
assert_ignored "test.crt" "Certificado CRT"
assert_ignored ".env" "Env file raíz"
assert_ignored ".env.production" "Env variant"

echo "--- Data Sidecar — raw/ ignorado ---"
assert_ignored "raw/PEFs/CP_2024.xlsx" "Asset binario en raw/"
assert_ignored "raw/PEFs/algo.dta" "Cualquier archivo en raw/"
assert_ignored "raw/nuevo_subdir/foo.csv" "Subdirectorio nuevo en raw/"

echo "--- Carpetas de operación local ---"
assert_ignored "temp/output.csv" "temp/"
assert_ignored "master/2024/foo.dta" "master/"
assert_ignored "graphs/grafica.png" "graphs/"
assert_ignored "users/ciepmx/algo" "users/"
assert_ignored "simuladorfiscal.ciep.mx/index.html" "servidor producción"

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
assert_not_ignored "01_modulos/tax_models/IVA_Mod.do" "Módulo de impuesto"

echo "--- Governance y meta ---"
assert_not_ignored ".mailmap" "Normalización de identidad"
assert_not_ignored ".windsurfrules" "Contrato de governance Windsurf"
assert_not_ignored ".gitignore" ".gitignore mismo (sí se versiona)"
assert_not_ignored "governance/fase-0-reconocimiento.md" "Doc governance"
assert_not_ignored "governance/fase-0-5-git-hygiene-audit.md" "Doc governance"
assert_not_ignored "governance/convenciones-git.md" "Este documento"
assert_not_ignored "governance/scripts/verify_gitignore.sh" "Este script"

echo "--- Excepción Data Sidecar: el manifest sí se versiona ---"
assert_not_ignored "raw/manifest.json" "Manifest del sidecar"

echo "--- Help y docs ---"
assert_not_ignored "help/FiscalGap.md" "Help file Markdown"
assert_not_ignored "help/Stata/AccesoBIE.sthlp" "Help Stata sthlp"
assert_not_ignored "README.md" "README"

echo "--- Archivos con caracteres del falso character class [Recovered] ---"
# Estos paths contienen R, e, c, o, v, r, d (el character class roto).
# Verificación de regresión del bug de 2026-05-09: con el patrón mal escapado,
# todos estos quedaban marcados como ignorados.
assert_not_ignored "scheme-ciepcolores.scheme" "Scheme color"
assert_not_ignored "01_modulos/visualizations/sankey/SankeySF.do" "Sankey SF"
assert_not_ignored "PIBDeflactor.ado" "Deflactor PIB"

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
