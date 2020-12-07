********************
*** 9 FISCAL GAP ***
********************
timer on 95
if "`1'" == "" {
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local anio = substr(`"`=trim("`fecha'")'"',1,4)
	local nographs "nographs"
}
else {
	local anio = `1'
	local nographs "$nographs"
}





***********************************
** PAR{c A'}METROS DEL SIMULADOR **




***************/
*** 1 SANKEY ***
****************
if "$pais" == "" {
	run "`c(sysdir_personal)'/3GastosWeb.do" `anio' fast
	run "`c(sysdir_personal)'/4IngresosWeb.do" `anio' fast

	foreach k in sexo decil /*escol grupo_edad*/ {
		noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `anio'
	}
}





*******************/
*** 2 FISCAL GAP ***
********************
noisily FiscalGap, anio(`anio') `nographs' end(2050) output //boot(250) //update





************************/
**** Touchdown!!! :) ****
*************************
timer off 95
timer list 95
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t95)/r(nt95)',.1) in g " segs  " _dup(20) "."
