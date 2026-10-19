# Compuertas de salida — global entidad (compuertas-entidad.py)


## 2 Aditividad: Σ 32 entidades = nacional

- ✓ los 160 JSON de entidad existen
- ✓ quintil: ningún enlace de entidad sin contraparte nacional
- ✓ grupoedad: ningún enlace de entidad sin contraparte nacional
- ✓ sexo: ningún enlace de entidad sin contraparte nacional
- ✓ rural: ningún enlace de entidad sin contraparte nacional
- ✓ escol: ningún enlace de entidad sin contraparte nacional
- ✓ Σ 32 entidades = nacional en 224 enlaces/familias de 5 cortes (reldif máx 1.84e-13; tol 1e-09; tabla en aditividad.csv)

| corte | enlace | nacional (mdp) | Σ entidades (mdp) | reldif |
|---|---|---:|---:|---:|
| quintil | fam →    Inversión | 618,096.4 | 618,096.4 | 3.0e-15 |
| quintil | fam →    Transferencias | 22,074.9 | 22,074.9 | 9.0e-15 |
| quintil | fam →   Imp al capital | 2,323,380.3 | 2,323,380.3 | 0.0e+00 |
| quintil | fam →   Pensiones | 2,421,928.9 | 2,421,928.9 | 1.8e-15 |
| quintil | fam →  Imp al consumo | 2,846,081.8 | 2,846,081.8 | 8.6e-16 |
| quintil | fam → Educación | 1,387,957.6 | 1,387,957.6 | 1.6e-15 |
| quintil | fam → Imp al trabajo | 2,318,255.8 | 2,318,255.8 | 3.2e-15 |
| quintil | fam → Salud | 1,137,250.1 | 1,137,250.1 | 4.1e-15 |
| quintil | macro → Costo de la deuda → Sistema financiero | 1,453,393.8 | 1,453,393.8 | 1.7e-16 |
| quintil | macro → Energía → CFE Pemex SENER | 1,066,295.2 | 1,066,295.2 | 2.3e-16 |
| quintil | macro → Energía → Sistema financiero | 203,010.0 | 203,010.0 | 0.0e+00 |
| quintil | macro → IMSS  ISSSTE → Empresas públicas | 174,233.8 | 174,233.8 | 3.5e-16 |
| quintil | macro → Otros gastos → No distribuibles | 675,648.8 | 675,648.8 | 1.8e-16 |
| quintil | macro → Part y otras Aport → Estados y municipios | 1,651,673.5 | 1,651,673.5 | 1.5e-16 |
| quintil | macro → Pemex  CFE → Empresas públicas | 1,283,496.2 | 1,283,496.2 | 3.8e-16 |
| quintil | macro → Pemex  CFE → FMP | 210,893.9 | 210,893.9 | 0.0e+00 |
| quintil | residual | 1,480,987.4 | 1,480,987.4 | 9.9e-16 |
| sexo |    Inversión →  Hombres | 294,682.8 | 294,682.8 | 5.4e-14 |
| sexo |    Inversión →  Mujeres | 323,413.6 | 323,413.6 | 7.5e-15 |
| sexo |    Transferencias →  Hombres | 10,669.3 | 10,669.3 | 1.6e-14 |
| sexo |    Transferencias →  Mujeres | 11,405.6 | 11,405.6 | 2.0e-14 |
| sexo |   Imp al capital → CGPE 2027 | 2,323,380.3 | 2,323,380.3 | 2.1e-16 |
| sexo |   Pensiones →  Hombres | 1,359,705.6 | 1,359,705.6 | 6.6e-15 |
| sexo |   Pensiones →  Mujeres | 1,062,223.3 | 1,062,223.3 | 1.3e-15 |
| sexo |  Imp al consumo → CGPE 2027 | 2,846,081.8 | 2,846,081.8 | 1.5e-15 |
| sexo | CGPE 2027 →    Inversión | 618,096.4 | 618,096.4 | 2.9e-14 |
| sexo | CGPE 2027 →    Transferencias | 22,074.9 | 22,074.9 | 1.8e-14 |
| sexo | CGPE 2027 →   Pensiones | 2,421,928.9 | 2,421,928.9 | 3.4e-15 |
| sexo | CGPE 2027 → Costo de la deuda | 1,453,393.8 | 1,453,393.8 | 1.7e-16 |
| sexo | CGPE 2027 → Educación | 1,387,957.6 | 1,387,957.6 | 2.3e-14 |
| sexo | CGPE 2027 → Energía | 1,269,305.2 | 1,269,305.2 | 1.9e-16 |
| sexo | CGPE 2027 → Otros gastos | 675,648.8 | 675,648.8 | 1.8e-16 |
| sexo | CGPE 2027 → Part y otras Aport | 1,651,673.5 | 1,651,673.5 | 1.5e-16 |
| sexo | CGPE 2027 → Salud | 1,137,250.1 | 1,137,250.1 | 2.8e-15 |
| sexo | Costo de la deuda → Sistema financiero | 1,453,393.8 | 1,453,393.8 | 1.7e-16 |
| sexo | Educación →  Hombres | 700,318.8 | 700,318.8 | 7.8e-15 |
| sexo | Educación →  Mujeres | 687,638.8 | 687,638.8 | 3.7e-14 |
| sexo | Empresas públicas → CGPE 2027 | 1,457,730.0 | 1,457,730.0 | 1.7e-16 |
| sexo | Energía → CFE Pemex SENER | 1,066,295.2 | 1,066,295.2 | 2.3e-16 |
| sexo | Energía → Sistema financiero | 203,010.0 | 203,010.0 | 0.0e+00 |
| sexo | FMP → CGPE 2027 | 210,893.9 | 210,893.9 | 0.0e+00 |
| sexo | Hombres →   Imp al capital | 1,913,391.7 | 1,913,391.7 | 1.3e-16 |
| sexo | Hombres →  Imp al consumo | 1,549,787.6 | 1,549,787.6 | 7.9e-15 |
| sexo | Hombres → Imp al trabajo | 1,543,160.5 | 1,543,160.5 | 1.8e-14 |
| sexo | IMSS  ISSSTE → Empresas públicas | 174,233.8 | 174,233.8 | 3.5e-16 |
| sexo | Imp al trabajo → CGPE 2027 | 2,318,255.8 | 2,318,255.8 | 1.1e-14 |
| sexo | Mujeres →   Imp al capital | 409,988.7 | 409,988.7 | 4.5e-16 |
| sexo | Mujeres →  Imp al consumo | 1,296,294.2 | 1,296,294.2 | 6.2e-15 |
| sexo | Mujeres → Imp al trabajo | 775,095.3 | 775,095.3 | 2.2e-15 |
| sexo | Otros gastos → No distribuibles | 675,648.8 | 675,648.8 | 1.8e-16 |
| sexo | Part y otras Aport → Estados y municipios | 1,651,673.5 | 1,651,673.5 | 1.5e-16 |
| sexo | Pemex  CFE → Empresas públicas | 1,283,496.2 | 1,283,496.2 | 3.8e-16 |
| sexo | Pemex  CFE → FMP | 210,893.9 | 210,893.9 | 0.0e+00 |
| sexo | Salud →  Hombres | 464,130.0 | 464,130.0 | 1.1e-14 |
| sexo | Salud →  Mujeres | 673,120.2 | 673,120.2 | 1.2e-14 |
| sexo | residual | 1,480,987.4 | 1,480,987.4 | 1.5e-14 |

