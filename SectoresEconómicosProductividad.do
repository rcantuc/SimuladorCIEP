***
*** Productividad por sector económico
***


**
** 1. Importar variables de interés desde el BIE
/**
AccesoBIE "734410 734417 734536 735146 735153 735272" "Primaria Secundaria Terciaria Indice_Primaria Indice_Secundaria Indice_Terciaria"

** Label variables
label var Primaria "Sector primario"
label var Secundaria "Sector secundario"
label var Terciaria "Sector terciario"

label var Indice_Primaria "Índice de precios implícitos (Primaria)"
label var Indice_Secundaria "Índice de precios implícitos (Secundaria)"
label var Indice_Terciaria "Índice de precios implícitos (Terciaria)"


** Dar formato a variables
replace Primaria = Primaria*1000000
replace Secundaria = Secundaria*1000000
replace Terciaria = Terciaria*1000000

format Primaria %20.0fc
format Secundaria %20.0fc
format Terciaria %20.0fc

format Indice_Primaria %10.3fc
format Indice_Secundaria %10.3fc
format Indice_Terciaria %10.3fc

** Guardar
tempfile productividad
save `productividad'


**
** 2. Importar variables de interés desde el BIE
**
AccesoBIE "289251 289252 289253" "PobOcupPrimaria PobOcupSecundaria PobOcupTerciaria"

** Label variables
label var PobOcupPrimaria "Población ocupada sector primario"
label var PobOcupSecundaria "Población ocupada sector secundario"
label var PobOcupTerciaria "Población ocupada sector terciario"

** Dar formato a variables
format PobOcupPrimaria %20.0fc
format PobOcupSecundaria %20.0fc
format PobOcupTerciaria %20.0fc

** Guardar
tempfile pobocupada
save `pobocupada'


**
** 3. Merge datasets
**
use `productividad', clear
merge 1:1 (anio trimestre) using `pobocupada', nogen //keep(matched)

** Guardar
save "`c(sysdir_site)'/03_temp/productividad.dta", replace


**/
** 4. Gráfica
**
use "`c(sysdir_site)'/03_temp/productividad.dta", clear

collapse (mean) Primaria Secundaria Terciaria PobOcupPrimaria PobOcupSecundaria PobOcupTerciaria Indice_Primaria Indice_Secundaria Indice_Terciaria, by(anio)

g deflactorPrimaria = Indice_Primaria/Indice_Primaria[_N]
g deflactorSecundaria = Indice_Secundaria/Indice_Secundaria[_N]
g deflactorTerciaria = Indice_Terciaria/Indice_Terciaria[_N]

g productividadPrimaria = Primaria/PobOcupPrimaria/deflactorPrimaria
format productividadPrimaria %20.0fc

g productividadSecundaria = Secundaria/PobOcupSecundaria/deflactorSecundaria
format productividadSecundaria %20.0fc

g productividadTerciaria = Terciaria/PobOcupTerciaria/deflactorTerciaria
format productividadTerciaria %20.0fc

