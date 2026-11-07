*! version 1.0.0  CIEP 07nov2026 (sesion 8.16a) — tabla vertical de anclas al SCN/BIE/LIF, comun a Households, NTA, Expenditure, TasasEfectivas y SCN
*
* Sustituye las impresiones horizontales «Anclas S.14 (CSI_115 2024): D.1 10052961730000 B.3n ...» que nadie podia
* auditar: una fila por ancla, con el nombre de la cuenta tal como lo escribe INEGI (catalogo 05_scripts/scn-cuentas.csv,
* separador «;»), el codigo SCN 2008 (o la clave BIE / divSIM de la LIF), el sector, la fuente (cuadro · fila, serie o LIF),
* el valor con separador de miles (%21.0fc), la variable del motor que ancla y el sello con su razon. Con `motor` imprime
* debajo la misma tabla con Σ motor antes del ancla, el factor y la cobertura ENIGH (la Tabla 1 de CUAD-0 viva en el log).
* Solo escribe en el log: no define escalares ni toca los datos en memoria (gate-numeros no se entera).
*
* Sintaxis (tres subcomandos; las filas se acumulan en Mata hasta `print`):
*   _tabla_anclas clear
*   _tabla_anclas add, codigo(str) valor(exp) [sector(str) fuente(str) variable(str) motor(exp) factor(exp) cobertura(exp) nota(str)]
*   _tabla_anclas print, titulo(str) [sello(str) razon(str) motor unidad(str)]
*     - valor/motor/factor/cobertura son expresiones numericas de Stata (locales, escalares, elementos de matriz);
*       si factor se omite y hay motor, se calcula valor/motor; cobertura va en % (0-100).
*     - motor: imprime ademas la tabla «Σ motor antes del ancla, factor y cobertura ENIGH».
*     - Si el catalogo no esta (p. ej. instalacion via net install, sin 05_scripts/), la columna «Cuenta» queda vacia y se avisa.
* Invocar con `noisily` desde un do-file corrido con quietly (un noisily DENTRO del programa no vence al quietly del run).

program define _tabla_anclas
	version 17.0
	gettoken sub 0 : 0, parse(" ,")
	local sub = lower(trim("`sub'"))
	if "`sub'" == "clear" {
		mata: _ta_clear()
		exit
	}
	if "`sub'" == "add" {
		syntax , CODigo(string) VALor(string) [SECtor(string) FUente(string) VARiable(string) MOTor(string) FACtor(string) COBertura(string) NOTa(string)]
		local v = `valor'
		local m = .
		local f = .
		local c = .
		if `"`motor'"' != "" local m = `motor'
		if `"`factor'"' != "" local f = `factor'
		else if `m' < . & `m' != 0 local f = `v'/`m'
		if `"`cobertura'"' != "" local c = `cobertura'
		mata: _ta_add(`"`codigo'"', `"`sector'"', `"`fuente'"', `"`variable'"', `"`nota'"', `v', `m', `f', `c')
		exit
	}
	if "`sub'" == "print" {
		syntax , TITulo(string) [SELlo(string) RAZon(string) MOTOR UNIdad(string)]
		if `"`unidad'"' == "" local unidad "MXN"
		local csv "${SIMROOT}/05_scripts/scn-cuentas.csv"
		capture confirm file "`csv'"
		if _rc != 0 {
			capture findfile scn-cuentas.csv
			if _rc == 0 local csv "`r(fn)'"
			else local csv ""
		}
		mata: _ta_print(`"`titulo'"', `"`sello'"', `"`razon'"', ("`motor'" != ""), `"`csv'"', `"`unidad'"')
		exit
	}
	di as err "_tabla_anclas: subcomando `sub' no reconocido (clear | add | print)"
	exit 198
end


mata:
mata set matastrict on

void _ta_clear()
{
	external string matrix _TA_S
	external real matrix _TA_V
	_TA_S = J(0, 5, "")
	_TA_V = J(0, 4, .)
}

void _ta_add(string scalar cod, string scalar sec, string scalar fue, string scalar var, string scalar nota,
             real scalar v, real scalar m, real scalar f, real scalar c)
{
	external string matrix _TA_S
	external real matrix _TA_V
	if (cols(_TA_S) != 5 | cols(_TA_V) != 4) _ta_clear()
	_TA_S = _TA_S \ (cod, sec, fue, var, nota)
	_TA_V = _TA_V \ (v, m, f, c)
}

