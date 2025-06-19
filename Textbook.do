****
**** SIMULADOR FISCAL CIEP (9 de mayo de 2025)
**** Descripción: Genera las gráficas y tablas del libro de texto CIEP
**** Autor: Ricardo Cantú Calderón
**** Email: ricardocantu@ciep.mx
****



***
**# 0. SET UP
***
clear all
macro drop _all
capture log close _all
timer on 1

** Directorios de trabajo (uno por computadora)
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {					// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/"
	global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/7/"
}
cd "`c(sysdir_site)'"

** Parámetros iniciales
scalar aniovp = 2025								// ANIO VALOR PRESENTE
scalar anioPE = 2025								// ANIO PAQUETE ECONÓMICO
scalar anioenigh = 2022								// ANIO ENIGH
global id = "ciepmx"								// ID USUARIO
global paqueteEconomico "CGPE 2025"						// POLÍTICA FISCAL

** Opciones
//global nographs "nographs"							// SUPRIMIR GRAFICAS
//global update "update"							// UPDATE BASES DE DATOS
global textbook "textbook"							// SCALAR TO LATEX



***
**# 1. CAPTÍULO 2
***
** 2.1 Producto Interno Bruto (inputs opcionales)
global pib2025 = 1.5								// CRECIMIENTO ANUAL PIB
global pib2026 = 2.1								// <-- AGREGAR O QUITAR AÑOS
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5

** 2.2 Deflactor (inputs opcionales)
global def2025 = 4.4								// CRECIMIENTO ANUAL PRECIOS IMPLÍCITOS
global def2026 = 4.0								// <-- AGREGAR O QUITAR AÑOS
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5

** 2.3 Inflación (inputs opcionales)
global inf2025 = 3.5								// CRECIMIENTO ANUAL INFLACIÓN
global inf2026 = 3.0								// <-- AGREGAR O QUITAR AÑOS
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0

noisily PIBDeflactor, aniovp(`=aniovp') geodef(1993) geopib(1993) aniomax(2030) $update $textbook


** 2.4 Sistema de Cuentas Nacionales (sin inputs)
noisily SCN, anio(`=aniovp') $update $textbook



***
**# 2. CAPTÍULO 3
***
