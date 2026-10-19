# El cronómetro del «Calcular» dice la verdad (v8.12.2, 2026-10-19)

Solo front-end: `js/config-tiempos.js` (nuevo), `js/stataCalcula{,-en}.js`, `index{,-en}.php`. Ni motor ni números.
Evidencia cruda (capturas antes/después, series del reloj a 1 Hz, tiempos de Stata): `~/CIEP_Simuladores/diag-v8.12.2-cronometro-2026-10-19/`.

## 1. Inventario de controles (ES = EN; `index.php` / `index-en.php`)

| Control | Handler JS | Endpoint | ¿Lanza Stata? | Cuenta regresiva ANTES (literal) | Ahora |
|---|---|---|---|---|---|
| «Calcular» principal `#isrSub` (index.php:2080 / en:2092) | `$('#isrSub,.isrSub').click` (stataCalcula.js:1440) | `logCalcular.php` (bitácora) + `calculaStata.php` (**síncrono**) + 5 × `jsonSankey*.php` al terminar | **sí** (el único punto que lo lanza) | **35**: `index.php:3924` (`startCountdown(35)`), `stataCalcula.js:1664` (`$('#count').text(35)`) y `30` en `index.php:800` (HTML) | `CIEP_TIEMPOS[flujo]` |
| «Calcular» de los modales ISR-1 (3167), cuotas IMSS (3337), ISR-2 (3377) | el mismo handler (clase `.isrSub`) | el mismo POST, con `moduloCambio=1` si se tocó algo del submódulo | **sí** — corre además `ISR_Mod.do` (Web.Stata.do §3.1.6) | **35** × 3: `index.php:3925-3927` | `isr` |
| «Calcular» del modal IVA (3546) | el mismo handler | el mismo POST, con `moduloCambioIva=1` | **sí** — corre además `IVA_Mod.do` (§3.1.7) | **35**: `index.php:3928` | `iva` |
| (cualquiera de los anteriores con ambos flags) | ídem | ídem | **sí** — ambos submódulos | 35 | `isr_iva` |
| «Reestablecer» `#btn-reestablecer` (820, 2074) | `location.href = 'index.php'` (stataCalcula.js:254) | recarga: `cargaDefault.php` (lee el `output.txt` default) | **no** | — | — |
| «Reestablecer» `#reset-pib` (2041) | parpadeo CSS (index.php:3652) | ninguno | **no** | — | — |
| `.btn-percapita`, `.btn-tasa`, `.btn-macro` (±) | cuentas locales (stataCalcula.js:295/327/359) | ninguno | **no** | — | — |
| Toggle 2027 / Simulación `.btn-toggle` | `updateChartsWithData` (stataCalcula.js:~100-190) | re-pide `jsonSankey*.php` (lee JSON ya escrito) | **no** | — | — |
| Carga de la página | `$(document).ready` | `cargaDefault.php` + `jsonSankey*.php` (sesión `ciepmx`) | **no** | — | — |

Los controles que no lanzan Stata no tenían cuenta regresiva: **no hay nada que retirar** (FLAG vacío). El de «Calcular» es un solo handler: lo que cambia entre flujos es qué flags manda (`moduloCambio`, `moduloCambioIva`), y por eso el reloj se elige con `CIEPCronometro.flujo()` leyendo esos mismos campos. Antes los cuatro mostraban 35 s aunque el principal tarda ~20 s y los submódulos ~30–40 s.

## 2. Medición por flujo (Stata real, `Web.Stata.do` con el escenario default, 3 corridas por flujo)

Harness: `correr-web.sh` (misma mecánica que `perfilar-web.sh`: `.do` generado con los mismos campos que arma el JS; `moduloCambio`/`moduloCambioIva` según el flujo), StataNow 19.5 SE en la Mac, con el cache de v8.12.

