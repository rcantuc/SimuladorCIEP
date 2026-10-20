*! pibe-32.do  v1.0 (v8.13a-2, 2026-10-19) — bases master/PIBDeflactor<ABREV>.dta de las 32 entidades
*
* QUÉ HACE (lo invoca 05_scripts/pibe-32.sh; necesita $SIMROOT, $id y $BIE_API_TOKEN, que el wrapper
* fija con set_token.do). Recorre el catálogo SIMentidad y, para cada entidad, ejecuta LA receta de
* Ricardo, sin tocarla:
*     PIBDeflactor if entidad == "<nombre>", update aniovp(2027) aniomax(2032) nographs nooutput
* (UpdatePIBDeflactor: PIBE 750453 e índice de precios implícitos 753357 del BIE, área cc; ocupados y
* desocupados ENOE 6200093954/6200093973 del BISE vía API con token; ITAEE 741177/741180; INPC estatal
* del programa INPC de INEGI; población CONAPO). Fuentes VIVAS: cada corrida consulta a INEGI y deja
* la fecha de consulta; nada se congela. El `update` solo se pide si la base ya existía (si no, la
* receta la construye sola al no encontrarla: evita el doble recorrido).
* Tolerante a fallos: cada entidad va en `capture noisily`; rc, segundos y nota quedan en
* <evidencia>/pibe-32.tsv (se APENDEA: una segunda pasada con la lista de abreviaturas reintenta solo
* las fallidas) y el log de cada entidad en <evidencia>/entidades/<ABREV>.log. Pausa entre entidades
* (cortesía con la API de INEGI).
* No sella ni compara: eso lo hace pibe-32.py (sellos .meta) y sellar-pibe-32.do (sello dentro del .dta).
*
* USO: do "${SIMROOT}/05_scripts/pibe-32.do" "<carpeta de evidencia>" ["<abrevs separadas por espacio>"] [pausa_s]
* OJO: destruye los datos en memoria.
local evidencia `"`1'"'
local solo `"`2'"'
local pausa = cond("`3'" == "", 5, real("`3'"))
if `"`evidencia'"' == "" | `"$SIMROOT"' == "" | `"$id"' == "" {
	di as err "pibe-32: indica la carpeta de evidencia y fija SIMROOT e id (lo hace pibe-32.sh)."
	exit 198
}
if `"$BIE_API_TOKEN"' == "" {
	di as err "pibe-32: sin token del BIE/INEGI (set_token.do): el BISE no responde sin él."
	exit 198
}
capture mkdir `"`evidencia'"'
capture mkdir `"`evidencia'/entidades"'
scalar aniovp = 2027
SIMentidad

tempname tsv
capture confirm file `"`evidencia'/pibe-32.tsv"'
if _rc {
	file open `tsv' using `"`evidencia'/pibe-32.tsv"', write replace text
	file write `tsv' "pos" _tab "abrev" _tab "clave" _tab "nombre" _tab "update" _tab "rc" _tab "base_existe" _tab "segundos" _tab "inicio" _n
	file close `tsv'
}

local j = 1
foreach ent of global entidadesL {
	if `j' > 32 continue, break
	SIMentidad `"`ent'"'
	local abrev "`r(abrev)'"
	local clave "`r(clave)'"
	local pos = `j'
	local ++j
	if `"`solo'"' != "" {
		local esta : list posof "`abrev'" in solo
		if !`esta' continue
	}
	local inicio "`c(current_date)' `c(current_time)'"
	local t0 = clock("`inicio'", "DMYhms")
	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.dta"
	local previa = _rc == 0
	local upd = cond(`previa', "update", "")
	capture log close ent32
	quietly log using `"`evidencia'/entidades/`abrev'.log"', append text name(ent32)
	noisily di _newline in g "  `pos'/32 " in y `"`ent'"' in g " (`abrev', clave `clave') — " in y "`inicio'"

	* La receta de Ricardo, sin tocarla (comillas simples: PIBDeflactor extrae el if con una regex) *
	capture noisily PIBDeflactor if entidad == "`ent'", `upd' aniovp(`=aniovp') aniomax(2032) nographs nooutput
	local rc = _rc

	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.dta"
	local existe = _rc == 0
	local seg = (clock("`c(current_date)' `c(current_time)'", "DMYhms") - `t0')/1000
	noisily di in g "     rc=" in y "`rc'" in g "  base=" in y "`existe'" in g "  (" in y "`seg'" in g " s)"
	quietly log close ent32
	file open `tsv' using `"`evidencia'/pibe-32.tsv"', write append text
	file write `tsv' "`pos'" _tab "`abrev'" _tab "`clave'" _tab `"`ent'"' _tab "`upd'" _tab "`rc'" _tab "`existe'" _tab "`seg'" _tab "`inicio'" _n
	file close `tsv'
	sleep `=`pausa'*1000'
}
noisily di _newline in g "pibe-32: listo. Tabla: " in y `"`evidencia'/pibe-32.tsv"'
