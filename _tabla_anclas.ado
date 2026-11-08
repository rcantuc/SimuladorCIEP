*! version 2.0.0  CIEP 08nov2026 (sesion 8.16b) — cuadro de anclas al estandar de la firma CUAD-1-2 §D, comun a Households, NTA, Expenditure, TasasEfectivas y SCN
*
* Estandar §D (firma CUAD-1-2, 2026-11-07): rotulo = nombre de la cuenta tal como lo escribe INEGI, sin parentesis; codigo y sector en
* columnas propias; todo comentario o parametro va a una nota al pie («^n» en la fila, «Nota n:» debajo del cuadro); columnas de ancho
* fijo alineadas por CARACTERES (no por bytes: los acentos no desalinean); separador de miles en todo valor; los gates debajo del cuadro,
* una linea cada uno, alineados. Solo escribe en el log: no define escalares ni toca los datos en memoria (gate-numeros no se entera).
* El nombre INEGI sale del catalogo 05_scripts/scn-cuentas.csv (separador «;»); `rotulo()` lo sustituye cuando la fila no es una
* cuenta del catalogo (p. ej. «YL + YA de las personas»).
*
* Sintaxis (las filas y los gates se acumulan en Mata hasta `print`):
*   _tabla_anclas clear
*   _tabla_anclas add, codigo(str) valor(exp) [sector(str) fuente(str) variable(str) motor(exp) factor(exp) cobertura(exp) gini(exp)
*                      rotulo(str) nota(str) sep]
*     - valor/motor/factor/cobertura/gini son expresiones numericas de Stata (locales, escalares, elementos de matriz); si factor se
*       omite y hay motor, se calcula valor/motor; cobertura va en % (0-100). `sep` dibuja una regla antes de la fila (subtotales).
*   _tabla_anclas gate, texto(str) a(exp) b(exp) [tol(real 1e-9)]
*     - gate relativo: reldif(a, b) <= tol -> OK, si no ROJO. Se imprimen debajo de las notas, alineados.
*   _tabla_anclas print, titulo(str) [sello(str) razon(str) motor unidad(str) pib(exp) nota(str)]
*     - motor: columnas «Σ motor», «Factor» (y «Cobert. %» si alguna fila la trae); pib(exp): columnas «% PIB» del valor y del motor.
*     - nota(): nota al pie del cuadro (ademas de la del sello, que es la Nota 1 si hay sello o razon).
*     - Deja en los globals TA_GATES_OK (1/0) y TA_N_ROJO el resultado de los gates impresos (sin gates: 1 y 0).
*     - Si el catalogo no esta (p. ej. instalacion via net install, sin 05_scripts/), la columna «Cuenta» repite el codigo y se avisa.
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
		syntax , CODigo(string) VALor(string asis) [SECtor(string) FUente(string) VARiable(string) MOTor(string asis) FACtor(string asis) COBertura(string asis) GINi(string asis) ROTulo(string) NOTa(string) SEP]
		local v = `valor'
		local m = .
		local f = .
		local c = .
		local g = .
		if `"`motor'"' != "" local m = `motor'
		if `"`factor'"' != "" local f = `factor'
		else if `m' < . & `m' != 0 local f = `v'/`m'
		if `"`cobertura'"' != "" local c = `cobertura'
		if `"`gini'"' != "" local g = `gini'
		mata: _ta_add(`"`codigo'"', `"`sector'"', `"`fuente'"', `"`variable'"', `"`nota'"', `"`rotulo'"', ("`sep'" != ""), `v', `m', `f', `c', `g')
		exit
	}
	if "`sub'" == "gate" {
		syntax , TEXto(string) A(string asis) B(string asis) [TOL(real 1e-9)]
		local av = `a'
		local bv = `b'
		mata: _ta_gate(`"`texto'"', `av', `bv', `tol')
		exit
	}
	if "`sub'" == "print" {
		syntax , TITulo(string) [SELlo(string) RAZon(string) MOTOR UNIdad(string) PIB(string asis) NOTa(string)]
		if `"`unidad'"' == "" local unidad "MXN"
		local pibv = .
		if `"`pib'"' != "" local pibv = `pib'
		local csv "${SIMROOT}/05_scripts/scn-cuentas.csv"
		capture confirm file "`csv'"
		if _rc != 0 {
			capture findfile scn-cuentas.csv
			if _rc == 0 local csv "`r(fn)'"
			else local csv ""
		}
		mata: _ta_print(`"`titulo'"', `"`sello'"', `"`razon'"', ("`motor'" != ""), `"`csv'"', `"`unidad'"', `pibv', `"`nota'"')
		exit
	}
	di as err "_tabla_anclas: subcomando `sub' no reconocido (clear | add | gate | print)"
	exit 198
end


mata:
mata set matastrict on

void _ta_clear()
{
	external string matrix _TA_S
	external real matrix _TA_V
	external string colvector _TA_G
	external real matrix _TA_GV
	_TA_S = J(0, 7, "")
	_TA_V = J(0, 5, .)
	_TA_G = J(0, 1, "")
	_TA_GV = J(0, 3, .)
}

void _ta_add(string scalar cod, string scalar sec, string scalar fue, string scalar var, string scalar nota, string scalar rot, real scalar sep,
             real scalar v, real scalar m, real scalar f, real scalar c, real scalar g)
{
	external string matrix _TA_S
	external real matrix _TA_V
	if (cols(_TA_S) != 7 | cols(_TA_V) != 5) _ta_clear()
	_TA_S = _TA_S \ (cod, sec, fue, var, nota, rot, (sep ? "1" : ""))
	_TA_V = _TA_V \ (v, m, f, c, g)
}

void _ta_gate(string scalar texto, real scalar a, real scalar b, real scalar tol)
{
	external string colvector _TA_G
	external real matrix _TA_GV
	external string matrix _TA_S
	if (cols(_TA_S) != 7) _ta_clear()
	_TA_G = _TA_G \ texto
	_TA_GV = _TA_GV \ (a, b, tol)
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

// Rellena a la derecha por CARACTERES (printf("%-ws") rellena por bytes y desalinea los acentos); recorta con «…»
string scalar _ta_fit(string scalar s, real scalar w)
{
	string scalar r
	r = (udstrlen(s) <= w ? s : udsubstr(s, 1, w - 1) + "…")
	return(r + (w - udstrlen(r)) * " ")
}

// Rellena a la izquierda por caracteres (numeros y «—»)
string scalar _ta_rfit(string scalar s, real scalar w)
{
	if (udstrlen(s) >= w) return(s)
	return((w - udstrlen(s)) * " " + s)
}

string scalar _ta_num(real scalar x, string scalar fmt, real scalar w)
{
	if (x >= .) return(_ta_rfit("—", w))
	return(_ta_rfit(strtrim(strofreal(x, fmt)), w))
}

// Sin parentesis en el rotulo (estandar §D): lo que iba entre parentesis se devuelve aparte para la nota
string scalar _ta_sinparen(string scalar s)
{
	string scalar r
	r = ustrregexra(s, "\s*\([^)]*\)", "")
	return(strtrim(ustrregexra(r, "\s+", " ")))
}

void _ta_print(string scalar titulo, string scalar sello, string scalar razon, real scalar motor, string scalar csv, string scalar unidad,
               real scalar pib, string scalar notacuadro)
{
	external string matrix _TA_S
	external real matrix _TA_V
	external string colvector _TA_G
	external real matrix _TA_GV
	transmorphic A
	string scalar rule, cab, nombre, cuenta, mk, linea, res
	string colvector notas
	real scalar i, n, w, ncob, nn, wcta, ng, rojo, d, ok
	if (cols(_TA_S) != 7) _ta_clear()
	n = rows(_TA_S)
	A = _ta_catalogo(csv)
	ncob = (motor ? sum(_TA_V[., 4] :< .) : 0)
	// anchos
	wcta = 38
	w = 1 + 9 + 1 + 9 + 1 + wcta + 1 + 20 + 1 + 21 + (motor ? 1 + 21 + 1 + 8 : 0) + (ncob ? 1 + 8 : 0) + (pib < . ? 1 + 8 + (motor ? 1 + 8 : 0) : 0) + (sum(_TA_V[., 5] :< .) ? 1 + 6 : 0) + 3 + 18
	rule = w * "─"
	// notas al pie: la 1 es el sello/razon, luego la del cuadro, luego una por fila con nota
	notas = J(0, 1, "")
	cab = titulo
	if (sello != "" | razon != "") {
		notas = notas \ ("Sello " + (sello != "" ? sello : "no declarado") + (razon != "" ? ": " + razon : ""))
		cab = cab + "^" + strofreal(rows(notas))
	}
	if (notacuadro != "") {
		notas = notas \ notacuadro
		cab = cab + "^" + strofreal(rows(notas))
	}
	printf("{txt}%s\n", rule)
	printf("{txt} {bf:%s}\n", cab)
	printf("{txt}%s\n", rule)
	linea = " " + _ta_fit("Código", 9) + " " + _ta_fit("Sector", 9) + " " + _ta_fit("Cuenta", wcta) + " " + _ta_fit("Fuente", 20) + " " + _ta_rfit(unidad, 21)
	if (motor) linea = linea + " " + _ta_rfit("Σ motor " + unidad, 21) + " " + _ta_rfit("Factor", 8)
	if (ncob) linea = linea + " " + _ta_rfit("Cobert.%", 8)
	if (pib < .) {
		linea = linea + " " + _ta_rfit("% PIB", 8)
		if (motor) linea = linea + " " + _ta_rfit("Motor %", 8)
	}
	if (sum(_TA_V[., 5] :< .)) linea = linea + " " + _ta_rfit("Gini", 6)
	linea = linea + "   " + "Variable del motor"
	printf("{txt}%s\n", linea)
	for (i = 1; i <= n; i++) {
		if (_TA_S[i, 7] == "1") printf("{txt}%s\n", rule)
		if (_TA_S[i, 6] != "") nombre = _TA_S[i, 6]
		else nombre = (asarray_contains(A, _TA_S[i, 1]) ? asarray(A, _TA_S[i, 1]) : _TA_S[i, 1])
		nombre = _ta_sinparen(nombre)
		mk = ""
		if (_TA_S[i, 5] != "") {
			notas = notas \ _TA_S[i, 5]
			mk = "^" + strofreal(rows(notas))
		}
		// el marcador va pegado al texto (recortado si hace falta) y el conjunto se rellena al ancho de la columna
		cuenta = (udstrlen(nombre) + udstrlen(mk) <= wcta ? nombre : udsubstr(nombre, 1, wcta - udstrlen(mk) - 1) + "…") + mk
		cuenta = _ta_fit(cuenta, wcta)
		linea = " " + _ta_fit(_TA_S[i, 1], 9) + " " + _ta_fit(_TA_S[i, 2], 9) + " " + cuenta + " " + _ta_fit(_TA_S[i, 3], 20) + " {res}" + _ta_num(_TA_V[i, 1], "%21.0fc", 21)
		if (motor) linea = linea + " " + _ta_num(_TA_V[i, 2], "%21.0fc", 21) + " " + _ta_num(_TA_V[i, 3], "%8.4f", 8)
		if (ncob) linea = linea + " " + _ta_num(_TA_V[i, 4], "%8.2f", 8)
		if (pib < .) {
			linea = linea + " " + _ta_num(_TA_V[i, 1] / pib * 100, "%8.3f", 8)
			if (motor) linea = linea + " " + _ta_num((_TA_V[i, 2] < . ? _TA_V[i, 2] / pib * 100 : .), "%8.3f", 8)
		}
		if (sum(_TA_V[., 5] :< .)) linea = linea + " " + _ta_num(_TA_V[i, 5], "%6.3f", 6)
		linea = linea + "{txt}   " + _TA_S[i, 4]
		printf("%s\n", linea)
	}
	printf("{txt}%s\n", rule)
	if (csv == "") printf("{txt} (catálogo 05_scripts/scn-cuentas.csv no encontrado: la columna «Cuenta» repite el código)\n")
	for (i = 1; i <= rows(notas); i++) printf("{txt} Nota %s: %s\n", strofreal(i), notas[i])
	// gates: una linea cada uno, alineados
	ng = rows(_TA_G)
	rojo = 0
	for (i = 1; i <= ng; i++) {
		d = (_TA_GV[i, 1] == _TA_GV[i, 2] ? 0 : reldif(_TA_GV[i, 1], _TA_GV[i, 2]))
		ok = (d <= _TA_GV[i, 3])
		if (!ok) rojo++
		res = (ok ? "OK" : "ROJO")
		printf("{txt} GATE %s %s {res}%s{txt} vs {res}%s{txt}  reldif %s  %s\n", _ta_rfit(strtrim(strofreal(_TA_GV[i, 3], "%9.0e")), 6), _ta_fit(_TA_G[i], 62),
			_ta_num(_TA_GV[i, 1], "%21.0fc", 21), _ta_num(_TA_GV[i, 2], "%21.0fc", 21), _ta_rfit(strtrim(strofreal(d, "%9.2e")), 9),
			(ok ? "{res}OK{txt}" : "{err}ROJO{txt}"))
	}
	if (ng) printf("{txt}%s\n", rule)
	st_global("TA_GATES_OK", (rojo ? "0" : "1"))
	st_global("TA_N_ROJO", strofreal(rojo))
}
end
