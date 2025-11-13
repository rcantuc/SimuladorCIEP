*Este do-file muestra cómo programar las escalares usando el simulador de CIEP para el libro de CIEP
///////////////////
///		Latex de Ingresos ///
//////////////////



//////// Todos los scalares que refieras en el Latex ponerle la terminación "ing" ; ejemplo: EImpuestos pasaría a EImpuestosing

/// Limpia todo lo de la consola /////
clear all
macro drop _all
scalar anioenigh = 2024

// Directorio ////

if "`c(username)'" == "ricardo" {
	global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}


if "`c(username)'" == "jhon9" {
	global export "C:\Users\jhon9\CIEP Dropbox\TextbookCIEP\images"
}


if "`c(username)'" == "Admin" {
	global export "C:\Users\Admin\CIEP Dropbox\TextbookCIEP\images"
}



//// Se abre la base de datos que quiero trabajar, luego me meto al directorio de scalares con el comando "scalar dir"

/// Busco el nombre de la variable que quiero poner en el textbook 

/// En caso de no tener el formato para el caso de montos "Sin decimales y separados por comas" y en el caso de porcentajes del PIB "tres decimales" y en el caso de tasas de crecimiento "un decimal"



//////////////////////////////////////////////////////////////////////////
////////////////////    Esto para ELASTICIDADES     //////////////////////
////////////////////                                //////////////////////
//////////////////////////////////////////////////////////////////////////

/// La base para 2015 ////
LIF, by(divLIF) anio(2015) rows(2) min(0) nograph // base

/// Obteniendo el deflactor para 2015
scalar Deflactorde2015 = 0.55969178
scalar Deflactora2026 = Deflactorde2015
*scalar str_Deflactora2026 = string(Deflactorde2015, "%20.1fc") // Por si lo quiero referenciar en el documento 

/// monto 2015 (versión numérica)
scalar ImpuestosInicio_val = Impuestos / Deflactora2026
scalar CuotasActualInicio_val = Cuotas / Deflactora2026
scalar ContribActualInicio_val = Contrib_de_mejora / Deflactora2026
scalar DerechosActualInicio_val = Derechos / Deflactora2026
scalar ProductosActualInicio_val = Productos / Deflactora2026
scalar AprovechamientosActualInicio_val = Aprovechamientos / Deflactora2026
scalar VentasInicio_val= Ventas / Deflactora2026
scalar ParticipacionesInicio_val= Participaciones / Deflactora2026
scalar TransferenciasInicio_val= Transferencias / Deflactora2026
scalar IngresosTotalesActualInicio_val = Ingresos_sin_deuda / Deflactora2026

/// monto 2015 (formato string)
scalar ImpuestosInicio = string(ImpuestosInicio_val, "%20.1fc")
scalar CuotasActualInicio = string(CuotasActualInicio_val, "%20.1fc")
scalar ContribActualInicio = string(ContribActualInicio_val, "%20.1fc")
scalar DerechosActualInicio = string(DerechosActualInicio_val, "%20.1fc")
scalar ProductosActualInicio = string(ProductosActualInicio_val, "%20.1fc")
scalar AprovechamientosActualInicio = string(AprovechamientosActualInicio_val, "%20.1fc")
scalar VentasActualInicio = string(VentasInicio_val, "%20.1fc")
scalar ParticipacionesActualInicio = string(ParticipacionesInicio_val, "%20.1fc")
scalar TransferenciasActualInicio = string(TransferenciasInicio_val, "%20.1fc")
scalar IngresosTotalesActualInicio = string(IngresosTotalesActualInicio_val, "%20.1fc")

/// monto PIB 2015 (versión numérica)
scalar ImpuestosInicioPIB_val = ImpuestosPIB
scalar CuotasInicioPIB_val = CuotasPIB
scalar ContribInicioPIB_val = Contrib_de_mejoraPIB
scalar DerechosInicioPIB_val = DerechosPIB
scalar ProductosInicioPIB_val = ProductosPIB
scalar AprovechamientosInicioPIB_val = AprovechamientosPIB
scalar VentasInicioPIB_val = VentasPIB
scalar ParticipacionesInicioPIB_val = ParticipacionesPIB
scalar TransferenciasInicioPIB_val = TransferenciasPIB
scalar IngresosTotalesInicioPIB_val = Ingresos_sin_deudaPIB



/// monto PIB 2015 (formato string)
scalar ImpuestosInicioPIB = string(ImpuestosInicioPIB_val, "%7.3fc")
scalar CuotasInicioPIB = string(CuotasInicioPIB_val, "%7.3fc")
scalar ContribInicioPIB = string(ContribInicioPIB_val, "%7.3fc")
scalar DerechosInicioPIB = string(DerechosInicioPIB_val, "%7.3fc")
scalar ProductosInicioPIB = string(ProductosInicioPIB_val, "%7.3fc")
scalar AprovechamientosInicioPIB = string(AprovechamientosInicioPIB_val, "%7.3fc")
scalar VentasInicioPIB = string(VentasInicioPIB_val, "%7.3fc")
scalar ParticipacionesInicioPIB = string(ParticipacionesInicioPIB_val, "%7.3fc")
scalar TransferenciasInicioPIB = string(TransferenciasInicioPIB_val, "%7.3fc")
scalar IngresosTotalesInicioPIB = string(IngresosTotalesInicioPIB_val, "%7.3fc")


/// La base para 2026 /////
LIF if divPE!=1, by(divLIF) desde(2015) anio(2026) rows(2) min(0) nograph // base

