clear all
macro drop _all

if "`c(username)'" == "ricardo" {
	global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}


LIF, by(divLIF) desde(2015) rows(2) min(0)

scalar EImpuestos = string(scalar(EImpuestos),"%7.3fc")


local EImpuestos = real(scalar(EImpuestos))
scalar NuevaVariable = string(`EImpuestos'/scalar(ECuotas)*100,"%7.3fc")




scalarlatex, log(ingresos) alt(ing)
