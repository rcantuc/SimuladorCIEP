program define Acentos

	syntax [varname]

	if "`=c(os)'" == "Unix" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"ç","Á",.)
			replace `varlist' = subinstr(`varlist',"ƒ","É",.)
			replace `varlist' = subinstr(`varlist',"ê","Í",.)
			replace `varlist' = subinstr(`varlist',"î","Ó",.)
			replace `varlist' = subinstr(`varlist',"ò","Ú",.)

			replace `varlist' = subinstr(`varlist',"‡","á",.)
			replace `varlist' = subinstr(`varlist',"","é",.)
			replace `varlist' = subinstr(`varlist',"’","í",.)
			replace `varlist' = subinstr(`varlist',"—","ó",.)
			replace `varlist' = subinstr(`varlist',"œ","ú",.)

			replace `varlist' = subinstr(`varlist',"–","ñ",.)
			replace `varlist' = subinstr(`varlist',"Ÿ","ü",.)
		}

		else {
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
	}


	if "`=c(os)'" == "MacOSX" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"Á","ç",.)
			replace `varlist' = subinstr(`varlist',"É","ƒ",.)
			replace `varlist' = subinstr(`varlist',"Í","ê",.)
			replace `varlist' = subinstr(`varlist',"Ã“","î",.)
			replace `varlist' = subinstr(`varlist',"Ú","ò",.)

			replace `varlist' = subinstr(`varlist',"Ã¡","‡",.)
			replace `varlist' = subinstr(`varlist',"Ã©","",.)
			replace `varlist' = subinstr(`varlist',"Ã­","’",.)
			replace `varlist' = subinstr(`varlist',"Ã³","—",.)
			replace `varlist' = subinstr(`varlist',"Ãº","œ",.)

			replace `varlist' = subinstr(`varlist',"ñ","–",.)
			replace `varlist' = subinstr(`varlist',"ü","Ÿ",.)
		}

		else {
			global A "ç"
			global E "ƒ"
			global I "ê"
			global O "î"
			global U "ò"

			global a "‡"
			global e ""
			global i "’"
			global o "—"
			global u "œ"

			global ni "–"
			global NI "„"
		}
	}


	if "`=c(os)'" == "Windows" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"ç","ç",.)
			replace `varlist' = subinstr(`varlist',"ƒ","ƒ",.)
			replace `varlist' = subinstr(`varlist',"ê","ê",.)
			replace `varlist' = subinstr(`varlist',"î","î",.)
			replace `varlist' = subinstr(`varlist',"ò","ò",.)

			replace `varlist' = subinstr(`varlist',"‡","‡",.)
			replace `varlist' = subinstr(`varlist',"","",.)
			replace `varlist' = subinstr(`varlist',"’","’",.)
			replace `varlist' = subinstr(`varlist',"—","—",.)
			replace `varlist' = subinstr(`varlist',"œ","œ",.)

			replace `varlist' = subinstr(`varlist',"–","–",.)
			replace `varlist' = subinstr(`varlist',"Ÿ","Ÿ",.)
		}

		else {
			global A "ç"
			global E "ƒ"
			global I "ê"
			global O "î"
			global U "ò"

			global a "‡"
			global e ""
			global i "’"
			global o "—"
			global u "œ"

			global ni "–"
		}
	}

end
