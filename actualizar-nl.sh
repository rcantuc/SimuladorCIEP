#!/bin/zsh
# actualizar-nl.sh — actualización de los endpoints NL en UN comando (capa NL-0.4.0).
#
#   1. Corre Stata en batch desde la raíz del worktree (profile.do carga aniovp,
#      anioPE, entidades y token): PoblacionNL.do + PIBDeflactorNL.do + FederacionNL.do
#      (este último en modo canal si existen statajson_entidad-nl.json, LIF.dta y PEF.dta;
#      si no, en modo sello con nl-assets/federacion-sello.json).
#   2. FALLO SEGURO: si INEGI no responde, una compuerta aborta o el log trae un
#      error de Stata, NO publica, restaura los últimos JSON/HTML buenos en
#      users/ricardo/nodos/ y deja el detalle en users/ricardo/actualizar-nl.log
#      (los productos del Drive no se tocan). Nunca publica un endpoint a medias.
#   3. Si todo pasa: ./publicar-conl.sh y una línea en
#      01_modulos/nl-assets/bitacora-publicaciones.log (fecha, vintages, SHAs).
#
# Uso: ./actualizar-nl.sh [--offline]      (--offline: reutiliza la caché INEGI)
set -u
ROOT="$HOME/CIEP_Simuladores/SimuladorCIEP-NL"
STATA="/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"
NODOS="$ROOT/users/ricardo/nodos"
LOCAL_LOG="$ROOT/users/ricardo/actualizar-nl.log"
BITACORA="$ROOT/01_modulos/nl-assets/bitacora-publicaciones.log"
DRIVE="/Users/ricardo/Library/CloudStorage/GoogleDrive-rcantu@conl.mx/My Drive/2. Simuladores CoNL/SimuladorCoNL"
OFFLINE=0
[[ "${1:-}" == "--offline" ]] && OFFLINE=1

