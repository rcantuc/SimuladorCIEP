///// scalares necesarios para el ejercicio
//	versión numérica:

clear all
macro drop _all
scalar anioenigh = 2024

// Directorio ////

if "`c(username)'" == "ricardo" {
	global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
**# Bookmark #1


if "`c(username)'" == "jhon9" {
	global export "C:\Users\jhon9\CIEP Dropbox\TextbookCIEP\images"
}


if "`c(username)'" == "Admin" {
	global export "C:\Users\Admin\CIEP Dropbox\TextbookCIEP\images"
}


LIF if divPE!=1, by(divLIF) desde(2013) anio(2026) rows(2) min(0) nograph // base

** Escenarios de las variables:
scalar crecimientoCGPE_val= 2.3
scalar escecrecimientoAltern_Optim= crecimientoCGPE_val+1.0
scalar escecrecimientoAltern_Pesim= crecimientoCGPE_val-1.0

** Datos de las partidas (que también es el escenario base)

scalar ImpuestosActual_val = Impuestos/1000000
scalar CuotasActual_val = Cuotas/1000000
scalar ContribActual_val = Contrib_de_mejora/1000000
scalar DerechosActual_val = Derechos/1000000
scalar ProductosActual_val = Productos/1000000
scalar AprovechamientosActual_val = Aprovechamientos/1000000
scalar VentasActual_val= Ventas/1000000
scalar ParticipacionesActual_val= Participaciones/1000000
scalar TransferenciasActual_val= Transferencias/1000000
scalar IngresosTotalesActual_val = Ingresos_sin_deuda/1000000



** elasticidades a tomar en cuenta

scalar ElasImpuestos = EImpuestos
scalar ElasCuotas = ECuotas
scalar ElasContrib = EContrib_de_mejora
scalar ElasDerechos = EDerechos
scalar ElasProductos = EProductos
scalar ElasAprove = EAprovechamientos
scalar ElasPartici = EParticipaciones
scalar ElasTrans = ETransferencias
scalar ElasVentas = EVentas
scalar ElasIngresosTot = 1.771

**	Revisa las elasticidades por si alguna tiene un valor de missing "." y lo reemplaza por "0"

local elas_list ElasImpuestos ElasCuotas ElasContrib ElasDerechos ElasProductos ///
                ElasAprove ElasPartici ElasTrans ElasVentas

foreach e of local elas_list {
    if missing(`e') {
        scalar `e' = 0
    }
}

**	Calculando los escenarios 

*** ESCENARIO OPTIMISTA (crecimiento + 1)
scalar Impuestos_Optim      = ImpuestosActual_val        * (1 + ElasImpuestos  * escecrecimientoAltern_Optim/100)
scalar Cuotas_Optim         = CuotasActual_val           * (1 + ElasCuotas     * escecrecimientoAltern_Optim/100)
scalar Contrib_Optim        = ContribActual_val          * (1 + ElasContrib    * escecrecimientoAltern_Optim/100)
scalar Derechos_Optim       = DerechosActual_val         * (1 + ElasDerechos   * escecrecimientoAltern_Optim/100)
scalar Productos_Optim      = ProductosActual_val        * (1 + ElasProductos  * escecrecimientoAltern_Optim/100)
scalar Aprove_Optim         = AprovechamientosActual_val * (1 + ElasAprove     * escecrecimientoAltern_Optim/100)
scalar Ventas_Optim         = VentasActual_val           * (1 + ElasVentas     * escecrecimientoAltern_Optim/100)
scalar Participaciones_Optim= ParticipacionesActual_val  * (1 + ElasPartici    * escecrecimientoAltern_Optim/100)
scalar Transfer_Optim       = TransferenciasActual_val   * (1 + ElasTrans      * escecrecimientoAltern_Optim/100)
scalar Ingresos_Optim    = IngresosTotalesActual_val  * (1 + ElasIngresosTot* escecrecimientoAltern_Optim/100)


*scalar Ingresos_Optim = Impuestos_Optim + Cuotas_Optim + Contrib_Optim + Derechos_Optim + ///
                        Productos_Optim + Aprove_Optim + Ventas_Optim + ///
                        Participaciones_Optim + Transfer_Optim


*scalar Ingresos_Optim = Impuestos_Optim + Cuotas_Optim + ///
                        Productos_Optim  + Ventas_Optim + ///
                        Participaciones_Optim + Transfer_Optim		
							
						
*** ESCENARIO PESIMISTA (crecimiento – 1)

*scalar Impuestos_Pesim      = ImpuestosActual_val        * (1 + ElasImpuestos  * escecrecimientoAltern_Pesim/100)
*scalar Cuotas_Pesim         = CuotasActual_val           * (1 + ElasCuotas     * escecrecimientoAltern_Pesim/100)
*scalar Contrib_Pesim        = ContribActual_val          * (1 + ElasContrib    * escecrecimientoAltern_Pesim/100)
*scalar Derechos_Pesim       = DerechosActual_val         * (1 + ElasDerechos   * escecrecimientoAltern_Pesim/100)
*scalar Productos_Pesim      = ProductosActual_val        * (1 + ElasProductos  * escecrecimientoAltern_Pesim/100)
*scalar Aprove_Pesim         = AprovechamientosActual_val * (1 + ElasAprove     * escecrecimientoAltern_Pesim/100)
*scalar Ventas_Pesim         = VentasActual_val           * (1 + ElasVentas     * escecrecimientoAltern_Pesim/100)
*scalar Participaciones_Pesim= ParticipacionesActual_val  * (1 + ElasPartici    * escecrecimientoAltern_Pesim/100)
*scalar Transfer_Pesim       = TransferenciasActual_val   * (1 + ElasTrans      * escecrecimientoAltern_Pesim/100)


scalar Impuestos_Pesim      = ImpuestosActual_val       - Impuestos_Optim
scalar Cuotas_Pesim         = CuotasActual_val          - Cuotas_Optim
scalar Contrib_Pesim        = ContribActual_val         - Contrib_Optim
scalar Derechos_Pesim       = DerechosActual_val        - Derechos_Optim
scalar Productos_Pesim      = ProductosActual_val       - Productos_Optim
scalar Aprove_Pesim         = AprovechamientosActual_val- Aprove_Optim 
scalar Ventas_Pesim         = VentasActual_val          - Ventas_Optim
scalar Participaciones_Pesim= ParticipacionesActual_val - Participaciones_Optim
scalar Transfer_Pesim       = TransferenciasActual_val  - Transfer_Optim

*scalar Ingresos_Pesim = Impuestos_Pesim + Cuotas_Pesim + Contrib_Pesim + Derechos_Pesim + ///
                        Productos_Pesim + Aprove_Pesim + Ventas_Pesim + ///
                        Participaciones_Pesim + Transfer_Pesim						
						

*scalar Ingresos_Pesim = Impuestos_Pesim + Cuotas_Pesim + ///
                        Productos_Pesim  + Ventas_Pesim + ///
                        Participaciones_Pesim + Transfer_Pesim		
						
*scalar Ingresos_Pesim    = IngresosTotalesActual_val  * (1 + ElasIngresosTot* escecrecimientoAltern_Pesim/100)

scalar Ingresos_Pesim    = IngresosTotalesActual_val - Ingresos_Optim
					
***************************************************
	*     Strings a llamar en el Latex    *
***************************************************
						

*** Del escenario base (se tiene que borrar esta parte porque ya esta en el código principal, o bien, puede servir de referencia para identificar donde poner los scalares)

scalar ImpuestosActual = string(ImpuestosActual_val, "%20.1fc")
scalar CuotasActual = string(CuotasActual_val, "%20.1fc")
scalar ContribActual = string(ContribActual_val, "%20.1fc")
scalar DerechosActual = string(DerechosActual_val, "%20.1fc")
scalar ProductosActual = string(ProductosActual_val, "%20.1fc")
scalar AprovechamientosActual = string(AprovechamientosActual_val, "%20.1fc")
scalar VentasActual = string(VentasActual_val, "%20.1fc")
scalar ParticipacionesActual= string(ParticipacionesActual_val, "%20.1fc")
scalar TransferenciasActual= string(TransferenciasActual_val, "%20.1fc")
scalar IngresosTotalesActual = string(IngresosTotalesActual_val, "%20.1fc")

***	Del escenario optimista

scalar ImpuestosOptimSTR = string(Impuestos_Optim, "%20.1fc")
scalar CuotasOptimSTR = string(Cuotas_Optim, "%20.1fc")
scalar ContribOptimSTR = string(Contrib_Optim, "%20.1fc")
scalar DerechosOptimSTR = string(Derechos_Optim, "%20.1fc")
scalar ProductosOptimSTR = string(Productos_Optim, "%20.1fc")
scalar AprovechamientosOptimSTR = string(Aprove_Optim, "%20.1fc")
scalar VentasOptimSTR = string(Ventas_Optim, "%20.1fc")
scalar ParticipacionesOptimSTR= string(Participaciones_Optim, "%20.1fc")
scalar TransferenciasOptimSTR= string(Transfer_Optim, "%20.1fc")
scalar IngresosTotalesOptimSTR = string(Ingresos_Optim, "%20.1fc")


***	Del escenario pesimista

scalar ImpuestosPesiSTR = string(Impuestos_Pesim, "%20.1fc")
scalar CuotasPesiSTR = string(Cuotas_Pesim, "%20.1fc")
scalar ContribPesiSTR = string(Contrib_Pesim, "%20.1fc")
scalar DerechosPesiSTR = string(Derechos_Pesim, "%20.1fc")
scalar ProductosPesiSTR = string(Productos_Pesim, "%20.1fc")
scalar AprovechamientosPesiSTR = string(Aprove_Pesim, "%20.1fc")
scalar VentasPesiSTR = string(Ventas_Pesim, "%20.1fc")
scalar ParticipacionesPesiSTR= string(Participaciones_Pesim, "%20.1fc")
scalar TransferenciasPesiSTR= string(Transfer_Pesim, "%20.1fc")
scalar IngresosTotalesPesiSTR = string(Ingresos_Pesim, "%20.1fc")
scalar crecimientoCGPESTR= string(crecimientoCGPE_val, "%20.1fc")
/////////////////////////////////////////////////////
// EXPORTAR A LaTeX
/////////////////////////////////////////////////////
scalarlatex, log(ingresos) alt(anex)



