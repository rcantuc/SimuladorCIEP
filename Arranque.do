timer on 1





***************************************
***    2. USERS AND SUPERUSER(S)    ***
***************************************
global id = "`c(username)'"                                                     // ID DEL USUARIO
if ("`c(username)'" == "ricardo" | "`c(username)'" == "ciepmx") & "`c(console)'" == "" {
	global id = ""
}




*****************************************
***    3. OTROS PAISES (SI APLICA)    ***
*****************************************
*global pais "Ecuador"
*global pais "El Salvador"

if "$pais" == "" {
	local pais = "M{c e'}xico"
}
else {
	local pais = "$pais"
}




********************************************************************
***    4. DIRECTORIOS DE LAS BASES A GENERAR POR EL SIMULADOR    ***
********************************************************************
capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$pais/"'
capture mkdir `"`c(sysdir_personal)'/users/$pais/$id/"'




*************************************
***    5. PARAMETROS A SIMULAR    ***
*************************************
run "`c(sysdir_personal)'/PARAM${pais}.do"




************************************
***    6. TEXTO DE BIENVENIDA    ***
************************************
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in w " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`=aniovp'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g "  PA{c I'}S: " in y "`pais'" ///
	_newline in g _dup(23) "*"

