# Reporte de inventario — Boceto Paquete 2027 (Entrega 1)

**Fecha:** 2026-08-01
**Alcance:** solo lectura sobre `Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/`
**Método:** recorrido de filesystem, `git ls-files`/`git check-ignore`, lectura de `escalar.ado`, `scalarlatex.ado` y governance, y análisis de los `.tex` de los 15 años de Paquete Económico (2013–2027).

---

## 1. Mapa de la carpeta

### 1.1 Contexto de versionado

- La raíz de la carpeta **es** el repositorio git (`origin = github.com/rcantuc/SimuladorCIEP.git`, rama `master`, último commit `dc12cee` 2026-07-19, último tag `v8.2.0`).
- El `.gitignore` excluye deliberadamente las carpetas de operación (`raw/`, `master/`, `users/`, `06_libro/`, `04_1_simuladorfiscal.ciep.mx/` salvo `health.php`): viven en Dropbox, fuera de git.
- **Hallazgo importante:** `04_1_paqueteeconomico.ciep.mx/` y `04_2_documentos_latex/` están **sin trackear y sin ignorar** (aparecen como `??` en `git status`). Un `git add .` accidental metería ~9 GB al repo, **incluyendo dos `wp-config.php` con credenciales reales** (ver §4 y §5). También hay 4 documentos nuevos de governance sin commitear.

### 1.2 Primer nivel

| Carpeta | Archivos | Peso | Ext. predominantes | Git | Más reciente | Categoría |
|---|---:|---:|---|---|---|---|
| *(raíz)* — `.ado`, `SIM.do`, `profile.do`, `scheme-*` | ~45 | ~1.5 MB | ado, do, scheme | ✅ trackeado | 2026-07-19 | `motor` |
| `01_modulos/` | 33 | 692 KB | do (28), scheme | ✅ trackeado (32) | 2026-07-19 | `motor` |
| `02_governance/` | 20 | 640 KB | md (17), txt | ✅ trackeado (15) + 4 md **sin commitear** | 2026-08-01 | `gobernanza` |
| `03_help/` | 23 | 17 MB | sthlp (11), md (6), png | ✅ trackeado | 2026-07-18 | `gobernanza` |
| `04_1_paqueteeconomico.ciep.mx/` | 11,125 | 443 MB | php (4,183), js, css, png | ⚠️ **untracked, no ignorado** | 2026-08-01 | `web` |
| `04_2_documentos_latex/` | 7,078 | 8.5 GB | png (2,238), pdf (1,096), xlsx (457), tex (322) | ⚠️ **untracked, no ignorado** | 2026-07-29 | `paquete-tex` |
| `04_1_simuladorfiscal.ciep.mx/` (entonces `04_simuladorfiscal.ciep.mx/`; renombrada 2026-09-08) | 2,110 | 43 MB | svg (1,436), html, js | 🚫 ignorado (salvo `health.php`) | 2026-07-21 | `web` |
| `05_scripts/` | 19 | 184 KB | sh (9), pkg (8) | ✅ trackeado (17; credenciales ignoradas) | 2026-07-19 | `otro` — pipeline de publicación/deploy (endpoint Stata, GitHub Releases, VPS) |
| `06_libro/` | 23,593 | 1.1 GB | php (12,190), js, png, json | 🚫 ignorado | 2026-07-19 | `salidas` + `otro` — ver nota A |
| `master/` | 88 | 18 GB | dta (70), ster (18) | 🚫 ignorado | 2026-07-18 | `datos` (procesados/canon) |
| `raw/` | 1,037 | 20 GB | csv (532), xlsx (292), dta (140) | 🚫 ignorado (data sidecar en GitHub Releases + `manifest.json`) | 2026-07-19 | `datos` (crudos) |
| `users/` | 315 | 1.7 GB | dta (242), png, json | 🚫 ignorado | 2026-07-19 | `salidas` (corridas por usuario/sesión) |
| `.devin/` | 48 | 1.1 MB | backups, config IDE | 🚫 ignorado | 2026-07-04 | `otro` — estado del IDE |

**Nota A — `06_libro/`:** es el libro institucional (LaTeX: `maindoc.tex` + capítulos `0_Prologo` … `4_Balance`), el **único consumidor conformante del contrato** — su carpeta `images/` contiene los 14 `statalatex_*.tex` generados por `scalarlatex` y 628 PNG del motor. Pero además contiene `public_html/` (435 MB): **otra copia completa de WordPress con `wp-config.php`**, que no encaja en ninguna categoría y mezcla salidas con infraestructura web.