log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOCAL_LOG"; }
fail() {
  log "ABORTA: $*"
  if [[ -d "$BAK" ]]; then
    rm -f "$NODOS"/*.json "$NODOS"/*.html
    cp -p "$BAK"/* "$NODOS"/ 2>/dev/null
    log "Restaurados los últimos JSON/HTML buenos en $NODOS (el Drive no se tocó)."
  fi
  exit 1
}

mkdir -p "$NODOS"
log "== actualizar-nl inicio (offline=$OFFLINE) =="
[[ -x "$STATA" ]] || fail "no se encontró Stata en $STATA"
[[ -f "$ROOT/profile.do" && -f "$ROOT/01_modulos/PIBDeflactorNL.do" ]] || fail "raíz del worktree incompleta: $ROOT"

# Respaldo de los últimos productos buenos
BAK="$(mktemp -d "${TMPDIR:-/tmp}/nl-nodos-bak.XXXXXX")"
cp -p "$NODOS"/*.json "$NODOS"/*.html "$BAK"/ 2>/dev/null
log "Respaldo de productos previos en $BAK"

# Corrida Stata en batch desde la raíz (carga profile.do)
cd "$ROOT" || fail "no se pudo entrar a $ROOT"
rm -f "$ROOT/actualizar-nl-stata.log"            # Stata batch deja el log en el cwd
WRAP="$ROOT/users/ricardo/actualizar-nl-stata.do"
{
  [[ $OFFLINE -eq 1 ]] && echo 'global nlbie_offline 1'
  echo "do \"$ROOT/01_modulos/nl-assets/actualizar-nl.do\""
} > "$WRAP"
"$STATA" -b do "$WRAP"
RC=$?
SLOG="$ROOT/actualizar-nl-stata.log"
[[ -f "$SLOG" ]] || fail "Stata no dejó log ($SLOG), rc=$RC"
if grep -q -E '^r\([0-9]+\);' "$SLOG"; then
  ERR="$(grep -n -E '^r\([0-9]+\);' "$SLOG" | head -1)"
  CTX="$(grep -B4 -m1 -E '^r\([0-9]+\);' "$SLOG" | head -5 | tr '\n' ' ')"
  fail "error de Stata ($ERR): $CTX"
fi
grep -q 'PoblacionNL: listo' "$SLOG" || fail "PoblacionNL.do no llegó al final"
grep -q 'PIBDeflactorNL: listo' "$SLOG" || fail "PIBDeflactorNL.do no llegó al final"
grep -q 'FederacionNL: listo' "$SLOG" || fail "FederacionNL.do no llegó al final"
grep -q 'LOS TRES DRIVERS TERMINARON' "$SLOG" || fail "la corrida conjunta no terminó"
for f in poblacion-nl.json poblacion-nl.html actividad-nl.json actividad-nl.html federacion-nl.json federacion-nl.html; do
  [[ -s "$NODOS/$f" ]] || fail "falta o está vacío $NODOS/$f"
done
mv -f "$SLOG" "$NODOS/actualizar-nl-stata.log"
log "Stata OK: compuertas en verde, 6 productos generados"

# Publicación
[[ -d "${DRIVE:h}" ]] || fail "Drive de CoNL no montado (${DRIVE:h}); no se publica"
"$ROOT/publicar-conl.sh" > "$ROOT/users/ricardo/publicar-conl.out" 2>&1 || fail "publicar-conl.sh devolvió error (ver users/ricardo/publicar-conl.out)"
for f in poblacion-nl.html actividad-nl.html federacion-nl.html; do
  [[ -s "$DRIVE/$f" ]] || fail "no quedó $f en el Drive"
done

# Bitácora (commiteada): fecha, vintages y SHAs publicados
VINT_POB="$(python3 -c "import json;j=json.load(open('$NODOS/poblacion-nl.json'));p=j['procedencia'];print('pob: ' + p['cobertura_estatal'] + '; mun ' + p['cobertura_municipal'].split(',')[0] + '; corrida ' + p['generado_en'])")"
VINT_ACT="$(python3 -c "import json;j=json.load(open('$NODOS/actividad-nl.json'));p=j['procedencia'];s={x['variable']:x for x in p['series']};u=lambda k:(s[k]['ultimo']+(' '+s[k]['sello_ultimo'] if s[k].get('sello_ultimo') else ''));print('act: PIBE hasta ' + u('pibeNnl') + '; ITAEE ' + u('itaeenl') + '; INPC NL ' + u('inpcnl') + '; INPC nac ' + u('inpcnac') + '; consulta INEGI ' + s['pibeNnl']['consulta'] + '; corrida ' + p['generado_en'])")"
VINT_FED="$(python3 -c "import json;j=json.load(open('$NODOS/federacion-nl.json'));p=j['procedencia'];f={x['id']:x for x in p['fuentes']};print('fed: modo ' + p['modo'] + '; EOFP hasta ' + f['eopf_transferencias']['periodo_final'] + ' (Last-Modified ' + f['eopf_transferencias']['last_modified'].split(';')[0].split('=')[-1] + '); ref ' + str(j['anio_referencia']) + '; sello ' + f['sello']['generado_en'] + '; corrida ' + p['generado_en'])")"
SHAS="$(cd "$DRIVE" && shasum -a 256 poblacion-nl.html actividad-nl.html federacion-nl.html nodos/poblacion-nl.json nodos/actividad-nl.json nodos/federacion-nl.json | awk '{printf "%s=%s ", $2, substr($1,1,12)}')"
VNL="$(python3 -c "import json;print(json.load(open('$ROOT/01_modulos/nl-assets/nl-manifest.json'))['version_nl'])")"
print -r -- "$(date '+%Y-%m-%dT%H:%M:%S') capa=$VNL | $VINT_POB | $VINT_ACT | $VINT_FED | sha256(12): $SHAS" >> "$BITACORA"
log "Publicado y registrado en bitácora: $(tail -1 "$BITACORA")"
rm -rf "$BAK"
log "== actualizar-nl fin OK =="
