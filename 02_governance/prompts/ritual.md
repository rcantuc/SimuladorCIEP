# Sesión v<X.Y.Z> — merge de <#PR…> + ritual hasta `--check` (<nocturna, sin intervención humana | con Ricardo>)

**Punto de partida:** `master` = `<hash corto>` (<versión en producción>). Verifica el endpoint con `curl -s "https://ciep.mx/simuladorfiscal/stata.toc?x=$(date +%s)" | sed -n 3p` (sin `?x=` responde la caché del CDN) y repórtalo; si no coincide, diagnostica sin tocar el endpoint. **Un agente por repo.** **Una sola corrida completa, anunciada**: la del paso `sim` (más la de `contrato-32`, que corre su propio `SIM.do`). No corras `publicar.sh vX.Y.Z` ni `publicar-vps.sh`: eso es de Ricardo.

## 1. Antes del merge

<<CONTENIDO>>

<Lo que hay que salvar de worktrees o ramas antes de fusionar (`gh pr merge --delete-branch` borra el worktree local: runbook §14.1, lección 9), datos que se copian a `-datos` con su verificación (sha contra el manifest, sello, `cmp`; nunca a Dropbox: firma §C), y conflictos esperados entre PR.>

## 2. Merges

- `gh pr merge <n> --merge --delete-branch`, en este orden: <…>. Si el segundo queda `BEHIND`: `gh pr update-branch`, esperar los checks y fusionar; nunca `--admin` (lección 10).
- El hash del último merge es `$H` **literal**, los 40 hex, en todo lo que sigue.
- Worktrees de la sesión anterior: `git worktree remove --force` si siguen ahí; `git worktree prune`; `git fetch --prune`.

## 3. Ritual

`bash 05_scripts/ritual.sh v<X.Y.Z> --hash <$H literal> --si` en `-datos` (runbook §14). Corre merge → baile → sim → web → c32 → precache → sidecar → release-commit → tag → check → listo y se detiene en el primer rojo.

- **El clon de Dropbox es intocable** (firma CUAD-1-2 §C, 8.16b): el paso `baile` solo mueve `-datos` (`fetch`, `checkout master`, `pull --ff-only`); ninguna orden del ritual ni de la sesión toca Dropbox. Si `master` quedó extraído ahí, lo resuelve Ricardo.

- **`--si` es obligatorio en sesiones nocturnas:** sin tty el paso `tag` no puede preguntar, y sin `--si` falla sin crear nada. Con Ricardo presente se omite y el tag se confirma en la terminal.

- **gate-numeros:** <VERDE (no mueve números) | ROJO aceptado con `--baseline-nuevo` (mueve el baseline a vX.Y.Z)>. Si sale ROJO sin estar previsto, para: reporte con el diff de llaves y nada más.
- **Release commit:** ya debe estar en el PR. Si `release-commit` falla, es un PR corto (branch protection: sin push directo) y el ritual vuelve a empezar en `merge` con el hash nuevo.
- **Al reanudar:** `--desde <paso>` y la misma evidencia; no se repite lo que ya pasó.
- **Al cerrar:** `-datos` en `master` = `$H` (Ricardo publica desde ahí), Dropbox sin tocar, sin Stata vivo y árbol de `-datos` limpio.

## Evidencia

`~/CIEP_Simuladores/diag-v<X.Y.Z>-<AAAA-MM-DD>/`: `ritual.log`, `ritual-<n>-<paso>.out`, `01-ritual/`, `02-test-web-batch/`, `c32/` y lo del paso 1.

## Reporte (Ricardo lo lee <mañana | al terminar>)

- Hash `$H`; estado del `stata.toc`.
- Tabla del ritual con cada paso, resultado y ruta de evidencia (sale de `ritual.log`).
- `--check` N/N.
- La frase **«listo para publicar: `publicar.sh v<X.Y.Z>` y `publicar-vps.sh v<X.Y>`»**, o lo que falta, una línea por renglón.
- Lo que salió distinto de este prompt, una línea por desviación.
- Si algo rojo te detiene, el reporte abre con eso y no sigues: no se improvisa de noche.
