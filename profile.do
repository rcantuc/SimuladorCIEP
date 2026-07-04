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
noisily {
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
_emit("sim_changes", "")

try:
	site_dir = Path(r"""`c(sysdir_site)'""".strip())
	manifest_path = site_dir / "manifest.json"
	changelog_path = site_dir / "CHANGELOG.md"
	state_path = Path.home() / ".simulador_ciep_state"

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
		escaped_ver = re.escape(sim_version)
		section_pattern = "^## " + chr(92) + "[" + escaped_ver + chr(92) + "][^" + nl + "]*" + nl + "(.*?)(?=^## " + chr(92) + "[|" + chr(92) + "Z)"
		section_match = re.search(section_pattern, changelog_text, re.MULTILINE | re.DOTALL)
		if section_match:
			raw = section_match.group(1).strip()
			lines = [line.strip() for line in raw.splitlines() if line.strip()]
			display_lines = []
			for line in lines[:15]:
				display_lines.append(line[:120])
			Macro.setLocal("sim_changes", " | ".join(display_lines))

	nl = chr(10)
	ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
	state_path.write_text("version=" + sim_version + nl + "timestamp=" + ts + nl, encoding="utf-8")

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

	if "`sim_mode'" != "silent" & "`sim_changes'" != "" {
		local changes_display "`sim_changes'"
		while strpos("`changes_display'", " | ") > 0 {
			local segment = substr("`changes_display'", 1, strpos("`changes_display'", " | ") - 1)
			noisily di in g "    `segment'"
			local changes_display = substr("`changes_display'", strpos("`changes_display'", " | ") + 3, .)
		}
		if "`changes_display'" != "" {
			noisily di in g "    `changes_display'"
		}
	}
}
noisily di _newline in g "  Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g "  Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g "  User: " _col(30) in y "$id"

noisily di _newline in g " Comandos principales:"
noisily di `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs] {view "help/Stata/Poblacion.sthlp":({it:help})}"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010) aniomax(2031)":PIBDeflactor} [, ANIOvp(int) ANIOMAX(int) NOGraphs] {view "help/Stata/PIBDeflactor.sthlp":({it:help})}"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs] {view "help/Stata/SCN.sthlp":({it:help})}"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE] {view "help/Stata/LIF.sthlp":({it:help})}"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE] {view "help/Stata/PEF.sthlp":({it:help})}"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs] {view "help/Stata/SHRFSP.sthlp":({it:help})}"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos} {it:serie} [, NOGraphs DESDE(real) MES] {view "help/Stata/DatosAbiertos.sthlp":({it:help})}"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)] {view "help/Stata/TasasEfectivas.sthlp":({it:help})}"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)] {view "help/Stata/GastoPC.sthlp":({it:help})}"'
noisily di `" {stata "AccesoBIE 734407, nombres(pibQ)":AccesoBIE} {it:serie} [, nombres()] {view "help/Stata/AccesoBIE.sthlp":({it:help})}"' 



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
