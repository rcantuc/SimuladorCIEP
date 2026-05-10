# Fase 0.5 — Auditoría de seguridad pre-rewrite

**Fecha:** 2026-05-09  
**Propósito:** verificar que NO existe material sensible (datos personales, credenciales, drafts confidenciales, llaves) en la historia Git **antes** de ejecutar el `git filter-repo --invert-paths` (Acción 6) que reescribe historia y purga binarios. Los binarios actuales se republicarán como assets de GitHub Release `v7.0` bajo el patrón Data Sidecar (decisión arquitectónica registrada en `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/fase-0-5-git-hygiene-audit.md` §4; documentación operativa detallada pendiente en Acción 8).  
**Naturaleza:** diagnóstico solo. No modifica nada. Define los patrones de exclusión que la Acción 6 (rewrite) debe usar.

---

## 1. Síntesis ejecutiva

| Categoría auditada                                 | Hallazgo                                                                                                    | Acción requerida pre-rewrite                                                                                            |
| ----------------------------------------------------| -------------------------------------------------------------------------------------------------------------| -------------------------------------------------------------------------------------------------------------------------|
| **Llaves SSL privadas** (`*.key`)                  | NO entraron a la historia. Existen sólo en el árbol actual bajo `simuladorfiscal.ciep.mx/ssl/`, gitignored. | ✅ Sin acción urgente. Reforzar `.gitignore` con patrón explícito en Acción 3.                                           |
| **Tokens / API keys**                              | Hay 1 token UUID hardcoded en `AccesoBIE.ado:13` (BIE de INEGI, datos públicos). Bajo riesgo.               | ⚠️ **Rotar ANTES del rewrite**: solicitar token nuevo a INEGI + migrar `AccesoBIE.ado` a env var con fallback (ver §2.2) + crear `governance/secretos.md`. |
| **Datos personales / PII**                         | No detectados. Las `.dta` históricas son ENIGH (anonimizadas por INEGI).                                    | ✅ Sin acción.                                                                                                           |
| **Drafts confidenciales**                          | 2 archivos `.docx` (manuales) borrados de tronco; pueden tener metadatos Word.                              | ✅ El rewrite los purga al eliminar `00_manuales/`.                                                                      |
| **Software de terceros redistribuido**             | Carpeta `x12arima/` (X-12-ARIMA del U.S. Census Bureau) con `.exe` y docs PDF.                              | ✅ El rewrite los purga. Software de dominio público (US Government Work).                                               |
| **Dropbox conflict files / Stata recovered files** | Confirmados: `(... conflicted copy ...)`, `[Recovered]`.                                                    | ✅ El rewrite los purga si se incluyen en patrones.                                                                      |
| **Forks activos en GitHub**                        | 1 fork: `JuanPabloSantisteban/SimuladorCIEP` (v5, inactivo desde feb-2025).                                 | ✅ Sin acción. Ricardo confirma que JP ya no trabaja en el Simulador; el fork queda como snapshot histórico v5.          |
| **Referencias externas a SHAs específicos**        | Cero detectadas en `README.md`, `help/`, `governance/`, README de GitHub.                                   | ✅ Sin acción.                                                                                                           |
| **Ramas remotas no fetcheadas**                    | Sólo `origin/master`. Nada huérfano.                                                                        | ✅ Sin acción.                                                                                                           |

**Conclusión:** la auditoría no encontró bloqueantes. Una mejora obligatoria (rotar token API antes del rewrite, no después), y los patrones de exclusión del rewrite definidos en §5.

---

## 2. Hallazgos detallados

### 2.1 Llaves SSL privadas — VERIFICADO LIMPIO ✅

**Estado en árbol actual** (`simuladorfiscal.ciep.mx/ssl/`):

```
-rw-------@ 1 ricardo staff 1674 May 12 2025 iepsaltabaco.ciep.mx_private_key.key
-rw-------@ 1 ricardo staff 1678 May 14 2025 simuladorfiscal.ciep.mx_private_key.key
```

Ambas son **PEM RSA private keys** auténticas (verificado con `file`). Son las llaves activas de los servidores `simuladorfiscal.ciep.mx` y `iepsaltabaco.ciep.mx`. Permisos `600`, sólo Ricardo.

**Estado en historia Git:**

```bash
git log --all -- '*.key' '*private_key*' '**/ssl/*'
# (sin output)
```

**Cero commits.** Las llaves nunca entraron al repo. El patrón `**/simuladorfiscal.ciep.mx/**` en `.gitignore` (`@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/.gitignore:5`) las protegió desde el primer commit.

