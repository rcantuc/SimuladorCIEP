# Arquitectura de distribución de los Simuladores CIEP

**Ubicación en el Ecosistema CIEP.** Este documento describe la arquitectura técnica de los Simuladores CIEP — uno de los componentes del **Ecosistema CIEP** (el conjunto completo de productos digitales, infraestructura y dominios del CIEP; definición formal en el Glosario CIEP institucional, `glosario-ciep.md`). Otros componentes del Ecosistema (Micrositios, sitio principal `ciep.mx`, infraestructura general) se describen en otros documentos de governance o están pendientes de documentar formalmente.

**Alcance.** Los **Simuladores CIEP** son el ecosistema de tres herramientas interactivas web del CIEP, todas alojadas como subdominios de `ciep.mx`: el Simulador Fiscal CIEP (`simuladorfiscal.ciep.mx`), el Simulador IEPS al tabaco (`iepsaltabaco.ciep.mx`) y el Simulador de tenencia vehicular (`tenencia.ciep.mx`). "Simuladores CIEP" es sustantivo colectivo: las políticas y procedimientos de governance del CIEP aplican a los tres por defecto, no por excepción. Este documento describe la arquitectura común al ecosistema. El Simulador Fiscal CIEP es el caso operativo más maduro y mejor documentado, y es el ejemplo concreto al que se anclan las descripciones detalladas de las secciones 2 a 5; los simuladores de IEPS al tabaco y de tenencia vehicular son sustantivamente más pequeños en código y complejidad, y aún no tienen governance formal aplicada, pero la arquitectura, las políticas y los procedimientos aquí descritos se diseñan para extenderse a ellos.

**Naturaleza del documento:** describe la arquitectura de los Simuladores CIEP como sistema de cuatro capas. Desde v8.0 (julio de 2026) la arquitectura está desplegada para el Simulador Fiscal CIEP: `publicar.sh` con gates, `CHANGELOG.md`, el banner de versión de `profile.do`, el comando `sim_changelog`, el candado de datos (`manifest.json` + `ensure_asset`) y el pipeline al VPS con backup y rollback operan en producción. La sección 7 lista lo que sigue pendiente (`reproducir.sh`, alta automatizada de investigadores, consolidación de infraestructura) y la extensión a los simuladores de IEPS al tabaco y tenencia vehicular es trabajo posterior.

**Este documento no lleva bitácora propia.** Hasta el 2026-10-03 la llevó (v1.0–v1.57), junto con la narrativa de cada deploy; esa memoria está congelada en `historico/bitacora-arquitectura.md`. Los cambios al Simulador se registran únicamente en `CHANGELOG.md`; este documento se reescribe en su lugar cuando la arquitectura cambia.

**Para quién es este documento:** cualquier persona que interactúe con los Simuladores CIEP. Investigadores CIEP que los usan como herramientas, el investigador principal que los desarrolla, investigadores colaboradores que se sumen al mantenimiento, lectores externos que necesiten reproducir un análisis publicado, o usuarios externos que entran a los sitios web públicos.

**Qué encuentras aquí:** cómo está organizado el ecosistema como sistema vivo. No es un solo producto con una sola audiencia; son cuatro capas con audiencias y mecanismos distintos que comparten patrones arquitectónicos comunes y, en el caso del Simulador Fiscal CIEP, un solo motor de cálculo expuesto a través de varias interfaces.

**Cuatro preguntas que este documento responde:**

1. *Si soy investigador del CIEP y nunca he tocado Git, ¿cómo uso el Simulador Fiscal CIEP en mi día a día?* → Sección 2.
2. *Si voy a publicar una versión nueva al equipo, ¿qué tengo que hacer?* → Sección 3.
3. *Si necesito reproducir exactamente lo que el Simulador Fiscal CIEP produjo cuando se publicó un análisis hace año y medio, ¿cómo lo hago?* → Sección 5.
4. *¿Cómo se relacionan los Simuladores CIEP entre sí y cómo se conectan con sus herramientas web públicas?* → Sección 6.

**Qué NO encuentras aquí:** cómo se hacen commits, ramas o pull requests en el lado de desarrollo. Eso vive en `versionado-y-git.md`. Este documento describe la arquitectura completa; el otro describe el detalle operativo de la Capa 1.

---

## Tabla de contenido

