# `/metodo` — Plantilla de capítulo por módulo

*Vigente desde v8.18.0 (sesión 8.18). Un capítulo por módulo, en el orden de `SIM.do`. El capítulo se **genera** del repo por `05_scripts/metodo.py` (headers de los `.do`/`.ado`, `SIM.do` §0.8, memos `CUAD-*`, `scn-celdas.md`, manifest, fixtures); nada se redacta a mano en el sitio. Regla: ninguna frase del método nace fuera del repo. Los títulos de las secciones 1–10 de esta plantilla son los que la página muestra (el generador los lee de aquí).*

---

## Encabezado (metadatos, máquina-legibles)

| Campo | Fuente en el repo |
|---|---|
| `modulo` | nombre del `.do` (p. ej. `Households`) |
| `archivo` | ruta y hash del commit en que se genera |
| `orden_en_SIM` | posición en `SIM.do` |
| `desde_version` | primer tag en que existe en su forma actual |
| `ultima_decision` | fecha del último FLAG o memo que lo tocó |
| `sello` | verde / amarillo / rojo, heredado del peor sello de sus entradas y anclas |

## 1. Propósito

Una oración. Qué pregunta responde el módulo y qué le entrega al siguiente. Ejemplo (Households): *"Construye el ingreso por persona y fuente a partir de la ENIGH, anclado al SCN del sector hogares, para que todos los módulos posteriores repartan sobre la misma base."*

## 2. Entradas

| Base | Fuente / institución | Vintage usado | Variables clave | Llave única | Sello |
|---|---|---|---|---|---|

- Vintage = el que registra el motor (`manifest-datos.json`), no el que dice la documentación.
- Año: las anclas al SCN se leen en `anioenigh` (`scalar anioenigh` de `SIM.do`, el año de la ENIGH; hoy 2024); el año del Paquete (`anioPE`, hoy 2027) es el de la proyección. El capítulo dice en qué año está cada cifra.
- Llave única = la que garantiza reproducibilidad del `sort` (regla de los seis `gsort`).
- Sello de cada entrada: verde (oficial, estable), amarillo (oficial con vintage ambiguo, p. ej. BIE vs CSI), rojo (reconstruida o imputada).

## 3. Procedimiento

Pasos numerados, uno por bloque del `.do`. Cada paso declara:

- **Qué hace** (una línea).
- **Qué conserva**: la identidad contable que debe cumplirse al final del paso (Σ entradas = Σ salidas, o "ninguna" si es una transformación sin conservación).
- **Dónde está**: rango de líneas del `.do` o nombre del programa.

No se explica Stata. Se explica economía.

## 4. Decisiones (parámetros + FLAGs)

| Parámetro | Default | Alternativas | FLAG | Memo | Qué cambia si se mueve |
|---|---|---|---|---|---|

Toda decisión metodológica es un parámetro con default y un FLAG. Si una decisión no aparece aquí, no existe. Ejemplos ya vivos: `informalidad corte|probabilistica` (8.16), `perfilpc` vs per cápita, tratamiento de `ImpNetProductos_mixK` (⅓ / ⅔).

## 5. Anclas al SCN

| Variable del motor | Celda del SCN (sector, código) | Valor SCN | Σ motor antes de ancla | Factor | Tipo de regla (propiedad / incidencia / per cápita) | Sello |
|---|---|---|---|---|---|---|

Es la tabla C de los principios A–C, por módulo. El memo CUAD-0 se escribe directamente en este formato para que Cuadratura produzca documentación como subproducto.

## 6. Salidas

| Archivo / JSON / figura | Qué contiene | Quién lo consume (módulo siguiente, página, sidecar) | Check de CI que lo protege |
|---|---|---|---|

Si una salida no tiene check, se declara: *"sin protección automática — gate humano"*.

Regla (`arquitectura.md` §6.3.1): **todo valor en pantalla tiene origen en un archivo exportado** por el motor; si un número no está en un archivo exportado, no aparece en la página.

## 7. Identidades verificadas

Lista de las igualdades que el gate del módulo comprueba y con qué tolerancia (p. ej. `nta-identidad.txt`: Σ entradas − Σ salidas = 0 a 1e-6; `gate-numeros.sh`: `output.txt` byte a byte y sankeys a 1e-9; `test-web-batch.sh`: llaves 46/46). Resultado de la última corrida, con hash.

## 8. Límites conocidos

FLAGs abiertos del módulo, en una línea cada uno, con la versión en que se planea cerrar. Ejemplos: pensiones dentro de YL (→ 8.15), ISFLSH mezcladas en hogares (sin fecha), subreporte de top incomes en ENIGH (estructural).

## 9. Específico de México (alimenta el capítulo 0)

| Elemento | Qué requiere genéricamente | Por qué México lo resuelve así |
|---|---|---|

Esta sección es la única que mira hacia afuera. Cada renglón se copia al capítulo 0 con la columna "equivalente en otro país" vacía para que la llene quien replica.

