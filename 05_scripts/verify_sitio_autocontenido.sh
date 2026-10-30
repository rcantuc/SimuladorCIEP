#!/usr/bin/env bash
# verify_sitio_autocontenido.sh — el sitio (04_1_simuladorfiscal.ciep.mx/) es auto-contenido
# desde un checkout fresco: la misma regla que el Gate 7 de publicar-vps.sh (líneas "Sitio
# auto-contenido"), aquí sin VPS ni credenciales, para correr en CI y en cualquier clon.
#
# Incidente que lo motiva (deploy v8.10, 2026-10-16): se desplegó desde un worktree cuyo 04_1
# solo tenía lo copiado a mano; el sitio salió sin css/, js/ ni plugins/ con el health check
# verde. Desde v8.11a el sitio vive completo en git, así que "qué debe haber en el docroot" es
# `git ls-files 04_1/`. Tres comprobaciones:
#   1. Todo archivo versionado bajo 04_1/ existe en el árbol de trabajo (checkout completo).
#   2. Ningún FANTASMA: archivo presente en 04_1/ que git no versiona y que el rsync de la
#      Fase 2 de publicar-vps.sh subiría (mismas exclusiones que allá: .DS_Store,
#      DEPLOYED_COMMIT, calcular_clicks.log, ssl/, logs/, sesiones 0*/).
#   3. Todo activo LOCAL que index.php / index-en.php referencian (src=, href=, url() en css)
#      existe y está versionado — es la forma estática del incidente: un enlace a un archivo
#      que no viaja en git. Más la lista de activos de humo de publicar-vps.sh (SITE_SMOKE_ASSETS).
#
# Uso: bash 05_scripts/verify_sitio_autocontenido.sh      Exit 0 si pasa; 1 si no.
set -uo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
[[ -z "$REPO_ROOT" ]] && { echo "No se pudo detectar root del repo Git." >&2; exit 1; }
cd "$REPO_ROOT" || exit 1
SITE_REL="04_1_simuladorfiscal.ciep.mx"
fallos=0

# -c core.quotePath=false: sin ella git escapa los nombres no ASCII ("Educaci\303\263n_2025.png")
tracked="$(git -c core.quotePath=false ls-files -- "$SITE_REL")"
[[ -n "$tracked" ]] || { echo "FALLO: git no versiona nada bajo $SITE_REL/ (¿checkout anterior a v8.11a?)"; exit 1; }
n_tracked="$(printf '%s\n' "$tracked" | wc -l | tr -d ' ')"

