*! nl-flujos.do  v0.1.0 (C3, sprint NL-0.6.x "Ida y vuelta por quintil") — PALETA DE FLUJOS: el ÚNICO bloque editable.
*
* Lo lee FederacionNLQuintiles.do (run) y de aquí se deriva TODO: el JSON hermano, las columnas del Sankey, el letrero
* de alcance, los pies y las autocomprobaciones. La vista (federacion-nl.html) no tiene ninguna lista cableada: pinta lo
* que esta paleta diga. Añadir un flujo = UNA línea. La metodología (qué flujos entran, con qué clave se reparten, con
* qué ancla cierran) la decide Ricardo aquí; el driver solo ejecuta. No se corre solo: requiere los programas _nlflujo y
* _nlparam que define el driver.
*
* SINTAXIS DE CADA FLUJO (una línea):
*   _nlflujo <id> <lado> <abrir> <variable> <ancla_ref> <ancla_pe> "<etiqueta>" [, grupo(<g>) banda unidad(<u>) clave(<txt>) nota(<txt>) anclas(<txt>)]
*
*   id        clave corta única (mayúsculas, sin espacios); es la clave del JSON y de la vista.
*   lado      paga | recibe | aparte        (aparte = se dibuja fuera del nodo Federación y no se suma: cuotas IMSS).
*   abrir     0 = INVENTARIO: listado en el JSON con sus números (totales, quintiles, n por celda), NO entra a la página
*                 ni al balance. Es el estado de arranque del gasto distribuido por el motor: Ricardo revisa cada uno
*                 con sus cifras antes de encenderlo.
*             1 = EN PÁGINA SIN ABRIR: nodo cerrado con sus sellos (concTop1 de NL, celdas bajo el umbral); entra al balance.
*             2 = ABIERTO POR QUINTIL: cinco celdas, cada una con sus sellos (n, hogares, concTop1, cumpleN).
*             Ricardo cambia el estado tocando UN número.
*   variable  de dónde sale la clave de reparto por persona (muestra NL, corrida PE vigente):
*               aport:<var>      users/$id/aportaciones.dta  (objeto del pipeline NL; <X>_Sim para impuestos, como C1)
*               perfiles:<var>   master/perfiles<PE>.dta     (objeto del motor nacional, conciliado macro-micro)
*               ind:alum_basica  indicador 0/1: alumno de educación básica pública (alum_basica, GastoPC.ado)
*               ind:afil_ssa     indicador 0/1: afiliación a institución federal/estatal de salud (inst_6 = "6", D3)
*             El peso de reparto es variable × factor; el total NL de la muestra (Σ) viaja al JSON siempre.
*   ancla_ref / ancla_pe   de dónde sale el TOTAL NL del flujo en el año observado y en el año del Paquete:
*               fed:<campo>            campo del arreglo anual de federacion-nl.json para ese año (pagaISRAS, pagaLifISRAS, nlPSS…)
*               eofp:<clave>           subfondo EOFP de ese año (XAC33A = FAEB/FONE…); solo existe para el año observado
*               pef:<pp>               PEF.dta ramo 33, entidad 19, ese año, programa <pp> (13 = FONE SP, 15 = FONE GO, 2 = FASSA)
*               pef:<ramo>/<pp>        PEF.dta cualquier ramo (50 = IMSS, 51 = ISSSTE, 53 = CFE, 11 = SEP, 12 = Salud, 20 = Bienestar…)
*               statajson:<escalar>    escalar de statajson_entidad-nl.json (Rec<X>nl, conciliados con la LIF del PE)
*               suma                   Σ variable × factor de la muestra NL (pesos del PE) → SUPUESTO: se marca en el JSON y en la página
*             Los términos se suman con "+"; un término sin tipo hereda el del anterior: pef:13+15 = pef:13 + pef:15;
*             eofp:XAC33B+fed:nlPSS = FASSA + PSS. Los flujos de C1 conservan HOY su ancla (no cambian de ancla).
*   grupo()   nodo "sin abrir" compartido cuando abrir = 1 (capital, vehicular…); vacío = nodo propio.
*   banda     el flujo lleva la banda [S1, S3] del contrato (hoy solo el ISR PM); abierto: halo por celda = share × banda.
*   unidad()  unidad en especie para el costo de provisión (total / Σ indicador × factor): "alumno de básica pública"…
*   clave()   descripción de la clave de reparto (texto para pies y tooltips).
*   nota()    nota obligatoria que acompaña al nodo (p. ej. nota de composición de salud).
*   anclas()  anclas candidatas encontradas (texto del inventario; no se usan hasta que Ricardo las escriba en la línea).
*
* REGLAS DEL BALANCE (el driver aborta si no se cumplen):
*   · lado paga:   Σ totales de los flujos paga con abrir ≥ 1 = tarjeta paga (cifras.pagaS0NL / pagaPES0NL), reldif 1e-6.
*   · lado aparte: Σ = tarjeta cuotas.
*   · lado recibe: caja gris = tarjeta recibe − Σ flujos recibe con abrir ≥ 1 (calculada; si Ricardo abre más, el gris
*                  encoge solo). Negativa → aborta, salvo parámetro gris_negativo 1.
*
* PARÁMETROS (una línea cada uno):  _nlparam <nombre> <valor> [supuesto]
_nlparam umbral_n          100   supuesto      // n mínimo por celda para que una celda abierta no lleve sello
_nlparam sello_top1        25    supuesto      // % de concentración top-1 de la celda a partir del cual la celda lleva badge visible
_nlparam neta_por_quintil  0     supuesto      // 0 = NO existe neta por quintil (resolución 2026-10-08); 1 = se calcula sobre los flujos abiertos
_nlparam gris_negativo     0     supuesto      // 0 = abortar si la caja gris queda negativa; 1 = exportar con aviso