### 1.3 Segundo nivel (selección relevante)

| Subcarpeta | Archivos | Peso | Más reciente | Nota |
|---|---:|---:|---|---|
| `01_modulos/legacy/` | 19 | 356 KB | 2026-07-19 | módulos retirados |
| `01_modulos/visualizations/` | 6 | 60 KB | 2026-07-19 | |
| `02_governance/historico/` | 5 | 128 KB | 2026-07-04 | auditorías fase 0/0.5 |
| `04_1_…/wp-content/uploads/` | 1,230 | 208 MB | carpetas 2019–2026 | 17 PDFs de Implicaciones + infografías |
| `04_1_…/6yt5ppa3hb/` | — | — | — | micrositio estático "Paquete Económico 2023" |
| `04_1_…/app/` | 1 | — | — | `app-Paquete-Economico-v0.apk` (Android) |
| `04_2_…/Paquete Económico 2013 … 2027` | ver §2 | 17 MB–3.1 GB por año | 2026-07-29 | 15 años; 2027 ya tiene esqueleto vacío de 6 subcarpetas |
| `master/2014 … 2024/` | 12 c/u | 0.8–3.3 GB | 2026-07-18 | ENIGH procesadas + perfiles |
| `raw/temp/` | 843 | 12 GB | 2026-07-19 | intermedios de corrida |
| `raw/ENIGH/` | 176 | 8.4 GB | 2026-06-22 | |
| `users/ricardo/` | 265 | 585 MB | 2026-07-19 | incluye `sankey-*.json` para la web |

**Peso por año del Paquete (04_2):** 2013: 17M · 2014: 44M · 2015: 176M · 2016: 175M · 2017: 1.2G · 2018: 329M · 2019: 1.4G · 2020: 504M · 2021: 532M · 2022: 252M · 2023: 428M · 2024: 211M · 2025: 3.1G · 2026: 140M · 2027: 0B (esqueleto).

---

## 2. Análisis de los documentos LaTeX históricos

**El contrato de referencia** (`escalar.ado` v1.1.0 + `scalarlatex.ado` v2.1.0): Stata registra `escalar <tipo> <nombre> = <exp>` y `scalarlatex` escribe `$export/statalatex_<log>.tex` con el patrón `\def\d<Nombre>#1{\gdef\<Nombre>{#1}}`. El documento consume `\<Nombre>`. Baseline auditado: `02_governance/scalarlatex-baseline.txt` (228 nombres).

**Hallazgo central: de los 14 años con documento, solo 2021 usó macros de escalares. Los otros 13 años —incluido 2026— teclearon todas las cifras a mano.** Los `statalatex_*.tex` del motor solo existen en `06_libro/images/`; en `04_2_documentos_latex/` hay exactamente un archivo de macros en 14 años (`2021/03_documento_ciep/statalatex.tex`, 132 macros, cargado desde `CIEP/preamble.tex` — verificado).

### Resumen por año

