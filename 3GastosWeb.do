****************
*** 3 GASTOS ***
****************
timer on 98
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY

*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
*global id = "Ricardo"




***********************************
** PAR{c A'}METROS DEL SIMULADOR ** 

* Educacion *
scalar basica = 21340 // 1.939 //												Educaci{c o'}n b{c a'}sica
scalar medsup = 21640 // 0.446 //												Educaci{c o'}n media superior
scalar superi = 39613 // 0.526 //												Educaci{c o'}n superior
scalar posgra = 46602 // 0.031 //												Posgrado

* Salud *
scalar ssa    =   414 // 0.202 //												SSalud
scalar segpop =  3221 // 0.687 //												Seguro Popular
scalar imss   =  7018 // 1.247 //												IMSS (salud)
scalar issste =  9265 // 0.247 //												ISSSTE (salud)
scalar prospe = 30538 // 0.051 //												IMSS-Prospera
scalar pemex  = 22407 // 0.085 //												Pemex (salud) + ISSFAM (salud)

* Pensiones *
scalar bienestar =   17747 // 0.560 //											Pensi{c o'}n Bienestar
scalar penims    =  121321 // 1.908 //											Pensi{c o'}n IMSS
scalar peniss    =  217814 // 0.959 //											Pensi{c o'}n ISSSTE
scalar penotr    = 1377018 // 0.901 //											Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

* Ingreso b{c a'}sico *
scalar IngBas      = 0 //														Ingreso b{c a'}sico
scalar ingbasico18 = 1 // 1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 = 1 // 1: Incluye mayores de 65 anios, 0: no

* Otros gastos *
scalar servpers = 3486 // 1.704 //												Servicios personales
scalar matesumi = 2150 // 1.051 //												Materiales y suministros
scalar gastgene = 1828 // 0.894 //												Gastos generales
scalar substran = 2007 // 0.981 //												Subsidios y transferencias
scalar bienmueb =  262 // 0.128 // 												Bienes muebles e inmuebles
scalar obrapubl = 2870 // 1.403 //												Obras p{c u'}blicas
scalar invefina =  823 // 0.402 // 												Inversi{c o'}n financiera
scalar partapor = 9521 // 4.654 // 												Participaciones y aportaciones
scalar costodeu = 5982 // 2.924 //												Costo de la deuda

***********************************/


noisily GastoPC //																Cap. 5


** 3.1 Educacion **
noisily run 31Educacion.do

** 3.2 Salud **
noisily run 32Salud.do

** 3.3 Pensiones **
noisily run 33Pensiones.do

** 3.4 Ingreso b{c a'}sico **
noisily run 34IngBasico.do

** 3.5 Otros gastos **
noisily run 35OtrosGas.do



************************/
**** Touchdown!!! :) ****
*************************
timer off 98
timer list 98
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t98)/r(nt98)',.1) in g " segs  " _dup(20) "."