* ========================= lado PAGA (anclas = contrato federacion-nl.json; las de C1 no cambian) =========================
_nlflujo ISRAS   paga    2  aport:ISRAS_Sim    fed:pagaISRAS    fed:pagaLifISRAS   "ISR a asalariados"
_nlflujo ISRPM   paga    2  aport:ISRPM_Sim    fed:pagaISRPM    fed:pagaLifISRPM   "ISR de personas morales", grupo(capital) banda clave("ISRPM_Sim del objeto de incidencia: ISR PM distribuido por ingresos de capital (Households.do); conciliado macro-micro; una sola observación sostiene ~48 % del ISR PM de NL y ~53 % de la celda Q5")
_nlflujo ISRPF   paga    2  aport:ISRPF_Sim    fed:pagaISRPF    fed:pagaLifISRPF   "ISR de personas físicas", grupo(capital) clave("ISRPF_Sim: ISR de personas físicas con actividad empresarial/profesional; n < 100 en las cinco celdas")
_nlflujo IVA     paga    2  aport:IVA_Sim      fed:pagaIVA      fed:pagaLifIVA     "IVA"
_nlflujo IEPSNP  paga    2  aport:IEPSNP_Sim   fed:pagaIEPSNP   fed:pagaLifIEPSNP  "IEPS no petrolero"
_nlflujo IEPSP   paga    2  aport:IEPSP_Sim    fed:pagaIEPSP    fed:pagaLifIEPSP   "IEPS petrolero (gasolinas)", grupo(vehicular) clave("clave vehicular (gasto en combustibles); n < 100 en Q3 y Q4")
_nlflujo ISAN    paga    2  aport:ISAN_Sim     fed:pagaISAN     fed:pagaLifISAN    "ISAN", grupo(vehicular) clave("misma clave vehicular que el IEPS petrolero")
_nlflujo IMPORT  paga    2  aport:IMPORT_Sim   fed:pagaIMPORT   fed:pagaLifIMPORT  "impuestos a la importación"
* ========================= APARTE (se dibuja fuera de Federación, no se suma) =========================
_nlflujo CUOTAS  aparte  2  aport:CUOTAS_Sim   fed:pagaCUOTAS   fed:pagaLifCUOTAS  "cuotas IMSS (aparte, no sumadas)", nota("su contraparte de gasto (IMSS) está fuera del alcance")
* ========================= lado RECIBE (C1: FONE y salud; anclas EOFP en el observado, PPEF por pp en el Paquete) =========================
_nlflujo FONE    recibe  2  ind:alum_basica    eofp:XAC33A              pef:13+15  "FONE: educación básica (alumnos de escuela pública)", unidad("alumno de básica pública") clave("alumnos de educación básica en escuela pública expandidos (alum_basica de GastoPC.ado: asiste, pública, nivel 01–07, edad ≤ 15)") nota("costo de provisión: la aportación federal es proxy parcial (el estado añade nómina y gasto propio)")
_nlflujo SALUD   recibe  2  ind:afil_ssa       eofp:XAC33B+fed:nlPSS    pef:2      "FASSA + PSS: salud (afiliación SSA)", unidad("afiliado SSA") clave("afiliación a institución federal/estatal de salud (inst_6 = 6, D3). DIVERGENCIA DECLARADA: la clave del motor (benef_ssa) reparte salud por gasto privado en salud del hogar; el motor no se toca") nota("nota de composición (resolución 2026-10-08): el año observado suma FASSA + PSS y el Paquete solo FASSA (el PPEF no trae PSS por entidad): los dos años NO son comparables en este nodo")
* ========================= gasto DISTRIBUIDO POR EL MOTOR (perfiles<PE>.dta): LISTADO, abrir 0 hasta que Ricardo encienda cada uno =========================
* ancla `suma` = SUPUESTO editable; anclas() = candidatas encontradas en EOFP 2025 / PEF.dta NL (cifras en el inventario del reporte C3)
_nlflujo EDUCACION   recibe 0 perfiles:Educacion     suma suma "Educación (gasto del motor)",            clave("costo por alumno según nivel (asistencia a escuela pública, PerfilesSim.do §Educacion) + otros gastos educativos prorrateados") anclas("eofp:XAC33A (FAEB) · eofp:XAC33L (FAETA) · eofp:XAC33G+XAC33H (FAM educación) · fed:nlCD XACCDD (convenios SEP) · pef:13+15 (FONE) · pef:9 (FAETA) · pef:11/6 (convenios ODES) · gasto federal directo (becas pef:11/72, pef:11/311) fuera de la tarjeta")
_nlflujo SALUDM      recibe 0 perfiles:Salud         suma suma "Salud (gasto del motor)",                clave("gasto público en salud por derechohabiencia (benef_*) ponderado por gasto privado en salud del hogar (gas_pc_Salu, GastoPC.ado): clave distinta de la afiliación SSA del flujo SALUD") anclas("eofp:XAC33B (FASSA) · fed:nlPSS (PSS) · pef:2 (FASSA) · gasto federal directo IMSS pef:50/31, ISSSTE pef:51/31, IMSS-Bienestar ramo 56: fuera de la tarjeta")
_nlflujo PENSIONES   recibe 0 perfiles:Pensiones     suma suma "Pensiones contributivas (gasto del motor)", clave("ing_jubila_pub: ingreso por jubilación de personas jubiladas (PerfilesSim.do §Pensiones)") anclas("ninguna en EOFP (gasto federal directo, alcance.excluye) · PEF.dta NL: pef:50/13 (IMSS Ley 1973), pef:50/15, pef:50/14, pef:51/17 (ISSSTE), pef:53/22 (CFE): fuera de la tarjeta recibe")
_nlflujo PENSIONAM   recibe 0 perfiles:Pension_AM    suma suma "Pensión para adultos mayores (gasto del motor)", clave("ing_pam: personas ≥ 65 o con discapacidad que declaran la PAM (PerfilesSim.do §Pension_AM)") anclas("ninguna en EOFP · el PEF no distribuye la PAM por entidad (ramo 20 en NL 2027 = 12.7 mdp): HUECO")
_nlflujo INGBASICO   recibe 0 aport:IngBasico        suma suma "Ingreso básico / transferencias (solo en aportaciones.dta)", clave("IngBasico: en perfiles<PE>.dta es un marcador (1e-20, Σ nacional = 0); en aportaciones.dta viene etiquetado Transferencias") anclas("ninguna: HUECO")
_nlflujo FEDERALIZADO recibe 0 perfiles:Federalizado suma suma "Participaciones y otras aportaciones (gasto del motor, per cápita)", clave("per cápita (relativo(pob), PerfilesSim.do): el motor reparte las transferencias federalizadas NACIONALES por persona") anclas("es el mismo universo que la tarjeta recibe (fed:nlTot / fed:recibePaq): encenderlo con esa ancla vaciaría la caja gris por construcción")
_nlflujo ENERGIA     recibe 0 perfiles:Energia       suma suma "Energía (gasto del motor, per cápita)",   clave("per cápita (relativo(pob))") anclas("ninguna en EOFP · PEF.dta CFE/PEMEX en NL son gasto no federalizado (pef:53/37…): fuera de la tarjeta; el subsidio eléctrico no viene por entidad: HUECO")
_nlflujo OTROSGASTOS recibe 0 perfiles:Otros_gastos  suma suma "Otros gastos (gasto del motor, per cápita)", clave("per cápita (relativo(pob))") anclas("ninguna: HUECO")
_nlflujo INFRA       recibe 0 perfiles:infra_entidad suma suma "Infraestructura por entidad (gasto del motor)", clave("infra_entidad = Σ Infra_* (inversión física federal asignada por entidad)") anclas("ninguna en EOFP · PEF.dta NL no federalizado pef:9/19 (ferroviario 2027), pef:9/40 (2025): fuera de la tarjeta")
_nlflujo OTRASINV    recibe 0 perfiles:Otras_inversiones suma suma "Otras inversiones (gasto del motor)", clave("relativo(infra_entidad): se reparte con la misma clave que INFRA") anclas("ninguna en EOFP · igual que INFRA: fuera de la tarjeta")
