#!/usr/bin/env bash
# =============================================================================
# test-manifiesto-default.sh — el manifiesto del default se DERIVA de las páginas (v8.17.1)
# =============================================================================
# Sin Stata, sin red (CI, job sitio-seguridad). Prueba 05_scripts/manifiesto-default.py, la única lista de lo que
# viaja a users/ciepmx/ (Fase 3b-ter de publicar-vps.sh) y de lo que el humo pide tras el swap (humo-calcular.sh):
#   1. Sobre el repo: TSV de 3 columnas, archivos y endpoints únicos; trae lo que las páginas piden hoy (portada:
#      output.txt y los 5 sankeys; /NTA: v4 y v3, cuenta, panel e identidad; /entidades: entidades.json y las
#      32 × 9) y NO trae lo que ninguna página pide (v2, v1 del Sankey NTA, nta-quinquenio-sexo.json);
#      --entidades NL deja solo el testigo; --archivos y --endpoints son las columnas del TSV sin repetir.
#   2. Derivación, no lista: en una copia del sitio, si NTA/index.php pide además ?corte=v2-grupoedad, el manifiesto
#      lo incluye solo; si pide un corte que jsonSankeyNTA.php no admite, sale 2 con el motivo; si _entidad.php deja de
#      pedir el producto neto, las 32 × neto-pibe.json desaparecen. Un comentario con una URL no cuenta.
#   3. Los archivos de /NTA del manifiesto existen como fixtures (05_scripts/fixtures/) con el nombre que la
#      derivación espera (el gate CI de /NTA y el humo local los usan).
# Uso: bash 05_scripts/test-manifiesto-default.sh
# =============================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$REPO_ROOT/05_scripts/manifiesto-default.py"
H="$(mktemp -d -t manif-default-XXXXXX)"
trap 'rm -rf "$H"' EXIT
fallos=0
ok()    { printf 'OK     %s\n' "$*"; }
fallo() { printf 'FALLO  %s\n' "$*"; fallos=$((fallos+1)); }
aserta() { if eval "$1"; then ok "$2"; else fallo "$2"; fi; }

echo "== 1. sobre el repo"
python3 -I "$PY" --root "$REPO_ROOT" --tsv > "$H/todo.tsv" 2> "$H/err"; rc=$?
aserta '[[ $rc -eq 0 ]]' "manifiesto-default.py sale 0 sobre el repo ($(cat "$H/err" 2>/dev/null))"
N=$(wc -l < "$H/todo.tsv" | tr -d ' ')
aserta '[[ "$(awk -F"\t" "NF!=3" "$H/todo.tsv" | wc -l | tr -d " ")" == "0" ]]' "TSV de 3 columnas en las $N filas"
aserta '[[ "$(cut -f1 "$H/todo.tsv" | sort | uniq -d | wc -l | tr -d " ")" == "0" ]]' "archivos sin repetir"
aserta '[[ "$(cut -f2 "$H/todo.tsv" | sort | uniq -d | wc -l | tr -d " ")" == "0" ]]' "endpoints sin repetir"
tiene() { cut -f1 "$H/todo.tsv" | grep -qx "$1"; }
for f in output.txt sankey-decil.json sankey-escol.json sankey-grupoedad.json sankey-rural.json sankey-sexo.json \
         SankeyNTA/sankey-v4-economia.json SankeyNTA/sankey-v3-grupoedad.json \
         NTA/nta-grupoedad.json NTA/nta-panel-grupoedad-sexo.json NTA/nta-identidad.txt entidades.json; do
    aserta "tiene '$f'" "viaja $f"
done
for f in SankeyNTA/sankey-v2-grupoedad.json SankeyNTA/sankey-grupoedad.json NTA/nta-quinquenio-sexo.json; do
    aserta "! tiene '$f'" "NO viaja $f (ninguna página lo pide)"
