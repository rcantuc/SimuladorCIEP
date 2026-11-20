*! Distribucion v1.0 — imputación macro-micro proporcional a un relativo (el único mecanismo de imputación del motor)
*
* Sintaxis:  Distribucion newvar [if], RELativo(varname) MACro(real)
*   Crea (o reemplaza, si ya existe) newvar = relativo * macro / Σ_[fw=factor] relativo, de modo que
*   Σ_[fw=factor] newvar = macro exactamente (en el total; cada persona recibe la parte proporcional a su
*   relativo). Requiere la variable factor en memoria (peso de la suma). Con [if], el total se reparte
*   solo entre las observaciones seleccionadas y newvar queda missing fuera de ellas.
*   Es per cápita solo cuando relativo(pob); con relativo(factor) reparte ∝ al factor de expansión de cada
*   persona (nta-0-inventario §1); con relativo(gas_pc_X) sigue el reparto intra-hogar de perfilpc.ado.
*   NO calcula desigualdad: la descripción «Gini/Theil» que 03_help/PROGRAMAS_AUXILIARES.md §3 tuvo hasta
*   v8.13 describía un programa que nunca existió (corregida en v8.14; Gini vive en Gini.ado).
* Usuarios: Households.do (anclas SCN/LIF: ImpNetProductos_*, gasto_anualGobierno, ing_capitalROW, ISAN,
*   Importaciones…), PerfilesSim.do (re-ancla a LIF/PEF/SCN del año PE), ISR_Mod.do, NTA.do, GastoPC.ado,
*   TasasEfectivas.ado, TasasEfectivasMicro.ado. No forma parte del paquete público (manifest-endpoint.toml):
*   ningún .pkg lo lista porque ningún .ado publicado lo invoca.
* Decisión v8.14 (DoD 4, «gemelo»): el único gemelo encontrado es documental (la ayuda de PROGRAMAS_AUXILIARES.md)
*   más una copia idéntica sin versionar en .devin/backups/; el .ado no se retira (siete módulos dependen de él),
*   se documenta aquí y en la ayuda.
program Distribucion, return
	syntax anything [if], RELativo(varname) MACro(real)

	tabstat `relativo' `if' [fw=factor], stat(sum) f(%20.0fc) save
	tempname SumaVar
	matrix `SumaVar' = r(StatTotal)

	capture confirm variable `anything'
	if _rc == 0 {
		tempvar `relativo'
		g double ``relativo'' = `anything'
		drop `anything'
		g double `anything' = ``relativo''*`macro'/`SumaVar'[1,1] `if'
	}
	else {
		g double `anything' = `relativo'*`macro'/`SumaVar'[1,1] `if'
	}
end
