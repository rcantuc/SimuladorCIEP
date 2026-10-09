*! nl-html.do  v1.2.0 — construcción de los HTML autocontenidos de la capa NL (NL-0.4.1; v1.2.0 NL-0.6.0: segunda inyección)
*
* Define en Mata nlhtml_inject(): copia la plantilla línea a línea y sustituye
*   /*__<MARCA>_DATA__*/      por el JSON de datos del driver,
*   /*__NL_DATOS_JS__*/        por nl-assets/nl-datos.js (modo datos + NLEstilo), y
*   /*__NL_ESTILO_ASSETS__*/   por nl-assets/nl-estilo-assets.js (fuentes OFL y logo CoNL
*                              como data: URI; generado por nl-estilo-build.py).
* El resultado es UN archivo, inline, sin red. Cada marca debe aparecer
* exactamente una vez (r(hits_data), r(hits_js), r(hits_assets)); el driver aborta si no.
* Mata no expande macros: el contenido de la plantilla/JSON/JS pasa intacto.
* Uso:  run "${SIMROOT}/01_modulos/nl-assets/nl-html.do"
*       mata: nlhtml_inject(tpl, json, js, out, "/*__NLPOB_DATA__*/", assets)
*
* v1.2.0 (NL-0.6.0): un endpoint puede llevar un SEGUNDO JSON (contrato hermano) en otra marca, inyectado por un paso
* posterior sobre el HTML ya generado (nl-fedq-html.do: /*__NLFEDQ_DATA__*/ ← federacion-nl-quintiles.json):
*   nlhtml_inject_marca(html, json, marca)  sustituye, en el mismo archivo, la línea que es exactamente la marca por el JSON;
*                                           r(hits) = veces que apareció la marca (solo escribe si es exactamente 1).
*   nlhtml_marcas(html)                     r(marcas) = líneas que conservan una marca /*__NL…__*/ (la compuerta de
*                                           publicación exige 0).
*   nlhtml_grep1(file, inicio, patron, nombre) guarda en el local `nombre' el primer grupo del primer renglón que casa
*                                           `patron', buscando desde el renglón que casa `inicio' (inclusive; desde el
*                                           principio si inicio == ""); lectura en Mata: ningún $ ni acento grave se expande.
capture mata: mata drop nlhtml_inject()
capture mata: mata drop nlhtml_inject_marca()
capture mata: mata drop nlhtml_marcas()
capture mata: mata drop nlhtml_grep1()
mata:
void nlhtml_inject(string scalar tpl, string scalar json, string scalar js, string scalar out, string scalar marca, string scalar assets)
{
	real scalar fi, fo, fj, hd, hj, ha
	string scalar line, l2
	fi = fopen(tpl, "r")
	unlink(out)
	fo = fopen(out, "w")
	hd = 0
	hj = 0
	ha = 0
	while ((line = fget(fi)) != J(0, 0, "")) {
		if (strtrim(line) == marca) {
			hd++
			fj = fopen(json, "r")
			while ((l2 = fget(fj)) != J(0, 0, "")) fput(fo, l2)
			fclose(fj)
		}
		else if (strtrim(line) == "/*__NL_DATOS_JS__*/") {
			hj++
			fj = fopen(js, "r")
			while ((l2 = fget(fj)) != J(0, 0, "")) fput(fo, l2)
			fclose(fj)
		}
		else if (strtrim(line) == "/*__NL_ESTILO_ASSETS__*/") {
			ha++
			fj = fopen(assets, "r")
			while ((l2 = fget(fj)) != J(0, 0, "")) fput(fo, l2)
			fclose(fj)
		}
		else fput(fo, line)
	}
	fclose(fi)
	fclose(fo)
	st_numscalar("r(hits_data)", hd)
	st_numscalar("r(hits_js)", hj)
	st_numscalar("r(hits_assets)", ha)
}
void nlhtml_inject_marca(string scalar html, string scalar json, string scalar marca)
{
	real scalar fi, fo, fj, n, i, h
	string scalar line, l2
	string colvector L
	fi = fopen(html, "r")
	L = J(0, 1, "")
	while ((line = fget(fi)) != J(0, 0, "")) L = L \ line
	fclose(fi)
	n = rows(L)
	h = 0
	for (i = 1; i <= n; i++) if (strtrim(L[i]) == marca) h++
	if (h == 1) {
		unlink(html)
		fo = fopen(html, "w")
		for (i = 1; i <= n; i++) {
			if (strtrim(L[i]) == marca) {
				fj = fopen(json, "r")
				while ((l2 = fget(fj)) != J(0, 0, "")) fput(fo, l2)
				fclose(fj)
			}
			else fput(fo, L[i])
		}
		fclose(fo)
	}
	st_numscalar("r(hits)", h)
}
void nlhtml_marcas(string scalar html)
{
	real scalar fi, m
	string scalar line
	fi = fopen(html, "r")
	m = 0
	while ((line = fget(fi)) != J(0, 0, "")) if (regexm(line, "/\*__NL[A-Z_]*__\*/")) m++
	fclose(fi)
	st_numscalar("r(marcas)", m)
}
void nlhtml_grep1(string scalar file, string scalar inicio, string scalar patron, string scalar nombre)
{
	real scalar fi, activo
	string scalar line, res
	fi = fopen(file, "r")
	activo = (inicio == "")
	res = ""
	while ((line = fget(fi)) != J(0, 0, "")) {
		if (!activo) {
			if (regexm(line, inicio)) activo = 1
			else continue
		}
		if (regexm(line, patron)) {
			res = regexs(1)
			break
		}
	}
	fclose(fi)
	st_local(nombre, res)
}
end
