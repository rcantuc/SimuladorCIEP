** SUPERUSER(S) **
if ("`c(username)'" == "ricardo" | "`c(username)'" == "ciepmx") & "`c(console)'" == "" {
	global id = ""
}


** DIRECTORIOS DE LAS BASES A GENERAR POR EL SIMULADOR **
capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'
capture mkdir `"`c(sysdir_personal)'/users/$pais/"'


** PAIS **
if "$pais" == "" {
	local pais = "M{c e'}xico"
}
else {
	local pais = "$pais"
}

** TEXTO DE BIENVENIDA **
timer on 1                                                                      // TIEMPO: CONTADOR 1
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in w " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`1'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g "  PA{c I'}S: " in y "`pais'" ///
	_newline in g _dup(23) "*"
