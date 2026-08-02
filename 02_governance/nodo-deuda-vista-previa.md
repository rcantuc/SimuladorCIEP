# Nodo de deuda — dónde vive y cómo verlo

## Fuente versionada vs. salida generada

Decisión de Ricardo (2026-08-01, destino actualizado 2026-08-02 con el cierre
de `04_3_nodos/`): el destino de render vive **bajo el docroot del WordPress
local del Paquete** (patrón 6yt5ppa3hb: estáticos servidos junto al sitio,
jamás dentro de Elementor) y está en `.gitignore`, junto a las demás carpetas
de operación local. Es un **destino de render desechable**, no una carpeta de
código.

| | ruta | git |
|---|---|---|
| Exportador | `scalarjson.ado` | **versionado** |
| Driver del nodo | `01_modulos/nodos/nodo-deuda.do` | **versionado** |
| Página (fuente) | `01_modulos/nodos/nodo-deuda.html` | **versionado** |
| Contrato | `04_1_paqueteeconomico.ciep.mx/public_html/nodos/statajson_deuda-publica.json` | generado, ignorado |
| Página (copia servible) | `04_1_paqueteeconomico.ciep.mx/public_html/nodos/nodo-deuda.html` | generado, ignorado |

Es el mismo estatus que los `statalatex_*.tex` de `06_libro/images`: se
versiona lo que **produce** el artefacto, no el artefacto. La copia de la
página existe porque la página lee el JSON por ruta relativa y ambos tienen
que quedar en la misma carpeta; la hace el driver al final de cada corrida.

> **Consecuencia que hay que tener presente.** El JSON no tiene historial en
> git, así que **su diff entre cortes no es auditable desde el repo**. Si en
> septiembre hace falta comparar el corte nuevo contra el vigente, hay que
> guardar una copia del anterior a mano antes de re-exportar. Era el argumento
> a favor de versionarlo; la decisión fue otra y esto es lo que cuesta.

## Regenerar el nodo

Desde Stata, con el repo como SITE:

```stata
do "01_modulos/nodos/nodo-deuda.do"
```

O automáticamente al final de `SHRFSP` cuando corre el flujo del libro
(`global textbook "textbook"`): el bloque de `SHRFSP.ado` lo dispara si
`scalarjson` y el driver están presentes.

## Verla

Con el WordPress local del Paquete corriendo (ver `04_1_…/DEPLOY.md`):

```
http://localhost:8892/nodos/nodo-deuda.html
```

Si el WordPress no está levantado, cualquier server estático sobre la carpeta
sirve igual:

```bash
cd 04_1_paqueteeconomico.ciep.mx/public_html/nodos
python3 -m http.server 8137
# abre http://localhost:8137/nodo-deuda.html
```

`Ctrl-C` para detenerlo. Si el puerto está ocupado, cambia el número.

Abrir el HTML con doble clic (`file://`) **no funciona**: el navegador bloquea
la lectura del JSON por política de origen, y como la página no contiene
ninguna cifra, sin contrato no hay nada que mostrar (eso mismo dice en
pantalla si el fetch falla).

Si `…/public_html/nodos/` está vacía o no existe, corre el driver primero.

## Qué deberías ver

1. **Arriba, la entrada personal.** Escribe un año de nacimiento. Si es
   anterior al piso de la serie, la página lo dice y no inventa nada.
2. **El selector de unidad**, visible y obligatorio. Cambia todos los números
   de la página, y la elección se muestra en pantalla.
3. **Evolución**, con la gráfica de la serie y la tabla equivalente.
4. **Incidencia**, declarada no aplicable con la razón visible.
5. **Implicaciones**, **capas declaradas**, **conciliación**, **acervo**.
6. **El sello al pie**, con versión, corte de datos y descarga de CSV.

## Una combinación que la página declara ausente (a propósito)

El **porcentaje del PIB no se expresa por persona**: el PIB ya es una magnitud
agregada. La página lo dice en vez de derivar algo. Es el comportamiento
correcto — `scalarjson` no calcula y la página tampoco.

## Antes de publicar

```bash
bash 05_scripts/verify_nodo.sh
```

Seis reglas, exit ≠ 0 si alguna falla. Audita la **fuente** de la página
(`01_modulos/nodos/`), no la copia de render. La regla 3 (determinismo) corre
Stata; si no lo tienes a mano, `--sin-stata` la salta — pero hay que
declararlo, no se salta en silencio. Si el JSON no existe todavía, sale con
exit 2 y te dice cómo producirlo.
