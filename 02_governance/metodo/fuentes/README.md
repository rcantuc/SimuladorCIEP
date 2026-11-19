# Fuentes del método (PDF de terceros, citados por liga oficial y sha256)

Regla de la firma de CUAD-0 (§D, hoy §10 bis): ninguna frase del método nace fuera del repo; cada cita de CUAD-0 §10 y de CUAD-3 §10 apunta a un archivo de esta tabla con su sha256, página y liga oficial. Los PDF son de terceros (INEGI, CEPAL) y no se redistribuyen: desde la limpieza de 2026-11 no están en el árbol (siguen en la historia de git hasta v8.19.1). Quien necesite el archivo exacto lo baja de la liga oficial y comprueba el sha256; la verificación del 2026-11-19 dio los mismos bytes que las copias congeladas el 2026-10-31 y el 2026-11-08.

| Archivo | Título | Liga oficial (verificada por sha256 el 2026-11-19) | sha256 | Bytes |
|---|---|---|---|---|
| `702825068479.pdf` | INEGI, *Sistema de Cuentas Nacionales de México. Cuentas por sectores institucionales 2003-2013. Año base 2008. Fuentes y metodología. Primera versión* (2014), 117 pp. | https://www.inegi.org.mx/contenidos/productos/prod_serv/contenidos/espanol/bvinegi/productos/metodologias/SCNM/702825068479.pdf | `20ff0c4fa802ef4e76c3b0541da41682c3534135abf9a85b2d70a75990bcd56c` | 3,964,492 |
| `S2300345_es.pdf` | M. del Castillo Negrete, *La distribución del ingreso y la riqueza: nuevas aproximaciones conceptuales y metodológicas*, Documentos de Proyectos LC/TS.2023/44 – LC/MEX/TS.2023/8, CEPAL, Ciudad de México, 2023, 606 pp. (capítulo III §3 «Propuesta de ajuste de la información», pp. 230–240 del PDF; cuadro 69 p. 233; cuadro 74 p. 241; §5 «El truncamiento», pp. 268–273). Adjunto de Ricardo (CUAD-3, 2026-11-08) | https://hdl.handle.net/11362/48821 · https://repositorio.cepal.org/server/api/core/bitstreams/137bcd3c-aa23-460e-89e0-d96a543b83c9/content | `74c0c04869b507908aa479ae18ce6a172f8307c5296962256ff3a58a6ac5e4a7` | 10,364,197 |

Verificar (fuera del repo):

```bash
curl -sSLo 702825068479.pdf 'https://www.inegi.org.mx/contenidos/productos/prod_serv/contenidos/espanol/bvinegi/productos/metodologias/SCNM/702825068479.pdf'
curl -sSLo S2300345_es.pdf 'https://repositorio.cepal.org/server/api/core/bitstreams/137bcd3c-aa23-460e-89e0-d96a543b83c9/content'
shasum -a 256 702825068479.pdf S2300345_es.pdf
```

Si la liga deja de servir esos bytes, la copia exacta está en la historia de git: `git show v8.19.1:02_governance/metodo/fuentes/<archivo> > <archivo>`. Las páginas citadas son las del PDF (numeración del visor), no las impresas.
