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
#                --from <tag>  (v8.11a) baja los assets de la Release <tag> en lugar
#                de la del manifest: para el huevo-y-gallina de un release en curso
#                (el manifest ya dice vX.Y.Z pero publicar.sh aun no creo su
#                Release; 2026-10-16). Los SHA se verifican contra el manifest
#                LOCAL: pasa solo si los assets no cambiaron entre <tag> y hoy.
#                --into <dir>  deposita cada asset en <dir>/<local_path> (p. ej.
#                la raiz de un worktree sin raw/) y lo conserva; sin --into el
#                SITE es temporal y se borra al pasar.
#
#   --zip        (dinamico, ~1 min, sin red)  La via del ALUMNO (2026-10-05): ZIP de
#                GitHub sin git, carpeta con nombre arbitrario y espacios, sin
#                profile.do cargado, sin sysdir set SITE. Se arma una copia
#                `git archive` del arbol en /tmp, se escribe la ruta de esa copia en
#                la linea `global SIMROOT` de SIM.do (la unica instruccion que da el
#                README al alumno) y se verifica que, con el setup de SIM.do 0
#                (global + adopath + scheme), los .ado del motor se encuentran despues
#                de un cd (la clase de falla "command LIF is unrecognized"). Con
#                --completo, corre SIM.do entero (descarga ~1.3 GB y construye todo:
#                ~1 h) y exige TOUCH-DOWN.
#
# Uso: bash 05_scripts/test-maquina-virgen.sh --cobertura
#      bash 05_scripts/test-maquina-virgen.sh --download [--stata <ruta stata-se>]
#      bash 05_scripts/test-maquina-virgen.sh --download --from <tag> [--into <dir>]
#      bash 05_scripts/test-maquina-virgen.sh --zip [--completo] [--stata <ruta>]
# Exit 0 si pasa; 1 si falla (lista lo que falta).

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
[[ -z "$REPO_ROOT" ]] && { echo "No se pudo detectar root del repo Git." >&2; exit 1; }
cd "$REPO_ROOT"

MODE=""
STATA=""
COMPLETO=false
FROM_TAG=""
INTO_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cobertura) MODE="cobertura"; shift ;;
        --download)  MODE="download"; shift ;;
        --zip)       MODE="zip"; shift ;;
        --completo)  COMPLETO=true; shift ;;
        --stata)     STATA="$2"; shift 2 ;;
        --from)      FROM_TAG="${2:-}"; shift 2 ;;
        --into)      INTO_DIR="${2:-}"; shift 2 ;;
        *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
done
[[ -z "$MODE" ]] && { echo "Uso: $0 --cobertura | --download [--stata <ruta>] [--from <tag> [--into <dir>]] | --zip [--completo]" >&2; exit 1; }
if [[ -n "$FROM_TAG" || -n "$INTO_DIR" ]] && [[ "$MODE" != "download" ]]; then
    echo "--from/--into solo aplican con --download." >&2; exit 1
fi
if [[ -n "$INTO_DIR" && -z "$FROM_TAG" ]]; then
    echo "--into requiere --from <tag> (la via sin Stata que deposita los assets en su local_path)." >&2; exit 1
