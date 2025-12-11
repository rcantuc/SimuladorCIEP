quietly log on output

noisily di in w "CRECPIB: ["  ///
	%8.1f $pib2025 ", " ///
	%8.1f $pib2026 ", " ///
	%8.1f $pib2027 ", " ///
	%8.1f $pib2028 ", " ///
	%8.1f $pib2029 ", " ///
	%8.1f $pib2030 ", " ///
	%8.1f $pib2031 ///
"]"

noisily di in w "CRECDEF: ["  ///
	%8.1f $def2025 ", " ///
	%8.1f $def2026 ", " ///
	%8.1f $def2027 ", " ///
	%8.1f $def2028 ", " ///
	%8.1f $def2029 ", " ///
	%8.1f $def2030 ", " ///
	%8.1f $def2031 ///
"]"

noisily di in w "DEUDAPARAM: [" ///
	%8.3f scalar(tasaEfectiva) /// Tasa de interés efectiva
"]"

noisily di in w "INGRESOS: " in w "["  ///
	%8.3f scalar(ISRASPIB) "," /// ISR (salarios) - 0
	%8.3f scalar(ISRPFPIB) "," /// ISR (físicas) - 1
	%8.3f scalar(CUOTASPIB) "," /// Cuotas IMSS - 2
	%8.3f scalar(YlImpPIB) "," /// Total Impuestos laborales - 3
	%8.3f scalar(ISRPMPIB) "," /// ISR (morales) - 4
	%8.3f scalar(OTROSKPIB) "," /// Productos, derechos y aprovechamientos - 5
	%8.3f scalar(IngKPrivadoPIB) "," /// Total Impuestos al capital - 6
	%8.3f scalar(IVAPIB) "," /// IVA - 7
	%8.3f scalar(ISANPIB) "," /// ISAN - 8
	%8.3f scalar(IEPSNPPIB) "," /// IEPS (no petrolero)- 9
	%8.3f scalar(IEPSPPIB) "," /// IEPS (petrolero) - 10
	%8.3f scalar(IMPORTPIB) "," /// Importaciones - 11
	%8.3f scalar(ingconsumoPIB) "," /// Total Impuestos al consumo - 12
	%8.3f scalar(IMSSPIB) "," /// IMSS - 13
	%8.3f scalar(ISSSTEPIB) "," /// ISSSTE - 14
	%8.3f scalar(FMPPIB) "," /// FMP - 15
	%8.3f scalar(PEMEXPIB) "," /// Pemex - 16
	%8.3f scalar(CFEPIB) "," /// CFE - 17
	%8.3f scalar(IngKPublicosTotPIB) "," /// Total Organismos y Empresas - 18
	%8.3f real(YlImpPIB)+real(ImpKPrivadoPIB)+real(ingconsumoPIB)+real(ImpKPublicosPIB) /// Total INGRESOS - 19
"]"


noisily di in w "INGRESOSTEF: " in w "["  ///
	%8.1f (scalar(ISRASTE)) "," /// ISR (salarios) - 0
	%8.1f (scalar(ISRPFTE)) "," /// ISR (físicas) - 1
	%8.1f (scalar(CUOTASTE)) "," /// Cuotas IMSS - 2
	%8.1f (scalar(YlImpTE)) "," /// Total Impuestos laborales - 3
	%8.1f (scalar(ISRPMTE)) "," /// ISR (morales) - 4
	%8.1f (scalar(OTROSKTE)) "," /// Productos, derechos y aprovechamientos - 5
	%8.1f (scalar(IngKPrivadoTotTE)) "," /// Total Impuestos al capital - 6
	%8.1f (scalar(IVATE)) "," /// IVA - 7
	%8.1f (scalar(ISANTE)) "," /// ISAN - 8
	%8.1f (scalar(IEPSNPTE)) "," /// IEPS (no petrolero) - 9
	%8.1f (scalar(IEPSPTE)) "," /// IEPS (petrolero) - 10
	%8.1f (scalar(IMPORTTE)) "," /// Importaciones - 11
	%8.1f (scalar(ingconsumoTE)) "," /// Total Impuestos al consumo - 12
	%8.1f (scalar(IMSSTE)) "," /// IMSS - 13
	%8.1f (scalar(ISSSTETE)) "," /// ISSSTE - 14
	%8.1f (scalar(FMPTE)) "," /// FMP - 15
	%8.1f (scalar(PEMEXTE)) "," /// Pemex - 16
	%8.1f (scalar(CFEPIB)) "," /// CFE - 17
	%8.1f (scalar(IngKPublicosTotTE)) /// Total Organismos y Empresas - 18
