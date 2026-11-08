#!/usr/bin/env bash
# =============================================================================
# ritual.sh — el ritual de publicación (runbook §14) como script con paradas (8.18a-1)
# =============================================================================
# Lo que las sesiones v8.14.0–v8.15.2 hicieron a mano, un paso a la vez, ahora con cada paso como gate
# del siguiente. Corre en el worktree de publicación (default: el clon de este script; en la práctica
# ~/CIEP_Simuladores/SimuladorCIEP-datos) y escribe la evidencia en ~/CIEP_Simuladores/diag-<v>-<fecha>/.
#
#   1 merge           NO fusiona: verifica que origin/master sea --hash y que el árbol esté limpio;
#                     escribe <evidencia>/ritual.hash (lo leen los pasos siguientes al reanudar).
#   2 baile           worktree de publicación `checkout master` + `pull --ff-only`; HEAD = hash y árbol limpio.
#                     (8.16b, firma CUAD-1-2 §C: el clon de Dropbox es intocable; el ritual no lo toca.)
#   3 sim             correr-sim.sh → 01-ritual (~33 min): «end of do-file», 0 `r(#);`, commit.txt = hash
#                     sin cambios locales, gate-numeros VERDE (ROJO solo con --baseline-nuevo, que exige
#                     manifest.baseline = <v> y que la entrada [<v>] del CHANGELOG lo declare).
#   4 web             test-web-batch.sh → 02-test-web-batch: N/N llaves, N = llaves de output.txt (no se fija).
#   5 c32             contrato-32.sh --evidencia c32 --refs 01-ritual (~42 min): PASÓ y 32 meta.json.
#   6 precache        si users/<id>/cache/sello.txt ≠ manifest (data_updated, baseline): Precache suelto → 04-precache.
#   7 sidecar         publicar.sh <v> --empaquetar-datos; manifest-datos.json lleva el commit del hash.
#   8 release-commit  CHANGELOG [<v>] sin [Unreleased] huérfano; manifest version/release_tag/release_url_prefix;
#                     CITATION.cff con <v> y data_updated. Si falta algo aborta con la receta: no edita master.
#   9 tag             git tag -a <v> <hash literal> -m "<mensaje del CHANGELOG>" y push (pide confirmación salvo --si).
#  10 check           publicar.sh <v> --check: todos los gates (hoy 11/11; Gate 8 avisa que la Release no existe).
#  11 listo           imprime «listo para publicar: publicar.sh <v> y publicar-vps.sh <vN.M>».
#
# Reglas: cada paso anota inicio, fin y resultado en <evidencia>/ritual.log y guarda su salida completa en
# <evidencia>/ritual-<n>-<paso>.out (sin filtrar: también va a la terminal); los resúmenes y la única
# pregunta (antes de empujar el tag) van a /dev/tty, con stderr si no hay tty. Nunca llama a publicar.sh
# sin --check o --empaquetar-datos, ni a publicar-vps.sh: publicar es de Ricardo.
#
# Uso: bash 05_scripts/ritual.sh <version> [--hash <40 hex>] [--desde <paso>] [--hasta <paso>]
#        [--root <clon de publicación>] [--evidencia <dir>] [--baseline-nuevo] [--mensaje <mensaje del tag>] [--si]
#   <paso>       nombre (merge, baile, …, listo) o número (1–11).
#   --hash       hash COMPLETO del merge (runbook §14.1 lección 2: nunca una variable que pueda venir vacía).
#                Obligatorio para merge, baile y tag; los demás pasos lo leen de <evidencia>/ritual.hash
#                y, si no existe, usan el HEAD del clon de publicación (con aviso).
#   --evidencia  default: la diag-<v>-AAAA-MM-DD más reciente bajo $SIM_EVIDENCIA (~/CIEP_Simuladores);
#                si no hay, la de hoy. Así --desde reanuda en la misma carpeta aunque haya cambiado el día.
#   --si         no pregunta antes de empujar el tag (sesiones nocturnas sin tty).
# Exit 0 = los pasos pedidos pasaron; 1 = un paso falló (el log dice cuál y qué hacer); 2 = uso.
# =============================================================================
# Los paso_* se invocan por nombre ("paso_${PASO//-/_}"): shellcheck no los ve llamados.
# shellcheck disable=SC2329
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASOS=(merge baile sim web c32 precache sidecar release-commit tag check listo)
BASE="${SIM_EVIDENCIA:-$HOME/CIEP_Simuladores}"
VERSION=""; HASH=""; DESDE=1; HASTA=${#PASOS[@]}; ROOT=""; EVID=""; BASELINE_NUEVO=false; MENSAJE=""; SI=false

uso() { sed -n '/^# Uso:/,/^# Exit/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }
a_tty() { if { true > /dev/tty; } 2>/dev/null; then printf '%s\n' "$*" > /dev/tty; else printf '%s\n' "$*" >&2; fi; }
indice() {   # nombre o número de paso → número 1..11 (0 si no existe)
    local p="$1" i
    if [[ "$p" =~ ^[0-9]+$ ]]; then
        if (( p >= 1 && p <= ${#PASOS[@]} )); then echo "$p"; else echo 0; fi
        return
    fi
    for i in "${!PASOS[@]}"; do [[ "${PASOS[$i]}" == "$p" ]] && { echo $((i + 1)); return; }; done
    echo 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hash) HASH="${2:-}"; shift 2 ;;
        --desde) DESDE="$(indice "${2:-}")"; shift 2 ;;
        --hasta) HASTA="$(indice "${2:-}")"; shift 2 ;;
        --root) ROOT="${2:-}"; shift 2 ;;
        --dropbox) echo "ritual: --dropbox ya no existe (8.16b, firma CUAD-1-2 §C: el clon de Dropbox es intocable; el paso baile solo actualiza el clon de publicación)" >&2; uso ;;
        --evidencia) EVID="${2:-}"; shift 2 ;;
        --baseline-nuevo) BASELINE_NUEVO=true; shift ;;
        --mensaje) MENSAJE="${2:-}"; shift 2 ;;
        --si) SI=true; shift ;;
        -h|--help) uso ;;
        -*) echo "ritual: argumento desconocido: $1" >&2; uso ;;
        *) [[ -z "$VERSION" ]] || { echo "ritual: sobra el argumento $1" >&2; uso; }; VERSION="$1"; shift ;;
    esac
