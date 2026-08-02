# Independencia metodológica y series históricas

**Adenda al rediseño del Paquete Económico**
Agosto 2026

---

## 1. El principio

> "Es importante que nuestras cifras cuadren con las de Hacienda."

Esa petición confunde dos cosas distintas: **coincidir** y **verificar**. Una cifra que se copia de la fuente oficial no la verifica —la repite. Y una organización que solo repite no aporta control independiente; aporta redundancia con membrete.

La independencia metodológica significa rehacer la estimación con criterios propios, explícitos y públicos. Si el resultado coincide, la coincidencia **es información**: dos rutas distintas llegaron al mismo lugar. Si difiere, la diferencia **también es información**: hay una decisión de criterio que alguien tomó y que merece discutirse.

Y el argumento que cierra la objeción es el tuyo:

> Si una diferencia menor confunde la discusión, el problema no es la diferencia. Es que la discusión estaba anclada en una precisión falsa y las cifras no estaban en su dimensión correcta.

Cuando la conversación pública se traba en un decimal, lo que está fallando es la escala del debate, no el decimal. **La respuesta correcta no es esconder la diferencia: es enseñar la dimensión.**

## 2. Por qué esto es el corazón de "democratizar"

Una ciudadanía que cree que las cifras fiscales son hechos naturales no puede exigir cuentas: solo puede creer o no creer. Una ciudadanía que entiende que **una cifra fiscal es una construcción con criterios** puede preguntar cuáles son esos criterios, quién los eligió y qué cambiaría con otros.

Hacer visible la diferencia entre la cifra oficial y la propia no es un riesgo reputacional que haya que administrar. **Es el acto pedagógico central del proyecto.** Es donde el marco enseña lo que ningún documento explica: que detrás de cada número hay decisiones, y que las decisiones se discuten.

Por eso la conciliación no va en un pie de página. Va en la ficha del nodo, visible, con la misma jerarquía que la cifra.

---

## 3. Las siete razones

El problema práctico que describes —"a veces es difícil explicar los criterios"— se resuelve dejando de explicar en prosa cada vez. Casi toda discrepancia en finanzas públicas mexicanas cae en una de siete razones. Con una lista cerrada, la explicación deja de ser retórica y se vuelve mecánica.

| # | Razón | Pregunta que responde | Ejemplos típicos |
|---|---|---|---|
| **1** | **Cobertura** | ¿Qué se incluye? | Sector público presupuestario frente a sector público federal amplio; si un fondo federalizado cuenta en su función o en federalizado; organismos y empresas dentro o fuera |
| **2** | **Clasificación** | ¿En qué categoría entra? | Funcional, administrativa o económica; a qué finalidad y función se asigna un programa |
| **3** | **Momento contable** | ¿Qué etapa del ciclo? | Proyecto, aprobado, modificado, devengado, ejercido, pagado |
| **4** | **Deflactor** | ¿Nominal o real, y con qué índice? | INPC frente a deflactor implícito del PIB; qué año base; qué proyección de inflación para años futuros |
| **5** | **Denominador** | ¿Contra qué se compara? | Qué PIB —proyectado en CGPE o observado por INEGI—; qué proyección de población y de qué vintage |
| **6** | **Fuente y corte** | ¿Qué documento y de qué fecha? | Entrega original frente a versión corregida; anexos frente a bases de datos abiertas |
| **7** | **Consolidación** | ¿Se netean transferencias? | Transferencias entre entes contadas una o dos veces |

**Regla operativa:** toda diferencia entre la cifra CIEP y la oficial se explica declarando cuál o cuáles de las siete razones aplican. Si una diferencia no cae en ninguna de las siete, es un error —de CIEP o de la fuente— y se investiga antes de publicar.

Esa lista cerrada tiene una segunda virtud: **es el temario de un taller de un día para periodistas.** Quien entiende las siete razones deja de escribir "hay discrepancias entre las cifras" y empieza a escribir "el gobierno reporta la cifra en devengado y el CIEP en aprobado".

---

## 4. El bloque de conciliación

Cada nodo lleva el mismo bloque, siempre con la misma estructura:

| Campo | Contenido |
|---|---|
| **Cifra CIEP** | El valor, con su unidad y sus cuatro lentes |
| **Criterios CIEP** | Cobertura, clasificación, momento, deflactor, denominador, fuente, consolidación. Los siete, declarados. |
| **Cifra oficial comparable** | El valor publicado por la fuente, con la referencia exacta |
| **Diferencia** | Absoluta y relativa |
| **Razones** | Cuáles de las siete explican la diferencia |
| **Dimensión** | Qué tan grande es la diferencia frente a la magnitud que está en discusión |

El último campo es el que resuelve tu objeción de fondo. Una diferencia de 0.05% del PIB en una discusión sobre un ajuste de 1.5% del PIB no es una discrepancia: es ruido, y decirlo explícitamente reencuadra la conversación en lugar de alimentarla.

---

## 5. El puente de conciliación

Un dispositivo estándar de contabilidad que convierte la explicación en algo mecánico: se parte de la cifra oficial y se llega a la del CIEP mostrando cada ajuste por separado.

