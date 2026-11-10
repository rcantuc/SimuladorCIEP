<?php
// entidades/_entidad.php — la plantilla ÚNICA de las 32 páginas /entidades/<ABREV> (v8.13.0, «template estatal»).
//
// Cada entidades/<ABREV>/index.php (GENERADO por 05_scripts/generar-entidades.py desde SIMentidad.ado) fija
// $ENTIDAD_ABREV y carga este archivo: las 32 páginas son iguales por construcción (decisión de Ricardo, 29-oct:
// las 32 iguales, con sellos). Página estática de lectura sobre plantilla-metodo.php (misma cabecera, notas
// numeradas y pie que /NTA). Orden: encabezado (nombre, clave, n ENIGH, vintage) → párrafo de método (qué es
// por entidad, qué es federal, qué está anclado a qué) → los cuatro productos, cada uno con su gráfica y su
// lectura de dos líneas: (i) los cinco Sankeys de aportación con selector de corte (FusionCharts, como la
// portada), (ii) el ciclo de vida quinquenio × sexo (ApexCharts, como «Tax burden by age» de la portada),
// (iii) las tasas efectivas por impuesto sin ISAN/IMPORT (SVG propio: la portada no tiene gráfica equivalente,
// solo PNG), (iv) el neto del ciclo como % del PIBE (cifras + SVG propio) leído de neto-pibe.json, el escalar
// que contrato-32.do §4b divide EN STATA y exporta con scalarjson (regla: ningún número de la página nace fuera
// de Stata). Sellos: toda celda con n < sello_n o top-1 > sello_top1 lleva marca ⚠ en la gráfica y nota al pie
// numerada con su n; se leen de meta.json (generar-entidades.py meta, a partir de los JSON del motor y de la
// tabla de las 32), no se cablean. CERO números en este archivo: todo valor viene en runtime de
// /jsonEntidad.php (users/<id>/<ABREV>/{sankey-<corte>.json, ciclo-vida.json, tasas-efectivas.json,
// neto-pibe.json, meta.json}); js/entidad.js llena los <span data-ent="ruta.en.meta.json"> y
// <span data-neto="ruta.en.neto-pibe.json"> (con {abrev} como comodín del sufijo del escalar) y dibuja. El
// nombre y la clave vienen del catálogo generado (_catalogo.php), no del JSON, porque el <title> se escribe en
// el servidor. La línea del espejo CoNL en NL es texto fijo, sin enlace (decisión de Ricardo).
$catalogo = require __DIR__ . '/_catalogo.php';
if (!isset($ENTIDAD_ABREV) || !is_string($ENTIDAD_ABREV) || !array_key_exists($ENTIDAD_ABREV, $catalogo)) {
	http_response_code(404);
	header('Content-type: text/plain; charset=utf-8');
	echo "Unknown state. See /entidades for the 32.\n";
	exit;
}
$abrev = $ENTIDAD_ABREV;
$ent = $catalogo[$abrev];
$nombre = $ent['nombre'];
$h = function ($s) { return htmlspecialchars($s); };
$ep = '/jsonEntidad.php?abrev=' . rawurlencode($abrev) . '&producto=';
require_once dirname(__DIR__) . '/plantilla-metodo.php';
$lang = metodo_lang('en');   // 8.19: la página es bilingüe; default inglés, ?lang=es la cambia
$cortes = $lang === 'es' ? array(
	'quintil' => 'Quintil de ingreso (estatal)',
	'grupoedad' => 'Grupo de edad',
	'sexo' => 'Sexo',
	'rural' => 'Rural / urbano / indígena',
	'escol' => 'Escolaridad',
) : array(
	'quintil' => 'Income quintile (state)',
	'grupoedad' => 'Age group',
	'sexo' => 'Sex',
	'rural' => 'Rural / urban / indigenous',
	'escol' => 'Schooling',
);
require_once dirname(__DIR__) . '/plantilla-metodo.php';

