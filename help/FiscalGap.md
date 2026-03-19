# Manual de usuario para el comando `FiscalGap`

El programa `FiscalGap`, definido en el archivo `FiscalGap.ado`, forma parte del análisis económico y fiscal del "Simulador Fiscal CIEP". Este manual detalla cada sección del código y describe su función dentro del programa.

## Sintaxis

Antes de iniciar, el código Stata realiza las siguientes operaciones:

1. Inicia un temporizador para medir el tiempo de ejecución del código.
2. Obtiene la fecha actual y la almacena en la variable local `fecha`. Extrae el año de la fecha y lo almacena en la variable local `aniovp`.
3. Verifica si existe un escalar llamado `aniovp`. Si existe, actualiza el valor de la variable local `aniovp` con el valor del escalar. Este escalar se define en `profile.do`.
4. Define la sintaxis. Este comando acepta varias opciones y argumentos.

```stata
FiscalGap [, NOGraphs Anio(int año_actual) BOOTstrap(int 1) Update END(int 2100) ANIOMIN(int 2000) DIScount(real 5) DESDE(int año_anterior)]
```

### Opciones principales:

- `NOGraphs`: Una opción que, si se especifica, indica que no se deben generar gráficos.
- `Anio(integer)`: Especifica el año de inicio para el análisis. El valor predeterminado es el año actual.
- `BOOTstrap(integer)`: Número de iteraciones bootstrap. Valor predeterminado: 1.
- `Update`: Opción para actualizar datos (uso interno).
- `END(integer)`: Especifica el año final para el análisis. El valor predeterminado es 2100.
- `ANIOMIN(integer)`: Especifica el año mínimo para el análisis. El valor predeterminado es 2000.
- `DIScount(real)`: Especifica la tasa de descuento para el análisis de valor presente. El valor predeterminado es 5%.
- `DESDE(integer)`: Especifica el año de inicio para el cálculo de los crecimientos para la LIF y el PEF. El valor predeterminado es el año anterior al año especificado en el escalar `aniovp`.

## Dependencias

### Programas .ado requeridos:
- `PIBDeflactor.ado`: Para obtener datos del PIB, deflactor, población y proyecciones
- `SHRFSP.ado`: Para análisis de deuda y pasivos del sector público
- `LIF.ado`: Para proyección de ingresos tributarios
- `PEF.ado`: Para proyección de gastos públicos

### Archivos de datos requeridos:
- `ingresos.dta`: Base de microdatos de ingresos por hogar
- `gastos.dta`: Base de microdatos de gastos por hogar  
- `LIF.dta`: Datos históricos de ingresos por tipo de impuesto
- `PEF.dta`: Datos históricos de gastos por tipo
- Archivos bootstrap por tipo de impuesto: `{IMPUESTO}REC.dta`

### Variables globales requeridas:
- `$pais`: Nombre del país para el análisis
- `$id`: Identificador del usuario
- `$textbook`: Parámetros para modo textbook
- `$nographs`: Supresor global de gráficos
- `$output`: Habilitador de salida estructurada

## 1. PIB (Producto Interno Bruto)

