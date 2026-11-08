*! version 1.0.0  CIEP 09nov2026 (sesión log-legible) — toda impresión del motor pasa por aquí
*
* Estándar del log (CUAD-1-2-firma.md §D ampliado; runbook «Cómo leer el log»):
*   · ancho máximo 110 columnas: nada se parte; los rótulos se truncan con «…», los números nunca;
*   · una unidad por cuadro, declarada en el encabezado (MXN <año>, miles de millones | % del PIB <año>);
*   · jerarquía: «══» módulo, «──» sección (numerada como SIM.do, con la referencia al documento), nada para subsección;
*   · rótulo = nombre INEGI sin paréntesis; código y sector en columnas propias; comentarios como notas «^n» / «Nota n:»;
*   · gates al pie, una línea cada uno: GATE  texto ……  a  vs  b   reldif d   OK|ROJO;
*   · avisos (FLAG, UPDATE, IMPORTANTE, Nota, SELLO ROJO, SUPUESTO, MODELO, Tiempo) de una línea con prefijo de 10 caracteres
*     y referencia al documento («→ CUAD-1 §8»); lo que necesita más de una línea es documentación, no log.
* Solo escribe en el log: no define escalares, no toca los datos ni las matrices (gate-numeros no se entera).
* Invocar con `noisily` desde do-files corridos con run/quietly (un noisily dentro del programa no vence al quietly del run).
*
* Sintaxis
*   _log modulo "Texto" [, ref(str)]                       ══ Texto  ·  ref ══…  (línea en blanco antes)
*   _log seccion "§3.2.4" "Texto" [, ref(str)]             ── §3.2.4  Texto  ·  ref ──…
*   _log linea "texto" [, rojo sangria(#)]                 línea suelta, recortada a 110
*   _log aviso, tipo(str) [num(str)] texto(str) [ref(str) rojo]
*   _log gate, texto(str) a(exp) b(exp) [tol(real 1e-9) unidad(bn|mxn|pct|n|factor)]   (bn = exp/1e9 %14.3fc, default)
*   _log modelo, nombre(str) [n(exp) r2(exp) ruta(str) archivo(str)]  una línea por modelo (N, pseudo-R²/R², dónde está la tabla
*                                                          completa): ruta() guarda estimates (.ster); archivo() solo cita el que ya se guardó
*   _log tiempo, timer(#) [texto(str)]                     Tiempo    Texto · 12.3 s   (lee el timer sin imprimirlo)
*   _log cuadro clear
*   _log cuadro col, titulo(str) [ancho(#) fmt(%fmt) escala(real 1) flex]      sin fmt = texto (izquierda); con fmt = número (derecha)
*   _log cuadro fila <celda> <celda> … [, nota(str) sep negrita]              celdas numéricas = expresiones de Stata ("—" si no evalúan)
*   _log cuadro nota "texto"                              nota al pie del cuadro (se numera en orden)
*   _log cuadro gate, texto(str) a(exp) b(exp) [tol(real 1e-9) unidad(str)]
*   _log cuadro print, titulo(str) [unidad(str) sello(str) razon(str) ref(str) nota(str)]
*   _log param, nombre(str) firmado(str) doc(str) lee(str) acumula una fila del cuadro de parámetros (SIM.do §0.8) y marca FLAG
*   _log anclas clear | add | gate | print                 el cuadro de anclas (antes _tabla_anclas v2), mismas opciones; v3 a 110 col.
*   _log envuelve, archivo(ruta)                           reescribe un .txt (nta-identidad.txt): líneas > 110 se envuelven (Nota, Cuadro,
*                                                          GATE…) y las reglas ─ se recortan a 110; los cuadros deben venir ya a 110
* Deja en los globals LOG_GATES_OK (1/0) y LOG_N_ROJO el resultado de los gates del último cuadro impreso (también TA_GATES_OK y
* TA_N_ROJO, que Households lee).

program define _log
	version 17.0
	* r() del llamador queda intacto (los módulos leen r(name`k'), r(StatTotal)… entre una fila y la siguiente)
	tempname hold
	_return hold `hold'
	capture noisily _log_despacha `0'
	local rc = _rc
	_return restore `hold'
	if `rc' exit `rc'
end


program define _log_despacha
	gettoken sub 0 : 0, parse(" ,")
	local sub = lower(trim("`sub'"))
	if "`sub'" == "modulo" {
		_log_modulo `0'
		exit
	}
	if "`sub'" == "seccion" {
		_log_seccion `0'
		exit
	}
	if "`sub'" == "linea" {
		_log_linea `0'
		exit
	}
	if "`sub'" == "aviso" {
		_log_aviso `0'
		exit
	}
	if "`sub'" == "gate" {
		_log_gate `0'
		exit
	}
	if "`sub'" == "modelo" {
		_log_modelo `0'
		exit
	}
	if "`sub'" == "tiempo" {
		_log_tiempo `0'
		exit
	}
	if "`sub'" == "cuadro" {
		_log_cuadro `0'
		exit
	}
	if "`sub'" == "param" {
		_log_param `0'
		exit
	}
	if "`sub'" == "anclas" {
		_log_anclas `0'
		exit
	}
	if "`sub'" == "envuelve" {
		_log_envuelve `0'
		exit
	}
	di as err "_log: subcomando `sub' no reconocido (modulo | seccion | linea | aviso | gate | modelo | tiempo | cuadro | param | anclas | envuelve)"
	exit 198
end


program define _log_modulo
	syntax anything(everything) [, REF(string)]
	gettoken texto : anything
	mata: _lg_header("══", `"`texto'"', `"`ref'"', 1)
end


program define _log_seccion
	syntax anything(everything) [, REF(string)]
	gettoken num anything : anything
	gettoken texto : anything
	if `"`texto'"' == "" {
		local texto `"`num'"'
		local num ""
	}
	mata: _lg_header("──", `"`=cond(`"`num'"' == "", "", `"`num'  "')'`texto'"', `"`ref'"', 0)
end


program define _log_linea
	syntax anything(everything) [, Rojo SANgria(integer 0)]
	gettoken texto : anything
	mata: _lg_linea(`"`texto'"', `sangria', ("`rojo'" != ""))
end


program define _log_aviso
	syntax , TIPO(string) TEXto(string) [NUM(string) REF(string) Rojo]
	mata: _lg_aviso(`"`tipo'"', `"`num'"', `"`texto'"', `"`ref'"', ("`rojo'" != ""))
end


program define _log_gate
	syntax , TEXto(string) A(string asis) B(string asis) [TOL(real 1e-9) UNIdad(string)]
	local av = `a'
	local bv = `b'
	if "`unidad'" == "" local unidad "bn"
	mata: _lg_gate_print(`"`texto'"', `av', `bv', `tol', "`unidad'", 1)
end


program define _log_modelo
	syntax , NOMbre(string) [N(string asis) R2(string asis) RUTA(string) ARCHivo(string)]
	local nv = .
	local rv = .
	if `"`n'"' != "" local nv = `n'
	else {
		capture local nv = e(N)
	}
	if `"`r2'"' != "" local rv = `r2'
	else {
		capture local rv = e(r2_p)
		if _rc | `rv' == . {
			capture local rv = e(r2)
		}
	}
	local etiqueta = cond(`"`r2'"' == "" & "`e(r2_p)'" != "", "pseudo-R²", "R²")
	local texto `"`nombre'"'
	if `nv' < . local texto `"`texto'  N `: di %12.0fc `nv''"'
	if `rv' < . local texto `"`texto'  `etiqueta' `: di %6.4f `rv''"'
	if `"`ruta'"' != "" {
		capture estimates save `"`ruta'"', replace
		if _rc == 0 local ref `"`ruta'.ster"'
		else local ref `"`ruta' (no se pudo guardar: r(`=_rc'))"'
	}
	else if `"`archivo'"' != "" local ref `"`archivo'"'	// la tabla completa ya la guardó quien llama (estimates save)
	mata: _lg_aviso("MODELO", "", `"`texto'"', `"`ref'"', 0)
end


program define _log_tiempo
	syntax , TIMER(integer) [TEXto(string)]
	quietly timer list `timer'
	local s = r(t`timer')/r(nt`timer')
	local segs : di %9.1fc `s'
	local texto `"`=cond(`"`texto'"' == "", "", `"`texto' · "')'`=strtrim("`segs'")' s"'
	mata: _lg_aviso("Tiempo", "", `"`texto'"', "", 0)
end


program define _log_param
	syntax , NOMbre(string) FIRmado(string) DOC(string) LEE(string)
	local valor `"${`nombre'}"'
	if `"`valor'"' == "" local valor "(vacío)"
	mata: _lg_cuadro_fila((`"`nombre'"', `"`valor'"', `"`firmado'"', `"`doc'"', `"`lee'"'), J(1, 5, .), "", 0, 0)
	if `"`valor'"' != `"`firmado'"' {
		global LOG_PARAM_FLAGS `"$LOG_PARAM_FLAGS "`nombre' = `valor' (firmado `firmado'; `doc')""'
	}
end


program define _log_cuadro
	gettoken sub 0 : 0, parse(" ,")
	local sub = lower(trim("`sub'"))
	if "`sub'" == "clear" {
		mata: _lg_cuadro_clear()
		global LOG_PARAM_FLAGS ""
		exit
	}
	if "`sub'" == "col" {
		syntax , TITulo(string) [ANcho(integer 0) FMT(string) ESCala(real 1) FLEX]
		mata: _lg_cuadro_col(`"`titulo'"', `ancho', `"`fmt'"', `escala', ("`flex'" != ""))
		exit
	}
	if "`sub'" == "fila" {
		syntax anything(everything) [, NOTa(string) SEP NEGrita]
		mata: _lg_cuadro_ncols()
		local nc = `lg_ncols'
		local celdas
		local valores
		local rest `"`anything'"'
		forvalues j = 1/`nc' {
			gettoken tok rest : rest
			mata: st_local("esnum", strofreal(_lg_cuadro_esnum(`j')))
			local v = .
			if `esnum' & `"`tok'"' != "" & `"`tok'"' != "." & `"`tok'"' != "—" {
				capture local v = `tok'
				if _rc {
					local v = .
					if regexm(`"`tok'"', "[A-Za-z]") local tok "—"	// un nombre que no existe no es un dato
				}
				else local tok ""									// evaluó: la celda es el número (o «—» si es missing)
			}
			local celdas `"`celdas' `"`tok'"'"'
			local valores "`valores' `v'"
		}
		mata: _lg_cuadro_fila_st(`"`celdas'"', "`valores'", `"`nota'"', ("`sep'" != ""), ("`negrita'" != ""))
		exit
	}
	if "`sub'" == "nota" {
		syntax anything(everything)
		gettoken texto : anything
		mata: _lg_cuadro_nota(`"`texto'"')
		exit
	}
	if "`sub'" == "gate" {
		syntax , TEXto(string) A(string asis) B(string asis) [TOL(real 1e-9) UNIdad(string)]
		local av = `a'
		local bv = `b'
		if "`unidad'" == "" local unidad "bn"
		mata: _lg_cuadro_gate(`"`texto'"', `av', `bv', `tol', "`unidad'")
		exit
	}
	if "`sub'" == "print" {
		syntax , TITulo(string) [UNIdad(string) SELlo(string) RAZon(string) REF(string) NOTa(string)]
		mata: _lg_cuadro_print(`"`titulo'"', `"`unidad'"', `"`sello'"', `"`razon'"', `"`ref'"', `"`nota'"')
		exit
	}
	di as err "_log cuadro: subcomando `sub' no reconocido (clear | col | fila | nota | gate | print)"
	exit 198
end


program define _log_envuelve
	syntax , ARCHivo(string)
	mata: _lg_envuelve(`"`archivo'"')
end


program define _log_anclas
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
		syntax , TITulo(string) [SELlo(string) RAZon(string) MOTOR UNIdad(string) PIB(string asis) NOTa(string) REF(string)]
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
		mata: _ta_print(`"`titulo'"', `"`sello'"', `"`razon'"', ("`motor'" != ""), `"`csv'"', `"`unidad'"', `pibv', `"`nota'"', `"`ref'"')
		exit
	}
	di as err "_log anclas: subcomando `sub' no reconocido (clear | add | gate | print)"
	exit 198
end


mata:
mata set matastrict on

real scalar _lg_W() return(110)

// ---------- cadenas: anchos por CARACTERES (los acentos no desalinean), recorte con «…» ----------
string scalar _lg_fit(string scalar s, real scalar w)
{
	string scalar r
	if (w <= 0) return("")
	r = (udstrlen(s) <= w ? s : (w > 1 ? udsubstr(s, 1, w - 1) + "…" : "…"))
	return(r + (w - udstrlen(r)) * " ")
}

string scalar _lg_rfit(string scalar s, real scalar w)
{
	if (udstrlen(s) >= w) return(s)
	return((w - udstrlen(s)) * " " + s)
}

string scalar _lg_trunc(string scalar s, real scalar w)
{
	if (w <= 0) return("")
	return(udstrlen(s) <= w ? s : (w > 1 ? udsubstr(s, 1, w - 1) + "…" : "…"))
}

// número con formato; nunca se recorta: si no cabe, desborda (el llamador ensancha la columna)
string scalar _lg_num(real scalar x, string scalar fmt, real scalar w)
{
	if (x >= .) return(_lg_rfit("—", w))
	return(_lg_rfit(strtrim(strofreal(x, fmt)), w))
}

// corta un texto en líneas de ancho w; las continuaciones llevan sangría ind
string colvector _lg_wrap(string scalar s, real scalar w, real scalar ind)
{
	string colvector out, pal
	string scalar linea, p
	real scalar i, lim
	out = J(0, 1, "")
	pal = tokens(s, " ")
	pal = select(pal, pal :!= " ")
	linea = ""
	lim = w
	for (i = 1; i <= cols(pal); i++) {
		p = pal[i]
		if (linea == "") {
			linea = p
			continue
		}
		if (udstrlen(linea) + 1 + udstrlen(p) <= lim) linea = linea + " " + p
		else {
			out = out \ linea
			linea = ind * " " + p
			lim = w
		}
	}
	if (linea != "" | rows(out) == 0) out = out \ linea
	return(out)
}

// ---------- jerarquía ----------
void _lg_header(string scalar ch, string scalar texto, string scalar ref, real scalar modulo)
{
	string scalar t, linea
	real scalar W, resto
	W = _lg_W()
	t = texto
	if (ref != "") t = t + "  ·  " + ref
	t = _lg_trunc(t, W - 6)
	linea = ch + " " + t + " "
	resto = W - udstrlen(linea)
	if (resto > 0) linea = linea + (resto * usubstr(ch, 1, 1))
	if (modulo) printf("\n")
	printf("{txt}%s\n", linea)
}

void _lg_linea(string scalar texto, real scalar sangria, real scalar rojo)
{
	string scalar s
	s = (sangria * " ") + _lg_trunc(texto, _lg_W() - sangria)
	if (rojo) printf("{err}%s\n", s)
	else printf("{txt}%s\n", s)
}

// prefijo fijo de 10 caracteres: «FLAG 27   », «UPDATE    », «IMPORTANTE», «SELLO ROJO», «Nota      »
void _lg_aviso(string scalar tipo, string scalar num, string scalar texto, string scalar ref, real scalar rojo)
{
	string scalar pre, t, r
	real scalar W, wt
	W = _lg_W()
	pre = tipo + (num != "" ? " " + num : "")
	pre = (udstrlen(pre) >= 10 ? _lg_trunc(pre, 10) + " " : _lg_fit(pre, 10))
	r = (ref != "" ? "  → " + ref : "")
	wt = W - udstrlen(pre) - udstrlen(r)
	if (wt < 20) {
		r = _lg_trunc(r, W - udstrlen(pre) - 20)
		wt = W - udstrlen(pre) - udstrlen(r)
	}
	t = _lg_trunc(texto, wt)
	if (rojo | tipo == "SELLO ROJO") printf("{err}%s%s%s\n", pre, t, r)
	else printf("{txt}%s{res}%s{txt}%s\n", pre, t, r)
}

// ---------- gates ----------
// unidad: bn (x/1e9 %14.3fc) | mxn (%14.0fc) | pct (%14.3f) | n (%14.0fc) | factor (%14.4f)
string scalar _lg_gate_str(string scalar texto, real scalar a, real scalar b, real scalar tol, string scalar unidad, real scalar ok)
{
	string scalar t, fmt, sa, sb, res
	real scalar d, esc, wt
	d = (a == b ? 0 : reldif(a, b))
	ok = (d <= tol)
	esc = 1
	fmt = "%14.0fc"
	if (unidad == "bn") {
		esc = 1e9
		fmt = "%14.3fc"
	}
	else if (unidad == "pct") fmt = "%14.3f"
	else if (unidad == "factor") fmt = "%14.4f"
	t = texto
	if (tol != 1e-9) t = t + " · tol " + strtrim(strofreal(tol, "%9.0e"))
	wt = 44
	if (udstrlen(t) > wt) t = _lg_trunc(t, wt)
	else if (udstrlen(t) < wt) t = t + " " + ((wt - udstrlen(t) - 1) * "…")
	sa = _lg_num(a / esc, fmt, 14)
	sb = _lg_num(b / esc, fmt, 14)
	res = (ok ? "  OK" : "ROJO")
	return(sprintf("{txt}GATE  %s {res}%s{txt}  vs  {res}%s{txt}   reldif %s   %s", t, sa, sb,
		_lg_rfit(strtrim(strofreal(d, "%7.1e")), 7), (ok ? "{res}" + res : "{err}" + res + "{txt}")))
}

void _lg_gate_print(string scalar texto, real scalar a, real scalar b, real scalar tol, string scalar unidad, real scalar suelto)
{
	real scalar ok
	ok = 0
	printf("%s\n", _lg_gate_str(texto, a, b, tol, unidad, ok))
	if (suelto) {
		st_global("LOG_LAST_GATE_OK", (ok ? "1" : "0"))
	}
}

// ---------- cuadro genérico ----------
// _LG_C: cols × 5 (titulo, ancho, fmt, escala, flex); _LG_RS: filas × ncols (texto); _LG_RV: filas × ncols (número);
// _LG_RA: filas × 3 (nota-marcador, sep, negrita); _LG_N notas; _LG_G gates (texto, unidad), _LG_GV (a, b, tol)
void _lg_cuadro_clear()
{
	external string matrix _LG_C
	external string matrix _LG_RS
	external real matrix _LG_RV
	external string matrix _LG_RA
	external string colvector _LG_N
	external string matrix _LG_G
	external real matrix _LG_GV
	_LG_C = J(0, 5, "")
	_LG_RS = J(0, 0, "")
	_LG_RV = J(0, 0, .)
	_LG_RA = J(0, 3, "")
	_LG_N = J(0, 1, "")
	_LG_G = J(0, 2, "")
	_LG_GV = J(0, 3, .)
}

void _lg_cuadro_col(string scalar titulo, real scalar ancho, string scalar fmt, real scalar escala, real scalar flex)
{
	external string matrix _LG_C
	external string matrix _LG_RS
	external real matrix _LG_RV
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	_LG_C = _LG_C \ (titulo, strofreal(ancho), fmt, strofreal(escala, "%21.0g"), (flex ? "1" : ""))
	_LG_RS = J(0, rows(_LG_C), "")
	_LG_RV = J(0, rows(_LG_C), .)
}

void _lg_cuadro_ncols()
{
	external string matrix _LG_C
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	st_local("lg_ncols", strofreal(rows(_LG_C)))
}

real scalar _lg_cuadro_esnum(real scalar j)
{
	external string matrix _LG_C
	if (j > rows(_LG_C)) return(0)
	return(_LG_C[j, 3] != "")
}

void _lg_cuadro_fila(string rowvector celdas, real rowvector valores, string scalar nota, real scalar sep, real scalar negrita)
{
	external string matrix _LG_C
	external string matrix _LG_RS
	external real matrix _LG_RV
	external string matrix _LG_RA
	external string colvector _LG_N
	string rowvector c
	real rowvector v
	real scalar nc
	string scalar mk
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	nc = rows(_LG_C)
	c = J(1, nc, "")
	v = J(1, nc, .)
	c[1, 1..min((nc, cols(celdas)))] = celdas[1, 1..min((nc, cols(celdas)))]
	v[1, 1..min((nc, cols(valores)))] = valores[1, 1..min((nc, cols(valores)))]
	mk = ""
	if (nota != "") {
		_LG_N = _LG_N \ nota
		mk = "^" + strofreal(rows(_LG_N))
	}
	_LG_RS = _LG_RS \ c
	_LG_RV = _LG_RV \ v
	_LG_RA = _LG_RA \ (mk, (sep ? "1" : ""), (negrita ? "1" : ""))
}

// desde Stata: celdas como lista de tokens entre comillas compuestas, valores como lista de números
void _lg_cuadro_fila_st(string scalar celdas, string scalar valores, string scalar nota, real scalar sep, real scalar negrita)
{
	string rowvector c
	real rowvector v
	string scalar tok
	real scalar i
	c = J(1, 0, "")
	while (celdas != "") {
		celdas = strtrim(celdas)
		if (substr(celdas, 1, 2) == "`" + `"""') {
			i = strpos(celdas, `"""' + "'")
			tok = substr(celdas, 3, i - 3)
			celdas = substr(celdas, i + 2, .)
		}
		else {
			i = strpos(celdas, " ")
			if (i == 0) {
				tok = celdas
				celdas = ""
			}
			else {
				tok = substr(celdas, 1, i - 1)
				celdas = substr(celdas, i + 1, .)
			}
		}
		c = c, tok
	}
	v = strtoreal(tokens(valores))
	_lg_cuadro_fila(c, v, nota, sep, negrita)
}

void _lg_cuadro_nota(string scalar texto)
{
	external string colvector _LG_N
	external string matrix _LG_C
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	_LG_N = _LG_N \ texto
	st_local("lg_nota_n", strofreal(rows(_LG_N)))
}

void _lg_cuadro_gate(string scalar texto, real scalar a, real scalar b, real scalar tol, string scalar unidad)
{
	external string matrix _LG_G
	external real matrix _LG_GV
	external string matrix _LG_C
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	_LG_G = _LG_G \ (texto, unidad)
	_LG_GV = _LG_GV \ (a, b, tol)
}

// título con marcadores y unidad a la derecha (si no cabe, la unidad baja de renglón)
void _lg_titulo(string scalar cab, string scalar unidad, real scalar W)
{
	real scalar lt, lu
	lt = udstrlen(cab)
	lu = udstrlen(unidad)
	if (unidad == "") printf("{txt}%s\n", _lg_trunc(cab, W))
	else if (lt + 2 + lu <= W) printf("{txt}%s%s%s\n", cab, (W - lt - lu) * " ", unidad)
	else {
		printf("{txt}%s\n", _lg_trunc(cab, W))
		printf("{txt}%s\n", _lg_rfit(_lg_trunc(unidad, W), W))
	}
}

void _lg_notas_print(string colvector notas, real scalar W)
{
	string colvector L
	real scalar i, k
	for (i = 1; i <= rows(notas); i++) {
		L = _lg_wrap("Nota " + strofreal(i) + ": " + notas[i], W, 8)
		for (k = 1; k <= rows(L); k++) printf("{txt}%s\n", L[k])
	}
}

real scalar _lg_gates_print(string matrix G, real matrix GV, real scalar W)
{
	real scalar i, ok, rojo
	rojo = 0
	for (i = 1; i <= rows(G); i++) {
		ok = 0
		printf("%s\n", _lg_gate_str(G[i, 1], GV[i, 1], GV[i, 2], GV[i, 3], G[i, 2], ok))
		if (!ok) rojo++
	}
	return(rojo)
}

void _lg_cuadro_print(string scalar titulo, string scalar unidad, string scalar sello, string scalar razon, string scalar ref, string scalar notacuadro)
{
	external string matrix _LG_C
	external string matrix _LG_RS
	external real matrix _LG_RV
	external string matrix _LG_RA
	external string colvector _LG_N
	external string matrix _LG_G
	external real matrix _LG_GV
	string colvector notas
	string scalar cab, rule, linea, s, fmt
	real rowvector w, esnum, esc
	real scalar W, nc, nr, i, j, flex, fijo, rojo, ancho
	if (cols(_LG_C) != 5) _lg_cuadro_clear()
	W = _lg_W()
	nc = rows(_LG_C)
	nr = rows(_LG_RS)
	if (nc == 0) {
		printf("{err}_log cuadro print: sin columnas declaradas (_log cuadro col)\n")
		return
	}
	// notas: la 1 es el sello y su razón; luego la del cuadro; las de fila ya están numeradas detrás (se reordenan abajo)
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
	// los marcadores de fila se corren por las notas del encabezado
	if (rows(notas) > 0) {
		for (i = 1; i <= nr; i++) {
			if (_LG_RA[i, 1] != "") _LG_RA[i, 1] = "^" + strofreal(strtoreal(substr(_LG_RA[i, 1], 2, .)) + rows(notas))
		}
	}
	notas = notas \ _LG_N
	if (ref != "") cab = cab + "  ·  " + ref
	// anchos: numéricas = máx(declarado, título, dato formateado); texto = declarado; una flex toma el resto
	w = J(1, nc, 0)
	esnum = J(1, nc, 0)
	esc = J(1, nc, 1)
	flex = 0
	for (j = 1; j <= nc; j++) {
		ancho = strtoreal(_LG_C[j, 2])
		esnum[j] = (_LG_C[j, 3] != "")
		esc[j] = strtoreal(_LG_C[j, 4])
		if (_LG_C[j, 5] == "1" & flex == 0) flex = j
		w[j] = max((ancho, (esnum[j] ? udstrlen(_LG_C[j, 1]) : 0)))
		if (esnum[j]) {
			for (i = 1; i <= nr; i++) {
				if (_LG_RV[i, j] < .) w[j] = max((w[j], udstrlen(strtrim(strofreal(_LG_RV[i, j] / esc[j], _LG_C[j, 3])))))
				else if (_LG_RS[i, j] != "") w[j] = max((w[j], udstrlen(_LG_RS[i, j])))
			}
		}
		else if (w[j] == 0) {
			w[j] = udstrlen(_LG_C[j, 1])
			for (i = 1; i <= nr; i++) w[j] = max((w[j], udstrlen(_LG_RS[i, j]) + udstrlen(_LG_RA[i, 1])))
		}
	}
	fijo = sum(w) - (flex ? w[flex] : 0) + (nc - 1)
	if (flex) {
		w[flex] = W - fijo
		if (w[flex] < 10) {
			printf("{err}_log cuadro print: las columnas fijas ocupan %f columnas; la flexible queda con %f (< 10). Declara menos columnas.\n", fijo, w[flex])
			return
		}
		ancho = W
	}
	else {
		// sin columna flexible el cuadro mide lo que suman sus columnas, salvo que el encabezado o los gates pidan más
		ancho = fijo + 0
		if (ancho > W) {
			printf("{err}_log cuadro print: el cuadro mide %f columnas (> 110). Declara menos columnas o una flexible.\n", ancho)
			return
		}
		ancho = max((ancho, min((W, udstrlen(cab) + (unidad != "" ? 2 + udstrlen(unidad) : 0)))))
		if (rows(_LG_G)) ancho = W
	}
	rule = ancho * "─"
	printf("{txt}%s\n", rule)
	_lg_titulo(cab, unidad, ancho)
	printf("{txt}%s\n", rule)
	linea = ""
	for (j = 1; j <= nc; j++) {
		s = (esnum[j] ? _lg_rfit(_lg_trunc(_LG_C[j, 1], w[j]), w[j]) : _lg_fit(_LG_C[j, 1], w[j]))
		linea = linea + (j > 1 ? " " : "") + s
	}
	printf("{txt}%s\n", ustrregexra(linea, " +$", ""))
	for (i = 1; i <= nr; i++) {
		if (_LG_RA[i, 2] == "1") printf("{txt}%s\n", rule)
		linea = ""
		for (j = 1; j <= nc; j++) {
			if (esnum[j]) {
				if (_LG_RV[i, j] < .) s = "{res}" + _lg_num(_LG_RV[i, j] / esc[j], _LG_C[j, 3], w[j]) + "{txt}"
				else s = _lg_rfit((_LG_RS[i, j] != "" & _LG_RS[i, j] != "." ? _lg_trunc(_LG_RS[i, j], w[j]) : "—"), w[j])
			}
			else {
				s = _LG_RS[i, j]
				if (j == (flex ? flex : 1) & _LG_RA[i, 1] != "") {
					s = (udstrlen(s) + udstrlen(_LG_RA[i, 1]) <= w[j] ? s : _lg_trunc(s, w[j] - udstrlen(_LG_RA[i, 1]))) + _LG_RA[i, 1]
				}
				s = _lg_fit(s, w[j])
			}
			linea = linea + (j > 1 ? " " : "") + s
		}
		linea = ustrregexra(linea, " +$", "")
		if (_LG_RA[i, 3] == "1") printf("{txt}{bf:%s}\n", linea)
		else printf("{txt}%s\n", linea)
	}
	printf("{txt}%s\n", rule)
	_lg_notas_print(notas, W)
	rojo = _lg_gates_print(_LG_G, _LG_GV, ancho)
	if (rows(_LG_G)) printf("{txt}%s\n", rule)
	st_global("LOG_GATES_OK", (rojo ? "0" : "1"))
	st_global("LOG_N_ROJO", strofreal(rojo))
	st_global("TA_GATES_OK", (rojo ? "0" : "1"))
	st_global("TA_N_ROJO", strofreal(rojo))
}

// ---------- archivo de texto a 110 columnas (nta-identidad.txt): títulos, notas y gates se envuelven; las reglas se recortan ----------
void _lg_envuelve(string scalar archivo)
{
	string colvector L, out, W
	string scalar l, pre
	real scalar i, k, fh, ind, Wd
	Wd = _lg_W()
	L = cat(archivo)
	out = J(0, 1, "")
	for (i = 1; i <= rows(L); i++) {
		l = L[i]
		if (udstrlen(l) <= Wd) {
			out = out \ l
			continue
		}
		if (udsubstr(l, 1, 1) == "─") {
			out = out \ (Wd * "─")
			continue
		}
		pre = usubstr(l, 1, 6)
		ind = 8
		if (pre == "Cuadro") ind = 10
		if (pre == "GATE 1" | pre == "RESULT" | pre == "INFO  ") ind = 11
		W = _lg_wrap(l, Wd, ind)
		for (k = 1; k <= rows(W); k++) out = out \ W[k]
	}
	fh = fopen(archivo, "w")
	for (i = 1; i <= rows(out); i++) fput(fh, out[i])
	fclose(fh)
}

// ---------- cuadro de anclas (antes _tabla_anclas v2; v3 a 110 columnas, en miles de millones) ----------
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

// Catálogo 05_scripts/scn-cuentas.csv: codigo;nombre_inegi;nombre_sna2008;sectores;fuente;nota (# = comentario)
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

// Sin paréntesis en el rótulo (estándar §D)
string scalar _ta_sinparen(string scalar s)
{
	string scalar r
	r = s
	while (ustrregexm(r, "\([^()]*\)")) r = ustrregexra(r, "\s*\([^()]*\)", "")
	return(strtrim(ustrregexra(r, "\s+", " ")))
}

void _ta_print(string scalar titulo, string scalar sello, string scalar razon, real scalar motor, string scalar csv, string scalar unidad,
               real scalar pib, string scalar notacuadro, string scalar ref)
{
	external string matrix _TA_S
	external real matrix _TA_V
	external string colvector _TA_G
	external real matrix _TA_GV
	transmorphic A
	string scalar rule, cab, nombre, cuenta, mk, linea, uni, fmtv, fuentes, ginis
	string colvector notas, nombres
	string matrix G
	real scalar i, n, W, ncob, hasgini, haspib, hasfue, hasvar, esc, wcod, wsec, wfue, wval, wfac, wcob, wpib, wgin, wvar, wcta, fijo, rojo
	if (cols(_TA_S) != 7) _ta_clear()
	W = _lg_W()
	n = rows(_TA_S)
	// sin filas: solo el encabezado de sección y los gates (p. ej. «Gates de Yl y Yk contra las celdas S.14»)
	if (n == 0) {
		_lg_header("──", titulo, ref, 0)
		G = J(rows(_TA_G), 2, "")
		if (rows(_TA_G)) {
			G[., 1] = _TA_G
			G[., 2] = J(rows(_TA_G), 1, (substr(unidad, 1, 3) == "MXN" ? "bn" : "mxn"))
		}
		rojo = _lg_gates_print(G, _TA_GV, W)
		st_global("LOG_GATES_OK", (rojo ? "0" : "1"))
		st_global("LOG_N_ROJO", strofreal(rojo))
		st_global("TA_GATES_OK", (rojo ? "0" : "1"))
		st_global("TA_N_ROJO", strofreal(rojo))
		return
	}
	A = _ta_catalogo(csv)
	ncob = (motor ? sum(_TA_V[., 4] :< .) : 0)
	hasgini = (sum(_TA_V[., 5] :< .) > 0)
	haspib = (pib < .)
	hasfue = (n > 0 ? any(_TA_S[., 3] :!= "") : 0)
	hasvar = (n > 0 ? any(_TA_S[., 4] :!= "") : 0)
	// unidad: MXN → miles de millones
	esc = 1
	fmtv = "%11.0fc"
	uni = unidad
	if (substr(unidad, 1, 3) == "MXN") {
		esc = 1e9
		fmtv = "%11.3fc"
		uni = unidad + ", miles de millones"
	}
	// nombres INEGI (catálogo) o rótulo
	nombres = J(n, 1, "")
	for (i = 1; i <= n; i++) {
		if (_TA_S[i, 6] != "") nombre = _TA_S[i, 6]
		else nombre = (asarray_contains(A, _TA_S[i, 1]) ? asarray(A, _TA_S[i, 1]) : _TA_S[i, 1])
		nombres[i] = _ta_sinparen(nombre)
	}
	// anchos
	wcod = 7
	wsec = 6
	wval = 11
	wfac = 7
	wcob = 6
	wpib = 7
	wgin = 6
	wvar = 0
	wfue = 0
	for (i = 1; i <= n; i++) {
		wcod = max((wcod, min((9, udstrlen(_TA_S[i, 1])))))
		wsec = max((wsec, min((9, udstrlen(_TA_S[i, 2])))))
		if (_TA_V[i, 1] < .) wval = max((wval, udstrlen(strtrim(strofreal(_TA_V[i, 1] / esc, fmtv)))))
		if (motor & _TA_V[i, 2] < .) wval = max((wval, udstrlen(strtrim(strofreal(_TA_V[i, 2] / esc, fmtv)))))
		if (hasvar) wvar = max((wvar, udstrlen(_TA_S[i, 4])))
		if (hasfue) wfue = max((wfue, udstrlen(_TA_S[i, 3])))
	}
	wvar = (hasvar ? min((wvar, 16)) : 0)
	wfue = (hasfue ? min((wfue, 20)) : 0)
	// fijo = todo menos Cuenta; Cuenta = resto; si queda < 26 se recortan Variable, luego Fuente (→ nota), luego Gini (→ nota)
	fijo = wcod + 1 + wsec + 1 + (wfue ? wfue + 1 : 0) + wval + (motor ? 1 + wval + 1 + wfac : 0) + (ncob ? 1 + wcob : 0) + (haspib ? 1 + wpib : 0) + (hasgini ? 1 + wgin : 0) + (wvar ? 1 + wvar : 0) + 1
	wcta = W - fijo
	fuentes = ""
	if (wcta < 34 & wfue) {
		fijo = fijo - wfue - 1
		wfue = 0
		wcta = W - fijo
		for (i = 1; i <= n; i++) {
			if (_TA_S[i, 3] != "") fuentes = fuentes + (fuentes != "" ? "; " : "") + _TA_S[i, 1] + " " + _TA_S[i, 3]
		}
	}
	ginis = ""
	if (wcta < 34 & hasgini) {
		fijo = fijo - wgin - 1
		hasgini = 0
		wcta = W - fijo
		for (i = 1; i <= n; i++) {
			if (_TA_V[i, 5] < .) ginis = ginis + (ginis != "" ? "; " : "") + (_TA_S[i, 4] != "" ? _TA_S[i, 4] : _TA_S[i, 1]) + " " + strtrim(strofreal(_TA_V[i, 5], "%6.3f"))
		}
	}
	if (wcta < 34 & wvar > 13) {
		fijo = fijo - (wvar - 13)
		wvar = 13
		wcta = W - fijo
	}
	if (wcta < 12) wcta = 12
	rule = W * "─"
	// notas: 1 sello, 2 nota del cuadro, luego fuentes / ginis desplazados y las de fila en orden
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
	if (fuentes != "") {
		notas = notas \ ("Fuentes: " + fuentes)
		cab = cab + "^" + strofreal(rows(notas))
	}
	if (ginis != "") {
		notas = notas \ ("Gini: " + ginis)
		cab = cab + "^" + strofreal(rows(notas))
	}
	if (csv == "") notas = notas \ "catálogo 05_scripts/scn-cuentas.csv no encontrado: la columna «Cuenta» repite el código"
	if (ref != "") cab = cab + "  ·  " + ref
	printf("{txt}%s\n", rule)
	_lg_titulo(cab, uni, W)
	printf("{txt}%s\n", rule)
	linea = _lg_fit("Código", wcod) + " " + _lg_fit("Sector", wsec) + " " + _lg_fit("Cuenta", wcta)
	if (wfue) linea = linea + " " + _lg_fit("Fuente", wfue)
	linea = linea + " " + _lg_rfit((motor ? "Ancla" : "Valor"), wval)
	if (motor) linea = linea + " " + _lg_rfit("Σ motor", wval) + " " + _lg_rfit("Factor", wfac)
	if (ncob) linea = linea + " " + _lg_rfit("Cob %", wcob)
	if (haspib) linea = linea + " " + _lg_rfit("% PIB", wpib)
	if (hasgini) linea = linea + " " + _lg_rfit("Gini", wgin)
	if (wvar) linea = linea + " " + _lg_fit("Variable", wvar)
	printf("{txt}%s\n", ustrregexra(linea, " +$", ""))
	for (i = 1; i <= n; i++) {
		if (_TA_S[i, 7] == "1") printf("{txt}%s\n", rule)
		mk = ""
		if (_TA_S[i, 5] != "") {
			notas = notas \ _TA_S[i, 5]
			mk = "^" + strofreal(rows(notas))
		}
		cuenta = (udstrlen(nombres[i]) + udstrlen(mk) <= wcta ? nombres[i] : _lg_trunc(nombres[i], wcta - udstrlen(mk))) + mk
		linea = _lg_fit(_TA_S[i, 1], wcod) + " " + _lg_fit(_TA_S[i, 2], wsec) + " " + _lg_fit(cuenta, wcta)
		if (wfue) linea = linea + " " + _lg_fit(_TA_S[i, 3], wfue)
		linea = linea + " {res}" + _lg_num(_TA_V[i, 1] / esc, fmtv, wval)
		if (motor) linea = linea + " " + _lg_num(_TA_V[i, 2] / esc, fmtv, wval) + " " + _lg_num(_TA_V[i, 3], "%7.4f", wfac)
		if (ncob) linea = linea + " " + _lg_num(_TA_V[i, 4], "%6.2f", wcob)
		if (haspib) linea = linea + " " + _lg_num(_TA_V[i, 1] / pib * 100, "%7.3f", wpib)
		if (hasgini) linea = linea + " " + _lg_num(_TA_V[i, 5], "%6.3f", wgin)
		linea = linea + "{txt}"
		if (wvar) linea = linea + " " + _lg_fit(_TA_S[i, 4], wvar)
		printf("%s\n", ustrregexra(linea, " +$", ""))
	}
	printf("{txt}%s\n", rule)
	_lg_notas_print(notas, W)
	G = J(rows(_TA_G), 2, "")
	if (rows(_TA_G)) {
		G[., 1] = _TA_G
		G[., 2] = J(rows(_TA_G), 1, (esc == 1e9 ? "bn" : "mxn"))
	}
	rojo = _lg_gates_print(G, _TA_GV, W)
	if (rows(_TA_G)) printf("{txt}%s\n", rule)
	st_global("LOG_GATES_OK", (rojo ? "0" : "1"))
	st_global("LOG_N_ROJO", strofreal(rojo))
	st_global("TA_GATES_OK", (rojo ? "0" : "1"))
	st_global("TA_N_ROJO", strofreal(rojo))
}
end
