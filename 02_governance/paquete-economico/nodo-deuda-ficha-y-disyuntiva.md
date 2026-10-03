# Nodo: Deuda pública

**Ficha completa y especificación de la disyuntiva**
Piloto de septiembre 2026

---

## 0. Nota sobre las cifras

**Ninguna cifra aparece escrita en este documento.** Todas se representan con el nombre del escalar que las produce. Esto no es una omisión: es el contrato. Si un número no viene de `escalar`, no entra al nodo.

Los nombres de escalar aquí son propuestas y deben conciliarse con la línea base de nombres auditados antes de implementar.

**Verificación pendiente de Ricardo:** la composición exacta de la cobertura del SHRFSP —qué entes, qué instrumentos, qué se consolida— debe declararse con precisión normativa antes de publicar. Lo que sigue es la estructura, no la definición autorizada.

---

## 1. `nodo.yml`

```yaml
nodo: deuda-publica
titulo: Deuda pública
rama: financiamiento
medida_titular: SHRFSP

definicion: >
  Lo que el sector público debe hoy por decisiones de gasto que en su
  momento no se financiaron con ingresos. Cada año con déficit suma
  al saldo; cada año con superávit lo reduce.

definicion_tecnica: >
  Saldo Histórico de los Requerimientos Financieros del Sector Público:
  la medida oficial más amplia de la deuda pública del sector público
  federal. Acumula los requerimientos financieros de cada ejercicio.

vistas: [magnitud, per_capita, proyeccion]
vistas_no_aplican:
  tasa_efectiva: la deuda no es un gravamen; no hay tasa que pagar
  incidencia: el saldo no se distribuye por decil; su efecto es intertemporal
  territorio: el SHRFSP es federal. Ver nodo vecino deuda-subnacional

criterios:
  cobertura: sector público federal, según definición oficial de SHRFSP
  clasificacion: saldo, no flujo. El flujo anual es RFSP
  momento: saldo al cierre del periodo declarado
  deflactor: no aplica al saldo nominal; sí a la serie en pesos constantes
  denominador: PIB, serie transversal CIEP
  fuente: informes trimestrales SHCP y CGPE del año correspondiente
  consolidacion: según criterio oficial

capas_declaradas:
  - id: deuda-subnacional
    estado: fuera de la medida titular
    razon: corresponde a entidades y municipios, registro distinto
  - id: pasivo-pensionario
    estado: fuera de la medida titular
    razon: >
      Compromiso de pago futuro no registrado como deuda. Es el mayor
      compromiso intergeneracional del país y no aparece en ninguna
      estadística oficial de deuda.

disyuntiva: cerrar-la-brecha

vecinos: [balance-publico, costo-financiero, pensiones, deuda-subnacional]
```

---

## 2. La página, sección por sección

**Orden deliberado: primero personal, luego colectivo, luego técnico.** Nadie entra por el saldo agregado.

| # | Sección | Contenido |
|---|---|---|
| 1 | **Tu año de nacimiento** | El indicador central. Ver §3. |
| 2 | **Qué es** | Definición en lenguaje claro. Dos oraciones. |
| 3 | **Cuánto es** | Vista de magnitud: saldo en pesos y en % del PIB |
| 4 | **Cuánto por persona** | Vista per cápita, con la serie |
| 5 | **Hacia dónde va** | Vista de proyección |
| 6 | **Qué no está incluido** | Las capas declaradas. Ver §5. |
| 7 | **Cómo lo calculamos** | Criterios y bloque de conciliación |
| 8 | **Qué hemos publicado** | Acervo CIEP sobre deuda, con vigencia |
| 9 | **Decide** | Entrada a la disyuntiva |
| 10 | **Sello** | Versión, corte, log, DOI, descarga de datos |

---

## 3. El indicador central: deuda sin voto

El problema de un nodo de deuda es que la deuda no es tangible. Nadie recibe un recibo. La solución es una sola pregunta de entrada:

> **¿En qué año naciste?**

Y la respuesta:

> **El [X]% del saldo actual se contrajo antes de que pudieras votar.**

