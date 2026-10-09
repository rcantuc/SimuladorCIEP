*! nl-fedq-html.do  v1.0.0 — segunda inyección del endpoint Federación↔NL: el JSON hermano de quintiles (NL-0.6.0, sesión C2)
*
* Sustituye la marca /*__NLFEDQ_DATA__*/ de users/$id/nodos/federacion-nl.html (ya generado por FederacionNL.do §7 desde la
* plantilla) por users/$id/nodos/federacion-nl-quintiles.json (FederacionNLQuintiles.do), en el mismo archivo, inline, sin red.
* Corre DESPUÉS de FederacionNL.do y de FederacionNLQuintiles.do, en la misma máquina y la misma corrida.
*
* NO está enganchado a actualizar-nl.do ni a publicar-conl.sh: el enganche es de la fase de publicación deliberada (decisión
* de Ricardo). Mientras tanto, la compuerta de publicación aborta si la marca sigue en el HTML (es la plantilla, no el endpoint).
*
* Compuertas (abortan sin tocar el HTML):
*   H1 existen el HTML, el JSON hermano y el contrato base federacion-nl.json;
*   H2 el JSON hermano declara contrato_base.generado_en = procedencia.generado_en del contrato base y la misma capa / motor;
*   H3 contrato_base.sha256 = SHA-256 del federacion-nl.json en disco (shasum en Mac/Unix; certutil en Windows, no probado);
*   H4 el HTML trae exactamente UNA marca /*__NLFEDQ_DATA__*/ y, después de inyectar, ninguna marca /*__NL…__*/.
* Toda lectura de archivos es en Mata (nl-html.do v1.2.0): ningún $ ni acento grave del JSON se expande como macro.
* Uso:  do "${SIMROOT}/01_modulos/nl-assets/nl-fedq-html.do"      (requiere $id; usa ${SIMROOT} como raíz)
capture noisily {
	local site `"${SIMROOT}"'
	if `"`site'"' == "" {
		di as err "nl-fedq-html: falta la macro global SIMROOT (raíz del repositorio)."
		exit 198
	}
	local html  `"`site'/users/$id/nodos/federacion-nl.html"'
	local jsonq `"`site'/users/$id/nodos/federacion-nl-quintiles.json"'
	local jsonb `"`site'/users/$id/nodos/federacion-nl.json"'
	foreach f in html jsonq jsonb {
		capture confirm file `"``f''"'
		if _rc {
			di as err `"nl-fedq-html (H1): falta ``f''. No se inyecta."'
			exit 601
		}
	}
	run `"`site'/01_modulos/nl-assets/nl-html.do"'

	*** H2 identidad: contrato_base del hermano vs procedencia del contrato base ***
	mata: nlhtml_grep1(st_local("jsonq"), `""contrato_base": *\{"', `""generado_en": *"([^"]+)""', "q_gen")
	mata: nlhtml_grep1(st_local("jsonq"), `""contrato_base": *\{"', `""sha256": *"([a-f0-9]+)""', "q_sha")
	mata: nlhtml_grep1(st_local("jsonq"), `""procedencia": *\{"', `""version_capa_nl": *"([^"]+)""', "q_capa")
	mata: nlhtml_grep1(st_local("jsonq"), `""procedencia": *\{"', `""version_motor": *"([^"]+)""', "q_motor")
	mata: nlhtml_grep1(st_local("jsonb"), `""procedencia": *\{"', `""generado_en": *"([^"]+)""', "b_gen")
	mata: nlhtml_grep1(st_local("jsonb"), `""procedencia": *\{"', `""version_capa_nl": *"([^"]+)""', "b_capa")
	mata: nlhtml_grep1(st_local("jsonb"), `""procedencia": *\{"', `""version_motor": *"([^"]+)""', "b_motor")
	if `"`q_gen'"' == "" | `"`q_sha'"' == "" | `"`b_gen'"' == "" | `"`q_capa'"' == "" | `"`b_capa'"' == "" {
		di as err "nl-fedq-html (H2): no pude leer contrato_base.generado_en / sha256 del JSON hermano o procedencia del contrato base."
		exit 459
	}
	if `"`q_gen'"' != `"`b_gen'"' | `"`q_capa'"' != `"`b_capa'"' | `"`q_motor'"' != `"`b_motor'"' {
		di as err `"nl-fedq-html (H2): el JSON hermano se calculó con el contrato base generado `q_gen' (capa `q_capa', motor `q_motor'); el contrato base en disco es `b_gen' (capa `b_capa', motor `b_motor'). Re-corre FederacionNLQuintiles.do. No se inyecta."'
		exit 459
	}

	*** H3 SHA-256 del contrato base en disco = contrato_base.sha256 ***
	tempfile shaout
	if "`c(os)'" == "Windows" {
		quietly shell certutil -hashfile "`jsonb'" SHA256 > "`shaout'"
	}
	else {
		quietly shell shasum -a 256 "`jsonb'" > "`shaout'"
	}
	mata: nlhtml_grep1(st_local("shaout"), "", "^ *([a-fA-F0-9][a-fA-F0-9 ]*[a-fA-F0-9])", "b_sha")
	local b_sha = lower(subinstr("`b_sha'", " ", "", .))
	if strlen("`b_sha'") != 64 {
		di as err "nl-fedq-html (H3): no pude calcular el SHA-256 de federacion-nl.json (shasum / certutil no disponible o salida inesperada). No se inyecta."
		exit 459
	}
	if "`b_sha'" != "`q_sha'" {
		di as err `"nl-fedq-html (H3): contrato_base.sha256 del hermano (`q_sha') ≠ SHA-256 de federacion-nl.json en disco (`b_sha'). No se inyecta."'
		exit 459
	}

	*** H4 inyección en el mismo archivo: exactamente una marca antes, ninguna después ***
	mata: nlhtml_inject_marca(st_local("html"), st_local("jsonq"), "/*__NLFEDQ_DATA__*/")
	if r(hits) != 1 {
		di as err "nl-fedq-html (H4): el HTML debe traer exactamente una marca /*__NLFEDQ_DATA__*/ (encontradas: `r(hits)'). Si es 0, el HTML salió de una plantilla sin la vista por quintil o ya fue inyectado."
		exit 459
	}
	mata: nlhtml_marcas(st_local("html"))
	if r(marcas) != 0 {
		di as err "nl-fedq-html (H4): tras inyectar quedan `r(marcas)' marca(s) /*__NL…__*/ en el HTML."
		exit 459
	}
	quietly checksum `"`html'"'
	local kb = string(r(filelen)/1024, "%9.0fc")
	noisily di as txt "{bf:nl-fedq-html: listo.} " as res `"`html'"' as txt " (`kb' KB) · quintiles del contrato base generado `b_gen' (sha256 `=substr("`b_sha'", 1, 12)'…), capa `b_capa', motor `b_motor'."
}
if _rc exit _rc