/// monto 2026 (versión numérica)
scalar ImpuestosActual_val = Impuestos
scalar CuotasActual_val = Cuotas
scalar ContribActual_val = Contrib_de_mejora
scalar DerechosActual_val = Derechos
scalar ProductosActual_val = Productos
scalar AprovechamientosActual_val = Aprovechamientos
scalar VentasInicio_Actual_val= Ventas
scalar Participaciones_Actual_val= Participaciones
scalar TransferenciasInicio_Actual_val= Transferencias
scalar IngresosTotalesActual_val = Ingresos_sin_deuda
scalar IngresosTotalesActual_val_bill = Ingresos_sin_deuda/1000000000000


/// monto 2026 (formato string)
scalar ImpuestosActual = string(ImpuestosActual_val, "%20.1fc")
scalar CuotasActual = string(CuotasActual_val, "%20.1fc")
scalar ContribActual = string(ContribActual_val, "%20.1fc")
scalar DerechosActual = string(DerechosActual_val, "%20.1fc")
scalar ProductosActual = string(ProductosActual_val, "%20.1fc")
scalar AprovechamientosActual = string(AprovechamientosActual_val, "%20.1fc")
scalar VentasActual = string(VentasInicio_Actual_val, "%20.1fc")
scalar ParticipacionesActual= string(Participaciones_Actual_val, "%20.1fc")
scalar TransferenciasActual= string(TransferenciasInicio_Actual_val, "%20.1fc")
scalar IngresosTotalesActual = string(IngresosTotalesActual_val, "%20.1fc")
scalar IngresosTotalesActualBill = string(IngresosTotalesActual_val_bill, "%20.2fc")



/// monto PIB 2026 (versión numérica)
scalar ImpuestosActualPIB_val = ImpuestosPIB
scalar CuotasActualPIB_val = CuotasPIB
scalar ContribActualPIB_val = Contrib_de_mejoraPIB
scalar DerechosActualPIB_val = DerechosPIB
scalar ProductosActualPIB_val = ProductosPIB
scalar AprovechamientosActualPIB_val = AprovechamientosPIB
scalar VentasActualPIB_val = VentasPIB
scalar ParticipacionesActualPIB_val = ParticipacionesPIB
scalar TransferenciasActualPIB_val = TransferenciasPIB
scalar IngresosTotalesActualPIB_val = Ingresos_sin_deudaPIB



/// monto PIB 2026 (formato string)
scalar ImpuestosActualPIB = string(ImpuestosActualPIB_val, "%7.3fc")
scalar CuotasActualPIB = string(CuotasActualPIB_val, "%7.3fc")
scalar ContribActualPIB = string(ContribActualPIB_val, "%7.3fc")
scalar DerechosActualPIB = string(DerechosActualPIB_val, "%7.3fc")
scalar ProductosActualPIB = string(ProductosActualPIB_val, "%7.3fc")
scalar AprovechamientosActualPIB = string(AprovechamientosActualPIB_val, "%7.3fc")
scalar VentasActualPIB = string(VentasInicioPIB_val, "%7.3fc")
scalar ParticipacionesActualPIB = string(ParticipacionesInicioPIB_val, "%7.3fc")
scalar TransferenciasActualPIB = string(TransferenciasInicioPIB_val, "%7.3fc")
scalar IngresosTotalesActualPIB = string(IngresosTotalesActualPIB_val, "%7.3fc")

/// Escalares para la elasticidad (formato string)
scalar strEImpuestos = string(EImpuestos, "%7.3fc")
scalar strECuotas = string(ECuotas, "%7.3fc")
scalar strEContrib = string(EContrib_de_mejora, "%7.3fc")
scalar strEDerechos = string(EDerechos, "%7.3fc")
scalar strEProductos = string(EProductos, "%7.3fc")
scalar strEAprovechamientos = string(EAprovechamientos, "%7.3fc")
scalar strEParticipaciones = string(EParticipaciones, "%7.3fc")
scalar strETransferencias = string(ETransferencias, "%7.3fc")
scalar strEVentas = string(EVentas, "%7.3fc")


*scalar str_EIngresosTotales = string(EIngresos_sin_deuda, "%7.3fc") // si aplica

/// Diferencia % real entre 2015-2026 (usando valores numéricos)
scalar DifImpuestos_val = ImpuestosActualPIB_val - ImpuestosInicioPIB_val
scalar DifCuotas_val = CuotasActualPIB_val - CuotasInicioPIB_val
scalar DifContrib_val = ContribActualPIB_val - ContribInicioPIB_val
scalar DifDerechos_val = DerechosActualPIB_val - DerechosInicioPIB_val
scalar DifProductos_val = ProductosActualPIB_val - ProductosInicioPIB_val
scalar DifAprovechamientos_val = AprovechamientosActualPIB_val - AprovechamientosInicioPIB_val

scalar DifVentasPIB_val = VentasActualPIB_val - VentasInicioPIB_val
scalar DifParticipacionesPIB_val = ParticipacionesActualPIB_val - ParticipacionesInicioPIB_val
scalar DifTransferenciasPIB_val = TransferenciasActualPIB_val - TransferenciasInicioPIB_val 
scalar DifIngresosTotales_val = IngresosTotalesActualPIB_val - IngresosTotalesInicioPIB_val

/// Diferencia % real (formato string para exportar)
scalar DifImpuestos = string(DifImpuestos_val, "%7.3fc")
scalar DifCuotas = string(DifCuotas_val, "%7.3fc")
scalar DifContrib = string(DifContrib_val, "%7.3fc")
scalar DifDerechos = string(DifDerechos_val, "%7.3fc")
scalar DifProductos = string(DifProductos_val, "%7.3fc")
scalar DifAprovechamientos = string(DifAprovechamientos_val, "%7.3fc")
scalar DifVentas = string(DifVentasPIB_val,"%7.3fc")
scalar DifParticipaciones = string(DifParticipacionesPIB_val, "%7.3fc")
scalar DifTransferencias = string(DifTransferenciasPIB_val,"%7.3fc" )
scalar DifIngresosTotales = string(DifIngresosTotales_val, "%7.3fc")


