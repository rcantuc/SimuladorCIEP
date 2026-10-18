# Anexo: resumen generado por perfilar-web.sh — 2026-10-18

Salida íntegra de `python3 05_scripts/perfilar-web.py resumen <evidencia> 3` para la corrida de `perfil-web-2026-10-18.md` (rutas abreviadas: `<root>` = `/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-release-v8.10.0`). No se edita a mano: se regenera corriendo el instrumento.

## Resumen generado por perfilar-web.sh

Stata: `19.5|BE|1|Unix|Mac (Apple Silicon)|12 Aug 2026` (stata_version|edition|processors|os|machine_type|born_date)

Corridas instrumentadas: 3. Baseline no instrumentado: sí.

### Tiempo de pared (shell, `stata -b do`, incluye arranque de Stata y sysprofile)

| corrida | pared (s) | timer 1 de Web.Stata.do (s) | arranque + cierre (s) |
|---|---:|---:|---:|
| perfbase (sin hooks) | 32.49 | — | — |
| perfrun1 | 31.57 | 31.36 | 0.21 |
| perfrun2 | 31.71 | 31.54 | 0.17 |
| perfrun3 | 31.96 | 31.76 | 0.20 |

### Secciones de Web.Stata.do (timer de Stata, segundos de pared)

| # | sección | run1 | run2 | run3 | media | DE | % del total |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | 0 SET UP (sysdir, cd, scalars, log using) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 2 | 2 ECONOMIA: globals pib/def/inf | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 3 | 3.1 LIF + collapse + save LIF.dta | 0.08 | 0.06 | 0.07 | 0.07 | 0.01 | 0.2 |
| 4 | 3.1.1-3.1.7 parametros (scalars, matrices; submodulos apagados) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 5 | 3.1.8 TasasEfectivas (save ingresos.dta) | 1.35 | 1.49 | 1.44 | 1.43 | 0.06 | 4.5 |
| 6 | 3.2 PEF (dentro de /** ... **/: no corre) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 7 | 3.2.1 parametros gasto (scalars) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 8 | 3.2.2 GastoPC (save gastos.dta) | 7.37 | 7.83 | 7.99 | 7.73 | 0.26 | 24.5 |
| 9 | 3.3 matrices deuda + globals + tasaEfectiva | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| 10 | 6 use ingresos + merge gastos + save aportaciones | 0.62 | 0.63 | 0.63 | 0.62 | 0.01 | 2.0 |
| 11 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones | 4.59 | 4.48 | 4.62 | 4.56 | 0.06 | 14.5 |
| 12 | 7.1 FiscalGap | 12.79 | 12.46 | 12.41 | 12.55 | 0.17 | 39.8 |
| 13 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) | 4.54 | 4.57 | 4.58 | 4.56 | 0.01 | 14.5 |
| 14 | 8 output.do (log on -> output.txt + filefilter) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.0 |
| | **total secciones** | 31.34 | 31.52 | 31.73 | 31.53 | 0.16 | 100 |

### Comandos de primer nivel con rmsg (media de las corridas; ≥ 0.05 s)

