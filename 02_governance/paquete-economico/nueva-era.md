# Paquete Económico · Nueva era

**Rediseño del operativo anual bajo el marco conceptual**
Agosto 2026

---

## 1. Diagnóstico del sitio actual

`paqueteeconomico.ciep.mx` funciona. Tiene identidad propia, explica bien qué es el Paquete, tiene serie histórica y liga al Simulador. El problema no es que esté mal hecho: es que está diseñado para **entregar un documento**, no para **sostener conocimiento**.

Cinco hallazgos concretos:

**1.1 · El sitio se autoexcluye de los buscadores.** La etiqueta `meta-robots` está en `noindex, nofollow`. Le está diciendo explícitamente a Google que no lo indexe. Es casi seguro el ajuste de WordPress "disuadir a los motores de búsqueda" que quedó encendido desde alguna migración. **Un sitio cuya misión es democratizar información se está escondiendo del principal camino por el que la gente llega a la información.** Es el arreglo de mayor retorno y menor costo de toda esta lista: se resuelve en un clic.

**1.2 · Todo es PDF.** El documento de 85 páginas, la presentación, el kit de prensa. Las infografías son JPG. Un PDF no se cita por sección, no se comparte por tema, no se indexa bien, no se lee en teléfono y no se actualiza. **El PDF debe ser el archivo, no la interfaz.**

**1.3 · Cada año borra al anterior.** El sitio muestra el documento vigente y una lista de PDFs anteriores desde 2020 —aunque el título prometa 2013-2026. No hay forma de preguntar "qué ha pasado con salud en catorce años" sin abrir catorce PDFs.

**1.4 · Los datos están en la página pero no son datos.** Las series de la sección de evolución están incrustadas como listas de números sin encabezado, sin unidad, sin descarga. La información existe; el bien público no.

**1.5 · Las once infografías ya son once nodos.** Deuda, Energía, Ingresos, Gasto, Salud, Cuidados, Educación, Inversión, Medio ambiente, Federalizado, Pensiones. Y la descripción del sitio ya dice "tres ejes: ingresos, gastos y deuda". **La arquitectura conceptual del marco ya está ahí implícita.** Lo que falta no es inventarla: es hacerla explícita, navegable y permanente.

---

## 2. Lo que se mantiene igual

Hay cosas que funcionan y que un rediseño mal llevado destruiría.

- **Llegar el día D.** La velocidad es el activo reputacional del CIEP. Que el análisis exista cuando la conversación pública está ocurriendo es lo que hace que los periodistas llamen. No se toca.
- **El documento largo como documento bandera.** Las 85 páginas son el activo citable y de conservación permanente. Nada de lo que sigue lo sustituye.
- **La rueda de prensa.** Es el momento de mayor densidad de relación con medios del año.
- **Los tres ejes.** Ingresos, gasto y deuda ya son la columna vertebral. El marco no cambia el enfoque: lo formaliza.
- **El kit de prensa.** Buena práctica, se conserva y se amplía.
- **El sitio con dominio propio.** Separado de ciep.mx, con identidad visual distinta. Es correcto: el Paquete tiene un público más amplio que el centro.

---

## 3. Lo que cambia

**3.1 · De publicación anual a acervo permanente.**
Hoy cada año reemplaza al anterior. Con nodos, cada año **reenciende los mismos nodos con datos nuevos** y la serie histórica se acumula sola. El sitio deja de ser un anuncio y se vuelve una referencia.

**3.2 · De PDF a página.**
Cada uno de los once temas se vuelve una URL propia, permanente, citable, compartible e indexable. El PDF completo sigue existiendo y se descarga desde ahí.

**3.3 · De archivo a dato.**
Cada cifra publicada tiene su CSV y su JSON detrás, con unidad, fuente y año. Con el contrato `escalar` ya funcionando, esto es trabajo marginal: los números ya salen tipados del Simulador.

**3.4 · De un público a tres puertas.**
El sitio hoy asume un lector único. Son tres y necesitan cosas distintas:

| Puerta | Quién | Qué quiere | Qué recibe |
|---|---|---|---|
| **¿Qué me toca?** | Ciudadanía | Su propio caso | Entrada personal, ligada al Simulador y a los nodos |
| **Cifras y gráficas** | Prensa | Material usable hoy, verificado | Kit, cifras clave, gráficas descargables con licencia, voceros por tema |
| **Documento y datos** | Especialistas, academia, legislativo | Profundidad y reproducibilidad | Documento bandera, datos abiertos, método |

**3.5 · La rueda de prensa deja de ser el clímax.**
Pasa a ser un eslabón de una cadena que empieza antes y sigue después. Ver §6.

