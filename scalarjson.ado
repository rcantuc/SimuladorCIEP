*! version 1.0.0  Exporta un nodo (escalares + serie) a JSON — hermano de scalarlatex (v8.2.0)
*
* REGLA DURA (governance): scalarjson es un exportador HERMANO DE SOLO LECTURA.
* NO modifica scalarlatex.ado, NI el registro $scalarlatex_reg, NI el baseline
* auditado 02_governance/scalarlatex-baseline.txt (no lo lee siquiera: ese
* baseline gobierna la cobertura del libro, no la de un nodo).
*
* NO CALCULA. Todo valor que escribe ya existe: o en el registro de escalares
* (contrato escalar.ado) o en el dataset de serie que recibe ya preparado. Un
* derivado que no exista en ninguno de los dos es un FALTANTE reportado, no un
* calculo improvisado aqui. La derivacion vive aguas arriba, versionada.
*
* Sintaxis:
*   scalarjson, nodo(<slug>) serie(<ruta .dta>) [opciones]
*
*   serie()      dataset YA PREPARADO por el driver del nodo, con las
*                variables canonicas del esquema:
*                  anio saldo_nominal saldo_real poblacion indice_precios
*                  saldo_pc_nominal saldo_pc_real saldo_pib
*                Una variable canonica ausente => null en todas las filas
*                + faltante declarado. scalarjson no la fabrica.
*
*   metadatos()  dataset largo con bloque/clave/texto. bloque en:
*                  unidad   clave = variable canonica -> texto = unidad
*                  formato  clave = variable canonica -> texto = %fmt
*                  divisor  clave = variable canonica -> texto = divisor
*                  criterio clave = uno de los 7 campos de conciliacion
*                  fuente   clave = variable canonica
*                Clave ausente => cadena vacia + faltante declarado.
*
*   capas()      dataset con id etiqueta escalar definida_en tipo_dato
*                unidad incluida. Cada capa declara SU PROPIA procedencia:
*                  origen = registro_escalares | no_disponible
*                (el titular lleva origen = serie_observada). Si el escalar
*                de la capa no esta vivo en memoria, la capa sale con
*                disponible=false y valor null — nunca con un numero prestado.
*
*   escalares()  nombres a exportar. Vacio = todos los del registro que
*                esten vivos en memoria.
*
* Espeja de scalarlatex tres pasos y solo tres: (1) enumeracion de escalares
* vivos via log temporal + scalar list, (2) mapa nombre->tipo desde
* $scalarlatex_reg con last-wins, (3) catalogo de tipos. NO espeja el
* digitos->letras (es una restriccion de nombres de macro de LaTeX) ni el
* alias. Y donde scalarlatex escribe strings YA FORMATEADOS, scalarjson
* escribe NUMEROS de precision completa mas formato_sugerido/divisor_sugerido:
* el formato es una sugerencia de presentacion, no el dato.
*
* DETERMINISMO: la unica fuente de variacion entre dos corridas identicas es
* procedencia.generado_en, aislado a proposito como ULTIMA clave del bloque
* procedencia para que un diff de una sola linea lo distinga del contenido.

