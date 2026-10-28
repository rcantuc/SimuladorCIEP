<?php
// /NTA — Sankey NTA de los hogares, por grupo de edad, tal cual lo emite el motor
// (Households.do §"Sankeys NTA" → visualizations/Sankey.do grupoedad → SankeySumSim →
// users/<id>/SankeyNTA/sankey-grupoedad.json). Página estática de lectura: el texto
// explica cómo se construye la gráfica; la gráfica se lee en runtime de
// /jsonSankeyNTA.php?corte=grupoedad. Primera página de la sección de método
// (metodo/plantilla.php). Sin números en este archivo.
require_once dirname(__DIR__) . '/metodo/plantilla.php';

metodo_cabecera(array(
	'slug' => 'NTA',
	'titulo' => 'Household NTA Sankey: how the chart is built',
	'lang' => 'en',
	'descripcion' => 'How the Simulador Fiscal CIEP builds the household National Transfer Accounts Sankey from the ENIGH, benchmarked to the national accounts.',
));
?>
		<section class="metodo-texto">
			<p>The chart is a five-column Sankey of the household account for one survey year. It is built from the <abbr title="Encuesta Nacional de Ingresos y Gastos de los Hogares (INEGI)">ENIGH</abbr> at the individual level, after the Simulador's Households module has annualized every income and expenditure item, split household-level items per capita among the members of each household, and benchmarked each income and consumption component to the national accounts of the same year (an Altimir-type scaling of wages, mixed income, operating surplus, imputed rent, remittances and each consumption category to its System of National Accounts counterpart; taxes net of production are folded into the income components). Every number is a survey-weighted sum in current pesos: there are no per-capita values and no single-year age profiles in this chart. Age enters only through five groups (0–4, 5–17, 18–24, 25–64, 65 and over), and each group appears twice, on the far left as an earner and on the far right as a consumer. Reading left to right: (1) the age groups, together with two non-household sources, public enterprises and agencies (own revenue of IMSS, ISSSTE, CFE, Pemex, the oil fund and other public firms, taken from the federal revenue law) and the rest of the world, send flows to (2) the income types: labor income (wages and salaries plus the labor share of mixed income), capital income (operating surplus plus the capital share of mixed income plus depreciation), imputed rent of owner-occupied housing, remittances (net current transfers from abroad) and foreign tourists (purchases of non-residents in the country net of residents’ purchases abroad, shown only when that balance favours the country); the rest of the world feeds labor income with net compensation of employees from abroad and remittances with net transfers, and the public enterprises feed capital income. (3) All income types collapse into a single hub, national income, whose inflows are simply the column-2 totals. (4) The hub fans out into the uses: seven household consumption categories assembled from the ENIGH expenditure groups (food, clothing, health, education, housing, transport, other), depreciation, saving and property income paid abroad. (5) Each consumption category and depreciation are split back to the five age groups according to who consumed them, while the health, education and “other” categories also carry general-government consumption (government health spending, government education spending and the remainder of government consumption) into a public-goods sink; saving goes to a “future” sink and property income to the rest of the world. Saving is not computed from the survey: it is the national-accounts residual (gross saving net of consumption of fixed capital), which is what makes the hub balance (in the current file, to within rounding); in that file the residual is negative, and the Sankey carries it as a negative link.</p>
			<p class="lead-nota">Node labels are the ones the engine emits, in Spanish. FusionCharts identifies a node by its label, so the engine disambiguates a name that must appear in two columns by prefixing spaces (<code>De 0 a 4</code> on the left vs. <code>&nbsp;De 0 a 4</code> on the right; <code>El mundo</code> vs. <code>&nbsp;&nbsp;El mundo</code>), and the leading spaces on the use categories only fix their vertical order. If you replicate the schema, keep node identifiers unique per column.</p>
		</section>

		<h2>Nodes and links</h2>
		<section class="metodo-texto">
			<p>Weighted sums use the ENIGH expansion factor (<code>factor</code>) over persons. ENIGH variable names are those of the Simulador's household file; national-accounts scalars (<code>ROWRem</code>, <code>ROWTrans</code>, <code>ROWProp</code>, <code>ComprasN</code>, <code>ConGob</code>, <code>SerEGob</code>, <code>SaluGob</code>, <code>AhorroN</code>) come from INEGI's institutional-sector and consumption accounts for the same year; the public-enterprise revenues come from the federal revenue law (LIF).</p>
		</section>
		<div class="table-responsive">
			<table class="table table-sm metodo-tabla">
				<thead>
					<tr><th>Column</th><th>Node (label as emitted)</th><th>Definition</th><th>Outgoing links (value)</th></tr>
				</thead>
				<tbody>
					<tr>
						<th rowspan="3">1 · Sources</th>
						<td><code>De 0 a 4</code>, <code>De 5 a 17</code>, <code>De 18 a 24</code>, <code>De 25 a 64</code>, <code>De 65 y más</code></td>
						<td>Persons grouped by age (<code>edad</code>), as earners.</td>
						<td>→ <code>Ing Laboral</code>: Σ <code>Yl</code> = <code>ing_subor</code> + <code>ing_mixtoL</code>.<br>→ <code>Ing Capital</code>: Σ (<code>Yk</code> − <code>ing_estim_alqu</code>), with <code>Yk</code> = <code>ing_capital</code> + <code>ing_mixtoK</code> + <code>ing_estim_alqu</code> + <code>gasto_anualDepreciacion</code>.<br>→ <code>Alquiler propio</code>: Σ <code>ing_estim_alqu</code>.</td>
					</tr>
					<tr>
						<td><code>OyE públicas</code></td>
						<td>Public enterprises and agencies (own revenue, LIF): IMSS + ISSSTE + CFE + Pemex + oil fund (FMP) + other public firms.</td>
						<td>→ <code>Ing Capital</code>: that sum.</td>
					</tr>
					<tr>
						<td><code>El mundo</code></td>
						<td>Rest of the world (net flows, national accounts).</td>
						<td>→ <code>Ing Laboral</code>: <code>ROWRem</code> (compensation of employees received − paid).<br>→ <code>Remesas</code>: <code>ROWTrans</code> (current transfers received − paid).<br>→ <code>Turistas extranjeros</code>: −<code>ComprasN</code>, only if <code>ComprasN</code> &lt; 0 (net purchases of non-residents).</td>
					</tr>
					<tr>
						<th>2 · Income types</th>
						<td><code>Ing Laboral</code>, <code>Ing Capital</code>, <code>Alquiler propio</code>, <code>Remesas</code>, <code>Turistas extranjeros</code></td>
						<td>Labor income; capital income (incl. depreciation); imputed rent; remittances; foreign tourists.</td>
						<td>→ <code>Ing nacional</code>: the sum of the node's inflows (one link per income type).</td>
					</tr>
					<tr>
						<th>3 · Hub</th>
						<td><code>Ing nacional</code></td>
						<td>National income: the single pivot between resources and uses. Inflows = outflows by construction.</td>
						<td>→ each use in column 4: the sum of that use's outflows (column 4 → 5).</td>
					</tr>
					<tr>
						<th rowspan="4">4 · Uses</th>
						<td><code>Alimentos</code>, <code>Vestido</code>, <code>&nbsp;Salud</code>, <code>&nbsp;&nbsp;Educación</code>, <code>&nbsp;&nbsp;Vivienda</code>, <code>&nbsp;&nbsp;Transporte</code>, <code>&nbsp;&nbsp;&nbsp;Otros gastos</code></td>
						<td>Household consumption, per capita ENIGH expenditure groups (<code>gas_pc_*</code>): Alimentos = Agua + Alim + BebN; Vestido = Vest + Calz; Salud = Salu; Educación = Educ + Recr; Vivienda = Alqu + Hoga + Comu + Elec; Transporte = Vehi + STra + FTra; Otros gastos = Taba + BebA + Dive + Rest.</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ of the category over the persons in that group.<br>Additionally → <code>Bienes públicos</code>: from <code>&nbsp;Salud</code> = <code>SaluGob</code>; from <code>&nbsp;&nbsp;Educación</code> = <code>SerEGob</code>; from <code>&nbsp;&nbsp;&nbsp;Otros gastos</code> = <code>ConGob</code> − <code>SerEGob</code> − <code>SaluGob</code>.</td>
					</tr>
					<tr>
						<td><code>&nbsp;&nbsp;&nbsp;&nbsp;Depreciación</code></td>
						<td>Consumption of fixed capital imputed to persons (<code>gasto_anualDepreciacion</code>); it is also inside <code>Yk</code> on the resources side.</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ by group.</td>
					</tr>
					<tr>
						<td><code>Ahorro</code></td>
						<td>National saving (<code>AhorroN</code>: gross saving net of consumption of fixed capital), a national-accounts residual, not a survey aggregate.</td>
						<td>→ <code>&nbsp;Futuro</code>: <code>AhorroN</code> (may be negative).</td>
					</tr>
					<tr>
						<td><code>&nbsp;Ing a la propiedad</code></td>
						<td>Net property income paid to the rest of the world.</td>
						<td>→ <code>&nbsp;&nbsp;El mundo</code>: −<code>ROWProp</code> (property income received − paid, sign reversed).</td>
					</tr>
					<tr>
						<th>5 · Sinks</th>
						<td><code>&nbsp;De 0 a 4</code> … <code>&nbsp;De 65 y más</code>; <code>Bienes públicos</code>; <code>&nbsp;Futuro</code>; <code>&nbsp;&nbsp;El mundo</code></td>
						<td>The same five age groups as consumers; public goods (general-government consumption); the future (saving); the rest of the world.</td>
						<td>None (terminal nodes).</td>
					</tr>
				</tbody>
			</table>
		</div>

		<h2>The chart, as the engine emits it</h2>
		<div class="metodo-sankey-wrap">
			<table class="metodo-titulos">
				<tbody>
					<tr>
						<td width="20%" style="text-align:left;">Age groups<br>(earners) · public enterprises · rest of the world</td>
						<td width="20%" style="text-align:center;">Income types</td>
						<td width="20%" style="text-align:center;">National income<br>(MXN, current)</td>
						<td width="20%" style="text-align:center;">Uses</td>
						<td width="20%" style="text-align:right;">Age groups<br>(consumers) · public goods · future · rest of the world</td>
					</tr>
				</tbody>
			</table>
			<div class="chart metodo-sankey" id="sankey-nta"></div>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota">Hover a link to read its value. The data behind the chart is served verbatim from the engine's output (<a href="/jsonSankeyNTA.php?corte=grupoedad">jsonSankeyNTA.php?corte=grupoedad</a>); the same engine run also emits the cuts by income decile, sex, schooling and rural/urban/indigenous (<code>corte=decil|sexo|escol|rural</code>).</p>
		</section>
<?php
metodo_pie(array(
	'sankeys' => array(
		array('renderAt' => 'sankey-nta', 'url' => '/jsonSankeyNTA.php?corte=grupoedad'),
	),
	'fuente' => function ($meta) {
		$enigh = $meta['enigh_vintage'] !== '' ? 'ENIGH ' . htmlspecialchars($meta['enigh_vintage']) : 'ENIGH';
		$version = $meta['version_html'] !== '' ? ' ' . $meta['version_html'] : '';
		$sna = $meta['enigh_vintage'] !== '' ? htmlspecialchars($meta['enigh_vintage']) . ' ' : '';
		$fecha = '';
		if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $meta['data_updated_iso'], $dm) && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
			$fecha = ' Data updated ' . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		return '<b>Source</b>: CIEP, <a href="/">Simulador Fiscal CIEP</a>' . $version . ', with INEGI\'s ' . $enigh . ' benchmarked to the ' . $sna . 'System of National Accounts (INEGI, BIE).' . $fecha;
	},
));
?>
