** USER(S) **
global id = "`c(username)'"							// ID DEL USUARIO


** SUPERUSER(S) **
if "`c(username)'" == "ricardo" | "`c(username)'" == "ciepmx" {
	global id = ""
}


** DIRECTORIOS DE LAS BASES A GENERAR POR EL SIMULADOR **
capture mkdir `"`c(sysdir_personal)'/SIM/"'
capture mkdir `"`c(sysdir_personal)'/users/"'
capture mkdir `"`c(sysdir_personal)'/users/$id/"'
capture mkdir `"`c(sysdir_personal)'/users/$pais/"'


** OUTPUT SIMULADOR **
if "$output" == "output" {
	quietly log using "`c(sysdir_personal)'/users/$pais/$id/output.txt", replace text name(output)
	quietly log off output
}


** TEXTO DE BIENVENIDA **
timer on 1                                                                      // TIEMPO: CONTADOR 1
noisily di _newline(10) in g _dup(23) "*" ///
	_newline in w " Simulador Fiscal CIEP" ///
	_newline in g _dup(23) "*" ///
	_newline in g "  A{c N~}O:  " in y "`1'" ///
	_newline in g "  USER: " in y "$id" ///
	_newline in g _dup(23) "*"
