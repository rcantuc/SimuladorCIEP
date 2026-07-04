# Arquitectura de distribución de los Simuladores CIEP

**Ubicación en el Ecosistema CIEP.** Este documento describe la arquitectura técnica de los Simuladores CIEP — uno de los componentes del **Ecosistema CIEP** (el conjunto completo de productos digitales, infraestructura y dominios del CIEP; definición formal en el Glosario CIEP institucional, `governance/glosario-ciep.md`). Otros componentes del Ecosistema (Micrositios, sitio principal `ciep.mx`, infraestructura general) se describen en otros documentos de governance o están pendientes de documentar formalmente.

**Alcance.** Los **Simuladores CIEP** son el ecosistema de tres herramientas interactivas web del CIEP, todas alojadas como subdominios de `ciep.mx`: el Simulador Fiscal CIEP (`simuladorfiscal.ciep.mx`), el Simulador IEPS al tabaco (`iepsaltabaco.ciep.mx`) y el Simulador de tenencia vehicular (`tenencia.ciep.mx`). "Simuladores CIEP" es sustantivo colectivo: las políticas y procedimientos de governance del CIEP aplican a los tres por defecto, no por excepción. Este documento describe la arquitectura común al ecosistema. El Simulador Fiscal CIEP es el caso operativo más maduro y mejor documentado, y es el ejemplo concreto al que se anclan las descripciones detalladas de las secciones 2 a 5; los simuladores de IEPS al tabaco y de tenencia vehicular son sustantivamente más pequeños en código y complejidad, y aún no tienen governance formal aplicada, pero la arquitectura, las políticas y los procedimientos aquí descritos se diseñan para extenderse a ellos.

**Naturaleza del documento:** describe la arquitectura **objetivo** de los Simuladores CIEP como sistema de cuatro capas. Varios componentes (los scripts `publicar.sh` y `reproducir.sh`, el banner enriquecido de `profile.do`, el archivo `CHANGELOG.md`, el comando `sim_changelog`, la firma de versión en outputs, la documentación operativa del sitio web) aparecen aquí descritos por su contrato funcional pero aún no están implementados. La sección 7 lista honestamente lo que falta y en qué fase se construye cada cosa. Si lees este documento hoy y abres Stata hoy, vas a ver el Simulador Fiscal CIEP funcionando como siempre — la arquitectura completa aquí descrita se construye en fases siguientes, y la extensión a los simuladores de IEPS al tabaco y tenencia vehicular es trabajo posterior.

**Para quién es este documento:** cualquier persona que interactúe con los Simuladores CIEP. Investigadores CIEP que los usan como herramientas, el investigador principal que los desarrolla, investigadores colaboradores que se sumen al mantenimiento, lectores externos que necesiten reproducir un análisis publicado, o usuarios externos que entran a los sitios web públicos.

**Qué encuentras aquí:** cómo está organizado el ecosistema como sistema vivo. No es un solo producto con una sola audiencia; son cuatro capas con audiencias y mecanismos distintos que comparten patrones arquitectónicos comunes y, en el caso del Simulador Fiscal CIEP, un solo motor de cálculo expuesto a través de varias interfaces.

**Cuatro preguntas que este documento responde:**

1. *Si soy investigador del CIEP y nunca he tocado Git, ¿cómo uso el Simulador Fiscal CIEP en mi día a día?* → Sección 2.
2. *Si voy a publicar una versión nueva al equipo, ¿qué tengo que hacer?* → Sección 3.
3. *Si necesito reproducir exactamente lo que el Simulador Fiscal CIEP produjo cuando se publicó un análisis hace año y medio, ¿cómo lo hago?* → Sección 5.
4. *¿Cómo se relacionan los Simuladores CIEP entre sí y cómo se conectan con sus herramientas web públicas?* → Sección 6.

**Qué NO encuentras aquí:** cómo se hacen commits, ramas o pull requests en el lado de desarrollo. Eso vive en `convenciones-git.md`. Este documento describe la arquitectura completa; el otro describe el detalle operativo de la Capa 1.

---

## Tabla de contenido

