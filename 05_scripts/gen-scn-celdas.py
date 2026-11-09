#!/usr/bin/env python3
"""gen-scn-celdas.py — genera 02_governance/scn-celdas.md (inventario de celdas del SCN que lee el motor). Solo lectura.

Uso:
  python3 05_scripts/gen-scn-celdas.py [--datos <clon -datos>] [--salida <ruta.md>] [--check]

Fuentes (nada se redacta a mano fuera de este archivo):
  - 05_scripts/manifest.json: scn_vintage (anio_referencia = anclas; bie.<serie>.variable / etiqueta / ultimo_congelado =
    marco del Paquete; consulta; series_congeladas; asset).
  - SIM.do: scalar anioenigh (debe coincidir con anio_referencia) y scalar anioPE (el año del marco).
  - <datos>/master/SCN.dta, fila anio_referencia: los valores de las celdas (bn).
  - USO (abajo): consumidores por escalar (grep scalar() en 01_modulos/*.do y *.ado).
  - VINTAGE_V815B_PRE (abajo): el registro histórico de la capa que el documento describe «como estaba en v8.15b-pre»
    (fechas de los csv del 16-oct-2026 y sha de master/SCN.dta del 28-oct): es un hecho fechado, no se recalcula de -datos.

Distinción anclas / marco (CUAD-0 §4 bis; FLAG de 8.18a-2): las anclas (tablas A y B, PIB) se leen en anioenigh =
scn_vintage.anio_referencia; el marco del Paquete (SCN, anio(anioPE)) parte del último año congelado del asset
(scn_vintage.bie.<serie>.ultimo_congelado, hoy «2025 p1»). El generador toma los tres valores de sus fuentes y aborta si
anioenigh (SIM.do) != anio_referencia (manifest). Regenerar con --check debe dar 0 diferencias contra el archivo del repo.
"""
import argparse, json, os, re, sys
import pandas as pd

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ap = argparse.ArgumentParser()
ap.add_argument('--datos', default=os.path.expanduser('~/CIEP_Simuladores/SimuladorCIEP-datos'))
ap.add_argument('--salida', default=os.path.join(REPO, '02_governance', 'scn-celdas.md'))
ap.add_argument('--check', action='store_true', help='no escribe: compara con --salida y sale 1 si difiere')
a = ap.parse_args()

man = json.load(open(os.path.join(REPO, '05_scripts', 'manifest.json'), encoding='utf-8'))
sv = man['scn_vintage']
ANCLA = int(sv['anio_referencia'])                                   # año de las anclas (= anioenigh)
sim = open(os.path.join(REPO, 'SIM.do'), encoding='utf-8').read()
anioenigh = int(re.search(r'scalar anioenigh\s*=\s*(\d{4})', sim).group(1))
ANIOPE = int(re.search(r'scalar anioPE\s*=\s*(\d{4})', sim).group(1))  # año del marco del Paquete
if anioenigh != ANCLA:
    sys.exit(f'gen-scn-celdas: anioenigh de SIM.do ({anioenigh}) != scn_vintage.anio_referencia ({ANCLA})')
bie = sv['bie']
ULTIMO = bie['724025']['ultimo_congelado']                          # último año congelado del asset (marco)
NSERIES = int(sv['series_congeladas'])
CONSULTA = sv['consulta'][:10]
ASSET = sv['asset']
assert all(bie[s]['ultimo_congelado'] == ULTIMO for s in bie), 'series con distinto último año congelado'

scn = pd.read_stata(os.path.join(a.datos, 'master', 'SCN.dta'), convert_categoricals=False)
r = scn[scn.anio == ANCLA].iloc[0]
def v(col):
    try:
        x = float(r[col]); return '' if x != x else f'{x/1e9:,.3f}'
    except Exception:
        return 'n/a'

# --- Registro histórico de la capa descrita «como estaba en v8.15b-pre» (fechado; no se recalcula) ---
VINTAGE_V815B_PRE = {
    'scn_dta': ('2026-10-28 20:49', '3bdc3a0215a3'),
    'csv_rango': ('2026-10-16 00:34', '2026-10-16 00:48'),
    'csi_fecha': '2026-10-16 00:48',
    'csi_sha': 'CSI_103 `c28d560709f5`, CSI_115 `f0e9fecfd9f8`, CSI_106 `b498099f959d`, CSI_109 `230c609766cf`, CSI_112 `3b981612648c`, CSI_118 `9bf053f965f0`',
}
def csv_date(s):
    s = int(s)
    if s in (725116, 725126, 725130): return '2026-10-16 00:48'
    if s in (780054, 780055, 780065): return '2026-10-16 00:45'
    if s in (780103, 780104, 780105, 780108): return '2026-10-16 00:46'
    if s == 780135: return '2026-10-16 00:47'
    if 724014 <= s <= 724018: return '2026-10-16 00:34'
    if s <= 724030: return '2026-10-16 00:35'
    if s <= 724629: return '2026-10-16 00:36'
    return '2026-10-16 00:37'

