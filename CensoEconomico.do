import delimited "/Users/ricardo/CIEP Dropbox/BasesCIEP/INEGI/Censo Economico/2024/censo_eco_municipios.csv", clear 

drop in 1/4

rename v1 anio
label var anio "Año censal"

rename v2 entidad
label var entidad "Entidad Federativa"

rename v3 municipio
label var municipio "Municipio"

rename v4 actividad_economica
label var actividad_economica "Actividad Económica"

rename v5 unidades_economicas
label var unidades_economicas "Unidades Económicas"

foreach var of varlist v6-v102 {
	local varname = substr("`=`var'[1]'",1,5)
	local label = substr("`=`var'[1]'",7,.)
	local numero = substr("`var'",2,.)
	
	noisily di in g "`numero'. `varname': " in y "`label'"
	
	rename `var' `varname'
	label var `varname' "`label'"
}
drop in 1
drop in `=_N'
drop in `=_N'
destring unidades_economicas H001A-Q900A, replace
drop if H001A == .

g ent = substr(entidad,1,2)
g mun = substr(municipio,1,3)

replace actividad_economica = subinstr(actividad_economica,"Sector ","",.)
replace actividad_economica = subinstr(actividad_economica,"Subsector ","",.)
replace actividad_economica = subinstr(actividad_economica,"Rama ","",.)
replace actividad_economica = subinstr(actividad_economica,"Subrama ","",.)
replace actividad_economica = subinstr(actividad_economica,"Clase ","",.)

tempvar codigo_space
g `codigo_space' = strpos(actividad_economica," ")
g codigo = substr(actividad_economica,1,`codigo_space')
replace codigo = substr(codigo,1,2) if strpos(codigo,"-") != 0

compress
order anio ent entidad mun municipio actividad codigo
save "/Users/ricardo/CIEP Dropbox/BasesCIEP/INEGI/Censo Economico/2024/censo_eco_municipios.dta", replace 
