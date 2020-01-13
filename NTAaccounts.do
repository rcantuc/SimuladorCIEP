	****************************
	** 1.5. NTA: Adding taxes **
	g double RemSalNTA = RemSal + ImpNetProduccion*RemSal/(RemSal + MixL + CapInc)
	g double MixLNTA = MixL + ImpNetProduccion*MixL/(RemSal + MixL + CapInc)
	g double CapIncNTA = CapInc + ImpNetProduccion*CapInc/(RemSal + MixL + CapInc)

	
	****************************
	** 1.6. NTA: Adding Taxes **
	g double ExBOpSoc = ExBOpISFLSH + ExBOpNoFin + ExBOpFin + MixK

	g double ExBOpNoFinNTA = ExBOpNoFin ///
		+ ImpNetProductos*ExBOpNoFin/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpNoFin/ExBOpSoc*CapInc/(RemSal + MixL + CapInc) 
	g double ExBOpFinNTA = ExBOpFin ///
		+ ImpNetProductos*ExBOpFin/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpFin/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)
	g double ExBOpISFLSHNTA = ExBOpISFLSH ///
		+ ImpNetProductos*ExBOpISFLSH/ExBOpSoc ///
		+ ImpNetProduccion*ExBOpISFLSH/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)
	g double MixKNTA = MixK ///
		+ ImpNetProductos*MixK/ExBOpSoc ///
		+ ImpNetProduccion*MixK/ExBOpSoc*CapInc/(RemSal + MixL + CapInc)

	g double ExBOpSocNTA = ExBOpNoFinNTA + ExBOpFinNTA + ExBOpISFLSHNTA + MixKNTA
	label var ExBOpSocNTA "Sociedades e ISFLSH (NTA)"

		g double ExNOpSocNTA = ExBOpNoFinNTA - DepNoFin + ExBOpFinNTA - DepFin + ExBOpISFLSHNTA - DepISFLSH - ROW
	format ExNOpSocNTA %20.0fc
	label var ExNOpSocNTA "Sociedades e ISFLSH (NTA)"

	g double MixKNNTA = MixKNTA - DepMix
	format MixKNNTA %20.0fc
	label var MixKNNTA "Ingreso mixto neto (capital) (NTA)"



	****************************
	** 1.7. Final adjustments **
	g double CapitalNTA = ExNOpSocNTA + ExNOpHog + ExNOpGob + MixKNNTA
	format CapitalNTA %20.0fc
	label var CapitalNTA "Ingreso de capital (NTA)"

		return scalar ExNOpSocNTA = ExNOpSocNTA[`obs']

	return scalar RemSalNTA = RemSalNTA[`obs']
	return scalar MixLNTA = MixLNTA[`obs']

	return scalar CapitalNTA = CapitalNTA[`obs']

	return scalar MixKNNTA = MixKNNTA[`obs']
