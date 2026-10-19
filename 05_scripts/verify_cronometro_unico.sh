#!/usr/bin/env bash
# verify_cronometro_unico.sh — la cuenta regresiva del «Calcular» tiene UNA fuente de verdad (v8.12.2).
# Falla si reaparece un literal de segundos suelto (startCountdown(N), #count … N, <b id="count">N</b>) fuera de
# js/config-tiempos.js, o si una página carga stataCalcula*.js sin cargar antes config-tiempos.js.
set -uo pipefail
cd "$(dirname "$0")/.."
S=04_1_simuladorfiscal.ciep.mx; fallos=0
mal() { echo "FALLO: $*"; fallos=$((fallos+1)); }
sueltos="$(grep -nE "startCountdown|countdownTimer|#count'\)\.text\([0-9]|id=\"count\">[0-9]" "$S"/js/stataCalcula.js "$S"/js/stataCalcula-en.js "$S"/index.php "$S"/index-en.php || true)"
[[ -z "$sueltos" ]] || mal "literales de cuenta regresiva fuera de js/config-tiempos.js:"$'\n'"$sueltos"
for par in "index.php:stataCalcula.js" "index-en.php:stataCalcula-en.js"; do
    p="${par%%:*}"; j="${par##*:}"
    lc="$(grep -n 'js/config-tiempos.js' "$S/$p" | head -1 | cut -d: -f1)"; lj="$(grep -n "js/$j" "$S/$p" | head -1 | cut -d: -f1)"
    [[ -n "$lc" && -n "$lj" && "$lc" -lt "$lj" ]] || mal "$p debe cargar js/config-tiempos.js ANTES de js/$j (config en línea '${lc:-—}', calcula en '${lj:-—}')"
done
for j in stataCalcula.js stataCalcula-en.js; do
    grep -q "CIEPCronometro.iniciar" "$S/js/$j" && grep -q "complete:" "$S/js/$j" || mal "$j no arranca/corta el cronómetro por CIEPCronometro (iniciar + complete)"
done
n="$(grep -cE '^\s+(principal|isr|iva|isr_iva): [0-9]+' "$S/js/config-tiempos.js")"
[[ "$n" == "4" ]] || mal "js/config-tiempos.js debe definir las 4 constantes (principal, isr, iva, isr_iva); encontré $n"
if (( fallos )); then echo "RESULTADO: $fallos fallo(s)"; exit 1; fi
echo "RESULTADO: cronómetro del «Calcular» con una sola fuente (js/config-tiempos.js: 4 constantes; cero literales sueltos)"