"]"

noisily di in w "GASTOS: ["  ///
	%8.3f iniciaAPIB "," /// Educación inicial 0
	%8.3f basicaPIB "," /// Educación básica 1
	%8.3f medsupPIB "," /// Educación media superior 2
	%8.3f superiPIB "," /// Educación superior 3
	%8.3f posgraPIB "," /// Educación Posgrado 4
	%8.3f eduaduPIB "," /// Educación para adultos 5
	%8.3f otrosePIB "," /// Otros gastos educativos 6
	%8.3f inverePIB "," /// Inversión educativa 7
	%8.3f culturPIB "," /// Cultura 8
	%8.3f investPIB "," /// Inversión en ciencia y tecnología 9
	%8.3f EducacPIB "," /// Total Educación 10
	%8.3f ssaPIB "," /// Secretaría de Salud 11
	%8.3f imssbienPIB "," /// IMSS-Bienestar 12
	%8.3f imssPIB "," /// IMSS 13
	%8.3f issstePIB "," /// ISSSTE 14
	%8.3f pemexPIB "," /// Pemex 15
	%8.3f issfamPIB "," /// ISSFAM 16
	%8.3f inversPIB "," /// Inversión en salud 17
	%8.3f saludPIB "," /// Total Salud 18
	%8.3f pamPIB "," /// Pensión Bienestar 19
	%8.3f penimssPIB "," /// Pensión IMSS 20
	%8.3f penisssPIB "," /// Pensión ISSSTE 21
	%8.3f penpemePIB "," /// Pensión Pemex 22
	%8.3f penotroPIB "," /// Pensión CFE, LFC, ISSFAM, Otros 23
	%8.3f pensionPIB "," /// Total Pensiones 24
	%8.3f gascfePIB "," /// Gasto en CFE 25
	%8.3f gaspemexPIB "," /// Gasto en Pemex 26
	%8.3f gassenerPIB "," /// Gasto en SENER 27
	%8.3f gasinverfPIB "," /// Gasto en Inversión (energía) 28
	%8.3f gascosdeuePIB "," /// Gasto en Costo de la deuda (energía) 29
	%8.3f gasenergiaPIB "," /// Total Energía 30
	%8.3f gasinfraPIB "," /// Gasto en Inversión 31
	%8.3f gasotrosPIB "," /// Otros gastos 32
	%8.3f gasfederPIB "," /// Participaciones y aportaciones 33
	%8.3f gascostoPIB "," /// Gasto en Costo de la deuda 34
	%8.3f otrosgasPIB "," /// Total Otros gastos 35
	%8.3f IngBasPIB "," /// Ingreso Básico 36
	%8.3f gasmadresPIB "," /// Apoyo a madres trabajadoras 37
	%8.3f gascuidadosPIB "," /// Gasto en cuidados 38
	%8.3f transfPIB "," /// Total Transferencias 39
	%8.3f real(EducacPIB)+real(saludPIB)+real(pensionPIB)+real(gasenergiaPIB)+real(otrosgasPIB)+real(transfPIB) /// Total GASTO 40
"]"

