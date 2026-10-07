{smcl}
{* *! version 8.6 CIEP 06oct2026}{...}
{viewerjumpto "Descripción" "SIMroot##description"}{...}
{viewerjumpto "Sintaxis" "SIMroot##syntax"}{...}
{viewerjumpto "Opciones" "SIMroot##options"}{...}
{viewerjumpto "Cómo se resuelve la raíz" "SIMroot##resolution"}{...}
{viewerjumpto "Qué se guarda en la raíz" "SIMroot##layout"}{...}
{viewerjumpto "Modo motor: scheme y smoke" "SIMroot##motor"}{...}
{viewerjumpto "Ejemplos" "SIMroot##examples"}{...}
{viewerjumpto "Resultados" "SIMroot##results"}{...}

{title:SIMroot — Raíz del proyecto del Simulador Fiscal CIEP}

{pstd}
{bf:Centro de Investigación Económica y Presupuestaria, A.C.} {c |} {browse "https://ciep.mx":ciep.mx}{break}
Ricardo Cantú Calderón {c |} {browse "mailto:ricardocantu@ciep.mx":ricardocantu@ciep.mx}
{p_end}

{hline}

{marker description}{...}
{title:Descripción}

{pstd}
{cmd:SIMroot} fija la {bf:carpeta raíz} donde los comandos del Simulador Fiscal
CIEP ({cmd:PEF}, {cmd:LIF}, {cmd:SCN}, {cmd:SHRFSP}, {cmd:PIBDeflactor},
{cmd:Poblacion}, {cmd:DatosAbiertos}, {cmd:AccesoBIE}, {cmd:ensure_asset}) leen y
escriben sus datos: {cmd:raw/} (insumos descargados de las Releases de GitHub),
{cmd:master/} (bases procesadas) y {cmd:users/}{it:<usuario>}{cmd:/} (salidas y
gráficas). La raíz queda en la global {cmd:$SIMROOT}, sin diagonal final.
{p_end}

{pstd}
Normalmente {ul:no necesitas invocarlo}: cada comando del Simulador lo llama al
arrancar y la primera llamada de la sesión decide la carpeta. Lo invocas a mano
solo para {bf:elegir otra carpeta} o para consultar cuál está activa.
{p_end}

{pstd}
{bf:Por qué existe.} Hasta v8.3 los comandos usaban {cmd:c(sysdir_site)} como
raíz. Ese directorio es el de ado-files de la instalación de Stata (por ejemplo
{cmd:/Applications/Stata/ado/site/} o {cmd:C:\Program Files\Stata18\ado\site\}):
no tiene permisos de escritura para un usuario normal, así que quien instalaba
los comandos con {cmd:net install} no podía reconstruir datos sin redefinir
{cmd:SITE} en su {cmd:sysprofile.do}. Desde v8.4 la raíz es el directorio de
trabajo (o la que tú indiques) y {cmd:SITE} vuelve a ser cosa de Stata.
{p_end}

{marker syntax}{...}
{title:Sintaxis}

{p 8 16 2}
{cmd:SIMroot} [{cmd:,} {opt d:ir(ruta)} {opt reset} {opt q:uietly} {opt sch:eme} {opt sm:oke}]
{p_end}

{marker options}{...}
{title:Opciones}

{phang}
{opt dir(ruta)} fija la raíz explícitamente. Si la carpeta no existe, la crea.
Equivale a {cmd:global SIMROOT "ruta"} pero además normaliza la ruta (absoluta,
sin diagonal final) y crea {cmd:raw/}, {cmd:raw/temp/}, {cmd:master/} y {cmd:users/}.
{p_end}

{phang}
{opt reset} vuelve a resolver la raíz aunque {cmd:$SIMROOT} ya esté fijada
(útil tras un {cmd:cd} si quieres que el Simulador siga al nuevo directorio).
{p_end}

{phang}
{opt quietly} suprime el aviso que se muestra cuando la raíz se toma del
directorio de trabajo.
{p_end}

{phang}
{opt scheme} (modo motor, v8.6) exige que la raíz sea la carpeta {bf:completa} del
simulador y ejecuta {cmd:set scheme ciep}. Es lo que llama {cmd:SIM.do} §0.0.
{p_end}

{phang}
{opt smoke} (modo motor, v8.6) corre la prueba de humo de
{cmd:05_scripts/test-maquina-virgen.sh --zip} y devuelve {cmd:r(smoke)} = 1.
También se activa con la variable de entorno {cmd:SIM_SMOKE=1} cuando se pide {opt scheme}.
{p_end}

{marker resolution}{...}
{title:Cómo se resuelve la raíz}

{pstd}
En este orden; la primera regla que aplica gana y la decisión se guarda en
{cmd:$SIMROOT} para el resto de la sesión:
{p_end}

