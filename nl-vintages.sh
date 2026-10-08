#!/bin/zsh
# nl-vintages.sh — participaciones de NL por vintage ENIGH bienal en UN comando (capa NL-0.5.1; solo Mac).
#
#   1. Corre, en batch y en serie, nl-vintage.do para cada ENIGH (2016 2018 2020 2022 2024):
#      motor con anioPE = aniovp = anioenigh = vintage (calibración contemporánea, sin los
#      parámetros del Paquete) + EntidadNL.do en la misma sesión (compuerta D.1). Construye las
#      cachés master/<vintage>/ si faltan (~20 min la primera vez; ~11 min con cachés).
#   2. Corre nl-vintages-sello.do: compuertas (identidad, Rec = LIF observada, Part = Rec/Rec,
#      muestra) y escribe 01_modulos/nl-assets/participaciones-vintages.json (commiteable).
#   3. FALLO SEGURO: si una corrida truena, no se escribe el sello y el anterior queda intacto.
#   Después: SIM.do + EntidadNL.do (corrida vigente), FederacionNL con `global nlfed_sellar 1`,
#   ./actualizar-nl.sh y commit de los dos sellos (ver DIAGNOSTICO_NL.md, anexo Participaciones).
#
# Uso: ./nl-vintages.sh [2016 2018 ...]     (sin argumentos: los cinco)
#      NLVINT_LIGHT=1 ./nl-vintages.sh       (desarrollo: modo ligero de nl-vintage.do; NO sellar para publicar)
#      STATA=<ruta a stata-se|stata-mp> ... (NL-0.5.2: ejecutable de Stata; default StataMP 17. El ancla v8.8.0 se declaró con StataNow 19.5 SE y 1 procesador)
set -u
ROOT="$HOME/CIEP_Simuladores/SimuladorCIEP-NL"
STATA="${STATA:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}"   # override: STATA=/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se (motor del ancla v8.8.0: StataNow 19.5 SE, 1 procesador)
LOCAL_LOG="$ROOT/users/ricardo/nl-vintages.log"
VINTAGES=("$@"); [[ ${#VINTAGES[@]} -eq 0 ]] && VINTAGES=(2016 2018 2020 2022 2024)
LIGHT="${NLVINT_LIGHT:-0}"
log() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOCAL_LOG"; }
fail() { log "ABORTA: $*"; exit 1; }

mkdir -p "$ROOT/users/ricardo/vintages"
log "== nl-vintages inicio: ${VINTAGES[*]} (light=$LIGHT) =="
[[ -x "$STATA" ]] || fail "no se encontró Stata en $STATA"
cd "$ROOT" || fail "no se pudo entrar a $ROOT"
for y in "${VINTAGES[@]}"; do
  WRAP="$ROOT/users/ricardo/vintages/run-v$y.do"
  { echo 'capture set processors 1'; echo 'set linesize 200'; [[ "$LIGHT" == "1" ]] && echo 'global nlvint_light 1'; echo "do \"$ROOT/01_modulos/nl-assets/nl-vintage.do\" $y"; } > "$WRAP"
  rm -f "$ROOT/run-v$y.log"
  T0=$(date +%s)
  "$STATA" -b do "$WRAP"
  SLOG="$ROOT/run-v$y.log"
  [[ -f "$SLOG" ]] || fail "Stata no dejó log para $y"
  mv -f "$SLOG" "$ROOT/users/ricardo/vintages/run-v$y.log"; SLOG="$ROOT/users/ricardo/vintages/run-v$y.log"
  if grep -q -E '^r\([0-9]+\);' "$SLOG"; then fail "error de Stata en el vintage $y: $(grep -B3 -m1 -E '^r\([0-9]+\);' "$SLOG" | head -4 | tr '\n' ' ')"; fi
  grep -q "Compuerta D.1: PASÓ" "$SLOG" || fail "vintage $y: la compuerta D.1 no pasó"
  grep -q "nl-vintage ENIGH $y: LISTO" "$SLOG" || fail "vintage $y: la corrida no llegó al final"
  log "vintage $y OK en $(( $(date +%s) - T0 )) s · $(grep -o 'ISRPM *[0-9.]*' "$SLOG" | tail -1)"
done
WRAP="$ROOT/users/ricardo/vintages/run-sello.do"
{ echo 'set linesize 200'; echo "do \"$ROOT/01_modulos/nl-assets/nl-vintages-sello.do\""; } > "$WRAP"
rm -f "$ROOT/run-sello.log"
"$STATA" -b do "$WRAP"
mv -f "$ROOT/run-sello.log" "$ROOT/users/ricardo/vintages/run-sello.log"
SLOG="$ROOT/users/ricardo/vintages/run-sello.log"
if grep -q -E '^r\([0-9]+\);' "$SLOG"; then fail "error en nl-vintages-sello.do: $(grep -B3 -m1 -E '^r\([0-9]+\);' "$SLOG" | head -4 | tr '\n' ' ')"; fi
grep -q "nl-vintages-sello: listo" "$SLOG" || fail "nl-vintages-sello.do no llegó al final"
log "Sello escrito: 01_modulos/nl-assets/participaciones-vintages.json (sha256 $(shasum -a 256 "$ROOT/01_modulos/nl-assets/participaciones-vintages.json" | cut -c1-12)); compuertas: $(grep -c 'PASÓ' "$SLOG")"
log "== nl-vintages fin OK =="
