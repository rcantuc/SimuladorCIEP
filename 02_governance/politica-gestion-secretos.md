# Política de gestión de secretos del CIEP

**Para quién es este documento:** todo el personal del CIEP que toca infraestructura digital — investigadores que generan tokens para acceder a fuentes de datos, personal técnico que administra servidores, administración que aprueba accesos, y cualquier colaborador que en el curso de su trabajo recibe una credencial institucional.

**Qué documenta:** los principios y procedimientos del CIEP para manejar credenciales (contraseñas, llaves API, tokens, certificados, llaves SSH). Define qué cuenta como secreto, dónde viven los secretos, quién tiene acceso a qué, y qué hacer cuando uno se compromete.

**Por qué importa:** un secreto institucional expuesto puede comprometer datos, suplantar al CIEP frente a terceros, o cerrar el acceso a fuentes que costó años construir. El CIEP ya vivió ese escenario una vez (ver §6, bitácora de incidentes); esta política existe para que no vuelva a pasar y, si vuelve a pasar, para que la respuesta sea rápida y ordenada.

**Alcance:** aplica hoy al ecosistema del Simulador Fiscal CIEP, y se extiende automáticamente a todo nuevo proyecto, servicio o iniciativa institucional del CIEP que requiera credenciales. Está escrita para ser portable a contextos institucionales hermanos (por ejemplo, la unidad de Análisis Fiscal y Sostenibilidad en Consejo Nuevo León). El cuerpo del documento es agnóstico de proyecto; el apéndice A aplica la política al caso específico del Simulador.

---

## Tabla de contenido

