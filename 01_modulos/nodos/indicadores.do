*! indicadores.do  v2.0.0 — driver del nodo de indicadores de ciep.mx (hashtags del home)
*
* QUÉ ES ESTO
* El driver de los indicadores: toma para cada concepto la serie OFICIAL de
* datos abiertos (SHCP, Estadísticas Oportunas, vía DatosAbiertos.ado) con
* su último corte MENSUAL, y escribe statajson_indicadores.json — un valor
* en % del PIB por SLUG de categoría de ciep.mx. El decorador estático
* (indicadores-decorador.js) pinta la cifra junto al hashtag cuyo slug SÍ
* tiene dato; los demás quedan intactos. WordPress jamás guarda un número.
*
* DECISIÓN DE FUENTE (Ricardo, 2026-08-03): ÚNICAMENTE datos abiertos como
* lo oficial, con el último mes disponible como corte de cada concepto (hoy:
* mayo de 2026). v1 usaba LIF/PEF anual (ley/aprobado); v2 los sustituye.
*
* CONVENCIÓN DE % PIB (la del MOTOR, no inventada aquí): los FLUJOS van con
* la opción `proyeccion' de DatosAbiertos.ado — el acumulado observado al
* mes m se anualiza con el perfil promedio de acumulación (acum_prom) y se
* divide entre el PIB anual. tipo_dato = "proyectado_observado". El SALDO
* de deuda no se proyecta: es el saldo al cierre del mes (observado_mensual).
*
* TIEMPO ESPERADO DE CORRIDA: ~40 s (12 llamadas a DatosAbiertos sobre una
* base de 8.5M filas + PIBDeflactor). La regla 3 del verificador lo duplica.
*
* CENSO v2 (claves verificadas contra master/DatosAbiertos.dta, mayo 2026):
*   ingresos, ingresospublicos  XAB      Ingresos del Sector Público
*   tributarios                 XAB11    Ingresos Tributarios del Gob. Federal
*   otrosingresos               XAB12    Ingresos No Tributarios del Gob. Federal
*   seguridadsocial             XDA12    Contribuciones de Seguridad Social
*   gastopublico                XAC      Gasto Neto Pagado del Sector Público
*   costodeladeuda              XAC21    Costo Financiero del Sector Público
*   pensiones                   XOA0135  Gasto en Pensiones del Sector Público
*   salud                       XOA0417  Gasto Programable, Función Salud
*   educacion                   XOA0419  Gasto Programable, Función Educación
*   energia                     XAB21 - XOA0425 (balance: Ingresos Petroleros
*                               menos Gasto Programable Función Combustibles y
*                               Energía — la definición de balance es decisión
*                               de Ricardo; las dos series son datos abiertos)
*   endeudamiento               XAC - XAB (cierre por construcción, misma
*                               definición que la portada del Paquete)
*   deudapublica                master/SHRFSP.dta (SHRF5000 vía DatosAbiertos;
*                               saldo % PIB, último mes)
*   NOTA XOA0316/XOA0315 (frames viejos de Salud/Educación) ya no traen dato
*   en 2026; el censo usa XOA0417/XOA0419. Si una clave se queda sin dato en
*   el corte, el guard truena: censo desactualizado, no hueco silencioso.
*   11 slugs NO DISPONIBLES declarados con su razón (igual que v1).
*
* DÓNDE VIVE CADA COSA (mismo patrón que nodo-deuda/portada)
*   FUENTE (versionada):  01_modulos/nodos/indicadores.do
*                         01_modulos/nodos/indicadores-decorador.js
*                         01_modulos/nodos/indicadores-muplugin.php
*   SALIDA (ignorada, generada, bajo el docroot de ciep.mx local):
*     04_5_ciep.mx/indicadores/statajson_indicadores.json
*     04_5_ciep.mx/indicadores/decorador.js  (copia servible)
*   El mu-plugin se instala UNA vez a mano en wp-content/mu-plugins/.
*
* USO:  do "`c(sysdir_site)'/01_modulos/nodos/indicadores.do"
* Override de destino para verify_nodo.sh (regla 3): global nodo_saving.

*** 0 PRELIMINARES ***
local site `"`c(sysdir_site)'"'

capture confirm scalar aniovp
if _rc {
	di as err "indicadores: falta scalar aniovp (lo fija profile.do). No se exporta."
	exit 198
}
local anioref = scalar(aniovp)
local meses "enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre"

