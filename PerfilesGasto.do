****
**** Ahorro de los hogares: ENIGH 2024
****
global enigh2024 "/Users/ricardo/CIEP Dropbox/BasesCIEP/INEGI/ENIGH/2024"
global export "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Deuda/2. Boletines/Ahorro ENIGH 2024/images"



***
*** 1. Gastos del hogar y de los individuos
***
use "$enigh2024/gastospersona.dta", clear
append using "$enigh2024/gastohogar.dta"
append using "$enigh2024/gastotarjetas.dta"
append using "$enigh2024/erogaciones.dta"

g gasto_ind = gasto_tri if numren != ""
g gasto_hog = gasto_tri if numren == ""

g tabaco_ind = gasto_tri if numren != "" & (clave == "023010" | clave == "023020" | clave == "023090")
g tabaco_hog = gasto_tri if numren == "" & (clave == "023010" | clave == "023020" | clave == "023090")

g alcohol_ind = gasto_tri if numren != "" & (clave == "021101" | clave == "021301" | clave == "021302" | clave == "021303" | clave == "181146" | clave == "181151" | clave == "181147" | clave == "181148" | clave == "181154" | clave == "021102" | clave == "021103" | clave == "021211" | clave == "021213" | clave == "181150" | clave == "021104" | clave == "021212" | clave == "021901" | clave == "021902" | clave == "021105")
g alcohol_hog = gasto_tri if numren == "" & (clave == "021101" | clave == "021301" | clave == "021302" | clave == "021303" | clave == "181146" | clave == "181151" | clave == "181147" | clave == "181148" | clave == "181154" | clave == "021102" | clave == "021103" | clave == "021211" | clave == "021213" | clave == "181150" | clave == "021104" | clave == "021212" | clave == "021901" | clave == "021902" | clave == "021105")

g mujeres_ind = gasto_tri if numren != "" & clave == "13120N"
g mujeres_hog = gasto_tri if numren == "" & clave == "13120N"

g parto_ind = gasto_tri if numren != "" & (clave == "062194" | clave == "062192" | clave == "064103" | clave == "064202" | clave == "063103" | clave == "063104" | clave == "062198" | clave == "063106")
g parto_hog = gasto_tri if numren == "" & (clave == "062194" | clave == "062192" | clave == "064103" | clave == "064202" | clave == "063103" | clave == "063104" | clave == "062198" | clave == "063106")

g consultas_ind = gasto_tri if numren != "" & (clave == "062193" | clave == "062191" | clave == "062210" | clave == "062291" | clave == "062292" | clave == "064101" | clave == "064102" | clave == "064201")
g consultas_hog = gasto_tri if numren == "" & (clave == "062193" | clave == "062191" | clave == "062210" | clave == "062291" | clave == "062292" | clave == "064101" | clave == "064102" | clave == "064201")

g medicinas_ind = gasto_tri if numren != "" & (clave == "061118" | clave == "061119" | clave == "06111A" | clave == "06111B" | clave == "06111C" | clave == "06111D" | clave == "06111E" | clave == "06111G" | clave == "06111H" | clave == "06111I" | clave == "061111" | clave == "061112" | clave == "061113" | clave == "061114" | clave == "061115" | clave == "061116" | clave == "061117" | clave == "06111K" | clave == "06111L" | clave == "011994")
g medicinas_hog = gasto_tri if numren == "" & (clave == "061118" | clave == "061119" | clave == "06111A" | clave == "06111B" | clave == "06111C" | clave == "06111D" | clave == "06111E" | clave == "06111G" | clave == "06111H" | clave == "06111I" | clave == "061111" | clave == "061112" | clave == "061113" | clave == "061114" | clave == "061115" | clave == "061116" | clave == "061117" | clave == "06111K" | clave == "06111L" | clave == "011994" | clave == "06111F")

g combustibles_ind = gasto_tri if numren != "" & (clave == "072210" | clave == "072221" | clave == "072222")
g combustibles_hog = gasto_tri if numren == "" & (clave == "072210" | clave == "072221" | clave == "072222")

g Apps_ind = gasto_tri if numren != "" & (clave == "073222" | clave == "181212")
g Apps_hog = gasto_tri if numren == "" & (clave == "073222" | clave == "181212")

g cuidado_ind = gasto_tri if numren != "" & (clave == "131311" | clave == "131312" | clave == "131313" | clave == "131321" | clave == "131322" | clave == "131323")
g cuidado_hog = gasto_tri if numren == "" & (clave == "131311" | clave == "131312" | clave == "131313" | clave == "131321" | clave == "131322" | clave == "131323")

g streaming_ind = gasto_tri if numren != "" & (clave == "083921" | clave == "083922")
g streaming_hog = gasto_tri if numren == "" & (clave == "083921" | clave == "083922")

