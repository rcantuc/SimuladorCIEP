if "$output" != "" {
	quietly log on output

	noisily di in w "CRECPIB: ["  ///
		%8.1f pib2024 ", " ///
		%8.1f pib2025 ", " ///
		%8.1f pib2026 ", " ///
		%8.1f pib2027 ", " ///
		%8.1f pib2028 ", " ///
		%8.1f pib2029 ", " ///
		%8.1f pib2029 ///
	"]"
	noisily di in w "CRECDEF: ["  ///
		%8.1f def2024 ", " ///
		%8.1f def2025 ", " ///
		%8.1f def2026 ", " ///
		%8.1f def2027 ", " ///
		%8.1f def2028 ", " ///
		%8.1f def2029 ", " ///
		%8.1f def2029 ///
	"]"
	noisily di in w "DEUDAPARAM: [" ///
		%8.3f scalar(tasaEfectiva) /// Tasa de interés efectiva
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
		%8.3f iniciaAPIB+basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB+inverePIB+culturPIB+investPIB+ ///
			ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+issfamPIB+inversPIB+ ///
			pamPIB+penimssPIB+penisssPIB+penpemePIB+penotroPIB+ ///
			gascfePIB+gaspemexPIB+gassenerPIB+gasinverfPIB+gascosdeuePIB+ ///
			gasinfraPIB+gasotrosPIB+gasfederPIB+gascostoPIB+IngBasPIB+gasmadresPIB+gascuidadosPIB /// Total GASTO 40
		"]"
	noisily di in w "GASTOSPC: ["  ///
		%8.0f iniciaA "," /// Educación inicial 0
		%8.0f basica "," /// Educación básica 1
		%8.0f medsup "," /// Educación media superior 2
		%8.0f superi "," /// Educación superior 3
		%8.0f posgra "," /// Educación Posgrado 4
		%8.0f eduadu "," /// Educación para adultos 5
		%8.0f otrose "," /// Otros gastos educativos 6
		%8.0f invere "," /// Inversión educativa 7
		%8.0f cultur "," /// Cultura 8
		%8.0f invest "," /// Inversión en ciencia y tecnología 9
		%8.0f scalar(Educacion) "," /// Total Educación 10
		%8.0f ssa "," /// Secretaría de Salud 11
		%8.0f imssbien "," /// IMSS-Bienestar 12
		%8.0f imss "," /// IMSS 13
		%8.0f issste "," /// ISSSTE 14
		%8.0f pemex "," /// Pemex 15
		%8.0f issfam "," /// ISSFAM 16
		%8.0f invers "," /// Inversión en salud 17
		%8.0f scalar(salud) "," /// Total Salud 18
		%8.0f pam "," /// Pensión Bienestar 19
		%8.0f penimss "," /// Pensión IMSS 20
		%8.0f penisss "," /// Pensión ISSSTE 21
		%8.0f penpeme "," /// Pensión Pemex 22
		%8.0f penotro "," /// Pensión CFE, LFC, ISSFAM, Otros 23
		%8.0f scalar(pensiones) "," /// Total Pensiones 24
		%8.0f gascfe "," /// Gasto en CFE 25
		%8.0f gaspemex "," /// Gasto en Pemex 26
		%8.0f gassener "," /// Gasto en SENER 27
		%8.0f gasinverf "," /// Gasto en Inversión (energía) 28
		%8.0f gascosdeue "," /// Gasto en Costo de la deuda (energía) 29
		%8.0f scalar(gasenergia) "," /// Total Energía 30
		%8.0f gasinfra "," /// Gasto en Inversión 31
		%8.0f gasotros "," /// Otros gastos 32
		%8.0f gasfeder "," /// Participaciones y aportaciones 33
		%8.0f gascosto "," /// Gasto en costo de la deuda 34
		%8.0f scalar(otrosgas) "," /// Total Otros gastos 35
		%8.0f ingbasico "," /// Ingreso Básico 36
		%8.0f ingbasico18 "," /// Checkbox "menores de 18 años" 37
		%8.0f ingbasico65 "," /// Checkbox "mayores de 65 años" 38
		%8.0f gasmadres "," /// Apoyo a madres trabajadoras 39
		%8.0f gascuidados "," /// Gasto en cuidados 40
		%8.0f scalar(transf) /// Total Transferencias 41
		"]"
	noisily di in w "INGRESOS: " in w "["  ///
		%8.3f scalar(ISRAS) "," /// ISR (salarios) - 0
		%8.3f scalar(ISRPF) "," /// ISR (físicas) - 1
		%8.3f scalar(CUOTAS) "," /// Cuotas IMSS - 2
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS) "," /// Total Impuestos laborales - 3
		%8.3f scalar(ISRPM) "," /// ISR (morales) - 4
		%8.3f scalar(OTROSK) "," /// Productos, derechos y aprovechamientos - 5
		%8.3f scalar(ISRPM)+scalar(OTROSK) "," /// Total Impuestos al capital - 6
		%8.3f scalar(IVA) "," /// IVA - 7
		%8.3f scalar(ISAN) "," /// ISAN - 8
		%8.3f scalar(IEPSNP) "," /// IEPS (no petrolero)- 9
		%8.3f scalar(IEPSP) "," /// IEPS (petrolero) - 10
		%8.3f scalar(IMPORT) "," /// Importaciones - 11
		%8.3f scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT) "," /// Total Impuestos al consumo - 12
		%8.3f scalar(IMSS) "," /// IMSS - 13
		%8.3f scalar(ISSSTE) "," /// ISSSTE - 14
		%8.3f scalar(FMP) "," /// FMP - 15
		%8.3f scalar(PEMEX) "," /// Pemex - 16
		%8.3f scalar(CFE) "," /// CFE - 17
		%8.3f scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) "," /// Total Organismos y Empresas - 18
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS)+scalar(ISRPM)+scalar(OTROSK)+scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT)+scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) /// Total INGRESOS - 19
		"]"
	noisily di in w "INGRESOSTEF: " in w "["  ///
		%8.1f scalar(ISRAS)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 "," /// ISR (salarios) - 0
		%8.1f scalar(ISRPF)/MixLPIB*100 "," /// ISR (físicas) - 1
		%8.1f scalar(CUOTAS)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB+ImpNetProduccionLPIB)*100 "," /// Cuotas IMSS - 2
		%8.1f (scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS))/YlPIB*100 "," /// Total Impuestos laborales - 3
		%8.1f scalar(ISRPM)/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100 "," /// ISR (morales) - 4
		%8.1f scalar(OTROSK)/(ExNOpSocPIB+MixKNPIB+ImpNetProduccionKPIB+ImpNetProductosPIB-IngKPublicosPIB)*100 "," /// Productos, derechos y aprovechamientos - 5
		%8.1f (scalar(ISRPM)+scalar(OTROSK))/(CapIncImpPIB-IngKPublicosPIB)*100 "," /// Total Impuestos al capital - 6
		%8.1f scalar(IVA)/(ConHogPIB)*100 "," /// IVA - 7
		%8.1f scalar(ISAN)/VehiPIB*100 "," /// ISAN - 8
		%8.1f scalar(IEPSNP)/ConHogPIB*100 "," /// IEPS (no petrolero) - 9
		%8.1f scalar(IEPSP)/ConHogPIB*100 "," /// IEPS (petrolero) - 10
		%8.1f scalar(IMPORT)/ConHogPIB*100 "," /// Importaciones - 11
		%8.1f ((IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT))/ConHogPIB*100 "," /// Total Impuestos al consumo - 12
		%8.1f scalar(IMSS)/(CapIncImpPIB)*100 "," /// IMSS - 13
		%8.1f scalar(ISSSTE)/(CapIncImpPIB)*100 "," /// ISSSTE - 14
		%8.1f scalar(FMP)/(CapIncImpPIB)*100 "," /// FMP - 15
		%8.1f scalar(PEMEX)/(CapIncImpPIB)*100 "," /// Pemex - 16
		%8.1f scalar(CFE)/(CapIncImpPIB)*100 "," /// CFE - 17
		%8.1f (scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE))/CapIncImpPIB*100 /// Total Organismos y Empresas - 18
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
		capture filefilter "`c(sysdir_personal)'/users/$pais/$id/${output}.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/${output}.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' `output3', from("_") to(" ") replace
	filefilter `output3' "`c(sysdir_personal)'/users/$pais/$id/${output}.txt", from(".,") to("0") replace
}