```stata
PIBDeflactor, anio(`=aniovp') geopib(`desde') geodef(`desde') nographs nooutput
replace Poblacion = Poblacion*lambda
replace Poblacion0 = Poblacion0*lambda
keep if anio <= `end'
local currency = currency[1]
local llambda = real(llambda)
tempfile PIB
save `PIB'
```

**Descripción:** Se utiliza el comando `PIBDeflactor` para obtener:
- Series de PIB nominal y real
- Deflactor del PIB
- Proyecciones poblacionales ajustadas por lambda
- Tipo de moneda del análisis

Los datos se filtran hasta el año final especificado y se guardan en un archivo temporal para uso posterior.

## 2. SHRFSP (Saldos Históricos de Requerimientos de Financiamiento del Sector Público)

```stata
noisily SHRFSP, anio(`anio') nographs $textbook //update
tempfile shrfsp
save `shrfsp'
```

**Descripción:** Se ejecuta un procesamiento de pasivos y deuda del sector público utilizando el comando `SHRFSP`. Los resultados incluyen:
- Deuda neta del sector público
- Requerimientos de financiamiento
- Proyecciones de balance primario
- Costo de la deuda

## 3. HOUSEHOLDS (Análisis de Microdatos de Hogares)

```stata
use "`c(sysdir_site)'/users/$id/ingresos.dta", clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen update
foreach k in Educacion Pensiones Pensión_AM Salud OtrosGastos IngBasico OtrasInversiones Federalizado Energia {
    tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
    tempname HH`k'
    matrix `HH`k'' = r(StatTotal)
}
```

**Descripción:** Carga y procesa microdatos de la encuesta de hogares para obtener:

### Categorías de gasto analizadas:
- **Educación**: Gasto total en educación
- **Pensiones**: Contribuciones a sistemas de pensiones
- **Pensión_AM**: Pensión para adultos mayores
- **Salud**: Gasto en salud
- **OtrosGastos**: Otros gastos gubernamentales
- **IngBasico**: Ingreso básico universal
- **OtrasInversiones**: Otras inversiones públicas
- **Federalizado**: Gasto federalizado
- **Energía**: Subsidios energéticos

Para cada categoría se calcula el total ponderado por factor de expansión y se almacena en matrices `HH{categoria}`.

## 4. Fiscal Gap: Ingresos

```stata
noisily di _newline in g "  INGRESOS " in y "`desde'-`anio'"
LIF if divLIF != 10, anio(`anio') nographs by(divSIM) min(0) desde(`desde')
local divSIM = r(divSIM)
```

**Descripción:** Analiza y proyecta los ingresos fiscales utilizando tendencias históricas y demográficas.

### 4.1 Categorías de ingresos analizadas:
- **CFE**: Comisión Federal de Electricidad
- **CUOTAS**: Cuotas de seguridad social
- **FMP**: Fondo Mexicano del Petróleo
- **IEPSNP**: IEPS no petrolero
- **IEPSP**: IEPS petrolero
- **IMPORT**: Aranceles a importaciones
- **IMSS**: Instituto Mexicano del Seguro Social
- **ISAN**: Impuesto sobre automóviles nuevos
- **ISRAS**: ISR asalariados
- **ISRPF**: ISR personas físicas
- **ISRPM**: ISR personas morales
- **ISSSTE**: Instituto de Seguridad y Servicios Sociales de los Trabajadores del Estado
- **IVA**: Impuesto al valor agregado
- **OTROSK**: Otros impuestos al capital
- **PEMEX**: Petróleos Mexicanos

### 4.2 Metodología de proyección:
Para cada tipo de ingreso se calcula:

1. **Tasa de crecimiento demográfico**: Basada en contribuyentes históricos
2. **Tasa total de crecimiento**: Del módulo LIF.ado  
3. **Componente per cápita**: Tendencia total menos crecimiento demográfico
4. **Proyección**: 
   ```stata
   estimacion = (contribuyentes/L.contribuyentes) * 
                (PIB_parametro) * 
                (1+tendencia_pc/100)^(anio-anio_base)
   ```

### 4.3 Agrupaciones para gráficos:
- **Impuestos laborales**: CUOTAS, ISRAS, ISRPF
- **Impuestos al consumo**: IEPSNP, IEPSP, IVA, ISAN, IMPORT  
- **Impuestos al capital**: ISRPM, OTROSK, FMP
- **Organismos y empresas**: CFE, IMSS, ISSSTE, PEMEX

## 4.4 Gráficos de ingresos

Si no se especifica `nographs`, se generan:
- **Proy_ingresos1**: Ingresos históricos observados por categoría
- **Proy_ingresos2**: Ingresos proyectados por categoría
- **grc_ingresos**: Gráfico combinado (requiere `grc1leg2`)

```stata
graph export "`c(sysdir_site)'/users/$id/graphs/ingresos_`anio'.pdf", as(pdf) replace
tabout anio using "`c(sysdir_site)'/users/$id/tablas/ingresos_`anio'.csv" if anio >= `aniomin', ///
    sum cells(sum recaudacion_pib sum estimacionRecaudacion_pib) format(%9.1fc) replace
```

## 5. Fiscal Gap: Gastos

```stata
noisily di _newline in g "  GASTOS " in y "`desde'-`anio'"
noisily PEF if transf_gf == 0, anio(`anio') by(divCIEP) nographs desde(`desde')
```

**Descripción:** Proyecta gastos públicos por categoría utilizando tendencias del PEF y ajustes demográficos.

### 5.1 Categorías principales de gasto:
- **Educación**: Gasto educativo
- **Salud**: Gasto en salud
- **Energía**: Subsidios energéticos  
- **Pensiones**: Sistema de pensiones
- **IngBasico**: Ingreso básico universal (si aplica)
- **OtrasInversiones**: Otras inversiones públicas
- **OtrosGastos**: Otros gastos no clasificados
- **Federalizado**: Participaciones federales

### 5.2 Metodología de cálculo:
```stata
replace estimacionGasto = estimacionGasto*deflator + `HH{categoria}'[1,1]*Poblacion0/deflator ///
    if anio >= `anio' & divCIEP == "categoria"
```

El gasto proyectado combina:
- Tendencia histórica ajustada por deflactor
- Impacto de microdatos de hogares
- Ajuste poblacional

## 6. Deuda y Costo de la Deuda

### 6.1 Tasa efectiva promedio ponderada:
```stata
tabstat tasaEfectiva [fw=deuda], stat(mean) f(%9.2f) save
local tasaEfectiva = r(StatTotal)[1,1]
scalar tasaEfectiva = `tasaEfectiva'
```

### 6.2 Costo de la deuda:
- Se calcula usando tasas efectivas históricas ponderadas por saldos de deuda
- Se puede sobrescribir con scalar `gascosto` si está definido
- La proyección usa la metodología: `costo = tasa_efectiva * saldo_deuda`

### 6.3 SHRFSP externo en USD:
```stata
replace shrfsp_ext = shrfsp_ext*tipocambio  
replace shrfsp_externo = shrfsp_ext if anio == `anio'
replace shrfsp_externo = shrfsp_externo*(1+0.03)^(anio-`anio') if anio > `anio'
```

La deuda externa se convierte a pesos y se proyecta con crecimiento del 3% anual.

## 7. Fiscal Gap: Balance y Cuenta Generacional

### 7.1 Cálculo del balance fiscal:
```stata
g balance = estimacionRecaudacion - estimacionGasto - estimacionCosto_de_la_deuda
g balanceVP = balance/(1+`discount'/100)^(anio-`anio') if anio > `anio'
```

### 7.2 Valor presente del balance:
- **ingresoVP**: Valor presente de ingresos futuros
- **gastoVP**: Valor presente de gastos futuros  
- **balanceVP**: Valor presente del balance fiscal futuro
- **poblacionVP**: Valor presente de la población futura

### 7.3 Inequidad intergeneracional:
```stata
noisily di in g "  (*) Deuda generaciones `anio':" ///
    in y %25.0fc (shrfsp/deflator)/poblacion_actual in g " por persona"
noisily di in g "  (*) Deuda generaciones `end':" ///  
    in y %25.0fc (shrfsp_final/deflator)/poblacion_final in g " por persona"
```

Calcula la carga de deuda per cápita para generaciones actuales vs futuras.

## Inputs (Archivos de entrada)

### Archivos de datos requeridos:
1. **`ingresos.dta`**: Microdatos de ingresos por hogar (ENIGH)
   - Variables: `folioviv`, `foliohog`, `numren`, `factor`, categorías de ingreso
2. **`gastos.dta`**: Microdatos de gastos por hogar (ENIGH)  
   - Variables: categorías de gasto por programa social
3. **`LIF.dta`**: Datos históricos de ingresos fiscales
   - Variables: `anio`, `divSIM`, `recaudacion`
4. **`PEF.dta`**: Datos históricos de gastos públicos
   - Variables: `anio`, `divCIEP`, `gasto`, `transf_gf`
5. **Archivos bootstrap**: `{IMPUESTO}REC.dta` para cada tipo de impuesto
   - Variables: `anio`, `modulo`, `aniobase`, `estimacion`, `contribuyentes`

### Scalares globales utilizados:
- **Tasas de crecimiento por impuesto**: `{IMPUESTO}C` (ej: `IVAC`, `ISRPFC`)
- **Parámetros como % del PIB**: `{IMPUESTO}PIB`  
- **PIB**: `pibY`
- **Costo de deuda**: `gascosto` (opcional)
- **Tasa efectiva**: `tasaEfectiva` (opcional)

## Outputs (Archivos y variables generadas)

### Archivos exportados:
1. **Gráficos PDF**:
   - `graphs/ingresos_{anio}.pdf`: Gráficos de ingresos históricos y proyectados
   - `graphs/gastos_{anio}.pdf`: Gráficos de gastos por categoría
   - `graphs/balance_{anio}.pdf`: Balance fiscal proyectado
   - `graphs/shrfsp_{anio}.pdf`: Evolución de la deuda pública

2. **Tablas CSV**:  
   - `tablas/ingresos_{anio}.csv`: Ingresos como % del PIB por año
   - `tablas/gastos_{anio}.csv`: Gastos como % del PIB por año
   - `tablas/balance_{anio}.csv`: Balance fiscal por año

3. **Dataset final**: Variables en memoria al terminar
   - `anio`: Año
   - `recaudacion`, `estimacionRecaudacion`: Ingresos observados vs proyectados
   - `gasto`, `estimacionGasto`: Gastos observados vs proyectados  
   - `balance`: Balance fiscal (ingresos - gastos - costo_deuda)
   - `shrfsp`: Saldos históricos de requerimientos de financiamiento
   - `*_pib`: Todas las variables anteriores como % del PIB
   - `*VP`: Valores presentes descontados

### Variables de retorno (scalars):
- **`r(pibY)`**: PIB del año base en moneda local
- **`r(currency)`**: Tipo de moneda ("MXN", "USD", etc.)
- **`r(anio_base)`**: Año base del análisis
- **`r(tasa_descuento)`**: Tasa de descuento utilizada
- **`r(deuda_per_capita_actual)`**: Deuda per cápita generación actual
- **`r(deuda_per_capita_futura)`**: Deuda per cápita generación futura

### Matrices de retorno:
- **`r(ingresoVP)`**: Valor presente de ingresos por categoría
- **`r(gastoVP)`**: Valor presente de gastos por categoría  
- **`r(balanceVP)`**: Valor presente del balance fiscal
- **`r(HH_Education)`**, **`r(HH_Pensions)`**, etc.: Totales por categoría de microdatos

## Ejemplos prácticos

### Ejemplo 1: Análisis básico
```stata
FiscalGap, anio(2024) end(2050) discount(3.5)
```

### Ejemplo 2: Proyección de largo plazo sin gráficos
```stata  
FiscalGap, anio(2024) end(2100) discount(5) nographs
```

### Ejemplo 3: Análisis con año mínimo específico
```stata
FiscalGap, anio(2024) aniomin(2010) desde(2020) discount(4)
```

## Ver también

### Programas relacionados:
- **`PIBDeflactor`**: Genera proyecciones macroeconómicas base
- **`SHRFSP`**: Analiza deuda y pasivos del sector público  
- **`LIF`**: Proyecta ingresos tributarios por tipo de impuesto
- **`PEF`**: Proyecta gastos públicos por programa
- **`Poblacion`**: Genera proyecciones demográficas
- **`TasasEfectivas`**: Calcula tasas efectivas de deuda pública

### Archivos de configuración:
- **`profile.do`**: Define parámetros globales y scalars base
- **`Simulador.ado`**: Programa principal que orquesta la secuencia completa

## Notas técnicas

### Limitaciones:
1. **Tasa de descuento**: Debe ser mayor que la tasa de crecimiento de largo plazo para evitar divergencia en valor presente
2. **Calidad de datos**: Los resultados dependen críticamente de la calidad de los microdatos y series históricas
3. **Supuestos de proyección**: Las tendencias de crecimiento se mantienen constantes en el tiempo

### Tiempo de ejecución:
El programa incluye un timer que reporta el tiempo total de ejecución al final. Para datasets grandes puede tomar varios minutos.

### Manejo de errores:
- Validación automática de tasas de crecimiento vs descuento
- Manejo de datos faltantes en series históricas
- Verificación de existencia de archivos requeridos

---

El manual proporciona directrices claras sobre el uso de cada sección del programa `FiscalGap`. Para aplicaciones específicas o modificaciones para un análisis preciso, el usuario debe tener un conocimiento adecuado en economía y estadística y se recomienda la colaboración con los creadores del simulador o expertos en la materia.