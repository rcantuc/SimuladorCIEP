*! version 1.0 CIEP 10oct2026
*!*******************************************
*!***                                    ****
*!***    SIMentidad                      ****
*!***    Catálogo de entidades y         ****
*!***    resolución nombre -> clave      ****
*!***    Autor: Ricardo                  ****
*!***                                    ****
*!***    Sintaxis:                       ****
*!***    SIMentidad ["<nombre>"]         ****
*!*******************************************
*
* CONTRATO (global entidad, 2026-10-10): única fuente de verdad del catálogo de
* entidades federativas del Simulador. Define $entidadesL (nombres) y $entidadesC
* (abreviaturas) si no existen — profile.do §2.1 los carga de aquí; en batch (receta
* canónica, sin profile.do) los define el primer comando que los necesite. La
* POSICIÓN en la lista es la clave INEGI de la ENIGH (01 Aguascalientes … 32
* Zacatecas; substr(folioviv,1,2)) y la abreviatura es la que Poblacion.ado ya usa
* para nombrar escalares y gráficas (pobtotNL, PP_…_NL.png).
*
* Sin argumento: solo carga el catálogo. Con <nombre>: lo valida contra $entidadesL
* (exacto, con acentos; "Nacional" no es una entidad) y devuelve
*   r(nombre)  nombre tal como está en el catálogo
*   r(clave)   clave INEGI de dos dígitos ("19")
*   r(abrev)   abreviatura ("NL")
*   r(pos)     posición numérica (19)
* Si no existe: error accionable (r(198)) con el catálogo completo.

program define SIMentidad, rclass
	version 14

	** 1 Catálogo (orden = clave INEGI 01-32; el 33 es "Nacional") **
	if `"$entidadesL"' == "" | "$entidadesC" == "" {
		global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
		global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"
	}

	** 2 Resolución del nombre **
	* Quita comillas simples y compuestas (el argumento puede llegar como "x", `"x"' o x) *
	local nombre : subinstr local 0 `"""' "", all
	local nombre : subinstr local nombre "`" "", all
	local nombre : subinstr local nombre "'" "", all
	local nombre = trim(`"`nombre'"')
	if `"`nombre'"' == "" exit

	local pos = 0
	local j = 1
	foreach k of global entidadesL {
		if `"`k'"' == `"`nombre'"' & `pos' == 0 local pos = `j'
		local ++j
	}
	if `pos' == 0 | `pos' > 32 {
		di as error `"SIMentidad: "`nombre'" no es una entidad federativa del catálogo (global entidad, SIM.do §0.4)."'
		di as error "  El nombre va exacto, con acentos y entre comillas, p. ej.: global entidad " `"""' "Nuevo León" `"""'
		local catalogo : subinstr global entidadesL `""Nacional""' "", all
		di as error `"  Catálogo ($entidadesL):`catalogo'"'
		exit 198
	}

	local abrev : word `pos' of $entidadesC
	return local nombre `"`nombre'"'
	return local clave = string(`pos', "%02.0f")
	return local abrev "`abrev'"
	return scalar pos = `pos'
end
