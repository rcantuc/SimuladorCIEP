# 02_governance/prompts — plantillas de prompt de sesión

**Todo prompt de sesión nace de una de estas plantillas.** Las sesiones de octubre y noviembre de 2026 (v8.15a, v8.15b-pre, v8.15b, v8.15.1, post-v8.15.1, v8.15.2) repetían los mismos bloques a mano: punto de partida con hash, rama/PR/checks, un agente por repo, una sola corrida completa al final, qué no entra, evidencia y formato del reporte. Cuando faltaba uno, la sesión lo improvisaba. Aquí esos bloques son fijos y lo específico va en `<<CONTENIDO>>`.

| Plantilla | Para | Ejemplos de origen |
|---|---|---|
| `memo.md` | Documento de solo lectura: memo, inventario o diagnóstico. No toca el motor ni ningún número. | v8.15a (CUAD-0), inventario 8.18a |
| `implementacion.md` | Cambio de código o de datos en una rama con PR: mueva números o no. | v8.15b-pre, v8.15b, v8.15.1 (hotfix), PR de datos SCN |
| `ritual.md` | Merge, ritual de publicación hasta `--check` y «listo para publicar», con `ritual.sh`. | v8.15.2 |

## Cómo se usa

1. Copia la plantilla y llena los `<…>` del encabezado: hash de partida, rama, versión y fecha.
2. Escribe lo específico en `<<CONTENIDO>>`, con entregables numerados y gates verificables: un número, un archivo o un exit code, nunca «que quede bien».
3. Deja los bloques fijos como están. Si uno no aplica, escribe «no aplica» y la razón; no lo borres: el agente lee la ausencia como permiso.
4. El cambio que aparezca en tres prompts seguidos sube a la plantilla en un PR, y este README dice de qué sesión salió.

Los bloques fijos no sustituyen al runbook. Lo citan: §14 (`ritual.sh` y lecciones), §10 (topología y baile), §11 (qué gate corre dónde).
