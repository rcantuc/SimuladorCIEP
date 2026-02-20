# Simulador Fiscal CIEP: Índice Cruzado de Dependencias

Versión: 19 de febrero de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

## Descripción

Este índice documenta las dependencias entre los diferentes programas del Simulador CIEP, mostrando qué programa llama a qué otros programas. Esta información es crucial para entender la arquitectura del sistema y el orden de ejecución.

---

## Tabla de Dependencias Principales

| Programa Principal | Llama a | Función |
|------------------|---------|---------|
| **SCN.ado** | PIBDeflactor | Obtiene deflactores y años base |
| **SCN.ado** | UpdateSCN | Actualiza datos de cuentas nacionales |
| **SCN.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **LIF.ado** | PIBDeflactor | Deflactores para valores reales |
| **LIF.ado** | DatosAbiertos | Series específicas de ESTOPOR |
| **LIF.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **PEF.ado** | PIBDeflactor | Deflactores y PIB |
| **PEF.ado** | SCN | Cuentas nacionales |
| **PEF.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **SHRFSP.ado** | PIBDeflactor | Deflactores y PIB |
| **SHRFSP.ado** | LIF | Ingresos federales |
| **SHRFSP.ado** | PEF | Gastos federales |
| **SHRFSP.ado** | DatosAbiertos | Series de deuda |
| **SHRFSP.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **FiscalGap.ado** | PIBDeflactor | Deflactores y crecimiento |
| **FiscalGap.ado** | SHRFSP | Balance fiscal |
| **FiscalGap.ado** | Poblacion | Proyecciones demográficas |
| **FiscalGap.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **Poblacion.ado** | UpdatePoblacion | Descarga datos de CONAPO |
| **Poblacion.ado** | scalarlatex | Exporta scalars a LaTeX (opcional) |
| **DatosAbiertos.ado** | PIBDeflactor | Deflactores para valores reales |
| **DatosAbiertos.ado** | UpdateDatosAbiertos | Descarga datos de ESTOPOR |
| **AccesoBIE.ado** | *Python integrado* | Descarga vía API del BIE |

---

## Dependencias de Programas Auxiliares

| Programa Auxiliar | Llama a | Función |
|------------------|---------|---------|
| **GastoPC.ado** | PEF | Clasificación del gasto |
| **GastoPC.ado** | Poblacion | Datos demográficos |
| **CuentasGeneracionales.ado** | Poblacion | Proyecciones demográficas |
| **CuentasGeneracionales.ado** | SHRFSP | Balance fiscal intergeneracional |
| **Perfiles.ado** | SCN | Cuentas nacionales |
| **Perfiles.ado** | Poblacion | Datos demográficos |
| **TasasEfectivas.ado** | LIF | Recaudación por impuesto |
| **TasasEfectivas.ado** | PIBDeflactor | PIB para tasas efectivas |
| **Simulador.ado** | *Múltiples* | Prácticamente todos los módulos |
| **SankeySumLoop.ado** | LIF | Ingresos para diagramas |
| **SankeySumLoop.ado** | PEF | Gastos para diagramas |
| **SankeySumSim.ado** | LIF | Ingresos simulados |
| **SankeySumSim.ado** | PEF | Gastos simulados |
| **REC.ado** | LIF | Recaudación observada |
| **REC.ado** | PIBDeflactor | PIB para calcular bases |

---

## Dependencias de Archivos .do

| Programa .do | Llama a | Función |
|-------------|---------|---------|
| **Households.do** | PIBDeflactor | Deflactores e información macro |
| **Households.do** | SCN | Cuentas nacionales para armonización |
| **Households.do** | LIF | Ingresos federales |
| **Expenditure.do** | SCN | Cuentas nacionales |
| **Expenditure.do** | LIF | Ingresos federales |
| **Expenditure.do** | Poblacion | Datos demográficos |

---

## Rutinas de Actualización (Update*)

| Rutina | Función | Llamada por |
|---------|---------|------------|
| **UpdateSCN** | Descarga datos BIE/CSI | SCN.ado |
| **UpdatePoblacion** | Descarga datos CONAPO | Poblacion.ado |
| **UpdateDatosAbiertos** | Descarga ESTOPOR | DatosAbiertos.ado |
| **UpdateDeflactor** | Actualiza INPC | DatosAbiertos.ado |

---

## Flujo de Dependencias Típico

### Secuencia Básica de Ejecución:
1. **PIBDeflactor.ado** → Base fundamental (deflactores, PIB)
2. **Poblacion.ado** → Proyecciones demográficas  
3. **SCN.ado** → Cuentas nacionales (usa PIBDeflactor)
4. **LIF.ado** → Ingresos (usa PIBDeflactor, DatosAbiertos)
5. **PEF.ado** → Gastos (usa PIBDeflactor, SCN)
6. **SHRFSP.ado** → Balance fiscal (usa LIF, PEF)
7. **FiscalGap.ado** → Sostenibilidad (usa SHRFSP, Poblacion)

### Procesamiento de Microdatos:
1. **Expenditure.do** → Gastos de hogares (usa SCN, LIF, Poblacion)
2. **Households.do** → Ingresos de hogares (usa PIBDeflactor, SCN, LIF)

---

## Archivos de Datos Compartidos

| Base de Datos | Generada por | Utilizada por |
|---------------|--------------|---------------|
| **PIBDeflactor.dta** | PIBDeflactor.ado | SCN, LIF, PEF, SHRFSP, FiscalGap |
| **SCN.dta** | SCN.ado | PEF, Households, Expenditure |
| **Poblacion.dta** | Poblacion.ado | FiscalGap, GastoPC, CuentasGeneracionales |
| **Poblaciontot.dta** | Poblacion.ado | DatosAbiertos, Expenditure |
| **DatosAbiertos.dta** | DatosAbiertos.ado | LIF, SHRFSP, TasasEfectivas |
| **households.dta** | Households.do | Simulador, análisis distributivos |
| **expenditures.dta** | Expenditure.do | Simulador, análisis fiscales |

---

## Notas Técnicas

**Orden de dependencias:**
- Los programas deben ejecutarse respetando las dependencias
- PIBDeflactor.ado es la base de casi todo el sistema
- Los módulos principales deben ejecutarse antes que los auxiliares

**Actualización de datos:**
- Las rutinas Update* se ejecutan automáticamente cuando es necesario
- Pueden forzarse manualmente con la opción `update`

**Compatibilidad:**
- Todos los programas mantienen compatibilidad con versiones de datos
- Las dependencias están optimizadas para minimizar tiempo de ejecución