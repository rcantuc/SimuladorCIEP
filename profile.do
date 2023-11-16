***********************
***                 ***
***   ver: SIM.md   ***
***                 ***
***********************
***                 ***
***    1. SET UP    ***
***		            ***
***********************
clear all
macro drop _all
capture log close _all
timer on 1


** Estilo CIEP **
set scheme ciep
graph set window fontface "Ubuntu"
set more off, permanently
set type double, permanently
set charset latin1, permanently


** Ruta PERSONAL **
sysdir set PERSONAL `"`c(sysdir_site)'"'
adopath ++PERSONAL
cd `"`c(sysdir_personal)'"'





********************
***              ***
*** 2 PARÁMETROS ***
***		         ***
********************
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)


** Política Fiscal **
global paqueteEconomico "CGPE 2024"
scalar anioPE = 2024
scalar aniovp = 2024
run "`c(sysdir_personal)'/parametros.do"


** Incidencia ENIGH **
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


** Entidades Federativas **
global entidadesL `""Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"





********************
***              ***
*** 3 BIENVENIDA ***
***		         ***
********************
noisily di _newline(50) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"

noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""': Simulador Fiscal CIEP v6}}"'
noisily di in g " Paquete Económico:  " _col(30) in y "`=anioPE'" ///
	_newline in g " Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g " Año de ENIGH:  " _col(30) in y "`=anioenigh'" ///
	_newline in g " User: " _col(30) in y "$id" ///
	_newline(2) " CLICK para ejecutar los comandos o usar la siguiente sintaxis: "

noisily di _newline `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre con espacios y acentos}"] [, ANIO(int) ANIOFINal(int) NOGraphs UPDATE]"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs UPDATE]"'
noisily di `" {stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs UPDATE]"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs UPDATE]"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) UPDATE BASE]"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs UPDATE]"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES UPDATE]"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)]"'
