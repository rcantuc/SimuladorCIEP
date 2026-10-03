# 02_governance — Documentación institucional del Simulador Fiscal CIEP

Esta carpeta contiene los documentos vivos que describen la arquitectura, las convenciones y las políticas del Simulador Fiscal CIEP. Si eres nuevo en el proyecto, este índice te dice qué documento abrir según lo que necesites.

## Documentos vigentes

**`CHANGELOG.md`** — Registro operativo de cambios por versión publicada del Simulador (qué cambió para el investigador en cada v8.x). Referencia obligatoria al publicar: el Gate 1 de `publicar.sh` exige una entrada por versión.

**`arquitectura.md`** — Arquitectura de distribución del Simulador: canales de publicación (GitHub Releases, endpoint Stata, Carpeta para investigadores), estructura del repo con la convención de prefijos numéricos, y política del `.stpr`. Su bitácora histórica (v1.0–v1.57) está congelada en `historico/bitacora-arquitectura.md`; desde 2026-10-03 los cambios se registran solo en `CHANGELOG.md`.

**`versionado-y-git.md`** — Parte I: convenciones de commits, ramas, etiquetas de versión, reescritura de historia y verificación del `.gitignore`. Parte II: historia de versiones (era v7.x de transición vs. era v8.0+ institucional) y contexto de los releases publicados en GitHub.

**`politicas-institucionales.md`** — Parte I: política de gestión de secretos y credenciales del CIEP (qué cuenta como secreto, dónde vive, qué hacer si se compromete). Parte II: marco de ciclo de vida de productos del Ecosistema CIEP (documento bandera vs. micrositio).

**`glosario-ciep.md`** — Glosario de términos técnicos e institucionales usados en toda esta carpeta.

## Subdirectorios

**`deploys/`** — Log persistente del pipeline de publicación al endpoint (`endpoint-stata.log`): cada deploy, verificación de Release y backup queda registrado ahí (el archivo es local, no se versiona).

**`historico/`** — Documentos fechados o reportes one-shot ya ejecutados. Son registros congelados: no se editan. Incluye el análisis del gate semántico (decisión tomada: Gate α implementado como Gate 4 en v8.0.5; quedan los candidatos descartados como registro), la auditoría de sincronía `.ado` ↔ `.sthlp` (fechada 2026-05-25), y los 3 registros de las fases 0–0.5 del reconocimiento inicial del repo.

## Guía rápida por caso de uso

- ¿Vas a publicar una versión nueva? → `CHANGELOG.md` + `versionado-y-git.md` §3
- ¿Eres investigador nuevo en el equipo? → `arquitectura.md` primero, después `politicas-institucionales.md` (el manual práctico vive en `03_help/manual-investigador-ciep.md`)
- ¿Necesitas entender la estructura del repo? → `arquitectura.md` §2
- ¿Manejas credenciales del CIEP? → `politicas-institucionales.md` Parte I
- ¿Decides qué hacer con un producto CIEP que envejece? → `politicas-institucionales.md` Parte II
- ¿Vas a tocar el `.gitignore`? → `versionado-y-git.md` §6 + `05_scripts/verify_gitignore.sh`
- ¿Términos que no reconoces? → `glosario-ciep.md`

## Política de higiene de esta carpeta

Reglas operativas para mantener orden en este directorio mientras crece:

- **Los documentos vivos se reescriben en su lugar.** Cuando un documento cambia de versión (de `v1.0` a `v2.0`, por ejemplo), se sobrescribe el mismo archivo y la bitácora interna del documento registra el cambio. No hay archivos versionados con sufijos `_v1`, `_v2` en el directorio actual; las versiones viejas viven en la historia de Git, accesibles con `git log --follow <archivo>`.
- **Documentos que dejan de aplicar se archivan en `02_governance/historico/`.** Esto pasa cuando la realidad o la decisión cambian y el documento ya no describe el sistema actual. Al mover, se agrega una nota corta en el archivo explicando por qué se retiró y qué documento vigente lo reemplaza (si aplica).
- **No se borra nada permanentemente.** Aunque un documento sea obsoleto, queda en `02_governance/historico/` para que el contexto histórico de decisiones siga consultable.
