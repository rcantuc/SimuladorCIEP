*! contrato-32.do  v1.0 (v8.13a, 2026-10-19) — el contrato de entidad para las 32 entidades federativas
*
* QUÉ HACE (corre DENTRO de la sesión de SIM.do, con sus escalares y users/$id/aportaciones.dta
* vivos, después de §8.2; lo invoca 05_scripts/contrato-32.sh). Recorre el catálogo SIMentidad y,
* para cada entidad, produce en users/$id/<ABREV>/ lo que el motor produce para $entidad:
*   §1  Poblacion if entidad == "<nombre>"          (escalares pobtot<ABREV>…; pirámide)
*   §2  PIBDeflactor if entidad == "<nombre>"       SOLO si existe master/PIBDeflactor<ABREV>.dta
*                                                   (construirla baja series del BISE con token:
*                                                   no se hace aquí; se registra "sin base" + receta)
*   §8.2 SankeySF.do × 5 cortes (quintil estatal, grupoedad, sexo, rural, escol), con banda de
*        vintages si existen las bases users/$id-v{2016..2024}/aportaciones.dta ("" ) y sin ella ("0")
*   §8.2 CicloEntidad.do                           ciclo-vida.json
*   §4.7 TasasEfectivasEntidad.do                  tasas-efectivas.json (TasasEfectivasMicro)
* Tolerante a fallos: cada paso va en `capture noisily`; el rc, el tiempo y la nota se registran
* por entidad en <evidencia>/contrato-32.tsv y el recorrido sigue con la siguiente. Un reporte
* parcial vale más que nada. El log de cada entidad queda en <evidencia>/entidades/<ABREV>.log.
* No toca el flujo nacional: los productos nacionales ya están escritos cuando esto corre.
*
* USO: do "${SIMROOT}/05_scripts/contrato-32.do" "<carpeta de evidencia>"
* OJO: destruye los datos en memoria.
local evidencia `"`1'"'
if `"`evidencia'"' == "" {
	di as err "contrato-32: indica la carpeta de evidencia."
	exit 198
}
capture mkdir `"`evidencia'"'
capture mkdir `"`evidencia'/entidades"'
timer clear 9
timer on 9
SIMentidad

** Bases precedentes (banda de vintages): las cinco o ninguna **
local vint "0"
local faltan ""
foreach v in 2016 2018 2020 2022 2024 {
	capture confirm file "${SIMROOT}/users/$id-v`v'/aportaciones.dta"
	if _rc local faltan "`faltan' `v'"
}
if "`faltan'" == "" local vint ""
noisily di _newline in g "{bf:contrato-32: las 32 entidades}" _newline in g "  banda de vintages: " in y `"`=cond("`vint'" == "", "sí (5 bases users/$id-v<anio>/aportaciones.dta)", "no — faltan vintages:`faltan' (receta en runbook §13)")'"'

tempname tsv
file open `tsv' using `"`evidencia'/contrato-32.tsv"', write replace text
file write `tsv' "pos" _tab "abrev" _tab "clave" _tab "nombre" _tab "poblacion_rc" _tab "pib_rc" _tab "pib_nota" _tab "sankeys_ok" _tab "sankeys_rc" _tab "ciclo_rc" _tab "te_rc" _tab "segundos" _tab "banda" _n

local j = 1
foreach ent of global entidadesL {
	if `j' > 32 continue, break
	SIMentidad `"`ent'"'
	local abrev "`r(abrev)'"
	local clave "`r(clave)'"
	local t0 = clock("$S_DATE $S_TIME", "DMYhms")
	capture mkdir "${SIMROOT}/users/$id/`abrev'"
	capture log close ent32
	quietly log using `"`evidencia'/entidades/`abrev'.log"', replace text name(ent32)
	noisily di _newline in g "  `j'/32 " in y `"`ent'"' in g " (`abrev', clave `clave')"

	* §1 Población *
	capture noisily Poblacion if entidad == `"`ent'"', anioi(`=aniovp') aniofinal(2070) nographs
	local rc_pob = _rc

	* §2 PIB/Deflactor: solo con base; la fracción SCN y el BISE quedan fuera (declarado) *
	local rc_pib = .
	local nota_pib "sin base master/PIBDeflactor`abrev'.dta (receta: PIBDeflactor if entidad == \"`ent'\", update  — baja series del BISE con token)"
	capture confirm file "${SIMROOT}/master/PIBDeflactor`abrev'.dta"
	if _rc == 0 {
		* comillas simples, no compuestas: PIBDeflactor extrae el `if entidad == "..."` con una regex antes de syntax *
		capture noisily PIBDeflactor if entidad == "`ent'", aniovp(`=aniovp') aniomax(2032) nographs nooutput
		local rc_pib = _rc
		local nota_pib "con base"
	}

	* §8.2 Sankeys (5 cortes) *
	local ok_sk = 0
	local rc_sk ""
	foreach k in quintil grupoedad sexo rural escol {
		capture noisily run "${SIMROOT}/01_modulos/visualizations/SankeySF.do" `k' `=anioPE' `"`ent'"' "`vint'"
		if _rc == 0 local ++ok_sk
		else local rc_sk "`rc_sk' `k':`=_rc'"
	}

	* §8.2 Ciclo de vida *
	capture noisily run "${SIMROOT}/01_modulos/visualizations/CicloEntidad.do" `=anioPE' `"`ent'"'
	local rc_ciclo = _rc

	* §4.7 Tasas efectivas micro/micro *
	capture noisily run "${SIMROOT}/01_modulos/TasasEfectivasEntidad.do" `=anioPE' `"`ent'"'
	local rc_te = _rc

	local seg = (clock("$S_DATE $S_TIME", "DMYhms") - `t0')/1000
	quietly log close ent32
	file write `tsv' "`j'" _tab "`abrev'" _tab "`clave'" _tab `"`ent'"' _tab "`rc_pob'" _tab "`rc_pib'" _tab `"`nota_pib'"' _tab "`ok_sk'" _tab "`=trim("`rc_sk'")'" _tab "`rc_ciclo'" _tab "`rc_te'" _tab "`seg'" _tab "`=cond("`vint'" == "", "si", "no")'" _n
	noisily di in g "     poblacion rc=" in y "`rc_pob'" in g "  pib rc=" in y "`rc_pib'" in g "  sankeys " in y "`ok_sk'/5" in g "  ciclo rc=" in y "`rc_ciclo'" in g "  te rc=" in y "`rc_te'" in g "  (" in y "`seg'" in g " s)"
	local ++j
}
file close `tsv'
timer off 9
noisily di _newline in g "contrato-32: listo. Tabla: " in y `"`evidencia'/contrato-32.tsv"'
timer list 9