1. [La arquitectura en una imagen](#1-la-arquitectura-en-una-imagen)
2. [Para ti, investigador CIEP: cómo se ve el Simulador del día a día](#2-para-ti-investigador-ciep-cómo-se-ve-el-simulador-del-día-a-día)
3. [Para ti, investigador principal: cómo publicar una versión nueva](#3-para-ti-investigador-principal-cómo-publicar-una-versión-nueva)
4. [Qué es "una versión publicada"](#4-qué-es-una-versión-publicada)
5. [Cómo reproducir un análisis publicado](#5-cómo-reproducir-un-análisis-publicado)
6. [Las herramientas web públicas](#6-las-herramientas-web-públicas)
7. [Lo que NO está implementado todavía](#7-lo-que-no-está-implementado-todavía)

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
| **Con prefijo numérico** (`01_`, `02_`…) | `01_modulos/`, `02_governance/`, `03_help/`, `04_simuladorfiscal.ciep.mx/`, `05_scripts/` | **No.** Son permanentes: contienen código, documentación y configuración que no se regeneran solos. |
| **Sin prefijo** | `master/`, `raw/` (con `raw/temp/`), `users/` | **Sí.** Son restablecibles: el propio Simulador los vuelve a crear y llenar cuando corres el pipeline. |

**Qué vive en cada directorio permanente:**

- **`01_modulos/`** — los `.do` del pipeline del Simulador (módulos de análisis, visualizaciones) y `01_modulos/legacy/` con código histórico congelado que se conserva como testimonio pero no se mantiene.
- **`02_governance/`** — la documentación de cómo se administra el proyecto, incluido `CHANGELOG.md` (el registro de cambios por versión). El changelog vive aquí y no en `03_help/` porque es un registro institucional del proyecto, no ayuda de uso de comandos.
- **`03_help/`** — la ayuda: los `.sthlp` de cada comando (en `03_help/Stata/`), el manual del investigador y las imágenes de documentación.
- **`04_simuladorfiscal.ciep.mx/`** — los archivos del sitio web público. Ignorado por Git (es copia operativa del servidor), pero el directorio en sí es permanente.
- **`05_scripts/`** — los scripts de publicación (`publicar.sh`, `publicar-endpoint.sh`), sus manifiestos (`manifest.json`, `manifest-endpoint.toml`), las credenciales (plantilla versionada + archivo real gitignored) y los `.pkg` del sub-canal Stata. El `manifest.json` vive aquí — y no en la raíz — porque se agrupa con los scripts que lo consumen y lo actualizan.

**Por qué los `.ado` siguen sueltos en la raíz.** Los comandos del canon (`SCN.ado`, `PEF.ado`, `LIF.ado`…), los esquemas de gráficas (`scheme-*.scheme`) y los archivos de arranque (`SIM.do`, `profile.do`, `sysprofile-template.do`, `set_token.template.do`, `sim_changelog.ado`, `ensure_asset.ado`) **no** se mueven a ningún subdirectorio. Stata los busca exactamente ahí: el arranque del Simulador registra la carpeta raíz en la ruta de búsqueda de comandos de Stata (técnicamente, `adopath ++SITE` — la instrucción que le dice a Stata "también busca comandos en esta carpeta"). Si mueves un `.ado` a un subdirectorio, Stata deja de encontrar ese comando.

**Qué pasa cuando borras un directorio restablecible:**

- **`raw/`** — los insumos se vuelven a descargar automáticamente: `ensure_asset` baja cada archivo desde GitHub Releases y verifica su integridad. `raw/temp/` (archivos intermedios de cada corrida) se regenera solo al correr los comandos.
- **`master/`** — las bases procesadas se reconstruyen corriendo el pipeline (tarda, pero no se pierde nada).
- **`users/<tu-usuario>/`** — es tu espacio personal de trabajo (resultados, gráficas). Puedes borrar el tuyo; **no borres el de otra persona**.

🧠 **Concepto: separar lo permanente de lo regenerable.** La convención de prefijos hace visible, desde el nombre mismo del directorio, qué es patrimonio del proyecto (código, docs, configuración — prefijado y versionado en Git) y qué es estado de trabajo (datos descargados y procesados — sin prefijo, ignorado por Git, regenerable). Un investigador nuevo no necesita preguntar qué puede borrar: el nombre lo dice.

---

## 3. Para ti, investigador principal: cómo publicar una versión nueva

*Qué aprendes en esta sección:* el procedimiento exacto para tomar el trabajo terminado en una rama de trabajo y publicarlo como versión nueva al equipo CIEP y a la herramienta web pública.

Esta sección asume que ya conoces las convenciones de Git que usa este repositorio (`convenciones-git.md`). Aquí sólo describimos el flujo de publicación; los detalles de cómo se hacen commits, ramas de trabajo y etiquetas de versión están allá.

### 3.1 Los pasos

1. **Termina e integra tu trabajo en `master`.** Todo lo que entra en una versión publicada tiene que estar en `master` primero. Detalle del flujo de pull request: `convenciones-git.md` §2.

2. **Decide el número de versión.** ¿Es un cambio metodológico de fondo (mayor: `v7 → v8`)? ¿Datos anuales nuevos o módulo nuevo (menor: `v7.0 → v7.1`)? ¿Corrección urgente sobre versión publicada (parche: `v7.0 → v7.0.1`)? Detalle: `convenciones-git.md` §3.2.

3. **Actualiza `02_governance/CHANGELOG.md` en el Código del Simulador.** Una entrada nueva con el número de versión, la fecha, y bullets agrupados por categoría:
   - **Cambios metodológicos** (afectan resultados — los lectores del Simulador tienen que verlos).
   - **Datos actualizados** (qué fuentes se subieron de versión).
   - **Funcionalidad nueva** (módulos o comandos nuevos).
   - **Correcciones de errores**.
   - **Cambios técnicos** (no afectan resultados pero importa documentar).

4. **Crea la etiqueta de versión en Git** (en inglés *tag*, un marcador permanente sobre un commit específico) sobre el commit correspondiente: `git tag -a v7.2 -m "v7.2 — descripción corta"`. Detalle: `convenciones-git.md` §3.3.

5. **Sube la etiqueta al remoto** (en inglés *push*): `git push origin v7.2`.

6. **Crea la Publicación en GitHub** (en inglés *Release*) apuntando a la etiqueta, con el changelog y los archivos de datos pesados que correspondan a la versión. El Catálogo de datos asociados (`05_scripts/manifest.json`) se actualiza con las huellas digitales de los archivos subidos. Detalle: `convenciones-git.md` §3.3 paso 2.

7. **Ejecuta `publicar.sh v7.2`** (cuando exista — ver §7). El script copia desde tu carpeta de desarrollo a la Carpeta del Simulador para investigadores, eligiendo qué archivos van y cuáles no.

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

El esquema de números (`v7.0`, `v7.1`, `v8.0`...) sigue una regla simple: el primer número sube cuando hay un cambio metodológico de fondo que rompe la comparabilidad con resultados anteriores; el segundo sube cuando hay datos nuevos o funcionalidad nueva pero los resultados siguen siendo comparables; el tercero sólo aparece para corregir un error urgente sobre una versión ya publicada y citada. La regla detallada con cuándo aplica cada incremento está en `convenciones-git.md` §3.2.

**¿Por qué las versiones publicadas no se borran ni se editan, nunca?** Por la misma razón que una publicación académica no se reescribe después de aparecer en una revista. Cuando un paper del CIEP cita *"resultados del Simulador Fiscal v7.0 (octubre 2024)"*, esa cita es una promesa al lector: cualquiera puede volver a `v7.0` y reproducir los mismos números. Si borras o editas `v7.0` retroactivamente, rompes la promesa. La práctica académica resolvió esto hace cien años con el concepto de errata: si descubres un error después de publicar, no editas el original — publicas una corrección como artefacto nuevo, complementario, citable por separado. En el Simulador es lo mismo: encuentras un error en `v7.0`, publicas `v7.0.1` con la corrección y una nota explícita en el changelog. La etiqueta de versión es un contrato social con quien cita el Simulador. Detalle del razonamiento: `convenciones-git.md` §3.4.

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
| **Qué hace**                  | (1) Descarga una copia completa del Código del Simulador desde GitHub a la carpeta destino (técnicamente, hace `git clone` — el comando que verías en Git o GitHub Desktop si lo hicieras a mano). (2) Vuelve esa copia al estado exacto que tenía en `v7.0` (técnicamente, hace `git checkout v7.0` por ti). (3) Lee el Catálogo de datos asociados (`05_scripts/manifest.json`, descrito en `convenciones-git.md` §3.3) y descarga los archivos de datos que corresponden a `v7.0` desde la Publicación de GitHub de esa versión. (4) Verifica las huellas digitales SHA-256 (en inglés *SHA*, un identificador único derivado del contenido del archivo, equivalente a una huella digital) de los datos para confirmar que son los originales. |
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

Daniel Orduña no es investigador del CIEP — es un colaborador externo cuyo rol formal es de mantenimiento de infraestructura. Acceso a Cloudways, no a IONOS, no al Código del Simulador, no a credenciales del gestor de secretos del investigador principal. Esta es la primera vez que el ecosistema CIEP tiene un colaborador externo con privilegios administrativos formales sobre alguna pieza de infraestructura, y la política completa de gestión de credenciales vive en `governance/politica-gestion-secretos.md`. La adopción formal del gestor de secretos institucional sigue pendiente — ver §7.

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

La documentación detallada del procedimiento de renovación (comandos exactos, dónde se guarda el certificado en el servidor) es trabajo pendiente (§7). La política completa de gestión de secretos vive en `governance/politica-gestion-secretos.md`.

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

*Qué aprendes en esta sección:* esta arquitectura es objetivo, no estado actual completo. Aquí está la lista honesta de lo que falta y cuándo se construye.

**Alcance de esta sección:** los pendientes listados abajo corresponden específicamente al Simulador Fiscal CIEP. Algunos componentes mantienen dependencias con decisiones institucionales del Ecosistema CIEP completo (gestor de secretos del CIEP, documentación SSL del sitio web, procedimiento de actualización del sitio web): estas dependencias se reconocen aquí, pero la construcción institucional correspondiente se trabaja en proyecto separado dedicado al Ecosistema CIEP. Pendientes que corresponden exclusivamente a otros productos del Ecosistema (governance formal de los otros Simuladores CIEP, decisiones de infraestructura del CIEP completo, política del rol "colaborador externo de infraestructura") no se documentan en esta sección.

| Componente                                                                                                     | Estado hoy                                                                                                                                                                                                                                                                                 | Cuándo se construye                                                                                                                                                               |
| ----------------------------------------------------------------------------------------------------------------| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clon de desarrollo fuera de Dropbox                                                                            | Sigue dentro de Dropbox (`~/Library/CloudStorage/Dropbox-CIEP/.../SimuladorCIEP/`). Riesgo de corrupción del directorio `.git/` documentado en `governance/historico/fase-0-5-git-hygiene-audit.md`.                                                                                                 | Sin calendario fijo. Operación manual cuando se justifique mover el clon de desarrollo fuera de Dropbox.                                                                          |
| Carpeta del Simulador para investigadores separada de la carpeta de desarrollo                                 | No existe como carpeta distinta. Hoy `~/Dropbox-CIEP/SimuladorCIEP/` cumple ambos papeles (desarrollo + distribución). La separación entre ambas carpetas se implementa en Fase A5.                                                                                                        | Fase A5 (primera publicación formal de una versión).                                                                                                                              |
| `reproducir.sh`                                                                                                | No implementado. Contrato funcional documentado en §5.4.                                                                                                                                                                                                                                   | Fase A5 o A6 (después de la primera Publicación con datos asociados).                                                                                                             |
| `profile.do` enriquecido con banner de versión y changelog                                                     | No implementado. El `profile.do` actual ya tiene un banner de bienvenida, pero sin información de versión ni de cambios. Mockup en §2.2.                                                                                                                                                   | Fase A5.                                                                                                                                                                          |
| `CHANGELOG.md` en la raíz del Código del Simulador                                                             | No existe.                                                                                                                                                                                                                                                                                 | Fase A5, junto con la primera versión publicable.                                                                                                                                 |
| Comando interno `sim_changelog` (Stata) que muestra changelog completo                                         | No implementado.                                                                                                                                                                                                                                                                           | Fase A5.                                                                                                                                                                          |
| Mecanismo de archivo de estado local del investigador (`~/.simulador_ciep_state`)                              | No implementado. Diseño preliminar en §2.2; ruta exacta y formato a definir.                                                                                                                                                                                                               | Fase A5.                                                                                                                                                                          |
| Firma de versión en outputs (globales `${sim_version}`, etc.)                                                  | No implementado. Diseño en §2.4.                                                                                                                                                                                                                                                           | Fase A5, integrado con `profile.do` enriquecido.                                                                                                                                  |
| Procedimiento de incorporación de un investigador CIEP nuevo (configuración estandarizada del `sysprofile.do`) | El repo incluye `sysprofile-template.do` como referencia, pero la instalación del `sysprofile.do` real en `/Applications/StataNow/` de cada investigador sigue siendo trabajo manual del investigador principal (Ricardo lo configura a mano en cada máquina nueva). No está documentado ni automatizado. La consecuencia es que dar de alta a un investigador nuevo requiere intervención uno-a-uno.               | Por definir. Opciones: script `setup_user.sh` o sección nueva en este mismo documento ("Cómo doy de alta a un investigador CIEP nuevo"). Decisión sobre formato y fase pendiente. |
| Procedimiento detallado de actualización del sitio web por cada publicación                                    | No documentado. Hoy es trabajo manual del investigador principal. Falta especificar: comandos exactos, cuánto downtime, prueba previa, qué hacer si la nueva versión rompe el sitio.                                                                                                       | Fase A5 o posterior.                                                                                                                                                              |
| **Estrategia de versionado de `simulador.stpr`**                                                              | El proyecto de Stata Project Manager (`.stpr`) está gitignored porque Stata guarda paths absolutos que revelan la estructura de disco del investigador principal y no funcionan en otras máquinas. Sin versionar, cada investigador construye su propia organización de archivos desde cero. Alternativas a evaluar: (1) verificar si Stata Project Manager tiene opción de rutas relativas; (2) versionar `simulador-template.stpr` con estructura mínima como template y mantener `simulador.stpr` personal gitignored.                                                                                                                                                                                       | Sin calendario fijo. Trabajo cuando aparezca demanda de investigadores por navegación estructurada del repo.                                                                       |
| **Adopción formal del gestor de secretos institucional del CIEP**                                              | El documento de política existe (`governance/politica-gestion-secretos.md`) y define principios, procedimientos y matriz de acceso. Lo que sigue pendiente es la adopción operativa del gestor institucional: hoy las credenciales del investigador principal viven en su gestor personal. Migrar a un gestor institucional es práctica a completar antes de incorporar al primer investigador colaborador.                                                                                                                       | Decisión administrativa/presupuestal del investigador principal sobre qué gestor adoptar (ej. 1Password Business, Bitwarden self-hosted) y bajo qué presupuesto.                  |
| Documentación operativa del certificado SSL del sitio web                                                      | No documentada. Falta especificar: emisor del certificado, procedimiento de renovación (automático o manual), responsable, calendario de verificación.                                                                                                                                     | Fase A5 o posterior.                                                                                                                                                              |
| **Documentación formal de la convención `legacy/<categoria>/`**                                                | La convención está aplicada de facto: el repo tiene un directorio `legacy/analisis-v7/` con artefactos preservados pero no mantenidos activamente (commit `a6ed606` agregó `Expenditure_PTLAC.do` siguiendo el patrón existente). Falta documentar formalmente la convención en governance: qué califica como "legacy", cómo se nombran las sub-categorías, cuál es el flujo para mover un artefacto a legacy (cuándo se justifica, quién decide, cómo se registra).                                                            | Trabajo de governance pendiente, probablemente en este mismo documento o en `convenciones-git.md`. Sin calendario fijo.                                                            |
Mientras estos componentes no existan, el Simulador opera como siempre: el equipo CIEP usa la carpeta de Dropbox sin distinción de capas, sin trazabilidad de versión en outputs, sin script de reproducción; el sitio web sigue funcionando pero sin procedimiento documentado de actualización. La arquitectura aquí descrita es la que se va construyendo en las fases siguientes.

---

## 🧠 Concepto: un motor de cálculo, varias interfaces hacia audiencias distintas

El patrón detrás de las cuatro capas es viejo en la práctica científica: **un modelo único cuyos resultados se comunican mediante distintos canales adaptados a su audiencia**. Un grupo de investigación con un modelo macroeconómico no lo publica una sola vez en un solo formato. Lo publica como paper técnico para revisores especializados, como working paper accesible para colegas, como nota de divulgación para periodistas, como presentación en conferencia para tomadores de decisión, y a veces como herramienta interactiva para el público general. Las audiencias son distintas; el modelo subyacente es el mismo.

El Simulador funciona igual. La Capa 1 es el modelo en su forma técnica completa (código auditable, decisiones metodológicas documentadas). La Capa 2 lo hace usable como herramienta de análisis para investigadores CIEP. La Capa 3 lo congela en instantáneas reproducibles que cualquiera puede recuperar para defender un resultado citado. La Capa 4 lo expone como herramienta pública para audiencias externas que no usan Stata. Las cuatro interfaces hablan distinto, pero los números salen del mismo cálculo. Es lo que mantiene al Simulador coherente como fuente única — y lo que permite que un periodista, un investigador y un revisor académico, cada uno usando su interfaz preferida, vean el mismo modelo.

---

## Comportamientos no obvios y troubleshooting

Esta sección documenta peculiaridades del entorno técnico que pueden confundir a quien mantenga el Simulador. Cada entrada captura un comportamiento real, verificado empíricamente, que no es bug del sistema sino propiedad del entorno que no es obvia a primera vista. Documentarlos aquí ahorra horas de debugging a futuros mantenedores.

La sección está abierta a expansión: cuando se identifique un nuevo comportamiento no obvio, se agrega como sub-sección nueva siguiendo el patrón Síntoma / Causa / Solución / Cómo evitar.

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

## Política de higiene del directorio `02_governance/`

Reglas operativas para mantener orden en este directorio mientras crece:

- **Los documentos vivos se reescriben en su lugar.** Cuando un documento cambia de versión (de `v1.0` a `v2.0`, por ejemplo), se sobrescribe el mismo archivo y la bitácora interna del documento registra el cambio. No hay archivos versionados con sufijos `_v1`, `_v2` en el directorio actual; las versiones viejas viven en la historia de Git, accesibles con `git log --follow <archivo>`.
- **Documentos que dejan de aplicar se archivan en `02_governance/historico/`.** Esto pasa cuando la realidad o la decisión cambian y el documento ya no describe el sistema actual. Al mover, se agrega una nota corta en el archivo explicando por qué se retiró y qué documento vigente lo reemplaza (si aplica).
- **No se borra nada permanentemente.** Aunque un documento sea obsoleto, queda en `02_governance/historico/` para que el contexto histórico de decisiones siga consultable.

---

## Sobre el registro formal vs. coloquial

La documentación formal del CIEP usa términos cortos y técnicos. La conversación, las presentaciones generales y la comunicación al público pueden usar formas más descriptivas. Ninguno está mal; cada uno tiene su lugar.

**Equivalencias documentadas:**

| Formal (documentación)   | Coloquial (conversación, presentaciones) |
| ------------------------- | ----------------------------------------- |
| Simuladores CIEP         | Simuladores fiscales CIEP                |
| Ecosistema CIEP          | Ecosistema digital del CIEP              |
| Micrositios              | Micrositios narrativos                   |

Quien lea documentación formal puede esperar precisión técnica. Quien escuche conversación interna o presentación pública puede esperar las dos formas. Ambas se aceptan, no se castigan.

---

## Bitácora de cambios de este documento

| Fecha      | Versión | Cambios                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------| ---------| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2026-05-12 | 1.0     | Versión inicial. Documenta la arquitectura de cuatro capas (desarrollo, distribución vigente para investigadores, reproducción histórica, herramienta web pública) que hasta hoy vivía solo en la cabeza del investigador principal. Establece el contrato funcional de los componentes pendientes (`publicar.sh`, `reproducir.sh`, `profile.do` enriquecido, `CHANGELOG.md`, `sim_changelog`, archivo de estado local, procedimientos web y SSL). Adopta el glosario CIEP consolidado: "investigador principal", "investigadores colaboradores", "investigadores", "usuarios externos", "publicación", "etiqueta de versión", "Código del Simulador", "Carpeta del Simulador para investigadores", "Catálogo de datos asociados". Incluye política de higiene del directorio `governance/`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| 2026-05-13 | 1.1     | Reconoce que la Capa 4 (herramienta web pública) tiene **dos sub-canales**: web HTML interactivo (`simuladorfiscal.ciep.mx`) y Stata `net from` (instalación remota vía `https://ciep.mx/simuladorfiscal/`). Las dos URLs son distintas (subdominio vs. ruta del dominio principal del CIEP), pero ambos endpoints corren en infraestructura del CIEP en IONOS y sirven al mismo motor de cálculo. Actualiza el diagrama de §1 con la Capa 4 expandida en sus dos sub-canales. Reescribe §6.2 para reconocer que el motor corre en tres lugares (instalación local del investigador CIEP, copia remota del usuario externo vía `net from`, sitio HTML interactivo). Renombra §6.4 a "Sub-canal web HTML" (la documentación SSL queda como sub-sección sin cambios). Agrega §6.5 "Sub-canal Stata `net from`", que documenta la carpeta `Stata net/` del repo como área de staging actual del sub-canal Stata, con despliegue manual al servidor y limitaciones reconocidas (sin trazabilidad, sin automatización, divergencia silenciosa). Declara solución futura en v8: script `publicar-endpoint.sh` + manifiesto `manifest-endpoint.toml` + borrado de `Stata net/` una vez validado el script. Agrega contrato funcional preliminar de `publicar-endpoint.sh` al final de §7. |
| 2026-05-13 | 1.2     | Corrige error de hosting introducido en v1.1: los dos sub-canales de la Capa 4 no corren en la misma infraestructura. El sub-canal HTML (`simuladorfiscal.ciep.mx`) corre en IONOS (VPS dedicado); el sub-canal Stata `net from` (`https://ciep.mx/simuladorfiscal/`) corre en Cloudways (mismo hosting que el sitio principal `ciep.mx` y sus micrositios). Actualiza §1 (párrafo posterior al sub-diagrama de Capa 4) y §6.5 (subpárrafo "Endpoint"). Documentación completa de la infraestructura dual (cómo conviven Cloudways e IONOS, gestión de credenciales, planes de migración) queda pendiente para iteración futura.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 2026-05-13 | 1.3     | Expande el alcance del documento del **Simulador Fiscal CIEP** en singular a los **Simuladores CIEP** como sustantivo colectivo plural. Reconoce que el CIEP opera tres herramientas web públicas: el Simulador Fiscal CIEP (`simuladorfiscal.ciep.mx`), el Simulador IEPS al tabaco (`iepsaltabaco.ciep.mx`) y el Simulador de tenencia vehicular (`tenencia.ciep.mx`). Reescribe la cabecera y §1 (párrafos intro, diagrama principal y sub-diagrama de Capa 4) para incorporar el ecosistema de los tres simuladores y aclarar que la arquitectura completa de cuatro capas está desplegada hoy únicamente para el Simulador Fiscal CIEP — los otros dos existen sustantivamente sólo en la Capa 4 y su governance formal está pendiente. Renombra §6 a "Las herramientas web públicas" (plural). Reescribe §6.1 con la tabla de los tres simuladores (URL, audiencia natural, governance formal). Inserta nuevo §6.2 "La infraestructura dual: Cloudways e IONOS" que documenta a) qué es cada proveedor en lenguaje accesible, b) qué activo CIEP vive en cada uno (Cloudways: sitio principal `ciep.mx` + micrositios + sub-canal Stata del Fiscal; IONOS VPS: los tres sitios HTML), c) introduce a **Daniel Orduña** como primer colaborador externo formal del CIEP en infraestructura web con acceso administrativo a Cloudways pero no a IONOS, y d) registra la decisión pendiente sobre consolidar el sub-canal Stata del Fiscal en IONOS, con pros y contras enumerados. Renumera §6.2→§6.3 (Mismo motor), §6.3→§6.4 (Versionado), §6.4→§6.5 (Sub-canal web HTML), §6.5→§6.6 (Sub-canal Stata `net from`), y actualiza todas las referencias cruzadas correspondientes. Agrega cuatro filas a §7: governance formal del Simulador IEPS al tabaco; governance formal del Simulador de tenencia vehicular; decisión de migración del sub-canal Stata de Cloudways a IONOS; política formal del rol "colaborador externo de infraestructura". Agrega entrada **"Simuladores CIEP"** al Glosario CIEP en `.windsurfrules` como sustantivo colectivo plural. |
| 2026-05-15 | 1.4     | Iteración de precisión sobre v1.3 — sin expandir alcance del documento ni agregar capas o componentes nuevos. Tres clarificaciones articuladas por el equipo del CIEP: (1) **Repositorios Git independientes de los tres Simuladores CIEP.** La v1.3 sugería implícitamente que los tres compartían una arquitectura técnica unificada (un solo "Código del Simulador"); v1.4 aclara que cada simulador tiene su propio repositorio Git con desarrollo paralelo — el Simulador Fiscal CIEP en `github.com/rcantuc/SimuladorCIEP`, el Simulador IEPS al tabaco y el Simulador de tenencia vehicular en repositorios propios separados. Comparten código por reuso histórico (el código del Fiscal sirvió de base inicial para los otros dos) pero no por dependencia activa: cada uno tiene su propio ciclo de commits, etiquetas, versiones y decisiones metodológicas. La governance formal documentada en este documento corresponde al repositorio del Simulador Fiscal CIEP específicamente; cuando se extienda a los repositorios de IEPS y tenencia, será trabajo concreto en cada uno, no aplicación automática. (2) **Definición formal de "Ecosistema CIEP"** como término institucional: conjunto completo de productos digitales (Simuladores CIEP + **Micrositios** + sitio principal `ciep.mx`) + infraestructura (hosting Cloudways/Hostinger, VPS IONOS) + dominios `*.ciep.mx`. Punto clave: la infraestructura es **parte** del Ecosistema, no su contexto externo. La governance del Ecosistema CIEP incluye decisiones sobre hosting, dominios y credenciales, no solo sobre productos publicados. (3) **Política de registro formal vs. coloquial.** La documentación formal usa términos cortos y técnicos (Simuladores CIEP, Ecosistema CIEP, Micrositios); la conversación y comunicación al público pueden usar formas descriptivas (Simuladores fiscales CIEP, Ecosistema digital del CIEP, Micrositios narrativos). Ninguno está mal; cada uno tiene su lugar. Cambios concretos en el documento: agrega nota "Ubicación en el Ecosistema CIEP" al inicio de la cabecera; amplía §1 con párrafo nuevo "Repositorios Git independientes" antes del diagrama; agrega columna "Repositorio Git" a la tabla de §6.1; agrega subsección nueva "Sobre el registro formal vs. coloquial" antes de la bitácora. Las entradas del Glosario CIEP correspondientes (**Ecosistema CIEP**, **Micrositios** y actualización de **Simuladores CIEP**) viven en `.windsurfrules` y se actualizan en commit separado, siguiendo el precedente de v1.3. |
| 2026-05-23 | 1.5     | Registro de decisión arquitectónica: migración del sub-canal de datos del Simulador Fiscal CIEP desde URLs permanentes de Dropbox hacia GitHub Releases. La decisión se asienta en esta bitácora sin modificar todavía las secciones del documento principal (§6.5, §6.6, §7); esas modificaciones quedan pendientes para una v1.6 que cerrará la migración cuando la ejecución esté completa. La decisión proviene de dos motivaciones: (1) el mecanismo Dropbox dejó de funcionar desde clientes HTTP de Stata (descarga zips corruptos con "falta el head"), aunque sigue funcionando desde browser — causa probable: cambio reciente de policy de Dropbox respecto a interstitials o User-Agent; (2) la migración elimina la dependencia del Simulador respecto a una cuenta personal de Dropbox y la sustituye por infraestructura institucional pública (GitHub Releases del repo `rcantuc/SimuladorCIEP`), reduciendo bus factor y robusteciendo reproducibilidad. Alcance preciso: 23 URLs únicas distribuidas en cuatro archivos del repo (`01_modulos/households/Expenditure.do`, `Stata net/PEF.ado`, `Stata net/DatosAbiertos.ado`, `Stata net/LIF.ado`), inventariadas en un archivo de discovery temporal que se migrará a `governance/` al cerrar la migración. El archivo `01_modulos/households/Expenditure_PTLAC.do` queda fuera de alcance por ser código legacy. La fase preparatoria de esta migración fue la externalización del token BIE/INEGI, completada en los commits `f87b1e1` (introducción del patrón `set_token.do` y plantilla `set_token.template.do` gitignored, blindados por dos asserts adicionales en `verify_gitignore.sh`) y `4d6d39f` (fixes funcionales por cambios INEGI 2025), publicados en GitHub mediante `git push --force-with-lease` tras el rewrite de historia que purgó la credencial expuesta y los binarios pesados (`.git` de 5.1 GB → 49 MB, 1100 → 1044 commits). Fases planeadas para la migración: documentar arquitectura del sub-canal en detalle, poblar `raw/` desde Dropbox, generar `raw/manifest.json` con SHA-256, crear release v7.0 con assets, migrar código del Simulador con verificación SHA y test end-to-end. Estado al momento de registrar esta entrada: decisión tomada, ejecución en curso. |
| 2026-05-24 | 1.6     | Cierre del ciclo de migración Dropbox → GitHub Releases (decisión arquitectónica registrada en v1.5). Tras tres sesiones de trabajo distribuidas en las fases 1-8 del roadmap de migración, el sub-canal de datos del Simulador opera bajo infraestructura institucional: los binarios pesados (PEFs, CPs, ENIGH, LIFs, ISRInformesTrimestrales, CuotasISSSTE) viven como assets del release v7.0 en GitHub Releases del repo público; el código del Simulador los descarga vía `ensure_asset.ado` que consume `manifest.json` con verificación SHA-256. Eliminación de la dependencia respecto a la cuenta personal de Dropbox del investigador principal; reducción de bus factor; trazabilidad institucional completa. Commits que materializaron el cierre: `dfcf424` (introduce ensure_asset.ado), `63adbe0` (reubica manifest del raw/ al root del repo, ensure_asset v1.0 → v1.1), `88c34cb` (refactor de los .ado del Simulador a usar ensure_asset, eliminando URLs hardcoded a Dropbox), `2daadf8` (elimina las copias .ado del directorio Stata net/, conservando .pkg y .toc; cambio de convención sobre el canal staging), `a6ed606` (aplica la convención legacy/ ya establecida al archivo Expenditure_PTLAC.do), `6a56b51` (cleanup operativo: corrige orden de sysdir en SIM.do, comenta global update por default, elimina cuadro_inversion.tex errante). Tres decisiones arquitectónicas derivadas se cristalizaron durante el cierre: (1) el `manifest.json` vive en el root del repo, no en `raw/`, porque es artefacto institucional inmutable y no cache descartable; (2) los .ado del Simulador viven solo en repo root, no en `Stata net/` — la doble copia con sincronización manual se desincronizaba con frecuencia y el patrón se abandonó; (3) la convención `legacy/<categoria>/` queda formalmente reconocida para artefactos preservados pero no mantenidos activamente. Modifica §6.6 (sub-canal Stata `net from`) reflejando que el directorio `Stata net/` solo conserva `.pkg` y `.toc`, y que el mecanismo de publicación al servidor queda como pendiente institucional; §7 (lo que NO está implementado todavía) mueve la migración Dropbox → GitHub Releases de pendiente a implementado, e introduce pendientes nuevos. Introduce nueva sección "Comportamientos no obvios y troubleshooting" con cuatro gotchas inaugurales del entorno técnico capturados durante el trabajo de las fases 5-8. |
| 2026-05-25 | 1.7     | Clarificación de scope: §7 (Lo que NO está implementado todavía) se enfoca en pendientes del Simulador Fiscal CIEP específicamente. Se eliminan cuatro filas que correspondían a pendientes del Ecosistema CIEP completo y se trabajan en proyecto separado: governance formal del Simulador IEPS al tabaco; governance formal del Simulador de tenencia vehicular; decisión sobre migración del sub-canal Stata `net from` de Cloudways a IONOS; política formal del rol "colaborador externo de infraestructura". Algunos otros componentes de §7 mantienen dependencias institucionales del Ecosistema (gestor de secretos del CIEP, documentación SSL del sitio web, procedimiento de actualización del sitio web): se conservan porque describen brechas operativas del Simulador, pero su resolución completa requiere construcción institucional fuera del alcance de este documento. Cambio concreto en el documento: cuatro filas eliminadas en §7 + párrafo de framing al inicio de §7 reconociendo el scope enfocado y mencionando las dependencias institucionales. §6.1 y §6.2 no se modifican: siguen siendo contexto pertinente para entender la posición del Simulador Fiscal CIEP dentro del Ecosistema CIEP, no son pendientes en sí mismos. |
| 2026-06-18 | 1.8     | Cierre del ciclo de implementación del sub-canal Stata público del Simulador Fiscal CIEP, introducción del wrapper de publicación `publicar.sh`, y aprendizaje arquitectónico institucional sobre el modelo de la Carpeta del Simulador para investigadores. Tres bloques de trabajo distribuidos en tres sesiones (mayo 24, mayo 30, junio 18 de 2026) materializan el cierre: (1) **Implementación del sub-canal Stata público al endpoint Cloudways**. Hasta la sesión de mayo 24, la publicación al endpoint `https://ciep.mx/simuladorfiscal/` carecía de proceso definido tras la eliminación del staging manual `Stata net/` (commit `2daadf8` de v1.6). Los commits `c9bdc47` (introduce `publicar-endpoint.sh` y `manifest-endpoint.toml`), `d468b18` (completa migración `Stata net/` → root, corrige manifiesto tras hallazgos del primer dry-run; **tag v8.0**) y `4414e18` (aplica permisos rsync `--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r` para evitar HTTP 403 en Apache) cierran ese pendiente institucional. El deploy v8.0 al endpoint fue validado end-to-end mediante `net from https://ciep.mx/simuladorfiscal/` desde Stata externo al CIEP, confirmando los 8 paquetes declarados en el manifiesto. (2) **Introducción de `publicar.sh` wrapper con sub-comandos `release`, `internos`, `todo`**. Los commits `60fffa3` (introduce `publicar.sh`), `86c4756` (auto-detección inicial de Carpeta vía `find` recursivo) y `cad03b7` (reemplazo del `find` por array de candidatos típicos tras hallazgo de cuelgues en `$HOME` con cloud providers) construyen el wrapper que orquesta el flujo completo de publicación. Sub-comando `release` invoca `publicar-endpoint.sh`; sub-comando `internos` sincroniza a la Carpeta de investigadores; sub-comando `todo` combina ambos. (3) **Reclone correctivo de la Carpeta de investigadores y blindaje del repo contra carpetas operativas**. Los commits `75dc849` (gitignora `.devin/`, sucesor de Windsurf como IDE agent) y `60495ad` (gitignora `_backups/` generado por `publicar.sh internos`) blindan el repo contra commits accidentales de carpetas operativas. La operación de reclone correctivo en sí (junio 11) restauró el clon Git de la Carpeta de investigadores tras descubrirse divergencia masiva de 1100 vs 1064 commits respecto al repo de producción, causada por rsync del K-fix-2 sobre el working tree del clon Git. **Aprendizaje arquitectónico institucional clave** emergente del proceso: la Carpeta del Simulador para investigadores (`Dropbox-CIEP/SimuladorCIEP`) **es un clon Git del repo de producción**, no un destino independiente que recibe archivos sincronizados. El sub-comando `publicar.sh internos` construido en esta sesión usa `rsync` con excludes — modelo arquitectónico incorrecto que funciona accidentalmente porque los excludes replican aproximadamente lo que daría un `git pull`. Decisión consciente de documentar el modelo institucional correcto **antes** del rediseño del código: el aprendizaje arquitectónico no debe perderse en memoria mientras se espera al rediseño técnico. Cambios concretos al documento en este commit: §3.2 reemplaza el contrato preliminar de `publicar.sh` con el contrato real de la implementación de tres sub-comandos (incluyendo declaración explícita de que `internos` usa modelo arquitectónico actual rsync vs. correcto `git pull` documentado en §6.7); §6.6 actualiza el subpárrafo "Estado actual del mecanismo de despliegue al endpoint" para reflejar que el sub-canal Stata público funciona end-to-end y describe el primer deploy genuinamente reproducible (v8.0); §6.7 nuevo "Modelo de la Carpeta del Simulador para investigadores" articula el modelo institucional correcto (clon Git con `git pull`), las dos consecuencias institucionales (sincronización correcta es `git pull`; cada investigador tiene espacio personal gitignored en `users/<usuario>/`), y la disonancia presente con el código actual (rsync con excludes); §7 pivota la fila de `publicar.sh` de "no implementado" a "implementado parcialmente" reconociendo la disonancia, elimina las filas de `publicar-endpoint.sh` y `manifest-endpoint.toml` (ya implementados), elimina el contrato funcional preliminar de `publicar-endpoint.sh` al final de la sección (su contrato real vive ahora en §3.2 y §6.6), y agrega fila nueva sobre el rediseño pendiente de `publicar.sh internos` con modelo `git pull` (incluyendo descripción técnica del rediseño y señales que harían urgirlo); sección "Comportamientos no obvios y troubleshooting" expande de 4 a 9 gotchas con cinco nuevos: permisos rsync `--chmod` para evitar HTTP 403 en Apache; `find` recursivo en `$HOME` que se cuelga indefinidamente con cloud providers; Dropbox revierte renames locales que el cloud aún no propagó; Terminal macOS sin Full Disk Access falla al listar Desktop/Documents/Downloads pero accede archivos por path absoluto; zsh sin `setopt interactive_comments` rompe bloques de comandos pegados con `#`. |
| 2026-06-19 | 1.9     | Decisión de governance: eliminar el sub-comando `publicar.sh internos` en favor del procedimiento manual del investigador principal como owner del clon Dropbox-CIEP/SimuladorCIEP. Trasfondo: en commit J (v1.8) se documentó la disonancia entre el modelo arquitectónico correcto (Carpeta como clon Git, sincronización via `git pull`) y el código de `publicar.sh internos` (rsync con excludes que funcionaba accidentalmente). Esa disonancia quedó como pendiente para rediseño con modelo git pull. Iteración subsiguiente reconoció que la complejidad de un script automatizado no se justifica para una operación unipersonal de baja frecuencia: el investigador principal es el único operador que mantiene la Carpeta sincronizada, hace `git pull` directamente desde su clon en su Mac, y Dropbox propaga al equipo. El modelo manual respeta naturalmente la integridad Git del clon y los archivos locales del investigador en `users/<usuario>/`. Cambios concretos en este commit: (1) `publicar.sh` reescrito de wrapper con 3 sub-comandos (release/internos/todo, 351 líneas) a script monolítico de propósito único (publica al endpoint público, ~150 líneas); el flag `--skip-backup` desaparece junto con la lógica de backup tar.gz; la variable `CARPETA_INVESTIGADORES_PATH` y su auto-detección dejan de aplicar. (2) `endpoint-credentials.template.sh` elimina la línea de `CARPETA_INVESTIGADORES_PATH` (ya no aplica). (3) `governance/deploys/carpeta-investigadores.log` eliminado (ya no se genera). (4) §3.2 reescrito como tabla única para `publicar.sh` sin sub-comandos, con nota explícita sobre qué NO hace el script (la Carpeta). (5) §6.7 actualizado: la "disonancia documento↔código" desaparece; en su lugar, descripción del procedimiento manual del investigador principal como owner del clon. (6) §7 elimina la fila "Rediseño de `publicar.sh internos` con modelo `git pull`" (ya no es pendiente — se resolvió eliminando el sub-comando, no rediseñándolo). |
| 2026-07-03 | 1.10    | Cadena de reproducibilidad end-to-end del Simulador Fiscal CIEP y limpieza de setup. El trabajo de v1.8 declaró v8.0 como "primera versión institucional completa" pero la reproducibilidad prometida no se había materializado — la Release v8.0 en GitHub no existía (solo el tag), `manifest.json` seguía apuntando a v7.0, no había changelog, y `profile.do` no mostraba versión al investigador. La cadena de "código + datos + changelog + visibilidad" estaba rota en varios eslabones. Cinco bloques de trabajo distribuidos en dos sesiones (julio 3 de 2026): (1) **Cierre del sidecar de v8.0** (commit `aec0e45`). Crear la Release v8.0 en GitHub, subir los 23 assets del data sidecar, actualizar `manifest.json` v7.0 → v8.0 con URL y timestamp nuevos. Descubrimiento durante el proceso: `convenciones-git.md` §3.3 y `arquitectura-distribucion.md` mencionaban `raw/manifest.json`, pero la decisión institucional documentada en la bitácora v1.6 y el código de `ensure_asset.ado` establecen que `manifest.json` vive en la raíz del repo. Se corrigieron 5 referencias en documentos vivos para reflejar la decisión real (la cita al `§4` inexistente también se corrigió a `§3.3`). (2) **Bloque 1.5 en `profile.do` + creación de `CHANGELOG.md`** (commit `63fad39`). `CHANGELOG.md` creado con entradas históricas de v7.0 (2026-05-23, "Data sidecar publicado — transición v7.x → v8.0") y v8.0 (2026-05-29, "Primera versión institucionalmente replicable"). Formato Keep A Changelog adaptado con secciones "Institucional" que capturan honestamente que v8.0 es ruptura institucional, no metodológica (fuentes de datos iguales a v7.0). Nuevo bloque "1.5 VERSIÓN Y CAMBIOS" en `profile.do` con lógica en Python (requiere Stata 17+ con `python:` block): lee `manifest.json` de `sysdir_site` para versión, lee `CHANGELOG.md` para cambios, compara con state file por usuario para decidir modo (welcome / update / silent), actualiza state file al final, emite locals Stata para renderizado con estilo `di in y`. Bloque envuelto en `capture` para fallar silenciosamente en máquinas sin Python. (3) **UX fixes al banner** (commits `eb1be68`, `3267868`). Sanitización de Markdown en el bloque Python: `**...**` → `{bf:...}`, backticks eliminados, `### Título` → `TÍTULO` en mayúsculas. Corrección de color: líneas del changelog en `y` (data variable) en vez de `g` (texto fijo), respetando convención institucional del `profile.do`. Newline vacío insertado antes de encabezados en mayúsculas para legibilidad. (4) **Acumulación entre versiones y state file en `users/<username>/`** (commit `d9cb0bf`). Descubrimiento del problema: la lógica original solo mostraba cambios de la versión actual. Un investigador que estuvo desconectado 2 versiones (v7.0 → v8.2) veía solo v8.2, perdiendo v8.0 y v8.1. Rediseño del bloque Python para acumular entradas del CHANGELOG entre `previous_version` (exclusivo) y `sim_version` (inclusivo), respetando límite de 25 líneas totales. Cada versión acumulada se renderiza con header propio en negrita para separación visual. State file migrado de `~/.simulador_ciep_state` a `<sysdir_site>/users/<username>/.simulador_state` — respeta la convención institucional del directorio `users/` como espacio personal, elimina la posibilidad de colisión entre proyectos (SimuladorCIEP vs SimuladorCoNL). El directorio `users/<username>/` se crea automáticamente si no existe. (5) **Refactor del setup** (commit `c840d2a`). Descubrimiento durante trabajo del Bloque 4: `SIM.do` contenía hardcode `if c(username) == "ricardo"` que sobreescribía `sysdir set SITE` para el path personal del investigador principal, y `global id = "ciepmx"` como identidad institucional distinta al username del Mac. Decisión de simplificación radical: la identidad del investigador principal es su username del Mac (`ricardo`), sin override institucional. `SIM.do` limpio: sin `sysdir set SITE` hardcode, sin `global id`. Ambos ahora responsabilidad exclusiva de `profile.do` (que define `global id = c(username)`) y de `/Applications/StataNow/sysprofile.do` personal del investigador (fuera del repo). `sysprofile.do` del repo renombrado a `sysprofile-template.do` para dejar claro que es plantilla, no configuración funcional. `FiscalGap.ado` líneas 97 y 351: `users/ciepmx/bootstraps/` → `users/ricardo/bootstraps/` — bug histórico que hacía fallar `FiscalGap` para cualquier investigador que no fuera el principal. Cambios documentales concretos de esta entrada: `convenciones-git.md` §3.3 con 3 correcciones de path del manifest; `arquitectura-distribucion.md` con 2 correcciones de path del manifest, actualización de la fila del sysprofile en §7 para reconocer que ya existe `sysprofile-template.do`, y fila nueva en §7 sobre estrategia de versionado del `simulador.stpr` (gitignored porque revela paths absolutos del disco del investigador principal). Cuatro aprendizajes institucionales registrados: (a) la cadena de reproducibilidad end-to-end requiere sincronía entre 4 artefactos (GitHub Release, manifest.json, CHANGELOG.md, profile.do); cualquier eslabón desalineado rompe la promesa institucional; el próximo bump de versión debe operar todos los eslabones simultáneamente; (b) la divergencia entre clones desarrollo/Dropbox es fricción operativa real — cuando editas `profile.do` en el clon de desarrollo, Stata sigue leyendo el `profile.do` viejo del clon Dropbox hasta que se hace commit + push + git pull; probar en Stata solo después del pull en el clon Dropbox; (c) el bloque `python:` de Stata es sensible a escape sequences en heredoc — usar `chr(10)` en vez de `\n` y `chr(92)` en vez de `\\` evita problemas de layering; (d) rastros de identidad institucional histórica (`ciepmx` como global id, hardcodes de path del investigador principal en código compartido) generan fricción para investigadores no-principal — vale detectarlos y limpiarlos cuando aparezcan. |
| 2026-07-03 | 1.11    | Cierre de la cadena de reproducibilidad desde la perspectiva del publicador + manual del investigador + resolución de auditoría de sincronía .ado/.sthlp. La bitácora v1.10 cerró la cadena desde la perspectiva del investigador que abre Stata (banner de versión, CHANGELOG.md, state file por usuario). Faltaba cerrar la cadena desde la perspectiva del investigador principal que publica una versión nueva (`publicar.sh` sin gates, sin automatización de Release, sin comando para consultar historial completo). También quedaban hallazgos de auditoría de sincronía entre `.ado` y `.sthlp` sin resolver, y el manual del investigador nuevo aún no existía. Ocho bloques de trabajo ejecutados en paralelo entre Devin y Ricardo tras cierre de bitácora v1.10 (julio 3 de 2026): (1) **Manual del investigador** (commit `4f1f79b`). Devin redactó `manuales/manual-investigador-ciep.md` (416 líneas, 9 secciones; movido después a `help/manual-investigador-ciep.md`), redactado para el perfil económico no-programador. Incluye qué es el Simulador, cómo empieza a usarlo un investigador nuevo, día a día, comandos principales, convenciones, versionado, reproducibilidad, troubleshooting, y recursos. (2) **Auditoría de sincronía .ado ↔ .sthlp** (commit `fe7fcc8`). Devin auditó los 10 pares (comandos institucionales del Simulador) y produjo `governance/auditoria-drift-sthlp.md` con checklist de 5 puntos por comando y clasificación de severidades. Detectó hallazgos rojos (opciones documentadas pero no existentes) y amarillos (opciones sin documentar). (3) **Correcciones iniciales a .sthlp** (commit `5597ff7`). Devin corrigió los hallazgos evidentes (rutas `06_helps/` → `help/Stata/`, defaults erróneos en `LIF minimum`, `PIBDeflactor aniomax`, `Poblacion aniofinal`) sin tocar los hallazgos que requerían decisión del investigador principal. (4) **Resolución final de auditoría** (commit `f7580ab`). Devin implementó las decisiones que Ricardo tomó sobre los hallazgos pendientes: (a) `SCN.ado` gana opción real `ANIOMAX(int 2050)` que controla solo el eje horizontal de las gráficas; (b) `PEF.ado` elimina las opciones muertas `pef/ppef/aprobado` (declaradas pero nunca consumidas); (c) `DatosAbiertos.ado` implementa `pibvp()`, `pibvf()`, `files` según semántica dictada por el investigador principal; (d) los 10 `.ado` y los 10 `.sthlp` reciben `*! version 8.0 CIEP 03jul2026`, unificando el versionado con la versión pública del Simulador — decisión institucional: paremos el número de versión del `.ado` con la versión pública del Simulador, no con contadores propios de cada archivo; (e) `SCN.sthlp`, `GastoPC.sthlp`, `DatosAbiertos.sthlp` actualizados al comportamiento real; (f) `profile.do` deja de anunciar la opción `MES` en la línea de `DatosAbiertos` (esa opción nunca existió en el .ado); (g) manual actualizado con referencia a `sysprofile-template.do` (post-c840d2a); (h) auditoría documenta la resolución de cada hallazgo con fecha, dejando rastro de las decisiones tomadas. (5) **Gates de validación en publicar.sh** (commit `f3b1d38`). Devin agregó tres gates que abortan `publicar.sh` antes de tocar tag, Release, o endpoint: Gate 1 valida que `CHANGELOG.md` contenga entrada `## [<VERSION>] — YYYY-MM-DD` para la versión que se publica; Gate 2 valida que el tag Git sea anotado (no lightweight) y con mensaje no vacío usando `git for-each-ref`; Gate 3 valida que `manifest.json` esté sincronizado en `version`, `release_tag` y `release_url_prefix`. Los 3 gates ejecutan antes de cualquier acción destructiva. También se agrega flag `--check` que ejecuta solo los gates sin acciones, acumulando fallas de los 3 en un solo output (no aborta al primer error para ser útil como herramienta de diagnóstico), y que NO corre `verify_repo_state` para que un working tree sucio durante desarrollo no bloquee el `--check`. (6) **Automatización de GitHub Release en publicar.sh** (commit `3011d18`). Devin agregó tres pasos entre el push del tag y la invocación de `publicar-endpoint.sh`: (a) `release_create()` crea la Release en GitHub extrayendo las notas de la sección correspondiente del CHANGELOG.md (inclusivo → exclusivo con `awk`); si la Release ya existe, se omite sin sobrescribir (no destructivo); (b) `assets_upload()` sube los assets listados en `manifest.assets` con `gh release upload`, pre-chequea existencia local de todos los archivos (aborta con lista completa de faltantes antes de subir nada), omite assets ya subidos comparando `gh release view --json assets` con el manifest para idempotencia, verifica conteo final Release vs manifest; (c) `release_post_verify()` descarga cada asset de vuelta, calcula SHA-256, compara contra `manifest.assets[i].sha256`, drift genera WARN (no aborta) con registro en `02_governance/deploys/endpoint-stata.log` con formato `<TIMESTAMP> <VERSION> <sha-corto> <usuario> RELEASE-VERIFY OK|DRIFT|SKIPPED`. Se agrega flag `--skip-post-verify` para saltar este paso cuando ya se verificó una versión previa (evita descargar 1.3 GB de vuelta en republish o re-ejecución). (7) **Comando sim_changelog en Stata** (commit `9fa2c5e`). Devin creó `sim_changelog.ado` en el root del repo que lee `CHANGELOG.md` desde `sysdir_site` y renderiza todas las entradas o una versión específica según opción `version()`. Aplica la misma sanitización del bloque 1.5 (`**texto**` → `{bf:texto}`, `### Título` → `TÍTULO` en mayúsculas, backticks fuera). Diferencia clave vs el bloque 1.5: en vez de acumular en un local Stata con límite de 25 líneas, imprime línea por línea con `sfi.SFIToolkit.displayln()` desde Python, renderizando SMCL sin límite. Se crea `help/Stata/sim_changelog.sthlp` con formato del canon. Se agrega el comando al bloque de bienvenida de `profile.do` como línea clickable. Cartucho institucional del `.ado` sigue la nueva convención: línea `*! version 8.0 CIEP 03jul2026` arriba (parseable por Stata) + `Version:` y `Última actualización:` dentro del cartucho con 4 espacios de sangría y ancho fijo 45 caracteres. (8) **Alineación de cartuchos institucionales pre-existentes** (commit `5847542`). Ricardo detectó que los cartuchos de `PIBDeflactor.ado`, `Poblacion.ado`, `SCN.ado` (los 3 `.ado` que ya tenían cartucho institucional antes de esta sesión) quedaron descoordinados tras el commit `f7580ab`: la línea `*! version 8.0 CIEP 03jul2026` apareció encima del cartucho pero el cartucho seguía mostrando `Fecha:` con valores desactualizados (agosto 2025, octubre 2022), sin `Version:` ni `Última actualización:` dentro. Corregido con Python que: (a) elimina línea `*!*** Fecha: ... ****`; (b) inserta antes del último renglón vacío del cartucho las dos líneas `Version: 8.0` y `Última actualización: 03jul2026` con 4 espacios de sangría, ancho 45 caracteres, alineación derecha uniforme. Validaciones ejecutadas al cierre: `publicar.sh v8.0 --check` los 3 gates pasan, exit 0; `publicar.sh v8.0.1 --check` y `v99.0 --check` los 3 gates reportan fallas acumuladas con mensajes instructivos por gate, exit 1; `sim_changelog` sin argumentos renderiza CHANGELOG completo con v8.0 y v7.0 correctamente formateados; `sim_changelog, version(v8.0)` y `version(v7.0)` filtro por versión funciona; `sim_changelog, version(v99.0)` error 198 con mensaje instructivo; `which sim_changelog` encontrado en `sysdir_site` con cartucho institucional bien formado. Cuatro aprendizajes institucionales registrados: (a) trabajo en paralelo con Devin sin conflictos es viable cuando los alcances de archivos no se solapan y ambas partes hacen `git pull` frecuente y explícito — en esta sesión Frente B y Sesión 3 corrieron concurrentemente ~2 horas sin merge conflicts porque tocaron áreas distintas del repo; la única colisión potencial en `profile.do` (línea del banner) se resolvió porque Devin S3 hizo `git pull` justo antes de editar y encontró la versión post-Frente B que ya tenía el fix de MES aplicado; (b) detección temprana de inconsistencias en formato institucional ahorra trabajo — cuando Ricardo vio el cartucho descoordinado tras commit `f7580ab`, la corrección quedó como commit adicional (Sesión 3 ya había pusheado y bloqueaba `git commit --amend`); si el problema se hubiera detectado semanas después con múltiples versiones intermedias, el fix habría requerido tocar más archivos; (c) los gates institucionales de `publicar.sh` transforman la cadena de reproducibilidad de declarativa a operacional — ya no depende de que el investigador principal recuerde actualizar `CHANGELOG.md`, crear tag anotado, o sincronizar los 3 campos de `manifest.json`; el costo de olvidar algo se paga en el `--check` local, no en un deploy roto; (d) la decisión de unificar `*!` de los `.ado` con la versión pública del Simulador (v8.0, no contadores propios) establece regla institucional durable: cada vez que se toque un `.ado`, el `*!` se actualiza al número del Simulador vigente en ese momento; los `.sthlp` también migraron a esta convención en el mismo commit para no tener dos numeraciones paralelas. |
| 2026-07-04 | 1.12    | Reorganización estructural del root del repo con convención de prefijos. Se formaliza la convención institucional: directorios con prefijo numérico (`01_modulos/`, `02_governance/`, `03_help/`, `04_simuladorfiscal.ciep.mx/`, `05_scripts/`) son permanentes; directorios sin prefijo (`master/`, `raw/` con `raw/temp/`, `users/`) son restablecibles y regenerables por el pipeline. Movimientos: `governance/` → `02_governance/` (incluye `CHANGELOG.md`); `help/` → `03_help/`; `simuladorfiscal.ciep.mx/` → `04_simuladorfiscal.ciep.mx/`; `publicar.sh`, `publicar-endpoint.sh`, `endpoint-credentials.template.sh`, `manifest.json`, `manifest-endpoint.toml` y los 7 `.pkg` → `05_scripts/`; `temp/` → `raw/temp/`; `users/ciepmx/` → `users/ricardo/`; los `.do` sueltos del root → `01_modulos/` (análisis vivo) o `01_modulos/legacy/` (históricos, junto con 5 schemes retirados); los sub-directorios de `01_modulos/` (`households/`, `profiles/`, `tax_models/`, `visualizations/sankey/`) se aplanan. Schemes renombrados sin el prefijo `ciep`: `ingresos`, `deuda`, `cuidados`, `educacion`, `energia`, `salud` (`ciepdeuda2` se retira a legacy; sus usos en `SIM.do` pasan a `deuda`). Los `.ado` del canon, `scheme-*.scheme` y los `.do` de arranque quedan en root porque Stata los busca ahí vía `adopath ++SITE`. Referencias actualizadas en todas las capas vivas: `SIM.do`, `profile.do`, `ensure_asset.ado`, `sim_changelog.ado`, los `.ado` del canon (paths `temp/` → `raw/temp/`), `Web.Stata.do`, los scripts de publicación (gates y rutas), `manifest-endpoint.toml`, `verify_gitignore.sh`, `.gitignore` (patrón del servidor de producción y cobertura de `05_scripts/endpoint-credentials.sh`), README, manual del investigador y este documento (nueva §2.8 con la convención). Se restauraron los 3 registros congelados de `02_governance/historico/` que el move manual había dejado fuera del working tree. Las bitácoras y registros históricos conservan los paths antiguos como testimonio. |