done
[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "ritual: <version> debe ser vX.Y.Z (recibí «${VERSION}»)" >&2; uso; }
(( DESDE >= 1 && HASTA >= 1 && DESDE <= HASTA )) || { echo "ritual: --desde/--hasta fuera de rango o invertidos (pasos: ${PASOS[*]})" >&2; exit 2; }
[[ -z "$HASH" || "$HASH" =~ ^[0-9a-f]{40}$ ]] || { echo "ritual: --hash debe ser el hash COMPLETO (40 hex), copiado literal: «${HASH}»" >&2; exit 2; }
ROOT="$(cd "${ROOT:-$HERE/..}" && git rev-parse --show-toplevel 2>/dev/null)" || { echo "ritual: --root no es un clon de git" >&2; exit 2; }
ID="$(whoami)"
VNM="${VERSION%.*}"

# --- carpeta de evidencia: la diag-<v>-<fecha> más reciente o la de hoy ---
if [[ -z "$EVID" ]]; then
    EVID="$(find "$BASE" -maxdepth 1 -type d -name "diag-$VERSION-20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" 2>/dev/null | sort | tail -n 1)"
    [[ -n "$EVID" ]] || EVID="$BASE/diag-$VERSION-$(date +%Y-%m-%d)"
fi
mkdir -p "$EVID" || { echo "ritual: no puedo crear $EVID" >&2; exit 2; }
EVID="$(cd "$EVID" && pwd)"
LOG="$EVID/ritual.log"

# --- hash: --hash > ritual.hash > HEAD del clon (con aviso) ---
if [[ -z "$HASH" && -f "$EVID/ritual.hash" ]]; then HASH="$(tr -d '[:space:]' < "$EVID/ritual.hash")"; ORIGEN_HASH="$EVID/ritual.hash"; else ORIGEN_HASH="--hash"; fi
for (( i = DESDE; i <= HASTA; i++ )); do
    case "${PASOS[$((i - 1))]}" in merge|baile|tag)
        [[ -n "$HASH" ]] || { echo "ritual: el paso ${PASOS[$((i - 1))]} exige --hash <40 hex> (o $EVID/ritual.hash de un paso merge previo)" >&2; exit 2; } ;;
    esac