---

## 4. Lo que mejora

**4.1 · Llegar al día D con el marco ya encendido.**
Hoy buena parte del esfuerzo de septiembre se gasta explicando qué es el gasto no programable, qué son las participaciones, qué significa el balance primario. Si esos nodos están encendidos desde julio, **el día D se dedica a lo nuevo, no a lo básico.** Ese es el mayor ahorro de capacidad de todo el rediseño.

**4.2 · Comparación histórica automática.**
Los datos de 2013 a 2026 ya existen y ya están en el sitio, mal presentados. Un comparador por nodo —cuánto era, cuánto es, en % del PIB y per cápita— es de las cosas más útiles y menos costosas que se pueden construir.

**4.3 · Un video por nodo.**
No un video del documento. Un video de sesenta a noventa segundos por concepto, acumulable año con año. Al final de dos ciclos existe una videoteca conceptual completa de las finanzas públicas mexicanas.

**4.4 · Del análisis a la posición.**
Después de entender un nodo, la persona enfrenta la disyuntiva que ese nodo abre y toma posición. Los agregados se publican abiertos y se entregan durante la discusión legislativa de octubre y noviembre. Eso convierte al sitio de vitrina en infraestructura de deliberación.

---

## 5. El operativo

### 5.1 Preparación (julio–agosto)

| Semana | Qué ocurre |
|---|---|
| **T-6 a T-4** | Encendido de nodos base: conceptos que no dependen del Paquete de este año. Definición, cifras del año vigente, serie histórica. |
| **T-4 a T-2** | Plantillas listas: documento, presentación, kit de prensa, formatos de gráfica, guiones de video con huecos donde van las cifras. Datos del año anterior cargados y verificados. |
| **T-2** | **Simulacro completo con el Paquete del año pasado.** Se corre el pipeline entero contra datos conocidos, con cronómetro. Es la única forma de saber cuánto tarde de verdad y dónde se rompe. |
| **T-1** | Corrección de lo que falló en el simulacro. Voceros asignados por tema. Pre-briefing agendado con periodistas. Congelamiento: nada nuevo entra. |

El simulacro es la pieza que hoy no existe y la que más riesgo elimina. Descubrir el 8 de septiembre que un clasificador cambió de formato es distinto a descubrirlo el 25 de agosto.

### 5.2 El día D y las olas siguientes

| Ola | Momento | Entregable | Público |
|---|---|---|---|
| **Ola 0** | Día D, primeras horas | Cifras verificadas de la identidad: qué cambia en ingresos, en gasto, en balance, en deuda. Publicación en el sitio y en redes. | Prensa, redes |
| **Ola 1** | Día D + 24 a 72 h | Documento bandera, presentación, kit de prensa, rueda de prensa | Todos |
| **Ola 2** | Semana 2 | Nodos sectoriales reencendidos con datos del año: salud, educación, pensiones, federalizado, energía, cuidados, ambiente, inversión. Un video por nodo. | Ciudadanía, especialistas |
| **Ola 3** | Octubre–noviembre | Seguimiento de la discusión legislativa, cambios aprobados, entrega de agregados de deliberación | Legislativo, prensa |
| **Ola 4** | Diciembre | Cierre: qué se aprobó frente a qué se propuso, qué quedó apagado, agenda del siguiente año | Interno y público |

**La disciplina de la Ola 0 es lo que define el operativo:** pocas cifras, todas verificadas, todas trazables, publicadas rápido. Es preferible publicar seis números correctos en tres horas que treinta en doce.

---

## 6. La rueda de prensa

Cuatro cambios sobre el formato actual:

**6.1 · Pre-briefing técnico bajo embargo.** Sesión cerrada con periodistas especializados uno o dos días antes de la publicación del documento, con material embargado hasta la hora acordada. Es práctica estándar internacional, mejora radicalmente la calidad de la cobertura, y construye una relación de confianza que no se compra de otra forma.

**6.2 · Estructura fija, siempre la misma.** La rueda sigue la identidad: qué cambia en ingresos, qué cambia en gasto, qué resulta en el balance, qué implica para la deuda. Que sea idéntica cada año es una ventaja: el periodista sabe qué va a recibir y aprende el marco por repetición.

**6.3 · Vocería distribuida por tema.** Cada nodo sectorial tiene su vocero. Reduce la concentración de riesgo, da visibilidad a más personas del equipo y mejora la calidad de la respuesta técnica.

**6.4 · La rueda se convierte en insumo.** Se transcribe, se publica la transcripción, se cortan clips por pregunta y cada clip se liga a su nodo. Una hora de video se vuelve doce piezas reutilizables.

---

