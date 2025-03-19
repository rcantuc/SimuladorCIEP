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

