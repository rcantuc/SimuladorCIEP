# Guía: cómo construir y gobernar un simulador

**Para quién es:** para quien va a construir su propio simulador de política pública en Stata y quiere que, dentro de dos años, siga funcionando, se pueda explicar y se pueda defender. Asume Stata básico y poco o nada de Git. No asume que conoces el Simulador Fiscal CIEP: aquí aparece como ejemplo trabajado, no como objeto de estudio.

**Qué es un simulador, para efectos de esta guía:** un programa que toma datos oficiales, aplica una metodología explícita y produce cifras que otros van a citar. Esa última parte —*que otros van a citar*— es lo que lo distingue de un script de análisis y lo que obliga a gobernarlo. Un script que corre una vez y produce una gráfica no necesita gobernanza. Un modelo que alimenta un libro, un sitio web y la respuesta a un periodista, sí.

**Cómo leerla:** doce principios. Cada uno tiene la misma estructura: **la regla**, **por qué** (casi siempre con el incidente que la originó, con fecha), **cómo lo hace el CIEP** (la ruta exacta en este repositorio, para que lo veas funcionando) y **en tu simulador** (qué haces desde el día uno). Al final hay una lista de arranque para la primera semana y un mapa hacia los documentos de norma del CIEP, que son la versión precisa y específica de todo lo que aquí está dicho en general.

---

## Índice

