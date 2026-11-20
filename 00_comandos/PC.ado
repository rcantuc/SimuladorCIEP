program define PC, rclass
quietly {	
	version 13.1
	syntax varname [if] [fweight/] , [POST]

	capture di _newline in y "  PC.ado"


    /*if "`=scalar(aniovp)'" == "2022" {
        local ppp = 9.684
    }
    if "`=scalar(aniovp)'" == "2020" {
        local ppp = 9.813
    }
    if "`=scalar(aniovp)'" == "2018" {
        local ppp = 9.276
    }
    if "`=scalar(aniovp)'" == "2016" {
        local ppp = 8.446
    }
    if "`=scalar(aniovp)'" == "2014" {
        local ppp = 8.045
    }*/


	tempvar varlist2
	g double `varlist2' = `varlist' /* / `ppp' */ `if'


	**********************
	*** 1. Recaudacion ***
	**********************
	tempvar cont
	g double `cont' = 1

	** 1.1 Recaudacion total **
	tempname REC
	capture tabstat `varlist2' [`weight' = `exp'] `if', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `REC' = r(StatTotal)
	}
	else {
		matrix `REC' = J(1,1,0)
	}


	** 1.2 Recaudacion, Hombres y Mujeres **
	tempname RECM
	if "`if'" != "" {
		local ifm = "`if' & sexo == 2"
	}
	else {
		local ifm = "if sexo == 2"
	}
	capture tabstat `varlist2' [`weight' = `exp'] `ifm', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `RECM' = r(StatTotal)
	}
	else {
		matrix `RECM' = J(1,1,0)
	}

	tempname RECH
	if "`if'" != "" {
		local ifh = "`if' & sexo == 1"
	}
	else {
		local ifh = "if sexo == 1"
	}
	capture tabstat `varlist2' [`weight' = `exp'] `ifh', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `RECH' = r(StatTotal)
	}
	else {
		matrix `RECH' = J(1,1,0)
	}


	** 1.3 Recaudacion, Edades 0-18, 19-64, 65 y más **
	tempname REC0_18
	if "`if'" != "" {
		local if0_18 = "`if' & edad <= 18"
	}
	else {
		local if0_18 = "if edad <= 18"
	}
	capture tabstat `varlist2' [`weight' = `exp'] `if0_18', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `REC0_18' = r(StatTotal)
	}
	else {
		matrix `REC0_18' = J(1,1,0)
	}

	tempname REC19_64
	if "`if'" != "" {
		local if19_64 = "`if' & edad > 18 & edad < 65"
	}
	else {
		local if19_64 = "if edad > 18 & edad < 65"
	}
	capture tabstat `varlist2' [`weight' = `exp'] `if19_64', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `REC19_64' = r(StatTotal)
	}
	else {
		matrix `REC19_64' = J(1,1,0)
	}

	tempname REC65
	if "`if'" != "" {
		local if65 = "`if' & edad >= 65"
	}
	else {
		local if65 = "if edad >= 65"
	}
	capture tabstat `varlist2' [`weight' = `exp'] `if65', stat(sum) f(%20.2fc) save
	if _rc == 0 {
		matrix `REC65' = r(StatTotal)
	}
	else {
		matrix `REC65' = J(1,1,0)
	}



	*******************
	*** 2. Personas ***
	*******************
	tempname POB
	capture tabstat `cont' [`weight' = `exp'], stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POB' = r(StatTotal)
	}
	else {
		matrix `POB' = J(1,1,0)
	}


	** 2.1 Contribuyentes totales **
	tempname FOR
	capture tabstat `cont' [`weight' = `exp'] `if', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `FOR' = r(StatTotal)
	}
	else {
		matrix `FOR' = J(1,1,0)
	}


	** 2.2 Poblacion, Hombres y Mujeres **
	tempname POBM
	capture tabstat `cont' [`weight' = `exp'] `ifm', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POBM' = r(StatTotal)
	}
	else {
		matrix `POBM' = J(1,1,0)
	}

	tempname POBH
	capture tabstat `cont' [`weight' = `exp'] `ifh', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POBH' = r(StatTotal)
	}
	else {
		matrix `POBH' = J(1,1,0)
	}


	** 2.3 Poblacion, Edades 0-18, 19-64, 65 y más **
	tempname POB0_18
	capture tabstat `cont' [`weight' = `exp'] `if0_18', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POB0_18' = r(StatTotal)
	}
	else {
		matrix `POB0_18' = J(1,1,0)
	}

	tempname POB19_64
	capture tabstat `cont' [`weight' = `exp'] `if19_64', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POB19_64' = r(StatTotal)
	}
	else {
		matrix `POB19_64' = J(1,1,0)
	}

	tempname POB65
	capture tabstat `cont' [`weight' = `exp'] `if65', stat(sum) f(%12.0fc) save
	if _rc == 0 {
		matrix `POB65' = r(StatTotal)
	}
	else {
		matrix `POB65' = J(1,1,0)
	}



	*************************************
	*** 3. Montos per capita promedio ***
	*************************************

	** 3.1 Monto per capita para contribuyentes totales **
	if `FOR'[1,1] != 0 {
		local montopc = `REC'[1,1]/`FOR'[1,1]
	}
	else {
		local montopc = 0
	}

	** 3.2 Monto per capita para hombres y mujeres **
	if `POBM'[1,1] != 0 {
		local montopcm = `RECM'[1,1]/`POBM'[1,1]
	}
	else {
		local montopcm = 0
	}

	if `POBH'[1,1] != 0 {
		local montopch = `RECH'[1,1]/`POBH'[1,1]
	}
	else {
		local montopch = 0
	}

	** 3.3 Monto per capita por edades **
	if `POB0_18'[1,1] != 0 {
		local montopc0_18 = `REC0_18'[1,1]/`POB0_18'[1,1]
	}
	else {
		local montopc0_18 = 0
	}

	if `POB19_64'[1,1] != 0 {
		local montopc19_64 = `REC19_64'[1,1]/`POB19_64'[1,1]
	}
	else {
		local montopc19_64 = 0
	}

	if `POB65'[1,1] != 0 {
		local montopc65 = `REC65'[1,1]/`POB65'[1,1]
	}
	else {
		local montopc65 = 0
	}

	* Mata: PC *
	local pc = `montopc'
	mata: PC = `pc'

	* Desplegar estadisticos *
	`capture' di in y "  Monto PC (`aniovp')"
	`capture' di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
	`capture' di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]
	`capture' di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]
	`capture' di in g "  Per c{c a'}pita:" _column(40) in y %25.0fc `montopc'



	**********************************
	*** 4. Guardar resultados POST ***
	**********************************
	post PC2 (`REC'[1,1]) (`FOR'[1,1]) (`POB'[1,1]) (`montopc') (`montopch') (`montopcm') ///
		(`montopc0_18') (`montopc19_64') (`montopc65')

	return scalar pc = `pc'
	return matrix REC = `REC'
}
end