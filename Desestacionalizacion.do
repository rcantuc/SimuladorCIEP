* LIF *
use "`c(sysdir_personal)'/bases/LIFs/Nacional/LIF`c(os)'.dta", clear
decode serie, g(series)
levelsof series, local(series)

foreach k of local series {
*foreach k in XAB1120 {


	* SERIES *
	use if clave_de_concepto == "`k'" using "`c(sysdir_personal)'/bases/SHCP/Datos Abiertos/DatosAbiertos`c(os)'.dta", clear
	sort anio mes
	keep if monto != .

	if `=_N' == 0 | monto[_N] == 0 {
		continue
	}


	* REALES *
	merge m:1 (anio trimestre) using "`c(sysdir_personal)'/bases/INEGI/BIE/SCN/Deflactor/deflactor.dta", nogen keep(matched)
	g double deflator = indiceQ/indiceQ[_N]
	replace monto = monto/deflator


	* BEGIN FILE *
	quietly {
	tempfile file
	capture quietly log using `file', replace text name(`k')


	* DATA *
	noisily di  "series{"
	noisily di `"  title="`=nombre[1]'""'
	noisily di  "  start=`=anio[1]'.`=mes[1]'"
	noisily di  "  data=("

	forvalues j=1(1)`=_N' {
		noisily di  "   `=monto[`j']'"
	}
	noisily di  "  )"

	noisily di  "  span=(`=anio[1]'.`=mes[1]', )"
	noisily di  "}"


	* SPECS *
	noisily di  "spectrum{"
	noisily di  "  savelog=peaks"
	noisily di  "}"
	noisily di  "transform{"
	noisily di  "  function=auto"
	noisily di  "  savelog=autotransform"
	noisily di  "}"
	noisily di  "regression{"
	noisily di  "  aictest=(td easter)"
	noisily di  "  savelog=aictest"
	noisily di  "  variables = (td Easter[14])"
	noisily di  "}"
	noisily di  "automdl{"
	noisily di  "  savelog=automodel"
	noisily di  "}"
	noisily di  "outlier{ }"
	noisily di  "x11{}"


	* END FILE *
	capture quietly log close `k'
	tempfile file1 file2 file3
	if "`=c(os)'" == "Windows" {
		filefilter `file' `file1', from(\r\n>) to("") replace		// Windows
	}
	else {
		filefilter `file' `file1', from(\n>) to("") replace			// Mac & Linux
	}
	filefilter `file1' "`c(sysdir_personal)'/bases/X13 ARIMA SEATS/SeriesHacienda/`k'.spc", from(".,") to("0") replace
	}

	shell "/home/ciepmx/Dropbox (CIEP)/4.10 (Sim5)/bases/X13 ARIMA SEATS/x13as" "`c(sysdir_personal)'/bases/X13 ARIMA SEATS/SeriesHacienda/`k'" 
}
