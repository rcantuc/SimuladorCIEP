#!/usr/bin/env bash
# test-maquina-virgen.sh — ¿Puede un externo reconstruir el Simulador desde cero?
#
# La promesa publica del endpoint es que, con el repo (o la copia publicada) y
# SIN raw/ ni master/, la cadena descarga TODOS los assets del manifest desde la
# GitHub Release y los verifica por SHA-256. En v8.3.0 esa promesa se rompio sin
# ruido: PPEF.2027.xlsx y Diccionario.csv estaban en el manifest y en la Release,
# pero ningun modulo los pedia (PEF.ado mantenia la lista de ensure_asset a mano
# desde v7.0) y una maquina virgen simplemente no los tenia. Este test lo
# formaliza en dos capas:
#
#   --cobertura  (estatico, segundos, sin red)  Cada asset del manifest debe ser
#                solicitado por algun modulo: por nombre (ensure_asset "X") o por
#                directorio (ensure_asset, dir(D) con local_path bajo D/). Es el
#                Gate 6 de publicar.sh.
#   --download   (dinamico, ~1.3 GB, requiere la Release publicada)  Crea un SITE
#                falso en /tmp con ensure_asset.ado y el manifest del repo, raw/
#                VACIO, y corre las MISMAS invocaciones de ensure_asset que hacen
#                los modulos. Exito = todos los assets del manifest descargados y
#                con SHA verificado (N/N). Correr DESPUES de publicar.sh vX.Y.Z y
#                antes de anunciar. No toca el repo ni raw/ real.
#
#   --zip        (dinamico, ~1 min, sin red)  La via del ALUMNO (2026-10-05): ZIP de
#                GitHub sin git, carpeta con nombre arbitrario y espacios, sin
#                profile.do cargado, sin sysdir set SITE. Se arma una copia
#                `git archive` del arbol en /tmp y se corre SIM.do en los tres
#                modos de ejecucion reales: (1) `do` desde OTRA carpeta de
#                trabajo -> debe detenerse con la instruccion en espanol (r(601));
#                (2) carpeta de trabajo = el simulador (doble clic en SIM.do, o
#                cd previo) con SIM_SMOKE=1 -> autolocalizacion OK y los .ado se
#                encuentran despues de un cd (la clase de falla "command LIF is
#                unrecognized"); (3) idem con profile.do presente (flujo del
#                investigador). Con --completo, el modo (2) corre SIM.do entero
#                (descarga ~1.3 GB y construye todo: ~1 h) y exige TOUCH-DOWN.
#
# Uso: bash 05_scripts/test-maquina-virgen.sh --cobertura
#      bash 05_scripts/test-maquina-virgen.sh --download [--stata <ruta stata-se>]
#      bash 05_scripts/test-maquina-virgen.sh --zip [--completo] [--stata <ruta>]
# Exit 0 si pasa; 1 si falla (lista lo que falta).

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
[[ -z "$REPO_ROOT" ]] && { echo "No se pudo detectar root del repo Git." >&2; exit 1; }
cd "$REPO_ROOT"

MODE=""
STATA=""
COMPLETO=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cobertura) MODE="cobertura"; shift ;;
        --download)  MODE="download"; shift ;;
        --zip)       MODE="zip"; shift ;;
        --completo)  COMPLETO=true; shift ;;
        --stata)     STATA="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
done
[[ -z "$MODE" ]] && { echo "Uso: $0 --cobertura | --download [--stata <ruta>] | --zip [--completo]" >&2; exit 1; }

# ─── Inventario del manifest y de las invocaciones de ensure_asset ───
# Emite lineas "name<TAB>local_path<TAB>solicitado_por" (solicitado_por vacio = huerfano).
cobertura() {
python3 - <<'PYEOF'
import json, re, glob, os, sys
m = json.load(open("05_scripts/manifest.json", encoding="utf-8"))
fuentes = glob.glob("*.ado") + glob.glob("01_modulos/*.do")
por_nombre, por_dir = {}, {}
for f in fuentes:
    if os.path.basename(f) == "ensure_asset.ado":
        continue
    txt = open(f, encoding="utf-8", errors="replace").read()
    for n in re.findall(r'ensure_asset\s+"([^"]+)"', txt):
        por_nombre.setdefault(n, f)
    for d in re.findall(r'ensure_asset\s*,\s*dir\(\s*"?([^")]+?)"?\s*\)', txt):
        por_dir.setdefault(d.strip().strip("/") + "/", f)
huerfanos = 0
for a in m["assets"]:
    n, lp = a["name"], a["local_path"].replace("\\", "/")
    quien = por_nombre.get(n, "")
    if not quien:
        for d, f in por_dir.items():
            if lp.startswith(d):
                quien = f + " [dir(" + d.rstrip("/") + ")]"
                break
    if not quien:
        huerfanos += 1
    print(f"{n}\t{lp}\t{quien}")
print(f"TOTAL\t{len(m['assets'])}\t{huerfanos}")
PYEOF
}

