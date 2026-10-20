*! sellar-pibe-32.do  v1.0 (v8.13a-2, 2026-10-19) — el sello de procedencia DENTRO de cada master/PIBDeflactor<ABREV>.dta
*
* Lee master/PIBDeflactor<ABREV>.meta (lo escribe `pibe-32.py sellar`: series BIE/BISE, estructura,
* fecha de consulta, último periodo, n) y lo deja como características del dataset:
*   char _dta[sello_<clave>] "<valor>"       (se ven con: char list)
* para que el sello viaje con el .dta aunque solo se copie el .dta (rsync de master/PIBDeflactor*.dta).
* No altera datos, etiquetas ni formatos: use + char + save. Corre DESPUÉS de pibe-32.do y de `sellar`.
* USO: do "${SIMROOT}/05_scripts/sellar-pibe-32.do"
SIMentidad
local n = 0
foreach abrev of global entidadesC {
	if "`abrev'" == "Nac" continue
	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.dta"
	local base = _rc == 0
	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.meta"
	if _rc | !`base' {
		noisily di in y "  `abrev': sin base o sin .meta; no se sella."
		continue
	}
	use "${SIMROOT}/master/PIBDeflactor`abrev'.dta", clear
	tempname fh
	file open `fh' using "${SIMROOT}/master/PIBDeflactor`abrev'.meta", read text
	file read `fh' line
	while r(eof) == 0 {
		local linea `"`macval(line)'"'
		local p = strpos(`"`linea'"', "=")
		if `p' > 1 {
			local k = substr(`"`linea'"', 1, `p' - 1)
			local v = substr(`"`linea'"', `p' + 1, .)
			char _dta[sello_`k'] `"`macval(v)'"'
		}
		file read `fh' line
	}
	file close `fh'
	save "${SIMROOT}/master/PIBDeflactor`abrev'.dta", replace
	local ++n
}
noisily di in g "sellar-pibe-32: " in y "`n'" in g " bases selladas."