// Catalogo 05_scripts/scn-cuentas.csv: codigo;nombre_inegi;nombre_sna2008;sectores;fuente;nota (lineas que empiezan por # son comentarios)
transmorphic _ta_catalogo(string scalar csv)
{
	transmorphic A
	string colvector L
	string scalar line, cod, nombre
	real scalar i, p1, p2
	A = asarray_create()
	if (csv == "") return(A)
	L = cat(csv)
	for (i = 1; i <= rows(L); i++) {
		line = L[i]
		if (strlen(line) == 0 | substr(line, 1, 1) == "#" | substr(line, 1, 6) == "codigo") continue
		p1 = strpos(line, ";")
		if (p1 == 0) continue
		cod = substr(line, 1, p1 - 1)
		p2 = strpos(substr(line, p1 + 1, .), ";")
		nombre = (p2 == 0 ? substr(line, p1 + 1, .) : substr(line, p1 + 1, p2 - 1))
		asarray(A, cod, nombre)
	}
	return(A)
}

// Recorta a w caracteres (con «…») y rellena a la derecha por CARACTERES: printf("%-ws") rellena por bytes y desalinea los acentos
string scalar _ta_fit(string scalar s, real scalar w)
{
	string scalar r
	r = (udstrlen(s) <= w ? s : udsubstr(s, 1, w - 1) + "…")
	return(r + (w - udstrlen(r)) * " ")
}

string scalar _ta_num(real scalar x, string scalar fmt, real scalar w)
{
	if (x >= .) return(sprintf("%" + strofreal(w) + "s", "—"))
	return(sprintf("%" + strofreal(w) + "s", strtrim(strofreal(x, fmt))))
}

void _ta_print(string scalar titulo, string scalar sello, string scalar razon, real scalar motor, string scalar csv, string scalar unidad)
{
	external string matrix _TA_S
	external real matrix _TA_V
	transmorphic A
	string scalar rule, cab, nombre, cuenta
	real scalar i, n, w
	if (cols(_TA_S) != 5) _ta_clear()
	n = rows(_TA_S)
	A = _ta_catalogo(csv)
	w = 150
	rule = w * "─"
	cab = titulo
	if (razon != "" | sello != "") {
		cab = cab + " (" + (razon != "" ? razon : "") + (razon != "" & sello != "" ? ", " : "") + (sello != "" ? "sello " + sello : "") + ")"
	}
	printf("{txt}%s\n", rule)
	printf("{txt} {bf:%s}\n", cab)
	printf("{txt}%s\n", rule)
	printf("{txt} %s %s %s %s %21s   %s\n", _ta_fit("Código", 9), _ta_fit("Cuenta (SCN 2008 / INEGI)", 44), _ta_fit("Sector", 9), _ta_fit("Fuente (cuadro·fila)", 29), unidad, "Variable del motor")
	for (i = 1; i <= n; i++) {
		nombre = asarray_contains(A, _TA_S[i, 1]) ? asarray(A, _TA_S[i, 1]) : ""
		cuenta = _ta_fit(nombre, 44)
		printf("{txt} %s %s %s %s {res}%21s{txt}   %s\n", _ta_fit(_TA_S[i, 1], 9), cuenta, _ta_fit(_TA_S[i, 2], 9), _ta_fit(_TA_S[i, 3], 29), _ta_num(_TA_V[i, 1], "%21.0fc", 21), _TA_S[i, 4])
	}
	printf("{txt}%s\n", rule)
	if (csv == "") printf("{txt} (catálogo 05_scripts/scn-cuentas.csv no encontrado: la columna «Cuenta» va vacía)\n")
	if (motor) {
		printf("{txt} {bf:Σ motor antes del ancla, factor y cobertura ENIGH} (factor = ancla / Σ motor; cobertura = Σ ENIGH cruda / ancla, %%)\n")
		printf("{txt}%s\n", rule)
		printf("{txt} %s %s %21s %21s %10s %10s   %s\n", _ta_fit("Código", 9), _ta_fit("Variable del motor", 28), "Σ motor (" + unidad + ")", "Ancla (" + unidad + ")", "Factor", "Cobert.%", "Nota")
		for (i = 1; i <= n; i++) {
			printf("{txt} %s %s {res}%21s %21s %10s %10s{txt}   %s\n", _ta_fit(_TA_S[i, 1], 9), _ta_fit(_TA_S[i, 4], 28), _ta_num(_TA_V[i, 2], "%21.0fc", 21), _ta_num(_TA_V[i, 1], "%21.0fc", 21), _ta_num(_TA_V[i, 3], "%10.4f", 10), _ta_num(_TA_V[i, 4], "%9.2f", 10), _TA_S[i, 5])
		}
		printf("{txt}%s\n", rule)
	}
	else {
		for (i = 1; i <= n; i++) {
			if (_TA_S[i, 5] != "") printf("{txt}   %s: %s\n", _TA_S[i, 1], _TA_S[i, 5])
		}
	}
}
end