# --- Consumidores por escalar (grep scalar() en 01_modulos/*.do y los .ado; v8.15.3) ---
USO = {
 'PIB': 'Households §1.1 (PIBSCN), Expenditure, NTA, ISR_Mod, PerfilesSim, TasasEfectivas (pibY), escalar PIB de todo el motor',
 'RemSalSS': 'SCN B.1 (Yl, ImpNetProduccionL); TasasEfectivas (RemSalSSPIB)', 'RemSal': 'Households §1.1/§9 (TaltimirSal), PerfilesSim, TasasEfectivas',
 'SSEmpleadores': 'Households §1.1/§9, TasasEfectivas', 'Imp': 'SCN (ImpuestosNetos)', 'ImpProductos': 'SCN B.5 → ImpNetProductos (Households §9, l. 2420-2427)',
 'ImpProduccion': 'SCN B.5 → ImpNetProduccion → ImpNetProduccionL/K (Households §9, §12)', 'Sub': 'SCN (ImpuestosNetos)',
 'ExBOp': 'SCN B.3 → ExNOpSoc residuo (Households §9 TaltimirCap; PerfilesSim)',
 'ImpNet': 'Households §9 Altimir (ImpNetProductos_*), NTA §4.3, PerfilesSim', 'ImpProd': 'SCN cuadre', 'SubProd': 'SCN B.5 → ImpNetProductos',
 'ProdT': 'SCN cuenta A', 'ConsInt': 'SCN cuenta A',
 'CapFij': 'Households §11.3 (ConCapFij: depreciación ∝ ing_capital), NTA (YA neto), SCN B/C', 'PIN': 'PerfilesSim, SCN C',
 'ROWRemR': 'SCN C.6 → ROWRem (Households §12 ing_suborROW; Sankey.do)', 'ROWRemP': 'ídem', 'ROWPropR': 'SCN C.6 → ROWProp (Households ing_capitalROW; Sankey.do)', 'ROWPropP': 'ídem',
 'ROWTransR': 'SCN C.6 → ROWTrans (Households §9 TaltimirROWTrans: remesas; Sankey.do)', 'ROWTransP': 'ídem',
 'ConHog': 'Expenditure (ancla ConHog), PerfilesSim, TasasEfectivas (ConHogPIB), SCN D', 'GastPrivT': 'SCN D', 'ComprasN': 'Households (gasto_anualComprasN), NTA (Cpriv), Sankey.do, SCN D',
 'ConGob': 'Households (gasto_anualGobierno), NTA (colectivo), Sankey.do, SCN D',
 'ConsPriv_21': 'TasasEfectivas (ConsPriv21PIB: IEPS petrolero)',
 'ConsPriv_54': 'Households §1.2 l. 249 (local sin uso desde v8.15b: sin partición pf/PM, firma B.7)',
 'ConsPriv_62': 'Households §1.2 l. 250 (local sin uso desde v8.15b: sin partición pf/PM, firma B.7)',
 'Prof541_T': 'Households §1.2 (ServProf)', 'Salud6211': 'Households §1.2 (ConsMedi)', 'Salud6212': 'Households §1.2 (ConsDent)', 'Salud6213': 'Households §1.2 (ConsOtro)',
 'Salud6216': 'Households §1.2 (EnfeDomi)', 'Inmob5311': 'Households §1.2 l. 252 (local sin uso desde v8.15b: sin partición pf/PM, firma B.7)', 'Inmob5312': 'Households §1.2 (SNAInmobiliarias)',
 'Recre7132': 'TasasEfectivas (Recre7132PIB: IEPS juegos)',
 'AlojT': 'Expenditure (TT); Households §1.2 l. 255 lo lee en un local sin uso desde v8.15b (la partición pf/PM murió con la firma B.7)',
}
ANCLAS_TT = ('Alim','BebN','BebA','Taba','Vest','Calz','Alqu','CRep','Agua','Elec','HogaT','SaluT','Vehi','FTra','STra','ComuT','RecrT','EducT','RestT','DiveT')
def uso(n):
    if n in USO: return USO[n]
    if n in ANCLAS_TT: return f'Expenditure.do (ancla TT{n}); ' + ('TasasEfectivas ' + n + 'PIB' if n in ('Vehi','BebA','Taba') else 'SCN R.6')
    return 'SCN.ado (escalar mxn/pctpib; sin consumidor fuera de SCN)'

