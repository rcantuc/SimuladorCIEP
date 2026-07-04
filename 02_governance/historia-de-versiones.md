# Historia de versiones del SimuladorCIEP

Este documento traza la evolución del Simulador Fiscal CIEP desde proyecto personal hacia infraestructura institucional. Sirve como contexto para entender los releases publicados en GitHub y la trayectoria del proyecto.

## Modelo de versiones

El proyecto distingue dos eras:

**Era v7.x — transición.** Cubre los pasos sucesivos desde el Simulador como proyecto personal del investigador principal hacia el Simulador como infraestructura institucional documentada. Cada release v7.x marca un avance específico de esa transición; ninguno representa el estado final.

**Era v8.0+ — institucional completo.** v8.0 marcará la primera versión donde el Simulador opera completamente bajo arquitectura institucional: data sidecar publicado, código migrado a la lógica manifest-driven, tests pasando end-to-end, governance documentada y verificada. Las versiones citables y replicables empiezan en v8.0; los releases posteriores (v8.1, v8.2.1, etc.) son los apropiados para citarse en publicaciones académicas y análisis institucionales.

## El estado previo a la transición — snapshot pre-rewrite

Antes de mayo de 2026, el Simulador Fiscal CIEP existió por aproximadamente 16 años (2010-2026) como conjunto de archivos en la computadora del investigador principal y como cuerpo de decisiones metodológicas en su cabeza. Era código funcional pero no infraestructura institucional: no había política explícita de gestión de secretos, no había arquitectura de distribución documentada, los datos binarios pesados se distribuían vía URLs personales de Dropbox, y el conocimiento operativo dependía epistémica y operativamente de una sola persona.

Esa etapa quedó marcada internamente como "v7.0 — Último estado del Simulador como proyecto personal" en un tag de Git que apuntaba al commit `2f46d92` ("Carpeta Raw", 30 de abril de 2026). Ese commit y ese tag forman parte del historial pre-rewrite del repositorio. El rewrite de seguridad de mayo de 2026 (que purgó credenciales expuestas y binarios pesados de la historia) reescribió todos los SHAs del repo; el commit `2f46d92` ya no es referenciable desde la rama `master` actual.

Este documento preserva la narrativa de ese momento histórico sin depender de un tag de Git apuntando a un commit huérfano.

## Releases publicados en GitHub

Cada release publicado representa un punto específico en la transición. Su contexto, alcance, y referencias a commits están documentados en las notas del release respectivo en GitHub Releases (`https://github.com/rcantuc/SimuladorCIEP/releases`).

A partir de v8.0, esta sección se actualizará para clarificar qué versiones son aptas para citarse en publicaciones formales.

## Notas para futuras versiones

Cuando la era v8.x inicie, vale considerar:

- Documentar explícitamente qué constituye un release "completo" (criterios de cierre para una versión)
- Establecer convención de cuándo bumpear major vs minor vs patch (v8.x.y semver-style)
- Política sobre cómo se referencia el Simulador en publicaciones académicas del CIEP
- Eventualmente, considerar publicación con DOI vía Zenodo o similar para los releases citables
