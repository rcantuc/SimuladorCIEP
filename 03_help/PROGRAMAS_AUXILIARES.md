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

**Descripción:** Exporta a LaTeX los scalars registrados vía `escalar` (ver §16).

**Sintaxis:** `scalarlatex [, log(string) alt(string)]`

**Función:**
- Recorre TODOS los scalars vivos en memoria (contrato global-acumulado: el
  libro consume scalars de un módulo desde el .tex de otro)
- A los registrados en `$scalarlatex_reg` (vía `escalar`) les aplica el formato
  canónico de su tipo; los NO registrados se exportan tal cual (as-is)
- El valor exportado es el scalar real, no su impresión en pantalla

**Opciones:**
- `log(nombre)`: Nombre del archivo .tex de salida (`statalatex_<nombre>.tex`)
- `alt(sufijo)`: Sufijo de los comandos LaTeX generados (`\d<Nombre><sufijo>`)

**Output:** `$export/statalatex_<log>.tex` con `\def`s para documentos internos CIEP.

**Nota:** solo-repo (opción `textbook`). No viaja al endpoint público; los
productores publicados lo invocan tras `capture which scalarlatex`.

---

## 16. escalar.ado

**Descripción:** Registra un scalar con clase semántica para exportación textbook.
Reemplaza al patrón fósil `noisily di %fmt = scalar(...)` + relectura de log.

**Sintaxis:** `escalar <tipo> <nombre> = <expresión>`

**Tipos y formato canónico al exportar:**
- `pctpib` — % del PIB, `%7.3fc`
- `pct` — % de un total / tasas, `%7.1fc`
- `mxn` — pesos (se exporta entre 1e6, en millones), `%12.1fc`
- `mxnpc` — pesos per cápita, `%10.0fc`
- `personas` — conteos de población, `%15.0fc`
- `anio` — años calendario, `%4.0f`
- `custom(%fmt)` — excepción documentada; comentar el porqué en el call site

**Función:**
- Define `scalar <nombre> = <exp>` con precisión completa (los cómputos aguas
  abajo lo usan directo; el formato se aplica UNA vez, al escribir el .tex)
- Registra `nombre:tipo` en `$scalarlatex_reg` (last wins si se re-registra)
- En `scalarlatex`, los dígitos del nombre se convierten a letras (0→A ... 9→J)
  para que el `\def` LaTeX sea válido (antes esas macros quedaban rotas en silencio)

**Reglas para colaboradores:**
- **CONTRATO (governance, v8.0.13): todo lo que alimenta el libro pasa por
  `escalar`.** No es una regla de homogeneidad de estilo: es el contrato que
  garantiza que cada valor del libro tiene precisión completa y tipo semántico
  declarado. Corolario operativo: los sin-registrar de cada corrida se
  comparan AUTOMÁTICAMENTE contra el **baseline auditado**
  `02_governance/scalarlatex-baseline.txt` (228 en v8.0.13: 211 scalars de
  trabajo que el libro no referencia + 17 consumidos as-is numéricos, ver
  CHANGELOG v8.0.13). Dentro del baseline → línea informativa (sin dump);
  nombres NUEVOS → aviso en rojo con esos nombres: drift real (typo
  `scalar`/`escalar` o scalar nuevo sin migrar), no ruido tolerable. Cómo
  actualizar el baseline cuando cambie legítimamente: procedimiento en el
  header del propio archivo (regenerar desde la corrida textbook, auditar
  los nuevos contra el libro, commitear con justificación en CHANGELOG).
  Meta de ciclo futuro: migrar los 17 y bajar a solo scalars de trabajo.
- Todo scalar nuevo destinado a textbook DEBE declararse con `escalar`, nunca
  con `noisily di` + formato manual
- Preferir nombres sin dígitos; si los hay, documentar la conversión A–J en el
  texto LaTeX que los consuma

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