{smcl}
{* *! version 8.4 CIEP 23sep2026}{...}
{viewerjumpto "Descripción" "SIMroot##description"}{...}
{viewerjumpto "Sintaxis" "SIMroot##syntax"}{...}
{viewerjumpto "Opciones" "SIMroot##options"}{...}
{viewerjumpto "Cómo se resuelve la raíz" "SIMroot##resolution"}{...}
{viewerjumpto "Qué se guarda en la raíz" "SIMroot##layout"}{...}
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
{cmd:SIMroot} [{cmd:,} {opt d:ir(ruta)} {opt reset} {opt q:uietly}]
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

{marker examples}{...}
{title:Ejemplos}

{pstd}Usuario externo: instalar y correr en una carpeta propia{p_end}
{phang2}{cmd:. net from https://ciep.mx/simuladorfiscal/}{p_end}
{phang2}{cmd:. net install PEF}{p_end}
{phang2}{cmd:. cd "~/Simulador"}{p_end}
{phang2}{cmd:. PEF, anio(2027)}{p_end}

{pstd}Fijar la raíz explícitamente (por ejemplo en tu {cmd:profile.do}){p_end}
{phang2}{cmd:. SIMroot, dir("/Volumes/Datos/SimuladorCIEP")}{p_end}

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
{p2colreset}{...}

{hline}
{pstd}
Ver también: {help ensure_asset}, {help PEF}, {help LIF}, {help SCN}.
{p_end}
