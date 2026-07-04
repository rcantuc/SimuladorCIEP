# Auditoría de sincronía entre comandos (.ado) y sus ayudas (.sthlp)

**Fecha de auditoría:** 2026-05-25
**Estado del repo auditado:** commit `aec0e45` (working tree limpio)
**Alcance:** los 10 comandos del Simulador y sus 10 archivos de ayuda en `help/Stata/`

---

## 1. Qué se auditó y cómo

*Esta sección explica qué significa "drift" y qué se revisó en cada comando.*

🧠 **Concepto: drift de documentación.** Es la separación gradual entre lo que el código *hace* y lo que la documentación *dice* que hace. Ocurre naturalmente: se modifica un `.ado` para arreglar algo urgente y nadie vuelve a tocar el `.sthlp`. El costo lo paga el siguiente lector: sigue la ayuda al pie de la letra y el comando truena o, peor, hace otra cosa en silencio.

Checklist aplicado a cada uno de los 10 comandos:

1. **Sintaxis:** ¿las opciones documentadas en el `.sthlp` existen en la instrucción `syntax` del `.ado`, y viceversa?
2. **Valores por defecto:** ¿los defaults documentados coinciden con los del código?
3. **Fuentes de datos:** ¿las fuentes que menciona la ayuda son las que el código realmente consulta?
4. **Ejemplos:** ¿los ejemplos de la ayuda son sintácticamente válidos contra el `syntax` real?
5. **Rutas y referencias:** ¿las rutas de archivos y los enlaces internos de la ayuda apuntan a lugares que existen?

Clasificación de severidad:

| Nivel | Significado |
|---|---|
| 🔴 Crítico | Seguir la ayuda produce un error o un resultado vacío |
| 🟡 Medio | La ayuda omite u oculta funcionalidad, o da un dato incorrecto que afecta decisiones |
| 🟢 Menor | Detalle cosmético o ruta desactualizada sin impacto en el uso |

---

## 2. Resumen ejecutivo

| Comando | Sintaxis | Defaults | Fuentes | Ejemplos | Rutas | Veredicto |
|---|---|---|---|---|---|---|
| `Poblacion` | ✓ | 🟢 | ✓ | ✓ | 🟢 | Coherente |
| `PIBDeflactor` | ✓ | 🟡 | ✓ | ✓ | 🟢 | Drift menor |
| `SCN` | 🔴 | ✓ | ✓ | 🔴 | 🟢 | **Drift crítico** |
| `LIF` | ✓ | 🟡 | 🟢 | ✓ | 🟢 | Drift menor |
| `PEF` | 🟡 | ✓ | 🟢 | ✓ | 🟢 | Drift medio |
| `SHRFSP` | ✓ | ✓ | ✓ | ✓ | 🟢 | Coherente |
| `DatosAbiertos` | 🟡 | ✓ | ✓ | ✓ | 🟢 | Drift medio |
| `AccesoBIE` | ✓ | ✓ | ✓ | ✓ | 🟢 | Drift menor (versión) |
| `GastoPC` | 🔴 | ✓ | ✓ | 🔴 | 🟢 | **Drift crítico** |
| `TasasEfectivas` | ✓ | ✓ | ✓ | ✓ | 🟢 | Coherente |

Los hallazgos 🟢 de rutas ya fueron **corregidos en esta auditoría** (ver sección 5). Los 🔴 y 🟡 requerían decisión del autor y se detallan abajo.

> **Actualización 03jul2026:** todos los hallazgos 🔴 y 🟡 fueron resueltos por decisión del autor. Cada hallazgo indica abajo su resolución.

---

## 3. Hallazgos por comando

### 3.1 `SCN` — 🔴 crítico

- **Opción documentada que no existe.** El `.sthlp` documenta `aniomax(#)` ("año final hasta el que se extiende la proyección, por defecto 2070"). La instrucción real es `syntax [, ANIO(int) NOGraphs UPDATE TEXTBOOK]` — no acepta `aniomax`. En el código, `aniomax` es una variable interna calculada del último año de la base, no una opción del usuario.
- **Ejemplo inválido.** El Ejemplo 5 de la ayuda, `SCN, anio(2025) aniomax(2031)`, termina en error `option aniomax not allowed`.
- ~~**Decisión pendiente del autor:** ¿se elimina `aniomax` de la ayuda, o se agrega como opción real al `.ado` (como ya la tiene `PIBDeflactor`)?~~
- ✅ **Resuelto (03jul2026):** se agregó `ANIOMAX(int 2050)` como opción real de `SCN.ado`. Solo controla el rango del eje horizontal de las gráficas; la ayuda se actualizó en consecuencia.

### 3.2 `GastoPC` — 🔴 crítico