*** 1 FLUJOS DE DATOS ABIERTOS (proyección anual del motor, corte mensual) ***
* El dataset que deja DatosAbiertos con `proyeccion' está colapsado por año:
* la fila del año de referencia trae monto_pib proyectado y el mes del corte. *
local claves  "XAB XAB11 XAB12 XDA12 XAC XAC21 XOA0135 XOA0417 XOA0419 XAB21 XOA0425"
local alias   "ING TRIB OTR CSS GAS CDD PEN SAL EDU PETI ENGG"
local n : word count `claves'
local cortemes = .
forvalues i = 1/`n' {
	local k : word `i' of `claves'
	local a : word `i' of `alias'
	quietly DatosAbiertos `k', proyeccion nographs
	quietly keep if anio == `anioref'
	if _N != 1 | monto_pib[1] == . {
		di as err "indicadores: la clave `k' no trae dato proyectable para `anioref'. El censo cambió; actualiza el driver."
		exit 459
	}
	scalar __ind`a' = monto_pib[1]
	local mes`a' = mes[1]
	if `cortemes' == . local cortemes = mes[1]
	if mes[1] != `cortemes' {
		di as err "indicadores: la clave `k' corta en el mes " mes[1] " y las previas en `cortemes'. Cortes mixtos: decide antes de publicar."
		exit 459
	}
}
local corteflujo "`:word `cortemes' of `meses'' de `anioref'"

*** 2 DERIVACIONES DECLARADAS (las únicas cuentas del nodo) ***
scalar __indEND = __indGAS - __indING
scalar __indENE = __indPETI - __indENGG

*** 3 DEUDA — saldo observado MENSUAL (SHRF5000 vía master/SHRFSP.dta) ***
preserve
quietly use `"`site'/master/SHRFSP.dta"', clear
sort anio
if unidad_de_medida[_N] != "Pesos" {
	di as err "indicadores: la última fila de SHRFSP.dta no está en Pesos. No se exporta."
	exit 459
}
scalar __indDEU = monto_pib[_N]
local deu_anio = anio[_N]
local deu_mes  = mes[_N]
restore
local deu_etq "`:word `deu_mes' of `meses'' de `deu_anio'"

*** 4 PROCEDENCIA (espejo de scalarjson: manifest + log basename) ***
local mversion ""
local mcorte ""
local faltantes ""
local manifest `"`site'/05_scripts/manifest.json"'
capture confirm file `"`manifest'"'
if _rc == 0 {
	tempname mh
	file open `mh' using `"`manifest'"', read text
	file read `mh' mline
	while r(eof) == 0 {
		if regexm(`"`mline'"', `""version"[ ]*:[ ]*"([^"]*)""') & "`mversion'" == "" {
			local mversion = regexs(1)
		}
		if regexm(`"`mline'"', `""data_updated"[ ]*:[ ]*"([^"]*)""') & "`mcorte'" == "" {
			local mcorte = regexs(1)
		}
		file read `mh' mline
	}
	file close `mh'
}
if "`mversion'" == "" local faltantes "`faltantes' procedencia.version_simulador"
if "`mcorte'"   == "" local faltantes "`faltantes' procedencia.corte_datos"

local logfile ""
capture quietly log query
local lf `"`r(filename)'"'
if `"`lf'"' != "" & `"`lf'"' != "." {
	local logfile = substr(`"`lf'"', length(`"`lf'"') - strpos(reverse(`"`lf'"'), "/") + 2, .)
}
if `"`logfile'"' == "" local faltantes "`faltantes' procedencia.log"

