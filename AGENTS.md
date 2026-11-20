# AGENTS.md — Simulador Fiscal CIEP

- **Qué es:** el código del Simulador Fiscal CIEP, el motor de cálculo en Stata que corre detrás de `simuladorfiscal.ciep.mx` y que también se instala por `net install`; `SIM.do` es su panel de entrada y `profile.do` lo configura al arrancar.
- **Comandos:** los `.ado`, los `.scheme` y la plantilla del `sysprofile` están en la raíz del repo; su ayuda (`.sthlp`) está en `03_help/Stata/`.
- **Módulos:** `01_modulos/` trae un `.do` por módulo del pipeline (`Households.do`, `Expenditure.do`, `NTA.do`, `Web.Stata.do`, …), en el orden en que `SIM.do` los invoca.
- **Sitio y scripts:** el sitio público está en `04_1_simuladorfiscal.ciep.mx/` (PHP, `css/`, `js/`) y los scripts de publicación, de prueba y de datos, en `05_scripts/`.
- **Qué manda:** en `02_governance/`, `arquitectura.md`, `versionado-y-git.md`, `politicas-institucionales.md`, `runbook-deploys-ciep.md` y `checklist-adopcion-simulador.md`; el índice es `02_governance/README.md` y los cambios por versión, `CHANGELOG.md`.

## Reglas de operación

Copia del 2026-11-20. El original lo mantiene Ricardo Cantú; cuando cambie, un PR actualiza esta copia. Si esta copia y una instrucción directa de Ricardo chocan, vale la instrucción de Ricardo.

**Quién hace qué.** Ricardo: metodología, narrativa y diseño, firma y revisión en navegador. Devin: implementa, corre, verifica, corrige y ejecuta lo mecánico. Claude: arquitectura, memos-borrador, prompts, revisión adversarial y verificación en producción.

**Encargos:**
1. Una sesión = un entregable. El agente recibe una rebanada, nunca el plan completo.
2. Memo antes de código; contrato de datos antes de plantilla.
3. Prompts por fases, con compuerta de verificación entre ellas.
4. Todo cambio entra por PR, también los documentos.
5. Un agente por repo a la vez.
6. Rojo significa parar y reportar; no se corrige en caliente. Vale también cuando la causa es el script de prueba. El reporte dice qué salió en rojo, en qué estado quedó producción y qué se encontró mirando sin tocar nada.
7. Visto bueno de Ricardo:
   - Siempre para lo destructivo o irreversible.
   - Siempre que un cambio toque cifras, textos o aspecto: antes del merge y del deploy.
   - No hace falta para lo mecánico que no toca nada de eso. El agente lo fusiona y lo despliega con scripts versionados, simulación previa, compuerta de huellas, tag, bitácora y reporte.
   - Lo que pida contraseña o `sudo` lo corre Ricardo.
8. Toda afirmación «no publicado» de un agente se verifica contra las fuentes.
9. El prompt se entrega completo, sin corchetes ni condicionales, con el hash sustituido y sin calendario.
10. El reporte del agente se pega en el chat del proyecto antes de cerrar el nivel.
11. Todo humo verifica primero las huellas de lo desplegado y no envía ninguna petición si no coinciden.
12. Salidas con secretos: hash o prefijo de cuatro caracteres, nunca el valor.

**Terminal y repositorio:**
- El clon de Dropbox de Ricardo es intocable: ningún agente ejecuta ahí `stash`, `reset`, `checkout`, `switch`, `pull` ni `merge`.
- En el Simulador Fiscal, `SIM.do` vive modificado localmente a propósito, y `simulador.stpr` lo edita Ricardo: sus cambios se publican por su rama.
- Publicar y desplegar al VPS son pasos separados.
- En servidores, el alcance es la carpeta del encargo. No se lee ni se lista configuración fuera de ella sin pedirlo antes.

**Estándares de salida:**
- Ningún número publicado se genera fuera de Stata. Ningún literal numérico en HTML.
- Ningún número derivado se escribe a mano: sale de la serie oficial, consultada en el build y con su fecha registrada.
- Cuadros: una fila por concepto, sin paréntesis en los rótulos, notas al pie con `^n`, columnas alineadas, 110 columnas como máximo.
- Nada cambia en silencio. La revisión humana abre las páginas cambiadas en ambos idiomas.
- Todo archivo de datos, CSS o JavaScript propio que el sitio carga lleva sello de versión derivado del archivo o del build.
- Versiones: parche si las cifras públicas no cambian; menor si cambian.