noisily di in w "GASTOSPC: ["  ///
	%8.0f real(subinstr(iniciaAPC,",","",.)) "," /// Educación inicial 0
	%8.0f real(subinstr(basicaPC,",","",.)) "," /// Educación básica 1
	%8.0f real(subinstr(medsupPC,",","",.)) "," /// Educación media superior 2
	%8.0f real(subinstr(superiPC,",","",.)) "," /// Educación superior 3
	%8.0f real(subinstr(posgraPC,",","",.)) "," /// Educación Posgrado 4
	%8.0f real(subinstr(eduaduPC,",","",.)) "," /// Educación para adultos 5
	%8.0f real(subinstr(otrosePC,",","",.)) "," /// Otros gastos educativos 6
	%8.0f real(subinstr(inverePC,",","",.)) "," /// Inversión educativa 7
	%8.0f real(subinstr(culturPC,",","",.)) "," /// Cultura 8
	%8.0f real(subinstr(investPC,",","",.)) "," /// Inversión en ciencia y tecnología 9
	%8.0f real(subinstr(EducacPC,",","",.)) "," /// Total Educación 10
	%8.0f real(subinstr(ssaPC,",","",.)) "," /// Secretaría de Salud 11
	%8.0f real(subinstr(imssbienPC,",","",.)) "," /// IMSS-Bienestar 12
	%8.0f real(subinstr(imssPC,",","",.)) "," /// IMSS 13
	%8.0f real(subinstr(issstePC,",","",.)) "," /// ISSSTE 14
	%8.0f real(subinstr(pemexPC,",","",.)) "," /// Pemex 15
	%8.0f real(subinstr(issfamPC,",","",.)) "," /// ISSFAM 16
	%8.0f real(subinstr(inversPC,",","",.)) "," /// Inversión en salud 17
	%8.0f real(subinstr(saludPC,",","",.)) "," /// Total Salud 18
	%8.0f real(subinstr(pamPC,",","",.)) "," /// Pensión Bienestar 19
	%8.0f real(subinstr(penimssPC,",","",.)) "," /// Pensión IMSS 20
	%8.0f real(subinstr(penisssPC,",","",.)) "," /// Pensión ISSSTE 21
	%8.0f real(subinstr(penpemePC,",","",.)) "," /// Pensión Pemex 22
	%8.0f real(subinstr(penotroPC,",","",.)) "," /// Pensión CFE, LFC, ISSFAM, Otros 23
	%8.0f real(subinstr(pensionPC,",","",.)) "," /// Total Pensiones 24
	%8.0f real(subinstr(gascfePC,",","",.)) "," /// Gasto en CFE 25
	%8.0f real(subinstr(gaspemexPC,",","",.)) "," /// Gasto en Pemex 26
	%8.0f real(subinstr(gassenerPC,",","",.)) "," /// Gasto en SENER 27
	%8.0f real(subinstr(gasinverfPC,",","",.)) "," /// Gasto en Inversión (energía) 28
	%8.0f real(subinstr(gascosdeuePC,",","",.)) "," /// Gasto en Costo de la deuda (energía) 29
	%8.0f real(subinstr(gasenergiaPC,",","",.)) "," /// Total Energía 30
	%8.0f real(subinstr(gasinfraPC,",","",.)) "," /// Gasto en Inversión 31
	%8.0f real(subinstr(gasotrosPC,",","",.)) "," /// Otros gastos 32
	%8.0f real(subinstr(gasfederPC,",","",.)) "," /// Participaciones y aportaciones 33
	%8.0f real(subinstr(gascostoPC,",","",.)) "," /// Gasto en costo de la deuda 34
	%8.0f real(subinstr(otrosgasPC,",","",.)) "," /// Total Otros gastos 35
	%8.0f real(subinstr(IngBasPC,",","",.)) "," /// Ingreso Básico 36
	%8.0f ingbasico18 "," /// Checkbox "menores de 18 años" 37
	%8.0f ingbasico65 "," /// Checkbox "mayores de 65 años" 38
	%8.0f real(subinstr(gasmadresPC,",","",.)) "," /// Apoyo a madres trabajadoras 39
	%8.0f real(subinstr(gascuidadosPC,",","",.)) "," /// Gasto en cuidados 40
	%8.0f real(subinstr(transfPC,",","",.)) /// Total Transferencias 41
"]"

noisily di in w "ISRTASA: [" ///
	%10.2f ISR[1,4] "," ///
	%10.2f ISR[2,4] "," ///
	%10.2f ISR[3,4] "," ///
	%10.2f ISR[4,4] "," ///
	%10.2f ISR[5,4] "," ///
	%10.2f ISR[6,4] "," ///
	%10.2f ISR[7,4] "," ///
	%10.2f ISR[8,4] "," ///
	%10.2f ISR[9,4] "," ///
	%10.2f ISR[10,4] "," ///
	%10.2f ISR[11,4] ///
"]"

noisily di in w "ISRCUFI: [" ///
	%10.2f ISR[1,3] "," ///
	%10.2f ISR[2,3] "," ///
	%10.2f ISR[3,3] "," ///
	%10.2f ISR[4,3] "," ///
	%10.2f ISR[5,3] "," ///
	%10.2f ISR[6,3] "," ///
	%10.2f ISR[7,3] "," ///
	%10.2f ISR[8,3] "," ///
	%10.2f ISR[9,3] "," ///
	%10.2f ISR[10,3] "," ///
	%10.2f ISR[11,3] ///
"]"

