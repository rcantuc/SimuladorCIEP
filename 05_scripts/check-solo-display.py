#!/usr/bin/env python3
"""check-solo-display.py — verificación mecánica de la sesión log-legible: el diff contra una referencia solo toca impresión.

Uso: python3 05_scripts/check-solo-display.py [--ref master] archivo...
Para cada archivo compara la versión de la referencia (git show) con la del árbol, uniendo las continuaciones `///` en enunciados
lógicos, y clasifica cada enunciado quitado o añadido (comentarios y líneas en blanco fuera):
  · impresión: display/di, noisily _log, _tabla_anclas, printf, simci, `local` de texto para _log (lg_*, cuadro_titulo, ifdesc, lgo,
    nn, nl, sepest), `capture log on|off`, `run`/`do` del driver del nodo, `timer list`, `syntax` de simci;
  · declaradas (prefijo/opción de impresión sobre un comando de cálculo; se listan aparte): `noisily xi: probit` → `xi: probit`,
    `noisily tabstat …` → `quietly tabstat … save` en Expenditure.do §3.4;
  · cálculo: todo lo demás cuyo primer comando sea gen, replace, collapse, merge, save, scalar, escalar, matrix, drop, keep, sort,
    reshape, append, use, predict, Distribucion, etc.
Exit 0 si ninguna línea de cálculo cambió (las declaradas se imprimen, no fallan); 1 si alguna cambió.
"""
import re, subprocess, sys, difflib
ref = 'master'; args = sys.argv[1:]
if args and args[0] == '--ref': ref = args[1]; args = args[2:]
def join(text):
    out=[]; buf=''
    for l in text.split('\n'):
        s=l.rstrip()
        if s.endswith('///'):
            buf += s[:-3].rstrip()+' '
        else:
            out.append((buf+s).strip()); buf=''
    if buf: out.append(buf.strip())
    res=[]
    for x in out:
        x=re.sub(r'\s+//(?!/).*$', '', x).strip()          # comentario de cola (// …) fuera: solo cambia la documentación
        if x and not x.startswith('*') and not x.startswith('//'): res.append(x)
    return res
# nta-identidad.txt es un producto de texto del log (no un JSON ni un .dta): sus `file write` son impresión
IDENT = re.compile(r'^(?:file write `fh\' (?:"(?:Cuadro|Nota|NTA |`raya)|%-\d+s|_n)|local raya = |local lab : label grupoedad|forvalues g = 1/5 \{|if "\$cuotas_por_sector" == "on" & "\$nta_cuotas" == "S14" (?:\{|file write))')
PRINT = re.compile(r'^(?:(?:noisily|noi|quietly|qui|capture|cap)\s+)*(?:_log\b|_tabla_anclas\b|di\b|display\b|dis\b|printf\b|simci\b|local (?:lg_|cuadro_titulo|ifdesc|lgo|nn |nl |sepest)|capture log (?:on|off)\b|timer list\b|if .*\b(?:_log|di)\b|else .*\b(?:_log|di)\b|foreach k of local deciles \{|foreach p of global LOG_PARAM_FLAGS \{|\}$)')
DECLARADAS = [('noisily xi: probit', 'xi: probit'), ('noisily tabstat', 'quietly tabstat'), ('noisily tabstat', 'tabstat'), ('noisily do `"${SIMROOT}/01_modulos/nodos/nodo-deuda.do"\'', 'noisily run `"${SIMROOT}/01_modulos/nodos/nodo-deuda.do"\'')]
SIMCI_SYNTAX = 'syntax varname [if], [POINT(real -1e300) LABel(string) COL(integer 40) FMT(string)'
total=0; impresion=0; declaradas=[]; calculo=[]
for f in args:
    old = subprocess.run(['git','show',f'{ref}:{f}'], capture_output=True, text=True, encoding='utf-8').stdout
    new = open(f, encoding='utf-8').read()
    a, b = join(old), join(new)
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal': continue
        for s in a[i1:i2]:
            total += 1
            if PRINT.match(s) or IDENT.match(s) or s.startswith(SIMCI_SYNTAX) or 'SCN_CONGELADO_RES' in s or s.startswith(('res = (f"', 'f"{sv.get')) or f.endswith('_tabla_anclas.ado'): impresion += 1; continue
            if any(s.startswith(d[0]) for d in DECLARADAS): declaradas.append((f,'-',s)); continue
            calculo.append((f,'-',s))
        for s in b[j1:j2]:
            total += 1
            if PRINT.match(s) or IDENT.match(s) or s.startswith(SIMCI_SYNTAX) or 'SCN_CONGELADO_RES' in s or 'SCN_CONGELADO_DET' in s or s.startswith('res = f"') or f.endswith('_tabla_anclas.ado'): impresion += 1; continue
            if any(s.startswith(d[1]) for d in DECLARADAS): declaradas.append((f,'+',s)); continue
            calculo.append((f,'+',s))
print(f'check-solo-display vs {ref}: {total} enunciados cambiados; {impresion} de impresión; {len(declaradas)} declarados (prefijo/opción de impresión sobre un comando); {len(calculo)} de cálculo')
for f,s,b in declaradas: print(f'  declarado {s} {f}: {b[:140]}')
for f,s,b in calculo: print(f'  CALCULO   {s} {f}: {b[:160]}')
sys.exit(1 if calculo else 0)