done
aserta '[[ "$(cut -f1 "$H/todo.tsv" | grep -cE "^[A-Za-z]+/(sankey-(quintil|grupoedad|sexo|rural|escol)|ciclo-vida|tasas-efectivas|neto-pibe|meta)\.json$")" == "288" ]]' "las 32 entidades × 9 productos = 288 archivos"
aserta 'grep -q "^SankeyNTA/sankey-v4-economia.json	jsonSankeyNTA.php?corte=v4-economia	NTA/index.php$" "$H/todo.tsv"' "el v4 lo pide NTA/index.php por jsonSankeyNTA.php?corte=v4-economia"
aserta 'grep -q "^NL/meta.json	jsonEntidad.php?abrev=NL&producto=meta	entidades/NL (_entidad.php)$" "$H/todo.tsv"' "NL/meta.json lo pide /entidades/NL por jsonEntidad.php?abrev=NL&producto=meta"
python3 -I "$PY" --root "$REPO_ROOT" --tsv --entidades NL > "$H/nl.tsv" 2>/dev/null
aserta '[[ "$(wc -l < "$H/nl.tsv" | tr -d " ")" == "21" ]]' "--entidades NL: 21 filas (6 portada + 5 /NTA + índice + 9 de NL)"
aserta '! python3 -I "$PY" --root "$REPO_ROOT" --tsv --entidades Inventada >/dev/null 2>&1' "--entidades con una abreviatura fuera del catálogo sale ≠ 0"
python3 -I "$PY" --root "$REPO_ROOT" --archivos > "$H/archivos"; python3 -I "$PY" --root "$REPO_ROOT" --endpoints > "$H/endpoints"
aserta 'cmp -s <(cut -f1 "$H/todo.tsv") "$H/archivos"' "--archivos = columna 1 del TSV (en orden)"
aserta 'cmp -s <(cut -f2 "$H/todo.tsv") "$H/endpoints"' "--endpoints = columna 2 del TSV (en orden)"

