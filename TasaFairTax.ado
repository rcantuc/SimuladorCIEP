program TasaFairTax
quietly {
	args TaxSize

	SCN
	local PIB = r(PIB)
	local Con = r(Hogares_e_ISFLSH)

	noisily di _newline(2) in g "FairTax (exclusive): " in y %7.3fc  `TaxSize'/100*`PIB'/(`Con'-`TaxSize'/100*`PIB')*100 "%"
	noisily di in g "FairTax (inclusive): " in y %7.3fc `TaxSize'/100*`PIB'/`Con'*100 "%" _newline
}
end
