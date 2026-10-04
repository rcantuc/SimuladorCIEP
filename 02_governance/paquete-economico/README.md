# paquete-economico/ — Expediente de diseño del rediseño de `paqueteeconomico.ciep.mx`

Documentos de agosto-septiembre de 2026 que definen el marco conceptual del Paquete Económico como producto permanente (nodos temáticos, series históricas, contrato de datos con el Simulador). No son normas del Simulador Fiscal: son el diseño de un proyecto hermano que **consume** el Simulador vía `escalar` → `scalarjson.ado`.

**Estado:** diseño en curso; piloto del nodo de deuda implementado en `01_modulos/nodos/`.

| Documento | Qué es |
|---|---|
| `nueva-era.md` | Diagnóstico del sitio actual y rediseño del operativo anual bajo el marco conceptual. Empieza aquí. |
| `independencia-metodologica-series.md` | Adenda: por qué las cifras propias no tienen que coincidir con las oficiales (coincidir ≠ verificar) y cómo se presentan las series históricas. |
| `nodo-deuda-ficha-y-disyuntiva.md` | Especificación del nodo piloto (deuda pública): `nodo.yml`, ficha, disyuntiva. Sin cifras: solo nombres de escalar. |
| `nodo-deuda-vista-previa.md` | Dónde vive cada pieza del piloto (fuente versionada vs. salida generada) y cómo verlo en local. Lo citan `01_modulos/nodos/portada.html` y `nodo-deuda.html`. |

El principio que gobierna todo esto —*Stata produce todos los números; la página solo renderiza*— es transversal al ecosistema y por eso vive un nivel arriba, en `../principio-stata-produce-los-numeros.md`.

Los reportes fechados que precedieron a estos documentos (inventario, plan de integración y verificación del repo, 2026-08-01) están en `../historico/`.