1. [Un simulador es un motor, no un script](#1-un-simulador-es-un-motor-no-un-script)
2. [Los números tienen una sola fuente](#2-los-números-tienen-una-sola-fuente)
3. [Separa lo permanente de lo regenerable](#3-separa-lo-permanente-de-lo-regenerable)
4. [Los datos se descargan, se verifican y se cachean](#4-los-datos-se-descargan-se-verifican-y-se-cachean)
5. [Falla en el origen, con un mensaje que diga qué hacer](#5-falla-en-el-origen-con-un-mensaje-que-diga-qué-hacer)
6. [Una versión es código + datos + registro, y no se edita](#6-una-versión-es-código--datos--registro-y-no-se-edita)
7. [Un commit, una idea; y escribe lo que decidiste no hacer](#7-un-commit-una-idea-y-escribe-lo-que-decidiste-no-hacer)
8. [Demuestra, no razones](#8-demuestra-no-razones)
9. [Publicar tiene compuertas](#9-publicar-tiene-compuertas)
10. [Los secretos no viven en el repositorio](#10-los-secretos-no-viven-en-el-repositorio)
11. [Coincidir no es verificar](#11-coincidir-no-es-verificar)
12. [La gobernanza también se gobierna](#12-la-gobernanza-también-se-gobierna)
- [Tu simulador en la semana 1](#tu-simulador-en-la-semana-1)
- [Mapa de lectura: de la guía a la norma](#mapa-de-lectura-de-la-guía-a-la-norma)

---

## 1. Un simulador es un motor, no un script

**La regla.** Cada pieza de cálculo es un comando de Stata (`.ado`) con sintaxis declarada, opciones con valores por defecto, un archivo de ayuda y una sola responsabilidad. Los `.do` solo orquestan: llaman comandos en orden, no calculan.

**Por qué.** Un `.do` de 3,000 líneas funciona mientras lo opera la persona que lo escribió. El día que otra persona necesita *solo* la parte de deuda, o correr el modelo con otro año, o entender de dónde salió una cifra, el `.do` monolítico no ofrece puntos de entrada. El Simulador Fiscal CIEP vivió así hasta v7 —"cuerpo de archivos en la computadora del investigador principal con conocimiento metodológico tácito y unipersonal", según su propia historia de versiones— y la transición a v8 consistió, en buena medida, en convertirlo en motor.

**Cómo lo hace el CIEP.** En la raíz del repo hay un `.ado` por cuenta o fuente: `Poblacion`, `PIBDeflactor`, `SCN`, `LIF`, `PEF`, `SHRFSP`, `AccesoBIE`, `DatosAbiertos`. Cada uno acepta `anio()` y opciones como `update` o `nographs`, devuelve resultados en escalares con nombre, y tiene su `.sthlp` en `03_help/Stata/`. `SIM.do` los llama en secuencia; `01_modulos/` contiene los análisis que los consumen. Un comando se puede correr solo: `SCN, anio(2026)` reconstruye la cuenta de generación del ingreso sin tocar nada más. Para que esto no se desincronice, existe una auditoría de que cada opción documentada en el `.sthlp` existe en el `.ado` y viceversa (`historico/auditoria-drift-sthlp.md`), y el gate 7 de publicación verifica que cada `.pkg` liste todos los `.ado` que invoca.

**En tu simulador.** Antes de escribir la primera línea de cálculo, decide los comandos: uno por fuente de datos, uno por bloque metodológico. Dale a cada uno `syntax [, ANIO(int ...) UPDATE NOGraphs]` desde el principio, aunque hoy solo tenga un uso. Escribe el `.sthlp` el mismo día que el `.ado`; si lo dejas para después, nunca llega. Tu `.do` principal debe leerse como un índice: llamadas en orden, sin cálculos; si un bloque de cálculo empieza a crecer ahí, es un comando que todavía no tiene nombre.

---

## 2. Los números tienen una sola fuente

**La regla.** Todo número que sale del simulador hacia cualquier destino —tabla, gráfica, PDF, página web, tuit— se produce una sola vez, en el motor, con tipo y unidad declarados, y los destinos lo *renderizan*. Nadie recalcula, redondea a mano ni copia de una pantalla.

**Por qué.** Cuando aparece una segunda fuente de verdad (una hoja de cálculo donde alguien "ajustó" el número, un literal escrito a mano en el documento), funciona bien un tiempo, diverge en silencio y, cuando alguien nota la diferencia, nadie recuerda de dónde salió. El censo del documento del Paquete Económico 2026 encontró 89 grupos de cifras escritas como literales en la prosa; cada una era una divergencia potencial que ningún proceso iba a detectar.

**Cómo lo hace el CIEP.** El contrato se llama `escalar` (`escalar.ado`, en la raíz del repo): `escalar pctpib YlPIB = Yl[`obs']/PIB[`obs']*100`. El tipo (`pctpib`, `pct`, `mxn`, `mxnpc`, `personas`, `anio`) fija el formato de salida; el valor se guarda con precisión completa y el formato se aplica una sola vez, al exportar. `scalarlatex` escribe los escalares a `.tex` para el libro; `scalarjson` los escribe a JSON para la web. Y hay un mecanismo de deriva: `scalarlatex` compara los escalares que *no* pasaron por `escalar` contra una lista auditada (`scalarlatex-baseline.txt`); un nombre nuevo fuera de esa lista se reporta en rojo porque casi siempre es un `scalar` que alguien escribió sin migrar. El principio completo, aplicado a la web, está en `principio-stata-produce-los-numeros.md`.

**En tu simulador.** Define un catálogo de tipos antes de tener diez escalares, no después de tener quinientos. Escribe un comando `escalar` propio (o copia la idea) que registre nombre y tipo, y que todos los destinos lean de ahí. Prohíbete, por escrito, poner cifras a mano en los documentos: si un número no viene del registro, no entra.

---

## 3. Separa lo permanente de lo regenerable

**La regla.** El repositorio distingue a simple vista lo que es código y norma (permanente, versionado) de lo que es dato descargado, resultado intermedio o salida por usuario (regenerable, fuera de Git). Borrar lo regenerable debe ser siempre seguro.

**Por qué.** Si no está claro qué se puede borrar, nadie borra nada, los directorios crecen a gigabytes y un `git add .` accidental sube datos pesados —o credenciales— al repositorio. El inventario del 2026-08-01 encontró ~9 GB sin trackear y sin ignorar en este repo, incluidos dos `wp-config.php` con contraseñas reales de base de datos; un solo `git add .` los habría publicado.

**Cómo lo hace el CIEP.** Convención de prefijos: los directorios con número (`01_modulos/`, `02_governance/`, `03_help/`, `04_*` sitios, `05_scripts/`) son permanentes; los sin prefijo (`raw/`, `raw/temp/`, `master/`, `users/`) los regenera el pipeline y están en `.gitignore`. Hay una prueba de que la regla se cumple: `05_scripts/test-maquina-virgen.sh` borra `raw/` y `master/` y verifica que el simulador se reconstruye desde cero (ver §4). Y `05_scripts/verify_gitignore.sh` comprueba que lo que debe ignorarse se ignora y lo que debe versionarse no.

**En tu simulador.** Día uno: crea `raw/`, `master/`, `users/` y mételos al `.gitignore` antes de descargar el primer archivo. Ponle prefijo numérico a todo lo demás. Cada tanto, borra `master/` y vuelve a correr: si algo no se reconstruye, encontraste un dato que dependía de tu máquina.

---

## 4. Los datos se descargan, se verifican y se cachean

**La regla.** Cada archivo de datos que el simulador necesita está declarado en un manifiesto con su nombre, su ruta, su huella SHA-256 y su tamaño. Un comando único lo descarga si falta, verifica la huella si existe y **aborta si no coincide**. No adivina.

**Por qué.** Los datos cambian por fuera del código: alguien actualiza el Excel de la Ley de Ingresos, el INEGI republica una serie, un archivo se corrompe al sincronizar. Sin candado, el modelo corre con datos distintos a los que el código cree tener y los resultados cambian sin que ningún commit lo explique. El 2026-09-08 el equipo cargó la ILIF 2027 en `LIFs.xlsx`; el archivo cambió, el manifiesto no, y el candado detuvo la corrida. Eso no fue un error del candado: fue el candado haciendo exactamente su trabajo.

**Cómo lo hace el CIEP.** `05_scripts/manifest.json` declara los assets; `ensure_asset.ado` es el candado y corre cada vez que un módulo pide un archivo. Los assets viven como adjuntos del GitHub Release de cada versión, así que una máquina sin `raw/` los descarga del Release correcto. Cuando el candado detiene, el mensaje de error trae la receta completa (los ocho pasos, con el SHA ya calculado) y apunta a `runbook-actualizar-assets.md`. Para la temporada en que `raw/` cambia a diario (septiembre, Paquete Económico) existe un modo de aviso sin bloqueo (`global rawwip`) que el gate 5 de publicación obliga a apagar antes de publicar. Y el gate 6 cierra el otro flanco: todo asset del manifiesto debe ser solicitado por algún módulo —en v8.3.0 dos archivos estaban en el manifiesto y en el Release pero ningún módulo los pedía, y una máquina virgen simplemente no los tenía.

**En tu simulador.** Tu primera fuente de datos ya merece manifiesto: un JSON con nombre, ruta, SHA-256 y tamaño. Escribe el comando que lo verifica y hazlo la única puerta por la que entran archivos. Publica los datos como adjuntos del Release, no en el repo. Y cuando el candado te detenga, resiste la tentación de comentarlo "nada más por hoy".

---

## 5. Falla en el origen, con un mensaje que diga qué hacer

**La regla.** Cuando algo externo cambia de formato o una precondición no se cumple, el programa se detiene en el punto donde el problema nace, con un mensaje que nombre el problema y el siguiente paso. No se deja que el error aparezca más tarde, en otro comando, con otro nombre.

**Por qué.** El 2026-10-03 el INEGI empezó a marcar la cifra preliminar del año como `"2025 p1"` (con espacio) en vez de `"2025/p1"`. La rutina de descarga no la reconoció, el año quedó como texto en vez de número, y once cruces de bases después `SCN, update` falló con `key variable anio is str7 in master but int in using data`. El mensaje era correcto y completamente inútil: no decía qué base, ni por qué, ni qué hacer. La corrección tuvo dos partes, y la segunda es la que importa aquí: además de limpiar el formato nuevo, `AccesoBIE` ahora verifica al terminar que `anio` sea numérico y, si no, aborta ahí mismo listando los periodos que no pudo convertir.

**Cómo lo hace el CIEP.** `AccesoBIE.ado`: después de construir `anio`, `capture confirm numeric variable anio` y, si falla, `levelsof` de los valores no numéricos + `exit 109`. `ensure_asset.ado`: cuando la huella no coincide, imprime la receta de ocho pasos con los valores ya calculados. `escalar.ado`: si el tipo no está en el catálogo, lo dice y lista el catálogo. En los tres casos el mensaje responde *qué pasó* y *qué sigue*.

**En tu simulador.** Después de cada paso que depende del mundo exterior (descargar, importar, cruzar), pon una verificación de la forma que esperas (`confirm numeric variable`, `assert _N > 0`, `assert _merge == 3`) y un mensaje que un colega pueda seguir sin llamarte. Cuando un error te llegue "de lejos", no lo arregles solo donde apareció: pregúntate dónde debió haberse detenido y pon la guardia ahí.

---

## 6. Una versión es código + datos + registro, y no se edita

**La regla.** Una versión publicada es la combinación inmutable de tres cosas: el código, los datos de entrada declarados en el manifiesto y la entrada del CHANGELOG que dice qué cambió. Se marca con una etiqueta de Git (`vX.Y.Z`). Una vez publicada no se borra ni se modifica: si tiene un error, se publica una corrección como versión nueva. **Commit no es versión**: solo hay versión si cambió lo que se distribuye.

**Por qué.** Es la misma lógica de una publicación académica: cuando un libro cita "Simulador Fiscal v8.2", esa cita es una promesa de que cualquiera puede volver a v8.2 y obtener los mismos números. Editar v8.2 después rompe la promesa; publicar v8.2.1 con nota la cumple. El esquema de tres números dice qué tan grave es la diferencia: mayor cuando cambia la metodología y los resultados dejan de ser comparables, menor cuando entran datos o módulos nuevos, parche cuando se corrige algo sobre una versión ya citada.

**Cómo lo hace el CIEP.** `git tag -a v8.4.2`, Release en GitHub con los assets, entrada `## [v8.4.2] — 2026-09-23` en `CHANGELOG.md`, y `manifest.json` con `version` y `release_tag` apuntando a la misma etiqueta. `profile.do` lee el manifiesto al abrir Stata y muestra la versión en el banner; `sim_changelog` la consulta desde Stata. Reproducir una versión vieja es `git clone` + `git checkout v8.2.0` y dejar que el candado descargue los datos de ese Release. Las reglas de cuándo sube cada número, con casos reales, están en `versionado-y-git.md` §3.

**En tu simulador.** Crea el `CHANGELOG.md` antes de la primera versión, con el formato que vas a respetar (`## [vX.Y.Z] — AAAA-MM-DD` y categorías fijas). Tu primera versión puede ser `v0.1.0`; lo que importa es que exista la etiqueta y que el manifiesto la nombre. Nunca edites una etiqueta ya publicada.

---

## 7. Un commit, una idea; y escribe lo que decidiste no hacer

**La regla.** Cada commit contiene un solo cambio con sentido propio y un mensaje que explica el *porqué*. Si el commit descarta una alternativa que parecía obvia, el mensaje lo dice. Si una regla nace de un incidente, el mensaje cita el commit del incidente por su SHA.

**Por qué.** El historial de Git es la única memoria que no depende de que alguien se acuerde. Un commit que mezcla "corrige la fórmula de deuda" con "reformatea 400 líneas de espacios" vuelve imposible revisar la fórmula. Un mensaje que dice "arreglo" no sirve dentro de seis meses; uno que dice "la línea 469 leía el escalar con `subinstr()` y habría tronado con `r(109)` en producción al volverse numérico" sí. Y la documentación negativa —*consideramos X y lo descartamos porque Y*— evita que la siguiente persona vuelva a recorrer el mismo callejón.

**Cómo lo hace el CIEP.** Formato `tipo(ámbito): descripción` (`fix(AccesoBIE): …`, `docs(governance): …`), cuerpo en párrafos separados con varias banderas `-m`, descripción corta en español sin punto final. `git diff` antes de `git add` y `git status` + `git diff --cached` antes de `git commit`, siempre. La convención completa, con el caso real del editor que reformateó tablas y contaminó un diff, está en `versionado-y-git.md` §1. La bitácora congelada en `historico/bitacora-arquitectura.md` es un ejemplo de documentación negativa sostenida durante meses: cada decisión con su alternativa descartada.

**En tu simulador.** Antes de cada commit, pregúntate si podrías describirlo en una línea sin usar "y". Si no, son dos commits. Escribe en el cuerpo la alternativa que descartaste, aunque te parezca obvio: dentro de un año no lo será.

---

## 8. Demuestra, no razones

**La regla.** Cuando cambias algo que no debería alterar resultados (una migración, una refactorización, un cambio de formato), la evidencia de que no los alteró es una comparación mecánica de salidas antes y después, no un argumento de por qué no debería haberlos alterado.

**Por qué.** Los argumentos tienen huecos que el código no perdona. En la migración de `Simulador.ado` al contrato `escalar` (v8.0.13, julio de 2026), el razonamiento decía que nueve sitios cambiaban de `string()` a numérico sin efecto; la prueba encontró que una línea fuera de esos nueve leía uno de esos escalares como texto y habría tronado en cada simulación web. El equivalente fiscal: nadie acepta "la reforma es neutral" sin la tabla de incidencia.

**Cómo lo hace el CIEP.** Un *test dorado*: se guarda la salida completa de una corrida de referencia (los `.tex` del libro, los archivos del flujo web) y, después del cambio, se vuelve a correr y se comparan byte a byte. En v8.0.13 la comparación cubrió nueve `.tex` y 519 valores: cero diferencias de valor, y la única clase de cambio (un decimal más en ciertos porcentajes) era exactamente la esperada. `scalarlatex-baseline.txt` es la misma idea aplicada a los nombres: la lista auditada contra la que se detecta deriva. `test-maquina-virgen.sh` lo aplica a la instalación: ¿puede un externo reconstruir todo desde cero? Se corre antes de cada release.

**En tu simulador.** Desde la primera versión que alguien cite, guarda sus salidas como referencia (una carpeta `golden/` fuera de Git o un asset del Release). Escribe un `.do` que corra el modelo y compare contra la referencia con `cf` o `datasignature`. Córrelo antes de cada etiqueta. Cuando esperes diferencias, el test te obliga a enumerarlas y explicarlas; eso es el CHANGELOG escribiéndose solo.

---

## 9. Publicar tiene compuertas

**La regla.** Publicar una versión es un script, no una lista mental. El script verifica una serie de condiciones (*gates*) y se niega a continuar si alguna falla. Un gate no se salta "solo por esta vez"; si un gate estorba, se discute y se cambia el gate.

**Por qué.** Los errores de publicación son silenciosos y caros: la versión sale, alguien la cita y el defecto se descubre semanas después. El 4 de julio de 2026 una prueba de humo destapó tres defectos en tres versiones seguidas (v8.0.2 a v8.0.4), todos de cosas que un gate habría atrapado antes de publicar. Y el health check no basta: el 2026-07-09 el sitio respondía HTTP 200 y el motor Stata tronaba por dentro; desde entonces el gate final es humano —una simulación real en el navegador después de cada deploy.

**Cómo lo hace el CIEP.** `05_scripts/publicar.sh vX.Y.Z` corre siete gates antes de tocar nada: (1) entrada en el CHANGELOG para esa versión; (2) etiqueta anotada, no ligera; (3) `manifest.json` sincronizado con la versión; (4) archivos del endpoint declarados existen; (5) `raw/` declarado: assets locales = manifiesto y sin modo aviso activo; (6) cobertura: todo asset del manifiesto lo pide algún módulo; (7) clausura transitiva de los `.pkg`. Solo entonces crea el Release, sube assets y publica al endpoint; cada paso queda en `deploys/endpoint-stata.log`. El deploy al sitio web (`publicar-vps.sh`) hace backup antes, verifica después y hace rollback solo si falla. Los comandos por tipo de release están en `runbook-deploys-ciep.md`.

**En tu simulador.** Tu primer `publicar.sh` puede tener dos gates: que exista la entrada del CHANGELOG y que el test dorado pase. Cada incidente de publicación que tengas se convierte en un gate nuevo, con el incidente citado en el comentario. Nunca publiques a mano lo que el script puede publicar.

---

## 10. Los secretos no viven en el repositorio

**La regla.** Tokens de API, contraseñas, llaves SSH y SSL, rutas personales: nunca en archivos versionados, nunca en mensajes de commit, nunca en logs. Lo que el código necesita lo lee de variables de entorno o de archivos locales ignorados por Git, y el repo versiona una plantilla que documenta qué campos hacen falta.

**Por qué.** Git no olvida: un secreto que entró una vez al historial sigue ahí aunque lo borres en el siguiente commit, y los repositorios públicos se rastrean automáticamente en busca de tokens. En este proyecto, llaves privadas SSL estuvieron cinco meses (enero a julio de 2026) en un lugar donde no debían, sin que nadie lo notara, hasta que una auditoría de solo lectura las encontró. Se rotaron el mismo día; la política escrita existe porque el incidente existió.

**Cómo lo hace el CIEP.** El token del INEGI se lee de la global `$BIE_API_TOKEN`, que `profile.do` carga desde un archivo local; sin token el comando no aborta, usa la vía pública y avisa. Las credenciales de los servidores viven en `endpoint-credentials.sh` y `publicar-vps-credentials.sh` (ignorados) y el repo versiona `*.template.sh` con los campos. El `.gitignore` bloquea `*.key`, `*.pem`, `*.p12`, `*.pfx`, `*.crt`, los `wp-config.php`. Qué cuenta como secreto, dónde vive cada uno, quién tiene acceso y qué hacer si uno se compromete está en `politicas-institucionales.md` Parte I.

**En tu simulador.** El día que obtengas tu primer token, crea `credenciales.template.do` versionado y `credenciales.do` ignorado, y haz que tu `profile.do` cargue el segundo. Agrega las extensiones de llaves al `.gitignore` antes de tener llaves. Si un secreto llega a entrar al historial, rotarlo es lo primero; limpiar el historial es lo segundo.

---

## 11. Coincidir no es verificar

**La regla.** El simulador rehace la estimación con criterios propios, explícitos y publicados. Si el resultado coincide con la cifra oficial, la coincidencia es información (dos rutas llegaron al mismo lugar); si difiere, la diferencia también lo es (hay una decisión de criterio que merece discutirse). La conciliación con la cifra oficial se muestra, no se esconde.

**Por qué.** Una cifra que se copia de la fuente oficial no la verifica: la repite. Una organización que solo repite no aporta control independiente, aporta redundancia con membrete. Y el valor pedagógico está precisamente en la diferencia: una ciudadanía que entiende que una cifra fiscal es una construcción con criterios puede preguntar cuáles son, quién los eligió y qué cambiaría con otros. Si una diferencia menor confunde la discusión, el problema no es la diferencia; es que la discusión estaba anclada en una precisión falsa.

**Cómo lo hace el CIEP.** `SCN.ado` calcula el excedente neto de operación de sociedades como residuo para que las cuentas cuadren con el PIB oficial, y lo documenta en el código con la magnitud de la discrepancia estadística del INEGI que absorbe (~820 mil millones en los componentes desagregados). El ingreso nacional disponible se reporta como PIN + resto del mundo, con nota de la diferencia respecto a la cifra del BIE. El marco completo —por qué la conciliación va en la ficha del indicador con la misma jerarquía que la cifra, no en un pie de página— está en `paquete-economico/independencia-metodologica-series.md`.

**En tu simulador.** Para cada cifra titular, calcula también la oficial y reporta ambas con la diferencia. Documenta en el código, junto al cálculo, cada decisión de criterio y la magnitud de lo que absorbe. Si la diferencia es grande, no la ajustes para que cuadre: explícala.

---

## 12. La gobernanza también se gobierna

**La regla.** Los documentos de norma se reescriben en su lugar cuando la realidad cambia; los que dejan de aplicar se archivan con una nota de por qué, no se borran; y hay un índice que dice la verdad sobre qué documento está vigente y para qué sirve. Los documentos que describen *cómo es* el sistema no mezclan con los que narran *cómo llegó a serlo*.

**Por qué.** La gobernanza envejece igual que el código, pero sin compilador que avise. En este repo, la carpeta de gobernanza llegó a 24 archivos con un índice que listaba 5; el documento de arquitectura abría diciendo que `publicar.sh` y el CHANGELOG "aún no están implementados" tres meses después de que operaban en producción, y arrastraba 57 filas de bitácora que duplicaban al CHANGELOG. Nada de eso era falso cuando se escribió; era falso cuando se leyó. La limpieza del 2026-10-03 que produjo esta guía es el ejemplo: cuatro reportes cerrados a `historico/`, el expediente de un proyecto hermano a su subcarpeta, la arquitectura separada de su memoria.

**Cómo lo hace el CIEP.** `02_governance/README.md` es el mapa y lleva la política de higiene: documentos vivos se sobrescriben (la historia está en `git log --follow`), lo obsoleto va a `historico/` con nota de retiro, nada se borra. `CHANGELOG.md` es el único registro de cambios; los documentos de norma no llevan bitácora propia. Cada documento abre diciendo para quién es, qué responde y qué no encontrarás en él.

**En tu simulador.** Empieza con tres documentos y un índice: `README.md` (mapa), `arquitectura.md` (cómo es el sistema), `CHANGELOG.md` (qué cambió por versión). Crea `historico/` el día que archives el primero. Cada seis meses, abre el índice y pregúntate si cada línea sigue siendo cierta.

---

## Tu simulador en la semana 1

Lo mínimo para arrancar con buenas prácticas en lugar de adoptarlas después, que siempre cuesta más.

**Día 1 — Estructura.**
```
mi-simulador/
├── 01_modulos/        # análisis que consumen los comandos
├── 02_governance/     # README.md, arquitectura.md, CHANGELOG.md
├── 03_help/           # .sthlp de cada comando
├── 05_scripts/        # manifest.json, publicar.sh
├── raw/               # descargas        (gitignored)
├── master/            # bases procesadas (gitignored)
├── users/             # salidas por usuario (gitignored)
├── profile.do         # arranque: adopath, globales, credenciales
├── credenciales.template.do
└── .gitignore         # raw/ master/ users/ credenciales.do *.key *.pem *.log
```
`git init`, primer commit: solo la estructura y el `.gitignore`.

**Día 2 — Primer comando.** Un `.ado` que descarga una fuente, la limpia y guarda en `master/`. Con `syntax [, ANIO(int) UPDATE]`, con verificación al final (`confirm numeric variable anio`), con su `.sthlp`.

**Día 3 — Primer escalar.** Tu comando `escalar` con tres tipos. El primer resultado del modelo se registra ahí y de ahí sale a la primera tabla.

**Día 4 — Primer manifiesto.** `manifest.json` con el archivo que descargaste el día 2: nombre, ruta, SHA-256, tamaño. Tu comando que verifica la huella. Borra `raw/` y comprueba que se reconstruye.

**Día 5 — Primera versión.** `CHANGELOG.md` con `## [v0.1.0] — fecha`, `git tag -a v0.1.0`, Release con el asset, salidas de referencia guardadas para el test dorado. Un `publicar.sh` con dos gates.

A partir de ahí, cada incidente te dice qué gate, qué guardia o qué documento te faltaba. Esta guía nació así.

---

## Mapa de lectura: de la guía a la norma

Esta guía es la versión general. La versión precisa y específica del Simulador Fiscal CIEP está en los documentos de norma de esta misma carpeta:

| Si quieres el detalle de… | Lee |
|---|---|
| Las cuatro capas (desarrollo, distribución, reproducción, web) y cómo se conectan | `arquitectura.md` §1, §6 |
| El día a día del investigador que usa el Simulador | `arquitectura.md` §2 y `03_help/manual-investigador-ciep.md` |
| Qué es una versión y por qué no se edita | `arquitectura.md` §4; `versionado-y-git.md` §3 |
| Cómo se escriben commits, ramas y etiquetas | `versionado-y-git.md` §1–§3 |
| Comandos exactos para publicar un release | `runbook-deploys-ciep.md` |
| Qué hacer cuando el candado de datos detiene | `runbook-actualizar-assets.md` |
| Secretos, credenciales y ciclo de vida de productos | `politicas-institucionales.md` |
| El principio "Stata produce todos los números" aplicado a la web | `principio-stata-produce-los-numeros.md` |
| Independencia metodológica y series históricas | `paquete-economico/independencia-metodologica-series.md` |
| El contrato `escalar` y sus auxiliares | `escalar.ado` (header), `03_help/PROGRAMAS_AUXILIARES.md` |
| Los incidentes, con fecha y commit | `CHANGELOG.md`; `historico/bitacora-arquitectura.md` |
| Vocabulario | `glosario-ciep.md` |