bloques = [(724014, 724025, '§1.1 Generación del ingreso / GenIng.dta'), (723651, 723672, '§2.1 Producción bruta / ProdBru.dta'), (724026, 724037, '§3.1 Ingreso nacional disponible / IngNacDis.dta'),
           (724600, 724656, '§4.1 Consumo de hogares e ISFLSH / ConHog.dta'), (724771, 724777, '§5.1 Consumo privado / GastPriv.dta'), (724959, 724980, '§6.1 Consumo de gobierno / GovCons.dta'),
           (779804, 780174, '§7 PIB por actividad / PIBAE1-5.dta'), (725114, 725135, '§8.1 Consumo privado por actividad / SecExt.dta')]
def bloque(s):
    s = int(s)
    for lo, hi, n in bloques:
        if lo <= s <= hi: return n
    return '?'
A_SERIES = ['724014','724015','724016','724017','724018','724022','724023','724024','724025','723652','723656','723657','723658','723663','724028','724029','724030','724031','724032','724033','724034','724035'] \
         + [str(s) for s in range(724600, 724657)] + ['724771','724777','724959','725116','725126','725130'] \
         + [s for s, d in bie.items() if d['variable'] in ('Prof541_T','Salud6211','Salud6212','Salud6213','Salud6216','Inmob5311','Inmob5312','Recre7132')]

