<?php
// /NTA — Sankey NTA v2 de los hogares, por grupo de edad, tal cual lo emite el motor
// (01_modulos/NTA.do §7 → SankeySumSim folder(SankeyNTA) name(v2-grupoedad) →
// users/<id>/SankeyNTA/sankey-v2-grupoedad.json; contrato v2.1, 05_scripts/test-nta-identidad.sh).
// Página estática de lectura: el texto explica cómo se construye la cuenta por individuo y la
// gráfica; la gráfica se lee en runtime de /jsonSankeyNTA.php?corte=v2-grupoedad y las cifras del
// apartado «Anchoring and residual» de /jsonSankeyNTA.php?cuenta=grupoedad (users/<id>/NTA/
// nta-grupoedad.json, NTA.do §6.2). Primera página de la sección de método (metodo/plantilla.php).
// Sin números en este archivo: todo valor viene de esos dos JSON. v8.12.5 (NTA-2): el Sankey v1
// (Households.do §"Sankeys NTA") ya no se dibuja aquí; el motor lo sigue emitiendo.
require_once dirname(__DIR__) . '/metodo/plantilla.php';

metodo_cabecera(array(
	'slug' => 'NTA',
	'titulo' => 'Household NTA Sankey: how the chart is built',
	'lang' => 'en',
	'descripcion' => 'How the Simulador Fiscal CIEP builds the National Transfer Accounts of households by age from the ENIGH, person by person, closed on the household sector of the national accounts.',
));
?>
		<section class="metodo-texto">
			<p>The chart is a Sankey of the National Transfer Accounts (<abbr title="National Transfer Accounts (Lee–Mason)">NTA</abbr>) of households for one survey year, built person by person from the <abbr title="Encuesta Nacional de Ingresos y Gastos de los Hogares (INEGI)">ENIGH</abbr> and closed on the household sector (S.14) of the national accounts. The Simulador's Households module has first annualized every income and expenditure item, split household-level items among the members of each household<?= metodo_nota_ref(1) ?>, and benchmarked each income and consumption component to the national accounts of the same year (Altimir-type scaling). The NTA module then rearranges those person-level amounts into the lifecycle identity <i>C − YL = (τ⁺ − τ⁻) + (YA − S)</i>: consumption not covered by labor income is financed by net transfers and by asset-based reallocations, each term defined as in the household sector and anchored to it. Labor income excludes pensions and the transfers the survey records inside mixed income. Asset income is net of depreciation, excludes the taxes on products the engine folds into capital income, is scaled to the sector's operating surplus, one third of its mixed income and its net property income, and adds the adjustment for pension entitlements (D.8); imputed rent is income of the household head. Taxes on products enter as income in proportion to consumption, so income is at market prices and consumption at purchasers' prices. Public transfers received are cash pensions and programs scaled to the sector's social benefits, in-kind consumption (education by enrolment, health by private health spending, the rest per capita) equal to social transfers in kind, and collective consumption per capita; public transfers paid are the income tax, social contributions and indirect taxes households pay (not corporate taxes). Private transfers are gifts, inheritances, remittances and cash given to other households. Saving is each household's residual, assigned to its adults in proportion to income and, since the survey total falls within tolerance of the sector's net saving (B.8n), scaled to it by one factor that the chart declares as two explicit nodes. The within-household transfer is the only residual; it sums to zero in every household. Every number is a survey-weighted sum in current pesos: no per-capita values, no single-year age profiles. Age enters only through five groups (0–4, 5–17, 18–24, 25–64, 65 and over); each group appears as an earner on the left, as holder of its income and consumption in the middle, and as a consumer on the right. Reading left to right: age groups, public enterprises and the rest of the world feed the income types, which collapse into national income; it returns to each group, which pays taxes, gives to other households, saves and consumes the rest; government, families and assets send cash transfers, private transfers and dissaving back to the consuming groups, and government buys in-kind and collective consumption; consumption splits into seven private and four public categories, each drawn back to the group that consumed it, while saving goes to a future node per group.</p>
			<p class="lead-nota">Node labels are the ones the engine emits, in Spanish. FusionCharts identifies a node by its label, so the engine disambiguates a name that must appear in two columns by prefixing a space (<code>De 0 a 4</code> on the left as earner vs. <code>&nbsp;De 0 a 4</code> on the right as consumer), and a group's income and consumption nodes carry their own labels (<code>Ingreso 0 a 4</code>, <code>Consumo 0 a 4</code>). If you replicate the schema, keep node identifiers unique.</p>
