# `02_governance/metodo/` — fuente del método

`/metodo` es la sección del método del sitio (desde v8.18.0): el índice, el capítulo 0 y un capítulo por módulo, en el orden de `SIM.do`, **generados del repo** por `05_scripts/metodo.py` (runbook §16). El generador lee, no redacta.

**Regla:** ninguna frase del método nace fuera del repo. Si no está en un header de módulo, un memo, esta carpeta o un archivo que el generador lea, no se publica: la sección sale vacía con FLAG «header incompleto».

Desde 8.15 todo header de módulo lleva la sección 9, «Específico de México»; de ahí sale el capítulo 0. Desde 8.18 el header de cada módulo marca sus secciones con «§N Título» (1 Propósito, 2 Entradas, 3 Procedimiento, 4 Decisiones, 5 Anclas, 6 Salidas, 7 Identidades, 8 Límites, 9 Específico de México) y el generador las lee tal cual (convención en `plantilla-capitulo.md`, «Convención de headers»).

- `plantilla-capitulo.md`: formato de cada capítulo (encabezado, secciones 1–10, esquema de `metodo.json`, convención de headers, reglas de generación).
- `cap0-requerimientos.md`: qué hace falta para replicar el simulador en otro país; cada fila nace de la sección 9 de un capítulo. La página publica la columna «Otro país» vacía (la candidata colombiana del documento se queda aquí). §0.7 es la bibliografía del método.
- `fuentes/`: los PDF citados por los memos, con sha256 (`fuentes/README.md`; la página los lista como bibliografía).

Qué memo documenta qué capítulo (lo declara `metodo.py`, `MEMOS`): `CUAD-0.md` y `CUAD-3.md` → `Households`; `CUAD-1.md` → `Expenditure` (Tabla 1, consumo) y `TasasEfectivas` (Tabla 1b, impuestos y cuotas; el resto del memo a los dos); `CUAD-2.md` → `NTA`. Los capítulos `NTA` y `Entidades` enlazan a `/NTA` y `/entidades` como sus salidas.

Cómo se regenera y qué lo vigila: `python3 -I 05_scripts/metodo.py` (escribe `04_1_simuladorfiscal.ciep.mx/metodo/`), `--check` (bytes idénticos, lo corre CI en `test-sitio-metodo.sh`), `--reporte` (sello y secciones vacías por capítulo).
