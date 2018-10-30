if "`=c(os)'" == "Unix" {
	global A "Á"
	global E "É"
	global I "Í"
	global O "Ó"
	global U "Ú"

	global a "á"
	global e "é"
	global i "í"
	global o "ó"
	global u "ú"

	global NI "Ñ"
	global ni "ñ"
}


if "`=c(os)'" == "MacOSX" {
	global A "ç"
	global E "ƒ"
	global I "ê"
	global O "î"
	global U "ò"

	global a "‡"
	global e "Ž"
	global i "’"
	global o "—"
	global u "œ"

	global ni "–"
	global NI "„"
}


if "`=c(os)'" == "Windows" {
	global A "Á"
	global E "É"
	global I "Í"
	global O "Ó"
	global U "Ú"

	global a "á"
	global e "é"
	global i "í"
	global o "ó"
	global u "ú"

	global NI "Ñ"
	global ni "ñ"
}