done
if [[ -z "$HASH" ]]; then
    HASH="$(git -C "$ROOT" rev-parse HEAD)"; ORIGEN_HASH="HEAD de $ROOT (sin --hash ni ritual.hash)"
fi
CORTO="${HASH:0:7}"

# script del clon de publicación (el código que se publica); el de este checkout si el clon aún no lo tiene
script_de() { if [[ -f "$ROOT/05_scripts/$1" ]]; then echo "$ROOT/05_scripts/$1"; else echo "$HERE/$1"; fi; }
manifest() { python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get(sys.argv[2], ""))' "$ROOT/05_scripts/manifest.json" "$1"; }
anota() { printf '%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$*" >> "$LOG"; }
corre() {   # salida completa a la terminal y a $OUT; devuelve el exit del comando
    "$@" < /dev/null 2>&1 | tee -a "$OUT"
    return "${PIPESTATUS[0]}"
}
FALLA=""
falla() { FALLA="$*"; return 1; }
sin_corridas_vivas() {
    local v
    v="$(pgrep -fl 'correr-sim\.sh|contrato-32\.sh|compuertas-entidad\.sh|pibe-32\.sh|test-maquina-virgen\.sh|vintage-aportaciones|stata-(se|mp) -b' 2>/dev/null | grep -v "^$$ " || true)"
    [[ -z "$v" ]] || falla "hay corridas de Stata/evidencia vivas (candado del ritual): $(tr '\n' ';' <<< "$v")"
}
log_cerrado() {   # $1 = wrap.log: termina en «end of do-file» y sin r(#);
    [[ -f "$1" ]] || { falla "no existe $1"; return 1; }
    local fin n
    fin="$(grep -v '^[[:space:]]*$' "$1" | tail -n 1)"
    [[ "$fin" == *"end of do-file"* ]] || { falla "$1 no termina en «end of do-file» (termina en: ${fin:0:80})"; return 1; }
    n="$(grep -c 'r([0-9][0-9]*);' "$1")"
    [[ "$n" == 0 ]] || { falla "$1 tiene $n línea(s) r(#);"; return 1; }
}

# =============================================================================
# Pasos (cada uno devuelve 0 o llama a falla con la razón y la receta)
# =============================================================================
paso_merge() {
    corre git -C "$ROOT" fetch --prune --tags origin || { falla "git fetch falló"; return 1; }
    local om; om="$(git -C "$ROOT" rev-parse origin/master)"
    [[ "$om" == "$HASH" ]] || { falla "origin/master = $om, esperaba $HASH (¿falta el merge o el hash es de otro PR?)"; return 1; }
    [[ -z "$(git -C "$ROOT" status --short)" ]] || { falla "el árbol de $ROOT tiene cambios: $(git -C "$ROOT" status --short | head -3 | tr '\n' ';')"; return 1; }
    echo "$HASH" > "$EVID/ritual.hash"
    RESUMEN="origin/master = $CORTO, árbol limpio; $EVID/ritual.hash escrito"
}

paso_baile() {
    # 8.16b (firma CUAD-1-2 §C): el clon de Dropbox es intocable (ni stash, reset, checkout, switch, pull ni merge ahí); el ritual solo mueve el
    # clon de publicación. Si master sigue extraído en Dropbox, checkout master falla aquí y el remedio es de Ricardo, no del script.
    corre git -C "$ROOT" fetch -q origin || { falla "$ROOT: git fetch falló"; return 1; }
    corre git -C "$ROOT" checkout master || { falla "$ROOT: git checkout master falló (¿master sigue extraído en el clon de Dropbox? El ritual no lo toca: firma §C)"; return 1; }
    corre git -C "$ROOT" pull --ff-only || { falla "$ROOT: git pull --ff-only falló"; return 1; }
    [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$HASH" ]] || { falla "$ROOT quedó en $(git -C "$ROOT" rev-parse --short HEAD), no en $CORTO"; return 1; }
    [[ -z "$(git -C "$ROOT" status --short)" ]] || { falla "$ROOT tiene cambios tras el pull"; return 1; }
    RESUMEN="$ROOT en master = $CORTO, árbol limpio (Dropbox sin tocar: firma §C)"
}

paso_sim() {
    sin_corridas_vivas || return 1
    [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$HASH" ]] || { falla "$ROOT está en $(git -C "$ROOT" rev-parse --short HEAD), no en $CORTO: corre antes el paso baile"; return 1; }
    local d="$EVID/01-ritual"
    if [[ -e "$d" ]]; then
        local previa; previa="$d.previa-$(date +%Y%m%d-%H%M%S)"
        mv "$d" "$previa"; echo "ritual: la 01-ritual anterior se conserva como $previa" | tee -a "$OUT"
    fi
    corre bash "$(script_de correr-sim.sh)" "$ROOT" "$d"
    log_cerrado "$d/wrap.log" || return 1
    local c; c="$(head -n 1 "$d/commit.txt")"
    [[ -n "$c" && "$HASH" == "$c"* ]] || { falla "commit.txt = «${c}», esperaba $CORTO"; return 1; }
    [[ "$(wc -l < "$d/commit.txt" | tr -d ' ')" == 1 ]] || { falla "commit.txt declara cambios locales: $(sed -n '2,4p' "$d/commit.txt" | tr '\n' ';')"; return 1; }
    corre bash "$ROOT/05_scripts/gate-numeros.sh" "$d"; local g=$?
    case "$g" in
        0) RESUMEN="end of do-file, 0 r(#), commit $CORTO, gate-numeros VERDE ($(cat "$d/tiempo.txt" | head -n 1))" ;;
        1) if [[ "$BASELINE_NUEVO" == true ]]; then
               [[ "$(manifest baseline)" == "$VERSION" ]] || { falla "gate-numeros ROJO con --baseline-nuevo, pero manifest.baseline = $(manifest baseline), no $VERSION"; return 1; }
               python3 -I - "$ROOT/02_governance/CHANGELOG.md" "$VERSION" <<'PY' || { falla "gate-numeros ROJO con --baseline-nuevo, pero la entrada [$VERSION] del CHANGELOG no declara el baseline"; return 1; }
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'^## \[' + re.escape(sys.argv[2]) + r'\].*?(?=^## \[|\Z)', t, re.M | re.S)
sys.exit(0 if m and 'baseline' in m.group(0) else 1)
PY
               RESUMEN="gate-numeros ROJO ACEPTADO (--baseline-nuevo: manifest.baseline = $VERSION y el CHANGELOG lo declara)"
           else
               falla "gate-numeros ROJO: los números publicados cambiaron. Para aquí: reporte con el diff de llaves (ritual-3-sim.out); solo un release que mueve el baseline usa --baseline-nuevo"; return 1
           fi ;;
        *) falla "gate-numeros NO EVALUABLE (exit $g): faltan archivos en $d"; return 1 ;;
    esac
}

