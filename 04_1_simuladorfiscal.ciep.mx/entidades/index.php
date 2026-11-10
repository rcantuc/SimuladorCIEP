<?php
// /entidades — índice de las 32 entidades federativas (v8.13.0, «template estatal»): una tabla, sin mapa.
// Las 32 filas (número, nombre, abreviatura, enlace) salen del catálogo generado (_catalogo.php, desde
// SIMentidad.ado); las columnas con cifras (n ENIGH, celdas con n < sello_n, celdas selladas, concentración
// top-1, neto del ciclo / PIBE) las llena js/entidad.js en runtime desde /jsonEntidad.php?producto=indice
// (users/<id>/entidades.json, esquema entidades-indice/v1, que escribe generar-entidades.py meta a partir de
// los JSON del motor y de la tabla de las 32). Cero números en este archivo. Página de la sección de método
// (plantilla-metodo.php), hermana de /NTA; cada fila enlaza a /entidades/<ABREV>.
$catalogo = require __DIR__ . '/_catalogo.php';
require_once dirname(__DIR__) . '/plantilla-metodo.php';

metodo_cabecera(array(
	'slug' => 'entidades',
	'titulo' => array('en' => 'The fiscal system by state: the 32 entities', 'es' => 'El sistema fiscal por entidad: las 32 entidades federativas'),
	'lang' => 'en',
	'descripcion' => array('en' => 'Index of the 32 state pages of the Simulador Fiscal CIEP: contribution Sankeys, lifecycle profile, effective tax rates and net contribution as a share of state GDP, cut by residence from the national engine run, with the sample size and the sealed cells of each state.',
		'es' => 'Índice de las 32 páginas estatales del Simulador Fiscal CIEP: Sankeys de aportación, perfil del ciclo de vida, tasas efectivas y aportación neta como proporción del PIB estatal, como corte por residencia de la corrida nacional del motor, con el tamaño de muestra y las celdas selladas de cada entidad.'),
));
?>
<?php require __DIR__ . '/_cuerpo-indice-' . metodo_lang() . '.php'; ?>
<?php
metodo_pie(array(
	'sankeys' => array(),
	'scripts' => array('/js/entidad.js'),
	'init' => 'entidadIndice(' . json_encode(array('url' => '/jsonEntidad.php?producto=indice', 'tabla' => 'ent-indice'), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . ');',
	'fuente' => function ($meta) {
		$enigh = $meta['enigh_vintage'] !== '' ? 'ENIGH ' . htmlspecialchars($meta['enigh_vintage']) : 'ENIGH';
		$version = $meta['version_html'] !== '' ? ' ' . $meta['version_html'] : '';
		$fecha = '';
		if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $meta['data_updated_iso'], $dm) && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
			$fecha = (metodo_lang() === 'es' ? ' Datos actualizados al ' : ' Data updated ') . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		$inicio = htmlspecialchars(metodo_url('/'));
		if (metodo_lang() === 'es') {
			return '<b>Fuente</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', corte estatal de la corrida nacional (<code>contrato-32</code>) con la ' . $enigh . ' del INEGI anclada a las cuentas nacionales, el BIE del INEGI para el PIB estatal y CONAPO para la población.' . $fecha;
		}
		return '<b>Source</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', state cut of the national run (<code>contrato-32</code>) with INEGI\'s ' . $enigh . ' benchmarked to the national accounts, INEGI\'s BIE for the state GDP and CONAPO for the population.' . $fecha;
	},
));
?>
