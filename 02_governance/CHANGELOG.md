# Changelog del Simulador Fiscal CIEP

Este archivo registra los cambios de cada versión publicada del Simulador Fiscal CIEP.

Las versiones se numeran siguiendo el esquema descrito en `02_governance/versionado-y-git.md` §3:
mayor cuando hay cambio metodológico o institucional de fondo, menor cuando hay datos nuevos
o funcionalidad nueva compatible, patch para correcciones sobre versión publicada.

**A partir de v8.0, todas las versiones son reproducibles end-to-end** — código + datos +
endpoint publicados en la misma versión, referenciables mediante `git checkout v8.x`.

Formato de cada entrada:
- **Institucional:** cambios de governance, infraestructura, arquitectura de publicación
- **Comandos:** cambios que afectan cómo se usa el Simulador desde Stata (nuevas opciones,
  comandos agregados o modificados, comandos deprecados)
- **Datos:** cambios en fuentes, actualizaciones de PEFs, LIFs, ENIGH, u otras fuentes
- **Correcciones:** bugs corregidos que afectaban resultados o funcionamiento

## [Unreleased]

### [v8.15.0] — Cuadratura I: `Households` re-anclado al sector hogares S.14 (sesión v8.15b, 2026-10-31; CUAD-0 firmado)

**Baseline: `v8.15.0`. A partir de v8.15.0 los números publicados (`output.txt`, los 10 sankeys, las 32 entidades, `/NTA`) NO comparan con ≤ v8.14.0** por las decisiones firmadas en `02_governance/CUAD-0-firma.md` §B (manda sobre el memo): (2) `pensiones_en_yl = off`; (3) `ing_mixto_depurado = transf_negocios` con honorarios íntegros a B.3n y sin partición pf/PM (`cap3_particion` murió; no existen `*pf`/`*PM`); (5) `yk_ancla = b2n_b3n_d4` completo; (6) `cap4 = fuera`; (8) `alq_en_capital = off`; `d4_relativo = proxy_propiedad` (sello rojo: la ENIGH cubre 0.43 % de D.4); (9) `suborrow = off`; (10) `oye_en_hub = off`; (11) `cuotas_d614 = neto`; (13) filas de sector; (14) `baseline`; más lo que la firma D implica: **sin impuestos embebidos** en ningún factor Altimir (productos y producción explícitos, fuera de Yl/Yk) y **`rentas_celda = b3n`** (rentas efectivas de hogares en B.3n: SNA 2008 §7.9, INEGI p. 33/45; la alternativa `b2n`, SNA §24.55, queda declarada: el paso 0 encontró B.2b S.14 2,107.569 > alquiler imputado CSVM 2024 1,886.385, +221.184 = 11.7 %: FLAG 18 abierto, de contenido, no de vintage (el vintage BIE–CSI es 0.25 %); las dos lecturas quedan declaradas hasta la ficha de la CSVM o de la CSI base 2018).

- **Datos — `Households.do` (Tabla 1 firmada; principio C: una celda S.14 por variable, sin impuestos embebidos).** `ing_subor` → D.1 S.14 (10,052.962; `TaltimirSal` 0.9781 → **1.0650**); `ing_mixto` = honorarios + rentas efectivas + negocios propios → B.3n (6,956.984; `TaltimirSelf` 6.1543 → **3.6848**; base cruda 1,888.030 = honorarios 758.146 + rentas 110.753 + negocios 900.869 + agropecuario 118.262, no ≈ 1,512 como estimaba la firma con ≈ 4.6); `ing_estim_alqu` → B.2n (910.359; `TaltimirHouse` 3.1666 → **2.5860**); `ing_capital` = `Distribucion` de D.4 neto − D.442 (**4,997.037**) ∝ `ing_d4_rel` (cap6 + cap8 + cap3 + alquiler + negocios, crudos 1,503.626; D.4/relativo 3.3233; cobertura ENIGH cap6 + cap8 **0.43 %**, `escalar D4CoberturaENIGH`); remesas una sola vez (`ing_remesas` × 8.3807 a ROWTrans; D.752 S.14 1,188.474 se reporta); cap4, cap5, cap6, cap7, cap8, cap9 con factor 1 fuera de Yl/Yk (siguen en `ing_bruto_tax`); `ing_bruto_tpm` = negocios propios. Yl = D.1 + ⅔ B.3n = **14,690.951**; Yk − CCF = YAHogS14 − D.442 = **8,226.391**. Gates nuevos en el log de `Households.do` §9.1 (1e-9): Σ `ing_subor` = D.1, Σ `ing_mixto` = B.3n, Σ alquiler + rentas = B.2n, Σ `ing_capital` = D.4 neto − D.442, componentes de `ing_mixto` = agregado, Σ Yl, Σ Yk − CCF, identidad de sectores. Los parámetros y los factores viajan en `households.dta` (`char cuad_params`, `TaltimirSal/Self/House/ROWTrans`).
- **Datos — `NTA.do`.** Las correcciones que compensaban al motor (`nta_pens_enYl`, `nta_mixto_transf/fin`, `nta_impprod_*`, `ing_suborROW`) valen 0 con la firma y se reportan; YA se ancla a YAHogS14 − D.442 (`cuotas_d614 = neto`) y el factor `fYA` **= 1.000000** se exige (FLAG si no); OyE fuera del hub: «Empresas públicas → Gobierno» en los Sankeys v2 y v3 (el hub `Ing nacional` baja en 1,601.824). `nta-identidad.txt` gana los parámetros de Households y la tabla «De dónde sale la brecha» (Σ S sin ancla − B.8n partida por partida, formato CUAD-0). Σ S sin ancla = **2,116.145** bn, brecha **+11.3 %** vs B.8n 1,901.026 (esperado +11.3 %, firma C); ancla multiplicativa viva (factor 0.8983).
- **Datos — Sankey «PIB demográfico» (`Sankey.do`) y `output.txt` (firma 13).** `Yl + Yk + OyE = PIB` se sustituye por **PIB (BIE) = YL + YA + D.442 + B.5n S.11 + S.12 + B.5n S.13 + B.5n S.15 + CCF + renta primaria neta pagada al exterior + vintage BIE−CSI**: filas de sector sin edad (CSI 2024: S.11 + S.12 953.904; S.13 1,594.102 = D.2 − D.3 2,431.022 + D.4 neto −836.920; S.15 116.767; exterior 936.500 = D.4 pagada 1,350.775 − recibida 361.554 − D.1 recibida 52.721; D.442 605.932; vintage 83.348 = 84.124 en B.1b − 0.776 en CCF) → «Otros sectores» → `Ing nacional`; cierra a 1e-9 (gate de `Households.do` §9.1). `output.txt` gana la llave `CUADRATURA` (10 valores en % del PIB; `gate-numeros` la compara byte a byte). El uso «Ing a la propiedad → El mundo» pasa a «Renta primaria al exterior» (−ROWProp − ROWRem). `SCN.ado` lee de los tabulados CSI las celdas nuevas (D.1, D.442, D.752, D.5, D.7 de S.14; B.5n de S.11, S.12, S.13, S.15; D.2, D.3, D.4 del gobierno; D.1 y D.4 del resto del mundo; B.1b, P.51c y B.5n de S.1) y las deja como escalares.
- **Comandos — `refrescar-scn.sh --congelar` (E4, CUAD-0 §4 bis pasos 6–7).** Escribe los assets congelados del SCN en `raw/SCN/` (`bie/<serie>.csv` con los años ≤ `anioenigh`: las 93 series del inventario, `--todas` las 525; los 7 cuadros `CSI_1xx.xlsx`) y los registra en `manifest.json: scn_vintage` (fecha de consulta 2026-10-31, año de referencia 2024, por serie sha256, n, etiqueta INEGI del último dato y vía; por cuadro sha256 y las 49 celdas del inventario con su valor). `SCN.ado` (`SCNCongelado`, en `SCN`, `UpdateSCN` y `SCNHogaresS14`) y `AccesoBIE.ado` verifican el sha256 y leen el asset sin red (sello **verde**); sin asset descargan y lo declaran (amarillo); sha distinto aborta (candado). Corrida real: 93/93 series y 7 cuadros iguales a lo congelado el 16-oct (API oficial HTTP 400 con el token: vía exportación pública, declarada); las series traen 2025 p1, fuera del año de referencia, no incorporado. `raw/SCN/` no se versiona: `--congelar` empaqueta `raw/SCN/scn-congelado-2024.zip` (631,619 bytes, sha256 `2b578e55…`) y lo declara en `assets` del manifest con `desde: v8.15.0`; `publicar.sh` lo sube al publicar esa versión y su Gate 8 no lo exige en Releases anteriores (campo `desde`, nuevo); `SCNCongelado` lo descarga con `ensure_asset` y lo desempaca en una máquina sin `raw/SCN/`.
- **Institucional — `baseline = v8.15.0`** en `manifest.json` (Gate 11 lo avisa como posterior a v8.14.0 hasta el bump; el sidecar lo copia). CUAD-0: §4 firmado, §5 Tabla 1 con «Obtenido 8.15b», §7 gates nuevos, §8 FLAGs 1–9, 11, 12, 16 cerrados, 10 declarado, 18 nuevo (rentas), §10 bis con los párrafos literales del SNA 2008 (§7.9, §7.19c, §7.21, §24.6, §24.7, §24.55), INEGI (CSI base 2008 p. 33, CSI 2003) y CSVM 2024 con URL. `/NTA`: nota 2 y los textos del hub, OyE y YA con las cifras nuevas (spans del motor).
- **Δ real vs Δ esperado de CUAD-0** (v8.14.0 → v8.15.0; el memo suponía `oye_en_hub = on` y D.442 dentro de YA; la firma cambió ambos):

| Agregado | v8.14.0 | Esperado CUAD-0 | Real v8.15b | Δ real | Real − esperado | Por qué |
|---|---:|---:|---:|---:|---:|---|
| `Yl` del motor (bn) | 15,129.128 | 14,690.951 | 14,690.951 | -438.177 | +0.000 | YL = D.1 + ⅔ B.3n al peso: el memo acertó |
| `Yk` del motor con CCF (bn) | 16,936.071 | 15,289.899 | 14,683.967 | -2,252.104 | -605.932 | memo: 8,832.323 + CCF; firma 11 saca D.442 (−605.932) → 8,226.391 + CCF |
| YL de NTA (bn) | 13,603.690 | 14,690.951 | 14,690.951 | +1,087.261 | -0.000 | ídem Yl |
| YA base de NTA (bn) | 8,832.323 | 8,832.323 | 8,226.391 | -605.932 | -605.932 | YAHogS14 − D.442 (firma 11); factor 1 exigido |
| Hub `Ing nacional` (bn) | 28,863.765 | 28,349.202 | 27,743.270 | -1,120.496 | -605.932 | memo con oye_en_hub=off: 28,349.202; además D.442 fuera de YA (−605.932) |
| Σ S sin ancla (bn) | 1,634.816 | 2,116.145 | 2,116.145 | +481.329 | -0.000 | memo con cuotas_d614=neto: 2,116.145 |
| Brecha vs B.8n (%) | -14.003 | 11.300 | 11.316 | +25.319 | +0.016 | memo con neto: +11.3 % |

  Hub `Ing nacional`: 85.733 → **82.405 % del PIB**; `Gobierno` 21.866 (igual: OyE sigue entrando, ahora de «Empresas públicas»); factor YA 1.1938 → **1.000000**; ancla de S multiplicativa en ambas (factor 1.1628 → 0.8983: el ajuste pasa de fuente +266.2 a sumidero −215.1 bn). Signos: Yl −438 porque D.1 + ⅔ B.3n (14,690.951) es menor que el RemSal + CSS + impuestos + ⅔ mixto embebido de v8.14 (15,129.128); YL de NTA +1,087 porque ya no se restan pensiones ni transferencias de mixto; Yk −2,252 = −1,646 del memo (sin ExNOpSoc residuo ni impuestos embebidos) − 606 de D.442; hub −1,120 = −515 del memo con `oye_en_hub=off` − 606 de D.442; Σ S +481 = +1,087 de YL − 606 de D.442 (el memo con `cuotas_d614=neto` lo predijo al peso: 2,116.145). Σ x·factor del motor: `ing_subor` 10,113.216 → 10,052.962; `ing_mixto` 7,523.869 → 6,956.984; `ing_capital` 6,855.782 → 4,997.037; `ing_estim_alqu` 1,114.756 → 910.359; `ingbrutotot` 26,793.714 → 24,103.433.

- **Conocido / no entra (firma C y decisiones de Ricardo del 2026-10-31):** base del ISR PM = negocios propios (`ing_bruto_tpm`): no es correcto, los negocios propios tributan como PF y el ISR PM es de sociedades con incidencia ∝ `d4_relativo` (regla P de la Tabla 2); FLAG declarado, se corrige en 8.16 (ISR_Mod/TasasEfectivas). FLAG 18 (B.2b > alquiler imputado, +221 bn, de contenido) abierto; brecha residual de S (+11.3 %: D.5 LIF vs devengado, τ⁺ efectivo vs D.62 + D.7, Cpriv vs P.3 → Expenditures/TasasEfectivas 8.16), top incomes (9.x), informalidad (8.16), excedente retenido a personas (8.17), `/metodo`. ISR del motor: con la base nueva (`ing_bruto_tax` con honorarios y rentas íntegros, `ing_bruto_tpm` = negocios) el ISR total sigue anclado a la LIF por el cut-off, pero su distribución cambia (ISR_asalariados 1,337.390 → 1,424.327, ISR_PF 77.036 → 75.413, ISR_PM 1,351.275 → 1,351.117 bn).

Sesión v8.15a: memo e higiene del ritual. **Ningún `.do`/`.ado` ni número publicado cambia** (`gate-numeros.sh` verde; sin bump de manifest).

- **Institucional — CUAD-0.** `02_governance/CUAD-0.md`: capítulo `Households` del método en v8.14.0 y columna «propuesto 8.15» (Tabla 1 principio C, Tabla 2 principio B, parámetros, política de fuente SCN, campo `baseline`, Δ esperado). Es insumo de 8.15b, pendiente de firma.
- **Institucional — `02_governance/metodo/`.** `plantilla-capitulo.md` y `cap0-requerimientos.md` (borradores de Ricardo; plantilla y cap0 con cinco correcciones de Ricardo) y README de la carpeta. CUAD-0 queda escrito en esa plantilla.
- **Comandos — `contrato-32.py --refs`.** Acepta `sankey-*.json` planos o `SankeySF/`. Una referencia que falta es «referencia ausente: <ruta>» y hace FALLÓ, con mensaje distinto de «difiere».
- **Comandos — `gate-numeros.sh`.** Acepta `sankey-*.json` planos o `SankeySF/`. Un archivo que falta es «ausente: <ruta>» y da NO EVALUABLE (exit 2), ya no «los números cambiaron»; si además algún número difiere, sigue siendo ROJO (exit 1).
- **Comandos — `publicar-vps.sh`.** La pregunta del cutover y la línea de rollback van a `/dev/tty` (sin tty, a stdout), para que `| tee | grep` no las esconda. `publicar.sh` no tiene prompts interactivos.
- **Institucional — Runbook.** §14 «Lecciones del ritual v8.14.0»; §4b anota que `crear-deployment` ya está instalado.

Sesión v8.15b-pre (2026-10-31): infraestructura de Cuadratura y diagnósticos, **sin mover un número** (`gate-numeros.sh` verde contra `-datos/users/ricardo`; `output.txt`, los 10 sankeys y las 32 entidades byte-idénticos a v8.14.0; sin bump de manifest). Ninguna de las nueve decisiones abiertas de CUAD-0 (3, 7–13) entra; eso es 8.15b con el memo firmado.

- **Institucional — convención `baseline` (CUAD-0 §4 ter, decisión 14).** `05_scripts/manifest.json` y el sidecar `manifest-datos.json` llevan `baseline`: el tag desde el que los números publicados son comparables con la versión. **Para v8.14.0 y anteriores el baseline es `v8.12.4`** (última corrección de datos; desde ahí `output.txt`, los 10 sankeys y las 32 entidades comparan). Se mueve solo con una corrección de datos o un re-anclaje declarado de `gate-numeros.sh`, y entonces esta línea dice «a partir de vX los números no comparan con ≤ vY por …». **Gate 11** de `publicar.sh` (`--check` y `--ci`): el campo existe, es un tag (local u `origin`) y no es posterior a la versión; obligatorio desde v8.15.0, informativo antes. `publicar-vps.sh` Fase 4 escribe `Baseline:` en `DEPLOYED_COMMIT` y `health.php` lo muestra (o «n/d» en deploys anteriores). README «Cómo citar» lo explica.
- **Comandos — `05_scripts/refrescar-scn.sh --comparar`** (política de fuente SCN, CUAD-0 §4 bis). Descarga del BIE las series del inventario (API oficial con el token de `set_token.do`; si la API no responde, la consulta pública de exportación del BIE, el mismo respaldo de `AccesoBIE.ado`, y lo declara por serie: el 2026-10-31 la API devolvió HTTP 400 con el token configurado y las 93 series se compararon por la exportación pública) (las ~93 que llegan a un escalar que algún módulo lee; `--todas` las 525 de `UpdateSCN`; `--csi` baja además `tabulados_CSI.zip` y compara sha256 de los cuadros y las filas del inventario), calcula sha256 de lo congelado (`raw/temp/AccesoBIE/<serie>.csv`; respaldo `master/SCN.dta`) y de lo descargado, y emite celda, valor congelado, valor BIE, Δ, Δ % del PIB, etiqueta INEGI (`OBS_STATUS`/`OBS_NOTE`, `LASTUPDATE`) y fecha de consulta. El año de comparación es `anioenigh` del motor (leído de `SIM.do`; `--anio` lo sobreescribe), sin escalar nuevo: las series con años posteriores se listan como «fuera del año de referencia», no como revisión ni como años nuevos. **Solo compara**: no escribe en `raw/` ni toca el manifest; exit 0 sin revisión, 1 con diferencias, 3 no comparado (sin token o sin respuesta del BIE: «no comparado» no es «sin revisión»). `--congelar` queda documentado y **deshabilitado hasta 8.15b**.
- **Institucional — `02_governance/scn-celdas.md`.** Inventario de las celdas del SCN que lee hoy el motor: 93 series BIE con consumidor (serie, variable, bloque, valor 2024, quién la lee, fecha del csv), las 33 filas de los tabulados CSI que el BIE no tiene como serie (cuadro, fila, columna U/A–R/P, código SCN), los escalares derivados con su fórmula y la brecha frente a §4 bis (nada congelado como asset; vintage BIE vs CSI).
- **Comandos — tres parámetros de Cuadratura con default = v8.14.0** (`SIM.do` §0.8; validados en `Households.do` §0.0; FLAG en el header de `Households.do`): `pensiones_en_yl` ∈ {on, **off**} (off: `ing_jubila` fuera de `ing_t4_cap1`/`exen_t4_cap1`, y `NTA.do` deja de restarlas), `yk_ancla` ∈ {actual, **b2n_b3n_d4**} (alterno: `TaltimirCap` a D.4 neto S.14 y `TaltimirHouse` a B.2n S.14, CSI_115 f.95 y f.69), `cap4` ∈ {dentro, **fuera**} (fuera: `ing_t4_cap4` sale de `ing_mixto`, sigue en `ing_bruto_tax`). Las ramas alternas corren sin error; sus Δ (Yl, Yk, hub, Σ S) están en el PR como insumo de la sesión de revisión, no se publican. Un valor fuera del default imprime FLAG y deja los números fuera del baseline.
- **Institucional — header de `Households.do`.** Sección 9 «Específico de México» de la plantilla de capítulo (los cinco renglones de CUAD-0 §9), más los FLAGs de los tres parámetros. Texto, sin cambio de código.
- **Diagnósticos de solo lectura** (en `diag-v8.15b-pre-2026-10-31/`, no en el repo): catálogo ENIGH 2024 de P001–P009, P032, P036, P068–P081 contra el descriptor oficial; remesas con doble escalado y `cap3PM` negativo cuantificados; informalidad de asalariados (deciles de *p*, umbral, concentración, Σ obligación, Σ p×obligación, λ) y los tres conteos de formales. Resultados en el PR.

## [v8.14.0] — 2026-10-30 — Pulido, docs y auditoría DoD: la última antes de v9.0.0

Sesión de cierre sobre `master` con #47 (y #48: comentarios de `SIM.do`). **Nada metodológico nuevo**; la Cuadratura es
9.1+.

### Conocido

- **Remesas.** Remesas en Households/ciclo de vida están escaladas dos veces (`TaltimirSelf` y factor propio): 2,057.1 bn publicados vs 1,188.5 bn con un solo factor; NTA usa 1,186 y no está afectado. Se corrige en 8.15b con baseline nuevo. (Cuantificado en el diagnóstico 4b de #52: 141.526 bn crudos × 8.3807 en `ing_remesas` + × 6.1543 dentro de `ing_mixto`.)

### Segunda entrega (PR v8.14b, mismo tag; puntos 13–17)

- **13 Corte de datos citable.** `publicar.sh` gana la fase *data sidecar* (antes de crear la Release): empaqueta desde
  `users/ricardo/` del worktree de publicación `output.txt`, los 10 sankeys, `NTA/*` (los JSON y el reporte; **sin** el
  microdato `nta-persona.dta`: el zip es de salidas publicadas y el microdato se reproduce con la receta de DoD 1),
  `SankeyNTA/sankey-v3-grupoedad.json`, las 32 carpetas `<ABREV>/` (catálogo de `SIMentidad.ado`) y `entidades.json` +
  `entidades-pibe32.json` en `users/_sidecar/<versión>/datos-<versión>.zip` (306 archivos, 3.7 MB sin comprimir, zip
  ≈ 1.2 MB; reproducible) con
  `manifest-datos.json` (sha256 y bytes por archivo, `version`, `commit`, `data_updated`, la cita sugerida y el bloque
  `vintages` **tal como los registra el motor**: `enigh_vintage`, `cache/sello.txt`, procedencia y anclas de
  `nta-grupoedad.json`, `base_generada` de los `.meta` del PIBE, vintages de la banda del Sankey NL). Los dos suben a la
  Release como assets y se verifican por digest sha256 como los 26 crudos. **Gate 9**: `--check` y la publicación exigen,
  desde v8.14.0, que el sidecar exista y cuadre (manifest ↔ zip ↔ `users/ricardo`); se omite en `--ci`.
  **`CITATION.cff`** en la raíz (CIEP como autor institucional, Ricardo Cantú Calderón; versión y fecha leídas del manifest;
  cita «CIEP (año). Simulador Fiscal CIEP vX.Y.Z, datos al `data_updated`. URL de la Release»), regenerado con
  `publicar.sh --citation` y exigido por el **Gate 10** (también en `--ci`). Sin Zenodo. Runbook §4c; README «Cómo citar».
- **14 Sankey v3 sin cruces innecesarios.** `NTA.do` §7b ordena cada eje por (rango del origen, rango del destino) con
  `_nta_v3rank`: col. 1 El mundo, grupos de edad, OyE públicas, Desahorro, Otras transferencias privadas, Déficit público,
  Ajuste S14 (si es fuente); col. 2 Remesas, Impuestos a productos, Ing capital, Ing laboral, Alquiler propio, Derechos de
  pensión D8; Ing nacional; Gobierno, Activos; Transferencias en efectivo, Colectivo, Futuro; categorías Alimentos,
  Vivienda, Transporte, Salud, Educación, Vestido, Otros gastos; grupos consumidores. `SankeySumSim` emite los nodos por
  primera aparición y los enlaces en el orden de las filas, y **FusionCharts respeta el orden del arreglo `nodes` dentro de
  cada columna** (verificado con la captura de `test-sitio-nta.sh --png`; no hace falta atributo de la librería): Remesas
  entra al hub por arriba, Alquiler propio y D.8 por abajo; Gobierno sobre Activos. Ningún valor cambia: el fixture del v3 se
  refresca solo por orden (mismo conjunto de 99 enlaces con los mismos `value`/`pctpib`), el v2 no se toca.
- **15 `/NTA`, nota 2 con las cifras post-§4.3**: hub 85.7 % del PIB (81.6 + 4.8 + 3.8 + 0.6 + 1.7 − 2.8 − 0.3 − 3.2 − 0.3),
  Σ S sin ancla 1,634.8 bn, brecha −14.0 %, ancla multiplicativa (factor leído del motor) dibujada como fuente de
  +266.2 bn, y la línea que explica el cambio de signo respecto al memo CONC-1 (los ⅔ de `ImpNetProductos_mixK` salen de
  YL; YA, re-anclado a S.14, absorbe; el ingreso total baja 331.7 bn; la brecha laboral YL vs D.1 + ⅔ B.3n es la Cuadratura
  9.1).
- **16 `data_updated` → 2026-10-30** (criterio v8.12.4: cambiaron números publicados). El sello de `users/ricardo/cache` lo
  escribe `Precache` con esta fecha en la corrida del ritual.
- **17 Bases de vintages.** `cmp` de las cinco `users/ricardo-v{2016..2024}/aportaciones.dta` de la receta contra las del
  8-oct (`SimuladorCIEP-NL`, motor v8.8.1): **las cinco distintas**, así que la receta es la verdad: se instalan en
  `-datos/users/` y la banda de los Sankeys de entidad se regenera con ellas. Δ: misma N y mismos totales nacionales de
  las nueve familias en los cinco vintages (byte a byte en los totales); las participaciones de NL se mueven en el
  segundo decimal por las correcciones del motor desde v8.8.1 (AlTrabajo: 2016 7.884 → 7.864 %, 2018 7.535 → 7.594,
  2020 8.952 → 8.927, 2022 9.204 → 9.181, 2024 sin cambio; AlCapital: 2016 41.635 → 41.674, 2018 7.889 → 7.897,
  2020 10.014 → 10.027, 2022 4.640 → 4.644, 2024 14.151 → 14.121; AlConsumo, Educación, Transferencias e Inversión
  sin cambio a tres decimales). `Salud` y `Pensiones` siguen en cero en ambas (límite heredado, runbook §13). Los
  fixtures de `entidades/*` (NL, Jal, Col, índice) se refrescan con la corrida que lleva la banda nueva: los `value` de
  los enlaces, el ciclo, las tasas, el neto y los sellos no cambian respecto a #49; solo `bmin`/`bmax` (mediana Δ 0; máximos
  de 4–20 % en celdas delgadas de un vintage: NL quintil 3.8 %, Jal grupoedad 20.5 %, Jal rural 13.8 %, Col quintil 6.0 %;
  tabla completa en el PR). Nota sobre #49: los fixtures de `entidades/*` que cambiaron ahí difieren solo en metadatos (`generado_el`,
  `commit`, `vintage` del PIBE), no en valores (≤ 2.5e-15, último bit).

### Primera entrega (PR #49, puntos 1–12)

Un commit por punto (rama `sesion/v8.14`); evidencia en `~/CIEP_Simuladores/diag-v8.14-2026-10-30/` (tres corridas
completas de `SIM.do` + `contrato-32.sh`, StataNow 19.5 SE, 1 procesador; r1/r2 31 min cada una). Solo dos puntos tocan
números publicados y ambos los declaran: el **4** (sort del último bit: 0 líneas de `output.txt`, 11 JSON byte-idénticos entre
caminos) y el **7** (NTA §4.3: la cuenta NTA y `/NTA`). El baseline del gate de números se re-ancla en un commit propio
(`baseline: v8.14.0`): `output-default.txt` cambia solo en las tres líneas de formato del FLAG-5; los 10 sankeys se refrescan a
la corrida (Δ rel. máx 3.0e-14 frente a v8.12.4).

### Correcciones — FLAG-5 cerrado: el «Calcular» default reproduce el `output.txt` del batch (punto 1)

- **`01_modulos/output.do`** imprime `CRECPIB`/`CRECDEF` con `%12.0g` y `DEUDAPARAM` (tasa efectiva) con `%20.0g`: lo que el
  sitio devuelve a `Web.Stata.do` como `{{CRECPIB*}}`, `{{CRECDEF*}}` y `{{DEUDA0}}` ya no llega redondeado (1.4 → 1.4127;
  6.667 → el double completo). **`Web.Stata.do` §7** llama a `Simulador` exactamente como `SIM.do` §7.3 (`if AportacionesNetas
  != 0`, `bootstrap(1)`, `title("")`). **`ISR_Mod.do`** suma `infonavit` una vez a `cuotasTPF` como `Households.do` l. 1547
  (FLAG 2 de v8.12.4) y `PerfilesSim.do` conserva `infonavit` en `perfiles<anio>.dta` para que el submódulo lo lea. `SIM.do` es
  canónico; el web se alinea. En `output.txt` solo cambian las tres líneas: `CRECPIB:[1.4127,1.9983,2,2,2,2,2]`,
  `CRECDEF:[3.8,4,4,4,4,4,4]`, `DEUDAPARAM:[6.66715858753942836]` (mismos números, sin redondeo; el formulario del sitio los
  pinta tal cual).
- **Gate nuevo `05_scripts/test-web-batch.sh`** (sesión, Stata): arma el escenario default desde `users/ricardo/output.txt` como
  lo hace el JS, genera el `.do` del web como `calculaStata.php`, lo corre y compara las **46 llaves** de `output.txt` como
  cadena. **Medido: 46/46 idénticas** (antes 5 de 46 diferían: `GASTOSPC`, `INCD`, `PIBY`, `PROYSHRFSP2/3`); 15 s de pared.

### Institucional — receta ejecutable de las bases de la banda (DoD 1, punto 2)

- **`05_scripts/vintage-aportaciones.do`** (nuevo, motor intacto): `SIM.do` §0–§5 y §7 con `anioPE = aniovp = anioenigh = t`
  (calibración contemporánea: sin los escalares del Paquete de §4.1/§5.1, `TasasEfectivas` toma LIF `t` y `GastoPC` el PEF
  `t`; `bootstrap 1`; sin NTA, Precache, SHRFSP ni §8), `id = <usuario>-v<t>`, compuerta final con las variables que lee la
  banda. **`test-maquina-virgen.sh --download --vintages "<t …>" [--into <raíz>]`** lo corre por vintage (los assets que falten
  los baja `ensure_asset` de la Release) e imprime el tiempo. Sustituye la clonación a mano desde `SimuladorCIEP-NL` (FLAG #26).
  Prueba punta a punta en worktree limpio y tiempos: PR de la sesión (sección «vintages»).

### Institucional — candado del ritual (punto 3)

- `publicar.sh` (también `--check`; omitido en `--ci`) y `publicar-vps.sh` (también dry-run) **abortan** si hay una corrida viva
  (`pgrep`: `correr-sim.sh`, `contrato-32.sh`, `compuertas-entidad.sh`, `pibe-32.sh`, `test-maquina-virgen.sh`,
  `vintage-aportaciones`, cualquier `stata-se|mp -b`) o si el `wrap*.log` / `SIM*.log` más reciente bajo `SIM_EVIDENCIA`
  (default `~/CIEP_Simuladores`) o en la raíz del repo **no termina en «end of do-file»**. Sin bandera para saltarlo. Runbook §10.4.

### Correcciones — el último bit (punto 4)

- `Households.do` §3: `sort folioviv foliohog numren id_trabajo clave` antes del `collapse` de `ing_tri` y `id_trabajo` en el
  sort siguiente (FLAG del memo REPRO-1 / PR #43). Dos corridas completas por los dos caminos (`master/SCN.dta` enriquecido vs
  18 series S.14 borradas): **`output.txt` y los 11 JSON byte-idénticos**; la cuenta NTA idéntica salvo `generado_el`. Frente al
  baseline v8.12.4, 0 líneas de `output.txt` (las 3 que cambian son las del FLAG-5).

### Datos — testigo NL regenerado con el motor actual (punto 5)

- `compuertas-entidad.do` §2 escribe las 90 celdas `dis<fam>nle<dec>` también como testigo JSON (`ciep.testigo.entidad-nl/v1`,
  procedencia con commit y año) y la referencia se **versiona** en `05_scripts/fixtures/statajson_entidad-nl.json`
  (corrida r3 de esta sesión); `contrato-32.sh` y `compuertas-entidad.sh` la leen por default. El testigo del sprint NL
  (2026-10-08, motor v8.8.1) quedó obsoleto con v8.12.4 (reldif 6.6e-2). Gate 3 de `compuertas-entidad.py`: ver PR.

### Institucional — higiene (punto 6)

- Los 32 `master/PIBDeflactor<ABREV>.meta` del sello pibe-32 viven junto a sus `.dta` (en `-datos/master/`; eran
  `sellos/<ABREV>.meta` en la carpeta diag): `generar-entidades.py meta` lee de ahí el vintage del PIBE y **`--pibe-vintage` se
  retira** de `generar-entidades.py` y `contrato-32.sh`. `.gitignore`: `__pycache__/` y `*.pyc` (+3 casos en
  `verify_gitignore.sh`, 88/88). `sitio-entidades` pasa a check requerido de branch protection (comando `gh api` en el runbook
  §11 y en el PR; lo ejecuta Ricardo).

### Correcciones — NTA §4.3: los impuestos a los productos embebidos salen de donde viajan (punto 7)

- `ImpNetProductos_mixK` (497.6 bn en 2024) es el impuesto neto a los productos que Altimir embebe en **todo** `ing_mixto`, que
  el motor reparte ⅔ a `Yl` y ⅓ a `Yk`. `NTA.do` restaba de YA los 497.6 completos y YL conservaba 331.7 bn de impuestos además
  de recibir `ImpProd` (CONC-1 línea 13 / §6.1). Ahora **YA resta ⅓ (165.9 bn) y YL resta ⅔ (331.7 bn)**; escalares
  `NTAImpProdMotorYA`/`NTAImpProdMotorYL`; `nta-identidad.txt` y `nta-grupoedad.json` (`impuestos_productos`) declaran el reparto.
- **Δ declarado (2024, bn MXN):** YL 13,935.4 → 13,603.7; YA del motor 7,066.9 → 7,398.6 (re-anclado a 8,832.3, igual; factor
  1.2498 → 1.1938); Σ S sin ancla 1,966.5 → **1,634.8** (brecha vs B.8n +3.4 % → **−14.0 %**, dentro del 15 %: `nta_anclaS = auto`
  sigue resolviendo a multiplicativo, factor 0.9667 → **1.1628**); el ajuste S.14 pasa de recorte neto −65.5 a **complemento neto
  +266.2** (recorte 9.6, complemento 275.8): el nodo «Ajuste a cuentas nacionales S14» del v3 es ahora **fuente** hacia Activos
  (−0.79 % del PIB); hub «Ing nacional» 86.72 → **85.73 % del PIB**; Gobierno 21.87, Activos 6.87, Transferencias en efectivo
  10.23. El v3 sigue en 35 nodos / 99 enlaces; `test-nta-identidad.sh` VERDE (identidad 4e-18, anclas S.14 por construcción);
  `test-sitio-nta.sh` VERDE. Fixtures NTA (`nta-grupoedad.json`, `nta-identidad.txt`, `nta-panel-grupoedad-sexo.json`,
  `sankey-nta-grupoedad.json` = v3) refrescados. `output.txt` y los 10 sankeys publicados **no cambian** (el Sankey NTA v1 de la
  portada no lee `NTA.do`).

### Institucional — `/NTA` dice lo que es (punto 8)

- Las cinco frases de CONC-1 §5: el hub es **«household-side income»**, no «national income» (texto de método, definición del
  nodo, cabecera de columna «Household income hub (% of GDP)», párrafo de unidades, lista de hubs). **Nota 2** con el puente al
  81.6 % del INBD: añade OyE +4.8, D.8 +3.8 y desbalance ENIGH +0.6; deja fuera excedente retenido de sociedades −2.8, gobierno
  sin impuestos a productos +1.7 (es negativo), ISFLSH −0.3, brecha laboral −2.2 y vintage −0.3 → 86.7 al corte del memo; y
  declara que desde esta versión (§4.3) la brecha laboral absorbe ~1.0 punto y el hub baja lo mismo (la cifra impresa es la del
  motor). La etiqueta `Ing nacional` **no** se renombra (cambio de contrato: 35 etiquetas, fixtures, test).

### Documentación (puntos 9–12)

- `Households.do`: header y bloque «Sankey: PIB demográfico» declaran el reparto intra-hogar por `perfilpc` (no per cápita);
  `Distribucion.ado` es per cápita solo con `relativo(pob)` (FLAG de v8.12.5).
- Runbook §10 (el cuarto árbol `-datos`; §10.4: baile obligatorio, tag al hash explícito, versión de deployment, candado, de
  dónde salen los números), §11 (gates de sesión: `gate-numeros`, dos caminos, `test-web-batch`, `test-nta-identidad`,
  `contrato-32`, vintages, `--png`; por qué el veredicto de `test-sitio-transitorios` lo da CI; nueve checks + `gh api`) y §13
  (receta de vintages, testigo versionado, `.meta` en `master/`).
- `Distribucion.ado`: se **documenta**, no se retira (siete módulos lo invocan). El «gemelo» era documental:
  `03_help/PROGRAMAS_AUXILIARES.md` §3 describía un programa Gini/Theil que nunca existió (corregido) y hay una copia idéntica
  sin versionar en `.devin/backups/`.
- CHANGELOG sin `[Unreleased]` huérfano: NTA-1/1b/1c y la página `/NTA` v1 quedan bajo v8.12.5; v8.13a y v8.13a-2 bajo v8.12.4
  (el tag es un punto de `master`). README: las dos secciones de método (`/NTA`, `/entidades`), los memos y `NTA.do`.
  `manifest.json` → v8.14.0 (en #49 `data_updated` se dejó en 2026-10-29; la segunda entrega lo bumpea a 2026-10-30 con el
  criterio de v8.12.4: punto 16).

## [v8.13.0] — 2026-10-29 — Andamiaje 32: template estatal

El sitio gana una página por entidad federativa, **/entidades/<ABREV>** para las 32, y el índice **/entidades** (PR
v8.13b). El motor de cifras **no cambia** ningún número: lo que se publica es lo que contrato-32 ya emite por entidad
(v8.13a, `02_governance/contrato-32-2026-10-19.md`) más dos exportaciones nuevas en Stata (abajo) y el sitio solo lo
lee. **Regla sostenida: ningún número de la página nace fuera de Stata.** Decisiones de Ricardo (29-oct): las 32
iguales, con sellos; los cuatro productos; 32 páginas estáticas generadas; precalculado en el deploy; índice en tabla,
sin mapa; reúso de `metodo/plantilla.php`; inglés.

### Institucional — generador, páginas, endpoint

- **`05_scripts/generar-entidades.py`** (nuevo). `paginas`: desde `SIMentidad.ado` (única fuente del catálogo) escribe
  `entidades/_catalogo.php` y las 32 `entidades/<ABREV>/index.php`, cada una un stub de tres líneas que fija
  `$ENTIDAD_ABREV` y carga la plantilla única `entidades/_entidad.php` (las 32 iguales por construcción); idempotente y
  determinista; `--check` es el gate «generado == commiteado» (CI). `meta`: lee `users/<id>/<ABREV>/{sankey-*.json ×5,
  ciclo-vida.json, tasas-efectivas.json}` y `contrato-32.tsv` y escribe `users/<id>/<ABREV>/meta.json` (esquema
  `entidad-meta/v1`: cada celda sellada con su `n` y su top-1 por producto, conteos, top-1 en celdas no delgadas, PIBE y
  neto del ciclo, espejo, procedencia) y `users/<id>/entidades.json` (`entidades-indice/v1`: la tabla de las 32).
  `contrato-32.sh` lo llama al final del recorrido (`--pibe-vintage`). El generador **transcribe, no calcula**: el
  neto del ciclo como % del PIBE, el PIBE y el neto se copian de `neto-pibe.json`; la suma de los 32 PIBE, su
  discrepancia y el neto nacional / PIB se copian de `entidades-pibe32.json`. Los sellos **no se cablean**: la página
  los lee de ahí.
- **`entidades/_entidad.php`** (plantilla de método reutilizada: cabecera con migas, notas numeradas, pie). Orden:
  encabezado (nombre, clave INEGI, n ENIGH, población, vintage, corrida) → párrafo de método en inglés (qué es por
  entidad: §1–3, Sankeys y ciclo §7–8.2, tasas efectivas micro/micro por residencia; qué es federal: parámetros, deciles
  nacionales, anclas SCN sin apertura estatal, ISAN/IMPORT a tasa nacional por construcción; qué está anclado a qué: PIBE
  por entidad con su vintage, PIB nacional de la corrida) → los cuatro productos, cada uno con gráfica y lectura:
  (i) los **cinco Sankeys de aportación** con selector de corte (quintil estatal, grupo de edad, sexo, rural, escolaridad;
  FusionCharts como la portada, un corte por petición, cacheado), (ii) el **ciclo de vida quinquenio × sexo** (ApexCharts,
  la receta de «Tax burden by age» de la portada: barras horizontales apiladas por grupo de deciles, % del neto de la
  entidad), (iii) las **tasas efectivas por impuesto** sin renglón ISAN/IMPORT (SVG propio, como el panel NTA: la portada
  solo tiene PNG; barra = entidad, marca = nacional micro), (iv) el **neto del ciclo como % del PIBE** (cifras + dos
  barras SVG, entidad vs nacional) leído de `neto-pibe.json` (ajuste de Ricardo: nada se divide en Python) con nota al
  pie de la discrepancia Σ32 PIBE vs PIB nacional (informativa). **Sellos**:
  toda celda con n < sello_n o top-1 > sello_top1 lleva marca ⚠ en la gráfica (toolText y lista bajo el Sankey, «⚠» en
  la etiqueta del quinquenio, rayado en la barra de la tasa) y **nota al pie numerada** («n = 73 in this cell; read as
  indicative»), continuando la numeración de las cinco notas de método. Pie: fuente, versión, data_updated. La página
  NL lleva una línea fija, sin enlace: «Nuevo León also has a dedicated mirror (SimuladorCoNL) maintained with
  Consejo Nuevo León; available on request.» (decisión de Ricardo; sin parámetro de URL).
- **`entidades/index.php`**: tabla de las 32 (número, nombre, abreviatura, n ENIGH, celdas por debajo del umbral,
  celdas selladas Sankeys / ciclo / tasas, concentración top-1 en celdas no delgadas, neto/PIBE, enlace), filas del
  catálogo y columnas leídas de `entidades.json`.
- **`jsonEntidad.php`** (nuevo): `?abrev=<ABREV>&producto=sankey|ciclo|tasas|neto|meta[&corte=…]` y `?producto=indice`;
  sirve byte a byte ciclo, tasas, neto (`neto-pibe.json`), meta y el índice; el Sankey con los nodos y enlaces del motor tal cual
  (claves entrecomilladas con la misma gramática que `compuertas-entidad.py`, `toolText` de sello en los enlaces con
  `sello=1`); **abrev estricto** contra el catálogo generado (minúsculas, clave numérica, traversal y `%00` → 400),
  producto y corte en lista blanca (400), idSession inválido → default `ciepmx`, archivo ausente → 404 con la pista del
  deploy. `js/entidad.js` (nuevo), `metodo/plantilla.php` (sección «States», migas, `scripts`/`init`), `css/metodo.css`.
  **Cero literales numéricos** en PHP/JS/CSS (gate de 4+ dígitos sobre los nueve archivos y las 32 páginas).
- **Stata (v8.13.0, ajuste de Ricardo: el neto/PIBE nace en Stata).** `01_modulos/visualizations/CicloEntidad.do`
  registra en el registro escalar (`escalar.ado`) `NetoCiclo<ABREV>`, `AportaCiclo<ABREV>`, `RecibeCiclo<ABREV>`,
  `PobCiclo<ABREV>` y `NetoCicloNac` (los mismos valores que escribe en `ciclo-vida.json`; **ningún número cambia**:
  `gate-numeros.sh` verde, paridad byte-idéntica). `05_scripts/contrato-32.do` §4b: `escalar pctpib NetoCicloPIBE<ABREV>
  = NetoCiclo<ABREV>/pibY<ABREV>*100` (solo con base PIBE) y exportación con `scalarjson` a
  `users/<id>/<ABREV>/neto-pibe.json` (serie de una fila: `saldo_nominal` = neto, `saldo_pib` = % del PIBE, `poblacion`;
  escalares NetoCiclo, Aporta, Recibe, Pob, pibY y NetoCicloPIBE con su tipo; metadatos de unidad/criterio/fuente);
  al final del recorrido `pibYSum32`, `pibeDiscrepancia32` y `NetoCicloPIBNac` a `users/<id>/entidades-pibe32.json`.
  La columna `neto_rc` se suma a `contrato-32.tsv`.
- **Deploy.** `publicar-vps.sh`: la Fase 3b-ter embarca `users/ricardo/<ABREV>/` para las 32 (5 Sankeys + ciclo + tasas +
  `neto-pibe.json` + `meta.json` = 288 archivos; catálogo leído de `SIMentidad.ado`) y `entidades.json` (manifiesto 12 → 301); Gate 5-remoto
  exige `users/ciepmx/<ABREV>/meta.json` de las 32 y el índice; el esqueleto suma `/entidades` y las tres páginas muestra
  (NL, Jal, Col); la Fase 6 hace un HEAD a `jsonEntidad.php?abrev=<ABREV>&producto=meta` para las 32. Precondición del
  ritual: `contrato-32.sh` (que ya corre `generar-entidades.py meta`) antes del tag. `manifest.json` → v8.13.0.
- **Gates.** `test-sitio-entidades.{sh,js}` (nuevo; job `sitio-entidades` en CI): generado == commiteado; 37 PHP parsean y
  hay 32 carpetas; HTTP (índice con 32 filas; por entidad: contenedores, selector, cinco notas; ciclo/tasas/meta/índice
  byte a byte; los cinco Sankeys con los mismos nodos/enlaces y los mismos enlaces con sello que el motor); harness de
  seguridad (400/404); cero literales; Chrome headless sobre NL, Jal y Col: los cuatro productos renderizan, enlaces del
  Sankey idénticos como cadena (quintil y, tras el selector, grupoedad con una sola petición), series del ciclo = pct del
  JSON y «⚠» exactamente en las celdas selladas, barras de tasas con el te del JSON y sello exacto, neto/PIBE = el escalar
  `NetoCicloPIBE<ABREV>` de `neto-pibe.json` (y `meta.json` lo transcribe igual; control neto/PIBE×100 a 1e-9), frase fija
  del espejo solo en NL,
  listas y notas de sellos = exactamente las celdas selladas de meta.json (que a su vez = `sello=1` de los JSON del
  motor), cifras llenas, espejo en NL, sin errores de JS, `--png`; índice lleno. `test-sitio-seguridad.sh` gana los casos
  de `jsonEntidad.php`; `verify_sitio_autocontenido.sh` al día. Fixtures: `05_scripts/fixtures/entidades/{NL,Jal,Col}/`
  + `entidades.json` de la corrida completa de esta sesión (SIM.do + contrato-32 en worktree de `b837c33`).
- **FLAGs.** ISAN/IMPORT omitidos de la gráfica de tasas por la FLAG TE de v8.13a. La vista previa §4b de
  `contrato-32.py` sigue dividiendo en Python para el reporte (no alimenta la página); se puede retirar cuando el
  reporte lea `neto-pibe.json`.
- **Corrida de evidencia** (`~/CIEP_Simuladores/diag-v8.13b-entidades-2026-10-29/`, worktree de `b837c33` con `raw/` y
  `master/` de `-datos`, Stata 39 min): paridad byte-idéntica con `-datos` (`output.txt` `fcddfb84…`, 5 Sankeys),
  `gate-numeros.sh` VERDE, contrato-32.py PASÓ (32/32, aditividad del ciclo), **conteos de sellos idénticos a la tabla
  de las 32 del 19-oct en las 32 entidades** (NL 23/155 / 16/46 / 2/10; Jal 32/155 / 19/46 / 0/10; Col 15/155 / 18/46 /
  1/10); el neto/PIBE se mueve respecto a la vista previa del 19-oct por la corrección de datos v8.12.4 (NL 10.974 →
  10.958 %, Jal 8.217 → 8.337 %, Col 6.359 → 6.376 %); Σ32 PIBE 39,629,804 mdp vs PIB nacional 39,419,415 mdp (+0.53 %).
  Hallazgo lateral (no de este PR): `compuertas-entidad.py` falla su gate 3 (testigo NL: `statajson_entidad-nl-2026-10-08.json`
  es anterior a v8.12.4; reldif 6.6e-2) y la banda de vintages no corre sin `users/ricardo-v<anio>/`; los gates 2 y 4
  (Σ32 = nacional, sellos en las 32×5) pasan.

### Institucional — `/NTA` v3 sin nodos redundantes, en % del PIB, con un solo nodo de ancla (PR NTA-4, 2026-10-29)

Decisiones de Ricardo (29-oct) sobre el Sankey v3 de `/NTA` (`NTA.do` §7b) y el panel (§7c). **La cuenta no cambia;
cambia la emisión y la página**: `gate-numeros.sh` verde; `nta-identidad.txt`, `nta-grupoedad.json` (salvo `generado_el`),
`nta-quinquenio-sexo.json` y el v2 byte-idénticos a la corrida de NTA-3; `output.txt` y los 10 sankeys publicados
byte-idénticos al baseline. Mismo PR sobre `master` con #45 (v8.13.0) mergeado.

- **Un solo «Desahorro» (fuente) y un solo «Futuro» (sink)** en lugar de uno por grupo; el detalle por grupo vive en el
  panel. **La especie pública se funde con su categoría de consumo**: `Gobierno` → `Salud` / `Educación` / `Otros gastos`
  (desaparecen «Salud pública», «Educación pública», «Otros en especie»); cada categoría recibe de `Ing nacional`,
  `Transferencias en efectivo`, `Activos` y `Gobierno`, y sale a los grupos consumidores con privado + especie;
  `Colectivo` sigue como nodo propio terminal. **El ancla S.14 en un nodo**: «Ancla S14 recorte» (66.9 bn) y «Ancla S14
  complemento» (1.4 bn) se funden en `Ajuste a cuentas nacionales S14` con el neto, **65.5 bn** (0.195 % del PIB), desde
  `Activos` (si algún año el complemento superara al recorte, el nodo sería fuente hacia `Activos`); recorte y
  complemento siguen por separado en la cuenta, en el panel y en «Anchoring and residual». Etiqueta en español como el
  resto de los nodos del motor (SankeySumSim no admite paréntesis ni puntos en una etiqueta); la página la llama
  «adjustment to national accounts (S.14)». **42 nodos / 118 enlaces → 35 / 99** en 2024 (−7 nodos: 2 Desahorro g → 1,
  3 Futuro g → 1, 3 especie → 0, 2 ancla → 1; −19 enlaces: los 15 especie → grupo se funden con los privados). Lo que
  llega a cada grupo consumidor no se mueve (reldif ≤ 5e-15 contra el v3 de NTA-3); conservación en todo nodo intermedio
  ≤ 1.5e-14.
- **Flujos en % del PIB.** §7b emite cada enlace con `value` (MXN corrientes, como siempre) y `pctpib` = `value` / PIB ×
  100 (variable `j_pctpib`; `SankeySumSim` la escribe como campo del enlace) con el PIB nominal del año que registra
  `SCN.ado` (`escalar mxn PIB`, 33,667.0 bn en 2024; §1 lo guarda como `NTAPIBY` y aborta si falta); los ejes 1 y 2 se
  copian a archivos propios para que el v2 siga byte-idéntico; hubs y nodos fundidos registrados como `escalar pctpib`
  (`NTAV3IngNacPIB` 86.72, `NTAV3GobiernoPIB` 21.87, `NTAV3ActivosPIB` 6.08, `NTAV3TransfEfPIB` 10.23, `NTAV3FuturoPIB`
  5.76, `NTAV3DesahorroPIB` 0.12, `NTAV3ColectivoPIB` 4.51, `NTAV3AjusteS14PIB` 0.19). **Nada se divide fuera de Stata.**
  El panel pasa a **`nta-panel/v2`** con doble emisión: bloque `pib` (año, valor, escalar), `pctpib` por celda (los
  mismos escalares y flujos en % del PIB), `nacional_pctpib` (las cifras de «Anchoring and residual» y los hubs del v3 en
  % del PIB, mismas fuentes que §6.2) y `v3_mxn` (hubs, Futuro, Desahorro, Colectivo, ancla recorte / complemento / neta
  en MXN); procedencia `v1.4 (NTA-4)`.
- **Sitio.** `jsonSankeyNTA.php`: la clave `pctpib` viaja entre comillas (sin tocar el valor), `chart.unidad = pctpib` para
  el v3 (`mxn` para v2/v1), tooltips y `toolText` de los hubs en «% of GDP» (no estaba en la compuerta: el fragmento del
  motor no parsea sin entrecomillar la clave nueva y la unidad de los tooltips vive ahí). `js/metodo-sankey.js`:
  `metodoSankeyEnUnidad` dibuja con `pctpib` como `value` del enlace (FusionCharts suma los nodos en % del PIB), guarda
  el MXN en `mxn` y un `tooltext` por enlace con ambas unidades (verificado: FusionCharts lo respeta); `metodoFormato`
  gana `pctpib` (dos decimales); el panel lee `celda.pctpib` (cintas con `data-pctpib`, tooltips y pies en ambas
  unidades) y llena los `<span data-pib>` desde `nacional_pctpib` / `v3_mxn` / `pib`. `NTA/index.php`: unidad en el
  encabezado («% of 2024 GDP; GDP = 100», el año leído de `pib.anio`), una línea que explica por qué el hub `Ing
  nacional` lee 86.7 y no 100 (depreciación 19.2 % del PIB, saldo de renta primaria con el resto del mundo −2.9 %, lo que
  retienen sociedades y gobierno; suma impuestos a productos, OyE y remesas), tabla de nodos del v3 NTA-4, «Anchoring
  and residual» en bn y en % del PIB con recorte y complemento por separado y el neto del nodo, hubs en % del PIB; el
  párrafo de método y las cabeceras de columnas al día. Cero literales en los cinco archivos.
- **Gates.** `test-nta-identidad.sh` mitad C: `pctpib` en todos los enlaces y = `value` / PIB × 100 a **1e-12**;
  conservación en ambas unidades; nodos retirados prohibidos, `Desahorro`/`Futuro`/`Colectivo`/`Ajuste` únicos y
  terminales; contra `nta-grupoedad.json`: Σ entradas de cada « De g» = Cpriv + CpubInd del grupo, Colectivo, Futuro,
  Desahorro, especie por categoría y ajuste neto = la cuenta (1e-9); panel v2 balanceado en ambas unidades, `pctpib` por
  celda a 1e-12, `nacional_pctpib` = cuenta / PIB × 100 y = hubs del v3. `test-sitio-nta.{sh,js}`: **35/99** fijados con
  el fixture, cada enlace servido idéntico (from, to, value, pctpib), `chart.unidad`, FusionCharts con `pctpib` como
  `value` y el MXN en `mxn`, tooltext con ambas unidades y el **tooltip real** (hover en Chrome headless) con «% of GDP» y
  «bn MXN», `<span data-pib>` llenos e iguales al archivo del panel, año del encabezado = `pib.anio`, pies del panel en
  ambas unidades, `data-pctpib` en cada cinta; panel v2 con 15 celdas balanceadas en MXN y % del PIB. Harness de
  seguridad con el stub del panel en v2. Fixtures: `sankey-nta-grupoedad.json` = el **v3 NTA-4 real** (35/99, sha256
  `d352033f…`) y `nta-panel-grupoedad-sexo.json` v2 (sha256 `f4b23e9a…`) de la corrida completa de `SIM.do` en esta
  rama (`33a7ffc`, worktree con `raw/` y `master/` de `-datos`, Stata 33 min; `output.txt`, los 10 sankeys, el v2,
  `nta-identidad.txt` y `nta-grupoedad.json` byte-idénticos al baseline y a NTA-3 salvo `generado_el`).

## [v8.12.6] — 2026-10-29 — Reproducibilidad: el orden de los empates ya no depende del camino

Cierre del memo REPRO-1 (`02_governance/repro-1-2026-10-28.md`, PR #42): dos corridas completas del mismo
código (`8766c90`) con los mismos insumos daban `output.txt` distinto en 23 líneas porque `Households.do`
ordenaba a las personas por probabilidades predichas (`gsort -prob_*`, 17,179 empates exactos en
`prob_moral`) antes de los cut-offs de formalidad, y Stata rompe los empates de `sort` con un RNG propio
que avanza con cada `sort` de la sesión (no lo gobierna `set seed`). El primer paso por `SCNHogaresS14`
en un clon (NTA-1) añadía sorts antes de `Households.do` y cambiaba de bando a 2 de las 3 personas
empatadas en el margen del cut-off de personas morales. **Seis `gsort` de `01_modulos/Households.do`
llevan ahora la llave única `folioviv foliohog numren`** (la misma receta que FLAG-7 aplicó en
`SankeySF.do` en v8.12.0); cero cambios de lógica, un commit por línea, cada uno medido con una corrida
completa de `SIM.do` (defaults + `nographs` + `output`, StataNow 19.5, 1 procesador) en un worktree
con los `raw/` y `master/` de `-datos`. Evidencia (corridas, diffs, gate): PR #43 y `~/CIEP_Simuladores/diag-repro-fix-2026-10-29/`.

**Regla nueva (contrato del gate de números):** *el orden de los empates ya no depende del camino de la
corrida.* Dos corridas completas con los seis fixes por caminos distintos — una con `master/SCN.dta` ya
enriquecido con las series S.14 (`SCNHogaresS14` no corre) y otra con las 18 series borradas del
`SCN.dta` (`SCNHogaresS14` corre: 15 `reshape`, 14 `merge`, 16 `save` extra antes de `Households.do`) —
dan `output.txt` **byte-idéntico** (con `7338fa7` esos dos caminos difieren en 23 líneas) y los 10 sankeys
del gate dentro de 1e-9 con **Δ rel. máx 1.3e-15**: 10 de los 11 JSON no son byte-idénticos (10 enlaces de
`Imp al trabajo`, YL y S en el último bit) y la cuenta NTA difiere en 7 campos en el último bit. Ese
residuo no es un cambio de bando sino **orden de suma en punto flotante**, y tiene un origen único
(FLAG abajo).

### Correcciones — `01_modulos/Households.do`, llave única en seis `gsort` (REPRO-FIX)

| commit | línea | antes | después | qué decide | mueve vs commit anterior |
|---|---|---|---|---|---|
| `aa1fb75` | 2300 | `gsort -prob_moral` | `gsort -prob_moral folioviv foliohog numren` | cut-off `ISR_PM` (§11.3) | **14 líneas** de `output.txt`, 5 SankeySF (tabla abajo); NTA 0 |
| `862eebb` | 2210 | `gsort -formal_probit -prob_salarios` | `… folioviv foliohog numren` | `prop_salarios` (§10.2) | 0 líneas, 11 JSON idénticos |
| `3ea236a` | 2227 | `gsort -formal_probit -prob_formal` | `… folioviv foliohog numren` | `prop_formal` (§10.3) | 0 líneas, 11 JSON idénticos |
| `19c8641` | 2243 | `gsort -formal_probit -prob_moral` | `… folioviv foliohog numren` | `prop_moral` (§10.4; el 66.75 % impreso) | 0 líneas, 11 JSON idénticos |
| `03acb24` | 2251 | `gsort -prob_salarios` | `… folioviv foliohog numren` | cut-off `ISR_asalariados` (§11.1) | 0 líneas, 11 JSON idénticos |
| `acd8a8c` | 2273 | `gsort -prob_formal` | `… folioviv foliohog numren` | cut-off `ISR_PF` (§11.2) | 0 líneas, 11 JSON idénticos |

Las cinco hermanas no mueven nada hoy (su margen no cae en un empate, memo §5) pero quedan cerradas:
cualquier `sort` extra antes de `Households.do` ya no puede moverlas. Los `gsort` continuos de §9
(l. 1817/1828/1957, sobre ingreso) no se tocan: un empate exacto en ingreso con factor es improbable y
no hay cut-off discreto detrás.

### Qué mueve (`output.txt`, 14 de 519 líneas; `7338fa7` → v8.12.6)

La llave única elige, dentro del grupo de 3 personas empatadas en el margen del cut-off de personas
morales (410 M MXN de `ISR_PM` ponderado; memo §5), un subconjunto formal distinto del que tenía el
baseline (y distinto del de la corrida del ritual del 28-10): el saldo neto cae en el decil VIII (+18.5 M) y,
como el total de `ISR_PM` está anclado a la LIF, el resto de los deciles se reescala −8.8e-6. Nada fuera de
los bloques que contienen `ISR_PM` (ISRPM, OTROSK, KPrivado, ImpuestosAportaciones, AportacionesNetas);
los 39 bloques restantes y las 35 líneas de proyección/FiscalGap son byte-idénticos; los 5 SankeyNTA y el
v2, Δ = 0. En las filas `INCD` (deciles I … X y promedio) se muestran el decil I, el X y el promedio.

| línea | bloque | clave | posiciones | antes | después | Δ máx abs (Δ rel máx) |
|---|---|---|---|---|---|---|
| 188 | ISRPM | `INCD` | I … X; prom. | 86,927 … 1,661,669; 687,492 | 86,926 … 1,661,654; 687,481 | 15 (2.9e-05) |
| 193 | ISRPM | `APORTHX` | 9 | 12.719 | 12.718 | 0.001 (7.9e-05) |
| 195 | ISRPM | `APORTMVIIX` | 12 | 0.619 | 0.62 | 0.001 (1.6e-03) |
| 199 | OTROSK | `INCD` | I, III … X; prom. | 33,800 … 646,108; 267,318 | 33,799 … 646,102; 267,314 | 6 (3.2e-05) |
| 204 | OTROSK | `APORTHX` | 9 | 12.719 | 12.718 | 0.001 (7.9e-05) |
| 206 | OTROSK | `APORTMVIIX` | 12 | 0.619 | 0.62 | 0.001 (1.6e-03) |
| 210 | KPrivado | `INCD` | I … X; prom. | 120,726 … 2,307,777; 954,810 | 120,725 … 2,307,757; 954,795 | 20 (3.0e-05) |
| 215 | KPrivado | `APORTHX` | 9 | 12.719 | 12.718 | 0.001 (7.9e-05) |
| 217 | KPrivado | `APORTMVIIX` | 12 | 0.619 | 0.62 | 0.001 (1.6e-03) |
| 353 | ImpuestosAportaciones | `INCD` | 7,8,9,10 | 156455,198288,277108,705012 | 156454,198293,277107,705009 | 5 (2.5e-05) |
| 358 | ImpuestosAportaciones | `APORTHX` | 10 | 4.905 | 4.904 | 0.001 (2.0e-04) |
| 474 | AportacionesNetas | `INCD` | 7,8,10 | 7232,41137,483164 | 7231,41140,483162 | 3 (1.4e-04) |
| 479 | AportacionesNetas | `APORTHX` | 9,12 | 5.457,15.091 | 5.456,15.09 | 0.001 (1.8e-04) |
| 481 | AportacionesNetas | `APORTMVIIX` | 13 | 5.333 | 5.334 | 0.001 (1.9e-04) |

| enlace Sankey SF (decil) | antes | después | Δ (Δ rel) |
|---|---|---|---|
| `VIII → Imp al capital` | 217,413,979,633 | 217,432,507,822 | +18,528,189 (8.5e-05) |
| `V → Imp al capital` | 75,934,567,782 | 75,933,899,714 | -668,069 (8.8e-06) |
| `IV → Imp al capital` | 48,308,676,105 | 48,308,251,088 | -425,017 (8.8e-06) |
| `III → Imp al capital` | 28,985,941,430 | 28,985,686,413 | -255,017 (8.8e-06) |
| `VII → Imp al capital` | 131,116,764,970 | 131,115,611,411 | -1,153,559 (8.8e-06) |
| `I → Imp al capital` | 7,883,672,610 | 7,883,603,250 | -69,360 (8.8e-06) |
| `X → Imp al capital` | 1,356,957,510,192 | 1,356,945,571,747 | -11,938,446 (8.8e-06) |
| `II → Imp al capital` | 18,475,002,106 | 18,474,839,564 | -162,542 (8.8e-06) |
| `IX → Imp al capital` | 348,019,101,818 | 348,016,039,963 | -3,061,855 (8.8e-06) |
| `VI → Imp al capital` | 90,285,122,246 | 90,284,327,922 | -794,324 (8.8e-06) |

Δ relativo máximo en los sankeys: SankeySF/decil 8.5e-5 (`VIII → Imp al capital`); grupoedad y rural
8.8e-6; sexo 4.1e-5; escol 4.1e-5. Informalidad impresa de personas morales: 66.75 % (igual que el baseline).

### FLAG — el residuo de último bit: falta un `sort` fuera de la compuerta de este PR (para v8.12.7)

- **Qué es.** `households.dta` de los dos caminos tiene el mismo orden de filas y las mismas personas en
  cada bando, pero 49 variables difieren en ≤ 6e-16 relativo desde la primera (`ing_tri`, 6,892 personas):
  `Households.do` l. 341–342 (`merge m:1` de las líneas de ingreso con `poblacion`/`concentrado`, que
  reordena las líneas de una misma persona con el RNG de `sort`) y l. 551 `collapse (sum) ing_* …
  by(folioviv foliohog numren id_trabajo)` suman las líneas de cada persona en un orden que depende del
  camino. Después, l. 552 `sort folioviv foliohog numren` deja empatadas las filas de `id_trabajo`. De ahí
  heredan `isrE`, `ISR`, `Yl`, `Ahorro` (≤ 3e-12), y en la salida solo lo que no se redondea: 10 enlaces
  de sankeys (≤ 1.3e-15) y 7 campos de `nta-*.json`.
- **Prueba.** (i) Aislado (`ulp-collapse.do`): la misma lectura con y sin un `sort` previo → 7,197
  personas con `ing_tri` distinto; con `sort folioviv foliohog numren id_trabajo clave` antes del
  `collapse` → 0. (ii) Dos corridas completas por los dos caminos en worktrees desechables de `acd8a8c`
  más ese `sort` y `id_trabajo` en la l. 552 (2 líneas, **no commiteadas**): `output.txt` byte-idéntico,
  **los 11 JSON byte-idénticos**, cuenta NTA idéntica salvo `generado_el`.
- **Qué haría si se aplica.** Respecto a este baseline: `output.txt` byte-idéntico (0 líneas), sankeys
  ≤ 3.9e-14 (dentro del gate), `nta-identidad.txt` cambia en los últimos dígitos impresos y
  `nta-*.json` en el último bit → refrescar los fixtures NTA en el mismo commit. No se aplica aquí porque la
  compuerta de este PR cubre solo las seis líneas del memo; propuesto para v8.12.7.

### Institucional — `/NTA` v3 simplificado + panel por grupo de edad × sexo (PR NTA-3, 2026-10-29)

Decisión de Ricardo (29-oct): en `/NTA` el Sankey principal lleva las edades **solo al inicio y al final**; se
eliminan los ejes «Ingreso por grupo» y «Consumo por grupo» y el hub «Familias». Como las transferencias en efectivo,
inter e intra-hogar netean a cero nacionalmente (lo que un grupo recibe otro lo paga), el gráfico principal ya no las
dibuja por grupo; la cuenta por grupo vive en un **panel de cinco mini-Sankeys** debajo, con selector Total / Hombres /
Mujeres. **Ningún número cambia**: `gate-numeros.sh` y `test-nta-identidad.sh` verdes; `output.txt`, los 10 sankeys
publicados, el v2 y `nta-persona.dta` son los de la corrida determinista de v8.12.6. En el motor solo cambia la emisión
de JSON en `01_modulos/NTA.do` (dos archivos nuevos; v1.3). PR NTA-3 (el segundo de v8.12.6).

- **`NTA.do` §7b — Sankey v3** (`users/<id>/SankeyNTA/sankey-v3-grupoedad.json`, contrato v3, **42 nodos / 118 enlaces**
  en 2024; el v2 de §7 se sigue emitiendo: 52/174). Fuentes (5 grupos perceptores, OyE públicas, El mundo, Desahorro g,
  balances declarados) → Tipos de ingreso (mismos ejes 1 y 2 del v2) → `Ing nacional` → `Gobierno` (entran τ⁻ + OyE;
  salen Educación/Salud pública y Otros en especie por edad, `Colectivo` sin edad y terminal, y **`Transferencias en
  efectivo`** a un nodo único) y `Activos` (entran el S sin ancla de los grupos que ahorran, Desahorro g y el complemento
  del ancla; salen Futuro g, `Ancla S14 recorte` y el desahorro hacia las categorías) → Usos (7 categorías privadas, 3 en
  especie, Colectivo, Transferencias en efectivo) → Sinks (5 grupos consumidores, Futuro g, Colectivo, recorte). El
  consumo privado de cada categoría se financia desde `Ing nacional` (ingreso propio: Y − τ⁻ − S⁺ − recorte + inter
  recibido + remesas + intra − inter otorgado), desde `Transferencias en efectivo` (τ⁺ efectivo) y desde `Activos`
  (desahorro + complemento), cada flujo de cada grupo repartido por la **canasta del grupo** (Cpriv_gc / Cpriv_g): es el
  reparto que v2 hacía implícitamente en «Consumo g», así que cada categoría conserva por la identidad. Balances como en
  v2 (`Déficit público` → Gobierno; `Otras transferencias privadas` → Ing nacional). Conservación en todo nodo intermedio
  (|in − out|/max ≤ 1.5e-14); `Ing nacional` 29,195.5 bn, `Gobierno` 7,361.5, `Activos` 2,048.5, `Transferencias en
  efectivo` 3,445.1; desahorro + complemento a categorías 41.0; recorte 66.9, complemento 1.4.
- **`NTA.do` §7c — panel** (`users/<id>/NTA/nta-panel-grupoedad-sexo.json`, esquema `nta-panel/v1`): 5 grupos ×
  {Total, Hombres, Mujeres} = 15 celdas, cada una un mini-Sankey de dos columnas: entradas YL; YA (con D.8) + impuestos a
  productos; τ⁺ efectivo, especie y colectivo; inter-hogar recibido (con remesas); intra-hogar recibido (Σ intra > 0 por
  persona); desahorro; ancla complemento → salidas C privado; C público en especie; C colectivo; τ⁻; inter-hogar otorgado;
  intra-hogar otorgado (Σ intra < 0); S; ancla recorte. **Cada celda balancea por la identidad del gate** con el ancla
  declarada (|Δ|/C máx 1.1e-14); S es el anclado (Σ Total = Σ H + Σ M = B.8n). Trae además C, YL, **déficit de ciclo de
  vida C − YL**, S, S sin ancla y los componentes por celda. Formato scalarjson: números crudos a 17 dígitos
  significativos, nada de literales, `generado_el` aislado al final de `procedencia`.
- **Sitio.** `jsonSankeyNTA.php`: default **`?corte=v3-grupoedad`**; `v2-grupoedad` y los v1 siguen en la lista blanca
  (404 con pista si el archivo no viajó); nuevo `?cuenta=panel-grupoedad-sexo` (byte a byte); `toolText` «inflows =
  outflows» en los cuatro hubs del v3 (en el v2, en los nodos de grupo). `NTA/index.php`: párrafo de método con las
  columnas del v3 (nota ¹ intacta), tabla de nodos y enlaces del v3 (7 columnas), «Anchoring and residual» al v3 (el
  ancla cuelga de `Activos`) con un punto nuevo que lee de la cuenta cuánto efectivo devuelve el gobierno y cuánto dan y
  reciben los hogares, y la sección **«The account by age group»**: selector Total / Men / Women y cinco mini-Sankeys en
  fila, cada uno con el título (etiqueta del motor) y al pie su déficit de ciclo de vida y su S leídos del JSON.
  `js/metodo-sankey.js` gana `metodoPanel()` (una sola petición; el selector cambia los cinco con `setJSONData`, sin
  recarga); `metodo/plantilla.php` admite `panel`; `css/metodo.css` (grid de 5 → 3 → 1 columnas; Sankey principal a
  820 px). **v2 retirado del sitio**; el motor lo sigue emitiendo. Cero literales en los cinco archivos.
- **Deploy.** Fase 3b-ter embarca `SankeyNTA/sankey-v3-grupoedad.json` y `NTA/nta-panel-grupoedad-sexo.json` y **deja de
  exigir el v2** (manifiesto 11 → 12 archivos); Gate 5-remoto exige el v3 y el panel (+1 ruta neta).
- **Gates.** `test-sitio-nta.{sh,js}`: default y `?corte=v3-grupoedad`, **42/118** fijados cuando el origen es el
  fixture, `toolText` solo en hubs, sin Ingreso g / Consumo g / Familias, v2 y v1 sin archivo → 404, `?cuenta=` byte a
  byte (cuenta y panel), 15 celdas balanceadas, cero literales, y en Chrome headless: enlaces del v3 idénticos como
  cadena, cifras llenas, cinco paneles con las celdas Total, títulos del motor, pies iguales al archivo, selector Hombres
  / Mujeres cambia los cinco paneles con una sola petición al endpoint, `--png` (página, v3 solo, panel Total).
  `test-nta-identidad.sh` gana la mitad C (v3: conservación, hubs, sin nodos retirados, 5 + 5 grupos, `Colectivo`
  terminal; panel: 15 celdas a 1e-9, Σ S = B.8n). Harness de seguridad con el default v3 y el panel. Fixtures:
  `sankey-nta-grupoedad.json` pasa a ser el **v3 real** (sha256 `7bcafacb…`) de la corrida completa de `SIM.do` en esta
  rama (`5b05979`; reproduce byte a byte el baseline v8.12.6: gate de números verde, `output.txt`, los 10 sankeys, el v2
  y `nta-identidad.txt` idénticos a la corrida determinista de `acd8a8c`), más `nta-panel-grupoedad-sexo.json` (nuevo,
  sha256 `2bff8f61…`) y `nta-grupoedad.json` refrescado (solo `procedencia.modulo` → v1.3; números idénticos).
- **Hallazgo lateral (sitio).** A ~200 px de ancho FusionCharts trunca toda etiqueta de nodo de un sankey a ~35 px
  («In…», «τ…») con cualquier `nodelabelposition`, márgenes a cero y fuente menor (medido con Chrome headless, ocho
  variantes); por eso los mini-Sankeys del panel se dibujan con SVG propio y el Sankey principal sigue en FusionCharts.
- **Interpretación del v3 (para el lector).** `El mundo` sigue siendo fuente de `Remesas` (columna 1); `Colectivo` es
  terminal porque no tiene edad; FusionCharts coloca cada nodo por su profundidad desde las fuentes, así que las 7
  categorías privadas quedan una columna a la derecha de las 3 en especie (reciben de `Transferencias en efectivo`), y
  `Colectivo`, `Futuro g` y `Ancla S14 recorte` comparten columna con `Transferencias en efectivo`: la tabla de cabeceras
  de la página lo refleja (7 columnas).

### Baseline y manifest

- Commit «baseline: v8.12.6 reproducibilidad»: `05_scripts/fixtures/output-default.txt`, los 5
  `fixtures/sankeys-default/SankeySF/sankey-*.json` y `fixtures/nta-grupoedad.json` (su `TmenFuera`,
  informativo, contiene `ISR_PM` por grupo; además su `procedencia.modulo` estaba en v1.1 y el motor emite
  v1.2 desde NTA-1c) reemplazados por la salida determinista de `acd8a8c`; los 5 SankeyNTA v1,
  `sankey-nta-grupoedad.json` (v2) y `nta-identidad.txt` no cambian (byte-idénticos). `gate-numeros.sh`
  **VERDE contra la rama y ROJO contra `7338fa7`** (ambas salidas en el PR).
- `manifest.json` → v8.12.6 y `data_updated` → 2026-10-29 (criterio de v8.12.4: cambian números
  publicados aunque los insumos no; el hero lo pinta).
- `master/SCN.dta` sigue sin versionar ni sellar (memo §9): el gate no ve si un clon tiene o no las series
  S.14, pero desde esta versión ese estado ya no mueve ningún número.

## [v8.12.4] — 2026-10-27 — Corrección de datos

Hotfix sobre v8.12.3: tres FLAGs de `01_modulos/Households.do` detectados en el inventario NTA-0
(`02_governance/nta-0-inventario-2026-10-27.md`) que **movían números publicados**. Un commit por
corrección con el diff mínimo; medidos con corridas completas de `SIM.do` (defaults + `nographs` +
`output`, StataNow 19.5, 1 procesador, ~33 min c/u): baseline `07b9d5c` (reproduce al 1e-9 los
sankeys publicados) y una por corrección acumulada; evidencia y deltas enlace por enlace en PR #39.
El gate de números (`05_scripts/gate-numeros.sh`: `output.txt` byte-idéntico + 10 sankeys ≤ 1e-9)
queda **ROJO contra `07b9d5c` y VERDE contra el baseline nuevo** (`05_scripts/fixtures/output-default.txt`
y `fixtures/sankeys-default/`, commit "baseline: v8.12.4 corrección de datos"). `manifest.json` →
v8.12.4 y `data_updated` 2026-10-27 (los datos precargados se reprocesaron; el hero lo pinta).
Solo cambian `Households.do`, el CHANGELOG, el manifest y el baseline del gate. El `.do`/`.ado` del motor web (`Web.Stata.do`, `ISR_Mod.do`) no cambia.

**Lectura para el usuario del sitio.** Los valores precargados (Paquete Económico 2027) cambian poco
pero cambian: las aportaciones netas por decil (`APORT*`) se mueven hasta ±2 pp del PIB por celda y
el ingreso neto per cápita por decil (`INCD`) hasta ±2.5 %; en los Sankeys del sistema fiscal **la
cuota al trabajo del decil I baja 12 %** (49.2 → 43.1 mil millones) y la de los menores de 18 baja
40 % (7.5 → 4.5 mil millones), porque esos asalariados cargaban el INFONAVIT dos veces; el resto de
los enlaces se mueve < 2 %. Los totales nacionales (ingreso laboral, de capital, consumo) **no**
cambian: están anclados a Cuentas Nacionales.

**«Calcular» web vs batch (FLAG-5).** La distancia entre el `output.txt` del «Calcular» default
(`Web.Stata.do`) y el `output.txt` publicado se midió antes y después: en `07b9d5c` difieren 5 de 46
llaves (`GASTOSPC` 1.8e-3, `INCD` 1.5e-4, `PIBY` 1.1e-4, `PROYSHRFSP2/3` ≈ 1e-4: redondeo de
`CRECPIB`/`CRECDEF` a un decimal y el `if k != 0` de `SIM.do` §7); con v8.12.4 la distancia es
**la misma** (ver PR #39), así que la diferencia de `ISR_Mod.do` (`cuotasTPF` sin infonavit, FLAG
abajo) no amplifica la divergencia web/batch.

#### Fix 1 — `infonavit` sumado dos veces en `cuotasTPF` (`4a425d1`)
- **Línea:** `Households.do` l. 1541 `replace cuotasF = cuotasF + infonavit` (borrada); l. 1549
  `replace cuotasTPF = cuotasTPF + infonavit` se conserva. `cuotasF = rsum(*F)` + infonavit y luego
  `cuotasTPF = rsum(cuotasP cuotasT cuotasF)` + infonavit: 221 bn de más en las contribuciones a la
  seguridad social de 2024 (Σ `cuotasTPF` 1,690.6 → 1,469.2 bn, −13.1 %). INFONAVIT es aportación
  patronal, no federal (`ISR_Mod.do` l. 129 construye `cuotasF` sin él).
- **En producción desde:** la suma a `cuotasTPF` existe desde `1ebd71e` (2025-06-18, "Simulador v7
  final"); la segunda, a `cuotasF`, desde `76d3cd5` (2025-07-21, "Pre-ENIGH 2024"). Doble conteo en
  **todas las versiones publicadas (v7.0, 2026-05-23 → v8.12.3)**.
- **Qué mueve:** el gross-up de `ing_subor` por persona (l. 1709; el total lo re-ancla Altimir a
  RemSal, así que Σ `Yl`, Σ `Yk`, Σ `ingbrutotot` no cambian), `isrE` +6.5 bn, la base gravable y los
  cortes de formalidad, `ISR_asalariados` −0.5 bn, y por el re-ranking de `ingbrutotot` **el decil de
  cada persona**: 389 de 519 líneas de `output.txt` (los 44 bloques de `Simulador`) y los 10 sankeys.
  `TasasEfectivasMicro` (`BaseCSS ∝ cuotasTPF`) hereda la nueva forma.

| número publicado | antes (`07b9d5c`) | después | Δ |
|---|---|---|---|
| `INCD` decil I … X, promedio (MXN/persona) | −87,882 … 483,532; 30,987 | −89,705 … 483,164; 30,987 | hasta −2.5 % en decil III |
| `INCD2` (% del promedio) decil I | −28.4 | −29.0 | −0.6 pp |
| `APORTHIV`, `APORTMIV` … (% PIB por celda edad × decil) | — | — | hasta ±0.4 pp (`APORTMVIIX`), típico 0.02–0.1 pp |
| `PROY` (ciclo fiscal) | 0.800 … −1.002 | 0.799 … −0.998 | ≤ 0.004 |
| Sankey SF `I → Imp al trabajo` | 49,203,202,515 | 43,160,499,085 | −12.3 % |
| Sankey SF `De 5 a 17 → Imp al trabajo` | 7,455,177,497 | 4,482,138,784 | −39.9 % |
| Sankey SF `Indígena → Imp al trabajo` | 44,152,525,344 | 40,447,425,879 | −8.4 % |
| Sankey SF `Pensiones → VI` / `→ VIII` | 284.0 / 293.7 bn | 279.2 / 297.6 bn | −1.7 % / +1.3 % (re-ranking) |
| Sankey NTA `Salud → VI` (decil) | 72,484,693,107 | 71,021,673,094 | −2.0 % (máximo NTA) |
| Sankey NTA `De 65 y más → Ing Laboral` | 1,920,774,303,829 | 1,930,851,744,154 | +0.5 % |

#### Fix 2 — Altimir escalaba `ing/exen_t4_cap5–9` dos veces (`06db1e2`)
- **Línea:** l. 2105 `foreach k of varlist ing_subor *_t4_cap4 *_t4_cap5 *_t4_cap6 *_t4_cap7
  *_t4_cap8 *_t4_cap9 { × TaltimirSal }` → `foreach k of varlist ing_subor *_t4_cap4 { … }`; cap5–9
  quedan solo en el bucle × `TaltimirSelf` (l. 2108), como componentes de `ing_mixto` (l. 1046).
- **En producción desde:** el bucle con `*_t4_cap5 … *_t4_cap9` existe desde `9f7982f` (2021-06-11,
  "Reporte Ingresos"). **Todas las versiones publicadas.**
- **Qué mueve:** `ing_mixto`, `Yl`, `Yk`, `ingbrutotot`, deciles y `Ahorro` **no** cambian (se
  escalaban una vez). Cambian las componentes que lee §10: `ing_bruto_tax` +103 bn (+0.6 %),
  `exen_tot` +100 bn (+1.7 %) → ISR recalculado, cortes de formalidad, `ISR_asalariados` −0.5 bn,
  `ISR_PF` −0.01, `ISR_PM` −0.01. (`TaltimirSal` ≈ 0.978: quitarlo **sube** cap5–9 un 2.2 %.)

| número publicado | antes (fix 1) | después | Δ |
|---|---|---|---|
| `output.txt` | — | 59 líneas en 9 bloques (`ing_bruto_tax`, `ISRAS`, `ISRPF`, `Laboral`, `ISRPM`, `OTROSK`, `KPrivado`, `ImpuestosAportaciones`, `AportacionesNetas`) | — |
| `INCD` (sitio) | −89,705 … | −89,708 … | ≤ 0.2 % |
| `INCD3` decil IX | 9.9 | 9.8 | −0.1 pp |
| `APORTMVIIX` | — | — | ≤ 1.7 % relativo por celda |
| Sankeys SF (5 cortes) | — | 48 enlaces se mueven | Δ rel. máx 7.7e-4 (`Sin escolaridad → Imp al trabajo`) |
| Sankeys NTA (5 cortes) | — | idénticos | 0 |

#### Fix 3 — `ing_remesas` sumado otra vez en `Ahorro` (`0c712a7`)
- **Línea:** l. 2678 `g Ahorro = ingbrutotot + ing_capitalROW + ing_suborROW + ing_remesas − gastoanualTOT`
  → sin `+ ing_remesas` (`ingbrutotot`, l. 2462, ya lo trae).
- **En producción desde:** `05325a2` (2020-10-22, "Capítulo 3") / `36f7a96` (2021-03-04, "5.0").
  **Todas las versiones publicadas.**
- **Qué mueve:** Σ `Ahorro` 2,851.2 → 1,665.1 bn (−1,186.1 bn = ROWTrans 2024). Solo `Ahorro`: el
  bloque 6 de `output.txt` (10 líneas que el sitio **no** pinta: `cargaDefault.php` lee la última
  aparición de cada llave, bloque 43), `Ahorro{PC,PERF,INCI,CICLO,REC,RECprom}.dta` de
  `bootstraps/250` (Δ rel. máx `AhorroPC` 0.53, `AhorroRECprom` 1.28), las barras `Usos.png`/
  `Recursos.png` (`Ahorro_dec`) y los escalares `Ahorro*` del textbook. `output.txt` deja de ser
  byte-idéntico (gate ROJO), pero ninguna llave del sitio ni ningún sankey se mueve.

| número publicado | antes | después | Δ |
|---|---|---|---|
| `output.txt` bloque 6 (`Ahorro`): `INCD` decil I … X | −169,392 … 1,326,812 | −169,014 … 1,108,624 | decil X −16 % |
| `output.txt` bloque 6: `INCD2` decil I | −23.0 | −39.4 | el ahorro cae y la incidencia relativa se amplifica |
| Llaves del sitio, sankeys SF y NTA | — | idénticos | 0 |

#### Pendiente (FLAG, decisión de Ricardo): `*_t4_cap4` escalado × `TaltimirSal` en vez de × `TaltimirSelf`
Se probó como cuarto commit (`90c7c96`, revertido en `407749f`): `ing_t4_cap4` 93.8 → 590.4 bn
(`TaltimirSelf` ≈ 6.3 vs `TaltimirSal` ≈ 0.98), `ing_bruto_tax` +497 bn (+2.9 %), `exen_tot` +319 bn
(+5.3 %), `ISR_asalariados` −2.1 bn; `Yl`/`Yk`/deciles/sankeys NTA sin cambio, pero los sankeys SF se
mueven hasta **1.5e-2** (`De 65 y más → Imp al trabajo` +1.5 %) y 4.7e-3 en decil (`VIII → Imp al
capital`), por encima del umbral 1e-3 fijado para este hotfix; en el sitio `INCD` ±1.5 %, `APORT*`
hasta ±7 %. Queda fuera; evidencia en PR #39.

#### FLAGs registrados, no corregidos
1. Remesas siguen dentro de `ing_mixto` vía `ing_t4_cap9` (l. 544): `Ahorro`, `ingbrutotot`, `Yl`/`Yk`
   las cuentan dos veces y `Ciclodevida` (l. 2673) las suma además explícitamente. Cambia Altimir y
   deciles: NTA-1.
2. `ISR_Mod.do` l. 130 construye `cuotasTPF = cuotasF + CUOTAS` **sin** infonavit (el batch sí lo
   incluye): web y batch no definen igual la variable; medido, no amplifica FLAG-5.
3. `SankeyNTA/` y la página `/NTA` (PR #37) heredan los números nuevos al regenerar `users/ricardo/`.

### Trabajo acumulado que entró con este tag (estuvo bajo `[Unreleased]` hasta v8.14.0)

Lo que sigue estaba registrado bajo `[Unreleased]` y queda incluido en el tag `v8.12.4` porque el tag es un
punto de `master`: `05_scripts/contrato-32.sh`, `pibe-32.sh` y `01_modulos/TasasEfectivasEntidad.do` nacen en
`93e1700` / `d15431a` (2026-10-19), cuyo primer tag es v8.12.4. Nada de esto cambia el paquete distribuido ni un
número publicado (el contrato de entidad corre solo con `global entidad`).

### Comandos — v8.13a: el contrato de entidad corre para las 32 (motor, sin visualización)

- **`TasasEfectivasMicro.ado` deja de ser huérfano** (v1.1.0, no se toca por dentro): `SIM.do` §4.7 lo
  invoca, solo con `global entidad`, vía `01_modulos/TasasEfectivasEntidad.do` (nuevo), que traduce
  nombre → clave con `SIMentidad`, pide `entidad(<clave>) sufijo(<abrev minúscula>)`, calcula una vez
  el espejo nacional micro/micro (referencia de `Rel<IMP>TE<suf>`), mide los sellos de muestra con la
  regla P5 (n de la muestra de la entidad; top-1 del numerador por impuesto) y escribe
  `users/$id/<ABREV>/tasas-efectivas.json` (montos, bases, tasas, dif. vs oficial, rel. vs nacional,
  sellos, procedencia). Una línea en `SIM.do`; con el global vacío no corre: nacional byte-idéntico.
- **`05_scripts/contrato-32.{sh,do,py}`** (nuevos): una sesión de Stata recorre el catálogo
  `SIMentidad` y produce para cada entidad Población, PIB/Deflactor (solo con base), los 5 Sankeys
  (con banda si hay vintages), `ciclo-vida.json` y `tasas-efectivas.json`; tolerante a fallos (rc por
  paso en `contrato-32.tsv`, log por entidad). Gates por script: paridad (sha256 vs `--refs`),
  aditividad del ciclo de vida (port de `gate-aditividad.py`, F3), Sankeys y testigo NL
  (`compuertas-entidad.py`, reuso), sellos (solo reportados) y la **tabla de las 32** en
  `contrato-32.md`. Para las tasas efectivas (no aditivas) se PROPONE el gate de consistencia —
  Σ32 montos = nacional ⇒ tasa nacional = promedio ponderado por base — y se mide; es FLAG, no gate.
- Runbook §13: cómo correr las 32, cuánto tarda, y la receta/validación de las bases precedentes
  (vintages, testigo NL, `PIBDeflactor<ABREV>.dta`): se validan y se imprime la receta; fabricarlas es
  decisión de Ricardo (FLAG de #26 sigue abierto, ahora escrito).
- Cero visualización, cero template: qué se muestra y cómo es v8.13b (Ricardo).

### Datos — v8.13a-2: bases de PIB/Deflactor para las 32 entidades (fuentes vivas, BISE)

- **`master/PIBDeflactor<ABREV>.dta` × 32**, regeneradas el mismo día (vintage uniforme: las tablas BIE
  por área se bajan una vez por sesión y sirven a las 32), con la receta de siempre sin tocarla:
  `PIBDeflactor if entidad == "<nombre>"` (PIBE 750453 e índice de precios implícitos 753357 del BIE;
  ocupados/desocupados ENOE 6200093954/6200093973 del BISE vía API con token; ITAEE 741177/741180; INPC
  estatal; población CONAPO). Antes: solo NL, Jal y Camp; las otras 29 corrían «sin base». Las bases son
  datos (gitignored); viajan al VPS por la Fase 3b del deploy.
- **`05_scripts/pibe-32.{sh,do,py}` y `sellar-pibe-32.do`** (nuevos): compuerta de arranque (catálogo con 32,
  `set_token.do` válido con una consulta BISE de prueba, `PIBDeflactorNL.dta` de referencia; el token nunca
  se imprime), una sesión de Stata que recorre el catálogo con pausa entre entidades y tolera fallos (rc por
  entidad en `pibe-32.tsv`, log por entidad, reintento de las fallidas), **sello de procedencia por base**
  (`master/PIBDeflactor<ABREV>.meta` y `char _dta[sello_*]` dentro del `.dta`: series BIE/BISE, estructura,
  fecha de consulta, último periodo, n), diff de las bases previas contra las nuevas y tabla de las 32 con
  SHA-256 y tamaño en `pibe-32.md`. Las copias previas se respaldan en `<evidencia>/bases-previas/` antes de pisar.
- `contrato-32.do` registra `pibe_pesos` (`pibY<ABREV>`) por entidad y `contrato-32.py` agrega la sección
  «4b PIBE»: gate de que las 32 corren con base y una vista previa de «% del PIBE» (neto del ciclo ÷ PIBE).
  Los JSON de entidad todavía NO escriben «% del PIBE»: es v8.13b.
- Runbook §13: receta y tiempo medido de `pibe-32.sh`.

## [v8.12.5] — 2026-10-28 — `/NTA` dibuja el Sankey v2 (cuenta NTA por individuo, S.14)

Release de sitio y deploy sobre v8.12.4 más NTA-1/1b/1c (PR #40; sus secciones, que estuvieron bajo
`[Unreleased]` hasta v8.14.0, están al final de esta entrada). **Nada del Sankey SF ni de deciles cambia**: `output.txt` y los 10 sankeys
publicados son los de v8.12.4 (gate de números verde; `data_updated` se queda en 2026-10-27: los datos no
cambiaron, cambió la cuenta que se dibuja). El motor no cambia salvo tres líneas de documentación en
`01_modulos/NTA.do` (verificación del punto 1, abajo).

### Institucional — página de método `/NTA` v2 (PR NTA-2)

- **`jsonSankeyNTA.php`**: el default es el **Sankey v2** (`?corte=v2-grupoedad` →
  `users/<id>/SankeyNTA/sankey-v2-grupoedad.json`, 52 nodos / 174 enlaces, contrato v2.1); `?corte=`
  conserva los cortes v1 (`decil|sexo|grupoedad|escol|rural`) mientras existan los archivos; nuevo
  `?cuenta=grupoedad|quinquenio-sexo|identidad` sirve byte a byte `users/<id>/NTA/nta-*.{json,txt}`
  (la cuenta por grupo, `NTA.do` §6.2-6.3, y el reporte de identidad). El bloque `chart` trae
  `plotToolText`/`linkToolText` (hover con valor, macros de FusionCharts) y, solo en el v2, un `toolText`
  en los nodos de grupo («Ingreso <g>», «Consumo <g>»: *inflows = outflows*). Nodos y enlaces viajan tal
  cual; cero números en el PHP.
- **`NTA/index.php`**: texto de método reescrito en inglés para la estructura nueva (misma extensión:
  ~475 palabras frente a ~445 del v1; identidad, cada término definido como en S.14 y su ancla, S anclado y declarado, intra
  como único residual); la frase *«split household-level items among the members of each household¹»*
  lleva la **nota al pie 1** (textual, sobre el reparto intra-hogar por `perfilpc.ado`: punto fijo por
  perfil edad-sexo, no per cápita; un niño de 0–4 recibe ~11 % del gasto en alimentos de un adulto de
  30–64 frente al 0.4 → 1 de la escala NTA; el piso con la escala es opción explícita, no aplicada);
  lista de nodos y enlaces del v2 con definición y escalar SCN de ancla (B.2n, B.3n, D.4, D.8, D.21−D.31,
  D.61−D.614, D.62+D.759, D.63, B.8n); apartado **«Anchoring and residual»** con las cifras leídas en
  runtime de `?cuenta=grupoedad` (Σ S sin ancla vs B.8n, brecha, modo, factor del recorte, S_ajuste =
  recorte − complemento, YA del motor vs S.14, intra por grupo con suma cero, residual máximo, Cpriv vs
  P.3, procedencia); pie con fuente, versión, vintage ENIGH y `data_updated`. La plantilla
  `metodo/plantilla.php` admite **notas numeradas** (`metodo_nota_ref`, `metodo_notas`: superíndice con
  ida y vuelta) y `cifras` (`metodoCifras` en `js/metodo-sankey.js` llena los `<span data-nta>`); estilos
  en `css/metodo.css` (nota a tamaño menor y mismo ancho; Sankey a 900 px para las ocho capas).
- **v1 retirado del sitio**: `/NTA` ya no pide `corte=grupoedad`; `SankeyNTA/sankey-grupoedad.json` lo
  sigue emitiendo el motor (otros consumidores) y el endpoint lo sirve si existe. Nada del motor se borra.
- **Punto 1 verificado (`nta_alqu`)**: `NTA.do` **no** re-reparte el consumo de alquiler imputado:
  `gas_pc_Alqu` llega de `Expenditure.do` ya repartido entre los miembros del hogar por `perfilpc.ado`
  (perfil edad-sexo, punto fijo) y entra a `Cpriv` tal cual (`gastoanualTOT`); `nta_alqu` (`jefe` |
  `motor`) gobierna solo el lado **ingreso**. Default sin cambio; **Δ Σ por grupo = 0**; el JSON v2 no se
  mueve. Queda documentado en el encabezado de `NTA.do`.
- **Deploy**: la Fase 3b-ter de `publicar-vps.sh` embarca `SankeyNTA/sankey-v2-grupoedad.json` y
  `NTA/{nta-grupoedad.json, nta-quinquenio-sexo.json, nta-identidad.txt}` (manifiesto del default
  7 → 11 archivos; `nta-persona.dta` no viaja); Gate 5-remoto exige el v2, `NTA/nta-grupoedad.json` y
  `nta-identidad.txt` (+3 rutas); el esqueleto de la Fase 6 sigue 15/15. `manifest.json` → v8.12.5,
  `data_updated` igual.
- **Gates**: `test-sitio-nta.{sh,js}` (job `sitio-nta`) valida el v2: ruta, default y `?corte=v2-grupoedad`,
  mismo conteo de nodos/enlaces que el JSON de origen (**52/174** cuando el origen es el fixture),
  `toolText` solo en nodos de grupo, `?cuenta=` byte a byte, 400/404 en lista blanca, cero literales en
  cinco archivos, y en Chrome headless nodos/enlaces idénticos como cadena (también en
  `getJSONData()`), cifras llenas desde la cuenta, nota al pie presente, `--png`. Fixtures:
  `05_scripts/fixtures/sankey-nta-grupoedad.json` pasa a ser el **v2 real** (corrida completa de `SIM.do`
  en `0f72606` que reprodujo el baseline v8.12.4; sha256 `fd2a699d…`), más `nta-grupoedad.json` y
  `nta-identidad.txt` de la misma corrida. El harness de seguridad cubre el default v2 y `?cuenta=`.
- **FLAG para v8.14 (no se toca aquí)**: el encabezado de `Households.do` debe mencionar el reparto por
  `perfilpc` (perfil edad-sexo, punto fijo), no «per cápita».

### Trabajo acumulado que entró con este tag (estuvo bajo `[Unreleased]` hasta v8.14.0)

Lo que sigue estaba registrado bajo `[Unreleased]` y queda incluido en el tag `v8.12.5` porque el tag es un
punto de `master` (`01_modulos/NTA.do` nace en `d70ef3d`, cuyo primer tag es v8.12.5; la página `/NTA` v1
entró en `93d97da`, v8.12.4, y aquí se registra junto a la cuenta que dibuja).

### Comandos — NTA-1: `01_modulos/NTA.do`, la cuenta de Transferencias Nacionales por individuo (2024)

- **`NTA.do`** (nuevo; `SIM.do` §3.2b, después de `Households.do`, con `anioenigh`): construye por persona la
  identidad NTA `C − YL = (τ⁺ − τ⁻) + (YA − S)` con lo que el motor ya tiene por persona (`households.dta`
  2024, anclado a SCN/LIF/PEF 2024) y las decisiones firmadas el 2026-10-27 sobre el memo NTA-0 (#38):
  S = residual del hogar repartido a adultos con ingreso ∝ (YL+YA) y anclado a `AhorroHog` (B.8n S.14);
  intra-hogar = único residual por persona (Σ por hogar = 0); especie (`SerEGob` por matrícula, `SaluGob`
  ∝ gasto privado en salud, resto de `ConGob` per cápita) como τ⁺ público; τ⁻ anclado a la recaudación LIF
  2024 (indirectos una sola vez, C a precios de comprador); pensiones fuera de YL hacia τ⁺ (PEF 2024);
  flujos financieros de `ing_mixto` fuera; alquiler imputado al jefe del hogar; remesas una vez. Parámetros
  declarados (`nta_anclaS`, `nta_alqu`, `nta_tauCash`, `nta_otorgado`, `nta_mixto`). Salidas en
  `users/<id>/NTA/` (`nta-persona.dta`, `nta-grupoedad.json`, `nta-quinquenio-sexo.json`,
  `nta-identidad.txt`) y el **Sankey v2** `users/<id>/SankeyNTA/sankey-v2-grupoedad.json` (contrato nuevo,
  48 nodos / 156 enlaces, conservación en todo nodo; el 31/79 de v1 y `/NTA` no cambian).
- **`SCN.ado` v8.2 (aditivo)**: lee del tabulado S.14 Hogares (`CSI_115.xlsx`, cuenta II.4) B.8b, B.8n, P.3 y
  P.4 (verificando el rótulo de cada fila y P.4 − P.3 = D.63) y registra `AhorroHog`, `AhorroHogB`,
  `TransfEspecie`, `ConHogS14` (+ `*PIB`). Un `master/SCN.dta` previo se enriquece una vez sin tocar el BIE.
- **Gate de sesión `05_scripts/test-nta-identidad.{do,sh}`** (runbook §11): identidad a 1e-9 relativo por grupo
  de edad y quinquenio × sexo, Σ intra = 0, Σ S = `AhorroHog`, JSON = base, y conservación por nodo del Sankey v2.
- Hallazgo (FLAG al motor, v9.x): el ancla de S exige un ajuste aditivo de 5,048 bn (Σ S micro = −3,147 bn vs
  B.8n 1,901 bn); el 61 % de `ing_mixto` (4,571 de 7,524 bn) son transferencias y flujos financieros escalados
  × `TaltimirSelf` = 6.15. Nada del `output.txt` ni de los 10 sankeys publicados cambia (gate de números verde).

### Comandos — NTA-1b: definiciones alineadas con S.14 antes de anclar; sin tapón (mismo PR #40)

La brecha Σ S micro vs B.8n era de definición, no de escala. Un commit por pieza, con Σ S medido tras cada una
(bn MXN 2024): antes −3,147 → (2) τ⁻ de hogares −2,509 → (3) impuestos a productos como ingreso −2,508 →
(4) D.8 −1,238 → (5) τ⁺ efectivo a D.62 + D.759 **+201** → (6) `ConGob` partido +201. Brecha final −89 % de
B.8n (> 15 %): **no se aplica ancla**; la descomposición restante va en el PR.

- **`NTA.do` v1.1**: `nta_anclaS` default **`off`** (el aditivo de NTA-1 queda como variante `aditivo`; nueva
  `multiplicativo`: factor sobre S de adultos sin contrapartida, cae a intra); el reporte abre con Σ S sin ajuste
  por grupo vs B.8n y el factor implícito. **τ⁻** = lo que los hogares pagan en S.14: ISR de personas físicas
  (asalariados + PF, LIF), cuotas (`cuotasTP` + infonavit una vez; `nta_cuotas` = `S14` D.61 − D.614 = 1,729 bn
  | `LIF` 566) e indirectos LIF; **fuera** ISR_PM y OTROSK (1,802 bn; `TmenFuera`, informativo). **`ImpProd`** =
  `ImpNetosProd` (D.21 − D.31, 2,176 bn) ∝ consumo privado entra a la identidad como ingreso
  (`C − YL − ImpProd − (τ⁺ − τ⁻) − (YA − S) − intra = 0`); de YA se saca lo que Altimir embebía de ImpNet en Yk.
  **`YA_d8`** = `AjustePension` (D.8, 1,270 bn) ∝ YL de quienes cotizan (`nta_d8`). **τ⁺ efectivo** × un factor
  global 1.717 a D.62 + D.759 (`nta_anclaTau` on). **`ConGob` partido**: individual = D.63 con perfil de edad
  (educación matrícula, salud ∝ gasto privado, resto per cápita) = τ⁺ en especie; colectivo = `ConGob` − D.63
  per cápita = τ⁺ colectivo; ambos en C público. `nta-identidad.txt` agrega S e intra por quinquenio × sexo.
- **Sankey v2.1** (`sankey-v2-grupoedad.json`, 50 nodos / 169 enlaces): tipos de ingreso + «Impuestos a
  productos» y «Derechos de pensión D8»; «Otros bienes públicos» → «Otros en especie» (con Educación y Salud
  públicas suma D.63) y «Colectivo per cápita»; «Ajuste ancla S.14» solo con `nta_anclaS = aditivo`.
- **`SCN.ado` v8.3 (aditivo)**: `SCNHogaresS14` generalizado a cuadro/fila/lado; lee además de `CSI_115.xlsx`
  D.61 (f. 117), D.614 (f. 127), D.8 (f. 169), D.62 (f. 131), D.759 (f. 151) y de `CSI_103.xlsx` D.21 (f. 25),
  D.31 (f. 26) → escalares `CuotasHogS14`, `ImpNetosProd`, `AjustePension`, `PrestSocHog`, `OtrasTransfHog`,
  `TauPubS14` (+ `*PIB`). Un `master/SCN.dta` de NTA-1 se completa solo (`update replace`).
- **Gate `test-nta-identidad.{do,sh}` v1.1**: identidad con `ImpProd` (5 + 36 celdas), Σ intra = 0, **sin ajuste
  de S activo** (un ancla es ROJO), anclas S.14 por construcción (Σ `CpubInd` = D.63, Σ `ImpProd` = D.21 − D.31,
  Σ `YA_d8` = D.8, Σ τ⁺ efectivo = D.62 + D.759) y nodos del contrato v2.1. `output.txt` y los 10 sankeys no cambian.
- FLAG al frente para v8.14: `TaltimirSelf` = 6.15 escala como ingreso mixto 4,571 bn de transferencias y flujos
  financieros (`ing_dona`, `ing_heren`, `ing_benef`, remesas crudas, `ing_prest`, `ing_otrocap`, `ing_ahorro`);
  `nta_mixto` default `crudo` se mantiene.

### Comandos — NTA-1c: YA anclado a S.14 dentro de `NTA.do`; ancla multiplicativa de S declarada (mismo PR #40)

- **`NTA.do` v1.2**: `nta_YA` ∈ {`motor`, `S14`} (default **`S14`**): el total de YA del motor (7,067 bn: neto de
  depreciación, sin el ImpNet embebido —pieza 3— y sin D.8 —pieza 4, que entra aparte—) se re-ancla a
  `YAHogS14` = B.2n + ⅓ B.3n + D.4 neto del sector hogares = **8,832 bn**, repartido ∝ YA del motor (misma
  distribución, otro nivel; factor 1.2498; el alquiler imputado se escala igual). Σ S sin ancla pasa de +201 a
  **+1,966.5 bn vs B.8n 1,901.0: brecha +3.4 %** (≤ 15 %), así que `nta_anclaS` = `auto` (default nuevo) resuelve
  a **`multiplicativo`** (factor **0.9667**); si la brecha superara 15 % resolvería a `off` con FLAG. El ancla queda
  **declarada, no escondida**: intra se calcula con S sin ancla (Σ intra = 0 en todos los modos), `S_ajuste` =
  S − S sin ancla (−65.5 bn) es el residual explícito de la identidad con ancla y en el Sankey v2.1 aparece como
  «Ancla S14 recorte» (66.9) / «Ancla S14 complemento» (1.4). Reporte: YA motor vs re-anclado por decil
  (D1 124→155, D10 2,709→3,386 bn) y S e intra por sexo y quinquenio.
- **`SCN.ado` v8.4 (aditivo)**: `SCNHogaresS14` lee además `CSI_115.xlsx` filas 69 B.2n (R/P), 70 B.3n (R/P) y
  95 D.4 (R/P y U/A) → `YAHogS14`, `ExNOpHogS14`, `MixNHogS14`, `RentaPropHogNeta` (+ `YAHogS14PIB`).
- **Gate `test-nta-identidad.{do,sh}` v1.2**: identidad **sin ancla** (5 + 36 celdas) y, con ancla, residual =
  `S_ajuste` declarado; Σ intra = 0; Σ S = B.8n cuando hay ancla; Σ `YA_base` = `YAHogS14` con `nta_YA = S14`;
  nodos del ancla reportados. `output.txt` y los 10 sankeys publicados no cambian (gate de números verde).
- **Decisión de Ricardo para v8.14 (FLAG del motor, registrado aquí)**: `Yk` de `Households.do` lleva el excedente
  de sociedades `ExNOpSoc` bruto (y resta la depreciación de toda la economía ∝ `ing_capital`) donde el sector
  hogares S.14 tiene B.2n + ⅓ B.3n + D.4 neto: **−1,765 bn** en el YA de los hogares (7,067 vs 8,832; factor 1.25).
  Magnitud en el Sistema Fiscal / deciles (YA del motor → re-anclado, bn): D1 124→155, D2 191→239, D3 257→322,
  D4 332→416, D5 418→523, D6 504→629, D7 640→800, D8 799→999, D9 1,092→1,365, D10 2,709→3,386 (misma
  distribución: el Gini de YA no cambia, el nivel sí). Junto con `TaltimirSelf` = 6.15 (4,571 bn de transferencias y
  flujos financieros dentro de `ing_mixto`), los dos se corrigen en el motor en v8.14; mientras, `NTA.do` los
  re-ancla localmente (`nta_YA = S14`) y los registra (`nta_mixto = crudo`).

### Institucional — página de método `/NTA`: el Sankey NTA de los hogares, como lo emite el motor

- **`/NTA`** (`04_1_simuladorfiscal.ciep.mx/NTA/index.php`, primera página de la futura sección de
  método; plantilla compartida en `metodo/plantilla.php`, hermanas = carpeta + entrada en
  `$METODO_PAGINAS` + ruta en el esqueleto): explica en inglés cómo se construye el Sankey NTA de
  los hogares (`Households.do` §"Sankeys NTA" → `visualizations/Sankey.do` → `SankeySumSim`), lista
  nodos y enlaces con su definición, y dibuja el corte por grupo de edad con la misma receta de los
  Sankeys de la portada (FusionCharts, `js/metodo-sankey.js`). Estática: sin «Calcular» ni selector;
  los datos los sirve **`jsonSankeyNTA.php`** (corte en lista blanca, lectura de
  `users/<id>/SankeyNTA/sankey-<corte>.json`, misma transformación que `jsonSankey*.php`). Cero
  números en el HTML/JS; el pie cita versión, ENIGH y fecha desde `DEPLOYED_COMMIT`.
- **Deploy**: `SankeyNTA/sankey-grupoedad.json` entra al manifiesto del default (Fase 3b-ter, que ahora
  admite subcarpetas y hace `chmod -R …X`), a `MOTOR_LECTURAS_VPS` (Gate 5-remoto) y `/NTA` al
  esqueleto de la Fase 6 (14 → 15). `manifest.json` gana `enigh_vintage` (→ `EnighVintage:` en
  `DEPLOYED_COMMIT`, Fase 4). Gates: `test-sitio-nta.sh` (+ job `sitio-nta` en CI: ruta, endpoint,
  sin literales, Sankey byte-idéntico al JSON del motor con Chrome headless, `--png`), casos de
  `jsonSankeyNTA.php` en el harness de seguridad, `verify_sitio_autocontenido.sh` con la ruta.
  El motor (`.ado`/`.do`) no cambia.

## [v8.12.3] — 2026-10-19

### Sitio — se restaura el parpadeo de las tablas, el refresco de los Sankeys y el reinicio de flags tras «Calcular»

- **Regresión de v8.12.2 (`f8c2dce`, #33).** El `$.ajax` de `calculaStata.php` ya traía un `complete:function(){…}`
  (reinicio de `moduloCambio`/`moduloCambioIva`, refresco de los 5 Sankeys, parpadeo `blink-1` de las
  tablas). v8.12.2 añadió un segundo `complete:` para cortar el reloj: en un objeto literal la última
  clave gana **en silencio** y el bloque original dejó de ejecutarse. Efectos para el usuario: ya no
  parpadeaban las tablas (señal de qué se movió), **los 5 Sankeys no se refrescaban tras «Calcular»**
  (se quedaban con los del escenario anterior) y los flags del submódulo no se reiniciaban (el
  siguiente «Calcular» volvía a correr `ISR_Mod.do`/`IVA_Mod.do`). Pasó el gate visual porque comparaba
  capturas del estado final y porque el Stata falso devolvía el mismo escenario.
- Fix: un solo `complete`; el corte del reloj (`CIEPCronometro.terminar()`) va dentro del original, en
  `stataCalcula.js` y `stataCalcula-en.js`. El efecto es el original: `blink-1` (1.0 s, opacidad) sobre
  todas las `.table`, retirado a los 1500 ms; no se rediseña nada.
- **Test de efectos transitorios** (`05_scripts/test-sitio-transitorios.{sh,js}`, job `sitio-transitorios` en CI):
  Chrome headless muestrea el DOM cada ~100 ms tras el POST — las tablas adquieren y pierden `blink-1`
  (≈ 1.5 s), se refrescan los 5 Sankeys, los flags vuelven a 0 — y repite las pruebas de v8.12.2
  (valor del reloj por flujo, «Finalizando…», spinner apagado y flags conservados tras un 429), en ES y EN.
  Probado en rojo contra `c921bf6` (6 fallos) y en verde. Fixture: `05_scripts/fixtures/output-default.txt`.
- Solo front-end: sin cambios al motor ni a los números. `manifest.json` → v8.12.3.

## [v8.12.2] — 2026-10-19

### Sitio — el cronómetro del «Calcular» dice la verdad

- La cuenta regresiva mostraba 35 s en todos los casos (literales en `index.php`/`index-en.php`
  y en `stataCalcula{,-en}.js`) cuando el «Calcular» principal tarda ~20 s en el VPS y los
  submódulos ISR/IVA ~30–40 s. Ahora: **una constante por flujo en un solo archivo**,
  `js/config-tiempos.js` (`CIEP_TIEMPOS`: principal 25, isr 40, iva 40, isr_iva 50; valor =
  tiempo medido + ~25 %), y el flujo se elige por los flags que el clic manda (`moduloCambio`,
  `moduloCambioIva`). Medición por flujo (3 corridas con Stata real) e inventario de botones en
  `02_governance/perf/cronometro-calcular-2026-10-19.md`.
- **El reloj es cosmético; el fin lo dicta la respuesta.** Si el run termina antes, los
  resultados aparecen y el reloj se corta; si tarda más que la cuenta pasa a «Finalizando…» /
  «Finishing…» (antes se quedaba en «1s»). Corrige además que el aviso solo se apagaba en la rama de
  éxito: ante un error (p. ej. el 429 del freno) quedaba encendido. Los mensajes del 429 no cambian.
- `05_scripts/verify_cronometro_unico.sh` (en CI): falla si reaparece un literal de segundos
  suelto o si una página carga `stataCalcula*.js` sin `config-tiempos.js` antes.
- Solo front-end: sin cambios al motor ni a los números. `manifest.json` → v8.12.2.

## [v8.12.1] — 2026-10-18

### Correcciones — el deployment embarca lo que el motor lee + «Calcular» de humo automático

- **Incidente (2026-10-18, deploy v8.12):** `_precache_manifest.ado` lee `data_updated` de
  `${SIMROOT}/05_scripts/manifest.json`; `publicar-vps.sh` nunca embarcó `05_scripts/` y en el VPS
  «Calcular» abortó con `r(601)` (el candado hizo lo correcto) hasta copiar el archivo a mano.
  Health check y esqueleto habían pasado: segundo deploy consecutivo que rompe el run interactivo y
  solo lo cacha un clic humano.
- `publicar-vps.sh`: la Fase 3a embarca `05_scripts/manifest.json` al deployment; **Gate 5-remoto**
  nuevo, antes del swap: cada ruta que el motor web lee bajo `${SIMROOT}/` (`MOTOR_LECTURAS_VPS`,
  inventario en el runbook §12) existe en el destino y `manifest.json` es idéntico al local; si
  falta algo, muere con `current` intacto.
- **Fase 6 — «Calcular» de humo real** (`05_scripts/humo-calcular.sh`, nuevo): tras el swap y 125 s
  de espera por el caché de realpath de PHP, POST del escenario default a `calculaStata.php` como
  lo hace el JS (campos armados desde `cargaDefault.php` con el mapeo de `perfilar-web.py
  escenario`), timeout 120 s, sondeo de `checkStataStatus.php` como señal de vida; aserta números
  en la respuesta (el `output.txt` de la sesión) y los 5 `jsonSankey*.php` **de esa sesión** (no el
  fallback `ciepmx`). Si falla → rollback automático (Fase 7) con la cola del log de Stata de la
  sesión. Cronometrado y reportado. Flags `--skip-humo` y `--sin-espera-realpath`.
- `test-humo-calcular.sh` (nuevo, corre en CI en el job `sitio-seguridad`): rojo/verde del humo con
  `php -S` + Stata falso — verde con `output.txt` + 5 sankeys; rojo si el motor aborta sin
  `output.txt` (el incidente) y rojo si deja `output.txt` sin sankeys.
- `perfilar-web.py escenario` acepta un archivo (`output.txt` o el JSON de `cargaDefault.php`).
- Runbook: §6 (el clic «Calcular» ya es del pipeline; el gate humano queda para lo que el humo no
  prueba), **§12 regla nueva** — un `.ado` del motor solo lee lo que `publicar-vps.sh` embarca; lo
  que no embarca, se embarca o no se lee — con el inventario completo de lecturas bajo `${SIMROOT}/`.
  FLAG: `checkStataStatus.php` depende de un `<id>.done` que nadie escribe (el JS no lo usa).
- Sin cambios al motor ni a los números: `manifest.json` → v8.12.1, `data_updated` sin cambio.

## [v8.12.0] — 2026-10-18

### Institucional — sitio: triage de Dependabot y freno de abuso de CPU (v8.11c, 2026-10-18)

- **Dependabot: 3 avisos abiertos → 0, sin bumps.** Los tres apuntaban a `grunt`, devDependency
  del `package.json` del plugin vendor `plugins/idle-timer/` (herramienta de build que el sitio
  no ejecuta ni sirve). Decisión de Ricardo: en vez de mantener al día un toolchain que nadie
  corre, se borra del vendor lo que no se sirve — `idle-timer/` pierde `Gruntfile.js`,
  `package.json`, `bower.json`, `.sln/.suo`, `test/`, `demos/`, `libs/`, `src/` (queda `dist/` +
  licencia/README/CHANGELOG) y `apexcharts/` pierde `package.json` y `samples/` (queda `dist/`);
  302 archivos. Sin manifest no hay aviso. `verify_sitio_autocontenido.sh`: todo lo que
  referencian `index.php`, `index-en.php` y `css/` sigue existiendo en git. (`idle-timer` no lo
  carga hoy ninguna página; `font-awesome` trae 17 MB de `scss/less/svgs/sprites` que tampoco se
  sirven pero son distribución, no toolchain: ambas quedan como decisión aparte.)
- **Hero: markup muerto fuera.** El `<img src="images/top-slide-2-v2b.png">` que el gate de
  auto-contención toleraba vivía dentro de un `<!--div class="carousel-item"> … div-->` (el
  carrusel pasó de 3 a 2 pasos): el navegador ni lo parsea ni lo pide. Confirmado con capturas
  del hero antes/después idénticas (4 slides en el DOM, mismas 4 imágenes pedidas); se borra el
  bloque comentado en `index.php` e `index-en.php`, se retira la entrada de
  `sitio-referencias-rotas-conocidas.txt` y el gate ahora ignora los comentarios HTML (y ya no
  truena con arrays vacíos en el bash 3.2 de macOS).
- **Freno de abuso de CPU en `calculaStata.php`.** Cada «Calcular» lanza un Stata (~35 s de CPU)
  y no había tope: N peticiones = N Stata en paralelo. Ahora, antes de lanzar Stata y después
  de validar las entradas: `MAX_STATA_SIMULTANEOS = 3` (guardia real contra DoS por CPU) y
  `LIMITE_CORRIDAS_POR_IP = 100` por `VENTANA_SEG = 600` (constantes en `config.php`; firmados
  el 2026-10-18 — 100 porque las aulas y talleres del CIEP salen por una sola IP pública).
  Única exención: `127.0.0.1` (`IPS_EXENTAS_LIMITE_IP`) queda fuera del tope por IP, no del de
  simultáneos, que protege la CPU y aplica a todos. PHP plano, contadores por archivo con `flock` en `users/_ratelimit/`, sin
  dependencias. Exceso → HTTP 429 con `Retry-After` y JSON `{error, error_en, motivo,
  retry_after}`; el front-end (`stataCalcula.js` y `-en.js`) muestra el mensaje, apaga el
  spinner y conserva los flags del submódulo ISR/IVA para el reintento. La IP es `REMOTE_ADDR`
  (no las cabeceras `X-Forwarded-For`, que el cliente falsifica). Lo inválido sigue
  respondiendo 400 sin consumir cupo. Pruebas rojo/verde con `php -S` + Stata falso en el PR:
  la petición 101 de una IP → 429; 101 desde 127.0.0.1 → todas pasan; el 4º Stata simultáneo →
  429 aunque venga de 127.0.0.1; pasada la ventana vuelve a pasar.

### Comandos — v8.12 fase 2a: precache de lo invariante (mejora de rendimiento sin cambio de números)

- **El «Calcular» pasa de ~32 s a ~19 s** (local, StataNow 19.5; el reparto relativo es lo
  transferible al VPS) sin mover un número: lo que no depende del formulario y se recalculaba
  en cada clic (perfil de fase 1, `02_governance/perf/perfil-web-2026-10-18.md`) se precomputa
  UNA vez por corrida batch y viaja como producto en `users/<id>/cache/`, con sello y el mismo
  candado que los `*RECprom`: sin cache no se calcula; nunca se usa "lo que haya".
  - `Precache` (nuevo; `SIM.do` §5.1b, después de `PEF` y antes de `GastoPC`): escribe
    `PEF_divCIEP_iftransf_gfeq0.dta` (colapso anual de `master/PEF.dta`, 3.56 M filas, en
    **pesos corrientes** — el % PIB con `pibY`, que sí depende de CRECPIB/CRECDEF, se calcula
    al vuelo), `GastoPC_base_<aniope>.dta` + `_mat.dta` (micro de `GastoPC` §2 y sus matrices
    de **conteos**), `REC_<var>.dta` (los 24 colapsos de `*RECprom`) y `sello.txt` (version,
    data_updated, commit, generado; por item: archivo e insumos con bytes).
  - `_precache_usa` (consumidor): aborta con receta si falta el sello o el item, si el
    `data_updated` del `manifest.json` ya no es el del sello, o si un insumo cambió de bytes.
    Probado: sin cache, sin item, insumo cambiado y `data_updated` distinto → r(601) con
    mensaje y sin números viejos.
  - `PEF, cache|precachear(dir)`; `GastoPC, cache|precachear(dir)`; `FiscalGap` usa `PEF, cache`
    y `_FGreccol`. Sin opción, `PEF` y `GastoPC` calculan como siempre.
  - `publicar-vps.sh`: Fase 3b-bis también propaga `users/ricardo/cache/` (~210 MB) y el
    Gate 5 exige sello, items y `data_updated` == manifest.
  - `Web.Stata.do` §3.2 (O-1 del perfil): se retira la llamada muerta a `PEF` que vivía
    dentro de un comentario de bloque y nunca corría.
  - Compuertas: `output.txt` del «Calcular» default **byte-idéntico** con y sin cache; batch
    completo con `entidad` vacío → `output.txt` byte-idéntico a v8.11.0 (`566c31ea…`). Los
    5 `sankey-*.json` diferían en el flujo web en el 15º–16º dígito (orden de acumulación de
    las sumas ponderadas de `SankeySF.do`, que dependía del historial del `sort`): resuelto en
    esta misma versión con el orden determinista de abajo (FLAG-7 del reporte
    `02_governance/perf/fase2-precache-2026-10-18.md`).

### Comandos — v8.12 fase 2b: forma cerrada, encendida por default

- `global algebra "algebra"` (`SIM.do` §0.4 y `Web.Stata.do` §0; `""` = la ruta micro de
  siempre). En el mismo `.ado` para batch y web (sin fork): `FiscalGap` §3 obtiene los
  totales HH del año base como Σ escalares/100·pibY/deflator (con el mismo `PIBDeflactor` de
  `GastoPC` §1) en vez de recorrer la micro, y `GastoPC` §3–6 genera `Educacion`, `Salud`,
  `Pensiones` y `Energia` en una sola pasada (`_GPCsuma`/`_GPCcierra`) en vez de 26 `replace`.
- Medido antes de encenderlo (3 corridas web + 1 batch): **0 diferencias al byte** en
  `output.txt` y en los 5 sankeys respecto al interruptor apagado; los totales HH coinciden
  con la ruta micro a ≤ 3.8e-16 relativo (1–2 ulp). Decisión de Ricardo (2026-10-18) con esa
  tabla enfrente: encendido por default, con la tolerancia de abajo como red.

### Correcciones — sankeys con orden de acumulación determinista (FLAG-7) y gate nuevo

- `SankeySF.do`: `sort <corte> folioviv foliohog numren` (clave única) antes de cada
  `collapse` ponderado (ejes 1 y 4, ejes 2–3 por `to`/`from`, y los de entidad). Antes, el
  orden de los empates del `sort` interno del `collapse` dependía del historial de la
  sesión (`c(sortrngstate)`, documentado en el runbook §9) y los JSON cambiaban en el
  15º–16º dígito con cualquier cambio del pipeline. Antes de los dos `sort` grandes se hace
  `keep` de las columnas que el `collapse` suma (lo demás se descartaba igual).
- **Gate declarado desde v8.12.0:** `output.txt` byte-idéntico; JSON de sankey dentro de
  **1e-9 relativo**. Medido contra v8.11.0: `output.txt` byte-idéntico (web y batch);
  sankeys Δ relativo máximo 1.1e-13 (web, drift único del nuevo orden) — el del batch se
  anota en el reporte de fase 2 §3. «Calcular» default: ~32 s (v8.11.0) → **~16.5 s**.

## [v8.11.0] — 2026-10-17

### Institucional — el sitio del Simulador entra a git completo (v8.11a, 2026-10-16)

- **Fin de los fantasmas del VPS.** Tres deploys seguidos (v8.8, v8.9, v8.10) tropezaron con
  archivos que `index.php` enlaza y git no versionaba; el deploy v8.10 (2026-10-16) desde el
  worktree del release sirvió el sitio **sin `css/`, `js/` ni `plugins/`** (404) con el health
  check verde, hasta completarlo a mano desde Dropbox. Causa: `.gitignore` ignoraba
  `**/04_1_simuladorfiscal.ciep.mx/**` entero salvo `health.php` (desde `360ebae`), así que un
  checkout fresco nunca tuvo el sitio. Decisión de Ricardo: **`04_1_simuladorfiscal.ciep.mx/`
  se versiona completo** — 13 PHP, `css/` (5), `js/` (14), `images/` (86, incluidas las 10
  `TE_*`/`GastoPC_*` como snapshot), `plugins/` (1,991, vendor versionado como pin de
  reproducibilidad), `favicon.ico`, `.htaccess` — tal cual estaba en el 04_1 del clon de Dropbox
  que reparó producción. Siguen fuera `ssl/`, `logs/`, `*.log` y `simuladorfiscalv7.png`
  (huérfano de 1.5 MB). `config.php` auditado: detecta rutas local/VPS, sin credenciales.
  Inventario (77 archivos enlazados, 1 en git, 74 fantasmas) y prueba de auto-contención en
  `~/CIEP_Simuladores/diag-v8.11a-fantasmas-2026-10-16/`.
- **Revisión de seguridad de los 13 PHP al volverse públicos (compuerta de Ricardo).** Dos
  hallazgos explotables en `calculaStata.php`, presentes en producción desde el origen del sitio:
  (1) **inyección de código Stata** — los ~150 valores del formulario se interpolaban sin
  validar en el `.do` que Stata ejecuta como `www-data` (`INGRESOS0=0\nshell …` corría comandos);
  (2) **path traversal en `idSession`** (`../x` creaba directorios y escribía el `.do` fuera de
  `users/`). Corrección en `config.php` (`lee_idSession()`: alfanumérico 1-32; `lee_numero()`:
  solo números, `12%`→`12`, ausente→`0`; lo demás → HTTP 400 sin correr Stata) aplicada en
  `calculaStata.php`, `checkStataStatus.php` (también `ctype_digit` del pid antes de `ps -p`) y
  los cinco `jsonSankey*.php` (inválido → escenario default). Endurecimientos menores:
  `cargaDefault.php` sin `eval()` (parser con salida byte-idéntica), `logCalcular.php` sin
  inyección de renglones ni rutas del servidor en la respuesta, `rm -f` por shell → `unlink`.
  Tabla input→sanitización→veredicto y pruebas (php -S + Stata falso, código viejo vs nuevo) en
  `diag-v8.11a-fantasmas-2026-10-16/seguridad-php.md`. Fuera de alcance: rate-limit de
  `calculaStata.php` (DoS por abuso de CPU). **Mientras no se despliegue este PR, producción
  corre el código vulnerable.** Se retira `js/pages/charts-v2.js_` (variante 2024 sin enlace).
- **`publicar-vps.sh`:** Gate 6 — `manifest.version` debe ser vN.M.x del deployment pedido
  (el deploy v8.8 shipeó código v8.7.2); Gate 7 — el docroot coincide con `git ls-files 04_1/`
  (nada versionado falta, ningún fantasma sobra) y los activos de humo existen; Fase 6 — además
  de `health.php` y el commit, un activo por clase (css, js, plugins, imagen, favicon,
  `cargaDefault.php`, `jsonSankey.php`) debe responder 200 o hay rollback; Fase 1b — mensajes
  con la receta exacta de `Graphs_TE.do`/`Graphs_PC.do` y aviso de commitear las gráficas
  refrescadas.
- **`test-maquina-virgen.sh --download --from <tag> [--into <dir>]`:** baja (con `gh`, sin
  Stata) los assets de otra Release a su `local_path` del manifest con SHA verificado contra
  el manifest local — para el huevo-y-gallina de un release cuya Release aún no existe y para
  poblar `raw/` de un worktree sin copiar de otro clon.
- Runbook: §1 checklist del sitio y receta «Gráficas del sitio»; §3 `--from`; §4 tabla de
  gates locales; §5 curl del esqueleto; gotchas nuevos. `verify_gitignore.sh` con los asserts
  invertidos para `04_1/`.

### Institucional — retiro de la capa NL de la era del runner (v8.11b, 2026-10-16)

- **Se retira de `master` la capa NL-0.4.x** (39 rutas): los drivers `01_modulos/EntidadNL.do`,
  `FederacionNL.do`, `PIBDeflactorNL.do` y `PoblacionNL.do`; `01_modulos/nl-assets/` completa
  (lectores `nl-bie.do`/`nl-fed.do`, `nl-html.do`, `nl-identidad.do`, `actualizar-nl.do`,
  plantillas HTML, `nl-datos.js`, identidad CoNL, `nl-manifest.json`, `federacion-sello.json`,
  bitácora y `pobproy_quinq1.csv`); `actualizar-nl.sh` y `publicar-conl.sh`; el runner Windows
  `windows/` (instalador, `actualizar-nl.ps1`, verificador, README); y `DIAGNOSTICO_NL.md`.
  **Por qué:** la capa quedó superada por el motor `global entidad` (v8.8–v8.10: `SIMentidad`,
  `Poblacion`/`PIBDeflactor` por entidad, `compuertas-entidad.*`) y su código en `master` no podía
  correr: sus scripts apuntaban al worktree `SimuladorCIEP-NL` y el runner clonaba
  `feature/entidad-nl`, rama que ya no existe. Nada se pierde: la capa entera, en su versión más
  reciente (NL-0.5.x/0.6.0, espejo del sitio, `nl-fuentes`), está archivada en la rama
  **`archive/entidad-nl-capa-y-espejo`** (b9ac315, 2026-10-16), de la que `master` solo
  difería por dos ediciones mecánicas (62ec15d, a99eb19). El motor no se toca: lo prueban la
  corrida completa de `SIM.do`, `compuertas-entidad.sh` (Nuevo León) y `publicar.sh --check`
  tras el retiro (evidencia en `~/CIEP_Simuladores/diag-v8.11b-retiro-capa-2026-10-16/`).
- **`TasasEfectivasMicro.ado` queda huérfano a propósito.** Su único llamador era
  `EntidadNL.do`; se conserva intacto en la raíz (v1.1.0) hasta su re-cableo al motor vía
  `SIMentidad` en v8.13. No es un olvido del barrido.
- Citas que se conservan como historia: `DatosAbiertos.ado` §4.7 y `TasasEfectivasMicro.ado`
  citan `DIAGNOSTICO_NL.md`; `PIBDeflactor.ado` y su `.sthlp` hablan de `master/PIBDeflactorNL.dta`
  (base por entidad del motor, no de la capa); `compuertas-entidad.{sh,py}` aceptan un
  `statajson_entidad-nl.json` como testigo opcional. Runbook de deploys: el paso 8 del checklist
  ya no avisa a la capa NL (merge de cadencia).

### Corrección — restaura el run interactivo nacional («Calcular»), roto desde v8.10.0 (hotfix 2026-10-17)

Restaura el run interactivo nacional del sitio («Calcular»), roto en producción desde el deploy
de v8.10.0 (2026-10-16). Producción quedó estable con el rollback a v8.9 (`current → v8.9`)
mientras se preparó la corrección; se despliega con v8.11.0 (deployment nuevo `v8.11`, §4b),
junto con el sitio versionado y el retiro de la capa. El endpoint, que con el pin v8.10.0 seguía
sirviendo el `PIBDeflactor.ado` roto, se re-publica en v8.11.0.

### Incidente

- Toda corrida del VPS, incluida la nacional (`global entidad` vacío; el `.do` generado no
  menciona INPC ni entidad), moría al cargar `PIBDeflactor.ado` con `r(7102)`
  `IndentationError: expected an indented block after function definition on line 1`. El
  archivo del deployment era byte-idéntico a git: no hubo corrupción.
- **Causa.** `deff8c9` (v8.10.0) añadió al final de `PIBDeflactor.ado` el bloque `python:` de
  nivel superior que define `inegi_inpc_entidad` (INPC por entidad federativa). Un bloque de
  nivel superior se ejecuta **al cargar el `.ado`**, así que también lo pagaba el camino
  nacional. Y el entorno de producción no es el de validación: el VPS corre **Stata/MP 17.0
  revisión 17-ene-2022** (binario de dic-2021) con **Python 3.10.12** (Ubuntu 24.04; el
  `python3` del sistema es 3.12.3, pero Stata quedó ligado a la libpython 3.10 del Ubuntu
  anterior); los agentes validan en **StataNow 19.5**. Esa revisión de Stata 17 no parsea
  bloques python multilínea con Python ≥ 3.10 (incompatibilidad conocida de las revisiones
  tempranas de Stata 17 con el parser de Python 3.10, Statalist #1686450): el `def` llega a
  Python sin su cuerpo. Verificado en esta sesión: el mismo `.ado` carga sin error en
  StataNow 19.5 y en **Stata/MP 17 revisión 21-may-2024** (la Mac de Ricardo) con Python
  3.9, 3.10, 3.11, 3.12 y 3.13; y en el VPS (consulta de solo lectura: `about`,
  `python query`) la revisión es la de ene-2022.

### Correcciones

- **`AccesoINPCEntidad.ado` (nuevo, v1.0):** el programa `AccesoINPCEntidad` y su bloque
  `python:` (`inegi_inpc_entidad`, `import requests`) salen de `PIBDeflactor.ado` a su propio
  archivo, **byte a byte** (sin cambios en la lógica ni en la definición). La pereza la da el
  autoload de Stata: el `.ado` solo se carga —y el bloque solo se manda a Python— cuando
  `UpdatePIBDeflactor` lo invoca, es decir, en la rama de entidad federativa. Con `entidad`
  vacío, Stata no envía ni un byte de la maquinaria de entidad a Python en ningún momento del
  ciclo de vida de `PIBDeflactor.ado` (que ya no contiene código Python). `PIBDeflactor.ado`
  v8.2.1 (solo encabezado + retiro del bloque); `PIBDeflactor.sthlp` cita el comando.
- **Endpoint:** `AccesoINPCEntidad.ado` entra a `manifest-endpoint.toml` y a los `.pkg` cuya
  clausura incluye `PIBDeflactor` (PIBDeflactor, LIF, PEF, SCN, SHRFSP, DatosAbiertos; Gate 7).
- No se toca la lógica numérica del deflactor nacional ni la metodología de entidad.

### Compuertas (evidencia en `~/CIEP_Simuladores/diag-v8.10.1-hotfix-2026-10-17/`)

- **Nacional byte-idéntico:** `SIM.do` completo con `entidad` vacío (`nographs`+`output`,
  StataNow 19.5 SE, 1 procesador, semilla 1111, bootstrap 250, `raw/`/`master/` clonados del
  worktree del release) → TOUCH-DOWN, 0 `r()`; `output.txt` (`566c31ea…`) y los 5
  `sankey-*.json` **byte-idénticos** a las corridas 1 y 2 del release v8.10.0 y a la de v8.11b
  (`corrida-nacional/sha256.txt`). Tras la corrida, `program dir` no lista `AccesoINPCEntidad`.
- **Parseo perezoso (estructural):** la misma llamada nacional que hace `LIF.ado`
  (`PIBDeflactor, anio(2027) nographs nooutput`) con el `.ado` del hotfix deja `python query`
  en `initialized no` y `AccesoINPCEntidad` sin cargar (`program list` → r(111)), en 19.5 y en
  Stata 17; con el `.ado` de v8.10.0 la misma llamada deja Python `initialized yes` (el bloque
  se ejecutó al cargar aunque `entidad` esté vacío). Prueba fuerte en Stata 17: con un Python
  **inutilizable** (3.14, que Stata 17 no inicializa: `python:` → r(7100)) el `.ado` viejo
  falla al cargar (`r(7100)`) y el del hotfix completa el run nacional (`estructural/`).
- **Entidad sigue vivo:** `PIBDeflactor if entidad == "Nuevo León", update` en 19.5 (y en
  Stata 17 rev. 2024 + Python 3.12) carga `AccesoINPCEntidad`, ejecuta el bloque (INPC
  entidad 19, serie 902690, 99 meses, último 2026/09; `inpc_19.meta`) y construye
  `PIBDeflactorNL.dta` (`entidad-sandbox/`).
- `publicar.sh v8.10.1 --check`: Gates 1, 3, 4, 5, 6, 7 verdes (Gate 4: 11 `.ado`, 8 `.sthlp`,
  8 `.pkg`); Gate 2 falla solo porque el tag anotado `v8.10.1` lo crea el ritual; Gate 8
  informa que la Release aún no existe (esperado).
- **No verificado aquí (ritual de Ricardo):** que «Calcular» revive en el VPS con Stata 17
  rev. ene-2022. Esta sesión no corrió Stata en el VPS (decisión de Ricardo).

### FLAGs (reportados, no resueltos aquí)

- El endpoint Cloudways (`net install`) sirve el `.ado` roto con pin v8.10.0 hasta el ritual.
- **Stata 17 (prod) vs StataNow 19.5 (validación)** es un hallazgo mayor para el plan v9.0:
  la revisión del VPS no corre **ningún** bloque python multilínea con su Python 3.10 —hoy el
  flujo web no carga `AccesoBIE.ado` ni `ensure_asset.ado` (ambos con bloques así), pero
  cualquier `.ado` nuevo con Python los rompería igual. Dos salidas, ambas fuera de este PR:
  `update all` de Stata 17 en el VPS (la revisión 21-may-2024 carga estos bloques con Python
  3.10) o validar también en Stata 17 antes de cada deploy.
- `SIMentidad.ado` (que `PIBDeflactor` llama en la rama de entidad) no está en
  `manifest-endpoint.toml` ni en ningún `.pkg`: un investigador externo con `net install` no
  puede correr la rama de entidad (preexistente; Gate 7 no lo ve porque no es comando publicado).

## [v8.10.0] — 2026-10-16

Release **menor** (`versionado-y-git.md` §3.2). Consolida lo que entró a `master` después de
v8.9.0: el PR **#23 `feat/ciclo-entidad`** (ciclo de vida de entidad) y seis commits directos
(`62ec15d`…`0692d9c`: retiro de `SIMroot`, `SIM.do` §0.4 sin parámetros de entidad ni
`bootstrap`, retiro de `SIM-local.do`, retiro de las fuentes congeladas y del ancla,
`PIBDeflactor` por entidad y bootstrap de 250 réplicas en la corrida), más las correcciones
de abajo y el rediseño del consumo de las réplicas (`global bootstrap` restaurado, semilla
versionada, `FiscalGap` sobre el promedio de las réplicas). **No es release de datos**: `data_updated` no cambia y los 26 assets del manifest
siguen siendo los mismos (el manifest de v8.9.0 declaraba 27: `fuentes-2026-10-06.zip` salió
en el retiro de las fuentes congeladas). No es v9.0.0: la versión 9 se reserva para cambios más
profundos (decisión de Ricardo, 2026-10-16). Deploy del VPS por §4b del runbook (minor:
deployment nuevo `v8.10`).

**Régimen de la corrida desde este release: fuentes vivas, sin ancla.** El motor descarga
siempre en vivo de INEGI y SHCP; el `output.txt` publicado es el del día de la corrida, no hay
SHA contra el cual medirlo ni se calcula delta contra v8.9.0. Las menciones a «el ancla» en las
entradas fechadas antes del 2026-10-15 (ciclo de vida de entidad, v8.9.0 y anteriores) describen
el régimen que existía entonces y se conservan como historia.

### Cambio declarado en los números publicados (sin ancla que lo mida)

Regla de la casa: nada cambia en silencio. Con respecto a v8.9.0, la corrida de `SIM.do` y sus
salidas cambian por cuatro causas que **no se pueden separar contra una referencia** (ya no hay
ancla):

1. **Errores estándar con `bootstrap(250)`.** Cada perfil de `PerfilesSim.do` (35 llamadas a
   `Simulador` con `reboot bootstrap(250)`) y los perfiles ENIGH de `Expenditure.do` y
   `Households.do` (`reboot boot(250)`) reportan EE e IC 95 % (normal y percentil) en el **log de
   la corrida**; antes no tenían bootstrap. `Simulador` fija el estimador puntual en la muestra
   completa, así que el puntual no depende de B. **`output.txt` no gana líneas de EE/IC**: `Simulador`
   las imprime a consola, fuera del log `output` (verificado en la corrida de este release: cero
   líneas de EE/IC en `output.txt`). La corrida es **más larga** (esperado, no es un cuelgue).
2. **Fuentes vivas.** INEGI (BIE, tabulados CSI) y SHCP revisan sus series: los valores que
   dependen de ellas (PIB del SCN, deflactores, recaudación observada, LIF/PEF de Datos Abiertos)
   pueden moverse respecto a v8.9.0 sin que el código cambie, y con ellos `output.txt` y los JSON.
3. **`Households.do` reactiva** el ingreso laboral ROW, las cuotas a la seguridad social y la
   variable `Ciclodevida` (`Yl + Yk + remesas + ROW − gasto`), antes comentados; ahora pasan por
   `Simulador` y, con `$output` activo, añaden sus bloques `INCD*`/`APORT*`/`PROY` a `output.txt`
   (el sitio lee el último de cada clave, el de `AportacionesNetas`, §7.3).
4. **`FiscalGap` consume el promedio de las 250 réplicas, no una réplica suelta.** Hasta v8.9,
   la proyección de ingresos (4.2) y gastos (5.2) de `FiscalGap` leía
   `users/ricardo/bootstraps/1/<var>REC.dta`: la única pasada con `bootstrap(1)`. Desde este
   release lee `<var>RECprom.dta`: el promedio por año de las 250 réplicas (misma convención que
   `ProyGraph` usa desde `Simulador` v2.0 para la proyección puntual). La brecha fiscal, el
   bloque `GASTOSPC`/`PROY` que de ahí sale y los Sankeys que dependen de `FiscalGap` cambian
   en el orden del sesgo bootstrap de los perfiles: pequeño, no cero (comparación informativa
   sobre el REC de CFE: la media de las 250 réplicas difiere de la pasada única de v8.9 —la del
   6-oct, con otras fuentes— en menos de 0.03 % en todos los años). **Se declara; no hay ancla
   contra la cual medirlo.**

### `global bootstrap` restaurado, semilla versionada y escenario base de `FiscalGap` (`44da4ed`)

Decisión de Ricardo (2026-10-16, firmada): se restaura el global y se rediseña el consumo.

- **`SIM.do` §0.2:** `global bootstrap "250"` (réplicas de `Simulador` en `PerfilesSim.do`,
  `Expenditure.do` y `Households.do`; las 45 llamadas pasan `bootstrap($bootstrap)`),
  `global seed "1111"` + `set seed $seed` y `global idbase "$id"`. **Semilla 1111** porque es la
  que `Simulador` (y `Perfiles`) fijan por llamada desde v1.x: las réplicas de este release son
  las mismas que las de la corrida `0692d9c`, y la compuerta de determinismo de abajo las
  reproduce. `Simulador` `seed()` deja de ser un entero fijo: vacío = `$seed` del panel (1111 si
  no hay panel); el bloque `legacy` usa la misma semilla. **`SIM.do` §7 (`AportacionesNetas`)
  sigue en `bootstrap(1)`**: es la misma llamada de `Web.Stata.do` y de esa pasada salen los
  `APORT*` que el sitio dibuja; no se cambia el contrato del sitio aquí.
- **`PerfilesSim.do` §8 (nuevo prepaso):** tras los perfiles, colapsa cada `<var>REC.dta`
  (250 réplicas × 101 años) a su promedio por (`modulo`, `anio`, `aniobase`) y lo guarda como
  **`users/<id>/bootstraps/<bootstrap>/<var>RECprom.dta`** (mismo directorio que las réplicas,
  sufijo `prom`, columna `replicas` = B; un `collapse` por variable, cero réplicas adicionales).
  Con B = 1 el promedio es la única pasada.
- **`FiscalGap` 4.2 y 5.2:** leen `<var>RECprom.dta` de `users/<idbase>/bootstraps/<bootstrap>/`
  (programa `_FGrecprom`). **Sin fallback silencioso:** si falta `global bootstrap` aborta con
  r(198) y si falta el producto aborta con r(601) diciendo exactamente qué correr (`SIM.do` con
  `global bootstrap "<B>"` e id `<idbase>` desde §3). **`users/ricardo/` fijo desaparece** del
  motor: `idbase` = `$idbase` (local: el propio `id`; vacío = el `id` de la sesión).
- **`Web.Stata.do`:** `global bootstrap "250"` y `global idbase "ricardo"` (el escenario base
  publicado). **`publicar-vps.sh` Fase 3b-bis** sincroniza solo `*RECprom.dta` (las réplicas
  crudas pesan ≈ 0.8 GB con B = 250) y el Gate 5 exige que existan para la B de `Web.Stata.do`.
  No probado contra el VPS en esta sesión (el ritual es de Ricardo).
- Consumidores de `bootstraps/` que **no** cambian (clasificados): `Perfiles.ado` y
  `CuentasGeneracionales.ado` (sus llamadas en `SIM.do` están comentadas; opción `bootstrap()`
  propia), `05_scripts/test-simulador-dorado.do` (test dorado, B = 1 por diseño sobre
  `users/dorado_*`), `Simulador.ado` (escribe y lee con su propia opción).

### Correcciones

- **Default de `entidad` (D1).** Entre `62ec15d` y `0692d9c` el default versionado de
  `global entidad` en `SIM.do` §0 quedó en `"Nuevo León"` (descuido: era la edición local de
  quien desarrollaba la entidad): quien clonara `master` corría Nuevo León sin saberlo. Corregido:
  la línea queda comentada (`//global entidad "Nuevo León"`, edición local) y **el default
  versionado es vacío = nacional**.
- **Restos de sesión en `SIM.do` (`d76d5af`).** El mismo commit que activó la entidad (`deff8c9`)
  dejó (1) un `ex` suelto tras `PIBDeflactor` (§2.4) que terminaba la corrida antes del SCN,
  (2) `global hasta "3"` activo en §0.4 (paro temprano tras §3: sin Sankeys ni `output.txt`) y
  (3) el bloque final `TOUCH-DOWN` + `output.do` duplicado (con `$output` activo `output.do`
  corría dos veces). Con ellos, el `SIM.do` versionado no corría de punta a punta. Corregidos.
- **Restos del régimen retirado** (limpieza de texto, sin efecto en cálculo): `README.md` deja
  de documentar los globals `fuentes` y `bootstrap` y la frase «byte-idéntico al ancla»;
  `runbook-actualizar-assets.md` pierde el §2d (asset de fuentes congeladas); comentarios en
  `compuertas-entidad.sh` y `EntidadNL.do`; `publicar.sh --check` dice «los 8 gates» (el Gate 9
  ya no existe).

### `PIBDeflactor` por entidad federativa (`deff8c9`, 2026-10-16)

`PIBDeflactor` acepta `if entidad == "<Nombre>"` (misma convención que `Poblacion`; `SIM.do`
§2.4 pasa `ifentidad`). Con entidad construye `master/PIBDeflactor<abrev>.dta` con: PIBE
corriente (BIE 750453) e índice de precios implícito (753357), anuales replicados en cuatro
trimestres; población ocupada y desocupada de la ENOE (6200093954 / 6200093973, BISE vía API por
área); INPC de la entidad (programa INPC de INEGI, estructura 112001700070; existe desde
jul-2018); y población CONAPO de la entidad. Gráficas y escalares llevan la abreviatura como
sufijo; **la base nacional no se toca**. Años posteriores al último PIBE sin exógeno `$pib`:
nowcast con el ITAEE (741177 / 741180 según área) y, si no hay, promedio geométrico; el nivel se
encadena para no romper la serie. `AccesoBIE` v8.3: con `area()` y clave de 10 dígitos usa la
API BISE (`inegi_bise_area`).

**Corrección con alcance nacional** (declarada por el autor): el respaldo de las tasas
proyectadas (`L.var_XG == .`) sobrescribía el promedio geométrico con la última tasa; afecta
**solo** a los años posteriores al último exógeno.

### `bootstrap(250)` en la salida de la corrida (`0692d9c`, 2026-10-16)

Las llamadas a `Simulador` de los perfiles ENIGH (gasto por categoría en `Expenditure.do`;
ingreso laboral, de capital, bruto, gasto total, ahorro, cuotas y ciclo de vida en
`Households.do`) pasan de `reboot` sin bootstrap (`boot(25)` comentado) a `reboot boot(250)`,
de modo que la corrida reporta errores estándar de los perfiles con 250 réplicas. Efecto
declarado arriba.

### Raíz del proyecto: se retira el comando `SIMroot` (2026-10-15)

Decisión de Ricardo: la raíz del simulador es **una sola línea** en `SIM.do` §0, `global SIMROOT
"<carpeta del repositorio>"`, seguida de `adopath ++ "${SIMROOT}"` y `set scheme ciep`. Se elimina
`SIMroot.ado` (resolución en cuatro pasos, `dir()/reset/scheme/smoke`, validación de la carpeta,
prueba de humo `SIM_SMOKE`), su ayuda y su `.pkg`; la línea `SIMroot` que abría cada `.ado` y los
drivers NL desaparece (los comandos leen `${SIMROOT}` tal cual). `profile.do` fija el global con la
carpeta donde vive (`findfile profile.do`; si falla, `c(pwd)`) y mete el adopath; `Web.Stata.do` lo
fija desde SITE. `test-maquina-virgen.sh --zip` ahora sustituye la ruta en la línea `global SIMROOT`
de la copia y comprueba que los `.ado` se ven tras un `cd`; `compuertas-entidad.sh --sin-sim` y
`verificar-runner.ps1` dejan de invocar el comando. Los `.pkg` del endpoint ya no arrastran
`SIMroot.ado`.

### `SIM.do` §0.4 sin parámetros de entidad ni `bootstrap` (2026-10-15)

Decisión de Ricardo (minimalismo): los siete globals opcionales que documentaba §0.4 dejan de
existir. `entidad_vintages`, `entidad_macro`, `entidad_cuotas`, `sello_n`, `sello_top1` y
`entidad_ciclo_grupos` se **congelan en su default** dentro de `SankeySF.do` y `CicloEntidad.do`
(banda ENIGH 2016-2024, renglones macro por población —se firma `pob`—, cuotas IMSS dentro de
"Imp al trabajo" como el nacional —se retira la rama `aparte`—, sellos n<100 / top1>25 %, series
por deciles nacionales); la banda pasa a ser el 4.º argumento de `SankeySF.do` para que
`compuertas-entidad.do` siga omitiéndola en las 31 entidades que no son la de la sesión.
`bootstrap` deja de ser global: `SIM.do` §7 usa `bootstrap(1)` y `PerfilesSim.do` `bootstrap(250)`
(EE e IC 95 % en los perfiles). Con `$entidad` vacío no corre ninguna rama de entidad.

### Se retiran las fuentes congeladas y el ancla de reproducibilidad (2026-10-15)

Decisión de Ricardo: el motor descarga **siempre en vivo** de INEGI (BIE, tabulados CSI) y
SHCP; se asume que el `output.txt` publicado es el de las fuentes del día y que no se
garantiza regenerarlo al byte después. Desaparecen `global fuentes` y su bloque en `SIM.do`
§0, las guardas en `AccesoBIE.ado` (`inegi_congelada`, `.meta`), `SCN.ado` y
`DatosAbiertos.ado`, el campo `fuentes_congeladas_al` del JSON de `CicloEntidad.do`, el asset
`fuentes-2026-10-06.zip` y los campos `fuentes_congeladas_*` del manifest (el asset sigue en
la Release v8.9.0 como histórico), `05_scripts/ancla-reproducibilidad.json`, el modo
`--reproducibilidad` de `test-maquina-virgen.sh`, el Gate 9 de `publicar.sh` y la paridad
informativa contra el ancla en `compuertas-entidad.py`. Runbook §9 queda como nota de la
decisión y conserva las piezas que sí mueven números (estado cero, StataNow 19.5,
`set processors 1`, `log` en bloque `quietly`).

### Se retira `SIM-local.do` (SIM.do §0.5, v8.8.0) (2026-10-15)

El panel local gitignored y su plantilla `SIM-local.template.do` desaparecen: los toggles se
activan descomentando su línea en `SIM.do` §0.4. Los scripts batch (`test-maquina-virgen.sh`
`--zip`/`--reproducibilidad`, `compuertas-entidad.sh`) ya no escriben un `SIM-local.do`: generan
una copia `SIM_run.do` con la raíz en `global SIMROOT` y sus globals insertados tras
`macro drop _all` (`sim_run`); `SIM.do` versionado no se toca. Runbook §9.1/§9.5, README y las
cadenas `receta` del ancla y del manifest se actualizan.

### Ciclo de vida de entidad: `CicloEntidad.do` (PR feat/ciclo-entidad, 2026-10-11)

Decisión de Ricardo (2026-10-11): el espejo NL deja de mostrar los cortes grupoedad y sexo y muestra
**la misma gráfica de ciclo de vida del sitio nacional** ("La carga fiscal por edades") filtrada a la
entidad. Unificación, no invención: la definición es la del nacional y no se rediseña. **Todo vive
dentro de `if "$entidad" != ""`** (`SIM.do` §8.2, una línea después de los Sankeys de entidad): con
el global vacío no corre ni una línea nueva ni se escribe un archivo nuevo, así que la receta
canónica y el ancla v8.9.0 no cambian.

#### Comandos

- **`01_modulos/visualizations/CicloEntidad.do`** (nuevo) — `run CicloEntidad.do <anioPE> "<entidad>"`.
  Lee `users/$id/aportaciones.dta` (la misma base del nacional), filtra por clave INEGI
  (`substr(folioviv,1,2)`, como `SankeySF.do`) y escribe `users/$id/<ABREV>/ciclo-vida.json`
  (JSON plano, no script FusionCharts).
- **`SIM.do` §0.4** — `//global entidad_ciclo_grupos "decil"`: series apiladas de la gráfica.
  `decil` (default) = grupos de deciles **nacionales** I-V / VI-IX / X, exactamente como el
  nacional; `quintil` = quintil estatal I…V (re-ranking de `SankeySF.do`, P2); `ninguno` = una
  sola serie. Reutiliza `sello_n` (100) y `sello_top1` (25).

#### Definición heredada del nacional (radiografía; no se rediseña)

- La gráfica del sitio (`js/stataCalcula.js`, ApexCharts `#chart-duo-pt1/2`, barras horizontales
  apiladas, hombres y mujeres, 22 quinquenios de 105-109 a 0-4) lee las familias `APORTHIV`,
  `APORTHVIIX`, `APORTHX`, `APORTMIV`, `APORTMVIIX`, `APORTMX` de `output.txt`; `cargaDefault.php`
  pisa las claves repetidas, así que el bloque que manda es el **último**: el de
  `Simulador AportacionesNetas` (`SIM.do` §7.3).
- `AportacionesNetas = ImpuestosAportaciones − Transferencias` por persona, `[fw=factor]`.
  `ImpuestosAportaciones = ISRPM + ISRAS + ISRPF + CUOTAS + IVA + IEPSNP + IEPSP + ISAN + IMPORT`
  (`*_Sim`; sin FMP ni OTROSK). `Transferencias = Pensiones (con Pensión_AM) + IngBasico + Educacion
  + Salud + OtrasInversiones` (sin OtrosGastos ni Energia).
- Celda = `grupo_edad` 1..23 (0-4 … 105-109, 110+) × sexo × `over` (deciles I-V, VI-IX, X).
  **Unidad: porcentaje del total nacional de aportaciones netas** (`graphpiramide`: `POR =
  neto/Σneto×100`; Σ de las 132 celdas = 100; `%8.3f`). Negativo = la celda recibe más de lo que
  aporta. Valor presente: `Simulador.ado` divide la variable por el deflactor de anioPE respecto a
  anioVP antes de guardar `aportaciones.dta` (con anioVP = anioPE = 2027 es 1); `CicloEntidad.do`
  aplica el mismo cociente a aporta y recibe.
- Hallazgos del nacional, declarados y no corregidos aquí (sitio fuera del alcance del motor): los
  tooltips dicen "MXN" (hombres) y "% PIB" (mujeres) cuando el dato es % del neto total; la etiqueta
  del grupo 23 en `graphpiramide` dice "109+" (es 110+); los dos primeros bloques `APORT*` de
  `output.txt` (otras variables de `PerfilesSim`) no son los que el sitio dibuja.

#### Contrato de `ciclo-vida.json`

Por celda quinquenio × sexo (rejilla completa, 46 celdas, las vacías con `n = 0`, nunca omitidas):
`n` (personas de la muestra de la entidad, sin ponderar), `pob` (Σ factor), `aporta`, `recibe`,
`neto` (pesos de anioVP), `pct` (% del neto total de la entidad, Σ = 100), `pct_nac` (% del neto
total nacional: **Σ de las 32 entidades, celda a celda = `APORT*`**), `top1_aporta`/`top1_recibe`
(% del aporta/recibe de la celda que pone una sola persona), `sello` (1 si `n < sello_n` o
`top1_* > sello_top1`; regla P5) y `grupos[]` con el desglose por serie. Más `totales` (entidad y
nacional: n, pob, aporta, recibe, neto, PIB nacional `pibY`, participaciones), `definicion`,
`parametros`, `quinquenios`, `grupos` y `procedencia`.

#### Compuertas (evidencia `diag-pivote-entidad-2026-10-10/F3-ciclo/`)

1. **Paridad nacional**: todo el diff vive dentro de `if "$entidad" != ""` (SIM.do: dos líneas, una
   comentada en §0.4 y la llamada en §8.2; archivo nuevo); receta rápida `--zip`.
2. **Aditividad** (`gate-aditividad.py`): Σ de las 32 entidades de `pct_nac`, celda a celda, contra
   los 6 vectores `APORT*` del `output.txt` del ancla (último bloque): diferencia máxima **0.000495**
   con tolerancia 0.0005 (medio milésimo del `%8.3f`); Σ32 neto = neto nacional **1,249,989.66 mdp**
   (reldif 0); 32/32 JSON con rejilla completa, Σ pct = 100, neto = aporta − recibe, celdas = Σ grupos
   y regla del sello verificada. Reconstrucción independiente con pandas sobre `aportaciones.dta`:
   mismos vectores (máx 0.0005).
3. **Testigo NL** (`ent/NL-ciclo-vida.json`): 12,586 personas, población ENIGH 6,375,312 (4.71 %),
   neto **354,608.5 mdp = 28.37 % del neto nacional**; 16 de 46 celdas con sello (4 vacías: 105-109 y
   110+ de ambos sexos; n < 100 en 80-84 H, 85-89 H/M y de 90-94 en adelante; concentración: en
   **60-64 H una sola persona pone el 83.8 % del aporta de la celda y la celda es el 34.1 % del neto
   de NL**; 65-69 H 70.1 %; 80-84 M 50.3 %). No existe referencia nacional por edades para NL: el
   testigo es la aditividad y la reconstrucción con pandas.
4. **Segundo estado**: Jalisco 8,617 personas, 19.77 % del neto nacional, 19 sellos; CDMX 18 sellos.

#### FLAGs (decisiones de Ricardo; defaults declarados)

- **C-1 Series por default**: deciles nacionales (herencia exacta) vs quintil estatal (regla P2 de los
  Sankeys de entidad). Parámetro `entidad_ciclo_grupos`, default `decil`.
- **C-2 Definición de `n`**: personas de la muestra en la celda (todas); el nacional llama a
  `Simulador` con `if AportacionesNetas != 0`, pero en la ENIGH 2024 ninguna persona tiene neto
  exactamente 0 (`n_neto_cero` viaja en `totales`).
- **C-3 Sello de concentración en el ciclo de vida**: se reutiliza `sello_top1` (25 %) sobre aporta y
  recibe de la celda; el neto, por ser signado, no lleva top1.
- **C-4 Nombre del archivo** `ciclo-vida.json` y **unidad por default en el espejo** (% del neto total,
  como el nacional, frente a MXN por persona o mdp que la página ya ofrece como registros).
- **Bandas de vintages**: no entran (el nacional no las muestra en esta gráfica); extensión posible
  como una fila de paleta (misma mecánica que `_SFsellos`: filtrar `users/$id-v<t>/aportaciones.dta`,
  participación de la celda × neto nacional vigente), costo ~1 sesión; no es un rediseño.


## [v8.9.0] — 2026-10-11

Release **menor** (funcionalidad nueva compatible, `versionado-y-git.md` §3.2) **sin efecto en
los números publicados**: con `entidad` vacío, `output.txt` (`e40af4a6…`) y los 5 `sankey-*.json`
nacionales son byte-idénticos al ancla v8.8.2. Consolida dos PR mergeados en `master`:
**#20 `feat/entidad`** (`e99d963`, 2026-10-10: el motor entidad-consciente) y **#21
`fix/etiqueta-residual-entidad`** (`af2eaf9`, 2026-10-11: etiquetas por signo del residual de
entidad y separación clave/texto en `SankeySumSim.ado`). Ancla re-declarada por la receta §9.1
sobre `af2eaf9` con los mismos SHAs (abajo). **No es release de datos**: `data_updated` y
`fuentes_congeladas_al` siguen en 2026-10-06 y los 27 assets del manifest no cambian. Deploy del
VPS por §4b del runbook (minor: deployment nuevo `v8.9`).

### Institucional

- **Pivote a `global entidad`** (decisión del 2026-10-10, mapa F0
  `diag-pivote-entidad-2026-10-10/mapa-migracion.md`): la capa NL (`*NL.do`, `nl-assets/`) deja de
  crecer y su conocimiento pasa al motor como opción del panel `SIM.do` §0.4. Todo lo nuevo vive
  dentro de `if "$entidad" != ""` y sin entidad no se escribe ningún archivo nuevo. Uso documentado
  en `runbook-deploys-ciep.md` §9.7.
- **Etiqueta del residual de entidad por signo** (decisión de Ricardo, 2026-10-10 noche): el cierre
  contable del Sankey de una entidad deja de llamarse "Ahorro" y se nombra "Aportación neta a la
  Federación" o "Recepción neta de la Federación" según el signo. Solo etiquetas, ningún valor.
- **`05_scripts/compuertas-entidad.sh`, `.do` y `.py`** (nuevos): 32 entidades × 5 cortes en una sesión de
  `SIM.do`, aditividad contra el nacional, testigo NL contra el statajson sellado y sellos del
  segundo estado; reconocen las etiquetas nuevas del residual (`RESID_POS`/`RESID_NEG`).

### Comandos

- **`SIM.do` §0.4** — `//global entidad "Nuevo León"` comentado por defecto, junto a `$fuentes`,
  sobreescribible desde `SIM-local.do`; **§0.6** valida el nombre con `SIMentidad` (error
  accionable con el catálogo si no existe) y crea `users/$id/<ABREV>/`. Parámetros opcionales
  del Sankey de entidad, todos con default: `entidad_vintages`, `entidad_macro`,
  `entidad_cuotas`, `sello_n` (100), `sello_top1` (25).
- **`SIMentidad.ado`** (nuevo) — catálogo de entidades (`$entidadesL`/`$entidadesC`, única
  fuente de verdad; `profile.do` §2.1 lo carga de aquí) y resolución nombre → clave INEGI
  (posición en la lista = `substr(folioviv,1,2)` de la ENIGH) y abreviatura (la que
  `Poblacion.ado` ya usa).
- **`SIM.do` §1** — con entidad, `Poblacion if entidad == "$entidad"` (ya era
  entidad-consciente): tarjeta demográfica y escalares `pob*<ABREV>`.
- **`SIM.do` §8.2 → `SankeySF.do`** — tras los 5 Sankeys nacionales (intactos), los de la
  entidad con un tercer argumento: `keep if` por clave INEGI tras cada `use aportaciones.dta`;
  corte **quintil estatal** (re-ranking dentro de la entidad con el criterio de ingreso de
  `Households.do` §12: ingreso bruto del hogar por integrante, `xtile n(5)` con
  `pw = factor/integrantes` — la construcción sellada del sprint NL C1, 2026-10-08) en lugar
  del decil nacional, más grupoedad, sexo, rural y escol; outputs en
  `users/$id/<ABREV>/sankey-<corte>.json` (quintil, grupoedad, sexo, rural, escol).
- **`SankeySF.do`** (bloque "DEUDA o AHORRO") — con `entidad`, ingreso > gasto → nodo
  **"Aportación neta a la Federación"** → **"Federación y futuro"**; gasto > ingreso →
  **"Federación y futuro"** → **"Recepción neta de la Federación"** (p. ej. Chiapas, 240,918.9 mdp
  en PE 2027). Sin `entidad`, el nacional conserva "Ahorro"/"Endeudamiento" ↔ "Futuro".
- **`SankeySumSim.ado`** — opción `folder()` (existía sin uso) escribe en `users/$id/<folder>/`;
  opción `meta()` inserta un bloque `entidad` en `dataSource`; las variables `j_*` de los
  ejes viajan como campos del enlace (`n`, `top1`, `sello`, `bmin`, `bmax`, `v<t>`). Sin
  `folder()`/`meta()`/`j_*` el JSON es byte-idéntico. **Fix de truncado (#21):** la clave interna
  del nodo (`substr(…,1,20)` + `strtoname`, nombre de macro `node<clave>`) se separa del texto que
  va al JSON (etiqueta completa, espacios → `_` como antes). Motivo: con 31 caracteres `strtoname`
  truncaba a 32 bytes y el nombre de macro reventaba (`r(198)`); el JSON salía "Aportación neta a
  l". Para etiquetas ≤ 20 bytes (todas las nacionales) el texto es idéntico al de antes.
- **Banda de vintages (P4)** — para cada enlace micro, la participación de la celda de la
  entidad en el total nacional de la familia observada en cada ENIGH
  (`users/$id-v<t>/aportaciones.dta`, t = 2016…2024, bases del 8-oct, motor v8.8.1, fuentes
  2026-10-06; se filtran, no se re-corren) × el total nacional vigente: `v<t>` por vintage,
  `bmin`/`bmax` = halo, el vigente = punto. Distinta de la banda S1–S3 del ISR PM (método),
  que no entra al motor. Sin bases de vintages no hay banda (se declara en `vintages`).
- **Sellos de muestra (P5)** — por enlace micro: `n` = personas con el flujo en la celda,
  `top1` = % del flujo de la celda que aporta una sola persona, `sello` = 1 si `n < sello_n`
  o `top1 > sello_top1`. Umbrales = parámetros del motor con los defaults de la paleta NL.

### Supuestos declarados para firma (P3: renglones macro del Sankey de entidad)

Población ENIGH de la entidad / nacional (Σ factor de `aportaciones.dta`; NL = 6,375,312 /
135,391,415 = 4.7088 %) es la única clave nueva. PE 2027, mdp:

| Renglón | Nacional | NL | Con entidad | Supuesto |
|---|---:|---:|---|---|
| Imp al trabajo / consumo / capital (micro) | 2,318,255.8 / 2,846,081.8 / 2,323,380.3 | 209,477.2 / 199,574.5 / 328,850.2 | `keep if` + collapse por quintil estatal | ninguno (mecánico, = C1) |
| IMSS, ISSSTE · Pemex, CFE · FMP (`% PIB × pibY`) | 174,233.8 · 1,283,496.2 · 210,893.9 | 8,204.3 · 60,437.3 · 9,930.6 | nacional × población de la entidad / nacional | **S-P3a** (`entidad_macro "pob"`; alternativa `"omitir"`) |
| Educación · Salud · Pensiones · Transferencias · Inversión (micro) | 1,387,957.6 · 1,137,250.1 · 2,421,928.9 · 22,074.9 · 618,096.4 | 59,230.7 · 50,415.3 · 130,331.6 · 1,041.9 · 50,213.7 | `keep if` + collapse | ninguno (Pensiones = 154,210.9 de C4 − 23,879.3 de la doble suma de v8.8.2) |
| Costo de la deuda · Part y otras Aport · Otros gastos · Energía (2) (`gas*PC × pobtot`) | 1,453,393.8 · 1,651,673.5 · 675,648.8 · 1,066,295.2 + 203,010.0 | 68,437.4 · 77,774.0 · 31,815.0 · 50,209.7 + 9,559.3 | la fórmula actual con `pobtot` = Σ factor de la entidad | **S-P3b** (equivale a reparto por población; alternativa CONAPO de la entidad rompería la aditividad) |
| Residual Federación y futuro ↔ Aportación / Recepción neta | +1,480,987.4 (Endeudamiento) | **−287,445.4 (Aportación neta a la Federación)** | `gastot − ingtot` de la entidad | **S-P3c**: con S-P3a/b, Σ 32 residuales = residual nacional |

Tabla completa renglón por renglón y FLAGs abiertos (nombre `sankey-quintil.json`; banda del lado
gasto: `Salud` y `Pensiones` vienen vacías en las bases de vintages del 8-oct y la de Inversión
refleja la clave `infra_entidad` del PEF de cada año, no la muestra; cuotas aparte; umbrales;
definición de la banda) en `diag-pivote-entidad-2026-10-10/F1/reporte-F1.md`. La decisión por
fila es de Ricardo.

### Compuertas (evidencia en `diag-pivote-entidad-2026-10-10/F1/` y `F2/parteA/`)

| # | Compuerta | Resultado | Evidencia |
|---|---|---|---|
| 1 | Paridad nacional con `entidad` vacío: `test-maquina-virgen.sh --reproducibilidad --assets-locales` (receta §9.1 desde estado cero, StataNow 19.5 SE, 1 procesador), sobre `c10fff0` (#20) y sobre `a93e179` (#21) | **PASÓ** las dos veces: `output.txt` `e40af4a6…` y los 5 `sankey-*.json` con el SHA del ancla v8.8.2; 56 y 60 min | `F1/compuerta1-reproducibilidad.out`, `F2/parteA/compuerta-reproducibilidad.out` |
| 1 | `--zip`: las tres vías de ejecución (otra carpeta → r(601); carpeta del simulador sin `profile.do`; con `profile.do`, que ahora carga `SIMentidad`) | **PASÓ** | `F1/compuerta1-zip.out` |
| 1 | Informativa: corrida con `entidad "Nuevo León"` sobre cachés (no estado cero): `output.txt` = ancla `e40af4a6…`; los 5 sankeys nacionales byte-idénticos a la corrida v8.8.1 del 8-oct salvo exactamente los enlaces de Pensiones y el residual (fix v8.8.2) | **los archivos nacionales no cambian con entidad puesta** | `F1/compuertas/compuertas-entidad.md` §1 |
| 2 | Aditividad: Σ de los 32 Sankeys de entidad = nacional, enlace por enlace en grupoedad/sexo/rural/escol y por familia + 7 renglones macro + residual en quintil (224 comparaciones, 5 cortes) | **PASÓ**, reldif máx **8.5e-14** (tol 1e-9) | `F1/compuertas/aditividad.csv` |
| 3 | Testigo NL: `users/ricardo/NL/sankey-quintil.json` vs `statajson_entidad-nl.json` del sprint (8-oct): 15 celdas quintil×familia = Σ pares `dis<fam>nle<dec>` y las 90 celdas decil×familia reconstruidas con el criterio de `Households.do` §12; quintil = ceil(decil/2) en las 12,586 personas | **PASÓ**, reldif máx **1.9e-15** (15) y **3.4e-15** (90) | `F1/compuertas/nl-dis-nle-recalc.csv`, `F1/statajson_entidad-nl-2026-10-08.json` |
| 4 | Segundo estado (Jalisco, clave 14, 6.70 % de la población): 5 JSON sin error; 32 enlaces micro con sello (p. ej. Imp al capital Q1–Q4 con n = 38/54/53/79; rural Indígena → Pensiones n = 1, top1 100 %). En las 32 entidades × 5 cortes: 4,950 enlaces micro con `n/top1/sello`, 715 sellados; banda ENIGH solo en NL (la entidad de la corrida) | **PASÓ** | `F1/compuertas/compuertas-entidad.md` §4 |
| 5 | Etiquetas (#21): harness de `SankeySF.do` con `entidad "Nuevo León"`, 5 cortes, antes vs después: solo cambian 2 etiquetas por corte; valores, `n`, `top1`, `sello`, bandas y bloque `entidad` idénticos campo a campo. Chiapas (quintil) exhibe la etiqueta negativa. Nacional antes/después del `.ado`: byte-idéntico (5/5) | **PASÓ** | `F2/parteA/` |

Tiempos: `SIM.do` completo con entidad (sin `update`) 9 min + `compuertas-entidad.do` (160 Sankeys
de entidad + 90 celdas) 68 s. Observación: en el harness, el cambio de texto de `SankeySF.do` mueve
la última cifra (reldif ≤ 4.6e-14) de 81/104 enlaces micro del `sankey-decil.json` nacional (orden
de suma en `collapse`); la receta completa no lo exhibe (ancla reproducida). La compuerta byte a
byte es la de la receta.

### Reproducibilidad

- **Ancla re-declarada por la receta** (`test-maquina-virgen.sh --reproducibilidad --assets-locales
  --anclar` sobre `af2eaf9` = `master` tras #21; estado cero, fuentes 2026-10-06, StataNow 19.5 SE,
  `set processors 1`, 51 min, `anclado_el 2026-10-11T19:14:17Z`): `output_txt_sha256` **idéntico**
  (`e40af4a6…`) y los 5 `sankeys_sha256` **idénticos a v8.8.2** (`sankey-decil.json` `8952d14ef4d2…`,
  `sankey-escol.json` `fd059f8c6b56…`, `sankey-grupoedad.json` `14ce05b14579…`, `sankey-rural.json`
  `02dd7ac04d74…`, `sankey-sexo.json` `bf49cec77340…`). Solo cambian `version`, `commit` y
  `anclado_el`, como en v8.8.1. Evidencia: `diag-pivote-entidad-2026-10-10/release-v8.9.0/`.
- La política de que un release sin cambio de números herede el ancla (anotada en v8.8.1) sigue
  pendiente de Ricardo; mientras, el Gate 9 exige `ancla.version == version` y se re-ancla con la
  receta, nunca a mano.

### Pendiente (documentado, sin cambio de código)

- Retiro de la copia NL-0.4.1 de la capa NL que vive en `master` (PR aparte; Fase B del mapa F0);
  `PIBDeflactor` por entidad (el INPC estatal no existe en el BIE); los HTML de CoNL; el runner.
- FLAGs de F1 (arriba) y el gemelo `Pension_AM` de `PerfilesSim.do` §5 (anotado en v8.8.2) siguen
  abiertos; la definición es de Ricardo.

## [v8.8.2] — 2026-10-10

Patch **con efecto en números publicados**: los 5 `sankey-*.json` del sitio cambian;
`output.txt` no (no pasa por `SankeySF.do`; la receta §9.1 lo reprodujo byte-idéntico,
`e40af4a6…`). Ancla re-declarada por la receta. Detectado y cuantificado en la capa NL
(`feature/entidad-nl`, sesión C4 del 2026-10-09) y confirmado el 2026-10-10 con la prueba
de endeudamiento (`~/CIEP_Simuladores/diag-pivote-entidad-2026-10-10/prueba-pam/`).

### Correcciones

- **El nodo "Pensiones" del Sankey del sistema fiscal contaba `Pensión_AM` dos veces.**
  `GastoPC.ado` §5 construye `Pensiones` con las cuatro contributivas (IMSS, ISSSTE, Pemex,
  otras) y `Pensión_AM` aparte; `SIM.do` §7.2 suma `Pensiones + Pensión_AM` **una vez**
  antes de guardar `aportaciones.dta` (desde `afac956`, 2025-11-27, cuando `Pensión_AM`
  salió de `Transferencias` y entró a `Pensiones`); `SankeySF.do` abría esa base y la volvía
  a sumar (línea heredada de `0afac4e`, 2025-09-02, cuando aún no venía sumada). La
  duplicación existe desde `afac956`: afecta a todo v7.0–v8.8.1. Se retira la re-suma de
  `SankeySF.do`; `SIM.do` §7.2 y `Web.Stata.do` §7.2 (misma suma legítima en la vía web, que
  también corre `SankeySF.do`) no cambian.

  Efecto, PE 2027 (mdp; PIB 39,419,415.3):

  | Enlace del Sankey (los 5 cortes) | Antes | Después | Δ |
  |---|---:|---:|---:|
  | CGPE 2027 → Pensiones | 3,002,971.1 (7.618 % PIB) | 2,421,928.9 (6.144 %) | −581,042.2 |
  | Pensiones → cortes (decil, edad, sexo, rural, escolaridad) | Σ 3,002,971.1 | Σ 2,421,928.9 | −581,042.2, repartido como `Pensión_AM` |
  | Futuro → Endeudamiento → CGPE 2027 (residual) | 2,062,029.6 (5.231 %) | 1,480,987.4 (3.757 %) | −581,042.2 |
  | Σ gasto (eje 3) | 11,218,371.4 (28.459 %) | 10,637,329.2 (26.985 % = Σ §5.1) | −581,042.2 |
  | todo lo demás (eje de ingresos, Educación, Salud, Inversión, Transferencias, renglones macro) | | | 0 |

  La Δ es exactamente `pam` (1.474 % del PIB, `SIM.do` §5.1). El residual de endeudamiento
  ahora cierra contra el déficit implícito de los parámetros del propio `SIM.do`
  (Σ §5.1 − Σ §4.1 = 3.757 %) y queda a 1,028 mdp (0.003 pp) del financiamiento de la ILIF
  2027 (`LIF.dta`, divLIF 10: 3.754 %); antes excedía ambos en ~1.47 pp. Por decil, cada enlace
  Pensiones → decil baja en la Σ de `Pensión_AM` de ese decil (I −65,055.6 … X −52,923.8).

### Reproducibilidad

- Ancla re-declarada (`05_scripts/ancla-reproducibilidad.json`): `output_txt_sha256`
  **idéntico** (`e40af4a6…`); `sankeys_sha256` nuevos:
  `sankey-decil.json` `8952d14ef4d2…`, `sankey-escol.json` `fd059f8c6b56…`,
  `sankey-grupoedad.json` `14ce05b14579…`, `sankey-rural.json` `02dd7ac04d74…`,
  `sankey-sexo.json` `bf49cec77340…`. Receta §9.1 desde estado cero, fuentes 2026-10-06,
  StataNow 19.5 SE, `set processors 1`.
- Compuertas del PR (evidencia en `diag-pivote-entidad-2026-10-10/fix-pam/`): residual =
  Σ §5.1 − Σ §4.1 (reldif < 1e-9); nodo Pensiones = 6.144 % del PIB; aditividad del delta en
  los 5 cortes (solo se mueven los enlaces de Pensiones y el residual, en −`pam`);
  `test-maquina-virgen.sh --zip` en las tres vías.

### Pendiente (documentado, sin cambio de código)

- **`Pension_AM` (sin acento, `PerfilesSim.do` §5)** suma 904,680 mdp con un ancla declarada de
  580,935: `Distribucion.ado`, cuando la variable **ya existe**, multiplica la variable vieja (no
  el `relativo`) por `macro/Σ(relativo)`, y `PerfilesSim.do:457` la crea antes de llamarla con
  `relativo(ing_pam)` → total `macro²/Σ(ing_pam·factor)` (reproducido al 0.001 %). Es la única
  llamada del motor en ese patrón; hoy la variable solo alimenta su perfil por edad y no entra a
  `output.txt` ni al Sankey. Hechos en `fix-pam/anexo-gemelo-Pension_AM.md`; la definición es de
  Ricardo.

## [v8.8.1] — 2026-10-08

Hotfix sin efecto en números: `output.txt` y los 5 `sankey-*.json` de v8.8.0 siguen
siendo el ancla (`e40af4a6…`; receta §9.1 re-verificada el 2026-10-08 desde estado
cero con el merge de cadencia de la capa NL: byte-idénticos). Detectado durante ese
merge (`DIAGNOSTICO_NL.md`, entrada de cadencia v8.8.x, rama `feature/entidad-nl`).

### Correcciones

- **`05_scripts/manifest.json` v8.8.0 rompía `scalarjson.ado` y los tres nodos del
  micrositio con `r(132) too few quotes`.** La regla `fuentes_congeladas_regla`
  (nueva en v8.8.0) traía un acento grave (la cita de `global fuentes`).
  `scalarjson.ado` §1, `nodos/micrositio-pe.do`, `nodos/portada.do` y
  `nodos/indicadores.do` leen el manifest línea por línea (`file read` y `regexm`
  sobre la línea expandida en comillas compuestas): al expandir el macro, el acento
  grave abre una referencia a macro que se traga la comilla de cierre. Efecto: `SHRFSP.ado` →
  `nodo-deuda.do` → `scalarjson` aborta `SIM.do` en §6 **en cualquier clon con
  `../CIEP_Micrositios/Paquete Económico/public_html/nodos` presente** (el clon de
  Dropbox; la receta del ancla no lo tenía y por eso el nodo se omitió "solo-repo" y
  el ancla salió bien). Reproducido aislado: línea 2 del manifest OK, línea 6 r(132).
  Dos cinturones: (1) **`scalarjson.ado` v1.0.1 y los tres nodos** quitan el acento
  grave (`char(96)`) de cada línea leída **antes** de expandirla, con la función
  extendida `subinstr local`, que opera sobre el macro sin expandirlo; en
  `scalarjson` también en la enumeración de escalares vivos (`scalar list`). (2) **El
  texto del manifest ya no lleva acentos graves** y lo declara como regla del archivo.
  Verificación: las 175 líneas del manifest v8.8.0 se leen sin error con ambas formas;
  `which scalarjson` carga v1.0.1. `ensure_asset` no estaba afectado (parsea en Python).
  Regla colateral para este CHANGELOG: `profile.do` §1.5 imprime las novedades con
  `display` tras quitar los acentos graves, así que una línea no debe contener la
  secuencia comilla doble + comilla simple (cerraría la comilla compuesta: r(132)).
- **Ancla de reproducibilidad:** este hotfix no mueve números, así que
  `05_scripts/ancla-reproducibilidad.json` conserva `version: v8.8.0` y el SHA
  `e40af4a6…`. Para publicar v8.8.1 el Gate 9 exige `ancla.version == v8.8.1`:
  re-anclar con `test-maquina-virgen.sh --reproducibilidad --assets-locales
  --anclar` (esperado: SHAs idénticos; solo cambian `version`, `commit`,
  `anclado_el`) o decidir que un patch sin cambio de números hereda el ancla
  (ajuste de política del Gate 9, pendiente de Ricardo).

## [v8.8.0] — 2026-10-06

Release de **datos** (fuentes INEGI/SHCP al 2026-10-06, `data_updated` =
`2026-10-06`) y de **reproducibilidad**: el `output.txt` publicado vuelve a tener
un ancla que cualquier máquina puede reproducir con una receta, no con suerte.
Diagnóstico completo (F0, tres anclas, siete corridas): `02_governance/historico/F0-reproducibilidad-ancla-2026-10-06.md`.

### Datos

- **Fuentes vivas congeladas al 2026-10-06: asset `fuentes-2026-10-06.zip`**
  (`raw/fuentes/`, 27.º asset del manifest; ~540 series del BIE con sus `.meta`,
  tabulados CSI de INEGI y los 10 csv de Datos Abiertos de la SHCP). Entre el
  22-sep (ancla anterior) y el 5-oct INEGI revisó el PIB 2024 (33,582.9 →
  33,667.0 mmdp) y publicó 2025, y la SHCP agregó meses; `data_updated` pasa de
  `2026-09-12` a `2026-10-06`. Con `global fuentes "2026-10-06"` (SIM.do §0.4)
  los módulos leen esas descargas desde `raw/temp/` en vez de la red.
- **Delta del `output.txt` por defecto (PE 2027) respecto al ancla anterior
  `ae624b98…`** — 2,890 de ~5,000 valores en 16 llaves, por tres causas
  separables (F0 §3.1):

  | Familia | Cambio | Causa |
  |---|---|---|
  | `INGRESOSTEF` | IEPSP 67.6→76.3, IEPSNP 46.5→47.9, ISRAS 12.8→12.7, ISRPM 12.8→12.9, ISAN 1.8→1.7, consumo 10.0→9.9 | INEGI: SCN 2024 revisado (denominadores) |
  | `DEUDAPARAM` 6.599→6.667; `PROYSHRFSP2/3`; `PROYCOSTO` 2026 2.0→2.2 | | SHCP: meses nuevos en `DatosAbiertos` → `SHRFSP` |
  | `INCD/INCD2/INCD3` (41 bloques) | hasta 11 % | SCN 2024 revisado → armonización macro-micro de `Households.do`; cachés micro regenerados |
  | `APORTH*/APORTM*` (ciclo de vida) | hasta 0.9 pp | cachés `master/2024/consumption_*_pc` del ancla anterior eran **anteriores a `perfilpc` (v8.5.0)** y nunca se habían regenerado (`update` no los tocaba); ahora reflejan el reparto intra-hogar vigente |
  | `PROY`/`PROYMAX` | hasta 1.2 (6 %); un máximo 2027→2028 | las dos anteriores vía `perfiles2027` |
  | `IVA:[…,23.1]` | 23.0→23.1 | recalibración de la informalidad (abajo) |
  | sin cambio | `INGRESOS`, `GASTOS`, `GASTOSPC`, `PIBY`, `ISR*`, `CSS*`, `CRECPIB/DEF`, `PROY{LABOR…INVER}`, `PROYSHRFSP1` | parámetros de `SIM.do` y PEF (assets) |

  Ningún número se corrige en silencio: este cuadro es la trazabilidad de por qué
  el default de hoy no es el de septiembre.
- **IVAT evasión/informalidad 23.0 → 23.1 (`SIM.do` §4.5).** Recalibración
  interna, no estimación externa: es la fila "Informalidad %" de `Expenditure.do`
  §5, (IVA potencial ENIGH − IVA observado)/potencial en % del PIB 2024. Con las
  fuentes del 22-sep: 5.443/4.193 → 22.96 % ("23.0"); con las del 6-oct:
  5.44094/4.18208 → **23.137 %** ("23.1"). **Causa principal: la revisión del PIB
  2024 de INEGI** (IVA observado/PIB 4.193 → 4.182); los perfiles v8.5.0 mueven el
  potencial solo de 5.443 a 5.441. Regla nueva en el runbook (§9.6): este
  parámetro se recalibra y documenta cada vez que cambie lo que mueve el cierre
  (perfiles o fuentes), nunca se hereda a ciegas.

### Correcciones

- **`IVA_Mod.do` (módulo IVA del sitio): sin factor `4.249/4.495` ni año base
  fijo 2022.** El resultado se multiplicaba por `4.249/4.495`, calibración ad hoc
  del Paquete 2022 que cerraba contra la recaudación proyectada de entonces sin
  tocar la informalidad observada, y deflactaba precios con `anio == 2022` (ENIGH
  2022) aunque la ENIGH vigente es 2024. Ahora: precios de `anioenigh` llevados al
  año del Paquete y **sin factor**. Cierre documentado (PE 2027, fuentes 6-oct,
  informalidad 23.1): simulado **4.128 % del PIB vs 4.485 proyectado en la LIF
  2027 → residuo −0.357 pp (−8.0 %)**; con 23.0 sería 4.134. Antes (factor + año
  2022): 4.243 (−5.4 %) / 4.248. El residuo se declara (y `IVA_Mod.do` lo imprime),
  no se absorbe: regla en el runbook §9.6. Afecta solo a las simulaciones web que
  cambian el IVA; el default (`output.txt`) distribuye la recaudación de la LIF.
- **`global update` también rehace los cachés micro de `master/<anioenigh>/`**
  (`deducciones`, `consumption_categ_pc`, `consumption_categ_iva_pc`,
  `consumption_categ_ieps_pc`). Solo se creaban si faltaban, así que una máquina
  con cachés viejos "actualizaba" con perfiles de otra versión del código; eso
  hizo irreproducible el ancla `ae624b98`. Mejora futura anotada: sellar cada
  caché con la versión del código que lo generó y rechazarlo si no coincide.
- **`DatosAbiertos` `_DAdescarga`: la descarga del csv va a `.tmp` y solo entonces
  reemplaza.** `copy …, replace` borra el destino **antes** de fallar (Stata 17 da
  r(603) con `secciones.hacienda.gob.mx`), así que el fallback "archivos locales
  de `raw/temp/`" encontraba el archivo recién borrado. Con el fix, el respaldo
  local sobrevive a una descarga fallida.
- **`SIM.do` §0.4: el log de `output.txt` se abre dentro de `quietly { }`.** Con
  `do` el eco del comando caía dentro del log (`.quietlylogoffoutput` como primera
  línea); con `run` o desde el Do-file Editor no. Ahora `do` y `run` producen los
  mismos bytes.
- **`SIM.do` §0.0 → `SIMroot` v8.6 (opciones `scheme` y `smoke`).** La
  autolocalización de v8.7.2 vivía entera en `SIM.do` (validación, mensaje de error,
  `set scheme`, prueba de humo). Por el huevo y la gallina (`SIMroot.ado` no se puede
  ejecutar antes de encontrarlo) en `SIM.do` queda solo lo irreducible: localizar la
  carpeta (carpeta de trabajo o `SITE`), un error de dos líneas que apunta al README,
  `adopath ++` y `SIMroot, dir() scheme`. `SIMroot` valida que la raíz sea la carpeta
  completa del simulador (`SIM.do`, `SIMroot.ado`, `scheme-ciep.scheme`,
  `05_scripts/manifest.json`; si no, la instrucción exacta y r(601)), hace `set scheme
  ciep` y, con `smoke` o `SIM_SMOKE=1`, corre la prueba de humo y devuelve
  `r(smoke)=1` para que `SIM.do` termine sin pipeline. `test-maquina-virgen.sh --zip`
  sigue probando las tres vías vía `SIM.do`. Sin efecto en números.
- **`ISR_Mod.do` no cambia en este release.** Sus factores `3.793/3.255`,
  `0.241/0.553`, `4.176/2.781`, `1.675/1.525` y `.1492/.098` (de v7, marzo 2026)
  se quedan tal cual; la decisión por fila se pospone a una auditoría de
  descomposición de la brecha (base, tarifa, formalidad, precios), entregable
  aparte. Solo afecta a las simulaciones web que cambian el ISR; no toca `output.txt`.

### Comandos

- **`global fuentes "AAAA-MM-DD"` (SIM.do §0.4; vacío = en vivo, byte-idéntico a
  antes).** `SIM.do` descarga/verifica `fuentes-<fecha>.zip` (`ensure_asset`) y lo
  descomprime en `raw/temp/`; `AccesoBIE` v8.2 usa `raw/temp/AccesoBIE/<serie>.csv`
  + `.meta` (nuevo: nombre crudo del indicador, para reproducir nombre y etiqueta
  sin red) en vez de descargar; `DatosAbiertos` v8.2 entra en modo `local`; `SCN`
  v8.1 no vuelve a bajar `tabulados_CSI.zip` aunque haya `update`. Hace viable
  Stata 17 (no descarga de la SHCP) y la máquina sin red.
- **`SIM-local.do`: panel local de toggles, no versionado** (`.gitignore`;
  plantilla `SIM-local.template.do`). `SIM.do` §0.5 lo ejecuta si existe, tras los
  defaults de §0.4; ahí viven `output`, `bootstrap`, `nographs`, `update`,
  `fuentes`, `textbook`, `export` y el nuevo **`global hasta "N"`** (paro temprano:
  termina al cerrar la sección 1-7). Sin el archivo, comportamiento byte-idéntico.
  Fin de los diffs locales en el `SIM.do` de la Carpeta de investigadores.

### Institucional

- **`publicar.sh` en modo fuente remota.** Ya no exige `raw/` local completo: un
  asset del manifest ausente en disco pero presente en la Release con el digest
  sha256 de GitHub igual al del manifest cuenta como verificado y no se re-sube;
  solo aborta lo que falta en los dos lados. Gate 8 y la verificación post-Release
  comparan ese digest (descargan solo assets sin digest, de Releases antiguas).
  Nuevo `--poblar-raw`: baja a `raw/` los assets que falten, verificando SHA.
  Motivo: la máquina de producción ya no tiene `raw/` completo; los Releases son
  la fuente de verdad. Runbook §3.
- **Ancla de reproducibilidad y receta canónica (`runbook-deploys-ciep.md` §9).**
  `05_scripts/ancla-reproducibilidad.json` declara versión, fecha de fuentes, Stata
  (19.5, 1 procesador), receta y SHA-256 de `output.txt` y de los 5
  `sankey-*.json`; **solo lo escribe la receta** (`test-maquina-virgen.sh
  --reproducibilidad --anclar`). Nuevo modo `test-maquina-virgen.sh
  --reproducibilidad [--assets-locales]` (~80 min): copia `git archive` en estado
  cero, `SIM-local.do` canónico, `set processors 1`, y compara SHAs y versión de
  Stata contra el ancla. Nuevo **Gate 9** en `publicar.sh`: ancla declarada para la
  versión, alineada con `fuentes_congeladas_al` del manifest y con el asset de
  fuentes. Política: se re-ancla en cada release de datos y cuando el código mueva
  números, nunca en silencio, con el delta en este CHANGELOG.
- **Lo que fija la receta, medido (F0):** misma receta dos veces desde cero (SE
  19.5) → `output.txt` y sankeys idénticos al byte, con 815 descargas idénticas;
  Stata 17 vs 19.5 → 52 de ~5,000 valores distintos (el "~1e-4 en INCD/APORT"
  que v8.7.2 atribuyó a `635b14dc`); MP con 1 vs 10 procesadores → `output.txt`
  idéntico, sankeys distintos (`collapse (sum)` por hilos); `sort` rompe empates
  con un RNG propio (`sortseed`) que avanza con cada `sort` de la sesión, así que
  los bits de un `collapse` dependen de qué corrió antes (ruido que `output.txt`
  absorbe y los sankeys a 16 dígitos no).
- **Ancla v8.8.0:** `output.txt` SHA-256
  `e40af4a6dda77d3a042228a291d55443fc020d3bf431698b179e7c11385a4d27` (fuentes
  2026-10-06, StataNow 19.5 SE, `set processors 1`, IVAT 23.1; 62 min desde
  estado cero con fuentes congeladas, sin red salvo assets); los 5 sankeys en el
  json. Compuerta: esa corrida congelada reproduce **al byte** los 5 sankeys de la
  regeneración en vivo del mismo día y su `output.txt` salvo las dos líneas
  esperadas (línea 1 del fix `do`/`run` e `IVA:[…,23.1]`). Para la capa NL: ver el
  anexo del PR (actualizar la cita `ae624b98` y re-verificar D.1).
  **Ancla definitiva (2026-10-07, commit `1ce94de`):** la receta se volvió a correr
  desde estado cero tras mover `SIM.do` §0.0 a `SIMroot` v8.6 y con `ISR_Mod.do`
  congelado: `output.txt` y los 5 sankeys **idénticos al byte** a la corrida anterior
  (65 min); el json solo cambia `commit` y `anclado_el`.

## [v8.7.2] — 2026-10-06

### Correcciones

- **`SIM.do` se autolocaliza: el simulador corre desde el ZIP de GitHub sin
  `profile.do` ni `sysdir set SITE`.** Reproducido con el ZIP real
  (`SimuladorCIEP-master`, ruta con espacios, sin profile.do cargado): (1)
  `do "…/SIM.do"` desde otra carpeta de trabajo → `command SIMroot is
  unrecognized` (y `scheme ciep not found`), porque los `.ado` solo se veían por
  `"."`; (2) doble clic en `SIM.do` o `cd` previo → arranca, pero `Expenditure.do`
  hace `cd raw/ENIGH` y el siguiente `.ado` aún no cargado truena (`command LIF
  is unrecognized`; en la máquina del alumno, `perfilpc`). Producción no lo
  sufría porque la receta batch del runbook hace `sysdir set SITE`. Ahora
  `SIM.do` §0.0 localiza su carpeta **antes** de `set scheme` (carpeta de
  trabajo con `SIMroot.ado` + `05_scripts/manifest.json`, o SITE), la mete al
  adopath y llama `SIMroot, dir()`; si no la encuentra, se detiene con la
  instrucción en español (`File > Change Working Directory…` o `cd`, y luego
  `do "SIM.do"`; r(601)). **`SIMroot` v8.5** hace lo mismo para cualquier otro
  punto de entrada (interactivo, drivers, `Web.Stata.do`): si la raíz es un clon
  (trae `SIMroot.ado`), entra al adopath (idempotente). Gancho `SIM_SMOKE=1`
  (variable de entorno) para la prueba sin correr el pipeline.
- **Compuertas.** `output.txt` SHA-256 `ae624b98…45fa15` **idéntico** (a) con la
  receta `sysdir set SITE` y (b) sin ella con `profile.do` (flujo del
  investigador); el ZIP sin profile.do en `/tmp/Prueba Alumno/SimuladorCIEP-master`
  llega a TOUCH-DOWN (701 s con cachés). `test-maquina-virgen.sh --zip` (nuevo):
  arma la copia `git archive` sin git en una ruta con espacios y prueba las tres
  vías (otra carpeta → mensaje r(601); carpeta del simulador sin profile.do →
  autolocalización y `.ado` visibles tras `cd`; con profile.do → ídem);
  `--completo` corre SIM.do entero. README: "Inicio rápido para estudiantes"
  (5 pasos) con la salida correcta de Stata (`exit, clear`): el "end
  unrecognized" al cerrar no lo emite SIM.do ni profile.do en ninguna vía — es
  exactamente el mensaje de teclear `end`, que no es un comando de Stata.
- **Symlink `raw/` commiteado por error en `fd7caa1`** (eliminado; `.gitignore`
  ahora ignora las entradas `/raw`, `/master`, `/users` y no solo su contenido):
  apuntaba a una ruta local de la máquina de Ricardo y viajó en el ZIP de GitHub
  como enlace roto; en otra máquina `mkdir raw` y `ensure_asset` fallan.
- **Hallazgo abierto (no se corrige aquí): el `output.txt` por defecto depende de
  intermedios de `raw/temp/2024/` del 22-sep-2026.** `Expenditure.do` reutiliza
  `pre_iva.dta`, `pre_iva_final.dta`, `preconsumption.dta` y
  `va_por_clase_actividad.dta` si existen; una máquina limpia los reconstruye y
  obtiene un `output.txt` distinto (`635b14dc…`: diferencias de ~1e-4 en los
  bloques INCD/APORT del ciclo de vida), mientras que con los intermedios del
  22-sep se reproduce `ae624b98…`. Hay que regenerar `raw/temp` (`global
  update`) en el próximo release de datos y fijar el default con intermedios
  frescos; mientras, la paridad se mide con los intermedios vigentes.

### Institucional

- **Proceso de release de punta a punta y Gate 8 "Release remota completa"**
  (`05_scripts/publicar.sh`, `02_governance/runbook-deploys-ciep.md`). Incidente
  2026-10-05: las Releases v8.6.1, v8.7.0 y v8.7.1 se crearon a mano desde los
  tags, sin assets; como el manifest ya apuntaba `release_url_prefix` a ellas,
  `ensure_asset` recibió 404 en el `SIM.do` nacional hasta espejar los 26 assets
  a v8.7.1. `publicar.sh --check` ahora consulta GitHub y falla si la Release de
  la versión existe sin los assets del manifest (o con otro tamaño); nuevo modo
  `--solo-assets` para reparar una Release existente (sube lo que falta y
  verifica SHA, sin tag/push/endpoint). El runbook deja escrita la secuencia
  completa (PR → merge → tag → `publicar.sh` inmediato → `test-maquina-virgen
  --download` → VPS → gate humano → pull de la Carpeta) y la decisión de
  **mantener el prefix por versión** (Release inmutable = código + datos) en
  lugar de anclar los assets a una Release fija, con el trade-off documentado.
  v8.6.1 y v8.7.0 siguen sin assets: `publicar.sh v8.6.1 --solo-assets` y
  `v8.7.0 --solo-assets` las completan (o se declaran superadas en sus notas).

## [v8.7.1] — 2026-10-05

### Correcciones

- **`PIBDeflactor` v8.1: años de valor presente anteriores a (último trimestre
  publicado − 5) ya no truenan.** §2.1 detecta el "último trimestre observado"
  buscando la primera fila con `pibQ` faltante dentro del rango
  `anio <= aniomax`, y `aniomax` por default es `aniovp + 5`. Si `aniovp + 5`
  queda antes del último trimestre publicado (hoy 2026q2), ninguna fila del
  rango tiene `pibQ` faltante, `aniofinal`/`obsfinal` no se definen y la
  rutina aborta con `pibQ not found` (`r(111)`). Como `SCN.ado` llama
  `PIBDeflactor, anio(`anio')` sin `aniomax` y `Households.do` llama
  `PIBDeflactor, aniovp(anioenigh)`, **`SCN, anio(2016|2018|2020)` y la
  armonización de las ENIGH 2016, 2018 y 2020 fallaban** en v8.6.0–v8.7.0
  (caso borde nunca ejercitado: el nacional corre con `aniovp >= 2024`;
  2022 y 2024 sí pasaban porque `aniovp + 5 > 2026`). Corrección mínima: si
  el bucle no definió `obsfinal`, el último observado es la última fila del
  rango (4 líneas). **Sin efecto en producción:** con `aniovp >= 2024` el
  bucle sí define `obsfinal` y el bloque nuevo no se ejecuta.
- **Compuertas.** (1) `PIBDeflactor, aniovp(2016|2018|2020|2022)` y
  `SCN, anio(...)` corren (antes `r(111)` en 2016–2020; PIB 2016 =
  20,758,790,507,000 MXN). (2) No-regresión: la base de `PIBDeflactor,
  aniovp(2027) aniomax(2032)` antes y después del cambio es idéntica
  (`cf _all`). (3) Paridad nacional: `SIM.do` completo (PE 2027, receta
  batch del runbook) produce `users/ricardo/output.txt` con SHA-256
  idéntico al de v8.6.0/v8.7.0 (`ae624b98…45fa15`). Detectado durante la
  construcción de la capa NL (`DIAGNOSTICO_NL.md`, anexo Participaciones
  históricas F0 §0.5-A): la capa necesita correr el motor sobre cada ENIGH
  bienal con calibración contemporánea (`anioPE = aniovp = anioenigh`).

## [v8.7.0] — 2026-10-05

### Comandos

- **`AccesoBIE` v8.1: opción `area(##)` para indicadores por entidad
  federativa.** El BIE (versión 2025) exporta cada indicador con las 33 áreas
  geográficas apiladas en la columna "Área geográfica" (00 nacional, 01–32
  entidades); las claves clásicas por estado ya no responden y `ag=` se
  ignora. `AccesoBIE` leía periodo/valor sin mirar el área: correcto para las
  series nacionales (solo traen el área 00), pero un indicador estatal (PIBE,
  ITAEE) mezclaría los 33 estados. La capa NL lo resolvió con un lector
  propio (`_NLbie`, NL-0.2.0); este cambio lleva la capacidad al motor.
  **Estrictamente aditivo:** sin `area()` el código que corre es el mismo
  (byte-idéntico). Con `area(##)`: descarga la **tabla completa** del
  indicador por la consulta pública una vez por sesión (global
  `INEGI_AREAS_<serie>`), la cachea en `raw/temp/AccesoBIE/<serie>_areas.csv`
  (`periodo, area, valor, nota`) + `.meta` (título, fecha de consulta INEGI,
  áreas, n, URL) con **escritura atómica** (`.tmp` → `os.replace`; si la
  respuesta no trae tabla, columna de área o filas, aborta con mensaje y el
  último caché bueno queda intacto), filtra el área al cargar y muestra filas,
  fecha de consulta y `checksum` de la tabla completa. El comparativo nacional
  (`area(00)`) sale del mismo pull. Falla con mensaje claro si el indicador no
  trae el área pedida (lista las disponibles) o si `area()` no es 00–32.
  Nueva sección "Indicadores por área geográfica" y ejemplo 6 en
  `AccesoBIE.sthlp`. Propuesto en `DIAGNOSTICO_NL.md` (anexo PIBDeflactorNL
  §0.2, hallazgo 1); detectado durante la construcción de la capa NL.
- **Compuertas.** (1) No-regresión nacional: las descargas que usa el motor
  (`734407 735143 446562 446565 446566`, `910392`, bloque SCN
  `724014–724025`, `734407` con nombre automático) antes y después del cambio
  producen **18 cachés `.csv` con SHA-256 idéntico** y 4 bases `cf _all`
  idénticas. (2) Validación cruzada: `AccesoBIE <id>, area(19)` reproduce con
  **igualdad exacta** los valores de `_NLbie <id>, area(19)` para las series
  NL en producción — PIBE corriente `750453` y real `746097` (22 años), ITAEE
  original `741180` y desestacionalizado `741927` (185 trimestres). (3)
  Negativos: `910392, area(19)` → `r(459)` "no trae filas para el área 19;
  disponibles: 00"; `area(99)` y `area(ab)` → `r(198)`.

## [v8.6.1] — 2026-10-04

### Correcciones

- **`DatosAbiertos.ado` v8.1: `UpdateDatosAbiertos` ya no fabrica la clave
  `XACGF00` y vigila la costura histórico/vigente y las transferencias por
  entidad.** Detectado durante la construcción de la capa NL
  (`DIAGNOSTICO_NL.md`, anexo Federación↔NL F0 §5, rama `feature/entidad-nl`).
  (1) **`XACGF00` duplicada.** §4.7 apendizaba una serie derivada
  `XACGF00` = `XAC2800 + XAC3300` ("Gasto Federalizado") que colisionaba con
  la clave homónima de la SHCP ("Total: Total Gasto Federalizado" = R28 + R33
  + convenios + R23 + PSS, publicada desde 1997): 356 periodos con dos filas
  y un total nacional ~2× (2024: 4.88 vs 2.59 billones). La derivada era
  redundante y de definición más estrecha; **se elimina** (440 filas menos en
  el caché). (2) **Costura 2011.** El caché del 22-sep-2026 traía en 2011
  filas nacionales de R28 (−6.9 %), FAIS (−47 %), FAM (−30/−53 %), FAFEF
  (−41 %) y FAETA (−12 %) por debajo de la suma de entidades. La causa **no
  era la costura `_hist`/vigente** (los diez archivos de la SHCP no se
  traslapan: 0 claves en común) sino el csv vigente de ese día: la SHCP lo
  publicó truncado — 5,611 filas de 2011 ausentes (1,046 de transferencias,
  4,565 de deuda pública) y bloques de filas repetidas — y el motor lo
  absorbió sin aviso; el csv del 30-sep-2026 está completo y el caché del
  3-oct ya cuadraba. Para que no vuelva a pasar en silencio: (a) **compuerta
  `_DAcompuertaEntidades`** sobre los dos archivos de transferencias: cada
  fondo×mes trae ≥ 32 entidades y la fila nacional (`00`) es la suma de las
  entidades (|Σ − nacional| ≤ max(1e-3·|nacional|, 10 mil pesos); el ruido de
  redondeo de la SHCP es ≤ 1e-4 y ≤ 3.1 mil pesos); si falla, lista los
  peores casos y aborta con `r(459)` **conservando el caché anterior**
  (probada en negativo con el csv del 22-sep: 102 fondo-mes alarmados, todos
  de 2011); (b) **costura explícita** tras el append: si un (clave, ciclo,
  mes, tipo) viene en el histórico y en el vigente, manda el vigente (hoy es
  no-op; probada con 1,326 filas sintéticas traslapadas → caché idéntico);
  (c) **`isid clave anio mes tipo`** antes de guardar, que habría atrapado
  (1) al nacer.
- **Impacto en salidas publicadas: ninguno.** Ningún `.ado`, módulo, nodo ni
  escalar consume `XACGF00` (solo `legacy/Subnacional.do`, sin mantenimiento,
  y un bloque congelado de `PEF.ado`). Las 132 filas de 2011 de claves
  consumidas que faltaban en el caché del 22-sep (11 componentes de deuda
  bruta de `SHRFSP`) solo entran a escalares del año de política (exógenos),
  no a 2011; el caché de producción se regeneró el 3-oct con el csv completo.
- **Compuertas del fix** (caché regenerado en modo `local` con los csv del
  30-sep-2026, byte-idénticos a la descarga del 4-oct): caché nuevo =
  caché anterior menos las 440 filas derivadas (`cf _all`: 0 diferencias);
  454,380 filas fondo×entidad×periodo del csv fresco = caché (reldif 0);
  Σ entidades = nacional en los 1,157 fondo×año (máx 1.17e-5, 2011 incluido);
  `UpdateSHRFSP` y `UpdateLIF` producen `SHRFSP.dta` y `LIF.dta` idénticos;
  `SIM.do` (receta del runbook, PE 2027) produce `output.txt` y los cinco
  `sankey-*.json` con el mismo SHA-256 antes y después.
- `DatosAbiertos.sthlp`: nota "Construcción de la base" (series derivadas,
  costura y compuertas).

## [v8.6.0] — 2026-10-03

### Comandos

- **`Simulador.ado` v2.0: bootstrap por diseño muestral en Mata, inferencia
  corregida y 15× más rápido.** Hasta v1.x cada réplica corría PERF, INCI, CICLO
  y REC como programas con `preserve`/`collapse`/`restore` sobre la base
  completa (~3.7 s por réplica en 217 variables × 308 mil personas; B=100 × 20
  variables de PerfilesSim ≈ 2–3 h), y remuestreaba **personas** (`bsample _N`).
  Ahora: (1) una sola extracción de columnas, índices de grupo precalculados y
  sumas por `panelsum`; los deciles de `xtile` ponderado se reproducen en Mata
  (exacto: 0 diferencias en 308 mil personas) y, como son bloques contiguos en
  el orden de la variable, INCI y CICLO no reordenan por réplica. B=1 en 3.0 s
  (5.6 s antes); B=100 en ~24 s. (2) `cluster(upm)` por default: UPM dentro de
  estrato de diseño (`upm`, `est_dis`, de la base o de
  `raw/ENIGH/<anio>/concentrado.dta`), como `bsample, strata() cluster()`;
  `hogar` y `persona` disponibles. (3) **Inferencia corregida:** el puntual es
  el de la muestra completa (réplica 0) y el EE la desviación estándar de las
  réplicas, con IC normal y percentil. En v1.x el puntual era la media de las
  réplicas y el "IC" venía de `ci means` sobre ellas —el intervalo de la MEDIA
  de las réplicas, ancho ∝ sd/√B—, que se encogía con B: subestimaba el
  intervalo 3.2× con B=10 y 10× con B=100. Con B=100 y `gas_pc_Alim` 2024 el
  EE relativo del total es 0.44% por UPM-estrato, 0.55% por hogar y 0.34% por
  persona. (4) Los cinco archivos de salida conservan su esquema (los leen
  Perfiles, FiscalGap y CuentasGeneracionales) y con B=1 coinciden con v1.x a
  precisión de máquina (≤ 4e-14 relativo, mismas filas y missing; test en
  `05_scripts/test-simulador-dorado.do`); nuevo `<var>PT.dta` con los
  puntuales. `legacy` conserva el bloque v1.x. `ProyGraph` toma la carpeta del
  B corriente (antes `bootstraps/1` fijo) y promedia réplicas por año. Nota
  metodológica en el encabezado del `.ado` y en
  `03_help/PROGRAMAS_AUXILIARES.md` §13. Pendiente: `Perfiles.ado` y
  `CuentasGeneracionales.ado` siguen con `ci means` sobre réplicas.
- **`global bootstrap` en `SIM.do` §0.4 (default 1):** las 35 llamadas a
  `Simulador` de `PerfilesSim.do` y el loop de AportacionesNetas usan
  `bootstrap($bootstrap)`. En producción el sitio corre PerfilesSim en cada
  simulación, así que queda en 1 (sin EE); con 100 se obtienen EE e IC 95% por
  UPM-estrato a ~25 s por variable.

### Infraestructura

- Deployment VPS `v8.6` (minor): primer deployment desde v8.4; incluye
  `perfilpc` (v8.5.0) y `Simulador` v2.0.

## [v8.5.0] — 2026-10-03

### Comandos

- **`perfilpc.ado` (nuevo) sustituye el bloque "Iteraciones" de
  `01_modulos/Expenditure.do` y cambia el método del reparto intra-hogar:
  precisión relativa de 6 cifras y paro por tolerancia, en lugar de centavos
  y 25 iteraciones fijas. CAMBIA RESULTADOS.** El reparto del gasto del hogar
  entre sus integrantes por perfil edad-sexo (punto fijo) hacía 220 `tabstat`
  + 440 `replace` por iteración sobre las ~309 mil personas: ~440 s por
  variable × 84 variables ≈ 10 h por ENIGH. Ahora es una función Mata con
  `panelsum` por celda y por hogar (~0.02 s por iteración). (1) **Fidelidad
  demostrada:** el modo `legacy` reproduce el bloque original con
  diferencias ≤ 3e-11 pesos (2 y 25 iteraciones, `gas_pc_Alim` 2024), sumas
  ponderadas idénticas al peso, resultado independiente del orden físico de
  la base; `05_scripts/test-perfilpc-dorado.do` lo verifica variable por
  variable contra el bloque viejo verbatim. (2) **Hallazgo que motivó el
  cambio:** el redondeo a centavos cuantizaba las cantidades per cápita
  (0.01–1 unidad por celda): el perfil quedaba atrapado en la rejilla de .01 y
  Δ caía a 0 exacto de golpe (`cant_pc_Alqu` en la iteración 19), con error
  de hasta ±0.005 por celda; y las 25 iteraciones no eran convergencia: en
  Alimentos 2024 el gasto per cápita de 0–4 años seguía bajando (12,988
  inicial → 3,732 en la 25 → 2,700 convergido) y el de 30–64 subiendo (18,352
  → 23,423 → 23,728); **el resultado dependía de T**. (3) **Método vigente:**
  `m_c` se redondea a 6 cifras significativas (piso `1e-6·máx m`) y se itera
  hasta que la fracción del gasto total que cambia de celda edad-sexo baja de
  `tol(1e-6)` (criterio adimensional: gasto y cantidades convergen al mismo
  nivel), con `maxiter(1000)`; en ENIGH 2024 las 82 variables convergen en
  105–574 iteraciones (media 255), 7–9 s por variable con gráficas;
  Expenditure.do completo con `nographs` en ~15 min. El criterio por celda (máximo
  relativo) se descartó como paro porque lo dominan celdas con poca población
  (ages 100+) y las que tienden a cero; se reporta como diagnóstico. (4)
  **Gráficas**, en memoria con nombre y en `users/$id/graphs/`, tres por
  variable (`<var>_<anio>_pc/_tot/_conv`): pirámides demográficas (edad en
  vertical, hombres a la izquierda, mujeres a la derecha, como en
  `Simulador.ado`) del gasto per cápita y de la distribución del gasto total
  por edad y sexo —perfil inicial, hasta 24 iteraciones intermedias y final—
  y la convergencia en términos relativos con la línea de tolerancia; más una
  gráfica resumen por grupo (`conv_<categ>_<anio>`) con las iteraciones que
  necesitó cada variable. Stata admite 2,000 sersets en memoria y un serset
  es una muestra distinta, no un plot (la primera versión, con `if iter==t` ×
  `by(sexo)`, gastaba ~100 por variable y abortaba con `r(1001)` en la
  novena): cada serie va en su propia variable sobre la misma muestra. Pasar
  la trayectoria completa como matriz de Stata (50 mil filas) tardaba más que
  iterar: `r(perfil)` trae solo las iteraciones que se dibujan. Nota
  metodológica en el encabezado del `.ado` y en
  `03_help/PROGRAMAS_AUXILIARES.md` §17.
- **`Households.do`: ruta corregida a `01_modulos/Expenditure.do`** (apuntaba al root,
  anterior a la reorganización de prefijos).
- **Expenditure.do §3.1–3.2: el relleno de la rejilla hogar/individuo ×
  categoría ya no usa `reshape wide → long → wide`.** Un solo `reshape wide` +
  `replace = 0` (gasto, cantidad) y `= media global` (`prop`) produce la misma
  base (`cf _all` idéntico sobre 91,414 hogares × 19 categorías de 2024). La
  media de `prop` se pasa por escalar temporal, no por `local`: el `local`
  perdía el último dígito del `double` y rompía la identidad byte a byte.

## [v8.4.3] — 2026-10-03

### Institucional

- **`02_governance/` reorganizada como norma + memoria + guía (2026-10-03, tres
  commits).** La carpeta había llegado a 24 archivos con un índice que listaba 5,
  y el documento de arquitectura (981 líneas) abría afirmando que `publicar.sh`,
  el CHANGELOG y `sim_changelog` "aún no están implementados" tres meses después
  de operar en producción, arrastrando 57 filas de bitácora que duplicaban este
  registro. (1) Cuatro reportes one-shot ya ejecutados (reconocimiento del VPS;
  inventario, plan de integración y verificación del repo del Paquete 2027) a
  `historico/` con nota de retiro; los cuatro documentos de diseño del rediseño
  de `paqueteeconomico.ciep.mx` a `paquete-economico/` con README propio;
  `arquitectura-procedimientos-stata-web.md` → `principio-stata-produce-los-numeros.md`.
  (2) `arquitectura-y-bitacoras.md` separado en `arquitectura.md` (vigente:
  encabezado reescrito al estado real, §7 solo con lo pendiente, backup como
  operando, troubleshooting como apéndice) y `historico/bitacora-arquitectura.md`
  (tabla v1.0–v1.57 y narrativa de deploys, congeladas); la política de higiene
  pasa al README de la carpeta y la tabla formal/coloquial al glosario (v1.1).
  Regla nueva: ningún documento de norma registra cambios del Simulador; eso es
  exclusivo de este CHANGELOG. (3) Nueva `guia-simulador-bien-gobernado.md`:
  doce principios para quien construye su propio simulador (motor no script,
  una sola fuente de números, permanente vs. regenerable, candado de datos,
  fallar en el origen, versión inmutable, un commit una idea, demostrar no
  razonar, compuertas al publicar, secretos fuera del repo, coincidir ≠
  verificar, gobernar la gobernanza), cada uno con el incidente fechado que lo
  originó y la ruta donde se ve en este repo, más una lista de arranque para la
  primera semana; README reescrito como mapa por audiencia. Referencias
  actualizadas en README raíz, scripts de publicación, `escalar.ado`, manual del
  investigador y HTML de nodos; las citas dentro de este CHANGELOG quedan como
  estaban.
- **Museo de versiones (`simuladorfiscal.ciep.mx/anteriores/`) rediseñado y
  restaurado — cuarto canal del Simulador, con fuente en `04_3_anteriores/` y
  pipeline propio (`05_scripts/publicar-anteriores.sh`, gates: auditoría
  estática `verify_anteriores.py` + destino escribible; Apache lo sirve con
  `Alias /anteriores /var/www/anteriores`, estático, fuera del deployment
  `current`).** La galería `index.html` adopta el lenguaje visual del
  Simulador actual (header `#2d373d`, hero `#FFD520`, Roboto Mono/Ubuntu,
  tarjetas con chips y captura real de cada generación, footer del
  ecosistema CIEP). Cada pieza (v1 2014, v2 2014, v3 2015-16, v4 2018) lleva
  una franja fija de contexto y un interceptor que vuelve inertes botones y
  formularios con aviso (`assets/museo.js`), y las librerías externas
  (jQuery/jQuery UI/fancybox/Bootstrap/Chart.js) se vendorizaron en
  `assets/vendor/` porque las piezas las cargaban por `http://` y el sitio
  `https` las bloqueaba como *mixed content*. Regla acordada: donde el
  original mostraba resultados calculados al vuelo, se reconstruyen con las
  **cifras oficiales del año** y una nota visible; lo ilustrativo se declara.
  Por pieza: **v1** — las tarjetas estaban en cero porque el JS leía
  `default.php`/`inputsaved.php` (no capturados): ahora lee `default.xml`
  con la LIF/PEF 2014 de `master/LIF.dta` (46 conceptos del artículo 1,
  cuadra 3,816,747.8 y 4,467,225.8 mdp), deuda 650,478, GINI 0.48;
  formularios a `localhost` neutralizados. **v2** — las 5 páginas interiores
  estaban vacías (contenido por AJAX desde `parts/*.php`, nunca capturado):
  se reconstruyeron menú lateral, incidencia del módulo IVA, perfil
  generacional con el velocímetro original (`gauge.js`), recaudación,
  incidencia global (los `$100…-10%` eran *placeholders* de desarrollo),
  sostenibilidad (SHRFSP 2000-2020), distribución del PEF y Ramos 28/33
  (la página era una copia de la portada); el demo del velocímetro tronaba
  y jQuery 1.10 abortaba el resto de `ready`, por eso el menú se carga con
  JS plano. **v3** — `google.com/jsapi` (retirado) → `loader.js`; el on-load
  llamaba `defaultStata.php` con `alert()` en el error (bloqueaba la página)
  y 86 campos: `defaultStata*.xml` generados desde los valores que la
  página ya traía (tablas, perfiles) más proyecciones ilustrativas; `js/chart.js`
  (barras SHRFSP) faltaba por mayúsculas en Linux → recuperado de v2; línea
  `getRandomImage` corrompida por wget; treemaps guardados contra la carga
  asíncrona. **v4** — GTM/Analytics retirado, `localhost` fuera. Auditoría
  final: 0 recursos rotos, 0 hosts de desarrollo en 42 páginas. Pendiente
  operativo: `chown ciepmx:web /var/www/anteriores` (una vez) antes del
  primer deploy con el script.

### Correcciones

- **`AccesoBIE`: `anio` salía como texto (`str7`) y `SCN, update` tronaba
  con `r(106)` en el merge contra `IngMixto.dta`.** El BIE ahora marca la
  cifra preliminar como `"2025 p1"` (con espacio, no `/p1`); la limpieza
  anterior solo quitaba `r1`, así que `destring` no convertía y las 11 bases
  del BIE se cruzaban entre sí (todas `str7`) hasta chocar con la primera
  base de tabulados CSI con `anio` entero. Ahora `periodo` se fuerza a string
  y se le quita cualquier nota al pie al final (`2025 p1`, `2026/01 r1`,
  `2024/p1`, `2023 /a`) con un regex; además, `AccesoBIE` verifica al salir
  que `anio` sea numérico y, si no, aborta con `r(109)` listando los periodos
  que no pudo convertir, en lugar de dejar que el error aparezca aguas arriba.
- **Leyenda de descarga de `AccesoBIE` sin la cola repetitiva.** La línea
  `Serie | Variable | ...` mostraba los últimos 80 caracteres del nombre del
  indicador, que casi siempre eran `(Millones de pesos a precios corrientes)
  Anual /a`; el `replace` que debía quitarla buscaba un texto que el BIE ya no
  usa. Ahora se eliminan notas al pie, unidad entre paréntesis y frecuencia y
  se muestra la jerarquía completa del indicador; la etiqueta de variable
  (`label var`, tope de 80 bytes) conserva los niveles más específicos de esa
  jerarquía.

## [v8.4.2] — 2026-09-23

### Correcciones

- **`net install Poblacion` (y `PIBDeflactor`, `SCN`) tronaba en máquina
  virgen con "command ensure_asset is unrecognized".** En v8.4.1 `Poblacion`
  empezó a llamar `ensure_asset` pero `Poblacion.pkg` no lo listaba, ni
  `PIBDeflactor.pkg`/`SCN.pkg` (que llaman `Poblacion`). Lo atrapó la prueba
  post-publicación de máquina virgen (`net from` al endpoint público + `cd` a
  carpeta vacía); v8.4.1 estuvo ~20 minutos en el endpoint con ese hueco.
  Los tres `.pkg` ahora traen `f ensure_asset.ado`.

### Institucional

- **Gate 7 en `publicar.sh`: clausura transitiva de los `.pkg`.** La regla de
  v8.0.11 ("cada `.pkg` declara TODAS sus dependencias `.ado` transitivas")
  solo se verificaba a mano y volvió a fallar en cuanto una dependencia
  cambió. El gate hace grep de cada comando publicado (inicio de línea, con
  prefijos `noisily`/`quietly`/`capture`) en cada `.ado`, cierra
  transitivamente y compara con las líneas `f X.ado` del `.pkg`; corre en
  `--check` y antes del tag. Probado: falla con los tres `.pkg` de v8.4.1 y
  pasa tras corregirlos.

## [v8.4.1] — 2026-09-23

### Datos

- **`Poblacion` deja de depender de CONAPO en vivo: la proyección entra al
  data sidecar.** Los tres CSV de
  `conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/` que
  `UpdatePoblacion` leía con `import delimited` dejaron de servirse (timeout
  también con `curl`; era el pendiente declarado en v8.4.0). La misma
  proyección — Conciliación Demográfica 1970–2019 y Proyecciones 2020–2070,
  `pry23` del 11-sep-2023 — la redistribuye la DGIS-Salud en
  `dgis.salud.gob.mx/descargas/datosabiertos/poblacion/proyecciones_censo/Poblacion_Estimada_Mitad_Anio.zip`
  (4.9 MB, CSV largo por año × entidad × edad simple × sexo). Ese zip es el
  asset 26 de `manifest.json` (`raw/CONAPO/`, SHA-256 `e77873cd…`) y
  `UpdatePoblacion` lo pide con `ensure_asset`, lo descomprime en
  `raw/temp/CONAPO/` y lo importa; la fila `Nacional` (antes "República
  Mexicana" de CONAPO) se reconstruye como suma de las 32 entidades. **Cifras
  idénticas:** `master/Poblacion.dta` regenerado coincide celda a celda
  (733,260 celdas, diferencia 0) con el vintage anterior en 1970–2070,
  incluida `tasafecundidad`; `Poblaciontot.dta` idem.
- **Lo que cambia en el esquema:** la cobertura pasa de 1950–2070 a
  **1970–2070** (DGIS no redistribuye 1950–69) y desaparecen `defunciones`,
  `emigrantes` e `inmigrantes`. Se verificó con `grep` en todo el árbol que
  ningún módulo (`PIBDeflactor`, `SCN`, `DatosAbiertos`, `PerfilesSim`, `REC`,
  `CuentasGeneracionales`, sitio) consume esas variables ni años < 1970;
  `Poblacion.sthlp`, el manual del investigador y la ficha de fuentes del
  nodo de deuda quedan alineados. Patch y no minor porque ni la metodología
  ni un solo número publicado cambian; el `data_updated` del manifest no se
  toca (mismo vintage).

## [v8.4.0] — 2026-09-23

### Comandos

- **Nuevo `SIMroot`: la raíz de datos del Simulador deja de ser
  `c(sysdir_site)` y pasa a la global `$SIMROOT`.** Hasta v8.3 los ~450
  usos de `` `c(sysdir_site)' `` en 41 archivos (`SCN` 90, `Expenditure.do`
  61, `Simulador` 24…) usaban el directorio SITE de Stata como raíz de
  `raw/`, `master/`, `users/` y `01_modulos/`. Eso solo funcionaba porque
  `sysprofile.do` lo redefinía al clon; para quien instalaba desde el
  endpoint (`net install`), SITE es `/Applications/Stata/ado/site/` o
  `C:\Program Files\Stata18\ado\site\` — sin permisos de escritura y sin
  que ningún `.sthlp` avisara del `sysdir set SITE` necesario. En esta
  máquina, `/Applications/Stata/ado/site/` ya tenía `raw/temp/` y
  `users/ricardo/` creados por corridas viejas: el síntoma en vivo.
  `SIMroot [, dir() reset quietly]` resuelve la raíz una vez por sesión:
  (1) `$SIMROOT` ya fijada → nada; (2) `dir()` explícito; (3) `c(sysdir_site)`
  contiene `05_scripts/manifest.json` → es un clon apuntado por
  `sysprofile.do` (investigadores CIEP, servidor): compatibilidad total;
  (4) si no, el directorio de trabajo `c(pwd)`, con aviso de dónde se
  escribirán los datos. Crea `raw/`, `raw/temp/`, `master/`, `users/`.
  Todos los `.ado` lo invocan al arrancar (idempotente); `SIM.do` lo llama
  tras su `macro drop _all`; `profile.do` fija la raíz a la carpeta donde
  él mismo vive (`findfile profile.do`), no a SITE; `Web.Stata.do` la fija
  explícitamente con `dir()`. Los bloques Python (`ensure_asset`,
  `AccesoBIE`, `sim_changelog`, `profile.do`) leen `Macro.getGlobal('SIMROOT')`.
  `SIMroot.ado` viaja en todos los `.pkg` (clausura transitiva, regla de
  v8.0.11) y tiene `.sthlp` y `.pkg` propios. `sysprofile-template.do`
  conserva `sysdir set SITE` (sigue siendo cómo Stata encuentra los `.ado`
  y el `profile.do` del clon) y documenta que ya no decide dónde van los
  datos.

### Institucional

- **`test-maquina-virgen.sh --download` prueba el camino real del externo:**
  sin `sysdir set SITE`; `adopath ++` a la carpeta con los `.ado`, `cd` a
  ella y `SIMroot` resuelve por `pwd`. Antes la prueba hacía el
  `sysdir set SITE` que el usuario nunca hacía, así que "pasaba" un
  escenario que no existía.
- **Verificación de este release.** (A) Modo repo, StataMP 17 batch, SITE →
  clon, `profile.do` + `PIBDeflactor`, `Poblacion`, `PEF` (`r(Pension_AM)`,
  `r(educacion_basica)`), `LIF`, `SHRFSP`, `SCN`, `DatosAbiertos`: todo
  pasa, `$SIMROOT` = clon. (B) Modo externo, StataNow 19.5 SE, SITE default
  de Stata, `.ado` copiados a una carpeta ajena en el adopath con el pin
  `v8.3.4` inyectado como hace `publicar-endpoint.sh`, `cd` a una carpeta
  vacía: `SIMroot` cae en `pwd` con aviso, `ensure_asset` baja el manifest
  v8.3.4 y dos assets a `pwd/raw/PEFs/` con SHA verificado, `AccesoBIE`
  escribe sus CSV en `pwd/raw/temp/AccesoBIE/`; nada se escribe en el SITE
  de Stata. `PIBDeflactor` en modo externo terminó en `r(603)` porque
  `UpdatePoblacion` descarga en vivo de `conapo.segob.gob.mx`
  (`Poblacion.ado:659,684,709`) y el servidor no respondió (también con
  `curl`, timeout 15 s): **pendiente preexistente**, no regresión — la
  reconstrucción externa depende de tres URLs de CONAPO fuera del sidecar
  de datos; candidato a entrar al `manifest.json` como assets.
- **Documentación negativa.** No se hizo `lower()`/`c(pwd)` a secas en los
  `.ado`: `pwd` cambia con cada `cd` y partiría `raw/` y `master/` en dos
  carpetas a media sesión; por eso la raíz se congela en la global la
  primera vez y solo cambia con `SIMroot, reset` o `dir()`. No se quitó
  `sysdir set SITE` de `sysprofile-template.do` ni de `Web.Stata.do`: SITE
  sigue siendo la vía por la que Stata encuentra los `.ado` y el
  `profile.do` del clon (adopath); lo que cambia es que ya no es la raíz de
  datos. Los `.ado` de `01_modulos/legacy/` no se tocaron.
- Este cambio se desarrolló en la rama de trabajo `raiz-proyecto-simroot`
  sobre un worktree fuera de Dropbox (`~/Developer/`), para que la
  publicación de v8.3.4 corriera desde el clon de desarrollo con árbol
  limpio y sin riesgo de que `publicar-endpoint.sh` copiara al endpoint
  archivos a medio refactor (Fase 2 lee del working tree). La rama se
  integró a `master` con commits limpios y se borró (§2.1 de
  `versionado-y-git.md`).

## [v8.3.4] — 2026-09-23

### Comandos

- **`PEF` guarda los catálogos de texto en Title Case, sin cambiar el
  contrato `r()`.** La limpieza 1.4 de `UpdatePEF` (`_PEFlimpia`) pasa los
  `desc_*` de minúsculas a `ustrtitle()` con artículos y preposiciones en
  minúscula ("Pensión para el Bienestar de las Personas Adultas Mayores"),
  y `desc_ramo` ya no se fuerza a minúsculas; todas las comparaciones
  internas (`ur`, `modalidad`, `desc_pp`, `desc_tipogasto`, `transf_gf`,
  `_PEFverifica`) se actualizaron al caso nuevo. Los nombres de `r()`
  derivados con `strtoname()` **se mantienen en minúsculas cuando `by()` es
  un `desc_*`** (`r(educacion_basica)`, `r(cuota_social_seguro_de_salud_iss)`),
  y los demás conservan su capitalización histórica (`r(Pension_AM)`,
  `r(Educacion)`, `r(Cuotas_ISSSTE)`, estados por `entidad`). Verificado en
  batch contra `master/PEF.dta` regenerado: `by(desc_subfuncion)`,
  `by(divCIEP)` y el loop de `transf_gf` (`by(desc_pp)`) devuelven los
  nombres que leen `GastoPC.ado` y `Households.do`.

### Correcciones

- **`AccesoBIE` no truena con `periodo` malformado.** La limpieza de la
  cadena `periodo` (extracción de 7 caracteres) va con `capture replace`
  para que valores faltantes o malformados del BIE no aborten la rutina.
- **Regresión evitada antes de publicar:** el commit `2b03cb7` (Title Case
  en `PEF`) cambiaba de facto el contrato `r()` de `PEF ..., by(desc_*)`
  porque `strtoname()` conserva mayúsculas: `r(educacion_basica)` pasaba a
  `r(Educacion_Basica)`. Las ~75 lecturas de `GastoPC.ado` y las de
  `Households.do` §1.3 seguían pidiendo minúsculas y, por sus fallbacks
  `if == . → 0`, habrían dejado en cero las cifras per cápita de Educación y
  Salud del `SIM.do` §5 y del sitio **sin error visible**. Se corrigió en
  `PEF.ado` (bandera `lowername` en §1.5, aplicada en los tres sitios de
  `strtoname`) en lugar de tocar los consumidores, para no romper a
  usuarios externos del endpoint que leen esos `r()`. La lección: un cambio
  de capitalización en catálogos que alimentan `strtoname()` es un cambio
  de API, no cosmético.

### Institucional

- `simulador.stpr` actualizado junto con el fix de `AccesoBIE`.
- Este clon de desarrollo había perdido el marker gitignored
  `.clon-desarrollo` (guard de `publicar.sh`, creado el 2026-09-09); se
  volvió a crear con `touch`. Probable causa: Dropbox no conserva archivos
  vacíos con punto en algunos ciclos de sincronización.
- **Sitio (rsync, fuera de git; deploy 2026-09-21 sobre v8.3 sin bump de
  versión):** referencias bibliográficas a los micrositios del CIEP al pie
  de cada tabla de `index.php` e `index-en.php`, en una segunda línea
  `<p class="notas">` junto a la nota de "títulos amarillos". Mapa:
  Ingresos 1–4 → `ingresosenmexico.ciep.mx` (Consumo suma
  `iepsaltabaco.ciep.mx`; Organismos suma `energiaenmexico.ciep.mx`);
  Educación → `gastoeducativo.ciep.mx`; Salud → `salud.ciep.mx`;
  Pensiones → `pensionesenmexico.ciep.mx`; Energía →
  `energiaenmexico.ciep.mx`; Otros gastos → `subnacional.ciep.mx` +
  `inversion.ciep.mx`; Transferencias → `cuidados.ciep.mx` +
  `desarrollosostenible.ciep.mx`; tarjeta Marco Macroeconómico →
  `paqueteeconomico.ciep.mx`. Dominios tomados de `ciep.mx/micrositios`
  (antes `/historias`, renombrada el 2026-09-20 con 301). El clon local
  `04_1_simuladorfiscal.ciep.mx/` se encontró sin `index.php` ni assets
  (solo `health.php`, `plugins/`, `ssl/`, `logs/`) y se restauró desde
  `/var/www/html/v8.3` del VPS antes de editar; con el árbol incompleto,
  `rsync --delete` de la Fase 2 habría borrado el sitio.

## [v8.3.3] — 2026-09-16

### Correcciones

- **`Graphs_TE.do` y `Graphs_PC.do` corren autocontenidos y con lo
  observado de cada año.** `TasasEfectivas` y `GastoPC` toman los parámetros
  de escenario (`ISRASPIB`…, `basica`…) si existen en memoria, y ambos
  do-files están llamados en `SIM.do` justo después de §4.1/§5.1: los 28 y
  15 años habrían salido con los valores de anioPE. Ahora apartan los
  parámetros, los borran antes de cada año (los módulos los vuelven a
  declarar desde LIF/PEF) y los restauran al final — verificado con
  parámetros ficticios (99.9/88.8) que no tocaron las series y volvieron
  intactos. `Graphs_TE.do`: horizonte 2000–anioPE (antes 2001) colgado de
  un solo `anioini` (antes `anioPE-25` en 13 sitios); el texto de derechos
  petroleros decía "De 2000 a 2027 … perdió 15.2 pp" pero calculaba
  max−min de toda la serie (pico 2008) — ahora compara `anioini` vs anioPE
  como las otras dos (5.0 pp) y ya no se encima con las líneas.
  `Graphs_PC.do`: la serie Ciencia y tecnología (`invest`) tenía leyenda
  pero no se graficaba; leyendas en 1–3 filas (antes se encimaban).
  `GastoPC.ado`: el aviso "Creando base … con ENIGH" imprimía el escalar
  global `anioenigh` (2024) y no el local del año pedido. Corrida completa
  verificada: TE 2000–2027 y PC 2013–2027 sin errores; construyó
  `master/perfiles2017/2019/2021/2023/2025.dta` (no existían).
  `Graphs_TE.do` exporta ahora a `users/$id/graphs/TE_*.png` (como
  `Graphs_PC.do`), ya no a `$export`; etiquetas anuales en el eje x.
  `SIM.do` §4.6/§5.1 corre ambos do-files en la corrida completa (+~2 h
  por `Graphs_PC.do`).
- **`publicar-vps.sh` Fase 1b (nueva):** copia las 10 gráficas del sitio
  (`TE_*.png`, `GastoPC_*.png`) de `users/ricardo/graphs/` al docroot local
  ANTES del rsync de la Fase 2 — misma fuente local de verdad que el default
  de la Fase 3b-ter. Si una falta en `users/ricardo/graphs/` conserva la del
  sitio con aviso; si no existe en ninguno, aborta (el index la enlaza).
- **Sitio (rsync, fuera de git):** `images/TE_*.png` regeneradas
  (2000–2027; las anteriores eran de mayo 2025) y `images/GastoPC_*.png`
  nuevas (6), enlazadas con lightbox desde el encabezado "Per cápita" de
  cada tabla de gasto en `index.php` e `index-en.php`. Liga del BIE:
  `inegi.org.mx/sistemas/bie/` → `inegi.org.mx/app/indicadores/?tm=3`
  (4 encabezados "Cuenta Nacional" por idioma).
- **Sitio (rsync, fuera de git): banner del libro CIEP.** La sección
  `#libro-simulador` (texto plano "EL libro del Simulador Fiscal CIEP")
  se sustituye en `index.php` e `index-en.php` por el banner promocional de
  *Finanzas Públicas Antropocéntricas* — mismo patrón que el banner de
  paqueteeconomico.ciep.mx (hero amarillo + portada + CTA a libro.ciep.mx),
  adaptado a la identidad del sitio (Roboto Mono, tarjeta redondeada).
  Assets en `images/libro-promo/`; el ancla del menú se conserva.

## [v8.3.2] — 2026-09-15

**El hero restaba el gasto devengado; la SHCP resta el pagado.** Patch
sobre v8.3.1: cambia un resultado visible del sitio (el endeudamiento de la
ecuación principal pasa de 3.8 a 3.4 % PIB con los defaults del PPEF 2027),
sin datos nuevos. El VPS recibe este árbol en el deploy `v8.3` que quedó
pendiente desde v8.3.1 (producción seguía en el commit `08149e6`, con
`Version: v8.3.0` en `DEPLOYED_COMMIT`).

### Correcciones

- **La ecuación del sitio cierra con el balance presupuestario, no con el
  devengado.** `GASTOS[40]` (el total de la fórmula INGRESOS − GASTOS =
  endeudamiento del hero) sumaba los seis totales de gasto DEVENGADO
  (26.985 % PIB con los defaults del PPEF 2027), así que el resultado
  (−3.76) no coincidía con el balance presupuestario del CGPE 2027 (−3.4,
  `rfspBalance`). La SHCP llega al gasto neto PAGADO restando el
  diferimiento de pagos (LIF divCIEP 8; ILIF 2027: 121,400 mdp ≈ 0.32 %
  PIB) — exactamente lo que FiscalGap 5.9b ya hacía en su tabla, pero el
  sitio no. Fix: `FiscalGap.ado` §5.6 registra `escalar pctpib difpagosPIB`
  (diferimiento de `anio` / PIB, 0 si la LIF no lo trae) y `output.do` lo
  resta en `GASTOS[40]` → 26.665 % PIB, balance −3.44 ≈ −3.4. Se publica
  además la clave `DIFPAGOS: [x]` en `output.txt` (el parser de
  `checkStataStatus.php`/`cargaDefault.php` es genérico; el sitio no la
  consume todavía). Los 40 renglones editables de GASTOS no cambian.

### Institucional

- `manifest.json`: `version`/`release_tag`/`release_url_prefix` → v8.3.2.
  `data_updated` (2026-09-12) y los 25 SHAs intactos: mismos datos que
  v8.3.0/v8.3.1; la Release re-sube los mismos assets.

## [v8.3.1] — 2026-09-14

**Un asset publicado que nadie pedía: la máquina virgen no reconstruía el
PPEF 2027 — sin error.** Ricardo hizo la prueba correcta tras v8.3.0: borrar
`master/` y `raw/` y esperar la reconstrucción completa. `PPEF.2027.xlsx`
estaba en el manifest y en la Release, pero **ningún módulo lo solicitaba**:
`PEF.ado` mantenía la lista de `ensure_asset` como un `foreach` tecleado a
mano (comentario "GitHub Release v7.0": ocho versiones sin tocarla) y descubre
los años con `dir raw/PEFs *.xlsx` — un asset no pedido simplemente no
existía para el módulo. Mismo destino tenía `Diccionario.csv`. El manifest y
la lista del módulo eran dos fuentes de verdad, y ya habían divergido. Patch
porque toca `.ado` publicados (`ensure_asset`, `PEF`, `LIF`). **Envuelve los
tres commits posteriores al tag v8.3.0** (`6b5fad4` whitelist del canon web
a `perfiles2027.dta`; `ef1678f` guard del nodo de deuda cuando no existe el
destino de render; `08149e6` el endeudamiento del Sankey ya no se esconde en
los impuestos al capital), que hasta hoy vivían solo en `master`.

### Comandos
- **`ensure_asset.ado` v1.6 — forma `ensure_asset, dir(<directorio>)`:**
  pide TODOS los assets del manifest cuyo `local_path` vive bajo ese
  directorio, con la misma lógica por asset (descarga si falta, SHA, modo
  WIP) y un resumen (`raw/PEFs/ — 17 asset(s) verificados (17 descargados)`).
  La lista se **deriva del manifest**, única fuente de verdad: agregar un
  asset al manifest basta para que el módulo lo pida. Funciona en los dos
  entornos (manifest local y manifest pineado del endpoint). `<nombre>` y
  `dir()` son excluyentes; sin ninguno, o con un directorio que no cubre
  ningún asset, aborta con mensaje. Refactor interno: `_load_manifest` y
  `_ensure_one` compartidos; el marcador `local PINNED_VERSION ""` que
  `publicar-endpoint.sh` inyecta sigue intacto.
- **`PEF.ado`**: el `foreach` de 15 nombres muere → `ensure_asset, dir(raw/PEFs)`
  (17 assets hoy: CP 2013–2025, PEF 2026, PPEF 2027, CuotasISSSTE,
  Diccionario). El descubrimiento por `dir` y la prioridad CP > PEF > PPEF no
  cambian. **`LIF.ado`** → `ensure_asset, dir(raw/LIFs)`. `DatosAbiertos`
  (un archivo en la raíz de `raw/`) y `Expenditure.do` (un zip por ENIGH,
  cada año exige código propio) siguen pidiendo por nombre; el Gate 6 los
  vigila.
- Nota de inventario: `Diccionario.csv` no lo lee ningún código — el mapeo
  origen→canónico de PEF.ado §3 es inline; es el diccionario de la SHCP
  guardado como documentación del esquema CP 2025 (v8.1.0). Con `dir()`
  viaja igual que los demás.

### Institucional
- **Test de máquina virgen, formalizado en dos capas
  (`05_scripts/test-maquina-virgen.sh`):**
  - `--cobertura` (estático, segundos, sin red): cada asset del manifest
    debe ser solicitado por algún módulo, por nombre (`ensure_asset "X"`) o
    por directorio (`ensure_asset, dir(D)` con `local_path` bajo `D/`).
    Contra el `PEF.ado` de v8.3.0 reporta **17 de 25 sin solicitante** (la
    lista vieja pasaba los nombres por macro: opaca para cualquier auditoría
    estática — otra razón para derivar); con el fix, 25/25.
  - `--download` (dinámico, ~1.3 GB, requiere la Release publicada): SITE
    falso en `/tmp` con `ensure_asset.ado` y el manifest, `raw/` VACÍO, y
    las mismas invocaciones de `ensure_asset` que hacen los módulos
    (derivadas del inventario, no tecleadas); verificación independiente por
    `shasum` de cada asset. Contra la Release v8.3.0: **25/25 descargados y
    verificados**, incluidos `PPEF.2027.xlsx` y `Diccionario.csv` (que la
    prueba manual no ejercitó porque nadie lo lee). No toca el repo ni
    `raw/` real. Se corre DESPUÉS de `publicar.sh vX.Y.Z` y antes de
    anunciar; la corrida completa de SIM.do desde cero sigue siendo la
    prueba manual de Ricardo.
- **`publicar.sh` Gate 6 — cobertura de assets** (también en `--check`):
  delega en `test-maquina-virgen.sh --cobertura`. Un asset huérfano bloquea
  el tag. `--check v8.3.0` con el árbol de hoy: 6/6 gates.
- `runbook-deploys-ciep.md`: paso post-publicación con el test de máquina
  virgen.

## [v8.3.0] — 2026-09-13

**Paquete Económico 2027 (CGPE/ILIF/PPEF 2027) como escenario base, con
horizonte 2027–2032, y reestructura de la brecha fiscal: `FiscalGap` deja
de proyectar a valor presente/infinito y construye una trayectoria anual
cerrada por componentes (ingresos, gasto, costo financiero, RFSP y SHRFSP)
que se despliega en una sola tabla `Proy_fiscal`.** Los números publicados
cambian de forma visible (año base, PEF, horizonte y metodología), por lo
que el release es *minor* con deployment nuevo en el VPS (`v8.3`).

### Datos
- **Paquete Económico 2027:** `raw/PEFs/PPEF 2027.xlsx` (asset nuevo),
  `raw/LIFs/LIFs.xlsx` (ILIF 2027, SHA `7d9db942`) y
  `raw/PEFs/CuotasISSSTE.xlsx` (SHA `68fa8f59`). `manifest.json`:
  `data_updated = 2026-09-12`. Marco macro CGPE 2027 en `SIM.do` §2 y §6
  (PIB 1.41/2.00%, deflactor 3.8/4.0%, inflación 3.8/3.2/3.0%, SHRFSP
  54.0→56.5% del PIB, RFSP 4.1→3.1%, tipo de cambio, balance primario,
  costo financiero, ingresos y gasto 2026–2032). `profile.do`:
  `paqueteEconomico = "CGPE 2027"`, `anioPE = aniovp = 2027`.
- `PEF.ado`: prioridad por año **CP > PEF > PPEF** — si coexisten dos
  versiones del mismo año se usa la de mayor prioridad y se avisa (ya no hay
  que borrar xlsx a mano cuando llega la Cuenta Pública). Diccionario único
  `_PEFhomologa` para todos los layouts SHCP 2013–2027 (CP 2013–2024, CP 2025,
  PEF 2026, PPEF 2027, CuotasISSSTE): elimina columnas fantasma por contenido,
  renombra al layout canónico y **detiene** con lista explícita ante una
  columna desconocida o una canónica faltante. `_PEFlimpia`: montos
  numéricos, mojibake/NBSP/saltos fuera, códigos forzados, detección de
  archivos de bloqueo de Excel.
- `DatosAbiertos.ado`: `_DAlimpia` elimina filas corruptas de los csv de la
  SHCP (registros truncados o pegados, CICLO no numérico, PERIODO_FINAL sin
  AAAA-MM, MONTO no numérico) y `_DAappend` diagnostica y repara tipos
  string/numérica antes de reintentar el `append`, reportando qué base falló.

### Comandos
- **`FiscalGap.ado` — trayectoria anual 2027–2032, sin VP/infinito.**
  Horizonte único `end()` para PIB, SHRFSP y la matriz fiscal (antes cada
  frame tenía el suyo y el último año salía huérfano). §4.3b y §5.3b: tablas
  "LIF vs simulación" y "PEF vs simulación" en el año base con tasas total,
  demográfica y económica (residuo acotado a ±5). Diferimiento de pagos
  (LIF divCIEP 8) sale de los ingresos y viaja como serie propia (la SHCP lo
  resta al gasto devengado). `estimacionGasto`: primero lo micro-simulado
  (× deflator) y después las partidas macro (cuotas ISSSTE constantes como %
  del PIB del año base; antes se inflaban dos veces). §5.9: el motor arranca
  en `anio+1` y sobreescribe los exógenos del CGPE de ahí en adelante; el año
  base se respeta como ancla. §5.9b `Proy_fiscal`: ingresos, gasto devengado,
  primario, costo financiero, diferimientos, gasto pagado, balance, RFSP,
  superávit primario y SHRFSP, calculados desde los componentes. Las
  secciones 6–7 (balance e inequidad en VP) quedan desactivadas hasta
  validar la trayectoria anual. Salida web: `PROY*`/`PROYSHRFSP*`/`PROYCOSTO`
  llegan hasta `end()` (antes tope fijo 2030) y se emite `ANIOEND`.
- **`FiscalGap.ado` §5.5 (corrección):** `gascosto` es % del PIB
  (`SIM.do` §5.1, `GastoPC` §7.2, `GASTOS[34]` del sitio) pero se multiplicaba
  por población (semántica per cápita vieja): el costo financiero del año
  base salía ≈ 0 (`PROYCOSTO` 2027 = 0.0 y fila `Costo_financiero` de
  `Proy_fiscal`). Ahora `gascosto/100 × pibY`.
- `PEF.ado` v8.1: display simétrico con LIF — Tabla A (nivel por `by()`:
  MXN, % PIB, % Tot, per cápita; conciliación bruto→neto con cuotas ISSSTE y
  aportaciones) y Tabla B (crecimiento `desde()`–`anio()`, dif. % PIB,
  crecimiento real, elasticidad). `desde() < anio()` obligatorio (mismo guard
  que LIF). Help `PEF.sthlp` actualizado.
- `SHRFSP.ado`: se retiran las gráficas y mínimos "de 5 años centrales";
  `aniomax()` gobierna el horizonte del PIB (antes `anio+5` fijo).
- `GastoPC.ado`: educación para adultos usa alumnos ADULTOS como denominador
  (col 5; con col 6 se perdía ~99% del monto — 5,862 mill. en 2027). "Otros
  gastos" BRUTO, sin netar cuotas ISSSTE (se restaban dos veces con
  `PerfilesSim` §1.2). Ruta `01_modulos/PerfilesSim.do` corregida.
- `PIBDeflactor.ado`/`Web.Stata.do`/`output.do`: horizonte macro
  **2026–2032** (7 años) en los tres a la vez — `CRECPIB`/`CRECDEF` del sitio,
  placeholders del template y globals `pib*`/`def*`/`inf*`. Antes el template
  traía 2025–2031 y las matrices de deuda 2025–2031 con el loop leyendo la
  columna 1 como 2026 (desfase de un año); ahora son las mismas matrices de
  `SIM.do`. `output.do`: `PIBY` con `scalar()` explícito — el nombre pelado
  resolvía a la variable `pibY[1]` (2013, 1.65 billones) del dataset de
  FiscalGap en memoria, no al escalar de 2027.
- **`LIF.ado` v8.1 — lo observado va en `r()`, no en escalares globales por
  grupo (mismo contrato que `PEF`).** Antes LIF escribía `<g>`, `<g>PIB`,
  `<g>Tot`, `<g>PC`, `<g>C` como escalares globales; con `by(divSIM)` esos
  nombres son exactamente los parámetros de escenario del usuario
  (`ISRASPIB`, `IVAPIB`, ...) y la corrida interna de LIF en `FiscalGap` §4.1
  (y el fallback de `TasasEfectivas`) los pisaba después de que `SIM.do` §4.1 /
  `ISR_Mod` / `IVA_Mod` los habían definido. Ahora hay dos espacios de nombres:
  **observado** = `r(<g>...)` de LIF; **escenario** = escalares `<g>PIB` que
  solo escribe el usuario (SIM.do, Web.Stata.do) o `TasasEfectivas` cuando no
  existen (default explícito desde `r()`). Siguen globales, sin colisión:
  `Ingresos_totales*`, `Ingresos_sin_deuda*`, elasticidades `E<g>` y "Returns
  Extras" (`Cuotas_IMSS`, IEPS por producto). Se agregan
  `r(Ingresos_totales*)`. Consumidores migrados a `r()`: `FiscalGap` (§4.1
  captura `r(<g>C)`/`r(<g>PIB)` en locals; ancla §4.2 = parámetro si existe,
  si no el observado — sigue autocontenido), `Households.do` §1.4,
  `Expenditure.do` §1.2, `PerfilesSim.do` §2, `visualizations/Sankey.do` §1.
  Libro: la prosa solo cita `\<g>PIBtasas` (TasasEfectivas, parámetro); las
  definiciones `\<g>{PIB,Tot,C}{gap,ing,perf}` que dejan de emitirse no se
  usan. Help `LIF.sthlp` actualizado (stored results). Los `legacy/` que
  leen `scalar(<g>)` tras LIF no se tocaron.
- **`SIM.do` §4.4/§4.6:** las reestimaciones de `ISR_Mod`/`IVA_Mod` asignaban
  `<g>PIB` como *string* (`"`=round(...)'"`), contra el invariante numérico
  v8.1.0 que `Web.Stata.do` ya cumplía; ahora `escalar pctpib ... = round(...)`.

### Institucional
- **Sitio (`04_1_simuladorfiscal.ciep.mx/`, fuera de git; viaja por
  `publicar-vps.sh`):** año base 2027 y horizonte 2032. Marco macro con 7
  filas 2026–2032 (sale la fila oculta 2025, entra 2032) en `index.php`,
  `index-en.php`, `calculaStata.php` (`$llaves`) y el POST de
  `stataCalcula(.js|-en.js)`; categorías de las gráficas de ingresos, gasto y
  SHRFSP 2013–2032 (20 puntos, mismos que emite FiscalGap); el veredicto de
  deuda compara el año base contra el último año de la serie con índices
  dinámicos (`ANIOBASE`, `ANIOEND`) en vez de `[9]`/`[17]` quemados; "DEUDA
  per cápita 2027/2032"; "Valores 2027"; textos y links al Paquete 2027
  (CGPE 2027, ILIF 2027, PPEF 2027 — LIF/PEF 2027 aún no existen en la SHCP).
- `manifest.json`: `version`/`release_tag`/`release_url_prefix` → v8.3.0.
  Probado en local: template web sustituido con los defaults del sitio corre
  end-to-end (34.7 s) y `output.txt` entrega 20 puntos por serie, `CRECPIB`/
  `CRECDEF` con 7 valores y `PIBY` = 39.4 billones (2027).

## [v8.2.3] — 2026-09-12

**El ciclo de edición diaria de `raw/` gana un modo de trabajo con tres fases:
actuar rápido → declarar → publicar.** Con `$update` cada corrida re-lee los
archivos que Ricardo edita a diario (LIFs, PEFs, CuotasISSSTE) y el candado
bloqueaba en cada edición. Se descartó, tras estresarla, la idea de saltar la
verificación cuando hay `update`: habría dejado ciego al candado en el único
momento en que alguien toca `raw/` a propósito (el incidente del 8-sep no se
habría detectado), habría dejado pasar raw corrupto con `update` en la Carpeta
y en el endpoint, y habría vuelto incoherente `LIF, update` frente a `$update`.
La solución separa intención de mecanismo: un global propio, `rawwip`, que
solo pone quien opera el manifest. Patch nuevo porque toca `ensure_asset`.

### Comandos
- **`ensure_asset.ado` v1.5 — modo WIP de raw.** Con `global rawwip "rawwip"`
  definido y repo local, un SHA distinto **no bloquea**: imprime una línea
  (`[RAW WIP] LIFs.xlsx: SHA difiere del manifest (real 84f5…, 48966 bytes) —
  se usa el archivo local. Decláralo antes del release`) y anota el asset en
  `raw/temp/assets-wip.txt` (nombre, ruta, SHA real, tamaño, SHA esperado,
  hora; última captura gana). Sin el global, la verificación es estricta con
  el mensaje-runbook de v1.4, que ahora menciona el modo. **En modo endpoint
  (sin repo) el global se ignora siempre.** Un archivo ausente se descarga y
  verifica en cualquier modo. Probado en batch contra SITE falso: con el
  global avisa y sigue (`rc=0`, archivo de pendientes escrito); sin él
  bloquea (`r(198)`).
- **`SIM.do` §0.4:** una línea comentada `//global rawwip "rawwip"` junto a
  `$update`, con la instrucción de quitarla para declarar y publicar. Nada
  más de `SIM.do` cambia en este release (el trabajo del día de Ricardo en el
  working tree no se tocó: solo esta línea entró al commit).

### Institucional
- **`publicar.sh` Gate 5 — raw declarado (~6 s).** Antes de cualquier acción
  (también en `--check`): (a) SIM.do no puede tener `global rawwip` activo —
  todo el equipo correría con el candado en modo aviso; (b) **todo asset del
  manifest presente en disco debe coincidir en SHA** — sin esto `publicar.sh`
  subiría al Release un archivo que el propio manifest rechaza y el
  post-verify lo cazaría después de subir ~1.3 GB; (c) lista
  `raw/temp/assets-wip.txt` si quedó de la Fase 1. **Primera corrida del gate
  cazó un asset real sin declarar:** `raw/PEFs/CuotasISSSTE.xlsx` (disco
  `11836aa9…`, 10,858 B; manifest `bffce255…`, 10,838 B) — la edición en
  curso de Ricardo. Queda como **pendiente de Fase 2 antes del tag v8.2.3**.
- **`runbook-actualizar-assets.md` §2c "Modo WIP de raw: las tres fases":**
  la tabla de fases, por qué no se ligó a `update`, y las reglas (solo repo
  local; nunca se commitea activo; el aviso no es opcional; `update` y
  `rawwip` son independientes).
- Se descartó el banner en `profile.do`: el global se define en `SIM.do`,
  después de que `profile.do` corre, así que ahí nunca sería visible. El
  aviso por asset de `ensure_asset` y el Gate 5 cumplen esa función.

### Hallazgo registrado (no corregido aquí; lo resuelve Ricardo)
- **El Release `v8.2.2` sirve 23 de 24 assets: falta `LIFs.xlsx`.** Un
  `gh release delete-asset` sin el `publicar.sh` posterior (o abortado)
  dejó el Release sin el archivo; una máquina virgen hoy no puede construir
  `master/LIF.dta` desde v8.2.2. Como el `LIFs.xlsx` en disco SÍ coincide con
  el manifest, el fix inmediato es `gh release upload v8.2.2 raw/LIFs/LIFs.xlsx`;
  el fix estructural es el release v8.2.3 completo tras declarar CuotasISSSTE.

## [v8.2.2] — 2026-09-09

**Día 2 del Paquete 2027: el flujo de actualización de assets se vuelve
AUTOSERVICIO.** La cadencia de ediciones diarias del `LIFs.xlsx` llegó para
quedarse durante septiembre (rev1 el 8, rev2 y rev3 el 9), y cada una dispara
el candado con razón. La respuesta no es aflojar el candado sino que su
mensaje traiga la secuencia completa para resolver sin ayuda. Como eso toca
un `.ado` publicado (`ensure_asset`), es patch nuevo — no reemplazo de asset
sobre v8.2.1. **Deja atrás la deriva de v8.2.1:** el Release `v8.2.1` sirve
el `LIFs.xlsx` rev2 (`a29070bf…`, reemplazado post-tag) mientras el manifest
del commit etiquetado declara rev1 (`81bef034…`) — válido para un parcial,
pero v8.2.2 nace alineado: tag, manifest y Release con la rev3. El VPS sigue
sin redeploy hasta v8.3.0.

### Datos
- **`raw/LIFs/LIFs.xlsx` rev3 (edición de Ricardo, 2026-09-09):** `sha256`
  `a29070bf…` → **`84f5605c…`**, `size_bytes` 48,877 → **48,966**,
  `data_updated` → 2026-09-09. Gate de contenido: la edición es del propio
  Ricardo. **Corrida `LIF, anio(2027) update` en batch:** el candado pasa,
  `master/LIF.dta` regenerado; **total ILIF 2027 rev3 = 9,156,528.9 mdp =
  23.228% del PIB** (PIB 2027 de `SIM.do` = 39,419,415 mdp). Frente a la
  rev1 del día anterior (9,038,576.6 mdp): OTROSK +1,800.0 mdp y PEMEX
  +116,152.3 mdp; los 13 conceptos restantes idénticos. Nota de registro: el
  brief del ciclo citaba una rev intermedia `d06f4614…` que ya no estaba en
  disco; se declaró la que sí (decisión de Ricardo).

### Comandos
- **`ensure_asset.ado` v1.4 — el mensaje-runbook.** El caso (a) no cambia. El
  caso (b) pasa de "ver el runbook" a la **secuencia completa numerada, con
  comandos pegables y los valores YA CALCULADOS** del archivo real y del
  manifest (SHA nuevo, tamaño, `release_tag`, fecha de hoy, número de
  assets): (1) validar CONTENIDO — si no eres Ricardo, avisar antes; (2) cd
  al clon de DESARROLLO, no la Carpeta, con `git rev-parse --show-toplevel`
  para confirmarlo; (3) shasum/stat con el resultado impreso; (4) las líneas
  exactas del manifest; (5) re-correr; (6) `git add/commit/push`; (7)
  `gh release delete-asset <tag> <archivo> -y || true` +
  `bash 05_scripts/publicar.sh <tag>`; (8) avisar a Ricardo para el pull en
  la Carpeta. Marcado "solo equipo CIEP con el repo"; **en modo endpoint
  (instalación sin repo) el caso (b) se reduce a una línea** porque ahí no
  hay manifest que editar. Se eligió la variante completa sobre la mínima
  (pasos 1–5 + referencia): un `errprintln` no tiene límite práctico, el
  mensaje es ~30 líneas, y la mitad del valor está en imprimir los valores
  calculados — con la variante mínima el operador tendría que abrir el
  runbook precisamente para los pasos que más se equivocan (borrar el asset
  del Release antes de re-publicar). Verificado contra un SITE falso con el
  manifest de rev2: reproduce el bloqueo de hoy con los valores de rev3 y
  sale `r(198)`. Refactor: el mensaje vive en `_sha_mismatch_msg()`.

### Institucional
- **Guard de identidad de clon en `publicar.sh`.** El 2026-09-08 se lanzó
  `publicar.sh` sin querer desde la Carpeta del Simulador para
  investigadores — también es un clon git, así que `git rev-parse` no la
  distingue — y el pre-chequeo de assets falló de forma confusa. Ahora, antes
  de cualquier gate (incluido `--check`), el script exige el marker
  gitignored **`.clon-desarrollo`** en la raíz; si falta, aborta con "Estás
  en `<ruta>`…" y, si la ruta termina en `Dropbox-CIEP/SimuladorCIEP`, lo
  nombra: "Esta ruta es la Carpeta: aquí NO se publica ni se opera git
  (§6.7)". El marker no viaja por git, así que la Carpeta nunca lo tiene; se
  crea una vez con `touch .clon-desarrollo` (creado en el clon de desarrollo
  de Ricardo en este ciclo). `.gitignore` y `verify_gitignore.sh` lo cubren
  (**93/93, 0 FAILS**). Probado en un clon temporal en ruta genérica y en
  una ruta `…/Dropbox-CIEP/SimuladorCIEP`.
- **`runbook-actualizar-assets.md` §2b "Comandos exactos":** la misma
  secuencia parametrizada (`<archivo>`, `<nombre>`, `<tag>`), pegable,
  incluida la prueba del candado en batch sin abrir Stata; la trampa de los
  dos clones documentada con el guard; y la regla del paso 7: `publicar.sh`
  es idempotente por nombre, por eso el `delete-asset` va antes;
  **reemplazar un asset en un Release existente es válido para un parcial**
  (deriva conocida y aceptada durante el Paquete) y **la reconciliación
  formal llega con el minor v8.3.0**; cuando el cambio toca código
  distribuido, se corta patch nuevo. §3 gana "nunca commitear ni publicar
  desde la Carpeta".

## [v8.2.1] — 2026-09-08

**Release PARCIAL del Paquete 2027: el `LIFs.xlsx` del data sidecar carga la
ILIF 2027 y el manifest la declara; el resto de las bases 2027 (PPEF, CGPE)
llega en v8.3.0, el release formal.** Es un patch porque lo que cambia de lo
distribuido es un asset de datos y el mensaje de un `.ado` de
infraestructura; el motor, el sitio y el endpoint no cambian de
comportamiento. **El VPS NO se redeploya en este parcial** — el web sigue
sirviendo el PE2026 correctamente hasta v8.3.0.

**GATE DE CONTENIDO PENDIENTE (registrado explícitamente):** el SHA-256 del
`LIFs.xlsx` 2027 quedó declarado en el manifest ANTES de que Ricardo validara
con el ojo que la ILIF 2027 está bien vaciada. El hash certifica identidad
del archivo, no corrección de los datos. El tag `v8.2.1` y `publicar.sh`
(que re-sube los 24 assets al Release con el LIFs nuevo) quedan bloqueados
hasta que Ricardo confirme ese gate; si el contenido falla, el fix es un
LIFs corregido + SHA nuevo, no revertir este release.

### Datos
- **`raw/LIFs/LIFs.xlsx` → ILIF 2027 (actualización parcial del Paquete
  2027).** Vaciado por el equipo CIEP el 2026-09-08 en su máquina.
  `manifest.json`: `sha256` `a145d8f5…` → `81bef034…`, `size_bytes`
  47,910 → 48,875, `data_updated` 2026-07-19 → 2026-09-08. Corrección en
  este ciclo: el commit `3f33f8a` había declarado el SHA nuevo con el tamaño
  viejo (47,910); `ensure_asset` no valida tamaño, así que pasaba, pero el
  manifest quedaba a medias.
- **El candado contuvo el incidente — primer evento multi-usuario del repo.**
  `ensure_asset` detuvo la corrida en la máquina de los compañeros ("SHA real
  `81bef034…` vs manifest `a145d8f5…`"): una modificación legítima pero no
  declarada. Es exactamente lo que el candado existe para detener. Lo que
  falló fue el mensaje (siguiente sección) y la ausencia de un procedimiento
  escrito para el equipo (runbook nuevo).

### Comandos
- **`ensure_asset.ado` v1.3 — el error de SHA distingue los dos casos.** El
  mensaje anterior ("Archivo corrupto o desactualizado. Bórralo y vuelve a
  correr") es correcto para corrupción y DESTRUCTIVO para actualización
  intencional: borrar re-descarga el archivo VIEJO del Release y pisa los
  datos nuevos. El mensaje nuevo enumera (a) si NO modificaste el archivo:
  bórralo y re-corre; (b) si lo actualizaste a propósito: el manifest debe
  declararlo (shasum, `size_bytes`, `data_updated`), ver el runbook, y **NO
  borres el archivo**. Añade la ruta del archivo al mensaje. Verificado
  contra un SITE falso con manifest desalineado: reproduce el incidente
  palabra por palabra y sale con `r(198)`. Sin cambios de comportamiento:
  misma verificación, misma descarga, mismo código de error.

### Institucional
- **`02_governance/runbook-actualizar-assets.md` (nuevo, una página, para el
  equipo):** qué es el manifest y por qué existe el candado; el flujo en
  diez pasos (avisar → Ricardo valida CONTENIDO → shasum + size → manifest
  → `data_updated` → probar → commit + push → release → pull en la Carpeta
  de investigadores); qué NUNCA hacer (borrar-y-recorrer tras actualizar;
  manifest a medias; renombrar el asset); y la regla de la carpeta
  compartida: **git ahí lo opera UNA sola persona** (§6.7 de arquitectura).
- **Regla nueva de operación: un ciclo, un operador por juego de archivos.**
  Durante la auditoría de este ciclo (delegado), `manifest.json` y `SIM.do`
  cambiaron en el working tree a las 20:57–20:58 sin aviso: era Ricardo
  ejecutando el desbloqueo a mano en paralelo (commit `3f33f8a`). Near-miss
  sin daño — pero dos manos sobre los mismos archivos sin declararlo es el
  mismo incidente que el candado acaba de contener, sin candado. Si Ricardo
  va a editar a mano archivos de un ciclo delegado, se declara antes.
  Registrada en el runbook §4.
- **Rename `04_simuladorfiscal.ciep.mx/` → `04_1_simuladorfiscal.ciep.mx/`
  (commit `360ebae` del 2026-09-08), documentado aquí porque no lo estaba
  en ningún lado.** Renumeración, no colisión: la semilla
  `04_1_paqueteeconomico.ciep.mx/` se RETIRÓ del repo hacia
  `../CIEP_Micrositios/Paquete Económico/` (hermana del repo, con
  `DEPLOY-semilla-04_1-legado.md` como acta; el render de los nodos la siguió
  ahí — `scalarjson.ado:70`, `nodo-deuda.do`, `portada.do`, `verify_nodo.sh`
  ya apuntan a ese destino), lo que liberó el slot `04_1` para el sitio del
  Simulador. Mapa `04_*` vigente: `04_1_simuladorfiscal.ciep.mx/`,
  `04_2_documentos_latex/`, `04_4_libro.ciep.mx/`, `04_5_ciep.mx/` (04_3
  cerrado el 2026-08-02). **Fallout censado y cerrado en este release:**
  `05_scripts/publicar-vps-credentials.template.sh` (`LOCAL_SITE_ROOT` a la
  ruta nueva, con nota para credenciales anteriores);
  `05_scripts/verify_gitignore.sh` (93/94 con 1 FAIL → **92/92, 0 FAILS**:
  la ruta nueva en las 2 aserciones del sitio, retiro de las 5 aserciones
  fantasma sobre `04_1_paqueteeconomico…`, y 3 aserciones nuevas —
  `config.php` del sitio ignorado, plantilla VPS versionada, `health.php`
  versionado); `.gitignore` (reglas muertas de `04_1_paqueteeconomico…`
  retiradas con nota; el clon del sitio comentado en su sección); docs vivas
  `arquitectura-y-bitacoras.md` §2.8 y D.1, `verificacion-estado-repo.md`,
  `reporte-inventario-paquete2027.md`, `manual-investigador-ciep.md`
  (tabla "no borres" con el mapa 04_* completo). Las bitácoras y
  `reconocimiento-vps.md` (2026-07-09) conservan la ruta vieja como
  histórico. **Pendiente de Ricardo:** la línea 23 de su
  `publicar-vps-credentials.sh` (gitignored) sigue en la ruta vieja — el
  Gate 5 de `publicar-vps.sh` aborta con `die` si no existe, así que un
  deploy no puede subir vacío, pero tampoco puede correr hasta editarla.

### Correcciones
- **`SIM.do`: el estado Pre-CGPE 2027 y el freno declarado.** El commit
  `4b047ae` subió `aniovp` 2026→2027, actualizó los inputs macro
  (`pib2027` 2.1→2.4, `def2026` 4.8→3.8, `def2027` 4.2→4.0, `inf2026`
  3.54→3.8, `inf2027` 3.0→3.2; filas 2025 retiradas), descomentó §2.4
  `PIBDeflactor` y dejó un `exit` sin comentario tras él; `3f33f8a` subió
  `anioPE` 2026→2027 y retiró el `exit`. **Corrida completa de
  verificación (2026-09-08, batch, `$id` scratch, `$export` a scratch, SIN
  `update`, `master/` intacto):** §2.4 PIBDeflactor 2027, §2.5 SCN 2027 y
  §4.1–4.6 (LIF 2027 con la ILIF nueva — 9,038,576.6 mdp, 22.641% del PIB —
  ISR, IMSS/ISSSTE, IVA, IEPS) pasan; **§4.7 `TasasEfectivas, anio(2027)
  enigh` truena con `r(601)`**: no existe `master/perfiles2027.dta` (§3
  Hogares está comentado, así que nadie lo construye) y el fallback de
  `TasasEfectivas.ado:308` corre `"<site>/PerfilesSim.do"` — ruta muerta
  desde la reorganización del 2026-07-04 (el archivo vive en
  `01_modulos/PerfilesSim.do`). **Fallback aprobado aplicado:** el `exit`
  vuelve a su posición tras `PIBDeflactor`, ahora DECLARADO ("WIP Pre-CGPE
  2027: la cadena termina aquí A PROPÓSITO hasta v8.3.0") con el diagnóstico
  en el comentario. Verificado: SIM.do corre limpio hasta el freno. El mix
  `aniovp = anioPE = 2027` con bases 2026 NO es estado válido de corrida
  completa; lo es de la cadena §0–§2.4.

### Candidatos registrados (no corregidos en este ciclo)
- **Dos rutas muertas a `PerfilesSim.do` en el motor**, destapadas por el
  mix: `TasasEfectivas.ado:308` (`<site>/PerfilesSim.do`) y `GastoPC.ado:74`
  (`<site>/01_modules/profiles/PerfilesSim.do`, anterior incluso a la
  reorganización). Ambas son fallbacks que solo corren cuando falta
  `master/perfiles<anio>.dta`, por eso sobrevivieron desde julio. Van en el
  ciclo v8.3.0 junto con la construcción de `perfiles2027.dta`.
- **La opción de mover el freno a antes de §4.7** (conservando SCN 2027 y
  LIF 2027 verificados) queda para decisión de Ricardo; este release respeta
  el fallback aprobado.

### Trabajo acumulado en `master` desde v8.2.0 (nodos y micrositio)

Lo que sigue estaba registrado bajo `[Unreleased]` y queda incluido en el tag
`v8.2.1` porque el tag es un punto de `master`. **Nada de esto cambia el
paquete distribuido** (`05_scripts/manifest-endpoint.toml` no incluye
`scalarjson.ado`, igual que nunca incluyó `scalarlatex.ado`): el endpoint
público y el VPS corren el mismo motor que en v8.2.0. Los nodos se publican
en su propio ciclo.

### Institucional
- **Primer corte vertical de un nodo: un número sale de Stata y llega a una
  página sin que nadie lo teclee.** Nodo de deuda pública, año de referencia
  2026. Tres piezas versionadas — el exportador (`scalarjson.ado`), el driver
  (`01_modulos/nodos/nodo-deuda.do`) y la página
  (`01_modulos/nodos/nodo-deuda.html`) — y un destino de render generado,
  `04_3_nodos/`, con el contrato (`statajson_deuda-publica.json`) y la copia
  servible de la página.
- **`04_3_nodos/` se ignora (decisión de Ricardo, 2026-08-01).** Es un destino
  de render desechable, reconstruible con una corrida: el mismo estatus que
  los `statalatex_*.tex` de `06_libro/images`, que tampoco se versionan. Se
  versiona lo que PRODUCE el artefacto, no el artefacto. **Consecuencia
  registrada:** el JSON no tiene historial en git, así que su diff entre
  cortes no es auditable desde el repo — para comparar en septiembre hay que
  guardar el corte anterior a mano antes de re-exportar.
- **`05_scripts/verify_nodo.sh`:** seis reglas con exit ≠ 0. (1) la página no
  contiene literales numéricos fuera de `<style>` — el verificador anti-fósil,
  la clase que este repo acaba de extinguir en v1.42/v1.44 y v8.2.0; (2)
  procedencia completa en el JSON; (3) exportación determinista, comprobada
  corriendo Stata dos veces (no se salta en silencio: sin Stata y sin
  `--sin-stata` sale con exit 2); (4) sin huecos de año no declarados; (5)
  toda serie declara unidad y formato; (6) la raíz no contiene `.md`.
  Audita la FUENTE de la página (`01_modulos/nodos/`), no la copia de render:
  auditar copias es auditar el pasado. Si el contrato no existe todavía (clone
  limpio), sale con exit 2 explicando cómo producirlo.
- **Regla nueva: la raíz del repo no contiene archivos `.md`.** La
  documentación vive en `02_governance/` o `03_help/`. Excepción única y
  confirmada: `README.md` (portada convencional de GitHub; ya tratada como
  institucional por `verify_gitignore.sh:180`). Movidos en este ciclo:
  `plan-integracion-paquete2027.md`, `reporte-inventario-paquete2027.md` y
  `verificacion-estado-repo.md` → `02_governance/` (cero referencias en el
  repo, el movimiento no rompe ninguna ruta).
- **Mapa 04_\* (2026-08-02): cada sitio web tiene su semilla local con
  anatomía estándar** — `public_html/` (código desplegable) + `db/` (dumps
  fechados) + `local/` (utilería) + `DEPLOY.md`. Estado: 04_1
  paqueteeconomico corre en `localhost:8892` (BD `paqueteeconomico_local`),
  04_4 libro corre en `localhost:8888` (BD `libro_local`), 04_5 ciep.mx tiene
  BD importada y código pendiente de reorganizar a `public_html/`; 04_2 es el
  archivo histórico LaTeX. Todas gitignored; ningún `wp-config.php`,
  `wp-salt.php` ni dump está trackeado (verificado con `git ls-files`).
  Residuo eliminado: `wp-admin/`/`wp-content/` sueltas en la raíz de 04_1
  (placeholders de 0 bytes, sobras de la reorganización).
- **Regla de dumps fechados (2026-08-02, aplica a toda semilla):** toda BD
  activada en local deja su dump fechado en el `db/` de su semilla
  (`<base>-AAAAMMDD.sql[.gz]`). Cumplen 04_1 (`emepykgvhz-20260802.sql`) y
  04_4 (`libro_local-20260802.sql.gz`, generado en este ciclo); 04_5 cuando
  se active. Los dumps contienen datos reales (hashes de usuarios, pedidos
  WooCommerce): NUNCA van a git ni salen de la máquina.
- **Cierre de `04_3_nodos/` (decisión de Ricardo, 2026-08-02):** el destino
  de render de los nodos se muda BAJO EL DOCROOT del WordPress local del
  Paquete — `04_1_…/public_html/nodos/` (patrón 6yt5ppa3hb: estáticos
  servidos junto al sitio, jamás dentro de Elementor). El nodo de deuda es
  visible en el MISMO localhost del sitio:
  `http://localhost:8892/nodos/nodo-deuda.html`. Piezas movidas: default de
  `scalarjson`, driver (mkdir antes de exportar + copia servible),
  `verify_nodo.sh` (todas las reglas pasan contra el destino nuevo, exit 0) y
  `nodo-deuda-vista-previa.md`; `.gitignore` gana el cinturón explícito con
  sus aserciones. `04_3_nodos/` se eliminó tras mover el corte vigente
  (byte-idéntico). El estatus no cambia: render desechable, sin historial en
  git — el corolario de guardar el corte anterior a mano antes de re-exportar
  sigue vigente.
- **El "header doble" del sitio local NO es un defecto del local (auditado
  2026-08-02):** el header rosa del tema (hello-elementor default) aparece
  también en producción. Evidencia: el HTML de producción emite
  `<header id="site-header">` con y sin el caché de WP Rocket, las 17 hojas
  CSS son byte-idénticas entre producción y local y ninguna lo oculta, y los
  screenshots headless (Chrome 151) de producción y de `:8892` salen
  byte-idénticos. La paridad local–producción está demostrada; quitar el
  header rosa es una decisión de DISEÑO que aplicaría a ambos lados, y las
  opciones quedaron documentadas en el `DEPLOY.md` de la semilla.
  **Segunda verificación y parche local (mismo día):** re-verificado en vivo
  con cache-buster — producción HOY muestra el header rosa; NO existe
  mecanismo de producción que emular. Por decisión de Ricardo el local lo
  oculta con CSS del Customizer (`.site-header { display: none; }`, aplicado
  vía `wp_update_custom_css_post`, vive en la BD local); el `DEPLOY.md` lo
  registra como PARCHE LOCAL con la instrucción explícita de NO portarlo en
  deploys de código (es estado de BD y lleva su propio gate).
- **La página del nodo de deuda adopta el lenguaje ultra-austero (variante A
  de la ronda de estilo, veredicto de Ricardo 2026-08-02):** título, la
  tabla y el sello; la costura CGPE y la procedencia viven en un `<details>`
  plegado de una línea; cero texto explicativo suelto. La regla 1 del
  verificador cazó la fecha de la ronda en un comentario del `<script>`
  durante la promoción — el anti-fósil funcionando contra su propio autor.
- **La portada del Paquete: la ecuación fundamental con cifras del motor
  (`/nodos/` en el localhost del sitio).** Referencia CONCEPTUAL: la sección
  "La ecuación fundamental" de libro.ciep.mx (tres términos con jerarquía
  visual y operadores); re-implementada al estilo nodo, no copiada: aquí los
  términos llevan el número del motor. `01_modulos/nodos/portada.do` corre
  LIF y PEF y deriva EXACTAMENTE tres cosas — ingresos = suma de las 7
  familias del display B de LIF (divResumido, sin la familia Deuda); gasto =
  suma de las 10 divisiones del display B de PEF (Resumido, Cuotas ISSSTE
  negativa), verificada contra `r(Gasto_netoPIB)`; financiamiento = cierre
  por construcción (gasto − ingresos). La familia Deuda de la LIF viaja como
  REFERENCIA con su brecha declarada contra el cierre (LIF y PEF no
  coinciden al centavo; la brecha se publica en vez de esconderse). Capa
  CGPE declarada con el patrón del nodo (RFSP/ingresos/gasto de las matrices
  de `SIM.do:361-405`; sin los globals de política, `disponible:false`).
  Esquema propio `ciep.nodo.portada/v1`; página en el lenguaje A con hover
  (desktop) / tap (móvil) para desagregar cada término, el término
  Financiamiento enlaza al nodo de deuda, y la línea personal (año de
  nacimiento) lee el per cápita real del CONTRATO DEL NODO — la portada no
  calcula ni inventa. La copia servible se llama `index.html`: `/nodos/` ES
  la portada. `router.php` local sirve `index.html` de directorios estáticos
  antes de caer a WordPress (equivalente del `DirectoryIndex` de producción).
- **Precisión declarada de la portada: `%20.12g` para % del PIB, `%25.17g`
  para montos.** Los agregados de LIF/PEF no son bit-estables entre corridas
  (sorts con empates no estables mueven el último ulp de la suma — la regla
  3 del verificador lo cazó en la primera corrida doble); 12 dígitos
  significativos publican el dato sin el ruido. Los montos son enteros
  exactos en double y conservan round-trip completo. El nodo de deuda sigue
  en `%25.17g` porque lee un `.dta` congelado, que sí es bit-estable.
- **`verify_nodo.sh` extendido a la portada:** `bash 05_scripts/verify_nodo.sh
  portada`. Reglas 1-3 y 6 idénticas (la 3 corre el driver dos veces: LIF y
  PEF incluidos); las reglas 4/5 se sustituyen por sus equivalentes
  estructurales — cierre de la ecuación (montos exactos; % PIB a la
  precisión emitida), sumas de desagregaciones contra los
  totales, brecha LIF declarada, y unidades/formatos/fuentes por término más
  procedencia de capas. Ambos nodos: todas las reglas pasan, exit 0.
- **La portada se vuelve MULTI-AÑO: selector 2013–2026 (v2.0 del driver,
  mismo esquema `ciep.nodo.portada/v1`).** Censo previo (2026-08-02): los 14
  años corren completos y las etiquetas son ESTABLES — las mismas 7 familias
  de ingreso y 10 divisiones de gasto en todos los años, así que el
  blueprint del driver es único, sin ramas por año. El bloque `ecuacion` se
  extiende a `ecuaciones[]` por año SIN subir a v2: contrato pre-publicación
  sin consumidor externo (decisión documentada en el header del driver: "v2
  solo cuando exista consumidor externo publicado"). **`tipo_dato` por año Y
  POR LADO, leído de los datos, no de una tabla tecleada:** gasto = qué
  columna trae datos en `master/PEF.dta` según la regla del motor
  (`PEF.ado:1295-97`: ejercido → aprobado → proyecto — 2013-2025 ejercido/CP,
  2026 aprobado/PEF); ingresos = mes máximo observado en `master/LIF.dta`
  (12 → observado; menor → ley/ILIF — 2026). La página lo muestra como marca
  discreta bajo el selector ("gasto: aprobado · ingresos: ley"), sin
  párrafos. La capa CGPE viaja SOLO en el año de referencia. Deep-link por
  año: `/nodos/#2016`. Tiempo de corrida declarado en el header del driver:
  ~2 min el export (PEF ~8.6 s × 14 años), ~5 min la regla 3.
- **Dos lecciones de precisión más, cazadas por las reglas 3 y 4 en la
  primera corrida multi-año:** (a) los MONTOS de Cuenta Pública traen
  centavos y tampoco son bit-estables entre corridas — los montos ahora
  viajan en MILLONES DE MXN ENTEROS (`round(x/1e6)`), seis órdenes por
  encima del ruido, y el financiamiento se deriva DESPUÉS del redondeo, así
  que el cierre en montos es exacto en enteros; los % del PIB bajan a
  `%16.9g` (9 dígitos: ~5 órdenes de margen sobre el ruido, y el display usa
  3 decimales). (b) `local x = exp` guarda el resultado como TEXTO con menos
  dígitos — el cierre por construcción perdía los centavos al pasar por
  locals; toda la captura del driver vive ahora en scalars (`__prt*`,
  limpiados al final). La regla 4 verifica el cierre POR AÑO en los 14 años.
- **Integración (a) ejecutada en el WP local (2026-08-02):** item de menú
  "La ecuación" → `/nodos/` en `menu-paquete` (posición 1, vía
  `wp menu item add-custom`). El hero quedó DESCARTADO por escrito (regla:
  nada de los nodos vive dentro de Elementor). Es estado de BD: documentado
  en el `DEPLOY.md` de la semilla como PENDIENTE DE PORTAR con el comando
  exacto (mismo `wp` por SSH + purga de WP Rocket, prerrequisito: `/nodos/`
  desplegada).
- **Tercer nodo: los indicadores de los hashtags de ciep.mx (2026-08-03,
  esquema `ciep.nodo.indicadores/v1`).** Los 26 hashtags del home de ciep.mx
  son anclas a `/category/<slug>/` — el slug es la llave del censo: **13
  disponibles y 11 declarados no disponibles con su razón** (FiscalGap
  registra tasas y no niveles; y 7 hashtags sin correspondencia hoy). Un
  **decorador estático** (`indicadores-decorador.js`, auditado por la regla 1
  como cualquier página de nodo) lee el contrato y añade la cifra al ancla
  cuyo slug tiene dato — los demás quedan intactos; se encola con un
  **mu-plugin de una línea** (`indicadores-muplugin.php`, fuente versionada;
  instalado como `wp-content/mu-plugins/ciep-indicadores.php` en la semilla:
  viaja con el rsync, no vive en la BD). WordPress jamás guarda un número; la
  actualización mensual es re-exportar el JSON y re-publicar un archivo.
- **Indicadores v2 (mismo día, decisión de Ricardo tras ver v1): ÚNICAMENTE
  datos abiertos como lo oficial, con el último mes como corte de cada
  concepto.** v1 usaba LIF/PEF anual (ley/aprobado); v2 mapea cada slug a su
  serie de SHCP Estadísticas Oportunas vía `DatosAbiertos.ado` con claves
  verificadas contra `master/DatosAbiertos.dta` (XAB ingresos, XAC gasto
  neto pagado, XAB11 tributarios, XAB12 no tributarios, XDA12 contribuciones
  SS, XAC21 costo financiero, XOA0135 pensiones, XOA0417/XOA0419 funciones
  Salud/Educación — los frames viejos XOA0316/XOA0315 ya no traen 2026 y el
  guard truena si una clave se queda sin dato; `energia` = balance XAB21 −
  XOA0425; `endeudamiento` = XAC − XAB, el cierre de siempre). **Convención
  de % PIB del MOTOR, no inventada:** flujos con la opción `proyeccion` de
  `DatosAbiertos.ado` (acumulado observado anualizado con `acum_prom` ÷ PIB
  anual), `tipo_dato = proyectado_observado`; el saldo de deuda no se
  proyecta (`observado_mensual`). Todos los conceptos cortan en **mayo de
  2026**; guard de cortes mixtos incluido. **Ronda visual aplicada:** junto
  al hashtag SOLO el número y el `%` (columna angosta), todo en blanco con
  sombra sutil; la unidad y el corte NO se repiten — viven una sola vez en
  una nota fija en la esquina superior derecha, leída del contrato; el
  detalle por concepto (clave SHCP, fuente, tipo de dato) va al tooltip.
  La regla 1 volvió a cazar dos fósiles del propio autor durante la ronda
  (una fecha en comentario y un `12px/1.4`). `verify_nodo.sh indicadores`:
  reglas 4/5 propias (cierre del endeudamiento re-derivado del contrato,
  `ingresos == ingresospublicos`, slugs únicos, disponibles con
  pib/corte/tipo_dato/fuente y ausentes con razón); los TRES nodos en exit 0.
- **El decorador gana el conteo de investigaciones por hashtag (2026-08-04):**
  dato VIVO de la API REST de WordPress (`/wp-json/wp/v2/categories`, campo
  `count`), pintado junto a la cifra del motor (`#Salud 3.1% (122)`); los
  hashtags sin cifra llevan solo su conteo. Nada tecleado: si la API falla,
  no hay conteos y la página queda tal cual. El decorador ahora exige que el
  ancla SEA un hashtag (texto que inicia con `#`) para no decorar menú/footer.
  Los cambios de LAYOUT del home de ciep.mx (hero 2/3 + destacadas 1/3
  vertical cuadrada a la altura del hero; Venn a columna completa con offsets
  escalados ×1.39; las 3 secciones de /investigaciones insertadas bajo el
  Venn con filtros colapsados a 5 items + "Más…", 9 por página, ancla
  `#investigaciones`, y el botón "Investigaciones" fuera del menú del header)
  viven en la BD LOCAL (`_elementor_data` + menús), documentados en el
  DEPLOY.md de la semilla con su hallazgo crítico: el auto-update del primer
  arranque subió Elementor a 3.35.5 y desactivó elementor-pro (por eso el
  widget de posts salía vacío); producción sirve Elementor 4.2.1 — NO rsync
  de plugins sin reconciliar versiones.

### Comandos
- **`scalarjson.ado` v1.0.0 — exportador de nodos a JSON, hermano de SOLO
  LECTURA de `scalarlatex`.** Espeja tres pasos y solo tres: enumeración de
  escalares vivos, mapa nombre→tipo desde `$scalarlatex_reg` con last-wins, y
  el catálogo de tipos. NO espeja el dígitos→letras (restricción de nombres de
  macro de LaTeX) ni el alias. NO toca `scalarlatex`, ni el registro, ni
  `02_governance/scalarlatex-baseline.txt` (no lo lee siquiera: ese baseline
  gobierna la cobertura del libro, no la de un nodo). **NO CALCULA:** todo
  valor que escribe ya existe en el registro o en el dataset de serie que
  recibe; lo que no existe es un faltante declarado. Donde `scalarlatex`
  escribe strings ya formateados, `scalarjson` escribe NÚMEROS de precisión
  completa más `formato_sugerido`/`divisor_sugerido` — el formato es una
  sugerencia de presentación, no el dato.
- **`SHRFSP.ado`:** la invocación del nodo entra al bloque `$textbook`
  existente, junto a `scalarlatex`, con la misma clausura (lección v8.0.11).
  Tres guards en serie: `$textbook` (solo-repo) + `capture which scalarjson` +
  `capture confirm file` del driver. Degradación silenciosa si falta
  cualquiera. `scalarjson.ado` NO se publica al endpoint: en el VPS el comando
  no existe y el bloque solo imprime la nota.
- **`scalarjson.ado` v1.1 — el contrato lleva el espejo del display.** Opción
  `tabla()` nueva y dos bloques nuevos en el JSON: `presentacion` (lo que la
  página necesita para renderizar y no es una cifra: etiqueta de moneda,
  escala, encabezados y formatos de columna, denominadores por bloque) y
  `tabla` (la ESTRUCTURA del display que la página espeja: qué filas, en qué
  orden, con qué etiqueta, prefijo, familia y énfasis). Viven en el contrato
  y no en la página para que la tabla del sitio no pueda divergir en silencio
  de la que imprime el módulo en Stata. En el driver, los 72 escalares salen
  de la MISMA tabla (19 filas, 5 bloques): contrato y display no pueden
  desincronizarse porque no hay dos listas que mantener. La página
  (`nodo-deuda.html`) se reescribió como espejo del display.
- **`scalarjson` escribe números con `%25.17g` (antes `%22.15g`).** 17
  dígitos significativos garantizan round-trip exacto de un double IEEE 754;
  con 15, el JSON perdía el último bit y la página redondeaba a un peso de
  distancia del display de Stata (`SHRFSPMonto` …533 vs …534).

### Correcciones
- **`scalarjson` sanea backticks al escribir (clase: inyección de macro desde
  datos).** Las líneas de datos de `input` no expanden macros, así que un
  `` `anioref' `` quedó guardado literal en un `.dta` de metadatos — y al
  escribirse desde `scalarjson` se re-expandió contra las **locales de ese
  programa**, saliendo como `2026` en el JSON. Texto de un dataset
  ejecutándose como código. `_sjkv`/`_sjesc` eliminan `char(96)` antes de
  escribir; los drivers construyen todo lo dinámico con `replace`, que sí
  expande. (De paso, dos gotchas de Stata registrados: un backtick sin cerrar
  dentro de un comentario se traga el resto del archivo sin error, y `\` no
  puede viajar por macro a un literal entrecomillado — escapa la expansión y
  truena con `r(198)`; el escape JSON usa `char(92)`/`char(34)` dentro de la
  expresión.)

### Correcciones — escenario de política fiscal
- **`SIM.do:389`: el mapeo de columnas le daba a cada año la columna del año
  ANTERIOR, y nunca leía la columna 2031.** Las matrices de política fiscal
  (`SIM.do:361-405`) tienen 7 columnas rotuladas 2025-2031, pero el
  `forvalues k = 2026(1)2031` calculaba `j = k - 2026 + 1`: 2026 leía la
  columna 2025, 2027 la 2026, y así hasta 2031, que leía la 2030 — la columna
  2031 quedaba muerta. Corregido a `j = k - 2025 + 1`. Una línea.
- **El rótulo estaba bien y el motor mal; el fósil tecleado fue el testigo.**
  `04_2_documentos_latex/PE2026/…/3_Deuda/deuda.tex:39` —cifras tecleadas a
  mano, sin getters— dice *"4.1% del PIB"* tanto para el costo financiero
  como para el endeudamiento neto de 2026. El motor producía 3.8 y 4.30. Tras
  el fix produce **4.100 y 4.100**: coinciden con el documento publicado. El
  número que un humano escribió a mano validó al motor, no al revés.
- **Test dorado (2 corridas del flujo textbook, `$export` a scratch, mismo
  `master/`):** de 110 getters de `statalatex_shrfsp.tex`, **51 cambian y 59
  no**; cero getters nuevos, cero perdidos. Los 51 caen todos en la clase
  predicha por el triage: `CostoFinanciero*` (3.800→4.100), `RFSP*`
  (4.300→4.100), `SHRFSPInterno*` (40.500→41.500), `SHRFSPExterno*`
  (12.100→11.000), `rfspPIDIREGAS*`/`rfspIPAB*` (0.150→0.100),
  `rfspAdecuaciones*` (0.400→0.300), `SHRFSPLIF` (240.2→233.8) y las familias
  `Deuda*` por el tipo de cambio (19.6→18.9). Quedan intactos —como se
  predijo— `SHRFSP{PIB,Monto,PC,PorTot}` (52.6 en ambas columnas),
  `SHRFSPlast*`, `rfspBalance{PIB,Monto}` y los `rfsp*` en cero.
- **Detectado por el nodo de deuda:** el patrón anti-fósil cazando su primer
  bug de motor. El nodo obliga a declarar de dónde sale cada número, y al
  declarar la procedencia de la capa de escenario (`SIM.do:362 -> global
  shrfsp<año>`) el mapeo quedó a la vista.
- **Archivos del libro que Ricardo debe regenerar y repasar en prosa:**
  `06_libro/images/statalatex_{shrfsp,perfiles,fiscalgap}.tex` (el registro es
  global-acumulado: los tres cargan escalares de SHRFSP) y los capítulos que
  los consumen, `06_libro/4_Balance/costofinanciero.tex` y
  `costofinancieroi.tex`.

### Candidatos registrados (no corregidos en este ciclo)
- **`master/SHRFSP.dta` carga derivados 1990-1999 contaminados.** Esas filas
  traen `unidad_de_medida == "Dólares"`: `monto_pc` son dólares per cápita
  deflactados con un índice de precios MEXICANO y `monto_pib` es un cociente
  dólares/pesos (0.23% del PIB en 1999). El saldo en pesos simplemente no
  existe antes de 2000. El nodo lo esquiva con piso 2000 + un guard de unidad
  que verifica el piso en cada corrida; la limpieza a missing explícito
  corresponde a un ciclo futuro de `UpdateSHRFSP`.
- **La columna "Total" de la matriz `rfsp` de `SIM.do` es decorativa.**
  `global rfsp<año>` se define en `SIM.do:393` y no lo consume nadie:
  `SHRFSP.ado:131` recalcula `rfsp` como la suma de sus siete componentes.

## [v8.2.0] — 2026-07-19

**Cambio de metodología del PC de salud: el denominador pasa de
hogares-equivalentes a PERSONAS para mantener consistencia con los demás
rubros del gasto.** Y unificación de los conteos de población del sitio: los
19 `data-pop`/columnas quemados en el HTML migran a viajar por `output.txt`
(bloques nuevos `GASTOSPOB1`/`GASTOSPOB2`).

### Comandos
- `GastoPC.ado`: conteos de PERSONAS para display/PC/web (matriz `SaludPer`,
  ENIGH 2024 con el factor de perfiles ya proyectado a población CONAPO del
  año PE — reescalado calculado en la corrida, no hardcodeado). Definiciones
  documentadas en el código: SSA/Inversión/Total = población CONAPO
  (coherente con Energía/Cultura); IMSS `inst_1`; ISSSTE `inst_2`;
  Pemex/ISSFAM `inst_4` partido con el ancla administrativa 602513/1169476;
  otros `inst_6`; IMSS-Bienestar = residuo sin seguridad social, con `inst_3`
  (ISSSTE estatal, ~2.0M personas) DENTRO del residuo por continuidad
  metodológica — candidato de refinamiento registrado en bitácora. La doble
  afiliación declarada (0.7%) se cuenta en AMBAS instituciones, como en los
  registros administrativos. Los `*Pob`/`*PC` de salud pasan a personas
  (IMSS: 12,091,141 hogares-eq → 55,311,028 personas; PC 43,008 → 9,402);
  los `*PIB` no cambian.
- **Desacople de la incidencia**: la imputación por persona
  (`Salud = Σ PC×benef_*`) conserva el cociente hogares-equivalentes como
  tempname scalar interno (`*PCinc`, double exacto — un local stringifica y
  mueve el último bit); `benef_*` INTACTOS. Guardián: Sankeys y deciles
  byte-idénticos.
- `01_modulos/output.do`: bloques `GASTOSPOB1`/`GASTOSPOB2` con los 42 conteos
  (indexado espejo de `GASTOSPC`; en DOS bloques porque el linesize máximo de
  Stata (255) partiría la línea con `> ` y `checkStataStatus.php` no maneja
  continuaciones). Parser PHP genérico: cero cambios en PHP.
- Display de `GastoPC`: header "Asegurados" → "Derechohabientes".
- TODOs sembrados en las anclas administrativas sin fuente/corte documentados
  (`602513/1169476` salud Pemex/ISSFAM; `110000/181290` pensiones Pemex).

### Correcciones
- **Bug vivo del botón ± de Salud**: el HTML traía conteos quemados grandes
  (`data-pop`) mientras el PC publicado usaba denominador chico
  (hogares-equivalentes): un click de +$1,000 en IMSS saltaba el gasto de
  1.374% a ~6.4% del PIB. Con el PC por persona y `data-pop` del motor:
  1.374% → 1.520% (Δ +0.146 pp), verificado con la aritmética exacta del
  handler.
- **Procedencia de los fósiles del sitio RECUPERADA**: los conteos quemados
  (IMSS 55,311,028; IMSS-B 57,363,801; ISSSTE 7,171,893; Pemex 619,741;
  ISSFAM 583,175) eran exactamente esta misma construcción — personas ENIGH
  con el factor proyectado a CONAPO — y el motor nuevo los reproduce dígito
  por dígito (ese era el test de la construcción). La clase de fósil HTML
  muere: `poblarConteos()` en ambos JS sobreescribe la columna visible
  (spans `.pob-value`) y los `data-pop` desde `GASTOSPOB` en cada carga y en
  cada simulación; los números del HTML quedan como placeholder-snapshot con
  guard para motores sin el bloque.
- Sitio (ambos index): etiqueta "Asegurados"/"Insured" → "Derechohabientes
  (ENIGH 2024)"/"Beneficiaries (ENIGH 2024)" con tooltip ("Estimación ENIGH
  2024 ajustada a población CONAPO"); los 6 links de headers que apuntaban a
  ENIGH 2022 → 2024; el JS inglés NO tenía el handler del ± (gap preexistente
  del tablero) — portado idéntico al español.

### Datos
- Sin cambios de fuentes: misma ENIGH 2024 / CGPE 2026 (`data_updated`
  intacto — cambia la metodología de un derivado, no los datos).

Tests (todas las clases esperadas verificadas con harness batch old-vs-new,
ids aislados `users/cbase820`/`users/cnew820`): (a) conteos y PC de salud
según la tabla aprobada; (b) 5 `sankey-*.json` BYTE-IDÉNTICOS
(incidencia/deciles intactos) y `output.txt` byte-idéntico salvo los 8 PC de
salud de `GASTOSPC`; (c) par de `statalatex_gastopc` harness: SOLO los 16
getters `*Pob/*PC` de salud cambian, `*PIBgpc` intactos — el `.tex` trackeado
del libro (registro global-acumulado de la corrida textbook completa, ~4,400
líneas vs 368 del harness) se refresca en la próxima corrida real del libro;
(d) bloques `GASTOSPOB` bien formados (196/193 chars, 21+21 slots, cero
elementos no numéricos) y digeridos por los parsers de
`cargaDefault.php`/`checkStataStatus.php` simulados en PHP; (e) test del ±
declarado y observado: 1.520% (Δ +0.146 pp).

## [v8.1.0] — 2026-07-19

Reprocesamiento completo de PEF.dta (2013-2026) y rediseño de `UpdatePEF`:
las divisiones (divCIEP/divSIM/divFEDE) se anclan a códigos oficiales de la
Clasificación Funcional del Gasto del CONAC (pares finalidad/función) y a
texto normalizado de TIPOGASTO, con verificador de deriva año-por-año que
DETIENE el proceso ante cualquier mismatch (jamás clasificar en silencio).
Motivador: los selectores por códigos de `encode` (alfabéticos) derivaron con
cada categoría nueva — `desc_funcion==21` ("salud" al escribirse) apuntaba a
"cuotas a organismos internacionales de energía" y `desc_funcion==10`
("educación") a "asuntos financieros y hacendarios".

### Datos
- **CP 2013 entra completa por primera vez** (308,454 obs; antes 1 obs): el
  xlsx de SHCP trae una hoja pivote antes de la hoja de datos y el import
  tomaba la primera. `UpdatePEF` ahora detecta la hoja de datos (la de más
  filas) sin depender de xlsx curados a mano.
- **2025 pasa de PEF (aprobado) a Cuenta Pública** (`CP 2025.xlsx`, 210,459
  obs con ejercido/modificado/devengado/pagado; el asset `PEF.2025.xlsx`
  queda superseded y se elimina localmente). Gasto total 2025:
  10,940.5 → 11,417.7 mmdp (aprobado→ejercido).
- CP 2025 llega con esquema nuevo de SHCP (columnas sin prefijo `ID_`; el
  ramo viene en la columna `R` — el `Diccionario.csv` de SHCP la documenta
  como `RAMO`; discrepancia documentada en el código). El drop de columnas
  de 2 caracteres (hack para las ~180 columnas fantasma de CP 2022) se
  reemplaza por detección de columnas 100% vacías, que no mata UR/AI/PP/FF.
- `manifest.json`: SHAs nuevos de `CP.2013.xlsx` (sin hoja pivote) y
  `CuotasISSSTE.xlsx`; alta de `CP.2025.xlsx` y `Diccionario.csv`; baja de
  `PEF.2025.xlsx`. `data_updated` → 2026-07-19.

### Correcciones
- **(a3) Reclasificación Salud/Educación/Energía**: con las reglas CONAC,
  Salud pasa de 133.7→489.3 (2014) … 255.6→959.6 (2024) mmdp; Educación de
  451.7→712.5 (2014) … 620.9→1,124.1 (2024) mmdp — recuperan la función
  salud/educación en IMSS/ISSSTE/ramo 33 que la regla muerta perdía, y sale
  de Educación el gasto hacendario (41-244 mmdp/año) que la deriva le metió.
  Contraparte: divCIEP "Federalizado" y "Otros gastos" disminuyen en lo
  mismo. **El gasto total por año NO cambia** (verificado al peso, 2014-2024
  y 2026).
- **(a4) Comparaciones muertas por mayúsculas** (la limpieza pasa todo a
  minúsculas): FEIEF `modalidad=="Y"` (1.8-25.9 mmdp/año), INSABI/IMSS-B
  federalizado `modalidad=="U"` (67.8-105.3 mmdp/año, divFEDE "Salud
  (federalizado)" revive desde 2019), cuidados `ur=="V3A"/"V00"`
  (~0.3-0.8 mmdp/año), y `ur=="TZZ"/"TOQ"` en la homologación de ramo.
- Basura del pivote de CP 2013 eliminada: 66 obs sin año, variable
  `combustiblesyenergía`, y los labels fantasma "row labels"/"total result"
  en `desc_funcion`. Se limpia también la redundancia
  `desc_entidad_federativa` (quedaba junto a `entidad`).
- Evidencia contra anclar TIPOGASTO por id ("doble llave"): el id 4 fue
  "participaciones" en 2013-2015 y "pensiones y jubilaciones" desde 2016
  (SHCP renumeró el catálogo). El ancla correcta es el texto normalizado.

### Comandos
- `PEF.ado` v8.1: verificador de deriva (sección 4.0) corre en cada
  `UpdatePEF` — asserts por año de los pares CONAC (salud, educación,
  combustibles y energía) y whitelist de textos TIPOGASTO; mismatch → error
  459 con año y texto encontrado.
- Secciones 3.1/3.2 (series de Estadísticas Oportunas por códigos de encode)
  congeladas junto con la 3.3: el bloque completo se comenta y revive junto.
  `PEF.dta` pierde las variables muertas `serie_desc_funcion`/`serie_ramo`.
- `SubnacionalGasto.do` (legacy): comentario de advertencia — selecciona por
  códigos de encode que ya no significan lo que significaban.
- Contrato r() intacto: batería dorada con los nombres que consumen
  `GastoPC`/`Households`/`PerfilesSim`/`FiscalGap` corrida contra base vieja
  y nueva — ningún nombre se pierde; totales (`Gasto_neto`) idénticos; solo
  cambian los valores de las divisiones reclasificadas. Las etiquetas de los
  encodes se mantienen en minúsculas: los nombres de r() derivan del texto
  de las etiquetas y los consumidores dependen de su case exacto
  (`r(educacion_basica)` y `r(Baja_California)` conviven) — el plan de
  "etiquetas bonitas" queda diferido a un ciclo con migración de
  consumidores.

### Contrato de params de interfaz: string → NUMÉRICO
- Los 15 params de ingresos (`ISRASPIB`…`IMPORTPIB`) que `Web.Stata.do`
  declaraba entre comillas (string scalars) pasan a declararse SIN comillas,
  igual que las 5 reasignaciones de los submódulos ISR/IVA
  (`round(<Mod>, 0.001)` en vez de `"\`=round(...)'"`). Ambos flujos hablan
  igual: local vía `escalar` (SIM.do) y web vía template — y los `real()` a
  la lectura mueren con razón (FiscalGap:132 y los 4 sitios de SankeySF ya
  consumían numérico directo; sin esta migración el flujo web tronaba con
  type mismatch). Censo repo: cero `real()` sobre params restantes; los
  `real()` de parsing legítimo (`PEF.ado:678` regex, `TarjetaRFSP.do:25`
  fecha) no son params y quedan.
- **Mejora del modo de falla**: un placeholder `{{X}}` sin sustituir antes
  producía `real("{{X}}") = missing` — cero silencioso que se propagaba;
  ahora truena en SINTAXIS (r(198), visible en el log de sesión con el
  nombre del placeholder en la línea). Verificado con harness del contrato
  web (positivo: 155/155 sustituidos, corrida completa sin errores, bloques
  de `output.txt` idénticos en forma a la referencia; negativo: r(198)
  visible, cero bloques de datos producidos). Matiz registrado sin tocar:
  `calculaStata.php:63` sustituye `0` por default para params ausentes del
  POST — ese modo de falla silencioso es preexistente y de otro ciclo.
- Strings por diseño conservan comillas con comentario: `{{idSession}}`
  (id de sesión: paths) y `{{moduloCambio}}`/`{{moduloCambioIva}}` (flags en
  igualdad de strings; sin sustituir el módulo queda apagado — degradación
  intencional). `calculaStata.php` no se toca: `str_replace` es textual y
  las comillas vivían solo en el template.

## [v8.0.13] — 2026-07-18

Cierra la migración a `escalar` con `Simulador.ado` (excluido explícitamente
en v8.0.12): sus 9 sitios `string()` alimentan el alias `perf`, el mayor
consumidor del libro (414 usos). Con esto queda vigente el CONTRATO de
governance: **todo lo que alimenta el libro pasa por `escalar`** (regla
escrita donde vive el catálogo: header de `escalar.ado` y
`03_help/PROGRAMAS_AUXILIARES.md` §16). Cobertura verificada con censo
contra el libro: los 17 productores textbook + `Simulador.ado` registran
todo lo que el libro consume con formato; el residual "sin registrar" del
resumen (228 scalars en memoria) se auditó nombre por nombre — 211 son
scalars de trabajo internos que el libro NO referencia y 17 los consume
as-is numéricos con valor correcto (años de sesión `aniovp/anioPE/anioenigh/
aniofinal` y agregados `RFSPmax*`, `*gene*`, `pibVECES*`) — candidatos a
migración puntual en un ciclo futuro para dejar el resumen en 0 real.

### Comandos
- `Simulador.ado`: migrados los 9 sitios `string()` → `escalar` con tipos del
  catálogo: `<var>GPIB`→pctpib; `<var><decil>` (pesos por hogar)→mxnpc;
  `dis/inc<var><decil>`→pct; `<var>GIV/GVIIX/GX`→pct; `<var>GH/GM`→pct.
  Estos sitios corren también en cada simulación web (secciones 2, 4 y
  `poblaciongini` son incondicionales), no solo bajo textbook.
- `scalarlatex.ado` v2.1.0: el resumen de cobertura compara los sin-registrar
  contra el baseline auditado `02_governance/scalarlatex-baseline.txt` (228
  nombres) — dentro del baseline, línea informativa sin dump; nombres NUEVOS,
  aviso en rojo solo con esos nombres (la señal ya no se ahoga en 228 líneas
  permanentes). Procedimiento de actualización legítima en el header del
  baseline; sin el archivo (repo incompleto), cae al listado histórico.

### Correcciones
- Hallazgo de Fase A: `Simulador.ado:469` leía el scalar por-decil con
  `subinstr()` (función de strings) para armar la línea `INCD:` del flujo
  web — con el scalar ya numérico habría tronado con r(109) en CADA
  simulación web. Adaptado a `string(<scalar>,"%10.0f")`, que produce el
  mismo entero sin comas. Equivalencia demostrada empíricamente (lección del
  incidente v1.39): corrida batch con `$output=="output"` antes y después de
  la migración — líneas `INCD:`/`INCD2:`/`INCD3:` (y `APORT*`/`PROY*`)
  byte-idénticas.

### Test dorado (perfiles + acumulación)
- Los 9 `.tex` regenerados (corrida textbook completa, export a /tmp) y
  comparados getter por getter contra los vigentes: **519 getters cambiados,
  el 100% de la clase esperada** `*GIV/*GVIIX/*GX` entero → 1 decimal (108 en
  perfiles/fiscalgap/shrfsp, 90 en gastopc/tasas, 15 en households, por
  acumulación del registro global); **cero diffs de valor, cero getters
  nuevos**. Los 414 getters `perf` que usa el libro: 380 existen con el mismo
  nombre; los 34 restantes (`OtrosGastos*` sin T, `GATA*`) ya faltaban en el
  baseline — drift libro↔modelo preexistente, no regresión.
- Nota del test batch: `aniotdmin/aniotdmax` no se generan bajo `nographs`
  (se definen dentro del bloque de gráficas de `Poblacion.ado:197`) — artefacto
  del harness, preexistente; la corrida real del libro va con gráficas.

## [v8.0.12] — 2026-07-18

Pipeline textbook declarativo: los ~670 scalars que alimentan los documentos
LaTeX internos dejan de definirse con `noisily di %fmt` + relectura de logs de
pantalla (patrón fósil, frágil ante cualquier cambio cosmético de impresión) y
pasan a declararse con el nuevo comando `escalar <tipo> <nombre> = <exp>`,
que registra nombre y tipo semántico; `scalarlatex` exporta desde ese registro
con formato canónico por tipo. Cero impacto en el endpoint público. Los `.tex`
internos sí cambian de valores: la precisión completa y dos bugs corregidos
(ver Correcciones) mueven los agregados por decil de los módulos ENIGH.

### Comandos
- Nuevo `escalar.ado` (solo-repo): define el scalar y lo registra para
  exportación textbook con el catálogo de tipos pctpib, pct, mxn, mxnpc,
  personas, anio y custom(%fmt). Ver `03_help/PROGRAMAS_AUXILIARES.md` §16.
- `scalarlatex.ado` reescrito: aplica el formato canónico del registro
  `$scalarlatex_reg` en vez de releer `users/$id/*.txt`; ya no depende de
  `log on/off` ni de formatos de impresión. Los scalars sin registrar se
  exportan tal cual y se reportan (drift visible). Interfaz intacta
  (`log()`, `alt()`).
- Migrados los 17 archivos productores textbook (~670 sitios): PIBDeflactor, Poblacion,
  SCN, SHRFSP, TasasEfectivas, GastoPC, LIF, FiscalGap y módulos Households,
  PerfilesSim, Expenditure, ISR_Mod, IVA_Mod, output, Sankey(SF), Graphs_TE.
- El censo de cierre cazó 17 sitios omitidos en `Expenditure.do` (incluidos los
  round-trips `DifIVA`/`DifIEPSNP`, misma clase del bug del arrendamiento) y 10 en
  `FiscalGap.ado` (`tt*/td*/tn*` + años): migrados. El `real()` de FiscalGap:132
  sobre los params `*PIB` de SIM.do queda con comentario-INVARIANTE: son strings
  por diseño (interfaz web), igual que en SankeySF — no migrar.
- `Simulador.ado` (9 sitios `string()`, nombres dinámicos por decil) NO se migra
  en v8.0.12: corre en el VPS por cada simulación y exige ciclo propio con
  validación web. Registrado en bitácora v1.38 como candidato.

### Correcciones
- Cierra el AGUJERO CONOCIDO de v8.0.11: PIBDeflactor, Poblacion, SCN y SHRFSP
  publicados ahora hacen `capture which scalarlatex` bajo `textbook` y avisan
  amablemente que la opción es solo-repo, en vez de tronar con "command
  scalarlatex is unrecognized" en el endpoint.
- Los `\def` LaTeX con dígitos en el nombre (p.ej. `\dConsPriv21PIBscn`) se
  generaban rotos en silencio; `escalar` convierte dígitos a letras (0→A…9→J)
  y ahora esas macros son válidas.
- Los scalars "% del PIB" del SHRFSP se exportaban con 1 decimal (formato de
  pantalla); ahora 3 decimales canónicos. Padding accidental de `%07.1fc` y
  redondeos compuestos de la relectura de logs eliminados.
- BUG NUMÉRICO corregido (silencioso desde el origen del patrón): en
  `Households.do` el split arrendamiento pf/PM (`ing_t4_cap3pf`/`PM`) usaba
  `real(scalar(AlojT))` sin quitar comas; `real("940,573.4")` = missing, así
  que TODO el capítulo 3 (arrendamiento) se caía en silencio del ingreso mixto
  y del ingreso de capital (`rsum` trata missing como 0). Con el valor real,
  el ingreso mixto captado sube ~30% (MixLHHSPIB 1.861→2.421% PIB;
  DifMixL −86.5→−82.5%) y se recorren deciles, ahorro, cortes de formalidad
  ISR y la brecha fiscal (diffs de ±1–4% en fiscalgap/gastopc/households/
  perfiles/shrfsp/tasasEfectivas del test dorado).
  Causalidad DEMOSTRADA por prueba de aislamiento: código viejo + únicamente
  el fix del `subinstr` reproduce 4,315 de los ~4,900 valores que cambian
  (base→viejo+parche); el resto es precisión/formato del pipeline nuevo
  (viejo+parche→nuevo: 96 diffs = 16 escalares×6 alias, todos auditados:
  mismo valor con decimal nuevo o fin del redondeo a 0.1 mdp de la
  relectura). Residuo inexplicado: 0.
- Durante la migración, `SCN.ado` registraba `PIB` en millones con tipo
  `pctpib` mientras sus consumidores (Households, Expenditure, ISR_Mod)
  esperan pesos: ratios `*HHSPIB` salían 1e6 veces más grandes. Corregido a
  `escalar mxn PIB = PIB[obs]` (pesos, display idéntico al histórico).

## [v8.0.11] — 2026-07-10

El endpoint público se vuelve autosuficiente: un usuario externo que instala
un comando vía `net install` puede reconstruir los datos desde cero en SU
máquina, sin repo ni clone. Corrige un bug de arquitectura presente desde el
primer deploy del endpoint: los comandos publicados invocaban helpers y
dependencias que el endpoint no entregaba — nunca funcionó para un externo;
solo parecía funcionar porque siempre se probó desde el repo. Cero impacto
en resultados numéricos.

### Institucional
- Decisión de arquitectura: el endpoint DEBE permitir reconstruir datos desde
  cero — es abierto, reconstruir es la gracia. La solución es un ensure_asset
  de doble entorno con pin de versión quemado al publicar (ver Comandos), de
  modo que código y datos del externo siempre casan: reconstruye contra los
  assets del Release de SU versión instalada.
- AGUJERO CONOCIDO PENDIENTE (no corregido en este bump): `scalarlatex` es
  invocado por PIBDeflactor, Poblacion, SCN y SHRFSP bajo la opción `textbook`
  (insumos LaTeX internos CIEP) y NO se publica al endpoint — un externo que
  active esa opción verá "command scalarlatex is unrecognized". Fix futuro:
  `capture which scalarlatex` + aviso amable de que textbook es solo-repo.

### Comandos
- ensure_asset ahora funciona sin repo (doble entorno): si encuentra
  `05_scripts/manifest.json` en el site (caso repo), comportamiento intacto;
  si no, usa el pin de versión que publicar-endpoint.sh quema en la copia
  publicada para descargar el manifest de GitHub por tag
  (raw.githubusercontent.com/<repo>/<tag>/05_scripts/manifest.json), lo
  cachea por versión en `raw/temp/manifest-<tag>.json`, valida que la
  versión del manifest coincida con el pin (drift → error ruidoso nombrando
  la URL) y continúa con la descarga de assets ya existente. El .ado del
  REPO lleva el pin VACÍO — solo la copia publicada lo lleva relleno.
- ensure_asset se publica al endpoint (sale de la lista de exclusión de
  manifest-endpoint.toml); viaja dentro de los .pkg que lo necesitan, sin
  paquete propio de cara al usuario.

### Datos
- Sin cambios respecto a v8.0.10.

### Correcciones
- Clausura transitiva de dependencias en 6 .pkg: cada paquete ahora declara
  TODAS sus dependencias .ado (quien instala PEF recibe también
  DatosAbiertos, AccesoBIE, Poblacion y ensure_asset; análogo para
  DatosAbiertos, LIF, PIBDeflactor, SCN y SHRFSP). Antes, instalar un
  paquete individual dejaba fuera eslabones de su cadena de reconstrucción
  y el comando tronaba con "command ... is unrecognized".
- publicar-endpoint.sh verifica la inyección del pin y ABORTA si el marcador
  no está — imposible publicar un ensure_asset sin pin por accidente.
- Hallazgos del test de "máquina virgen" (instalar SOLO desde el endpoint y
  reconstruir), corregidos de paso — tres bugs que solo muerden fuera del
  repo:
  - ensure_asset descarga con `requests` en lugar de `urllib`: urllib truena
    con CERTIFICATE_VERIFY_FAILED en Pythons sin certificados configurados
    (caso típico de instalación de python.org en macOS); requests trae sus
    propios certificados (certifi) y ya es dependencia dura de la suite
    (AccesoBIE la importa).
  - `mkdir master/` antes de cada save de la cadena de reconstrucción (LIF,
    PEF ×2, SCN, SHRFSP, Deflactor): en una máquina sin repo el directorio
    no existe y el save tronaba con r(603) — mismo bug de instalación fresca
    que v8.0.9/v8.0.10, en otra capa.
  - Eliminado un guard `if c(console)==console { exit }` en
    UpdateDatosAbiertos que abortaba la reconstrucción EN SILENCIO en Stata
    console/batch — el comando anunciaba "ACTUALIZANDO..." y salía sin
    hacer nada, dejando un r(601) críptico aguas abajo. Hacía imposible
    reconstruir en batch (p.ej. servidores).

## [v8.0.10] — 2026-07-10

AccesoBIE deja de exigir token para funcionar: sin token, usa la consulta
pública de exportación (.aspx) del INEGI — una vía que YA existía como
respaldo automático cuando la API falla, pero que era inalcanzable sin
token porque el comando abortaba antes de intentarla. Los comandos
publicados del Simulador dejan de depender de que el usuario externo
tenga token. Cero impacto en resultados numéricos.

### Institucional
- Nota de diseño sobre la vía pública (.aspx), con honestidad sobre su
  fragilidad: el *mecanismo* es oficial y abierto (el endpoint de
  exportación a Excel del propio portal del BIE, sin auth), pero la
  *implementación* parsea la tabla HTML de la respuesta con
  BeautifulSoup — más frágil que el JSON de la API: se rompe si INEGI
  cambia el layout de esa tabla. Es aceptable distribuirla porque (a) ya
  era camino de producción activo (corría cada vez que la API fallaba),
  (b) no introduce dependencias nuevas, y (c) el fallo es visible, no
  silencioso. Por esa fragilidad, la API con token sigue siendo la vía
  recomendada.

### Comandos
- AccesoBIE sin token: ya no aborta con exit 198 inmediato. Usa la
  consulta pública (.aspx) como vía única, con aviso visible de por cuál
  vía se obtuvieron los datos y de cómo conseguir el token gratuito.
  Sin token NO se golpea la API (no se hacen requests con token vacío).
  Ambas vías entregan exactamente el mismo formato de salida.
- AccesoBIE: exit 198 pasa a ser el fallo FINAL — solo cuando una serie
  no se pudo obtener por ninguna vía — con mensaje que nombra la serie y,
  si no hay token, explica que solo se intentó la vía pública.

### Datos
- Sin cambios respecto a v8.0.9.

### Correcciones
- AccesoBIE: si una serie no se obtenía (p.ej. clave inexistente), el
  comando mostraba un error y seguía (continue), dejando tempfiles
  indefinidos que después tronaban en el use/merge con un error críptico
  lejos de la causa. Ahora el error truena en su origen, claro y
  nombrando la serie.
- AccesoBIE: mismo bug de instalación fresca que v8.0.9 en DatosAbiertos
  — mkdir no recursivo —: el árbol site/raw/temp/AccesoBIE/ ahora se crea
  nivel por nivel.

## [v8.0.9] — 2026-07-10

DatosAbiertos aprende a descargar con respaldos: la opción `update` ahora
intenta el zip (dos veces, por errores transitorios de conexión), si falla
cae al csv directo, y si también falla usa los archivos locales de
`raw/temp/`. Antes, `update` sin más opciones ni siquiera descargaba —
leía los archivos locales en silencio. La opción `files` se renombra a
`local` y los 33 bloques repetidos de descarga se colapsan en un programa
auxiliar. Cero impacto en resultados numéricos.

### Institucional
- DatosAbiertos.ado: los 33 bloques idénticos `csvfile/zipfile/else`
  (~550 líneas, uno por base del portal SHCP) se colapsan en el programa
  auxiliar `_DAdescarga`, que concentra la cadena de respaldos en un solo
  lugar. Arreglar un problema de descarga ahora es un cambio de una línea,
  no de 33.

### Comandos
- DatosAbiertos, `update`: ahora descarga de verdad, con cadena de
  respaldos automática (zip con reintento → csv directo → archivos
  locales). Cada caída de la cadena se anuncia en pantalla; si tampoco hay
  archivo local, el error truena en su origen.
- DatosAbiertos, `zipfile`: se conserva por compatibilidad; hoy equivale a
  la cadena completa de `update`.
- DatosAbiertos, `csvfile`: brinca el zip y va directo al csv en línea;
  si falla, usa los archivos locales.
- DatosAbiertos, `local` (nueva): reconstruye la base desde los archivos
  ya descargados en `raw/temp/`, sin internet. Sustituye a `files`, que
  se retira — quien la use recibirá el error estándar "option files not
  allowed".

### Datos
- Sin cambios respecto a v8.0.8.

### Correcciones
- DatosAbiertos: la primera corrida en una instalación fresca tronaba con
  r(170) — `mkdir` de Stata no es recursivo y el árbol
  `site/raw/temp/Datos Abiertos/` no se creaba si faltaba algún nivel
  (una instalación nueva no trae ni `site/`). Ahora el árbol se crea
  nivel por nivel antes de usarse.
- DatosAbiertos: las descargas ahora van con `copy` (que acepta URLs en
  cualquier versión de Stata) en lugar de `unzipfile`/`import delimited`
  con URL directa, que no son portables entre versiones — en algunas, el
  intento de zip fallaba al instante sin llegar a la red. Los mensajes de
  la cadena de respaldos ahora incluyen el código de error de Stata para
  poder diagnosticar la causa (conexión, servidor, archivo inexistente).

## [v8.0.8] — 2026-07-10

La cadena del token BIE/INEGI se endurece de punta a punta: SIM.do deja
de tragarse errores reales al cargar el token, profile.do lo carga al
abrir Stata (los investigadores CIEP ya no necesitan correr SIM.do para
usar AccesoBIE), y el mensaje de error de AccesoBIE ahora dice qué hacer
según quién seas. Cero impacto en resultados numéricos.

### Institucional
- SIM.do: el `capture do set_token.do` ciego (que ocultaba errores de un
  token mal configurado) se reemplaza por `confirm file` + `run` sin
  capture. Ahora distingue archivo ausente (aviso amable con el camino:
  copiar `set_token.template.do` a `set_token.do`) de archivo roto (el
  error se ve en su origen). SIM.do sigue siendo autocontenido: carga su
  propio token después del `macro drop _all` del arranque.
- profile.do: carga el token al arranque interactivo con el mismo patrón.
  Si falta, la bienvenida incluye una nota amable con el camino para
  configurarlo — sin error rojo, el arranque no se interrumpe.

### Comandos
- AccesoBIE: mensaje de error mejorado cuando falta el token. Ahora sirve
  a dos audiencias: usuario externo (cómo fijar `global BIE_API_TOKEN` y
  el link del INEGI para obtener token) e investigadores CIEP (correr
  set_token.do o reiniciar Stata). La validación con `exit 198` ya
  existía; solo cambió la redacción. Sin cambios en sintaxis ni
  resultados.

### Datos
- Sin cambios respecto a v8.0.7.

## [v8.0.7] — 2026-07-09

SCN deja de depender de un directorio externo para su intermedio de PIB:
el archivo temporal `raw/temp/basepib.dta` se reemplaza por un `tempfile`
de Stata. En instalaciones donde `raw/temp/` no existía (por ejemplo, un
deployment limpio del servidor web), SCN tronaba con r(603) al intentar
guardar ahí. Cero impacto en resultados numéricos.

### Institucional
- SCN.ado: el intermedio `basepib` ahora vive en un `tempfile` (Stata lo
  crea donde corresponde y lo limpia solo), en lugar de escribir y leer
  `raw/temp/basepib.dta`. Mismo principio que `ensure_asset`: los comandos
  no asumen estado de directorios externo.
- Detectado durante el debugging del primer deploy del motor web v8.0 al
  VPS (2026-07-09); el pipeline de deployment también se endureció en el
  mismo commit (fases de permisos y assets — no afecta a los comandos).

### Comandos
- Sin cambios en sintaxis, opciones ni resultados de SCN. El cambio es
  interno (dónde vive un archivo temporal).

### Datos
- Sin cambios respecto a v8.0.6.

## [v8.0.6] — 2026-07-07

Fixes estéticos coherentes en las gráficas de dos comandos del canon
(PIBDeflactor y SCN): eliminar del eje temporal los años que solo contenían
datos missing, que hacían que las gráficas se vieran incompletas y con
huecos visuales. Cero impacto en resultados numéricos.

### Institucional
- PIBDeflactor.ado (gráfica de Productividad): filtro del `if` y del `tlabel`
  ajustados para mostrar solo años con datos válidos. Bloque `yline` + `text`
  de diferencia 2005-aniofinal preservado comentado (decisión del
  investigador principal para posible reactivación futura).
- SCN.ado (2 gráficas): `xlabel` del eje X ahora llega hasta `latest`
  (último año con datos reales) en lugar de `aniomax` (año máximo teórico).
- SIM.do: cambio de comportamiento default — por defecto muestra gráficas
  (`global nographs` comentado). Antes suprimía gráficas por default.
  Solo afecta a investigadores CIEP internos que corren SIM.do.

### Comandos
- Sin cambios en sintaxis, opciones ni datasets de PIBDeflactor y SCN.
  Los cambios son puramente visuales en las gráficas generadas.

### Datos
- Sin cambios respecto a v8.0.5.

## [v8.0.5] — 2026-07-04

Nuevo Gate 4 en pipeline de publicación: validación de existencia de archivos
declarados en manifest-endpoint.toml. Antes de crear la Release en GitHub,
publicar.sh verifica que cada archivo declarado como ado_files, sthlp_files,
y pkg_files existe físicamente en el filesystem del repo. Si algún archivo
falta, aborta con error informativo. Habría atrapado el bug de AccesoBIE.pkg
(v8.0.3 fix).

### Institucional
- Nuevo Gate 4 en publicar.sh valida existencia de archivos declarados en
  manifest-endpoint.toml antes de crear Release GitHub y rsync al endpoint.
- Los gates semánticos candidatos (autoría, URLs, prueba de humo automatizada)
  se descartan formalmente. Revisión visual del .sthlp por el investigador
  cubre autoría y URLs. Prueba de humo manual desde Stata externo (net from +
  net describe) es el gate humano institucional para validación semántica de
  paquetes publicados.

### Comandos
- Sin cambios de comportamiento en los comandos del canon.

### Datos
- Sin cambios respecto a v8.0.4.

## [v8.0.4] — 2026-07-04

Fix: corrige link para obtener el token del BIE/INEGI. El link anterior
(https://www.inegi.org.mx/servicios/api_biinegi.html) era una página obsoleta.
El link correcto es el generador de tokens de INEGI:
https://www.inegi.org.mx/app/api/denue/v1/tokenVerify.aspx
(compartido con DENUE, ya que INEGI usa un único sistema de tokens).

### Institucional
- 03_help/Stata/AccesoBIE.sthlp: link del {browse} corregido al generador
  de tokens vigente.
- AccesoBIE.ado: mensaje de error apunta al link correcto.
- set_token.template.do: comentario del template apunta al link correcto.

### Comandos
- Sin cambios de comportamiento. AccesoBIE mantiene sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.3.

## [v8.0.3] — 2026-07-04

Fix: agrega 05_scripts/AccesoBIE.pkg que estaba declarado en el manifest del
sub-canal Stata público pero nunca existió en el filesystem. Este bug estaba
presente silenciosamente desde v8.0 y solo se destapó al probar
`net describe AccesoBIE` desde Stata externo tras la publicación de v8.0.2.

### Institucional
- Nuevo 05_scripts/AccesoBIE.pkg permite que investigadores externos hagan
  `net describe AccesoBIE` y `net install AccesoBIE` correctamente.
- manifest-endpoint.toml actualizado para incluir AccesoBIE.pkg en pkg_files.
- Corrección de typo en los 8 .pkg: "finanzas púbicas" → "finanzas públicas"
  (texto visible para investigadores externos en `net describe`).

### Comandos
- Sin cambios de comportamiento. Los comandos mantienen sintaxis y datasets.

### Datos
- Sin cambios respecto a v8.0.2.

## [v8.0.2] — 2026-07-04

Cambio menor de metadata: los 11 archivos .sthlp del canon (AccesoBIE,
DatosAbiertos, LIF, PEF, PIBDeflactor, Poblacion, SCN, SHRFSP, GastoPC,
TasasEfectivas, sim_changelog) ahora incluyen autoría del investigador
principal + correo institucional clicable en el encabezado.

### Institucional
- Encabezado de los .sthlp muestra ahora: "Centro de Investigación Económica
  y Presupuestaria, A.C. | ciep.mx" seguido de "Ricardo Cantú Calderón |
  ricardocantu@ciep.mx" (correo abre cliente de mail al hacer clic).

### Comandos
- Sin cambios respecto a v8.0.1. Los comandos mantienen sintaxis, opciones,
  resultados y datasets.

### Datos
- Sin cambios respecto a v8.0.1. Assets del data sidecar son idénticos.

## [v8.0.1] — 2026-07-03

Cleanup documental. La ayuda de comandos institucionales del canon queda consolidada
en archivos .sthlp como fuente única de verdad. Los .md descriptivos que vivían en
paralelo desde febrero 2026 fueron migrados (contenido metodológico que sobrevivió
la auditoría de sincronía .ado/.sthlp) o eliminados. El manual del investigador se
movió de manuales/ a help/.

### Institucional
- Los .md de ayuda de los 8 comandos del canon (AccesoBIE, DatosAbiertos, LIF, PEF,
  PIBDeflactor, Poblacion, SCN, SHRFSP) fueron consolidados en sus respectivos .sthlp
  y eliminados. Nueva subsección 2.7 en 02_governance/arquitectura-y-bitacoras.md
  formaliza el principio "la ayuda de comandos vive en .sthlp".
- Manual del investigador movido de manuales/ a help/ (unifica dominio "help").
- README.md corregido: rutas de imágenes rotas apuntan a help/images/; bloques con
  imágenes fantasma eliminados; entrada canónica a la ayuda ahora es help <comando>.
- Hallazgo #3 de 02_governance/historico/auditoria-drift-sthlp.md marcado como resuelto.

### Comandos
- Sin cambios respecto a v8.0. Los comandos mantienen la misma sintaxis, opciones,
  resultados y datasets. Solo cambia el contenido de la ayuda (más rico, sin drift).

### Datos
- Sin cambios respecto a v8.0. Las fuentes y assets del data sidecar son idénticos.

## [v8.0] — 2026-05-29

**Primera versión bajo arquitectura institucional completa.** Marca el inicio de la era
reproducible: a partir de v8.0 cualquiera puede reconstruir código + datos exactos usados
para producir un resultado citado del Simulador.

### Institucional
- Data sidecar publicado en GitHub Release v8.0 con 23 archivos de fuentes (PEFs, LIFs,
  ENIGH, CuotasISSSTE, ISRInformesTrimestrales, CP históricos).
- Sub-canal Stata público automatizado: `net from https://ciep.mx/simuladorfiscal/`
  sirve los 8 paquetes principales sin necesidad de tener acceso al repo.
- `manifest.json` en la raíz del repo declara el Catálogo de datos asociados con
  huellas digitales SHA-256 y URLs de descarga.
- `publicar.sh` publica una versión nueva al endpoint público en un solo comando.
- Governance formal documentada en el directorio `governance/`.
- Convenciones de Git, versionado y publicación formalizadas en `02_governance/versionado-y-git.md`.

### Comandos
- Sin cambios respecto a v7.0. Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`,
  `SHRFSP`, `DatosAbiertos`, `AccesoBIE` mantienen la misma sintaxis y opciones.
- `GastoPC` y `TasasEfectivas` continúan en desarrollo, no publicados oficialmente.

### Datos
- Las fuentes de datos son las mismas que v7.0. La ruptura de v8.0 es institucional
  (reproducibilidad, publicación formal), no metodológica ni de fuentes.

## [v7.0] — 2026-05-23

**Última versión del Simulador como proyecto personal del investigador principal.**
Transición del Simulador desde código operativo con conocimiento metodológico
principalmente tácito hacia infraestructura institucional. El mensaje del tag lo captura:
"Data sidecar publicado (transición v7.x → v8.0)."

### Institucional
- Migración inicial de datos: de URLs personales de Dropbox a assets de GitHub Release v7.0.
- `manifest.json` inicial (23 assets con SHA-256).
- Introducción de `ensure_asset.ado` para descarga verificada de fuentes.
- Rewrite de historia Git para purgar credenciales expuestas y binarios pesados
  (repo: 5.1 GB → 49 MB).
- Externalización del token BIE/INEGI mediante `set_token.do` gitignored + plantilla
  `set_token.template.do` versionada.
- Cierre del canal manual `Stata net/`: los `.ado` viven solo en el root del repo.

### Comandos
- Los comandos `PEF`, `LIF`, `SCN`, `Poblacion`, `PIBDeflactor`, `SHRFSP`, `DatosAbiertos`,
  `AccesoBIE` están disponibles y funcionales.
- Refactor de los `.ado` para usar `ensure_asset` en lugar de URLs hardcoded a Dropbox.

### Datos
- Fuentes: PEFs (2013-2026), CPs, ENIGH (2014-2024), LIFs, CuotasISSSTE,
  ISRInformesTrimestrales.
