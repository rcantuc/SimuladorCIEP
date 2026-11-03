# historico/ — documentos congelados

Lo que dejó de aplicar pero un documento vigente (o el código) todavía cita. No se edita: cada archivo abre con una nota de cuándo se retiró, por qué y qué lo reemplaza. Lo que nadie cita no viene aquí, se borra (`02_governance/README.md`, política de higiene); `git log --follow` lo recupera. Un archivo entra o sale de esta carpeta en el mismo commit que su línea en este índice.

| Archivo | Fecha | Qué lo reemplaza | Quién lo cita |
|---|---|---|---|
| `F0-reproducibilidad-ancla-2026-10-06.md` | 2026-10-06 | `runbook-deploys-ciep.md` §9 (receta de las anclas) | `repro-1-2026-10-28.md` (diagnóstico base) |
| `auditoria-drift-sthlp.md` | 2026-05-25 | — (auditoría one-shot) | `guia-simulador-bien-gobernado.md` §1 |
| `bitacora-arquitectura.md` | 2026-05-12 → 2026-10-01 (congelada el 2026-10-03) | `arquitectura.md` y `CHANGELOG.md` | `arquitectura.md`, `guia-simulador-bien-gobernado.md`, `03_help/manual-investigador-ciep.md`, `05_scripts/backup-vps.sh` |
| `conc-1-scn-sankey-2026-10-30.md` | 2026-10-30 (archivado el 2026-11-03) | `CUAD-0.md` (capítulo `Households`) | `CUAD-0.md` (`C1 §x`), README raíz, comentarios «CONC-1» de `NTA.do`, `Households.do`, `SCN.ado` |
| `fase-0-5-git-hygiene-audit.md` | 2026-05-09 | `versionado-y-git.md` §6, `05_scripts/verify_gitignore.sh` | `arquitectura.md` §7, `.gitignore` |
| `nta-0-inventario-2026-10-27.md` | 2026-10-27 (archivado el 2026-11-03) | header de `01_modulos/NTA.do`, `CUAD-0.md` | `NTA.do`, `Distribucion.ado`, README raíz |
| `reconocimiento-vps.md` | 2026-07-09 (archivado el 2026-10-03) | `runbook-deploys-ciep.md` §4 (estructura `vN.M` + `current`) | `05_scripts/publicar-vps.sh`, `politicas-institucionales.md`, `03_help/manual-investigador-ciep.md` |
| `repro-1-2026-10-28.md` | 2026-10-28 (archivado el 2026-11-03) | `runbook-deploys-ciep.md` §9–§10, §14 | README raíz |