- **Componentes documentados que no existen.** La ayuda lista como componentes válidos: `educacion`, `salud`, `pensiones`, `energia`, `infraestructura`, `otrosgastos`. El código real acepta: `educacion`, `salud`, `pensiones`, `energia`, `resto`, `transferencias`.
- **Impacto:** `GastoPC infraestructura` no truena — simplemente **no ejecuta ningún bloque y termina sin resultados**, que es el peor tipo de falla para un usuario nuevo (no hay error que leer).
- ~~**Decisión pendiente del autor:** confirmar la lista canónica de componentes.~~ Nota: `SIM.do` llama `GastoPC educacion salud pensiones energia resto transferencias`, consistente con el código.
- ✅ **Resuelto (03jul2026):** la ayuda ahora documenta los componentes reales (`resto`, `transferencias`) con su descripción, y se eliminaron `infraestructura` y `otrosgastos`.

### 3.3 `PEF` — 🟡 medio

- **Tres opciones sin documentar.** El `syntax` real acepta `PEF`, `PPEF` y `APROBado` (fuerzan el uso de una fuente específica en lugar de la jerarquía automática ejercido → aprobado → proyecto). La ayuda no las menciona.
- **Fuente descrita a medias (🟢).** La ayuda describe las fuentes SHCP correctamente, pero no menciona que los archivos base (`CP.2013.xlsx` … `PEF.2026.xlsx`) ya no se descargan del portal de la SHCP en cada corrida: vienen pre-empaquetados del repositorio de datos del proyecto (GitHub Release) con verificación de integridad. Para el usuario es transparente, pero para quien mantiene el comando es información relevante.
- ~~**Decisión pendiente:** documentar `pef`/`ppef`/`aprobado` o marcarlas como internas.~~
- ✅ **Resuelto (03jul2026):** verificado que las tres opciones estaban declaradas pero **nunca se consumían** en el código (opciones muertas). Se eliminaron del `syntax` de `PEF.ado`: si alguien las escribe, Stata dará error explícito en lugar de ignorarlas en silencio.

### 3.4 `DatosAbiertos` — 🟡 medio

- **Tres opciones sin documentar:** `PIBVP(real)`, `PIBVF(real)` y `FILES`. La ayuda documenta las otras siete correctamente.
- ~~**Decisión pendiente:** documentarlas o marcarlas como internas.~~
- ✅ **Resuelto (03jul2026):** verificado que las tres estaban declaradas pero sin efecto. Se **implementaron**: `pibvp()` sustituye el año en curso con una cifra oficial como % del PIB; `pibvf()` grafica una estimación oficial para el año siguiente; `files` reconstruye la base desde los archivos locales de `temp/` sin internet. Las tres quedaron documentadas en la ayuda. De paso se corrigió que `csvfile` no se reenviaba a la subrutina de actualización.

### 3.5 `PIBDeflactor` — 🟡 medio (un default)

- **Default incorrecto (corregido):** la ayuda decía que `aniomax()` es por defecto "año actual + 15"; el código real usa `aniovp + 5`. **Corregido en esta auditoría.**
- Todo lo demás (9 opciones, ejemplos, fuentes) coherente.

### 3.6 `LIF` — 🟡 medio (un default)

- **Default incorrecto (corregido):** la ayuda decía que `minimum()` es por defecto 0.25; el código real usa 0.5. **Corregido en esta auditoría.**
- **Fuente sin mencionar (🟢):** el archivo base `LIFs.xlsx` viene del repositorio de datos del proyecto (GitHub Release), no se descarga de la SHCP en cada corrida. Mismo caso que `PEF`.

### 3.7 `AccesoBIE` — 🟢 menor (versión)

- **Versiones contradictorias:** el encabezado del `.ado` dice `AccesoBIE v2.0`; el `.sthlp` dice `version 3.0`. Ver hallazgo transversal 4.1.
- Sintaxis, opciones, ejemplos y la sección de token: todo coherente y actualizado a v8.0. Es la ayuda en mejor estado de las diez.

### 3.8 `Poblacion` — 🟢 menor

- **Default impreciso (corregido):** la ayuda decía que `aniofinal()` es por defecto "el año actual + 1"; el código usa el último año disponible en la base (2070). **Corregido en esta auditoría.**
- Todo lo demás coherente.

### 3.9 `SHRFSP` y `TasasEfectivas` — coherentes

Sin hallazgos más allá de las rutas transversales (sección 4.2). Las opciones, defaults, fuentes y ejemplos coinciden con el código.

---

## 4. Hallazgos transversales

### 4.1 Los `.ado` no declaran versión — 🟡

Los 10 `.sthlp` declaran `*! version 3.0 CIEP 23feb2026` de forma uniforme. En cambio, de los 10 `.ado`, solo `AccesoBIE` declara una versión (`v2.0`, que además contradice a su ayuda); `SCN`, `Poblacion` y `PIBDeflactor` tienen encabezado con fecha pero sin número, y los otros seis no tienen encabezado de versión.