paso_web() {
    sin_corridas_vivas || return 1
    corre bash "$ROOT/05_scripts/test-web-batch.sh" --root "$ROOT" --evidencia "$EVID/02-test-web-batch" || { falla "test-web-batch ROJO (ver $EVID/02-test-web-batch/test-web-batch.md)"; return 1; }
    local n linea
    n="$(python3 -I - "$(script_de perfilar-web.py)" "$ROOT/users/ricardo/output.txt" <<'PY'
import importlib.util, sys
s = importlib.util.spec_from_file_location("pw", sys.argv[1]); m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
print(len(m.leer_output(sys.argv[2])))
PY
)"
    linea="$(grep -E '^OK +[0-9]+/[0-9]+ llaves' "$OUT" | tail -n 1)"
    [[ "$linea" =~ ([0-9]+)/([0-9]+) ]] || { falla "test-web-batch no imprimió «OK N/N llaves»"; return 1; }
    [[ "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" && "${BASH_REMATCH[2]}" == "$n" ]] || { falla "test-web-batch: ${BASH_REMATCH[1]}/${BASH_REMATCH[2]} llaves, pero output.txt tiene $n"; return 1; }
    RESUMEN="$n/$n llaves web = batch"
}

paso_c32() {
    sin_corridas_vivas || return 1
    corre bash "$ROOT/05_scripts/contrato-32.sh" --evidencia "$EVID/c32" --refs "$EVID/01-ritual" || { falla "contrato-32 FALLÓ (ver $EVID/c32/contrato-32.md)"; return 1; }
    grep -q '^- \*\*PASÓ\*\*' "$EVID/c32/contrato-32.md" 2>/dev/null || { falla "contrato-32.md no dice PASÓ"; return 1; }
    local m; m="$(find "$ROOT/users/$ID" -mindepth 2 -maxdepth 2 -name meta.json 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$m" == 32 ]] || { falla "hay $m meta.json en users/$ID/<ABREV>/, no 32"; return 1; }
    RESUMEN="PASÓ, 32/32 meta.json"
}