Seguido de: cuánto es eso por persona, y en qué año esa proporción llegará a cero para una persona nacida hoy —nunca, porque el saldo heredado no se paga: se transfiere.

### Por qué este indicador

- **Es una métrica de representación, no de economía.** Mide qué proporción de un compromiso vinculante fue contraída sin la participación de quien lo va a pagar.
- **Convierte lo abstracto en personal** con un solo dato de entrada, sin pedir ingreso, ubicación ni registro.
- **Es no partidista de forma absoluta.** El saldo acumulado atraviesa todos los gobiernos del periodo. El indicador no atribuye responsabilidad: describe una estructura.
- **Es el principio intergeneracional convertido en número**, sin una sola línea de teoría.

### Cómo se calcula

Serie de SHRFSP por año, más la edad de voto, más el año de nacimiento declarado. La proporción es el saldo acumulado hasta el año en que la persona cumplió dieciocho, sobre el saldo actual, ajustado por la unidad de comparación que se declare —nominal, real o proporción del PIB—.

**La elección de unidad es una decisión metodológica y debe ser visible**, con las tres opciones disponibles. Es la razón 4 de las siete, enseñada en el momento en que más importa.

### Regla de tono

El indicador se presenta **sin adjetivos**. No "abrumador", no "insostenible", no "una carga". El número y su definición. La interpretación es de quien lee: eso es lo que distingue infraestructura de deliberación de una campaña.

---

## 4. Las tres vistas

**Magnitud.** Saldo en pesos corrientes y en % del PIB. Serie histórica desde el primer año disponible. Selector de unidad visible.

**Per cápita.** Saldo por persona, con la serie. Segunda lectura: por persona en edad de trabajar, que es una aproximación mejor a quién lo sostiene. Ambas visibles, con su denominador declarado.

**Proyección.** Trayectoria del saldo bajo los supuestos declarados de los CGPE del año. **Los supuestos son visibles y el usuario puede moverlos** —crecimiento, tasa de interés, balance primario— y ver el efecto. Es la lección central del nodo: la trayectoria no es un destino, es la consecuencia de decisiones.

---

## 5. Qué no está incluido

Esta sección es la que hace valioso el nodo y hay que tratarla con cuidado.

Se presenta como **capas declaradas**, no como corrección de la cifra oficial:

| Capa | Qué es | Por qué no está en el titular |
|---|---|---|
| **Deuda subnacional** | Obligaciones de entidades y municipios | Registro y responsable distintos |
| **Pasivo pensionario** | Compromisos de pago de pensiones ya devengadas | No se registra como deuda bajo la norma vigente |

**El texto de la sección, en sustancia:**

> El SHRFSP es la medida oficial más amplia de deuda pública. No incluye lo que el Estado se ha comprometido a pagar en pensiones. Ese compromiso es contractual, es exigible y lo pagarán en su mayoría personas que hoy no votan. No aparece aquí porque la norma contable vigente no lo clasifica como deuda —no porque no exista.

Esa frase es defendible, es técnicamente correcta, no acusa a nadie y enseña exactamente lo que hay que enseñar: **que la frontera de lo que se cuenta como deuda es una decisión, no un hecho.**

Con enlace al nodo de pensiones, donde la magnitud del pasivo sí se estima y se explican sus supuestos.

---

## 6. Bloque de conciliación

| Campo | Contenido |
|---|---|
| Cifra CIEP | `deuda_shrfsp_pctpib` |
| Cifra oficial comparable | SHCP, informe trimestral o CGPE, con referencia exacta al cuadro |
| Diferencia | Absoluta y relativa |
| Razones aplicables | **Denominador** (qué PIB) y **fuente y corte** (qué documento, qué fecha) |
| Dimensión | La diferencia frente a la magnitud en discusión |

**Nota del bloque:**

> El saldo lo publica la autoridad hacendaria y el CIEP no lo recalcula: lo toma. Lo que el CIEP recalcula es la proporción del PIB, con su propia serie de producto y su propio corte. Por eso la diferencia es pequeña y se explica por completo con dos de las siete razones.

Ese párrafo es honesto y es más fuerte que fingir independencia donde no la hay. **Declarar qué se toma de la fuente y qué se rehace es tan importante como rehacer.**

