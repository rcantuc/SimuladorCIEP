<?php
// entidades/_entidad.php — la plantilla ÚNICA de las 32 páginas /entidades/<ABREV> (v8.13.0, «template estatal»).
//
// Cada entidades/<ABREV>/index.php (GENERADO por 05_scripts/generar-entidades.py desde SIMentidad.ado) fija
// $ENTIDAD_ABREV y carga este archivo: las 32 páginas son iguales por construcción (decisión de Ricardo, 29-oct:
// las 32 iguales, con sellos). Página estática de lectura sobre metodo/plantilla.php (misma cabecera, notas
// numeradas y pie que /NTA). Orden: encabezado (nombre, clave, n ENIGH, vintage) → párrafo de método (qué es
// por entidad, qué es federal, qué está anclado a qué) → los cuatro productos, cada uno con su gráfica y su
// lectura de dos líneas: (i) los cinco Sankeys de aportación con selector de corte (FusionCharts, como la
// portada), (ii) el ciclo de vida quinquenio × sexo (ApexCharts, como «Tax burden by age» de la portada),
// (iii) las tasas efectivas por impuesto sin ISAN/IMPORT (SVG propio: la portada no tiene gráfica equivalente,
// solo PNG), (iv) el neto del ciclo como % del PIBE (cifras + SVG propio). Sellos: toda celda con n < sello_n
// o top-1 > sello_top1 lleva marca ⚠ en la gráfica y nota al pie numerada con su n; se leen de meta.json
// (generar-entidades.py meta, a partir de los JSON del motor y de la tabla de las 32), no se cablean.
// CERO números en este archivo: todo valor viene en runtime de /jsonEntidad.php (users/<id>/<ABREV>/
// {sankey-<corte>.json, ciclo-vida.json, tasas-efectivas.json, meta.json}); js/entidad.js llena los
// <span data-ent="ruta.en.meta.json" data-ent-unidad="…"> y dibuja. El nombre y la clave vienen del catálogo
// generado (_catalogo.php), no del JSON, porque el <title> se escribe en el servidor. La línea del espejo CoNL en NL
// es texto fijo, sin enlace (decisión de Ricardo).
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
$cortes = array(
	'quintil' => 'Income quintile (state)',
	'grupoedad' => 'Age group',
	'sexo' => 'Sex',
	'rural' => 'Rural / urban / indigenous',
	'escol' => 'Schooling',
);
require_once dirname(__DIR__) . '/metodo/plantilla.php';

metodo_cabecera(array(
	'slug' => 'entidades',
	'titulo' => $nombre . ': the fiscal system by state',
	'lang' => 'en',
	'descripcion' => 'What the households of ' . $nombre . ' pay and receive in the Simulador Fiscal CIEP: contribution Sankeys, lifecycle profile by sex and age, effective tax rates and the net contribution as a share of state GDP, cut by residence from the national engine run.',
	'migas' => array(array('href' => '/entidades/' . $abrev . '/', 'texto' => $nombre)),
));
?>
		<section class="metodo-texto ent-cabecera" id="ent-cabecera">
			<p class="ent-datos">
				<span><b>State</b> <?= $h($nombre) ?> (<?= $h($abrev) ?>)</span>
				<span><b>INEGI code</b> <?= $h($ent['clave']) ?></span>
				<span><b>ENIGH sample</b> <span data-ent="muestra.n" data-ent-unidad="entero"></span> persons, expanding to <span data-ent="muestra.pob" data-ent-unidad="entero"></span> residents (ENIGH <span data-ent="muestra.anio_enigh" data-ent-unidad="texto"></span>)</span>
				<span><b>Share of the national population</b> <span data-ent="nacional.share_pob" data-ent-unidad="share"></span> %</span>
				<span><b>Policy year</b> <span data-ent="muestra.paquete" data-ent-unidad="texto"></span>, values of <span data-ent="muestra.anio_vp" data-ent-unidad="texto"></span></span>
				<span><b>Engine run</b> <span data-ent="procedencia.modulos.ciclo" data-ent-unidad="texto"></span>, <span data-ent="procedencia.generado_el" data-ent-unidad="texto"></span></span>
			</p>
