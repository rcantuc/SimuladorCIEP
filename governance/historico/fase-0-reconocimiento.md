# Fase 0 — Reconocimiento del repo del Simulador Fiscal CIEP

**Fecha:** 2026-05-09  
**Autor del diagnóstico:** consultor de governance (asistente) + revisión pendiente de Ricardo  
**Alcance:** inspección no intrusiva del repositorio tal como está hoy, sin modificar código.  
**Commit de referencia:** `2f46d92` (HEAD, `master`, 2026-04-30)

> Este documento está escrito para que un lector externo que nunca ha visto el código pueda entender el estado actual del Simulador y dimensionar el trabajo de governance pendiente. No es un manual del modelo; es un diagnóstico del repo y de su gobernabilidad.

---

## 1. Resumen ejecutivo

Cinco observaciones críticas que determinan todo lo que sigue:

1. **Bus factor = 1, verificable en la historia Git.** 95.7% de los commits (1,031 de 1,077) son de Ricardo Cantú bajo cuatro identidades distintas. El resto son contribuciones muy marginales.
2. **El repo tiene ~30,000 líneas de Stata distribuidas en 30+ archivos grandes**, con una fachada de master do-file (`SIM.do`) que orquesta el pipeline, pero sin `dependencies.do`, sin tags de release y sin tests automatizados.
3. **Hay una duplicación peligrosa entre `Stata net/` (paquete distribuible) y la raíz (código de trabajo):** 6 de 8 programas core difieren. Un usuario externo que se instale el simulador vía `net install` recibe una versión distinta de la que Ricardo corre localmente.
4. **Ausencia casi total de invariantes declarativas del código Stata:** ningún `version XX` en los programas core más grandes (`SCN.ado`, `PEF.ado`, `LIF.ado`, `SHRFSP.ado`, `Poblacion.ado`, `PIBDeflactor.ado`, `DatosAbiertos.ado`, `GastoPC.ado`, `FiscalGap.ado`, `TasasEfectivas.ado`), cero `assert` tras `merge`/`append`, cero `notes`/`char` como metadatos en los `.dta`.
5. **El repo pesa ~18 GB (`master/` 5.3 GB + `raw/` 607 MB), pero `raw/` NO está en `.gitignore`** y sí se versiona. Higiene del repo es prerequisito de Fase 0.5.

---

## 2. Árbol de directorios resumido

```
SimuladorCIEP/
├── SIM.do                         # Master do-file (orquesta el pipeline)
├── profile.do, sysprofile.do      # Configuración automática de Stata
├── simulador.stpr                 # Archivo de proyecto Stata
├── README.md                      # Documentación al usuario final
├── .gitignore                     # 6 líneas; insuficiente para Stata
├── .windsurfrules                 # Este documento rector
│
├── *.ado (24 archivos en raíz)    # Programas core del Simulador
├── *.do  (5 archivos en raíz)     # Scripts auxiliares
├── *.scheme (13 archivos)         # Esquemas gráficos CIEP
│
├── 01_modulos/
│   ├── análisis/        (9 .do)   # Análisis auxiliares, varios legacy
│   ├── households/      (3 .do)   # Procesamiento ENIGH (macro-micro)
│   ├── profiles/        (2 .do)   # Perfiles fiscales
│   ├── tax_models/      (2 .do)   # Modelos ISR/IVA
│   └── visualizations/
│       ├── Graphs_*.do            # Gráficas ad-hoc
│       └── sankey/   (6 .do)      # Diagramas Sankey del sistema fiscal
│
├── Stata net/  (8 .ado + .pkg + stata.toc)  # Paquete distribuible (divergente)
├── raw/        (607 MB)           # Insumos: LIFs/, PEFs/ → LARGE BINARIES TRACKED
├── master/     (5.3 GB, gitignored) # Datasets derivados
├── temp/       (gitignored)       # Archivos temporales
├── users/      (gitignored)       # Output por usuario
├── graphs/     (gitignored, vacío)
├── simuladorfiscal.ciep.mx/ (gitignored) # Salida web
├── help/       (13 .md + 10 .sthlp) # Help files usuario
└── .git/                          # Historia de 7.5 años, 1,077 commits
```

---

## 3. Inventario de `.do` / `.ado`

### 3.1 Master do-file y configuración

