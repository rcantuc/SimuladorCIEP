*! version 8.0 CIEP 03jul2026
*!*******************************************
*!***                                    ****
*!***    Historial de cambios del        ****
*!***    Simulador Fiscal CIEP           ****
*!***    Autor: Ricardo Cantú Calderón   ****
*!***    Version: 8.0                    ****
*!***    Última actualización: 03jul2026 ****
*!***                                    ****
*!*******************************************
program define sim_changelog
	version 16
	syntax [, VERsion(str)]

	python: _sim_changelog_main("`version'")
end


python:
import os
import re
from sfi import Macro, SFIToolkit


def _sc_fail(msg):
	SFIToolkit.errprintln("sim_changelog: " + msg)
	SFIToolkit.error(198)


def _sc_sanitize(line):
	# Misma sanitización que el bloque 1.5 de profile.do:
	# **texto** -> {bf:texto}, backticks fuera
	clean = re.sub(r"\*\*(.+?)\*\*", r"{bf:\1}", line)
	clean = clean.replace("`", "")
	return clean


def _sim_changelog_main(only_version):
	only_version = only_version.strip().strip('"')
	if only_version and not only_version.startswith("v"):
		only_version = "v" + only_version

	sysdir_site = Macro.getGlobal("c(sysdir_site)")
	changelog_path = os.path.join(sysdir_site, "02_governance", "CHANGELOG.md")

	if not os.path.isfile(changelog_path):
		_sc_fail(
			"no se encontro CHANGELOG.md en " + changelog_path + ".\n"
			"Asegurate de que la Carpeta del Simulador este completa (git pull)."
		)
		return

	with open(changelog_path, "r", encoding="utf-8") as f:
		changelog_text = f.read()

	# Mismo parseo que el bloque 1.5 de profile.do: entradas '## [vX.Y] — fecha'
	version_header_re = re.compile(r"^## \[(v[^\]]+)\][^\n]*\n", re.MULTILINE)
	all_matches = list(version_header_re.finditer(changelog_text))
	entries = []
	for idx, m in enumerate(all_matches):
		ver = m.group(1)
		header_line = m.group(0).strip()
		body_start = m.end()
		body_end = all_matches[idx + 1].start() if idx + 1 < len(all_matches) else len(changelog_text)
		entries.append((ver, header_line, body_start, body_end))

	if not entries:
		_sc_fail("CHANGELOG.md no contiene entradas de version ('## [vX.Y] — fecha').")
		return

	if only_version:
		entries = [e for e in entries if e[0] == only_version]
		if not entries:
			_sc_fail(
				"version '" + only_version + "' no encontrada en CHANGELOG.md.\n"
				"Corre sim_changelog sin opciones para ver todas las versiones disponibles."
			)
			return

	SFIToolkit.displayln("")
	SFIToolkit.displayln("{bf:Historial de cambios del Simulador Fiscal CIEP}")

	for ver, header, s, e in entries:
		SFIToolkit.displayln("")
		SFIToolkit.displayln("{bf:" + _sc_sanitize(header.replace("## ", "")) + "}")
		body = changelog_text[s:e].strip()
		for ln in body.splitlines():
			ln = ln.strip()
			if not ln or ln == "---":
				continue
			is_header = False
			if ln.startswith("### "):
				ln = ln[4:].upper()
				is_header = True
			elif ln.startswith("## "):
				ln = ln[3:]
				is_header = True
			clean = _sc_sanitize(ln)
			if is_header:
				SFIToolkit.displayln("")
				SFIToolkit.displayln("  {bf:" + clean + "}")
			else:
				SFIToolkit.displayln("  {res}" + clean)

	SFIToolkit.displayln("")
end