//////////////////////////////////////////////////////////////////////////
////////////////////	Esto para La incidencia por Hogar ENIGH 2024 //////
////////////////////							 	   ////////////////////
//////////////////////////////////////////////////////////////////////////

scalar anioenigh = 2024
scalar anioPE = 2026
scalar aniovp = 2026
scalar anioinicio=2015

/// La base para 2015 ////
LIF, by(divSIM) desde(2015) rows(2) min(0) nograph // base 

/// La base para TasasEfectivas ////
TasasEfectivas, enigh nograph //base 

**# 7. CICLO DE VIDA FISCAL
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear // Cargar base

** 7.1 (+) Impuestos y aportaciones
egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)
label var AlTrabajo "Impuestos al trabajo"

egen AlCapital = rsum(ISRPM_Sim OTROSK)
label var AlCapital "Impuestos al capital"

egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)
label var AlConsumo "Impuestos al consumo"

foreach k of varlist AlTrabajo AlCapital AlConsumo {
	noisily Simulador `k' [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot
}


//////////////////////////////////////////////////////////////////////////
////////////////////    Esto para Impuestos  al Consumo  ///////////////////
////////////////////    (IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)  ///////////
//////////////////////////////////////////////////////////////////////////

// Impuestos consumo por hogar al año (formateados con separador de miles)
local strAlConsumoI      : display %20.1fc AlConsumoI
scalar strAlConsumoI     = "`strAlConsumoI'"

local strAlConsumoII     : display %20.1fc AlConsumoII
scalar strAlConsumoII    = "`strAlConsumoII'"

local strAlConsumoIII    : display %20.1fc AlConsumoIII
scalar strAlConsumoIII   = "`strAlConsumoIII'"

local strAlConsumoIV     : display %20.1fc AlConsumoIV
scalar strAlConsumoIV    = "`strAlConsumoIV'"

local strAlConsumoV      : display %20.1fc AlConsumoV
scalar strAlConsumoV     = "`strAlConsumoV'"

local strAlConsumoVI     : display %20.1fc AlConsumoVI
scalar strAlConsumoVI    = "`strAlConsumoVI'"

local strAlConsumoVII    : display %20.1fc AlConsumoVII
scalar strAlConsumoVII   = "`strAlConsumoVII'"

local strAlConsumoVIII   : display %20.1fc AlConsumoVIII
scalar strAlConsumoVIII  = "`strAlConsumoVIII'"

local strAlConsumoIX     : display %20.1fc AlConsumoIX
scalar strAlConsumoIX    = "`strAlConsumoIX'"

local strAlConsumoX      : display %20.1fc AlConsumoX
scalar strAlConsumoX     = "`strAlConsumoX'"

local strAlConsumoNac    : display %20.1fc AlConsumoNac
scalar strAlConsumoNac   = "`strAlConsumoNac'"


// Distribución consumo (formateados con separador de miles)
local strDisAlConsumoI      : display %20.1fc disAlConsumoI
scalar strDisAlConsumoI     = "`strDisAlConsumoI'"

local strDisAlConsumoII     : display %20.1fc disAlConsumoII
scalar strDisAlConsumoII    = "`strDisAlConsumoII'"

local strDisAlConsumoIII    : display %20.1fc disAlConsumoIII
scalar strDisAlConsumoIII   = "`strDisAlConsumoIII'"

local strDisAlConsumoIV     : display %20.1fc disAlConsumoIV
scalar strDisAlConsumoIV    = "`strDisAlConsumoIV'"

local strDisAlConsumoV      : display %20.1fc disAlConsumoV
scalar strDisAlConsumoV     = "`strDisAlConsumoV'"

local strDisAlConsumoVI     : display %20.1fc disAlConsumoVI
scalar strDisAlConsumoVI    = "`strDisAlConsumoVI'"

local strDisAlConsumoVII    : display %20.1fc disAlConsumoVII
scalar strDisAlConsumoVII   = "`strDisAlConsumoVII'"

local strDisAlConsumoVIII   : display %20.1fc disAlConsumoVIII
scalar strDisAlConsumoVIII  = "`strDisAlConsumoVIII'"

local strDisAlConsumoIX     : display %20.1fc disAlConsumoIX
scalar strDisAlConsumoIX    = "`strDisAlConsumoIX'"

local strDisAlConsumoX      : display %20.1fc disAlConsumoX
scalar strDisAlConsumoX     = "`strDisAlConsumoX'"

local strDisAlConsumoNac    : display %20.1fc disAlConsumoNac
scalar strDisAlConsumoNac   = "`strDisAlConsumoNac'"


// Como porcentaje del ingreso bruto consumo (formateados con separador de miles)
local strIncAlConsumoI      : display %20.1fc incAlConsumoI
scalar strIncAlConsumoI     = "`strIncAlConsumoI'"

local strIncAlConsumoII     : display %20.1fc incAlConsumoII
scalar strIncAlConsumoII    = "`strIncAlConsumoII'"

local strIncAlConsumoIII    : display %20.1fc incAlConsumoIII
scalar strIncAlConsumoIII   = "`strIncAlConsumoIII'"

local strIncAlConsumoIV     : display %20.1fc incAlConsumoIV
scalar strIncAlConsumoIV    = "`strIncAlConsumoIV'"

local strIncAlConsumoV      : display %20.1fc incAlConsumoV
scalar strIncAlConsumoV     = "`strIncAlConsumoV'"

local strIncAlConsumoVI     : display %20.1fc incAlConsumoVI
scalar strIncAlConsumoVI    = "`strIncAlConsumoVI'"

local strIncAlConsumoVII    : display %20.1fc incAlConsumoVII
scalar strIncAlConsumoVII   = "`strIncAlConsumoVII'"

local strIncAlConsumoVIII   : display %20.1fc incAlConsumoVIII
scalar strIncAlConsumoVIII  = "`strIncAlConsumoVIII'"

local strIncAlConsumoIX     : display %20.1fc incAlConsumoIX
scalar strIncAlConsumoIX    = "`strIncAlConsumoIX'"

local strIncAlConsumoX      : display %20.1fc incAlConsumoX
scalar strIncAlConsumoX     = "`strIncAlConsumoX'"

local strIncAlConsumoNac    : display %20.1fc incAlConsumoNac
scalar strIncAlConsumoNac   = "`strIncAlConsumoNac'"


//////////////////////////////////////////////////////////////////////////
////////////////////    Esto para Impuestos laborales  ///////////////////
////////////////////    (ISRPF_Sim + ISRAS_Sim + CUOTAS_Sim)  //////////////
//////////////////////////////////////////////////////////////////////////

// Impuestos laborales por hogar al año 
local strAlTrabajoI      : display %20.1fc AlTrabajoI
scalar strAlTrabajoI     = "`strAlTrabajoI'"

local strAlTrabajoII     : display %20.1fc AlTrabajoII
scalar strAlTrabajoII    = "`strAlTrabajoII'"

local strAlTrabajoIII    : display %20.1fc AlTrabajoIII
scalar strAlTrabajoIII   = "`strAlTrabajoIII'"

local strAlTrabajoIV     : display %20.1fc AlTrabajoIV
scalar strAlTrabajoIV    = "`strAlTrabajoIV'"

local strAlTrabajoV      : display %20.1fc AlTrabajoV
scalar strAlTrabajoV     = "`strAlTrabajoV'"

local strAlTrabajoVI     : display %20.1fc AlTrabajoVI
scalar strAlTrabajoVI    = "`strAlTrabajoVI'"

local strAlTrabajoVII    : display %20.1fc AlTrabajoVII
scalar strAlTrabajoVII   = "`strAlTrabajoVII'"

local strAlTrabajoVIII   : display %20.1fc AlTrabajoVIII
scalar strAlTrabajoVIII  = "`strAlTrabajoVIII'"

local strAlTrabajoIX     : display %20.1fc AlTrabajoIX
scalar strAlTrabajoIX    = "`strAlTrabajoIX'"

local strAlTrabajoX      : display %20.1fc AlTrabajoX
scalar strAlTrabajoX     = "`strAlTrabajoX'"

local strAlTrabajoNac    : display %20.1fc AlTrabajoNac
scalar strAlTrabajoNac   = "`strAlTrabajoNac'"


/// Distribución 
local strDisAlTrabajoI      : display %20.1fc disAlTrabajoI
scalar strDisAlTrabajoI     = "`strDisAlTrabajoI'"

local strDisAlTrabajoII     : display %20.1fc disAlTrabajoII
scalar strDisAlTrabajoII    = "`strDisAlTrabajoII'"

local strDisAlTrabajoIII    : display %20.1fc disAlTrabajoIII
scalar strDisAlTrabajoIII   = "`strDisAlTrabajoIII'"

local strDisAlTrabajoIV     : display %20.1fc disAlTrabajoIV
scalar strDisAlTrabajoIV    = "`strDisAlTrabajoIV'"

local strDisAlTrabajoV      : display %20.1fc disAlTrabajoV
scalar strDisAlTrabajoV     = "`strDisAlTrabajoV'"

local strDisAlTrabajoVI     : display %20.1fc disAlTrabajoVI
scalar strDisAlTrabajoVI    = "`strDisAlTrabajoVI'"

local strDisAlTrabajoVII    : display %20.1fc disAlTrabajoVII
scalar strDisAlTrabajoVII   = "`strDisAlTrabajoVII'"

local strDisAlTrabajoVIII   : display %20.1fc disAlTrabajoVIII
scalar strDisAlTrabajoVIII  = "`strDisAlTrabajoVIII'"

local strDisAlTrabajoIX     : display %20.1fc disAlTrabajoIX
scalar strDisAlTrabajoIX    = "`strDisAlTrabajoIX'"

local strDisAlTrabajoX      : display %20.1fc disAlTrabajoX
scalar strDisAlTrabajoX     = "`strDisAlTrabajoX'"

local strDisAlTrabajoNac    : display %20.1fc disAlTrabajoNac
scalar strDisAlTrabajoNac   = "`strDisAlTrabajoNac'"


/// Como porcentaje del ingreso bruto 
local strIncAlTrabajoI      : display %20.1fc incAlTrabajoI
scalar strIncAlTrabajoI     = "`strIncAlTrabajoI'"

local strIncAlTrabajoII     : display %20.1fc incAlTrabajoII
scalar strIncAlTrabajoII    = "`strIncAlTrabajoII'"

local strIncAlTrabajoIII    : display %20.1fc incAlTrabajoIII
scalar strIncAlTrabajoIII   = "`strIncAlTrabajoIII'"

local strIncAlTrabajoIV     : display %20.1fc incAlTrabajoIV
scalar strIncAlTrabajoIV    = "`strIncAlTrabajoIV'"

local strIncAlTrabajoV      : display %20.1fc incAlTrabajoV
scalar strIncAlTrabajoV     = "`strIncAlTrabajoV'"

local strIncAlTrabajoVI     : display %20.1fc incAlTrabajoVI
scalar strIncAlTrabajoVI    = "`strIncAlTrabajoVI'"

local strIncAlTrabajoVII    : display %20.1fc incAlTrabajoVII
scalar strIncAlTrabajoVII   = "`strIncAlTrabajoVII'"

local strIncAlTrabajoVIII   : display %20.1fc incAlTrabajoVIII
scalar strIncAlTrabajoVIII  = "`strIncAlTrabajoVIII'"

local strIncAlTrabajoIX     : display %20.1fc incAlTrabajoIX
scalar strIncAlTrabajoIX    = "`strIncAlTrabajoIX'"

local strIncAlTrabajoX      : display %20.1fc incAlTrabajoX
scalar strIncAlTrabajoX     = "`strIncAlTrabajoX'"

local strIncAlTrabajoNac    : display %20.1fc incAlTrabajoNac
scalar strIncAlTrabajoNac   = "`strIncAlTrabajoNac'"

//////////////////////////////////////////////////////////////////////////
////////////////////    Esto para Impuestos al Capital  //////////////
//////////////////////////////////////////////////////////////////////////

// Impuestos capital por hogar al año 
local strAlCapitalI      : display %20.1fc AlCapitalI
scalar strAlCapitalI     = "`strAlCapitalI'"

local strAlCapitalII     : display %20.1fc AlCapitalII
scalar strAlCapitalII    = "`strAlCapitalII'"

local strAlCapitalIII    : display %20.1fc AlCapitalIII
scalar strAlCapitalIII   = "`strAlCapitalIII'"

local strAlCapitalIV     : display %20.1fc AlCapitalIV
scalar strAlCapitalIV    = "`strAlCapitalIV'"

local strAlCapitalV      : display %20.1fc AlCapitalV
scalar strAlCapitalV     = "`strAlCapitalV'"

local strAlCapitalVI     : display %20.1fc AlCapitalVI
scalar strAlCapitalVI    = "`strAlCapitalVI'"

local strAlCapitalVII    : display %20.1fc AlCapitalVII
scalar strAlCapitalVII   = "`strAlCapitalVII'"

local strAlCapitalVIII   : display %20.1fc AlCapitalVIII
scalar strAlCapitalVIII  = "`strAlCapitalVIII'"

local strAlCapitalIX     : display %20.1fc AlCapitalIX
scalar strAlCapitalIX    = "`strAlCapitalIX'"

local strAlCapitalX      : display %20.1fc AlCapitalX
scalar strAlCapitalX     = "`strAlCapitalX'"

local strAlCapitalNac    : display %20.1fc AlCapitalNac
scalar strAlCapitalNac   = "`strAlCapitalNac'"


// Distribución capital 
local strDisAlCapitalI      : display %20.1fc disAlCapitalI
scalar strDisAlCapitalI     = "`strDisAlCapitalI'"

local strDisAlCapitalII     : display %20.1fc disAlCapitalII
scalar strDisAlCapitalII    = "`strDisAlCapitalII'"

local strDisAlCapitalIII    : display %20.1fc disAlCapitalIII
scalar strDisAlCapitalIII   = "`strDisAlCapitalIII'"

local strDisAlCapitalIV     : display %20.1fc disAlCapitalIV
scalar strDisAlCapitalIV    = "`strDisAlCapitalIV'"

local strDisAlCapitalV      : display %20.1fc disAlCapitalV
scalar strDisAlCapitalV     = "`strDisAlCapitalV'"

local strDisAlCapitalVI     : display %20.1fc disAlCapitalVI
scalar strDisAlCapitalVI    = "`strDisAlCapitalVI'"

local strDisAlCapitalVII    : display %20.1fc disAlCapitalVII
scalar strDisAlCapitalVII   = "`strDisAlCapitalVII'"

local strDisAlCapitalVIII   : display %20.1fc disAlCapitalVIII
scalar strDisAlCapitalVIII  = "`strDisAlCapitalVIII'"

local strDisAlCapitalIX     : display %20.1fc disAlCapitalIX
scalar strDisAlCapitalIX    = "`strDisAlCapitalIX'"

local strDisAlCapitalX      : display %20.1fc disAlCapitalX
scalar strDisAlCapitalX     = "`strDisAlCapitalX'"

local strDisAlCapitalNac    : display %20.1fc disAlCapitalNac
scalar strDisAlCapitalNac   = "`strDisAlCapitalNac'"


// Como porcentaje del ingreso bruto capital 
local strIncAlCapitalI      : display %20.1fc incAlCapitalI
scalar strIncAlCapitalI     = "`strIncAlCapitalI'"

local strIncAlCapitalII     : display %20.1fc incAlCapitalII
scalar strIncAlCapitalII    = "`strIncAlCapitalII'"

local strIncAlCapitalIII    : display %20.1fc incAlCapitalIII
scalar strIncAlCapitalIII   = "`strIncAlCapitalIII'"

local strIncAlCapitalIV     : display %20.1fc incAlCapitalIV
scalar strIncAlCapitalIV    = "`strIncAlCapitalIV'"

local strIncAlCapitalV      : display %20.1fc incAlCapitalV
scalar strIncAlCapitalV     = "`strIncAlCapitalV'"

local strIncAlCapitalVI     : display %20.1fc incAlCapitalVI
scalar strIncAlCapitalVI    = "`strIncAlCapitalVI'"

local strIncAlCapitalVII    : display %20.1fc incAlCapitalVII
scalar strIncAlCapitalVII   = "`strIncAlCapitalVII'"

local strIncAlCapitalVIII   : display %20.1fc incAlCapitalVIII
scalar strIncAlCapitalVIII  = "`strIncAlCapitalVIII'"

local strIncAlCapitalIX     : display %20.1fc incAlCapitalIX
scalar strIncAlCapitalIX    = "`strIncAlCapitalIX'"

local strIncAlCapitalX      : display %20.1fc incAlCapitalX
scalar strIncAlCapitalX     = "`strIncAlCapitalX'"

local strIncAlCapitalNac    : display %20.1fc incAlCapitalNac
scalar strIncAlCapitalNac   = "`strIncAlCapitalNac'"


/////////////////////////////////////////////////////
// PARTICIPACIÓN DE LOS INGRESOS (BASE 2015)
/////////////////////////////////////////////////////

// Ejecuta LIF para generar los escalares del año 2015
LIF if divPE!=1, by(divLIF) anio(2015) rows(2) min(0) nograph

// Calcular el total de ingresos incluyendo los nuevos rubros
scalar totalIngresosIncial = Impuestos + Cuotas + Contrib_de_mejora + Derechos + Productos + Aprovechamientos + Ventas + Participaciones + Transferencias

// Participación total (siempre 100%)
scalar strtotalIngresosIncialPart = "100.0"

// Calcular participaciones y convertir a string
scalar strParTotImpues       = string((Impuestos / totalIngresosIncial)*100, "%20.1fc")
scalar strParCuotas          = string((Cuotas / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotContrib      = string((Contrib_de_mejora / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotDerechos     = string((Derechos / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotProductos    = string((Productos / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotAprovecha    = string((Aprovechamientos / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotVentas       = string((Ventas / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotParticipa    = string((Participaciones / totalIngresosIncial)*100, "%20.1fc")
scalar strParTotTransf       = string((Transferencias / totalIngresosIncial)*100, "%20.1fc")



/////////////////////////////////////////////////////
// PARTICIPACIÓN DE LOS INGRESOS (BASE 2026)
/////////////////////////////////////////////////////

// Ejecuta LIF para generar los escalares del año 2026
LIF if divPE!=1, by(divLIF) desde(2015) anio(2026) rows(2) min(0) nograph

// Calcular el total de ingresos incluyendo los nuevos rubros
scalar totalIngresosFinal = Impuestos + Cuotas + Contrib_de_mejora + Derechos + Productos + Aprovechamientos + Ventas + Participaciones + Transferencias

// Participación total (siempre 100%)
scalar strtotalIngresosFinalPart = "100.0"

// Calcular participaciones y convertir a string
scalar strParTotImpuesFinal     = string((Impuestos / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotCuotasFinal     = string((Cuotas / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotContribFinal    = string((Contrib_de_mejora / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotDerechosFinal   = string((Derechos / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotProductosFinal  = string((Productos / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotAprovechaFinal  = string((Aprovechamientos / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotVentasFinal     = string((Ventas / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotParticipaFinal  = string((Participaciones / totalIngresosFinal)*100, "%20.1fc")
scalar strParTotTransfFinal     = string((Transferencias / totalIngresosFinal)*100, "%20.1fc")


// Se llaman al latex de la siguiente forma:

// \strParTotImpuesing
// \strParCuotasing
// \strParTotContring
// \strParTotDerechosing
// \strParTotProductosing
// \strParTotAprovechaing
// \strParTotVentas
// \strParTotParticipa
// \strParTotTransf
// \strtotalIngresosIncialParting


// \strParTotImpuesFinaling
// \strParTotCuotasFinaling
// \strParTotContribFinaling
// \strParTotDerechosFinaling
// \strParTotProductosFinaling
// \strParTotAprovechaFinaling
// \strParTotVentasFinal
// \strParTotParticipaFinal
// \strParTotTransfFinal
// \strtotalIngresosIncialParting



/// La base para 2015 ////
LIF, by(divSIM) desde(2015) rows(2) min(0) nograph // base 

/// La base para TasasEfectivas ////
TasasEfectivas, nograph //base 


/////////////////////////////////////////////////////
// Programación de las macro
/////////////////////////////////////////////////////


// Sociedades e ISFLSH



// ISR (personas morales)



/////////////////////////////////////////////////////
// Impuestos al Consumo
/////////////////////////////////////////////////////


// Impuestos (%) y Tasa efectiva (%)

*Consumo hogares e ISFLSH (IVA) como %PIB
scalar  ConHogIVAPIB= string(ConHogPIB, "%7.3fc")

*Compra de Vehículos (ISAN) como %PIB
scalar  ConHogISANPIB= string(VehiPIB, "%7.3fc")

*Consumo de alcohol, tabaco y juegos (IEPS no petrolero/salud) como %PIB
scalar  ConHogIEPSNOPIB= string(TabaPIB + BebAPIB + Recre7132PIB, "%7.3fc")

*Consumo privado minería (IEPS petrolero) como %PIB
scalar  ConHogIEPSPPIB= string(ConsPriv21PIB, "%7.3fc")

*Consumo hogares e ISFLSH (IGI) como %PIB
scalar  ConHogIGIPIB= string(ConHogPIB, "%7.3fc")


*IVA
scalar IVATasaPIB = string(IVAPIB, "%7.3fc")
scalar IVATasaEfec = string(IVAPIB, "%7.3fc")

* IEPS (IEPS no petrolero + petrolero)
scalar IEPSPTasaPIB = string(IEPSPPIB, "%7.3fc")
scalar IEPSNPTasaPIB = string(IEPSNPPIB, "%7.3fc")

scalar IEPSNPTasaEfec = string(IEPSNPPor, "%7.3fc")
scalar IEPSPTasaEfec = string(IEPSPPor, "%7.3fc")

*ISAN
scalar ISANTasaPIB= string(ISANPIB, "%7.3fc") 
scalar ISANTasaEfec = string(ISANPor, "%7.3fc")

*Importaciones

scalar IGITasaPIB= string(IMPORTPIB, "%7.3fc") 
scalar IGITasaEfec = string(IMPORTPor, "%7.3fc")

*Consumo hogares e ISFLSH

scalar ConsHogToTPIB= string(ingconsumoPIB , "%7.3fc")
scalar ConsHogTasaEfec= string(ingconsumoPor , "%7.3fc")




/////////////////////////////////////////////////////////////////////////
////////////    Esto para Incluir las Renuncias Recaudatorias  //////////
/////////////////////////////////////////////////////////////////////////

// Definimos los scalares de acuerdo con el Anexo I del Reporte de Renuncias

// =========================
// ISR de empresas
// =========================
* Individual monto
scalar ISRERenunDedu          = 40726
scalar ISRERenunExenc         = 16149
scalar ISRERenunRegimEsp      = 18808
scalar ISRERenunDiferimentos  = 33856
scalar ISRERenunFacilAd       = 4546
scalar ISRERenunSubEmpl       = 45135

* Individual PIB
scalar ISRERenunDeduPIB           = 0.1068
scalar ISRERenunExencPIB          = 0.0424
scalar ISRERenunRegimEspPIB       = 0.0493
scalar ISRERenunDiferimentosPIB   = 0.0888
scalar ISRERenunFacilAdPIB        = 0.0119
scalar ISRERenunSubEmplPIB        = 0.1184

// =========================
// ISR de Personas Físicas
// =========================
* Individual monto
scalar ISRPFRenunDedu         = 48182
scalar ISRPFRenunExenc        = 366377
scalar ISRPFRenunRegimEsp     = 4864
scalar ISRPFRenunDiferimentos = 0

* Individual PIB
scalar ISRPFRenunDeduPIB          = 0.1264
scalar ISRPFRenunExencPIB         = 0.9607
scalar ISRPFRenunRegimEspPIB      = 0.0128
scalar ISRPFRenunDiferimentosPIB  = 0

// =========================
// IVA
// =========================
* Individual monto
scalar IVARenunExenc       = 95900
scalar IVARenunTasaRed     = 598089

* Individual PIB
scalar IVARenunExencPIB    = 0.2515
scalar IVARenunTasaRedPIB  = 1.5685

// =========================
// Impuestos Especiales
// =========================
* Individual monto
scalar IMPERenunExenc      = 18863
scalar IMPERenunTasaRed    = 1528

* Individual PIB
scalar IMPERenunExencPIB   = 0.0456
scalar IMPERenunTasaRedPIB = 0.0040

// =========================
// Estímulos Fiscales
// =========================
scalar ESTIRenunEstiFisc       = 383690
scalar ESTIRenunEstiFiscPIB    = 1.0060

// =========================
// Totales
// =========================
scalar totalRenunISRE       = ISRERenunDedu + ISRERenunExenc + ISRERenunRegimEsp + ISRERenunDiferimentos + ISRERenunFacilAd + ISRERenunSubEmpl
scalar totalRenunISREPIB    = ISRERenunDeduPIB + ISRERenunExencPIB + ISRERenunRegimEspPIB + ISRERenunDiferimentosPIB + ISRERenunFacilAdPIB + ISRERenunSubEmplPIB

scalar totalRenunISRPF      = ISRPFRenunDedu + ISRPFRenunExenc + ISRPFRenunRegimEsp + ISRPFRenunDiferimentos
scalar totalRenunISRPFPIB   = ISRPFRenunDeduPIB + ISRPFRenunExencPIB + ISRPFRenunRegimEspPIB + ISRPFRenunDiferimentosPIB

scalar totalRenunISRTOT     = totalRenunISRE + totalRenunISRPF
scalar totalRenunISRTOTPIB  = totalRenunISREPIB + totalRenunISRPFPIB

scalar totalRenunIVA        = IVARenunExenc + IVARenunTasaRed
scalar totalRenunIVAPIB     = IVARenunExencPIB + IVARenunTasaRedPIB

scalar totalRenunIMPE       = IMPERenunExenc + IMPERenunTasaRed
scalar totalRenunIMPEPIB    = IMPERenunExencPIB + IMPERenunTasaRedPIB

scalar totalRenunciasGlobal 	=totalRenunISRTOT + totalRenunIVA + totalRenunIMPE + ESTIRenunEstiFisc

scalar totalRenunciasGlobalPIB	=totalRenunISRTOTPIB + totalRenunIVAPIB + totalRenunIMPEPIB + ESTIRenunEstiFiscPIB



// ---------------------------------------------------------------------
///// Formato de strings para LaTeX
// ---------------------------------------------------------------------

// ISR Empresas
scalar ISRERenunDeduSTR            = string(ISRERenunDedu, "%20.2fc")
scalar ISRERenunExencSTR           = string(ISRERenunExenc, "%20.2fc")
scalar ISRERenunRegimEspSTR        = string(ISRERenunRegimEsp, "%20.2fc")
scalar ISRERenunDiferimentosSTR    = string(ISRERenunDiferimentos, "%20.2fc")
scalar ISRERenunFacilAdSTR         = string(ISRERenunFacilAd, "%20.2fc")
scalar ISRERenunSubEmplSTR         = string(ISRERenunSubEmpl, "%20.2fc")

scalar ISRERenunDeduPIBSTR         = string(ISRERenunDeduPIB, "%7.3fc")
scalar ISRERenunExencPIBSTR        = string(ISRERenunExencPIB, "%7.3fc")
scalar ISRERenunRegimEspPIBSTR     = string(ISRERenunRegimEspPIB, "%7.3fc")
scalar ISRERenunDiferimentosPIBSTR = string(ISRERenunDiferimentosPIB, "%7.3fc")
scalar ISRERenunFacilAdPIBSTR      = string(ISRERenunFacilAdPIB, "%7.3fc")
scalar ISRERenunSubEmplPIBSTR      = string(ISRERenunSubEmplPIB, "%7.3fc")

// ISR Personas Físicas
scalar ISRPFRenunDeduSTR           = string(ISRPFRenunDedu, "%20.2fc")
scalar ISRPFRenunExencSTR          = string(ISRPFRenunExenc, "%20.2fc")
scalar ISRPFRenunRegimEspSTR       = string(ISRPFRenunRegimEsp, "%20.2fc")
scalar ISRPFRenunDiferimentosSTR   = string(ISRPFRenunDiferimentos, "%20.2fc")

scalar ISRPFRenunDeduPIBSTR        = string(ISRPFRenunDeduPIB, "%7.3fc")
scalar ISRPFRenunExencPIBSTR       = string(ISRPFRenunExencPIB, "%7.3fc")
scalar ISRPFRenunRegimEspPIBSTR    = string(ISRPFRenunRegimEspPIB, "%7.3fc")
scalar ISRPFRenunDiferimentosPIBSTR= string(ISRPFRenunDiferimentosPIB, "%7.3fc")

// IVA
scalar IVARenunExencSTR            = string(IVARenunExenc, "%20.2fc")
scalar IVARenunTasaRedSTR          = string(IVARenunTasaRed, "%20.2fc")

scalar IVARenunExencPIBSTR         = string(IVARenunExencPIB, "%7.3fc")
scalar IVARenunTasaRedPIBSTR       = string(IVARenunTasaRedPIB, "%7.3fc")

// Impuestos Especiales
scalar IMPERenunExencSTR           = string(IMPERenunExenc, "%20.2fc")
scalar IMPERenunTasaRedSTR         = string(IMPERenunTasaRed, "%20.2fc")

scalar IMPERenunExencPIBSTR        = string(IMPERenunExencPIB, "%7.3fc")
scalar IMPERenunTasaRedPIBSTR      = string(IMPERenunTasaRedPIB, "%7.3fc")

// Estímulos Fiscales
scalar ESTIRenunEstiFiscSTR        = string(ESTIRenunEstiFisc, "%20.2fc")
scalar ESTIRenunEstiFiscPIBSTR     = string(ESTIRenunEstiFiscPIB, "%7.3fc")

// Totales
scalar totalRenunISRESTR           = string(totalRenunISRE, "%20.2fc")
scalar totalRenunISREPIBSTR        = string(totalRenunISREPIB, "%7.3fc")

scalar totalRenunISRPFSTR          = string(totalRenunISRPF, "%20.2fc")
scalar totalRenunISRPFPIBSTR       = string(totalRenunISRPFPIB, "%7.3fc")

scalar totalRenunISRTOTSTR         = string(totalRenunISRTOT, "%20.2fc")
scalar totalRenunISRTOTPIBSTR      = string(totalRenunISRTOTPIB, "%7.3fc")

scalar totalRenunIVASTR            = string(totalRenunIVA, "%20.2fc")
scalar totalRenunIVAPIBSTR         = string(totalRenunIVAPIB, "%7.3fc")

scalar totalRenunIMPESTR           = string(totalRenunIMPE, "%20.2fc")
scalar totalRenunIMPEPIBSTR        = string(totalRenunIMPEPIB, "%7.3fc")


scalar STRtotalRenunciasGlobal		= string(totalRenunciasGlobal, "%20.2fc")
scalar STRtotalRenunciasGlobalPIB	= string(totalRenunciasGlobalPIB, "%7.3fc")


/////////////////////////////////////////////////////
// EXPORTAR A LaTeX
/////////////////////////////////////////////////////
scalarlatex, log(ingresos) alt(ing)




/////////////////////////////////////////////////////
// Gráfica de Histórico de Renuncias Recaudatorias
/////////////////////////////////////////////////////

clear
input str4 anios double(isre isrf iva ie est_fis)
"2015" 0.4573 1.0360 1.2773 0.0383 0.2188
"2016" 0.5144 1.0032 1.4442 0.0431 0.4843
"2017" 0.5563 1.0500 1.5173 0.0476 0.7429
"2018" 0.5179 0.9669 1.3608 0.0417 0.8087
"2019" 0.4946 0.9511 1.4318 0.0400 0.8431
"2020" 0.5239 1.1070 1.3939 0.0374 0.6236
"2021" 0.4767 1.1524 1.4612 0.0284 0.9593
"2022" 0.4519 0.8519 1.8657 0.0262 1.6469
"2023" 0.4518 0.8847 1.8657 0.0262 1.4353
"2024" 0.4099 0.9290 1.8220 0.0368 0.9981
"2025" 0.4176 1.0716 1.8200 0.0496 1.0352
"2026" 0.4176 1.0999 1.8200 0.0496 1.0060
end


//	Gráfica del Histórico de Renuncias Recaudatorias 

graph hbar (sum) isre isrf iva ie est_fis, over(anios) stack asyvars ///
title("{bf:Renuncias recaudatorias (Gasto fiscal o tributario)}") ///
blabel(bar, position(center) format(%16.2fc) size(small) color(white)) ///
legend(label(1 "ISRE") label(2 "ISRF") ///
       label(3 "IVA") label(4 "Impuestos Especiales (IEPS e ISAN)") ///
       label(5 "Estímulos Fiscales")) ///
note("Nota: Unidades: % del PIB", size(small))

graph export "C:/Users/Admin/CIEP Dropbox/TextbookCIEP/images/Renuncias.png", as(png) replace







