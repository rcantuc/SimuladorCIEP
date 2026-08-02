#!/bin/bash
# =============================================================================
# 05_scripts/verify_nodo.sh
# =============================================================================
# Verificación obligatoria de un nodo antes de publicar o mergear.
#
# En la línea de verify_gitignore.sh: un conjunto de aserciones sobre el
# contrato (el JSON), sobre la página que lo consume y sobre la higiene del
# repo. Cada regla existe porque su ausencia ya costó caro alguna vez.
#
# USO:
#   bash 05_scripts/verify_nodo.sh [nodo]        (por defecto: deuda-publica)
#   bash 05_scripts/verify_nodo.sh --sin-stata   (salta la regla 3)
#
# EXIT CODES:
#   0 — todas las reglas pasan.
#   1 — una o más reglas fallan; NO publicar hasta corregir.
#   2 — error de invocación (no estás en la raíz del repo, falta Stata sin
#       que lo hayas declarado con --sin-stata, etc.)
#
# LAS SEIS REGLAS
#   1. La página no contiene literales numéricos fuera de <style>. Es el
#      verificador anti-fósil: este repo acaba de extinguir la clase "números
#      quemados en HTML" (bitácoras v1.42/v1.44, ciclo v8.2.0) y el nodo nace
#      sin ella. Se eximen: el bloque <style> (geometría y tipografía), las
#      URLs (un namespace SVG no es una cifra) y los enteros de tres dígitos
#      o menos (índices, geometría de la gráfica).
#   2. El JSON declara todos los campos de procedencia.
#   3. La exportación es determinista: dos corridas seguidas byte-idénticas
#      salvo el sello, aislado en una sola línea.
#   4. Ninguna serie tiene huecos de año sin declarar.
#   5. Toda serie declara su unidad.
#   6. La raíz del repo no contiene archivos .md: la documentación vive en
#      02_governance/ (governance, planes, reportes) o 03_help/ (ayuda de
#      comandos). Excepción única y CONFIRMADA: README.md — es la portada
#      convencional de GitHub, la única pieza cuya ubicación no elegimos
#      nosotros, y verify_gitignore.sh:180 ya la trata como institucional
#      (assert_not_ignored "README.md"). Cualquier otro .md en la raíz es
#      un documento que se quedó donde cayó.
# =============================================================================

set -uo pipefail

NODO="deuda-publica"
SIN_STATA=0
for arg in "$@"; do
	case "$arg" in
		--sin-stata) SIN_STATA=1 ;;
		-*) echo "verify_nodo: opción desconocida: $arg" >&2; exit 2 ;;
		*)  NODO="$arg" ;;
	esac
done

# --- contexto -----------------------------------------------------------------
if [ ! -f "05_scripts/verify_nodo.sh" ] || [ ! -d "04_3_nodos" ]; then
	echo "verify_nodo: ejecútalo desde la raíz del repo (donde viven 04_3_nodos/ y 05_scripts/)." >&2
	exit 2
fi

# FUENTE versionada vs SALIDA generada. La página que se audita es la FUENTE
# (01_modulos/nodos/), no la copia de render: la copia se regenera en cada
# corrida y auditar copias es auditar el pasado. El contrato vive en
# 04_3_nodos/, que está en .gitignore — es un destino de render desechable,
# mismo estatus que los statalatex_*.tex de 06_libro/images. Consecuencia
# operativa: en un clone limpio el JSON no existe hasta que corras el driver,
# y este script te lo dice en vez de fallar de forma críptica.
JSON="04_3_nodos/statajson_${NODO}.json"
PAGINA="01_modulos/nodos/nodo-deuda.html"

FALLAS=0
ok()   { printf '  \033[0;32m[OK]\033[0m    %s\n' "$1"; }
fail() { printf '  \033[0;31m[FALLA]\033[0m %s\n' "$1"; FALLAS=$((FALLAS+1)); }
info() { printf '         %s\n' "$1"; }

echo "verify_nodo — nodo: ${NODO}"
echo "  contrato: ${JSON}"
echo "  página:   ${PAGINA}"
echo

if [ ! -f "$JSON" ]; then
	echo "verify_nodo: no existe $JSON" >&2
	echo "  Es una SALIDA generada, no vive en git (04_3_nodos/ está ignorada)." >&2
	echo "  Prodúcela corriendo el driver en Stata:" >&2
	echo "    do \"\$(pwd)/01_modulos/nodos/nodo-deuda.do\"" >&2
	exit 2
fi
if [ ! -f "$PAGINA" ]; then echo "verify_nodo: no existe la fuente $PAGINA" >&2; exit 2; fi

PY=$(command -v python3 || true)
if [ -z "$PY" ]; then echo "verify_nodo: se requiere python3 para leer el JSON." >&2; exit 2; fi

