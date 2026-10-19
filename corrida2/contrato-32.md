# Contrato de entidad para las 32 (contrato-32.py, v8.13a)

## 1 Paridad: el flujo nacional no cambia un byte

| producto | sha256 sesión | sha256 referencia | |
|---|---|---|---|
| output.txt | `566c31ea6ab83f72…` | `566c31ea6ab83f72…` | ✓ byte-idéntico |
| sankey-decil.json | `8c05b4ff7a83b2b7…` | `8c05b4ff7a83b2b7…` | ✓ byte-idéntico |
| sankey-grupoedad.json | `91339076698c3042…` | `91339076698c3042…` | ✓ byte-idéntico |
| sankey-sexo.json | `6900d5cb7e4472b5…` | `6900d5cb7e4472b5…` | ✓ byte-idéntico |
| sankey-rural.json | `e7f4043eeb882b15…` | `e7f4043eeb882b15…` | ✓ byte-idéntico |
| sankey-escol.json | `e62d05bdb1371cfc…` | `e62d05bdb1371cfc…` | ✓ byte-idéntico |

## 2 Aditividad del ciclo de vida: Σ32 pct_nac = APORT* del output.txt

- JSON de ciclo de vida: **32/32**
- Σ32 pct_nac vs APORT* (6 vectores, celda a celda): diferencia máxima **0.000495** (tolerancia 0.0005): APORTHIV L=22 máx 0.000474, APORTHVIIX L=22 máx 0.000462, APORTHX L=22 máx 0.000489, APORTMIV L=22 máx 0.000494, APORTMVIIX L=22 máx 0.000473, APORTMX L=22 máx 0.000495
- Σ32 neto = 1,249,989.66 mdp vs nacional 1,249,989.66 mdp (reldif 0.00e+00, tol 1e-09)
- **PASÓ**

## 3 Tasas efectivas micro/micro: consistencia (PROPUESTA de gate, FLAG)

- JSON de tasas efectivas: **32/32**

| impuesto | base | Σ32 rec vs nacional (reldif) | Σ32 base vs nacional (reldif) | Σ32 rec / Σ32 base vs te nacional micro (reldif; informativo, te va con 6 decimales en el JSON) | te nacional micro (%) | rango de las 32 (%) | entidades con sello |
|---|---|---:|---:|---:|---:|---|---:|
| ISRAS | Sal | 1.32e-14 | 8.01e-16 | 3.60e-08 | 12.462 | 9.711 – 15.468 | 0 |
| CUOTAS | Sal | 1.42e-14 | 8.01e-16 | 1.02e-08 | 5.761 | 2.540 – 7.286 | 0 |
| ISRPF | Mix | 1.04e-13 | 7.35e-15 | 1.56e-07 | 1.770 | 0.373 – 3.739 | 13 |
| ISRPM | KPriv | 5.98e-15 | 7.36e-16 | 1.94e-08 | 12.604 | 6.053 – 23.838 | 2 |
| OTROSK | KPriv | 0.00e+00 | 7.36e-16 | 8.10e-08 | 4.901 | 2.354 – 9.269 | 2 |
| IVA | Consu | 5.66e-15 | 4.02e-16 | 4.87e-09 | 6.059 | 4.948 – 6.563 | 0 |
| IEPSNP | AlcTaba | 1.38e-13 | 1.62e-14 | 1.62e-09 | 47.024 | 35.256 – 61.965 | 0 |
| IEPSP | Combu | 3.72e-14 | 1.39e-14 | 1.43e-09 | 75.037 | 26.110 – 182.390 | 0 |
| ISAN | Vehic | 1.15e-12 | 9.72e-15 | 2.65e-07 | 1.693 | 1.693 – 1.693 | 0 |
| IMPORT | Consu | 4.31e-14 | 4.02e-16 | 1.61e-07 | 0.797 | 0.797 – 0.797 | 0 |

- reldif máximo de los MONTOS (Σ32 rec, Σ32 base vs nacional): **1.15e-12** (tolerancia propuesta 1e-9; los montos son sumas [aw=factor] de la misma base por residencia, así que Σ32 = nacional salvo coma flotante; la tasa nacional micro = Σ32 rec / Σ32 base = promedio ponderado por base; el JSON escribe los montos con 2 decimales, 1e-14 relativo).
- FLAG (metodología, Ricardo firma): las tasas no son aditivas; lo que propongo como gate es que los MONTOS lo sean (Σ32 rec = rec nacional, Σ32 base = base nacional) y, en consecuencia, que la tasa nacional micro/micro sea el promedio de las 32 ponderado por su base. Hoy se mide y se reporta; no bloquea.

## 4 Tabla de las 32 (insumo de v8.13b; aquí solo se mide y se declara)

