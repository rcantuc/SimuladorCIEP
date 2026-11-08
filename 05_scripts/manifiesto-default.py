#!/usr/bin/env python3
# =============================================================================
# manifiesto-default.py — el manifiesto del escenario default (users/ciepmx/), DERIVADO de lo que el sitio pide
# =============================================================================
# Incidente v8.17.1 (2026-11-08): la Fase 3b-ter de publicar-vps.sh embarcaba users/ricardo/ → users/ciepmx/ con una
# lista escrita a mano (DEFAULT_MANIFEST) que no se actualizó cuando /NTA pasó a dibujar el v4 (v8.17.0): el deploy
# habría subido el sitio sin users/ciepmx/SankeyNTA/sankey-v4-economia.json y /NTA habría abierto con un 404 del
# endpoint. Tercer deploy que una lista a mano deja incompleto (v8.10 css/js, v8.12 manifest.json, v8.17 el v4).
#
# Regla: el manifiesto NO se escribe; se deriva de las páginas y de los endpoints que ellas piden, en un solo lugar
# (este script), y lo leen los dos consumidores:
#   - publicar-vps.sh, Fase 3b-ter (qué archivos de users/ricardo/ viajan a users/ciepmx/) y Gate 5-remoto (que estén);
#   - humo-calcular.sh (tras el swap: GET a cada endpoint del default → 200 con el archivo del manifiesto; rojo → rollback).
# Si una página pide algo nuevo (un corte, una cuenta, un producto), entra aquí solo: no hay lista que olvidar.
#
# Cómo se deriva (cada paso lee el código del sitio, nunca una lista):
#   1. Portada: js/stataCalcula.js pide cargaDefault.php y los jsonSankey*.php (url: '…'); cada uno de esos PHP cae al
#      default users/ciepmx/<archivo> (la ruta literal que trae el PHP) → ese archivo viaja y ese endpoint se prueba.
#   2. /NTA: NTA/index.php pide /jsonSankeyNTA.php?corte=<c> y ?cuenta=<q>; jsonSankeyNTA.php resuelve
#      "%s/SankeyNTA/sankey-{$corte}.json" y "%s/NTA/nta-{$cuenta}.{$ext}" (ext txt para la cuenta de texto): los
#      formatos se leen del PHP, y cada <c>/<q> debe estar en su lista blanca (si no, la página pide algo que el
#      endpoint rechaza: error).
#   3. /entidades: entidades/index.php pide jsonEntidad.php?producto=indice; entidades/_entidad.php (la página de las 32)
#      pide producto=meta|ciclo|tasas|neto y producto=sankey&corte=<los cortes de su selector>; jsonEntidad.php resuelve
#      "%s/entidades.json", "%s/{$abrev}/<archivo>.json" y "%s/{$abrev}/sankey-{$corte}.json". Las 32 abreviaturas se
#      leen de SIMentidad.ado (global entidadesC, sin «Nac»), la única fuente de verdad.
# Lo que ningún endpoint pedido por una página resuelve, NO viaja (p. ej. el v2 y los cortes v1 del Sankey NTA, o
# nta-quinquenio-sexo.json desde v8.17.1: el endpoint los acepta pero /NTA no los pide; a mano responden 404 con pista).
#
# Uso:
#   python3 -I 05_scripts/manifiesto-default.py [--root <repo>] [--archivos | --endpoints | --tsv] [--entidades "NL Jal" | todas]
#     --archivos   una ruta por línea, relativa a users/ricardo/ (= a users/ciepmx/ en el VPS); sin repetir, en orden
#     --endpoints  un endpoint por línea (ruta + query, relativa a la raíz del sitio, sin idSession → default ciepmx)
#     --tsv        (default) archivo <TAB> endpoint <TAB> página que lo pide
#     --entidades  qué entidades incluir: «todas» (default; las 32) o una lista («NL» para el humo: el testigo)
# Sale 0 con el manifiesto en stdout; 2 con el motivo en stderr si el contrato del sitio cambió y este script ya no lo
# sabe leer (entonces se actualiza AQUÍ la derivación, no una lista en otro archivo).
# =============================================================================
import argparse
import os
import re
import sys


def fallo(msg):
    sys.stderr.write("manifiesto-default: %s\n" % msg)
    sys.exit(2)


def leer(ruta):
    try:
        with open(ruta, encoding="utf-8") as f:
            return f.read()
    except OSError as e:
        fallo("no pude leer %s (%s)" % (ruta, e))