1. [La arquitectura en una imagen](#1-la-arquitectura-en-una-imagen)
2. [Para ti, investigador CIEP: cómo se ve el Simulador del día a día](#2-para-ti-investigador-ciep-cómo-se-ve-el-simulador-del-día-a-día)
3. [Para ti, investigador principal: cómo publicar una versión nueva](#3-para-ti-investigador-principal-cómo-publicar-una-versión-nueva)
4. [Qué es "una versión publicada"](#4-qué-es-una-versión-publicada)
5. [Cómo reproducir un análisis publicado](#5-cómo-reproducir-un-análisis-publicado)
6. [Las herramientas web públicas](#6-las-herramientas-web-públicas)
7. [Lo que NO está implementado todavía](#7-lo-que-no-está-implementado-todavía)
8. [Comportamientos no obvios y troubleshooting](#comportamientos-no-obvios-y-troubleshooting)

---

## 1. La arquitectura en una imagen

*Qué aprendes en esta sección:* por qué los Simuladores CIEP están organizados como cuatro capas distintas y cómo se conectan.

Los Simuladores CIEP no son un solo sistema con una sola audiencia. Son **piezas de software con cuatro tipos de gente que las tocan, cada uno con necesidades distintas**: el investigador principal y los investigadores colaboradores que escriben el código; los investigadores CIEP que los usan como herramientas de análisis fiscal; quien necesita volver a una versión vieja para defender un número publicado; y los usuarios externos (ciudadanos, periodistas, académicos, funcionarios) que entran a los sitios web públicos para simular políticas. Diseñar las cuatro situaciones bajo un solo mecanismo te obliga a hacer concesiones que dañan a todos.

Lo importante es que **las cuatro capas comparten un mismo motor de cálculo dentro de cada simulador**. Lo que cambia es la interfaz hacia cada audiencia y la frecuencia con que cada capa recibe actualizaciones. Por eso un cambio metodológico introducido en la Capa 1 termina, eventualmente, reflejándose en lo que un sitio web público devuelve a un periodista o en lo que un investigador CIEP ve al correr `PEF` en Stata. Esta arquitectura está completamente desplegada hoy para el **Simulador Fiscal CIEP** — el caso operativo más maduro, al que se anclan las descripciones detalladas de las secciones 2 a 5. Los simuladores de **IEPS al tabaco** y **tenencia vehicular** existen sustantivamente en la Capa 4 (la herramienta web pública); las otras tres capas operan de manera informal y aún no tienen governance formal aplicada. El plan es extenderles esta arquitectura en fases siguientes.

**Repositorios Git independientes.** Los tres Simuladores CIEP tienen **repositorios Git independientes con desarrollo paralelo**. El Simulador Fiscal CIEP vive en `github.com/rcantuc/SimuladorCIEP`; el Simulador IEPS al tabaco y el Simulador de tenencia vehicular viven en repositorios propios, separados. Comparten código por reuso histórico — el código del Simulador Fiscal CIEP sirvió de base inicial para los otros dos — pero no por dependencia activa: cada uno tiene su propia historia de cambios, sus propias versiones publicadas, sus propias decisiones metodológicas y su propio calendario de publicación. La governance formal documentada en este documento corresponde **al repositorio del Simulador Fiscal CIEP**. Cuando se extienda governance a los repositorios de IEPS al tabaco y tenencia vehicular, será trabajo concreto en cada uno de ellos — no aplicación automática de las políticas existentes.

El esquema es éste:

```
   ┌──────────────────────────────────────────────────────────────────┐
   │   CAPA 1: Desarrollo                                             │
   │                                                                  │
   │   Audiencia: investigador principal + investigadores             │
   │              colaboradores                                       │
   │   Herramienta: Git (github.com/rcantuc/SimuladorCIEP)            │
   │   Carpeta local: ~/Documents/SimuladorCIEP/  (FUERA de Dropbox)  │
   │                                                                  │
   │   ──── Motor de cálculo único compartido por las cuatro capas ───│
   └─────┬──────────────────┬─────────────────────┬───────────────────┘
         │                  │                     │
   publicar.sh        reproducir.sh      procedimiento de
   (al publicar       (puntual, cuando   actualización del
    una versión       alguien necesita   sitio web (al publicar
    nueva)            una versión vieja) una versión nueva)
         │                  │                     │
         ▼                  ▼                     ▼
   ┌────────────────┐  ┌────────────────┐  ┌──────────────────────┐
   │   CAPA 2       │  │   CAPA 3       │  │   CAPA 4             │
   │   Distribución │  │   Reproducción │  │   Herramientas web   │
   │   vigente para │  │   histórica    │  │   públicas           │
   │   investigadores│ │                │  │                      │
   │                │  │ Audiencia:     │  │ Audiencia: usuarios  │
   │ Audiencia:     │  │ cualquiera que │  │ externos             │
   │ investigadores │  │ necesite una   │  │ (ciudadanos, perio-  │
   │ CIEP           │  │ versión vieja  │  │ distas, académicos,  │
   │                │  │                │  │ funcionarios)        │
   │ Carpeta del    │  │ Carpeta tem-   │  │                      │
   │ Simulador para │  │ poral, descart-│  │ Tres Simuladores     │
   │ investigadores │  │ able           │  │ CIEP (detalle abajo):│
   │ ~/Dropbox-CIEP/│  │ Misma versión  │  │ • Fiscal CIEP        │
   │ SimuladorCIEP/ │  │ que pidió quien│  │ • IEPS al tabaco     │
   │ Stata corre    │  │ corrió el      │  │ • Tenencia vehicular │
   │ profile.do al  │  │ script         │  │                      │
   │ arrancar       │  │                │  │ Infraestructura dual:│
   │                │  │                │  │ Cloudways + IONOS    │
   │                │  │                │  │ (ver §6.2)           │
   │                │  │                │  │                      │
   │                │  │                │  │ Versionado alineado  │
   │                │  │                │  │ con la versión       │
   │                │  │                │  │ publicada actual de  │
   │                │  │                │  │ cada simulador       │
   └────────────────┘  └────────────────┘  └──────────────────────┘
```

Las flechas son direccionales. La Capa 1 es el origen: ahí se escribe el código y se mantienen las decisiones metodológicas. Las otras tres capas reciben actualizaciones distintas: la Capa 2 recibe automáticamente la versión nueva cada vez que el investigador principal ejecuta `publicar.sh` ; la Capa 3 se invoca puntualmente, bajo demanda, sin calendario fijo; la Capa 4 se actualiza siguiendo un procedimiento del lado web cuando se publica versión nueva — con la particularidad de que para el Simulador Fiscal CIEP esa actualización debe llegar a sus **dos sub-canales**: el sitio HTML interactivo (al que entran usuarios externos sin Stata) y el canal de instalación Stata vía `net from` (desde donde un usuario externo que sí usa Stata se instala el Simulador en su propia máquina). Los simuladores de IEPS al tabaco y tenencia vehicular tienen un único sub-canal (HTML).

**Detalle de la Capa 4 — los tres Simuladores CIEP:**

```
   ┌──────────────────────────┐  ┌──────────────────────────┐  ┌──────────────────────────┐
   │ Simulador Fiscal CIEP    │  │ Simulador IEPS al tabaco │  │ Simulador de tenencia    │
   │                          │  │                          │  │ vehicular                │
   │ Sub-canal HTML:          │  │                          │  │                          │
   │ simuladorfiscal.ciep.mx  │  │ Sub-canal HTML único:    │  │ Sub-canal HTML único:    │
   │ (alojado en IONOS)       │  │ iepsaltabaco.ciep.mx     │  │ tenencia.ciep.mx         │
   │                          │  │ (alojado en IONOS)       │  │ (alojado en IONOS)       │
   │ Sub-canal Stata net from:│  │                          │  │                          │
   │ ciep.mx/simuladorfiscal  │  │ Audiencia: ciudadanos,   │  │ Audiencia: ciudadanos,   │
   │ (alojado en Cloudways;   │  │ periodistas, salud       │  │ propietarios de          │
   │ sirve los archivos de    │  │ pública, fumadores       │  │ vehículos, periodistas   │
   │ instalación que necesita │  │ informados               │  │ del ramo                 │
   │ el comando `net from`)   │  │                          │  │                          │
   │ Audiencia: ciudadanos,   │  │                          │  │                          │
   │ periodistas, académicos, │  │ Interfaz: navegador web  │  │ Interfaz: navegador web  │
   │ analistas con Stata      │  │                          │  │                          │
   │                          │  │ Protocolo: HTTPS + SSL   │  │ Protocolo: HTTPS + SSL   │
   │ Detalle de los dos       │  │ (ver §6.5)               │  │ (ver §6.5)               │
   │ sub-canales del Fiscal:  │  │                          │  │                          │
   │ §6.5 (web HTML) y        │  │ Governance formal:       │  │ Governance formal:       │
   │ §6.6 (Stata net from)    │  │ pendiente (ver §7)       │  │ pendiente (ver §7)       │
   └──────────────────────────┘  └──────────────────────────┘  └──────────────────────────┘
```

Los tres simuladores son subdominios del dominio raíz `ciep.mx` y comparten el mismo proveedor de DNS, pero corren en **infraestructura distinta** según el sub-canal. Los tres sitios HTML interactivos están alojados en un VPS de **IONOS** (servidor virtual privado dedicado al CIEP). El sub-canal Stata `net from` del Simulador Fiscal CIEP está alojado en **Cloudways**, el mismo hosting administrado donde vive el sitio principal `ciep.mx` y sus micrositios. Esta separación es histórica, no de diseño, y está bajo revisión: §6.2 explica la dualidad de infraestructura (qué es cada proveedor, qué activo vive en cuál, quién tiene acceso) y §7 anota la decisión pendiente sobre consolidación. El detalle de los dos sub-canales del Fiscal CIEP está en §6.5 (web HTML) y §6.6 (Stata `net from`).

---

## 2. Para ti, investigador CIEP: cómo se ve el Simulador del día a día

*Qué aprendes en esta sección:* cómo encontrar el Simulador, qué pasa cuando lo abres, cómo correrlo, y cómo saber qué versión usaste.

Esta sección es para ti si trabajas en el CIEP y usas el Simulador para hacer análisis fiscal. **No necesitas saber Git** (el sistema de control de versiones donde vive el código). No necesitas saber qué es un *commit* (un cambio registrado en la historia del código). El Simulador llega a tu computadora vía Dropbox, lo abres con Stata, corres tus comandos. Eso es todo.

### 2.1 Dónde está el Simulador

El Simulador vive en una carpeta compartida en Dropbox a la que llamamos la **Carpeta del Simulador para investigadores**. En tu máquina, esa carpeta se sincroniza automáticamente:

```
~/Dropbox-CIEP/SimuladorCIEP/
```

Cuando se publica una versión nueva, Dropbox la baja a tu máquina sin que tengas que hacer nada. Si abres Stata mañana, ya está la nueva versión.

### 2.2 Qué pasa cuando abres Stata

Cuando arrancas Stata, dos archivos de configuración se ejecutan en orden, automáticamente:

1. **Primero `sysprofile.do`**, que vive en `~/StataNow/sysprofile.do` — dentro de la carpeta de instalación de Stata en tu máquina, no en la Carpeta del Simulador para investigadores. Este archivo lo configura el investigador principal una sola vez por máquina. Su única función es decirle a Stata dónde está la Carpeta del Simulador para investigadores: apunta a `~/Dropbox-CIEP/SimuladorCIEP/`. Es lo que hace posible que abras Stata desde donde sea y Stata aun así encuentre el Simulador.

2. **Después `profile.do`**, que vive dentro de la Carpeta del Simulador para investigadores. Este archivo configura el entorno (estilos de gráficas, parámetros del paquete económico, lista de comandos disponibles) y, en la versión enriquecida, **te dice exactamente qué versión tienes y qué cambió desde la última vez que abriste Stata**.

Así se ve la bienvenida (mockup de cómo se verá una vez implementado el cambio):

```
═══════════════════════════════════════════════════════
   Simulador Fiscal CIEP — v7.2 (publicada 2026-05-15)
═══════════════════════════════════════════════════════

Cambios desde la última vez que abriste Stata (v7.1 → v7.2):

  • PEF.ado: incluye Cuenta Pública 2026
  • LIF.ado: actualizado con Anexo 8 RMF 2026
  • SCN.ado: ningún cambio
  • NUEVO comando: TasasEfectivas (escribe: help TasasEfectivas)

Cambios técnicos sin impacto en resultados:
  • Mejoras de velocidad en bootstrap (~30% más rápido)

Para detalles completos: type 'sim_changelog' en Stata
═══════════════════════════════════════════════════════
```

**Cómo funciona por dentro** (no necesitas hacer nada, sólo es para que sepas):

- En la carpeta del Simulador hay un archivo `CHANGELOG.md` que lista los cambios de cada versión publicada. `profile.do` lo lee al arrancar.
- En tu máquina, en tu carpeta de configuración personal, queda un archivo de estado (algo como `~/.simulador_ciep_state`) que recuerda cuál fue la última versión que viste. La próxima vez que abras Stata, `profile.do` compara: si la versión publicada actual es más nueva que la que viste, te muestra el resumen de cambios.

### 2.3 Cómo corres tus comandos (no cambia nada)

`PEF`, `LIF`, `SCN`, `Poblacion`, `FiscalGap`, `TasasEfectivas`, `GastoPC` — todos siguen funcionando como siempre. La arquitectura nueva no cambia tu interfaz de uso; sólo agrega trazabilidad alrededor.

### 2.4 Cómo saber qué versión usaste para un análisis

**Toda gráfica, tabla y reporte LaTeX que produce el Simulador lleva impresa al pie la versión, fecha y un identificador único** (un *hash*, que es como una huella digital corta del estado exacto del código, ejemplo: `a8e8be5`). Algo así:

```
Simulador Fiscal CIEP v7.2 · 2026-05-15 · a8e8be5
```

**Por qué te importa:** si seis meses después un revisor te pregunta *"¿cómo obtuviste este número?"*, esa firma al pie de tu gráfica te dice exactamente qué versión del Simulador la produjo. Con eso puedes pedir reproducción histórica (sección 5).

El mecanismo: `profile.do` define tres variables de sesión (`${sim_version}`, `${sim_published_date}`, `${sim_published_hash}`) que los módulos de output consumen al generar gráficas, tablas y reportes. No tienes que hacer nada.

### 2.5 Si necesitas una versión vieja

Si tu análisis depende de una versión específica que ya no es la actual (por ejemplo: estás revisando algo que se publicó hace dos años), no intentes reconstruirla a mano. Usa el procedimiento de la sección 5.

### 2.6 Si abres Stata y NO ves el mensaje de bienvenida del Simulador

El mecanismo que conecta a tu Stata con el Simulador es el `sysprofile.do` de tu instalación personal de Stata, que apunta a la Carpeta del Simulador para investigadores en Dropbox (§2.2). Por eso normalmente abres Stata desde donde sea y ves el banner del Simulador automáticamente.

Si NO ves el banner, lo más probable es que **tu `sysprofile.do` está apuntando al lugar equivocado** — por ejemplo, porque la Carpeta cambió de ubicación, o porque la configuración inicial nunca quedó bien hecha en tu máquina.

**Diagnóstico rápido.** En Stata escribe:

```
sysdir
```

Eso te muestra las rutas que Stata tiene configuradas. La que importa aquí es la línea que dice `SITE` (es la ruta donde Stata busca el Simulador): debería apuntar a `~/Dropbox-CIEP/SimuladorCIEP/`. Si apunta a otro lado (o no apunta a nada), el problema está en `~/StataNow/sysprofile.do`.

**Cómo se arregla.** Contacta al investigador principal (hoy: Ricardo). El fix es editar `~/StataNow/sysprofile.do` para que la línea `sysdir set SITE` apunte a `~/Dropbox-CIEP/SimuladorCIEP/`. La configuración inicial es responsabilidad tuya; pero no es algo que tengas que pelear solo: pregúntale al investigador principal o a tus compañeros.

### 2.7 Dónde vive la ayuda de los comandos

*Qué aprendes en esta sección:* dónde buscar la documentación de cada comando y por qué solo hay un lugar.

Para consultar la ayuda de cualquier comando del Simulador, escribe en Stata `help` seguido del nombre del comando:

```
help LIF
```

Qué esperas ver: la ayuda del comando en el Viewer de Stata, con descripción, sintaxis, opciones, ejemplos listos para copiar y referencias a las fuentes oficiales.

**El principio institucional:** la ayuda de comandos del Simulador vive en archivos `.sthlp` (el formato de ayuda de Stata) bajo `03_help/Stata/`. **Es fuente única de verdad.** No hay documentación paralela en `.md` para los comandos del canon.

🧠 **Concepto: fuente única de verdad.** Cuando la misma información vive en dos documentos, tarde o temprano uno se actualiza y el otro no, y nadie sabe cuál creer. Eso pasó en este repo: existían manuales `.md` por comando junto a los `.sthlp`, y con el tiempo los `.md` quedaron cinco meses desactualizados respecto al código real (documentaban opciones que ya no existían y omitían opciones nuevas). En julio de 2026 se consolidó todo en los `.sthlp` — que se auditan contra el `.ado` real — y los `.md` por comando se eliminaron. Si encuentras documentación de un comando fuera de `03_help/Stata/`, repórtala: o se integra al `.sthlp` o se elimina.

---

### 2.8 Estructura del root del repo: convención de prefijos

*Qué aprendes en esta sección:* cómo está organizada la carpeta principal del Simulador, qué directorios puedes borrar sin miedo y cuáles no debes tocar.

Si abres la carpeta del Simulador, ves dos tipos de directorios. La diferencia está en el nombre:

| Tipo | Ejemplos | ¿Se puede borrar? |
| ---- | -------- | ------------------ |
| **Con prefijo numérico** (`01_`, `02_`…) | `01_modulos/`, `02_governance/`, `03_help/`, `04_1_simuladorfiscal.ciep.mx/` (y las demás `04_*`), `05_scripts/` | **No.** Son permanentes: contienen código, documentación y configuración que no se regeneran solos. |
| **Sin prefijo** | `master/`, `raw/` (con `raw/temp/`), `users/` | **Sí.** Son restablecibles: el propio Simulador los vuelve a crear y llenar cuando corres el pipeline. |

**Qué vive en cada directorio permanente:**

- **`01_modulos/`** — los `.do` del pipeline del Simulador (módulos de análisis, visualizaciones) y `01_modulos/legacy/` con código histórico congelado que se conserva como testimonio pero no se mantiene.
- **`02_governance/`** — la documentación de cómo se administra el proyecto, incluido `CHANGELOG.md` (el registro de cambios por versión). El changelog vive aquí y no en `03_help/` porque es un registro institucional del proyecto, no ayuda de uso de comandos.
- **`03_help/`** — la ayuda: los `.sthlp` de cada comando (en `03_help/Stata/`), el manual del investigador y las imágenes de documentación.
- **`04_1_simuladorfiscal.ciep.mx/`** — los archivos del sitio web público del Simulador. Ignorado por Git salvo `health.php` (es copia operativa del servidor), pero el directorio en sí es permanente. Renombrado desde `04_simuladorfiscal.ciep.mx/` el 2026-09-08 (commit `360ebae`) al liberarse el slot `04_1`: la semilla `04_1_paqueteeconomico.ciep.mx/` se retiró del repo hacia `../CIEP_Micrositios/Paquete Económico/`. Mapa `04_*` vigente: `04_1_simuladorfiscal.ciep.mx/` (sitio del Simulador), `04_2_documentos_latex/` (archivo LaTeX 2013-2027), `04_4_libro.ciep.mx/` y `04_5_ciep.mx/` (semillas WordPress); `04_3_nodos/` cerrado el 2026-08-02. Las bitácoras anteriores a esa fecha citan la ruta vieja tal cual.
- **`05_scripts/`** — los scripts de publicación (`publicar.sh`, `publicar-endpoint.sh`), sus manifiestos (`manifest.json`, `manifest-endpoint.toml`), las credenciales (plantilla versionada + archivo real gitignored) y los `.pkg` del sub-canal Stata. El `manifest.json` vive aquí — y no en la raíz — porque se agrupa con los scripts que lo consumen y lo actualizan.

**Por qué los `.ado` siguen sueltos en la raíz.** Los comandos del canon (`SCN.ado`, `PEF.ado`, `LIF.ado`…), los esquemas de gráficas (`scheme-*.scheme`) y los archivos de arranque (`SIM.do`, `profile.do`, `sysprofile-template.do`, `set_token.template.do`, `sim_changelog.ado`, `ensure_asset.ado`) **no** se mueven a ningún subdirectorio. Stata los busca exactamente ahí: el arranque del Simulador registra la carpeta raíz en la ruta de búsqueda de comandos de Stata (técnicamente, `adopath ++SITE` — la instrucción que le dice a Stata "también busca comandos en esta carpeta"). Si mueves un `.ado` a un subdirectorio, Stata deja de encontrar ese comando.

**Qué pasa cuando borras un directorio restablecible:**

- **`raw/`** — los insumos se vuelven a descargar automáticamente: `ensure_asset` baja cada archivo desde GitHub Releases y verifica su integridad. `raw/temp/` (archivos intermedios de cada corrida) se regenera solo al correr los comandos.
- **`master/`** — las bases procesadas se reconstruyen corriendo el pipeline (tarda, pero no se pierde nada).
- **`users/<tu-usuario>/`** — es tu espacio personal de trabajo (resultados, gráficas). Puedes borrar el tuyo; **no borres el de otra persona**.
- **`graphs/`** vive únicamente en `users/<tu-usuario>/graphs/` (nunca en la raíz del repo); es espacio personal por investigador, regenerable por el pipeline — los comandos del canon crean la carpeta y escriben ahí automáticamente.

🧠 **Concepto: separar lo permanente de lo regenerable.** La convención de prefijos hace visible, desde el nombre mismo del directorio, qué es patrimonio del proyecto (código, docs, configuración — prefijado y versionado en Git) y qué es estado de trabajo (datos descargados y procesados — sin prefijo, ignorado por Git, regenerable). Un investigador nuevo no necesita preguntar qué puede borrar: el nombre lo dice.

**El proyecto de Stata (`simulador.stpr`).** En la raíz vive `simulador.stpr`, el archivo de proyecto del Project Manager de Stata. Se trackea en Git porque funciona como snapshot del árbol de organización del Simulador: agrupa los `.ado`, `.do`, esquemas y ayudas en secciones temáticas (0 INICIO, 1 Bases, 2 Simulador Fiscal, 99 Schemes), lo que le da a un investigador nuevo un mapa navegable del proyecto. Para abrirlo: en Stata, **File > Open Project** y seleccionar `simulador.stpr`. Todas sus referencias son rutas relativas al repo (el archivo marca `isRelPath`), así que funciona en cualquier clon sin ajustes. Una precaución: Stata reescribe este archivo cada vez que guardas el proyecto, aunque solo hayas movido un nodo — haz commit del `.stpr` únicamente cuando el cambio de organización sea intencional, no en cada save automático.

---

## 3. Para ti, investigador principal: cómo publicar una versión nueva

*Qué aprendes en esta sección:* el procedimiento exacto para tomar el trabajo terminado en una rama de trabajo y publicarlo como versión nueva al equipo CIEP y a la herramienta web pública.

Esta sección asume que ya conoces las convenciones de Git que usa este repositorio (`versionado-y-git.md`). Aquí sólo describimos el flujo de publicación; los detalles de cómo se hacen commits, ramas de trabajo y etiquetas de versión están allá.

### 3.1 Los pasos

1. **Termina e integra tu trabajo en `master`.** Todo lo que entra en una versión publicada tiene que estar en `master` primero. Detalle del flujo de pull request: `versionado-y-git.md` §2.

2. **Decide el número de versión.** ¿Es un cambio metodológico de fondo (mayor: `v7 → v8`)? ¿Datos anuales nuevos o módulo nuevo (menor: `v7.0 → v7.1`)? ¿Corrección urgente sobre versión publicada (parche: `v7.0 → v7.0.1`)? Detalle: `versionado-y-git.md` §3.2.

3. **Actualiza `02_governance/CHANGELOG.md` en el Código del Simulador.** Una entrada nueva con el número de versión, la fecha, y bullets agrupados por categoría:
   - **Cambios metodológicos** (afectan resultados — los lectores del Simulador tienen que verlos).
   - **Datos actualizados** (qué fuentes se subieron de versión).
   - **Funcionalidad nueva** (módulos o comandos nuevos).
   - **Correcciones de errores**.
   - **Cambios técnicos** (no afectan resultados pero importa documentar).

4. **Crea la etiqueta de versión en Git** (en inglés *tag*, un marcador permanente sobre un commit específico) sobre el commit correspondiente: `git tag -a v7.2 -m "v7.2 — descripción corta"`. Detalle: `versionado-y-git.md` §3.3.

5. **Sube la etiqueta al remoto** (en inglés *push*): `git push origin v7.2`.

6. **Crea la Publicación en GitHub** (en inglés *Release*) apuntando a la etiqueta, con el changelog y los archivos de datos pesados que correspondan a la versión. El Catálogo de datos asociados (`05_scripts/manifest.json`) se actualiza con las huellas digitales de los archivos subidos. Detalle: `versionado-y-git.md` §3.3 paso 2.

7. **Ejecuta `./05_scripts/publicar.sh v7.2`.** El script corre los gates (entrada en el CHANGELOG, tag anotado, working tree limpio, alineación con `origin`), crea el Release en GitHub con los assets del manifest y publica al endpoint Stata. Contrato en §3.2; comandos paso a paso en `runbook-deploys-ciep.md`.

8. **Actualiza la herramienta web pública** con la nueva versión. Procedimiento separado descrito en §6. Asegúrate de que el sitio en `simuladorfiscal.ciep.mx` quede sirviendo `v7.2` y no la versión previa.

9. **Verifica con un investigador de prueba.** Borra tu archivo de estado local (`~/.simulador_ciep_state`), abre Stata desde la Carpeta del Simulador para investigadores, confirma que el banner muestra `v7.2` con los cambios de la nueva versión. Adicionalmente, entra a `simuladorfiscal.ciep.mx` y verifica que el pie del sitio reporta `v7.2`.

### 3.2 El contrato funcional de `publicar.sh` 

`publicar.sh` publica una versión nueva al **endpoint público** del Simulador (`https://ciep.mx/simuladorfiscal/`). El uso es:

```bash
./05_scripts/publicar.sh v8.0
./05_scripts/publicar.sh v8.0 --tag-message="v8.0 - cambios mayores en SCN"
```

| Elemento | Especificación |
|---|---|
| **Entrada** | Número de versión (ejemplo: `v8.0`). |
| **Pre-condiciones** | Estar en `master`, working tree limpio, alineación con `origin/master`. Si la etiqueta de versión no existe localmente, el script ofrece crearla en el HEAD actual mediante invocación interactiva de `$EDITOR` para escribir el mensaje del tag anotado (o vía flag `--tag-message="..."` para uso no-interactivo). |
| **Qué hace** | (1) Verifica pre-condiciones. (2) Push del tag a `origin` si aún no está. (3) Invoca `publicar-endpoint.sh` con la versión, que lee el manifiesto `manifest-endpoint.toml`, genera el `stata.toc` actualizado, hace backup remoto del endpoint vía `tar.gz`, sincroniza al servidor Cloudways vía `rsync` sobre SSH con `--chmod` para permisos Apache correctos, verifica post-deploy. |
| **Salida exitosa** | Endpoint `https://ciep.mx/simuladorfiscal/` sirve la versión nueva. Log appendado en `02_governance/deploys/endpoint-stata.log` con timestamp, SHA del commit, versión, operador, ruta del backup remoto. Mensaje en consola con URL del endpoint y comando de verificación (`net from https://ciep.mx/simuladorfiscal/` desde Stata externo). |
| **Si falla** | Aborta antes de tocar el servidor si las pre-condiciones fallan. Si falla en medio del rsync, el backup remoto permite rollback manual. |

**Archivos de configuración asociados.** El script lee credenciales del servidor desde `endpoint-credentials.sh` (gitignored, no versionado). Una plantilla `endpoint-credentials.template.sh` versionada documenta los campos requeridos (`SSH_HOST`, `SSH_USER`, `SSH_REMOTE_PATH`).

**Qué NO hace este script.** La sincronización de la Carpeta del Simulador para investigadores (`Dropbox-CIEP/SimuladorCIEP`, ver §6.7) no es responsabilidad de `publicar.sh`. La maneja manualmente el investigador principal como owner del clon Git, mediante `git pull` en su clon local. La decisión institucional detrás de este modelo manual está articulada en §6.7.

---

## 4. Qué es "una versión publicada"

*Qué aprendes en esta sección:* qué cuenta como versión y por qué importa que no se borren ni se editen.

Una versión publicada del Simulador es **la combinación inmutable, en un punto específico del tiempo, de tres cosas**: el código (los `.ado` y `.do`), los datos de entrada (PEFs, LIFs, ENIGH y demás insumos listados en el Catálogo de datos asociados), y el changelog que describe qué la distingue de la versión previa. Una vez publicada, esa combinación queda congelada y no se modifica.

El esquema de números (`v7.0`, `v7.1`, `v8.0`...) sigue una regla simple: el primer número sube cuando hay un cambio metodológico de fondo que rompe la comparabilidad con resultados anteriores; el segundo sube cuando hay datos nuevos o funcionalidad nueva pero los resultados siguen siendo comparables; el tercero sólo aparece para corregir un error urgente sobre una versión ya publicada y citada. La regla detallada con cuándo aplica cada incremento está en `versionado-y-git.md` §3.2.

**¿Por qué las versiones publicadas no se borran ni se editan, nunca?** Por la misma razón que una publicación académica no se reescribe después de aparecer en una revista. Cuando un paper del CIEP cita *"resultados del Simulador Fiscal v7.0 (octubre 2024)"*, esa cita es una promesa al lector: cualquiera puede volver a `v7.0` y reproducir los mismos números. Si borras o editas `v7.0` retroactivamente, rompes la promesa. La práctica académica resolvió esto hace cien años con el concepto de errata: si descubres un error después de publicar, no editas el original — publicas una corrección como artefacto nuevo, complementario, citable por separado. En el Simulador es lo mismo: encuentras un error en `v7.0`, publicas `v7.0.1` con la corrección y una nota explícita en el changelog. La etiqueta de versión es un contrato social con quien cita el Simulador. Detalle del razonamiento: `versionado-y-git.md` §3.4.

---

## 5. Cómo reproducir un análisis publicado

*Qué aprendes en esta sección:* cómo volver a una versión específica del Simulador para repetir exactamente lo que produjo cuando estaba vigente.

### 5.1 Tres casos de uso típicos

**Caso A — Reproducir resultados publicados en el libro CIEP.** El libro cita números producidos con `v7.0`. Quieres correr exactamente esos números otra vez (para verificar, para extender, para responder una pregunta de un revisor).

**Caso B — Defender un número de un paper.** Un revisor te escribe seis meses después de publicar y te pide justificar la cifra X. La gráfica original lleva impreso al pie *"Simulador v7.2 · 2026-05-15 · a8e8be5"* (sección 2.4). Reproducir requiere volver exactamente a `v7.2`.

**Caso C — Comparar dos versiones lado a lado.** Quieres mostrar que el resultado de un análisis cambia entre `v7.0` y `v7.2` por un cambio metodológico específico. Necesitas correr el mismo análisis en las dos versiones y comparar.

### 5.2 El comando

Una vez implementado el script `reproducir.sh` (ver §7), el procedimiento es:

```bash
./reproducir.sh v7.0
```

El script te crea una carpeta nueva (en una ubicación que tú eliges) con el código y los datos exactos de `v7.0`. Abres Stata desde esa carpeta y corres `do SIM.do`. Los resultados son idénticos a los originales — no aproximadamente, idénticamente.

Cuando termines el ejercicio, **puedes borrar la carpeta**. No tienes obligación de conservarla; siempre puedes regenerarla más tarde con el mismo comando.

### 5.3 Por qué un script y no un selector dentro de Stata

La alternativa que se descartó era un selector dentro de `SIM.do` (algo como `set sim_version "v7.0"` y que el modelo cambie de comportamiento). Cuatro razones para preferir el script externo:

| Problema del selector interno | Por qué importa |
|---|---|
| Solo cambia datos, no código. | Mezclas "código de v7.2 con datos de v7.0" — un híbrido que nunca existió en una publicación real. Auditar eso es imposible. |
| Carpetas con todas las versiones de datos crecen sin límite. | ~7 GB acumulados en 3 años. La mayoría de las máquinas del equipo no aguanta. |
| Hace cotidiano lo que es esporádico. | Reproducir versión vieja se hace una vez al año, no todos los días. No vale la pena pagar complejidad permanente por algo puntual. |
| Toda persona que abre Stata carga el peso. | El investigador CIEP del día a día (§2) no debería pagar costo por una operación que solo hacen el investigador principal, investigadores colaboradores y auditores externos. |

### 5.4 El contrato funcional de `reproducir.sh`

Este script todavía no existe (ver §7). Cuando se construya, su contrato es:

| Elemento                      | Especificación                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| -------------------------------| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Entrada**                   | Un argumento: el número de versión (ejemplo: `v7.0`). Opcional: un segundo argumento con la carpeta destino (default: `./reproduccion-v7.0/`).                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **Qué hace**                  | (1) Descarga una copia completa del Código del Simulador desde GitHub a la carpeta destino (técnicamente, hace `git clone` — el comando que verías en Git o GitHub Desktop si lo hicieras a mano). (2) Vuelve esa copia al estado exacto que tenía en `v7.0` (técnicamente, hace `git checkout v7.0` por ti). (3) Lee el Catálogo de datos asociados (`05_scripts/manifest.json`, descrito en `versionado-y-git.md` §3.3) y descarga los archivos de datos que corresponden a `v7.0` desde la Publicación de GitHub de esa versión. (4) Verifica las huellas digitales SHA-256 (en inglés *SHA*, un identificador único derivado del contenido del archivo, equivalente a una huella digital) de los datos para confirmar que son los originales. |
| **Salida exitosa**            | Carpeta autocontenida con código + datos de `v7.0`. Mensaje: *"v7.0 reconstruida en `./reproduccion-v7.0/`. Abre Stata ahí y corre `do SIM.do`."*                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **Si falla**                  | Aborta antes de dejar carpeta a medio armar. Mensajes diferenciados: etiqueta de versión no existe, sin conexión a internet, huella digital de algún archivo no coincide (archivo corrupto o modificado en origen).                                                                                                                                                                                                                                                                                                                                                                       |
| **Pre-requisito del usuario** | Tener Git y `curl` (o `wget`) instalados en tu máquina — herramientas estándar de línea de comandos que el investigador principal configura cuando se da de alta a un investigador nuevo en el CIEP. No necesitas tener cuenta de GitHub ni saber usar Git: el script se encarga de todo eso.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

---

## 6. Las herramientas web públicas

*Qué aprendes en esta sección:* qué son los tres Simuladores CIEP como herramientas web públicas, sobre qué infraestructura corren, cómo se conectan con las otras capas, y cómo se mantiene segura la conexión con los usuarios externos.

### 6.1 Los tres Simuladores CIEP

Las tres herramientas web públicas del CIEP son los tres Simuladores CIEP. Cada uno es la cara visible y accesible — sin Stata, sin programación — hacia un público externo distinto:

| Simulador                            | URL(s)                                                                                                            | Repositorio Git                                       | Audiencia natural                                                                                                                                                            | Governance formal aplicada                                                          |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| **Simulador Fiscal CIEP**            | `simuladorfiscal.ciep.mx` (sub-canal HTML) y `ciep.mx/simuladorfiscal` (sub-canal Stata `net from`)               | `github.com/rcantuc/SimuladorCIEP`                    | Sitio HTML: ciudadanos, periodistas, académicos no afiliados al CIEP, funcionarios públicos. Canal de instalación Stata `net from`: académicos y analistas que sí usan Stata.                       | Sí — caso operativo más maduro; governance documentada en este documento (§§6.3–6.6). |
| **Simulador IEPS al tabaco**         | `iepsaltabaco.ciep.mx`                                                                                            | Repositorio propio (no listado públicamente aún).     | Ciudadanos, periodistas, comunidad de salud pública, fumadores informados.                                                                                                   | Pendiente (ver §7).                                                                  |
| **Simulador de tenencia vehicular**  | `tenencia.ciep.mx`                                                                                                | Repositorio propio (no listado públicamente aún).     | Ciudadanos, propietarios de vehículos, periodistas del ramo automotriz, autoridades estatales y municipales.                                                                 | Pendiente (ver §7).                                                                  |

Las tres herramientas permiten a **usuarios externos** simular el impacto de políticas fiscales (en sus respectivos ámbitos) **sin necesidad de instalar Stata** ni saber programación. La audiencia es deliberadamente distinta a las otras tres capas del Simulador Fiscal CIEP: investigadores CIEP no son los usuarios típicos de los sitios web (ellos usan Stata directamente, que es más expresivo); los sitios web son para quien necesita explorar resultados sin entrar al modelo en profundidad.

**El Simulador Fiscal CIEP es el caso especial.** Es el único de los tres con dos sub-canales: el sitio HTML interactivo en `simuladorfiscal.ciep.mx` (mismo modelo que los otros dos sitios) **y** un canal de instalación Stata `net from` en `ciep.mx/simuladorfiscal` que sirve los `.ado`, `stata.toc` y archivos asociados, para que un usuario externo se instale el Simulador Fiscal en su propia copia de Stata. Los simuladores de IEPS al tabaco y tenencia vehicular tienen únicamente sub-canal HTML; no exponen un canal de instalación Stata.

**Por qué la asimetría.** El Simulador Fiscal CIEP es el más maduro y el más usado por academia técnica externa, donde Stata es lengua franca; tener el canal de instalación Stata permite reproducibilidad fina por parte de otros economistas. Los simuladores de IEPS al tabaco y tenencia vehicular son más acotados en alcance (un impuesto, un derecho), su público es predominantemente no técnico, y exponer un canal de instalación Stata para ellos no se justifica hoy.

**Versionado.** Los tres simuladores se versionan en sincronía con el código del cálculo subyacente que cada uno usa. Para el Simulador Fiscal CIEP, ese código es el Código del Simulador documentado en el resto de este documento; para los otros dos simuladores, el código vive en repositorios propios cuya governance formal está pendiente.

### 6.2 La infraestructura dual: Cloudways e IONOS

Los Simuladores CIEP corren sobre **dos proveedores de infraestructura distintos**. Esta dualidad no es de diseño — es histórica — pero tiene consecuencias operativas importantes que requieren documentarse.

**Qué es cada proveedor.**

- **Cloudways** es un servicio de **hosting administrado**: el CIEP no opera el servidor directamente, sino que Cloudways provee un panel donde se configuran sitios, certificados, copias de seguridad y recursos. Es el equivalente, para un sitio web, a tener un coche con servicio de mantenimiento incluido — tú lo usas, ellos se encargan del taller.
- **IONOS** ofrece, para el CIEP, un **VPS** (*Virtual Private Server* — servidor virtual privado): un servidor remoto al que se accede directamente vía SSH y se administra a fondo. Es el equivalente a tener tu propio coche y mantenerlo tú mismo — más control, pero también más responsabilidad.

**Qué activos del CIEP viven en cada proveedor.**

| Proveedor       | Activos del CIEP que aloja                                                                                                                                                                                                                                                                                       |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Cloudways**   | El sitio principal `ciep.mx` y todos sus micrositios (los blogs y secciones del sitio principal). De los Simuladores CIEP: **únicamente el sub-canal Stata `net from`** del Simulador Fiscal CIEP, que vive en la ruta `ciep.mx/simuladorfiscal/` y sirve los archivos `stata.toc`, `.ado`, `.sthlp`, `.pkg`. |
| **IONOS (VPS)** | Los **tres sitios HTML interactivos** de los Simuladores CIEP: `simuladorfiscal.ciep.mx`, `iepsaltabaco.ciep.mx`, `tenencia.ciep.mx`.                                                                                                                                                                            |

**Quién tiene acceso administrativo.** El acceso a estos dos proveedores no es simétrico, y aquí se introduce un nuevo actor en la governance: **Daniel Orduña**, primer colaborador externo formal del CIEP en infraestructura web, con acceso administrativo a Cloudways (pero no a IONOS). El acceso a IONOS sigue siendo exclusivo del investigador principal.

| Proveedor       | Investigador principal (Ricardo Cantú)               | Daniel Orduña (colaborador externo de infraestructura) | Otros        |
| ---------------- | ---------------------------------------------------- | ------------------------------------------------------ | ------------ |
| Cloudways       | Acceso administrativo permanente.                    | Acceso administrativo permanente.                      | Sin acceso. |
| IONOS (VPS)     | Acceso administrativo permanente (root + SSH).       | Sin acceso.                                            | Sin acceso. |

Daniel Orduña no es investigador del CIEP — es un colaborador externo cuyo rol formal es de mantenimiento de infraestructura. Acceso a Cloudways, no a IONOS, no al Código del Simulador, no a credenciales del gestor de secretos del investigador principal. Esta es la primera vez que el ecosistema CIEP tiene un colaborador externo con privilegios administrativos formales sobre alguna pieza de infraestructura, y la política completa de gestión de credenciales vive en `02_governance/politicas-institucionales.md`. La adopción formal del gestor de secretos institucional sigue pendiente — ver §7.

**Decisión pendiente: consolidación de la infraestructura.** Hoy la dualidad existe por razones históricas — cada proveedor se contrató en un momento distinto, para un propósito distinto. Hay una **decisión abierta** sobre migrar el sub-canal Stata `net from` del Simulador Fiscal CIEP de Cloudways a IONOS, dejando todos los activos web de los Simuladores CIEP bajo un solo proveedor.

A favor de migrar:

- **Simplifica.** Un solo proveedor para todos los activos web de los Simuladores CIEP — un solo panel, una sola política de respaldos, un solo perímetro de seguridad.
- **Reduce dependencias cruzadas.** Hoy el sub-canal Stata depende del hosting del sitio principal `ciep.mx` en Cloudways; cualquier cambio en la configuración del sitio principal puede afectarlo.
- **Concentra el conocimiento operativo del investigador principal.** El VPS de IONOS ya se opera para los tres sitios HTML; añadir el sub-canal Stata es marginal en complejidad.

En contra de migrar:

- **Trabajo de migración no trivial.** Reconfigurar URLs, redirecciones, pruebas para asegurar que `net from https://ciep.mx/simuladorfiscal/` siga funcionando para usuarios externos que ya tienen scripts apuntando ahí.
- **Pérdida de redundancia.** Hoy el sub-canal Stata vive en infraestructura distinta a los sitios HTML; si IONOS falla, el canal de instalación Stata sigue accesible (y viceversa). Migrar todo a IONOS elimina esa redundancia.
- **Daniel Orduña pierde campo de operación.** Su acceso administrativo es a Cloudways; migrar el canal de instalación Stata fuera de Cloudways reduce el alcance de su rol salvo que se le otorgue también acceso a IONOS, lo que requiere decidir qué tan amplio es ese rol en governance.

Decisión pendiente; ver §7 para el componente que la registra.

### 6.3 Mismo motor, distintas interfaces

Lo crítico de entender es que **el motor de cálculo del Simulador es uno solo y corre, sin reimplementaciones paralelas, en tres lugares distintos**:

1. **En la instalación local de Stata del investigador CIEP** (Capa 2): los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `FiscalGap`, etc. corriendo desde la Carpeta del Simulador para investigadores.
2. **En la copia remota de Stata del usuario externo que se instaló el Simulador con `net from`** (Capa 4, sub-canal Stata — ver §6.6): los mismos comandos, descargados desde el canal de instalación Stata al Stata personal del usuario.
3. **Detrás del sitio HTML interactivo** (Capa 4, sub-canal web — ver §6.5): los mismos comandos invocados por la capa web cuando un usuario externo mueve un control deslizable o llena un formulario.

Cuando un periodista mueve un control en la web para ver el impacto de cambiar la tasa del IVA, el cálculo que se ejecuta es el mismo comando `LIF` que un investigador CIEP corre en Stata o que un académico externo invoca después de hacer `net install LIF` desde el endpoint público. Lo que cambia es la interfaz (formularios y gráficas en la web; consola de comandos en las otras dos); el motor es uno.

Esto importa por una razón: garantiza que los números que ve un usuario externo en el sitio HTML son los **mismos** que los que un investigador CIEP obtiene en Stata, y los **mismos** que los que un académico externo obtiene en su Stata local instalada vía `net from`, para la misma versión publicada. No hay implementaciones paralelas que puedan divergir.

### 6.4 Versionado alineado

El sitio web se versiona en sincronía con el Código del Simulador. Cuando se publica `v7.2` (paso 8 del procedimiento de §3), el sitio web se actualiza a `v7.2`. El pie del sitio muestra explícitamente qué versión está sirviendo, igual que la firma en los outputs de Stata (§2.4). De este modo, si alguien hace una captura de pantalla de un cálculo web y la pone en un artículo periodístico, queda registro de qué versión la produjo.

El procedimiento detallado de actualización del sitio (cómo se hace el despliegue al servidor, cuánto downtime hay, cómo se prueba antes de publicar) está pendiente de documentar (§7).

### 6.5 Sub-canal web HTML

El sub-canal web HTML es el sitio interactivo al que llega un usuario externo cuando teclea `simuladorfiscal.ciep.mx` en su navegador. La audiencia natural son personas que **no usan Stata** (ciudadanos, periodistas, académicos no afiliados al CIEP, funcionarios). La interfaz son formularios, controles deslizables y gráficas; los resultados salen del motor de cálculo del Simulador (§6.3) corriendo detrás del servidor.

**Estado del sub-canal:** existe y funciona hoy. Lo que falta no es construirlo — es documentar formalmente cómo se actualiza con cada publicación y qué hacer si algo falla; esos pendientes viven en §7.

**Componente SSL: por qué importa el candadito del navegador.**

El sitio sirve sobre HTTPS, que es el protocolo seguro que ves en cualquier banco o servicio en línea (el candado a la izquierda de la URL en el navegador). HTTPS se construye sobre **SSL** (un sistema de certificados digitales), que garantiza dos cosas:

- **Privacidad**: la conexión entre el usuario externo y el servidor está cifrada; nadie en la red intermedia puede leer qué consultas hace el usuario ni qué resultados recibe.
- **Autenticidad**: el navegador del usuario verifica, contra una autoridad de certificación externa, que el servidor en `simuladorfiscal.ciep.mx` efectivamente pertenece al CIEP y no es una imitación.

Para que esto funcione, el servidor necesita un **certificado SSL** (archivos digitales que prueban la identidad del sitio) y una **llave privada** (la contraparte secreta que solo el servidor real conoce).

**Política sobre las llaves privadas SSL:**

- **Nunca viven dentro del Código del Simulador.** Esto ya está protegido por el `.gitignore` (`*.key`, `*.pem`, `*.crt` y similares ignorados), pero la política se documenta aquí explícitamente: aunque alguien las copie por error a la carpeta de desarrollo, Git las ignora.
- **Viven solo en el servidor de producción** donde el sitio web corre, con permisos de lectura restringidos al usuario que ejecuta el servidor web.
- **El respaldo de las llaves** se guarda en el gestor de contraseñas/secretos institucional del CIEP, no en repositorios compartidos. Si el servidor se pierde, la llave se recupera de ahí.

**Renovación del certificado.** ⚠️ Los certificados SSL del sitio **expiran cada 180 días** (dos días menos que seis meses) — si no se renuevan a tiempo, el sitio deja de ser accesible y el navegador muestra una advertencia de seguridad. No es automático: hay que hacerlo activamente.

La renovación se hace a través del **VPS** (*Virtual Private Server* — un servidor remoto contratado en IONOS que es donde físicamente corre el sitio web). Para realizarla necesitas dos credenciales:

1. **Acceso al correo `hostmaster.ciep.mx`** — la autoridad de certificación verifica el dominio enviando un desafío a esta dirección. La credencial vive en el **gestor de secretos institucional del CIEP**, carpeta "Infraestructura web".

2. **Acceso root al VPS de IONOS** — para instalar el certificado renovado en el servidor. La credencial (usuario root + llave SSH) vive en el gestor de secretos institucional, carpeta "Infraestructura web".

**Protocolo de acceso a estas credenciales:**

| Rol | Acceso a credenciales SSL |
|---|---|
| Investigador principal | Permanente |
| Investigador colaborador con rol de mantenimiento de infraestructura | Permanente |
| Investigador colaborador sin ese rol | Acceso temporal con caducidad de 7 días, otorgado por el investigador principal en el gestor de secretos. Suficiente para una sesión de renovación. |
| Cualquier otra persona | Sin acceso |

**Lo que no se hace, nunca:** compartir estas credenciales por correo, Slack, mensaje, captura de pantalla, ni dictado verbal. El gestor de secretos institucional es el único canal autorizado.

Si la fecha de expiración del certificado se acerca y nadie con acceso está disponible (vacaciones, enfermedad), el investigador principal define un suplente formal en el gestor de secretos con anticipación. **El plan de contingencia no es "alguien le pide la contraseña a Ricardo": es "alguien tiene acceso preconfigurado al gestor de secretos".**

La documentación detallada del procedimiento de renovación (comandos exactos, dónde se guarda el certificado en el servidor) es trabajo pendiente (§7). La política completa de gestión de secretos vive en `02_governance/politicas-institucionales.md`.

### 6.6 Sub-canal Stata `net from`

Hay una segunda forma de llegar al Simulador desde fuera del CIEP que no usa el navegador: un usuario externo **que sí sabe Stata** puede instalárselo en su propia copia de Stata con el comando:

```stata
net from https://ciep.mx/simuladorfiscal/
```

Nótese que esta URL es **distinta** a la del sub-canal HTML (`simuladorfiscal.ciep.mx`): el sub-canal Stata vive en la ruta `/simuladorfiscal` del dominio principal del CIEP (`ciep.mx`), no en el subdominio. Similar, pero no igual.

Cuando ese comando se ejecuta, Stata busca el archivo `stata.toc` (tabla de contenidos) en `https://ciep.mx/simuladorfiscal/stata.toc`. El `stata.toc` declara qué paquetes están disponibles (`PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos`); con `net install <paquete>` Stata descarga los `.ado` y archivos de ayuda correspondientes desde el servidor a la máquina del usuario. A partir de ahí los comandos del Simulador funcionan en esa instalación remota igual que funcionan en la Capa 2.

**Endpoint.** El `stata.toc` y los archivos asociados (`.ado`, `.sthlp`, `.pkg`) se sirven desde `https://ciep.mx/simuladorfiscal/` — una ruta del dominio principal del CIEP. Es una URL **distinta** a la del sub-canal HTML, que vive en el subdominio aparte `simuladorfiscal.ciep.mx`. Las infraestructuras también son distintas: este sub-canal Stata corre en Cloudways (mismo hosting que el sitio principal `ciep.mx` y sus micrositios), mientras que el sub-canal HTML corre en IONOS (VPS dedicado).

**Estado actual del mecanismo de despliegue al endpoint.** Hasta el commit `2daadf8` (mayo 2026), el directorio `Stata net/` en el Código del Simulador funcionaba como área de staging del sub-canal Stata: el investigador principal copiaba `.ado` y `.pkg` desde la raíz del repo a `Stata net/`, editaba el `stata.toc` para reflejar la versión nueva, y subía el contenido al servidor por SSH/SCP.

Ese flujo tenía limitaciones reconocidas (ver lista abajo) y, en la práctica, los `.ado` en `Stata net/` se desincronizaban silenciosamente respecto a los del root. La sesión de mayo 2026 que cerró la migración Dropbox → GitHub Releases destapó un caso concreto: una migración había sido aplicada solo a las copias de `Stata net/`, dejando el código del root intacto, con la consecuencia de que `SIM.do` (que carga desde el root) seguía roto mientras el endpoint público recibía una versión nueva no integrada.

Esa fricción motivó eliminar los `.ado` de `Stata net/` (commit `2daadf8`) y construir el reemplazo automatizado. La versión `v8.0` (mayo 2026) materializa ese reemplazo: el deploy al endpoint público está automatizado por dos artefactos del repo, descritos en §3.2 y §7:

- **`publicar-endpoint.sh`** — script de publicación que lee el manifiesto, genera dinámicamente el `stata.toc` con la versión y fecha, hace backup remoto pre-publicación, sincroniza al servidor Cloudways vía `rsync` sobre SSH (con flag `--chmod` que produce permisos Apache compatibles — sin él los archivos sincronizados generan HTTP 403), verifica que el endpoint responde la versión correcta post-publicación, y registra la publicación en `02_governance/deploys/endpoint-stata.log`.

- **`manifest-endpoint.toml`** — manifiesto versionado en Git que declara qué archivos `.ado`, `.sthlp`, `.pkg`, `stata.toc` forman parte del Simulador "público vía `net from`". Es subconjunto curado del repo: los módulos work-in-progress (`GastoPC.ado`, `TasasEfectivas.ado`) se excluyen explícitamente; los `.sthlp` viven en `03_help/Stata/` (no en root); los `.pkg` se generan al deploy desde la raíz, no desde `Stata net/`.

El primer deploy genuinamente reproducible — v8.0 — fue validado end-to-end mediante `net from https://ciep.mx/simuladorfiscal/` desde una instalación Stata externa al CIEP, que confirmó la disponibilidad de los 8 paquetes declarados en el manifiesto.

**Limitaciones del flujo manual anterior** (registradas para futura referencia y evitar replicarlas):

- **Sin trazabilidad de qué versión está sirviendo el endpoint.** No había registro automático de qué se subió ni cuándo; ese dato vivía en la memoria del investigador principal.
- **Sin automatización.** El copy-paste manual desde la raíz a `Stata net/` y luego al servidor dependía de hacerlo bien a mano cada vez. Olvidar un archivo o subir uno desactualizado no se detectaba hasta que un usuario externo reportara que algo no instalaba.
- **Divergencia silenciosa.** Era exactamente lo que pasó durante el cierre de la migración Dropbox → GitHub Releases.

Estas tres limitaciones quedan resueltas en el nuevo flujo: el log de deploys da trazabilidad, el script da automatización, y el manifiesto evita la divergencia silenciosa porque declara explícitamente qué archivos del repo se publican (no hay copias paralelas que sincronizar).

### 6.7 Modelo de la Carpeta del Simulador para investigadores

Los investigadores CIEP acceden al Simulador desde su disco local en `Dropbox-CIEP/SimuladorCIEP/`. Esa carpeta no es una copia parcial del repo curada para distribución: **es un clon Git del repo de producción** (`github.com/rcantuc/SimuladorCIEP`) sincronizado al disco de cada investigador a través de Dropbox.

Las dos consecuencias importantes de este modelo:

**Primera consecuencia: la sincronización correcta es `git pull`, no `rsync`.** Como cada investigador tiene un clon Git completo (incluyendo `.git/` versionado), la forma institucional correcta de actualizar la Carpeta a una versión nueva es entrar al clon y ejecutar `git pull` desde dentro. No copiar archivos selectivamente desde el repo de desarrollo. Eso preserva integridad Git, mantiene historia accesible localmente (`git log`, `git show`, `git diff`), y respeta los archivos locales del investigador que viven gitignored dentro del clon (ver siguiente punto).

**Segunda consecuencia: cada investigador tiene espacio personal dentro del clon.** El directorio `users/` del repo está gitignored — cada investigador tiene una sub-carpeta personal (`users/ricardo/`, `users/judysenya/`, etc.) donde guarda outputs intermedios, datos derivados de sus análisis, configuraciones experimentales. Eso vive solo en disco local del investigador, no se versiona, no se sincroniza entre investigadores. Esta convención es lo que hace que el clon Git sea **simultáneamente** distribución institucional (lo versionado en Git) y espacio de trabajo personal (lo gitignored en `users/<usuario>/`).

**Estado del código y procedimiento operativo.** El sub-comando `publicar.sh internos`, que en versiones anteriores sincronizaba el repo a la Carpeta usando `rsync`, fue eliminado en favor de un modelo más simple y arquitectónicamente coherente. La sincronización de la Carpeta del Simulador para investigadores **es responsabilidad operativa del investigador principal como owner del clon de Dropbox**, y se ejecuta manualmente:

```bash
cd "$HOME/Library/CloudStorage/Dropbox-CIEP/SimuladorCIEP"
git fetch origin
git checkout master
git pull origin master
```

Esta operación es trivial (3 comandos), de baja frecuencia (por publicación o por necesidad), y se hace desde la Mac del investigador principal sin requerir herramientas adicionales. Dropbox propaga el resultado al disco de cada investigador automáticamente. Esta decisión es deliberada, no provisional: la complejidad de un script automatizado no se justifica para una operación unipersonal de baja frecuencia, y el modelo manual respeta naturalmente la integridad Git del clon (ver primera consecuencia arriba) y los archivos locales del investigador en `users/<usuario>/` (segunda consecuencia).

**Operación cotidiana del investigador.** En la práctica diaria, el investigador CIEP que usa el Simulador no ejecuta nada para mantener la Carpeta sincronizada con el repo de producción. La sincronización es responsabilidad del investigador principal, y Dropbox propaga el resultado al disco de cada investigador. El investigador puede ejecutar `cd <carpeta>; git log --oneline -1` en cualquier momento para verificar qué versión tiene localmente.

---

## 7. Lo que NO está implementado todavía

*Qué aprendes en esta sección:* qué partes de la arquitectura siguen pendientes, en qué estado están y de qué depende cada una. Lo ya construido no se lista aquí: vive en las secciones anteriores y, con fecha y commit, en `CHANGELOG.md`.

**Alcance de esta sección:** los pendientes listados abajo corresponden específicamente al Simulador Fiscal CIEP. Algunos componentes mantienen dependencias con decisiones institucionales del Ecosistema CIEP completo (gestor de secretos del CIEP, documentación SSL del sitio web): estas dependencias se reconocen aquí, pero la construcción institucional correspondiente se trabaja en proyecto separado dedicado al Ecosistema CIEP. Pendientes que corresponden exclusivamente a otros productos del Ecosistema (governance formal de los otros Simuladores CIEP, decisiones de infraestructura del CIEP completo, política del rol "colaborador externo de infraestructura") no se documentan en esta sección.

| Componente | Estado (2026-10-03) | De qué depende |
|---|---|---|
| `reproducir.sh` | No implementado. Contrato funcional en §5.4. Hoy la reproducción se hace a mano: `git clone` + `git checkout vX.Y` + `ensure_asset` descarga los datos del Release de esa versión (el candado garantiza que son los originales). | Demanda real de reproducción por terceros; hasta entonces la receta manual de §5 basta. |
| Firma de versión en gráficas y outputs | Parcial. `profile.do` publica las globales `sim_version` / `sim_previous_version` y el state file por usuario (`users/<id>/.simulador_state`); el pie *"Simulador vX.Y · fecha · SHA"* en gráficas y archivos de salida no está generalizado. | Decidir el formato del pie y tocar los módulos que exportan gráficas. |
| Alta de un investigador CIEP nuevo | Manual uno-a-uno: el investigador principal instala `sysprofile.do` (plantilla `sysprofile-template.do`) y configura Python en cada máquina. El procedimiento está descrito para el investigador en `03_help/manual-investigador-ciep.md` §2, no automatizado. | Un `setup_user.sh` o equivalente; sin calendario mientras el equipo sea pequeño. |
| Clon de desarrollo fuera de Dropbox | Sigue dentro de Dropbox (`~/Library/CloudStorage/Dropbox-CIEP/.../SimuladorCIEP/`). Riesgo de corrupción de `.git/` documentado en `historico/fase-0-5-git-hygiene-audit.md`; mitigado por `publicar.sh` (guard de identidad de clon) y por la regla de no hacer `git add .`. | Operación manual cuando se justifique. |
| Estrategia de versionado de `simulador.stpr` | El proyecto de Stata Project Manager está gitignored porque guarda rutas absolutas. Alternativas: rutas relativas si Stata lo permite, o `simulador-template.stpr` versionado + `.stpr` personal ignorado. | Demanda de investigadores por navegación estructurada del repo. |
| Gestor de secretos institucional | La política existe (`politicas-institucionales.md` Parte I); las credenciales del investigador principal siguen en su gestor personal. | Decisión administrativa/presupuestal (1Password Business, Bitwarden, etc.). Requisito antes de incorporar al primer investigador colaborador con acceso a infraestructura. |
| Documentación operativa del certificado SSL | Emisor, procedimiento de renovación y calendario no están escritos como runbook; las llaves se respaldan con `backup-vps.sh --llaves` (§7.2) y el incidente de 2026 está en `politicas-institucionales.md`. | Redactar el runbook en la próxima renovación. |
| Convención `legacy/<categoría>/` | Aplicada de facto (`01_modulos/legacy/`); falta escribir qué califica como legacy, cómo se nombran las subcarpetas y quién decide el movimiento. | Trabajo de governance en `versionado-y-git.md`; sin calendario. |
| Consolidación de infraestructura Cloudways / IONOS | Dualidad histórica descrita en §6.2 (endpoint Stata en Cloudways; sitios HTML en IONOS). | Decisión institucional del Ecosistema CIEP. |

### 7.1 Deployment automatizado al VPS de simuladorfiscal.ciep.mx

*Qué aprendes en esta sub-sección:* que el pipeline al VPS ya opera y dónde está cada pieza.

El roadmap de seis fases (credenciales → reconocimiento del VPS → `publicar-vps.sh` → backup integrado → cutover a symlink `current` → primer deploy) arrancó y cerró en julio de 2026; v8.0 entró a producción el 2026-07-09 con backup pre-deploy, verificación post-deploy y rollback automático. La tabla de fases con commits y la narrativa de cada deploy están en `historico/bitacora-arquitectura.md` (§7.1 y §7.3 originales). Lo vigente:

- **Scripts:** `05_scripts/publicar-vps.sh` (gates → backup → rsync → cutover → verificación → rollback si falla) y `05_scripts/backup-vps.sh` (§7.2). Fuente de los auxiliares del servidor en `05_scripts/vps/`.
- **Comandos y decisiones por tipo de release:** `runbook-deploys-ciep.md`.
- **Gate final humano:** después de cada deploy, una simulación real en el navegador; el health check HTTP no cubre el motor (lección del 2026-07-09).

### 7.2 Diseño del componente de backup del VPS (operando)

*Qué aprendes en esta sub-sección:* las decisiones de diseño del backup del VPS (D.1–D.8) y de implementación (I.1–I.4) que hoy operan.

Estas decisiones fueron tomadas por el investigador principal el 2026-07-10 durante sesión de diseño arquitectónico. **El diseño ya está implementado y operando** (2026-07-09: `05_scripts/backup-vps.sh` + Fase 0 de `publicar-vps.sh`; decisiones de implementación I.1–I.3 al final de esta sub-sección; primera ejecución real registrada en la bitácora v1.24).

**D.1 — Alcance del backup.** Solo configuración de Apache + llaves SSL cifradas. El código de los sitios ya vive en Git y en el clon local del investigador principal (`04_1_simuladorfiscal.ciep.mx/`), por lo que no requiere respaldo adicional. Los `.dta` procesados de `master/` también viven en la Mac del investigador principal como fuente de verdad.

> **Ajuste a D.1 (I.1, aprobado 2026-07-09):** las llaves SSL salen del ciclo automático. El backup de cada deploy respalda SOLO la config Apache (legible sin sudo); las llaves se respaldan manualmente con `backup-vps.sh --llaves` cuando rotan (~2 veces/año), con sudo interactivo + cifrado gpg simétrico (passphrase de D.6, tecleada por Ricardo). Razón: las llaves en `/etc/ssl/private/` requieren sudo (710 `root:ssl-cert`) y no cambian entre deploys — respaldarlas en cada deploy era redundancia sin valor y forzaba automatizar sudo (superficie de riesgo innecesaria).

**D.2 — Destino del backup.** Dropbox institucional del CIEP. Cuenta con 2FA en la cuenta Dropbox del investigador principal. Las llaves SSL van cifradas con `gpg` antes de ir a Dropbox (Alternativa A de las opciones discutidas).

**D.3 — Frecuencia del backup.** Cada deploy. Es la garantía institucional de que existe backup consistente con el estado que quisiste preservar en ese momento.

**D.4 — Retención.** Últimos 90 backups. Cubre ~90 deploys, con margen para detectar problemas institucionales que aparecen semanas después del deploy que los causó (referencia: el incidente SSL de 2026-01-28 llevaba 5 meses silencioso — ver `politicas-institucionales.md` §6).

**D.5 — Prueba de restauración.** Trimestral. Restauración a directorio temporal en la Mac del investigador principal con verificación manual. Pragmático para el primer año; la migración a Docker o VPS de pruebas queda como decisión futura si aumenta la criticidad institucional.

**D.6 — Passphrase de gpg.** Passphrase aleatoria (generada por Firefox Password Manager), distinta a la password del VPS y a cualquier otra credencial CIEP. Guardada en Firefox como entrada "GPG - Backup llaves SSL VPS CIEP".

**D.7 — Estructura del backup en Dropbox.** Unificada por timestamp:

```
Dropbox-CIEP/Backups/VPS-simuladorfiscal/YYYY-MM-DD-HHMMSS/
  apache-config/*.conf
  llaves-cifradas/ssl-2026a.tar.gz.gpg
```

**D.8 — Ubicación de ejecución del script.** ✅ **Cerrada 2026-07-09:** el backup corre en la Mac de Ricardo (pull desde el VPS), como componente del pipeline maestro. El destino es la variable `BACKUP_ROOT` del archivo de credenciales (gitignored) — apunta al Dropbox institucional del CIEP; el path personal NO va hardcodeado en scripts versionados.

**Decisiones de implementación I.1–I.3 (aprobadas por el investigador principal, 2026-07-09):**

- **I.1 — Resolución del sudo para llaves SSL** (modifica D.1; ver el recuadro de ajuste bajo D.1): backup automático = solo config Apache; llaves = modo manual `--llaves`.
- **I.2 — Arquitectura:** script separado `05_scripts/backup-vps.sh`, invocado por `publicar-vps.sh` como **Fase 0** (pre-deploy, después de los gates): si el backup falla, el deploy aborta — sin backup exitoso no hay deploy. También ejecutable standalone: prueba de restauración trimestral (D.5), respaldo manual de llaves (`--llaves`) y mantenimiento de retención (`--solo-poda`).
- **I.3 — Destino:** variable `BACKUP_ROOT` en el credentials. El path contiene espacios y el carácter `+`: toda expansión en los scripts va citada (`"${BACKUP_ROOT}"`).
- **I.4 — Creación del deployment con privilegio mínimo (2026-10-01; complementa I.1, no la revierte):** la contraseña de `sudo` del VPS sigue siendo exclusiva del investigador principal y nunca se comparte con el agente ni se guarda en credentials. Lo único que el pipeline necesitaba de root eran dos `mkdir` + `chown` por release *minor* (Gate 4 de `publicar-vps.sh`), que hasta hoy exigían al operador en la terminal. Solución: un comando de propósito único en el VPS, `/usr/local/sbin/crear-deployment vN.M` (root:root 0755, fuente en `05_scripts/vps/crear-deployment`), que valida su argumento con expresión regular estricta, crea `/var/www/html/vN.M` y `/SIM/OUT/N.M` y los asigna a `ciepmx`; y una regla `NOPASSWD` en `/etc/sudoers.d/ciepmx-deploy` (fuente en `05_scripts/vps/ciepmx-deploy.sudoers`) **restringida a ese comando**. `publicar-vps.sh` lo invoca con `sudo -n` solo si el deployment no existe y el comando está instalado; si no, cae a la receta manual. Cualquier otro `sudo` sigue pidiendo contraseña. La instalación en el VPS (copiar el script, `visudo -f`) la hace el operador una sola vez (runbook §4b).

**Estado:** operando en producción desde el 2026-07-09 (bitácoras v1.23-v1.24): primera ejecución real completada (config Apache + línea base de llaves cifradas con `--llaves`), `BACKUP_ROOT` en el credentials real, y primera prueba de restauración D.5 ejecutada de facto (descifrado + listado verificado). Pendiente: prueba de restauración trimestral de octubre 2026, que además confirmará al 100% la passphrase guardada en Firefox (en la primera prueba gpg pudo tomarla del agent).

### 7.3 Historia de los deploys al VPS

La narrativa fechada de cada deploy (primer deploy automatizado de v8.0 el 2026-07-09, cutovers posteriores, incidentes y lo que se corrigió en cada uno) vive congelada en `historico/bitacora-arquitectura.md` §7.3. Lo que de ahí se volvió regla está incorporado en las secciones vigentes de este documento y en `runbook-deploys-ciep.md`.

---

## 🧠 Concepto: un motor de cálculo, varias interfaces hacia audiencias distintas

El patrón detrás de las cuatro capas es viejo en la práctica científica: **un modelo único cuyos resultados se comunican mediante distintos canales adaptados a su audiencia**. Un grupo de investigación con un modelo macroeconómico no lo publica una sola vez en un solo formato. Lo publica como paper técnico para revisores especializados, como working paper accesible para colegas, como nota de divulgación para periodistas, como presentación en conferencia para tomadores de decisión, y a veces como herramienta interactiva para el público general. Las audiencias son distintas; el modelo subyacente es el mismo.

El Simulador funciona igual. La Capa 1 es el modelo en su forma técnica completa (código auditable, decisiones metodológicas documentadas). La Capa 2 lo hace usable como herramienta de análisis para investigadores CIEP. La Capa 3 lo congela en instantáneas reproducibles que cualquiera puede recuperar para defender un resultado citado. La Capa 4 lo expone como herramienta pública para audiencias externas que no usan Stata. Las cuatro interfaces hablan distinto, pero los números salen del mismo cálculo. Es lo que mantiene al Simulador coherente como fuente única — y lo que permite que un periodista, un investigador y un revisor académico, cada uno usando su interfaz preferida, vean el mismo modelo.

---

## Comportamientos no obvios y troubleshooting

Esta sección documenta peculiaridades del entorno técnico que pueden confundir a quien mantenga el Simulador. Cada entrada captura un comportamiento real, verificado empíricamente, que no es bug del sistema sino propiedad del entorno que no es obvia a primera vista. Documentarlos aquí ahorra horas de debugging a futuros mantenedores.

La sección está abierta a expansión: cuando se identifique un nuevo comportamiento no obvio, se agrega como sub-sección nueva siguiendo el patrón Síntoma / Causa / Solución / Cómo evitar.

### Logs de sesión del VPS son efímeros: un cron nocturno los borra

**Síntoma:** al diagnosticar un incidente en producción, los logs de las sesiones de simulación de días anteriores ya no existen — no hay contra qué comparar el comportamiento actual.

**Causa:** un cron nocturno del VPS borra los logs de sesión (higiene de disco). No es bug: es política del servidor.

**Solución:** el diagnóstico comparativo debe hacerse EL MISMO DÍA del incidente, o reconstruirse desde git (el código) — los logs de ayer no van a estar mañana.

**Cómo evitar:** ante cualquier anomalía post-deploy, capturar de inmediato los logs relevantes a un archivo fuera del VPS antes de seguir diagnosticando. Registrado en el incidente de v8.0.12 (bitácora v1.39), donde la ausencia de baseline hizo indemostrable qué cruzó el umbral del idle-timeout.

### Caché de Python en Stata: `clear all` no recarga funciones top-level

**Síntoma.** Después de modificar un archivo `.ado` que contiene un bloque `python: ... end` con funciones top-level (definiciones de `def`, imports, etc.), correr `clear all` en Stata y volver a ejecutar el `.ado` modificado parece no aplicar los cambios. El programa Stata se recompila correctamente pero el código Python sigue usando la versión vieja de las funciones.

**Causa.** `clear all` invoca internamente `python clear` y `discard`, pero esto no fuerza la re-importación de funciones que Python ya cargó al namespace top-level durante una invocación previa del `.ado`. El intérprete Python embebido en Stata mantiene esos símbolos en memoria entre invocaciones del programa, y solo recarga cuando explícitamente se reinicia el intérprete.

**Solución.** Reiniciar Stata completamente (cerrar y volver a abrir). No hay forma confiable de forzar el reload sin reinicio, al menos no desde Stata 16/17 con el patrón actual de `python:` block embebido en `.ado`.

**Cómo evitar.** Durante desarrollo iterativo de un `.ado` con Python integration, mantener una sesión de Stata dedicada al testing que se reinicia tras cada cambio relevante al código Python, en lugar de intentar reusar la sesión activa. Para corridas en producción no aplica porque el código no cambia entre invocaciones.

**Descubierto durante:** fase 7 de la migración Dropbox → GitHub Releases (implementación de `ensure_asset.ado`), sesión 2026-05-24.

### Sanitización de nombres de assets en GitHub Releases: espacios → puntos

**Síntoma.** Al subir un asset con espacios en el nombre (e.g., `CP 2024.xlsx`) vía `gh release upload` o vía la web UI de GitHub, el archivo queda almacenado en GitHub con un nombre distinto (e.g., `CP.2024.xlsx`). El download vía URL pública con el nombre original retorna 404; el correcto es el nombre sanitizado.

**Causa.** La API de GitHub Releases (no solo el CLI `gh`) aplica una regla de sanitización a los nombres de assets al momento de upload, sustituyendo espacios por puntos. Es comportamiento documentado pero fácil de pasar por alto. Otros caracteres no-ASCII (acentos, símbolos) podrían tener sanitización similar — no fueron probados en este proyecto con assets actuales, vale tener presente para releases futuros.

**Solución.** Declarar el nombre del asset en el `manifest.json` como el nombre real post-sanitización (con puntos), no como el nombre del archivo local. El campo `local_path` del manifest conserva el nombre original con espacios para la ubicación en disco; el campo `name` usa el nombre sanitizado para construir el URL de descarga. La asimetría es deliberada y captura una propiedad real del sistema.

**Cómo evitar.** Después de subir assets a un release, verificar empíricamente con `gh release view` que los nombres coinciden con lo declarado en el manifest. Si difieren, actualizar el manifest, no re-uploadar con nombres distintos.

**Descubierto durante:** fase 6 de la migración (creación del release v7.0), sesión 2026-05-23. Documentado en commit `d2be3ec`.

### `find` captura archivos durante su propia generación

**Síntoma.** Un comando del estilo `find raw/ -type f | while read f; do compute_hash "$f"; done > output.json` produce un output donde el propio `output.json` aparece como una de las entradas procesadas, frecuentemente con valores inválidos o inconsistentes.

**Causa.** Dependiendo de cuándo el shell abre el archivo de salida (`>`) versus cuándo el `find` enumera el directorio, el archivo recién creado vacío puede aparecer en el listado de `find` y procesarse como si fuera contenido legítimo. Es race condition entre la apertura del file descriptor por parte del shell y la enumeración del filesystem por `find`.

**Solución.** Excluir explícitamente el archivo de output del listado de `find`. Por ejemplo: `find raw/ -type f ! -name 'manifest.json'` antes del pipe. Alternativa: escribir a un archivo temporal fuera del directorio inspeccionado y moverlo al destino final tras completar.

**Cómo evitar.** Al diseñar scripts que generan archivos dentro del mismo directorio que están enumerando, anticipar este caso. Patrón seguro: escribir a `/tmp/temp_output` durante la generación, mover a destino final tras cerrar. Patrón alternativo: exclusión explícita en el `find`.

**Descubierto durante:** fase 5 de la migración (generación inicial del manifest.json), sesión 2026-05-23. Resuelto en el generador con exclusión explícita.

### `gh release create` reutiliza tags preexistentes sin moverlos

**Síntoma.** Al ejecutar `gh release create v7.0 --target <SHA del commit deseado>`, si el tag `v7.0` ya existe en el repositorio apuntando a un commit distinto, el release se crea pero el tag de Git no se mueve. El campo `targetCommitish` del release (visible vía API) refleja el SHA solicitado, pero el tag de Git visible en `git tag -l` y `git ls-remote --tags` sigue apuntando al commit viejo. La inconsistencia entre el release y el tag es difícil de detectar sin inspeccionar ambos por separado.

**Causa.** GitHub trata el release y el tag de Git como objetos distintos. El campo `targetCommitish` del release es metadato del release; el tag de Git es objeto separado. `gh release create` respeta tags preexistentes — los reutiliza tal cual en lugar de moverlos. Es defensivo (evita destruir tags inadvertidamente), pero produce sorpresa cuando el invocante espera que `--target` controle todo.

**Solución.** Verificar el tag y el release por separado tras crear el release:

```bash
gh release view <tag> --json targetCommitish,tagName
git ls-remote --tags origin <tag>
```

Si difieren, mover el tag explícitamente: borrar local y remoto, recrear apuntando al commit correcto, force push al remoto. Operación irreversible — hacerla con doble checkpoint.

**Cómo evitar.** Antes de `gh release create`, verificar si el tag ya existe en el remoto con `git ls-remote --tags origin <tag>`. Si existe, decidir explícitamente si mover el tag antes de crear el release, o si el commit destino debe ser el del tag preexistente.

**Descubierto durante:** fase 6 de la migración (creación del release v7.0 con tag preexistente con narrativa institucional), sesión 2026-05-23.

### Permisos rsync `--chmod` para evitar HTTP 403 en Apache

**Síntoma.** Tras un deploy exitoso vía `rsync` sobre SSH a un servidor Apache (caso concreto: el endpoint Cloudways del sub-canal Stata público en `https://ciep.mx/simuladorfiscal/`), las URLs públicas a los archivos sincronizados retornan HTTP 403 Forbidden. Acceso vía SSH directo al servidor confirma que los archivos existen y son legibles para el usuario SSH, pero Apache no puede servirlos.

**Causa.** rsync por default preserva los permisos del archivo origen (o, dependiendo de flags, los de un directorio temporal donde rsync escribe antes de mover al destino final). Si el directorio temporal usado por rsync tiene permisos restrictivos (caso típico: directorios sincronizados desde `tmpfs` o desde paths con `umask 077`), los archivos terminan con permisos `600` o `640` en el servidor Apache. El proceso Apache (típicamente usuario `www-data`, `apache` o equivalente) no es el dueño y no está en el grupo del archivo, así que falla la lectura — HTTP 403.

**Solución.** Aplicar el flag `--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r` al comando rsync. Eso fuerza permisos `755` a directorios y `644` a archivos durante la sincronización, independientemente de los permisos del origen. Apache lee los archivos por la entrada world-readable (último bit `r` en `Fgo=r`).

**Cómo evitar.** Cuando un script de deploy sincroniza a un servidor web vía rsync, agregar `--chmod` explícito desde la primera versión del script. No esperar a que aparezca el HTTP 403 en producción para descubrir el problema. El patrón general es: cualquier deploy a servidor web requiere permisos world-readable en los archivos servidos; rsync no garantiza eso por default.

**Descubierto durante:** primer deploy del sub-canal Stata público (v8.0, mayo 2026), implementación de `publicar-endpoint.sh`. Fix aplicado en commit `4414e18`.

**Actualización 2026-07-09 (primer deploy al VPS IONOS):** el mismo patrón reapareció en `publicar-vps.sh` y la investigación reveló una limitación adicional: el `rsync` que trae macOS es en realidad **openrsync de Apple** (se anuncia "rsync 2.6.9 compatible"), que rechaza la sintaxis octal de `--chmod` (`D775,F664` → "invalid argument") y **acepta pero ignora en silencio** la forma simbólica (verificado con transferencias locales: los permisos 700/600 del origen llegan intactos). Conclusión institucional: desde una Mac, `--chmod` NO es garantía — hay que normalizar permisos en el destino después de la transferencia (`ssh servidor "chmod -R u=rwX,g=rwX,o=rX <dir>"`), como hace la Fase 3c de `publicar-vps.sh`.

### `find` recursivo en `$HOME` se cuelga indefinidamente

**Síntoma.** Un script bash que ejecuta `find "$HOME" -maxdepth N -type d -name 'patron'` para auto-detectar la ubicación de un directorio típico de Dropbox dentro del `$HOME` del usuario, en lugar de terminar en segundos, se cuelga indefinidamente sin reportar errores ni progreso. El usuario eventualmente cancela con Ctrl-C.

**Causa.** `find` en `$HOME` recorre todo lo que considera subdirectorio, incluyendo carpetas de cloud providers que pueden tener semánticas no-locales: Dropbox, iCloud Drive, Google Drive, OneDrive, Adobe Cloud, Steam, etc. Cada cloud provider puede tener mecanismos distintos de presentación de archivos (placeholders descargables on-demand, archivos virtuales, montajes lazy) que hacen que `find` haga llamadas de stat o readdir que esperan respuesta del servicio remoto. Si la conexión del cloud provider está lenta o stalled, `find` espera indefinidamente. Aún con conexión rápida, recorrer decenas de miles de archivos remotos toma tiempo proporcional al tamaño total de la cuenta del usuario en cada servicio.

**Solución.** En lugar de `find` recursivo, evaluar candidatos típicos directamente con `[[ -d "$path" ]]`. Cada chequeo es operación de filesystem stat sobre un path específico, instantánea. Para el caso concreto de localizar `Dropbox-CIEP/SimuladorCIEP/`:

```bash
local -a candidates=(
    "$HOME/Library/CloudStorage/Dropbox-CIEP/SimuladorCIEP"  # Mac moderno
    "$HOME/Dropbox-CIEP/SimuladorCIEP"                       # Linux / Mac clásico
)
for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
        TARGET_PATH="$candidate"
        break
    fi
done
```

**Cómo evitar.** Cuando un script bash necesita localizar un directorio en `$HOME`, preferir array de candidatos típicos sobre `find` recursivo, incluso si eso requiere mantener el array cuando aparecen patrones nuevos. La mantenibilidad del array es preferible a la fragilidad del `find` con cloud providers. Si el `find` es estrictamente necesario, agregar `-not -path '*/CloudStorage/*'` o exclusiones similares para cortar las ramas problemáticas — pero la solución arquitectónicamente más limpia es no usar `find` para este propósito.

**Descubierto durante:** primer test funcional de `publicar.sh internos` con auto-detección de la Carpeta (mayo 2026). El `find` introducido en commit `86c4756` se colgaba; reemplazado por array de candidatos en commit `cad03b7`.

### Dropbox revierte renames locales que el cloud aún no propagó

**Síntoma.** Operación de mantenimiento sobre un directorio dentro de Dropbox-CIEP (caso concreto: renombrar un clon Git roto a `<directorio>.broken-<timestamp>` para preservarlo mientras se construye un reemplazo). El `mv` en terminal termina sin errores; el listado del directorio padre confirma el rename. Pero minutos después, el directorio renombrado desaparece y el directorio original reaparece con su nombre y contenido viejo. La operación de mantenimiento queda deshecha sin notificación al operador.

**Causa.** Dropbox sincroniza entre el filesystem local y su cloud bidireccionalmente. Cuando una operación local (rename, mv, rm) no ha sido propagada al cloud aún — porque Dropbox no ha tenido tiempo de detectarla, o porque sync está pausado, o porque está en cola con otras operaciones — y simultáneamente Dropbox detecta divergencia entre cloud y local, **la operación que prevalece es la del cloud** (asumiendo que el local está en error y el cloud es la verdad). Es comportamiento conservador, defensivo contra modificaciones accidentales del filesystem por procesos no-Dropbox. Pero significa que mantenimiento local explícito puede ser revertido sin previo aviso.

**Solución.** Antes de cualquier operación destructiva o de mantenimiento dentro de un directorio sincronizado por Dropbox (rename, mv, rm masivos), pausar el sync de Dropbox manualmente desde su app de barra de menú ("Pause syncing"). Ejecutar las operaciones con sync pausado. Verificar el estado final. Reanudar el sync ("Resume syncing"). Dropbox detecta los cambios masivos como un solo batch y propaga al cloud, esta vez sin pelear contra ellos. Operaciones afectadas: rename de directorios, eliminaciones masivas, copias destructivas (`cp -R` que sobreescribe), `git checkout` sobre archivos versionados en Dropbox.

**Cómo evitar.** Si un script de mantenimiento o de deploy va a tocar varios archivos dentro de Dropbox-CIEP en operaciones consecutivas (más de unos pocos archivos en menos de un minuto), incluir como pre-condición pausar Dropbox, y como post-condición un mensaje al operador para reanudar. Alternativa: ejecutar las operaciones fuera de Dropbox (en `/tmp/`) y al final mover el resultado en una sola operación atómica.

**Descubierto durante:** operación de reclone correctivo de la Carpeta de investigadores (junio 2026), donde el rename inicial del clon roto fue deshecho por Dropbox antes de poder clonar el repo fresco. La operación se completó después con sync pausado.

### Terminal macOS no puede listar Desktop sin Full Disk Access

**Síntoma.** Comando `ls $HOME/Desktop/` o `find $HOME/Desktop -type d` desde Terminal retorna `Operation not permitted` aunque el usuario sea dueño del directorio y exista contenido. Comandos sobre paths absolutos a archivos específicos dentro de Desktop (e.g., `ls $HOME/Desktop/archivo-específico.txt`) sí funcionan. La asimetría es: Terminal puede leer archivos cuando sabe su path completo, pero no puede enumerar el directorio para descubrirlos.

**Causa.** macOS moderno (versiones recientes) aplica el framework TCC (Transparency, Consent, Control) a ciertos directorios sensibles del usuario: Desktop, Documents, Downloads. Apps que quieren listar el contenido de estos directorios necesitan permiso explícito en System Settings > Privacy & Security > Full Disk Access. Terminal viene sin ese permiso por default. La asimetría entre "enumerar directorio" y "leer archivo por path absoluto" es deliberada: el sistema operativo considera que listar el contenido es una operación de descubrimiento que merece consentimiento más estricto que leer un archivo cuya ruta el usuario ya conoce.

**Solución.** Otorgar Full Disk Access a la app Terminal en System Settings > Privacy & Security. Requiere abrir el panel, hacer click en el candado (autenticación), agregar Terminal a la lista, reiniciar Terminal para que el permiso se aplique. Una vez otorgado, `ls $HOME/Desktop/` funciona normalmente. Si se usa otra app de terminal (iTerm2, Warp, etc.), aplica lo mismo a esa app específicamente.

**Cómo evitar.** Cuando un script bash necesita interactuar con archivos en Desktop, Documents o Downloads del usuario, asumir que el `ls` o `find` puede fallar y degradar gracefully. Para operaciones críticas, documentar al operador que debe otorgar Full Disk Access antes de ejecutar. Alternativa más robusta: no usar Desktop/Documents/Downloads como ubicación de archivos operativos del Simulador — preferir ubicaciones en `$HOME` directamente (e.g., `$HOME/.simulador-state/`) que no están sujetas a TCC.

**Descubierto durante:** verificación post-reclone correctivo de la Carpeta (junio 2026), donde el snapshot de respaldo en `~/Desktop/users-snapshot-<timestamp>/` no aparecía con `ls` desde Terminal aunque existía físicamente. Confirmado que `ls /Users/ricardo/Desktop/users-snapshot-...` por path absoluto sí funciona, pero `ls $HOME/Desktop/ | grep snapshot` falla con Operation not permitted.

### zsh sin `interactive_comments` rompe comandos pegados con `#` 

**Síntoma.** Pegar en Terminal zsh un bloque de comandos que incluye líneas de comentario (`# Este es un comentario`) hace que zsh trate la línea de comentario como un comando, retornando `command not found: #`. Las líneas subsiguientes del bloque pueden o no ejecutarse dependiendo de cómo zsh interprete el flujo. Ejecuciones por script (no pegadas, sino vía `bash script.sh` o `zsh script.sh`) funcionan correctamente porque scripts son no-interactivos.

**Causa.** Por default, zsh interactivo trata `#` como carácter literal, no como inicio de comentario. Esta es decisión de diseño de zsh: en sesión interactiva, comentarios no tienen sentido (no estás escribiendo un script, estás escribiendo comandos para ejecución inmediata). Bash interactivo, por contraste, sí honra `#` como comentario por default. La opción de zsh que cambia este comportamiento es `interactive_comments`, que debe activarse explícitamente con `setopt interactive_comments` para que zsh interactivo trate `#` como inicio de comentario.

**Solución.** Agregar `setopt interactive_comments` al archivo `~/.zshrc` del operador. Después de eso, comandos pegados con comentarios funcionan como esperan los usuarios de bash. Recargar configuración con `source ~/.zshrc` o abrir Terminal nueva para que aplique.

**Cómo evitar.** Cuando se diseñan bloques de comandos para que el operador los pegue en Terminal, evitar comentarios con `#` si la audiencia tiene zsh sin `interactive_comments` activado. Si los comentarios son institucionalmente importantes para la legibilidad del bloque, agregar la nota: "Antes de pegar, asegura que tu zsh tiene `setopt interactive_comments` activado." Alternativa: usar `echo "..."` para mensajes informativos en lugar de comentarios `#`, eso funciona en todo shell.

**Descubierto durante:** sesiones de operación interactiva del Simulador con bloques de comandos pegados desde documentos. El operador encuentra el problema repetidamente; documentado aquí para que próximas sesiones lo eviten.
