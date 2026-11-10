<?php
// /NTA — Sankey NTA de la economía completa (v4, 8.17) y, como corte, el v3 del lado de los hogares; debajo el panel grupo × sexo.
// v8.17.0 (sesión 8.17, CUAD-2 firmado): el gráfico principal es el Sankey v4 que emite 01_modulos/NTA.do §7d (SankeySumSim folder(SankeyNTA)
// name(v4-economia) → users/<id>/SankeyNTA/sankey-v4-economia.json): personas por edad en los dos extremos, sectores institucionales en medio
// (Hogares, Sociedades = S.11 + S.12, Gobierno, ISFLSH, el mundo) conservando en cada nodo, y un solo pivote: el ingreso nacional disponible neto
// del BIE (hub = inbd). El v3 (NTA.do §7b, edades solo al inicio y al final, hub del lado de los hogares) sigue emitiéndose y se dibuja aquí como
// corte (jsonSankeyNTA.php?corte=v3-grupoedad). Panel por grupo de edad × sexo (NTA.do §7c → users/<id>/NTA/nta-panel-grupoedad-sexo.json).
// Página estática de lectura: la gráfica se lee en runtime de /jsonSankeyNTA.php?corte=v4-economia (default), el corte v3 de ?corte=v3-grupoedad,
// el panel de ?cuenta=panel-grupoedad-sexo y las cifras de «Anchoring and residual» de ?cuenta=grupoedad (users/<id>/NTA/nta-grupoedad.json,
// NTA.do §6.2; bloques nacional_pctpib y v3_mxn del panel para el % del PIB y los totales en MXN de los dos Sankeys).
// Sin números en este archivo: todo valor viene de esos JSON (<span data-nta>, <span data-pib>); test-sitio-nta.sh lo exige.
// Historia: v8.12.5 (NTA-2) retiró el v1; v8.12.6 (NTA-3) el v2; v8.13.0 (NTA-4) dibujó el v3 en % del PIB con un solo Desahorro / Futuro / ajuste;
// v8.17.0 (8.17) dibuja la economía completa y deja el v3 como corte.
require_once dirname(__DIR__) . '/plantilla-metodo.php';

metodo_cabecera(array(
	'slug' => 'NTA',
	'titulo' => array('en' => 'National Transfer Accounts Sankey: the whole economy, person to person',
		'es' => 'Sankey de Cuentas Nacionales de Transferencias: toda la economía, de persona a persona'),
	'lang' => 'en',
	'descripcion' => array('en' => 'How the Simulador Fiscal CIEP draws the whole economy of one survey year as flows from persons by age, through the institutional sectors of the national accounts, back to persons by age, with net national disposable income as the single pivot.',
		'es' => 'Cómo dibuja el Simulador Fiscal CIEP toda la economía de un año de encuesta como flujos que salen de las personas por edad, pasan por los sectores institucionales de las cuentas nacionales y regresan a las personas por edad, con el ingreso nacional disponible neto como único pivote.'),
));
?>
<?php require __DIR__ . '/_cuerpo-' . metodo_lang() . '.php'; ?>
<?php
metodo_pie(array(
	'sankeys' => array(
		array('renderAt' => 'sankey-nta', 'url' => '/jsonSankeyNTA.php?corte=v4-economia'),
		array('renderAt' => 'sankey-nta-v3', 'url' => '/jsonSankeyNTA.php?corte=v3-grupoedad'),
	),
	'cifras' => array('url' => '/jsonSankeyNTA.php?cuenta=grupoedad'),
	'panel' => array('url' => '/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo', 'contenedor' => 'nta-panel', 'selector' => 'nta-sexo'),
	'fuente' => function ($meta) {
		$enigh = $meta['enigh_vintage'] !== '' ? 'ENIGH ' . htmlspecialchars($meta['enigh_vintage']) : 'ENIGH';
		$version = $meta['version_html'] !== '' ? ' ' . $meta['version_html'] : '';
		$sna = $meta['enigh_vintage'] !== '' ? htmlspecialchars($meta['enigh_vintage']) . ' ' : '';
		$fecha = '';
		if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $meta['data_updated_iso'], $dm) && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
			$fecha = (metodo_lang() === 'es' ? ' Datos actualizados al ' : ' Data updated ') . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		$inicio = htmlspecialchars(metodo_url('/'));
		if (metodo_lang() === 'es') {
			return '<b>Fuente</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', Cuentas Nacionales de Transferencias por individuo (<code>NTA.do</code>) con la ' . $enigh . ' del INEGI anclada a los sectores institucionales del Sistema de Cuentas Nacionales ' . $sna . '(INEGI, BIE y cuentas por sectores institucionales).' . $fecha;
		}
		return '<b>Source</b>: CIEP, <a href="' . $inicio . '">Simulador Fiscal CIEP</a>' . $version . ', National Transfer Accounts by individual (<code>NTA.do</code>) with INEGI\'s ' . $enigh . ' benchmarked to the institutional sectors of the ' . $sna . 'System of National Accounts (INEGI, BIE and institutional sector accounts).' . $fecha;
	},
));
?>
