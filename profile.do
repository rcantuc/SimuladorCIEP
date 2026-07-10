*********************
***               ***
*** 1 Estilo CIEP ***
***               ***
*********************
set scheme ciep
graph set window fontface "Ubuntu Light"
set more off, permanently
set type double, permanently
set charset latin1, permanently



*******************************
***                         ***
*** 1.5 VERSIÓN Y CAMBIOS   ***
***                         ***
*******************************
quietly {
	python:
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from sfi import Macro

def _emit(name, value):
	Macro.setLocal(name, str(value))

_emit("sim_version", "")
_emit("sim_release_tag", "")
_emit("sim_generated_at", "")
_emit("sim_previous_version", "")
_emit("sim_mode", "silent")

try:
	site_dir = Path(r"""`c(sysdir_site)'""".strip())
	manifest_path = site_dir / "05_scripts" / "manifest.json"
	changelog_path = site_dir / "02_governance" / "CHANGELOG.md"
	username = os.environ.get("USER", "unknown")
	user_dir = site_dir / "users" / username
	user_dir.mkdir(parents=True, exist_ok=True)
	state_path = user_dir / ".simulador_state"

	if not manifest_path.exists():
		raise FileNotFoundError("manifest.json no está en la Carpeta del Simulador")

	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	sim_version = manifest.get("version", "")
	sim_release_tag = manifest.get("release_tag", "")
	sim_generated_at = manifest.get("generated_at", "")

	_emit("sim_version", sim_version)
	_emit("sim_release_tag", sim_release_tag)
	_emit("sim_generated_at", sim_generated_at)

	previous_version = ""
	if state_path.exists():
		state_content = state_path.read_text(encoding="utf-8")
		match = re.search(r"^version=(.+)$", state_content, re.MULTILINE)
		if match:
			previous_version = match.group(1).strip()

	_emit("sim_previous_version", previous_version)

	if not previous_version:
		mode = "welcome"
	elif previous_version != sim_version:
		mode = "update"
	else:
		mode = "silent"

	_emit("sim_mode", mode)

	if mode in ("welcome", "update") and changelog_path.exists():
		changelog_text = changelog_path.read_text(encoding="utf-8")
		nl = chr(10)
		# Parsear todas las entradas ## [vX.Y.Z] del CHANGELOG en orden de aparición
		version_header_re = re.compile(r"^## " + chr(92) + "[(v[^" + chr(92) + "]]+)" + chr(92) + "][^" + nl + "]*" + nl, re.MULTILINE)
		all_matches = list(version_header_re.finditer(changelog_text))
		# Cada entry: (version_str, header_line, body_start_pos, body_end_pos)
		entries = []
		for idx, m in enumerate(all_matches):
			ver = m.group(1)
			header_line = m.group(0).strip()
			body_start = m.end()
			body_end = all_matches[idx + 1].start() if idx + 1 < len(all_matches) else len(changelog_text)
			entries.append((ver, header_line, body_start, body_end))
		# Filtrar: acumular entradas entre previous_version (exclusivo) y sim_version (inclusivo)
		# En welcome mode: solo la entrada de sim_version.
		# En update mode: todas las que están arriba (más nuevas) hasta previous_version.
		selected = []
		if mode == "welcome":
			for ver, header, s, e in entries:
				if ver == sim_version:
					selected.append((ver, header, s, e))
					break
		else:
			# mode == update: acumular desde el tope hasta encontrar previous_version
			for ver, header, s, e in entries:
				if ver == previous_version:
					break
				selected.append((ver, header, s, e))
		# Renderizar líneas con sanitización de Markdown y separador entre versiones
		display_lines = []
		max_lines = 100
		for ver, header, s, e in selected:
			if len(display_lines) >= max_lines:
				break
			# Header de versión (siempre, aunque haya varias)
			display_lines.append("")
			display_lines.append("{bf:" + header.replace("## ", "").replace("`", "") + "}")
			body = changelog_text[s:e].strip()
			body_lines = [ln.strip() for ln in body.splitlines() if ln.strip()]
			for ln in body_lines:
				if len(display_lines) >= max_lines:
					break
				clean = ln
				is_header = False
				if clean.startswith("### "):
					clean = clean[4:].upper()
					is_header = True
				elif clean.startswith("## "):
					clean = clean[3:]
					is_header = True
				clean = re.sub(r"\*\*(.+?)\*\*", r"{bf:\1}", clean)
				clean = clean.replace("`", "")
				if is_header and display_lines:
					display_lines.append("")
					if len(display_lines) >= max_lines:
						break
				display_lines.append(clean[:120])
		# Emitir cada linea como local individual (evita limite de longitud).
		for i, line in enumerate(display_lines, 1):
			Macro.setLocal("sim_change_" + str(i), line)
		Macro.setLocal("sim_change_count", str(len(display_lines)))

	nl = chr(10)
	ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
	_ = state_path.write_text("version=" + sim_version + nl + "timestamp=" + ts + nl, encoding="utf-8")

except Exception:
	pass
end
}



