<?php
// plantilla-metodo.php — cabecera y pie de las páginas de MÉTODO del sitio (hasta 8.18 vivía en metodo/plantilla.php;
// se movió a la raíz porque /metodo es ahora la sección generada por 05_scripts/metodo.py: índice, cap0 y un capítulo por
// módulo, en español). /NTA fue la primera; /entidades y sus 32 páginas /entidades/<ABREV> desde v8.13.0. Páginas estáticas de lectura:
// sin «Calcular», sin selector, sin sesión; los datos los sirve un PHP de solo
// lectura que lee en runtime lo que el motor ya exporta (jsonSankeyNTA.php, …).
//
// Cómo se agrega una hermana sin reescribir nada:
//   1. carpeta <Slug>/index.php en el docroot (la ruta es /<Slug>), con
//        require_once dirname(__DIR__) . '/plantilla-metodo.php';
//        metodo_cabecera(array('slug' => '<Slug>', 'titulo' => '…', 'lang' => 'en'));
//        … contenido …
//        metodo_pie(array('sankeys' => array(array('renderAt' => '…', 'url' => '/json….php?…'))));
//   2. su entrada en $METODO_PAGINAS (orden = orden de la sección);
//   3. su ruta en SITE_SMOKE_ASSETS de publicar-vps.sh (y la copia de
//      verify_sitio_autocontenido.sh) para que el esqueleto del deploy la cubra.
// Las rutas de activos son absolutas (/css, /js, /plugins) porque la página vive
// un nivel abajo del docroot.

// Índice de la sección, en el orden en que se leerá. Solo páginas que existen. 'lang' es el idioma en que se escribió la
// sección (el default de su URL sin ?lang=); 'titulo' va en los dos idiomas (8.19: el sitio de método es bilingüe).
$METODO_PAGINAS = array(
	'metodo' => array('titulo' => array('es' => 'Capítulos', 'en' => 'Chapters'), 'lang' => 'es'),   // /metodo: el rótulo de la sección ya dice «Método»; la entrada es el índice de capítulos
	'NTA' => array('titulo' => array('es' => 'Sankey NTA de los hogares', 'en' => 'Household NTA Sankey'), 'lang' => 'en'),
	'entidades' => array('titulo' => array('es' => 'Entidades', 'en' => 'States'), 'lang' => 'en'),
);

// Idioma (8.19). Cada sección tiene el suyo por default ($METODO_PAGINAS[slug]['lang']); ?lang=es|en lo cambia (lista
// blanca: cualquier otro valor se ignora). metodo_lang() devuelve el idioma ya resuelto de la página; las páginas lo
// llaman antes de metodo_cabecera() para escoger su texto. metodo_url() arma un enlace interno que conserva el idioma
// (solo agrega ?lang= cuando difiere del default de la sección destino).
function metodo_lang($defecto = null) {
	static $lang = null;
	if ($lang === null || $defecto !== null) {
		$pedido = isset($_GET['lang']) && is_string($_GET['lang']) ? $_GET['lang'] : '';
		$lang = in_array($pedido, array('es', 'en'), true) ? $pedido : ($defecto === 'en' ? 'en' : ($defecto === 'es' ? 'es' : ($lang ?? 'es')));
	}
	return $lang;
}

function metodo_url($ruta, $slug_destino = null) {
	global $METODO_PAGINAS;
	$lang = metodo_lang();
	if ($ruta === '/' || $slug_destino === '') {
		return $lang === 'en' ? '/index-en.php' : '/';
	}
	$defecto = $METODO_PAGINAS[$slug_destino]['lang'] ?? 'es';
	return $lang === $defecto ? $ruta : $ruta . '?lang=' . $lang;
}

// Texto en el idioma de la página: una cadena se usa tal cual; un array('es' => …, 'en' => …) se resuelve.
function metodo_t($texto) {
	if (is_array($texto)) {
		$lang = metodo_lang();
		return $texto[$lang] ?? reset($texto);
	}
	return $texto;
}

