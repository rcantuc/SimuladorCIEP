# Runner Windows — Simulador Fiscal NL (capa NL-0.3.0)

La laptop HP de CoNL (Windows 11, Stata 19.5 StataNow, Git, Tailscale, Google Drive Desktop) es un **runner**: clona la rama `feature/entidad-nl` en **solo lectura**, corre los drivers NL en Stata batch y publica los endpoints al Drive de CoNL **de esa máquina**. Jamás desarrolla, jamás hace push. Si el working tree aparece sucio, el runner aborta: alguien editó donde no debía.

## Checklist de instalación (una vez, ~15 minutos)

1. **PowerShell como administrador** (clic derecho → "Ejecutar como administrador") y permite scripts firmados/locales:
   `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
2. **Prerrequisitos**: Git para Windows instalado (`git --version`), `git config --global core.autocrlf false`, Google Drive Desktop abierto con la cuenta de CoNL (debe existir `G:\Mi unidad\2. Simuladores CoNL`), Stata 19.5 instalado en `C:\Program Files\Stata19\` (o StataNow), Cliente de OpenSSH (viene con Windows 11).
3. **Python para Stata** (lo necesitan `AccesoBIE` y los lectores INEGI): instala Python 3.9–3.12 desde python.org marcando "Add python.exe to PATH" (no desde Microsoft Store). En **Stata**: `python search` → `python set exec "C:\ruta\a\python.exe", permanently` → `python query`. En cmd: `"C:\ruta\a\python.exe" -m pip install requests beautifulsoup4`.
4. Descarga el instalador (solo este archivo, el resto llega con el clon): abre PowerShell y ejecuta
   `Invoke-WebRequest https://raw.githubusercontent.com/rcantuc/SimuladorCIEP/feature/entidad-nl/windows/instalar-runner.ps1 -OutFile $env:TEMP\instalar-runner.ps1; Invoke-WebRequest https://raw.githubusercontent.com/rcantuc/SimuladorCIEP/feature/entidad-nl/windows/runner-common.ps1 -OutFile $env:TEMP\runner-common.ps1`
   (el repo es público, así que la descarga directa funciona; si cambiara a privado, copia ambos archivos a mano desde el Mac).
5. **Instala**: `powershell -ExecutionPolicy Bypass -File $env:TEMP\instalar-runner.ps1`
   La primera vez se detiene en el paso 2 mostrando la **llave pública** de la deploy key.
6. **Registra la deploy key** (solo lectura): GitHub → `rcantuc/SimuladorCIEP` → Settings → Deploy keys → *Add deploy key* → pega la llave, título `runner-conl-<equipo>`, **sin** "Allow write access".
7. **Vuelve a correr el instalador** (es idempotente): clona la rama, genera `windows\config-runner.ps1` (fuera de git) y registra la tarea `SimuladorNL-Actualizar`.
8. **Verifica**: `powershell -ExecutionPolicy Bypass -File C:\Users\<user>\SimuladorCIEP-NL\windows\verificar-runner.ps1`
   Tabla verde/rojo + corrida completa de prueba. Si algo sale rojo, pega a Devin/Claude el archivo `windows\verificacion-runner.log`.
9. Comprueba en el Drive: `G:\Mi unidad\2. Simuladores CoNL\SimuladorCoNL\ultimo-exito.txt` (latido: fecha, vintages, SHAs) y los HTML `poblacion-nl.html`, `actividad-nl.html`.
10. Listo. Cada mes (día 5, 03:00, o en cuanto haya sesión si se omitió) la tarea corre `actualizar-nl.ps1 -RetryOnce`.

## Política del runner

- **Solo lectura**: deploy key sin escritura, clon de una sola rama, `git reset --hard origin/feature/entidad-nl` en cada corrida. El runner nunca tiene cambios propios; si los detecta, aborta y lo reporta.
- **Nunca desarrollar ahí**: cualquier cambio se hace en el Mac y llega por `git push`; el runner lo toma en el siguiente ciclo.
- **Fallo seguro**: si INEGI no responde, una compuerta falla, Stata devuelve `r(#)` o falta un producto, **no se toca el Drive**; se restauran los últimos JSON/HTML buenos y queda el motivo en `windows\bitacora-runner.log`. Reintento único a los 30 minutos si el fallo parece de INEGI (`-RetryOnce`). Nunca publica a medias.
- **Publicación**: `robocopy /MIR` **solo** sobre `...\SimuladorCoNL\nodos\` (espejo, como el rsync del Mac); los HTML se copian a la raíz; `ultimo-exito.txt` es el latido.
- **Motor intacto**: el runner solo ejecuta; la capa NL no modifica archivos del motor.

## Tarea programada y credenciales

- La tarea corre con **InteractiveToken** (sesión iniciada, puede estar bloqueada) porque `G:\` (Google Drive Desktop) solo existe dentro de la sesión del usuario. Si la máquina está apagada o sin sesión a las 03:00 del día 5, Task Scheduler la ejecuta **en cuanto pueda** (`StartWhenAvailable`).
- **Cambio de contraseña de Windows**: con InteractiveToken la tarea **no guarda credenciales**, así que no hay nada que hacer. Si en el futuro se cambia a "ejecutar aunque el usuario no haya iniciado sesión" (requiere guardar la contraseña y perdería `G:\`), habría que volver a registrar la tarea tras cada cambio de contraseña.
- Ver/forzar: `Get-ScheduledTaskInfo SimuladorNL-Actualizar`; `Start-ScheduledTask SimuladorNL-Actualizar`; manual: `powershell -ExecutionPolicy Bypass -File ...\windows\actualizar-nl.ps1 -Manual`.

## Archivos

| Archivo | Qué es | ¿En git? |
|---|---|---|
| `runner-common.ps1` | funciones compartidas (detección de Stata, batch, bitácora, tabla verde/rojo) | sí |
| `instalar-runner.ps1` | instalador idempotente | sí |
| `actualizar-nl.ps1` | port de `actualizar-nl.sh` (fallo seguro, robocopy, latido) | sí |
| `verificar-runner.ps1` | chequeo integral post-instalación | sí |
| `config-runner.ps1.template` | plantilla de configuración | sí |
| `config-runner.ps1` | configuración real de esta máquina | **no** (`windows/.gitignore`) |
| `bitacora-runner.log`, `ultimo-exito.txt`, `*.log` | bitácora y latido locales | **no** |

Todos los `.ps1` están en UTF-8 con BOM (PowerShell 5 los lee bien con acentos) y no requieren PowerShell 7.
