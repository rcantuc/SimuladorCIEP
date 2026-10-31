# `/metodo` — Capítulo 0: Requerimientos para replicar el simulador

*Borrador para 8.18 y para el equipo de Colombia. Cada fila nace de la sección 9 de un capítulo de módulo. Tres columnas: cómo lo resuelve México → qué se necesita genéricamente → candidato colombiano. La columna Colombia es un punto de partida: **todo lo marcado ⚠ debe verificarlo el equipo local** (nombres, periodicidad, acceso a microdatos, nivel departamental).*

## 0.1 Criterio de viabilidad

Un módulo se replica si **todas** sus filas tienen equivalente con el mismo nivel de desagregación (persona, edad simple, sexo, unidad subnacional). Si una fila no tiene equivalente, hay tres salidas, en orden de preferencia: (a) fuente alterna del mismo nivel; (b) imputación declarada con sello rojo; (c) el módulo no se replica y se documenta la ausencia. Nunca se rellena en silencio.

## 0.2 Tabla de requerimientos

| # | Módulo | México | Requerimiento genérico | Colombia (candidato) |
|---|---|---|---|---|
| 1 | Población | CONAPO, proyecciones por edad simple, sexo y entidad (vintage anual) | Proyecciones oficiales por **edad simple** (0–100+), sexo y unidad subnacional, serie que cubra los años de la encuesta y del SCN | DANE, proyecciones de población base CNPV 2018, nacional y departamental por edad y sexo ⚠ verificar edad simple hasta 100+ por departamento |
| 2 | Hogares: ingreso | ENIGH (bienal 2016–2024): ingreso por persona y fuente, folio hogar/persona, factor de expansión, cotización a seguridad social | Encuesta de hogares con **ingreso por fuente a nivel persona**, factor, identificador hogar-persona, afiliación a seguridad social, representativa por unidad subnacional | GEIH (mensual, módulo de ingresos; afiliación a pensión/salud; representativa por departamento) ⚠ versión y año base; la GEIH no trae gasto |
| 3 | Hogares: gasto | ENIGH, gasto por rubro con clave de bien, mismo folio que ingreso | Gasto del hogar por **rubro clasificable** (alimentos, salud, educación, etc.) ligado al mismo hogar que el ingreso, para incidencia de impuestos indirectos y consumo privado por edad | ENPH 2016–17 (ingreso y gasto en la misma encuesta, representativa por ciudad/departamento ⚠). Decisión de diseño: usar ENPH como base única (ingreso + gasto, pero vieja) o GEIH + ENPH con *matching* (declarado, sello amarillo) |
| 4 | Cuentas nacionales por sector | INEGI, cuentas por sector institucional (CSI; BIE como vintage alterno): S.11, S.12, S.13, S.14, S.15, S.2; partidas D.1, B.2n, B.3n, D.4, D.5, D.61, D.62, D.63, D.7, D.8, B.5n, B.6n, B.8n, B.9 | **Cuentas económicas integradas por sector institucional**, con hogares separados de ISFLSH si es posible; al menos 5 años consecutivos; vintage identificable | DANE, Cuentas Económicas Integradas (CEI) por sector institucional ⚠ verificar si S.14 y S.15 vienen separados y hasta qué año |
| 5 | PIB y deflactores | INEGI, PIB nacional y PIBE por entidad; deflactor implícito | PIB nacional y **subnacional** nominal, mismo año base, deflactor | DANE, PIB nacional y Cuentas Departamentales ⚠ rezago del PIB departamental (≈2 años) |
| 6 | Gasto público funcional | Cuenta Pública (SHCP), clasificación funcional y económica CONAC, Transparencia Presupuestaria; ramos 28 y 33 para lo estatal | Gasto **ejecutado** (no aprobado) por función y por nivel de gobierno, con clasificación que permita separar consumo individual (salud, educación, pensiones) de colectivo | SIIF Nación / MHCP para el gobierno nacional; FUT (Formulario Único Territorial) para departamentos y municipios ⚠ homologar clasificaciones; SGP y SGR como transferencias territoriales |
| 7 | Ingresos públicos | LIF, recaudación SAT por impuesto (ISR PF/PM, IVA, IEPS, ISAN, importaciones), Cuenta Pública | Recaudación **efectiva** por impuesto y, para lo subnacional, ingresos propios por unidad | DIAN, estadísticas de recaudo por impuesto (renta personas naturales/jurídicas, IVA, consumo); MHCP; ingresos propios departamentales (licores, cerveza, vehículos, registro) ⚠ vía FUT |
| 8 | Legislación fiscal parametrizable | LISR tarifas y subsidio al empleo; LIVA tasas y exenciones por bien; cuotas IMSS/ISSSTE/INFONAVIT por rango salarial | Tarifas, umbrales, tasas y exenciones **en forma de parámetros** (tabla por año), no texto | Estatuto Tributario: tarifa de renta personas naturales en UVT, IVA 19 % / 5 % / excluidos por bien, aportes salud 4 % + pensión 4 % del trabajador, aportes del empleador y parafiscales ⚠ tabla por año y la UVT anual |
| 9 | Pensiones | IMSS, ISSSTE, Pensión Bienestar: beneficiarios y monto por edad y sexo; Ley 73/97 | Pensiones contributivas y no contributivas con **perfil por edad y sexo** de beneficiarios y de cotizantes | Colpensiones (RPM), fondos privados (RAIS), Colombia Mayor; Superfinanciera para RAIS ⚠ acceso a perfil por edad |
| 10 | Salud | IMSS, ISSSTE, IMSS-Bienestar: gasto y derechohabiencia; perfil de gasto por edad | Gasto público en salud **por edad y sexo** (o perfil de uso) y población cubierta por régimen | SGSSS: UPC por grupo etario y sexo (ADRES/MinSalud) — ventaja: Colombia ya publica un perfil por edad; régimen contributivo vs subsidiado ⚠ gasto efectivo vs UPC |
| 11 | Educación | SEP matrícula por nivel y edad; gasto por nivel | Matrícula por **nivel y edad** y gasto público por nivel, nacional y subnacional | SIMAT / MEN (básica y media), SNIES (superior); gasto vía SGP educación ⚠ edad simple en SIMAT |
| 12 | Informalidad | ENIGH: cotización, contrato, prestaciones → modelo de probabilidad; corte por ranking (8.14) o esperanza `p×obligación` (8.16) | Variable de **afiliación/cotización a nivel persona** en la encuesta de ingreso, y una definición oficial de informalidad para validar | GEIH: afiliación a pensiones y salud (contributivo); definición DANE de informalidad (empresas ≤5 personas) ⚠ elegir definición y declararla |
| 13 | Deuda y balance | SHCP: SHRFSP, costo financiero, balance presupuestario; deuda estatal por entidad | Deuda, costo financiero y balance del gobierno general, y deuda subnacional por unidad | MHCP / Banco de la República; deuda territorial vía MHCP (Ley 358 semáforos) ⚠ |
| 14 | Unidad subnacional | 32 entidades; contrato-32: celdas n<100 selladas, participaciones, PIBE, Ley de Ingresos estatal (9.x) | Lista cerrada de unidades con **representatividad muestral** en la encuesta, PIB propio, transferencias recibidas e ingresos propios | 32 departamentos + Bogotá D.C. (33 unidades); GEIH representativa por departamento ⚠ tamaños de muestra por celda edad×sexo×departamento; SGP/SGR como transferencias |
| 15 | Remesas | Banxico, remesas familiares; ENIGH ingreso del exterior | Remesas recibidas (balanza de pagos) y su contraparte en la encuesta | Banco de la República, remesas de trabajadores; GEIH ingresos del exterior ⚠ |
| 16 | NTA de referencia | NTA México (perfiles publicados) para contraste | Un NTA nacional **publicado** contra el cual validar perfiles por edad (no es insumo, es gate humano) | NTA Colombia (Urdinola y colaboradores, red NTA) ⚠ año de referencia |