def sin_comentarios(texto):
    """Quita las líneas que son solo comentario (// … , # …, * …, /* …) en PHP/JS: una URL de ejemplo en un comentario
    no es una petición de la página."""
    fuera = []
    for linea in texto.splitlines():
        s = linea.strip()
        if s.startswith("//") or s.startswith("#") or s.startswith("*") or s.startswith("/*"):
            continue
        fuera.append(linea)
    return "\n".join(fuera)


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--root", default=None)
    ap.add_argument("--archivos", action="store_true")
    ap.add_argument("--endpoints", action="store_true")
    ap.add_argument("--tsv", action="store_true")
    ap.add_argument("--entidades", default="todas")
    ap.add_argument("-h", "--help", action="store_true")
    a = ap.parse_args()
    if a.help:
        sys.stdout.write(open(__file__, encoding="utf-8").read().split("# ===", 3)[2])
        return 0
    root = a.root or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sitio = os.path.join(root, "04_1_simuladorfiscal.ciep.mx")
    if not os.path.isdir(sitio):
        fallo("no existe %s (¿--root apunta al repo?)" % sitio)

    filas = []  # (archivo, endpoint, origen)

    def agrega(archivo, endpoint, origen):
        filas.append((archivo, endpoint, origen))

    # --- 1. Portada: lo que stataCalcula.js pide y lo que cada PHP lee como default ---------------------------------
    js = sin_comentarios(leer(os.path.join(sitio, "js", "stataCalcula.js")))
    endpoints_portada = []
    for m in re.finditer(r"url:\s*'((?:cargaDefault|jsonSankey[A-Za-z]*)\.php)'", js):
        if m.group(1) not in endpoints_portada:
            endpoints_portada.append(m.group(1))
    if "cargaDefault.php" not in endpoints_portada or len(endpoints_portada) < 2:
        fallo("js/stataCalcula.js ya no pide cargaDefault.php y los jsonSankey*.php con url: '…' (contrato de la portada)")
    for php in endpoints_portada:
        if php == "jsonSankeyNTA.php":
            continue  # lo pide /NTA, no la portada (paso 2)
        texto = sin_comentarios(leer(os.path.join(sitio, php)))
        archivos = []
        for m in re.finditer(r"users/ciepmx/([A-Za-z0-9_./-]+\.(?:json|txt))", texto):
            if m.group(1) not in archivos:
                archivos.append(m.group(1))
        if len(archivos) != 1:
            fallo("%s debería caer a UN archivo users/ciepmx/<archivo> y encontré %s" % (php, archivos or "ninguno"))
        agrega(archivos[0], php, "index.php (js/stataCalcula.js)")

    # --- 2. /NTA: lo que NTA/index.php pide y cómo jsonSankeyNTA.php lo resuelve ------------------------------------
    nta_pag = sin_comentarios(leer(os.path.join(sitio, "NTA", "index.php")))
    nta_php = leer(os.path.join(sitio, "jsonSankeyNTA.php"))
    nta_codigo = sin_comentarios(nta_php)
    m_corte = re.search(r'"%s/([A-Za-z0-9_/-]+)sankey-\{\$corte\}\.json"', nta_codigo)
    m_cuenta = re.search(r'"%s/([A-Za-z0-9_/-]+)nta-\{\$cuenta\}\.\{\$ext\}"', nta_codigo)
    m_ext = re.search(r"\$ext\s*=\s*\(\$cuenta\s*===\s*'([a-z0-9-]+)'\)\s*\?\s*'(txt|json)'\s*:\s*'(txt|json)'", nta_codigo)
    if not (m_corte and m_cuenta and m_ext):
        fallo("jsonSankeyNTA.php cambió sus rutas (sprintf %s/SankeyNTA/sankey-{$corte}.json, %s/NTA/nta-{$cuenta}.{$ext}, $ext): actualiza la derivación")

    def lista_php(texto, nombre):
        m = re.search(r"\$" + nombre + r"\s*=\s*array\(([^)]*)\)", texto)
        if not m:
            fallo("no encontré $%s = array(...) en jsonSankeyNTA.php" % nombre)
        return re.findall(r"'([A-Za-z0-9_-]+)'", m.group(1))

    cortes_validos = lista_php(nta_codigo, "cortes_validos")
    cuentas_validas = lista_php(nta_codigo, "cuentas_validas")
    pedidos = []
    for m in re.finditer(r"/jsonSankeyNTA\.php\?(corte|cuenta)=([a-z0-9-]+)", nta_pag):
        par = (m.group(1), m.group(2))
        if par not in pedidos:
            pedidos.append(par)
    if not pedidos:
        fallo("NTA/index.php ya no pide /jsonSankeyNTA.php?corte=… ni ?cuenta=… (contrato de /NTA)")
    for clave, valor in pedidos:
        if clave == "corte":
            if valor not in cortes_validos:
                fallo("/NTA pide corte=%s y jsonSankeyNTA.php no lo admite (%s)" % (valor, "|".join(cortes_validos)))
            agrega("%ssankey-%s.json" % (m_corte.group(1), valor), "jsonSankeyNTA.php?corte=%s" % valor, "NTA/index.php")
        else:
            if valor not in cuentas_validas:
                fallo("/NTA pide cuenta=%s y jsonSankeyNTA.php no la admite (%s)" % (valor, "|".join(cuentas_validas)))
            ext = m_ext.group(2) if valor == m_ext.group(1) else m_ext.group(3)
            agrega("%snta-%s.%s" % (m_cuenta.group(1), valor, ext), "jsonSankeyNTA.php?cuenta=%s" % valor, "NTA/index.php")

    # --- 3. /entidades: el índice y la página de las 32 ------------------------------------------------------------
    ent_php = sin_comentarios(leer(os.path.join(sitio, "jsonEntidad.php")))
    ent_idx = sin_comentarios(leer(os.path.join(sitio, "entidades", "index.php")))
    ent_pag = sin_comentarios(leer(os.path.join(sitio, "entidades", "_entidad.php")))
    m_indice = re.search(r"'%s/([A-Za-z0-9_.-]+\.json)'", ent_php)
    rutas_prod = dict(re.findall(r"\$producto === '([a-z]+)'\)\s*\{\s*list\(\$ruta, \$rel\) = ent_ruta\(\$base_path, \$idSession, \"%s/\{\$abrev\}/([A-Za-z0-9_.-]+\.json)\"", ent_php))
    m_sankey = re.search(r'"%s/\{\$abrev\}/([A-Za-z0-9_-]*)sankey-\{\$corte\}\.json"', ent_php)
    if not (m_indice and rutas_prod and m_sankey):
        fallo("jsonEntidad.php cambió sus rutas (ent_ruta con %s/entidades.json, %s/{$abrev}/<producto>.json, sankey-{$corte}.json): actualiza la derivación")
    productos_validos = lista_php(ent_php, "productos_validos")
    cortes_ent_validos = lista_php(ent_php, "cortes_validos")
    if not re.search(r"jsonEntidad\.php\?producto=indice", ent_idx):
        fallo("entidades/index.php ya no pide jsonEntidad.php?producto=indice")
    m_urls = re.search(r"'urls'\s*=>\s*array\(([^)]*)\)", ent_pag)
    m_cortes = re.search(r"\$cortes\s*=\s*array\((.*?)\);", ent_pag, re.S)
    if not (m_urls and m_cortes):
        fallo("entidades/_entidad.php ya no declara 'urls' => array(…) y $cortes = array(…) (contrato de la página de entidad)")
    productos_pag = re.findall(r"\$ep\s*\.\s*'([a-z]+)(?:&corte=)?'", m_urls.group(1))
    cortes_pag = re.findall(r"^\s*'([a-z]+)'\s*=>", m_cortes.group(1), re.M)
    if not productos_pag or not cortes_pag:
        fallo("entidades/_entidad.php: no pude leer los productos ('urls') o los cortes ($cortes) que pide")
    for p in productos_pag:
        if p not in productos_validos:
            fallo("/entidades/<ABREV> pide producto=%s y jsonEntidad.php no lo admite (%s)" % (p, "|".join(productos_validos)))
    for c in cortes_pag:
        if c not in cortes_ent_validos:
            fallo("/entidades/<ABREV> pide corte=%s y jsonEntidad.php no lo admite (%s)" % (c, "|".join(cortes_ent_validos)))
    ado = leer(os.path.join(root, "SIMentidad.ado"))
    m_cat = re.search(r'^\s*global entidadesC "([^"]*)"', ado, re.M)
    if not m_cat:
        fallo("SIMentidad.ado: no encontré global entidadesC (el catálogo de las 32)")
    catalogo = [x for x in m_cat.group(1).split() if x != "Nac"]
    if len(catalogo) != 32:
        fallo("SIMentidad.ado trae %d entidades en entidadesC (sin Nac); esperaba 32" % len(catalogo))
    if a.entidades.strip().lower() == "todas":
        entidades = catalogo
    else:
        entidades = a.entidades.split()
        for e in entidades:
            if e not in catalogo:
                fallo("--entidades: %s no está en el catálogo de SIMentidad.ado" % e)
    agrega(m_indice.group(1), "jsonEntidad.php?producto=indice", "entidades/index.php")
    for ab in entidades:
        for p in productos_pag:
            if p == "sankey":
                for c in cortes_pag:
                    agrega("%s/%ssankey-%s.json" % (ab, m_sankey.group(1), c), "jsonEntidad.php?abrev=%s&producto=sankey&corte=%s" % (ab, c), "entidades/%s (_entidad.php)" % ab)
            else:
                if p not in rutas_prod:
                    fallo("jsonEntidad.php no resuelve producto=%s a un archivo" % p)
                agrega("%s/%s" % (ab, rutas_prod[p]), "jsonEntidad.php?abrev=%s&producto=%s" % (ab, p), "entidades/%s (_entidad.php)" % ab)

    # --- salida -----------------------------------------------------------------------------------------------------
    out = sys.stdout
    if a.archivos:
        vistos = []
        for f, _, _ in filas:
            if f not in vistos:
                vistos.append(f)
        out.write("".join(x + "\n" for x in vistos))
    elif a.endpoints:
        vistos = []
        for _, e, _ in filas:
            if e not in vistos:
                vistos.append(e)
        out.write("".join(x + "\n" for x in vistos))
    else:
        out.write("".join("%s\t%s\t%s\n" % fila for fila in filas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
