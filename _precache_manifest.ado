*! version 8.12 CIEP 18oct2026
* version y data_updated de ${SIMROOT}/05_scripts/manifest.json (sin parser JSON:
* dos claves de primer nivel con formato fijo)
program define _precache_manifest, rclass
	version 17
	local m `"${SIMROOT}/05_scripts/manifest.json"'
	capture confirm file `"`m'"'
	if _rc {
		di as err `"Precache: no existe `m' (data_updated del deployment)."'
		exit 601
	}
	tempname fh
	file open `fh' using `"`m'"', read text
	file read `fh' linea
	while r(eof) == 0 {
		foreach k in version data_updated {
			if regexm(`"`linea'"', `"^[ 	]*"`k'"[ 	]*:[ 	]*"([^"]*)""') local `k' = regexs(1)
		}
		file read `fh' linea
	}
	file close `fh'
	return local version "`version'"
	return local data_updated "`data_updated'"
end
