# Simulador Fiscal CIEP: Programas Auxiliares

Versión: 19 de febrero de 2025

<hr style="border: none; height: 2px; background-color: #ff7020;">

## Descripción General

Este manual documenta los programas auxiliares del Simulador CIEP que complementan las funcionalidades principales pero no cuentan con manual individual. Estos programas proporcionan herramientas especializadas para cálculos, análisis y presentación de resultados.

---

## 1. CICLO.ado

**Descripción:** Programa auxiliar para generar ciclos y bucles automáticos.

**Sintaxis:** `CICLO`

**Función:** Herramienta de soporte para automatización de procesos repetitivos en el simulador.

---

## 2. CuentasGeneracionales.ado

**Descripción:** Calcula cuentas generacionales y análisis intergeneracional.

**Sintaxis:** `CuentasGeneracionales [, opciones]`

**Variables generadas:**
- Transferencias netas por generación
- Carga fiscal por cohorte de edad
- Sostenibilidad fiscal intergeneracional

**Output:** Análisis de equidad intergeneracional del sistema fiscal.

---

## 3. Distribucion.ado

**Descripción:** Genera análisis distributivos de ingresos y gastos.

**Sintaxis:** `Distribucion varname [, opciones]`

**Función:** Calcula coeficientes de desigualdad (Gini, Theil) y distribución por percentiles.

---

## 4. GastoPC.ado

**Descripción:** Calcula gasto público per cápita por diferentes categorías.

**Sintaxis:** `GastoPC [, anio(int) categoria(string)]`

**Variables calculadas:**
- Gasto per cápita por función de gobierno
- Gasto por nivel educativo
- Gasto en salud per cápita
- Inversión pública per cápita

**Dependencias:** 
- PEF.ado (clasificación funcional del gasto)
- Poblacion.ado (datos demográficos)

---

## 5. Gini.ado

**Descripción:** Calcula el coeficiente de Gini para variables de distribución.

**Sintaxis:** `Gini varname [if] [in] [aw=weight]`

**Output:** 
- Coeficiente de Gini (0-1)
- Índice de concentración
- Curva de Lorenz (opcional)

---

## 6. INCI.ado

**Descripción:** Calcula índices de incidencia fiscal.

**Sintaxis:** `INCI [, impuesto(string) beneficio(string)]`

**Indicadores generados:**
- Incidencia de impuestos por decil
- Progresividad del sistema fiscal
- Índices de Kakwani y Reynolds-Smolensky

---

## 7. PC.ado

**Descripción:** Convierte variables a términos per cápita.

**Sintaxis:** `PC varname [, poblacion(varname)]`

**Función:** Normaliza variables fiscales y económicas por población.

**Variables generadas:** `[varname]_pc` 

---

## 8. PERF.ado

**Descripción:** Genera perfiles etarios de variables fiscales.

**Sintaxis:** `PERF varname [, edad(varname)]`

**Output:** Perfiles por edad de ingresos, gastos e impuestos.

---

## 9. Perfiles.ado

**Descripción:** Programa extenso para generar perfiles demográficos y económicos detallados.

**Sintaxis:** `Perfiles [, anio(int) tipo(string) grafico]`

**Funcionalidades:**
- Perfiles etarios de consumo e ingreso
- Transferencias intergeneracionales
- Cuentas nacionales de transferencias (NTA)
- Déficit de ciclo de vida

**Variables generadas:**
- `perfil_consumo`: Consumo promedio por edad
- `perfil_ingreso`: Ingreso laboral promedio por edad  
- `transferencias_privadas`: Transferencias familiares
- `transferencias_publicas`: Transferencias gubernamentales

**Dependencias:**
- Households.do
- SCN.ado
- Poblacion.ado

---

## 10. REC.ado

**Descripción:** Calcula recaudación potencial y efectiva.

**Sintaxis:** `REC [, impuesto(string) tasa(real)]`

**Cálculos:**
- Bases gravables
- Recaudación teórica vs real
- Eficiencia recaudatoria
- Elasticidades tributarias

---

## 11. SankeySumLoop.ado

**Descripción:** Genera diagramas de Sankey para flujos fiscales usando bucles.

**Sintaxis:** `SankeySumLoop [, tipo(string)]`

**Output:** Archivos para visualización de flujos de ingresos y gastos públicos.

---

## 12. SankeySumSim.ado

**Descripción:** Versión de simulación para diagramas de Sankey.

**Sintaxis:** `SankeySumSim [, escenario(string)]`

**Función:** Compara flujos fiscales entre escenarios base y simulados.

---

## 13. Simulador.ado

**Descripción:** Motor principal de simulaciones fiscales.

**Sintaxis:** `Simulador [, escenario(string) anio(int) parametros(string)]`

**Funcionalidades:**
- Simulación de políticas fiscales
- Cambios paramétricos en impuestos
- Análisis de equilibrio general
- Microsimulación con datos ENIGH

**Variables simuladas:**
- Recaudación por cambios de tasas
- Impacto distributivo de reformas
- Efectos sobre bienestar
- Sostenibilidad fiscal

**Dependencias:** Prácticamente todos los módulos del simulador

---

## 14. TasasEfectivas.ado

**Descripción:** Calcula tasas impositivas efectivas por decil y sector.

**Sintaxis:** `TasasEfectivas [, impuesto(string) base(string)]`

**Tasas calculadas:**
- Tasa efectiva de ISR por decil
- Tasa efectiva de IVA por decil
- Tasa efectiva total
- Tasas marginales efectivas

**Output:** 
- Tablas de tasas por grupo socioeconómico
- Gráficos de progresividad
- Comparaciones temporales

---

## 15. scalarlatex.ado

**Descripción:** Exporta scalars de Stata a formato LaTeX.

**Sintaxis:** `scalarlatex [, log(string) alt(string)]`

**Función:** 
- Convierte scalars numéricos a comandos LaTeX
- Facilita integración con documentos académicos
- Formato automático de números y porcentajes

**Opciones:**
- `log(nombre)`: Especifica nombre del archivo log
- `alt(prefijo)`: Prefijo alternativo para comandos LaTeX

**Output:** Archivo .tex con definiciones de comandos para usar en LaTeX.

---

## Notas Técnicas Generales

**Archivos de soporte común:**
- La mayoría utiliza `04_master/` para datos procesados
- Generan archivos temporales en `03_temp/`
- Comparten dependencias con módulos principales

**Integración con módulos principales:**
- Muchos son llamados automáticamente por programas principales
- Proporcionan funcionalidades especializadas
- Mantienen consistencia metodológica con el simulador

**Requerimientos:**
- Stata 13+ para compatibilidad
- Algunos requieren paquetes adicionales (ej. grstyle para gráficos)
- Datos base del simulador (ENIGH, SCN, etc.)