| Archivo                                                                                                        | Líneas | Rol                                                                                                                                                                                              | Notas                                                                                                                                                                                                               |
| ----------------------------------------------------------------------------------------------------------------| -------:| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do`        | 494    | Master. Secciones 0–8 (demografía → ciclo fiscal). Llama secuencialmente a `Poblacion`, `PIBDeflactor`, `SCN`, `LIF`, `PEF`, `SHRFSP`, `GastoPC`, `FiscalGap`, más sub-scripts en `01_modulos/`. | Hardcodea `username == "ricardo"` en l.19-21. Sin `log using` obligatorio.                                                                                                                                          |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/profile.do`    | 92     | Auto-ejecutado al abrir Stata. Fija `scheme ciep`, define entidades, `aniovp=2026`, `anioPE=2026`. Muestra menú de comandos.                                                                     | Duplica algunos parámetros que también están en `SIM.do` (pib2025…, def2025…, inf2025…). **Fuente única de verdad no establecida.**                                                                                 |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/sysprofile.do` | 10     | Fija `sysdir_site` según OS a ruta `CIEP Dropbox/SimuladorCIEP/`.                                                                                                                                | **Ruta no coincide con la del workspace real** (`Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/...`). Esto implica que existen al menos dos ubicaciones del repo en la(s) máquina(s) de Ricardo. |

### 3.2 Programas core en raíz (pipeline)

Orden probable de ejecución según `SIM.do`:

| # | Archivo | Líneas | Función aparente | `version XX` |
|---:|---|---:|---|:---:|
| 1 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Poblacion.ado` | 806 | Proyecciones CONAPO | ❌ |
| 2 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PIBDeflactor.ado` | 1,089 | PIB, deflactor, productividad (INEGI/BIE) | ❌ |
| 3 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SCN.ado` | 2,606 | Sistema de Cuentas Nacionales | ❌ |
| 4 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/LIF.ado` | 700 | Ley de Ingresos de la Federación | ❌ |
| 5 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PEF.ado` | 1,193 | Presupuesto de Egresos | ❌ |
| 6 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SHRFSP.ado` | 1,438 | Deuda pública | ❌ |
| 7 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/DatosAbiertos.ado` | 1,282 | Finanzas públicas SHCP | ❌ |
| 8 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/TasasEfectivas.ado` | 343 | Tasas efectivas sobre ENIGH | ❌ |
| 9 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/GastoPC.ado` | 1,537 | Gasto per cápita por función | ❌ |
| 10 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/FiscalGap.ado` | 982 | Brecha fiscal de largo plazo | ❌ |
| 11 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Simulador.ado` | 1,028 | Corredor de bootstraps del ciclo fiscal | ✅ v13.1 (subrutinas) |
| 12 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Perfiles.ado` | 993 | Perfiles fiscales con bootstrap | ✅ v13.1 (subrutinas) |
| 13 | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/AccesoBIE.ado` | 373 | Consulta API BIE/INEGI | ✅ v17.0 |

### 3.3 Programas auxiliares / subrutinas (raíz)

| Archivo | Líneas | Rol |
|---|---:|---|
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/CuentasGeneracionales.ado` | 175 | Contabilidad generacional (invocado opcionalmente) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/CICLO.ado` | 76 | Ciclo de vida por sexo/edad/decil (subrutina) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/REC.ado` | 131 | Proyecciones de recaudación (subrutina) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PC.ado` | 271 | Montos per cápita (subrutina) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PERF.ado` | 126 | Perfiles por edad/sexo (subrutina) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/INCI.ado` | 108 | Incidencia por decil (subrutina) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Distribucion.ado` | ? | Stub (473 bytes) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Gini.ado` | 34 | Cálculo de Gini |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SankeySumLoop.ado` | 121 | Preparación Sankey |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SankeySumSim.ado` | 117 | Preparación Sankey (simulación) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/scalarlatex.ado` | 118 | Exporta `scalar` a LaTeX (via `log using .tex`) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Web.Stata.do` | 420 | Generación de salidas web (uso opaco sin README) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/TarjetaRFSP.do` | 688 | Genera tarjeta sobre RFSP (propósito no documentado en README) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/output.do` | 298 | Postprocesa output web (ejecutado si `$output == "output"`) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/CensoEconomico.do` | 52 | Stub de acceso al Censo Económico |

### 3.4 `01_modulos/` — pipeline secundario y análisis legacy

| Archivo | Líneas | Rol | ¿Invocado por `SIM.do`? |
|---|---:|---|:---:|
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/households/Households.do` | 2,755 | Procesamiento de ENIGH (recursos) | ✅ (l.108 SIM.do) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/households/Expenditure.do` | 1,322 | Procesamiento de ENIGH (usos) | ✅ (l.104 SIM.do) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/households/Expenditure_PTLAC.do` | 1,331 | Variante PTLAC | ❌ (sin referencia) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/profiles/PerfilesSim.do` | 575 | Perfiles del paquete económico | ✅ (l.112 SIM.do) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/profiles/PerfilesGasto.do` | 162 | Perfiles de gasto | ❌ |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/tax_models/ISR_Mod.do` | 256 | Re-estimación ISR | ✅ condicional (`cambioisrpf==1`) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/tax_models/IVA_Mod.do` | 79 | Re-estimación IVA | ✅ condicional (`cambioiva==1`) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/visualizations/sankey/SankeySF.do` | 245 | Sankey del sistema fiscal | ✅ (l.483 SIM.do, en loop por `decil grupoedad sexo rural escol`) |
| `01_modulos/visualizations/sankey/Sankey*.do` (5 archivos) | ~1,830 | Variantes Sankey (CFE, Pemex, Proy) | ❌ (legacy / uso manual) |
| `01_modulos/visualizations/Graphs_PC.do`, `Graphs_TE.do` | 277 | Gráficas auxiliares | ❌ (comentadas en SIM.do) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/análisis/coneval.do` | 2,410 | Procesamiento Pobreza CONEVAL | ❌ (análisis standalone; ruta hardcoded `../BasesCIEP/INEGI/CONEVAL/2022/`) |
| `01_modulos/análisis/Subnacional.do`, `SubnacionalGasto.do` | 1,363 | Análisis subnacional | ❌ |
| `01_modulos/análisis/Cap_Ingresos_30.do`, `HistoricoRenunciasR_CapIngresos_final.do`, `MicrositioPE.do`, `SectoresEconómicosProductividad.do`, `Ejercicio_Elasticidades_Ingresos_beta.do`, `diccionarioCapIngresos.do` | ~2,000 | Análisis legacy / one-off | ❌ |