# =============================================================================
echo "REGLA 1 — la página no contiene cifras propias"
# =============================================================================
# Se quitan: bloque <style>…</style>, URLs y comentarios de línea marcados.
# Sobre lo que queda, es falla cualquier entero de 4+ dígitos o cualquier
# decimal. Un año (4 dígitos) también es dato: debe venir del JSON.
QUEMADOS=$("$PY" - "$PAGINA" <<'PYEOF'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
src = re.sub(r'<style\b.*?</style>', '', src, flags=re.S | re.I)   # geometría/tipografía
src = re.sub(r'https?://\S+', '', src)                              # URLs y namespaces
malos = []
for n, linea in enumerate(src.splitlines(), 1):
    if re.search(r'(?<![\w.])\d{4,}(?![\w.])', linea) or re.search(r'(?<![\w])\d+\.\d+', linea):
        malos.append(f"{n}: {linea.strip()[:96]}")
print("\n".join(malos))
PYEOF
)
if [ -z "$QUEMADOS" ]; then
	ok "sin literales numéricos fuera de <style>"
else
	fail "literales numéricos en la página (fósiles):"
	while IFS= read -r l; do info "$l"; done <<< "$QUEMADOS"
fi

# =============================================================================
echo
echo "REGLA 2 — procedencia completa en el JSON"
# =============================================================================
SALIDA=$("$PY" - "$JSON" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
p = d.get('procedencia', {})
req = ['version_simulador','corte_datos','corte_serie','log','origen','dataset_serie','generado_en']
faltan = [k for k in req if k not in p]
vacios = [k for k in req if k in p and p[k] in ('', None)]
sub = p.get('corte_serie', {})
faltan += ['corte_serie.'+k for k in ('anio','mes','etiqueta') if k not in sub]
# `log` puede venir vacío SOLO si está declarado en faltantes.
declarados = set(d.get('faltantes', []))
vacios = [k for k in vacios if ('procedencia.'+k) not in declarados]
print('FALTAN=' + ','.join(faltan))
print('VACIOS_NO_DECLARADOS=' + ','.join(vacios))
PYEOF
)
F2=$(echo "$SALIDA" | sed -n 's/^FALTAN=//p')
V2=$(echo "$SALIDA" | sed -n 's/^VACIOS_NO_DECLARADOS=//p')
if [ -z "$F2" ] && [ -z "$V2" ]; then
	ok "los siete campos de procedencia presentes (vacíos solo si están declarados como faltantes)"
else
	[ -n "$F2" ] && fail "campos de procedencia ausentes: $F2"
	[ -n "$V2" ] && fail "campos de procedencia vacíos y NO declarados en faltantes: $V2"
fi

# =============================================================================
echo
echo "REGLA 3 — la exportación es determinista"
# =============================================================================
STATA=""
for cand in /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se \
            /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp \
            "$(command -v stata-se || true)" "$(command -v stata-mp || true)" \
            "$(command -v stata || true)"; do
	if [ -n "$cand" ] && [ -x "$cand" ]; then STATA="$cand"; break; fi
done

if [ "$SIN_STATA" -eq 1 ]; then
	info "SALTADA por --sin-stata (declarado explícitamente)."
elif [ -z "$STATA" ]; then
	echo "verify_nodo: no encontré Stata y no pasaste --sin-stata." >&2
	echo "  El determinismo no se puede saltar en silencio: o corre con Stata," >&2
	echo "  o declara la omisión con --sin-stata." >&2
	exit 2
else
	TMP=$(mktemp -d)
	REPO="$PWD"
	cat > "$TMP/det.do" <<EOF
sysdir set SITE "$REPO"
adopath ++ "$REPO"
cd "$REPO"
run "$REPO/profile.do"
global nographs "nographs"
global textbook ""
quietly SHRFSP
global nodo_saving "$TMP/a.json"
quietly do "$REPO/01_modulos/nodos/nodo-deuda.do"
global nodo_saving "$TMP/b.json"
quietly do "$REPO/01_modulos/nodos/nodo-deuda.do"
global nodo_saving ""
EOF
	( cd "$TMP" && "$STATA" -b do "$TMP/det.do" >/dev/null 2>&1 )
	if [ ! -f "$TMP/a.json" ] || [ ! -f "$TMP/b.json" ]; then
		fail "no se pudieron producir las dos exportaciones (ver $TMP/det.log)"
	else
		DIF=$(diff "$TMP/a.json" "$TMP/b.json" | grep -c '^[<>]' || true)
		H1=$(grep -v '"generado_en"' "$TMP/a.json" | shasum -a 256 | awk '{print $1}')
		H2=$(grep -v '"generado_en"' "$TMP/b.json" | shasum -a 256 | awk '{print $1}')
		if [ "$H1" != "$H2" ]; then
			fail "las dos exportaciones difieren fuera del sello"
			diff "$TMP/a.json" "$TMP/b.json" | grep '^[<>]' | grep -v generado_en | head -10 | while IFS= read -r l; do info "$l"; done
		elif [ "$DIF" -gt 2 ]; then
			fail "el sello no está aislado: $DIF líneas distintas (se esperaban 2 como máximo)"
		else
			ok "byte-idénticas salvo el sello (sha256 sin sello: ${H1:0:12}…)"
		fi
		rm -rf "$TMP"
	fi
