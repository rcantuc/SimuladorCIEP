if "$id" == "CIEP" {
	scalar ZxhCIEPNETI = ZxhCIEPISRFisicasI + ZxhCIEPcuotasTPI + ZxhCIEPIVATotalI - ZxhCIEPbenefhealthI
	scalar ZxhCIEPNETII = ZxhCIEPISRFisicasII + ZxhCIEPcuotasTPII + ZxhCIEPIVATotalII - ZxhCIEPbenefhealthII
	scalar ZxhCIEPNETIII = ZxhCIEPISRFisicasIII + ZxhCIEPcuotasTPIII + ZxhCIEPIVATotalIII - ZxhCIEPbenefhealthIII
	scalar ZxhCIEPNETIV = ZxhCIEPISRFisicasIV + ZxhCIEPcuotasTPIV + ZxhCIEPIVATotalIV - ZxhCIEPbenefhealthIV
	scalar ZxhCIEPNETV = ZxhCIEPISRFisicasV + ZxhCIEPcuotasTPV + ZxhCIEPIVATotalV - ZxhCIEPbenefhealthV
	scalar ZxhCIEPNETVI = ZxhCIEPISRFisicasVI + ZxhCIEPcuotasTPVI + ZxhCIEPIVATotalVI - ZxhCIEPbenefhealthVI
	scalar ZxhCIEPNETVII = ZxhCIEPISRFisicasVII + ZxhCIEPcuotasTPVII + ZxhCIEPIVATotalVII - ZxhCIEPbenefhealthVII
	scalar ZxhCIEPNETVIII = ZxhCIEPISRFisicasVIII + ZxhCIEPcuotasTPVIII + ZxhCIEPIVATotalVIII - ZxhCIEPbenefhealthVIII
	scalar ZxhCIEPNETIX = ZxhCIEPISRFisicasIX + ZxhCIEPcuotasTPIX + ZxhCIEPIVATotalIX - ZxhCIEPbenefhealthIX
	scalar ZxhCIEPNETX = ZxhCIEPISRFisicasX + ZxhCIEPcuotasTPX + ZxhCIEPIVATotalX - ZxhCIEPbenefhealthX
	scalar ZxhCIEPNETNacional = ZxhCIEPISRFisicasNacional + ZxhCIEPcuotasTPNacional + ZxhCIEPIVATotalNacional - ZxhCIEPbenefhealthNacional

	scalar ZNETI = ZxhCIEPNETI/ZxhCIEPingbrutoTI*100
	scalar ZNETII = ZxhCIEPNETII/ZxhCIEPingbrutoTII*100
	scalar ZNETIII = ZxhCIEPNETII/ZxhCIEPingbrutoTIII*100
	scalar ZNETIV = ZxhCIEPNETIII/ZxhCIEPingbrutoTIV*100
	scalar ZNETV = ZxhCIEPNETIV/ZxhCIEPingbrutoTV*100
	scalar ZNETVI = ZxhCIEPNETVI/ZxhCIEPingbrutoTVI*100
	scalar ZNETVII = ZxhCIEPNETVII/ZxhCIEPingbrutoTVII*100
	scalar ZNETVIII = ZxhCIEPNETVIII/ZxhCIEPingbrutoTVIII*100
	scalar ZNETIX = ZxhCIEPNETIX/ZxhCIEPingbrutoTIX*100
	scalar ZNETX = ZxhCIEPNETX/ZxhCIEPingbrutoTX*100
	scalar ZNETNacional = ZxhCIEPNETNacional/ZxhCIEPingbrutoTNacional*100
}

if "$id" == "Fair" {
	scalar ZFAIRI = ZxhFairIVATotalI/ZxhFairingbrutoTI*100
	scalar ZFAIRII = ZxhFairIVATotalII/ZxhFairingbrutoTII*100
	scalar ZFAIRIII = ZxhFairIVATotalII/ZxhFairingbrutoTIII*100
	scalar ZFAIRIV = ZxhFairIVATotalIII/ZxhFairingbrutoTIV*100
	scalar ZFAIRV = ZxhFairIVATotalIV/ZxhFairingbrutoTV*100
	scalar ZFAIRVI = ZxhFairIVATotalVI/ZxhFairingbrutoTVI*100
	scalar ZFAIRVII = ZxhFairIVATotalVII/ZxhFairingbrutoTVII*100
	scalar ZFAIRVIII = ZxhFairIVATotalVIII/ZxhFairingbrutoTVIII*100
	scalar ZFAIRIX = ZxhFairIVATotalIX/ZxhFairingbrutoTIX*100
	scalar ZFAIRX = ZxhFairIVATotalX/ZxhFairingbrutoTX*100
	scalar ZFAIRNacional = ZxhFairIVATotalNacional/ZxhFairingbrutoTNacional*100
}
