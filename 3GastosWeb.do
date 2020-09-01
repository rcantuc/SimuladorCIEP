****************
*** 3 GASTOS ***
****************
timer on 98
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY




***********************************
** PAR{c A'}METROS DEL SIMULADOR **
**    Paquete Economico 2021     **

global id = "$id"

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*adopath ++ PERSONAL
*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

* Educacion *
scalar basica = 21541 //														Educaci{c o'}n b{c a'}sica
scalar medsup = 21640 //														Educaci{c o'}n media superior
scalar superi = 39613 //														Educaci{c o'}n superior
scalar posgra = 46602 //														Posgrado
scalar eduadu = 22178 // 														Educaci{c o'}n para adultos
scalar otrose =   867 //														Otros gastos educativos

* Salud *
scalar ssa    =   414 //														SSalud
scalar segpop =  3221 //														Seguro Popular
scalar imss   =  7018 //														IMSS (salud)
scalar issste =  9265 //														ISSSTE (salud)
scalar prospe = 30538 //														IMSS-Prospera
scalar pemex  = 22407 //														Pemex (salud) + ISSFAM (salud)

* Pensiones *
scalar bienestar =   17747 //													Pensi{c o'}n Bienestar
scalar penims    =  121321 //													Pensi{c o'}n IMSS
scalar peniss    =  217814 //													Pensi{c o'}n ISSSTE
scalar penotr    = 1377018 //													Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

* Ingreso b{c a'}sico *
scalar IngBas      = 0 //														Ingreso b{c a'}sico
scalar ingbasico18 = 1 // 														1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 = 1 // 														1: Incluye mayores de 65 anios, 0: no

* Otros gastos *
scalar servpers = 3486 //														Servicios personales
scalar matesumi = 2150 //														Materiales y suministros
scalar gastgene = 1828 //														Gastos generales
scalar substran = 2007 //														Subsidios y transferencias
scalar bienmueb =  262 // 														Bienes muebles e inmuebles
scalar obrapubl = 2870 //														Obras p{c u'}blicas
scalar invefina =  823 // 														Inversi{c o'}n financiera
scalar partapor = 9521 // 														Participaciones y aportaciones
scalar costodeu = 5982 //														Costo de la deuda


***********************************/




********************
** 4.4 Resultados **
********************
noisily GastoPC




************************/
**** Touchdown!!! :) ****
*************************
timer off 98
timer list 98
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t98)/r(nt98)',.1) in g " segs  " _dup(20) "."
