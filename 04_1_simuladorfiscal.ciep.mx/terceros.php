<?php
// terceros.php — scripts de otro origen que el sitio carga: versión fija y SRI (Subresource Integrity).
// Solo define funciones: no imprime nada, así que pedirlo por URL no entrega nada.
//
// Por qué (incidente del 2026-11-20): el download.js de danml.com que cargaba el simulador de tabaco traía código malicioso.
// Un <script> a una URL «latest» y sin `integrity` ejecuta lo que el proveedor publique ese día. Aquí cada archivo de
// terceros va con su versión en la URL y su hash sha384: si el CDN sirve un byte distinto, el navegador no lo ejecuta.
//
// FusionCharts queda en su CDN (no en plugins/) porque su licencia (FusionCharts Master Software License Agreement, Idera,
// ver. 010126) no permite redistribuirlo, y este repo es público. jQuery UI y ekko-lightbox (MIT) sí viven en plugins/.
//
// FusionCharts pide por su cuenta, desde la carpeta de fusioncharts.js, el módulo de cada tipo de gráfica que no trae el
// núcleo (el Sankey vive en fusioncharts.powercharts.js). Una petición así no lleva integrity, así que cada módulo que el
// sitio usa va aquí explícito, antes de dibujar. 05_scripts/pruebas/prueba-sitio-terceros.sh falla si alguna página pide
// a cdn.fusioncharts.com algo que no está en esta lista.
//
// Para cambiar de versión: bajar los archivos de cdn.fusioncharts.com/fusioncharts/<versión>/, compararlos contra el paquete
// npm fusioncharts@<versión>, sacar cada hash (openssl dgst -sha384 -binary <archivo> | openssl base64 -A), cambiar versión y
// hashes juntos, y correr prueba-sitio-terceros.sh y la comparación de capturas de las páginas con gráficas.

function fusioncharts_version() {
	return '4.2.3';
}

// Archivo (relativo a la carpeta de la versión) => hash SRI. El orden es el de carga: el núcleo primero.
function fusioncharts_archivos() {
	return array(
		'fusioncharts.js' => 'sha384-u6RZFm49AylGpA3qjtZgobGeXwrs2Yeat3SwBSCko0ekmIJn/tiVtGTmpNj7WoHd',
		'fusioncharts.powercharts.js' => 'sha384-PbrOfbduuziyMFGx13Su6ztyeduJtchgKLD/Y77dBPKbgInkbOtP5vsr18eFesBD',
		'themes/fusioncharts.theme.fusion.js' => 'sha384-Kvl5GC3qA+qHTOu0YbgVKNsg81rmxxg1Ge3PoWW1Y+ncG4M1zKYyFv0NghwO0U3s',
	);
}

// Las etiquetas <script> de FusionCharts, una por línea; $sangria antecede a la segunda y siguientes.
function fusioncharts_scripts($sangria = "\t") {
	$base = 'https://cdn.fusioncharts.com/fusioncharts/' . fusioncharts_version() . '/';
	$tags = array();
	foreach (fusioncharts_archivos() as $archivo => $sri) {
		$tags[] = '<script src="' . $base . $archivo . '" integrity="' . $sri . '" crossorigin="anonymous"></script>';
	}
	return implode("\n" . $sangria, $tags);
}
?>