sd, ss = VINTAGE_V815B_PRE['scn_dta']; c0, c1 = VINTAGE_V815B_PRE['csv_rango']
md = []
md.append('# Celdas del SCN que lee el motor — inventario (v8.15b-pre, 2026-10-31)')
md.append('')
md.append(f'Insumo de la política de fuente SCN de CUAD-0 §4 bis (canal BIE por API; congelado en `raw/`; refresco deliberado). Es el inventario que `05_scripts/refrescar-scn.sh --comparar` recorre. **Estado al {CONSULTA} (v8.15.2, PR de datos `datos/scn-congelado-{ANCLA}`): las {NSERIES} series completas (con «{ULTIMO}» etiquetado preliminar) y los 7 cuadros CSI son asset del manifest** (`raw/SCN/{ASSET}`, `scn_vintage`, año de referencia {ANCLA}). `UpdateSCN` lee solo el asset y el motor usa la serie como siempre. **Anclas y marco:** las anclas (tablas A y B de este inventario, PIB del año ENIGH) se leen en `anioenigh`; **el marco {ANIOPE} (`SCN, anio(aniovp)` en `SIM.do` §2.5, `SCN, anio(anioPE)` en `PerfilesSim.do` §4) parte del último año congelado**: el pastcast de `SCN` §1.2 proyecta {ANIOPE-1}–{ANIOPE} desde la última observación del asset (hoy «{ULTIMO}», preliminar, etiquetada en `scn_vintage.bie.<serie>.ultimo_congelado`), no desde `anioenigh`. Un refresco del asset que cambie «{ULTIMO}» (revisión o cifra definitiva) mueve el marco {ANIOPE} y, con él, `output.txt` (INCD/INCD3/PROY), no los sankeys ni las anclas: es un PR de datos con Δ declarado. El párrafo que sigue describe cómo estaba en v8.15b-pre. Lo que el motor lee es `master/SCN.dta`, construido por `SCN.ado` (`UpdateSCN`) a partir de (i) {NSERIES} series del BIE descargadas por `AccesoBIE.ado` (copia exacta en `raw/temp/AccesoBIE/<serie>.csv`) y (ii) los tabulados de cuentas por sector institucional `raw/temp/SCN/CSI_*.xlsx` (zip de INEGI). Ninguno registra etiqueta preliminar/revisada; el vintage es la fecha del archivo. Clon de referencia: `-datos` (`ee410a3`, v8.14.0). Valores {ANCLA} en miles de millones de MXN (bn) tal como están en `master/SCN.dta`.')
md.append('')
md.append('| Capa | Archivo | Vintage que registra el motor | sha256 |')
md.append('|---|---|---|---|')
md.append(f'| Base que lee el motor | `master/SCN.dta` | archivo del {sd} (sin etiqueta INEGI) | `{ss}` |')
md.append(f'| Descargas BIE (API) | `raw/temp/AccesoBIE/<serie>.csv` ×{NSERIES} nacionales | archivos del {c0} al {c1}; `periodo,valor`; sin LASTUPDATE ni OBS_NOTE guardados | por serie (ver `refrescar-scn.sh`) |')
md.append(f'| Tabulados CSI (zip INEGI, no API) | `raw/temp/SCN/CSI_103/106/109/112/115/118.xlsx` | archivos del {VINTAGE_V815B_PRE["csi_fecha"]}; INEGI «{ANCLA} revisada» (CONC-1) | {VINTAGE_V815B_PRE["csi_sha"]} |')
md.append('')
md.append(f'**Estado v8.15b (E4, 2026-10-31):** `refrescar-scn.sh --congelar` escribe los assets en `raw/SCN/` (`bie/<serie>.csv` con los años ≤ `anioenigh`; `CSI_1xx.xlsx`) y los registra en `05_scripts/manifest.json: scn_vintage` (sha256, fecha de consulta, etiqueta INEGI del último dato, vía por serie; por cuadro CSI sha256 y las celdas del inventario con su valor). `SCN.ado` (`SCNCongelado`: `UpdateSCN` y `SCNHogaresS14`) y `AccesoBIE.ado` los verifican y los leen sin tocar la red (sello **verde**); sin asset, descargan y lo declaran (sello **amarillo**); un sha distinto aborta (candado). Las 33 filas CSI (tabla B) se congelan desde los `.xlsx` del zip con cuadro, fila y columna exacta: **canal CSI** (el BIE no las tiene como serie). `raw/SCN/` no se versiona (como todo `raw/`): `--congelar` lo empaqueta en `raw/SCN/{ASSET}`, declarado en `assets` del manifest con `desde: v8.15.0` (`publicar.sh` lo sube al publicar esa versión; su Gate 8 no lo exige en Releases anteriores; `SCNCongelado` lo descarga y desempaca con `ensure_asset` cuando faltan los archivos). El vintage BIE vs CSI sigue (PIB {v("PIB")} vs B.1b 33,582.899; CCF {v("CapFij")} vs 6,458.352) y desde v8.15b se **declara** como fila «Vintage BIE−CSI» de la identidad de sectores (`output.txt: CUADRATURA`).')
md.append('')
md.append('## A. Series BIE que llegan a un escalar que algún módulo lee')
md.append('')
md.append('Serie = clave del indicador en el BIE (`AccesoBIE <serie>`); variable = nombre en `SCN.ado`; archivo = `.dta` intermedio de `UpdateSCN` que se fusiona en `master/SCN.dta`. Consumidores según `grep scalar()` en `01_modulos/*.do` y los `.ado` (2026-10-31).')
md.append('')
md.append(f'| Serie BIE | Variable | Etiqueta INEGI (SCN.ado) | Bloque / archivo intermedio | {ANCLA} (bn) | Quién la consume | Vintage (csv) |')
md.append('|---|---|---|---|---:|---|---|')
for s in A_SERIES:
    d = bie[s]
    md.append(f"| {s} | `{d['variable']}` | {d['etiqueta']} | {bloque(s)} | {v(d['variable'])} | {uso(d['variable'])} | {csv_date(s)} |")