---

## 7. La disyuntiva: cerrar la brecha

### Pantalla 1 — El planteamiento

Las tres cifras del Paquete 2027: ingreso propuesto, gasto propuesto, balance resultante. En % del PIB y en pesos, con selector.

Una frase: *el gobierno propone gastar más de lo que propone recaudar. La diferencia se financia con deuda.*

### Pantalla 2 — La elección

> **Si tuvieras que cerrar esa brecha, ¿cómo lo harías?**
> Más ingresos · Menos gasto · Más deuda

Sin opción recomendada. **Orden aleatorizado entre sesiones.**

### Pantalla 3 — Las consecuencias

| Rama | Segundo nivel | Consecuencia mostrada |
|---|---|---|
| **Más ingresos** | ¿De dónde? Opciones acotadas del sistema tributario | Efecto en tasa efectiva por decil |
| **Menos gasto** | ¿De dónde? Opciones acotadas por función | Qué deja de financiarse: per cápita y por entidad |
| **Más deuda** | Confirmar | Trayectoria del saldo y **el indicador de deuda sin voto aplicado a su propia elección** |

La tercera rama regresa al nodo. El circuito se cierra: quien elige más deuda ve su propia decisión medida con el indicador que abrió la página.

### Pantalla 4 — Cierre

1. Posición registrada
2. **Verificación de comprensión**: dos preguntas breves. Es el peldaño 3 de la escalera y casi nadie lo mide.
3. Agregado: dónde quedó su posición frente a las demás
4. Descarga del agregado
5. **Solo aquí**, claramente separada y etiquetada, la posición del CIEP y su fundamento

El punto 5 es una salvaguarda de diseño: **mostrar la posición del CIEP antes de que la persona elija sería anclar.** Mostrarla después la respeta y cumple el compromiso de transparencia sin convertir la herramienta en persuasión.

---

## 8. Instrumentación

| Evento | Peldaño |
|---|---|
| Llegada al nodo, con fuente de origen | Acceso |
| Año de nacimiento ingresado | Uso |
| Sección de proyección abierta o supuestos movidos | Uso profundo |
| Entrada a la disyuntiva | Uso |
| Rama elegida | — |
| Segundo nivel completado | Posición |
| Verificación de comprensión respondida | Comprensión |
| Datos descargados | Incidencia |

Todo anónimo y agregado. Sin registro, sin cuenta, sin dato personal más allá del año de nacimiento, que no se almacena ligado a nada.

---

## 9. Salvaguardas de no partidismo

1. Ninguna opción marcada como recomendada
2. Orden de opciones aleatorizado
3. La posición del CIEP solo después de la elección, etiquetada como tal
4. Sin adjetivos valorativos en cifras ni consecuencias
5. Sin mención de gobiernos, partidos ni funcionarios
6. Agregados publicados **aunque contradigan la posición del CIEP**
7. Consecuencias con la misma profundidad de detalle en las tres ramas

La séptima es la más fácil de romper sin querer: si la rama de gasto tiene tres pantallas de consecuencias y la de deuda una, el diseño está tomando partido.

---

## 10. Alcance para implementación

**Lo que se implementa:**
- Página de nodo que lee un solo archivo `statajson_deuda-publica.json`
- Indicador de año de nacimiento, cálculo en el navegador sobre la serie del archivo
- Tres vistas con selector de unidad
- Sección de capas declaradas, estática
- Bloque de conciliación, desde el archivo
- Disyuntiva de cuatro pantallas
- Instrumentación
- Sello al pie

**Lo que no se implementa ahora:**
- Integración en vivo con Stata: el archivo se genera y se commitea
- Los otros diez nodos
- Comparador histórico entre nodos
- Video
- Exportación distribuida

**La única pregunta que este piloto responde:** ¿una ficha de nodo con entrada personal y disyuntiva produce más comprensión y más participación que un PDF con infografía? Si la respuesta es no, once nodos tampoco lo lograrían.

---

*Especificación de trabajo. Las cifras y la definición normativa del SHRFSP requieren validación antes de publicar.*
