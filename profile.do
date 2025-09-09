*********************
***               ***
*** 1 Estilo CIEP ***
***               ***
*********************
set scheme ciepnew
graph set window fontface "Ubuntu Light"
set more off, permanently
set type double, permanently
set charset latin1, permanently



******************************
***                        ***
*** 2 PARÁMETROS GENERALES ***
***                        ***
******************************
cd `"`c(sysdir_site)'"'

** 2.1 Entidades Federativas **
global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"
global id = "`c(username)'"

** 2.2 Valor presente **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2026

** 2.3 Año paquete económico **
global paqueteEconomico "CGPE 2026"						// POLÍTICA FISCAL
scalar anioPE = 2026



********************
***              ***
*** 3 BIENVENIDA ***
***              ***
********************
noisily di in w _newline(50) "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""': Simulador Fiscal CIEP}}"'
noisily di in g " Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g " Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g " User: " _col(30) in y "$id"

noisily di _newline `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs]"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010) aniomax(2031)":PIBDeflactor} [, ANIOvp(int) ANIOMAX(int) NOGraphs]"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs]"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs]"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES]"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)]"'
noisily di `" {stata "AccesoBIE 734407 pibQ":AccesoBIE {it:clave} {it:nombre}}"' 



*********************************
***                           ***
*** 4 PARÁMETROS PARTICULARES ***
***                           ***
*********************************

** 2.1 Producto Interno Bruto (inputs opcionales)
global pib2025 = 1.0575							// CRECIMIENTO ANUAL PIB
global pib2026 = 2.262							// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.0898
global pib2028 = 2.0548
global pib2029 = 2.015
global pib2030 = 2.0137
global pib2031 = 2.0366

** 2.2 Deflactor (inputs opcionales)
global def2025 = 5.2							// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.8							// <-- AGREGAR O QUITAR AÑOS
global def2027 = 4.2
global def2028 = 4.0
global def2029 = 4.0
global def2030 = 4.0
global def2031 = 4.0

** 2.3 Inflación (inputs opcionales)
global inf2025 = 4.2							// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.54							// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0
