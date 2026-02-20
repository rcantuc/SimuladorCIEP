# Simulador Fiscal CIEP: Expenditure

Versión: 17 de marzo de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

## Expenditure.do

**Descripción:**  Do.File diseñado para integrar información económica mediante la armonización de datos macroeconómicos y microeconómicos. El programa consolida diversas fuentes oficiales y produce, varias bases de datos que permiten evaluar el comportamiento del gasto.


<h3 style="color: #ff7020;">1. Input:</h3>

En este programa se utilizan diversas fuentes de datos macroeconómicas y microeconómicas:

**Fuentes Macroeconómicas:**

Para obtener las información macroeconómica se utilizan los datos generados a través de los siguientes programas del SimuladorFiscal.

1. SCN: Importa y procesa los datos Sistema de Cuentas Nacionales. Para este programa se utilizan datos del INEGI.

2. LIF: Importa y procesa datos sobre los ingresos de la federación, utilizando información oficial de la SHCP y el INEGI. 

3. Población: Importa los datos de población. Los datos provienen de la CONAPO.

**Fuentes Microeconómicas:**

Para obtener las cifras microeconómicas, se utiliza información de encuestas del INEGI.

1. ENIGH: Se utilizan información de seis tablas de la ENIGH: gastospersona, gastohogar, gastotarjetas, erogaciones, concentrado y vivienda.

2. Censo Económico:  Se utiliza información del Censo Económico.



<h3 style="color: #ff7020;">2. Output:</h3>

El programa devolverá una base final, `expenditures.dta`, y tres bases intermedias, `preconsumption.dta`, `deducciones.dta`y `consumption_categ_pc.dta` .  

1. Expenditures.dta: Es el producto final del proceso de armonización de los datos microeconómicos con información macroeconómica. 
2. Preconsumption.dta: Contiene la base microeconómica de gastos de hogares y personas después de haber sido limpiada, unida y procesada.
3. Deducciones.dta: Resume a nivel hogar los gastos que pueden ser considerados deducciones personales para el ISR.
4. consumption_categ_pc.dta: Es la base final que integra el consumo de individuos y hogares, desagregado en categorías.

---

<h3 style="color: #ff7020;">3. Información técnica:</h3>

**A. Archivos ENIGH procesados (inputs):**
- `gastospersona.dta`: Gastos individuales por persona
- `gastohogar.dta`: Gastos del hogar (compartidos)
- `gastotarjetas.dta`: Gastos con tarjetas de crédito/débito
- `erogaciones.dta`: Erogaciones y pagos especiales
- `concentrado.dta`: Información agregada del hogar
- `vivienda.dta`: Características de la vivienda
- `clave_iva.dta`: Clasificación de gastos por tasa de IVA
- `censo_eco_municipios.dta`: Información del Censo Económico municipal

**B. Variables principales generadas:**
- `gasto_pc`: Gasto per cápita por categoría
- `gasto_total`: Gasto total del hogar
- `iva_pagado`: IVA implícito pagado por producto
- `tasa_iva`: Tasa de IVA aplicable (0%, 8%, 16%)
- `decil`: Decil de gasto del hogar
- `factor`: Factor de expansión poblacional
- `categoria`: Clasificación de gasto (alimentos, transporte, etc.)

**C. Categorías de gasto procesadas:**
- **Alimentos y bebidas**: Incluye dentro y fuera del hogar
- **Transporte**: Público, privado, combustibles
- **Vivienda**: Alquiler, servicios, mantenimiento
- **Vestido y calzado**: Ropa, calzado, accesorios
- **Salud**: Medicamentos, consultas, seguros médicos
- **Educación**: Colegiaturas, libros, materiales
- **Comunicaciones**: Teléfono, internet, correo
- **Esparcimiento**: Entretenimiento, vacaciones, deportes

**D. Cálculos fiscales integrados:**
- **IVA implícito**: Calculado por producto según tasa aplicable
- **Deducciones ISR**: Gastos deducibles personales
- **Elasticidades**: Gasto-ingreso por categoría
- **Incidencia fiscal**: Carga tributaria por decil

**E. Archivos de salida generados:**
- `03_temp/[año]/preconsumption.dta`: Base intermedia limpia (~200,000 obs)
- `04_master/[año]/deducciones.dta`: Deducciones por hogar (~74,000 obs)
- `04_master/[año]/consumption_categ_pc.dta`: Consumo por categoría per cápita
- `04_master/[año]/expenditures.dta`: Base final armonizada con SCN
- `03_temp/[año]/pre_iva.dta`, `pre_iva_final.dta`: Archivos intermedios IVA

**F. Metodología de armonización:**
- **Escalamiento macro**: Gastos ENIGH se escalan a totales de SCN
- **Imputación IVA**: Se calcula IVA implícito por producto/servicio
- **Clasificación sectorial**: Se asigna actividad económica por gasto
- **Corrección estacional**: Ajustes por diferencias temporales
- **Validación cruzada**: Verificación con agregados macroeconómicos

**G. Variables de clasificación:**
- `clave`: Código de gasto ENIGH (6 dígitos)
- `actividad_eco`: Sector de actividad económica
- `formal`: Establecimiento formal/informal
- `region`: Región geográfica
- `area`: Urbano/rural
- `tam_loc`: Tamaño de localidad

**H. Períodos disponibles:**
- ENIGH 2014, 2016, 2018, 2020, 2022, 2024
- Compatible con mismos años de Households.do
- Datos deflactados a precios constantes

**I. Dependencias externas:**
- SCN.ado (cuentas nacionales)
- LIF.ado (ingresos federales)
- Poblacion.ado (población CONAPO)
- ENIGH completa del INEGI
- Censo Económico del INEGI

**J. Usos en el simulador:**
- Cálculo de bases gravables del IVA
- Simulación de cambios en tasas impositivas
- Análisis distributivo del gasto público
- Elasticidades para modelos de equilibrio general