## 3 Testigo: Nuevo León por quintil estatal vs participaciones selladas del sprint

- ✓ 15 celdas quintil×familia del JSON = Σ pares dis<fam>nle<dec> del statajson (reldif máx 1.98e-15; tol 1e-12)
- ✓ 90 celdas dis<fam>nle<dec> reconstruidas (decil estatal, Households.do §12) = statajson (reldif máx 3.28e-15; tol 1e-13; 90 comparadas)
- ✓ meta del JSON: entidad Nuevo León clave 19 corte quintil estatal vintages 2016 2018 2020 2022 2024

## 4 Sellos de muestra y banda ENIGH (todas las entidades; detalle del segundo estado)

- ✓ todos los enlaces micro de las 32×5 traen n, top1 y sello
- ✓ banda ENIGH (bmin/bmax) en las 32 entidades (contrato-32): 32/32
- ✓ los sellos se activan: 715 enlaces micro con sello=1 en las 32 entidades × 5 cortes (4950 enlaces micro)

| entidad | corte | enlaces micro | con sello | con banda |
|---|---|---:|---:|---:|
| BCS | quintil | 40 | 2 | 30 |
| BCS | grupoedad | 35 | 5 | 28 |
| BCS | rural | 24 | 2 | 18 |
| BCS | escol | 40 | 12 | 30 |
| Camp | quintil | 40 | 3 | 30 |
| Camp | grupoedad | 34 | 5 | 27 |
| Camp | rural | 24 | 3 | 18 |
| Camp | escol | 40 | 7 | 30 |
| Col | quintil | 40 | 2 | 30 |
| Col | grupoedad | 35 | 2 | 28 |
| Col | rural | 24 | 5 | 18 |
| Col | escol | 40 | 6 | 30 |
| Jal | quintil | 40 | 4 | 30 |
| Jal | grupoedad | 35 | 6 | 28 |
| Jal | sexo | 16 | 1 | 12 |
| Jal | rural | 24 | 9 | 18 |
| Jal | escol | 40 | 12 | 30 |
| Nay | quintil | 40 | 3 | 30 |
| Nay | grupoedad | 35 | 6 | 28 |
| Nay | rural | 24 | 4 | 18 |
| Nay | escol | 40 | 13 | 30 |
| NL | quintil | 40 | 4 | 30 |
| NL | grupoedad | 35 | 5 | 28 |
| NL | sexo | 16 | 1 | 12 |
| NL | rural | 24 | 6 | 18 |
| NL | escol | 40 | 7 | 30 |
| Tlax | quintil | 40 | 4 | 30 |
| Tlax | grupoedad | 34 | 3 | 27 |
| Tlax | rural | 24 | 5 | 18 |
| Tlax | escol | 40 | 13 | 30 |

