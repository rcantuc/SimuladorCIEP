*! version 8.15.1 CIEP 31oct2026
* version, data_updated y baseline de ${SIMROOT}/05_scripts/manifest.json (sin parser
* JSON: tres claves de primer nivel con formato fijo  "clave": "valor").
*
* Hotfix fix/precache-manifest (2026-10-31, sobre e47a7af): el manifest trae textos
* libres (*_regla, assets.<id>.regla) con acentos graves, comillas simples y
* paréntesis. La versión 8.12 pasaba CADA línea por regexm(`"`linea'"', ...): Stata
* expandía el texto libre como macro dentro de las comillas compuestas y abortaba
* con r(132) «too few quotes» (línea «`desde` = version en que entra a la Release»
* de assets.scn-congelado-2024.zip.regla, v8.15b E4). Regla desde 8.15.1:
*   1. ninguna línea del manifest pasa por una macro de Stata: Mata la lee (fget),
*      la recorta y la compara como cadena; ni macval() basta cuando el texto trae
*      la secuencia `"' (lo vigila el caso A de 05_scripts/test-precache-manifest.sh);
*   2. solo se evalúa una línea cuyo inicio (sin blancos) sea "version",
*      "data_updated" o "baseline" (la clave entre comillas: "version_regla" y
*      "baseline_regla" no califican); las demás líneas no se tocan;
*   3. la primera aparición de cada clave manda (las tres son de primer nivel y
*      van al principio del archivo; una "version" anidada en assets no cuenta);
*   4. los valores vuelven a Stata con st_local() y se devuelven con macval().
* Regresión: 05_scripts/test-precache-manifest.sh (requiere Stata; no va en --ci).
program define _precache_manifest, rclass
	version 17
	local m `"${SIMROOT}/05_scripts/manifest.json"'
	capture confirm file `"`m'"'
	if _rc {
		di as err `"Precache: no existe `m' (data_updated del deployment)."'
		exit 601
	}
	local claves version data_updated baseline
	foreach k of local claves {
		local `k' ""
	}
	mata: _precache_lee_manifest(st_local("m"), tokens(st_local("claves")))
	foreach k of local claves {
		return local `k' `"`macval(`k')'"'
	}
end

mata:
void _precache_lee_manifest(string scalar m, string rowvector claves)
{
	real scalar fh, i
	string scalar linea, t, q, k, re
	q = char(34)
	fh = fopen(m, "r")
	while ((linea = fget(fh)) != J(0, 0, "")) {
		t = strtrim(linea)
		for (i = 1; i <= cols(claves); i++) {
			k = claves[i]
			if (substr(t, 1, strlen(k) + 2) != q + k + q) continue   // inicio: "clave" (con comillas)
			if (st_local(k) != "") continue                            // la primera aparición manda
			re = "^" + q + k + q + "[ " + char(9) + "]*:[ " + char(9) + "]*" + q + "([^" + q + "]*)" + q
			if (regexm(t, re)) st_local(k, regexs(1))
		}
	}
	fclose(fh)
}
end
