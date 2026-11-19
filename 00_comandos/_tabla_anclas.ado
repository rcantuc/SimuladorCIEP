*! version 3.0.0  CIEP 09nov2026 (sesión log-legible) — el cuadro de anclas vive en _log.ado (familia «anclas»); este es el nombre
*! que Households, NTA, Expenditure, TasasEfectivas y SCN ya usan. Misma sintaxis que v2 (clear | add | gate | print); el cuadro sale
*! a 110 columnas, en miles de millones (unidad declarada en el encabezado), con los gates al pie (estándar §D ampliado).
*  Invocar con `noisily` desde un do-file corrido con quietly. Deja TA_GATES_OK / TA_N_ROJO (y LOG_GATES_OK / LOG_N_ROJO).
program define _tabla_anclas
	version 17.0
	_log anclas `0'
end