*** 5 ESCRITURA DEL CONTRATO ***
* Emisor %16.9g: los agregados con proyección tampoco son bit-estables
* (mismo ruido de ordenamiento); 9 dígitos = margen de sobra para el
* display de 1 decimal. Este contrato no lleva montos. *
capture program drop _pjpib
program define _pjpib, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	capture local s = trim(string(`e', "%16.9g"))
	if _rc exit
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end
capture program drop _pjesc
program define _pjesc, rclass
	args s
	local s = subinstr(`"`s'"', char(96), "", .)
	local s = subinstr(`"`s'"', char(92), char(92) + char(92), .)
	local s = subinstr(`"`s'"', char(34), char(92) + char(34), .)
	return local s `"`s'"'
end

local saving `"`site'/04_5_ciep.mx/indicadores/statajson_indicadores.json"'
if `"$nodo_saving"' != "" {
	local saving `"$nodo_saving"'
}
else {
	capture mkdir `"`site'/04_5_ciep.mx/indicadores"'
}

local q = char(34)
tempname fh
file open `fh' using `"`saving'"', write replace text

file write `fh' "{" _n
file write `fh' `"  `q'esquema`q': `q'ciep.nodo.indicadores/v1`q',"' _n
file write `fh' `"  `q'nodo`q': `q'indicadores`q',"' _n
file write `fh' `"  `q'titulo`q': `q'Indicadores del sistema fiscal (hashtags de ciep.mx)`q',"' _n
file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
file write `fh' `"  `q'presentacion`q': {"' _n
file write `fh' `"    `q'unidad_pib`q': `q'% del PIB`q',"' _n
file write `fh' `"    `q'formato_pib`q': `q'%7.1f`q',"' _n
file write `fh' `"    `q'nota_general`q': `q'% del PIB · datos abiertos SHCP al cierre de `corteflujo'`q',"' _n
file write `fh' `"    `q'tipo_dato_leyenda`q': {`q'proyectado_observado`q': `q'proyección anual del motor con el observado acumulado al corte (DatosAbiertos, opción proyeccion)`q', `q'observado_mensual`q': `q'saldo observado al cierre del mes`q'}"' _n
file write `fh' "  }," _n
file write `fh' `"  `q'indicadores`q': ["' _n

capture program drop _indw
program define _indw
	args fh slug etq val tipo corte fuente coma
	local q = char(34)
	_pjpib `val'
	local v "`r(n)'"
	file write `fh' `"    {`q'slug`q': `q'`slug'`q', `q'etiqueta`q': `q'`etq'`q', `q'disponible`q': true, `q'pib`q': `v', `q'corte`q': `q'`corte'`q', `q'tipo_dato`q': `q'`tipo'`q', `q'fuente`q': `q'`fuente'`q'}`coma'"' _n
end
capture program drop _indno
program define _indno
	args fh slug etq razon coma
	local q = char(34)
	file write `fh' `"    {`q'slug`q': `q'`slug'`q', `q'etiqueta`q': `q'`etq'`q', `q'disponible`q': false, `q'razon`q': `q'`razon'`q'}`coma'"' _n
end

local FTE "SHCP, Estadísticas Oportunas (datos abiertos) vía DatosAbiertos.ado, proyección anual con observado a `corteflujo'"
_indw `fh' "ingresos" "Ingresos" __indING "proyectado_observado" "`corteflujo'" "`FTE': XAB, Ingresos del Sector Público" ","
_indw `fh' "ingresospublicos" "Ingresos públicos" __indING "proyectado_observado" "`corteflujo'" "`FTE': XAB, Ingresos del Sector Público" ","
_indw `fh' "gastopublico" "Gasto público" __indGAS "proyectado_observado" "`corteflujo'" "`FTE': XAC, Gasto Neto Pagado del Sector Público" ","
_indw `fh' "endeudamiento" "Endeudamiento" __indEND "proyectado_observado" "`corteflujo'" "cierre por construcción: XAC - XAB (gasto - ingresos, misma definición que la portada del Paquete)" ","
_indw `fh' "tributarios" "Ingresos tributarios" __indTRIB "proyectado_observado" "`corteflujo'" "`FTE': XAB11, Ingresos Tributarios del Gobierno Federal" ","
_indw `fh' "otrosingresos" "Otros ingresos" __indOTR "proyectado_observado" "`corteflujo'" "`FTE': XAB12, Ingresos No Tributarios del Gobierno Federal" ","
_indw `fh' "seguridadsocial" "Seguridad social" __indCSS "proyectado_observado" "`corteflujo'" "`FTE': XDA12, Contribuciones de Seguridad Social" ","
_indw `fh' "salud" "Salud" __indSAL "proyectado_observado" "`corteflujo'" "`FTE': XOA0417, Gasto Programable del Sector Público de la Función Salud" ","
_indw `fh' "educacion" "Educación" __indEDU "proyectado_observado" "`corteflujo'" "`FTE': XOA0419, Gasto Programable del Sector Público de la Función Educación" ","
_indw `fh' "pensiones" "Pensiones" __indPEN "proyectado_observado" "`corteflujo'" "`FTE': XOA0135, Gasto en Pensiones del Sector Público" ","
_indw `fh' "energia" "Energía (balance)" __indENE "proyectado_observado" "`corteflujo'" "balance declarado: XAB21 (Ingresos Petroleros) - XOA0425 (Gasto Programable, Función Combustibles y Energía); decisión de Ricardo" ","
_indw `fh' "deudapublica" "Deuda pública (SHRFSP)" __indDEU "observado_mensual" "`deu_etq'" "master/SHRFSP.dta (SHRF5000 vía DatosAbiertos), variable monto_pib, última observación (mismo titular que el nodo de deuda)" ","
_indw `fh' "costodeladeuda" "Costo de la deuda" __indCDD "proyectado_observado" "`corteflujo'" "`FTE': XAC21, Costo Financiero del Sector Público" ","
_indno `fh' "espaciofiscal" "Espacio fiscal" "FiscalGap.ado registra tasas (tt*/td*/tn*), no un nivel en % del PIB; pendiente de reconocimiento del módulo" ","
_indno `fh' "sostenibilidadfiscal" "Sostenibilidad fiscal" "FiscalGap.ado registra tasas, no un nivel en % del PIB; pendiente de reconocimiento del módulo" ","
_indno `fh' "iepsaltabaco" "IEPS al tabaco" "la serie de datos abiertos del IEPS a tabacos labrados no está en el censo todavía; candidata para un ciclo futuro" ","
_indno `fh' "cuentasgeneracionales" "Cuentas generacionales" "CuentasGeneracionales.ado no registra escalares" ","
_indno `fh' "analisis" "Análisis" "hashtag editorial, sin correspondencia numérica" ","
_indno `fh' "infraestructura" "Infraestructura" "sin correspondencia en el censo hoy" ","
_indno `fh' "seguridadpublica" "Seguridad pública" "sin correspondencia en el censo hoy" ","
_indno `fh' "finanzaslocales" "Finanzas locales" "sin correspondencia en el censo hoy" ","
_indno `fh' "equidaddegenero" "Equidad de género" "sin correspondencia en el censo hoy" ","
_indno `fh' "economiadeloscuidados" "Economía de los cuidados" "sin correspondencia en el censo hoy" ","
_indno `fh' "poblacionesvulneradas" "Poblaciones vulneradas" "sin correspondencia en el censo hoy" ""

file write `fh' "  ]," _n

* --- procedencia y sello (generado_en AL FINAL de su bloque, aislado) --- *
file write `fh' `"  `q'procedencia`q': {"' _n
_pjesc `"`mversion'"'
file write `fh' `"    `q'version_simulador`q': `q'`r(s)'`q',"' _n
_pjesc `"`mcorte'"'
file write `fh' `"    `q'corte_datos`q': `q'`r(s)'`q',"' _n
_pjesc `"`logfile'"'
file write `fh' `"    `q'log`q': `q'`r(s)'`q',"' _n
file write `fh' `"    `q'origen`q': `q'DatosAbiertos.ado (SHCP Estadísticas Oportunas) + master/SHRFSP.dta via 01_modulos/nodos/indicadores.do`q',"' _n
file write `fh' `"    `q'generado_en`q': `q'`c(current_date)'T`c(current_time)'`q'"' _n
file write `fh' "  }," _n

local faltantes = trim("`faltantes'")
local flist ""
local nfal : word count `faltantes'
local i = 0
foreach f of local faltantes {
	local i = `i' + 1
	local flist `"`flist'`q'`f'`q'`=cond(`i' < `nfal', ", ", "")'"'
}
file write `fh' `"  `q'faltantes`q': [`flist']"' _n
file write `fh' "}" _n
file close `fh'

noisily di in g "indicadores: contrato escrito -> " in y `"`saving'"'

* Limpieza de los escalares de captura *
foreach s in ING TRIB OTR CSS GAS CDD PEN SAL EDU PETI ENGG END ENE DEU {
	capture scalar drop __ind`s'
}

*** 6 DESTINO SERVIBLE ***
if `"$nodo_saving"' == "" {
	capture copy `"`site'/01_modulos/nodos/indicadores-decorador.js"' ///
		`"`site'/04_5_ciep.mx/indicadores/decorador.js"', replace
	if _rc {
		noisily di in g "indicadores: no se pudo copiar el decorador al destino de render."
	}
}
