******************
*** 4 INGRESOS ***
******************
timer on 97
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY




********************************************
** PAR{c A'}METROS DEL SIMULADOR (BASICO) **
**        Paquete Economico 2021          **

global id = "`id'"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

** Al ingreso **
scalar ISR_AS  = 3.511 // 														ISR (asalariados)
scalar ISR_PF  = 0.202 // 														ISR (personas f{c i'}sicas)
scalar CuotasT = 1.551 // 														Cuotas (IMSS)

* Al consumo *
scalar IVA     = 4.179 //														IVA 
scalar ISAN    = 0.045 //														ISAN
scalar IEPS    = 2.139 // 														IEPS (no petrolero + petrolero)
scalar Importa = 0.294 //														Importaciones

* Al capital *
scalar ISR_PM  = 3.973 //														ISR (personas morales)
scalar FMP     = 1.712 // 														Fondo Mexicano del Petr{c o'}leo
scalar OYE     = 4.418 //														Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)
scalar OtrosI  = 0.885 //														Productos, derechos, aprovechamientos, contribuciones

run "`c(sysdir_personal)'/2PIBWeb.do" //								Cap. 2. Sistema: Desempeño + SCN


***********************************/



**********************
/** 4.1 ISR PF + PM **
noisily di in g " Modulo: " in y "41ISR.do"
*				Inferior	Superior	CF			Tasa
matrix	ISR	= (	0.00,		5952.84,	0.0,		1.92	\	///	1
				5952.85,	50524.92,	114.24,		6.40	\ 	///	2
				50524.93,	88793.04,	2966.76,	10.88	\ 	///	3
				88793.05,	103218.00,	7130.88,	16.00	\ 	///	4
				103218.01,	123580.20,	9438.60,	17.92	\ 	///	5
				123580.21,	249243.48,	13087.44,	21.36	\ 	///	6
				249243.49,	392841.96,	39929.04,	23.52	\ 	///	7
				392841.97,	750000.00, 	73703.40,	30.00	\ 	///	8
				750000.01,	1000000.00,	180850.82,	32.00	\ 	///	9
				1000000.01,	3000000.00,	260850.81,	34.00	\ 	///	10
				3000000.01,	1E+14, 		940850.81,	35.00)		//	11

*				Inferior	Superior	Subsidio
matrix	SE	= (	0.00,		21227.52,	4884.24	\	///	1
				21227.53,	23744.40,	4881.96	\	///	2
				23744.41,	31840.56,	4318.08	\	///	3
				31840.57,	41674.08,	4123.20	\	///	4
				41674.09,	42454.44,	3723.48	\	///	5
				42454.45,	53353.80,	3581.28	\	///	6
				53353.81,	56606.16,	4250.76	\	///	7
				56606.17,	64025.04,	3898.44	\	///	8
				64025.05,	74696.04,	3535.56	\	///	9
				74696.05,	85366.80,	3042.48	\	///	10
				85366.81,	88587.96,	2611.32	\	///	11
				88587.97, 	1E+14,		0)			//	12

*				SS.MM.	Porcentaje
matrix	DED	= (	5, 	/// # de SS.MM.
				15)  // % ingreso gravable

*				Tasa ISR PM
matrix PM	= (	30, 	/// Tasa ISR PM
				20.10, 	/// Evasion PM
				96.07) 	 // Evasion PF
noisily run "`c(sysdir_personal)'/41ISR.do"


*********************/




*************
/** 4.2 IVA **
noisily di in g " Modulo: " in y "IVA_Mod"
* Matrix IVA *
matrix IVA = (	16	\ ///  1  Tasa general 
				1	\ ///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
				2	\ ///  3  Alquiler
				1	\ ///  4  Canasta basica
				1	\ ///  5  Educacion
				3	\ ///  6  Consumo fuera del hogar
				3	\ ///  7  Mascotas
				1	\ ///  8  Medicinas
				3	\ ///  9  Otros
				2	\ /// 10  Transporte local
				2 	\ /// 11  Transporte foraneo
				52.37 /// 12  Evasion e informalidad IVA
				)
IVA_Mod


*************/




********************
** 4.4 Resultados **
********************
* Modulos *
capture confirm scalar ISR_AS_Mod
if _rc == 0 {
	scalar ISR_AS = ISR_AS_Mod
	scalar ISR_PF = ISR_PF_Mod
	scalar ISR_PM = ISR_PM_Mod
}

capture confirm scalar IVA_Mod
if _rc == 0 {
	scalar IVA = IVA_Mod
}
noisily TasasEfectivas //														Cap. 4. Ingresos




************************/
**** Touchdown!!! :) ****
*************************
timer off 97
timer list 97
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t97)/r(nt97)',.1) in g " segs  " _dup(20) "."
