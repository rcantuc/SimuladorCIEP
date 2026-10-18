# 02_governance/perf — Perfiles de rendimiento del flujo web

Reportes fechados de **medición** del tiempo de respuesta del Simulador en la web (`calculaStata.php` → `Web.Stata.do`). Cada reporte dice dónde se va el tiempo, qué es invariante al escenario y qué no, y propone metas; **no decide ni implementa optimizaciones** (eso es decisión de Ricardo y va al `CHANGELOG.md` cuando se publica).

| Reporte | Base medida | Resultado |
|---|---|---|
| `perfil-web-2026-10-18.md` (+ `-resumen-generado.md`) | `ffca008` (v8.11.0), local StataNow 19.5 | 31.5–35 s por «Calcular»; FiscalGap 40 % (PEF histórico 26 %), GastoPC 25 %, Sankey 15 %, Simulador 15 %; I/O 4 % local; ≈ 12 s invariantes precacheables |

Instrumento: `05_scripts/perfilar-web.sh` (+ `perfilar-web.py`). Reproduce la invocación del sitio con el escenario default, corre N veces con hooks de tiempo en una copia del `.do` (el motor no se toca), comprueba que `output.txt` queda byte-idéntico al baseline sin hooks y escribe `resumen.md`. La evidencia cruda vive en `users/_perf/<fecha>/` del clon medido (no se versiona).