## 7. Bienes públicos que quedan cada año

Esto es lo que distingue una campaña de comunicación de una construcción de infraestructura. Cada ciclo del Paquete deja detrás, permanentemente:

1. **Datos abiertos por nodo** — CSV y JSON, con unidad, fuente, año y método
2. **Documento bandera con enlace permanente** que no se rompe cuando cambia el sitio
3. **Gráficas descargables con licencia explícita** de reutilización, atribución incluida
4. **Kit de prensa abierto**, no solo para medios invitados
5. **Videoteca conceptual acumulada**
6. **Código y método** del procesamiento del PPEF y la LIF
7. **Comparador histórico** con la serie completa
8. **Agregados de deliberación ciudadana**, abiertos
9. **Transcripción de la rueda de prensa**

La pregunta de control para cada ciclo: *¿qué queda disponible para siempre después de esto?* Si la respuesta es "un PDF", el ciclo no construyó infraestructura.

---

## 8. Arquitectura del sitio

```
/                        Identidad viva del año: ingresos − gasto = balance → deuda
                         con las cifras vigentes. La navegación ES el marco.

/nodo/{concepto}         Ficha permanente: definición, cifras con los cuatro lentes,
                         serie histórica, acervo CIEP asociado, disyuntiva, video

/año/{2027}              El Paquete de ese año: documento, presentación,
                         kit de prensa, rueda de prensa, qué cambió

/comparar                Serie histórica navegable por nodo y por lente

/datos                   Descargas: CSV, JSON, método, licencia

/prensa                  Kit vigente, cifras clave, gráficas, voceros por tema

/tu-caso                 Entrada personal, puente al Simulador y a los nodos

/deliberar/{disyuntiva}  Posición ciudadana y agregados abiertos
```

Dos principios de la arquitectura:

- **La URL del nodo es permanente y no lleva año.** El año está en el contenido, no en la dirección. Así una cita de 2027 sigue viva en 2032.
- **Todo camino lleva al nodo.** El documento, la infografía, el video, la nota de prensa y el resultado personal aterrizan en la misma ficha. El nodo es el destino, no la escala.

---

## 9. Qué cabe en cinco semanas y qué no

El Paquete Económico 2027 entra el **8 de septiembre de 2026**. Un sitio reconstruido no cabe. Conviene ser explícito sobre las dos velocidades.

### Cabe ahora, para el ciclo 2027 (bajo costo, alto retorno)

1. **Quitar el `noindex`.** Un clic. Mayor retorno de la lista.
2. **Once URLs por tema** en lugar de once JPG sueltos, aunque el contenido sea el mismo de siempre.
3. **Publicar los datos de la serie histórica en CSV**, que ya existen.
4. **Enlaces permanentes** al documento bandera.
5. **Pre-briefing técnico** con periodistas y estructura fija de la rueda de prensa.
6. **Simulacro T-2** con el Paquete anterior.
7. **Transcripción y clips** de la rueda.

Ninguna de esas siete requiere rediseño. Todas mejoran el ciclo de este año.

### Es para el ciclo 2028 (septiembre de 2027)

El marco completo, las fichas de nodo, el comparador, la capa de deliberación, la videoteca. Construcción de diciembre a agosto.

**Ese calendario coincide exactamente con un proyecto NED que arranca en febrero de 2027.** El operativo del Paquete Económico 2028 sería la prueba pública del marco: la demostración de que la infraestructura funciona, con público real y en el momento de máxima atención. Es también el mejor argumento de renovación que se puede construir.

---

## 10. Alcance del prototipo

Recomendación: **prototipar `paqueteeconomico.ciep.mx`, no `ciep.mx`.**

Tres razones: el alcance es acotado y evaluable; es el momento de mayor tráfico del año, así que el aprendizaje es real y no de laboratorio; y un error en el micrositio no toca la presencia institucional. Si el modelo de nodos funciona ahí, se lleva a `ciep.mx` con evidencia en mano. Si no funciona, se descubrió barato.

**Alcance del primer prototipo** —lo mínimo que prueba o tumba el concepto:

- Portada con la identidad viva y cifras del año vigente
- Tres fichas de nodo completas, no once: una de ingresos, una de gasto, una de deuda
- Comparador histórico funcionando en esos tres nodos
- Descarga de datos en esos tres nodos
- Una disyuntiva de deliberación, de punta a punta
- Datos cargados desde archivo, sin integración con el Simulador todavía

Con eso se responde la única pregunta que importa antes de invertir: **¿la ficha de nodo es realmente más útil que un PDF y una infografía?** Si tres nodos no lo demuestran, once tampoco.

---

*Documento de trabajo.*