1. [Principio fundacional](#1-principio-fundacional)
2. [Qué cuenta como secreto](#2-qué-cuenta-como-secreto)
3. [Dónde viven los secretos](#3-dónde-viven-los-secretos)
4. [Roles y matriz de acceso](#4-roles-y-matriz-de-acceso)
5. [Procedimientos](#5-procedimientos)
6. [Bitácora de incidentes](#6-bitácora-de-incidentes)
7. [Compromisos institucionales pendientes](#7-compromisos-institucionales-pendientes)
8. [Apéndice A — Aplicación a los Simuladores CIEP y su infraestructura](#apéndice-a--aplicación-a-los-simuladores-ciep-y-su-infraestructura)

---

## 1. Principio fundacional

*Qué aprendes en esta sección:* la regla central de la cual se derivan todas las demás.

> **Cero secretos en código. Cero secretos en documentación. Cero secretos compartidos por canal informal (correo, mensaje, Slack, dictado verbal, captura de pantalla).**

**Qué cuenta como "secreto"** para efectos de esta política: cualquier credencial que, si cae en manos equivocadas, permite acceso no autorizado a un sistema, dato o servicio del CIEP. La sección 2 lo desglosa por categoría.

**Por qué la regla es absoluta y no condicionada.** Una credencial compartida por canal informal queda fuera del control del CIEP a partir de ese momento: vive en la cache de correo del receptor, en el historial de Slack que sincroniza con la nube del proveedor, en notas personales, en respaldos automáticos del dispositivo. El control institucional sobre dónde está esa credencial se pierde. La política no asume disciplina permanente del personal; asume que las personas olvidan, se distraen, copian y pegan sin pensar, y migra el riesgo al diseño en lugar de al voluntarismo individual.

---

## 2. Qué cuenta como secreto

*Qué aprendes en esta sección:* las categorías de credenciales que esta política cubre, con ejemplos del CIEP.

| Categoría | Qué es | Ejemplo en el CIEP |
|---|---|---|
| Credenciales de servicios web | Contraseñas de cuentas en plataformas externas. | Cuenta institucional en el Banco de Indicadores Económicos (BIE) de INEGI. |
| Tokens API | Llaves que autentican acceso programático a servicios externos sin contraseña interactiva. | Token del BIE consumido por `AccesoBIE.ado`. |
| Llaves SSH y certificados | Archivos digitales que prueban identidad ante un servidor o ante una autoridad de certificación. | Llave SSH al VPS de IONOS; certificado SSL de `simuladorfiscal.ciep.mx`. |
| Contraseñas de correo institucional | Especialmente las direcciones que sirven como destino de verificación de dominio o de recuperación de cuentas. | `hostmaster.ciep.mx`. |
| Credenciales de infraestructura | Acceso administrativo a servidores, bases de datos, servicios en la nube. | Acceso root al VPS de IONOS. |
| Tokens personales | Tokens de acceso personal (PAT) que un investigador genera contra su propia cuenta para automatizar tareas que tocan datos o servicios institucionales. | PAT de GitHub para scripts que publican releases. |

Si un valor encaja en alguna de estas categorías, esta política lo gobierna. Si hay duda razonable sobre si algo es un secreto, se trata como secreto hasta que el investigador principal determine lo contrario.

---

## 3. Dónde viven los secretos

*Qué aprendes en esta sección:* el único lugar autorizado para almacenar valores reales de credenciales.

> Los valores reales de los secretos viven en una herramienta especializada llamada **gestor de secretos institucional del CIEP**. Ningún otro lugar es autorizado.

### 3.1 Criterios que debe cumplir el gestor de secretos institucional

La herramienta concreta es decisión administrativa, separada de esta política. Cualquier herramienta que adopte el CIEP debe cumplir los siguientes criterios. Si una herramienta falla en uno solo de estos, no califica.

- **Acceso granular** por usuario y por carpeta (no todo o nada).
- **Log de auditoría** que registra quién accedió a qué credencial y cuándo.
- **Recuperación administrativa** si un usuario sale del CIEP (un administrador puede recuperar el control de las credenciales que ese usuario gestionaba).
- **Compartir con caducidad** configurable por credencial.
- **Cifrado en reposo y en tránsito.**

Herramientas como **1Password Teams** o **Bitwarden Teams** cumplen estos criterios y son ejemplos válidos. La elección final corresponde a la administración del CIEP en consulta con el investigador principal.

### 3.2 Qué NO califica como gestor institucional

Las siguientes herramientas son útiles para uso personal y no están prohibidas para el día a día individual, pero **no son adecuadas para almacenar secretos institucionales del CIEP**:

- Apple Keychain personal, gestores integrados en navegadores (Chrome, Firefox, Safari) — son cuentas individuales sin acceso administrativo institucional.
- Notas en aplicaciones como Apple Notes, Google Keep, Notion personal — no cifran al nivel requerido y no registran acceso.
- Archivos cifrados sueltos en disco o en Dropbox — no permiten acceso granular ni auditoría.
- Correos electrónicos a uno mismo, mensajes personales archivados — explícitamente prohibido por la regla del §1.

---

## 4. Roles y matriz de acceso

*Qué aprendes en esta sección:* quién puede acceder a qué tipo de secreto, según su rol en el CIEP.

| Rol | Acceso a secretos del CIEP |
|---|---|
| **Investigador principal** | Permanente, a todos los secretos. |
| **Investigador colaborador con rol de mantenimiento de infraestructura** | Permanente, a secretos relacionados con su rol: SSL del servidor web, VPS de IONOS, deploys del sitio web público, correos de administración de dominio. |
| **Investigador colaborador con rol de análisis fiscal** | Permanente, a secretos relacionados con su trabajo: token BIE, credenciales de cuentas en plataformas de datos económicos. Sin acceso a infraestructura. |
| **Desarrollador externo de infraestructura** | Permanente, granularidad por infraestructura. Acceso administrativo (incluyendo superusuario cuando aplique) a la infraestructura específica que opera (ejemplo: Cloudways). Sin acceso por defecto a otras infraestructuras del CIEP (ejemplo: IONOS). |
| **Investigador colaborador temporal** (becario, consultor externo, residente) | Acceso temporal con caducidad explícita, otorgado caso por caso por el investigador principal. La caducidad se configura en el gestor de secretos, no se asume disciplina manual de revocación. |
| **Investigador CIEP que solo usa el Simulador como herramienta** | Sin acceso a secretos. Su interacción con el Simulador (correr comandos en Stata, leer outputs, citar versiones publicadas) no requiere credenciales. |
| **Cualquier persona externa al CIEP** | Sin acceso. |

**Notas sobre la tabla:**

- "Rol" significa **función dentro del CIEP**, no persona individual. Una misma persona puede tener varios roles simultáneos (por ejemplo, un investigador colaborador puede tener rol de análisis fiscal y rol de mantenimiento de infraestructura a la vez).
- Asignar un rol con acceso a secretos es decisión del investigador principal en consulta con la administración del CIEP. La decisión queda registrada en el gestor de secretos al momento de conceder el acceso.
- **Sobre el desarrollador externo de infraestructura:** este rol cubre a personas contratadas por el CIEP bajo régimen externo (honorarios, contrato de servicios) que operan infraestructura institucional (hosting, dominios, sistemas de gestión de contenido). A diferencia del investigador colaborador, no toca código de los Simuladores CIEP ni decisiones metodológicas; su trabajo es la operación de la infraestructura. El acceso de este rol es por infraestructura específica, no global. Las decisiones administrativas sobre quién recibe acceso (incorporación, modificación, revocación) las toma el investigador principal en consulta técnica con el desarrollador externo de infraestructura, no el desarrollador externo por sí mismo.

---

## 5. Procedimientos

*Qué aprendes en esta sección:* los cinco procedimientos operativos que materializan la política en el día a día.

### 5.1 Incorporación de personal al ecosistema de secretos

**Cuándo aplica:** cuando un nuevo colaborador entra al CIEP con un rol que requiere acceso a uno o más secretos.

1. El investigador principal define qué rol(es) tiene el nuevo colaborador y, en consecuencia, a qué secretos accede.
2. El investigador principal crea la cuenta del nuevo colaborador en el gestor de secretos institucional.
3. El investigador principal le concede acceso a los secretos correspondientes a su rol, con permisos de lectura (no de modificación, salvo justificación documentada).
4. El nuevo colaborador confirma que tiene acceso y reconoce por escrito (un correo de confirmación basta) las reglas de esta política, en particular la regla del §1.

### 5.2 Acceso temporal por solicitud

**Cuándo aplica:** cuando alguien con acceso permanente necesita delegar acceso a un colaborador por una ventana limitada — vacaciones del titular, renovación de certificado programada, intervención puntual de un consultor externo.

1. Identificar la(s) credencial(es) específica(s) requerida(s) y el periodo (idealmente medido en días, no semanas).
2. Crear el acceso en el gestor de secretos con caducidad configurada al final del periodo.
3. Notificar al receptor explicando duración, propósito y la regla del §1 (no propagar la credencial fuera del gestor).
4. Al expirar la caducidad, el gestor revoca el acceso automáticamente. No se requiere intervención manual del titular.

### 5.3 Salida de personal

**Cuándo aplica:** cuando un colaborador deja el CIEP, o cambia a un rol sin acceso a secretos.

1. El investigador principal revoca el acceso del colaborador a todos los secretos en el gestor de secretos institucional.
2. Revisar el log de auditoría para detectar accesos recientes inusuales. El objetivo es prevención, no sospecha por defecto.
3. Considerar rotación de credenciales especialmente sensibles (tokens API críticos, llaves SSH a servidores de producción) si la salida no fue amistosa o si el log muestra patrones inusuales.
4. Confirmar la revocación con un segundo procedimiento independiente cuando aplique. Por ejemplo: cambiar la contraseña root del VPS aunque el ex-colaborador no la tuviera directamente, si tuvo acceso reciente al servidor por otros caminos.

### 5.4 Compromiso de un secreto

**Cuándo aplica:** cuando se detecta o sospecha que un secreto fue expuesto — encontrado en código publicado, enviado por correo a destinatario equivocado, visible en pantalla compartida grabada, presente en una captura de pantalla, o cualquier otra ruta no autorizada.

1. **Asume lo peor.** Si hay duda, trata el secreto como expuesto y procede como si lo estuviera. El costo de una rotación innecesaria es bajo; el costo de no rotar un secreto realmente comprometido puede ser muy alto.
2. **Rotar la credencial** inmediatamente en el servicio externo correspondiente: generar nueva, revocar la vieja.
3. **Actualizar el gestor de secretos** institucional con el nuevo valor. Borrar el viejo del gestor para evitar confusión.
4. **Si el secreto está en código,** sustituirlo en la siguiente actualización del código. Si está expuesto en historia pública de Git, planear la reescritura de historia (operación destructiva, requiere coordinación específica con el investigador principal y con todos los colaboradores que tengan clones del repositorio).
5. **Registrar el incidente** en la bitácora del §6 de este documento. El registro no señala culpables; describe modo de exposición, respuesta, y mejora aplicada.

### 5.5 Rotación periódica

**Cuándo aplica:** como mantenimiento preventivo, sin que medie compromiso conocido.

Calendario sugerido (afinable con el investigador principal según riesgo del secreto):

- **Anual:** contraseñas de cuentas en servicios externos que no soportan llaves SSH o tokens (servicios que se acceden únicamente por contraseña tradicional).
- **Cada 6 meses:** tokens API de servicios de datos críticos (BIE de INEGI y similares). Mantener registro de la fecha de la última rotación en el gestor de secretos, junto a la credencial.
- **Cada renovación de certificado SSL:** llaves SSL del servidor web, si la renovación implica generar nueva llave (depende del flujo elegido).
- **Inmediato y sin esperar calendario:** cualquier credencial expuesta o sospechada de exposición, según §5.4.

### 5.6 Incorporación, modificación y salida de desarrolladores externos de infraestructura

**Cuándo aplica:** cuando una persona contratada por el CIEP bajo régimen externo va a operar infraestructura institucional (Cloudways, IONOS, u otras que el CIEP adopte en el futuro), o cuando un desarrollador externo de infraestructura existente cambia de alcance o deja de colaborar.

**Incorporación.** El procedimiento mínimo:

1. El investigador principal define qué infraestructura específica va a operar el nuevo desarrollador externo y con qué nivel de privilegio.
2. El investigador principal toma la decisión administrativa de otorgar acceso. Si hay un desarrollador externo de infraestructura ya activo en esa infraestructura (caso típico: incorporar a alguien a un equipo donde otro ya opera), puede consultar técnicamente con esa persona, pero la decisión sigue siendo del investigador principal.
3. Se crea cuenta en la infraestructura correspondiente con los privilegios mínimos necesarios para el trabajo definido (no más).
4. El nuevo desarrollador firma reconocimiento por escrito de las reglas de esta política, en particular el principio del §1 (cero secretos en canales informales).

**Modificación de alcance.** Si un desarrollador externo de infraestructura va a recibir acceso a una infraestructura adicional, o ampliar privilegios en la que ya opera, aplica el mismo procedimiento de incorporación para la infraestructura nueva o el privilegio nuevo. La decisión la toma el investigador principal.

**Salida.** Cuando un desarrollador externo de infraestructura deja de colaborar con el CIEP:

1. **Revocación inmediata de todos sus accesos** a las infraestructuras del CIEP. La revocación no se posterga aunque la salida sea amistosa.
2. **Rotación de credenciales** de las infraestructuras a las que tuvo acceso administrativo. Esto incluye cambiar contraseñas maestras de la cuenta (Cloudways, IONOS u otra), generar nuevas llaves SSH si las había, y cualquier otra credencial que él pudo haber conocido en años de operación.
3. **Período de transición previo a la salida (cuando es amistosa y planificada):** si la salida está agendada con anticipación, el desarrollador externo puede transferir conocimiento operativo en el período previo a la fecha de revocación. La transición NO es ventana de gracia post-revocación; es ventana de transferencia pre-revocación.
4. **Si la salida es conflictiva o súbita:** revocación inmediata y rotación sin período de transición. El conocimiento operativo se reconstruye desde lo que la documentación operativa del CIEP capture.

**Nota institucional sobre rotación:** la rotación tras la salida de un desarrollador externo de infraestructura no implica desconfianza personal. Es práctica estándar de seguridad institucional, aplicada por igual a salidas amistosas y conflictivas. Una vez que alguien sale del CIEP, las credenciales que conoció dejan de ser válidas, independientemente de la naturaleza de la salida.

---

## 6. Bitácora de incidentes

*Qué aprendes en esta sección:* el registro histórico de secretos comprometidos del CIEP, y cómo cada incidente refinó esta política.

> Esta política es viva. Cada vez que un secreto se compromete, se registra aquí el incidente, no para señalar culpables sino para que la política aprenda del caso.

| Fecha | Secreto afectado | Modo de exposición | Respuesta tomada | Mejora aplicada |
|---|---|---|---|---|
| 2018-10-29 a 2026-05-12 | Token API del Banco de Indicadores Económicos (BIE) de INEGI, cuenta institucional CIEP. | Hardcoded en `AccesoBIE.ado` y publicado en repositorio público de GitHub durante aproximadamente 7.5 años. | (1) Solicitud formal de revocación a INEGI por correo a `atencion.usuarios@inegi.org.mx` (2026-05-12). (2) Solicitud de token nuevo bajo correo distinto al original. (3) Pendiente: sustitución en código y reescritura de historia Git. | (4) Creación de esta política como respuesta institucional al incidente. (5) Decisión arquitectónica: tokens API jamás hardcoded; se leen de variable de entorno con fallback documentado. (6) `.gitignore` reforzado en mayo 2026 para prevenir entrada de archivos `.env` y similares al repositorio. |

Nuevos incidentes se registran como filas adicionales en la tabla, en orden cronológico ascendente.

---

## 7. Compromisos institucionales pendientes

*Qué aprendes en esta sección:* los compromisos que el CIEP asume al adoptar versiones específicas de esta política, con plazo explícito y criterio de revisión.

Esta sección lista compromisos institucionales que el CIEP asume al adoptar versiones específicas de esta política. Cada compromiso tiene plazo razonable. Si el plazo se cumple sin resolución, la política se actualiza en una iteración nueva para reflejar la realidad (extender plazo, cambiar estrategia, o aceptar el riesgo conscientemente).

### 7.1 Reducción del bus factor en Cloudways a ≥ 2

**Adoptado en:** v1.1 (2026-05-14). **Plazo:** 6-12 meses. **Fecha límite:** 14 de mayo de 2027.

Hasta la fecha de v1.1, la infraestructura Cloudways del CIEP tiene bus factor mixto: bus factor ≥ 2 para tareas operativas básicas (que el investigador principal puede ejecutar), y bus factor = 1 para tareas avanzadas (que solo el desarrollador externo de infraestructura Daniel Orduña conoce a fondo). El CIEP asume el compromiso de reducir el bus factor de las tareas avanzadas a ≥ 2 mediante al menos una de tres estrategias: (a) transferencia de conocimiento operativo del desarrollador externo de infraestructura al investigador principal, (b) documentación operativa escrita de las tareas avanzadas, o (c) incorporación de personal interno con capacidad de operar Cloudways.

Si al cumplirse el plazo el bus factor sigue siendo 1 para tareas avanzadas, la política se actualiza para reflejar la realidad.

---

## Apéndice A — Aplicación a los Simuladores CIEP y su infraestructura

*Qué aprendes en esta sección:* cómo los principios anteriores se aterrizan al caso concreto de los Simuladores CIEP y la infraestructura que los soporta.

### A.1 Inventario de secretos de los Simuladores CIEP y su infraestructura

A la fecha de esta versión (2026-05-14), los secretos asociados a los Simuladores CIEP y su infraestructura son:

- **Token API del BIE de INEGI** — usado por `AccesoBIE.ado` para extraer series económicas. Categoría: token API (§2).
- **Credenciales de la cuenta de correo `hostmaster.ciep.mx`** — usadas en la renovación del certificado SSL del sitio web público. Categoría: contraseña de correo institucional (§2).
- **Acceso root al VPS de IONOS** — donde corre el sitio `simuladorfiscal.ciep.mx`. Categoría: credencial de infraestructura (§2).
- **Llave privada del certificado SSL** del sitio web público. Categoría: llave SSH y certificado (§2).
- **Credenciales de la cuenta institucional del CIEP en Cloudways** — plataforma de hosting administrado donde el CIEP opera sitios y micrositios institucionales. La cuenta tiene acceso del investigador principal **y** del desarrollador externo de infraestructura (caso fundacional: Daniel Orduña, ver A.5). Categoría: credencial de infraestructura (§2).

### A.2 Quién tiene acceso (referencia a §4)

| Activo | Quién tiene acceso |
|---|---|
| Cuenta Cloudways del CIEP (superusuario) | Investigador principal (Ricardo Cantú) + Desarrollador externo de infraestructura (Daniel Orduña) |
| Cuenta IONOS del CIEP (VPS de los Simuladores CIEP) | Investigador principal (Ricardo Cantú) — solamente |
| Credenciales `hostmaster.ciep.mx` y llave privada del certificado SSL | Investigador principal; rol de mantenimiento de infraestructura cuando se incorpore |
| Token API del BIE de INEGI | Investigador principal — en migración tras incidente (ver §6) |

Investigadores CIEP que solo usan los Simuladores como herramienta no tienen acceso a ninguno de los anteriores.

### A.3 Estado actual del almacenamiento

A la fecha de esta versión, el CIEP **no ha adoptado formalmente** un gestor de secretos institucional. En esta ventana de transición, los secretos del Simulador viven en el gestor personal del investigador principal. Esto es práctica temporal, documentada honestamente — no objetivo. El propósito de hacerla explícita aquí es que cualquier lector externo, auditor o investigador colaborador entrante entienda el estado real, no una versión idealizada.

### A.4 Procedimiento de transición

Cuando la administración del CIEP, en consulta con el investigador principal, formalice la adopción de una herramienta de gestor de secretos institucional:

1. Crear las cuentas y la estructura de carpetas en la herramienta nueva.
2. Migrar los secretos del Apéndice A.1 desde el gestor personal del investigador principal hacia el gestor institucional.
3. Conceder accesos según la matriz del §4.
4. Actualizar este apéndice (A.3 y A.4) reflejando el nuevo estado.
5. Borrar las copias de los secretos del gestor personal del investigador principal, una vez verificada la migración.

La adopción formal del gestor institucional es prerrequisito para incorporar al primer investigador colaborador con rol de mantenimiento de infraestructura. No se incorpora personal con acceso a infraestructura antes de tener el gestor institucional operativo.

### A.5 Sobre Daniel Orduña como desarrollador externo de infraestructura

Daniel Orduña es el primer caso del rol "desarrollador externo de infraestructura" (§4) del CIEP. Su colaboración con el CIEP precede a la formalización de esta política y se ha caracterizado por buena fe operativa y conocimiento técnico profundo de Cloudways: dominios institucionales, configuración de WordPress, micrositios y resolución histórica de incidencias.

**Cambio de práctica reconocido en v1.1.** Hasta la fecha, las decisiones administrativas sobre quién recibe acceso a Cloudways se han tomado de facto por Daniel, dado su conocimiento operativo. La política v1.1 establece que hacia adelante esas decisiones las toma el investigador principal, en consulta técnica con Daniel. Esto es elevación del marco institucional, no crítica retrospectiva.

**Naturaleza de esta iteración:** punto de partida, no versión final. La política v1.1 se elabora con la información disponible al investigador principal. El investigador principal va a conversar con Daniel sobre el contenido de este documento — particularmente A.5 y §5.6 — para incorporar precisiones operativas que solo Daniel conoce (qué tareas específicas hace, qué procesos sigue, cómo resuelve clases de incidencias, qué decisiones técnicas pasadas merece documentar). Esa conversación está agendada como pendiente institucional. La política v1.2 capturará el conocimiento operativo que de ella surja.

**Compromiso institucional asociado:** el §7 de esta política establece el plazo de 6-12 meses para reducir el bus factor de Cloudways a ≥ 2. La conversación con Daniel descrita arriba es el primer paso de ese compromiso.

---

## Bitácora de cambios de este documento

| Fecha | Versión | Cambios |
|---|---|---|
| 2026-05-12 | 1.0 | Versión inicial. Articula el principio fundacional (cero secretos en código, documentación o canales informales), define categorías de secretos, criterios para el gestor institucional, matriz de acceso por rol, cinco procedimientos operativos (incorporación, acceso temporal, salida, compromiso, rotación), y la bitácora de incidentes arrancando con la exposición histórica del token BIE (2018-2026). Diseñada para ser portable a contextos institucionales hermanos; el apéndice A aplica la política al caso específico del Simulador Fiscal CIEP. |
| 2026-05-14 | 1.1 | Incorpora la categoría de rol **desarrollador externo de infraestructura** (§4): persona contratada por el CIEP bajo régimen externo (honorarios, contrato de servicios) que opera infraestructura institucional (hosting, dominios, sistemas de gestión de contenido) sin tocar código de los Simuladores CIEP. Acceso granular por infraestructura específica; las decisiones administrativas las toma el investigador principal en consulta técnica. Agrega **§5.6** con procedimientos de incorporación, modificación y salida del rol nuevo (la salida implica revocación inmediata más rotación de credenciales sin importar la naturaleza de la salida). Estrena **§7 (Compromisos institucionales pendientes)** con primer compromiso: reducir el bus factor de Cloudways a ≥ 2 en 6-12 meses (fecha límite 2027-05-14). Renombra el **Apéndice A** a *Aplicación a los Simuladores CIEP y su infraestructura*, agrega Cloudways al inventario (A.1), reformatea A.2 como tabla activo→acceso, e incorpora **A.5** sobre Daniel Orduña como caso fundacional del rol nuevo, con reconocimiento explícito del cambio de práctica (decisiones administrativas migran de facto a institución) y nota de que esta versión es punto de partida — la v1.2 capturará el input operativo de Daniel tras conversación pendiente. |
