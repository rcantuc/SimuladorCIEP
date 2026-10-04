*! nl-html.do  v1.0.0 — construcción de los HTML autocontenidos de la capa NL (NL-0.3.0)
*
* Define en Mata nlhtml_inject(): copia la plantilla línea a línea y sustituye
*   /*__<MARCA>_DATA__*/  por el JSON de datos del driver, y
*   /*__NL_DATOS_JS__*/    por nl-assets/nl-datos.js (componente "modo datos").
* El resultado es UN archivo, inline, sin red. Cada marca debe aparecer
* exactamente una vez (r(hits_data), r(hits_js)); el driver aborta si no.
* Mata no expande macros: el contenido de la plantilla/JSON/JS pasa intacto.
* Uso:  run "${SIMROOT}/01_modulos/nl-assets/nl-html.do"
*       mata: nlhtml_inject(tpl, json, js, out, "/*__NLPOB_DATA__*/")
capture mata: mata drop nlhtml_inject()
mata:
void nlhtml_inject(string scalar tpl, string scalar json, string scalar js, string scalar out, string scalar marca)
{
	real scalar fi, fo, fj, hd, hj
	string scalar line, l2
	fi = fopen(tpl, "r")
	unlink(out)
	fo = fopen(out, "w")
	hd = 0
	hj = 0
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
		else fput(fo, line)
	}
	fclose(fi)
	fclose(fo)
	st_numscalar("r(hits_data)", hd)
	st_numscalar("r(hits_js)", hj)
}
end