<?php if ($abrev === 'NL'): ?>
			<p class="ent-espejo lead-nota" id="ent-espejo">Nuevo León also has a dedicated mirror (SimuladorCoNL) maintained with Consejo Nuevo León; available on request.</p>
<?php endif; ?>
		</section>

		<section class="metodo-texto">
			<p>Every chart on this page is the <b>national engine run cut by residence</b>, not a separate state model. <b>What is state-specific</b>: the population projection (CONAPO by state, §1 of the engine), the state GDP and deflator (INEGI's PIBE base for the state, §2–3; vintage of the base: <span data-ent="pibe.vintage" data-ent-unidad="texto"></span><?= metodo_nota_ref(2) ?>), and everything built from the ENIGH persons who live in the state (the first two digits of the dwelling identifier): the five contribution Sankeys and the lifecycle profile by sex and age (§7–8.2), and the effective tax rates, whose numerator and denominator are both the micro sums of the state's residents. <b>What is federal, shared by the 32</b>: the fiscal parameters of the policy year (LIF, PEF, CGPE), the national income deciles that classify households, and the national-accounts anchors: every household component is benchmarked to the System of National Accounts <i>before</i> the cut, because the SCN fraction has no declared state breakdown<?= metodo_nota_ref(3) ?>; nothing is recalibrated by state, so the amounts of the 32 states add up to the national figures by construction (amounts, not rates). The car tax (ISAN) and import taxes are imputed with the same relative in numerator and denominator, so their effective rate is the national rate by construction and the rates chart omits them<?= metodo_nota_ref(4) ?>. <b>What is anchored to what</b>: the «% of state GDP» product divides the state's net lifecycle contribution (engine, pesos of the value-present year) by the state's PIBE of that year (BIE, vintage above); the national reference uses the national GDP of the same run. Cells with a thin sample (fewer than <span data-ent="parametros.sello_n" data-ent-unidad="entero"></span> persons) or dominated by one person (more than <span data-ent="parametros.sello_top1" data-ent-unidad="entero"></span> % of the cell) carry a seal ⚠ on the chart and a numbered footnote with their n<?= metodo_nota_ref(1) ?>: read them as indicative.</p>
		</section>

		<h2>1 · Where the state's taxes come from and where federal spending goes</h2>
		<section class="metodo-texto">
			<p>Households of <?= $h($nombre) ?> pay <span data-ent="ciclo.aporta_pesos" data-ent-unidad="bn"></span> bn MXN in taxes and contributions and receive <span data-ent="ciclo.recibe_pesos" data-ent-unidad="bn"></span> bn in pensions, basic income, education, health and investment: a net contribution of <span data-ent="ciclo.neto_pesos" data-ent-unidad="bn"></span> bn, <span data-ent="nacional.share_neto" data-ent-unidad="share"></span> % of the national net with <span data-ent="nacional.share_pob" data-ent-unidad="share"></span> % of the population. The Sankey draws the same flows as the national one: the state's households by the chosen cut → tax families → the federal fiscal system → spending → back to the households by the same cut; the residual node is the state's net position with the federation. The thin cells of the chosen cut are listed under the chart and marked in the link tooltips.</p>
		</section>
		<div class="ent-selector metodo-panel-selector" role="radiogroup" aria-label="Cut">
			<span class="metodo-panel-selector-titulo">Cut</span>
<?php $primero = true; foreach ($cortes as $k => $etq): ?>
			<label><input type="radio" name="ent-corte" value="<?= $h($k) ?>"<?= $primero ? ' checked' : '' ?>> <?= $h($etq) ?></label>
<?php $primero = false; endforeach; ?>
		</div>
		<div class="metodo-sankey-wrap">
			<div class="chart metodo-sankey" id="ent-sankey"></div>
		</div>
		<div class="ent-sellos" id="ent-sankey-sellos"></div>

		<h2>2 · Net contribution over the lifecycle, by sex and five-year age group</h2>
		<section class="metodo-texto">
			<p>Each bar is a five-year age group of the state's residents; its length is the group's net contribution (taxes and contributions paid minus transfers, pensions, education, health and investment received) as a percentage of the state's total net contribution, stacked by the national income decile of the household (deciles I–V, VI–IX and X); negative bars are groups that receive more than they pay. The cells of the 32 states add up, cell by cell, to the national profile of «Tax burden by age»; the engine's seal marks the cells of this state with a thin sample or one dominant person (⚠ next to the age label).</p>
		</section>
		<div class="ent-ciclo-grid">
			<div class="ent-ciclo-celda"><h3>Men</h3><div class="ent-ciclo" id="ent-ciclo-H"></div></div>
			<div class="ent-ciclo-celda"><h3>Women</h3><div class="ent-ciclo" id="ent-ciclo-M"></div></div>
		</div>
		<div class="ent-sellos" id="ent-ciclo-sellos"></div>

		<h2>3 · Effective tax rates</h2>
		<section class="metodo-texto">
			<p>For each tax, the bar is the state's effective rate: what its residents pay (micro sum of the tax, weighted) over the micro base of the same residents (wages, mixed income, private capital income, consumption, alcohol and tobacco, fuels), both after the national benchmark and without any state recalibration; the tick is the national micro rate, which is the average of the 32 states weighted by their bases. ISAN and import taxes are omitted (their state rate is the national one by construction<?= metodo_nota_ref(4) ?>); a rate whose numerator depends on one person carries the seal ⚠.</p>
		</section>
		<div class="ent-tasas" id="ent-tasas"></div>
		<div class="ent-sellos" id="ent-tasas-sellos"></div>

		<h2>4 · Net lifecycle contribution as a share of state GDP</h2>
		<section class="metodo-texto">
			<p class="ent-neto-cifra" id="ent-neto-cifra">The net contribution of the households of <?= $h($nombre) ?> to the federation, <span data-ent="ciclo.neto_pesos" data-ent-unidad="bn"></span> bn MXN, is <b><span data-ent="pibe.neto_pct_pibe" data-ent-unidad="pct3"></span> %</b> of the state's GDP (PIBE <span data-ent="pibe.anio_vp" data-ent-unidad="texto"></span>: <span data-ent="pibe.pibe_pesos" data-ent-unidad="bn"></span> bn MXN); the national ratio in the same run is <span data-ent="nacional.neto_pct_pib" data-ent-unidad="pct3"></span> % (national net <span data-ent="nacional.neto_pesos" data-ent-unidad="bn"></span> bn over national GDP <span data-ent="nacional.pib_pesos" data-ent-unidad="bn"></span> bn). A state above the national ratio is a net contributor relative to its economy; a negative ratio is a net recipient. The sum of the 32 PIBE differs from the national GDP of the run<?= metodo_nota_ref(5) ?>, so the state ratios are not exact shares of the national one.</p>
			<p class="ent-neto-nd lead-nota" id="ent-neto-nd" hidden>The PIBE of this state is not available in this run (no state base in contrato-32.tsv), so the ratio is not shown; the net contribution in pesos is in product 1.</p>
		</section>
		<div class="ent-neto" id="ent-neto"></div>

		<h2>Notes</h2>
<?php
metodo_notas(array(
	1 => '<b>Sample seals.</b> The engine seals a cell (a Sankey link from or to a household group, a five-year × sex cell of the lifecycle, a tax of the rates chart) when its unweighted sample has fewer than <span data-ent="parametros.sello_n" data-ent-unidad="entero"></span> persons or when a single person accounts for more than <span data-ent="parametros.sello_top1" data-ent-unidad="entero"></span> % of the cell\'s amount (rule P5 of <code>SankeySF.do</code>; <code>sello</code>, <code>n</code> and <code>top1</code> travel in every JSON). Sealed cells in this state: <span data-ent="sellos.texto" data-ent-unidad="texto"></span> (Sankey links / lifecycle cells / taxes). The seals below are read from <code>meta.json</code>, which <code>generar-entidades.py</code> builds from the engine\'s JSON at deploy time; the table of the 32 (contrato-32, §4) carries the same counts<span data-ent="tabla_32.coincide" data-ent-unidad="coincide"></span>.',
	2 => '<b>State GDP (PIBE).</b> <code>master/PIBDeflactor&lt;ABREV&gt;.dta</code>, built by <code>PIBDeflactor</code> by state from INEGI\'s BIE (GDP by state at current prices, implicit price index, state employment and ITAEE) and sealed with its consultation dates; vintage of the base used here: <span data-ent="pibe.vintage" data-ent-unidad="texto"></span>. The PIBE of the value-present year (<span data-ent="pibe.anio_vp" data-ent-unidad="texto"></span>) is the scalar <code>pibY&lt;ABREV&gt;</code> that contrato-32 records in its table.',
	3 => '<b>National-accounts fraction without state breakdown.</b> The household components (labor and capital income, consumption, contributions) are scaled to the household sector of the national accounts at the national level before the residence cut; the SCN publishes no institutional-sector accounts by state, so the engine declares the fraction national and does not recalibrate by state. Consequence: the amounts of the 32 add up to the national ones by construction (verified in contrato-32: Sankeys within 1e-13 relative, lifecycle within the print tolerance); rates and shares are not additive.',
	4 => '<b>National rate by construction.</b> For the car tax (ISAN) and import taxes, numerator and denominator are imputed to households with the same relative (<code>Distribucion</code>), so the state ratio equals the national micro rate in the 32 states and carries no state information; the chart omits both rows (decision of the v8.13a report, FLAG TE ISAN/IMPORT).',
	5 => '<b>Σ32 PIBE vs national GDP.</b> In this run the sum of the 32 state GDPs of the value-present year is <span data-ent="pibe_32.suma_pesos" data-ent-unidad="bn"></span> bn MXN against the national GDP of <span data-ent="pibe_32.pib_nacional_pesos" data-ent-unidad="bn"></span> bn: a discrepancy of <span data-ent="pibe_32.discrepancia_pct" data-ent-unidad="signo-pct2"></span> %, informative (state GDPs come from the state accounts, the national GDP from the national accounts and the engine\'s projection; it is not gated).',
));
?>
<?php
metodo_pie(array(
	'sankeys' => array(),
	'scripts' => array('/plugins/apexcharts/dist/apexcharts.min.js', '/js/entidad.js'),
	'init' => 'entidadPagina(' . json_encode(array(
		'abrev' => $abrev,
		'nombre' => $nombre,
		'urls' => array('meta' => $ep . 'meta', 'ciclo' => $ep . 'ciclo', 'tasas' => $ep . 'tasas', 'sankey' => $ep . 'sankey&corte='),
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
			$fecha = ' Data updated ' . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		return '<b>Source</b>: CIEP, <a href="/">Simulador Fiscal CIEP</a>' . $version . ', state cut of the national run (<code>contrato-32</code>: <code>SankeySF.do</code>, <code>CicloEntidad.do</code>, <code>TasasEfectivasEntidad.do</code>, <code>PIBDeflactor</code> by state) for ' . htmlspecialchars($nombre) . ', with INEGI\'s ' . $enigh . ' benchmarked to the national accounts, INEGI\'s BIE for the state GDP, CONAPO for the population and the fiscal parameters of the policy year (LIF, PEF, CGPE).' . $fecha . ' <a href="/entidades/">All 32 states</a>.';
	},
));
?>