// Metadatos del deploy (DEPLOYED_COMMIT lo escribe la Fase 4 de publicar-vps.sh
// en el docroot, desde 05_scripts/manifest.json). Misma lectura tolerante que
// index.php: archivo ausente o línea ausente → "" y la página no pinta ese dato.
// Nunca un fatal; ningún valor de respaldo escrito aquí.
function metodo_meta_deploy() {
	$meta = array('version' => '', 'version_html' => '', 'data_updated_iso' => '', 'release_url' => '', 'enigh_vintage' => '', 'commit' => '');
	$archivo = __DIR__ . '/DEPLOYED_COMMIT';   // 8.19: la plantilla vive en la raíz del docroot desde 8.18 (antes en metodo/, de ahí el dirname)
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
	$lang = metodo_lang($p['lang'] ?? ($METODO_PAGINAS[$slug]['lang'] ?? 'en'));
	$titulo = metodo_t($p['titulo'] ?? ($METODO_PAGINAS[$slug]['titulo'] ?? $slug));
	$descripcion = metodo_t($p['descripcion'] ?? $titulo);
	$t = htmlspecialchars($titulo);
	$d = htmlspecialchars($descripcion);
	$rotulo = ($lang === 'es') ? 'Método' : 'Method';
	// Banderas (8.19): el idioma activo es el de la página; cada bandera recarga la misma página con ?lang=.
	$act_en = ($lang === 'en') ? ' active' : '';
	$act_es = ($lang === 'es') ? ' active' : '';
	$inicio = htmlspecialchars(metodo_url('/'));
	$alt_logo = 'Simulador Fiscal CIEP';
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
		<div class="container metodo-header-fila">
			<a href="{$inicio}" class="metodo-logo" aria-label="{$alt_logo}"><img src="/images/logo-sim-fiscal-ciep.png" alt="Simulador Fiscal CIEP" width="117" height="41"></a>
			<div class="metodo-header-der">
				<a href="https://ciep.mx/" target="_blank" rel="noopener" class="metodo-header-ciep" aria-label="CIEP"><img src="/images/ciep-logo1.png" alt="CIEP" width="107" height="26"></a>
				<ul class="metodo-social">
					<li><a href="http://facebook.com/ciepmx" target="_blank" rel="noopener" aria-label="Facebook"><img src="/images/f-icon-facebook.svg" alt=""></a></li>
					<li><a href="https://twitter.com/ciepmx" target="_blank" rel="noopener" aria-label="X"><img src="/images/f-icon-twitter.svg" alt=""></a></li>
					<li><a href="https://www.youtube.com/user/CIEPMX" target="_blank" rel="noopener" aria-label="YouTube"><img src="/images/f-icon-youtube.svg" alt=""></a></li>
				</ul>
				<div class="metodo-lang" aria-label="Language / Idioma">
					<a href="?lang=en" class="lang-item{$act_en}" hreflang="en" lang="en" title="English"><img src="/images/lang-en.svg" alt="English"></a>
					<a href="?lang=es" class="lang-item{$act_es}" hreflang="es" lang="es" title="Español"><img src="/images/lang-es.svg" alt="Español"></a>
				</div>
			</div>
		</div>
		<nav class="metodo-migas" aria-label="{$rotulo}">
			<div class="container metodo-nav">
				<div class="metodo-nav-migas">
HTML;
	// Migas (a la izquierda): Simulador Fiscal CIEP › Método › Capítulos › <capítulo>. NTA y States no cuelgan de /metodo: son
	// secciones aparte, y en su propia página la miga es Simulador Fiscal CIEP › <sección> (› <entidad>). $p['migas'] (v8.13.0):
	// migas extra debajo de la sección; cada una array('href' => …, 'texto' => …). La última es la página actual (activa).
	$migas = $p['migas'] ?? array();
	$ruta = array(array('href' => metodo_url('/'), 'texto' => 'Simulador Fiscal CIEP'));
	if ($slug === 'metodo') {
		$ruta[] = array('href' => metodo_url('/metodo/', 'metodo'), 'texto' => $rotulo);
		$ruta[] = array('href' => metodo_url('/metodo/', 'metodo'), 'texto' => metodo_t($METODO_PAGINAS['metodo']['titulo']));
	} else {
		$ruta[] = array('href' => metodo_url('/' . $slug . '/', $slug), 'texto' => isset($METODO_PAGINAS[$slug]) ? metodo_t($METODO_PAGINAS[$slug]['titulo']) : $titulo);
	}
	foreach ($migas as $miga) {
		$miga['texto'] = metodo_t($miga['texto']);
		if (strpos($miga['href'], '/') === 0 && strpos($miga['href'], '?') === false) {
			$miga['href'] = metodo_url($miga['href'], $slug);   // la miga extra vive dentro de la sección
		}
		$ruta[] = $miga;
	}
	foreach ($ruta as $i => $miga) {
		$activa = ($i === count($ruta) - 1) ? ' class="activa" aria-current="page"' : '';
		if ($i > 0) {
			echo "\n\t\t\t\t\t<span class=\"sep\">›</span>";
		}
		echo "\n\t\t\t\t\t<a href=\"" . htmlspecialchars($miga['href']) . "\"{$activa}>" . htmlspecialchars($miga['texto']) . "</a>";
	}
	// Accesos (a la derecha): las tres secciones (Método, NTA, States), siempre visibles, con la actual resaltada: desde NTA o States
	// se vuelve a Método sin pasar por las migas.
	echo "\n\t\t\t\t</div>\n\t\t\t\t<div class=\"metodo-nav-accesos\">";
	foreach ($METODO_PAGINAS as $s => $pag) {
		$propia = ($s === $slug) ? ' class="propia" aria-current="location"' : '';
		$texto = ($s === 'metodo') ? $rotulo : metodo_t($pag['titulo']);   // el índice de /metodo se llama «Capítulos» en las migas; aquí es la sección
		echo "\n\t\t\t\t\t<a href=\"" . htmlspecialchars(metodo_url('/' . $s . '/', $s)) . "\"{$propia}>" . htmlspecialchars($texto) . "</a>";
	}
	echo <<<HTML

				</div>
			</div>
		</nav>
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
	$rot = metodo_lang() === 'es' ? 'Nota ' : 'Note ';
	return '<sup class="metodo-nota-ref" id="ref-' . $n . '"><a href="#nota-' . $n . '" aria-label="' . $rot . $n . '">' . $n . '</a></sup>';
}