md.append('')
md.append(f'{len(A_SERIES)} series de {NSERIES} descargadas llegan a un escalar con consumidor. Las {NSERIES-len(A_SERIES)} restantes (PIB por actividad §7, consumo de gobierno por rama §6, consumo privado por rama §8, agregados de producción §2) viven en `master/SCN.dta` sin consumidor fuera de `SCN.ado`, pero el pastcast de `SCN` §1.2 las proyecta a todas y `UpdateSCN` las fusiona en la misma base: por eso desde v8.15.2 (PR de datos `datos/scn-congelado-{ANCLA}`, {CONSULTA}) **las {NSERIES} están congeladas completas** (`refrescar-scn.sh --congelar --todas`; `scn_vintage.series_congeladas = {NSERIES}`; los periodos posteriores a `anioenigh` van con su etiqueta INEGI en `posteriores_a_referencia`), `UpdateSCN` lee solo el asset (sin asset aborta; con `rawwip` declara lo bajado en caliente, sello amarillo).')
md.append('')
md.append('## B. Celdas de los tabulados CSI (no están en la API del BIE): canal CSI')
md.append('')
md.append(f'`UpdateSCN` §9-§25b y `SCNHogaresS14` leen filas de `raw/temp/SCN/CSI_<cuadro>.xlsx` (zip `tabulados_CSI.zip`, INEGI SCNM base 2018; desde v8.15b copiadas del asset congelado `raw/SCN/CSI_<cuadro>.xlsx` cuando existe). Columnas: pares (U/A, R/P) por año desde 2003 en B; {ANCLA} = AR (U/A) y AS (R/P). **El BIE no tiene estas celdas como serie**: se dicen con cuadro, fila y columna, y no se sustituyen. v8.15b añade a `SCNHogaresS14` (sesión v8.15b, E1/E3): CSI_115 f.71 D.1 R/P (`D1HogS14`, ancla de `ing_subor`), f.103 D.442 R/P (`D442Hog`), f.150 D.752 R/P (`RemesasHogS14`), f.114 D.5 U/A (`ImpIngHog`), f.139 D.7 R/P y U/A (`OtrasTransfHogR/U`); CSI_106/109/112/118 f.110 B.5n U/A (`B5nNoFin`, `B5nFin`, `B5nGob`, `B5nISFLSH`); CSI_112 f.80 D.2 R/P, f.89 D.3 R/P, f.95 D.4 R/P y U/A (gobierno); CSI_121 f.71 D.1 U/A y f.95 D.4 U/A y R/P (resto del mundo); CSI_103 f.27 B.1b, f.28 P.51c y f.110 B.5n U/A (economía total). 8.17.2 (CUAD-3 §4.0) añade CSI_115 f.99 D.422 R/P (`D422Hog`, retiros de cuasisociedades: celda de `ing_mixto` con `ing_mixto_ancla = b3n_d422`, fuera de la de D.4).')
md.append('')
md.append(f'| Cuadro (sector) | Fila | Columna | Variable | Código SCN | {ANCLA} (bn) | Quién la consume |')
md.append('|---|---:|---|---|---|---:|---|')
B = [('CSI_103 (S.1 economía total)', 60, 'U/A', 'IngMixto', 'B.3b ingreso mixto bruto', 'IngMixto', 'SCN B.1 → MixN, MixL (⅔), MixK, MixKN: Households §9 (TaltimirSelf), PerfilesSim, TasasEfectivas (MixLPIB)'),
     ('CSI_103', 41, 'U/A', 'SSImputada', 'D.122 contribuciones sociales imputadas', 'SSImputada', 'SCN B (RemSal = RemSalSS − SSEmpleadores − SSImputada); Households §1.1/§9; TasasEfectivas'),
     ('CSI_103', 54, 'U/A', 'SubProductos', 'D.31 subsidios a los productos', 'SubProductos', 'SCN (ImpNetProductos usa SubProd del BIE; SubProductos CSI queda en SCN.dta)'),
     ('CSI_103', 58, 'U/A', 'SubProduccion', 'D.39 otros subsidios a la producción', 'SubProduccion', 'SCN B.5 → ImpNetProduccion (Households §9/§12)'),
     ('CSI_103', 62, 'U/A', 'DepMix', 'P.51c consumo de capital fijo del ingreso mixto', 'DepMix', 'SCN B.1 (MixN, MixK, MixKN); Households §1.1 (local DepMix)'),
     ('CSI_106 (S.11)', 59, 'U/A', 'ExBOpNoFin', 'B.2b excedente bruto, sociedades no financieras', 'ExBOpNoFin', 'SCN.dta (informativo; ExNOpSoc se calcula como residuo)'),
     ('CSI_109 (S.12)', 59, 'U/A', 'ExBOpFin', 'B.2b sociedades financieras', 'ExBOpFin', 'ídem'),
     ('CSI_118 (S.15)', 59, 'U/A', 'ExBOpISFLSH', 'B.2b ISFLSH', 'ExBOpISFLSH', 'ídem'),
     ('CSI_115 (S.14)', 59, 'U/A', 'ExBOpHog', 'B.2b excedente bruto, hogares', 'ExBOpHog', 'Households §1.2 l. 254 (local sin uso desde v8.15b); es la cifra del paso 0 de v8.15b (FLAG 18, CUAD-0 §10 bis 7)'),
     ('CSI_112 (S.13)', 59, 'U/A', 'ExBOpGob', 'B.2b gobierno', 'ExBOpGob', 'SCN.dta (informativo)'),
     ('CSI_106', 63, 'U/A', 'ExNOpNoFin', 'B.2n', 'ExNOpNoFin', 'SCN.dta (informativo)'), ('CSI_109', 63, 'U/A', 'ExNOpFin', 'B.2n', 'ExNOpFin', 'ídem'), ('CSI_118', 63, 'U/A', 'ExNOpISFLSH', 'B.2n', 'ExNOpISFLSH', 'ídem'),
     ('CSI_115', 63, 'U/A', 'ExNOpHog', 'B.2n excedente neto, hogares (alquiler imputado)', 'ExNOpHog', 'SCN B.3/B.4 (ExNOpSoc residuo, Capital); Households §9 (TaltimirHouse), §12'),
     ('CSI_112', 63, 'U/A', 'ExNOpGob', f'B.2n gobierno (0 en {ANCLA})', 'ExNOpGob', 'SCN B.3/B.4; Households §1.1'),
     ('CSI_103', 170, 'U/A', 'AhorroB', 'B.8b ahorro bruto, economía total', 'AhorroB', 'SCN.dta (informativo; AhorroN se calcula como residuo)'),
     ('CSI_103', 152, 'U/A', 'IngDisp', 'B.6b ingreso disponible bruto', 'IngDisp', 'SCN.dta (informativo; IngDispCalc se calcula)'),
     ('CSI_115', 170, 'U/A', 'AhorroHogB', 'B.8b ahorro bruto hogares', 'AhorroHogB', 'NTA (escalar AhorroHogB)'),
     ('CSI_115', 171, 'U/A', 'AhorroHogN', 'B.8n ahorro neto hogares', 'AhorroHogN', 'NTA (AhorroHog: ancla de S)'),
     ('CSI_115', 166, 'U/A', 'ConHogS14', 'P.3 gasto de consumo final hogares', 'ConHogS14', 'NTA (ConHogS14_P3)'),
     ('CSI_115', 176, 'U/A', 'ConEfecHogS14', 'P.4 consumo final efectivo', 'ConEfecHogS14', 'NTA (TransfEspecie = P.4 − P.3)'),
     ('CSI_115', 117, 'U/A', 'ContribSocHog', 'D.61 contribuciones sociales netas', 'ContribSocHog', 'NTA (CuotasHogS14 = D.61 − D.614)'),
     ('CSI_115', 127, 'U/A', 'ContribComplHog', 'D.614 contribuciones complementarias', 'ContribComplHog', 'ídem'),
     ('CSI_103', 25, 'R/P', 'ImpProductosS1', 'D.21 impuestos sobre los productos', 'ImpProductosS1', 'NTA (ImpNetosProd = D.21 − D.31)'),
     ('CSI_103', 26, 'R/P', 'SubProductosS1', 'D.31 subsidios a los productos (signo del tabulado)', 'SubProductosS1', 'ídem'),
     ('CSI_115', 169, 'R/P', 'AjustePensHog', 'D.8 ajuste por derechos de pensión', 'AjustePensHog', 'NTA (YA_d8)'),
     ('CSI_115', 131, 'R/P', 'PrestSocHog', 'D.62 prestaciones sociales en dinero', 'PrestSocHog', 'NTA (TauPubS14)'),
     ('CSI_115', 151, 'R/P', 'OtrasTransfHog', 'D.759 otras transferencias corrientes', 'OtrasTransfHog', 'NTA (TauPubS14)'),
     ('CSI_115', 69, 'R/P', 'ExNOpHogS14', 'B.2n', 'ExNOpHogS14', 'NTA (YAHogS14); Households §9 con yk_ancla = b2n_b3n_d4'),
     ('CSI_115', 70, 'R/P', 'MixNHogS14', 'B.3n ingreso mixto neto hogares', 'MixNHogS14', 'NTA (YAHogS14: ⅓)'),
     ('CSI_115', 95, 'R/P − U/A', 'RentaPropHogR − RentaPropHogU', 'D.4 renta de la propiedad neta', 'RentaPropHogR', 'NTA (YAHogS14; RentaPropHogNeta); Households §9 con yk_ancla = b2n_b3n_d4'),
     ('CSI_115', 157, 'R/P', '(verificación)', 'D.63 transferencias sociales en especie = P.4 − P.3', None, 'SCNHogaresS14 (FLAG si no cuadra)')]