sello() { awk -F'\t' -v k="$1" '$1 == "sello" && $2 == k { print $3 }' "$ROOT/users/$ID/cache/sello.txt" 2>/dev/null; }
paso_precache() {
    local du bl
    du="$(manifest data_updated)"; bl="$(manifest baseline)"
    if [[ "$(sello data_updated)" == "$du" && "$(sello baseline)" == "$bl" ]]; then
        RESUMEN="no hace falta: sello del cache = manifest (data_updated $du, baseline $bl; version $(sello version), commit $(sello commit))"
        echo "$RESUMEN" | tee -a "$OUT"; return 0
    fi
    sin_corridas_vivas || return 1
    local d="$EVID/04-precache" sim="$ROOT/SIM.do" STATA="${STATA:-/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se}"
    mkdir -p "$d"
    # globals y escalares que Precache exige, leídos de SIM.do §0 (no se fijan aquí)
    local bs vp pe en
    bs="$(sed -nE 's/^global bootstrap "([0-9]+)".*/\1/p' "$sim" | head -n 1)"
    vp="$(sed -nE 's/^scalar aniovp = ([0-9]+).*/\1/p' "$sim" | head -n 1)"
    pe="$(sed -nE 's/^scalar anioPE = ([0-9]+).*/\1/p' "$sim" | head -n 1)"
    en="$(sed -nE 's/^scalar anioenigh = ([0-9]+).*/\1/p' "$sim" | head -n 1)"
    [[ -n "$bs" && -n "$vp" && -n "$pe" && -n "$en" ]] || { falla "no pude leer bootstrap/aniovp/anioPE/anioenigh de SIM.do"; return 1; }
    printf 'capture set processors 1\nset linesize 200\nglobal SIMROOT "%s"\nsysdir set SITE "%s/"\nadopath ++SITE\ncd "%s"\nglobal id "%s"\nglobal idbase "%s"\nglobal bootstrap "%s"\nscalar aniovp = %s\nscalar anioPE = %s\nscalar anioenigh = %s\nnoisily Precache, aniope(%s) aniovp(%s)\n' \
        "$ROOT" "$ROOT" "$ROOT" "$ID" "$ID" "$bs" "$vp" "$pe" "$en" "$pe" "$vp" > "$d/wrap.do"
    ( cd "$d" && "$STATA" -b "do" "$d/wrap.do" < /dev/null )
    cat "$d/wrap.log" >> "$OUT" 2>/dev/null
    log_cerrado "$d/wrap.log" || return 1
    [[ "$(sello data_updated)" == "$du" && "$(sello baseline)" == "$bl" ]] || { falla "tras Precache el sello sigue ≠ manifest"; return 1; }
    RESUMEN="Precache suelto: sello = manifest (data_updated $du, baseline $bl)"
}

paso_sidecar() {
    (cd "$ROOT" && corre bash 05_scripts/publicar.sh "$VERSION" --empaquetar-datos) || { falla "publicar.sh $VERSION --empaquetar-datos falló"; return 1; }
    local m="$ROOT/users/_sidecar/$VERSION/manifest-datos.json" c
    [[ -f "$m" ]] || { falla "no existe $m"; return 1; }
    c="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("commit", ""))' "$m")"
    [[ -n "$c" && "$HASH" == "$c"* ]] || { falla "manifest-datos.json dice commit «${c}», esperaba $CORTO"; return 1; }
    RESUMEN="sidecar $VERSION: commit $c, data_updated $(manifest data_updated), baseline $(manifest baseline)"
}

