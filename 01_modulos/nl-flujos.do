*! nl-flujos.do  v0.2.0 (C4, sprint NL-0.6.x) — PALETA de NL: OVERRIDES de las filas heredadas del Sankey nacional + filas propias de NL.
*
* La LISTA de flujos ya no vive aquí: la hereda nl-flujos-herencia.do de la configuración del Sankey nacional
* (01_modulos/visualizations/SankeySF.do ejes 1 y 4 + familias de SIM.do §7.1), con los mismos ids, etiquetas, lados,
* agrupación y bases, verificada contra users/$id/sankey-decil.json. Todas las filas heredadas nacen con abrir 0
* (inventario) y ancla `suma suma` (SUPUESTO). Aquí Ricardo:
*   (a) cambia una fila heredada con UNA línea:  _nloverride <id>, [abrir(0|1|2) lado() variable(fuente:v1+v2) ancla_ref()
*       ancla_pe() etiqueta("…") grupo(<g>|.) banda|nobanda unidad("…") clave("…") nota("…") anclas("…") padre(<id>|.)]
*   (b) añade filas PROPIAS de NL (subcomponentes con ancla EOFP/PEF que el nacional no distingue), con padre():
*       _nlflujo <id> <lado> <abrir> <variable> <ancla_ref> <ancla_pe> "<etiqueta>", padre(<id heredado>) [grupo() banda unidad() clave() nota() anclas()]
*   (c) fija parámetros:  _nlparam <nombre> <valor> [supuesto]
* Regla P.1: un padre y su hijo no pueden estar ambos en página (abrir ≥ 1): doble conteo; salvo _nlparam anidados 1.
* Sintaxis de variable / anclas: ver la cabecera de FederacionNLQuintiles.do (fed: | eofp: | pef:[ramo/]pp | statajson: | suma | pendiente).
* Ids heredados (C4, corrida 2026-10-09): ALTRABAJO (ISRPF, ISRAS, CUOTAS), ALCAPITAL (ISRPM, OTROSK), ALCONSUMO (IVA, IEPSNP,
*   IEPSP, ISAN, IMPORT), IMSS_ISSSTE, PEMEX_CFE, FMP · EDUCACION, SALUD, PENSIONES, INGBASICO, OTRASINVERSIONES, FEDERALIZADO,
*   OTROSGASTOS, ENERGIA, COSTODEUDA. El log de la corrida (§0) imprime la lista vigente.

* ===== parámetros (todos marcados supuesto hasta que Ricardo los fije) =====
_nlparam umbral_n          100   supuesto      // n mínimo por celda para que una celda abierta no lleve sello
_nlparam sello_top1        25    supuesto      // % de concentración top-1 de la celda a partir del cual la celda lleva badge visible
_nlparam neta_por_quintil  0     supuesto      // 0 = NO existe neta por quintil (resolución 2026-10-08); 1 = se calcula sobre los flujos abiertos
_nlparam gris_negativo     0     supuesto      // 0 = abortar si la caja gris queda negativa; 1 = exportar con aviso
_nlparam anidados          0     supuesto      // 0 = padre e hijo no pueden estar ambos en página (doble conteo)

* ===== overrides del lado PAGA: estado C3 (decisión 2026-10-09): los 8 impuestos abiertos con las anclas del contrato; cuotas aparte =====
_nloverride ISRAS,  abrir(2) ancla_ref(fed:pagaISRAS)  ancla_pe(fed:pagaLifISRAS)  etiqueta("ISR a asalariados")
_nloverride ISRPM,  abrir(2) ancla_ref(fed:pagaISRPM)  ancla_pe(fed:pagaLifISRPM)  etiqueta("ISR de personas morales") grupo(capital) banda clave("ISRPM_Sim del objeto de incidencia: ISR PM distribuido por ingresos de capital (Households.do); conciliado macro-micro; una sola observación sostiene ~48 % del ISR PM de NL y ~53 % de la celda Q5")
_nloverride ISRPF,  abrir(2) ancla_ref(fed:pagaISRPF)  ancla_pe(fed:pagaLifISRPF)  etiqueta("ISR de personas físicas") grupo(capital) clave("ISRPF_Sim: ISR de personas físicas con actividad empresarial/profesional; n < 100 en las cinco celdas")
_nloverride IVA,    abrir(2) ancla_ref(fed:pagaIVA)    ancla_pe(fed:pagaLifIVA)    etiqueta("IVA")
_nloverride IEPSNP, abrir(2) ancla_ref(fed:pagaIEPSNP) ancla_pe(fed:pagaLifIEPSNP) etiqueta("IEPS no petrolero")
_nloverride IEPSP,  abrir(2) ancla_ref(fed:pagaIEPSP)  ancla_pe(fed:pagaLifIEPSP)  etiqueta("IEPS petrolero (gasolinas)") grupo(vehicular) clave("clave vehicular (gasto en combustibles); n < 100 en Q3 y Q4")
_nloverride ISAN,   abrir(2) ancla_ref(fed:pagaISAN)   ancla_pe(fed:pagaLifISAN)   etiqueta("ISAN") grupo(vehicular) clave("misma clave vehicular que el IEPS petrolero")
_nloverride IMPORT, abrir(2) ancla_ref(fed:pagaIMPORT) ancla_pe(fed:pagaLifIMPORT) etiqueta("impuestos a la importación")
_nloverride CUOTAS, abrir(2) lado(aparte) ancla_ref(fed:pagaCUOTAS) ancla_pe(fed:pagaLifCUOTAS) etiqueta("cuotas IMSS (aparte, no sumadas)") nota("su contraparte de gasto (IMSS) está fuera del alcance; en el nacional van dentro de Imp al trabajo")
_nloverride OTROSK, ancla_ref(fed:pagaOTROSK) ancla_pe(fed:pagaLifOTROSK) etiqueta("otros ingresos no tributarios (OTROSK; aparte, no sumados en la tarjeta)")

* ===== filas PROPIAS de NL (hijas de FEDERALIZADO: subcomponentes del gasto federalizado con ancla EOFP/PEF; C1) =====
_nlflujo FONE     recibe 2 ind:alum_basica eofp:XAC33A           pef:13+15 "FONE: educación básica (alumnos de escuela pública)", padre(FEDERALIZADO) unidad("alumno de básica pública") clave("alumnos de educación básica en escuela pública expandidos (alum_basica de GastoPC.ado: asiste, pública, nivel 01–07, edad ≤ 15)") nota("costo de provisión: la aportación federal es proxy parcial (el estado añade nómina y gasto propio)")
_nlflujo SALUDFED recibe 2 ind:afil_ssa    eofp:XAC33B+fed:nlPSS pef:2     "FASSA + PSS: salud federalizada (afiliación SSA)", padre(FEDERALIZADO) unidad("afiliado SSA") clave("afiliación a institución federal/estatal de salud (inst_6 = 6, D3). DIVERGENCIA DECLARADA: la clave del motor (benef_ssa) reparte salud por gasto privado en salud del hogar; el motor no se toca") nota("nota de composición (resolución 2026-10-08): el año observado suma FASSA + PSS y el Paquete solo FASSA (el PPEF no trae PSS por entidad): los dos años NO son comparables en este nodo")

* ===== overrides del lado RECIBE heredado: hoy ninguno (todo en inventario, abrir 0, ancla suma = supuesto). Ejemplos: =====
* _nloverride PENSIONES, abrir(1) ancla_ref(pef:50/13+50/15+50/14) ancla_pe(pef:50/13+50/15+50/14)
* _nloverride EDUCACION, variable(perfiles:Educacion)