for cu, fila, col, var, cod, colscn, u in B:
    val = v(colscn) if colscn else ''
    if var.startswith('RentaPropHogR'): val = f'{(float(r.RentaPropHogR)-float(r.RentaPropHogU))/1e9:,.3f} (R {v("RentaPropHogR")}, U {v("RentaPropHogU")})'
    md.append(f'| {cu} | {fila} | {col} | `{var}` | {cod} | {val} | {u} |')
md.append('')
md.append('## C. Escalares derivados (fórmula en `SCN.ado`) y de qué celdas dependen')
md.append('')
md.append(f'| Escalar | Fórmula (SCN.ado) | Celdas | {ANCLA} (bn) | Quién lo consume |')
md.append('|---|---|---|---:|---|')
C = [('RemSal', 'RemSal_BIE − SSImputada', '724015, CSI_103 f.41', v('RemSal'), 'Households §1.1/§9 (TaltimirSal), PerfilesSim, TasasEfectivas'),
     ('MixN / MixL / MixK / MixKN', 'IngMixto − DepMix; ⅔ MixN; ⅓ MixN + DepMix; MixK − DepMix', 'CSI_103 f.60, f.62', f'{v("MixL")} (MixL) / {v("MixKN")} (MixKN)', 'Households §9 (TaltimirSelf), TasasEfectivas, PerfilesSim'),
     ('ExNOpSoc', '(ExBOp − CapFij) − MixN − ExNOpHog − ExNOpGob (residuo)', '724024, 724028, CSI_103 f.60/62, CSI_115 f.63, CSI_112 f.63', v('ExNOpSoc'), 'Households §9 (TaltimirCap), PerfilesSim'),
     ('Capital', 'ExNOpSoc + MixKN + ExNOpHog + ExNOpGob', 'ídem', v('Capital'), 'SCN B.4'),
     ('ImpNetProduccion', 'ImpProduccion + SubProduccion', '724022, CSI_103 f.58', v('ImpNetProduccion'), 'SCN B.5'),
     ('ImpNetProduccionL', 'ImpNetProduccion × (RemSalSS + MixL)/(RemSalSS + MixL + Capital)', '724014, 724022, …', v('ImpNetProduccionL'), 'Households §9/§12, PerfilesSim, TasasEfectivas'),
     ('ImpNetProduccionK', 'ImpNetProduccion − ImpNetProduccionL + DiscEstPIB', '…', v('ImpNetProduccionK'), 'Households §9/§12'),
     ('ImpNetProductos', 'ImpProductos − SubProd', '724018, 723658', v('ImpNetProductos'), 'Households §9/§12 (ImpNetProductos_*)'),
     ('Yl', 'RemSalSS + MixL + ImpNetProduccionL', '724014, CSI_103, 724022', v('Yl'), 'PerfilesSim, TasasEfectivas (YlPIB)'),
     ('CapIncImp', 'Capital + ImpNetProduccionK + ImpNet', '…, 723656', v('CapIncImp'), 'TasasEfectivas (CapIncImpPIB)'),
     ('ROWRem / ROWProp / ROWTrans', 'recibidas − pagadas', '724030-724035', f'{v("ROWRem")} / {v("ROWProp")} / {v("ROWTrans")}', 'Households §9/§12, Sankey.do'),
     ('IngDispCalc, AhorroN', 'PIN + ROW + CapFij; − ConHog − ConGob − ComprasN', '724029, 724030-35, 724028, 724600, 724959, 724777', f'{v("IngDispCalc")} / {v("AhorroN")}', 'SCN C/D, Sankey.do (AhorroN)'),
     ('YAHogS14', 'ExNOpHogS14 + MixNHogS14/3 + RentaPropHogR − RentaPropHogU', 'CSI_115 f.69, 70, 95', v('YAHogS14'), 'NTA (nta_YA = S14)'),
     ('CuotasHogS14, ImpNetosProdS1, TauPubS14', 'D.61 − D.614; D.21 − |D.31|; D.62 + D.759', 'CSI_115 f.117/127; CSI_103 f.25/26; CSI_115 f.131/151', f'{v("CuotasHogS14")} / {v("ImpNetosProdS1")} / {(float(r.PrestSocHog)+float(r.OtrasTransfHog))/1e9:,.3f}', 'NTA')]
