*! version 2.0.0  CIEP 03oct2026
*! perfilpc — Reparto intra-hogar del gasto por perfil edad-sexo (punto fijo en Mata)
*
* NOTA METODOLÓGICA
* -----------------
* Problema. La ENIGH registra la mayor parte del gasto a nivel HOGAR (gastohogar,
* erogaciones, tarjetas) y solo una parte a nivel PERSONA (gastospersona). Para
* construir perfiles por edad (economía generacional) hay que repartir el gasto
* del hogar entre sus integrantes, y el reparto igualitario (gasto/integrantes)
* es una mala hipótesis: un bebé y un adulto no consumen lo mismo de la misma
* categoría.
*
* Idea. Dejar que los propios datos digan cómo se reparte: el gasto de un hogar
* en la categoría k se asigna a cada integrante en proporción a lo que, EN
* PROMEDIO, gasta una persona de su edad y sexo en esa categoría. Como ese
* promedio depende del reparto y el reparto depende del promedio, se resuelve
* por punto fijo (iteración de proporciones, en el espíritu del IPF):
*
*   x_i^(0)  = G_h / n_h                        (reparto igualitario: punto de partida)
*   repetir t = 1, 2, ...:
*     μ_c     = Σ_{i∈c} w_i x_i^(t-1) / Σ_{i∈c} w_i   media ponderada de la celda c = (edad, sexo)
*     m_c     = μ_c redondeada a sig() cifras significativas (default 6); piso 10^-sig·máx_c m_c
*     x_i^(t) = G_h · m_{c(i)} / Σ_{j∈h} m_{c(j)}     para cada integrante i del hogar h
*   hasta que  Σ_c |Δ(Σ_{i∈c} w_i x_i)| / Σ_i w_i x_i ≤ tol   (default 1e-6: en la última
*   iteración cambió de celda edad-sexo menos de una millonésima del gasto; el perfil
*   es estable en sus primeras 6 cifras significativas), o hasta maxiter.
*
*   Sobre sig() y tol(). El redondeo a s cifras perturba cada m_c hasta 5·10^-s en
*   términos relativos; con s = 6 ese ruido (≤ 5e-7) queda por debajo de tol = 1e-6
*   y en la práctica no altera el paro (ENIGH 2024: sig(6) y sig(7) convergen en el
*   mismo número de iteraciones ±2). El tope maxiter(1000) importa más: las variables
*   lentas (gas_pc_Agua 505, cant_pc_ComuT 574 iteraciones) superan 500.
*
*   donde G_h = gasto del hogar en k (= hogar() × integrantes(): hogar() llega
*   per cápita porque Expenditure.do ya lo dividió entre tot_integ), w_i = factor
*   de expansión, c(i) = celda edad-sexo del individuo i. La celda recorre
*   edad 0..109 × sexo {"1","2"}; una persona fuera de ese barrido conserva su
*   valor y participa en el reparto de su hogar.
*
* Propiedades.
*   - Cada iteración conserva EXACTAMENTE el gasto de cada hogar (Σ_i x_i = G_h),
*     y por tanto el total nacional ponderado; lo único que cambia es cómo se
*     reparte dentro del hogar. Es lo que se verifica con tabstat [fw] antes/después.
*   - El perfil m_c es la "forma" del consumo por edad que el usuario ve en las
*     gráficas de Perfiles/Simulador; la iteración lo va afinando: parte del
*     perfil igualitario (iteración 0) y converge hacia uno consistente con la
*     composición de los hogares que sí reportan consumo en esa categoría.
*   - El número de iteraciones lo decide cada variable: el criterio es relativo
*     (adimensional), así que gasto en pesos y cantidades en unidades convergen
*     al mismo nivel de precisión (6 cifras). r(iter) dice cuántas tardó y
*     r(converged) si alcanzó la tolerancia antes de maxiter.
*
* Por qué precisión relativa y no centavos (cambio metodológico, oct-2026).
*   El bloque original de Expenditure.do (v8.4.x) redondeaba m_c a .01 y ponía
*   .01 donde había 0, con 25 iteraciones fijas. Para GASTO (miles de pesos por
*   celda) eso era ruido de 1e-6, pero para CANTIDADES per cápita (0.01–1 unidad)
*   la rejilla de .01 era gruesa (pasos del 1% al 100% del valor): el perfil
*   quedaba atrapado en la rejilla, Δ caía a 0 exacto de golpe (p. ej. en la
*   iteración 19) y el resultado cargaba un error de cuantización de hasta ±0.005
*   por celda, con el piso de .01 sustituyendo medias legítimas de 0.004. Con 6
*   cifras significativas el error relativo es ≤ 5e-7 en cualquier escala, y con
*   el criterio de paro relativo cada variable itera lo que necesita (el gasto, que
*   con 25 fijas aún se movía ~1,000 pesos por persona, ahora llega a 1e-6).
*
* Lo que enseña converger (decisión metodológica abierta). Con 25 iteraciones
*   fijas el resultado dependía de T porque el proceso no había convergido: en
*   Alimentos 2024 el gasto per cápita de 0–4 años va de 12,988 (igualitario) a
*   3,732 en la iteración 25 y a 2,700 en el punto fijo (237 iteraciones); el de
*   30–64 de 18,352 a 23,423 y 23,728. La participación de 0–14 años en el gasto
*   total en alimentos pasa de 17.9% (igualitario) a 6.8% (iter. 25) y 5.8%
*   (convergido). El punto fijo asigna a un niño de 0–4 el 11% del gasto en
*   alimentos de un adulto de 30–64 (NTA usa, como escala de equivalencia a priori,
*   0.4 para 0–4 subiendo linealmente a 1 a los 20; es el `alfa` de Expenditure.do
*   §3.5). El método identifica el consumo de los niños solo por cómo varía el
*   gasto del hogar con su composición, y ese tipo de identificación tiende a
*   atribuirles poco (economías de escala, bienes compartidos). Las 25 iteraciones
*   actuaban como regularización implícita —parar antes de llegar al punto fijo—
*   sin que nadie la hubiera elegido. Converger hace explícito el supuesto; si se
*   juzga que el punto fijo subestima a los niños, la corrección debe ser también
*   explícita (p. ej. piso al perfil con la escala NTA), no un T arbitrario.
*
* Modo legacy (opción `legacy`): reproduce el bloque original de v8.4.x byte a
*   byte —25 iteraciones fijas (iter()), redondeo a .01, piso .01 y el artefacto de
*   que la primera celda (edad 0, sexo "1") calculaba su media viendo los ceros
*   como 0 y las otras 219 como .01— para el test dorado y para reproducir
*   versiones anteriores. No es el default.
*
* Por qué Mata. El original hacía 220 tabstat + 440 replace por iteración, cada
* uno recorriendo las ~309 mil personas: ~440 s por variable, ~10 h por ENIGH
* (84 variables). Aquí cada iteración son unas cuantas operaciones vectoriales
* sobre paneles (panelsum por celda y por hogar): ~0.08 s por iteración.
*
* Sintaxis:
*   perfilpc varname, HOGar(varname) INTegrantes(varname) FACtor(varname) HHid(varname)
*       [EDad(varname) SEXo(varname) SIG(#) TOL(real 1e-6) MAXiter(#) LEGacy ITER(#)
*        EQuiv(name) Grafica(name) TITle(string) NOGraphs]
*
*   varname        gasto per cápita a repartir; a la ENTRADA debe traer el punto de
*                  partida (en Expenditure.do: = hogar()); a la SALIDA trae x^(T).
*   hogar()        gasto del hogar per cápita (G_h / n_h), constante en la iteración.
*   integrantes()  n_h (tot_integ).
*   factor()       factor de expansión (peso de frecuencia).
*   hhid()         identificador numérico del hogar (egen group(folioviv foliohog)).
*                  No requiere que los datos estén ordenados.
*   edad(), sexo() default: edad, sexo. sexo puede ser string ("1"/"2") o numérico.
*   sig(#)         cifras significativas a las que se redondea m_c (default 6).
*   tol(#)         tolerancia relativa del criterio de paro (default 1e-6).
*   maxiter(#)     tope de iteraciones (default 1000); si se alcanza, r(converged)=0.
*   legacy         modo v8.4.x: iter() iteraciones fijas (default 25), centavos.
*   equiv(name)    guarda Σ_{j∈h} m_{c(j)} de la última iteración en esa variable
*                  (es la variable equivalencias<k> que dejaba el bloque original).
*   grafica(name)  crea tres gráficas con nombre (quedan en memoria para revisarlas
*                  una por una: son parte del proceso pedagógico, no un subproducto)
*                  y las exporta a users/$id/graphs/ (o $export/):
*                    <name>_pc    pirámide del gasto PER CÁPITA por edad y sexo
*                                 (hombres a la izquierda, mujeres a la derecha):
*                                 perfil inicial, iteraciones (hasta 24, espaciadas) y final.
*                    <name>_tot   pirámide de la DISTRIBUCIÓN DEL GASTO TOTAL de la
*                                 encuesta por edad y sexo (% del total, barras =
*                                 final; línea punteada = inicial; grises = iteraciones).
*                    <name>_conv  convergencia en términos relativos (escala log):
*                                 cambio relativo máx. del perfil (el criterio), con la
*                                 línea de tolerancia, y máx./media de |Δx| / x̄.
*                  <name> admite hasta 27 caracteres (32 de Stata menos "_conv").
*                  Stata admite 2,000 sersets en memoria y un serset es una MUESTRA
*                  distinta (un plot con `if` propio), no un plot: cada serie va en su
*                  propia variable sobre la misma muestra y los plots no llevan `if`.
*   nographs       no grafica aunque se dé grafica().
*
* Devuelve:
*   r(iter)       iteraciones ejecutadas; r(converged) 1/0; r(tol); r(sig); r(relL1)
*                 criterio en la última iteración (fracción del gasto que cambió de
*                 celda); r(relcel) cambio relativo máx. en una celda (informativo);
*                 r(maxdif), r(meandif) |Δx| máx. y media (unidades de la variable).
*   r(perfil)     matriz 220·k × 5: iter edad sexo media total, para k iteraciones:
*                 la 0 (inicial), la final y hasta 24 intermedias espaciadas
*   r(conv)       matriz T × 6: iter maxdif meandif relcel relL1 xbar
*                 (xbar = media ponderada de x en esa iteración, para relativizar |Δx|)

program define perfilpc, rclass
	version 17.0
	syntax varname(numeric) , HOGar(varname numeric) INTegrantes(varname numeric) ///
		FACtor(varname numeric) HHid(varname numeric) ///
		[EDad(varname numeric) SEXo(varname) SIG(integer 6) TOL(real 1e-6) MAXiter(integer 1000) LEGacy ITER(integer 25) ///
		 EQuiv(name) Grafica(name) TITle(string) NOGraphs]

	if "`edad'" == "" local edad edad
	if "`sexo'" == "" local sexo sexo
	confirm numeric variable `edad'
	confirm variable `sexo'
	if `iter' < 1 | `maxiter' < 1 | `tol' <= 0 | `sig' < 1 | `sig' > 15 {
		di as err "perfilpc: iter() y maxiter() deben ser >= 1, tol() > 0 y sig() entre 1 y 15"
		exit 198
	}
	local pc `varlist'
	local islegacy = ("`legacy'" == "legacy")
	local cap = cond(`islegacy', `iter', `maxiter')

	* Variable de equivalencias (opcional): se crea/reemplaza como double
	if "`equiv'" != "" {
		capture drop `equiv'
		qui gen double `equiv' = .
	}

	tempname P C
	mata: perfilpc_fixedpoint("`pc'", "`hogar'", "`integrantes'", "`factor'", ///
		"`edad'", "`sexo'", "`hhid'", `cap', `tol', `sig', `islegacy', "`equiv'", "`P'", "`C'")
	* Mata deja en locals: niter (iteraciones ejecutadas), converged (1/0)

	matrix colnames `P' = iter edad sexo media total
	matrix colnames `C' = iter maxdif meandif relcel relL1 xbar

	* Resumen en pantalla
	local d1max  = `C'[1,2]
	local dTmax  = `C'[`niter',2]
	local dTmean = `C'[`niter',3]
	local relT   = `C'[`niter',5]
	local relcT  = `C'[`niter',4]
	local fmtd = cond(`d1max' >= 100, "%12.0fc", "%12.4f")
	if `islegacy' {
		local estado "legacy: `niter' iter. fijas"
	}
	else if `converged' {
		local estado "convergi{c o'} en `niter' iter."
	}
	else {
		local estado "NO convergi{c o'} en `niter' iter. (maxiter)"
	}
	di as text "  perfilpc " as result "`pc'" as text ": " as result "`estado'" ///
		as text " | gasto que cambi{c o'} de celda " as result %9.2e `relT' as text " (tol " %6.0e `tol' ")" ///
		as text " | delta max " as result `fmtd' `d1max' as text " -> " as result `fmtd' `dTmax'

	* Gráficas: pirámide per cápita, pirámide del gasto total, convergencia
	if "`grafica'" != "" & "`nographs'" == "" & "$nographs" != "nographs" {
		if length("`grafica'") > 27 {
			di as err "perfilpc: grafica(`grafica') tiene " length("`grafica'") " caracteres; máximo 27 (los nombres de gráfica de Stata admiten 32 y se agrega _pc/_tot/_conv)."
			exit 198
		}
		perfilpc_graph `P' `C', iter(`niter') tol(`tol') converged(`converged') legacy(`islegacy') ///
			name(`grafica') title(`"`title'"') var(`pc')
	}

	return scalar iter      = `niter'
	return scalar converged = `converged'
	return scalar tol       = `tol'
	return scalar sig       = `sig'
	return scalar relL1     = `relT'
	return scalar relcel    = `relcT'
	return scalar maxdif    = `dTmax'
	return scalar meandif   = `dTmean'
	return matrix conv      = `C'
	return matrix perfil    = `P'
end


program define perfilpc_graph
	syntax namelist(min=2 max=2), iter(integer) tol(real) converged(integer) legacy(integer) ///
		name(name) var(string) [title(string)]
	tokenize `namelist'
	local P `1'
	local C `2'
	if `"`title'"' == "" local title "`var'"

	* Destino de los PNG
	if "$export" != "" {
		local dir "$export"
	}
	else {
		capture mkdir "${SIMROOT}/users/"
		capture mkdir "${SIMROOT}/users/$id/"
		capture mkdir "${SIMROOT}/users/$id/graphs/"
		local dir "${SIMROOT}/users/$id/graphs"
	}

	* Las gráficas se quedan en memoria con nombre (<name>_pc, _tot, _conv) y además se exportan.
	* Presupuesto de sersets (2,000 en memoria): un serset es una MUESTRA distinta, no un
	* plot. Por eso cada serie va en su propia variable sobre la misma muestra y los
	* plots no llevan `if` (con `if iter==t & sexo==s` eran 52 por gráfica).
	preserve
	clear
	qui svmat double `P', names(col)   // iter edad sexo media total

	local nint = `iter' - 1   // r(perfil) ya trae solo 0, la final y <= 24 intermedias espaciadas

	* % del gasto total de la encuesta que cae en cada celda edad-sexo (por iteración)
	bys iter: egen double _T = total(total)
	qui gen double pct = total/_T*100

	* Pirámide: hombres con signo negativo (izquierda), mujeres positivo (derecha)
	qui gen double media_s = cond(sexo == 1, -media, media)
	qui gen double pct_s   = cond(sexo == 1, -pct,   pct)

	* Fila separadora (missing) al final de cada bloque iter×sexo: con cmissing(n) la
	* línea se corta ahí y una sola variable puede dibujar los dos sexos sin unirlos.
	qui expand 2 if edad == 109, gen(_sep)
	qui replace edad = 109.5 if _sep
	qui replace media_s = . if _sep
	qui replace pct_s   = . if _sep
	sort iter sexo edad

	local fin = cond(`converged', "Final (`iter' iter.)", cond(`legacy', "Final (`iter' iter. fijas)", "Final (`iter' iter., sin converger)"))
	perfilpc_piramide media_s, iter(`iter') nint(`nint') gname(`name'_pc) tipo(line) fmt(%12.0fc) finlab(`"`fin'"') ///
		title(`"`title'"') subtitle("Gasto per c{c a'}pita anual por edad y sexo: perfil inicial, por iteraci{c o'}n y final") ///
		xtitle("Pesos anuales per c{c a'}pita")
	qui graph export `"`dir'/`name'_pc.png"', replace name(`name'_pc)

	perfilpc_piramide pct_s, iter(`iter') nint(`nint') gname(`name'_tot) tipo(bar) fmt(%4.1f) finlab(`"`fin'"') ///
		title(`"`title'"') subtitle("Distribuci{c o'}n del gasto total de la encuesta por edad y sexo (% del total)") ///
		xtitle("% del gasto total")
	qui graph export `"`dir'/`name'_tot.png"', replace name(`name'_tot)

	* Convergencia, en términos relativos (adimensional, comparable entre gasto y cantidades):
	*   relL1  = Σ_c |Δ(Σ_{i∈c} w_i x_i)| / Σ w x   (el criterio de paro); relcel = máx_c |Δμ_c| / μ_c
	*   maxdif/xbar, meandif/xbar = |Δx| por persona relativo a la media ponderada de x
	* Escala log con etiquetas en potencias de 10; los ceros exactos (log indefinido) se omiten.
	clear
	qui svmat double `C', names(col)
	qui gen double relmax  = maxdif/xbar
	qui gen double relmean = meandif/xbar
	foreach v in relL1 relcel relmax relmean {
		qui replace `v' = . if `v' <= 0
	}
	qui summ relmean
	local lo = min(r(min), `tol')
	qui summ relL1
	local lo = min(`lo', r(min))
	local hi = r(max)
	foreach v in relcel relmax {
		qui summ `v'
		local hi = max(`hi', r(max))
	}
	local ylab
	if `lo' < . & `hi' < . {
		forvalues e = `=floor(log10(`lo'))'/`=ceil(log10(`hi'))' {
			local y = 10^`e'
			local ylab `ylab' `y' "`=cond(`e' >= 0, string(`y', "%12.0fc"), "1e`e'")'"
		}
	}
	if `legacy' {
		local nota note("Modo legacy: `iter' iteraciones fijas, redondeo a centavos (bloque original v8.4.x).", size(vsmall))
	}
	else if `converged' {
		local nota note("Convergi{c o'} en `iter' iteraciones: la fracci{c o'}n del gasto total que cambi{c o'} de celda edad-sexo baj{c o'} de `=string(`tol', "%6.0e")'.", size(vsmall))
	}
	else {
		local nota note("NO convergi{c o'}: tras `iter' iteraciones (maxiter) la fracci{c o'}n del gasto que cambia de celda sigue arriba de `=string(`tol', "%6.0e")'.", size(vsmall))
	}
	local xstep = cond(`iter' <= 30, 5, cond(`iter' <= 100, 10, cond(`iter' <= 300, 25, 50)))
	local xlab 1
	forvalues t = `xstep'(`xstep')`iter' {
		local xlab `xlab' `t'
	}
	if `iter' > 1 & mod(`iter', `xstep') != 0 local xlab `xlab' `iter'
	twoway (line relL1 iter, pstyle(p1) lpattern(solid) lwidth(thick) cmissing(n)) ///
		(line relcel iter, lcolor(gs8) lpattern(solid) lwidth(thin) cmissing(n)) ///
		(line relmax iter, pstyle(p2) lpattern(solid) lwidth(medthick) cmissing(n)) ///
		(line relmean iter, pstyle(p3) lpattern(solid) lwidth(medthick) cmissing(n)) ///
		, yscale(log) ylabel(`ylab', angle(0)) yline(`tol', lpattern(dash) lcolor(black)) ///
		title(`"`title'"') ///
		subtitle("Convergencia del reparto intra-hogar, cambios relativos entre iteraciones (escala log); l{c i'}nea punteada = tolerancia", size(small)) ///
		xtitle("Iteraci{c o'}n") xlabel(`xlab') ytitle("") ///
		legend(order(1 "Gasto que cambi{c o'} de celda edad-sexo (criterio)" 2 "Cambio rel. m{c a'}ximo en una celda" 3 "{c |}{&Delta}x{c |} m{c a'}ximo / media de x" 4 "{c |}{&Delta}x{c |} medio / media de x") rows(2) size(small)) ///
		`nota' name(`name'_conv, replace)
	qui graph export `"`dir'/`name'_conv.png"', replace name(`name'_conv)
	restore
end


* Pirámide edad-sexo: edad en el eje vertical, hombres a la izquierda (valores
* negativos), mujeres a la derecha. tipo(line): perfil final en línea gruesa;
* tipo(bar): perfil final en barras. En ambos, inicial en negro punteado e
* iteraciones intermedias en gris de claro a oscuro (hasta 24, espaciadas si hay
* más). Una variable por serie y ningún `if` en los plots: un solo serset.
program define perfilpc_piramide
	syntax varname, iter(integer) nint(integer) gname(name) tipo(string) fmt(string) ///
		[title(string) subtitle(string) xtitle(string) finlab(string)]
	local v `varlist'
	if `"`finlab'"' == "" local finlab "Final (iteraci{c o'}n `iter')"

	* Eje horizontal simétrico con etiquetas en valor absoluto
	qui summ `v' if iter == 0 | iter == `iter'
	local xmax = max(abs(r(min)), abs(r(max)))
	local step = 10^(floor(log10(`xmax'))-1)
	foreach f in 1 2 5 10 20 50 {
		if `xmax'/(`step'*`f') <= 5 {
			local step = `step'*`f'
			continue, break
		}
	}
	local xlab
	forvalues j = -5/5 {
		local x = `j'*`step'
		if abs(`x') <= `xmax'*1.05 local xlab `xlab' `x' `"`=string(abs(`x'), "`fmt'")'"'
	}
	local xr = `step'*ceil(`xmax'/`step')

	* Iteraciones intermedias: las que perfilpc_graph dejó en la base (<= 24)
	qui levelsof iter if iter != 0 & iter != `iter', local(its)
	local nits : word count `its'

	* Una variable por serie (missing fuera de su bloque)
	tempvar finH finM ini
	qui gen double `finH' = `v' if iter == `iter' & sexo == 1
	qui gen double `finM' = `v' if iter == `iter' & sexo == 2
	qui gen double `ini'  = `v' if iter == 0
	local plots
	local j = 0
	foreach t of local its {
		local ++j
		tempvar it`j'
		qui gen double `it`j'' = `v' if iter == `t'
		local g = 13 - round(10*`j'/max(`nits',1))
		local plots `plots' (line edad `it`j'', lcolor(gs`g') lwidth(thin) lpattern(solid) cmissing(n))
	}

	* Final (1-2), inicial (3), iteraciones intermedias (4+)
	if "`tipo'" == "bar" {
		* Las barras SÍ llevan `if' (2 sersets más): twoway bar sobre las ~6,000 filas con
		* missing tarda ~27 s; restringido a las 220 filas del perfil final, décimas.
		local final (bar `finH' edad if iter == `iter' & sexo == 1, horizontal barwidth(1) pstyle(p1) lcolor(none)) ///
			(bar `finM' edad if iter == `iter' & sexo == 2, horizontal barwidth(1) pstyle(p2) lcolor(none))
	}
	else {
		local final (line edad `finH', pstyle(p1) lwidth(thick) lpattern(solid) cmissing(n)) ///
			(line edad `finM', pstyle(p2) lwidth(thick) lpattern(solid) cmissing(n))
	}
	local inicial (line edad `ini', lcolor(black) lpattern(dash) lwidth(medthick) cmissing(n))
	local lorder 3 "Inicial: reparto igualitario"
	if `nits' >= 1 local lorder `lorder' 4 `"`=cond(`nint' <= 24, "Iteraciones 1 a `nint'", "Iteraciones intermedias (`nits' de `nint')")'"'
	local lorder `lorder' 1 `"`finlab', H"' 2 "Final, M"

	twoway `final' `inicial' `plots' ///
		, xline(0, lcolor(gs8) lwidth(thin)) ///
		xlabel(`xlab') xscale(range(-`xr' `xr')) ///
		ylabel(0(10)110, angle(0)) yscale(range(0 118)) ytitle("Edad") xtitle("`xtitle'") ///
		text(116 -`xr' "{bf:Hombres}", place(e) size(medium)) ///
		text(116 `xr' "{bf:Mujeres}", place(w) size(medium)) ///
		title(`"`title'"') subtitle("`subtitle'", size(small)) ///
		legend(order(`lorder') cols(2) size(small) symxsize(*.6) position(6)) ///
		xsize(6) ysize(6.4) ///
		name(`gname', replace)
end


mata:
mata set matastrict on

// Redondeo a `sig' cifras significativas, elemento a elemento (0 y missing se conservan)
real colvector perfilpc_sig(real colvector v, real scalar sig)
{
	real colvector r, e, pos
	r   = v
	pos = selectindex((v :> 0) :& (v :< .))
	if (rows(pos)) {
		e      = floor(log10(v[pos]))
		r[pos] = round(v[pos], 10 :^ (e :- (sig - 1)))
	}
	return(r)
}

void perfilpc_fixedpoint(string scalar pcvar,  string scalar hogvar,
                         string scalar nint,   string scalar wvar,
                         string scalar edadvar, string scalar sexovar,
                         string scalar hhvar,  real scalar maxiter,
                         real scalar tol,      real scalar sig, real scalar legacy,
                         string scalar eqvar,  string scalar Pname, string scalar Cname)
{
	real colvector x, hog, ni, w, edad, hh, cell, x2, x2s, xs, sel, selfirst, xprev
	real colvector ph, infoh_id, pc, infoc_id, cell_of_panel, cellsel, ws, num, den, mu, muprev, m, eqs, eq
	real colvector sexon, dif, ok, tot, totprev, itsel
	real matrix    infoh, infoc, P, C, Psub
	real scalar    it, n, j, piso, rel, relL1, xbar, sw, converged
	string colvector sexos

	x    = st_data(., pcvar)                 // copia en memoria: operar sobre un st_view es mucho más lento
	n    = rows(x)
	hog  = st_data(., hogvar)
	ni   = st_data(., nint)
	w    = editmissing(st_data(., wvar), 0)
	edad = st_data(., edadvar)
	hh   = st_data(., hhvar)
	if (st_isstrvar(sexovar)) {
		sexos = st_sdata(., sexovar)
		sexon = editmissing(strtoreal(sexos), 0)
	}
	else sexon = editmissing(st_data(., sexovar), 0)

	// Celda edad-sexo 1..220 (= edad*2 + sexo); 0 = fuera del barrido, como en el forvalues original
	cell = ((edad :< .) :& (edad :>= 0) :& (edad :<= 109) :& ((sexon :== 1) :| (sexon :== 2))) ///
	       :* (edad :* 2 :+ sexon)
	sel      = selectindex(cell :> 0)
	selfirst = selectindex(cell :== 1)          // (edad 0, sexo 1): en legacy ve los ceros como 0

	// Paneles por hogar y por celda, construidos una sola vez vía permutación (no exige sort)
	ph       = order(hh, 1)
	infoh    = panelsetup(hh[ph], 1)
	infoh_id = J(n, 1, .)
	for (j = 1; j <= rows(infoh); j++) infoh_id[|infoh[j,1] \ infoh[j,2]|] = J(infoh[j,2]-infoh[j,1]+1, 1, j)
	pc       = order(cell[sel], 1)
	infoc    = panelsetup(cell[sel][pc], 1)
	infoc_id = J(rows(sel), 1, .)
	for (j = 1; j <= rows(infoc); j++) infoc_id[|infoc[j,1] \ infoc[j,2]|] = J(infoc[j,2]-infoc[j,1]+1, 1, j)
	cell_of_panel = (cell[sel][pc])[infoc[., 1]]
	cellsel  = cell[sel]
	ws       = w[sel][pc]
	sw       = sum(ws)

	// Trayectoria: perfil (medias por celda) tras t = 0..T iteraciones, y convergencia.
	// Por iteración: 2 permutaciones (x[sel][pc], x[ph]) y 3 panelsum; el perfil de
	// x^(t) que se guarda es el mismo num/den que usa la iteración t+1.
	P = J((maxiter+1)*220, 5, .)
	C = J(maxiter, 6, .)
	xs  = x[sel][pc]
	num = panelsum(ws :* xs, infoc)
	den = panelsum(ws :* (xs :< .), infoc)
	muprev  = perfilpc_store(P, 0, num, den, cell_of_panel)
	totprev = editmissing(J(220, 1, .), 0)
	totprev[cell_of_panel] = num

	eq = J(n, 1, .)
	converged = 0
	// Variable idénticamente cero (nada que repartir): una "iteración" trivial y salir
	if (rows(sel) == 0 | max(editmissing(xs, 0)) <= 0) {
		perfilpc_store(P, 1, num, den, cell_of_panel)
		C[1, .] = (1, 0, 0, 0, 0, 0)
		if (eqvar != "") st_store(., eqvar, J(n, 1, 0))
		st_matrix(Pname, P[|1, 1 \ 2*220, 5|])
		st_matrix(Cname, C[|1, 1 \ 1, 6|])
		st_local("niter", "1")
		st_local("converged", "1")
		return
	}
	for (it = 1; it <= maxiter; it++) {
		xprev = x
		// 1) Perfil m_c a partir de las medias por celda de x^(t-1)
		if (legacy) {
			// ceros como .01 salvo en la primera celda (artefacto del bloque original)
			x2 = x :+ (x :== 0) * .01
			if (rows(selfirst)) x2[selfirst] = x[selfirst]
			x2s = x2[sel][pc]
			m   = J(220, 1, 0)
			m[cell_of_panel] = (den :> 0) :* round(editmissing(panelsum(ws :* x2s, infoc) :/ den, 0), .01)
			piso = .01
		}
		else {
			m   = J(220, 1, 0)
			m[cell_of_panel] = (den :> 0) :* editmissing(num :/ den, 0)
			m    = perfilpc_sig(m, sig)
			piso = 10^(-sig) * max(m)         // lo que a sig cifras es cero; evita Σm = 0
			m = m :+ (m :< piso) :* (piso :- m)
		}
		// 2) Asignar la media de su celda; piso en todas las filas
		x[sel] = m[cellsel]
		x      = x :+ (x :== 0) * piso
		// 3) Equivalencias por hogar y reparto del gasto del hogar
		eqs    = panelsum(x[ph], infoh)
		eq[ph] = eqs[infoh_id]
		x      = hog :* ni :* x :/ eq
		// 4) Perfil de x^(t), registro y criterio de paro.
		//    relL1 = Σ_c |Δ(Σ_{i∈c} w_i x_i)| / Σ_i w_i x_i : fracción del gasto total que
		//    cambió de celda edad-sexo en esta iteración (criterio de paro, adimensional).
		//    rel   = máx_c |Δμ_c| / μ_c : cambio relativo máximo por celda (informativo; lo
		//    dominan celdas con poca población o medias que tienden a cero).
		xs  = x[sel][pc]
		num = panelsum(ws :* xs, infoc)
		den = panelsum(ws :* (xs :< .), infoc)
		mu  = perfilpc_store(P, it, num, den, cell_of_panel)
		tot = J(220, 1, 0)
		tot[cell_of_panel] = num
		relL1 = sum(tot) > 0 ? sum(abs(tot :- totprev)) / sum(tot) : 0
		ok  = selectindex((muprev :> 0) :& (muprev :< .) :& (mu :< .))
		rel = rows(ok) ? max(abs(mu[ok] :- muprev[ok]) :/ muprev[ok]) : 0
		dif  = abs(x :- xprev)
		xbar = sw > 0 ? sum(ws :* xs) / sw : .
		C[it, .] = (it, max(dif), mean(dif), rel, relL1, xbar)
		muprev  = mu
		totprev = tot
		if (!legacy & relL1 <= tol) {
			converged = 1
			break
		}
	}
	if (it > maxiter) it = maxiter
	if (legacy) converged = 1
	st_store(., pcvar, x)
	if (eqvar != "") st_store(., eqvar, eq)
	// r(perfil): iteración 0, la final y hasta 24 intermedias espaciadas (pasar la
	// trayectoria completa como matriz de Stata —50 mil filas— tardaba más que iterar)
	if (it - 1 <= 24) itsel = 0::it
	else itsel = uniqrows(0 \ round(1 :+ (0::23) :* (it-2)/23) \ it)
	Psub = J(rows(itsel)*220, 5, .)
	for (j = 1; j <= rows(itsel); j++) {
		Psub[|(j-1)*220+1, 1 \ j*220, 5|] = P[|itsel[j]*220+1, 1 \ (itsel[j]+1)*220, 5|]
	}
	st_matrix(Pname, Psub)
	st_matrix(Cname, C[|1, 1 \ it, 6|])
	st_local("niter", strofreal(it))
	st_local("converged", strofreal(converged))
}

// Perfil tras t iteraciones a partir de num = Σ w·x y den = Σ w por celda (missing si
// la celda no tiene datos): media ponderada per cápita y gasto total ponderado.
// Devuelve el vector de medias (220).
real colvector perfilpc_store(real matrix P, real scalar t, real colvector num,
                              real colvector den, real colvector cell_of_panel)
{
	real colvector m, tot, c
	real scalar    i0

	m   = J(220, 1, .)
	tot = J(220, 1, .)
	m[cell_of_panel]   = num :/ den    // den = 0 -> missing
	tot[cell_of_panel] = num
	c  = (1::220)
	i0 = t*220
	P[|i0+1, 1 \ i0+220, 5|] = (J(220, 1, t), floor((c :- 1) :/ 2), 2 :- mod(c, 2), m, tot)
	return(m)
}
end
