	************************
	*** 2 Datos Abiertos ***
	************************
	if "`by'" == "desc_funcion" {
		rename serie serielabel
		decode serielabel, g(serie)
		local varSerie "serie"
	}
		
	if "`by'" == "desc_funcion" & "`datosabiertos'" == "datosabiertos" {
		collapse (sum) gasto* aprobado* ejercido* proyecto* `if', by(`by' anio neto `varSerie') fast

		preserve

		levelsof serie, local(serie)
		foreach k of local serie {
			quietly DatosAbiertos `k', nographs

			rename clave_de_concepto serie
			keep anio serie nombre monto mes

			tempfile `k'
			quietly save ``k''
		}

		restore
		
		foreach k of local serie {
			joinby (anio serie) using ``k'', unmatched(both) update
			drop _merge
		}

		* Distribucion bycollapse **
		tempvar bycollapse
		egen `bycollapse' = sum(aprobado), by(`varSerie' anio neto)

		replace gasto = monto*aprobado/`bycollapse' if mes == 12 & (ejercido == . | ejercido == 0) & monto != . & neto == 0
		replace gastoneto = gasto if mes == 12 & (ejercido == . | ejercido == 0) & monto != . & neto == 0
		drop if desc_funcion == . & (monto < 1 | monto == .)

		sort anio desc_funcion
		forvalues k=`=_N'(-1)1 {
			if mes[`k'] != . {
				local textmes = "(mes `=mes[`k']')"
				continue, break
			}
		}
	}