for e in C: md.append(f'| `{e[0]}` | {e[1]} | {e[2]} | {e[3]} | {e[4]} |')
md.append('')
md.append('## D. Lo que no está en el BIE o viene de otra tabla')
md.append('')
md.append('- **Ingreso mixto, consumo de capital fijo del mixto, contribuciones imputadas, subsidios por tipo, excedente por sector, ahorro e ingreso disponible brutos (tabla B, filas CSI_103/106/109/112/118):** no son series del BIE; el motor los toma del zip `tabulados_CSI.zip` (SCNM base 2018, cuentas por sector institucional). Clave exacta = cuadro + fila + columna (par U/A o R/P del año). `refrescar-scn.sh --csi` compara el sha256 de cada cuadro y las filas del inventario.')
md.append('- **Sector hogares S.14 completo (CSI_115):** las anclas de `NTA.do` (B.8n, P.3, P.4, D.61, D.614, D.8, D.62, D.759, B.2n, B.3n, D.4) y las dos celdas que `yk_ancla = b2n_b3n_d4` usa. Mismo canal.')
md.append('- **Población** (`master/Poblaciontot.dta`, CONAPO) se fusiona en `master/SCN.dta` pero no es SCN: la gobierna `Poblacion.ado` y el asset `Poblacion_Estimada_Mitad_Anio.zip`.')
md.append('- **`escalar pctpib` de LIF/PEF** (ISRASPIB, …) no son SCN: salen de `LIF.ado`/`PEF.ado` (assets `LIFs.xlsx`, `CP *.xlsx`).')
md.append('')
md.append('## E. Cómo se refresca')
md.append('')
md.append('1. `bash 05_scripts/refrescar-scn.sh --comparar [--csi]` desde el clon con `set_token.do` (API oficial; si no responde, consulta pública de exportación del BIE, declarada por serie; los sufijos del periodo «p1»/«r1» son la etiqueta preliminar/revisada): compara hasta el año de referencia (`scalar anioenigh` de `SIM.do`; `--anio` lo sobreescribe; los años posteriores se listan como «fuera del año de referencia»), e imprime y guarda (en `--salida`, nunca en `raw/`) celda, valor congelado, valor BIE, Δ, Δ % del PIB, etiqueta INEGI (`OBS_STATUS`/`OBS_NOTE` del último dato, `LASTUPDATE` de la serie) y fecha de consulta; exit 0 sin revisión, 1 con diferencias, 3 no comparado.')
md.append('2. Con diferencias: PR de datos (runbook-actualizar-assets.md) con el reporte adjunto; `data_updated` y CHANGELOG declaran el Δ. `bash 05_scripts/refrescar-scn.sh --congelar [--todas]` (v8.15b) escribe los assets en `raw/SCN/` y el registro `scn_vintage` del manifest.')
md.append('3. `SIM.do` y los `.ado` nunca llaman a este script: el motor lee `master/SCN.dta`; cuando falta (o con `global update`), `UpdateSCN` reconstruye desde los assets congelados de `raw/SCN/` (`SCNCongelado` los copia a `raw/temp/`), y solo descarga en caliente las series sin asset, declarándolo (sello amarillo).')
md.append('')
md.append(f'*Generado con `05_scripts/gen-scn-celdas.py` a partir de `manifest.json: scn_vintage` (anclas en `anio_referencia` = `anioenigh` {ANCLA}; marco del Paquete {ANIOPE} desde `ultimo_congelado` = «{ULTIMO}»), `SCN.ado`, el grep de consumidores y la fila {ANCLA} de `-datos/master/SCN.dta`; `--check` compara con el archivo del repo (0 diferencias = regenerable). Antes (v8.15b-pre) vivía en `diag-v8.15b-pre-2026-10-31/gen-scn-celdas.py` y el archivo se editaba a mano.*')
texto = '\n'.join(md) + '\n'

if a.check:
    actual = open(a.salida, encoding='utf-8').read()
    if actual == texto:
        print(f'gen-scn-celdas --check: {os.path.relpath(a.salida, REPO)} es regenerable (0 diferencias; {len(md)} líneas; {len(A_SERIES)} series en A)'); sys.exit(0)
    import difflib
    sys.stdout.writelines(difflib.unified_diff(actual.splitlines(True), texto.splitlines(True), 'repo', 'regenerado'))
    sys.exit(1)
open(a.salida, 'w', encoding='utf-8').write(texto)
print(a.salida, len(md), 'líneas;', len(A_SERIES), 'series en A')
