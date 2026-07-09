# Manual del investigador — Simulador Fiscal CIEP

**Para quién es este manual:** para ti, investigadora o investigador del CIEP que va a usar el Simulador Fiscal como herramienta de análisis. No necesitas saber Git, ni programación más allá del Stata que ya usas todos los días.

**Qué versión cubre:** Simulador Fiscal CIEP v8.0.

**Dónde pedir ayuda:** ve directo a la [sección 9](#9-recursos-y-contactos).

---

## Índice

1. [Qué es el Simulador Fiscal CIEP](#1-qué-es-el-simulador-fiscal-ciep)
2. [Cómo empiezas a usarlo](#2-cómo-empiezas-a-usarlo)
3. [El día a día](#3-el-día-a-día)
4. [Los comandos principales](#4-los-comandos-principales)
5. [Convenciones del proyecto](#5-convenciones-del-proyecto)
6. [Cómo sabes qué versión estás usando](#6-cómo-sabes-qué-versión-estás-usando)
7. [Cómo reproduces un análisis viejo](#7-cómo-reproduces-un-análisis-viejo)
8. [Qué hacer si algo falla](#8-qué-hacer-si-algo-falla)
9. [Recursos y contactos](#9-recursos-y-contactos)

---

## 1. Qué es el Simulador Fiscal CIEP

*En esta sección aprendes qué hace el Simulador y por qué te sirve para tu trabajo.*

El Simulador Fiscal CIEP es un conjunto de **comandos de Stata** que descargan, procesan y proyectan la información económica y fiscal de México. En lugar de que tú bajes archivos del INEGI o de la SHCP, los limpies y los armes cada vez, el Simulador lo hace por ti con un solo comando.

Con él puedes:

- **Consultar información oficial ya procesada**: población (CONAPO), PIB e inflación (INEGI), ingresos y gastos públicos (SHCP), deuda pública, cuentas nacionales.
- **Proyectar a largo plazo**: el Simulador extiende las series hacia el futuro (hasta 2070 en el caso demográfico) con supuestos que tú puedes modificar.
- **Analizar el sistema fiscal completo**: quién paga impuestos, quién recibe gasto público y cómo se ve el ciclo de vida fiscal de las y los mexicanos.

El mismo motor tiene tres caras:

| Cara | Quién la usa |
|---|---|
| Comandos en Stata (este manual) | Tú y el equipo de investigación del CIEP |
| Sitio web público ([simuladorfiscal.ciep.mx](https://simuladorfiscal.ciep.mx)) | Cualquier persona, sin Stata |
| Instalación externa (`net install`) | Investigadores fuera del CIEP |

Lo que tú ves en Stata es la versión más completa y flexible de las tres.

---

## 2. Cómo empiezas a usarlo

*En esta sección aprendes dónde vive el Simulador y cómo verificar que está listo en tu máquina.*

### 2.1 Dónde vive

El Simulador vive en una carpeta compartida de Dropbox llamada la **Carpeta del Simulador**:

```
~/Dropbox-CIEP/SimuladorCIEP/
```

> **Nota:** dependiendo de cómo esté configurado Dropbox en tu máquina, la carpeta puede llamarse `CIEP Dropbox` en lugar de `Dropbox-CIEP`. Si tienes duda, pregunta al investigador principal cuál aplica en tu caso.

Dropbox sincroniza esa carpeta automáticamente: cuando se publica una versión nueva del Simulador, te llega sola. Tú no instalas ni actualizas nada.

### 2.2 La configuración inicial (una sola vez, y no la haces tú)

Para que Stata "vea" la Carpeta del Simulador, el investigador principal deja un pequeño archivo de configuración en tu instalación de Stata. Ese archivo le dice a Stata dónde está la carpeta, y a partir de ahí el Simulador se carga solo cada vez que abres el programa.

Si vas a usar el comando `AccesoBIE` (descarga series del INEGI), también necesitas un **token**: una clave personal de acceso, como una contraseña, que el INEGI te da gratis. La configuración del token también es parte de la instalación inicial; el detalle está en `help AccesoBIE` dentro de Stata.

### 2.3 Cómo verificas que está funcionando

Abre Stata. Deberías ver un mensaje de bienvenida parecido a este:

```
Centro de Investigación Económica y Presupuestaria, A.C.

Simulador Fiscal CIEP
 Información Económica:   CGPE 2026
 Año de Valor Presente:   2026
 User:                    tu-usuario

 Poblacion [...]  (help)
 PIBDeflactor [...]  (help)
 SCN [...]  (help)
 ...
```

Ese menú es **clicable**: puedes dar clic sobre el nombre de cada comando para ejecutarlo con opciones de ejemplo, o sobre *(help)* para leer su documentación.

**Si no ves este mensaje**, el Simulador no está configurado en tu máquina. Ve a la [sección 8](#8-qué-hacer-si-algo-falla).

---

## 3. El día a día

*En esta sección aprendes qué pasa al abrir Stata y las dos formas de trabajar con el Simulador.*

### 3.1 Qué pasa cada vez que abres Stata

Al abrir Stata, el Simulador automáticamente:

1. Aplica el **estilo gráfico CIEP** (colores, tipografía) a todas tus gráficas.
2. Define los **parámetros generales**: el año de valor presente, el paquete económico vigente (por ejemplo, "CGPE 2026") y los supuestos de crecimiento del PIB e inflación.
3. Muestra el menú de comandos que viste en la sección anterior.

No tienes que hacer nada: cuando aparece el menú, ya puedes trabajar.

### 3.2 Las dos formas de trabajar

**Forma 1 — Comandos individuales (tu día a día).** Escribes un comando en la consola y obtienes tablas, gráficas y una base de datos lista en memoria:

```stata
Poblacion, anioinicial(2026) aniofinal(2050)
```

Qué esperas ver: tablas con totales poblacionales, pirámides demográficas y la base de datos cargada en Stata, lista para que sigas trabajando sobre ella.

**Forma 2 — La simulación integral (`SIM.do`).** Es el archivo maestro que corre todo el Simulador de principio a fin: demografía → economía → hogares → ingresos → gastos → deuda → ciclo de vida fiscal. Tarda varios minutos y termina con el mensaje `TOUCH-DOWN!!!`. La usas cuando necesitas el escenario fiscal completo, no para consultas puntuales.

### 3.3 La primera corrida descarga datos (y es normal que tarde)

Algunos comandos usan archivos de datos pesados (la ENIGH, las Cuentas Públicas) que no viven en Dropbox. La primera vez que un comando los necesita, el Simulador los **descarga automáticamente** desde el repositorio de datos del proyecto en internet, y verifica que cada archivo llegó completo y sin alteraciones antes de usarlo.

Qué esperas ver: mensajes de descarga en la consola la primera vez. Las siguientes corridas ya no descargan nada y son mucho más rápidas.

Si una descarga falla (por ejemplo, sin internet), el comando se detiene con un mensaje explícito. Ve a la [sección 8](#8-qué-hacer-si-algo-falla).

### 3.4 Dónde quedan tus resultados

Todo lo que el Simulador genera para ti (gráficas, bases intermedias) se guarda en **tu carpeta personal** dentro de la Carpeta del Simulador:

```
users/tu-usuario/
```

🧠 **Concepto: espacio personal de trabajo.** Cada quien tiene su carpeta dentro de `users/`, identificada con su nombre de usuario. Así varios investigadores pueden trabajar sobre la misma copia del Simulador sin pisarse los resultados: lo tuyo queda en tu carpeta, lo de tu colega en la suya.

---

## 4. Los comandos principales

*En esta sección conoces los 10 comandos del Simulador y qué hace cada uno. El detalle completo de cada comando (todas sus opciones, ejemplos y resultados) está en su ayuda dentro de Stata: escribe `help` seguido del nombre del comando.*

### Vista rápida

| Comando | Qué te da | Fuente |
|---|---|---|
| `Poblacion` | Población, defunciones y migración, 1950–2070 | CONAPO |
| `PIBDeflactor` | PIB, deflactor e inflación, con proyecciones | INEGI (BIE) |
| `SCN` | Cuentas nacionales: composición del PIB | INEGI (BIE y CSI) |
| `LIF` | Ingresos públicos federales desde 1993 | SHCP |
| `PEF` | Gasto público federal desde 2013 | SHCP |
| `SHRFSP` | Deuda pública en su medida más amplia | SHCP |
| `DatosAbiertos` | Cualquier serie de finanzas públicas | SHCP |
| `AccesoBIE` | Cualquier serie económica del INEGI | INEGI (BIE) |
| `GastoPC` ⚠️ | Gasto per cápita por función, en la ENIGH | SHCP + INEGI |
| `TasasEfectivas` ⚠️ | Tasas efectivas de tributación | INEGI + SHCP |

⚠️ = comando **en construcción**: funciona, pero su interfaz puede cambiar. Úsalo con acompañamiento del investigador principal.

### 4.1 `Poblacion` — Demografía

Descarga y procesa las proyecciones de población del CONAPO: habitantes por edad, sexo y entidad federativa, de 1950 a 2070. Genera pirámides poblacionales y la transición demográfica.

```stata
Poblacion, anioinicial(2026) aniofinal(2050)
Poblacion if entidad == "Jalisco", anioinicial(2026) aniofinal(2050)
```

Detalle: `help Poblacion`

### 4.2 `PIBDeflactor` — PIB, precios e inflación

Es el comando base del Simulador: genera el PIB y el deflactor (el índice que convierte pesos corrientes en pesos constantes) que usan todos los demás comandos. Permite construir escenarios modificando los supuestos de crecimiento.

```stata
PIBDeflactor, aniovp(2026) aniomax(2031)
```

Detalle: `help PIBDeflactor`

### 4.3 `SCN` — Cuentas nacionales

Descompone el PIB por sus tres métodos de cálculo (producción, ingreso y gasto) y obtiene cuánto del ingreso nacional va al trabajo, al capital y a la depreciación. Es insumo clave para el análisis de tasas efectivas.

```stata
SCN, anio(2026)
```

Detalle: `help SCN`

### 4.4 `LIF` — Ingresos públicos

Ingresos presupuestarios federales desde 1993: ISR, IVA, IEPS, ingresos petroleros y demás. Compara años, calcula elasticidades y puede proyectar el cierre del año en curso.

```stata
LIF, anio(2026)
LIF, anio(2026) desde(2016) by(divLIF)
```

Detalle: `help LIF`

### 4.5 `PEF` — Gasto público

Gasto federal desde 2013, combinando automáticamente la mejor fuente disponible para cada año: gasto ejercido (Cuenta Pública), aprobado (PEF) o proyecto (PPEF). Permite agrupar por función, ramo o capítulo.

```stata
PEF, anio(2026)
PEF, anio(2026) by(ramo) minimum(0.5)
```

Detalle: `help PEF`

### 4.6 `SHRFSP` — Deuda pública

El Saldo Histórico de los Requerimientos Financieros del Sector Público: la medida más amplia de deuda pública en México. Analiza su evolución, composición y costo.

```stata
SHRFSP, anio(2026) ultanio(2010)
```

Detalle: `help SHRFSP`

### 4.7 `DatosAbiertos` — Series fiscales de la SHCP

Acceso directo a cualquiera de las más de 500 series de las Estadísticas Oportunas de Finanzas Públicas, usando su clave (por ejemplo, `XAB` = ingresos totales). Enriquece la serie con PIB, deflactor y población.

```stata
DatosAbiertos XAB
DatosAbiertos XAA, desde(2015)
```

Detalle: `help DatosAbiertos` (incluye cómo encontrar la clave de una serie)

### 4.8 `AccesoBIE` — Series económicas del INEGI

Descarga directamente a Stata cualquier serie del Banco de Información Económica del INEGI (más de 200,000 series) usando su clave numérica.

```stata
AccesoBIE 734407, nombres(PIBNominal)
```

**Requiere token**: una clave personal gratuita del INEGI. Si no está configurada, el comando se detiene con un error que te dice exactamente qué hacer. Detalle: `help AccesoBIE`.

### 4.9 `GastoPC` — Gasto per cápita ⚠️ en construcción

Calcula cuánto gasta el gobierno por persona en cada función (educación por alumno, salud por asegurado, pensión por pensionado) y lo distribuye entre los individuos de la ENIGH.

```stata
GastoPC educacion salud
```

Detalle: `help GastoPC`

### 4.10 `TasasEfectivas` — Carga fiscal efectiva ⚠️ en construcción

Calcula las tasas efectivas de tributación: el cociente entre lo que el gobierno realmente recauda por cada impuesto y la base económica sobre la que recae.

```stata
TasasEfectivas, anio(2026)
```

Detalle: `help TasasEfectivas`

---

## 5. Convenciones del proyecto

*En esta sección aprendes las reglas de convivencia: qué puedes tocar, qué no, y por qué.*

### 5.1 Qué SÍ puedes hacer

- **Correr cualquier comando** con las opciones que quieras: los comandos solo leen los datos del Simulador, no los alteran.
- **Guardar tus análisis en tu carpeta personal** (`users/tu-usuario/`): do-files propios, bases derivadas, gráficas.
- **Cambiar los supuestos de tu corrida**: los escenarios de crecimiento del PIB, deflactor e inflación se definen con parámetros que puedes ajustar. Pide al investigador principal que te muestre cómo la primera vez.

### 5.2 Qué NO debes hacer

| Regla | Por qué |
|---|---|
| No edites los archivos `.ado` ni los archivos de configuración (`profile.do`, `SIM.do`, `sysprofile-template.do`) | Son el motor compartido. Un cambio tuyo afecta a todo el equipo, porque Dropbox lo sincroniza a todas las máquinas. |
| No guardes archivos fuera de tu carpeta `users/` | Todo lo que quede fuera se mezcla con el motor y estorba a los demás. |
| No borres los directorios con prefijo numérico (`01_modulos/`, `02_governance/`, `03_help/`, `04_simuladorfiscal.ciep.mx/`, `05_scripts/`) | Contienen código, documentación y configuración que NO se regeneran solos. Ver sección 5.3. |
| No "arregles" un error del Simulador por tu cuenta | Repórtalo (sección 8). Si lo parchas localmente, tu copia diverge de la del equipo y tus resultados dejan de ser comparables. |

🧠 **Concepto: separación entre motor y trabajo personal.** El Simulador distingue entre el *motor* (comandos y datos compartidos, que mantiene el investigador principal) y el *trabajo personal* (tu carpeta `users/`). Mientras respetes esa frontera, es imposible que rompas algo para los demás.

### 5.3 Estructura del repo para el investigador nuevo

*En esta sección aprendes qué hay en cada carpeta del Simulador, cuáles puedes borrar y qué pasa si las borras.*

Los directorios de la carpeta del Simulador siguen una convención de nombres que te dice, sin preguntar a nadie, qué puedes tocar:

| Directorio | ¿Qué contiene? | ¿Puedes borrarlo? |
|---|---|---|
| `01_modulos/` | Los `.do` del pipeline (módulos de análisis y visualizaciones) y código histórico en `01_modulos/legacy/` | **No** |
| `02_governance/` | Documentación de administración del proyecto y el `CHANGELOG.md` (registro de cambios por versión) | **No** |
| `03_help/` | La ayuda: los `.sthlp` de cada comando, este manual y las imágenes de documentación | **No** |
| `04_simuladorfiscal.ciep.mx/` | Archivos del sitio web público | **No** |
| `05_scripts/` | Scripts de publicación y sus manifiestos (los usa el investigador principal) | **No** |
| `raw/` (incluye `raw/temp/`) | Datos crudos descargados de fuentes oficiales y archivos intermedios de cada corrida | Sí |
| `master/` | Bases procesadas listas para usar | Sí |
| `users/tu-usuario/` | Tu espacio personal: do-files, bases derivadas, gráficas | Sí (solo el tuyo) |
| `users/tu-usuario/graphs/` | Las gráficas que generan los comandos del Simulador | Sí — se regenera en la siguiente corrida |

**La regla es simple:** los directorios **con prefijo numérico** (`01_`, `02_`…) son permanentes — no los borres ni los muevas. Los directorios **sin prefijo** son restablecibles — el propio Simulador los regenera.

**Qué pasa cuando borras un directorio restablecible:**

- **`raw/`** — en la siguiente corrida, el Simulador vuelve a descargar cada insumo desde el repositorio institucional en GitHub y verifica su integridad automáticamente (lo hace el comando interno `ensure_asset`). Cuesta tiempo de descarga (varios GB en algunos casos), pero no se pierde nada.
- **`master/`** — las bases se reconstruyen corriendo el pipeline completo. También cuesta tiempo, tampoco se pierde nada.
- **`users/tu-usuario/`** — es tu espacio personal; bórralo solo si ya no necesitas lo que hay dentro, porque **eso sí no se regenera**. Nunca borres la carpeta de otra persona.

**Dónde viven las gráficas.** Todas las gráficas que generan los comandos del Simulador se guardan únicamente en `users/tu-usuario/graphs/` — nunca en la raíz del repo. No tienes que crear esa carpeta ni configurar nada: los comandos escriben ahí automáticamente. Si borras tu `graphs/`, las gráficas se regeneran la próxima vez que corras los comandos que las producen.

Los archivos sueltos en la raíz (los `.ado` de los comandos, los `scheme-*.scheme` de las gráficas, `SIM.do`, `profile.do`) tampoco se tocan: Stata los busca exactamente ahí y moverlos rompe los comandos para todo el equipo.

### 5.4 Clon experimental: probar mejoras sin afectar al equipo

*En esta sección aprendes a montar una copia separada del Simulador para experimentar, sin riesgo de romper la copia que usa todo el equipo.*

**Cuándo lo necesitas.** La regla de §5.2 es clara: no edites el motor compartido, porque Dropbox propaga tu cambio a todas las máquinas. Pero hay trabajo legítimo que exige tocar el motor: probar una mejora a un comando institucional, experimentar con un dataset nuevo, o desarrollar un módulo antes de proponerlo. Para eso existe el **clon experimental**: una copia completa e independiente del Simulador que vive solo en tu Mac. Lo que hagas ahí no toca la copia institucional ni le llega a nadie más.

**Paso 1 — Clona el repositorio a una carpeta local.** "Clonar" significa descargar una copia completa del proyecto desde GitHub, con toda su historia. En la Terminal de tu Mac:

```bash
git clone https://github.com/rcantuc/SimuladorCIEP.git ~/experimental/SimuladorCIEP
```

Qué esperas ver: mensajes de descarga (`Cloning into...`, contadores de objetos) y al final una carpeta `~/experimental/SimuladorCIEP` con el proyecto completo. Si falla con `git: command not found`, tu máquina no tiene Git instalado; pídeselo al investigador principal.

**Paso 2 — Configura tu sysprofile para elegir clon al abrir Stata.** El *sysprofile* es un pequeño archivo de configuración (`sysprofile.do`) que vive en tu instalación de Stata y le dice dónde está el Simulador. La plantilla `sysprofile-template.do` (en la raíz del Simulador) trae los dos casos documentados: un solo clon (lo normal) y un menú para elegir entre varios clones cada vez que abres Stata. Copia la plantilla como `sysprofile.do` en la carpeta de tu instalación de Stata, descomenta el menú del "CASO 2" y ajusta las rutas a tus clones.

Qué esperas ver: al abrir Stata, un menú te pregunta qué proyecto cargar; escribes el número y esa sesión trabaja contra el clon elegido.

**Las dos reglas de convivencia:**

| Regla | Por qué |
|---|---|
| El clon experimental es **local a tu Mac** — nunca lo pongas dentro de la carpeta Dropbox-CIEP institucional | Si vive en Dropbox, tus experimentos se propagan a las máquinas de todo el equipo, que es exactamente lo que queremos evitar. |
| El archivo `simulador.stpr` (el proyecto del Project Manager de Stata) se registra en Git **solo cuando lo modificas intencionalmente** (agregar items, reorganizar el árbol) | Stata lo re-guarda automáticamente cada vez que abres el proyecto, aunque no hayas cambiado nada. Registrar esos saves automáticos ensucia la historia del proyecto con cambios vacíos. |

🧠 **Concepto: clon.** Git permite que existan muchas copias completas del mismo proyecto ("clones"), cada una con vida propia. El clon institucional (el de Dropbox) es la referencia del equipo; tu clon experimental es tu laboratorio. Si un experimento sale bien, se lo propones al investigador principal para que lo incorpore formalmente; si sale mal, borras la carpeta y no pasó nada.

---

## 6. Cómo sabes qué versión estás usando

*En esta sección aprendes a identificar la versión exacta del Simulador con la que generaste un resultado.*

### 6.1 Por qué importa

Si publicas un número (por ejemplo, "el gasto en pensiones llegará a 6.9% del PIB"), necesitas poder decir *con qué versión del Simulador lo calculaste*. Las fuentes oficiales se actualizan, la metodología se afina, y el mismo comando puede dar un número ligeramente distinto seis meses después. La versión es tu referencia.

### 6.2 La receta

Copia y pega esto en la consola de Stata:

```stata
! git -C "`c(sysdir_site)'" log --oneline -1
```

Qué esperas ver: una línea con un código corto y una descripción, por ejemplo:

```
aec0e45 docs(release): actualiza notas de la versión v8.0
```

Ese código corto (`aec0e45`) identifica de forma única el estado exacto del Simulador en ese momento. **Anótalo junto a cualquier resultado que vayas a publicar o presentar.**

Si el comando falla con un mensaje tipo `git: command not found`, tu máquina no tiene Git instalado; pídele al investigador principal que lo instale (es parte de la configuración inicial).

### 6.3 El número de versión

Además del código corto, el Simulador tiene un número de versión pública (hoy: **v8.0**). Se lee así: el primer número (8) sube cuando cambia la metodología o los resultados; el segundo (0) cuando hay mejoras que no alteran resultados. Si dos personas usan la misma versión, deben obtener los mismos números.

🧠 **Concepto: trazabilidad.** Poder responder "¿con qué versión y qué datos se calculó este número?" meses después de publicarlo. Es lo que distingue un resultado defendible de uno irreproducible. El código de la receta 6.2 + la fecha de corrida son el mínimo que debes registrar.

> **Próximamente:** está previsto que el mensaje de bienvenida de Stata muestre la versión y los últimos cambios automáticamente, para que no tengas que correr la receta.

---

## 7. Cómo reproduces un análisis viejo

*En esta sección aprendes qué hacer cuando necesitas volver a generar un resultado calculado con una versión anterior.*

**Cuándo lo necesitas:** te piden defender un número publicado hace un año, o quieres comparar cuánto cambió una proyección entre dos versiones del Simulador.

**La vía más simple:** pídeselo al investigador principal, dándole dos datos:

1. El código de versión con el que se generó el resultado (el que anotaste siguiendo la sección 6.2 — o la fecha aproximada de la corrida, si no lo tienes).
2. Qué comando o análisis quieres reproducir.

El investigador principal puede reconstruir el Simulador exactamente como estaba en esa versión, con los datos de entonces, y correr el análisis.

**Si quieres hacerlo tú:** el proceso son tres pasos — ubicarte en la versión que necesitas con `git checkout v8.0.X`, abrir Stata (el `profile.do` descarga automáticamente los datos de esa versión desde GitHub, verificados contra su huella digital), y correr `SIM.do`. El proceso completo está documentado en la sección "Cómo reproducir resultados de una versión específica" del [README](../README.md) del repositorio. Importante: hazlo en un clon aparte del repositorio en tu computadora, **nunca en la carpeta compartida de Dropbox** — esa copia la administra el investigador principal.

**La regla de oro:** nunca intentes reconstruir una versión vieja a mano (bajando datos antiguos, comentando líneas, ajustando parámetros "como estaban"). Es la receta perfecta para producir un número que *parece* el de antes pero no lo es.

---

## 8. Qué hacer si algo falla

*En esta sección encuentras los problemas más comunes, cómo se ven y qué hacer.*

### 8.1 No aparece el mensaje de bienvenida al abrir Stata

**Cómo se ve:** abres Stata y no hay banner del Simulador, solo el Stata normal.

**Qué hacer:** copia y pega en la consola:

```stata
di "`c(sysdir_site)'"
```

Si el resultado **no** es la ruta de la Carpeta del Simulador (algo como `.../SimuladorCIEP/`), la configuración inicial de tu máquina falta o se movió. Contacta al investigador principal con el resultado que te dio el comando.

### 8.2 Stata dice `command Poblacion not recognized` (o cualquier otro comando)

**Cómo se ve:** error `unrecognized command` en rojo.

**Qué hacer:** es el mismo problema que 8.1 (Stata no encuentra la Carpeta del Simulador). Aplica el mismo diagnóstico.

### 8.3 `AccesoBIE` falla pidiendo un token

**Cómo se ve:** error explícito que menciona el token y la página del INEGI.

**Qué hacer:** tu token no está configurado. La solución paso a paso está en `help AccesoBIE`, sección "Configuración del token". Si no tienes token, ahí mismo viene el enlace para solicitarlo al INEGI (es gratuito e inmediato).

### 8.4 Falla la descarga de datos en la primera corrida

**Cómo se ve:** un comando se detiene con un error que menciona la descarga o verificación de un archivo.

**Qué hacer:**

1. Verifica que tienes internet y vuelve a correr el comando (las descargas se reintentan desde donde quedaron).
2. Si falla de nuevo con el mismo mensaje, repórtalo (sección 8.6). No intentes descargar el archivo a mano.

### 8.5 Un comando corre pero el resultado se ve raro

Números que no cuadran, años faltantes, gráficas vacías. **No lo parches por tu cuenta**: puede ser un cambio en la fuente oficial que el Simulador aún no absorbe. Repórtalo.

### 8.6 Cómo reportar un problema

Manda al investigador principal estos cuatro datos (los primeros tres los copias de tu consola):

1. El comando **exacto** que corriste, con todas sus opciones.
2. El mensaje de error completo (en rojo).
3. El resultado de la receta de versión (sección 6.2).
4. Qué esperabas que pasara.

Con eso, el diagnóstico casi siempre es inmediato. Sin eso, empieza un ping-pong de preguntas.

---

## 9. Recursos y contactos

*Dónde buscar más información, en orden.*

1. **La ayuda de cada comando** — siempre tu primera parada. En Stata:

   ```stata
   help Poblacion
   ```

   Cada ayuda tiene descripción, ejemplos listos para copiar, opciones y referencias a las fuentes oficiales. Es la **fuente única de verdad** sobre cada comando: se audita contra el código real y no existe documentación paralela por comando en otro formato.

2. **Este manual** — para las reglas del proyecto y los problemas comunes.

3. **La documentación de gobernanza** (carpeta `02_governance/` del Simulador) — si quieres profundizar en cómo se administra el proyecto: cómo se publican versiones, cómo se distribuye, cómo se reproduce una versión vieja. No la necesitas para el trabajo diario.

4. **El sitio web público** ([simuladorfiscal.ciep.mx](https://simuladorfiscal.ciep.mx)) — para consultas rápidas sin abrir Stata.

**Contacto:** Ricardo Cantú Calderón — <ricardocantu@ciep.mx>