program define scalarjson
	version 14

	syntax , NODO(string) SERIE(string) ///
		[ TITULO(string) MEDIDA(string) ANIOREF(int 0) PISO(int 0) ///
		  CORTEANIO(int 0) CORTEMES(int 0) CORTETEXTO(string) ///
		  ESCALARES(string) METADATOS(string) CAPAS(string) TABLA(string) ///
		  ORIGENSERIE(string) SAVING(string) ]

	* La ruta real de serie() es un tempfile: viajaria distinta en cada
	* corrida y romperia el determinismo. Al JSON va la etiqueta ESTABLE
	* que declara el driver (de donde salieron los datos, no donde estuvo
	* el archivo temporal).
	if `"`origenserie'"' == "" local origenserie `"`serie'"'

	local site `"`c(sysdir_site)'"'
	if `"`saving'"' == "" {
		local saving `"`site'/04_1_paqueteeconomico.ciep.mx/public_html/nodos/statajson_`nodo'.json"'
	}
	local faltantes ""
	local q = char(34)

	*** 1 PROCEDENCIA: manifiesto (unica fuente de verdad de version/corte) ***
	local mversion ""
	local mcorte ""
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
	if "`mversion'" == "" local faltantes `"`faltantes' procedencia.version_simulador"'
	if "`mcorte'"   == "" local faltantes `"`faltantes' procedencia.corte_datos"'

	* Log activo: solo el nombre base. Una ruta absoluta rompe el determinismo
	* entre maquinas sin aportarle nada al lector de la pagina.
	local logfile ""
	capture quietly log query
	local lf `"`r(filename)'"'
	if `"`lf'"' != "" & `"`lf'"' != "." {
		local logfile = substr(`"`lf'"', length(`"`lf'"') - strpos(reverse(`"`lf'"'), "/") + 2, .)
	}
	if `"`logfile'"' == "" local faltantes `"`faltantes' procedencia.log"'

	*** 2 ENUMERACION DE ESCALARES VIVOS (espejo de scalarlatex) ***
	tempfile scalarstata
	quietly log using `"`scalarstata'"', name(scalarjsonlist) replace text
	quietly scalar list
	quietly log close scalarjsonlist

	local vivos ""
	tempname sh
	file open `sh' using `"`scalarstata'"', read text
	file read `sh' line
	while r(eof) == 0 {
		local nm = word(`"`line'"', 1)
		capture confirm name `nm'
		if _rc == 0 & `: word count `nm'' == 1 {
			local vivos `"`vivos' `nm'"'
		}
		file read `sh' line
	}
	file close `sh'

	*** 3 MAPA NOMBRE->TIPO DESDE EL REGISTRO (last wins, espejo exacto) ***
	local registrados ""
	foreach e of global scalarlatex_reg {
		tokenize `"`e'"', parse(":")
		local t_`1' "`3'"
		local f_`1' "`5'"
		local nm1 "`1'"
		local registrados : list registrados | nm1
	}

	* Lista a exportar: la pedida, o el registro intersectado con lo vivo *
	if `"`escalares'"' == "" {
		local pedidos : list registrados & vivos
	}
	else {
		local pedidos `"`escalares'"'
	}
	local nped : word count `pedidos'

	*** 4 ESCRITURA ***
	preserve
	tempname fh
	file open `fh' using `"`saving'"', write replace text

	file write `fh' "{" _n
	file write `fh' `"  `q'esquema`q': `q'ciep.nodo.serie/v1`q',"' _n
	_sjkv `fh' "nodo" `"`nodo'"' 2 1
	_sjkv `fh' "titulo" `"`titulo'"' 2 1
	_sjkv `fh' "medida_titular" `"`medida'"' 2 1
	file write `fh' `"  `q'anio_referencia`q': `anioref',"' _n
	file write `fh' `"  `q'piso_serie`q': `piso',"' _n

	** 4.1 procedencia — el sello va al final, aislado en UNA linea **
	file write `fh' `"  `q'procedencia`q': {"' _n
	_sjkv `fh' "version_simulador" `"`mversion'"' 4 1
	_sjkv `fh' "corte_datos" `"`mcorte'"' 4 1
	file write `fh' `"    `q'corte_serie`q': {"' _n
	file write `fh' `"      `q'anio`q': `corteanio',"' _n
	file write `fh' `"      `q'mes`q': `cortemes',"' _n
	_sjkv `fh' "etiqueta" `"`cortetexto'"' 6 0
	file write `fh' "    }," _n
	_sjkv `fh' "log" `"`logfile'"' 4 1
	_sjkv `fh' "origen" "simulador" 4 1
	_sjkv `fh' "dataset_serie" `"`origenserie'"' 4 1
	local sello = subinstr(trim(`"`c(current_date)'"'), " ", "-", .) + "T" + trim(`"`c(current_time)'"')
	_sjkv `fh' "generado_en" `"`sello'"' 4 0
	file write `fh' "  }," _n

	** 4.2 unidades / criterios / fuentes — desde metadatos **
	local canon "saldo_nominal saldo_real poblacion indice_precios saldo_pc_nominal saldo_pc_real saldo_pib"
	local ncanon : word count `canon'
	local criterios7 "cobertura_institucional momento_de_registro neto_o_bruto moneda_y_valuacion denominador_pib poblacion_denominador deflactor"

	local hasmeta = 0
	if `"`metadatos'"' != "" {
		capture confirm file `"`metadatos'"'
		if _rc == 0 {
			quietly use `"`metadatos'"', clear
			local hasmeta = 1
		}
	}
	if `hasmeta' == 0 local faltantes `"`faltantes' metadatos.dataset"'

	file write `fh' `"  `q'unidades`q': {"' _n
	local i = 0
	foreach v of local canon {
		local i = `i' + 1
		local coma = cond(`i' < `ncanon', ",", "")
		local u ""
		local fm ""
		local dv "1"
		if `hasmeta' {
			_sjget "unidad" "`v'"
			local u `"`r(texto)'"'
			_sjget "formato" "`v'"
			local fm `"`r(texto)'"'
			_sjget "divisor" "`v'"
			if `"`r(texto)'"' != "" local dv `"`r(texto)'"'
		}
		if `"`u'"'  == "" local faltantes `"`faltantes' unidad.`v'"'
		if `"`fm'"' == "" local faltantes `"`faltantes' formato.`v'"'
		_sjesc `"`u'"'
		local ue `"`r(s)'"'
		_sjesc `"`fm'"'
		local fme `"`r(s)'"'
		file write `fh' `"    `q'`v'`q': {`q'unidad`q': `q'`ue'`q', "'
		file write `fh' `"`q'formato_sugerido`q': `q'`fme'`q', "'
		file write `fh' `"`q'divisor_sugerido`q': `dv'}`coma'"' _n
	}
	file write `fh' "  }," _n

	file write `fh' `"  `q'criterios`q': {"' _n
	local i = 0
	foreach k of local criterios7 {
		local i = `i' + 1
		local coma = cond(`i' < 7, 1, 0)
		local t ""
		if `hasmeta' {
			_sjget "criterio" "`k'"
			local t `"`r(texto)'"'
		}
		if `"`t'"' == "" local faltantes `"`faltantes' criterio.`k'"'
		_sjkv `fh' "`k'" `"`t'"' 4 `coma'
	}
	file write `fh' "  }," _n

	file write `fh' `"  `q'fuentes`q': {"' _n
	local i = 0
	foreach v of local canon {
		local i = `i' + 1
		local coma = cond(`i' < `ncanon', 1, 0)
		local t ""
		if `hasmeta' {
			_sjget "fuente" "`v'"
			local t `"`r(texto)'"'
		}
		if `"`t'"' == "" local faltantes `"`faltantes' fuente.`v'"'
		_sjkv `fh' "`v'" `"`t'"' 4 `coma'
	}
	file write `fh' "  }," _n

	** 4.2.1 presentacion — lo que la pagina necesita para RENDERIZAR y que
	* no es una cifra: etiqueta de moneda, escala, denominadores por bloque.
	* Claves libres: el driver declara, la pagina lee. Nada de esto se
	* escribe en el HTML. *
	file write `fh' `"  `q'presentacion`q': {"' _n
	local npres = 0
	if `hasmeta' {
		quietly count if bloque == "presentacion"
		local npres = r(N)
		local i = 0
		forvalues r = 1/`=_N' {
			if bloque[`r'] == "presentacion" {
				local i = `i' + 1
				local pk = clave[`r']
				local pt = texto[`r']
				_sjkv `fh' "`pk'" `"`pt'"' 4 `=cond(`i' < `npres', 1, 0)'
			}
		}
	}
	if `npres' == 0 local faltantes `"`faltantes' presentacion.vacia"'
	file write `fh' "  }," _n

	** 4.2.2 tabla — la ESTRUCTURA del display que la pagina espeja: que
	* filas, en que orden, con que etiqueta, prefijo y familia de escalar.
	* Vive en el contrato (no en la pagina) para que la tabla del sitio no
	* pueda divergir en silencio de la que imprime el modulo en Stata. *
	file write `fh' `"  `q'tabla`q': ["' _n
	local nfilas = 0
	if `"`tabla'"' != "" {
		capture confirm file `"`tabla'"'
		if _rc == 0 {
			quietly use `"`tabla'"', clear
			local nfilas = _N
		}
	}
	if `nfilas' == 0 local faltantes `"`faltantes' tabla.dataset"'
	forvalues r = 1/`nfilas' {
		local tb  = bloque[`r']
		local tet = etiqueta[`r']
		local tpx = prefijo[`r']
		local tfa = familia[`r']
		local ten = enfasis[`r']
		_sjesc `"`tet'"'
		local tete `"`r(s)'"'
		file write `fh' `"    {`q'bloque`q': `tb', `q'etiqueta`q': `q'`tete'`q', "'
		file write `fh' `"`q'prefijo`q': `q'`tpx'`q', `q'familia`q': `q'`tfa'`q', "'
		file write `fh' `"`q'enfasis`q': `ten'}`=cond(`r' < `nfilas', ",", "")'"' _n
	}
	file write `fh' "  ]," _n

	** 4.3 capas declaradas — cada una con SU procedencia **
	file write `fh' `"  `q'capas_declaradas`q': ["' _n
	local ncapas = 0
	if `"`capas'"' != "" {
		capture confirm file `"`capas'"'
		if _rc == 0 {
			quietly use `"`capas'"', clear
			local ncapas = _N
		}
	}
	if `ncapas' == 0 local faltantes `"`faltantes' capas.dataset"'
	forvalues j = 1/`ncapas' {
		local cid   = id[`j']
		local cet   = etiqueta[`j']
		local cesc  = escalar[`j']
		local cuni  = unidad[`j']
		local cinc  = incluida[`j']
		* Estos dos se escriben directo (no via _sjkv): sanear aqui. *
		_sjesc `"`=definida_en[`j']'"'
		local cdef `"`r(s)'"'
		_sjesc `"`=tipo_dato[`j']'"'
		local ctipo `"`r(s)'"'
		local coma = cond(`j' < `ncapas', ",", "")

		local cval "null"
		local cfmt ""
		local cdisp "false"
		local corigen "no_disponible"
		if `"`cesc'"' != "" {
			capture confirm scalar `cesc'
			if _rc == 0 {
				local tipo "`t_`cesc''"
				local cfmt ""
				if "`tipo'" == "pctpib"        local cfmt "%7.3fc"
				else if "`tipo'" == "pct"      local cfmt "%7.1fc"
				else if "`tipo'" == "mxn"      local cfmt "%12.1fc"
				else if "`tipo'" == "mxnpc"    local cfmt "%10.0fc"
				else if "`tipo'" == "personas" local cfmt "%15.0fc"
				else if "`tipo'" == "anio"     local cfmt "%4.0f"
				else if "`tipo'" == "custom"   local cfmt "`f_`cesc''"
				_sjnum "scalar(`cesc')"
				local cval `"`r(n)'"'
				if "`cval'" != "null" {
					local cdisp "true"
					local corigen "registro_escalares"
				}
			}
		}
		if "`cdisp'" == "false" local faltantes `"`faltantes' capa.`cid'"'

		file write `fh' "    {" _n
		_sjkv `fh' "id" `"`cid'"' 6 1
		_sjkv `fh' "etiqueta" `"`cet'"' 6 1
		file write `fh' `"      `q'incluida_en_titular`q': `cinc',"' _n
		file write `fh' `"      `q'disponible`q': `cdisp',"' _n
		file write `fh' `"      `q'valor`q': `cval',"' _n
		_sjkv `fh' "unidad" `"`cuni'"' 6 1
		_sjkv `fh' "formato_sugerido" `"`cfmt'"' 6 1
		file write `fh' `"      `q'procedencia`q': {`q'origen`q': `q'`corigen'`q', "'
		file write `fh' `"`q'escalar`q': `q'`cesc'`q', "'
		file write `fh' `"`q'definida_en`q': `q'`cdef'`q', "'
		file write `fh' `"`q'tipo_dato`q': `q'`ctipo'`q'}"' _n
		file write `fh' "    }`coma'" _n
	}
	file write `fh' "  ]," _n

	** 4.4 escalares (catalogo aplicado, numeros crudos) **
	file write `fh' `"  `q'escalares`q': {"' _n
	local i = 0
	local nesc = 0
	foreach nm of local pedidos {
		local i = `i' + 1
		capture confirm scalar `nm'
		if _rc {
			local faltantes `"`faltantes' escalar.`nm'"'
			continue
		}
		local tipo "`t_`nm''"
		if "`tipo'" == "" local faltantes `"`faltantes' tipo.`nm'"'
		local xfmt ""
		local xdiv "1"
		if "`tipo'" == "pctpib"        local xfmt "%7.3fc"
		else if "`tipo'" == "pct"      local xfmt "%7.1fc"
		else if "`tipo'" == "mxn" {
			local xfmt "%12.1fc"
			local xdiv "1000000"
		}
		else if "`tipo'" == "mxnpc"    local xfmt "%10.0fc"
		else if "`tipo'" == "personas" local xfmt "%15.0fc"
		else if "`tipo'" == "anio"     local xfmt "%4.0f"
		else if "`tipo'" == "custom"   local xfmt "`f_`nm''"

		* Un registrado pisado por un scalar string (el caso que scalarlatex
		* reporta como no numerico) sale null y se declara: no truena. *
		_sjnum "scalar(`nm')"
		local val `"`r(n)'"'
		if "`val'" == "null" local faltantes `"`faltantes' valor_nulo.`nm'"'
		local coma = cond(`i' < `nped', ",", "")
		file write `fh' `"    `q'`nm'`q': {`q'valor`q': `val', "'
		file write `fh' `"`q'tipo`q': `q'`tipo'`q', "'
		file write `fh' `"`q'formato_sugerido`q': `q'`xfmt'`q', "'
		file write `fh' `"`q'divisor_sugerido`q': `xdiv'}`coma'"' _n
		local nesc = `nesc' + 1
	}
	file write `fh' "  }," _n

	** 4.5 titular + cobertura + series — desde el dataset de serie **
	quietly use `"`serie'"', clear
	quietly keep if anio >= `piso'
	sort anio

	local presentes ""
	foreach v of local canon {
		capture confirm variable `v'
		if _rc == 0 {
			local presentes `"`presentes' `v'"'
		}
		else {
			local faltantes `"`faltantes' serie.`v'"'
		}
	}

	* Titular: la fila del anio de referencia. Se LEE, no se calcula. *
	tempvar idx
	quietly gen long `idx' = _n
	quietly summarize `idx' if anio == `anioref', meanonly
	local nref = r(N)
	local obsref = r(min)
	if `nref' == 0 local faltantes `"`faltantes' titular.fila_anio_referencia"'

	file write `fh' `"  `q'titular`q': {"' _n
	file write `fh' `"    `q'anio`q': `anioref',"' _n
	file write `fh' `"    `q'procedencia`q': {`q'origen`q': `q'serie_observada`q', "'
	file write `fh' `"`q'dataset`q': `q'`origenserie'`q', `q'tipo_dato`q': `q'observado`q'},"' _n
	local i = 0
	foreach v of local canon {
		local i = `i' + 1
		local coma = cond(`i' < `ncanon', ",", "")
		local val "null"
		if `: list v in presentes' & `nref' > 0 {
			_sjnum "`v'[`obsref']"
			local val `"`r(n)'"'
		}
		if "`val'" == "null" local faltantes `"`faltantes' titular.`v'"'
		file write `fh' `"    `q'`v'`q': `val'`coma'"' _n
	}
	file write `fh' "  }," _n

	* Cobertura y huecos de anio *
	quietly summarize anio, meanonly
	local amin = r(min)
	local amax = r(max)
	local esperados = `amax' - `amin' + 1
	local huecos ""
	forvalues a = `amin'/`amax' {
		quietly count if anio == `a'
		if r(N) == 0 local huecos `"`huecos' `a'"'
	}
	local nhuecos : word count `huecos'
	file write `fh' `"  `q'cobertura`q': {`q'anio_min`q': `amin', `q'anio_max`q': `amax', "'
	file write `fh' `"`q'n_anios`q': `=_N', `q'n_esperados`q': `esperados', "'
	file write `fh' `"`q'anios_faltantes`q': ["'
	local i = 0
	foreach a of local huecos {
		local i = `i' + 1
		local coma = cond(`i' < `nhuecos', ", ", "")
		file write `fh' "`a'`coma'"
	}
	file write `fh' "]}," _n

	file write `fh' `"  `q'series`q': ["' _n
	local nobs = _N
	forvalues j = 1/`nobs' {
		file write `fh' `"    {`q'anio`q': `=anio[`j']'"'
		foreach v of local canon {
			local val "null"
			if `: list v in presentes' {
				_sjnum "`v'[`j']"
				local val `"`r(n)'"'
			}
			file write `fh' `", `q'`v'`q': `val'"'
		}
		local coma = cond(`j' < `nobs', ",", "")
		file write `fh' "}`coma'" _n
	}
	file write `fh' "  ]," _n

	** 4.6 faltantes: la estructura completa importa mas que el contenido **
	local faltantes : list clean faltantes
	local nfalta : word count `faltantes'
	file write `fh' `"  `q'faltantes`q': ["' _n
	local i = 0
	foreach f of local faltantes {
		local i = `i' + 1
		local coma = cond(`i' < `nfalta', ",", "")
		file write `fh' `"    `q'`f'`q'`coma'"' _n
	}
	file write `fh' "  ]" _n
	file write `fh' "}" _n
	file close `fh'
	restore

	noisily di in g "scalarjson (`nodo'): " in y `nesc' in g " escalares, " ///
		in y `nobs' in g " anios de serie, " in y `ncapas' in g " capas, " ///
		in y `nfalta' in g " faltantes declarados"
	noisily di in g "  -> " in y `"`saving'"'
	if `nfalta' > 0 {
		noisily di in g "  faltantes:`faltantes'"
	}
