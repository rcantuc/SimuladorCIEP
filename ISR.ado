**********************************************************************
****         MICRO SIMULADOR DEL IMPUESTO SOBRE LA RENTA          ****
****      CENTRO DE INVESTIGACION ECONOMICA Y PRESUPUESTARIA      ****
**********************************************************************
program define ISR
quietly {
	version 13.1
	syntax [using/]
	di _newline in g "* M${o}dulo: " in y "ISR.ado " _cont
	if "`using'" != "" {
		di in g "using " in y `"`using'"' in g " *"
	}
	else {
		di in g " *"
	}




	*****************
	*** 0. INICIO ***
	*****************
	capture confirm file "`c(sysdir_personal)'/bases/SIM/2016/income.dta"
	if _rc != 0 {
		noisily run "`c(sysdir_personal)'/Income.do"
	}





	************************
	*** 1. BASE DE DATOS ***
	************************
	if `"`using'"' == "" {
		use "`c(sysdir_personal)'/bases/SIM/2016/income.dta", clear
	}
	else {
		use `"`using'"', clear
	}





	**********************************/
	*** 2. NUEVO ESQUEMA IMPOSITIVO ***
	***********************************



	**************
	** 2.1. ISR **
	*		Inferior	Superior	CF		Tasa		
	matrix ISR = 	(0.00,		5952.84,	0.0,		1.92  \ 	///	1
			5952.85,	50524.92,	114.24,		6.40  \ 	///	2
			50524.93,	88793.04,	2966.76,	10.88 \ 	///	3
			88793.05,	103218.00,	7130.88,	16.00 \ 	///	4
			103218.01,	123580.20,	9438.60,	17.92 \ 	///	5
			123580.21,	249243.48,	13087.44,	21.36 \ 	///	6
			249243.49,	392841.96,	39929.04,	23.52 \ 	///	7
			392841.97,	750000.00, 	73703.40,	30.00 \ 	///	8
			750000.01,	1000000.00,	180850.82,	32.00 \ 	///	9
			1000000.01,	3000000.00,	260850.81,	34.00 \ 	///	10
			3000000.01,	1E+14, 		940850.81,	35.00)		//	11

	*		Inferior	Superior	Subsidio
	matrix SE = 	(0.00,		21227.52,	4884.24 \	///	1
			21227.53,	23744.40,	4881.96 \	///	2
			23744.41,	31840.56,	4318.08 \	///	3
			31840.57,	41674.08,	4123.20 \	///	4
			41674.09,	42454.44,	3723.48 \	///	5
			42454.45,	53353.80,	3581.28 \	///	6
			53353.81,	56606.16,	4250.76 \	///	7
			56606.17,	64025.04,	3898.44 \	///	8
			64025.05,	74696.04,	3535.56 \	///	9
			74696.05,	85366.80,	3042.48 \	///	10
			85366.81,	88587.96,	2611.32 \	///	11
			88587.97, 	1E+14,		0)		//	12



	*********************
	** 2.2. EXENCIONES **
	drop ing_capital
	egen double ing_capital = rsum(ing_util ing_ganan ing_indemn ing_indemn2 ing_indemn3 ///
		ing_segvida ///
		ing_rent ///
		ing_enajecasa ing_enajem ing_enaje ///
		ing_intereses ///
		ing_dona ///
		ing_loter ///
		ing_acc ///
		ing_autor /*ing_remesas ing_prest ing_otrocap ing_ahorro*/ ing_heren /*ing_benef*/)	// 21

	drop exen_capital
	egen double exen_capital = rsum(exen_util exen_ganan exen_indemn exen_indemn2 exen_indemn3 ///
		exen_segvida ///
		exen_rent ///
		exen_enajecasa exen_enajem exen_enaje ///
		exen_intereses ///
		exen_dona ///
		exen_loter ///
		exen_acc ///
		exen_autor /*exen_remesas exen_prest exen_otrocap exen_ahorro*/ exen_heren /*exen_benef*/)



	***************
	** 2.3. ISR ***
	drop ing_bruto_tax exen_tot
	g double ing_bruto_tax = ing_subor + ing_mixto + ing_capital
	label var ing_bruto_tax "Ingreso gravable"
	g double exen_tot = exen_t4_cap1 + exen_mixto + exen_capital
	label var exen_tot "Exenciones totales"



	************************************
	** Ingresos gravable (alquileres) **
	replace ing_bruto_tax = ing_bruto_tax - ing_rent if formal_renta == 0 & prob_renta != . & formal != 0
	replace exen_tot = exen_tot - exen_rent if formal_renta == 0 & prob_renta != . & formal != 0

	* Formales (alquileres) *
	replace ing_bruto_tax = ing_rent if formal_renta == 1 & prob_renta != . & formal == 0
	replace exen_tot = exen_rent if formal_renta == 1 & prob_renta != . & formal == 0

	capture confirm existence $escen2
	if _rc != 0 {
		global escen2 = 0
	}
	if $escen2 == 1 {
		replace ing_bruto_tax = ing_bruto_tax - ing_rent if formal_renta == 1 & prob_renta != . & formal != 0
		replace exen_tot = exen_tot - exen_rent if formal_renta == 1 & prob_renta != . & formal != 0
	}



	*************************************************
	** Ingresos gravable (servicios profesionales) **
	replace ing_bruto_tax = ing_bruto_tax - (ing_honor + ing_empre) if formal_servprof == 0 & prob_servprof != . & formal != 0
	replace exen_tot = exen_tot - (exen_honor + exen_empre) if formal_servprof == 0 & prob_servprof != . & formal != 0

	* Formales (servicios profesionales) *
	replace ing_bruto_tax = (ing_honor + ing_empre) if formal_servprof == 1 & prob_servprof != . & formal == 0
	replace exen_tot = (exen_honor + exen_empre) if formal_servprof == 1 & prob_servprof != . & formal == 0


	*************************
	** Limitar deducciones **
	local smdf = 73.04
	*replace deduc_isr = 5*`smdf'*365 if 5*`smdf'*365 <= 15/100*ing_bruto_tax & deduc_isr >= 5*`smdf'*365
	*replace deduc_isr = 15/100*ing_bruto_tax if 5*`smdf'*365 >= 15/100*ing_bruto_tax & deduc_isr >= 15/100*ing_bruto_tax



	**************
	** Calcular **
	g double ISR2 = 0
	label var ISR2 "ISR (f${i}sicas y asalariados)"
	replace categF = ""
	forvalues j=`=rowsof(ISR)'(-1)1 {
		forvalues k=`=rowsof(SE)'(-1)1 {
			replace categF = "J`j'K`k'" ///
				if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= ISR[`j',1] ///
				 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= ISR[`j',2] ///
				 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= SE[`k',1] ///
				 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= SE[`k',2] ///
				 //& formal != 0

			replace ISR2 = ISR[`j',3] + ///
				(ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
				- SE[`k',3]*htrab/48 ///
				if categF == "J`j'K`k'" /*& formal != 0*/ & htrab < 48 & tipo_contribuyente == 1
			replace ISR2 = ISR[`j',3] + ///
				(ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
				- SE[`k',3] ///
				if categF == "J`j'K`k'" /*& formal != 0*/ & htrab >= 48 & tipo_contribuyente == 1
			replace ISR2 = ISR[`j',3] + ///
				(ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
				if categF == "J`j'K`k'" & /*formal != 0*/ & (tipo_contribuyente == 2 | htrab == 0)
		}
	}
	replace ISR2 = 0 if formal == 0 & formal_renta == 0 & formal_servprof == 0

	* Sankey *
	g double ISR__PF2 = ISR2 - isrE if ISR2 - isrE >= 0

	replace ISR__PF2 = ISR__PF2 // *(1-.16071429)
	replace ISR__PF2 = 0 if ISR__PF2 == .
	label var ISR__PF2 "ISR (personas f${i}sicas)"
}
end
