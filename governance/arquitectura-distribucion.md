# Arquitectura de distribución del Simulador Fiscal CIEP

**Naturaleza del documento:** describe la arquitectura **objetivo** del Simulador como sistema de cuatro capas. Varios componentes (los scripts `publicar.sh` y `reproducir.sh`, el banner enriquecido de `profile.do`, el archivo `CHANGELOG.md`, el comando `sim_changelog`, la firma de versión en outputs, la documentación operativa del sitio web) aparecen aquí descritos por su contrato funcional pero aún no están implementados. La sección 7 lista honestamente lo que falta y en qué fase se construye cada cosa. Si lees este documento hoy y abres Stata hoy, vas a ver el Simulador funcionando como siempre — la arquitectura completa aquí descrita se construye en fases siguientes.

**Para quién es este documento:** cualquier persona que interactúe con el Simulador. Investigadores CIEP que lo usan como herramienta, el investigador principal que lo desarrolla, investigadores colaboradores que se sumen al mantenimiento, lectores externos que necesiten reproducir un análisis publicado, o usuarios externos que entran al sitio web público.

**Qué encuentras aquí:** cómo está organizado el Simulador como sistema vivo. No es un solo producto con una sola audiencia; son cuatro capas con audiencias y mecanismos distintos que comparten un solo motor de cálculo.

**Cuatro preguntas que este documento responde:**

1. *Si soy investigador del CIEP y nunca he tocado Git, ¿cómo uso el Simulador en mi día a día?* → Sección 2.
2. *Si voy a publicar una versión nueva al equipo, ¿qué tengo que hacer?* → Sección 3.
3. *Si necesito reproducir exactamente lo que el Simulador produjo cuando se publicó un análisis hace año y medio, ¿cómo lo hago?* → Sección 5.
4. *¿Cómo se relaciona el Simulador en Stata con la herramienta web pública en `simuladorfiscal.ciep.mx`?* → Sección 6.

**Qué NO encuentras aquí:** cómo se hacen commits, ramas o pull requests en el lado de desarrollo. Eso vive en `convenciones-git.md`. Este documento describe la arquitectura completa; el otro describe el detalle operativo de la Capa 1.

---

## Tabla de contenido

