* SIM-local.template.do — panel local de SIM.do (v8.8.0)
*
* Copia este archivo como SIM-local.do en la raíz del simulador (está en .gitignore:
* nunca viaja en un commit). SIM.do lo ejecuta en §0.5, DESPUÉS de los defaults de §0.4
* y ANTES de usarlos, así que aquí viven los toggles personales de quien corre, y el
* SIM.do versionado se queda limpio. Sin SIM-local.do, SIM.do se comporta exactamente
* igual que antes (byte-idéntico).
*
* Regla: aquí solo globals de §0.4. Parámetros del modelo (escalares, matrices,
* IVAT, etc.) NO: esos son cambios del motor y van por commit con CHANGELOG.
*
* Ejemplo (los toggles que Ricardo mantenía como diffs locales en su SIM.do):

global output "output"					// escribe users/$id/output.txt + sankey-*.json (lo que alimenta el sitio)
global bootstrap 100					// réplicas bootstrap de Simulador: EE e IC 95% por UPM-estrato (~25 s por variable); 1 = producción

* Otros toggles disponibles (descomenta el que necesites):
//global nographs "nographs"			// sin gráficas (batch)
//global update "update"				// reconstruye raw/temp/, master/*.dta y los cachés micro de master/<anioenigh>/
//global fuentes "2026-10-06"			// fuentes vivas congeladas a esa fecha (asset fuentes-AAAA-MM-DD.zip); vacío = en vivo
//global entidad "Nuevo León"			// entidad federativa (nombre exacto de $entidadesL): Poblacion de la entidad y Sankey por quintil estatal en users/$id/<ABREV>/; los archivos nacionales no cambian
//global entidad_vintages "0"			// banda de vintages ENIGH del Sankey de entidad: vacío = 2016-2024 (los que existan en users/$id-v<t>/), "0" = sin banda
//global sello_n 100					// sello de muestra (n mínimo por celda) y de concentración (% máximo de una persona) del Sankey de entidad
//global sello_top1 25
//global hasta "3"						// paro temprano: termina al cerrar la sección 1-7 (3 = tras PerfilesSim)
//global textbook "textbook"			// escalares a LaTeX
//global export "/ruta/a/images"		// exporta gráficas