**Consecuencia:** no existe forma mecánica de saber si un `.ado` y su `.sthlp` están sincronizados. Esta auditoría tuvo que comparar contenido línea por línea.

**Recomendación:** adoptar una línea `*! version X.Y  fecha` idéntica al inicio de cada `.ado` y su `.sthlp`, actualizada en el mismo commit que modifica cualquiera de los dos.

✅ **Resuelto (03jul2026):** decisión institucional — el número del header se empareja con la **versión pública del Simulador** (no con un contador propio de cada archivo). Los 10 `.ado` y los 10 `.sthlp` llevan ahora `*! version 8.0 CIEP 03jul2026`. Cada vez que se toque un `.ado`, el `*!` se actualiza al número del Simulador vigente, y el `.sthlp` migra en el mismo commit.

### 4.2 Rutas con nomenclatura vieja — 🟢 (corregido)

Los `.sthlp` referían carpetas con nombres numerados que ya no existen en el repo:

| Escrito en la ayuda | Real |
|---|---|
| `04_master/` | `master/` |
| `03_temp/` | `temp/` |
| `06_helps/*.sthlp` (enlaces "Ver también") | `help/Stata/*.sthlp` |

Los enlaces `06_helps/` aparecían en los 10 archivos y hacían que la navegación entre ayudas fallara. **Corregido en esta auditoría** (ver sección 5).

### 4.3 Señal de drift temporal — informativo

`PEF.ado`, `LIF.ado` y `DatosAbiertos.ado` se modificaron por última vez el 2026-05-24, y `SCN.ado` el 2026-05-21, mientras que sus `.sthlp` datan del 2026-04-16. Cualquier cambio de comportamiento en esos cuatro `.ado` posterior a abril no está reflejado en las ayudas. Los hallazgos 3.1–3.4 son consistentes con esta señal.

### 4.4 Hallazgos fuera del alcance (se reportan, no se corrigen)

1. ~~**`profile.do` anuncia una opción inexistente:** el menú de bienvenida muestra `DatosAbiertos {claves} [, NOGraphs DESDE(real) MES]`.~~ ✅ **Resuelto (03jul2026):** se eliminó la mención a `MES` del menú.
2. ~~**Contradicción de ruta canónica:** `sysprofile.do` vs `governance/arquitectura-distribucion.md`.~~ ✅ **Resuelto (commit c840d2a):** el repo conserva solo `sysprofile-template.do`; el `sysprofile.do` real vive en la instalación de Stata de cada investigador, fuera del repo.
3. ~~**`README.md` referencia imágenes inexistentes:** las rutas `manuales/images/ReadMe/*.png` del README no existen en el repo.~~ ✅ **Resuelto (03jul2026, consolidación de ayuda):** las rutas del README se corrigieron a los archivos reales en `help/images/` y se eliminaron los bloques de imágenes sin archivo correspondiente (`Grafica1-4.png`, `imagen1.png`).

---

## 5. Correcciones aplicadas en esta auditoría

Solo se corrigieron errores **fácticos y evidentes**, verificados contra el código. Nada que implique una decisión de diseño.

| Archivo(s) | Corrección |
|---|---|
| Los 10 `.sthlp` | Enlaces "Ver también": `06_helps/` → `help/Stata/` |
| `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos` (.sthlp) | Rutas de archivos guardados: `04_master/` → `master/` |
| `AccesoBIE.sthlp` | Ruta temporal: `03_temp/AccesoBIE/` → `temp/AccesoBIE/` |
| `LIF.sthlp` | Default de `minimum()`: 0.25 → 0.5 |
| `PIBDeflactor.sthlp` | Default de `aniomax()`: "año actual + 15" → "año de valor presente + 5" |
| `Poblacion.sthlp` | Default de `aniofinal()`: "año actual + 1" → "último año disponible (2070)" |

---

## 6. Recomendaciones

1. ~~**Resolver los dos críticos antes de la siguiente release.**~~ ✅ Resueltos el 03jul2026 (ver 3.1 y 3.2).
2. ~~**Adoptar la línea `*! version` sincronizada** en `.ado` y `.sthlp` (hallazgo 4.1).~~ ✅ Adoptada el 03jul2026.
3. **Regla de mantenimiento:** todo commit que modifique la interfaz de un `.ado` (su instrucción `syntax`, sus defaults o sus fuentes) debe tocar también su `.sthlp` en el mismo commit. Es la única defensa estructural contra el drift.
4. ~~**Decidir el estatus de las opciones internas.**~~ ✅ Resuelto el 03jul2026: eliminadas en `PEF` (eran opciones muertas), implementadas y documentadas en `DatosAbiertos` (ver 3.3 y 3.4).
5. **Repetir esta auditoría** con cada release mayor, usando el checklist de la sección 1. Con la línea `*! version` implantada, la revisión se reduce a comparar encabezados.
