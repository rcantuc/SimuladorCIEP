if "$output" == "output" {
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
		%8.3f basicaPIB "," ///
		%8.3f medsupPIB "," ///
		%8.3f superiPIB "," ///
		%8.3f posgraPIB "," ///
		%8.3f eduaduPIB "," ///
		%8.3f otrosePIB "," ///
		%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB "," ///
		%8.3f ssaPIB "," ///
		%8.3f imssbienPIB "," ///
		%8.3f imssPIB "," ///
		%8.3f issstePIB "," ///
		%8.3f pemexPIB "," ///
		%8.3f ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB "," ///
		%8.3f bienestarPIB "," ///
		%8.3f penimssPIB "," ///
		%8.3f penisssPIB "," ///
		%8.3f penotroPIB "," ///
		%8.3f bienestarPIB+penimssPIB+penisssPIB+penotroPIB "," ///
		%8.3f gascfePIB "," ///
		%8.3f gaspemexPIB "," ///
		%8.3f gassenerPIB "," ///
		%8.3f gasinfraPIB "," ///
		%8.3f gascostoPIB "," ///
		%8.3f gasfederPIB "," ///
		%8.3f gasotrosPIB "," ///
		%8.3f gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB "," ///
		%8.3f IngBasPIB "," ///
		%8.3f basicaPIB+medsupPIB+superiPIB+posgraPIB+eduaduPIB+otrosePIB+ssaPIB+imssbienPIB+imssPIB+issstePIB+pemexPIB+bienestarPIB+penimssPIB+penisssPIB+penotroPIB+gascfePIB+gaspemexPIB+gassenerPIB+gasinfraPIB+gascostoPIB+gasfederPIB+gasotrosPIB+IngBasPIB ///
		"]"
	noisily di in w "GASTOSPC: ["  ///
		%8.0f basica "," ///
		%8.0f medsup "," ///
		%8.0f superi "," ///
		%8.0f posgra "," ///
		%8.0f eduadu "," ///
		%8.0f otrose "," ///
		%8.0f scalar(educacion) "," ///
		%8.0f ssa "," ///
		%8.0f imssbien "," ///
		%8.0f imss "," ///
		%8.0f issste "," ///
		%8.0f pemex "," ///
		%8.0f scalar(salud) "," ///
		%8.0f bienestar "," ///
		%8.0f penimss "," ///
		%8.0f penisss "," ///
		%8.0f penotro "," ///
		%8.0f pensiones "," ///
		%8.0f gascfe "," ///
		%8.0f gaspemex "," ///
		%8.0f gassener "," ///
		%8.0f gasinfra "," ///
		%8.0f gascosto "," ///
		%8.0f gasfeder "," ///
		%8.0f gasotros "," ///
		%8.0f otrosgastos "," ///
		%8.0f ingbasico "," ///
		%8.0f ingbasico18 "," ///
		%8.0f ingbasico65 ///
		"]"
	noisily di in w "INGRESOSPIB: " in w "["  ///
		%8.3f scalar(ISRAS) "," ///
		%8.3f scalar(ISRPF) "," ///
		%8.3f scalar(CUOTAS) "," ///
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS) "," ///
		%8.3f scalar(ISRPM) "," ///
		%8.3f scalar(OTROSK) "," ///
		%8.3f scalar(ISRPM)+scalar(OTROSK) "," ///
		%8.3f scalar(IVA) "," ///
		%8.3f scalar(ISAN) "," ///
		%8.3f scalar(IEPSNP) "," ///
		%8.3f scalar(IEPSP) "," ///
		%8.3f scalar(IMPORT) "," ///
		%8.3f scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT) "," ///
		%8.3f scalar(IMSS) "," ///
		%8.3f scalar(ISSSTE) "," ///
		%8.3f scalar(FMP) "," ///
		%8.3f scalar(PEMEX) "," ///
		%8.3f scalar(CFE) "," ///
		%8.3f scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) "," ///
		%8.3f scalar(ISRAS)+scalar(ISRPF)+scalar(CUOTAS)+scalar(ISRPM)+scalar(OTROSK)+scalar(IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT)+scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE) ///
		"]"
	noisily di in w "INGRESOSTEF: " in w "["  ///
		%8.3f scalar(ISRAS)/RemSalPIB*100 "," ///
		%8.3f scalar(ISRPF)/MixLPIB*100 "," ///
		%8.3f scalar(CUOTAS)/(RemSalPIB+SSImputadaPIB+SSEmpleadoresPIB)*100 "," ///
		%8.3f (scalar(ISRPM)+scalar(OTROSK))/YlPIB*100 "," ///
		%8.3f scalar(ISRPM)/ExNOpSocPIB*100 "," ///
		%8.3f scalar(OTROSK)/ExNOpSocPIB*100 "," ///
		%8.3f (scalar(ISRPM)+scalar(OTROSK))/CapIncImpPIB*100 "," ///
		%8.3f scalar(IVA)/(ConHogPIB-AlimPIB-BebNPIB-SaluPIB)*100 "," ///
		%8.3f scalar(ISAN)/VehiPIB*100 "," ///
		%8.3f scalar(IEPSNP)/ConHogPIB*100 "," ///
		%8.3f scalar(IEPSP)/ConHogPIB*100 "," ///
		%8.3f scalar(IMPORT)/ConHogPIB*100 "," ///
		%8.3f ((IVA)+scalar(ISAN)+scalar(IEPSNP)+scalar(IEPSP)+scalar(IMPORT))/ConHogPIB*100 "," ///
		%8.3f scalar(IMSS)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," ///
		%8.3f scalar(ISSSTE)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," ///
		%8.3f scalar(FMP)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," ///
		%8.3f scalar(PEMEX)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," ///
		%8.3f scalar(CFE)/(IMSS+ISSSTE+FMP+PEMEX+CFE)*100 "," ///
		%8.3f (scalar(IMSS)+scalar(ISSSTE)+scalar(FMP)+scalar(PEMEX)+scalar(CFE))/CapIncImpPIB*100 ///
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
		DED[1,1] "," ///
		DED[1,2] "," ///
		DED[1,3] "," ///
		DED[1,4] ///
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
		filefilter "`c(sysdir_site)'/users/$pais/$id/output.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_site)'/users/$pais/$id/output.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' `output3', from("_") to(" ") replace
	filefilter `output3' "`c(sysdir_site)'/users/$pais/$id/output.txt", from(".,") to("0") replace
}

if "$export" != "" {
	noisily scalarlatex
}
