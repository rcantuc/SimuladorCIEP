# Simulador Fiscal: Households

**Versión:** 17 de marzo de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

## Households.do


#<h3 style="color: #ff7020;">1. Input:</h3>

**Fuentes Macroeconómicas:**

Para obtener las información macroeconómica se utilizan los datos generados a través de los siguientes programas del SimuladorFiscal.

1. PIBDeflactor: Importa y procesa los datos económicos de. Los datos provienen del INEGI y BIE.

2. SCN: Importa y procesa los datos Sistema de Cuentas Nacionales. Para este programa se utilizan datos del INEGI.

3. LIF: Importa y procesa datos sobre los ingresos de la federación, utilizando información oficial de la SHCP y el INEGI.

**Fuentes Microeconómicas:**

Para obtener los datos microeconmicos se utiliza información generada por el SimuladorFiscal y encuestas del INEGI.

1. Deducciones.dta: Resume a nivel hogar los gastos que pueden ser considerados deducciones personales para el ISR. Esta base es generada por el programa `Expenditure.do`.
2. ENIGH: Se utiliza información de seis tablas de la ENIGH: población, concentrado, trabajos y vivienda.


#<h3 style="color: #ff7020;">2.Output:</h3>

Households.do produce varios archivos intermedios y un archivo final que sirven para el análisis y la toma de decisiones en el simulador fiscal:

1. **households.dta:** Archivo principal con microdatos armonizados de hogares

---

<h3 style="color: #ff7020;">3. Información técnica:</h3>

**A. Archivos ENIGH procesados (inputs):**
- `ingresos.dta`: Ingresos por fuente y persona de la ENIGH
- `poblacion.dta`: Características demográficas de personas
- `concentrado.dta`: Información agregada por hogar (factor de expansión)
- `trabajos.dta`: Características de empleos por persona
- `vivienda.dta`: Características de la vivienda
- `deducciones.dta`: Gastos deducibles calculados por Expenditure.do

**B. Variables macroeconómicas integradas:**
- Deflactor del PIB (PIBDeflactor.ado)
- Cuentas nacionales (SCN.ado)
- Ingresos federales (LIF.ado)
- Parámetros fiscales: UMA, UDIS, subsidio al empleo

**C. Variables principales generadas:**
- `ing_sueldos`: Ingresos por sueldos y salarios
- `ing_mixto`: Ingreso mixto (trabajo independiente)
- `ing_capital`: Ingresos de capital (rentas, dividendos)
- `ing_estim_alqu`: Alquiler imputado de vivienda propia
- `ing_total`: Ingreso total del hogar
- `cuotasIMSS`, `cuotasISSSTE`: Contribuciones a seguridad social
- `isrE`: ISR efectivo pagado
- `SE`: Subsidio al empleo recibido
- `formal`: Indicador de formalidad laboral
- `beta`: Coeficiente para ajuste distributivo

**D. Metodología de armonización:**
- **Escalamiento a SCN**: Los microdatos ENIGH se escalan para coincidir con agregados de cuentas nacionales
- **Imputación de alquileres**: Se calcula renta imputada para viviendas propias
- **Cálculo de ISR**: Se simula el impuesto sobre la renta por persona
- **Formalidad laboral**: Clasificación basada en afiliación a seguridad social
- **Ajuste distributivo**: Parámetro beta para calibración con datos macro

**E. Períodos de datos disponibles:**
- ENIGH 2014, 2016, 2018, 2020, 2022, 2024
- Parámetros fiscales específicos por año:
  - UMA: 73.04 (2016) → 248.93 (2024)
  - UDIS: 5.45 (2016) → 8.15 (2024)
  - Subsidio al empleo: 43,707 (2016) → 32,841 MDP (2024)

**F. Archivos de salida:**
- `04_master/[año]/households.dta`: Base principal con ~74,000 observaciones (personas)
- `03_temp/[año]/households.smcl`: Log detallado del procesamiento
- Variables agregadas por decil, formal/informal, tipo de ingreso

**G. Características del archivo final:**
- **Unidad de observación**: Personas (numren)
- **Factor de expansión**: `factor` (poblacional)
- **Variables de identificación**: `folioviv`, `foliohog`, `numren`
- **Montos**: En pesos corrientes del año correspondiente
- **Cobertura**: Nacional, representativa de hogares mexicanos

**H. Indicadores calculados:**
- Distribución del ingreso por deciles
- Incidencia fiscal por tipo de impuesto
- Brecha de formalidad laboral
- Elasticidades ingreso-gasto por categoría
- Progresividad del sistema tributario

**I. Dependencias externas:**
- PIBDeflactor.ado
- SCN.ado  
- LIF.ado
- Expenditure.do (para deducciones.dta)
- ENIGH oficial del INEGI  
   