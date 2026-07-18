*! version 1.0.0  Registrador central de escalares para scalarlatex (v8.0.12)
*
* Sintaxis:   escalar <tipo> <nombre> = <expresion>
*
*   <tipo>    pctpib    % del PIB                 -> %7.3fc  al exportar
*             pct       % de un total / tasas     -> %7.1fc
*             mxn       pesos (se exporta /1e6)   -> %12.1fc
*             mxnpc     pesos per capita          -> %10.0fc
*             personas  conteos de poblacion      -> %15.0fc
*             anio      anios                     -> %4.0f
*             custom(%fmt)  EXCEPCION documentada, no puerta trasera:
*                           solo cuando el valor de verdad no cabe en el
*                           catalogo; comentar el porque en el call site.
*
* Guarda el escalar NUMERICO con precision completa (scalar <nombre> = <exp>;
* los computos aguas abajo lo usan directo, jamas releen strings) y registra
* nombre:tipo en la global $scalarlatex_reg — metadato EN MEMORIA, paralelo a
* los escalares, con su mismo ciclo de vida (clear all / macro drop _all borran
* ambos a la par). El registro es GLOBAL-ACUMULADO por contrato (ver
* 02_governance/arquitectura-y-bitacoras.md): el libro consume escalares de un
* modulo desde el .tex de otro. El formato se aplica UNA sola vez, en
* scalarlatex, al escribir el .tex.
*
* Re-registro del mismo nombre: se apendiza y en scalarlatex gana la ULTIMA
* entrada (last wins) — re-correr un modulo actualiza valor y tipo sin limpiar.

program define escalar
	version 14

	gettoken tipo 0 : 0, parse(" ")
	local fmt ""
	if regexm(`"`tipo'"', "^custom\((%.+)\)$") {
		local fmt = regexs(1)
		local tipo "custom"
	}
	else if !inlist("`tipo'", "pctpib", "pct", "mxn", "mxnpc", "personas", "anio") {
		di as err `"escalar: tipo invalido "`tipo'". Catalogo: pctpib pct mxn mxnpc personas anio custom(%fmt)"'
		exit 198
	}

	gettoken name 0 : 0, parse(" =")
	confirm name `name'
	gettoken eq 0 : 0, parse(" =")
	if `"`eq'"' != "=" {
		di as err "escalar: falta el signo = (sintaxis: escalar <tipo> <nombre> = <expresion>)"
		exit 198
	}

	* Valor numerico de precision completa: esta es la fuente para computos
	scalar `name' = `0'

	* Metadato nombre:tipo (custom lleva su formato: nombre:custom:%fmt)
	if "`tipo'" == "custom" {
		global scalarlatex_reg "$scalarlatex_reg `name':custom:`fmt'"
	}
	else {
		global scalarlatex_reg "$scalarlatex_reg `name':`tipo'"
	}
end
