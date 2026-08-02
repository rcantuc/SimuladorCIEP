*! nodo-deuda.do  v1.1.0 — driver del nodo de deuda pública (v8.2.0)
*
* QUÉ ES ESTO
* El driver del nodo: prepara la serie, declara los metadatos, llama a
* scalarjson y deja el destino servible. Es el ÚNICO lugar donde este nodo
* calcula algo, y calcula exactamente dos cosas: saldo_pc_nominal y
* saldo_real.
*
* DÓNDE VIVE CADA COSA (decisión de Ricardo, 2026-08-01)
*   FUENTE (versionada, aquí):  01_modulos/nodos/nodo-deuda.do
*                               01_modulos/nodos/nodo-deuda.html
*   SALIDA (ignorada, generada): 04_3_nodos/statajson_<nodo>.json
*                                04_3_nodos/nodo-deuda.html  (copia servible)
* 04_3_nodos/ está en .gitignore junto a las demás carpetas de operación
* local: es un destino de render desechable, reconstruible con una corrida —
* exactamente el mismo estatus que los statalatex_*.tex de 06_libro/images,
* que tampoco se versionan. Lo que se versiona es lo que los PRODUCE.
* Corolario que hay que tener presente: el JSON NO tiene historial en git,
* así que su diff entre cortes no es auditable desde el repo; si en
* septiembre hace falta esa comparación, hay que guardar el corte anterior
* a mano antes de re-exportar.
*
* POR QUÉ LA DERIVACIÓN VIVE AQUÍ Y NO EN UpdateSHRFSP (decisión 6)
*   1. La carpeta master/ está en .gitignore. Una columna añadida al
*      .dta es un artefacto NO versionado: la definición del derivado se
*      perdería fuera de Git. Este archivo sí se versiona (por eso vive en
*      01_modulos/nodos/ y no junto a su salida) — y es la definición.
*   2. UpdateSHRFSP vive dentro de SHRFSP.ado, que está PUBLICADO en el
*      endpoint Stata y corre en el VPS. Cada edición ahí es riesgo de
*      deploy (lección v8.0.11). El nodo no compra ese riesgo por una
*      división.
*   3. Regenerar el .dta exige token del BIE, red y la descarga completa de
*      ~30 series de SHCP — y además CAMBIA los datos. Mezclar "añadir un
*      derivado" con "refrescar el corte" en un solo acto, en agosto y antes
*      de septiembre, es exactamente lo que no queremos.
*   4. Si el derivado viviera solo en el .dta, cualquiera con un .dta viejo
*      exportaría un JSON al que le falta una serie, en silencio. Aquí se
*      recalcula en cada exportación.
* Si en un ciclo futuro el derivado pasa al motor, esta línea desaparece de
* aquí y aparece en UpdateSHRFSP: es un cambio de dos líneas, registrado.
*
* PISO 2000 (decisión 3): las filas 1990-1999 de master/SHRFSP.dta traen
* unidad_de_medida == "Dólares"; su monto_pc son dólares per cápita
* deflactados con un índice de precios MEXICANO y su monto_pib es un
* cociente dólares/pesos. No viajan al JSON. El guard de abajo lo verifica
* en cada corrida en lugar de confiar en el piso.
*
* USO:  do "`c(sysdir_site)'/01_modulos/nodos/nodo-deuda.do"
* Se invoca desde el bloque textbook de SHRFSP.ado, tras scalarlatex.

preserve

local site `"`c(sysdir_site)'"'
local piso = 2000

*** 1 AÑO DE REFERENCIA ***
capture confirm scalar aniovp
if _rc {
	di as err "nodo-deuda: falta scalar aniovp (lo fija profile.do). No se exporta."
	exit 198
}
local anioref = scalar(aniovp)

*** 2 SERIE OBSERVADA ***
quietly use `"`site'/master/SHRFSP.dta"', clear

* Guard de unidad: el piso existe por una razón verificable, no por decreto *
quietly count if anio >= `piso' & unidad_de_medida != "Pesos"
if r(N) > 0 {
	di as err "nodo-deuda: `r(N)' año(s) >= `piso' con unidad_de_medida != Pesos."
	di as err "  La serie mezcla monedas por encima del piso. No se exporta."
	exit 459
}

