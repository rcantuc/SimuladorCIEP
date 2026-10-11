#!/usr/bin/env python3
"""compuertas-entidad.py  v1.0 (global entidad, 2026-10-10) — verifica las compuertas de salida
2–4 del Sankey de entidad sobre los JSON que deja compuertas-entidad.do, y la paridad de los
archivos nacionales con el ancla (informativa aquí; la compuerta 1 formal es
test-maquina-virgen.sh --reproducibilidad). Escribe <evidencia>/compuertas-entidad.md.

  2. Aditividad: Σ de los 32 Sankeys de entidad = Sankey nacional, enlace por enlace en los
     cortes que no re-rankean (grupoedad, sexo, rural, escol) y por familia en quintil vs decil.
  3. Testigo NL: users/<id>/NL/sankey-quintil.json reproduce las participaciones selladas del
     sprint (dis<fam>nle<dec> del statajson_entidad-nl.json: 15 celdas quintil×familia desde el
     JSON y las 90 celdas decil×familia desde nl-dis-nle-recalc.csv).
  4. Segundo estado: cada Sankey de entidad trae n/top1/sello en todos los enlaces micro, la
     banda ENIGH en la entidad de la corrida, y los sellos se activan donde n < umbral.

Uso: compuertas-entidad.py --root <SIMROOT> --id <usuario> --evidencia <dir>
        [--statajson <statajson_entidad-nl.json>] [--testigo <ABREV de la entidad de la corrida>]
        [--tol-add 1e-9] [--tol-testigo 1e-12]
Exit 0 si todas pasan; 1 si alguna falla (el .md dice cuál).
"""
import argparse, hashlib, json, os, re, sys, csv

ABREVS = ("Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL "
          "Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac").split()
CORTES = ["quintil", "grupoedad", "sexo", "rural", "escol"]
FAM1 = ["Imp al trabajo", " Imp al consumo", "  Imp al capital", "   Cuotas IMSS"]
FAM4 = ["Educación", "Salud", "  Pensiones", "   Transferencias", "   Inversión"]
MACRO_FROM = {"IMSS  ISSSTE", "Pemex  CFE", "Costo de la deuda", "Part y otras Aport", "Otros gastos", "Energía"}

def reldif(a, b):
    return abs(a - b) / max(abs(a), abs(b), 1e-300) if (a != 0 or b != 0) else 0.0

def leer_sankey(path):
    """Lee el JSON de FusionCharts (JS con claves sin comillas) -> dict(nodes, links, meta)."""
    s = open(path, encoding="utf-8").read()
    m = re.search(r"const dataSource=(\{.*\});\s*FusionCharts", s, re.S)
    if not m:
        raise ValueError(f"{path}: no se encontró dataSource")
    js = m.group(1)
    js = re.sub(r'([{,\[])\s*([A-Za-z0-9]+)\s*:', r'\1"\2":', js)   # claves -> "clave":
    d = json.loads(js)
    nodes = [n["label"] for n in d["nodes"]]
    links = [{"from": l["from"], "to": l["to"], "value": float(l["value"]),
              **{k: v for k, v in l.items() if k not in ("from", "to", "value")}} for l in d["links"]]
    return {"nodes": nodes, "links": links, "meta": d.get("entidad")}

RESID = {"Endeudamiento", "Ahorro", "Futuro"}

def por_enlace(sk):
    """Enlaces (from, to) -> valor, sin los del residual (se comparan aparte con residual())."""
    out = {}
    for l in sk["links"]:
        if l["from"] in RESID or l["to"] in RESID: continue
        out[(l["from"], l["to"])] = out.get((l["from"], l["to"]), 0.0) + l["value"]
    return out

def residual(sk):
    """Endeudamiento (+) o Ahorro (−) del Sankey."""
    r = 0.0
    for l in sk["links"]:
        if l["to"] == "Endeudamiento": r += l["value"]
        if l["from"] == "Ahorro": r -= l["value"]
    return r

