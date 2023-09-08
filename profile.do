**************
*** 1 CIEP ***
**************
clear all
macro drop _all
capture log close _all
set more off, permanently
set type double, permanently
set charset latin1, permanently
set scheme ciep
graph set window fontface "Ubuntu"
sysdir set PERSONAL "`c(sysdir_site)'"



********************
*** 2 Bienvenida ***
********************
timer on 1
noisily di _newline(25) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"



********************
*** 3 Parametros ***
********************
run "`c(sysdir_personal)'/parametros.do"

local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2024

global paqueteEconomico "CGPE 2024"
scalar anioPE = 2023
if anioPE >= 2022 {
	scalar anioenigh = 2022
}
if anioPE >= 2020 & anioPE < 2022 {
	scalar anioenigh = 2020
}
if anioPE >= 2018 & anioPE < 2020 {
	scalar anioenigh = 2018
}
if anioPE >= 2016 & anioPE < 2018 {
	scalar anioenigh = 2016
}

global entidadesL `""Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"



*******************/
*** 4 Bienvenida ***
********************
noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""':Simulador Fiscal CIEP v6 ($paqueteEconomico)}}"' ///
	_newline(2) "CLICK para ejecutar los comandos o usar la siguiente sintaxis: " ///
	_newline(2) "{bf:Comando} {it:argumentos} [, OPCIONES]"
noisily di _newline `"{stata "Poblacion":Poblacion} [if entidad == "{it:Nombre con espacios y acentos}"] [, ANIOhoy(int) ANIOFINal(int) NOGraphs UPDATE]"'
noisily di `"{stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs UPDATE]"'
noisily di `"{stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs UPDATE]"'
noisily di `"{stata "SCN":SCN} [, ANIO(int) NOGraphs UPDATE]"'
noisily di `"{stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `"{stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `"{stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs UPDATE]"' 
noisily di `"{stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES UPDATE]"' 
noisily di `"{stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `"{stata "GastoPC":GastoPC} [, ANIO(int)]"'