quietly keep if anio >= `piso'
sort anio
local corteanio = anio[_N]
local cortemes  = mes[_N]
local meses "enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre"
local nommes : word `cortemes' of `meses'
local cortetexto "saldo al cierre de `nommes' de `corteanio'"

* LAS derivaciones del nodo. Aguas arriba de scalarjson, versionadas aquí.
* Son las dos únicas cuentas de todo el nodo, y ninguna vive ni en el
* exportador ni en la página. saldo_real usa el MISMO deflactor (INPC) que
* monto_pc trae del .dta, así que saldo_real/poblacion == saldo_pc_real. *
quietly gen double saldo_pc_nominal = shrfsp/poblacion
quietly gen double saldo_real       = shrfsp/deflactor

rename shrfsp    saldo_nominal
rename deflactor indice_precios
rename monto_pc  saldo_pc_real
rename monto_pib saldo_pib

keep  anio saldo_nominal saldo_real poblacion indice_precios saldo_pc_nominal saldo_pc_real saldo_pib
order anio saldo_nominal saldo_real poblacion indice_precios saldo_pc_nominal saldo_pc_real saldo_pib
tempfile serie
quietly save `"`serie'"'

*** 3 METADATOS: unidades, formatos, criterios, fuentes ***
* Los criterios que quedan en blanco NO se rellenan aquí: salen como
* faltantes declarados. Los que sí van describen código verificado en el
* reconocimiento del Paso 1, con su cita.
* OJO: las lineas de datos de `input` NO expanden macros (verificado). Todo
* lo que dependa del corte se deja vacio aqui y se llena abajo con `replace`,
* que si expande. Y nunca se guarda un backtick literal en el dataset: al
* escribirse desde scalarjson se re-expandiria contra las locales de ESE
* programa (inyeccion de macro, cazada en la primera corrida).
clear
quietly input str16 bloque str32 clave str200 texto
"unidad" "saldo_nominal"     "MXN corrientes"
"unidad" "saldo_real"        ""
"unidad" "poblacion"         "personas"
"unidad" "indice_precios"    ""
"unidad" "saldo_pc_nominal"  "MXN corrientes por persona"
"unidad" "saldo_pc_real"     ""
"unidad" "saldo_pib"         "% del PIB"
"formato" "saldo_nominal"    "%12.1fc"
"formato" "saldo_real"       "%12.1fc"
"formato" "poblacion"        "%15.0fc"
"formato" "indice_precios"   "%7.4f"
"formato" "saldo_pc_nominal" "%10.0fc"
"formato" "saldo_pc_real"    "%10.0fc"
"formato" "saldo_pib"        "%7.3fc"
"divisor" "saldo_nominal"    "1000000"
"divisor" "saldo_real"       "1000000"
"fuente" "saldo_nominal"     "SHCP, Estadísticas Oportunas de Finanzas Públicas (datos abiertos), serie SHRF5000, vía DatosAbiertos.ado"
"fuente" "poblacion"         "CONAPO, proyecciones 1950-2070 (pry23), vía Poblacion.ado; master/Poblaciontot.dta"
"fuente" "indice_precios"    "INEGI/BIE serie 910392 (INPC), vía AccesoBIE; master/Deflactor.dta"
"fuente" "saldo_real"        "Derivada en 04_3_nodos/nodo-deuda.do: saldo_nominal / indice_precios"
"fuente" "saldo_pc_nominal"  "Derivada en 04_3_nodos/nodo-deuda.do: saldo_nominal / poblacion"
"fuente" "saldo_pc_real"     "master/SHRFSP.dta, variable monto_pc (DatosAbiertos.ado:105)"
"fuente" "saldo_pib"         "master/SHRFSP.dta, variable monto_pib (DatosAbiertos.ado:112)"
"criterio" "denominador_pib"      "PIB anual = promedio de los cuatro trimestres de pibQ (INEGI/BIE serie 734407), DatosAbiertos.ado:112. No es el PIB proyectado del escenario."
"criterio" "poblacion_denominador" "Población total a mitad de año, CONAPO. No lleva el factor lambda de productividad que SHRFSP.ado aplica a sus escalares."
"criterio" "deflactor"            "INPC mensual, base = último mes disponible de la serie. No es el deflactor implícito del PIB que usa el escenario."
end
quietly replace texto = "índice INPC, base = último mes de la serie (`nommes' `corteanio' = 1)" if bloque == "unidad" & clave == "indice_precios"
quietly replace texto = "MXN constantes de `nommes' de `corteanio' por persona" if bloque == "unidad" & clave == "saldo_pc_real"
quietly replace texto = "MXN constantes de `nommes' de `corteanio'" if bloque == "unidad" & clave == "saldo_real"
tempfile meta
quietly save `"`meta'"'