def es_micro(l):
    return l["to"] in FAM1 or l["from"] in FAM4

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True); ap.add_argument("--id", required=True)
    ap.add_argument("--evidencia", required=True); ap.add_argument("--statajson")
    ap.add_argument("--testigo", default="NL"); ap.add_argument("--tol-add", type=float, default=1e-9)
    ap.add_argument("--tol-testigo", type=float, default=1e-12)
    a = ap.parse_args()
    U = os.path.join(a.root, "users", a.id)
    os.makedirs(a.evidencia, exist_ok=True)
    md, fallas = [], []
    def ok(cond, txt):
        md.append(("- ✓ " if cond else "- ✗ ") + txt)
        if not cond: fallas.append(txt)

    md.append("# Compuertas de salida — global entidad (compuertas-entidad.py)\n")

    # ---- Paridad nacional (informativa: con entidad puesta, los archivos nacionales no cambian) ----
    md.append("## 1 (informativa) Archivos nacionales vs ancla, con entidad puesta\n")
    try:
        ancla = json.load(open(os.path.join(a.root, "05_scripts", "ancla-reproducibilidad.json"), encoding="utf-8"))
        sha = lambda f: hashlib.sha256(open(f, "rb").read()).hexdigest()
        for f, h in [("output.txt", ancla["output_txt_sha256"])] + sorted(ancla["sankeys_sha256"].items()):
            p = os.path.join(U, f)
            if os.path.exists(p):
                hh = sha(p); md.append(f"- {'✓' if hh == h else '≠'} {f}: {hh[:16]}… {'= ancla' if hh == h else 'distinto del ancla ' + h[:16] + '… (esperado si la corrida no es la receta canónica desde estado cero)'}")
            else:
                md.append(f"- (no existe {f})")
    except Exception as e:
        md.append(f"- no se pudo leer el ancla: {e}")

    # ---- Cargar nacional y entidades ----
    nac = {c: leer_sankey(os.path.join(U, f"sankey-{c}.json")) for c in ["decil"] + CORTES[1:]}
    ent = {}
    faltan = []
    for ab in ABREVS:
        ent[ab] = {}
        for c in CORTES:
            p = os.path.join(U, ab, f"sankey-{c}.json")
            if os.path.exists(p): ent[ab][c] = leer_sankey(p)
            else: faltan.append(f"{ab}/sankey-{c}.json")
    md.append("\n## 2 Aditividad: Σ 32 entidades = nacional\n")
    ok(not faltan, f"los 160 JSON de entidad existen" + ("" if not faltan else f"; faltan {len(faltan)}: {', '.join(faltan[:8])}"))
    filas = []
    maxrd = 0.0
    for c in CORTES:
        if any(c not in ent[ab] for ab in ABREVS): continue
        if c == "quintil":
            # por familia (eje 2/3) + macro + residual, contra sankey-decil nacional
            n = por_enlace(nac["decil"]); keys = {}
            for (f, t), v in n.items():
                if t in FAM1: keys[("fam", t)] = keys.get(("fam", t), 0) + v
                elif f in FAM4: keys[("fam", f)] = keys.get(("fam", f), 0) + v
                elif f in MACRO_FROM: keys[("macro", f, t)] = keys.get(("macro", f, t), 0) + v
            keys[("residual",)] = residual(nac["decil"])
            s = {k: 0.0 for k in keys}
            for ab in ABREVS:
                e = por_enlace(ent[ab][c])
                for (f, t), v in e.items():
                    if t in FAM1: s[("fam", t)] = s.get(("fam", t), 0) + v
                    elif f in FAM4: s[("fam", f)] = s.get(("fam", f), 0) + v
                    elif f in MACRO_FROM: s[("macro", f, t)] = s.get(("macro", f, t), 0) + v
                s[("residual",)] += residual(ent[ab][c])
        else:
            keys = por_enlace(nac[c]); keys[("residual",)] = residual(nac[c])
            s = {k: 0.0 for k in keys}
            for ab in ABREVS:
                for k, v in por_enlace(ent[ab][c]).items():
                    s[k] = s.get(k, 0.0) + v
                s[("residual",)] += residual(ent[ab][c])
        for k in sorted(keys, key=str):
            rd = reldif(keys[k], s.get(k, 0.0)); maxrd = max(maxrd, rd)
            filas.append((c, " → ".join(str(x) for x in k), keys[k], s.get(k, 0.0), rd))
        extra = [k for k in s if k not in keys and abs(s[k]) > 0]
        ok(not extra, f"{c}: ningún enlace de entidad sin contraparte nacional" + ("" if not extra else f" (sobran {extra[:5]})"))
    with open(os.path.join(a.evidencia, "aditividad.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh); w.writerow(["corte", "enlace", "nacional", "suma_32_entidades", "reldif"])
        for r in filas: w.writerow([r[0], r[1], repr(r[2]), repr(r[3]), f"{r[4]:.3e}"])
    ok(filas and maxrd <= a.tol_add, f"Σ 32 entidades = nacional en {len(filas)} enlaces/familias de 5 cortes (reldif máx {maxrd:.2e}; tol {a.tol_add:.0e}; tabla en aditividad.csv)")
    md.append("\n| corte | enlace | nacional (mdp) | Σ entidades (mdp) | reldif |\n|---|---|---:|---:|---:|")
    for r in filas:
        if r[0] in ("quintil", "sexo"): md.append(f"| {r[0]} | {r[1]} | {r[2]/1e6:,.1f} | {r[3]/1e6:,.1f} | {r[4]:.1e} |")

    # ---- Testigo NL ----
    md.append("\n## 3 Testigo: Nuevo León por quintil estatal vs participaciones selladas del sprint\n")
    T = a.testigo
    if a.statajson and os.path.exists(a.statajson) and "quintil" in ent.get(T, {}):
        sj = json.load(open(a.statajson, encoding="utf-8"))["escalares"]
        dis = {k: float(v["valor"]) for k, v in sj.items() if k.startswith("dis") and "nle" in k and "nleS" not in k}
        dec = "I II III IV V VI VII VIII IX X".split()
        sk = ent[T]["quintil"]; e = por_enlace(sk)
        fammap = {"Imp al trabajo": "AlTrabajo", " Imp al consumo": "AlConsumo", "  Imp al capital": "AlCapital"}
        mx = 0.0; n = 0
        for lab, fam in fammap.items():
            tot = sum(v for (f, t), v in e.items() if t == lab and f in ("I", "II", "III", "IV", "V"))
            for q in range(1, 6):
                v = e.get((["I", "II", "III", "IV", "V"][q-1], lab), 0.0) / tot * 100
                ref = dis[f"dis{fam}nle{dec[2*q-2]}"] + dis[f"dis{fam}nle{dec[2*q-1]}"]
                mx = max(mx, reldif(v, ref)); n += 1
        ok(n == 15 and mx <= a.tol_testigo, f"15 celdas quintil×familia del JSON = Σ pares dis<fam>nle<dec> del statajson (reldif máx {mx:.2e}; tol {a.tol_testigo:.0e})")
        csvp = os.path.join(a.evidencia, "nl-dis-nle-recalc.csv")
        if os.path.exists(csvp):
            mx2 = 0.0; n2 = 0; falt = 0
            for row in csv.DictReader(open(csvp, encoding="utf-8")):
                if row["nombre"] in dis:
                    mx2 = max(mx2, reldif(float(row["share"]), dis[row["nombre"]])); n2 += 1
                else: falt += 1
            ok(n2 == 90 and falt == 0 and mx2 <= 1e-13, f"90 celdas dis<fam>nle<dec> reconstruidas (decil estatal, Households.do §12) = statajson (reldif máx {mx2:.2e}; tol 1e-13; {n2} comparadas)")
        else:
            ok(False, "falta nl-dis-nle-recalc.csv (compuertas-entidad.do)")
        meta = sk["meta"] or {}
        ok(meta.get("corte") == "quintil estatal" and meta.get("clave") == "19", f"meta del JSON: entidad {meta.get('nombre')} clave {meta.get('clave')} corte {meta.get('corte')} vintages {meta.get('vintages')}")
    else:
        ok(False, f"testigo no verificable: statajson={a.statajson} / JSON {T}/sankey-quintil.json")

    # ---- Sellos y banda (segundo estado y todos) ----
    md.append("\n## 4 Sellos de muestra y banda ENIGH (todas las entidades; detalle del segundo estado)\n")
    sinsello = []; resumen = []
    for ab in ABREVS:
        for c, sk in ent[ab].items():
            micro = [l for l in sk["links"] if es_micro(l)]
            falt = [l for l in micro if not all(k in l for k in ("n", "top1", "sello"))]
            if falt: sinsello.append(f"{ab}/{c}")
            act = [l for l in micro if l.get("sello") == "1"]
            resumen.append((ab, c, len(micro), len(act), sum(1 for l in micro if "bmin" in l)))
    ok(not sinsello, "todos los enlaces micro de las 32×5 traen n, top1 y sello" + ("" if not sinsello else f" (faltan en {sinsello[:6]})"))
    conbanda = [r for r in resumen if r[4] > 0]
    ok(any(r[0] == T for r in conbanda) and all(r[0] == T for r in conbanda), f"banda ENIGH (bmin/bmax) solo en la entidad de la corrida ({T}): {sorted({r[0] for r in conbanda})}")
    act_tot = sum(r[3] for r in resumen)
    ok(act_tot > 0, f"los sellos se activan: {act_tot} enlaces micro con sello=1 en las 32 entidades × 5 cortes ({sum(r[2] for r in resumen)} enlaces micro)")
    md.append("\n| entidad | corte | enlaces micro | con sello | con banda |\n|---|---|---:|---:|---:|")
    for r in resumen:
        if r[0] in (T, "Jal") or r[3] > 0 and r[0] in ("Col", "BCS", "Camp", "Tlax", "Nay"): md.append(f"| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4]} |")
    jal = [(c, l) for c, sk in ent.get("Jal", {}).items() for l in sk["links"] if es_micro(l) and l.get("sello") == "1"]
    md.append(f"\nJalisco (segundo estado de humo): {len(jal)} enlaces con sello. Detalle:\n")
    md.append("| corte | de | a | valor (mdp) | n | top1 % |\n|---|---|---|---:|---:|---:|")
    for c, l in jal[:40]:
        md.append(f"| {c} | {l['from'].strip()} | {l['to'].strip()} | {l['value']/1e6:,.1f} | {l.get('n')} | {float(l.get('top1', 'nan')):.1f} |")

    md.append("\n## Veredicto\n")
    md.append("**TODAS EN VERDE**" if not fallas else "**FALLAS:**\n" + "\n".join(f"- {f}" for f in fallas))
    open(os.path.join(a.evidencia, "compuertas-entidad.md"), "w", encoding="utf-8").write("\n".join(md) + "\n")
    print("\n".join(md))
    sys.exit(0 if not fallas else 1)

if __name__ == "__main__":
    main()