paso_release_commit() {
    local errores
    errores="$(python3 -I - "$ROOT" "$VERSION" <<'PY'
import json, re, sys
root, v = sys.argv[1:3]
ch = open(f"{root}/02_governance/CHANGELOG.md", encoding="utf-8").read()
if not re.search(r'^## \[' + re.escape(v) + r'\]', ch, re.M):
    print(f"CHANGELOG.md no tiene la entrada «## [{v}]»")
if re.search(r'^## \[Unreleased\]', ch, re.M | re.I):
    print("CHANGELOG.md tiene un «## [Unreleased]» huérfano: su contenido va dentro de la entrada de la versión")
m = json.load(open(f"{root}/05_scripts/manifest.json", encoding="utf-8"))
for k in ("version", "release_tag"):
    if m.get(k) != v:
        print(f"manifest.json: {k} = «{m.get(k)}», esperaba «{v}»")
if not m.get("release_url_prefix", "").endswith(f"/{v}/"):
    print(f"manifest.json: release_url_prefix = «{m.get('release_url_prefix')}» no termina en «/{v}/»")
cff = open(f"{root}/CITATION.cff", encoding="utf-8").read()
vs = set(re.findall(r'^\s*version: "(.*)"', cff, re.M)); ds = set(re.findall(r'^\s*date-released: "(.*)"', cff, re.M))
if vs != {v} or ds != {m.get("data_updated")} or f"releases/tag/{v}" not in cff:
    print(f"CITATION.cff no está sincronizado (version {sorted(vs)}, date-released {sorted(ds)}; manifest {v}, {m.get('data_updated')})")
PY
)"
    printf '%s\n' "${errores:-release commit completo}" | tee -a "$OUT"
    if [[ -n "$errores" ]]; then
        falla "falta el release commit. Receta: PR corto (no push directo a master: branch protection) con CHANGELOG [$VERSION], manifest.json (version, release_tag, release_url_prefix) y CITATION.cff (bash 05_scripts/publicar.sh --citation); merge, y el ritual vuelve a empezar en merge con el hash nuevo"
        return 1
    fi
    RESUMEN="CHANGELOG [$VERSION], manifest y CITATION sincronizados"
}

mensaje_tag() {   # «<v> — <título del encabezado>» o, si el encabezado no tiene título, el primer ### de la entrada
    python3 -I - "$ROOT/02_governance/CHANGELOG.md" "$VERSION" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read(); v = sys.argv[2]
m = re.search(r'^## \[' + re.escape(v) + r'\][^\n]*?(?: — \d{4}-\d{2}-\d{2})?(?: — (?P<t>[^\n]+))?\n(?P<cuerpo>.*?)(?=^## \[|\Z)', t, re.M | re.S)
if not m: sys.exit(1)
titulo = m.group('t') or next((l[4:] for l in m.group('cuerpo').splitlines() if l.startswith('### ')), '')
titulo = re.sub(r'\s+', ' ', titulo.replace('`', '')).strip()
print(f"{v} — {titulo}" if titulo else v)
PY
}
paso_tag() {
    git -C "$ROOT" cat-file -e "$HASH^{commit}" 2>/dev/null || { falla "$HASH no es un commit en $ROOT"; return 1; }
    local msg="$MENSAJE" local_t remoto
    [[ -n "$msg" ]] || msg="$(mensaje_tag)" || { falla "no pude sacar el mensaje del tag del CHANGELOG (usa --mensaje)"; return 1; }
    if git -C "$ROOT" rev-parse -q --verify "refs/tags/$VERSION" > /dev/null; then
        local_t="$(git -C "$ROOT" rev-parse "$VERSION^{commit}")"
        [[ "$local_t" == "$HASH" ]] || { falla "el tag $VERSION ya existe y apunta a ${local_t:0:7}, no a $CORTO (no lo muevo: bórralo a mano si es un ensayo)"; return 1; }
        [[ "$(git -C "$ROOT" cat-file -t "refs/tags/$VERSION")" == tag ]] || { falla "el tag $VERSION existe pero es ligero, no anotado"; return 1; }
        echo "ritual: el tag $VERSION ya existe, anotado, en $CORTO" | tee -a "$OUT"
    else
        if [[ "$SI" != true ]]; then
            { true > /dev/tty; } 2>/dev/null || { falla "no hay tty para confirmar el tag: repite con --si si es una sesión sin terminal"; return 1; }
            a_tty "ritual: git tag -a $VERSION $HASH -m \"$msg\" y git push origin $VERSION"
            local r; printf '¿Crear y empujar el tag? [s/N] ' > /dev/tty; read -r r < /dev/tty
            [[ "$r" == [sS] ]] || { falla "tag cancelado por el usuario"; return 1; }
        fi
        corre git -C "$ROOT" tag -a "$VERSION" "$HASH" -m "$msg" || { falla "git tag falló"; return 1; }
    fi
    remoto="$(git -C "$ROOT" ls-remote --tags origin "refs/tags/$VERSION^{}" | cut -f1)"
    if [[ -z "$remoto" ]]; then
        corre git -C "$ROOT" push origin "refs/tags/$VERSION" || { falla "git push origin $VERSION falló"; return 1; }
        remoto="$(git -C "$ROOT" ls-remote --tags origin "refs/tags/$VERSION^{}" | cut -f1)"
    fi
    [[ "$remoto" == "$HASH" ]] || { falla "el tag $VERSION en origin apunta a ${remoto:-(nada)}, no a $CORTO"; return 1; }
    RESUMEN="tag $VERSION anotado en $CORTO y en origin: «${msg}»"
}