fi
if [[ -n "$FROM_TAG" && ! "$FROM_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "--from espera un tag de Release vN.M.P (recibido: '$FROM_TAG')." >&2; exit 1
fi

# ─── sim_run <SIM.do origen> <destino> <raiz> [global ...] ───
# Copia de SIM.do para correr en batch: la raiz va en la linea `global SIMROOT` (lo unico
# que edita un usuario) y los globals pedidos se insertan tras `macro drop _all`, asi
# sobreviven al borrado de macros y mandan sobre los `//global` comentados de 0.4.
sim_run() {
python3 - "$@" <<'PYEOF'
import re, sys
src, dst, root, *globs = sys.argv[1:]
t = open(src, encoding="utf-8").read()
t, n = re.subn(r'^global SIMROOT ".*?"', 'global SIMROOT "%s"' % root, t, count=1, flags=re.M)
if n != 1:
    sys.exit("sim_run: no se encontro la linea 'global SIMROOT \"...\"' en " + src)
marca = "macro drop _all\n"
if marca not in t:
    sys.exit("sim_run: no se encontro 'macro drop _all' en " + src)
t = t.replace(marca, marca + "".join(g + "\n" for g in globs), 1)
open(dst, "w", encoding="utf-8").write(t)
PYEOF
}

# ─── Inventario del manifest y de las invocaciones de ensure_asset ───
# Emite lineas "name<TAB>local_path<TAB>solicitado_por" (solicitado_por vacio = huerfano).
cobertura() {
python3 - <<'PYEOF'
import json, re, glob, os, sys
m = json.load(open("05_scripts/manifest.json", encoding="utf-8"))
fuentes = glob.glob("*.ado") + glob.glob("01_modulos/*.do") + ["SIM.do"]
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

# ─── --download --from <tag>: los assets de OTRA Release, cada uno en su local_path ───
# Sin Stata: ensure_asset solo sabe bajar de la Release del manifest (release_url_prefix),
# que durante un release en curso aun no existe. Aqui se baja con gh de la Release <tag>
# (patron de publicar.sh --poblar-raw), se deposita en <dest>/<local_path> — no plano en
# raw/ — y se verifica el SHA contra el manifest LOCAL: si un asset cambio entre <tag> y
# el manifest de hoy, se reporta y no se instala. Con --into <dir> los assets se quedan
# (p. ej. --into "$PWD" en un worktree sin raw/); sin --into, el destino es temporal.
if [[ "$MODE" == "download" && -n "$FROM_TAG" ]]; then
    command -v gh >/dev/null 2>&1 || { echo "--from requiere gh (GitHub CLI) autenticado." >&2; exit 1; }
    # El repo de GitHub sale del manifest (release_url_prefix), no del remoto: un
    # worktree o clon de prueba puede no tener remoto hacia GitHub y gh fallaria.
    GH_REPO_SLUG="$(python3 -c "
import json, re
p = json.load(open('05_scripts/manifest.json'))['release_url_prefix']
m = re.match(r'https://github\.com/([^/]+/[^/]+)/releases/download/', p)
print(m.group(1) if m else '')")"
    [[ -n "$GH_REPO_SLUG" ]] || { echo "release_url_prefix del manifest no tiene la forma https://github.com/<owner>/<repo>/releases/download/…" >&2; exit 1; }
    gh release view "$FROM_TAG" --repo "$GH_REPO_SLUG" >/dev/null 2>&1 || { echo "La Release $FROM_TAG no existe en $GH_REPO_SLUG (gh release list --repo $GH_REPO_SLUG)." >&2; exit 1; }
    tag_manifest="$(python3 -c "import json;print(json.load(open('05_scripts/manifest.json'))['release_tag'])")"
    if [[ -n "$INTO_DIR" ]]; then
        mkdir -p "$INTO_DIR" || { echo "No pude crear $INTO_DIR." >&2; exit 1; }
        DEST="$(cd "$INTO_DIR" && pwd)"
    else
        DEST="$(mktemp -d /tmp/simulador-virgen-from.XXXXXX)"
    fi
    echo "Assets de la Release $FROM_TAG → $DEST/<local_path>  (manifest local: $tag_manifest; SHA contra el manifest local)"
    tmp_dl="$(mktemp -d /tmp/simulador-virgen-dl.XXXXXX)"
    bajados=0; presentes=0; fallas=0; total=0
    while IFS=$'\t' read -r name lp sha; do
        total=$((total+1))
        f="$DEST/$lp"
        if [[ -f "$f" ]]; then
            actual="$(shasum -a 256 "$f" | awk '{print $1}')"
            if [[ "$actual" == "$sha" ]]; then presentes=$((presentes+1)); continue; fi
            echo "  - $name: ya existe en $lp con SHA distinto al manifest (${actual:0:12}...); no se toca" >&2
            fallas=$((fallas+1)); continue
        fi
        rm -f "$tmp_dl/$name"
        if ! gh release download "$FROM_TAG" --repo "$GH_REPO_SLUG" --pattern "$name" --dir "$tmp_dl" 2>/dev/null || [[ ! -f "$tmp_dl/$name" ]]; then
            echo "  - $name: no esta en la Release $FROM_TAG (o la descarga fallo)" >&2
            fallas=$((fallas+1)); continue
        fi
        actual="$(shasum -a 256 "$tmp_dl/$name" | awk '{print $1}')"
        if [[ "$actual" != "$sha" ]]; then
            echo "  - $name: SHA en $FROM_TAG ${actual:0:12}... != manifest local ${sha:0:12}... (el asset cambio entre versiones; no se instala)" >&2
            fallas=$((fallas+1)); rm -f "$tmp_dl/$name"; continue
        fi
        mkdir -p "$(dirname "$f")"
        mv "$tmp_dl/$name" "$f"
        echo "  + $name → $lp"
        bajados=$((bajados+1))
    done < <(python3 -c "
import json
for a in json.load(open('05_scripts/manifest.json'))['assets']:
    print(a['name'], a['local_path'].replace('\\\\', '/'), a['sha256'], sep='\t')")
    rm -rf "$tmp_dl"
    if (( fallas > 0 )); then
        echo "MAQUINA VIRGEN (--from $FROM_TAG): $fallas de $total asset(s) fallaron; $bajados descargados, $presentes ya estaban. Destino conservado: $DEST"
        exit 1
    fi
    if [[ -n "$INTO_DIR" ]]; then
        echo "MAQUINA VIRGEN (--from $FROM_TAG): $total/$total assets en $DEST/<local_path> con el SHA del manifest ($bajados descargados, $presentes ya estaban)."
    else
        echo "MAQUINA VIRGEN (--from $FROM_TAG): $total/$total assets de la Release $FROM_TAG coinciden con el manifest $tag_manifest ($bajados descargados)."
        rm -rf "$DEST"
    fi
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

    # Lo que hace el alumno: escribir su carpeta en la linea `global SIMROOT` de SIM.do
    sim_run "$ZIPDIR/SIM.do" "$ZIPDIR/SIM_zip.do" "$ZIPDIR" 'global nographs "nographs"'   # batch: sin ventana de graficas
    mv "$ZIPDIR/profile.do" "$ZIPDIR/profile.do.off"   # sin profile.do: solo el setup de SIM.do 0

    # Humo: el setup de SIM.do 0 (global + adopath + scheme) y los .ado visibles tras un cd
    {
        printf 'global SIMROOT "%s"\nadopath ++ "${SIMROOT}"\nset scheme ciep\n' "$ZIPDIR"
        printf 'capture mkdir "${SIMROOT}/raw"\ncapture mkdir "${SIMROOT}/raw/temp"\ncd "${SIMROOT}/raw/temp"\n'
        for a in ensure_asset Poblacion PIBDeflactor SCN LIF PEF TasasEfectivas GastoPC perfilpc Simulador FiscalGap escalar; do
            printf 'which %s\n' "$a"
        done
        printf 'di "SMOKE_OK"\n'
    } > "$ZIPDIR/smoke.do"
    ( cd "$ZIPDIR" && "$STATA" -b do smoke.do < /dev/null )
    if grep -q "SMOKE_OK" "$ZIPDIR/smoke.log" && ! grep -qE '^r\([0-9]+\);' "$ZIPDIR/smoke.log"; then
        echo "  (humo) global SIMROOT + adopath: scheme y .ado visibles tras cd  OK"
    else
        echo "  (humo) FALLO; ver $ZIPDIR/smoke.log" >&2
        grep -B3 -E 'unrecognized|not found|^r\([0-9]+\);' "$ZIPDIR/smoke.log" | head -12 >&2; fallas=$((fallas+1))
    fi

    if [[ "$COMPLETO" == "true" && $fallas -eq 0 ]]; then
        echo "  (completo) SIM.do entero sin profile.do ni SITE (descarga assets y construye; ~1 h)..."
        ( cd "$ZIPDIR" && "$STATA" -b do SIM_zip.do < /dev/null )
        if grep -q "TOUCH-DOWN" "$ZIPDIR/SIM_zip.log" && ! grep -qE '^r\([0-9]+\);' "$ZIPDIR/SIM_zip.log"; then
            echo "  (completo) TOUCH-DOWN  OK"
        else
            echo "  (completo) FALLO; ver $ZIPDIR/SIM_zip.log" >&2
            grep -B4 -E '^r\([0-9]+\);' "$ZIPDIR/SIM_zip.log" | head -12 >&2; fallas=$((fallas+1))
        fi
    fi
    mv "$ZIPDIR/profile.do.off" "$ZIPDIR/profile.do"

    if (( fallas > 0 )); then
        echo "ZIP SIN GIT: $fallas prueba(s) fallaron. Copia conservada en $BASE."; exit 1
    fi
    echo "ZIP SIN GIT: la via del alumno pasa (copia en $BASE; borrala cuando quieras)."
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
cp ensure_asset.ado "$SITE/"
cp 05_scripts/manifest.json "$SITE/05_scripts/"
tag="$(python3 -c "import json;print(json.load(open('05_scripts/manifest.json'))['release_tag'])")"
echo "SITE virgen: $SITE  (manifest $tag; raw/ vacio)"

# Las invocaciones REALES de los modulos, derivadas del inventario: cada
# directorio con ensure_asset, dir() y cada asset pedido por nombre.
{
    # Camino REAL del externo (v8.4): sin sysdir set SITE. Los .ado estan en el
    # adopath (aqui la carpeta misma; en un usuario real, PLUS via net install) y
    # la raiz del proyecto es la global SIMROOT.
    echo "global SIMROOT \"$SITE\""
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
