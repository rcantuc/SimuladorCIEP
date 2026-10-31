# `/metodo` — Plantilla de capítulo por módulo

*Borrador para 8.18. Un capítulo por módulo, en el orden de `SIM.do`. El capítulo se **genera** del repo (headers de los `.do`, `02_governance/*.md`, FLAGs, fixtures); nada de aquí se redacta a mano en el sitio. Regla: ninguna frase del método nace fuera del repo.*

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

## Reglas de generación

1. Un script (`05_scripts/metodo.py`, propuesto) lee headers, memos y FLAGs y emite `metodo.json` + *N* páginas HTML, una por módulo, más `/metodo/index`.
2. Check de CI: `/metodo` regenerado desde el repo == el publicado (mismo patrón que `/NTA` y `/entidades`).
3. Si un `.do` cambia y su header no, el check falla: el header es la fuente del capítulo.
4. Sin literales numéricos a mano en el HTML; todo número es `span` del motor (misma regla que el factor 1.1628 en `/NTA`).