1. [La arquitectura en una imagen](#1-la-arquitectura-en-una-imagen)
2. [Para ti, investigador CIEP: cómo se ve el Simulador del día a día](#2-para-ti-investigador-ciep-cómo-se-ve-el-simulador-del-día-a-día)
3. [Para ti, investigador principal: cómo publicar una versión nueva](#3-para-ti-investigador-principal-cómo-publicar-una-versión-nueva)
4. [Qué es "una versión publicada"](#4-qué-es-una-versión-publicada)
5. [Cómo reproducir un análisis publicado](#5-cómo-reproducir-un-análisis-publicado)
6. [La herramienta web pública](#6-la-herramienta-web-pública)
7. [Lo que NO está implementado todavía](#7-lo-que-no-está-implementado-todavía)

---

## 1. La arquitectura en una imagen

*Qué aprendes en esta sección:* por qué el Simulador son cuatro capas distintas y cómo se conectan.

El Simulador no es un solo sistema con una sola audiencia. Es **una pieza de software con cuatro tipos de gente que lo tocan, cada uno con necesidades distintas**: el investigador principal y los investigadores colaboradores que escriben el código; los investigadores CIEP que lo usan como herramienta de análisis fiscal; quien necesita volver a una versión vieja para defender un número publicado; y los usuarios externos (ciudadanos, periodistas, académicos, funcionarios) que entran al sitio web público para simular políticas. Diseñar las cuatro situaciones bajo un solo mecanismo te obliga a hacer concesiones que dañan a todos.

Lo importante es que **las cuatro capas comparten un mismo motor de cálculo**. Lo que cambia es la interfaz hacia cada audiencia y la frecuencia con que cada capa recibe actualizaciones. Por eso un cambio metodológico introducido en la Capa 1 termina, eventualmente, reflejándose en lo que el sitio web público devuelve a un periodista o en lo que un investigador CIEP ve al correr `PEF` en Stata.

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
   │   Distribución │  │   Reproducción │  │   Herramienta web    │
   │   vigente para │  │   histórica    │  │   pública            │
   │   investigadores│ │                │  │                      │
   │                │  │ Audiencia:     │  │ Audiencia: usuarios  │
   │ Audiencia:     │  │ cualquiera que │  │ externos             │
   │ investigadores │  │ necesite una   │  │ (ciudadanos, perio-  │
   │ CIEP           │  │ versión vieja  │  │ distas, académicos,  │
   │                │  │                │  │ funcionarios)        │
   │ Carpeta del    │  │ Carpeta tem-   │  │                      │
   │ Simulador para │  │ poral, descart-│  │ Servidor IONOS,      │
   │ investigadores │  │ able           │  │ dominio raíz:        │
   │ ~/Dropbox-CIEP/│  │ Misma versión  │  │ ciep.mx (URLs        │
   │ SimuladorCIEP/ │  │ que pidió quien│  │ por sub-canal abajo) │
   │ Stata corre    │  │ corrió el      │  │                      │
   │ profile.do al  │  │ script         │  │ Dos sub-canales      │
   │ arrancar       │  │                │  │ (detalle abajo):     │
   │                │  │                │  │ • web HTML           │
   │                │  │                │  │ • Stata `net from`   │
   │                │  │                │  │                      │
   │                │  │                │  │ Versionado alineado  │
   │                │  │                │  │ con la versión       │
   │                │  │                │  │ publicada actual     │
   └────────────────┘  └────────────────┘  └──────────────────────┘
```

Las flechas son direccionales. La Capa 1 es el origen: ahí se escribe el código y se mantienen las decisiones metodológicas. Las otras tres capas reciben actualizaciones distintas: la Capa 2 recibe automáticamente cuando se publica una versión nueva (vía `publicar.sh`); la Capa 3 se invoca puntualmente, bajo demanda, sin calendario fijo; la Capa 4 se actualiza siguiendo un procedimiento del lado web cuando se publica versión nueva — con la particularidad de que esa actualización debe llegar a sus **dos sub-canales**: el sitio HTML interactivo (al que entran usuarios externos sin Stata) y el endpoint Stata `net from` (desde donde un usuario externo que sí usa Stata se instala el Simulador en su propia máquina).

**Detalle de la Capa 4 — los dos sub-canales:**

```
   ┌────────────────────────────┐  ┌────────────────────────────┐
   │ Sub-canal web HTML         │  │ Sub-canal Stata `net from` │
   │                            │  │                            │
   │ Endpoint:                  │  │ Endpoint:                  │
   │ simuladorfiscal.ciep.mx    │  │ ciep.mx/simuladorfiscal    │
   │ (sitio HTML interactivo)   │  │ (sirve stata.toc + .ado)   │
   │                            │  │                            │
   │ Audiencia: usuarios        │  │ Audiencia: usuarios        │
   │ externos sin Stata         │  │ externos que sí usan       │
   │ (ciudadanos,               │  │ Stata (académicos,         │
   │ periodistas)               │  │ analistas)                 │
   │                            │  │                            │
   │ Interfaz: navegador web    │  │ Interfaz: comandos en      │
   │                            │  │ Stata tras `net install`   │
   │ Protocolo: HTTPS + SSL     │  │                            │
   │ (ver §6.4)                 │  │ Despliegue actual: manual  │
   │                            │  │ desde `Stata net/` (§6.5)  │
   └────────────────────────────┘  └────────────────────────────┘
```

Las dos URLs son distintas (la del sub-canal HTML es el subdominio `simuladorfiscal.ciep.mx`; la del sub-canal Stata es la ruta `/simuladorfiscal` del dominio principal `ciep.mx`), pero ambos endpoints corren en infraestructura del CIEP en IONOS y sirven al mismo motor de cálculo. El detalle de cada uno está en §6.4 (web HTML) y §6.5 (Stata `net from`).

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

El mecanismo: `profile.do` define tres globales (`${sim_version}`, `${sim_published_date}`, `${sim_published_hash}`) y los módulos de output las consumen automáticamente. No tienes que hacer nada.

### 2.5 Si necesitas una versión vieja

Si tu análisis depende de una versión específica que ya no es la actual (por ejemplo: estás revisando algo que se publicó hace dos años), no intentes reconstruirla a mano. Usa el procedimiento de la sección 5.

### 2.6 Si abres Stata y NO ves el mensaje de bienvenida del Simulador

El mecanismo que conecta a tu Stata con el Simulador es el `sysprofile.do` de tu instalación personal de Stata, que apunta a la Carpeta del Simulador para investigadores en Dropbox (§2.2). Por eso normalmente abres Stata desde donde sea y ves el banner del Simulador automáticamente.

Si NO ves el banner, lo más probable es que **tu `sysprofile.do` está apuntando a una ruta incorrecta** — por ejemplo, porque la carpeta cambió de ubicación, o porque el setup inicial nunca se hizo bien en tu máquina.

**Diagnóstico rápido.** En Stata escribe:

```
sysdir
```

Eso te muestra las rutas que Stata tiene configuradas. La que importa aquí es `SITE`: debería apuntar a `~/Dropbox-CIEP/SimuladorCIEP/`. Si apunta a otro lado (o no apunta a nada), el problema está en `~/StataNow/sysprofile.do`.

**Cómo se arregla.** Contacta al investigador principal (hoy: Ricardo). El fix es editar `~/StataNow/sysprofile.do` para que la línea `sysdir set SITE` apunte a `~/Dropbox-CIEP/SimuladorCIEP/`. La configuración inicial es responsabilidad tuya; pero no es algo que tengas que pelear solo: pregúntale al investigador principal o a tus compañeros.

---

## 3. Para ti, investigador principal: cómo publicar una versión nueva

*Qué aprendes en esta sección:* el procedimiento exacto para tomar el trabajo terminado en una rama de trabajo y publicarlo como versión nueva al equipo CIEP y a la herramienta web pública.

Esta sección asume que ya conoces las convenciones de Git que usa este repositorio (`convenciones-git.md`). Aquí sólo describimos el flujo de publicación; los detalles de cómo se hacen commits, ramas de trabajo y etiquetas de versión están allá.

### 3.1 Los pasos

1. **Termina e integra tu trabajo en `master`.** Todo lo que entra en una versión publicada tiene que estar en `master` primero. Detalle del flujo de pull request: `convenciones-git.md` §2.

2. **Decide el número de versión.** ¿Es un cambio metodológico de fondo (mayor: `v7 → v8`)? ¿Datos anuales nuevos o módulo nuevo (menor: `v7.0 → v7.1`)? ¿Corrección urgente sobre versión publicada (parche: `v7.0 → v7.0.1`)? Detalle: `convenciones-git.md` §3.2.

3. **Actualiza `CHANGELOG.md` en la raíz del Código del Simulador.** Una entrada nueva con el número de versión, la fecha, y bullets agrupados por categoría:
   - **Cambios metodológicos** (afectan resultados — los lectores del Simulador tienen que verlos).
   - **Datos actualizados** (qué fuentes se subieron de versión).
   - **Funcionalidad nueva** (módulos o comandos nuevos).
   - **Correcciones de errores**.
   - **Cambios técnicos** (no afectan resultados pero importa documentar).

4. **Crea la etiqueta de versión en Git** (en inglés *tag*, un marcador permanente sobre un commit específico) sobre el commit correspondiente: `git tag -a v7.2 -m "v7.2 — descripción corta"`. Detalle: `convenciones-git.md` §3.3.

5. **Sube la etiqueta al remoto** (en inglés *push*): `git push origin v7.2`.

6. **Crea la Publicación en GitHub** (en inglés *Release*) apuntando a la etiqueta, con el changelog y los archivos de datos pesados que correspondan a la versión. El Catálogo de datos asociados (`raw/manifest.json`) se actualiza con las huellas digitales de los archivos subidos. Detalle: `convenciones-git.md` §3.3 paso 2.

7. **Ejecuta `publicar.sh v7.2`** (cuando exista — ver §7). El script copia desde tu carpeta de desarrollo a la Carpeta del Simulador para investigadores, eligiendo qué archivos van y cuáles no.

8. **Actualiza la herramienta web pública** con la nueva versión. Procedimiento separado descrito en §6. Asegúrate de que el sitio en `simuladorfiscal.ciep.mx` quede sirviendo `v7.2` y no la versión previa.

9. **Verifica con un investigador de prueba.** Borra tu archivo de estado local (`~/.simulador_ciep_state`), abre Stata desde la Carpeta del Simulador para investigadores, confirma que el banner muestra `v7.2` con los cambios de la nueva versión. Adicionalmente, entra a `simuladorfiscal.ciep.mx` y verifica que el pie del sitio reporta `v7.2`.

### 3.2 El contrato funcional de `publicar.sh`

Este script todavía no existe (ver §7). Cuando se construya, su contrato es:

| Elemento | Especificación |
|---|---|
| **Entrada** | Un argumento: el número de versión (ejemplo: `v7.2`). El script asume que la etiqueta ya existe en `master` local. |
| **Qué hace** | (1) Verifica que la etiqueta existe y que `master` está limpia. (2) Copia desde el clon de desarrollo a la Carpeta del Simulador para investigadores los archivos que el equipo necesita: `.ado`, `.do`, `profile.do`, `help/`, `scheme/`, `simulador.stpr`, `CHANGELOG.md`. (3) Excluye lo que NO debe ir: `.git/`, `governance/`, `raw/` completo (los datos pesados se distribuyen vía las Publicaciones de GitHub o mecanismo separado). (4) Imprime resumen de archivos copiados y omitidos. |
| **Salida exitosa** | La Carpeta del Simulador para investigadores queda con la versión nueva, `CHANGELOG.md` actualizado, sin restos de versiones previas. Mensaje en consola: *"v7.2 publicada en la Carpeta del Simulador para investigadores. Verifica abriendo Stata."* |
| **Si falla** | Aborta antes de tocar nada en la carpeta destino. Mensaje claro de qué validación falló (etiqueta inexistente, `master` sucia, carpeta destino inaccesible). |

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
| **Qué hace**                  | (1) Clona el Código del Simulador desde GitHub a la carpeta destino. (2) Hace `git checkout v7.0` para dejar el código exactamente como estaba en esa versión. (3) Lee el Catálogo de datos asociados (`raw/manifest.json`, descrito en `convenciones-git.md` §4) y descarga los archivos de datos que corresponden a `v7.0` desde la Publicación de GitHub de esa versión. (4) Verifica las huellas digitales SHA-256 (en inglés *SHA*, un identificador único derivado del contenido del archivo, equivalente a una huella digital) de los datos para confirmar que son los originales. |
| **Salida exitosa**            | Carpeta autocontenida con código + datos de `v7.0`. Mensaje: *"v7.0 reconstruida en `./reproduccion-v7.0/`. Abre Stata ahí y corre `do SIM.do`."*                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **Si falla**                  | Aborta antes de dejar carpeta a medio armar. Mensajes diferenciados: etiqueta de versión no existe, sin conexión a internet, huella digital de algún archivo no coincide (archivo corrupto o modificado en origen).                                                                                                                                                                                                                                                                                                                                                                       |
| **Pre-requisito del usuario** | Tener Git y `curl` (o `wget`) instalados. No tener cuenta de GitHub ni saber Git: el script abstrae todo.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

---

## 6. La herramienta web pública

*Qué aprendes en esta sección:* qué es el sitio en `simuladorfiscal.ciep.mx`, cómo se conecta con las otras capas, y cómo se mantiene segura la conexión con los usuarios externos.

### 6.1 Qué es y para quién

`simuladorfiscal.ciep.mx` es la interfaz web del Simulador. Permite a **usuarios externos** — ciudadanos, periodistas, académicos no afiliados al CIEP, funcionarios públicos — simular el impacto de políticas fiscales **sin necesidad de instalar Stata** ni saber programación. La audiencia es deliberadamente distinta a las otras tres capas: investigadores CIEP no son los usuarios típicos del sitio web (ellos usan Stata directamente, que es más expresivo); el sitio web es para quien necesita explorar resultados sin entrar al modelo en profundidad.

### 6.2 Mismo motor, distintas interfaces

Lo crítico de entender es que **el motor de cálculo del Simulador es uno solo y corre, sin reimplementaciones paralelas, en tres lugares distintos**:

1. **En la instalación local de Stata del investigador CIEP** (Capa 2): los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `FiscalGap`, etc. corriendo desde la Carpeta del Simulador para investigadores.
2. **En la copia remota de Stata del usuario externo que se instaló el Simulador con `net from`** (Capa 4, sub-canal Stata — ver §6.5): los mismos comandos, descargados desde el endpoint público al Stata personal del usuario.
3. **Detrás del sitio HTML interactivo** (Capa 4, sub-canal web — ver §6.4): los mismos comandos invocados por la capa web cuando un usuario externo mueve un control deslizable o llena un formulario.

Cuando un periodista mueve un control en la web para ver el impacto de cambiar la tasa del IVA, el cálculo que se ejecuta es el mismo comando `LIF` que un investigador CIEP corre en Stata o que un académico externo invoca después de hacer `net install LIF` desde el endpoint público. Lo que cambia es la interfaz (formularios y gráficas en la web; consola de comandos en las otras dos); el motor es uno.

Esto importa por una razón: garantiza que los números que ve un usuario externo en el sitio HTML son los **mismos** que los que un investigador CIEP obtiene en Stata, y los **mismos** que los que un académico externo obtiene en su Stata local instalada vía `net from`, para la misma versión publicada. No hay implementaciones paralelas que puedan divergir.

### 6.3 Versionado alineado

El sitio web se versiona en sincronía con el Código del Simulador. Cuando se publica `v7.2` (paso 8 del procedimiento de §3), el sitio web se actualiza a `v7.2`. El pie del sitio muestra explícitamente qué versión está sirviendo, igual que la firma en los outputs de Stata (§2.4). De este modo, si alguien hace una captura de pantalla de un cálculo web y la pone en un artículo periodístico, queda registro de qué versión la produjo.

El procedimiento detallado de actualización del sitio (cómo se hace el despliegue al servidor, cuánto downtime hay, cómo se prueba antes de publicar) está pendiente de documentar (§7).

### 6.4 Sub-canal web HTML

El sub-canal web HTML es el sitio interactivo al que llega un usuario externo cuando teclea `simuladorfiscal.ciep.mx` en su navegador. La audiencia natural son personas que **no usan Stata** (ciudadanos, periodistas, académicos no afiliados al CIEP, funcionarios). La interfaz son formularios, controles deslizables y gráficas; los resultados salen del motor de cálculo del Simulador (§6.2) corriendo detrás del servidor.

**Estado del sub-canal:** existe y funciona hoy. Lo que falta no es construirlo — es documentar formalmente cómo se actualiza con cada publicación y qué hacer si algo falla; esos pendientes viven en §7.

**Componente SSL: por qué importa el candadito del navegador.**

El sitio sirve sobre HTTPS, que es el protocolo seguro que ves en cualquier banco o servicio en línea (el candado a la izquierda de la URL en el navegador). HTTPS se construye sobre **SSL** (un sistema de certificados digitales), que garantiza dos cosas:

- **Privacidad**: la conexión entre el usuario externo y el servidor está cifrada; nadie en la red intermedia puede leer qué consultas hace el usuario ni qué resultados recibe.
- **Autenticidad**: el navegador del usuario verifica, contra una autoridad de certificación externa, que el servidor en `simuladorfiscal.ciep.mx` efectivamente pertenece al CIEP y no es una imitación.

Para que esto funcione, el servidor necesita un **certificado SSL** (archivos digitales que prueban la identidad del sitio) y una **llave privada** (la contraparte secreta que solo el servidor real conoce).

**Política sobre las llaves privadas SSL:**

- **Nunca viven dentro del Código del Simulador.** Esto ya está protegido por el `.gitignore` desde la Acción 3 (`*.key`, `*.pem`, `*.crt` y similares ignorados), pero la política se documenta aquí explícitamente: aunque alguien las copie por error a la carpeta de desarrollo, Git las ignora.
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

La documentación detallada del procedimiento de renovación (comandos exactos, dónde se guarda el certificado en el servidor) es trabajo pendiente (§7). La política completa de gestión de secretos vivirá en `governance/politica-gestion-secretos.md` (pendiente).

### 6.5 Sub-canal Stata `net from`

Hay una segunda forma de llegar al Simulador desde fuera del CIEP que no usa el navegador: un usuario externo **que sí sabe Stata** puede instalárselo en su propia copia de Stata con el comando:

```stata
net from https://ciep.mx/simuladorfiscal/
```

Nótese que esta URL es **distinta** a la del sub-canal HTML (`simuladorfiscal.ciep.mx`): el sub-canal Stata vive en la ruta `/simuladorfiscal` del dominio principal del CIEP (`ciep.mx`), no en el subdominio. Similar, pero no igual.

Cuando ese comando se ejecuta, Stata busca el archivo `stata.toc` (tabla de contenidos) en `https://ciep.mx/simuladorfiscal/stata.toc`. El `stata.toc` declara qué paquetes están disponibles (`PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos`); con `net install <paquete>` Stata descarga los `.ado` y archivos de ayuda correspondientes desde el servidor a la máquina del usuario. A partir de ahí los comandos del Simulador funcionan en esa instalación remota igual que funcionan en la Capa 2.

**Endpoint.** El `stata.toc` y los archivos asociados (`.ado`, `.sthlp`, `.pkg`) se sirven desde `https://ciep.mx/simuladorfiscal/` — una ruta del dominio principal del CIEP. Es una URL **distinta** a la del sub-canal HTML, que vive en el subdominio aparte `simuladorfiscal.ciep.mx`. Ambos endpoints corren en infraestructura del CIEP en IONOS.

**Mecanismo de despliegue actual — manual.** En el Código del Simulador existe una carpeta `Stata net/` que cumple la función de **área de staging local** del investigador principal. Cuando se va a publicar una versión nueva al endpoint, el flujo es:

1. El investigador principal copia desde la raíz del Código del Simulador los `.ado` y `.pkg` que deben publicarse a la carpeta `Stata net/`.
2. Edita el `stata.toc` dentro de `Stata net/` para reflejar la versión nueva y la fecha.
3. Sube el contenido de `Stata net/` al servidor IONOS por SSH/SCP, sobrescribiendo el contenido previo.

A partir de ese momento, cualquier `net from https://ciep.mx/simuladorfiscal/` desde Stata ve la versión nueva.

**Limitaciones reconocidas de este flujo manual:**

- **Sin trazabilidad de qué versión está sirviendo el endpoint.** No hay registro automático de qué se subió ni cuándo; ese dato vive en la memoria del investigador principal.
- **Sin automatización.** El copy-paste manual desde la raíz a `Stata net/` y luego al servidor depende de hacerlo bien a mano cada vez. Olvidar un archivo o subir uno desactualizado no se detecta hasta que un usuario externo reporte que algo no instala.
- **Divergencia silenciosa.** No hay separación explícita entre "lo que está en raíz del repo" y "lo que está publicado en el endpoint". Pueden divergir sin que nadie lo note.

**Solución futura (en v8).** Reemplazar `Stata net/` + publicación manual por un script `publicar-endpoint.sh` que lea un manifiesto versionado (`manifest-endpoint.toml`) declarando qué archivos forman parte del Simulador público vía `net from`, y sincronice al servidor IONOS con trazabilidad. Contrato funcional preliminar en §7. La carpeta `Stata net/` se conserva como staging hasta que ese script esté operativo y verificado; en ese momento se elimina.

---

## 7. Lo que NO está implementado todavía

*Qué aprendes en esta sección:* esta arquitectura es objetivo, no estado actual completo. Aquí está la lista honesta de lo que falta y cuándo se construye.

| Componente                                                                                                     | Estado hoy                                                                                                                                                                                                                                                                                 | Cuándo se construye                                                                                                                                                               |
| ----------------------------------------------------------------------------------------------------------------| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clon de desarrollo fuera de Dropbox                                                                            | Sigue dentro de Dropbox (`~/Library/CloudStorage/Dropbox-CIEP/.../SimuladorCIEP/`). Riesgo de corrupción del directorio `.git/` documentado en `governance/fase-0-5-git-hygiene-audit.md`.                                                                                                 | Migración manual antes de Acción 6.                                                                                                                                               |
| Carpeta del Simulador para investigadores separada de la carpeta de desarrollo                                 | No existe como carpeta distinta. Hoy `~/Dropbox-CIEP/SimuladorCIEP/` cumple ambos papeles (desarrollo + distribución). La separación entre ambas carpetas se implementa en Fase A5.                                                                                                        | Fase A5 (primera publicación formal de una versión).                                                                                                                              |
| `publicar.sh`                                                                                                  | No implementado. Contrato funcional documentado en §3.2.                                                                                                                                                                                                                                   | Fase A5.                                                                                                                                                                          |
| `reproducir.sh`                                                                                                | No implementado. Contrato funcional documentado en §5.4.                                                                                                                                                                                                                                   | Fase A5 o A6 (después de la primera Publicación con datos asociados).                                                                                                             |
| `profile.do` enriquecido con banner de versión y changelog                                                     | No implementado. El `profile.do` actual ya tiene un banner de bienvenida, pero sin información de versión ni de cambios. Mockup en §2.2.                                                                                                                                                   | Fase A5.                                                                                                                                                                          |
| `CHANGELOG.md` en la raíz del Código del Simulador                                                             | No existe.                                                                                                                                                                                                                                                                                 | Fase A5, junto con la primera versión publicable.                                                                                                                                 |
| Comando interno `sim_changelog` (Stata) que muestra changelog completo                                         | No implementado.                                                                                                                                                                                                                                                                           | Fase A5.                                                                                                                                                                          |
| Mecanismo de archivo de estado local del investigador (`~/.simulador_ciep_state`)                              | No implementado. Diseño preliminar en §2.2; ruta exacta y formato a definir.                                                                                                                                                                                                               | Fase A5.                                                                                                                                                                          |
| Firma de versión en outputs (globales `${sim_version}`, etc.)                                                  | No implementado. Diseño en §2.4.                                                                                                                                                                                                                                                           | Fase A5, integrado con `profile.do` enriquecido.                                                                                                                                  |
| Procedimiento de incorporación de un investigador CIEP nuevo (configuración estandarizada del `sysprofile.do`) | Hoy es trabajo manual y artesanal del investigador principal (Ricardo configura el `sysprofile.do` de cada investigador CIEP nuevo a mano). No está documentado ni automatizado. La consecuencia es que dar de alta a un investigador nuevo requiere intervención uno-a-uno.               | Por definir. Opciones: script `setup_user.sh` o sección nueva en este mismo documento ("Cómo doy de alta a un investigador CIEP nuevo"). Decisión sobre formato y fase pendiente. |
| Procedimiento detallado de actualización del sitio web por cada publicación                                    | No documentado. Hoy es trabajo manual del investigador principal. Falta especificar: comandos exactos, cuánto downtime, prueba previa, qué hacer si la nueva versión rompe el sitio.                                                                                                       | Fase A5 o posterior.                                                                                                                                                              |
| **Gestor de secretos institucional del CIEP**                                                                  | No adoptado formalmente. Las credenciales del investigador principal viven en su gestor personal. Práctica a migrar antes de incorporar al primer investigador colaborador. Documento de política pendiente: `governance/politica-gestion-secretos.md`.                                    | Decisión administrativa/presupuestal del investigador principal. Documento de política: próximo turno, después de aprobar este documento.                                         |
| Documentación operativa del certificado SSL del sitio web                                                      | No documentada. Falta especificar: emisor del certificado, procedimiento de renovación (automático o manual), responsable, calendario de verificación.                                                                                                                                     | Fase A5 o posterior.                                                                                                                                                              |
| **Script `publicar-endpoint.sh`**                                                                              | No implementado. El despliegue al sub-canal Stata del endpoint público es hoy un copy-paste manual del investigador principal (raíz del repo → `Stata net/` → servidor IONOS vía SSH). Estado actual y limitaciones documentados en §6.5.                                                  | Fase A5 o A6 (parte del trabajo de v8).                                                                                                                                           |
| **Manifiesto `manifest-endpoint.toml`**                                                                        | No existe. Sería un archivo versionado en Git que declara explícitamente qué `.ado`, `.sthlp`, `.pkg`, `stata.toc` forman parte del Simulador "público vía `net from`" (subconjunto de todos los archivos del repo). Análogo al Catálogo de datos asociados pero para código de la Capa 4. | Fase A5 o A6, junto con `publicar-endpoint.sh`.                                                                                                                                   |
| **Borrado de `Stata net/`**                                                                                    | Existente hoy como área de staging manual del sub-canal Stata (§6.5). Se conserva hasta que `publicar-endpoint.sh` esté operativo y verificado. Cuando esté funcionando, ese commit elimina `Stata net/` porque ya no es necesario.                                                        | Fase A5 o A6, después de validar el script automatizado.                                                                                                                          |

Mientras estos componentes no existan, el Simulador opera como siempre: el equipo CIEP usa la carpeta de Dropbox sin distinción de capas, sin trazabilidad de versión en outputs, sin script de reproducción; el sitio web sigue funcionando pero sin procedimiento documentado de actualización. La arquitectura aquí descrita es la que se va construyendo en las fases siguientes.

**Contrato funcional preliminar de `publicar-endpoint.sh`** (pendiente de implementación)

| Elemento | Especificación |
|---|---|
| **Entrada** | Un argumento: el número de versión publicada (ejemplo: `v8.0`). |
| **Lee** | Manifiesto `manifest-endpoint.toml` en raíz del Código del Simulador, que lista qué archivos `.ado`, `.sthlp`, `.pkg`, `stata.toc` forman parte del Simulador público vía `net from`. |
| **Verifica** | Que estás en `master`, working tree limpio, etiqueta de versión existe. Que las credenciales del servidor IONOS están disponibles vía gestor de secretos institucional (referencia: `governance/politica-gestion-secretos.md`). |
| **Genera** | El `stata.toc` actualizado con la versión y fecha de publicación. |
| **Sincroniza** | Los archivos del manifiesto al servidor IONOS vía `rsync` sobre SSH. |
| **Verifica post-deploy** | Que el endpoint responde y sirve la versión correcta (HTTP GET al `stata.toc` y validación del contenido). |
| **Registra** | En un log local de despliegues (`governance/deploys/endpoint-stata.log` o similar) qué versión se publicó, cuándo, por quién. |
| **Si falla** | Aborta antes de tocar el servidor si la validación inicial falla. Si falla en medio del rsync, registra el estado parcial y notifica al investigador principal. |

---

## 🧠 Concepto: un motor de cálculo, varias interfaces hacia audiencias distintas

El patrón detrás de las cuatro capas es viejo en la práctica científica: **un modelo único cuyos resultados se comunican mediante distintos canales adaptados a su audiencia**. Un grupo de investigación con un modelo macroeconómico no lo publica una sola vez en un solo formato. Lo publica como paper técnico para revisores especializados, como working paper accesible para colegas, como nota de divulgación para periodistas, como presentación en conferencia para tomadores de decisión, y a veces como herramienta interactiva para el público general. Las audiencias son distintas; el modelo subyacente es el mismo.

El Simulador funciona igual. La Capa 1 es el modelo en su forma técnica completa (código auditable, decisiones metodológicas documentadas). La Capa 2 lo hace usable como herramienta de análisis para investigadores CIEP. La Capa 3 lo congela en instantáneas reproducibles que cualquiera puede recuperar para defender un resultado citado. La Capa 4 lo expone como herramienta pública para audiencias externas que no usan Stata. Las cuatro interfaces hablan distinto, pero los números salen del mismo cálculo. Es lo que mantiene al Simulador coherente como fuente única — y lo que permite que un periodista, un investigador y un revisor académico, cada uno usando su interfaz preferida, vean el mismo modelo.

---

## Política de higiene del directorio `governance/`

Reglas operativas para mantener orden en este directorio mientras crece:

- **Los documentos vivos se reescriben en su lugar.** Cuando un documento cambia de versión (de `v1.0` a `v2.0`, por ejemplo), se sobrescribe el mismo archivo y la bitácora interna del documento registra el cambio. No hay archivos versionados con sufijos `_v1`, `_v2` en el directorio actual; las versiones viejas viven en la historia de Git, accesibles con `git log --follow <archivo>`.
- **Documentos que dejan de aplicar se archivan en `governance/historico/`.** Esto pasa cuando la realidad o la decisión cambian y el documento ya no describe el sistema actual. Al mover, se agrega una nota corta en el archivo explicando por qué se retiró y qué documento vigente lo reemplaza (si aplica).
- **No se borra nada permanentemente.** Aunque un documento sea obsoleto, queda en `governance/historico/` para que el contexto histórico de decisiones siga consultable.

---

## Bitácora de cambios de este documento

| Fecha | Versión | Cambios |
|---|---|---|
| 2026-05-12 | 1.0 | Versión inicial. Documenta la arquitectura de cuatro capas (desarrollo, distribución vigente para investigadores, reproducción histórica, herramienta web pública) que hasta hoy vivía solo en la cabeza del investigador principal. Establece el contrato funcional de los componentes pendientes (`publicar.sh`, `reproducir.sh`, `profile.do` enriquecido, `CHANGELOG.md`, `sim_changelog`, archivo de estado local, procedimientos web y SSL). Adopta el glosario CIEP consolidado: "investigador principal", "investigadores colaboradores", "investigadores", "usuarios externos", "publicación", "etiqueta de versión", "Código del Simulador", "Carpeta del Simulador para investigadores", "Catálogo de datos asociados". Incluye política de higiene del directorio `governance/`. |
| 2026-05-13 | 1.1 | Reconoce que la Capa 4 (herramienta web pública) tiene **dos sub-canales**: web HTML interactivo (`simuladorfiscal.ciep.mx`) y Stata `net from` (instalación remota vía `https://ciep.mx/simuladorfiscal/`). Las dos URLs son distintas (subdominio vs. ruta del dominio principal del CIEP), pero ambos endpoints corren en infraestructura del CIEP en IONOS y sirven al mismo motor de cálculo. Actualiza el diagrama de §1 con la Capa 4 expandida en sus dos sub-canales. Reescribe §6.2 para reconocer que el motor corre en tres lugares (instalación local del investigador CIEP, copia remota del usuario externo vía `net from`, sitio HTML interactivo). Renombra §6.4 a "Sub-canal web HTML" (la documentación SSL queda como sub-sección sin cambios). Agrega §6.5 "Sub-canal Stata `net from`", que documenta la carpeta `Stata net/` del repo como área de staging actual del sub-canal Stata, con despliegue manual al servidor y limitaciones reconocidas (sin trazabilidad, sin automatización, divergencia silenciosa). Declara solución futura en v8: script `publicar-endpoint.sh` + manifiesto `manifest-endpoint.toml` + borrado de `Stata net/` una vez validado el script. Agrega contrato funcional preliminar de `publicar-endpoint.sh` al final de §7. |
