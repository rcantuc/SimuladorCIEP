# Fuentes del método (PDF congelados)

Regla de la firma de CUAD-0 (§D, hoy §10 bis): ninguna frase del método nace fuera del repo; cada cita de CUAD-0 §10 y de CUAD-3 §10 apunta a un archivo de esta carpeta con su sha256, página y URL de origen.

| Archivo | Título | Origen (URL de descarga, 2026-10-31) | sha256 | Bytes |
|---|---|---|---|---|
| `702825068479.pdf` | INEGI, *Sistema de Cuentas Nacionales de México. Cuentas por sectores institucionales 2003-2013. Año base 2008. Fuentes y metodología. Primera versión* (2014), 117 pp. | https://www.inegi.org.mx/contenidos/productos/prod_serv/contenidos/espanol/bvinegi/productos/metodologias/SCNM/702825068479.pdf | `20ff0c4fa802ef4e76c3b0541da41682c3534135abf9a85b2d70a75990bcd56c` | 3,964,492 |
| `S2300345_es.pdf` | M. del Castillo Negrete, *La distribución del ingreso y la riqueza: nuevas aproximaciones conceptuales y metodológicas*, Documentos de Proyectos LC/TS.2023/44 – LC/MEX/TS.2023/8, CEPAL, Ciudad de México, 2023, 606 pp. (capítulo III §3 «Propuesta de ajuste de la información», pp. 230–240 del PDF; cuadro 69 p. 233; cuadro 74 p. 241; §5 «El truncamiento», pp. 268–273). Adjunto de Ricardo (CUAD-3, 2026-11-08) | (no en repo) el PDF lo adjuntó Ricardo el 2026-11-08 (archivo S2300345_es.pdf, Publicación de las Naciones Unidas S.23-00345); URL de la CEPAL por confirmar | `74c0c04869b507908aa479ae18ce6a172f8307c5296962256ff3a58a6ac5e4a7` | 10,364,197 |

Verificar: `shasum -a 256 02_governance/metodo/fuentes/*.pdf`. Las páginas citadas son las del PDF (numeración del visor), no las impresas.