paso_check() {
    [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$HASH" ]] || { falla "$ROOT está en $(git -C "$ROOT" rev-parse --short HEAD), no en $CORTO"; return 1; }
    if git -C "$ROOT" rev-parse -q --verify "refs/tags/$VERSION" > /dev/null; then
        [[ "$(git -C "$ROOT" rev-parse "$VERSION^{commit}")" == "$HASH" ]] || { falla "el tag $VERSION no apunta a $CORTO"; return 1; }
    fi
    (cd "$ROOT" && corre bash 05_scripts/publicar.sh "$VERSION" --check) || { falla "publicar.sh $VERSION --check: algún gate falló (ver ritual-10-check.out)"; return 1; }
    local linea; linea="$(grep -E -- '--check: los [0-9]+ gates pasaron' "$OUT" | tail -n 1)"
    [[ "$linea" =~ los\ ([0-9]+)\ gates ]] || { falla "publicar.sh --check salió 0 pero no imprimió «los N gates pasaron»"; return 1; }
    RESUMEN="${BASH_REMATCH[1]}/${BASH_REMATCH[1]} gates de publicar.sh --check"
    if grep -q 'Gate 8: la Release .* aun no existe' "$OUT"; then RESUMEN="$RESUMEN (Gate 8: la Release aún no existe, normal antes de publicar)"; fi
    return 0
}

paso_listo() {
    RESUMEN="listo para publicar: \`publicar.sh $VERSION\` y \`publicar-vps.sh $VNM\`"
    echo "$RESUMEN" | tee -a "$OUT"
}

# =============================================================================
a_tty "ritual $VERSION — pasos ${DESDE}–${HASTA} (${PASOS[*]:$((DESDE - 1)):$((HASTA - DESDE + 1))}) · hash $HASH ($ORIGEN_HASH) · clon $ROOT · evidencia $EVID"
anota "sesión	$VERSION	pasos $DESDE-$HASTA	hash $HASH ($ORIGEN_HASH)	root $ROOT"
for (( i = DESDE; i <= HASTA; i++ )); do
    PASO="${PASOS[$((i - 1))]}"; OUT="$EVID/ritual-$i-$PASO.out"; RESUMEN=""; FALLA=""
    : > "$OUT"
    T0=$(date +%s)
    anota "inicio	$i $PASO"
    a_tty "── paso $i/$((${#PASOS[@]})) $PASO"
    if "paso_${PASO//-/_}"; then
        anota "fin	$i $PASO	OK	$(( $(date +%s) - T0 )) s	$RESUMEN"
        a_tty "   OK  $PASO: $RESUMEN"
    else
        [[ -n "$FALLA" ]] || FALLA="el paso devolvió error sin decir por qué (bug de ritual.sh: revisa $OUT)"
        anota "fin	$i $PASO	FALLÓ	$(( $(date +%s) - T0 )) s	$FALLA"
        a_tty "   FALLÓ  $PASO: $FALLA"
        a_tty "   salida completa: $OUT · reanudar: bash 05_scripts/ritual.sh $VERSION --desde $PASO --evidencia $EVID"
        exit 1
    fi
done
a_tty "ritual $VERSION: pasos ${DESDE}–${HASTA} OK · log $LOG"
exit 0