| Flujo | Corridas locales (s) | Media local | Escala a VPS (×1.15) | + 25 % | Constante |
|---|---|---:|---:|---:|---:|
| `principal` | 18.5 / 16.9 / 16.6 | 17.3 | 20.0 | 25.0 | **25** |
| `isr` | 27.0 / 27.5 / 26.8 | 27.1 | 31.3 | 39.1 | **40** |
| `iva` | 25.1 / 25.4 / 24.5 | 25.0 | 28.9 | 36.1 | **40** |
| `isr_iva` | 34.1 / 34.2 / 34.6 | 34.3 | 39.6 | 49.5 | **50** |

Factor local→VPS = 20 s (principal medido en el VPS desde v8.12.0) / 17.3 s (media local de hoy; la primera corrida es en frío) = **1.15**. ISR_Mod.do suma ≈ 10 s locales y IVA_Mod.do ≈ 8 s; son aditivos (34.3 ≈ 17.3 + 10 + 7). Constante = ceil a múltiplo de 5 s de (VPS estimado × 1.25).

**Límite honesto:** los tiempos de VPS de `isr`, `iva` e `isr_iva` son **escalados**, no medidos; el factor se calibró con el principal. El «Calcular» de humo de `publicar-vps.sh` (Fase 6) mide y reporta el principal en el VPS en cada deploy; medir los submódulos allí (`moduloCambio=1`) queda como siguiente paso (FLAG). Si el VPS resultara más lento que el escalado, el reloj no miente: pasa a «Finalizando…».

## 3. Honestidad del reloj

La cuenta es cosmética; el fin lo dicta la respuesta del POST (`complete`), no el reloj (el JS no consulta `checkStataStatus.php`: el POST a `calculaStata.php` es síncrono — ver FLAG del runbook §12):

- Termina antes → los resultados aparecen y el reloj se corta de inmediato (run de 2 s: aviso apagado a los 2.58 s, igual que antes).
- Tarda más que la cuenta → el número se reemplaza por **«Finalizando…» / «Finishing…»** (spinner sin cifra) hasta que llegue la respuesta. Antes se quedaba en «1s» (run de 39 s: «Calculando… 1s» de los 36 a los 39 s).
- Éxito o error → `complete` apaga el aviso. **Corrige un defecto latente:** el aviso solo se apagaba en la rama de éxito; ante un error (p. ej. el 429 del rate-limit de v8.11c) quedaba encendido tras el `alert`. Los mensajes del 429 se siguen mostrando igual (ES/EN, `Retry-After`).

## 4. Verificación visual (Chrome headless, `php -S` + Stata falso, 8 s)

| Captura | Resultado |
|---|---|
| «calculando», desktop/móvil × ES/EN (4) | misma pantalla; solo cambia el número del reloj (caja de diferencias de 14 × 21 px; 32 s → 22 s a los 3 s) |
| «resultados», desktop ES/EN | **0 px** de diferencia |
| «resultados», móvil ES/EN | 302 px en etiquetas truncadas del Sankey (FusionCharts); el piso de ruido de esa captura es mayor: dos corridas de la **misma** versión difieren en ~10 900 px |
| «finalizando» (run de 32 s, cuenta de 25 s) | «Finalizando…» sin cifra desde los 25 s, hasta que llega la respuesta |

Valor inicial del reloj por flujo (S2): principal 25, isr 40, iva 40, isr+iva 50 (antes: 35 en los cuatro).

## 5. Dónde se ajusta, y el candado

Un solo lugar: `04_1_simuladorfiscal.ciep.mx/js/config-tiempos.js` → `CIEP_TIEMPOS = { principal, isr, iva, isr_iva }`. Candado: `bash 05_scripts/verify_cronometro_unico.sh` (en CI, job `sitio-autocontenido`) falla si reaparece un literal de segundos (`startCountdown`, `#count … N`, `id="count">N`) fuera de ese archivo o si una página carga `stataCalcula*.js` sin `config-tiempos.js` antes. `js/pages/session.js` (`var sec = 10`, contador de inactividad) no es del «Calcular» y no se carga en ninguna página.