| Año | Documento principal | Estructura | Macros escalares | Literales a mano (aprox.) | Gráficas | Tablas |
|---|---|---|---|---:|---:|---:|
| 2013 | `documento_paquete_2013/paquete2013.tex` | monolítico, 15 secciones | ❌ | ~880 | 7 | 68 |
| 2014 | `latex/paquete2014.tex` | monolítico corto, 4 secciones | ❌ | ~186 | 2 | 6 |
| 2015 | `documento_grande_v2/pe2015.tex` | monolítico, clase `ciep` | ❌ | ~783 | 18 | 35 |
| 2016 | `documento_implicaciones/docs.tex` | modular (9 inputs) | ❌ | ~799 | 18 | 23 |
| 2017 | `latex/maindoc.tex` | modular (10 includes) | ❌ | ~200–300 | ~19 | ~23 |
| 2018 | `03_documento_ciep/maindoc.tex` | modular por autor | ❌ | ~150–250 | ~30 | 0 (imágenes) |
| 2019 | `03_documento_ciep/maindoc.tex` | modular por tema, "Política/Evolución/Implicaciones" | ❌ | ~100–200 | ~35 | ~21 |
| 2020 | `03_documento_ciep/maindoc.tex` | partes (+)(−)(=) | ❌ | ~113 | ~30 | muchas |
| **2021** | `03_documento_ciep/maindoc.tex` | 4 partes (Deuda primero) | ✅ **`statalatex.tex`: 132 macros, 224 usos** | ~30–50 | ~35 | varias |
| 2022 | `03_documento_ciep/maindoc.tex` | 4 partes; +MA, +cuidados | ❌ | ~61 | ~35 | varias |
| 2023 | `03_documento_ciep/maindoc.tex` | 4 partes, capítulos "Evolución/Incidencia/Implicaciones" | ❌ | ~77 | 69 | varias |
| 2024 | `04. Documento CIEP/maindoc.tex` | Deuda→Gasto→Ingresos→Implicaciones | ❌ | ~176 | similar | varias |
| 2025 | `4. Documento CIEP/maindoc.tex` | ídem; +género | ❌ | ~157 | similar | varias |
| 2026 | `4. Documento CIEP/maindoc.tex` | ídem | ❌ | **68** | 38 (2–3 por capítulo + subportadas) | 4 tecleadas |
| 2027 | *(solo esqueleto de carpetas, 0 tex)* | — | — | — | — | — |

### a) Estructura — convergencia

Desde 2019 la estructura converge al patrón que sigue vigente en 2026: **partes** (Deuda / Ingresos / Egresos / Implicaciones) → **capítulo por concepto** → secciones internas casi idénticas cada año: *Evolución a [año] · Incidencia · Implicaciones*. Las secciones exactas por año están en los análisis fuente; la estructura 2026 es:

- **Deuda:** Consolidación fiscal · Incidencia · Implicaciones
- **Ingresos energía:** FMP · Pemex · CFE · Otros gastos · Incidencia · Implicaciones
- **Ingresos presupuestarios:** Evolución · Medidas administrativas · Modificaciones fiscales · Implicaciones
- **Gasto total:** Evolución (Espacio fiscal · ¿Quién gasta? · ¿Para qué?) · Incidencia
- **Salud / Educación / Inversión / Medio ambiente / Federalizado / Pensiones:** Evolución · Incidencia · Implicaciones
- **Cuidados:** Anexo Transversal · Implicaciones · Perspectiva de género
- **Implicaciones** (cierre)

### b) Macros usadas — solo 2021

Las 132 macros de 2021 (224 usos, principalmente en tablas del `maindoc`) cubren: aportaciones netas por decil (`AportacionesNetasI–X`, `inc…`, `dis…`), impuestos (`IVA`, `ISRPF`, `ISRPM`, `IEPS`, `FMP`, `CuotasT`…), gasto por capítulo (`servpersPIB`, `obrapublPIB`, `costodeuPIB`…), pensiones (`penimsPIB`, `penissPIB`, `bienestarPIB`…), salud (`imssPIB`, `ssaPIB`, `segpopPIB`…), educación (`basicaPIB`, `medsupPIB`, `superiPIB`…) y cuentas SCN (`RemSalPIB`, `ConHogPIB`…). Es la prueba de que el patrón ya funcionó una vez dentro del Paquete y luego se abandonó.

### c) Números a mano — la deuda técnica

Total acumulado 2013–2026: **~3,000–4,000 literales** en prosa (además de las tablas). El detalle línea por línea por año quedó levantado en los análisis; el caso operativo relevante es **2026, con 68 literales** — es la lista a migrar para 2027. Distribución 2026 por capítulo:

| Capítulo (2026) | Literales | Ejemplos |
|---|---:|---|
| Deuda | 6 grupos | "20.2 billones de MXN, 52.3% del PIB"; "151 mil pesos … 159 mil pesos" (deuda per cápita); "4.1% del PIB" (RFSP) |
| Ingresos energía | 8 | "1,794 mbd, 54.9 dólares por barril"; "971 mil 677 mdp" |
| Ingresos presupuestarios | 19 | "8 billones 721 mil 057 mdp, 22.5% del PIB"; "15.1% del PIB" tributarios |
| Gasto total | 8 | "10.2 billones de pesos, 26.3% del PIB" |
| Salud | 12 | "996 mil 528 mdp… 2.6% del PIB" vs "6% del PIB" recomendado |
| Cuidados | 9 | "466 mil 674.9 mdp, 4.6% del gasto neto" |
| Educación | 8 | "1 billón 238 mil 620 mdp… 3.02%" |
| Pensiones | 3 grupos | "2.3 billones de pesos… 13.5%" |
| Medio ambiente | 5 | "44.0 mil mdp, 4.0%" |
| Federalizado | 6 | "2 billones 810.8 mmdp… 7.4% del PIB" |
| Implicaciones | 11 | repite las cifras titulares de todos los capítulos |