Sellos: n < 100 o top-1 > 25 % (regla P5). «top-1 (n ≥ 100)» = mayor concentración en una celda NO delgada: el patrón del 47.9 % de NL (ISRPM) — una sola persona pone esa fracción del numerador. Las celdas con n = 1 valen 100 % por construcción y ya cuentan como selladas.

| # | entidad | corrió | s | sankeys | ciclo | tasas ef. | población | PIB/Defl. | n (TE) | selladas: sankeys micro / ciclo / TE | top-1 TE (impuesto) | top-1 (n ≥ 100) dónde | notas |
|---:|---|---|---:|---|---|---|---|---|---:|---|---|---|---|
| 1 | Aguascalientes (Ags) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 10247 | 23/154 / 22/46 / 0/10 | 10.6 % (ISRPF) | 35.7 % ciclo Mujeres 0-4 aporta (n=358) | PIB sin base (receta en tsv) |
| 2 | Baja California (BC) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 12686 | 21/154 / 17/46 / 0/10 | 22.1 % (ISRPF) | 45.6 % ciclo Mujeres 0-4 aporta (n=407) | PIB sin base (receta en tsv) |
| 3 | Baja California Sur (BCS) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 8661 | 21/155 / 21/46 / 0/10 | 24.6 % (ISRPF) | 49.7 % ciclo Hombres 5-9 aporta (n=315) | PIB sin base (receta en tsv) |
| 4 | Campeche (Camp) | ✓ | 13 | 5/5 | sí | sí | sí | sí | 7679 | 18/154 / 22/46 / 1/10 | 43.7 % (ISRPF) | 56.0 % ciclo Mujeres 0-4 aporta (n=248) |  |
| 5 | Coahuila (Coah) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 13841 | 19/155 / 15/46 / 0/10 | 11.7 % (ISRPM) | 29.1 % ciclo Mujeres 65-69 aporta (n=249) | PIB sin base (receta en tsv) |
| 6 | Colima (Col) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 10201 | 15/155 / 18/46 / 1/10 | 30.5 % (ISRPF) | 36.1 % ciclo Hombres 50-54 aporta (n=350) | PIB sin base (receta en tsv) |
| 7 | Chiapas (Chis) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 8417 | 26/155 / 19/46 / 0/10 | 21.0 % (ISRPF) | 34.2 % ciclo Hombres 0-4 aporta (n=355) | PIB sin base (receta en tsv) |
| 8 | Chihuahua (Chih) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 15100 | 13/155 / 17/46 / 0/10 | 13.2 % (ISRPF) | 53.2 % grupoedad De 5 a 17→Imp al trabajo (n=136) | PIB sin base (receta en tsv) |
| 9 | Ciudad de México (CDMX) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 8182 | 16/154 / 18/46 / 0/10 | 19.2 % (ISRPF) | 31.9 % ciclo Hombres 0-4 aporta (n=161) | PIB sin base (receta en tsv) |
| 10 | Durango (Dgo) | ✓ | 11 | 5/5 | sí | sí | sí | sin base | 9942 | 18/155 / 20/46 / 1/10 | 45.0 % (ISRPF) | 45.0 % TE ISRPF (n=9942) | PIB sin base (receta en tsv) |
| 11 | Guanajuato (Gto) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 11257 | 33/155 / 20/46 / 0/10 | 20.4 % (ISRPF) | 61.0 % ciclo Mujeres 0-4 aporta (n=360) | PIB sin base (receta en tsv) |
| 12 | Guerrero (Gro) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 9054 | 20/155 / 19/46 / 0/10 | 12.6 % (ISRPF) | 46.7 % ciclo Hombres 60-64 recibe (n=159) | PIB sin base (receta en tsv) |
| 13 | Hidalgo (Hgo) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 7704 | 24/154 / 19/46 / 0/10 | 13.9 % (ISRPF) | 36.5 % ciclo Hombres 45-49 aporta (n=205) | PIB sin base (receta en tsv) |
| 14 | Jalisco (Jal) | ✓ | 12 | 5/5 | sí | sí | sí | sí | 8617 | 32/155 / 19/46 / 0/10 | 14.5 % (ISRPF) | 54.1 % ciclo Hombres 55-59 recibe (n=159) |  |
| 15 | Estado de México (EdoMex) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 12885 | 17/155 / 19/46 / 1/10 | 29.7 % (ISRPF) | 62.7 % ciclo Hombres 75-79 aporta (n=102) | PIB sin base (receta en tsv) |
| 16 | Michoacán (Mich) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 7317 | 31/155 / 23/46 / 3/10 | 45.6 % (ISRPM) | 78.4 % ciclo Hombres 60-64 aporta (n=136) | PIB sin base (receta en tsv) |
| 17 | Morelos (Mor) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 8407 | 22/154 / 23/46 / 1/10 | 64.7 % (ISRPF) | 64.7 % TE ISRPF (n=8407) | PIB sin base (receta en tsv) |
| 18 | Nayarit (Nay) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 6783 | 26/155 / 23/46 / 1/10 | 42.1 % (ISRPF) | 85.7 % ciclo Hombres 5-9 aporta (n=278) | PIB sin base (receta en tsv) |
| 19 | Nuevo León (NL) | ✓ | 13 | 5/5 | sí | sí | sí | sí | 12586 | 23/155 / 16/46 / 2/10 | 47.9 % (ISRPM) | 83.8 % ciclo Hombres 60-64 aporta (n=293) |  |
| 20 | Oaxaca (Oax) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 9377 | 20/155 / 20/46 / 1/10 | 34.4 % (ISRPF) | 49.6 % ciclo Hombres 70-74 aporta (n=124) | PIB sin base (receta en tsv) |
| 21 | Puebla (Pue) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 7688 | 26/155 / 20/46 / 0/10 | 16.8 % (ISRPF) | 70.1 % ciclo Mujeres 15-19 aporta (n=345) | PIB sin base (receta en tsv) |
| 22 | Querétaro (Qro) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 13008 | 14/155 / 23/46 / 0/10 | 22.4 % (ISRPF) | 49.1 % escol Sin escolaridad→Imp al trabajo (n=113) | PIB sin base (receta en tsv) |
| 23 | Quintana Roo (QRoo) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 7868 | 28/154 / 22/46 / 0/10 | 12.6 % (IEPSNP) | 37.1 % ciclo Hombres 5-9 aporta (n=335) | PIB sin base (receta en tsv) |
| 24 | San Luis Potosí (SLP) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 9204 | 20/155 / 18/46 / 0/10 | 17.9 % (ISRPF) | 42.7 % ciclo Hombres 5-9 aporta (n=381) | PIB sin base (receta en tsv) |
| 25 | Sinaloa (Sin) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 11297 | 20/155 / 17/46 / 0/10 | 15.9 % (ISRPF) | 35.0 % ciclo Mujeres 75-79 aporta (n=113) | PIB sin base (receta en tsv) |
| 26 | Sonora (Son) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 8518 | 16/155 / 19/46 / 1/10 | 33.8 % (ISRPF) | 33.8 % TE ISRPF (n=8518) | PIB sin base (receta en tsv) |
| 27 | Tabasco (Tab) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 7775 | 25/155 / 26/46 / 1/10 | 36.9 % (ISRPF) | 67.8 % ciclo Mujeres 0-4 aporta (n=261) | PIB sin base (receta en tsv) |
| 28 | Tamaulipas (Tamps) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 7499 | 33/154 / 21/46 / 1/10 | 38.1 % (ISRPF) | 88.7 % ciclo Mujeres 0-4 aporta (n=221) | PIB sin base (receta en tsv) |
| 29 | Tlaxcala (Tlax) | ✓ | 13 | 5/5 | sí | sí | sí | sin base | 8269 | 25/154 / 18/46 / 1/10 | 26.9 % (ISRPF) | 34.3 % ciclo Mujeres 65-69 aporta (n=180) | PIB sin base (receta en tsv) |
| 30 | Veracruz (Ver) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 9831 | 21/155 / 17/46 / 0/10 | 19.0 % (ISRPF) | 31.0 % ciclo Hombres 15-19 aporta (n=398) | PIB sin base (receta en tsv) |
| 31 | Yucatán (Yuc) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 9803 | 21/155 / 20/46 / 1/10 | 27.0 % (ISRPF) | 41.4 % ciclo Mujeres 0-4 aporta (n=290) | PIB sin base (receta en tsv) |
| 32 | Zacatecas (Zac) | ✓ | 12 | 5/5 | sí | sí | sí | sin base | 8895 | 28/154 / 19/46 / 0/10 | 22.6 % (ISRPF) | 63.9 % ciclo Hombres 70-74 aporta (n=117) | PIB sin base (receta en tsv) |

- Entidades con el contrato completo (población + 5 sankeys + ciclo + tasas efectivas): **32/32**

## 5 Veredicto

- FLAG TE ISAN: la tasa es IDÉNTICA en las 32 (1.693 %): numerador y denominador se imputan con el mismo relativo (Distribucion); por entidad no aporta información — metodología, Ricardo decide si se publica
- FLAG TE IMPORT: la tasa es IDÉNTICA en las 32 (0.797 %): numerador y denominador se imputan con el mismo relativo (Distribucion); por entidad no aporta información — metodología, Ricardo decide si se publica
- **PASÓ** (paridad + aditividad del ciclo de vida; los Sankeys los dicta compuertas-entidad.md; TE y sellos solo se reportan)