echo "== 2. derivación, no lista (copia del sitio modificada)"
copia() { # copia mínima del repo que la derivación lee
    local d="$1"; rm -rf "$d"; mkdir -p "$d/04_1_simuladorfiscal.ciep.mx/js" "$d/04_1_simuladorfiscal.ciep.mx/NTA" "$d/04_1_simuladorfiscal.ciep.mx/entidades" "$d/05_scripts"
    cp "$REPO_ROOT/SIMentidad.ado" "$d/"
    cp "$REPO_ROOT/04_1_simuladorfiscal.ciep.mx/js/stataCalcula.js" "$d/04_1_simuladorfiscal.ciep.mx/js/"
    cp "$REPO_ROOT/04_1_simuladorfiscal.ciep.mx/"{cargaDefault,jsonSankey,jsonSankeyEscol,jsonSankeyGrupoedad,jsonSankeyRural,jsonSankeySexo,jsonSankeyNTA,jsonEntidad}.php "$d/04_1_simuladorfiscal.ciep.mx/"
    cp "$REPO_ROOT/04_1_simuladorfiscal.ciep.mx/NTA/index.php" "$REPO_ROOT"/04_1_simuladorfiscal.ciep.mx/NTA/_cuerpo-*.php "$d/04_1_simuladorfiscal.ciep.mx/NTA/"   # 8.19: lo que /NTA pide vive también en sus cuerpos _cuerpo-{en,es}.php
    cp "$REPO_ROOT/04_1_simuladorfiscal.ciep.mx/entidades/"{index,_entidad}.php "$d/04_1_simuladorfiscal.ciep.mx/entidades/"
}
copia "$H/c1"
python3 -I "$PY" --root "$H/c1" --archivos > "$H/c1.archivos" 2>"$H/c1.err"; rc=$?
aserta '[[ $rc -eq 0 ]] && cmp -s "$H/c1.archivos" "$H/archivos"' "la copia mínima reproduce el manifiesto del repo (la derivación solo lee esos archivos)"
# a) la página pide un corte más → entra solo
copia "$H/c2"
printf '\n<a href="/jsonSankeyNTA.php?corte=v2-grupoedad">v2</a>\n' >> "$H/c2/04_1_simuladorfiscal.ciep.mx/NTA/index.php"
aserta 'python3 -I "$PY" --root "$H/c2" --archivos 2>/dev/null | grep -qx "SankeyNTA/sankey-v2-grupoedad.json"' "si NTA/index.php pide ?corte=v2-grupoedad, SankeyNTA/sankey-v2-grupoedad.json entra al manifiesto"
# b) la misma URL en un comentario no cuenta
copia "$H/c3"
printf '\n// ejemplo: /jsonSankeyNTA.php?corte=v2-grupoedad\n' >> "$H/c3/04_1_simuladorfiscal.ciep.mx/NTA/index.php"
aserta '! python3 -I "$PY" --root "$H/c3" --archivos 2>/dev/null | grep -qx "SankeyNTA/sankey-v2-grupoedad.json"' "la misma URL en un comentario (// …) no entra"
# c) la página pide algo que el endpoint rechaza → exit 2 con el motivo
copia "$H/c4"
printf '\n<a href="/jsonSankeyNTA.php?corte=inventado">x</a>\n' >> "$H/c4/04_1_simuladorfiscal.ciep.mx/NTA/index.php"
python3 -I "$PY" --root "$H/c4" --archivos > /dev/null 2> "$H/c4.err"; rc=$?
aserta '[[ $rc -eq 2 ]] && grep -q "corte=inventado" "$H/c4.err"' "un corte que jsonSankeyNTA.php no admite → exit 2 nombrándolo"
# d) la página de entidad deja de pedir neto → las 32 × neto-pibe.json salen
copia "$H/c5"
python3 - "$H/c5/04_1_simuladorfiscal.ciep.mx/entidades/_entidad.php" <<'PYEOF'
import sys
p = sys.argv[1]; t = open(p, encoding='utf-8').read()
t2 = t.replace("'neto' => $ep . 'neto', ", "")
assert t2 != t, "no encontré 'neto' => $ep . 'neto' en _entidad.php"
open(p, 'w', encoding='utf-8').write(t2)
PYEOF
python3 -I "$PY" --root "$H/c5" --archivos > "$H/c5.archivos" 2>/dev/null
aserta '[[ "$(grep -c "/neto-pibe.json$" "$H/c5.archivos")" == "0" && "$(wc -l < "$H/c5.archivos" | tr -d " ")" == "268" ]]' "si _entidad.php deja de pedir producto=neto, salen las 32 neto-pibe.json (quedan 268)"
# e) sin el catálogo de SIMentidad.ado → exit 2
copia "$H/c6"; sed -i.bak 's/^\([[:space:]]*\)global entidadesC /\1global entidadesX /' "$H/c6/SIMentidad.ado"
aserta '! python3 -I "$PY" --root "$H/c6" --archivos >/dev/null 2>&1' "sin global entidadesC en SIMentidad.ado → exit ≠ 0"

echo "== 3. fixtures de /NTA con el nombre que la derivación espera"
# (pares archivo=fixture; sin arrays asociativos: el bash 3.2 de macOS)
for par in SankeyNTA/sankey-v4-economia.json=sankey-nta-v4-economia.json SankeyNTA/sankey-v3-grupoedad.json=sankey-nta-grupoedad.json \
           NTA/nta-grupoedad.json=nta-grupoedad.json NTA/nta-panel-grupoedad-sexo.json=nta-panel-grupoedad-sexo.json NTA/nta-identidad.txt=nta-identidad.txt; do
    f="${par%%=*}"; fx="${par#*=}"
    aserta "tiene '$f' && [[ -s '$REPO_ROOT/05_scripts/fixtures/$fx' ]]" "$f viaja y su fixture 05_scripts/fixtures/$fx existe"
done
for f in meta.json ciclo-vida.json tasas-efectivas.json neto-pibe.json sankey-quintil.json sankey-grupoedad.json sankey-sexo.json sankey-rural.json sankey-escol.json; do
    aserta "tiene 'NL/$f' && [[ -s '$REPO_ROOT/05_scripts/fixtures/entidades/NL/$f' ]]" "NL/$f viaja y su fixture existe"
done

if [[ $fallos -eq 0 ]]; then echo "RESULTADO: el manifiesto del default se deriva de las páginas (0 fallos)"; exit 0; fi
echo "RESULTADO: $fallos fallo(s) en test-manifiesto-default.sh"; exit 1