## 10. Procedencia del texto

Lista de archivos y rangos de línea de donde se generó cada sección (header del `.do`, memo, FLAG). Permite auditar que el capítulo no dice nada que el repo no diga.

---

## Esquema de `metodo.json` (por capítulo)

```json
{
  "modulo": "", "archivo": "", "commit": "", "orden_en_SIM": 0,
  "desde_version": "", "sello": "",
  "proposito": "",
  "entradas":   [{"base":"","fuente":"","vintage":"","variables":[],"llave":[],"sello":""}],
  "pasos":      [{"n":1,"hace":"","conserva":"","lineas":""}],
  "decisiones": [{"parametro":"","default":"","alternativas":[],"flag":"","memo":""}],
  "anclas":     [{"variable":"","celda_scn":"","valor_scn":0,"suma_motor":0,"factor":0,"regla":"","sello":""}],
  "salidas":    [{"archivo":"","consume":"","check":""}],
  "identidades":[{"nombre":"","tolerancia":"","resultado":"","hash":""}],
  "limites":    [{"flag":"","cierra_en":""}],
  "especifico_mx": [{"elemento":"","requerimiento":"","por_que_mx":""}],
  "procedencia": [{"archivo":"","lineas":""}]
}
```

## Convención de headers (lo que el generador lee de cada módulo)

El header es el bloque de comentarios anterior al primer comando del archivo (`.do`: antes del primer `if`/`timer`/`capture`; `.ado`: antes de `program define`). Dentro de él:

- Una sección empieza en una línea de comentario que, tras el prefijo (`*`, `****`, `*!`, `//`), dice `§N Título` o `N. Título`, con N = 1–9 y el título de esta plantilla (basta la palabra clave: Propósito, Entradas, Procedimiento, Decisiones, Anclas, Salidas, Identidad(es), Límites/FLAGs, Específico). Lo que sigue al título y a los dos puntos es el primer párrafo; la sección corre hasta el siguiente marcador. Un mismo `§N` puede aparecer dos veces (se acumula).
- `(procedencia: …)` o `(…texto de CUAD-n §9, fecha…)` en la línea del marcador alimenta la sección 10; en el cuerpo, `procedencia: …` también.
- Tablas: filas `| a | b | c |` (la primera es la cabecera; la fila `|---|` es opcional); una fila con la primera celda vacía continúa la anterior (tablas partidas en varias líneas de comentario). Los nombres de columna son los de esta plantilla; «Sello» (verde / amarillo / rojo) decide el sello del capítulo.
- §4: una entrada por parámetro, `nombre = valor «título del FLAG» — descripción` (continuación con sangría ≥ 20); los `nta_*` como `nta_x ("default") …`; las líneas `FLAG n (…) texto` van a §8. El valor firmado, el documento y quién lo lee se toman de `SIM.do` §0.8–§0.8c; las alternativas, de las tablas §4 de los memos.
- Lo que el generador deriva del código, sin header: §3 (secciones numeradas `** N.N Título **` del cuerpo, con programa y líneas), §2 (`ensure_asset` y `use master/`, con el manifest), §6 (`save`/`file open`/`scalarjson`/`SankeySumSim`, con las páginas de `manifiesto-default.py --tsv` que piden cada archivo y los scripts de `05_scripts/` que lo nombran), §7 (fixtures `nta-identidad.txt` y `gate-numeros.txt`).

## Reglas de generación

1. `05_scripts/metodo.py` lee headers, `SIM.do` §0.8, memos, inventarios y fixtures y emite `04_1_simuladorfiscal.ciep.mx/metodo/metodo.json` (un objeto por capítulo con el esquema de arriba, más `cap0` y `bibliografia`) y un cascarón PHP por página (`index.php`, `cap0/index.php`, `<Modulo>/index.php`); `js/metodo-capitulo.js` pinta todo desde el JSON.
2. Check de CI (`test-sitio-metodo.sh`, job `/metodo: capítulos generados del repo = publicados`): regenera y exige bytes idénticos a lo commiteado; cada página carga y pinta; cero literales de 4+ dígitos en PHP/JS/CSS; enlaces internos resuelven. Mismo patrón que `/NTA` y `/entidades`.
3. Si un header, un memo, este documento, `cap0-requerimientos.md`, `fuentes/README.md`, `scn-celdas.md`, `manifest.json` o un fixture cambian, el check falla hasta regenerar y commitear `metodo/` en el mismo PR: **todo header nuevo pasa por el generador** (runbook §16). El generador registra el sha256 de cada archivo fuente del capítulo en el encabezado (`archivo`), así que un cambio del código del módulo también exige regenerar.
4. Sin literales numéricos a mano en el HTML/JS; todo número viene de `metodo.json` (misma regla que `/NTA`). Una sección que no existe en ningún documento se publica vacía con FLAG «header incompleto»: no se inventa texto. Sello del capítulo: rojo con FLAG; si no, el peor de §2 y §5; «sin sello» si ninguna fila lo declara.