# 1. versionado => presente
faltan=()
while IFS= read -r f; do [[ -f "$f" ]] || faltan+=("$f"); done <<< "$tracked"
if (( ${#faltan[@]} > 0 )); then
    echo "FALLO 1: ${#faltan[@]} archivo(s) versionado(s) del sitio NO existen en el árbol de trabajo:"
    printf '        %s\n' "${faltan[@]:0:10}"; (( ${#faltan[@]} > 10 )) && echo "        … y $(( ${#faltan[@]} - 10 )) más"
    echo "        Restaura con: git checkout -- $SITE_REL"
    fallos=$((fallos+1))
else
    echo "OK 1: los $n_tracked archivos versionados del sitio existen en el árbol de trabajo."
fi

# 2. presente y subible => versionado (sin fantasmas). --exclude-per-directory=.gitignore: solo
#    cuentan las reglas versionadas, no .git/info/exclude ni el gitignore global de la máquina.
fantasmas="$(git -c core.quotePath=false ls-files --others --exclude-per-directory=.gitignore -- "$SITE_REL" \
    | grep -vE '(^|/)(\.DS_Store|DEPLOYED_COMMIT|calcular_clicks\.log)$|/(ssl|logs)/|/0[^/]*/' || true)"
if [[ -n "$fantasmas" ]]; then
    echo "FALLO 2: archivo(s) en el docroot que el deploy subiría pero git NO versiona (fantasmas):"
    printf '%s\n' "$fantasmas" | head -10 | sed 's/^/        /'
    echo "        Agrégalos a git (git add <archivo>, explícito) o, si son runtime, al .gitignore y a las exclusiones de la Fase 2 de publicar-vps.sh."
    fallos=$((fallos+1))
else
    echo "OK 2: ningún fantasma en $SITE_REL/."
fi

# 3. referenciado localmente => existe y versionado
# (el python va a un archivo temporal y no dentro de $( ): el bash 3.2 de macOS se confunde con los paréntesis de las regex)
refs="$(mktemp -t sitio-refs-XXXXXX)"
python3 - "$SITE_REL" > "$refs" <<'PYEOF'
import re, sys, os
site = sys.argv[1]
out = set()
def local(u):
    u = u.strip().split('#')[0].split('?')[0]
    if not u or u.startswith(('http://', 'https://', '//', 'data:', 'mailto:', 'tel:', 'javascript:', '#', '{', '<', '$')):
        return None
    return u
for php in ('index.php', 'index-en.php'):
    t = open(os.path.join(site, php), encoding='utf-8', errors='replace').read()
    t = re.sub(r'<!--.*?-->', '', t, flags=re.S)          # markup comentado: el navegador no lo parsea ni lo pide
    for m in re.finditer(r'<(?:script|link|img|source)\b[^>]*?\s(?:src|href)\s*=\s*["\']([^"\']+)["\']', t, re.I):
        u = local(m.group(1))
        if u and re.search(r'\.(css|js|png|jpe?g|gif|svg|ico|webp|woff2?|ttf|json)$', u, re.I):
            out.add((php, os.path.normpath(os.path.join(site, u))))
for root, _, files in os.walk(os.path.join(site, 'css')):
    for f in files:
        if not f.endswith('.css'): continue
        p = os.path.join(root, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        for m in re.finditer(r'url\(\s*["\']?([^"\')]+)["\']?\s*\)', t):
            u = local(m.group(1))
            if u:
                out.add((os.path.relpath(p, site), os.path.normpath(os.path.join(root, u))))
for src, path in sorted(out):
    print(f"{src}\t{path}")
PYEOF
# Referencias rotas CONOCIDAS (toleradas con nota, decisión pendiente de Ricardo): 05_scripts/sitio-referencias-rotas-conocidas.txt
CONOCIDAS="05_scripts/sitio-referencias-rotas-conocidas.txt"
n_refs=0; rotos=(); toleradas=(); avisos=()
while IFS=$'\t' read -r src path; do
    [[ -z "$path" ]] && continue
    n_refs=$((n_refs+1))
    motivo=""
    if [[ ! -f "$path" ]]; then motivo="no existe"
    elif ! git -c core.quotePath=false ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then motivo="existe pero NO está en git: fantasma"
    fi
    [[ -z "$motivo" ]] && continue
    if [[ "$src" == css/* ]]; then
        avisos+=("$src -> $path ($motivo)")          # url() de hojas del template: la clase puede no usarse; informativo
    elif [[ -f "$CONOCIDAS" ]] && grep -qF "$src	$path" "$CONOCIDAS"; then
        toleradas+=("$src -> $path ($motivo)")
    else
        rotos+=("$src -> $path ($motivo)")
    fi
done < "$refs"
rm -f "$refs"
if (( ${#rotos[@]} > 0 )); then
    echo "FALLO 3: ${#rotos[@]} activo(s) local(es) referenciado(s) por index.php/index-en.php no existen o no están versionados:"
    printf '        %s\n' "${rotos[@]:0:15}"; (( ${#rotos[@]} > 15 )) && echo "        … y $(( ${#rotos[@]} - 15 )) más"
    echo "        (si es una rotura conocida y decidida, anótala en $CONOCIDAS)"
    fallos=$((fallos+1))
else
    echo "OK 3: los $n_refs activos locales que referencian index.php, index-en.php y css/ existen y están en git (salvo los tolerados abajo)."
fi
# (${arr[@]+"${arr[@]}"}: con set -u, un array vacío truena en bash < 4.4 — el 3.2 de macOS)
for x in ${toleradas[@]+"${toleradas[@]}"}; do echo "  TOLERADA (decisión pendiente, ver $CONOCIDAS): $x"; done
for x in ${avisos[@]+"${avisos[@]}"}; do echo "  AVISO (url() de css, no bloquea): $x"; done

# activos de humo (copia de SITE_SMOKE_ASSETS de publicar-vps.sh: si se renombra uno, se actualiza allá y aquí;
# una entrada sin extensión es una ruta servida por <entrada>/index.php, p. ej. NTA → /NTA)
humo=(css/custom.css css/admin2.css js/stataCalcula.js js/config-tiempos.js js/connect.js plugins/bootstrap/css/bootstrap.min.css
      plugins/font-awesome/css/all.min.css plugins/jquery/jquery-3.4.1.min.js plugins/apexcharts/dist/apexcharts.min.js
      images/ciep-logo1.png images/TE_Trabajo.png favicon.ico cargaDefault.php jsonSankey.php NTA
      entidades entidades/NL entidades/Jal entidades/Col)
hf=()
for a in "${humo[@]}"; do [[ -f "$SITE_REL/$a" || -f "$SITE_REL/$a/index.php" ]] || hf+=("$a"); done
if (( ${#hf[@]} > 0 )); then
    echo "FALLO 4: activo(s) de humo ausente(s): ${hf[*]} (si se renombró, actualiza SITE_SMOKE_ASSETS en publicar-vps.sh y aquí)"
    fallos=$((fallos+1))
else
    echo "OK 4: ${#humo[@]} activos de humo presentes."
fi

if (( fallos == 0 )); then echo "RESULTADO: sitio auto-contenido ($n_tracked archivos versionados)."; exit 0; fi
echo "RESULTADO: $fallos comprobación(es) fallida(s) — un deploy desde este árbol subiría un sitio incompleto o con fantasmas."
exit 1
