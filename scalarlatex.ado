*! version 2.1.0  Exporta escalares a LaTeX con el catalogo central de tipos (v8.0.13)
*
* Sintaxis:  scalarlatex [, Logname(string) ALTname(string)]
*
* Recorre TODOS los escalares vivos en memoria (registro GLOBAL-ACUMULADO:
* contrato deliberado, el libro consume escalares de un modulo desde el .tex
* de otro — p.ej. \aniovpscn; ver governance) y escribe
* $export/statalatex_<logname>.tex en UNA pasada con el patron historico:
*
*     \def\d<nombre><alt>#1{\gdef\<nombre><alt>{#1}}
*     \d<nombre><alt>{<valor>}
*
* El formato del valor sale del catalogo de tipos registrado via escalar.ado
* en $scalarlatex_reg (pctpib %7.3fc | pct %7.1fc | mxn /1e6 %12.1fc |
* mxnpc %10.0fc | personas %15.0fc | anio %4.0f | custom(%fmt)). Escalares
* SIN registrar se exportan tal cual (as-is), igual que siempre. Si el mismo
* nombre se registro varias veces, gana la ULTIMA entrada.
*
* Nombres con digitos: LaTeX no admite digitos en nombres de macro (el patron
* viejo los emitia como macros delimitadas inservibles, en silencio). Al
* escribir el .tex cada digito se convierte a letra con la tabla fija
* 0>A 1>B 2>C 3>D 4>E 5>F 6>G 7>H 8>I 9>J (ej. ConsPriv21PIB -> ConsPrivCBPIB).
* Solo cambia el nombre del lado LaTeX; en Stata el escalar conserva su nombre.

program define scalarlatex

	if "$export" != "" {
		syntax [, Logname(string) ALTname(string)]

		* Enumerar los escalares en memoria (una sola captura de log) *
		noisily di _newline(3) in g "{bf:LaTeX scalar list}"
		tempfile scalarstata
		quietly log using `scalarstata', name(scalarlist) replace text
		noisily scalar list
		quietly log close scalarlist

		tempname myfile
		file open `myfile' using `scalarstata', read text
		file read `myfile' line
		while r(eof) == 0 {
			local name = word("`line'",1)
			* Solo nombres validos de escalar: descarta ruido del log
			* (rulers, continuaciones) sin tronar a mitad del .tex *
			capture confirm name `name'
			if _rc == 0 & `: word count `name'' == 1 {
				local scalars "`scalars' `name'"
			}
			file read `myfile' line
		}
		file close `myfile'

		* Mapa nombre->tipo desde el registro (last wins) *
		foreach e of global scalarlatex_reg {
			tokenize `"`e'"', parse(":")
			local t_`1' "`3'"
			local f_`1' "`5'"
		}

		* Escritura del .tex en UNA pasada *
		local nreg = 0
		local nsin = 0
		local sinlist ""
		local nbad = 0
		local badlist ""
		tempname fh
		file open `fh' using "$export/statalatex_`logname'.tex", write replace text
		foreach name in `scalars' {
			local tipo "`t_`name''"
			if "`tipo'" != "" {
				local nreg = `nreg' + 1
			}
			else {
				local nsin = `nsin' + 1
				local sinlist "`sinlist' `name'"
			}
			local xfmt ""
			local xdiv = 1
			if "`tipo'" == "pctpib" 		local xfmt "%7.3fc"
			else if "`tipo'" == "pct" 		local xfmt "%7.1fc"
			else if "`tipo'" == "mxn" {
				local xfmt "%12.1fc"
				local xdiv = 1000000
			}
			else if "`tipo'" == "mxnpc" 	local xfmt "%10.0fc"
			else if "`tipo'" == "personas" 	local xfmt "%15.0fc"
			else if "`tipo'" == "anio" 		local xfmt "%4.0f"
			else if "`tipo'" == "custom" 	local xfmt "`f_`name''"
			if "`xfmt'" != "" {
				* Registrado: formato canonico. Si el valor NO es numerico
				* (nombre registrado pisado por un scalar string, p.ej.
				* Simulador.ado/SIM.do guardan strings preformateados),
				* NO tronar: exportar as-is y reportarlo al final. *
				capture local value = string(scalar(`name')/`xdiv',"`xfmt'")
				if _rc {
					local value = scalar(`name')
					local nbad = `nbad' + 1
					local badlist "`badlist' `name'"
				}
			}
			else {
				* sin registrar: tal cual, comportamiento historico *
				capture local value = scalar(`name')
				if _rc {
					continue
				}
			}

			* Digitos -> letras para el nombre LaTeX *
			local texname "`name'"
			if regexm("`texname'","[0-9]") {
				foreach par in "0A" "1B" "2C" "3D" "4E" "5F" "6G" "7H" "8I" "9J" {
					local texname = subinstr("`texname'", substr("`par'",1,1), substr("`par'",2,1), .)
				}
			}

			file write `fh' "\def\d`texname'`altname'#1{\gdef\\`texname'`altname'{#1}}" _n
			file write `fh' `"\d`texname'`altname'{`value'}"' _n
		}
		file close `fh'

		* Resumen de cobertura: el drift de escalares sin tipo es fallo
		* suave silencioso (typo scalar/escalar) — hacerlo visible.
		* Los sin-registrar se comparan contra el BASELINE AUDITADO
		* (02_governance/scalarlatex-baseline.txt): dentro del baseline
		* -> linea informativa; nombres NUEVOS -> aviso en rojo. Sin el
		* baseline la lista completa (228 nombres) ahogaria la senal. *
		noisily di in g "scalarlatex (`logname'): " in y `nreg' in g " registrados, " in y `nsin' in g " sin registrar (as-is)"
		if `nsin' > 0 {
			local basefile "`c(sysdir_site)'/02_governance/scalarlatex-baseline.txt"
			capture confirm file "`basefile'"
			if _rc == 0 {
				local baseline ""
				tempname bh
				file open `bh' using "`basefile'", read text
				file read `bh' bline
				while r(eof) == 0 {
					local w = word(`"`bline'"',1)
					if `"`w'"' != "" & substr(`"`w'"',1,1) != "*" {
						local baseline "`baseline' `w'"
					}
					file read `bh' bline
				}
				file close `bh'
				local nuevos : list sinlist - baseline
				local nbase : word count `baseline'
				if `"`nuevos'"' == "" {
					noisily di in g "  sin registrar: todos dentro del baseline auditado (`nbase' nombres; ver 02_governance/scalarlatex-baseline.txt)"
				}
				else {
					noisily di as err "  ATENCION: sin registrar NUEVOS respecto al baseline auditado (drift real — typo scalar/escalar o scalar sin migrar):`nuevos'"
					noisily di as err "  Si el alta es legitima, actualizar 02_governance/scalarlatex-baseline.txt (procedimiento en su header)."
				}
			}
			else {
				* Sin baseline (repo incompleto): comportamiento historico *
				noisily di in g "  (baseline no encontrado: `basefile')"
				noisily di in g "  sin registrar:`sinlist'"
			}
		}
		if `nbad' > 0 {
			noisily di as err "  ATENCION: `nbad' registrados con valor NO numerico (exportados as-is):`badlist'"
		}
	}
end
