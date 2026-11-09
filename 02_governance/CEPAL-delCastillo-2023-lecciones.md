> **Procedencia (sesión del ritual v8.17.2, 2026-11-09).** Este es el **adjunto original** de Ricardo (lectura de Claude, 2026-11-08), que la sesión CUAD-3 no tuvo a mano: la transcripción de las cuatro decisiones que ocupó esta ruta en PR #71 y #72 queda sustituida por el texto que sigue, tal cual. Las cuatro decisiones de §5 fueron firmadas por Ricardo en PR #71 (CUAD-3 §4.0); lo que la transcripción decía de más (lecciones con página, diferencias del motor) vive en CUAD-3 §4.4, §8 y §10 bis.

# Del Castillo Negrete (CEPAL, 2023), *La distribución del ingreso y la riqueza* — lo que le sirve al Simulador

*Lectura de Claude, 2026-11-08, del documento LC/TS.2023/44 (606 pp.). Capítulos leídos: III (de la generación de valor a la acumulación), IV.B–I (ENIGH, equivalencias con el SCN, ajuste, truncamiento), I.C (conclusiones). Páginas del PDF.*

## 1. Mismo espíritu, misma arquitectura

Del Castillo sigue la **secuencia de cuentas del SCN por sector institucional** (producción → asignación primaria → distribución secundaria → uso → acumulación → balance) y la lleva a las personas con la ENIGH homologada 1984–2020: es el principio A del Simulador («SCN = totales; ENIGH = distribución») con veinte años más de serie. México es su caso de estudio con la CSI base 2013. La diferencia de alcance es la que Ricardo señala: él llega a la cuenta de capital y al balance (riqueza, B.90); el Simulador se detiene en el ahorro (v10).

## 2. Lo que confirma decisiones ya firmadas

| Decisión del Simulador | Del Castillo | Dónde |
|---|---|---|
| Una celda SCN por variable ENIGH (principio C) | Cuadro 69: equivalencias clave por clave (X001–X036) con D.1, B.3b, D.41/D.421/D.443/D.451, D.62/D.75 | p. 233 |
| D.442 fuera de la renta de la propiedad (`cuotas_d614 = neto`) | Compara la ENIGH con D.41 + D.421 + D.443 + D.451, **no** con D.44 completo | p. 232 |
| ISR de personas anclado a D.51 S.14 (`isr_personas_ancla = d51_s14`) | Imputa el ISR con tablas LISR sobre base gravable y lo compara con D.51 S.14; la diferencia es evasión | p. 241 |
| Predial y tenencia como D.59, fuera del consumo | Imputa D.59 S.14 (tenencia, predial) ∝ ingreso | p. 242 |
| Herencias, loterías y premios fuera del ingreso corriente (`cap4 fuera`) | Resta X040 de las transferencias | p. 233 |
| Renta de la propiedad y transferencias repartidas solo entre quienes declaran, proporcional | Regla explícita (c) del ajuste | p. 239 |
| La ENIGH no está truncada; el problema es subreporte | Prueba con las UPM de Miguel Hidalgo y el SINCO vs Censo: «los dos extremos están adecuadamente representados» | pp. 268–273 |

## 3. Lo que cambia o cierra algo abierto

### 3.1 FLAG 18 — rentas efectivas de hogares: del Castillo las pone en B.2b, y el +221 bn lo confirma
Cuadro 69 asigna **X017 «Alquiler de casas, edificios e inmuebles»** al grupo «renta de la propiedad + B.2b», y el texto (p. 232) dice que el B.2b de S.14 «incluye la renta de los inmuebles, más la renta imputada de las viviendas que las familias ocupan». Es la lectura SNA 2008 §24.55 (la alternativa `rentas_celda = b2n` que Devin midió), no la de §7.9 + INEGI p. 45 que firmamos. La prueba empírica del paso 0 de 8.15b (B.2b S.14 2,107.6 vs alquiler imputado CSVM 1,886.4 = **+221 bn**) coincide con esta lectura: el excedente de hogares de INEGI trae las rentas efectivas. **Propuesta:** cerrar FLAG 18 con `rentas_celda = b2n`: X017 (cap3 rentas) ancla con el alquiler imputado a B.2n; B.3n queda para negocios y honorarios. Mueve números (anclas de Households) → `baseline` nuevo; citar del Castillo p. 232 y SNA §24.55 en CUAD-0 §10 y retirar la cita de §7.9 para este punto.