if [[ "$MODE" == "cobertura" ]]; then
    out="$(cobertura)"
    total="$(awk -F'\t' '$1=="TOTAL"{print $2}' <<< "$out")"
    huerf="$(awk -F'\t' '$1=="TOTAL"{print $3}' <<< "$out")"
    if (( huerf > 0 )); then
        awk -F'\t' '$1!="TOTAL" && $3==""{print "  - "$1"  ("$2"): ningun modulo lo solicita"}' <<< "$out"
        echo "$huerf de $total asset(s) del manifest sin solicitante. Agrega el asset a un directorio cubierto por ensure_asset, dir() o pidelo por nombre."
        exit 1
    fi
    echo "$total/$total assets del manifest solicitados por algun modulo."
    exit 0
fi

# ─── --download: SITE falso contra la Release ───
if [[ -z "$STATA" ]]; then
    for c in /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se \
             /Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp \
             /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp \
             /Applications/Stata/StataSE.app/Contents/MacOS/stata-se; do
        [[ -x "$c" ]] && { STATA="$c"; break; }
    done
fi
[[ -x "${STATA:-}" ]] || { echo "No encontre stata-se/stata-mp; pasa --stata <ruta>." >&2; exit 1; }

# ─── Modo --zip: la via del alumno (ZIP sin git, ruta con espacios, sin profile.do, sin SITE) ───
if [[ "$MODE" == "zip" ]]; then
    BASE="$(mktemp -d /tmp/simulador-zip.XXXXXX)"
    ZIPDIR="$BASE/Carpeta del alumno/SimuladorCIEP-master"
    mkdir -p "$ZIPDIR"
    git archive HEAD | tar -x -C "$ZIPDIR"          # lo mismo que trae el ZIP de GitHub (sin .git)
    if [[ -L "$ZIPDIR/raw" || -L "$ZIPDIR/master" || -L "$ZIPDIR/users" ]]; then
        echo "ZIP: el arbol versionado trae un symlink raw/, master/ o users/ (incidente fd7caa1): en otra maquina es un enlace roto." >&2
        exit 1
    fi
    fallas=0
    echo "ZIP sin git en: $ZIPDIR"

    # (1) `do` desde OTRA carpeta de trabajo: debe detenerse con la instruccion, sin tocar nada
    printf 'do "%s/SIM.do"\n' "$ZIPDIR" > "$BASE/otra-carpeta.do"
    ( cd "$BASE" && "$STATA" -b do "$BASE/otra-carpeta.do" < /dev/null )
    if grep -q "SIM.do: no encuentro la carpeta del Simulador" "$BASE/otra-carpeta.log" && grep -q "^r(601);" "$BASE/otra-carpeta.log"; then
        echo "  (1) do desde otra carpeta de trabajo: se detiene con la instruccion en espanol (r(601))  OK"
    else
        echo "  (1) do desde otra carpeta de trabajo: NO dio el mensaje accionable; ver $BASE/otra-carpeta.log" >&2; fallas=$((fallas+1))
    fi

    # (2) carpeta de trabajo = el simulador, SIN profile.do (doble clic en SIM.do / cd previo)
    mv "$ZIPDIR/profile.do" "$ZIPDIR/profile.do.off"
    ( cd "$ZIPDIR" && SIM_SMOKE=1 "$STATA" -b do SIM.do < /dev/null )
    if grep -q "SIM.do: autolocalizaci" "$ZIPDIR/SIM.log" && ! grep -qE '^r\([0-9]+\);' "$ZIPDIR/SIM.log"; then
        echo "  (2) carpeta de trabajo = simulador, sin profile.do: autolocalizacion y .ado visibles tras cd  OK"
    else
        echo "  (2) carpeta de trabajo = simulador, sin profile.do: FALLO; ver $ZIPDIR/SIM.log" >&2
        grep -B3 -E 'unrecognized|^r\([0-9]+\);' "$ZIPDIR/SIM.log" | head -12 >&2; fallas=$((fallas+1))
    fi
    mv "$ZIPDIR/profile.do.off" "$ZIPDIR/profile.do"

    # (3) idem CON profile.do (Stata arrancado en la carpeta: flujo del investigador)
    rm -f "$ZIPDIR/SIM.log"
    ( cd "$ZIPDIR" && SIM_SMOKE=1 "$STATA" -b do SIM.do < /dev/null )
    if grep -q "SIM.do: autolocalizaci" "$ZIPDIR/SIM.log" && ! grep -qE '^r\([0-9]+\);' "$ZIPDIR/SIM.log"; then
        echo "  (3) carpeta de trabajo = simulador, con profile.do: OK"
    else
        echo "  (3) con profile.do: FALLO; ver $ZIPDIR/SIM.log" >&2; fallas=$((fallas+1))
    fi

    if [[ "$COMPLETO" == "true" && $fallas -eq 0 ]]; then
        echo "  (2-completo) SIM.do entero sin profile.do ni SITE (descarga assets y construye; ~1 h)..."
        mv "$ZIPDIR/profile.do" "$ZIPDIR/profile.do.off"
        sed -e 's|^//global nographs|global nographs|' "$ZIPDIR/SIM.do" > "$ZIPDIR/SIM_zip.do"   # batch: sin ventana de graficas
        ( cd "$ZIPDIR" && "$STATA" -b do SIM_zip.do < /dev/null )
        mv "$ZIPDIR/profile.do.off" "$ZIPDIR/profile.do"
        if grep -q "TOUCH-DOWN" "$ZIPDIR/SIM_zip.log" && ! grep -qE '^r\([0-9]+\);' "$ZIPDIR/SIM_zip.log"; then
            echo "  (2-completo) TOUCH-DOWN  OK"
        else
            echo "  (2-completo) FALLO; ver $ZIPDIR/SIM_zip.log" >&2
            grep -B4 -E '^r\([0-9]+\);' "$ZIPDIR/SIM_zip.log" | head -12 >&2; fallas=$((fallas+1))
        fi
    fi

    if (( fallas > 0 )); then
        echo "ZIP SIN GIT: $fallas prueba(s) fallaron. Copia conservada en $BASE."; exit 1
    fi
    echo "ZIP SIN GIT: las tres vias de ejecucion pasan (copia en $BASE; borrala cuando quieras)."
    exit 0