*** 4 CAPAS DECLARADAS ***
* El escenario solo se publica si la política fiscal fue cargada en esta
* corrida (los globals de SIM.do). Sin ellos, los escalares SHRFSP* traen
* el OBSERVADO, no el escenario: publicarlos como escenario sería el mismo
* número dos veces con dos etiquetas. La capa sale no disponible.
local escenario ""
capture confirm existence ${shrfsp`anioref'}
if _rc == 0 {
	local escenario "SHRFSPPIB"
}
local pe = trim("$paqueteEconomico")

clear
quietly input str32 id str120 etiqueta str32 escalar str72 definida_en str32 tipo_dato str32 unidad str8 incluida
"escenario_paquete" "" "" "" "exogeno_politica_fiscal" "% del PIB" "false"
"deuda_subnacional" "Deuda de entidades federativas y municipios" "" "" "" "" "false"
"pasivo_pensionario" "Pasivo pensionario" "" "" "" "" "false"
end
quietly replace etiqueta    = "Escenario `pe': proyección de cierre de año" in 1
quietly replace escalar     = "`escenario'" in 1
quietly replace definida_en = "SIM.do:362 (matrix shrfsp) -> global shrfsp`anioref'" in 1
tempfile capas
quietly save `"`capas'"'

*** 5 EXPORTACIÓN ***
* Override de destino para 05_scripts/verify_nodo.sh (regla 3): la prueba de
* determinismo exporta dos veces a un temporal y NO puede pisar el contrato
* versionado. Vacío = destino normal (04_3_nodos/statajson_<nodo>.json).
local saveopt ""
if `"$nodo_saving"' != "" {
	local saveopt saving(`"$nodo_saving"')
}

scalarjson, nodo("deuda-publica") ///
	titulo("Deuda pública") ///
	medida("SHRFSP") ///
	anioref(`anioref') ///
	piso(`piso') ///
	corteanio(`corteanio') ///
	cortemes(`cortemes') ///
	cortetexto(`"`cortetexto'"') ///
	serie(`"`serie'"') ///
	origenserie("master/SHRFSP.dta via 04_3_nodos/nodo-deuda.do") ///
	metadatos(`"`meta'"') ///
	capas(`"`capas'"') ///
	escalares("SHRFSPMonto SHRFSPPIB SHRFSPPC SHRFSPInternoPIB SHRFSPExternoPIB DeudaBrutaPIB DeudaBrutaMonto CostoFinancieroPIB CostoFinancieroMonto") ///
	`saveopt'

*** 6 DESTINO SERVIBLE ***
* La página lee el JSON por ruta relativa, así que ambos tienen que quedar
* en la misma carpeta. La fuente vive versionada en 01_modulos/nodos/; aquí
* se deja la copia de render junto a su contrato. Se salta cuando el destino
* fue redirigido (prueba de determinismo del verificador).
if `"$nodo_saving"' == "" {
	capture mkdir `"`site'/04_3_nodos"'
	capture copy `"`site'/01_modulos/nodos/nodo-deuda.html"' ///
		`"`site'/04_3_nodos/nodo-deuda.html"', replace
	if _rc {
		noisily di in g "nodo-deuda: no se pudo copiar la página al destino de render."
	}
}

restore