function metodo_notas(array $notas) {
	if (!$notas) return;
	$volver = metodo_lang() === 'es' ? 'Volver al texto' : 'Back to the text';
	echo "\t\t<ol class=\"metodo-notas\">\n";
	foreach ($notas as $n => $html) {
		$n = (int)$n;
		$html = metodo_t($html);
		echo "\t\t\t<li id=\"nota-{$n}\" value=\"{$n}\">{$html} <a class=\"metodo-nota-volver\" href=\"#ref-{$n}\" aria-label=\"{$volver}\">&#8617;</a></li>\n";
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
	$es = metodo_lang() === 'es';
	$copy = '&#9400; ' . date('Y') . ' | Simulador Fiscal CIEP - ricardocantu@ciep.mx';
	if ($meta['version_html'] !== '') $copy .= ($es ? ' | Versi&oacute;n ' : ' | Version ') . $meta['version_html'];
	// Footer (8.19): mismo contenido y colores que el del simulador grande (index.php / index-en.php), sin el banner del libro,
	// en el idioma de la página (los nombres de los micrositios son nombres propios y no se traducen). Sin literales de 4+
	// dígitos (test-sitio-nta.sh y test-sitio-entidades.sh): por eso la dirección no lleva código postal.
	$inicio = htmlspecialchars(metodo_url('/'));
	$tit_sim = $es ? 'Simuladores:' : 'Simulators:';
	$tit_mic = $es ? 'Micrositios:' : 'Microsites:';
	$tit_con = $es ? 'Contacto:' : 'Contact:';
	$sim_fiscal = $es ? 'Simulador Fiscal' : 'Fiscal Simulator';
	$sim_tenencia = $es ? 'Simulador de Tenencia' : 'Vehicle Tax Simulator';
	$sim_tabaco = $es ? 'IEPS al Tabaco' : 'Tobacco Excise Tax';
	$dir2 = $es ? 'Del. Cuauhtémoc, CDMX' : 'Cuauhtémoc, Mexico City';
	// micrositios: nombre en español (como en index.php) y en inglés (como en index-en.php)
	$mic = array(
		array('libro', 'El libro CIEP', 'The CIEP Book'), array('paqueteeconomico', 'Paquete Económico', 'Economic Package'),
		array('ingresosenmexico', 'Ingresos Públicos', 'Public Revenue'), array('pensionesenmexico', 'Pensiones en México', 'Pensions in Mexico'),
		array('salud', 'Salud en México', 'Health in Mexico'), array('gastoeducativo', 'Educación en México', 'Education in Mexico'),
		array('energiaenmexico', 'Energía en México', 'Energy in Mexico'), array('subnacional', 'Finanzas Subnacionales', 'Subnational Finances'),
		array('inversion', 'Inversión en México', 'Investment in Mexico'), array('desarrollosostenible', 'Desarrollo Sostenible', 'Sustainable Development'),
		array('cuidados', 'Cuidados', 'Care Economy'),
	);
	$col_mic = array('', '');
	foreach ($mic as $i => $m) {
		$col_mic[$i < 6 ? 0 : 1] .= "\n\t\t\t\t\t\t\t\t\t<li><a href=\"https://{$m[0]}.ciep.mx/\" target=\"_blank\" rel=\"noopener\">" . ($es ? $m[1] : $m[2]) . '</a></li>';
	}
	$social = '<ul class="metodo-social metodo-social-pie">'
		. '<li><a href="http://facebook.com/ciepmx" target="_blank" rel="noopener" aria-label="Facebook"><img src="/images/f-icon-facebook.svg" alt=""></a></li>'
		. '<li><a href="https://twitter.com/ciepmx" target="_blank" rel="noopener" aria-label="X"><img src="/images/f-icon-twitter.svg" alt=""></a></li>'
		. '<li><a href="https://www.youtube.com/user/CIEPMX" target="_blank" rel="noopener" aria-label="YouTube"><img src="/images/f-icon-youtube.svg" alt=""></a></li>'
		. '</ul>';
	echo <<<HTML
	<footer class="metodo-pie">
		<div class="metodo-pie-fila-2">
			<div class="container">
				<div class="row">
					<div class="col-sm-2">
						<a class="metodo-pie-logo" href="{$inicio}" aria-label="Simulador Fiscal CIEP"><img src="/images/logo-sim-fiscal-ciep-b.png" alt="Simulador Fiscal CIEP" width="150" height="52"></a>
					</div>
					<div class="col-sm-2 mt-4 mt-sm-0">
						<p class="metodo-pie-titulo"><small>{$tit_sim}</small></p>
						<ul class="list-unstyled mb-0">
							<li><a href="https://simuladorfiscal.ciep.mx/" target="_blank" rel="noopener">{$sim_fiscal}</a></li>
							<li><a href="https://tenencia.ciep.mx/" target="_blank" rel="noopener">{$sim_tenencia}</a></li>
							<li><a href="https://iepsaltabaco.ciep.mx/" target="_blank" rel="noopener">{$sim_tabaco}</a></li>
						</ul>
					</div>
					<div class="col-sm-5 mt-4 mt-sm-0">
						<p class="metodo-pie-titulo"><small>{$tit_mic}</small></p>
						<div class="row">
							<div class="col-sm-6">
								<ul class="list-unstyled mb-0">
									{$col_mic[0]}
								</ul>
							</div>
							<div class="col-sm-6">
								<ul class="list-unstyled mb-0">
									{$col_mic[1]}
								</ul>
							</div>
						</div>
					</div>
					<div class="col-sm-3 mt-4 mt-sm-0">
						<p class="metodo-pie-titulo"><small>{$tit_con}</small></p>
						<ul class="list-unstyled mb-0">
							<li>Puebla 151 Letra O, Col. Roma Norte,</li>
							<li>{$dir2}</li>
							<li><a href="mailto:info@ciep.mx">info@ciep.mx</a> / (55) 53.40.86.88</li>
							<li><a href="https://ciep.mx/" target="_blank" rel="noopener">ciep.mx</a></li>
						</ul>
					</div>
				</div>
			</div>
		</div>
		<div class="metodo-pie-fila-1">
			<div class="container metodo-pie-copia">
				<small>{$copy}</small>
				{$social}
			</div>
		</div>
	</footer>

HTML;
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