**Observación crítica:** de las ~12,700 líneas en `01_modulos/`, aproximadamente **la mitad son código que el pipeline actual no ejecuta** (análisis legacy, variantes abandonadas, scripts de micrositio). Eso es deuda cognitiva para un nuevo colaborador: todo está junto, pero no todo está vivo.

### 3.5 `Stata net/` — paquete distribuible divergente

| Archivo | Idéntico a raíz | Divergencia |
|---|:---:|---|
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/SCN.ado` | ✅ | ninguna |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/SHRFSP.ado` | ✅ | ninguna |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/PEF.ado` | ❌ | raíz 40,955 B vs net 45,736 B (**+4,781 B en net**) |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/LIF.ado` | ❌ | raíz 20,067 B vs net 20,389 B |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/Poblacion.ado` | ❌ | raíz 28,926 B vs net 28,337 B |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/PIBDeflactor.ado` | ❌ | raíz 39,005 B vs net 38,990 B |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/DatosAbiertos.ado` | ❌ | raíz 54,743 B vs net 54,824 B |
| `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/AccesoBIE.ado` | ❌ | raíz 11,565 B vs net 11,378 B |

El `stata.toc` (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Stata net/stata.toc:3`) se autodeclara como *"Simulador Fiscal CIEP v7. 23 de febrero de 2026"* — misma fecha que el `*Ricardo Cantú Calderón` header de `SIM.do` (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:5`). Es decir: la distribución pública y el código de trabajo dicen ser "v7" pero **no son el mismo código**.

Esto es **deuda de governance crítica**. Cualquier colaborador externo que siga el README (clonar → abrir `simulador.stpr`) recibe el código de raíz; cualquier usuario externo que haga `net install` desde el `stata.toc` recibe `Stata net/`. Un bug corregido en uno no se corrige en el otro.

---

## 4. Inventario de `.dta` files

La distinción clásica en microsimulación es **crudo → derivado → output**. Aquí:

### 4.1 Datos crudos (insumos, `raw/`)

| Ruta | Contenido | Tamaño | ¿Versionado? |
|---|---|---:|:---:|
| `raw/PEFs/CP 20XX.xlsx` (2008–2024) | Cuentas Públicas anuales SHCP | 18–67 MB c/u | ✅ (tracked) |
| `raw/PEFs/PEF 2025.xlsx`, `PEF 2026.xlsx` | Presupuesto de Egresos | 19–22 MB | ✅ |
| `raw/PEFs/CuotasISSSTE.xlsx` | Referencia de cuotas | 11 KB | ✅ |
| `raw/LIFs/LIFs.xlsx` y anexos | Ley de Ingresos históricas + Anexo 8 ISR | ~2.5 MB | ✅ |
| `raw/ISRInformesTrimestrales.xlsx` | Informes SHCP | 15 KB | ✅ |
| `BIE_tabla_equivalencias.csv` (raíz) | Equivalencias series INEGI | 17 MB | ✅ |

**Total `raw/`: 607 MB, versionado en Git.** Este es el principal candidato para migración a Git LFS o DVC (se decidirá en Fase A5). Sin eso, cada `git clone` descarga los 607 MB aunque el usuario solo necesite el código.

**Faltantes observados en `raw/`:** no hay subcarpetas `CONAPO/`, `INEGI/ENIGH/`, `SHCP/DatosAbiertos/`, ni el respaldo de los endpoints de `AccesoBIE`. El código los consume desde rutas externas (`../BasesCIEP/INEGI/CONEVAL/2022/` en `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/análisis/coneval.do:35`, APIs, o descargas por URL). Linaje incompleto.

### 4.2 Datos derivados (intermedios, `master/`)

`master/` está gitignored y pesa 5.3 GB. Contiene los `.dta` producidos por cada corrida del pipeline:

- `Poblacion.dta`, `Poblaciontot.dta` (de `Poblacion.ado`)
- `PIBDeflactor.dta`, `Deflactor.dta` (de `PIBDeflactor.ado`)
- `SCN.dta` (de `SCN.ado`)
- `DatosAbiertos.dta` (de `DatosAbiertos.ado`)
- `LIF.dta`, `PEF.dta` (de los respectivos programas)
- `SHRFSP.dta` (de `SHRFSP.ado`)
- `2024/expenditures.dta`, `2024/households.dta`, `2024/consumption_categ_*.dta`, `2024/categ_iva.dta`, `2024/deducciones.dta` (de `01_modulos/households/`)
- `perfiles2026.dta` (de `01_modulos/profiles/PerfilesSim.do`)

Todos se generan con `if c(version) > 13.1 { saveold version(13) }` → compatibles con Stata 13+ (positivo).

Sin embargo, al estar gitignored: **los derivados no están bajo control de versiones.** No hay forma de reproducir un informe publicado hace 6 meses sin re-correr el pipeline con datos actualizados, lo cual puede ya no dar el mismo número.

### 4.3 Outputs (por usuario, `users/$id/`)

Gitignored. Contiene: `LIF.dta`, `ingresos.dta`, `gastos.dta`, `aportaciones.dta`, `isr_mod.dta`, `iva_mod.dta`, `bootstraps/`, logs, LaTeX (`statalatex_*.tex`), imágenes. Es el resultado final por corrida, específico al `$id` definido en `SIM.do:25`.

### 4.4 Linaje

No existe diagrama de linaje. Esta tabla es una aproximación que Fase A1 debe formalizar:

```
raw/PEFs/CP*.xlsx ──► PEF.ado ──► master/PEF.dta
raw/LIFs/LIFs.xlsx ──► LIF.ado ──► master/LIF.dta
[CONAPO API] ──► Poblacion.ado ──► master/Poblacion.dta, Poblaciontot.dta
[INEGI BIE] ──► PIBDeflactor.ado, AccesoBIE.ado ──► master/PIBDeflactor.dta, Deflactor.dta
[INEGI SCN] ──► SCN.ado ──► master/SCN.dta
[SHCP Datos Abiertos] ──► DatosAbiertos.ado ──► master/DatosAbiertos.dta
[SHCP SHRFSP] ──► SHRFSP.ado ──► master/SHRFSP.dta
[INEGI ENIGH] ──► 01_modulos/households/Expenditure.do, Households.do
                  ──► master/{año}/expenditures.dta, households.dta, ...
master/* + users/$id/LIF.dta ──► 01_modulos/profiles/PerfilesSim.do ──► master/perfiles{año}.dta
master/perfiles{año}.dta + TasasEfectivas.ado + GastoPC.ado ──► users/$id/ingresos.dta, gastos.dta
users/$id/ingresos.dta + gastos.dta ──► Simulador.ado / Perfiles.ado ──► users/$id/aportaciones.dta
users/$id/aportaciones.dta ──► FiscalGap.ado ──► brecha fiscal + LaTeX
                            ──► SankeySF.do ──► diagramas Sankey
```

---

## 5. Paquetes SSC / user-written invocados

**No existe `dependencies.do`.** La instalación está dispersa, siempre condicional, y silenciosa si ya está presente:

| Paquete | Función | Invocado en | Patrón |
|---|---|---|---|
| `labutil` (`labmask`) | Etiquetar valores desde otra variable | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/LIF.ado:606-612`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PEF.ado:768-773` | `net install http://fmwww.bc.edu/RePEc/bocode/l/labutil.pkg` on-demand |
| `grc1leg2` | Combinar gráficas con leyenda común | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/FiscalGap.ado:196-198` | `net install "http://fmwww.bc.edu/RePEc/bocode/g/grc1leg2.pkg"` on-demand |

**Posibles dependencias no inventariadas (detectar en Fase A2):** comandos de diagramas Sankey en `01_modulos/visualizations/sankey/` — revisar si son `sankey_plot`, `sankey` de SSC, o custom.

**Riesgos del esquema actual:**

- Si `fmwww.bc.edu` se cae temporalmente, una corrida fresca falla sin que el usuario entienda por qué.
- No hay pin de versión — la última versión publicada de un paquete externo puede introducir cambios silenciosos.
- No hay equivalente a `requirements.txt` o `renv.lock`. Un nuevo co-mantenedor no sabe qué necesita instalado.

Acción para Fase 0.5 / Fase A5: crear `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/dependencies.do` que instale todo upfront con chequeo de versión.

---

## 6. Estado del control de versiones

### 6.1 Números

- **Commits totales:** 1,077 (inferido con `git log --all --oneline | wc -l`)
- **Primer commit:** 2018-10-29  
- **Último commit:** 2026-04-30 (6 días antes del diagnóstico)
- **Antigüedad:** 7 años 6 meses.
- **Ramas:** solo `master` local + `origin/master`. Ninguna rama de desarrollo ni feature.
- **Tags:** **cero**. Ninguna release etiquetada. El README dice "v7" y el `stata.toc` también, pero no hay `git tag v7.0`.

### 6.2 Distribución de autores

| Autor | Commits | % | Comentario |
|---|---:|---:|---|
| Ricardo Cantú | 608 | 56.5% | Identidad principal |
| ricarqo | 267 | 24.8% | Alias de Ricardo |
| rcantuc | 84 | 7.8% | Alias GitHub de Ricardo |
| Ricardo Cantu | 72 | 6.7% | Alias sin tilde |
| **Ricardo (total)** | **1,031** | **95.7%** | |
| Jotapelopez3696 | 23 | 2.1% | Contribuidor externo esporádico |
| JuanPabloSantisteban | 10 | 0.9% | Contribuidor externo esporádico |
| erikciep | 7 | 0.6% | Probable colaborador CIEP |
| Leslie Badillo | 3 | 0.3% | — |
| 18-carlos | 3 | 0.3% | — |

**Los cuatro alias de Ricardo deben normalizarse** con `.mailmap` en Fase 0.5.

### 6.3 Frecuencia por mes (últimos 25 meses)

```
 9 2024-02      3 2024-10      4 2025-04     46 2025-09     9 2026-03
 5 2024-03     16 2024-11      8 2025-05      9 2025-10     8 2026-04
 7 2024-04      1 2024-12      4 2025-06      3 2025-11
10 2024-06      5 2025-01      7 2025-07      5 2025-12
19 2024-07     10 2025-02     (2025-08: 0)    8 2026-01
 9 2024-08     43 2025-03                     7 2026-02
```

Actividad irregular, con picos en 2025-03 (43 commits) y 2025-09 (46), y meses completos de silencio (2025-08). Correlaciona con ciclos de publicación del libro / CGPE. **No hay cadencia de release predecible.**

### 6.4 Calidad de los mensajes de commit

Muestra de los 50 más recientes: dominan mensajes vagos y sin cuerpo. "Update SIM.do" aparece 4 veces en 50, "Update profile.do" 3 veces, "Update PIBDeflactor.ado" 3 veces seguidas. Otros ejemplos: "Major update", "Carpeta Raw", "LibroCIEP", "Simulador del libro.", "Update .gitignore".

Implicaciones:
- **El historial es prácticamente ilegible para un nuevo colaborador.** No puede hacer `git blame` + `git show` para entender por qué se hizo un cambio.
- No hay link a issues ni a decisiones metodológicas.
- Convención de commits es el primer artefacto de Fase 0.5.

### 6.5 `.gitignore` actual

```
@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/.gitignore:1-7
**/temp/**
**/master/**
**/graphs/**
**/users/**
**/simuladorfiscal.ciep.mx/**
**.DS_Store**
```

Ausencias:
- `*.smcl`, `*.log`, `*.dta` generados en otras ubicaciones
- `*.stswp` (Stata workspace), `*.stbak`
- `ado/personal/`, `ado/plus/`
- Archivos temporales de editores (`*~`, `.vscode/`, `.idea/`)
- `raw/` **NO está ignorado** → 607 MB en Git
- Patrón `**.DS_Store**` es erróneo (glob mal formado); el efectivo es `.DS_Store` — revisar

### 6.6 Estado de trabajo actual

```
 M .DS_Store                                                   (modificado)
 D "01_modulos/análisis/InformesTrimestrales.do"               (eliminado, sin commit)
 M simulador.stpr                                              (modificado)
?? .windsurfrules                                              (nuevo, sin tracking)
```

El repo está **"sucio":** hay un archivo eliminado sin commit (`InformesTrimestrales.do`) que no sabemos si debe permanecer borrado, y cambios menores sin stagear. Primer saneamiento en Fase 0.5.

---

## 7. Mapa de complejidad (determina orden de onboarding en Fase A3.5)

Clasificación provisional. **Sujeta a validación con Ricardo** (él es quien sabe qué es difícil).

### Nivel 1 — Baja complejidad. Entendible por alguien con Stata intermedio sin contexto fiscal profundo

- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Poblacion.ado` — Importa proyecciones CONAPO, genera pirámides. Inputs bien definidos, outputs bien definidos.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/AccesoBIE.ado` — wrapper sobre API BIE/INEGI. Tiene `version 17.0`, es el más moderno y limpio.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/DatosAbiertos.ado` — acceso estructurado a series SHCP. La lógica es ETL directa.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Gini.ado`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/scalarlatex.ado`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/INCI.ado`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PC.ado` — utilitarios pequeños.

### Nivel 2 — Complejidad media. Requiere conocimiento de dominio fiscal

- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/LIF.ado`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PEF.ado` — ingesta de Ley de Ingresos y Presupuesto de Egresos. Requiere conocer la estructura de "divLIF", "divSIM", "ramo", clasificadores administrativos.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/PIBDeflactor.ado` — cálculo de PIB real, nominal, deflactor, productividad. Requiere entender cambio de año base, encadenamiento.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SHRFSP.ado` — deuda pública. Requiere entender RFSP vs SHRFSP, interna/externa, tipo de cambio.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/GastoPC.ado` — gasto per cápita por función (salud, educación, pensiones). Requiere conocer beneficiarios y clasificadores sectoriales.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/tax_models/ISR_Mod.do`, `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/tax_models/IVA_Mod.do` — re-estimación de ISR e IVA bajo escenarios alternativos. Requiere fiscalidad aplicada.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/TasasEfectivas.ado` — tasas efectivas sobre ENIGH.

### Nivel 3 — Alta complejidad. Depende de decisiones tácitas no documentadas

- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SCN.ado` (2,606 líneas) — Sistema de Cuentas Nacionales. El más grande del repo. Armoniza múltiples tablas del INEGI, integra deflactor, ajusta por cambios de base. Decisiones metodológicas espesas.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/households/Households.do` (2,755 líneas) — procesamiento de ENIGH en recursos. Integración macro-micro.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/households/Expenditure.do` (1,322 líneas) — ENIGH en usos. Categorización IVA/IEPS.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/profiles/PerfilesSim.do` — construye `perfiles{año}.dta` integrando todo lo anterior.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Simulador.ado` + `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Perfiles.ado` — bootstrap del ciclo fiscal. Requiere entender el diseño de muestreo y por qué `set seed 1111`.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/FiscalGap.ado` — brecha fiscal. Proyección de largo plazo, tasa de descuento, lambda.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/CuentasGeneracionales.ado` — contabilidad generacional. Concepto especializado.

**Implicación operativa:** el onboarding en Fase A3.5 debe empezar por **Nivel 1** con tareas reales (ej.: actualizar `Poblacion.ado` con proyección CONAPO 2023-2070 nueva), nunca por SCN o Households como primer contacto.

### Zonas de **deuda cognitiva** (código vivo pero opaco)

- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/Web.Stata.do` — 420 líneas sin README. Se llama a veces. ¿Qué genera?
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/TarjetaRFSP.do` — 688 líneas. ¿Para qué publicación? ¿Ejecuta como parte del pipeline?
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/output.do` — 298 líneas. Condicional a `$output`. Documentar su rol.
- `01_modulos/análisis/*` — 5/9 archivos sin uso desde `SIM.do`. **Decidir: eliminar, archivar, o documentar como "análisis standalone".**

---

## 8. Presencia / ausencia de artefactos estándar

| Artefacto esperado | ¿Existe? | Estado |
|---|:---:|---|
| `README.md` | ✅ | Existe, enfocado al usuario final, no al mantenedor |
| Master do-file | ✅ | `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do` (nombre no estándar pero cumple) |
| `dependencies.do` | ❌ | **Ausente.** Dependencias on-demand dispersas |
| `.gitignore` | ⚠️ | Existe, pero insuficiente (ver §6.5) |
| `.mailmap` | ❌ | **Ausente.** Ricardo aparece bajo 4 alias |
| `CHANGELOG.md` | ❌ | **Ausente.** "v7" mencionado en código pero sin registro |
| Tags de release | ❌ | **Ausentes.** |
| Estrategia de ramas documentada | ❌ | Solo `master` |
| Convención de commits | ❌ | Mensajes libres, estilo informal |
| `log using` con timestamp en producción | ❌ | Logs de `.smcl` sobreescritos con nombre fijo |
| `version XX` en todos los `.do` de producción | ⚠️ | Solo subrutinas (REC, CICLO, PC, PERF, INCI, Perfiles subprogramas, Simulador subprogramas, AccesoBIE). Los **10+ programas core carecen de `version`** |
| `assert` tras `merge`/`append` | ❌ | **Cero ocurrencias.** 385+ `merge`/`append` sin validación de `_merge` |
| `notes` / `char` en datasets | ❌ | **Cero ocurrencias** como comando |
| `set seed` antes de operaciones aleatorias | ✅ | `set seed 1111` en `Perfiles.ado:147` y `Simulador.ado:144`. Correcto. |
| `saveold version(13)` para compatibilidad | ✅ | Consistente: `Poblacion`, `SHRFSP`, `PEF`, `expenditures`. Bien. |
| `ado/` con programas user-written dentro del repo | ⚠️ | Existen `.ado` en raíz y en `Stata net/`, pero divergen. `sysdir_site` apunta a la raíz del repo → bien, pero falta carpeta `ado/` formal |
| `help/*.sthlp` | ✅ | Existen 10 help files oficiales. Positivo. |
| `help/*.md` | ✅ | Existen 13 docs Markdown. Positivo. |
| Tests / CI | ❌ | **Ausentes.** Ni GitHub Actions ni tests locales. |

---

## 9. Hallazgos de higiene que Fase 0.5 debe resolver

Traslado a `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/hallazgos.md` en su momento. Listo aquí los que bloquean el arranque de Fase A1 si no se resuelven:

1. **`.gitignore` insuficiente** — agregar `*.smcl`, `*.log`, `*.stswp`, Dropbox conflict files, `.windsurfrules` (decidir), backups.
2. **`raw/` versionado con 607 MB** — decidir Git LFS vs DVC. Impacto inmediato en cualquier nuevo clone.
3. **Duplicación `Stata net/` vs raíz** — la distribución pública divergió. Política de una sola fuente de verdad con build step si se quiere seguir publicando.
4. **Ausencia de `dependencies.do`** — prerequisito para que alguien más pueda correr el pipeline.
5. **`.mailmap` para los 4 alias de Ricardo** — un pequeño fix, enorme ganancia de trazabilidad.
6. **Alias de commit `Update SIM.do`** — convención mínima de commits (recomendar Conventional Commits adaptado).
7. **Normalizar el `sysprofile.do`** — hoy asume ruta `CIEP Dropbox/SimuladorCIEP/` que no existe en el workspace actual. O es leftover, o hay dos ubicaciones sincronizadas.
8. **Archivo eliminado sin commit** (`InformesTrimestrales.do`) — decidir y limpiar el árbol antes de documentar encima.

---

## 10. Hallazgos de código (no de higiene) a reportar en `hallazgos.md`

No son bugs confirmados pero son "olores" que conviene revisar:

- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:19-21` — `if "\`c(username)'" == "ricardo" & "\`1'" != "ricardo"` hardcodea el path de Ricardo. Cualquier otro usuario depende de `sysprofile.do` que apunta a otra ruta.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/01_modulos/análisis/coneval.do:35` — `gl log="\`c(sysdir_site)'../BasesCIEP/INEGI/CONEVAL/2022/Log"` depende de un repo hermano `BasesCIEP/` que no aparece en este workspace.
- `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:352` — `matrix shrfsp = (52.6, ..., 52.6)` (constante 7 años). Supuesto fuerte: **deuda/PIB se congela** en proyecciones. Validar si es supuesto intencional o valor placeholder.
- Parámetros fiscales hardcoded en `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:135-153` (ISR, IVA, IEPS, FMP) duplicados con los del Anexo 8 de la RMF 2025 en `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:162-172`. No hay proceso documentado de actualización anual.
- El código menciona "2025" en comentarios dentro de secciones que ya son 2026 (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/SIM.do:157` *"Anexo 8 de la RMF para 2025"* dentro del bloque 2026). Posible drift de documentación vs. parámetros.

---

### 🧠 Concepto: *Data management* vs. *data governance*

**Data management** es **todo lo que ya tienes en este repo**: código que ingiere datos de fuentes oficiales, los transforma, calcula indicadores, genera gráficas y tablas. Se mide por "¿funciona?". Si el pipeline corre sin error y produce los números del informe anual, el *data management* está bien.

**Data governance** es una capa superior que responde preguntas que el *data management* no puede responder por sí mismo:

- ¿**Quién** puede aprobar un cambio metodológico? ¿Con qué criterios?
- ¿**Qué** datasets son fuente de verdad y cuáles son derivados? ¿Cuál es su linaje?
- ¿**Cuándo** se actualiza cada fuente? ¿Qué hacemos cuando INEGI cambia la base del SCN?
- ¿**Cómo** se versiona una decisión metodológica? Si volvemos a generar el informe 2024 en 2027, ¿obtenemos el mismo número?
- ¿**Por qué** se tomó una decisión hace 3 años? ¿Sigue siendo válida?

La diferencia práctica: *data management* sin governance funciona mientras la misma persona lo opere. En el momento en que entra un nuevo mantenedor, pasa un regulador, o se publica un número que hay que defender 2 años después, la ausencia de governance se siente como dolor. El Simulador está exactamente en ese punto.

Fase 0 diagnostica. Fases 0.5 → A6 construyen la capa de governance sobre el *data management* existente. **No vamos a reescribir el Simulador. Vamos a rodearlo con los artefactos que lo vuelven operable por terceros.**

### 🧠 Concepto: *Bus factor* / *truck number*

El **bus factor** (también llamado *truck number*, *lottery factor*) de un proyecto es el **número mínimo de personas que tendrían que desaparecer (literalmente ser atropelladas por un autobús, o renunciar, o ser contratadas por otro lado) para que el proyecto quede detenido o en crisis irrecuperable**.

Un bus factor de 1 es el peor diagnóstico posible para una pieza de infraestructura crítica: significa que **una sola persona concentra el conocimiento imprescindible**. El proyecto es, en términos operativos, frágil.

En este repo:

- 95.7% de los commits son de Ricardo.
- Las decisiones metodológicas (SCN, ENIGH armonization, brecha fiscal, proyecciones demográficas) no están documentadas en ningún cookbook.
- No hay un segundo revisor. Los merges van directo a `master` sin PR ni code review.
- Los "otros autores" en el `git log` hicieron contribuciones marginales, no tocaron módulos core.

**Bus factor observado: 1.** Mismo nivel que un proyecto personal de un estudiante de doctorado, excepto que el Simulador es insumo del libro CIEP, del micrositio, de los CGPE y posiblemente de tomas de decisión pública. El costo social de un bus factor = 1 en una herramienta así es mucho mayor que el costo en un proyecto personal.

**Objetivo de la transición:** subir el bus factor a **2 antes de intentar llegar a 3**. La diferencia cualitativa entre 1 y 2 es enorme: pasar de "frágil ante ausencia" a "sostenible ante ausencia". La diferencia entre 2 y 3 es cuantitativa: mejora marginal. Con 5 h/sem de mentoring de Ricardo se puede hacer lo primero bien; no lo segundo.

Esto implica: Fase A3.5 debe concentrarse en **una persona**, no en varias en paralelo.

---

## 11. Preguntas críticas para Ricardo antes de iniciar Fase 0.5

(Máximo 3, formuladas como opciones donde se puede.)

1. **Sobre la duplicación `Stata net/` vs raíz**: ¿el paquete distribuible (`Stata net/stata.toc` → `net install` público) sigue activo hoy? ¿Hay usuarios externos al CIEP que lo usan? De tu respuesta depende si en Fase 0.5 convertimos `Stata net/` en un *build artifact* generado (no editado a mano), o lo archivamos como histórico.

2. **Sobre `raw/` versionado (607 MB)**: ¿consideras que los `CP 20XX.xlsx` y `PEF 20XX.xlsx` deben estar en el repo histórico del código, o son sólo materia prima intercambiable? Las opciones para Fase 0.5/A5 son distintas: (a) migrar a **Git LFS** si quieres mantenerlos versionados con el código; (b) migrar a **DVC** si quieres versionarlos desacoplados; (c) sacarlos del repo y referenciarlos desde un *data registry* externo (Dropbox/S3).

3. **Sobre los ~5,000 líneas de `01_modulos/análisis/` que no son invocadas por `SIM.do`** (`coneval.do`, `Subnacional.do`, `Cap_Ingresos_30.do`, `MicrositioPE.do`, `SectoresEconómicos...`, etc.): ¿son análisis vivos que corres fuera del pipeline principal, o son legacy que se podría archivar en una rama/tag `legacy`? Esto afecta directamente el mapa de complejidad y la superficie de onboarding.

---

## Próximo paso

Con tus respuestas a las tres preguntas, paso a **Fase 0.5 — Higiene del repo**, cuyos artefactos serán (uno por turno, no todos juntos):

1. `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/git-hygiene-audit.md` — diagnóstico Git formal
2. `.gitignore` actualizado para Stata + `.mailmap` para normalizar tus alias
3. `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/convenciones-git.md` — convención de commits + estrategia de ramas + política de tags
4. Recomendación **Git LFS vs DVC** para `raw/` y `master/`, justificada

Cada artefacto lo construimos, discutimos, afinamos. No hay "documento maestro de 40 páginas".
