<?php
// metodo/plantilla.php — cabecera y pie de las páginas de MÉTODO del sitio
// (/NTA es la primera; las hermanas previstas: Población → PIB/Deflactor →
// Cuentas Nacionales → Expenditures → Households). Páginas estáticas de lectura:
// sin «Calcular», sin selector, sin sesión; los datos los sirve un PHP de solo
// lectura que lee en runtime lo que el motor ya exporta (jsonSankeyNTA.php, …).
//
// Cómo se agrega una hermana sin reescribir nada:
//   1. carpeta <Slug>/index.php en el docroot (la ruta es /<Slug>), con
//        require_once dirname(__DIR__) . '/metodo/plantilla.php';
//        metodo_cabecera(array('slug' => '<Slug>', 'titulo' => '…', 'lang' => 'en'));
//        … contenido …
//        metodo_pie(array('sankeys' => array(array('renderAt' => '…', 'url' => '/json….php?…'))));
//   2. su entrada en $METODO_PAGINAS (orden = orden de la sección);
//   3. su ruta en SITE_SMOKE_ASSETS de publicar-vps.sh (y la copia de
//      verify_sitio_autocontenido.sh) para que el esqueleto del deploy la cubra.
// Las rutas de activos son absolutas (/css, /js, /plugins) porque la página vive
// un nivel abajo del docroot.

// Índice de la sección, en el orden en que se leerá. Solo páginas que existen.
$METODO_PAGINAS = array(
	'NTA' => array('titulo' => 'Household NTA Sankey', 'lang' => 'en'),
);

// Metadatos del deploy (DEPLOYED_COMMIT lo escribe la Fase 4 de publicar-vps.sh
// en el docroot, desde 05_scripts/manifest.json). Misma lectura tolerante que
// index.php: archivo ausente o línea ausente → "" y la página no pinta ese dato.
// Nunca un fatal; ningún valor de respaldo escrito aquí.
function metodo_meta_deploy() {
	$meta = array('version' => '', 'version_html' => '', 'data_updated_iso' => '', 'release_url' => '', 'enigh_vintage' => '', 'commit' => '');
	$archivo = dirname(__DIR__) . '/DEPLOYED_COMMIT';
	if (!is_readable($archivo)) return $meta;
	$lineas = @file($archivo, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
	if ($lineas === false) return $meta;
	$claves = array('Version:' => 'version', 'DataUpdated:' => 'data_updated_iso', 'ReleaseUrl:' => 'release_url', 'EnighVintage:' => 'enigh_vintage', 'Commit:' => 'commit');
	foreach ($lineas as $l) {
		foreach ($claves as $prefijo => $k) {
			if (strpos($l, $prefijo) === 0) $meta[$k] = trim(substr($l, strlen($prefijo)));
		}
	}
	if ($meta['version'] !== '') {
		$meta['version_html'] = htmlspecialchars($meta['version']);
		if (strpos($meta['release_url'], 'https://github.com/') === 0) {
			$meta['version_html'] = '<a href="' . htmlspecialchars($meta['release_url']) . '" target="_blank" rel="noopener noreferrer" style="color: inherit; text-decoration: underline dotted;">' . $meta['version_html'] . '</a>';
		}
	}
	return $meta;
}

function metodo_cabecera(array $p) {
	global $METODO_PAGINAS;
	$slug = $p['slug'];
	$titulo = $p['titulo'] ?? ($METODO_PAGINAS[$slug]['titulo'] ?? $slug);
	$lang = $p['lang'] ?? 'en';
	$descripcion = $p['descripcion'] ?? $titulo;
	$t = htmlspecialchars($titulo);
	$d = htmlspecialchars($descripcion);
	echo <<<HTML
<!DOCTYPE html>
<html lang="{$lang}">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="icon" type="image/x-icon" href="/favicon.ico">
	<meta name="description" content="{$d}">
	<meta name="author" content="CIEP">
	<title>{$t} · Simulador Fiscal CIEP</title>
	<link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:ital,wght@0,300;0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">
	<link href="/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet">
	<link href="/css/admin2.css?v=17" rel="stylesheet">
	<link href="/css/custom.css" rel="stylesheet">
	<link href="/css/metodo.css" rel="stylesheet">
</head>
<body class="metodo">
	<header class="metodo-header">
		<div class="container">
			<a href="/" class="metodo-logo"><img src="/images/logo-sim-fiscal-ciep-b.png" width="69" height="73" alt="Simulador Fiscal CIEP"></a>
			<nav class="metodo-nav" aria-label="Method">
				<a href="/">Simulador Fiscal CIEP</a>
				<span class="sep">›</span>
				<span class="metodo-seccion">Method</span>
HTML;
	foreach ($METODO_PAGINAS as $s => $pag) {
		$activa = ($s === $slug) ? ' class="activa" aria-current="page"' : '';
		echo "\n\t\t\t\t<span class=\"sep\">›</span>\n\t\t\t\t<a href=\"/" . htmlspecialchars($s) . "/\"{$activa}>" . htmlspecialchars($pag['titulo']) . "</a>";
	}
	echo <<<HTML

			</nav>
		</div>
	</header>
	<main class="container metodo-main">
		<h1 class="metodo-titulo">{$t}</h1>

HTML;
}

// $p['sankeys']: lista de array('renderAt' => id del div, 'url' => endpoint JSON).
// Cada uno se dibuja con FusionCharts desde /js/metodo-sankey.js (misma librería,
// misma configuración que los Sankeys de la portada; los datos llegan del PHP,
// aquí no hay números).
function metodo_pie(array $p = array()) {
	$meta = metodo_meta_deploy();
	$fuente = $p['fuente'] ?? null;
	echo "\n\t</main>\n";
	if ($fuente !== null) {
		echo "\t<footer class=\"container metodo-fuente\">\n\t\t<p>" . $fuente($meta) . "</p>\n\t</footer>\n";
	}
	$copy = '&#9400; ' . date('Y') . ' | Simulador Fiscal CIEP - ricardocantu@ciep.mx';
	if ($meta['version_html'] !== '') $copy .= ' | Versi&oacute;n ' . $meta['version_html'];
	echo "\t<footer class=\"container metodo-pie\"><small>{$copy}</small></footer>\n";
	$sankeys = json_encode($p['sankeys'] ?? array(), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
	echo <<<HTML
	<script src="https://cdn.fusioncharts.com/fusioncharts/latest/fusioncharts.js"></script>
	<script src="https://cdn.fusioncharts.com/fusioncharts/latest/themes/fusioncharts.theme.fusion.js"></script>
	<script src="/plugins/jquery/jquery-3.4.1.min.js"></script>
	<script src="/js/metodo-sankey.js"></script>
	<script>metodoSankeys({$sankeys});</script>
</body>
</html>

HTML;
}
?>