Nota: el capítulo de inversión 2026 se compila desde un archivo **"copia en conflicto"** de Dropbox (`gasto-inversion_copia_en_conflicto_de_katherine_olvera_2025-09-09.tex`) — síntoma del flujo Dropbox sin control de versiones.

### d) Gráficas y tablas

- 2013–2018: PNG sin trazabilidad ("origen no determinable"); algunos `.do` sueltos por autor (`macrosshcp.do` 2017, `graficalif.do` 2018).
- 2019–2022: `.gph` de Stata junto a PNG (p.ej. `shrfsp.gph`, `ingresostributarios.gph` en 2021) — origen Stata pero fuera del pipeline del repo.
- 2023–2026: PNG en `images/`; los `.do`/`.gph`/`.xlsx` generadores viven en "2. Bases de datos" o "material_de_trabajo" del año (p.ej. `inversion_2025.do` + 4 `.gph` en 2025). **En 2026 las 4 tablas del documento están tecleadas a mano** y las subportadas se diseñan desde `.xlsx` en `3. Comunicación/diseno/subportadas/`.

### e) Inputs

- 2013–2015: monolíticos, sin `\input`.
- 2016+: modulares. 2026: `maindoc.tex` → `preamble` + 12 capítulos (`3_Deuda/deuda`, `1_Ingresos/…`×2, `2_Gastos/…`×8, `4_Implicaciones/implicaciones`). **Ningún año salvo 2021 hace `\input` de un archivo de macros de datos.**

---

## 3. Tabla de recurrencia: concepto × año

`●` capítulo/sección propia · `◐` tratado dentro de otro capítulo · `—` ausente

| Concepto | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | Años |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---:|
| **Ingresos** | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Gasto (total)** | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Deuda** | ● | ◐ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Salud** | ● | ◐ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Educación** | ● | ◐ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Energía** (ing. y/o gasto) | ◐ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 14/14 |
| **Criterios macro (CGPE)** | ● | ◐ | ● | ● | ◐ | ◐ | ● | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | 14/14 |
| **Pensiones / seg. social** | — | ◐ | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 13/14 |
| **Federalizado / estados** | ● | ● | — | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | ● | 13/14 |
| **Inversión / infraestructura** | ◐ | — | ◐ | ◐ | ◐ | — | ● | ● | ● | ● | ● | ● | ● | ● | 8/14 propias |
| **Cuidados** | — | — | — | — | — | — | — | — | — | ● | ● | ● | ● | ● | 5/14 |
| **Medio ambiente** | — | — | — | — | — | — | — | — | — | ● | ● | ● | ● | ● | 5/14 |
| **Seguridad** | — | — | — | — | — | — | — | ● | ● | ● | ● | — | — | — | 4/14 |
| **Género** | — | — | — | — | — | — | — | — | — | — | — | — | ◐ | ◐ | 2/14 |
| **Implicaciones / conclusiones** | ◐ | — | ◐ | ● | ◐ | ● | — | — | ● | ● | ● | ● | ● | ● | 9/14 |

**Lectura para el catálogo de nodos:**

- **Nodos permanentes (evidencia de 14 años):** ingresos, gasto, deuda, salud, educación, energía. Con pensiones y federalizado (13/14) suman **los 8 nodos troncales**.
- **Nodos consolidados recientes:** inversión (permanente desde 2019), cuidados y medio ambiente (permanentes desde 2022). Con los 8 troncales, son exactamente **las once infografías / los once nodos** ya identificados en `paquete-economico-nueva-era.md`.
- **Nodos ocasionales:** seguridad (2020–2023, descontinuado), género (2025–2026, aún dentro de cuidados).
- Las secciones internas convergieron a un patrón estable (*Evolución · Incidencia · Implicaciones*), que es una plantilla natural de ficha de nodo.

---