******************************
***                        ***
*** 2 PARÁMETROS GENERALES ***
***                        ***
******************************
cd `"`c(sysdir_site)'"'

** 2.0 Token del BIE/INEGI **
* Se carga desde set_token.do (gitignored) para que AccesoBIE funcione desde
* el arranque. confirm file distingue archivo ausente (nota amable en la
* bienvenida) de archivo roto (run SIN capture: el error se ve en su origen).
local sim_token_missing = 0
capture confirm file "`c(sysdir_site)'/set_token.do"
if _rc == 0 {
	run "`c(sysdir_site)'/set_token.do"
}
else {
	local sim_token_missing = 1
}

** 2.1 Entidades Federativas **
global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"
global id = "`c(username)'"

** 2.2 Valor presente **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2026

** 2.3 Año paquete económico **
global paqueteEconomico "CGPE 2026"						// POLÍTICA FISCAL
scalar anioPE = 2026



********************
***              ***
*** 3 BIENVENIDA ***
***              ***
********************
noisily di in w _newline(50) "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""': Simulador Fiscal CIEP}}"'
if "`sim_version'" != "" {
	noisily di in g "  Versión: " _col(30) in y "`sim_version'"
	if "`sim_generated_at'" != "" {
		noisily di in g "  Publicada: " _col(30) in y "`sim_generated_at'"
	}

	if "`sim_mode'" == "welcome" {
		noisily di _newline in g "  Bienvenido a esta versión del Simulador Fiscal CIEP."
		noisily di in g "  Novedades:"
	}
	else if "`sim_mode'" == "update" {
		noisily di _newline in g "  Novedades desde " in y "`sim_previous_version'" in g ":"
	}

	if "`sim_mode'" != "silent" & "`sim_change_count'" != "" & "`sim_change_count'" != "0" {
		forvalues i = 1/`sim_change_count' {
			noisily di in y `"    `sim_change_`i''"'
		}
	}
}
noisily di _newline in g "  Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g "  Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g "  User: " _col(30) in y "$id"

noisily di _newline in g " Comandos principales:"
noisily di `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs] {view "03_help/Stata/Poblacion.sthlp":({it:help})}"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010) aniomax(2031)":PIBDeflactor} [, ANIOvp(int) ANIOMAX(int) NOGraphs] {view "03_help/Stata/PIBDeflactor.sthlp":({it:help})}"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs] {view "03_help/Stata/SCN.sthlp":({it:help})}"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE] {view "03_help/Stata/LIF.sthlp":({it:help})}"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE] {view "03_help/Stata/PEF.sthlp":({it:help})}"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs] {view "03_help/Stata/SHRFSP.sthlp":({it:help})}"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos} {it:serie} [, NOGraphs DESDE(real)] {view "03_help/Stata/DatosAbiertos.sthlp":({it:help})}"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)] {view "03_help/Stata/TasasEfectivas.sthlp":({it:help})}"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)] {view "03_help/Stata/GastoPC.sthlp":({it:help})}"'
noisily di `" {stata "AccesoBIE 734407, nombres(pibQ)":AccesoBIE} {it:serie} [, nombres()] {view "03_help/Stata/AccesoBIE.sthlp":({it:help})}"' 
noisily di `" {stata "sim_changelog":sim_changelog} [, VERsion(str)] {view "03_help/Stata/sim_changelog.sthlp":({it:help})}"'

if `sim_token_missing' {
	noisily di _newline in g "  Nota: falta configurar el token del BIE/INEGI, necesario para los"
	noisily di in g "  comandos que consultan el BIE (como AccesoBIE). Copia"
	noisily di in g "  set_token.template.do a set_token.do y coloca ah{c i'} tu token."
}



*********************************
***                           ***
*** 4 PARÁMETROS PARTICULARES ***
***                           ***
*********************************

** 2.1 Producto Interno Bruto (inputs opcionales)
global pib2025 = 1.0575							// CRECIMIENTO ANUAL PIB
global pib2026 = 2.262							// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.0898
global pib2028 = 2.0548
global pib2029 = 2.015
global pib2030 = 2.0137
global pib2031 = 2.0366

** 2.2 Deflactor (inputs opcionales)
global def2025 = 5.2							// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.8							// <-- AGREGAR O QUITAR AÑOS
global def2027 = 4.2
global def2028 = 4.0
global def2029 = 4.0
global def2030 = 4.0
global def2031 = 4.0

** 2.3 Inflación (inputs opcionales)
global inf2025 = 4.2							// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.54							// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0
global inf2031 = 3.0