end


* Emision de un NUMERO a JSON, con precision completa.
* Recibe la EXPRESION como texto (no el valor ya convertido): pasar el valor
* lo redondearia al formato por defecto antes de llegar aqui.
*   - missing (incluidas .a-.z) -> null
*   - no numerico (scalar string) -> null
*   - Stata escribe .3319 y JSON exige 0.3319: se antepone el cero. *
program define _sjnum, rclass
	args e
	return local n "null"
	capture local ismiss = (`e' >= .)
	if _rc exit
	if `ismiss' exit
	* 17 digitos significativos: es lo que garantiza round-trip exacto de un
	* double IEEE754. Con 15 el JSON perdia el ultimo bit y la pagina redondeaba
	* a un peso de distancia del display de Stata (SHRFSPMonto ...533 vs ...534).
	capture local s = trim(string(`e', "%25.17g"))
	if _rc exit
	if substr("`s'", 1, 1) == "."  local s = "0`s'"
	if substr("`s'", 1, 2) == "-." local s = "-0" + substr("`s'", 2, .)
	return local n "`s'"
end


* Saneamiento de un texto antes de escribirlo al JSON.
*
* (a) Backslash y comilla doble: escape JSON.
* (b) Backtick: se ELIMINA. Un texto que viene de un dataset y lleva un
*     backtick literal se re-expande al escribirse desde aqui, contra las
*     LOCALES DE scalarjson — un `anioref' guardado en un .dta salia como
*     "2026" en el JSON. Es inyeccion de macro, no formato: el backtick no
*     significa nada en JSON y no sobrevive.
*
* OJO: el backslash NO puede viajar por macro a un literal entrecomillado —
* en Stata escapa la expansion de macros y rompe el parser (r(198)). Por eso
* char(92)/char(34)/char(96) se usan DENTRO de la expresion, nunca
* interpolados en un string. *
program define _sjesc, rclass
	args s
	local s = subinstr(`"`s'"', char(96), "", .)
	local s = subinstr(`"`s'"', char(92), char(92) + char(92), .)
	local s = subinstr(`"`s'"', char(34), char(92) + char(34), .)
	return local s `"`s'"'
end


* Escritura de un par "clave": "valor" de texto, con saneamiento y sangria. *
program define _sjkv
	args fh clave valor sangria coma
	local q = char(34)
	local v = subinstr(`"`valor'"', char(96), "", .)
	local v = subinstr(`"`v'"', char(92), char(92) + char(92), .)
	local v = subinstr(`"`v'"', char(34), char(92) + char(34), .)
	local pad = substr("                    ", 1, `sangria')
	local c = cond(`coma', ",", "")
	file write `fh' `"`pad'`q'`clave'`q': `q'`v'`q'`c'"' _n
end


* Lookup exacto en el dataset de metadatos: (bloque, clave) -> texto. *
program define _sjget, rclass
	args bl cl
	return local texto ""
	capture confirm variable bloque
	if _rc exit
	tempvar ix
	quietly gen long `ix' = _n
	quietly summarize `ix' if bloque == "`bl'" & clave == "`cl'", meanonly
	local n = r(N)
	local pos = r(min)
	if `n' > 0 {
		return local texto = texto[`pos']
	}
	quietly drop `ix'
end
