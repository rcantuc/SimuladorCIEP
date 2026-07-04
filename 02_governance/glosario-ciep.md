# Glosario CIEP

**Versión:** v1.0
**Fecha:** 2026-05-15
**Estado:** fuente canónica del vocabulario institucional del CIEP. Vocabulario de uso obligatorio en todos los documentos de governance y por Cascade.

---

## Propósito

Este documento es la fuente única y canónica del vocabulario institucional del CIEP. Antes vivía como sección de `.windsurfrules`; se migró a archivo propio para ser artefacto autónomo, referenciable y mantenible con dignidad propia, no apéndice de la configuración del IDE.

## Cómo usar este glosario

El vocabulario es de aplicación obligatoria en todos los documentos de governance del CIEP y en todo trabajo de Cascade sobre el repositorio. Si un término tiene entrada aquí, se usa ese término sin excepción.

## Relación con `.windsurfrules`

`.windsurfrules` conserva un subconjunto operativo compacto de este glosario (las tablas de términos) porque Cascade lo lee de forma automática y necesita ese vocabulario en contexto para no introducir errores. **Este archivo (`governance/glosario-ciep.md`) es la fuente canónica completa.** Si hay cualquier discrepancia entre el subconjunto de `.windsurfrules` y este archivo, **gana este archivo**. Todo cambio al glosario se hace primero aquí; luego, si el cambio afecta al subconjunto compacto, se sincroniza en `.windsurfrules`.

## Personas

| Rol | Término |
|---|---|
| Quien desarrolla y mantiene el Simulador | **Investigador principal** |
| Co-desarrolladores futuros | **Investigadores colaboradores** |
| Equipo CIEP que usa el Simulador como herramienta | **Investigadores** |
| Personas que usan la herramienta web pública | **Usuarios externos** |

## Acciones técnicas

| Concepto técnico | Término adoptado |
|---|---|
| Release | **Publicación** (verbo: "publicar una versión") |
| Commit | **Commit** (se conserva, con explicación inline la primera vez) |
| Tag | **Etiqueta de versión** |

## Artefactos físicos

| Concepto técnico | Término adoptado |
|---|---|
| Repositorio Git en GitHub | **Código del Simulador** |
| Carpeta Dropbox que recibe versión publicada | **Carpeta del Simulador para investigadores** |
| Rama Git de desarrollo | **Rama de trabajo** |
| Archivo manifest con SHA-256 de datos | **Catálogo de datos asociados** |

## Conjunto de productos

| Concepto | Término adoptado |
|---|---|
| Los tres simuladores web interactivos del CIEP como colectivo (Fiscal CIEP, IEPS al tabaco, tenencia vehicular) | **Simuladores CIEP** |
| El conjunto completo de productos digitales + infraestructura + dominios del CIEP | **Ecosistema CIEP** |
| Productos narrativos del CIEP vinculados a proyectos bandera | **Micrositios** |

**Simuladores CIEP** (sustantivo colectivo plural, registro formal): los tres simuladores web interactivos del CIEP — Simulador Fiscal CIEP, Simulador IEPS al tabaco, Simulador de tenencia vehicular. Cada uno tiene repositorio Git propio y desarrollo paralelo; comparten código por reuso histórico, no por dependencia activa. Cuando un documento de governance refiere a *"los Simuladores CIEP"*, las políticas y procedimientos aplican a los tres por defecto, no por excepción. Cuando refiere a *"el Simulador Fiscal CIEP"* (singular, con apellido), aplica solo a ese. Hoy el caso operativo más maduro es el Simulador Fiscal CIEP; los otros dos existen sustantivamente como sitios web públicos pero su governance formal está pendiente. Sinónimo coloquial aceptable: "Simuladores fiscales CIEP".

**Ecosistema CIEP** (sustantivo, registro formal): conjunto completo de productos digitales + infraestructura + dominios del CIEP. Incluye: Simuladores CIEP, Micrositios, sitio principal `ciep.mx`, hosting (Cloudways/Hostinger), VPS IONOS, y dominios `*.ciep.mx`. La infraestructura es parte del Ecosistema, no su contexto externo. Sinónimo coloquial aceptable: "Ecosistema digital del CIEP".

**Micrositios** (sustantivo común, plural): productos narrativos del CIEP vinculados a proyectos bandera. Contenido estructurado (gráficos, narrativa, datos) sin código activo de cálculo, a diferencia de los Simuladores CIEP. Audiencias amplias. Stack actual: Cloudways (migrando a Hostinger). Cadencia: uno por año más actualizaciones de existentes. Sinónimo coloquial aceptable: "Micrositios narrativos".

## Registro formal vs. coloquial

La documentación formal del CIEP usa términos cortos y técnicos. La conversación, presentaciones generales y comunicación al público pueden usar formas más descriptivas. Ninguno está mal; cada uno tiene su lugar.

| Formal (documentación) | Coloquial (conversación, presentaciones) |
|---|---|
| Simuladores CIEP | Simuladores fiscales CIEP |
| Ecosistema CIEP | Ecosistema digital del CIEP |
| Micrositios | Micrositios narrativos |

## Términos eliminados del vocabulario

| Término viejo | Reemplazo |
|---|---|
| "Canónico" (en cualquier contexto) | "Oficial", "de referencia", "institucional" según contexto |
| "Data Sidecar", "Sidecar pattern" | Eliminado. Se describe en prosa: "los datos viven separados del Código del Simulador, listados en el Catálogo de datos asociados" |
| "Mantenedor" | "Investigador principal" / "investigador colaborador" |
| "Audit trail", "single source of truth", "build artifact" | Describir en español llano cuando aparezcan |

## Términos en inglés que se conservan

Con explicación inline la primera vez: `Git`, `GitHub`, `commit`, `push`, `pull`, `branch` (junto a "rama"), `merge`, `rewrite`, `SHA`.

## Gestor de secretos institucional

**Gestor de secretos institucional:** herramienta especializada donde viven los valores reales de las credenciales del CIEP. Ejemplos: 1Password Teams, Bitwarden Teams. La adopción formal está pendiente de decisión administrativa.

## Cómo se modifica este glosario

Todo cambio de vocabulario se hace primero en este archivo (fuente canónica). Si el cambio afecta al subconjunto compacto que vive en `.windsurfrules`, se sincroniza ahí en el mismo trabajo. La bitácora de abajo registra cada cambio.

## Bitácora de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| v1.0 | 2026-05-15 | Creación del documento. Migración del Glosario CIEP desde `.windsurfrules` (donde vivía en las líneas 85–141) a archivo propio como artefacto canónico autónomo. Contenido preservado verbatim. `.windsurfrules` conserva el subconjunto operativo compacto (tablas) con nota de fuente canónica. |