## 4. Consumidores fuera del contrato

Todo número que llega a un documento, gráfica o web sin pasar por `escalar` + `statalatex_*`:

| # | Consumidor | Ruta | Qué produce | Esfuerzo de migración |
|---|---|---|---|---|
| 1 | **Literales en la prosa del documento anual** | `04_2_…/Paquete Económico <año>/…/*.tex` (13 de 14 años; 2026: 68 literales) | El documento bandera con cifras sin trazabilidad | **Medio** para 2027 (los módulos del motor ya emiten `escalar` para SHRFSP, población, deflactor, gasto, ingresos; falta apuntar `$export` al documento y sustituir literales por macros). **Alto/no aplica** para el histórico (documentos publicados: se archivan, no se migran) |
| 2 | **Tablas tecleadas en el documento** | 2026: 4 tablas (`ingresos-energia`, `gasto-salud`, `gasto-cuidados`, `gasto-educacion`) | Tabulares con valores manuales | **Medio** (requiere exportador de tablas, no solo escalares) |
| 3 | **Hojas de cálculo intermedias por año** | `04_2_…/<año>/2. Bases de datos/*.xlsx` (p.ej. `datos_para_analisis.xlsx`, `proyecciones_deuda.xlsx` 2026; `micrositio.xlsx` 2024; `inversion_paquete_2025.xlsx`) | Insumo de gráficas, tablas y micrositio | **Alto** — es el circuito paralelo completo: fuente→Excel→gráfica/texto sin pasar por el motor |
| 4 | **Gráficas del documento** | `04_2_…/<año>/…/images/*.png`; generadores dispersos (`.do`, `.gph`, `.xlsx` en "material_de_trabajo", "Bases de datos") | Las ~30–70 figuras anuales | **Medio** — parte ya sale de Stata pero de scripts personales fuera del repo; falta canonizarlas como salidas del motor |
| 5 | **Subportadas / infografías de diseño** | `04_2_…/<año>/3. Comunicación/diseno/subportadas/*.xlsx` (12 en 2026) | Cifras re-tecleadas en piezas de diseño | **Alto** (proceso de diseño manual; el contrato podría al menos proveer el CSV fuente) |
| 6 | **Micrositio estático del Paquete** | `04_1_…/6yt5ppa3hb/` ("Paquete Económico 2023") | Series numéricas incrustadas en el HTML/JS (`data-area-charts.js`) sin encabezado, unidad ni descarga — el hallazgo 1.4 de `paquete-economico-nueva-era.md` | **Medio** — es justo lo que el nodo con `statajson_*` sustituye |
| 7 | **Contenido WordPress de paqueteeconomico.ciep.mx** | `04_1_…/wp-content/` + páginas Elementor (viven en la **BD MySQL, no presente en esta carpeta**) | Cifras en páginas del sitio en producción | **No auditable desde este inventario** (faltante: dump de BD). Esfuerzo estimado **medio** si el rediseño sustituye páginas por nodos |
| 8 | **App Android** | `04_1_…/app/app-Paquete-Economico-v0.apk` | Números empaquetados en el APK v0 | **Alto/descartable** (artefacto congelado) |
| 9 | **Textos fijos del Simulador web** | `04_1_simuladorfiscal.ciep.mx/js/stataCalcula.js` y `stataCalcula-en.js` | Los **datos** llegan del motor vía `Web.Stata.do` (plantillas `{{…}}` — dentro del espíritu del contrato), pero hay literales de presentación tecleados: años base inconsistentes en ejes ("billones MXN de 2021", "de 2024", "de 2026"), umbrales ("2030", "2050") y categorías de años | **Bajo** — parametrizar esas etiquetas desde la salida del motor |
| 10 | **statalatex.tex de 2021** | `04_2_…/2021/03_documento_ciep/statalatex.tex` | Único año conformante; generado por una versión previa del motor, hoy no re-generable tal cual | **Bajo** — es el precedente, no deuda activa |

**Contraejemplo (lo que sí cumple):** `06_libro/` consume exclusivamente `06_libro/images/statalatex_*.tex` (14 archivos) generados por `scalarlatex` con baseline auditado. La cadena Stata→LaTeX **ya existe y opera**; lo que nunca se conectó es el **documento del Paquete** ni la **web** a esa cadena.

---

## 5. Estado del sitio web