```
Cifra oficial
   ± ajuste por cobertura
   ± ajuste por clasificación
   ± ajuste por momento contable
   ± ajuste por deflactor o denominador
   ± ajuste por consolidación
= Cifra CIEP
```

Ventajas sobre explicarlo en prosa: es auditable paso a paso, permite que alguien discrepe de **un** ajuste sin descalificar toda la cifra, se genera automáticamente si los criterios están registrados, y se ve igual en todos los nodos.

---

## 6. Calculadora del deflactor

La razón 4 es la que más confusión genera cada septiembre, porque la discusión sobre si el gasto crece o cae **en términos reales** depende del índice que se use, y la fuente oficial usa su propia proyección de inflación. Hoy eso es una discusión de autoridad. Con una calculadora pública se vuelve una discusión verificable.

### Funciones

- Convertir cualquier monto entre dos años
- Elegir índice: INPC, deflactor implícito del PIB, o la proyección de inflación de los propios CGPE
- Elegir año base
- Mostrar la fórmula aplicada y la serie utilizada
- Descargar la serie completa
- Enlace permanente con los parámetros incluidos, para que un periodista comparta una conversión específica

### Reglas de diseño

1. **La elección del índice es visible y obligatoria.** No hay opción por defecto oculta. Elegir el índice es la decisión metodológica, y el usuario debe verse tomándola.
2. **Los años futuros se marcan como proyección**, con la fuente de esa proyección. Convertir a pesos de 2027 usa un supuesto, no un dato, y eso tiene que estar en pantalla.
3. **Comparación lado a lado.** El mismo monto convertido con los tres índices, para que la magnitud de la diferencia entre criterios sea evidente de un vistazo.
4. **Cada serie con su fuente, su fecha de corte y su descarga.**

### Por qué es un bien público de alto valor

Es barata de construir, la usa todo el ecosistema —periodistas, académicos, oficinas legislativas, otras organizaciones civiles— y cada uso enseña la lección central: **el mismo número puede ser tres números distintos dependiendo de un criterio que alguien eligió.**

---

## 7. Series históricas: cómo construirlas

De acuerdo con usar las infografías sueltas como semilla de la estructura. Con una corrección al mecanismo, porque decide si esto se puede mantener o no.

**El JPG no es la fuente. Es el ocupante temporal del lugar.**

Si la página HTML se construye transcribiendo los JPG, el sitio nace con una segunda fuente de verdad que no se puede actualizar y que va a divergir de Stata en el primer ciclo. Es el mismo error del encode en la clasificación: funciona hasta que deja de funcionar, y para entonces ya nadie se acuerda de por qué.

**El modelo correcto:**

1. **La página del nodo se arma primero, vacía.** URL permanente, estructura de campos, bloque de conciliación, espacio de gráfica. Esto se puede hacer hoy, para los once nodos, sin ningún dato.
2. **La gráfica se renderiza desde un archivo de datos**, no desde una imagen. Un CSV o JSON por nodo, con año, valor, unidad, criterios y fuente.
3. **Mientras no exista el archivo de datos, el JPG ocupa el lugar** y se marca visiblemente como imagen de archivo. La página funciona desde el día uno y mejora sin rehacerse.
4. **El archivo de datos se llena por prioridad de nodo**, y sale de Stata vía el contrato `escalar`. Nunca se teclea a mano.
5. **Solo se transcribe un JPG** cuando el dato de ese año no sea recuperable desde el código. Y esos casos se marcan como reconstruidos, no como calculados.

Esto respeta tu intuición —empezar con lo que ya existe para armar la estructura— y evita que el atajo se vuelva deuda permanente.

### Estructura del repositorio

```
paquete-economico/
├── nodos/
│   └── {concepto}/
│       ├── nodo.yml          Definición, criterios, disyuntiva, acervo asociado
│       ├── serie.csv         Año, valor, unidad, lente, fuente, criterios
│       ├── conciliacion.yml  Cifra oficial, diferencia, razones aplicables
│       └── archivo/          JPG y PDF históricos, marcados como archivo
├── series/
│   ├── inpc.csv
│   ├── deflactor-pib.csv
│   ├── pib.csv
│   └── poblacion.csv
├── ciclos/
│   └── {año}/                Documento bandera, presentación, kit, transcripción
└── metodo/
    ├── siete-razones.md
    └── criterios-ciep.md
```

Las series de `/series/` son transversales: las usan todos los nodos, la calculadora del deflactor y el comparador histórico. Tener una sola copia de cada una, versionada, elimina de raíz la discrepancia interna —que es peor que la discrepancia con Hacienda, porque esa no se puede defender con criterios.

---

## 8. Lo que esto agrega a la lista de bienes públicos

- **Calculadora del deflactor**, con las tres series y enlaces permanentes
- **Series transversales abiertas**: INPC, deflactor del PIB, PIB, población
- **Documento público de criterios CIEP**, versionado
- **Las siete razones** como material de formación reutilizable
- **Bloques de conciliación** de cada nodo, abiertos y descargables

El último punto es inusual y por eso vale: **una organización que publica sistemáticamente en qué difiere de la fuente oficial y por qué está haciendo transparencia sobre sí misma**, no solo sobre el gobierno. Es el argumento de credibilidad más fuerte disponible, y no cuesta dinero.

---

*Adenda de trabajo.*