Jalisco (segundo estado de humo): 32 enlaces con sello. Detalle:

| corte | de | a | valor (mdp) | n | top1 % |
|---|---|---|---:|---:|---:|
| quintil | I | Imp al capital | 1,651.7 | 38 | 20.7 |
| quintil | II | Imp al capital | 5,325.6 | 54 | 8.1 |
| quintil | III | Imp al capital | 12,523.9 | 53 | 14.0 |
| quintil | IV | Imp al capital | 22,086.1 | 79 | 5.2 |
| grupoedad | De 0 a 4 | Imp al consumo | 1,769.8 | 547 | 34.0 |
| grupoedad | De 5 a 17 | Imp al trabajo | 831.7 | 94 | 6.7 |
| grupoedad | De 5 a 17 | Imp al capital | 69.1 | 3 | 69.4 |
| grupoedad | De 18 a 24 | Imp al capital | 2,110.2 | 20 | 30.7 |
| grupoedad | De 65 y más | Imp al capital | 16,890.8 | 73 | 13.0 |
| grupoedad | Pensiones | De 25 a 64 | 31,405.0 | 74 | 16.6 |
| sexo | Mujeres | Imp al capital | 28,359.6 | 99 | 14.6 |
| rural | Rural | Imp al capital | 5,449.9 | 60 | 14.8 |
| rural | Indígena | Imp al trabajo | 927.7 | 30 | 19.2 |
| rural | Indígena | Imp al consumo | 801.8 | 57 | 10.5 |
| rural | Indígena | Imp al capital | 722.5 | 2 | 51.0 |
| rural | Educación | Indígena | 308.3 | 57 | 16.8 |
| rural | Salud | Indígena | 630.4 | 46 | 9.2 |
| rural | Pensiones | Indígena | 485.0 | 1 | 100.0 |
| rural | Inversión | Indígena | 61.3 | 57 | 4.1 |
| rural | Transferencias | Indígena | 8.2 | 57 | 7.5 |
| escol | Sin escolaridad | Imp al trabajo | 2,468.1 | 72 | 17.9 |
| escol | Sin escolaridad | Imp al capital | 289.0 | 2 | 95.2 |
| escol | Media Superior | Imp al capital | 30,927.3 | 72 | 25.3 |
| escol | Posgrado | Imp al trabajo | 21,315.6 | 68 | 16.9 |
| escol | Posgrado | Imp al consumo | 18,903.3 | 89 | 14.2 |
| escol | Posgrado | Imp al capital | 17,453.4 | 13 | 25.6 |
| escol | Educación | Posgrado | 555.1 | 89 | 56.2 |
| escol | Salud | Posgrado | 2,068.6 | 64 | 6.9 |
| escol | Pensiones | Media Superior | 22,766.7 | 90 | 4.4 |
| escol | Pensiones | Posgrado | 4,783.7 | 17 | 12.1 |
| escol | Inversión | Posgrado | 155.8 | 89 | 11.2 |
| escol | Transferencias | Posgrado | 15.0 | 89 | 3.8 |

## Veredicto

**TODAS EN VERDE**
