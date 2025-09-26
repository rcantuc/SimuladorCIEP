# Manual de usuario para el comando `FiscalGap`

El programa `FiscalGap`, definido en el archivo `FiscalGap.ado`, forma parte del análisis económico y fiscal del "Simulador Fiscal CIEP". Este manual detalla cada sección del código y describe su función dentro del programa.

## Sintaxis

Antes de iniciar, el código Stata realiza las siguientes operaciones:

1. Inicia un temporizador para medir el tiempo de ejecución del código.
2. Obtiene la fecha actual y la almacena en la variable local `fecha`. Extrae el año de la fecha y lo almacena en la variable local `aniovp`.
3. Verifica si existe un escalar llamado `aniovp`. Si existe, actualiza el valor de la variable local `aniovp` con el valor del escalar. Este escalar se define en `profile.do`.
4. Define la sintaxis. Este comando acepta varias opciones y argumentos.



```stata
syntax [, NOGraphs Anio(int `aniovp') BOOTstrap(int 1) Update END(int 2100) ANIOMIN(int 2000) DIScount(real 5) DESDE(int `=`aniovp'-1')]
```



- `NOGraphs`: una opción que, si se especifica, indica que no se deben generar gráficos.
- `Anio`: un argumento que especifica el año de inicio para el análisis. El valor predeterminado es el año actual.
- `END`: un argumento que especifica el año final para el análisis. El valor predeterminado es 2100.
- `ANIOMIN`: un argumento que especifica el año mínimo para el análisis. El valor predeterminado es 2000.
- `DIScount`: un argumento que especifica la tasa de descuento para el análisis. El valor predeterminado es 5.
- `DESDE`: un argumento que especifica el año de inicio para el cálculo de los crecimientos para la LIF y el PEF. El valor predeterminado es el año anterior al año especificado en el escalar `aniovp`.


## 1. PIB (Producto Interno Bruto)


```stata
PIBDeflactor, nographs nooutput
keep if anio <= `end'
local currency = currency[1]
local anio_last = `anio'
...
tempfile PIB
save `PIB'
```

**Descripción:** Se utiliza el comando `PIBDeflactor` para seleccionar y procesar datos del PIB hasta un año especificado (`end`). Se capturan y almacenan el tipo de moneda y el último año analizado. Los resultados se guardan en un archivo temporal para utilizarlos más tarde.

## 2. SHRFSP (Compartición de Ingresos Fiscales)

```stata
SHRFSP, anio(`anio') nographs //update
tempfile shrfsp
save `shrfsp'
```

**Descripción:** Se ejecuta un procesamiento de recursos fiscales compartidos utilizando el comando `SHRFSP`, enfocado en el año de análisis y sin generar gráficos, y los resultados se guardan en otro archivo temporal.

## 3. HOUSEHOLDS (Hogares)

```stata
use "`c(sysdir_personal)'/users/$id/households.dta", clear
...
foreach k in Educación Pensiones ...
    tabstat `k' [fw=factor], stat(sum) f(%20.0fc) save
    ...
```

**Descripción:** Carga y procesa una base de datos con información a nivel de hogares, eliminando variables anteriores y calculando estadísticas descriptivas para categorías como educación y pensiones.

## 4. Fiscal Gap: Ingresos

```stata
LIF if divLIF != 10, base
...
foreach k of local divSIM {
    ...
}
collapse (sum) recaudacion, by(anio divSIM) fast
...
```

**Descripción:** Analiza los ingresos y la brecha fiscal asociada. Se utilizan divisiones de cifras fiscales para segmentar datos y consolidar estadísticas de recaudación fiscal.

## 4.1 Actualizaciones y 4.2 Gráficos

```stata
...
if "`nographs'" != "nographs" {
    ...
    graph export ...
}
...
```

**Descripción:** Tras actualizar los datos de recaudación, se generan y exportan gráficos de ingresos, siempre que no se especifique la supresión de los gráficos.

## 5. Fiscal Gap: Gastos y 5.1 Actualizaciones

...
**Descripción:** Siguiendo un procedimiento similar a la sección de ingresos, se procede al análisis y actualización de las proyecciones de gastos.

## 6. Deuda y Costo de la Deuda y 6.1 Costo de la Deuda

...
**Descripción:** Se maneja el análisis relacionado con la deuda pública, su mantenimiento y costo asociado, utilizando proyecciones y tasas efectivas para informar el análisis futuro.

## 7. Fiscal Gap: Balance

...
**Descripción:** Se culmina el análisis proyectando el balance fiscal en valor presente, incorporando deudas actuales y proyectando ingresos y gastos futuros.

El manual proporciona directrices claras sobre el uso de cada sección del programa `FiscalGap`. Para aplicaciones específicas o modificaciones para un análisis preciso, el usuario debe tener un conocimiento adecuado en economía y estadística y se recomienda la colaboración con los creadores del simulador o expertos en la materia.
