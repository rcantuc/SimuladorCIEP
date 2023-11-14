***************************
***                     ***
***    DOWNLOAD ENOE    ***
***                     ***
***************************
capture mkdir "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE"
cd "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE"


** Descargar archivos **
local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
forvalues anio=2005(1)`aniovp' {
	forvalues trim=1(1)4 {
		noisily di in g "Año: " in y `anio' in g ". Trim: " in y `trim'
		capture mkdir "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE/`anio'"
		cd "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE/`anio'"
		if `anio' < 2020 | (`anio' == 2020 & `trim' == 1) {
			unzipfile "https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/microdatos/`anio'trim`trim'_dta.zip"
		}
		if `anio' >= 2023 {
			capture unzipfile "https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/microdatos/enoe_`anio'_trim`trim'_dta.zip"
			if _rc != 0 {
				continue, break
			}
		}
		if (`anio' == 2020 & `trim' != 1 & `trim' != 2) | (`anio' >= 2021 & `anio' <= 2022) {
			unzipfile "https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/microdatos/enoe_n_`anio'_trim`trim'_dta.zip"
		}
		
	}

	* Renombrar archivos *
	local myfiles: dir "`c(sysdir_site)'../BasesCIEP/INEGI/ENOE/`anio'" files "*.dta"
	foreach file of local myfiles {
		shell mv `file' `=lower("`file'")'
		shell mv `=lower("`file'")' `=subinstr("`=lower("`file'")'","enoe_","",.)'
		shell mv `=lower("`file'")' `=subinstr("`=lower("`file'")'","enoen_","",.)'
	}
}