/* Gráfica 1: Productividad sector primario *
local graphtitle "{bf:Productividad laboral}"
local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."

tempvar  gpibYPrimaria gPOPri gPOPri2
g `gpibYPrimaria' = Primaria/1000000000000/deflactorPrimaria
format `gpibYPrimaria' %7.1fc

g `gPOPri' = PobOcupPrimaria/1000000
format `gPOPri' %7.1fc

g `gPOPri2' = productividadPrimaria/1000
format `gPOPri2' %7.0fc

forvalues i = 2005/2025 {

        tabstat `gPOPri2' if anio == `i', f(%7.1fc) stat(mean) save
        tempname meanPO2
        matrix `meanPO2' = r(StatTotal)

        tabstat `gPOPri2' if anio == 2005, f(%7.1fc) stat(mean) save
        tempname meanPO3
        matrix `meanPO3' = r(StatTotal)

        local crecpo2 = `meanPO2'[1,1]
        local crecpo3 = `meanPO3'[1,1]

        twoway (bar `gpibYPrimaria' anio, ///
                mlabel(`gpibYPrimaria') mlabposition(12) mlabcolor(black) mlabgap(0pt) mlabsize(medium) yaxis(1) barwidth(.75) pstyle(p2)) ///
                (bar `gPOPri' anio, mlabel(`gPOPri') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) yaxis(2) barwidth(.33) pstyle(p1)) ///
                (connected `gPOPri2' anio, yaxis(3) mlabel(`gPOPri2') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) pstyle(p3)) ///)
                if anio <= `i' & anio >= 2005, ///
                title(`graphtitle') ///
                subtitle("Sector primario") ///
                ytitle("", axis(1)) ///
                ytitle("", axis(2)) ///
                ytitle("", axis(3)) ///
                xtitle("") ///
                tlabel(2005(1)2025, labsize(medium)) ///
                ylabel(none, format(%20.0fc) axis(1)) ///
                ylabel(none, format(%20.0fc) axis(2)) ///
                ylabel(none, format(%20.0fc) axis(3)) ///
                yscale(range(0 2) axis(1)) ///
                yscale(range(0 20) axis(2)) ///
                yscale(range(0) axis(3)) ///
                legend(on label(1 "PIB (billones MXN 2025)") ///
                label(2 "Población Ocupada (millones)") ///
                label(3 "Productividad (miles MXN 2025)"))	///
                b1title("Dif. 2005 - 2025: {bf:`=string(`crecpo2'-`crecpo3',"%7.1fc")'}", size(large)) ///
                caption("`graphfuente'") ///
                name(UpdatePrimario`i', replace)

        capture confirm existence $export
        if _rc == 0 {
                graph export "$export/primario`i'.png", replace name(UpdatePrimario`i')
        }

}


* Gráfica 2: Productividad sector secundario *
local graphtitle "{bf:Productividad laboral}"
local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."

tempvar  gpibYSecundaria gPOSec gPOSec2
g `gpibYSecundaria' = Secundaria/1000000000000/deflactorSecundaria
format `gpibYSecundaria' %7.1fc

g `gPOSec' = PobOcupSecundaria/1000000
format `gPOSec' %7.1fc

g `gPOSec2' = productividadSecundaria/1000
format `gPOSec2' %7.0fc

forvalues i = 2005/2025 {

        tabstat `gPOSec2' if anio == `i', f(%7.1fc) stat(mean) save
        tempname meanPO2
        matrix `meanPO2' = r(StatTotal)

        tabstat `gPOSec2' if anio == 2005, f(%7.1fc) stat(mean) save
        tempname meanPO3
        matrix `meanPO3' = r(StatTotal)

        local crecpo2 = `meanPO2'[1,1]
        local crecpo3 = `meanPO3'[1,1]

        twoway (bar `gpibYSecundaria' anio, ///
                mlabel(`gpibYSecundaria') mlabposition(12) mlabcolor(black) mlabgap(0pt) mlabsize(medium) yaxis(1) barwidth(.75) pstyle(p2)) ///
                (bar `gPOSec' anio, mlabel(`gPOSec') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) yaxis(2) barwidth(.33) pstyle(p1)) ///
                (connected `gPOSec2' anio, yaxis(3) mlabel(`gPOSec2') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) pstyle(p3)) ///)
                if anio <= `i' & anio >= 2005, ///
                title(`graphtitle') ///
                subtitle("Sector secundario") ///
                ytitle("", axis(1)) ///
                ytitle("", axis(2)) ///
                ytitle("", axis(3)) ///
                xtitle("") ///
                tlabel(2005(1)2025, labsize(medium)) ///
                ylabel(none, format(%20.0fc) axis(1)) ///
                ylabel(none, format(%20.0fc) axis(2)) ///
                ylabel(none, format(%20.0fc) axis(3)) ///
                yscale(range(0 17) axis(1)) ///
                yscale(range(0 25) axis(2)) ///
                yscale(range(0) axis(3)) ///
                legend(on label(1 "PIB (billones MXN 2025)") ///
                label(2 "Población Ocupada (millones)") ///
                label(3 "Productividad (miles MXN 2025)"))	///
                b1title("Dif. 2005 - 2025: {bf:`=string(`crecpo2'-`crecpo3',"%7.1fc")'}", size(large)) ///
                caption("`graphfuente'") ///
                name(UpdateSecundario`i', replace)

        capture confirm existence $export
        if _rc == 0 {
                graph export "$export/secundario`i'.png", replace name(UpdateSecundario`i')
        }
}


* Gráfica 3: Productividad sector terciario */
local graphtitle "{bf:Productividad laboral}"
local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."

tempvar  gpibYTerciaria gPOT gPOT2
g `gpibYTerciaria' = Terciaria/1000000000000/deflactorTerciaria
format `gpibYTerciaria' %7.1fc

g `gPOT' = PobOcupTerciaria/1000000
format `gPOT' %7.1fc

g `gPOT2' = productividadTerciaria/1000
format `gPOT2' %7.0fc

forvalues i = 2005/2025 {

        tabstat `gPOT2' if anio == `i', f(%7.1fc) stat(mean) save
        tempname meanPO2
        matrix `meanPO2' = r(StatTotal)

        tabstat `gPOT2' if anio == 2005, f(%7.1fc) stat(mean) save
        tempname meanPO3
        matrix `meanPO3' = r(StatTotal)

        local crecpo2 = `meanPO2'[1,1]
        local crecpo3 = `meanPO3'[1,1]
        
        twoway (bar `gpibYTerciaria' anio, ///
                mlabel(`gpibYTerciaria') mlabposition(12) mlabcolor(black) mlabgap(0pt) mlabsize(medium) yaxis(1) barwidth(.75) pstyle(p2)) ///
                (bar `gPOT' anio, mlabel(`gPOT') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) yaxis(2) barwidth(.33) pstyle(p1)) ///
                (connected `gPOT2' anio, yaxis(3) mlabel(`gPOT2') mlabposition(12) mlabcolor(black) mlabgap(0pt) ///
                        lpattern(dot) mlabsize(medium) pstyle(p3)) ///)
                if anio <= `i' & anio >= 2005, ///
                title(`graphtitle') ///
                subtitle("Sector terciario") ///
                ytitle("", axis(1)) ///
                ytitle("", axis(2)) ///
                ytitle("", axis(3)) ///
                xtitle("") ///
                tlabel(2005(1)2025, labsize(medium)) ///
                ylabel(none, format(%20.0fc) axis(1)) ///
                ylabel(none, format(%20.0fc) axis(2)) ///
                ylabel(none, format(%20.0fc) axis(3)) ///
                yscale(range(0 25) axis(1)) ///
                yscale(range(0 55) axis(2)) ///
                yscale(range(0 600) axis(3)) ///
                legend(on label(1 "PIB (billones MXN 2025)") ///
                label(2 "Población Ocupada (millones)") ///
                label(3 "Productividad (miles MXN 2025)"))	///
                b1title("Dif. 2005 - 2025: {bf:`=string(`crecpo2'-`crecpo3',"%7.1fc")'}", size(large)) ///
                caption("`graphfuente'") ///
                name(UpdateTerciario`i', replace)

        capture confirm existence $export
        if _rc == 0 {
                graph export "$export/terciario`i'.png", replace name(UpdateTerciario`i')
        }
}