metodo_cabecera(array(
	'slug' => 'entidades',
	'titulo' => array('en' => $nombre . ': the fiscal system by state', 'es' => $nombre . ': el sistema fiscal por entidad'),
	'lang' => 'en',
	'descripcion' => array('en' => 'What the households of ' . $nombre . ' pay and receive in the Simulador Fiscal CIEP: contribution Sankeys, lifecycle profile by sex and age, effective tax rates and the net contribution as a share of state GDP, cut by residence from the national engine run.',
		'es' => 'Lo que pagan y reciben los hogares de ' . $nombre . ' en el Simulador Fiscal CIEP: Sankeys de aportación, perfil del ciclo de vida por sexo y edad, tasas efectivas y la aportación neta como proporción del PIB estatal, como corte por residencia de la corrida nacional del motor.'),
	'migas' => array(array('href' => '/entidades/' . $abrev . '/', 'texto' => $nombre)),
));
?>
<?php require __DIR__ . '/_cuerpo-entidad-' . metodo_lang() . '.php'; ?>
<?php
metodo_pie(array(
	'sankeys' => array(),
	'scripts' => array('/plugins/apexcharts/dist/apexcharts.min.js', '/js/entidad.js'),
	'init' => 'entidadPagina(' . json_encode(array(
		'abrev' => $abrev,
		'nombre' => $nombre,
		'urls' => array('meta' => $ep . 'meta', 'ciclo' => $ep . 'ciclo', 'tasas' => $ep . 'tasas', 'neto' => $ep . 'neto', 'sankey' => $ep . 'sankey&corte='),
		'cortes' => array_keys($cortes),
		'etiquetasCortes' => $cortes,
		'excluirTasas' => array('ISAN', 'IMPORT'),
		'selector' => 'ent-corte',
		'ids' => array('sankey' => 'ent-sankey', 'sankeySellos' => 'ent-sankey-sellos', 'cicloH' => 'ent-ciclo-H', 'cicloM' => 'ent-ciclo-M', 'cicloSellos' => 'ent-ciclo-sellos', 'tasas' => 'ent-tasas', 'tasasSellos' => 'ent-tasas-sellos', 'neto' => 'ent-neto', 'netoNd' => 'ent-neto-nd', 'netoCifra' => 'ent-neto-cifra'),
	), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . ');',
	'fuente' => function ($meta) use ($nombre) {
		$enigh = $meta['enigh_vintage'] !== '' ? 'ENIGH ' . htmlspecialchars($meta['enigh_vintage']) : 'ENIGH';
		$version = $meta['version_html'] !== '' ? ' ' . $meta['version_html'] : '';
		$fecha = '';
		if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $meta['data_updated_iso'], $dm) && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
			$fecha = (metodo_lang() === 'es' ? ' Datos actualizados al ' : ' Data updated ') . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		$inicio = htmlspecialchars(metodo_url('/'));
		if (metodo_lang() === 'es') {
			return '<b>Fuente</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', corte estatal de la corrida nacional (<code>contrato-32</code>: <code>SankeySF.do</code>, <code>CicloEntidad.do</code>, <code>TasasEfectivasEntidad.do</code>, <code>PIBDeflactor</code> por entidad) para ' . htmlspecialchars($nombre) . ', con la ' . $enigh . ' del INEGI anclada a las cuentas nacionales, el BIE del INEGI para el PIB estatal, CONAPO para la población y los parámetros fiscales del año de política (LIF, PEF, CGPE).' . $fecha . ' <a href="' . htmlspecialchars(metodo_url('/entidades/', 'entidades')) . '">Las 32 entidades</a>.';
		}
		return '<b>Source</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', state cut of the national run (<code>contrato-32</code>: <code>SankeySF.do</code>, <code>CicloEntidad.do</code>, <code>TasasEfectivasEntidad.do</code>, <code>PIBDeflactor</code> by state) for ' . htmlspecialchars($nombre) . ', with INEGI\'s ' . $enigh . ' benchmarked to the national accounts, INEGI\'s BIE for the state GDP, CONAPO for the population and the fiscal parameters of the policy year (LIF, PEF, CGPE).' . $fecha . ' <a href="' . htmlspecialchars(metodo_url('/entidades/', 'entidades')) . '">All 32 states</a>.';
	},
));
?>