### 5.1 `04_1_paqueteeconomico.ciep.mx/` — el sitio del Paquete

- **Tecnología:** WordPress completo (copia local, 443 MB / 11,125 archivos). Tema `hello-elementor`; plugins: Elementor + Elementor Pro, Jet (blocks/elements/tabs), Premium Addons (+Pro), GTranslate, Wordfence (con `wordfence-waf.php` en raíz), WP Rocket, WP File Manager, SVG Support, ShortPixel.
- **Contenido:** las páginas se construyen con Elementor y **viven en la base de datos MySQL, que NO está en esta carpeta** — el contenido editorial del sitio no es auditable desde este inventario. Lo que sí está: `wp-content/uploads/2019…2026/` (1,230 archivos, 208 MB) con los PDFs de Implicaciones 2020–2025 y las infografías JPG.
- **Assets adicionales:** micrositio estático `6yt5ppa3hb/` (PE 2023; Materialize CSS + jQuery + owl-carousel, series numéricas incrustadas en HTML/JS) y `app/` con un APK Android v0.
- **Despliegue:** **no hay pipeline en el repo para este sitio.** Los scripts de `05_scripts/` (`publicar.sh`, `publicar-vps.sh`, `publicar-endpoint.sh`) son exclusivos del Simulador. La relación de esta copia con producción (¿backup descargado?, ¿espejo de trabajo?, ¿de qué fecha?) no está documentada en governance — **faltante**.
- **Riesgos:** contiene `wp-config.php` **con credenciales reales de BD** y la carpeta no está ni trackeada ni ignorada en git; `wp-salt.php` presente. Según `paquete-economico-nueva-era.md`, el sitio en producción además está en `noindex, nofollow`.

### 5.2 `04_1_simuladorfiscal.ciep.mx/` — el Simulador

- **Tecnología:** PHP plano + jQuery/Highcharts (sin framework). `index.php`/`index-en.php` (~3,900 líneas), `js/stataCalcula.js` (~2,000 líneas). `calculaStata.php` rellena las plantillas `{{…}}` de `01_modulos/Web.Stata.do` y ejecuta Stata por sesión (`users/$id/`); los Sankey se sirven de `jsonSankey*.php` leyendo los JSON generados por el motor.
- **Despliegue:** sí tiene pipeline institucional — `05_scripts/publicar-vps.sh` a VPS IONOS con backup previo, cutover atómico por symlink, health-check (`health.php`, único archivo trackeado de la carpeta) y rollback documentado en `runbook-deploys-ciep.md`.
- **Relación con producción:** esta carpeta es el clon de trabajo local; el VPS corre la copia bajo `/var/www/html/vN.M` + canon `/SIM/OUT/N.M` (convención documentada en governance).

### 5.3 `06_libro/public_html/` — tercera copia web

Otra instalación WordPress completa (435 MB) con `wp-config.php`, dentro de la carpeta del libro. No está claro a qué dominio corresponde ni su vigencia — **faltante**; mismo riesgo de credenciales.

### 5.4 Síntesis para el proyecto de nodos

El destino natural del primer nodo (`paqueteeconomico.ciep.mx`) hoy **no tiene ni pipeline de deploy en el repo ni contenido auditable localmente**, mientras que el Simulador sí tiene ambas cosas. La infraestructura de publicación reutilizable (VPS, cutover, health-check, runbook) ya existe — pero apunta al dominio del Simulador, no al del Paquete.

---

## Faltantes (números/insumos que no se encontraron)

1. **Dump de la BD de WordPress** de paqueteeconomico.ciep.mx → imposible listar las cifras tecleadas en el sitio en producción (§4.7).
2. **Origen exacto de las gráficas 2013–2018** (los PNG no tienen generador identificable en la carpeta).
3. **Documento y datos del PE 2027**: la carpeta existe pero está vacía (esperado — el ciclo no ha empezado).
4. **Mecanismo y fecha de sincronización** de las copias WordPress (`04_1` y `06_libro/public_html`) con producción.
5. Conteos de literales 2017–2019 y de tablas en varios años son **estimaciones por patrón regex**, no censos exactos; el censo exacto que importa (2026: 68) sí está verificado.

---

*Fin de la Entrega 1. Pendiente de autorización para commitear este reporte y proceder a la Entrega 2 (plan de integración).*
