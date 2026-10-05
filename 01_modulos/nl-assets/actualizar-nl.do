*! actualizar-nl.do — corrida conjunta de los drivers de la capa NL (lo invocan actualizar-nl.sh y windows/actualizar-nl.ps1)
* Se ejecuta con Stata en batch desde la raíz del worktree, de modo que profile.do
* carga aniovp/anioPE, $entidadesC y el token del BIE como en una sesión normal.
* Cada driver aborta por sí mismo si una compuerta falla; el script de shell
* detecta el error en el log y no publica.
SIMroot
noisily di _newline in g "actualizar-nl: raíz " in y "${SIMROOT}" in g " · aniovp " in y `=aniovp' in g " · anioPE " in y `=anioPE'
do "${SIMROOT}/01_modulos/PoblacionNL.do"
do "${SIMROOT}/01_modulos/PIBDeflactorNL.do"
* FederacionNL depende de los dos anteriores (denominadores de la misma corrida); en el
* runner corre en modo sello (nl-assets/federacion-sello.json), en el Mac en modo canal. *
do "${SIMROOT}/01_modulos/FederacionNL.do"
noisily di _newline in g "actualizar-nl: " in y "LOS TRES DRIVERS TERMINARON"
