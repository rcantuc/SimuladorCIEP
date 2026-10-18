*! version 8.12 CIEP 18oct2026
* _precache_usa — consumidor del cache de lo invariante (v8.12 fase 2a).
*
* El flujo web «Calcular» recalculaba en cada clic piezas que no dependen del
* formulario (PEF histórico sobre 3.56 M filas, base de hogares de GastoPC,
* colapsos de los *RECprom). Precache.ado las precomputa UNA vez por corrida batch
* y las guarda en users/<id>/cache/ con un sello; este programa las entrega al
* consumidor (PEF, GastoPC, FiscalGap) o aborta con la receta. Misma regla que
* los *RECprom (_FGrecprom): sin fallback silencioso — nunca "usa lo que haya".
*
*   _precache_usa <item>
*     r(fn)     ruta del .dta del item      r(fn_mat)  ruta del _mat.dta (si existe)
*     r(dir)    carpeta del cache           r(sello_*) version, data_updated, commit, generado
*
* Convención (ver Precache.ado): users/<idbase>/cache/<item>.dta, sello en
* users/<idbase>/cache/sello.txt (tab-separado; líneas sello/item/insumo).
* Candado de frescura: (1) existe el sello y el item; (2) el data_updated del
* sello == el de 05_scripts/manifest.json de ESTE SIMROOT (los datos no cambiaron
* sin regenerar el cache); (3) cada insumo del item existe y tiene los MISMOS
* bytes que cuando se generó (un master/PEF.dta o un *RECprom.dta regenerados
* sin volver a correr Precache caducan el cache). mtime se registra pero no se
* exige (rsync/cp pueden no conservarlo). El cache guarda unidades CRUDAS
* (pesos, conteos): la conversión a % PIB con pibY/deflator (que sí depende de
* CRECPIB/CRECDEF) sigue en tiempo de ejecución (FLAG-1 del perfil 2026-10-18).
program define _precache_usa, rclass
	version 17
	args item
	if "`item'" == "" {
		di as err "_precache_usa: falta el nombre del item"
		exit 198
	}
	local idbase = cond("$idbase" != "", "$idbase", "$id")
	local dir `"${SIMROOT}/users/`idbase'/cache"'
	local sello `"`dir'/sello.txt"'
	local receta `"  Corre SIM.do (§5.1b: Precache) con id `idbase' — o, en una sesión con master/ y users/`idbase'/bootstraps/ ya hechos, {stata Precache}. Sin cache no se calcula: el flujo web exige el mismo producto que el batch."'
	capture confirm file `"`sello'"'
	if _rc {
		di as err `"Precache: no existe `sello' (cache de lo invariante, v8.12)."'
		di as err `"`receta'"'
		exit 601
	}

	* --- leer el sello (Mata: tab-separado) ---
	local fn ""
	local n_ins = 0
	foreach k in version data_updated commit generado id {
		local sello_`k' ""
	}
	mata: _precache_lee_sello(st_local("sello"), st_local("item"), st_local("dir"))

	if `"`fn'"' == "" {
		di as err `"Precache: el item `item' no está en `sello' (cache generado el `sello_generado', versión `sello_version')."'
		di as err `"`receta'"'
		exit 601
	}
	capture confirm file `"`fn'"'
	if _rc {
		di as err `"Precache: falta el archivo del item `item': `fn'"'
		di as err `"`receta'"'
		exit 601
	}

	* --- candado 2: data_updated del manifest de este SIMROOT ---
	_precache_manifest
	if "`r(data_updated)'" != "`sello_data_updated'" {
		di as err `"Precache: el cache se generó con data_updated = `sello_data_updated' y 05_scripts/manifest.json dice `r(data_updated)': los datos cambiaron sin regenerar el cache."'
		di as err `"`receta'"'
		exit 601
	}

	* --- candado 3: insumos con los mismos bytes ---
	forvalues i = 1/`n_ins' {
		local ruta `"${SIMROOT}/`ins_ruta`i''"'
		capture confirm file `"`ruta'"'
		if _rc {
			di as err `"Precache: el insumo `ins_ruta`i'' del item `item' ya no existe."'
			di as err `"`receta'"'
			exit 601
		}
		_precache_bytes `"`ruta'"'
		if "`r(bytes)'" != "`ins_bytes`i''" {
			di as err `"Precache: el insumo `ins_ruta`i'' cambió (`r(bytes)' bytes hoy, `ins_bytes`i'' cuando se generó el cache el `sello_generado'): el item `item' caducó."'
			di as err `"`receta'"'
			exit 601
		}
	}

	return local fn `"`fn'"'
	capture confirm file `"`dir'/`item'_mat.dta"'
	if _rc == 0 return local fn_mat `"`dir'/`item'_mat.dta"'
	return local dir `"`dir'"'
	foreach k in version data_updated commit generado id {
		return local sello_`k' `"`sello_`k''"'
	}
end

mata:
void _precache_lee_sello(string scalar sello, string scalar item, string scalar dir)
{
	real scalar fh, n
	string scalar linea
	string rowvector c
	fh = fopen(sello, "r")
	n = 0
	while ((linea = fget(fh)) != J(0, 0, "")) {
		c = tokens(linea, char(9))
		c = select(c, c :!= char(9))
		if (cols(c) < 3) continue
		if (c[1] == "sello") st_local("sello_" + c[2], strtrim(c[3]))
		else if (c[1] == "item" & c[2] == item) st_local("fn", dir + "/" + strtrim(c[3]))
		else if (c[1] == "insumo" & c[2] == item & cols(c) >= 4) {
			n++
			st_local("n_ins", strofreal(n))
			st_local("ins_ruta" + strofreal(n), strtrim(c[3]))
			st_local("ins_bytes" + strofreal(n), strtrim(c[4]))
		}
	}
	fclose(fh)
}

end