### 3.2 Cuasisociedades — la celda de negocios es B.3b **+ D.422**
La ENIGH tiene X007/X008 «ingreso de cooperativas, sociedades y cuasisociedades»; del Castillo compara el ingreso mixto ENIGH con **B.3b + D.422 Retiros de ingresos de cuasisociedades** (p. 232). Nuestro FLAG «cuasisociedades» (negocios con contabilidad completa están en S.11) se cierra parcialmente: lo que los hogares retiran de esas cuasisociedades sí está en S.14, como D.422 recibida. **Propuesta:** ancla de `ing_mixto` = B.3n + D.422 S.14 (verificar la celda en CSI_115); P068–P081 y X007/X008 juntos.

### 3.3 Elasticidad de subreporte > 1 — la corrección de ingresos altos que dejamos para 9.x ya tiene método y calibración
Altimir reparte la brecha ENIGH–SCN proporcional al ingreso (elasticidad 1). Del Castillo la reparte con **factor_i = (Y_i / ΣY)^1.75**, ponderador = factor_i / Σ factor (p. 238), para salarios e ingreso mixto; renta de la propiedad y transferencias siguen proporcionales entre declarantes. Valida con sueldos de directivos del sector financiero (ENIGH 53 mil → ajustado 282 mil mensuales; PageGroup 160–585 mil) y lo califica de «plausible y ligeramente conservador». Esto es exactamente nuestro FLAG 27: con Altimir uniforme la obligación de ISR de los formales queda **debajo** de lo recaudado (λ > 1, «evasión» negativa). Con ε > 1 la cola alta recibe más brecha, la obligación sube y la descomposición informalidad/evasión se vuelve identificable. **Propuesta:** parámetro `altimir_elasticidad` ∈ {1 (hoy), 1.75 (del Castillo), calibrada} aplicado **dentro de cada celda** (D.1, B.3n), y —ventaja nuestra que él no tenía— **calibrar ε contra el ITAN por rango** (8.16): la ε que reproduce la distribución del ISR de PF por rango de ingreso declarado es la que se firma. Es el contenido de 9.x «top incomes» adelantado a una decisión de método; mueve todo lo publicado → `baseline`.

### 3.4 Base gravable de asalariados
Del Castillo usa 85 % del ingreso laboral ajustado como base gravable (15 % de exentos y cuotas) para quienes tienen contrato. El Simulador ya hace mejor (exenciones por concepto, cuotas calculadas); pero su regla sirve de **cota de verificación**: Σ base gravable del motor / Σ salarios ajustados debe andar cerca de 0.85. Gate informativo.

### 3.5 Serie homologada 1984–2020
Su base homologada ENIGH (claves X001–X040) cubre 1984–2020; nuestra banda de vintages es 2016–2024. Para `/entidades` y para la narrativa histórica, la homologación de claves de del Castillo es la referencia para extender la banda hacia atrás si alguna vez hace falta (9.x o Colombia: es la «tabla de correspondencia encuesta → SCN» del cap. 0).

## 4. Lo que es v10 (acumulación de capital y riqueza)

Cap. III.F–G y V: cuentas de capital y financiera, variaciones de valor, balances (B.90 valor neto S.14 creció 6.1 % anual; riqueza/ingreso laboral de 6.8 a 16.2 veces). Fuentes para México: ENNVIH, ENH, ENIF, y la ausencia de una encuesta financiera de hogares como la EFH de Chile o la EFHU de Uruguay. El Simulador podría cerrar el ciclo con la cuenta de capital de S.14 (P.5, B.9) y el balance por edad: el «Futuro» del Sankey dejaría de ser un sumidero. No antes de 9.0.

## 5. Decisiones para Ricardo

1. **FLAG 18:** cerrar con `rentas_efectivas → B.2n` (del Castillo p. 232 + SNA §24.55 + el +221 medido) / mantener B.3n (§7.9 + INEGI p. 45). Mi voto: **B.2n**: tres evidencias contra una lectura de manual.
2. **Cuasisociedades:** ancla de `ing_mixto` = B.3n + D.422 S.14 / solo B.3n. Mi voto: **+ D.422**, si la celda existe en CSI_115.
3. **`altimir_elasticidad`:** adelantar a 8.18 como parámetro con default 1 y la calibración contra ITAN como memo (CUAD-3) / dejarlo en 9.x. Mi voto: **memo CUAD-3 antes de 9.0**; es la pieza que convierte FLAG 27 en resultado publicable y la que más mueve la distribución.
4. Citar a del Castillo (2023) en CUAD-0 §10, CUAD-1 §10 y cap. 0 de `/metodo` como el antecedente metodológico más cercano, y en el texto de `/NTA` como referencia.
