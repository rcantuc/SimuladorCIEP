<?php
// metodo/plantilla.php — cabecera y pie de las páginas de MÉTODO del sitio
// (/NTA es la primera; /entidades y sus 32 páginas /entidades/<ABREV> desde v8.13.0; las hermanas
// previstas: Población → PIB/Deflactor → Cuentas Nacionales → Expenditures → Households). Páginas estáticas de lectura:
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
	'entidades' => array('titulo' => 'States', 'lang' => 'en'),
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
	// $p['migas'] (v8.13.0, entidades): migas extra debajo de la página de la sección (p. ej. la entidad bajo
	// /entidades); cada una array('href' => …, 'texto' => …). La última es la página actual (activa); la
	// página de la sección deja de marcarse activa cuando hay migas.
	$migas = $p['migas'] ?? array();
	foreach ($METODO_PAGINAS as $s => $pag) {
		$activa = ($s === $slug && !$migas) ? ' class="activa" aria-current="page"' : '';
		echo "\n\t\t\t\t<span class=\"sep\">›</span>\n\t\t\t\t<a href=\"/" . htmlspecialchars($s) . "/\"{$activa}>" . htmlspecialchars($pag['titulo']) . "</a>";
	}
	foreach (array_values($migas) as $i => $miga) {
		$activa = ($i === count($migas) - 1) ? ' class="activa" aria-current="page"' : '';
		echo "\n\t\t\t\t<span class=\"sep\">›</span>\n\t\t\t\t<a href=\"" . htmlspecialchars($miga['href']) . "\"{$activa}>" . htmlspecialchars($miga['texto']) . "</a>";
	}
	echo <<<HTML

			</nav>
		</div>
	</header>
	<main class="container metodo-main">
		<h1 class="metodo-titulo">{$t}</h1>

HTML;
}

// Notas al pie numeradas (v8.12.5). En el texto, echo metodo_nota_ref(1) (en la plantilla
// corta de PHP) pinta el superíndice ¹ como enlace a la nota (#nota-1) con ancla de regreso
// (#ref-1); ojo: no escribir la etiqueta de cierre de PHP dentro de un comentario. Al final del
// apartado: metodo_notas(array(1 => '<html de la nota>', …)) pinta la lista, cada nota con su
// número y el enlace ↩ de regreso al superíndice. Estilo en css/metodo.css (.metodo-notas).
// Las hermanas usan lo mismo: la numeración es por página.
function metodo_nota_ref($n) {
	$n = (int)$n;
	return '<sup class="metodo-nota-ref" id="ref-' . $n . '"><a href="#nota-' . $n . '" aria-label="Note ' . $n . '">' . $n . '</a></sup>';
}

function metodo_notas(array $notas) {
	if (!$notas) return;
	echo "\t\t<ol class=\"metodo-notas\">\n";
	foreach ($notas as $n => $html) {
		$n = (int)$n;
		echo "\t\t\t<li id=\"nota-{$n}\" value=\"{$n}\">{$html} <a class=\"metodo-nota-volver\" href=\"#ref-{$n}\" aria-label=\"Back to the text\">&#8617;</a></li>\n";
	}
	echo "\t\t</ol>\n";
}

// $p['sankeys']: lista de array('renderAt' => id del div, 'url' => endpoint JSON).
// Cada uno se dibuja con FusionCharts desde /js/metodo-sankey.js (misma librería,
// misma configuración que los Sankeys de la portada; los datos llegan del PHP,
// aquí no hay números).
// $p['cifras']: array('url' => endpoint JSON de la cuenta) → metodoCifras() llena los
// <span data-nta="…"> de la página con los valores de ese JSON (cero números en el PHP).
// $p['panel'] (v8.12.6, NTA-3): array('url' => endpoint JSON del panel, 'contenedor' => id base de los
// <div> de los mini-Sankeys, 'selector' => name de los radios T/H/M) → metodoPanel() dibuja los cinco
// mini-Sankeys por grupo de edad y cambia de sexo sin recargar.
// $p['scripts'] (v8.13.0, entidades): rutas de <script src> adicionales (p. ej. /plugins/apexcharts/… y
// /js/entidad.js), cargados después de metodo-sankey.js; $p['init']: una llamada JS (cadena) que corre al
// final (p. ej. entidadPagina({...}) con su configuración en JSON). Sin números: la configuración son rutas e ids.
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
	$cifras = isset($p['cifras']) ? "\n\t<script>metodoCifras(" . json_encode($p['cifras'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . ");</script>" : '';
	$panel = isset($p['panel']) ? "\n\t<script>metodoPanel(" . json_encode($p['panel'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . ");</script>" : '';
	$scripts = '';
	foreach ($p['scripts'] ?? array() as $src) {
		$scripts .= "\n\t<script src=\"" . htmlspecialchars($src) . "\"></script>";
	}
	$init = isset($p['init']) ? "\n\t<script>" . $p['init'] . "</script>" : '';
	echo <<<HTML
	<script src="https://cdn.fusioncharts.com/fusioncharts/latest/fusioncharts.js"></script>
	<script src="https://cdn.fusioncharts.com/fusioncharts/latest/themes/fusioncharts.theme.fusion.js"></script>
	<script src="/plugins/jquery/jquery-3.4.1.min.js"></script>
	<script src="/js/metodo-sankey.js"></script>{$scripts}
	<script>metodoSankeys({$sankeys});</script>{$cifras}{$panel}{$init}
</body>
</html>

HTML;
}
?>
