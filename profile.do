***********************
***                 ***
***    1. SET UP    ***
***		            ***
***********************
clear all
macro drop _all
capture log close _all

*********************
** 1.1 Estilo CIEP **
set scheme ciep
graph set window fontface "Ubuntu Light"
set more off, permanently
set type double, permanently
set charset latin1, permanently

***********************
** 1.2 Ruta PERSONAL **
cd `"`c(sysdir_site)'"'
sysdir set PERSONAL `"`c(sysdir_site)'"'
adopath ++PERSONAL



********************
***              ***
*** 2 PARÁMETROS ***
***		         ***
********************

** 2.1 Entidades Federativas **
global entidadesL `""Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"

** 2.2 Anio valor presente **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2024

** 2.3 Política Fiscal **
global paqueteEconomico "Pre CGPE 2025"
scalar anioPE = 2024

** 2.4 Economía: Crecimiento anual del Producto Interno Bruto **
global pib2024 = 3.051
global pib2025 = 2.5007
global pib2026 = 2.4779
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5002

** 2.5 Economía: Crecimiento anual del índice de precios implícitos **
global def2024 = 5.0
global def2025 = 3.9
global def2026 = 3.5
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5

** 2.6 Economía: Crecimiento anual del índice nacional de precios al consumidor **
global inf2024 = 3.8
global inf2025 = 3.3
global inf2026 = 3.0
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0

** 2.7 Incidencia ENIGH **
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



********************
***              ***
*** 3 BIENVENIDA ***
***		         ***
********************
noisily di _newline(50) in w "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_personal)'/simulador.stpr""': Simulador Fiscal CIEP}}"'
noisily di in g " Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g " Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g " Año de ENIGH:  " _col(30) in y "`=anioenigh'" ///
	_newline in g " User: " _col(30) in y "$id" ///
	_newline(2) " CLICK para ejecutar los comandos o usar la siguiente sintaxis: "

noisily di _newline `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs]"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs]"'
noisily di `" {stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs]"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs]"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs]"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES]"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)]"'