<?php
metodo_notas(array(
	1 => '<b>Within-household allocation.</b> The ENIGH records most expenditure at the household level and only part of it by person, so building age profiles requires splitting household spending among its members. Dividing equally is a poor assumption: an infant and an adult do not consume the same amount of the same category. Instead, the data decide the split. Each household’s spending in a category is allocated to its members in proportion to the average spending of a person of the same age and sex in that category; since that average depends on the allocation and the allocation on the average, the two are solved jointly as a fixed point, starting from the equal split and iterating until less than one millionth of the category’s spending changes age-sex cell (profiles stable to six significant figures; each category takes the iterations it needs, typically 100–600). Every iteration preserves each household’s total exactly, so the national aggregate never moves; only its distribution within households does. Income is recorded by person in the ENIGH and needs no allocation. A caveat the reader should know: identifying children’s consumption from how household spending varies with household composition tends to attribute little to them (shared goods, economies of scale): at the fixed point a child aged 0–4 is assigned about 11 % of the food spending of an adult aged 30–64, against the 0.4 → 1 equivalence scale that NTA imposes a priori. The chart shows the data-driven allocation; a floor based on the NTA scale is an explicit option in the Simulador, not applied here.',
));
?>
		</section>

		<h2>Nodes and links</h2>
		<section class="metodo-texto">
			<p>Weighted sums use the ENIGH expansion factor (<code>factor</code>) over persons. Variable names are those of the Simulador's person-level NTA file (<code>users/&lt;id&gt;/NTA/nta-persona.dta</code>); the anchors are scalars of the household sector S.14 (INEGI, institutional sector accounts: B.2n, B.3n, D.4, D.8, D.61 − D.614, D.62 + D.759, D.63, B.8n), of the total economy (D.21 − D.31) and of the consumption accounts (<code>ConHog</code>, <code>ConGob</code>, <code>SerEGob</code>, <code>SaluGob</code>, <code>ComprasN</code>, <code>ROWTrans</code>); public-enterprise revenue comes from the federal revenue law (LIF) and the cash transfer profiles from the federal budget (PEF). A node that would carry a zero flow is not emitted (for instance a group with positive saving has no <code>Desahorro</code> node), so the number of nodes depends on the year.</p>
		</section>
		<div class="table-responsive">
			<table class="table table-sm metodo-tabla">
				<thead>
					<tr><th>Column</th><th>Node (label as emitted)</th><th>Definition</th><th>Outgoing links (value) and anchor</th></tr>
				</thead>
				<tbody>
					<tr>
						<th rowspan="7">1 · Sources</th>
						<td><code>De 0 a 4</code>, <code>De 5 a 17</code>, <code>De 18 a 24</code>, <code>De 25 a 64</code>, <code>De 65 y más</code></td>
						<td>Persons grouped by age (<code>edad</code>), as earners.</td>
						<td>→ <code>Ing laboral</code>: Σ <code>YL</code> (wages and the labor share of mixed income, without pensions and without the transfers and financial flows inside mixed income; with net compensation from abroad).<br>→ <code>Ing capital</code>: Σ (<code>YA</code> − <code>YA_d8</code> − <code>ALQ</code>): asset income net of depreciation, without the taxes on products, without imputed rent, scaled to S.14.<br>→ <code>Alquiler propio</code>: Σ <code>ALQ</code>, imputed rent of owner-occupied housing assigned to the household head, scaled with asset income.<br>→ <code>Impuestos a productos</code>: Σ <code>ImpProd</code>, taxes net of subsidies on products in proportion to private consumption (anchor D.21 − D.31).<br>→ <code>Derechos de pensión D8</code>: Σ <code>YA_d8</code>, adjustment for the change in pension entitlements in proportion to the labor income of contributors (anchor D.8).</td>
					</tr>
					<tr>
						<td><code>OyE públicas</code></td>
						<td>Public enterprises and agencies (own revenue, LIF): IMSS + ISSSTE + CFE + Pemex + oil fund (FMP).</td>
						<td>→ <code>Ing capital</code>: that sum.</td>
					</tr>
					<tr>
						<td><code>El mundo</code></td>
						<td>Rest of the world.</td>
						<td>→ <code>Remesas</code>: Σ <code>Remesas</code>, remittances received (anchor <code>ROWTrans</code>, net current transfers from abroad).</td>
					</tr>
					<tr>
						<td><code>Desahorro &lt;group&gt;</code></td>
						<td>A group whose saving is negative (emitted only then).</td>
						<td>→ <code>Activos</code>: −Σ <code>S</code> of the group.</td>
					</tr>
					<tr>
						<td><code>Otras transferencias privadas</code></td>
						<td>Balance of the families hub when private transfers received exceed those given (gifts and inheritances received − cash given to other households and institutions); emitted only if positive.</td>
						<td>→ <code>Familias</code>: that balance.</td>
					</tr>
					<tr>
						<td><code>Déficit público</code></td>
						<td>Balance of the government hub when what households pay plus public-enterprise revenue falls short of cash transfers plus public consumption (corporate taxes are not in the account); emitted only if negative.</td>
						<td>→ <code>Gobierno</code>: −(Σ <code>Tmen</code> + OyE − Σ <code>TpubEf</code> − Σ <code>Cpub</code>).</td>
					</tr>
					<tr>
						<td><code>Ancla S14 complemento</code></td>
						<td>Declared anchor of saving: for a group whose anchored saving is larger than its unanchored saving (its dissaving shrinks), the difference enters its consumption from here.</td>
						<td>→ <code>Consumo &lt;group&gt;</code>: max(<code>S_ajuste</code>, 0) of the group.</td>
					</tr>
					<tr>
						<th>2 · Income types</th>
						<td><code>Ing laboral</code>, <code>Ing capital</code>, <code>Alquiler propio</code>, <code>Impuestos a productos</code>, <code>Derechos de pensión D8</code>, <code>Remesas</code></td>
						<td>Labor income; asset income; imputed rent; taxes on products; pension entitlements; remittances. Σ (<code>Ing capital</code> + <code>Alquiler propio</code>) from the age groups = B.2n + ⅓ B.3n + net D.4 of S.14 (<code>YA_base</code>).</td>
						<td>→ <code>Ing nacional</code>: the sum of the node's inflows (one link per income type).</td>
					</tr>
					<tr>
						<th>3 · Hub</th>
						<td><code>Ing nacional</code></td>
						<td>National income at market prices: the single pivot between resources and their holders. Inflows = outflows by construction.</td>
						<td>→ <code>Ingreso &lt;group&gt;</code>: Σ (<code>YL</code> + <code>YA</code> + <code>ImpProd</code>) of the group.<br>→ <code>Gobierno</code>: the public-enterprise revenue.<br>→ <code>Familias</code>: the remittances.</td>
					</tr>
					<tr>
						<th>4 · Income by group</th>
						<td><code>Ingreso 0 a 4</code> … <code>Ingreso 65 y más</code></td>
						<td>What each age group holds before reallocation. Inflows = outflows (hover the node).</td>
						<td>→ <code>Gobierno</code>: Σ <code>Tmen</code>, taxes paid by households (personal income tax of employees and of individuals, LIF; social contributions, anchor D.61 − D.614; VAT, excises, car and import taxes, LIF).<br>→ <code>Familias</code>: Σ <code>InterOtor</code> (cash given to other households and institutions) + the group's negative net within-household transfer.<br>→ <code>Activos</code>: Σ <code>S</code> if positive.<br>→ <code>Ancla S14 recorte</code>: −min(<code>S_ajuste</code>, 0): the part of the group's unanchored saving that the anchor removes.<br>→ <code>Consumo &lt;group&gt;</code>: the remainder, the consumption the group pays from its own income.</td>
					</tr>
					<tr>
						<th rowspan="3">5 · Reallocation hubs</th>
						<td><code>Gobierno</code></td>
						<td>General government. Inflows: taxes from the groups, public-enterprise revenue and, if needed, <code>Déficit público</code>.</td>
						<td>→ <code>Consumo &lt;group&gt;</code>: Σ <code>TpubEf</code>, cash transfers (contributory pensions and Pensión Bienestar with PEF profiles, scholarships and programs from the ENIGH), all scaled by one factor to D.62 + D.759.<br>→ <code>Educación pública</code> (<code>SerEGob</code>, by enrolment), <code>Salud pública</code> (<code>SaluGob</code> ∝ private health spending), <code>Otros en especie</code> (the rest, per capita): together D.63, social transfers in kind, with an age dimension.<br>→ <code>Colectivo per cápita</code>: <code>ConGob</code> − D.63, collective consumption, per capita to everyone.</td>
					</tr>
					<tr>
						<td><code>Familias</code></td>
						<td>Transfers between households. Inflows: cash given by the groups, remittances and, if needed, <code>Otras transferencias privadas</code>.</td>
						<td>→ <code>Consumo &lt;group&gt;</code>: Σ (<code>InterRec</code> + <code>Remesas</code>) received by the group + its positive net within-household transfer.</td>
					</tr>
					<tr>
						<td><code>Activos</code></td>
						<td>Asset-based reallocation. Inflows: the saving of the groups that save and the <code>Desahorro</code> of those that do not.</td>
						<td>→ <code>Futuro &lt;group&gt;</code>: Σ <code>S</code> if positive (anchor: Σ over groups of saving minus dissaving = B.8n).<br>→ <code>Consumo &lt;group&gt;</code>: −Σ <code>S</code> if negative (the group's dissaving).</td>
					</tr>
					<tr>
						<th>6 · Consumption by group</th>
						<td><code>Consumo 0 a 4</code> … <code>Consumo 65 y más</code></td>
						<td>Private consumption of each age group at purchasers' prices, whoever paid for it. Inflows = outflows (hover the node).</td>
						<td>→ the seven private categories: Σ over the persons of the group of <code>gas_pc_*</code>, including each person's share of net purchases of residents abroad (<code>ComprasN</code>): Alimentos = Agua + Alim + BebN; Vestido = Vest + Calz; Salud = SaluT; Educación = EducT + RecrT; Vivienda = Alqu + HogaT + ComuT + Elec; Transporte = Vehi + STra + FTra; Otros gastos = Taba + BebA + DiveT + RestT. Σ private consumption is reported against P.3 of S.14.</td>
					</tr>
					<tr>
						<th rowspan="2">7 · Uses</th>
						<td><code>Alimentos</code>, <code>Vestido</code>, <code>Salud</code>, <code>Educación</code>, <code>Vivienda</code>, <code>Transporte</code>, <code>Otros gastos</code></td>
						<td>Private consumption categories.</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ of the category over the persons of that group.</td>
					</tr>
					<tr>
						<td><code>Educación pública</code>, <code>Salud pública</code>, <code>Otros en especie</code>, <code>Colectivo per cápita</code></td>
						<td>Public consumption: individual (D.63, by age) and collective (per capita).</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ of the category over the persons of that group.</td>
					</tr>
					<tr>
						<th>8 · Sinks</th>
						<td><code>&nbsp;De 0 a 4</code> … <code>&nbsp;De 65 y más</code>; <code>Futuro &lt;group&gt;</code>; <code>Ancla S14 recorte</code></td>
						<td>The same five age groups as consumers; the future (saving of each group that saves); the declared cut of the saving anchor.</td>
						<td>None (terminal nodes).</td>
					</tr>
				</tbody>
			</table>
		</div>

		<h2>Anchoring and residual</h2>
		<section class="metodo-texto">
			<p>The figures below are read from the engine's account file for this chart (<a href="/jsonSankeyNTA.php?cuenta=grupoedad">jsonSankeyNTA.php?cuenta=grupoedad</a>), in thousands of millions of current pesos (bn) unless stated; the full report, with the identity by age group and by five-year group and sex, is <a href="/jsonSankeyNTA.php?cuenta=identidad">nta-identidad.txt</a>.</p>
			<ul class="metodo-cifras">
				<li><b>Saving before the anchor.</b> The household residual sums to <span data-nta="S_vs_B8n.S_sin_ajuste"></span> bn against net saving of the household sector (B.8n) of <span data-nta="S_vs_B8n.AhorroHog"></span> bn: a gap of <span data-nta="S_vs_B8n.brecha_pct" data-nta-unidad="pct"></span> %, within the <span data-nta="S_vs_B8n.brecha_max_pct" data-nta-unidad="texto"></span> % tolerance, so the anchor mode resolves to <code><span data-nta="S_vs_B8n.modo" data-nta-unidad="texto"></span></code> (parameter <code><span data-nta="S_vs_B8n.modo_param" data-nta-unidad="texto"></span></code>).</li>
				<li><b>The cut.</b> Saving is multiplied by <span data-nta="S_vs_B8n.factor_implicito" data-nta-unidad="factor"></span> (B.8n over the survey total), so Σ saving in the chart is <span data-nta="S_vs_B8n.S_final"></span> bn. The difference, <span data-nta="S_vs_B8n.S_ajuste"></span> bn, is not folded into any other term: it is what <code>Ancla S14 recorte</code> minus <code>Ancla S14 complemento</code> carries, group by group.</li>
				<li><b>Asset income.</b> The engine's household asset income, <span data-nta="ya_s14.YA_motor"></span> bn, is scaled by <span data-nta="ya_s14.factor" data-nta-unidad="factor"></span> to <span data-nta="ya_s14.YAHogS14"></span> bn (B.2n <span data-nta="ya_s14.B2n"></span> + ⅓ B.3n <span data-nta="ya_s14.tercio_B3n"></span> + net D.4 <span data-nta="ya_s14.D4_neto"></span>), keeping its distribution; the Simulador records the gap as a pending correction of the engine.</li>
				<li><b>The only residual is within the household.</b> By age group, the net within-household transfer is <span data-nta="grupos.1.Intra"></span> (0–4), <span data-nta="grupos.2.Intra"></span> (5–17), <span data-nta="grupos.3.Intra"></span> (18–24), <span data-nta="grupos.4.Intra"></span> (25–64) and <span data-nta="grupos.5.Intra"></span> bn (65 and over); it sums to <span data-nta="gates.intra_nacional" data-nta-unidad="mxn"></span> pesos nationally and the largest household total is <span data-nta="gates.intra_hogar_max" data-nta-unidad="mxn"></span> pesos. The identity without the anchor closes to <span data-nta="gates.residual_max_persona" data-nta-unidad="mxn"></span> pesos per person at most; with the anchor, its residual is exactly the cut above.</li>
				<li><b>Consumption.</b> Σ private consumption is <span data-nta="grupos.0.Cpriv"></span> bn against P.3 of S.14 of <span data-nta="anclas.ConHogS14_P3"></span> bn (the engine anchors to the BIE figure, <span data-nta="anclas.ConHog"></span> bn, and subtracts net purchases of residents abroad); public consumption is <span data-nta="grupos.0.Cpub"></span> bn, of which <span data-nta="congob.individual_D63"></span> bn in kind (D.63) and <span data-nta="congob.colectivo_per_capita"></span> bn collective.</li>
				<li><b>Provenance.</b> <span data-nta="procedencia.modulo" data-nta-unidad="texto"></span>, generated <span data-nta="procedencia.generado_el" data-nta-unidad="texto"></span>; parameters <code><span data-nta="parametros.nta_YA" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_cuotas" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_d8" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_alqu" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_mixto" data-nta-unidad="texto"></span></code> (see the header of <code>01_modulos/NTA.do</code>).</li>
			</ul>
		</section>

		<h2>The chart, as the engine emits it</h2>
		<div class="metodo-sankey-wrap">
			<table class="metodo-titulos">
				<tbody>
					<tr>
						<td style="text-align:left;">Sources: age groups (earners) · public enterprises · rest of the world · balances</td>
						<td style="text-align:center;">Income types</td>
						<td style="text-align:center;">National income (MXN, current)</td>
						<td style="text-align:center;">Income by group</td>
						<td style="text-align:center;">Government · Families · Assets</td>
						<td style="text-align:center;">Consumption by group</td>
						<td style="text-align:center;">Uses: private and public categories</td>
						<td style="text-align:right;">Sinks: age groups (consumers) · future · anchor cut</td>
					</tr>
				</tbody>
			</table>
			<div class="chart metodo-sankey metodo-sankey-alto" id="sankey-nta"></div>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota">Hover a link to read its value, and a group node (<code>Ingreso …</code>, <code>Consumo …</code>) to see that its inflows equal its outflows. The data behind the chart is served verbatim from the engine's output (<a href="/jsonSankeyNTA.php?corte=v2-grupoedad">jsonSankeyNTA.php?corte=v2-grupoedad</a>); the same engine run also emits the previous household Sankey by income decile, sex, age group, schooling and rural/urban/indigenous (<code>corte=decil|sexo|grupoedad|escol|rural</code>), which this page no longer draws.</p>
		</section>
<?php
metodo_pie(array(
	'sankeys' => array(
		array('renderAt' => 'sankey-nta', 'url' => '/jsonSankeyNTA.php?corte=v2-grupoedad'),
	),
	'cifras' => array('url' => '/jsonSankeyNTA.php?cuenta=grupoedad'),
	'fuente' => function ($meta) {
		$enigh = $meta['enigh_vintage'] !== '' ? 'ENIGH ' . htmlspecialchars($meta['enigh_vintage']) : 'ENIGH';
		$version = $meta['version_html'] !== '' ? ' ' . $meta['version_html'] : '';
		$sna = $meta['enigh_vintage'] !== '' ? htmlspecialchars($meta['enigh_vintage']) . ' ' : '';
		$fecha = '';
		if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $meta['data_updated_iso'], $dm) && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
			$fecha = ' Data updated ' . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		return '<b>Source</b>: CIEP, <a href="/">Simulador Fiscal CIEP</a>' . $version . ', National Transfer Accounts by individual (<code>NTA.do</code>) with INEGI\'s ' . $enigh . ' benchmarked to the household sector of the ' . $sna . 'System of National Accounts (INEGI, BIE and institutional sector accounts).' . $fecha;
	},
));
?>