{phang2}1. Si {cmd:$SIMROOT} ya está fijada (y no pides {opt reset}), no cambia nada.{p_end}
{phang2}2. Si das {opt dir()}, esa es la raíz.{p_end}
{phang2}3. Si {cmd:c(sysdir_site)} contiene {cmd:05_scripts/manifest.json}, es un clon del
repositorio apuntado por {cmd:sysprofile.do} (investigadores CIEP, servidor web): se
usa esa carpeta. Así las instalaciones anteriores a v8.4 siguen funcionando igual.{p_end}
{phang2}4. En otro caso, la raíz es el {bf:directorio de trabajo actual} ({cmd:c(pwd)}) y
se muestra un aviso con la ruta elegida.{p_end}

{pstd}
{bf:Recomendación para usuarios externos:} antes de correr el primer comando,
colócate en la carpeta donde quieres los datos ({cmd:cd "C:\Proyectos\Simulador"}).
Las bases pesan varios GB; no uses el Escritorio ni una carpeta sincronizada
con la nube si puedes evitarlo.
{p_end}

{marker layout}{...}
{title:Qué se guarda en la raíz}

{p2colset 9 22 24 2}{...}
{p2col:{cmd:raw/}}insumos oficiales (ENIGH, PEFs, LIFs, Cuentas Nacionales…) descargados y verificados por {cmd:ensure_asset} contra el SHA-256 de la Release instalada{p_end}
{p2col:{cmd:raw/temp/}}archivos intermedios y caché del manifest{p_end}
{p2col:{cmd:master/}}bases procesadas ({cmd:PEF.dta}, {cmd:LIF.dta}, {cmd:SCN.dta}…) que consumen los comandos{p_end}
{p2col:{cmd:users/}{it:id}{cmd:/}}salidas por usuario: gráficas ({cmd:graphs/}), {cmd:output.txt}, bases derivadas{p_end}
{p2colreset}{...}

{marker motor}{...}
{title:Modo motor: scheme y smoke}

{pstd}
{cmd:SIM.do} no puede ejecutar {cmd:SIMroot} antes de encontrarlo (huevo y gallina),
así que su sección 0.0 solo localiza la carpeta del simulador (la carpeta de trabajo,
o el {cmd:SITE} del {cmd:sysprofile.do}), la mete al adopath y delega aquí con
{cmd:SIMroot, dir(...) scheme}. Con {opt scheme} o {opt smoke}:
{p_end}

{phang2}1. Se valida que la raíz contenga {cmd:SIM.do}, {cmd:SIMroot.ado},
{cmd:scheme-ciep.scheme} y {cmd:05_scripts/manifest.json}; si falta algo se detiene
con la instrucción exacta ({cmd:File > Change Working Directory...} o {cmd:cd}, y
luego {cmd:do "SIM.do"}; r(601)). Por eso aquí {opt dir()} {ul:no} crea la carpeta.{p_end}
{phang2}2. {opt scheme}: {cmd:set scheme ciep} (el scheme vive en la raíz, que ya está
en el adopath).{p_end}
{phang2}3. {opt smoke}, o {cmd:SIM_SMOKE=1} en el entorno junto con {opt scheme}: desde
{cmd:raw/temp/} (otra carpeta de trabajo, como la deja {cmd:Expenditure.do}) se
comprueba con {cmd:which} que los {cmd:.ado} del motor se siguen encontrando
(la clase de falla {it:command LIF is unrecognized}) y se devuelve
{cmd:r(smoke)} = 1; {cmd:SIM.do} termina entonces sin correr el pipeline.
Sin la prueba, {cmd:r(smoke)} = 0.{p_end}

{marker examples}{...}
{title:Ejemplos}

{pstd}Usuario externo: instalar y correr en una carpeta propia{p_end}
{phang2}{cmd:. net from https://ciep.mx/simuladorfiscal/}{p_end}
{phang2}{cmd:. net install PEF}{p_end}
{phang2}{cmd:. cd "~/Simulador"}{p_end}
{phang2}{cmd:. PEF, anio(2027)}{p_end}

{pstd}Fijar la raíz explícitamente (por ejemplo en tu {cmd:profile.do}){p_end}
{phang2}{cmd:. SIMroot, dir("/Volumes/Datos/SimuladorCIEP")}{p_end}

{pstd}Prueba de humo de un clon (lo que hace {cmd:test-maquina-virgen.sh --zip} vía {cmd:SIM.do}){p_end}
{phang2}{cmd:. SIMroot, dir("~/Downloads/SimuladorCIEP-master") smoke}{p_end}

{pstd}Consultar la raíz activa{p_end}
{phang2}{cmd:. SIMroot}{p_end}
{phang2}{cmd:. di "$SIMROOT"}{p_end}

{marker results}{...}
{title:Resultados}

{pstd}
{cmd:SIMroot} guarda en {cmd:r()}:
{p_end}

{synoptset 12 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(root)}}raíz del proyecto (igual a {cmd:$SIMROOT}){p_end}
{synopt:{cmd:r(smoke)}}1 si corrió la prueba de humo (modo motor), 0 en otro caso{p_end}
{p2colreset}{...}

{hline}
{pstd}
Ver también: {help ensure_asset}, {help PEF}, {help LIF}, {help SCN}.
{p_end}