fi

# =============================================================================
echo
echo "REGLA 4 — sin huecos de año no declarados"
# =============================================================================
SALIDA=$("$PY" - "$JSON" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
anios = sorted(f['anio'] for f in d['series'])
cob = d.get('cobertura', {})
decl = set(cob.get('anios_faltantes', []))
reales = set(range(anios[0], anios[-1]+1)) - set(anios) if anios else set()
print('NO_DECLARADOS=' + ','.join(str(a) for a in sorted(reales - decl)))
print('DECLARADOS_FALSOS=' + ','.join(str(a) for a in sorted(decl - reales)))
inc = []
if cob.get('anio_min') != (anios[0] if anios else None): inc.append('anio_min')
if cob.get('anio_max') != (anios[-1] if anios else None): inc.append('anio_max')
if cob.get('n_anios') != len(anios): inc.append('n_anios')
print('COBERTURA_INCONSISTENTE=' + ','.join(inc))
PYEOF
)
N4=$(echo "$SALIDA" | sed -n 's/^NO_DECLARADOS=//p')
D4=$(echo "$SALIDA" | sed -n 's/^DECLARADOS_FALSOS=//p')
C4=$(echo "$SALIDA" | sed -n 's/^COBERTURA_INCONSISTENTE=//p')
if [ -z "$N4" ] && [ -z "$D4" ] && [ -z "$C4" ]; then
	ok "serie continua y cobertura consistente con las filas"
else
	[ -n "$N4" ] && fail "años ausentes de la serie y NO declarados: $N4"
	[ -n "$D4" ] && fail "años declarados como faltantes que sí están: $D4"
	[ -n "$C4" ] && fail "el bloque cobertura no cuadra con las filas: $C4"
fi

# =============================================================================
echo
echo "REGLA 5 — toda serie declara su unidad"
# =============================================================================
SALIDA=$("$PY" - "$JSON" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
campos = [k for k in d['series'][0].keys() if k != 'anio'] if d.get('series') else []
u = d.get('unidades', {})
sin_entrada = [c for c in campos if c not in u]
sin_texto   = [c for c in campos if c in u and not (u[c] or {}).get('unidad')]
sin_formato = [c for c in campos if c in u and not (u[c] or {}).get('formato_sugerido')]
declarados = set(d.get('faltantes', []))
sin_texto   = [c for c in sin_texto   if ('unidad.'+c)  not in declarados]
sin_formato = [c for c in sin_formato if ('formato.'+c) not in declarados]
print('SIN_ENTRADA=' + ','.join(sin_entrada))
print('SIN_TEXTO='   + ','.join(sin_texto))
print('SIN_FORMATO=' + ','.join(sin_formato))
PYEOF
)
E5=$(echo "$SALIDA" | sed -n 's/^SIN_ENTRADA=//p')
T5=$(echo "$SALIDA" | sed -n 's/^SIN_TEXTO=//p')
FM5=$(echo "$SALIDA" | sed -n 's/^SIN_FORMATO=//p')
if [ -z "$E5" ] && [ -z "$T5" ] && [ -z "$FM5" ]; then
	ok "todas las series del contrato declaran unidad y formato"
else
	[ -n "$E5" ]  && fail "series sin entrada en unidades: $E5"
	[ -n "$T5" ]  && fail "series con unidad vacía y no declarada: $T5"
	[ -n "$FM5" ] && fail "series sin formato sugerido y no declarado: $FM5"
fi

# =============================================================================
echo
echo "REGLA 6 — la raíz no contiene archivos .md (salvo README.md)"
# =============================================================================
INTRUSOS=""
for f in ./*.md; do
	[ -e "$f" ] || continue
	base=$(basename "$f")
	[ "$base" = "README.md" ] && continue
	INTRUSOS="$INTRUSOS $base"
done
if [ -z "$INTRUSOS" ]; then
	ok "solo README.md en la raíz"
else
	fail ".md en la raíz que deberían vivir en 02_governance/ o 03_help/:$INTRUSOS"
fi

# =============================================================================
echo
if [ "$FALLAS" -eq 0 ]; then
	printf '\033[0;32mverify_nodo: todas las reglas pasan.\033[0m\n'
	exit 0
else
	printf '\033[0;31mverify_nodo: %s regla(s) con falla. NO publicar.\033[0m\n' "$FALLAS"
	exit 1
fi
