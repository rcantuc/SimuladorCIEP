* PLANTILLA OPCIONAL — el Simulador funciona sin esto.
* AccesoBIE trae un token de cortesía CIEP para la API de Indicadores del INEGI: público por diseño, dueño
* info@ciep.mx. El valor vive en un solo lugar: la constante BIE_TOKEN_CORTESIA de AccesoBIE.ado
* (política: 02_governance/politicas-institucionales.md, Parte I §3.4).
* Configura este archivo SOLO si quieres usar tu propia cuota del INEGI (replicaciones, descargas masivas):
*   1. Solicita tu token gratuito (uno por correo) en: https://www.inegi.org.mx/servicios/api-indicadores/
*      El token se activa por servicio: uno del DENUE no sirve aquí hasta registrarlo también en Indicadores.
*   2. Copia este archivo como `set_token.do` (mismo directorio) y reemplaza abajo con tu token.
* `set_token.do` está en .gitignore y nunca se versiona; esta plantilla SÍ se versiona.
global BIE_API_TOKEN "tu-token-aqui"