## 0.3 Requerimientos de procedimiento (no de datos)

| Requerimiento | México | Genérico |
|---|---|---|
| Motor | Stata (licencia); `SIM.do` lineal; ningún número nace fuera del motor | Un motor reproducible con un punto de entrada único y un log que cuente la historia |
| Ajuste encuesta–SCN | Altimir por variable contra su celda (principio C) | Tabla de correspondencia encuesta → SCN **antes** de escribir código; una celda por variable |
| Reparto de sector a persona | Reglas propiedad / incidencia / per cápita con sello (principio B) | Toda partida de sector lleva una regla declarada; per cápita es el default honesto |
| Gates | `gate-numeros.sh`, identidad NTA, contrato-N, paridad web = batch | Al menos: identidad contable por módulo, paridad de dos caminos, protección de números publicados |
| Versionado y cita | Tags, sidecar `datos-<v>.zip` con sha256, `CITATION.cff` | Cada número publicado es rastreable a un commit y a un vintage |
| Equipo | Una persona dueña del método + agentes para ejecución; un entregable por sesión | Separar quién decide (método) de quién ejecuta (código); decisión = parámetro + FLAG |

## 0.4 Lo que México no tiene y Colombia sí (ventajas al replicar)

- Perfil de gasto en salud por edad **oficial** (UPC por grupo etario): México lo imputa.
- Ingreso y gasto en una misma encuesta (ENPH): evita el *matching*, a costa de antigüedad.
- Unidad subnacional con régimen de transferencias más reglado (SGP por fórmula): facilita la incidencia del gasto territorial.

## 0.5 Lo que Colombia probablemente no tiene (riesgos)

- Encuesta de ingreso reciente **con gasto** (GEIH no lo trae): decisión de diseño obligatoria antes de empezar (fila 3).
- Perfil por edad de pensionados y cotizantes en RAIS (fondos privados): posible sello rojo en pensiones (fila 9).
- Rezago de cuentas departamentales (fila 5): la unidad subnacional puede quedar un año detrás del nacional.

## 0.6 Siguiente paso para el equipo de Colombia

Llenar la columna Colombia sin ⚠: para cada fila, nombre exacto de la fuente, año más reciente con microdatos accesibles, nivel de desagregación real (edad simple sí/no, departamento sí/no), y enlace. Con esa tabla llena se decide qué módulos entran en la primera versión y cuáles esperan.
