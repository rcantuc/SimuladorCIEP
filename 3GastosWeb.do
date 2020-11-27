****************
*** 3 GASTOS ***
****************
timer on 98
if "`1'" == "" {
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local anio = substr(`"`=trim("`fecha'")'"',1,4)
	local nographs "nographs"
}
else {
	local anio = `1'
	local nographs "$nographs"
}




**********************************/
** PAR{c A'}METROS DEL SIMULADOR **
***********************************
if "$id" == "PE2021" {

	* Educacion *
	scalar basica = 21333 // 						Educaci{c o'}n b{c a'}sica
	scalar medsup = 21056 //						Educaci{c o'}n media superior
	scalar superi = 38069 //						Educaci{c o'}n superior
	scalar posgra = 45789 //						Posgrado
	scalar eduadu = 19452 //						Educaci{c o'}n para adultos
	scalar otrose =  1475 //						Otros gastos educativos

	* Salud *
	scalar ssa    =   519 //						SSalud
	scalar prospe =  1081 //						IMSS-Prospera
	scalar segpop =  2406 //						Seguro Popular
	scalar imss   =  6385 //						IMSS (salud)
	scalar issste =  8590 //						ISSSTE (salud)
	scalar pemex  = 24179 //						Pemex (salud) + ISSFAM (salud)

	* Pensiones *
	scalar bienestar =   18063 //						Pensi{c o'}n Bienestar
	scalar penims    =  134649 //						Pensi{c o'}n IMSS
	scalar peniss    =  226463 //						Pensi{c o'}n ISSSTE
	scalar penotr    = 1402288 //						Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

	* Ingreso b{c a'}sico *
	scalar IngBas      = 0 //						Ingreso b{c a'}sico
	scalar ingbasico18 = 1 // 						1: Incluye menores de 18 anios, 0: no
	scalar ingbasico65 = 1 // 						1: Incluye mayores de 65 anios, 0: no

	* Otros gastos *
	scalar servpers = 3383 //						Servicios personales
	scalar matesumi = 1694 //						Materiales y suministros
	scalar gastgene = 1791 //						Gastos generales
	scalar substran = 1897 //						Subsidios y transferencias
	scalar bienmueb =  301 //						Bienes muebles e inmuebles
	scalar obrapubl = 3341 //						Obras p{c u'}blicas
	scalar invefina =  784 //						Inversi{c o'}n financiera
	scalar partapor = 8988 //						Participaciones y aportaciones
	scalar costodeu = 5862 //						Costo de la deuda
}
if "`2'" == "fast" {
	exit
}




**********************/
** Gastos per capita **
***********************
noisily GastoPC, anio(`anio') output `nographs'




************************/
**** Touchdown!!! :) ****
*************************
timer off 98
timer list 98
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t98)/r(nt98)',.1) in g " segs  " _dup(20) "."
