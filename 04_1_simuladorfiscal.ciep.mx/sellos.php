<?php
// sellos.php — sello de versión de los recursos propios del sitio (CSS, JavaScript y datos).
// Solo define funciones: no imprime nada, así que pedirlo por URL no entrega nada.
//
// Un recurso sin sello (`?v=…`) lo reutiliza el navegador o un proxy con el contenido de la visita anterior, y tras un
// deploy la página nueva puede armarse con un CSS, un JS o un JSON viejos. Dos sellos, los dos derivados de lo que se sirve:
//   - archivo estático del docroot (CSS, JS, JSON): los primeros 10 hex del sha1 de SU contenido. Cambia el archivo, cambia
//     el sello; un deploy que no lo toca no invalida nada.
//   - dato servido por un PHP (jsonEntidad.php, jsonSankeyNTA.php, …): sello del BUILD, los primeros 10 hex del sha1 de
//     DEPLOYED_COMMIT (lo escribe la Fase 4 de publicar-vps.sh en cada deploy, junto a este archivo). Esos PHP leen
//     users/ciepmx/, que viaja con el deployment: nuevo deployment, nuevo sello. Sin DEPLOYED_COMMIT (desarrollo local)
//     el sello se deriva de la fecha de este archivo y de index.php.
// Quedan sin sello a propósito: plugins/ (terceros, versionados por su carpeta; jQuery UI y ekko-lightbox, traídos del CDN
// al repo el 2026-11-20, llevan además `?v=`), los POST de la portada (no se cachean),
// imágenes, fuentes e íconos. 05_scripts/pruebas/prueba-sitio-sellos.sh (CI) falla si una página carga un recurso propio de datos,
// CSS o JS sin sello, o con uno que no corresponde.

// Sello del build: el mismo para todo dato servido por un PHP.
function sello_build() {
	static $build = null;
	if ($build === null) {
		$archivo = __DIR__ . '/DEPLOYED_COMMIT';
		$build = is_readable($archivo)
			? substr((string)sha1_file($archivo), 0, 10)
			: substr(sha1((string)@filemtime(__FILE__) . '|' . (string)@filemtime(__DIR__ . '/index.php')), 0, 10);
	}
	return $build;
}

// Sello (solo el valor) de un recurso propio. $ruta: la del sitio, con o sin `/` inicial y con o sin query.
function sello_valor($ruta) {
	$camino = explode('?', $ruta, 2)[0];
	$archivo = __DIR__ . '/' . ltrim($camino, '/');
	if (preg_match('/\.php$/i', $camino) || strpos($camino, '..') !== false || !is_file($archivo)) {
		return sello_build();
	}
	return substr((string)sha1_file($archivo), 0, 10);
}

// La misma ruta con `v=<sello>` agregado (`?` o `&` según corresponda). Absoluta ('/css/metodo.css') o relativa a la
// página ('css/custom.css'): se devuelve en la forma en que llegó.
function sello_url($ruta) {
	static $memo = array();
	if (!isset($memo[$ruta])) {
		$memo[$ruta] = $ruta . (strpos($ruta, '?') === false ? '?' : '&') . 'v=' . sello_valor($ruta);
	}
	return $memo[$ruta];
}

// Mapa que las páginas de método ponen en window.CIEP_SELLOS para js/metodo-sankey.js (selloUrl): el sello del build, que
// el prefiltro de $.ajax agrega a todo GET propio, y el sello de contenido de los JSON que lee js/metodo-capitulo.js.
function sello_mapa_js() {
	$archivos = array();
	foreach (array('/metodo/metodo.json', '/metodo/metodo-en.json') as $ruta) {
		$archivos[$ruta] = sello_valor($ruta);
	}
	return json_encode(array('build' => sello_build(), 'archivos' => $archivos), JSON_UNESCAPED_SLASHES);
}
?>