| comando (truncado) | media (s) | min | max |
|---|---:|---:|---:|
| `noisily TasasEfectivas, anio(`=anioPE') enigh` | 1.42 | 1.34 | 1.48 |
| `noisily GastoPC educacion salud pensiones energia resto transferencias, aniop e(`=anioPE')` | 7.73 | 7.37 | 7.99 |
| `merge 1:1 (folioviv foliohog numren) using "${SIMROOT}/users/$id/gastos.dta", nogen` | 0.52 | 0.50 | 0.53 |
| `save `"${SIMROOT}/users/$id/aportaciones.dta"', replace` | 0.08 | 0.07 | 0.08 |
| `egen AlTrabajo = rsum(ISRPF_Sim ISRAS_Sim CUOTAS_Sim)` | 0.14 | 0.13 | 0.15 |
| `egen AlCapital = rsum(ISRPM_Sim OTROSK_Sim)` | 0.09 | 0.09 | 0.09 |
| `egen AlConsumo = rsum(IVA_Sim IEPSNP_Sim IEPSP_Sim ISAN_Sim IMPORT_Sim)` | 0.23 | 0.23 | 0.23 |
| `egen ImpuestosAportaciones = rsum(ISRPM_Sim ISRAS_Sim ISRPF_Sim CUOTAS_Sim IV A_Sim IEPSNP` | 0.39 | 0.38 | 0.40 |
| `egen Transferencias = rsum(Pensiones IngBasico Educacion Salud OtrasInversion es)` | 0.25 | 0.24 | 0.28 |
| `noisily Simulador AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=a nioPE') $nog` | 3.28 | 3.23 | 3.32 |
| `save `"${SIMROOT}/users/$id/aportaciones.dta"', replace` | 0.10 | 0.08 | 0.12 |
| `noisily FiscalGap, anio(`=anioPE') end(`=anioPE+5') aniomin(2016) $nographs d esde(2016) d` | 12.55 | 12.41 | 12.79 |
| `foreach k in decil grupoedad sexo rural escol {` | 4.56 | 4.54 | 4.57 |

### Profiler de Stata por sección (tiempo propio por programa, media de las corridas; ≥ 0.10 s)

El profiler reporta tiempo *propio* (sin subprogramas): la suma de los programas de una sección ≈ su timer. Los comandos builtin (use, save, replace, generate, sort…) no aparecen: quedan en el propio del programa que los llama.

| sección | programa | llamadas | segundos (media) | % de la sección |
|---|---|---:|---:|---:|
| 5 3.1.8 TasasEfectivas (save i | tabstat | 16 | 0.89 | 62 |
| 5 3.1.8 TasasEfectivas (save i | Distribucion | 15 | 0.29 | 21 |
| 5 3.1.8 TasasEfectivas (save i | SCN | 1 | 0.14 | 10 |
| 8 3.2.2 GastoPC (save gastos.d | GastoPC | 1 | 3.84 | 50 |
| 8 3.2.2 GastoPC (save gastos.d | tabstat | 20 | 2.78 | 36 |
| 8 3.2.2 GastoPC (save gastos.d | Distribucion | 9 | 0.34 | 4 |
| 8 3.2.2 GastoPC (save gastos.d | merge | 1 | 0.32 | 4 |
| 8 3.2.2 GastoPC (save gastos.d | _gtotal | 2 | 0.26 | 3 |
| 8 3.2.2 GastoPC (save gastos.d | _gcount | 1 | 0.13 | 2 |
| 10 6 use ingresos + merge gasto | merge | 3 | 0.48 | 92 |
| 11 6.7 egen + Simulador(reboot, | Simulador | 1 | 1.93 | 45 |
| 11 6.7 egen + Simulador(reboot, | _growtotal | 5 | 0.92 | 21 |
| 11 6.7 egen + Simulador(reboot, | GroupFromSort | 3 | 0.57 | 13 |
| 11 6.7 egen + Simulador(reboot, | merge | 2 | 0.36 | 8 |
| 11 6.7 egen + Simulador(reboot, | egen | 10 | 0.24 | 6 |
| 11 6.7 egen + Simulador(reboot, | _ggroup | 3 | 0.14 | 3 |
| 12 7.1 FiscalGap | PEF | 1 | 4.39 | 35 |
| 12 7.1 FiscalGap | _gtotal | 3 | 3.95 | 32 |
| 12 7.1 FiscalGap | collapse_17 | 37 | 2.15 | 17 |
| 12 7.1 FiscalGap | tabstat | 52 | 0.89 | 7 |
| 12 7.1 FiscalGap | merge | 32 | 0.57 | 5 |
| 12 7.1 FiscalGap | egen | 6 | 0.18 | 1 |
| 12 7.1 FiscalGap | _gsum | 3 | 0.16 | 1 |
| 12 7.1 FiscalGap | FiscalGap | 1 | 0.15 | 1 |
| 13 7.2 SankeySF x5 (decil grupo | collapse_17 | 25 | 2.71 | 70 |
| 13 7.2 SankeySF x5 (decil grupo | tabstat | 360 | 1.01 | 26 |

### Profiler de Stata, total del flujo (tiempo propio por programa, media; ≥ 0.10 s)

| programa | llamadas | segundos (media) | % del total |
|---|---:|---:|---:|
| tabstat | 477 | 5.59 | 18 |
| collapse_17 | 69 | 4.87 | 16 |
| PEF | 1 | 4.39 | 14 |
| _gtotal | 8 | 4.21 | 14 |
| GastoPC | 1 | 3.84 | 13 |
| Simulador | 1 | 1.93 | 6 |
| merge | 40 | 1.73 | 6 |
| _growtotal | 6 | 0.92 | 3 |
| Distribucion | 24 | 0.64 | 2 |
| GroupFromSort | 3 | 0.57 | 2 |
| egen | 21 | 0.45 | 1 |
| _gsum | 8 | 0.17 | 1 |
| FiscalGap | 1 | 0.15 | 1 |
| _ggroup | 3 | 0.14 | 0 |
| SCN | 1 | 0.14 | 0 |
| _gcount | 1 | 0.13 | 0 |

### Piso de I/O (use/save aislado, media de 3; mismos archivos que toca el flujo)

| modo | archivo | MB | s | MB/s |
|---|---|---:|---:|---:|
| lee | <root>/master/PEF.dta | 1696.2 | 0.323 | 5246 |
| lee | <root>/master/2024/households.dta | 527.0 | 0.104 | 5067 |
| escribe | <root>/users/perftraza/aportaciones.dta | 285.6 | 0.229 | 1247 |
| escribe | <root>/users/perftraza/gastos.dta | 233.7 | 0.324 | 722 |
| lee | <root>/users/perftraza/gastos.dta | 233.7 | 0.064 | 3652 |
| lee | <root>/master/perfiles2027.dta | 127.5 | 0.056 | 2265 |
| lee | <root>/raw/ENIGH/2024/concentrado.dta | 87.8 | 0.037 | 2374 |
| escribe | <root>/users/perftraza/ingresos.dta | 83.4 | 0.114 | 731 |
| lee | <root>/users/perftraza/ingresos.dta | 83.4 | 0.029 | 2904 |
| lee | <root>/master//Poblacion.dta | 26.4 | 0.064 | 412 |
| | otros 40 archivos < 1 MB (RECprom, PIBDeflactor, LIF, SHRFSP, bootstraps/1) | | 0.004 | |
| | **suma** | | 1.35 | |

### Inventario de archivos (traza; `veces` = aperturas en una corrida)

| modo | archivo | MB | veces | secciones |
|---|---|---:|---:|---|
| lee | <root>/master/PEF.dta | 1696.2 | 2 | 7.1 FiscalGap |
| lee | <root>/master/2024/households.dta | 527.0 | 1 | 3.2.2 GastoPC (save gastos.dta) |
| escribe | <root>/users/perftraza/aportaciones.dta | 285.6 | 2 | 6 use ingresos + merge gastos + save aportaciones; 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| escribe | <root>/users/perftraza/gastos.dta | 233.7 | 1 | 3.2.2 GastoPC (save gastos.dta) |
| lee | <root>/users/perftraza/gastos.dta | 233.7 | 2 | 6 use ingresos + merge gastos + save aportaciones; 7.1 FiscalGap |
| lee | <root>/master/perfiles2027.dta | 127.5 | 2 | 3.1.8 TasasEfectivas (save ingresos.dta); 3.2.2 GastoPC (save gastos.dta) |
| lee | <root>/raw/ENIGH/2024/concentrado.dta | 87.8 | 2 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| escribe | <root>/users/perftraza/ingresos.dta | 83.4 | 1 | 3.1.8 TasasEfectivas (save ingresos.dta) |
| lee | <root>/users/perftraza/ingresos.dta | 83.4 | 2 | 6 use ingresos + merge gastos + save aportaciones; 7.1 FiscalGap |
| lee | <root>/master//Poblacion.dta | 26.4 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| escribe | <root>/users/perftraza/sankey-decil.json | 1.5 | 1 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| escribe | <root>/users/perftraza/sankey-escol.json | 1.0 | 1 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| escribe | <root>/users/perftraza/sankey-grupoedad.json | 1.0 | 1 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| escribe | <root>/users/perftraza/sankey-rural.json | 0.8 | 1 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| lee | <root>/master/SCN.dta | 0.8 | 2 | 3.1.8 TasasEfectivas (save ingresos.dta) |
| escribe | <root>/users/perftraza/sankey-sexo.json | 0.8 | 1 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| lee | <root>/master/LIF.dta | 0.3 | 4 | 3.1 LIF + collapse + save LIF.dta; 7.1 FiscalGap |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasCICLO.dta | 0.1 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/perftraza/bootstraps/1/AportacionesNetasCICLO.dta | 0.1 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/master/PIBDeflactor.dta | 0.0 | 14 | 3.1 LIF + collapse + save LIF.dta; 3.1.8 TasasEfectivas (save ingresos.dta); 3.2.2 GastoPC (save gastos.dta); 6.7 egen + Simulador(reboot, B=1) + save aportaciones; 7.1 FiscalGap; 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| lee | <root>/master/SHRFSP.dta | 0.0 | 2 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/OTROSKRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasREC.dta | 0.0 | 2 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/perftraza/bootstraps/1/AportacionesNetasREC.dta | 0.0 | 2 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/ricardo/bootstraps/250/FederalizadoRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/Pension_AMRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/CFERECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/CUOTASRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/EducacionRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/EnergiaRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/FMPRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IEPSNPRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IEPSPRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IMPORTRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IMSSRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/ISANRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/ISRASRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/ISRPFRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/ISRPMRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/ISSSTERECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IVARECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/IngBasicoRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/Otras_inversionesRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/Otros_gastosRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/PEMEXRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/PensionesRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| lee | <root>/users/ricardo/bootstraps/250/SaludRECprom.dta | 0.0 | 1 | 7.1 FiscalGap |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasPERF.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/perftraza/bootstraps/1/AportacionesNetasPERF.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/01_modulos/visualizations/SankeySF.do | 0.0 | 5 | 7.2 SankeySF x5 (decil grupoedad sexo rural escol) |
| escribe | <root>/users/perftraza/LIF.dta | 0.0 | 1 | 3.1 LIF + collapse + save LIF.dta |
| lee | <root>/01_modulos/nodos/nodo-deuda.do | 0.0 | 1 | 7.1 FiscalGap |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasPT.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasINCI.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/perftraza/bootstraps/1/AportacionesNetasINCI.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| escribe | <root>/users/perftraza/bootstraps/1/AportacionesNetasPC.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
| lee | <root>/users/perftraza/bootstraps/1/AportacionesNetasPC.dta | 0.0 | 1 | 6.7 egen + Simulador(reboot, B=1) + save aportaciones |