noisily di in w "ISRSUBS: [" ///
	%10.2f SE[1,3] "," ///
	%10.2f SE[2,3] "," ///
	%10.2f SE[3,3] "," ///
	%10.2f SE[4,3] "," ///
	%10.2f SE[5,3] "," ///
	%10.2f SE[6,3] "," ///
	%10.2f SE[7,3] "," ///
	%10.2f SE[8,3] "," ///
	%10.2f SE[9,3] "," ///
	%10.2f SE[10,3] "," ///
	%10.2f SE[11,3] ///
"]"

noisily di in w "ISRDEDU: [" ///
	DED[1,1] "," /// Deducciones en salarios mínimos
	DED[1,2] "," /// Deducciones como % del ingreso gravable
	DED[1,3] "," /// Informalidad (% de personas) PERSONAS FÍSICAS
	DED[1,4] /// Informalidad (% de personas) SALARIOS
"]"

noisily di in w "ISRMORA: [" ///
	PM[1,1] "," ///
	PM[1,2] ///
"]"

noisily di in w "IVA: [" ///
	%5.2f IVAT[1,1] "," ///
	IVAT[2,1] "," ///
	IVAT[3,1] "," ///
	IVAT[4,1] "," ///
	IVAT[5,1] "," ///
	IVAT[6,1] "," ///
	IVAT[7,1] "," ///
	IVAT[8,1] "," ///
	IVAT[9,1] "," ///
	IVAT[10,1] "," ///
	IVAT[11,1] "," ///
	IVAT[12,1] "," ///
	IVAT[13,1] ///
"]"

noisily di in w "CSSIMSS: [" ///
	CSS_IMSS[1,1] "," ///
	CSS_IMSS[1,2] "," ///
	CSS_IMSS[1,3] "," ///
	CSS_IMSS[2,1] "," ///
	CSS_IMSS[2,2] "," ///
	CSS_IMSS[2,3] "," ///
	CSS_IMSS[3,1] "," ///
	CSS_IMSS[3,2] "," ///
	CSS_IMSS[3,3] "," ///
	CSS_IMSS[4,1] "," ///
	CSS_IMSS[4,2] "," ///
	CSS_IMSS[4,3] "," ///
	CSS_IMSS[5,1] "," ///
	CSS_IMSS[5,2] "," ///
	CSS_IMSS[5,3] "," ///
	CSS_IMSS[6,1] "," ///
	CSS_IMSS[6,2] "," ///
	CSS_IMSS[6,3] "," ///
	CSS_IMSS[7,1] "," ///
	CSS_IMSS[7,2] "," ///
	CSS_IMSS[7,3] ///
"]"

noisily di in w "CSSISSSTE: [" ///
	CSS_ISSSTE[1,1] "," ///
	CSS_ISSSTE[1,2] "," ///
	CSS_ISSSTE[1,3] "," ///
	CSS_ISSSTE[2,1] "," ///
	CSS_ISSSTE[2,2] "," ///
	CSS_ISSSTE[2,3] "," ///
	CSS_ISSSTE[3,1] "," ///
	CSS_ISSSTE[3,2] "," ///
	CSS_ISSSTE[3,3] "," ///
	CSS_ISSSTE[4,1] "," ///
	CSS_ISSSTE[4,2] "," ///
	CSS_ISSSTE[4,3] "," ///
	CSS_ISSSTE[5,1] "," ///
	CSS_ISSSTE[5,2] "," ///
	CSS_ISSSTE[5,3] "," ///
	CSS_ISSSTE[6,1] "," ///
	CSS_ISSSTE[6,2] "," ///
	CSS_ISSSTE[6,3] "," ///
	CSS_ISSSTE[7,1] "," ///
	CSS_ISSSTE[7,2] "," ///
	CSS_ISSSTE[7,3] "," ///
	CSS_ISSSTE[8,1] "," ///
	CSS_ISSSTE[8,2] "," ///
	CSS_ISSSTE[8,3] ///
"]"

quietly log off output
quietly log close output
tempfile output1 output2 output3
if "`=c(os)'" == "Windows" {
	capture filefilter "`c(sysdir_site)'/users/$pais/$id/${output}.txt" `output1', from(\r\n>) to("") replace // Windows
}
else {
	filefilter "`c(sysdir_site)'/users/$pais/$id/${output}.txt" `output1', from(\n>) to("") replace // Mac & Linux
}
filefilter `output1' `output2', from(" ") to("") replace
filefilter `output2' `output3', from("_") to(" ") replace
filefilter `output3' "`c(sysdir_site)'/users/$pais/$id/${output}.txt", from(".,") to("0") replace
