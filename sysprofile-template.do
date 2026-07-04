* ============================================================================
* sysprofile-template.do — PLANTILLA del sysprofile personal
* ============================================================================
*
* Copia este archivo como sysprofile.do en el directorio donde Stata busca
* el sysprofile de tu sistema (en macOS, típicamente /Applications/StataNow/;
* verifica el tuyo con:  di "`c(sysdir_stata)'"  dentro de Stata).
*
* PROPÓSITO: elegir qué proyecto/clon del Simulador cargar al abrir Stata.
* Un "clon" es una copia completa del repositorio en tu máquina; puedes tener
* varios (institucional, experimental) sin que se estorben entre sí.
*
* CASO 1 — Un solo clon (uso institucional, lo normal):
*   Deja activo el bloque de abajo tal cual. Apunta al clon institucional
*   que Dropbox sincroniza. Si tu carpeta tiene otro nombre o ruta, ajusta
*   solo la línea de tu sistema operativo.
*
* CASO 2 — Múltiples clones (institucional + experimental):
*   Comenta el bloque del CASO 1 y descomenta el menú del CASO 2 más abajo.
*   Cada opción apunta a un clon diferente; al abrir Stata, escribes el
*   número del clon que quieres cargar en esa sesión.
* ============================================================================

* ─── CASO 1 — Un solo clon (activo por default) ─────────────────────────────

if "`c(os)'" == "MacOSX" {
	sysdir set SITE "/Users/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}
if "`c(os)'" == "Unix" {
	sysdir set SITE "/home/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}
if "`c(os)'" == "Windows" {
	sysdir set SITE "C:\Users\\`c(username)'\CIEP Dropbox\SimuladorCIEP\"
}

* ─── CASO 2 — Múltiples clones (menú interactivo, descomenta para usar) ─────
*
* Al abrir Stata aparece un menú y escribes el número del proyecto.
* Ajusta las rutas a donde vivan TUS clones. Los clones experimentales son
* LOCALES a tu máquina: nunca los pongas dentro de la carpeta Dropbox-CIEP
* institucional (ver manual del investigador, §5.4).
*
* noisily display _newline(5) in w "Hola `c(username)'."
* noisily display _newline in g "¿Qué proyecto quieres cargar?"
* noisily display in y "  1. Simulador (clon institucional)"
* noisily display in y "  2. Simulador (clon experimental)"
* noisily display _newline _request(_proyecto)
* if "`proyecto'" == "1" {
* 	sysdir set SITE "/Users/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
* }
* else if "`proyecto'" == "2" {
* 	sysdir set SITE "/Users/`c(username)'/experimental/SimuladorCIEP/"
* }

* ─── Común a ambos casos ─────────────────────────────────────────────────────
* Agrega la carpeta elegida a la ruta donde Stata busca comandos (.ado)
* y colócate en ella. A partir de aquí corre el profile.do del clon elegido.

adopath ++SITE
cd "`c(sysdir_site)'"
