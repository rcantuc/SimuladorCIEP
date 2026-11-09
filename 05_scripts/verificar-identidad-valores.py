#!/usr/bin/env python3
"""verificar-identidad-valores.py — dos nta-identidad.txt dicen los mismos números aunque cambie la forma (sesión log-legible).

Uso: python3 05_scripts/verificar-identidad-valores.py <anterior> <nuevo>
Extrae todos los números de cada archivo (con separador de miles, signo, decimales, notación e) y compara los CONJUNTOS de valores
tal como están escritos (misma precisión): un número que esté en uno y no en el otro es una diferencia. Las repeticiones no cuentan
(el cuadro 2 partido en 2a/2b/2c repite la columna Pob). También compara los conjuntos de rótulos de gate («GATE …») y de cuadros.
Exit 0 si los conjuntos de números coinciden; 1 si no (imprime los que sobran y los que faltan).
"""
import re, sys
a, b = sys.argv[1], sys.argv[2]
num = re.compile(r'(?<![\w.])[-−]?\d[\d,]*(?:\.\d+)?(?:e[-+]\d+)?(?![\w])')
def nums(p):
    t = open(p, encoding='utf-8').read().replace('−', '-')
    s = set()
    for m in num.finditer(t):
        v = m.group(0)
        if re.fullmatch(r'\d{1,2}', v) or re.fullmatch(r'\d\.\d{1,2}', v): continue   # índices de nota, «2a», «1e-9» en textos y numeración
        s.add(v)
    return s
def lineas(p, pre):
    return {l.strip() for l in open(p, encoding='utf-8') if l.startswith(pre)}
A, B = nums(a), nums(b)
solo_a, solo_b = sorted(A - B), sorted(B - A)
print(f'números distintos escritos: anterior {len(A)}, nuevo {len(B)}; comunes {len(A & B)}; solo en el anterior {len(solo_a)}; solo en el nuevo {len(solo_b)}')
for v in solo_a[:40]: print(f'  solo anterior: {v}')
for v in solo_b[:40]: print(f'  solo nuevo:    {v}')
ga, gb = lineas(a, 'GATE'), lineas(b, 'GATE')
print(f'líneas GATE: anterior {len(ga)}, nuevo {len(gb)}')
sys.exit(0 if not solo_a and not solo_b else 1)
