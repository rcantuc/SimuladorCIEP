if "$output" != "" {
	quietly log on output

	noisily di in w "CRECPIB: ["  ///
		%8.1f $pib2022 ", " ///
		%8.1f $pib2023 ", " ///
		%8.1f $pib2024 ", " ///
		%8.1f $pib2025 ", " ///
		%8.1f $pib2026 ", " ///
		%8.1f $pib2027 ", " ///
		%8.1f $pib2028 ///
	"]"
	noisily di in w "CRECDEF: ["  ///
		%8.1f $def2022 ", " ///
		%8.1f $def2023 ", " ///
		%8.1f $def2024 ", " ///
		%8.1f $def2025 ", " ///
		%8.1f $def2026 ", " ///
		%8.1f $def2027 ", " ///
		%8.1f $def2028 ///
	"]"
	noisily di in w "DEUDAPARAM: [" ///
		$tasaEfectiva ", " ///
		$tipoDeCambio ", " ///
		$depreciacion ///
	"]"
	noisily di in w "GASTOS: ["  ///
		%8.3f basicaPIB "," /// Educación básica
		%8.3f medsupPIB "," /// Educación media superior
		%8.3f superiPIB "," /// Educación superior
		%8.3f posgraPIB "," /// Educación Posgrado
		%8.3f eduaduPIB "," /// Educación para adultos
		%8.3f otrosePIB "," /// Otros gastos educativos
		%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB "," /// Total Educación
		%8.3f ssaPIB "," /// Secretaría de Salud
		%8.3f imssbienPIB "," /// IMSS-Bienestar
		%8.3f imssPIB "," /// IMSS 
		%8.3f issstePIB "," /// ISSSTE
		%8.3f pemexPIB "," /// Pemex + ISSFAM
		%8.3f ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB "," /// Total Salud
		%8.3f bienestarPIB "," /// Pensión Bienestar
		%8.3f penimssPIB "," /// Pensión IMSS
		%8.3f penisssPIB "," /// Pensión ISSSTE
		%8.3f penotroPIB "," /// Pensión Pemex, CFE, LFC, ISSFAM, Otros
		%8.3f bienestarPIB+penimssPIB+penisssPIB+penotroPIB "," /// Total Pensiones
		%8.3f gascfePIB "," /// Gasto en CFE
		%8.3f gaspemexPIB "," /// Gasto en Pemex
		%8.3f gassenerPIB "," /// Gasto en SENER
		%8.3f gasinfraPIB "," /// Gasto en Inversión
		%8.3f gascostoPIB "," /// Gasto en Costo de la deuda
		%8.3f gasfederPIB "," /// Participaciones y aportaciones
		%8.3f gasotrosPIB "," /// Otros gastos
		%8.3f gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB "," /// Total Otros gastos
		%8.3f IngBasPIB "," /// Ingreso Básico
		%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB+ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+bienestarPIB+penimssPIB+penisssPIB+penotroPIB+gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB+IngBasPIB /// Total GASTO
		"]"
	noisily di in w "GASTOSPC: ["  ///
		%8.0f basica "," /// Educación básica
		%8.0f medsup "," /// Educación media superior
		%8.0f superi "," /// Educación superior
		%8.0f posgra "," /// Educación Posgrado
		%8.0f eduadu "," /// Educación para adultos
		%8.0f otrose "," /// Otros gastos educativos
		%8.0f scalar(educacion) "," /// Total Educación
		%8.0f ssa "," /// Secretaría de Salud
		%8.0f imssbien "," /// IMSS-Bienestar
		%8.0f imss "," /// IMSS
		%8.0f issste "," /// ISSSTE
		%8.0f pemex "," /// Pemex + ISSFAM
		%8.0f scalar(salud) "," /// Total Salud
		%8.0f bienestar "," /// Pensión Bienestar
		%8.0f penimss "," /// Pensión Pemex
		%8.0f penisss "," /// Pensión SENER
		%8.0f penotro "," /// Pensión Inversión
		%8.0f scalar(pensiones) "," /// Total Pensiones
		%8.0f gascfe "," /// Gasto en CFE
		%8.0f gaspemex "," /// Gasto en Pemex
		%8.0f gassener "," /// Gasto en SENER
		%8.0f gasinfra "," /// Gasto en Inversión
		%8.0f gascosto "," /// Gasto en costo de la deuda
		%8.0f gasfeder "," /// Participaciones y aportaciones
		%8.0f gasotros "," /// Otros gastos
		%8.0f scalar(otrosgastos) "," /// Total Otros gastos
		%8.0f ingbasico "," /// Ingreso Básico
		%8.0f ingbasico18 "," /// Checkbox "menores de 18 años"
		%8.0f ingbasico65 /// Checkbox "mayores de 65 años"
		"]"
	noisily di in w "INGRESOS: " in w "["  ///
		%8.3f scalar(ISRAS) "," /// ISR (salarios)
		%8.3f scalar(ISRPF) "," /// ISR (físicas)
		%8.3f scalar(CUOTAS) "," /// Cuotas IMSS
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS) "," /// Total Impuestos laborales
		%8.3f scalar(ISRPM) "," /// ISR (morales)
		%8.3f scalar(OTROSK) "," /// Productos, derechos y aprovechamientos 
		%8.3f scalar(ISRPM)+scalar(OTROSK) "," /// Total Impuestos al capital
		%8.3f scalar(IVA) "," /// IVA
		%8.3f scalar(ISAN) "," /// ISAN
		%8.3f scalar(IEPSNP) "," /// IEPS (no petrolero)
		%8.3f scalar(IEPSP) "," /// IEPS (petrolero)
		%8.3f scalar(IMPORT) "," /// Importaciones
		%8.3f scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT) "," /// Total Impuestos al consumo
		%8.3f scalar(IMSS) "," /// IMSS 
		%8.3f scalar(ISSSTE) "," /// ISSSTE 
		%8.3f scalar(FMP) "," /// FMP
		%8.3f scalar(PEMEX) "," /// Pemex
		%8.3f scalar(CFE) "," /// CFE
		%8.3f scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) "," /// Total Organismos y Empresas
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS)+scalar(ISRPM)+scalar(OTROSK)+scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT)+scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) /// Total INGRESOS
		"]"
	noisily di in w "INGRESOSTEF: " in w "["  ///
		%8.3f scalar(ISRAS)/RemSalPIB*100 "," /// ISR (salarios)
		%8.3f scalar(ISRPF)/MixLPIB*100 "," /// ISR (físicas)
		%8.3f scalar(CUOTAS)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100 "," /// Cuotas IMSS
		%8.3f (scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS))/YlPIB*100 "," /// Total Impuestos laborales
		%8.3f scalar(ISRPM)/ExNOpSocPIB*100 "," /// ISR (morales)
		%8.3f scalar(OTROSK)/ExNOpSocPIB*100 "," /// Productos, derechos y aprovechamientos
		%8.3f (scalar(ISRPM)+scalar(OTROSK))/CapIncImpPIB*100 "," /// Total Impuestos al capital
		%8.3f scalar(IVA)/(ConHogPIB-AlimPIB-BebNPIB-SaluPIB)*100 "," /// IVA
		%8.3f scalar(ISAN)/VehiPIB*100 "," /// ISAN
		%8.3f scalar(IEPSNP)/ConHogPIB*100 "," /// IEPS (no petrolero)
		%8.3f scalar(IEPSP)/ConHogPIB*100 "," /// IEPS (petrolero)
		%8.3f scalar(IMPORT)/ConHogPIB*100 "," /// Importaciones
		%8.3f ((IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT))/ConHogPIB*100 "," /// Total Impuestos al consumo
		%8.3f scalar(IMSS)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," /// IMSS
		%8.3f scalar(ISSSTE)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," /// ISSSTE
		%8.3f scalar(FMP)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," /// FMP
		%8.3f scalar(PEMEX)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," /// Pemex
		%8.3f scalar(CFE)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," /// CFE
		%8.3f (scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE))/CapIncImpPIB*100 /// Total Organismos y Empresas
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
		%10.2f SE[11,3] "," ///
		%10.2f SE[12,3] ///
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
}

if "$export" != "" {
	noisily scalarlatex
}