fi

# Cobertura primero: sin ella la descarga no puede llegar a N/N.
if ! cob="$(cobertura)"; then echo "$cob"; exit 1; fi
huerf="$(awk -F'\t' '$1=="TOTAL"{print $3}' <<< "$cob")"
if (( huerf > 0 )); then
    echo "Cobertura incompleta; corre --cobertura para el detalle." >&2
    exit 1
fi

SITE="$(mktemp -d /tmp/simulador-virgen.XXXXXX)"
mkdir -p "$SITE/05_scripts" "$SITE/raw/temp"
cp ensure_asset.ado SIMroot.ado "$SITE/"
cp 05_scripts/manifest.json "$SITE/05_scripts/"
tag="$(python3 -c "import json;print(json.load(open('05_scripts/manifest.json'))['release_tag'])")"
echo "SITE virgen: $SITE  (manifest $tag; raw/ vacio)"

# Las invocaciones REALES de los modulos, derivadas del inventario: cada
# directorio con ensure_asset, dir() y cada asset pedido por nombre.
{
    # Camino REAL del externo (v8.4): sin sysdir set SITE. Los .ado estan en el
    # adopath (aqui la carpeta misma; en un usuario real, PLUS via net install) y
    # la raiz del proyecto la resuelve SIMroot como el directorio de trabajo.
    echo "adopath ++ \"$SITE\""
    echo "cd \"$SITE\""
    awk -F'\t' '$1!="TOTAL" && $3 ~ /\[dir\(/ {sub(/.*\[dir\(/,"",$3); sub(/\)\]$/,"",$3); print $3}' <<< "$cob" | sort -u \
        | while read -r d; do echo "noisily ensure_asset, dir($d)"; done
    awk -F'\t' '$1!="TOTAL" && $3 !~ /\[dir\(/ {print $1}' <<< "$cob" \
        | while read -r n; do echo "noisily ensure_asset \"$n\""; done
} > "$SITE/virgen.do"

( cd "$SITE" && "$STATA" -b do "$SITE/virgen.do" < /dev/null )
if grep -qE '^r\([0-9]+\);' "$SITE/virgen.log"; then
    echo "Stata reporto error; ver $SITE/virgen.log" >&2
    grep -B3 -E '^r\([0-9]+\);' "$SITE/virgen.log" | head -20 >&2
    exit 1
fi

# Verificacion independiente: cada asset del manifest existe en el SITE con el SHA declarado.
fallas=0; total=0
while IFS=$'\t' read -r name lp sha; do
    total=$((total+1))
    f="$SITE/$lp"
    if [[ ! -f "$f" ]]; then echo "  - $name: NO descargado ($lp)"; fallas=$((fallas+1)); continue; fi
    actual="$(shasum -a 256 "$f" | awk '{print $1}')"
    [[ "$actual" == "$sha" ]] || { echo "  - $name: SHA distinto ($actual)"; fallas=$((fallas+1)); }
done < <(python3 -c "
import json
for a in json.load(open('05_scripts/manifest.json'))['assets']:
    print(a['name'], a['local_path'], a['sha256'], sep='\t')")

if (( fallas > 0 )); then
    echo "MAQUINA VIRGEN: $fallas de $total asset(s) fallaron. SITE conservado en $SITE para inspeccion."
    exit 1
fi
echo "MAQUINA VIRGEN: $total/$total assets descargados desde la Release $tag y verificados por SHA-256."
rm -rf "$SITE"
exit 0
