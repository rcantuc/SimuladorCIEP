# Versionado y Git del Simulador Fiscal CIEP

Este documento reúne dos piezas que antes vivían en archivos separados de esta carpeta (fusión del 2026-07-04; la historia de cada parte se sigue con `git log --follow` sobre este archivo):

- **Parte I — Convenciones de Git**: cómo se escriben commits, cómo fluyen las ramas, cuándo sube cada número de versión y cómo se publica.
- **Parte II — Historia de versiones**: el modelo de eras del proyecto (v7.x transición, v8.0+ institucional) y el contexto de los releases publicados en GitHub.

---

# Parte I — Convenciones de Git del proyecto

**Versión:** v1.0
**Fecha:** 2026-05-15
**Estado:** referencia general de las convenciones de Git del proyecto. Vocabulario y tono según el Glosario CIEP y el perfil del lector institucionales.

---

## Tabla de contenido

1. [Principios y convención de mensajes de commit](#1-principios-y-convención-de-mensajes-de-commit)
2. [Flujo de ramas y pull request](#2-flujo-de-ramas-y-pull-request)
3. [Versionado y publicaciones](#3-versionado-y-publicaciones)
   - [3.1 Qué significa cada número de versión](#31-qué-significa-cada-número-de-versión)
   - [3.2 Cuándo sube cada número de versión](#32-cuándo-sube-cada-número-de-versión)
   - [3.3 Crear la etiqueta de versión y la publicación en GitHub](#33-crear-la-etiqueta-de-versión-y-la-publicación-en-github)
4. [Reescritura de historia](#4-reescritura-de-historia)
5. [Documentación negativa y bitácoras](#5-documentación-negativa-y-bitácoras)
6. [Verificación del .gitignore](#6-verificación-del-gitignore)
7. [Apéndice: entorno (macOS / zsh)](#7-apéndice-entorno-macos--zsh)
8. [Bitácora de cambios del documento](#8-bitácora-de-cambios-del-documento)

---

## 1. Principios y convención de mensajes de commit

*Qué aprendes en esta sección:* qué hace que un commit sea bueno en el Simulador Fiscal CIEP, y cómo se escribe el mensaje.

### 1.1 Cuatro principios, con ejemplo del propio repo

**Un commit, una idea.** Un commit que actualiza la sección §4 de un documento NO debe contener también el reformateo automático de espacios que tu editor metió al guardar. Si el linter de Markdown te realineó las tablas de la bitácora porque tocó padding, esos cambios cosméticos no entran en el mismo commit que tu cambio de contenido. Si los descartas, no contaminan el diff; si los conservas, lo hacen en commit separado de formato.

**Separa contenido de formato.** Caso real: durante la actualización de la bitácora de `arquitectura-y-bitacoras.md` v1.4, el editor reformateó padding de tablas en la sección de cambios anteriores. Esos cambios no entraron al commit de v1.4: se descartaron con `git checkout 02_governance/arquitectura-y-bitacoras.md` (después de stagear lo que sí iba) para que el `git diff` final reflejara exclusivamente el contenido nuevo, no el ruido del editor.

**Verifica antes de actuar.** `git diff` antes de `git add` es obligatorio. `git status` + `git diff --cached` antes de `git commit` son obligatorios. La vista del diff es lo único que te garantiza que estás commiteando lo que crees que estás commiteando, no lo que el editor decidió por ti al guardar.

**Documentación negativa en el mensaje.** Si decides explícitamente NO hacer algo que parecía obvio, dilo en el cuerpo del mensaje. Si una regla nace de un incidente, cita el incidente con su `SHA` (un identificador único derivado del contenido del commit, equivalente a una huella digital). Esta práctica se desarrolla en §5.

### 1.2 Formato del asunto del commit

El asunto del commit (la primera línea, lo que aparece en `git log --oneline`) sigue este formato:

```
tipo(ámbito): descripción corta
```

Los tipos que usa este proyecto son cuatro:

| Tipo | Cuándo usarlo | Ejemplo del propio repo |
|---|---|---|
| `docs` | Documentación: governance, README, help, comentarios. | `docs(governance): arquitectura v1.4 — Ecosistema CIEP, repositorios independientes y registro formal vs coloquial` |
| `infra` | Configuración o contratos meta-operativos: `.windsurfrules`, `.mailmap`, etiquetas de versión, hooks. | `infra(windsurfrules): política v2.0 — cero modificaciones del repo sin autorización explícita` |
| `chore` | Mantenimiento del repo en sí: `.gitignore`, limpieza de working tree, configuración del IDE. | `chore(repo): ignore .windsurf/ workflows locales del IDE` |
| `legacy` | Movimientos de código a la carpeta `legacy/` o reorganizaciones de archivado. | `legacy(análisis): archiva 9 análisis históricos a legacy/analisis-v7/` |

El **ámbito** entre paréntesis es el área del repo afectada (`governance`, `repo`, `windsurfrules`, `README`, `mailmap`, etc.). Si el cambio toca varios ámbitos legítimamente, escoge el más representativo; si toca dos ámbitos completamente distintos, casi siempre quieres dos commits separados.

La **descripción corta** del asunto va en español, en minúsculas (excepto nombres propios y siglas), sin punto final, y debe caber en una sola línea. Si necesitas más, va en el cuerpo, no en el asunto.

### 1.3 Cómo se escribe el cuerpo del commit (método robusto)

El cuerpo del commit se escribe con **múltiples banderas `-m`**, una por párrafo. La primera `-m` es el asunto; cada `-m` posterior es un párrafo del cuerpo, separado automáticamente por línea en blanco:

```bash
git commit -m 'docs(governance): título del cambio' \
  -m 'Primer párrafo: qué cambió y por qué.' \
  -m 'Segundo párrafo: qué se decidió no hacer y por qué (documentación negativa).' \
  -m 'Tercer párrafo: origen de la regla si aplica, o referencias cruzadas a incidentes por SHA.'
```

**Por qué múltiples `-m` y no heredoc.** Existe una alternativa popular: usar heredoc para pasar el cuerpo desde stdin (`git commit -F - <<EOF ... EOF`). El método demostró ser frágil en este entorno. La combinación de `zsh` (que interpreta `!` como expansión de historia incluso dentro de algunas formas de comillas), texto del cuerpo con comillas anidadas, y Cascade ejecutando comandos en lotes, produjo varios casos donde el cuerpo del commit se truncaba o se escapaba mal sin avisar. Múltiples `-m` no tienen ese problema: cada cadena se pasa íntegra como argumento al ejecutable de Git, sin reinterpretación de la shell.

Para mensajes con `!` (admiración) en el texto, usa **comillas simples**, no dobles. En zsh, comillas dobles + `!` dispara expansión de historia y el comando falla con "event not found".

### 1.4 Qué va en el cuerpo

Un cuerpo bien escrito responde tres cosas:

1. **Qué cambió** en términos sustantivos. No "actualicé el archivo X" (eso ya lo dice el diff); más bien "se incorpora el rol de desarrollador externo de infraestructura a la matriz de acceso del §4".
2. **Por qué.** El razonamiento. Si la decisión es no obvia o tiene alternativa descartada, dilo.
3. **Documentación negativa cuando aplica.** Lo que se decidió NO hacer y por qué. Si la regla nace de un incidente, qué incidente y qué SHA. Lo desarrolla §5.

---

## 2. Flujo de ramas y pull request

*Qué aprendes en esta sección:* cómo trabaja hoy el Simulador Fiscal CIEP con un solo desarrollador, y cómo cambia ese flujo cuando entre el primer investigador colaborador.

### 2.1 Realidad actual: un solo desarrollador trabaja directo sobre `master`

Hoy el Simulador Fiscal CIEP tiene un único desarrollador activo: el investigador principal. Bus factor = 1. En este escenario la práctica del proyecto es trabajar directamente sobre la rama principal, llamada `master` (una rama de Git es una línea de desarrollo independiente; `master` es la rama oficial del proyecto, la que está sincronizada con GitHub y la que produce versiones publicadas).

Para un proyecto con un solo desarrollador, esto es lo apropiado. Los modelos de ramificación complejos que usan equipos grandes — donde varias personas trabajan en paralelo en partes distintas y necesitan reservar espacios separados antes de integrar — añaden costo de coordinación sin beneficio cuando solo hay una persona que coordina consigo misma. La disciplina aquí no está en la estructura de ramas; está en la calidad de los commits, en `git diff` antes de `git add`, y en la verificación pre-publicación.

**Excepción dentro de la realidad actual.** Una rama de trabajo (rama temporal donde elaboras un cambio antes de integrarlo a `master`) tiene sentido cuando el cambio es grande, no compila o no corre durante varios commits intermedios, o tiene riesgo. La regla operativa es simple: la rama de trabajo se crea, se trabaja en ella, se integra a `master` con commits limpios, y se borra. No se acumulan ramas zombi en el remoto.

### 2.2 Qué es un pull request

Un *pull request* (en español también "propuesta de incorporación") es la pieza central del trabajo en equipo en GitHub: una propuesta de incorporar los cambios de una rama de trabajo a la rama principal, abierta para que alguien la revise antes de que efectivamente entren a `master`. La propuesta queda registrada como artefacto: tiene URL propia, hilo de comentarios, vista de diff comparada contra `master`, y un botón explícito de aceptar o rechazar.

El valor del pull request no es técnico — `git merge` puede hacer el mismo trabajo desde la línea de comandos sin pasar por GitHub. El valor es institucional: deja registro de quién propuso, quién revisó, qué se discutió, qué se cambió como resultado de la revisión. Para un equipo donde los cambios al Simulador Fiscal CIEP afectan productos citados, ese registro es memoria institucional.

### 2.3 Cuándo se activa el flujo de pull request

El flujo de pull request se activa el día en que el Simulador Fiscal CIEP tiene **más de una persona** tocando el Código del Simulador: el investigador principal más al menos un investigador colaborador. A partir de ese momento, ningún cambio entra directamente a `master`; el flujo es:

1. **Rama de trabajo.** El autor del cambio crea una rama de trabajo a partir de `master`, con un nombre descriptivo (`actualizacion-pef-2027`, `arregla-iva-decil-x`, etc.).
2. **Trabajo y commits.** Trabaja en esa rama, commitea siguiendo las convenciones de §1.
3. **Propuesta.** Sube la rama a GitHub y abre un pull request contra `master`. En el cuerpo del pull request describe qué cambió y por qué, en el mismo género que el cuerpo de un buen commit.
4. **Revisión.** Otro investigador (típicamente el principal cuando recién hay dos personas) revisa el diff, comenta, pide cambios si aplica.
5. **Integración.** Cuando la revisión está cerrada, el pull request se integra a `master` con el botón "Merge pull request" en GitHub. La rama de trabajo se borra.

### 2.4 Qué bloquea un pull request

Mientras un pull request está abierto, hay condiciones que tienen que cumplirse antes de integrar:

- **El pull request describe qué cambió y por qué.** No basta con el título; el cuerpo del PR es del mismo género que el cuerpo de un buen commit (§1.4).
- **Si el cambio toca el `.gitignore`,** la verificación obligatoria del §6 corre y pasa. Sin verificación verde, no se integra a `master`. Esta condición no es opcional.
- **Si el cambio toca un módulo de cálculo del Simulador Fiscal CIEP,** la corrida de prueba (`SIM.do` end-to-end o el subset relevante) pasa. El procedimiento detallado de pruebas de regresión es objeto de un documento futuro de governance; aquí basta establecer que la corrida tiene que pasar.
- **Quien revisa no es el mismo que quien propuso.** Auto-aprobar un pull request anula el sentido del flujo.

---

## 3. Versionado y publicaciones

*Qué aprendes en esta sección:* cómo el Simulador Fiscal CIEP numera sus versiones, cuándo sube cada número, y cómo se crea una etiqueta y una publicación cuando llega el momento.

### 3.1 Qué significa cada número de versión

El Simulador Fiscal CIEP usa un esquema de tres números: `mayor.menor.parche` (ejemplos: `v7.0`, `v8.1`, `v8.0.1`).

| Número | Qué representa | Ejemplo del propio repo |
|---|---|---|
| **Mayor** | Cambio institucional o metodológico de fondo. Rompe comparabilidad de resultados con la versión anterior. | `v7 → v8`. v7 fue la etapa pre-governance del Simulador como proyecto del investigador principal, con conocimiento metodológico tácito y unipersonal. v8 es la primera versión institucional citable, con governance documentada, Catálogo de datos asociados, y arquitectura de cuatro capas. |
| **Menor** | Cambios aditivos: datos anuales nuevos, módulo nuevo, refactorización compatible. Los resultados siguen siendo comparables con la versión anterior dentro del mismo mayor. | `arquitectura-y-bitacoras.md v1.0 → v1.1`. La v1.1 agregó el sub-canal Stata público sin modificar el resto del documento. |
| **Parche** | Corrección puntual sobre versión publicada y citada. Una errata, un dato mal capturado, un correo con typo. El contenido sustantivo no cambia. | Si en `politicas-institucionales.md v1.1` se detecta que un correo institucional está mal escrito, la corrección sale como `v1.1.1`: solo arregla el dato erróneo, sin cambiar el resto de la política. |

**Por qué tres números y no dos o cuatro.** Tres separan los tres tipos de cambio relevantes para el Simulador (de fondo, aditivo, errata) sin sobrediscriminar. Cuatro (estilo `v8.1.0.3`) es ruido sin ganancia para un proyecto a esta escala. Dos (estilo `v8.1`) no permite distinguir entre "agregamos una funcionalidad" y "corregimos una errata sobre versión publicada", que es justamente la distinción que el lector que cita al Simulador necesita ver.

### 3.2 Cuándo sube cada número de versión

Reglas concretas, con casos reales del proyecto.

**El número mayor sube cuando:**

- Cambia la metodología de fondo del Simulador y los resultados ya no son comparables con la versión anterior. Ejemplo prospectivo: si en algún momento se cambia el procedimiento de armonización ENIGH↔Cuentas Nacionales y los deciles cambian, eso es `v8 → v9`.
- Cambia el marco institucional del producto. Ejemplo real: `v7 → v8`. v7 fue cuerpo de archivos en la computadora del investigador principal con conocimiento metodológico tácito y unipersonal; v8 es producto con governance, Catálogo de datos asociados, y reproducibilidad documentada. La metodología no cambió de fondo; el producto institucional sí.

**El número menor sube cuando:**

- Se incorpora un PEF nuevo, una ENIGH nueva, o cualquier dato anual nuevo sin cambiar metodología.
- Se agrega un módulo nuevo (un impuesto nuevo, un perfil nuevo) que no rompe lo anterior.
- Se refactoriza código sin cambiar resultados.
- Ejemplo real: `arquitectura-y-bitacoras.md v1.0 → v1.1 → v1.2 → v1.3 → v1.4` durante la primera semana de governance. Cada incremento agregó una capa nueva o expandió alcance (sub-canal Stata, hosting de sub-canales, expansión a Simuladores CIEP, Ecosistema CIEP) sin romper lo anterior. Cuatro versiones menores en una semana NO es excesivo: es el indicador de que la documentación está madurando rápido y se está dejando registro de cada paso.

**El número de parche sube cuando:**

- Se corrige un error puntual en una versión publicada y citada. Sin cambio de alcance, sin contenido nuevo, sin reformulación.
- Ejemplo: si `politicas-institucionales.md v1.1` (publicada el 2026-05-14) contiene un correo institucional con un typo, la corrección sale como `v1.1.1`. Si en cambio el cambio agrega una sección nueva sobre un rol que aún no se había considerado, ese ya no es parche; es menor (`v1.2`).

**Cómo decides cuál es cuál cuando estás dudando.** Pregunta primero: *¿alguien que cite la versión anterior tiene que cambiar la cita?* Si la respuesta es sí (porque los números de los resultados cambiaron, la metodología cambió, el alcance cambió), es mayor. Si la respuesta es no, pero hay contenido nuevo que querrías documentar, es menor. Si la respuesta es no y solo arreglas algo mal escrito, es parche.

### 3.3 Crear la etiqueta de versión y la publicación en GitHub

*Qué aprendes en esta sección:* el procedimiento exacto para fijar una versión nueva del Simulador Fiscal CIEP en Git y publicarla en GitHub.

**Antes del procedimiento, dos términos.**

Una **etiqueta de versión** (en inglés *tag*) es un marcador permanente sobre un commit específico. Le pones un nombre legible (`v8.1`) a un commit identificado por su `SHA`. La diferencia operativa: el `SHA` de un commit es texto críptico (`d463caa…`) y poco memorable; una etiqueta de versión es legible y estable. La diferencia conceptual: los `SHA` pueden cambiar si la historia se reescribe (§4); las etiquetas, una vez creadas y subidas a GitHub, no se mueven y tienen mensaje propio.

Una **publicación** (en inglés *release*) de GitHub es el empaque oficial de una versión: la etiqueta de versión + un changelog descriptivo + opcionalmente archivos de datos pesados subidos como assets (los `.xlsx` de `raw/PEFs/` y demás insumos del Simulador, que viven separados del Código del Simulador y se listan en el Catálogo de datos asociados, `05_scripts/manifest.json`). Las publicaciones son **inmutables por diseño**: una vez creada `v8.0`, no se borra ni se edita. Si encuentras un error después, publicas `v8.0.1`, no editas `v8.0`. Es el mismo principio que las publicaciones académicas: cuando un análisis del CIEP cita "*Simulador Fiscal CIEP v8.0 (octubre 2026)*", esa cita es una promesa al lector de que cualquiera puede volver a v8.0 y reproducir los mismos números. Editar v8.0 retroactivamente rompe esa promesa.

**Procedimiento (dos pasos).**

1. **Crea la etiqueta de versión** sobre el commit de `master` que cierra la versión.

   Antes de empezar, asegúrate de que todo lo que va a la versión está en `master`. Si hay una rama de trabajo abierta con cambios que pertenecen a esta versión, ciérrala con su pull request (§2) primero. La etiqueta apunta a un commit en `master`, no a un estado intermedio.

   En la raíz del Código del Simulador:

   ```bash
   git tag -a v8.1 -m "v8.1 — descripción corta de qué la distingue de v8.0"
   ```

   La opción `-a` (anotada) es obligatoria: una etiqueta anotada queda como objeto Git con autor, fecha y mensaje propio; una etiqueta ligera (sin `-a`) es solo un alias que apunta a un commit y no carga metadatos. Para versiones del Simulador Fiscal CIEP, siempre anotada. El comando devuelve sin imprimir nada cuando funciona; `git tag -l` ahora lista `v8.1`. Si falla con "tag already exists", la versión ya estaba creada — no la sobrescribas; decide si esto es realmente un cambio nuevo y, si lo es, sube el número.

   Las etiquetas no se suben a GitHub automáticamente con `git push`; hay que mandarla por separado:

   ```bash
   git push origin v8.1
   ```

   Esperas ver una línea tipo `* [new tag] v8.1 -> v8.1`. Después de esto la etiqueta existe en GitHub y se puede usar para crear la publicación.

2. **Crea la publicación en GitHub apuntando a la etiqueta** y sube los assets de datos correspondientes.

   En la interfaz web del Código del Simulador en GitHub: *Releases → Draft a new release → Choose a tag: v8.1*. En el cuerpo de la publicación va el changelog de la versión: qué cambió respecto a la versión anterior, agrupado por categoría — cambios metodológicos que afectan resultados, cambios aditivos, correcciones, cambios técnicos. El changelog del cuerpo de la publicación replica el del `CHANGELOG.md` del repo; no son fuentes independientes.

   Si la versión incluye archivos pesados de datos (los `.xlsx` de `raw/PEFs/` y demás insumos que viven separados del Código del Simulador), se suben aquí como assets de la publicación. El `05_scripts/manifest.json` del Catálogo de datos asociados se actualiza, en el commit que cierra la versión, con las huellas digitales SHA-256 de los assets subidos. Una publicación con assets es lo que hace al Simulador Fiscal CIEP reproducible por terceros: el Catálogo lleva las huellas digitales, los assets viven en la URL inmutable de la publicación, cualquiera puede reconstruir bit por bit el estado de los datos en esa versión.

   Una vez publicada, **la publicación es inmutable**. No se borra, no se edita el changelog, no se reemplazan los assets. Si descubres un error después, publicas `v8.1.1` con la corrección y una nota explícita en su changelog; no editas `v8.1`.

   Para verificar que el paso 2 quedó bien: la etiqueta `v8.1` aparece en la página de Releases en GitHub; la publicación tiene su URL inmutable; los assets descargan correctamente desde un clone fresco del Código del Simulador. Cualquiera (interno o externo al CIEP) puede ahora citar y reproducir esta versión específica del Simulador Fiscal CIEP.

**Caso real: la etiqueta `v7.0` retroactiva.** El Simulador Fiscal CIEP existía como producto desde 2010, pero no tenía ninguna etiqueta de versión hasta 2026. Cuando se inició la documentación de governance, se creó la etiqueta `v7.0` retroactivamente sobre el commit pre-governance que representaba el último estado coherente del producto antes de la transición institucional. Esa etiqueta congeló el "antes" para poder hablar del "después" como `v8.0`. Una etiqueta retroactiva es legítima cuando el commit existió siempre y solo le faltaba el marcador; no implica reescritura de historia.

---

## 4. Reescritura de historia

*Qué aprendes en esta sección:* qué es reescribir la historia de Git, cuándo es seguro hacerlo en este proyecto, y por qué se planea como operación dedicada y no como rutina.

### 4.1 Qué es

Reescribir historia (en inglés *history rewrite*) significa modificar commits que ya existen en el repositorio. Las herramientas estándar son `git filter-repo`, `git rebase --interactive`, y `git lfs migrate import`. El resultado típico: los commits afectados (y todos sus descendientes) cambian de `SHA`. Lo que era el commit `2f46d92` puede convertirse en `a8e8be5` con el mismo contenido sustantivo pero historia limpia.

**Ejemplo concreto previsto para este proyecto:** purgar de la historia Git los binarios pesados de `raw/PEFs/*.xlsx` (más manuales borrados, carpetas obsoletas, y otros objetos muertos que abultan el `.git` a 5.1 GB). El plan es ejecutar `git filter-repo --invert-paths` con un patrón de purga, lo que reduce el `.git` a alrededor de 250 MB y republica los binarios como assets de la publicación `v7.0` en GitHub. Resultado: `git clone` fresco pasa de tardar 10–15 minutos a tardar 1 minuto.

### 4.2 Cuándo es seguro

La reescritura de historia es **segura mientras bus factor = 1**: hay un único desarrollador, ninguna otra persona tiene clones activos del Código del Simulador, no hay pull requests abiertos por terceros, no hay infraestructura externa (CI, paquetes, servicios) que dependa de `SHA` específicos.

En esa ventana, reescribir historia no rompe nada porque nadie tiene una copia paralela que se desincronice. El día que entra el primer investigador colaborador (cuando alguien más empieza a clonar y trabajar en serio sobre el Código del Simulador), **la ventana se cierra**. Reescribir historia compartida después de eso requeriría coordinar con todos los que tienen clones para que reseteen su rama local, lo cual es operativamente costoso y propenso a errores que pierden trabajo de gente.

**Por eso el rewrite del Simulador Fiscal CIEP se planea para antes** de incorporar al primer investigador colaborador. Está en la cola operativa, esperando a que se rote el token del Banco de Indicadores Económicos (BIE) de INEGI; una vez rotado, el rewrite se ejecuta en una sesión dedicada con backup integral previo (un `git clone --mirror` en disco externo).

### 4.3 Por qué es operación dedicada y no rutina

La reescritura es **irreversible** sin el backup previo: una vez que se hace `git push --force-with-lease`, los commits viejos dejan de existir en el remoto. Si después descubres que el rewrite borró por error algo que querías conservar, solo el backup te salva.

Por eso aplica una sola regla operativa: **este documento describe la convención y el patrón; no se ejecuta una reescritura como parte de una sesión de documentación, ni como efecto colateral de otra tarea.** La reescritura tiene su propia ventana, su propio backup, su propia verificación end-to-end (clone fresco + corrida exitosa de `SIM.do`), y su propio commit/etiqueta de hito.

---

## 5. Documentación negativa y bitácoras

*Qué aprendes en esta sección:* dos prácticas concretas del proyecto que difieren de la documentación de software genérica — escribir lo que NO se hizo, y no editar bitácoras pasadas.

### 5.1 Documentación negativa

Documentación negativa es registrar **lo que NO se hizo y por qué**. Un commit, un documento, una bitácora, contiene típicamente lo que sí se hizo. Pero las decisiones que más cuestan de reconstruir tres meses después son las negativas: qué alternativa se evaluó y se descartó, qué solución obvia se rechazó por una razón concreta, qué incidente originó una regla.

**Ejemplo real: el origen de la política de cero modificaciones sin autorización.** El commit `63d73cf` (*infra(windsurfrules): añade política de cero commits sin autorización explícita*) crea la regla. Su mensaje no se limita a decir "se agrega esta sección". Cita explícitamente el incidente:

> *Origen: incidente del 13 de mayo de 2026, commit `1a299a0`, donde un agente Cascade pusheó modificación al README sin autorización explícita después de actualizar el documento a Simuladores CIEP. El contenido era coherente, pero el proceso rompió el principio diff-antes-de-add. Esta regla cierra el agujero.*

Sin esa cita, dentro de un año alguien que lea el commit `63d73cf` aislado pensaría que la regla apareció por preferencia personal. Con la cita, queda claro que es respuesta a un evento específico, y el evento queda enlazado por `SHA` para quien quiera reconstruir el contexto.

**Práctica del proyecto:** cuando un commit crea una regla nueva o cambia una práctica, su cuerpo cita el incidente o la situación que lo originó (con `SHA` del commit relevante cuando aplique). Cuando un commit decide explícitamente NO hacer algo que parecía obvio, dilo en el cuerpo. Lo que parece redundante hoy es lo que salva al lector futuro de tener que reconstruirlo desde cero.

### 5.2 Bitácoras append-only

Las bitácoras de los documentos de governance (la sección final típica de cada `.md` con la tabla `Versión / Fecha / Cambio`) son **append-only**: cada entrada registra lo que pasó en el momento de esa versión, y NO se reescribe después aunque la realidad cambie.

**Ejemplo real:** la bitácora de `arquitectura-y-bitacoras.md` v1.x dice, en una de sus entradas, que el Glosario CIEP vivía como sección de `.windsurfrules`. Cuando posteriormente el glosario se migró a archivo propio (`governance/glosario-ciep.md`), esa entrada vieja **no se reescribió** para reflejar la nueva ubicación. Sigue diciendo lo que decía. La migración se documentó como entrada nueva en la bitácora del archivo correspondiente y como commit propio.

**Por qué.** La bitácora es registro histórico de cómo evolucionó la decisión, no fotografía del estado actual. Reescribir una entrada vieja para que "concuerde con hoy" falsifica el changelog: hace ver que la decisión actual estuvo siempre ahí, oculta la trayectoria, y le quita al lector futuro la posibilidad de entender cómo se llegó al estado actual paso a paso.

**Si descubres un error fáctico en una entrada vieja** (un dato mal escrito, una fecha equivocada), se corrige con una **entrada nueva** que explica el error y la corrección. No se sobrescribe la entrada vieja. Es el mismo principio académico de la errata: el original no se modifica; la corrección es artefacto adicional, citable por separado.

---

## 6. Verificación del `.gitignore`

*Qué aprendes en esta sección:* por qué existe una verificación obligatoria del `.gitignore`, qué hace el script que la ejecuta, y cómo añadir casos cuando el `.gitignore` cambia.

### 6.1 Historia del bug que originó la regla

El 9 de mayo de 2026, durante la Acción 3 de la Fase 0.5 de governance (reescritura del `.gitignore` para Stata + macOS + Dropbox + secretos), se descubrió que el patrón previsto para ignorar archivos de recuperación de Stata estaba mal escrito.

Stata genera archivos `Foo [Recovered].do` después de cierres anormales del programa. La idea era ignorarlos con un patrón como `*[Recovered]*.do`. El problema: en la sintaxis de glob de gitignore los corchetes `[…]` son una **clase de caracteres** — un conjunto de caracteres alternativos, donde `[Recovered]` significa *"cualquier carácter que sea R, e, c, o, v, r o d"*, no *"la cadena literal `[Recovered]`"*.

Resultado del patrón mal escapado: cualquier archivo cuyo nombre contuviera **alguna** de las letras `R, e, c, o, v, r, d` se marcaba como ignorado. Eso era prácticamente cualquier archivo del repo, incluido `scheme-ciepcolores.scheme`, `01_modulos/visualizations/sankey/SankeySF.do`, `PIBDeflactor.ado`, y muchos más. El bug se cazó haciendo `git check-ignore -v` sobre archivos legítimos del repo y viendo que aparecían como ignorados.

La corrección: escapar los corchetes con backslash, `*\[Recovered\]*`, para que el glob los interprete como caracteres literales. La explicación correspondiente vive como comentario en el `.gitignore` (líneas 65-73).

Pero la lección no era el escape específico. La lección era: un `.gitignore` mal escrito **rompe la confianza en la base** sin avisar. No genera un error visible; simplemente hace que el repo se comporte distinto de lo que el `.gitignore` parece decir. El proyecto necesitaba un mecanismo automático para verificar que el `.gitignore` hace lo que dice.

### 6.2 Justificación de la regla

Por eso existe `05_scripts/verify_gitignore.sh`: define un conjunto de referencia de paths que **deben** estar ignorados (logs Stata, archivos de Dropbox conflicted copy, llaves `.key`, binarios de `raw/`) y paths que **no deben** estar ignorados (código del Simulador, documentos de governance, el `05_scripts/manifest.json` del Catálogo de datos asociados), y reporta cualquier divergencia.

El script existe específicamente porque la sintaxis de gitignore no es trivial: corchetes que son clase de caracteres si no se escapan, doble asterisco que tiene significado solo entre slashes, excepciones con `!` que dependen del orden de aparición, interacción con archivos ya tracked. Cualquiera de esos puede romperse en un cambio aparentemente inocuo. La verificación automática es la única forma escalable de detectarlo antes de que entre a `master`.

### 6.3 Cuándo se corre

**Obligatorio antes de integrar a `master` cualquier cambio que toque el `.gitignore`.** No es opcional, no es recomendación. Si un pull request modifica el `.gitignore` y el script no pasa, el pull request no se integra hasta corregir.

Cómo se corre, desde la raíz del Código del Simulador:

```bash
bash 05_scripts/verify_gitignore.sh
```

Qué esperas ver al terminar:

```
RESUMEN: 55/55 casos OK; 0 FAILS

✓ .gitignore verificado. Apto para merge a master.
```

(El número `55` cambia conforme se añaden casos.) Si hay fallas, el script imprime cada caso `[FAIL]` con su descripción y termina con código de salida `1`. La instrucción operativa entonces es: corregir el `.gitignore` y volver a correr hasta tener cero fallas.

Para diagnosticar un caso específico que está fallando, el comando útil es:

```bash
git check-ignore -v <ruta>
```

que imprime exactamente qué línea del `.gitignore` matchea ese path.

### 6.4 Cómo añadir casos cuando se añade una regla nueva

Cada regla nueva del `.gitignore` debe tener al menos un caso positivo (un path que la regla **debe** ignorar) y al menos un caso negativo (un path cercano que la regla **no debe** ignorar). Esto se hace en el script, en la sección correspondiente de su lista de aserciones.

**Ejemplo prospectivo.** Si mañana se añade al `.gitignore` un patrón nuevo para ignorar archivos de extensión `.tmp`:

- Caso positivo: `assert_ignored "test.tmp" "Archivo temporal genérico"` en la sección 1 del script.
- Caso negativo: `assert_not_ignored "TasasEfectivas.ado" "Ado-file con la subcadena 'tmp' en algún lugar del path no debe matchearse por error"` o similar, dependiendo del riesgo de falso positivo del patrón.

Sin caso negativo asociado, una regla nueva puede romper algo y el script no lo detectaría — el patrón viejo del `[Recovered]` es exactamente el escenario que un caso negativo previene.

### 6.5 Nota de alcance: vocabulario interno del script

El script en su forma actual (`05_scripts/verify_gitignore.sh`) usa internamente la palabra "canónico" en algunos comentarios (define un *"set canónico de paths que DEBEN y NO deben estar ignorados"*). El Glosario CIEP eliminó "canónico" del vocabulario de prosa institucional. La descripción correcta en este documento es **conjunto de referencia**. La limpieza del vocabulario interno del script es pendiente menor separado y no afecta su funcionalidad: en el momento del primer commit del script, las 55 aserciones pasan en verde.

---

## 7. Apéndice: entorno (macOS / zsh)

*Qué aprendes en esta sección:* las trampas operativas reales que se acumularon trabajando con Git en este entorno la última semana. Referencia rápida para no reaprenderlas.

| Trampa                                                             | Síntoma                                                                                                                                                                                                      | Solución                                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`cat -A` no existe en macOS.**                                   | macOS trae las herramientas BSD, no GNU. `cat -A` (mostrar caracteres invisibles) falla con "invalid option".                                                                                                | Usa `cat -e` (muestra finales de línea con `$`) o `cat -et` para incluir tabs como `^I`.                                                                                                                                                                   |
| **`!` en zsh dispara expansión de historia.**                      | Un comando con `!` entre comillas dobles falla con `event not found`.                                                                                                                                        | Usa **comillas simples** para todo lo que contenga `!`, especialmente en mensajes de commit largos: `git commit -m '...!...'`, no `git commit -m "...!..."`.                                                                                               |
| **Heredoc frágil para `git commit -F`.**                           | El cuerpo del commit se trunca o se escapa mal cuando se usa `git commit -F - <<EOF ... EOF` en lotes con Cascade, sobre todo con comillas anidadas o `!` en el cuerpo.                                      | Usa múltiples `-m`, uno por párrafo, como se describe en §1.3. Cada cadena se pasa íntegra como argumento sin pasar por interpretación de heredoc.                                                                                                         |
| **Las carpetas vacías no se trackean en Git.**                     | Creas `governance/scripts/` vacío, haces `git add governance/scripts/`, y `git status` no la registra.                                                                                                       | Si necesitas que la estructura exista, mete un archivo dentro (un `.gitkeep` vacío como convención, o el archivo real cuando esté listo).                                                                                                                  |
| **`git checkout <archivo>` es destructivo.**                       | Descarta los cambios locales no commiteados de ese archivo, sin red de seguridad. No hay papelera.                                                                                                           | Antes de `git checkout <archivo>`, asegúrate con `git diff <archivo>` de que estás descartando exactamente lo que crees. Si dudas, haz una copia del archivo a otra ubicación primero.                                                                     |
| **`git diff --ignore-all-space` ignora espacios pero NO guiones.** | Te confunde: piensas que es un cambio de espaciado, pero el diff sigue marcando un cambio. Resulta que se cambió un guión `-` por una raya `—` (em dash) o las comillas `"` por comillas tipográficas `“ ”`. | Cuando un diff "imposible de explicar" persiste con `--ignore-all-space`, el sospechoso típico es puntuación Unicode (rayas, comillas tipográficas, espacios sin ruptura) introducida por el autocorrector del editor. Inspecciona con `cat -e` o `od -c`. |
| **El paginador captura la terminal.**                              | `git log`, `git diff`, `git show` te dejan en una vista paginada y los comandos posteriores no responden.                                                                                                    | Pulsa `q` para salir del paginador. Para que un comando no use el paginador desde el inicio: `git --no-pager log -10`, o exportar `GIT_PAGER=cat` para esa sesión.                                                                                         |

---

## 8. Bitácora de cambios del documento

| Versión | Fecha      | Cambio                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------| ------------| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| v1.0    | 2026-05-15 | Creación del documento (Acción 8 de la Fase 0.5, pendiente desde el inicio del proyecto de governance). Codifica las convenciones Git que el Simulador Fiscal CIEP ya practica en sus 18+ commits de la primera semana de governance: mensajes con tipo y ámbito (`docs`, `infra`, `chore`, `legacy`), cuerpo con múltiples banderas `-m` (no heredoc, frágil aquí), commits atómicos con separación explícita de contenido y formato, flujo de ramas y pull request (activo cuando entre el primer investigador colaborador), versionado con tres números `mayor.menor.parche`, etiquetas anotadas y publicaciones de GitHub inmutables, reescritura de historia segura mientras bus factor = 1, documentación negativa con cita de incidentes por SHA, bitácoras append-only, verificación obligatoria del `.gitignore` con script, y trampas reales del entorno macOS/zsh. La numeración (§2 ramas y PR, §3.2 cuándo sube cada número, §3.3 etiqueta y publicación con paso 2 = publicación en GitHub, §6 verificación gitignore) se eligió para sanar las referencias rotas de `arquitectura-y-bitacoras.md` y del propio `verify_gitignore.sh` sin tener que modificar esos archivos. En el mismo commit se formaliza `05_scripts/verify_gitignore.sh` (pasa de untracked a tracked); su §6 ya existe en este documento y lo justifica. La limpieza del vocabulario interno del script (usa "canónico", término eliminado del Glosario CIEP para prosa) queda como pendiente menor separado. |

---

# Parte II — Historia de versiones del SimuladorCIEP

Este documento traza la evolución del Simulador Fiscal CIEP desde proyecto personal hacia infraestructura institucional. Sirve como contexto para entender los releases publicados en GitHub y la trayectoria del proyecto.

## Modelo de versiones

El proyecto distingue dos eras:

**Era v7.x — transición.** Cubre los pasos sucesivos desde el Simulador como proyecto personal del investigador principal hacia el Simulador como infraestructura institucional documentada. Cada release v7.x marca un avance específico de esa transición; ninguno representa el estado final.

**Era v8.0+ — institucional completo.** v8.0 marcará la primera versión donde el Simulador opera completamente bajo arquitectura institucional: data sidecar publicado, código migrado a la lógica manifest-driven, tests pasando end-to-end, governance documentada y verificada. Las versiones citables y replicables empiezan en v8.0; los releases posteriores (v8.1, v8.2.1, etc.) son los apropiados para citarse en publicaciones académicas y análisis institucionales.

## El estado previo a la transición — snapshot pre-rewrite

Antes de mayo de 2026, el Simulador Fiscal CIEP existió por aproximadamente 16 años (2010-2026) como conjunto de archivos en la computadora del investigador principal y como cuerpo de decisiones metodológicas en su cabeza. Era código funcional pero no infraestructura institucional: no había política explícita de gestión de secretos, no había arquitectura de distribución documentada, los datos binarios pesados se distribuían vía URLs personales de Dropbox, y el conocimiento operativo dependía epistémica y operativamente de una sola persona.

Esa etapa quedó marcada internamente como "v7.0 — Último estado del Simulador como proyecto personal" en un tag de Git que apuntaba al commit `2f46d92` ("Carpeta Raw", 30 de abril de 2026). Ese commit y ese tag forman parte del historial pre-rewrite del repositorio. El rewrite de seguridad de mayo de 2026 (que purgó credenciales expuestas y binarios pesados de la historia) reescribió todos los SHAs del repo; el commit `2f46d92` ya no es referenciable desde la rama `master` actual.

Este documento preserva la narrativa de ese momento histórico sin depender de un tag de Git apuntando a un commit huérfano.

## Releases publicados en GitHub

Cada release publicado representa un punto específico en la transición. Su contexto, alcance, y referencias a commits están documentados en las notas del release respectivo en GitHub Releases (`https://github.com/rcantuc/SimuladorCIEP/releases`).

A partir de v8.0, esta sección se actualizará para clarificar qué versiones son aptas para citarse en publicaciones formales.

## Notas para futuras versiones

Cuando la era v8.x inicie, vale considerar:

- Documentar explícitamente qué constituye un release "completo" (criterios de cierre para una versión)
- Establecer convención de cuándo bumpear major vs minor vs patch (v8.x.y semver-style)
- Política sobre cómo se referencia el Simulador en publicaciones académicas del CIEP
- Eventualmente, considerar publicación con DOI vía Zenodo o similar para los releases citables
