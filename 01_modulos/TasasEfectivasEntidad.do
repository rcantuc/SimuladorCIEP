*************************************************
*** TASAS EFECTIVAS DE UNA ENTIDAD (micro/micro) ***
*************************************************
* TasasEfectivasEntidad.do — v1.0 (v8.13a, 2026-10-19). Re-cableo de TasasEfectivasMicro.ado
* (v1.1.0, huérfano desde v8.11b; aquí NO se toca por dentro) al flujo de entidad del motor.
*
* Llamada (SIM.do §4.7, solo con global entidad definido):
*   run TasasEfectivasEntidad.do <anioPE> "<entidad>"
* Con el global vacío SIM.do no llega a esta línea: cero efecto en la corrida nacional.
* También lo llama 05_scripts/contrato-32.do para cada una de las 32.
*
* QUÉ HACE (unificación, no invención — la metodología es la de TasasEfectivasMicro.ado):
*   1. Si no existe el espejo nacional micro/micro (escalares *TEnac), lo calcula una vez
*      (TasasEfectivasMicro sin entidad()): es la referencia de Rel<IMP>TE<suf>.
*   2. TasasEfectivasMicro, anio(<anio>) entidad(<clave INEGI>) sufijo(<abrev en minúsculas>)
*      — el motor habla nombre (global entidad), el comando habla código (catálogo SIMentidad).
*   3. Sellos de muestra, como los demás productos de entidad (regla P5 de SankeySF.do):
*      n = personas de la MUESTRA de la entidad en master/perfiles<anio>.dta (sin ponderar);
*      por impuesto, top1 = % del numerador (Σ impuesto × factor) que pone UNA sola persona;
*      sello = 1 si n < sello_n (100) o top1 > sello_top1 (25 %). Se declara, no se suaviza.
*   4. Escribe users/$id/<ABREV>/tasas-efectivas.json con los escalares del comando (montos,
*      bases, tasas, diferencias vs la TE oficial macro/macro y vs el espejo nacional), los
*      sellos y la procedencia. Los escalares quedan vivos en la sesión (escalar).
*
* LO QUE NO ES: no es aditivo (son tasas). Lo aditivo son los MONTOS (Rec*, Base*, Pob):
* Σ de las 32 entidades = nacional, porque TasasEfectivasMicro suma [aw=factor] por residencia
* sobre la misma base post-ajuste. De ahí la propuesta de gate de consistencia (FLAG v8.13a):
* la tasa nacional se reproduce como promedio de las 32 ponderado por su base.
*
* FLAGs (decisiones de Ricardo; aquí solo parámetros): sello_n, sello_top1 (heredados de P5);
* qué impuestos se publican por entidad (todos se escriben; nada se oculta ni se suaviza).
timer on 13
local anio = `1'
local entidad : subinstr local 2 `"""' "", all		// el argumento de un do-file llega con sus comillas
local entidad = trim(`"`entidad'"')
if `"`entidad'"' == "" {
	di as err "TasasEfectivasEntidad: falta la entidad. SIM.do §4.7 lo llama solo con global entidad definido."
	exit 198
}
SIMentidad `"`entidad'"'
local enombre `"`r(nombre)'"'
local eclave "`r(clave)'"
local eabrev "`r(abrev)'"
local suf = lower("`eabrev'")
local sello_n = 100
local sello_top1 = 25
capture mkdir "${SIMROOT}/users/$id/`eabrev'"
local json `"${SIMROOT}/users/$id/`eabrev'/tasas-efectivas.json"'
local telist "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IMPORT ISAN IEPSNP IEPSP YlImp ingconsumo"
local montos "ISRAS CUOTAS ISRPF ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT"
local bases "Sal Mix KPriv Consu Vehic AlcTaba Combu"

preserve

** 1 Espejo nacional micro/micro, una vez por sesión **
capture confirm scalar ISRASTEnac
if _rc != 0 {
	noisily TasasEfectivasMicro, anio(`anio')
}

** 2 La entidad **
noisily TasasEfectivasMicro, anio(`anio') entidad(`=real("`eclave'")') sufijo(`suf')

** 3 Sellos de muestra (n y top1 por impuesto) sobre la misma base micro **
quietly {
	use folioviv factor `montos' using "${SIMROOT}/master/perfiles`anio'.dta", clear
	keep if substr(folioviv, 1, 2) == "`eclave'"
	local n = _N
	local nsellos = 0
	foreach k of local montos {
		tempvar w
		g double `w' = `k'*factor
		summarize `w', meanonly
		local tot = r(sum)
		local mx = r(max)
		local top1_`k' = cond(`tot' > 0, `mx'/`tot'*100, 0)
		local sello_`k' = cond(`n' < `sello_n' | `top1_`k'' > `sello_top1', 1, 0)
		local nsellos = `nsellos' + `sello_`k''
		drop `w'
	}
}

** 4 JSON **
local fecha : di %tdCCYY-NN-DD date("$S_DATE", "DMY")
local hora "$S_TIME"
local enombrej : subinstr local enombre `"""' `"\""', all
local f2 "%20.2f"
local f6 "%12.6f"
tempname fh
file open `fh' using `"`json'"', write replace text
file write `fh' `"{"esquema":"tasas-efectivas/v1","entidad":{"nombre":"`enombrej'","clave":"`eclave'","abrev":"`eabrev'","sufijo":"`suf'"},"' _n
file write `fh' `""anio_politica":`anio',"anio_vp":`=aniovp',"paquete":"$paqueteEconomico","' _n
file write `fh' `""definicion":{"metodo":"TasasEfectivasMicro.ado v1.1.0: TE micro/micro, numerador = suma [aw=factor] de la variable de impuesto de master/perfiles<anio>.dta, denominador = suma de la base micro ajustada a Cuentas Nacionales (Distribucion, factores nacionales); la muestra se corta POR RESIDENCIA (substr(folioviv,1,2) == clave) DESPUES del ajuste nacional; aqui no se recalibra nada","' _n
file write `fh' `""aditividad":"los MONTOS (rec, base, pob) suman al nacional entidad por entidad (misma base, misma ponderacion); las TASAS no son aditivas: tasa nacional = promedio de las 32 ponderado por su base (propuesta de gate de consistencia, FLAG v8.13a)","' _n
file write `fh' `""unidades":{"rec":"pesos corrientes de anio_politica","base":"pesos corrientes","te":"porcentaje = rec/base*100","dif_vs_oficial":"porcentaje: (te_micro/te_oficial - 1)*100, vs TasasEfectivas.ado macro/macro","rel_vs_nac":"puntos porcentuales: te_entidad - te_nacional_micro"}},"' _n
file write `fh' `""parametros":{"sello_n":`sello_n',"sello_top1":`sello_top1',"regla_sello":"n = personas de la muestra de la entidad en perfiles<anio> (sin ponderar) < sello_n, o una sola persona pone mas de sello_top1 % del numerador del impuesto (regla P5 de SankeySF.do)"},"' _n
file write `fh' `""muestra":{"n":`n',"pob":`=trim(string(scalar(Pob`suf'), "`f2'"))',"pob_nacional":`=trim(string(scalar(Pobnac), "`f2'"))',"share_pob":`=trim(string(scalar(Pob`suf')/scalar(Pobnac), "`f6'"))',"ingbruto":`=trim(string(scalar(IngBruto`suf'), "`f2'"))',"impuestos_con_sello":`nsellos'},"' _n
file write `fh' `""bases":{"' 
local first = 1
foreach b of local bases {
	file write `fh' `"`=cond(`first', "", ",")'"`b'":{"entidad":`=trim(string(scalar(Base`b'`suf'), "`f2'"))',"nacional":`=trim(string(scalar(Base`b'nac), "`f2'"))'}"'
	local first = 0
}
file write `fh' `"},"' _n
file write `fh' `""impuestos":["' _n
local first = 1
foreach k of local montos {
	local dif = "null"
	capture confirm scalar Dif`k'TE`suf'
	if _rc == 0 local dif = trim(string(scalar(Dif`k'TE`suf'), "`f6'"))
	local rel = "null"
	capture confirm scalar Rel`k'TE`suf'
	if _rc == 0 local rel = trim(string(scalar(Rel`k'TE`suf'), "`f6'"))
	file write `fh' `"`=cond(`first', "", ",")'{"impuesto":"`k'","rec":`=trim(string(scalar(Rec`k'`suf'), "`f2'"))',"rec_nacional":`=trim(string(scalar(Rec`k'nac), "`f2'"))',"te":`=trim(string(scalar(`k'TE`suf'), "`f6'"))',"te_nacional_micro":`=trim(string(scalar(`k'TEnac), "`f6'"))',"dif_vs_oficial":`dif',"rel_vs_nac":`rel',"top1":`=trim(string(`top1_`k'', "`f6'"))',"sello":`sello_`k''}"' _n
	local first = 0
}
file write `fh' `"],"' _n
file write `fh' `""agregados":{"YlImpTE":`=trim(string(scalar(YlImpTE`suf'), "`f6'"))',"ingconsumoTE":`=trim(string(scalar(ingconsumoTE`suf'), "`f6'"))',"RecTotal":`=trim(string(scalar(RecTotal`suf'), "`f2'"))',"RecTotal_nacional":`=trim(string(scalar(RecTotalnac), "`f2'"))'},"' _n
file write `fh' `""procedencia":{"modulo":"01_modulos/TasasEfectivasEntidad.do v1.0 -> TasasEfectivasMicro.ado v1.1.0","base":"master/perfiles`anio'.dta + master/<anioenigh>/households.dta + consumption_categ_ieps_pc.dta (las mismas del nacional)","generado_el":"`fecha' `hora'","stata":"`c(stata_version)' `c(edition_real)'","escalares":"Rec<IMP>`suf', Base<BASE>`suf', <IMP>TE`suf', Dif<IMP>TE`suf', Rel<IMP>TE`suf', Pob`suf', IngBruto`suf' (registro escalar, vivos en la sesion)"}}"' _n
file close `fh'

restore
timer off 13
noisily di in g "  TasasEfectivasEntidad: " in y "`enombre'" in g " -> users/$id/`eabrev'/tasas-efectivas.json (n = " in y "`n'" in g ", impuestos con sello: " in y "`nsellos'" in g ")."