collapse (sum) *_ind *_hog , by(folioviv foliohog numren)

tempfile gastos
save `gastos'



***
*** 2. Ingresos de los individuos
***
use "$enigh2024/ingresos.dta", clear

collapse (sum) ing_tri, by(folioviv foliohog numren)

tempfile ingresos
save `ingresos'



***
*** 3. Asignación del gasto por individuo
***
use `ingresos', clear
merge 1:1 (folioviv foliohog numren) using `gastos', nogen
merge 1:1 (folioviv foliohog numren) using "$enigh2024/poblacion.dta", nogen keepus(edad sexo)
merge m:1 (folioviv foliohog) using "$enigh2024/concentrado.dta", nogen keepus(factor ubica_geo)
merge m:1 (ubica_geo) using "/Users/ricardo/CIEP Dropbox/BasesCIEP/Mapas/municipios_costeros.dta", nogen
g costeras = lat != .

foreach var of varlist *_ind *_hog *_tri {
	replace `var' = 0 if `var' == .
}
egen tamhog = count(edad), by(folioviv foliohog)

foreach var of varlist *_hog {
	tempvar `var'
	egen ``var'' = sum(`var') if numren == "", by(folioviv foliohog)
	egen `var'_tot = sum(``var''), by(folioviv foliohog)
	g `var'_pc = `var'_tot/tamhog
	drop ``var''
}
drop if numren == ""

** 3.1 deciles **
egen ing_hog = sum(ing_tri), by(folioviv foliohog)

g ing_pc = ing_hog/tamhog
xtile decil = ing_pc [pw=factor], nq(10)

label var ing_tri "Ingreso trimestral"
//noisily Simulador ing_tri [fw=factor], aniope(2024) aniovp(2024) title("Ingresos por persona") reboot

** 3.2 Perfiles de gasto **
g gasto_pc_orig = gasto_hog_pc + gasto_ind
label var gasto_pc_orig "Gasto (original)"
noisily Simulador gasto_pc_orig if costeras == 1 [fw=factor], aniope(2024) aniovp(2024) reboot
noisily Simulador gasto_pc_orig if costeras == 0 [fw=factor], aniope(2024) aniovp(2024) reboot
ex
g tabaco_pc_orig = tabaco_hog_pc + tabaco_ind
label var tabaco_pc_orig "Tabaco (original)"  
noisily Simulador tabaco_pc_orig [fw=factor], aniope(2024) aniovp(2024) reboot

g alcohol_pc_orig = alcohol_hog_pc + alcohol_ind
label var alcohol_pc_orig "Alcohol (original)"
noisily Simulador alcohol_pc_orig [fw=factor], aniope(2024) aniovp(2024) reboot

g mujeres_pc_orig = mujeres_hog_pc + mujeres_ind
label var mujeres_pc_orig "Mujeres (original)"
noisily Simulador mujeres_pc_orig [fw=factor], aniope(2024) aniovp(2024) reboot

* Iteraciones *
local salto = 1
foreach var in parto consultas medicinas combustibles Apps streaming cuidado /*gasto tabaco alcohol mujeres*/ {
	forvalues iter=1(1)25 {
		noisily di in w "`iter' " _cont
		forvalues edades=0(`salto')109 {
			forvalues sexos=1(1)2 {
				capture tabstat `var'_hog_pc [fw=factor] ///
					if (edad >= `edades' & edad <= `edades'+`salto'-1) ///
					& sexo == "`sexos'" ///
					, stat(mean) f(%20.0fc) save
				if _rc != 0 {
					local valor = 0
				}
				else {
					local valor = r(StatTotal)[1,1]
				}
				replace `var'_hog_pc = round(`valor',.01) ///
					if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == "`sexos'"
			}
		}
		egen equivalencias = sum(`var'_hog_pc), by(folioviv foliohog)
		replace `var'_hog_pc = `var'_hog_tot*`var'_hog_pc/equivalencias
		drop equivalencias
		
		g `var'_`iter' = `var'_hog_pc + `var'_ind
		label var `var'_`iter' "`=proper("`var'")' (iteración: `iter')"
		noisily Simulador `var'_`iter' [fw=factor], aniope(2024) aniovp(2024) reboot
	}
	replace `var'_hog_pc = `var'_hog_pc + `var'_ind
	label var `var'_hog_pc "`=proper("`var'")' (final)"
	noisily Simulador `var'_hog_pc [fw=factor], aniope(2024) aniovp(2024) reboot
}



***
*** 4. Ahorro 
***
g ahorro = ing_tri - gasto_hog_pc

label var ahorro "Ahorro trimestral"
noisily Simulador ahorro [fw=factor], aniope(2024) aniovp(2024) title("Ahorro por persona") reboot