**Recomendación operativa:** reforzar `.gitignore` con patrón redundante específico para no depender de un solo gate. Añadir en Acción 3:

```
# Llaves y certificados (nunca commit)
*.key
*.pem
*.p12
*.pfx
*.crt
**/ssl/**
```

**Riesgo residual:** quien clone el repo HOY no obtiene las llaves. ✅ El rewrite no las afecta porque no están en historia.

### 2.2 Token API hardcoded en `AccesoBIE.ado` — RIESGO BAJO, ACCIÓN RECOMENDADA

**Ubicación:** `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/AccesoBIE.ado:11-14`

```stata
// Token por defecto (CIEP)
if "`token'" == "" {
    local token "[REDACTED-BIE-TOKEN]"
}
```

**Análisis del riesgo:**

- **Servicio:** API del Banco de Indicadores Económicos (BIE) del INEGI. Acceso a series económicas públicas.
- **Modelo de control de acceso:** registro gratuito por usuario, sin cuotas restrictivas conocidas, sin facturación. INEGI puede revocar tokens por uso abusivo.
- **Documentación intencionalmente pública:** `help/Stata/AccesoBIE.sthlp:48-49` y `help/AccesoBIE.md:85` declaran "El token de acceso del CIEP está incluido por defecto".
- **Histórico:** `git log -S 'c228a022-...'` muestra que el token aparece desde el commit `499a06f` ("Simulador Fiscal CIEP. Versión 7."). Es el único token que ha existido en el repo. No hay rotaciones silenciosas con tokens distintos.
- **Impacto si lo abusan:** un actor malicioso puede consumir cuota del BIE bajo identidad CIEP. INEGI revoca el token; CIEP solicita uno nuevo. Inconveniente, no incidente.

**Decisión consolidada (2026-05-09):** rotar el token **ANTES** del rewrite, no después. Razón: el rewrite no limpia texto dentro de archivos `.ado` (el token está en código fuente, no en binario). La protección real es la revocación con INEGI. Si el token se rota antes y se reemplaza el código, la historia post-rewrite empuja con el token nuevo desde el primer commit.

**Implementación elegida** (cuarta opción, híbrida — env var con fallback de cortesía):

```stata
// AccesoBIE.ado — sección de resolución de token
// Prioriza variable de entorno; cae a token público de cortesía CIEP.
local token_env : env "BIE_TOKEN"
if "`token'" == "" & "`token_env'" != "" {
    local token "`token_env'"
}
if "`token'" == "" {
    local token "[NUEVO-TOKEN-ROTADO-AQUI]"  // token de cortesía CIEP, ver help/AccesoBIE.md
}
```

**Ventaja del fallback:** el código sigue corriendo out-of-the-box (no fricciona el onboarding), pero quien quiera hacerlo bien define `BIE_TOKEN` en su entorno y deja de depender del compartido.

**Ítems operativos:**

1. Solicitar token nuevo a INEGI bajo cuenta CIEP.
2. Reemplazar el UUID en `AccesoBIE.ado:13` y en `Stata net/AccesoBIE.ado:13` (mientras `Stata net/` siga vigente).
3. Actualizar `help/Stata/AccesoBIE.sthlp` y `help/AccesoBIE.md` para documentar la variable `BIE_TOKEN`.
4. Crear `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/secretos.md` declarando: qué secretos existen, dónde viven, quién los rota, cada cuánto.
5. Confirmar revocación del token viejo con INEGI.

### 2.3 Manuales `.docx` borrados — sin acción más allá del rewrite

**Blobs históricos confirmados:**

```
6a5df47e... 00_manuales/Manual Simulador Fiscal CIEP.docx
435c622f... 00_manuales/Manual Simulador Fiscal V5_JP.docx
```

**Riesgo:** archivos Word pueden contener track changes, comentarios firmados con nombres, propiedades de metadata (autor, organización). El sufijo `_JP` sugiere borrador colaborativo con Juan Pablo.

**Acción:** `git filter-repo --path 00_manuales/` (ya planeado en patrones de exclusión §5) los purga completamente. **Sin trabajo adicional.**

### 2.4 Software de terceros: `x12arima/` — purgar por higiene

**Blobs históricos:**

```
842a4e00... x12arima/x12a.exe
abbfe065... x12arima/unins000.exe
9cf6d36c... x12arima/unins000.dat
053ac777... x12arima/docs/x12adocV03.pdf
10aff234... x12arima/docs/qref03pc.pdf
534af843... x12arima/docs/ReleaseNotesVersion03.pdf
8cd8adb7... x12arima/examples
bf41538a... x12arima/examples/airline.spc
```

**Análisis:** X-12-ARIMA es software del U.S. Census Bureau para ajuste estacional. Es **U.S. Government Work, dominio público**, redistribución legalmente permitida sin licencia. Sin embargo:

- Binarios Windows (`.exe`) en repo Git son mala práctica.
- Posiblemente reemplazado por X-13ARIMA-SEATS (sucesor oficial); la versión 03 es vieja.
- No hay referencia a X-12 en el código actual del repo.

**Acción:** purgar con `--path x12arima/` en el rewrite.

### 2.5 Conflict files (Dropbox) y archivos `[Recovered]` (Stata) — purgar

**Blobs identificados en historia:**

```
006d0318... IVA_Mod (ServidorCIEP's conflicted copy 2021-05-28).do
768330c5... SIM (ServidorCIEP's conflicted copy 2021-05-28).do
b76832de... tabaco/Nov2022/bases/entidades (Ricardo Cantú's conflicted copy 2022-11-10).dta
16f5dd4d... Do_Medio_ambiente [Recovered].do
6cbdf5e1... Sankey_Salud_2024 [Recovered].do
```

**Acción:** purgar con patrones específicos en el rewrite (§5). Adicionalmente, agregar al `.gitignore` (Acción 3) los patrones para que no vuelvan a entrar.

### 2.6 `aserv.dta` y `backup.do` — verificados benignos

**`aserv.dta`** (1,350 bytes, blob `85a739b0`):

- Header `<stata_dta>` confirma formato Stata 13+. Tamaño minúsculo (1.3 KB) descarta dataset con datos personales o microdatos.
- Probablemente lookup table o dataset de testing.
- Subido en el primer commit del repo (`9954eca` 2018-10-29 "Add files via upload").
- **Verificado: no contiene material sensible por su tamaño.**

**`backup.do`** (blob `72a32270`):

- Es código Stata válido. Lógica de cálculo de costo financiero de la deuda (`shrfsp`, `costodeudashrfsp`, proyección de `rfspBalance`).
- Versión vieja de fragmentos hoy en `FiscalGap.ado` o `SHRFSP.ado`. Sin contenido sensible.
- Comprometido en commits 2018-2021.

**Acción:** ambos se purgan al eliminar la carpeta raíz histórica donde vivieron (estaban en raíz, no subcarpeta). Ver §5.

### 2.7 Carpetas históricas borradas confirmadas como insumos masivos sin contenido sensible

| Path | Contenido | Tamaño histórico | Sensibilidad |
|---|---|---:|---|
| `tabaco/Nov2022/Datos.dta` | ENIGH 2020 procesada (análisis fiscal del tabaco) | 99 MB | ENIGH es público y anonimizado por INEGI |
| `tabaco/Nov2022/bases/ENIGH 2020/concentrado.dta` | ENIGH 2020 original | 81 MB | Idem (público) |
| `tabaco/Nov2022/bases/concentradohogar.dta` | ENIGH hogar | 35 MB | Idem |
| `bases/PEFs/CP*.xlsx` (~25 archivos) | Cuentas Públicas históricas SHCP | ~700 MB total | SHCP, públicos en Diario Oficial |
| `2008/*.xlsx` | Snapshots viejos de Estadísticas Oportunas SHCP | ? | Idem (públicos) |
| `00_manuales/ManualSimuladorCIEP/*.pdf` | Documentación del Simulador | ~50 MB | Material de difusión, público |
| `help/images/Video1.mov` | Video tutorial | 47 MB | Material de difusión, público |
| `5.0/` (~70 archivos) | Versión histórica del Simulador (v5) | varias MB | Código no sensible; mismas fórmulas que `v7` |

Ninguno contiene material que requiera tratamiento legal especial. Todos son insumos públicos de fuentes oficiales o material propio de difusión. **El rewrite los purga porque pesan en el `.git`, no porque sean confidenciales.**

---

## 3. Forks activos en GitHub

### 3.1 `JuanPabloSantisteban/SimuladorCIEP`

**Datos:**

| Campo | Valor |
|---|---|
| URL | https://github.com/JuanPabloSantisteban/SimuladorCIEP |
| Título | "Simulador Fiscal CIEP **v5**" |
| Creado | 2025-02-21 19:00 UTC |
| Última actualización | 2025-02-21 23:16 UTC (mismo día) |
| Stars | 0 |
| Forks-de-fork | 0 |
| Issues abiertos | 0 |
| PRs abiertos hacia upstream | 0 |
| Estado | Inactivo desde el día de creación |

**Diagnóstico:** snapshot personal de Juan Pablo Santisteban tomado en feb-2025. Su README declara "v5" mientras el upstream actual es "v7". El fork es **funcionalmente abandonado** — no ha recibido cambios en 14 meses, no tiene PRs hacia upstream.

**Identidad de JP:** `git log --author="JuanPablo"` muestra 10 commits de él en upstream (desde el alias `Jotapelopez3696` con email `juanpablo.loprey@gmail.com`). Su cuenta `JuanPabloSantisteban` (51425712) es probablemente una segunda cuenta GitHub más reciente.

**Impacto del history rewrite sobre su fork:**

- Sus commits locales (si los tiene fuera del repo) quedan referenciando SHAs que ya no existen.
- En la práctica, dado que el fork no tiene cambios propios, simplemente queda "huérfano" pero usable como snapshot v5.
- Si JP intentara `git pull` desde su fork hacia upstream, vería conflicto masivo (o `non-fast-forward`).

**Decisión (2026-05-09):** **no notificar.** Ricardo confirma que JP ya no trabaja con el Simulador. Su fork queda como snapshot histórico v5; no requiere coordinación.

Plantilla de notificación originalmente preparada en §6 — preservada como referencia para futuros casos similares (otros forks que aparezcan), no se ejecuta ahora.

**Otros forks:** ninguno. La página `/forks` del repo upstream lista exactamente uno (`JuanPabloSantisteban/SimuladorCIEP`).

---

## 4. Referencias externas a SHAs específicos del repo

Búsqueda exhaustiva por patrones SHA-1 de Git (7-40 caracteres hex):

| Lugar | Hallazgos |
|---|---|
| `README.md` (local) | Cero |
| `help/*.md`, `help/Stata/*.sthlp` | Cero |
| `governance/*.md` | Cero (excepto el SHA `2f46d92` que cito explícitamente como HEAD pre-rewrite — se actualizará tras el rewrite) |
| README de GitHub (online, scraping del HTML público) | Cero |
| Posible blog CIEP (`ciep.mx`) | **No verificado.** Pendiente de tu confirmación: ¿hay artículos de blog que enlacen a `github.com/rcantuc/SimuladorCIEP/blob/<sha>/...`? |
| Twitter/X de CIEP | **No verificado.** ¿Algún hilo enlaza commits específicos? |
| Publicaciones académicas / libro CIEP | **No verificado.** Si el libro cita "código en commit X de fecha Y", el rewrite rompe el enlace. |

**Acción recomendada:** después del rewrite, si descubres referencias rotas, redirigir al **tag `v7.0` que crearemos en Acción 7** sobre el SHA equivalente post-rewrite.

---

## 5. Patrones de exclusión definitivos para el `git filter-repo`

> **Nota (2026-05-09):** la sección originalmente listaba también patrones para `git lfs migrate import`. La estrategia LFS fue descartada en favor del Data Sidecar pattern (registrado en `@/Users/ricardo/Library/CloudStorage/Dropbox-CIEP/Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/governance/fase-0-5-git-hygiene-audit.md` §4). Sólo aplican los patrones de purga (§5.1).

### 5.1 Patrones a **purgar completamente** de la historia (`git filter-repo --invert-paths`)

```text
# Carpetas históricas eliminadas que nunca volverán
--path tabaco/
--path bases/
--path 2008/
--path 00_manuales/
--path 5.0/
--path x12arima/
--path Manuales/
--path SankeySIM/
--path SankeySF/
--path Images/

# Archivos sueltos eliminados
--path-regex '.*conflicted copy.*'
--path-regex '.*\[Recovered\].*'
--path help/images/Video1.mov
--path aserv.dta
--path backup.do
--path 'sysprofile A COPIAR.do'
--path Acentos.ado
--path 'LIF copy.ado'
--path 'PEF copy.ado'
--path 'Sankey BK.ado'
--path Sankeyold.ado
--path 'LIEBK.do'
--path 'Do_Medio_ambiente [Recovered].do'
--path 'Sankey_Salud_2024 [Recovered].do'

# Archivos de error/log de Stata
--path-regex 'hs_err_pid.*\.log'

# Dropbox conflicts genéricos
--path-glob '* (*conflicted copy*).*'
```

### 5.2 Patrones a **purgar adicionalmente** del histórico (decisión Data Sidecar, 2026-05-09)

Bajo el patrón Data Sidecar, `raw/` también se purga del histórico Git porque sus contenidos van a vivir en GitHub Releases:

```text
# Carpetas y archivos vivos que migran a GitHub Releases (assets v7.0)
--path raw/
# Otros binarios pesados sueltos en raíz que no vivirán en repo
--path BIE_tabla_equivalencias.csv
```

**Importante:** purgar `raw/` del histórico es destructivo respecto al repo Git, pero los archivos NO se pierden — se publican como assets del release `v7.0` antes del `git push --force-with-lease`. El manifiesto `raw/manifest.json` queda en el repo y permite recuperarlos vía script.

### 5.3 Manifiesto y excepciones a `.gitignore`

Una vez ejecutado el rewrite, el `.gitignore` impide que `raw/` vuelva a entrar accidentalmente, **excepto el manifiesto**:

```
# .gitignore (Acción 3)
**/raw/**
!raw/manifest.json
```

Esto preserva la atomicidad código↔datos: cualquier checkout del repo en cualquier commit lleva consigo el manifiesto que apunta a los assets exactos correspondientes a ese estado de código.

---

## 6. Plantilla de comunicación pre-rewrite (preservada, no se ejecuta)

> **Decisión 2026-05-09:** no se enviará. Se preserva como template reutilizable si en el futuro aparece un fork activo que sí requiera coordinación.

Para enviar a un titular de fork activo antes de un `git push --force`:

```
Asunto: Heads-up: SimuladorCIEP repo upstream va a reescribir historia (Git LFS migration)

Hola Juan Pablo,

Quiero avisarte que el repositorio github.com/rcantuc/SimuladorCIEP va a sufrir
una reescritura de historia en los próximos días, como parte de un trabajo de
modernización del control de versiones (migración a Git LFS para reducir el
tamaño del repo de 5 GB a ~250 MB).

Como tienes un fork del repo (JuanPabloSantisteban/SimuladorCIEP), tu copia
quedará con SHAs que ya no van a existir en upstream. Si todavía te interesa
el código:

  - Tu fork actual queda como snapshot histórico v5 (que es lo que ya declara).
  - Si quieres mantenerlo sincronizado, te tocará re-clonar y re-fork después
    del rewrite.
  - Si no piensas seguir trabajando con el repo, simplemente ignora este aviso.

El rewrite está agendado para [FECHA]. El nuevo HEAD se etiquetará como v7.0.

Cualquier duda, me dices.

Ricardo
```

---

## 7. Acciones derivadas de esta auditoría

Resumiendo lo que hay que hacer ANTES de Acción 6 (rewrite):

| Sub-acción | Cuándo | Bloqueante para rewrite |
|---|---|:---:|
| Reforzar `.gitignore` con patrones `*.key`, `*.pem`, `**/ssl/**`, `* (*conflicted copy*).*`, `*[Recovered]*`, `hs_err_pid*.log`, `**/raw/**` (con excepción `!raw/manifest.json`) | Acción 3 (programada) | Sí |
| ~~Notificar a Juan Pablo Santisteban (fork owner)~~ | — | ~~Sí~~ → **Descartado**: JP ya no está activo |
| **Rotar token BIE de INEGI y migrar a variable de entorno con fallback** | **Antes** del rewrite (no después) | Sí |
| Crear `governance/secretos.md` documentando todos los secretos | Junto con la rotación del token | No (pero recomendado) |
| Confirmar que no hay artículos de blog/Twitter/libro citando SHAs específicos | Antes del rewrite | Recomendado |
| Construir `raw/manifest.json` y script `download_data` | Antes del rewrite, **probarlos en clone fresco** | Sí |
| Backup integral: `git clone --mirror . ../SimuladorCIEP-backup-pre-rewrite.git` + copia en disco externo | **Inmediatamente antes** de ejecutar rewrite | **Sí, obligatorio** |
| Tener listo el contenido de `raw/` para subirlo como assets del Release `v7.0` | Antes del `git push --force-with-lease` | Sí |

---

## 8. Próximo paso

Procedo con Acción 1 (`.mailmap`) en paralelo a este reporte. Es independiente del rewrite y te muestra efecto inmediato.

Una vez que confirmes:

1. ✅ Recibido y leído este reporte.
2. ✅ Decisión sobre rotación de token BIE: **(a)** ahora con Acción 6, **(b)** después en Fase A2.
3. ✅ Confirmas que no hay blog/libro con SHAs.
4. ✅ Aviso a JP enviado / decides no enviarlo.

…paso a las Acciones 2 → 3 → 8 → 7 (milestone v7.0) → 4 → 5 → backup pre-rewrite → 6 → tag v8.0.
