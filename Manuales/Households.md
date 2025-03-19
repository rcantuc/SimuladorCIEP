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

1. **households.dta:**  
   