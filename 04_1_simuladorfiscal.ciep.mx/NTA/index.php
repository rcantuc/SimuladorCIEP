<?php
// /NTA — Sankey NTA v3 de los hogares, por grupo de edad, tal cual lo emite el motor
// (01_modulos/NTA.do §7b → SankeySumSim folder(SankeyNTA) name(v3-grupoedad) →
// users/<id>/SankeyNTA/sankey-v3-grupoedad.json; contrato v3, 05_scripts/test-nta-identidad.sh), y debajo el panel
// por grupo de edad × sexo (NTA.do §7c → users/<id>/NTA/nta-panel-grupoedad-sexo.json; cinco mini-Sankeys con
// selector Total / Hombres / Mujeres que lee las tres variantes del mismo JSON, sin recarga).
// Página estática de lectura: el texto explica cómo se construye la cuenta por individuo y la gráfica; la gráfica se
// lee en runtime de /jsonSankeyNTA.php?corte=v3-grupoedad, el panel de /jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo
// y las cifras del apartado «Anchoring and residual» de /jsonSankeyNTA.php?cuenta=grupoedad (users/<id>/NTA/
// nta-grupoedad.json, NTA.do §6.2). Primera página de la sección de método (metodo/plantilla.php).
// Sin números en este archivo: todo valor viene de esos tres JSON. v8.12.5 (NTA-2): el Sankey v1 ya no se dibuja aquí;
// v8.12.6 (NTA-3): el v2 tampoco (decisión de Ricardo del 29-oct: edades solo al inicio y al final; las transferencias
// en efectivo y familiares, que netean a cero nacionalmente, viven en el panel). El motor sigue emitiendo v1 y v2.
// v8.13.0 (NTA-4, decisiones de Ricardo del 29-oct): el v3 se dibuja y se lee en % del PIB del año (cada enlace trae value en
// MXN y pctpib dividido en Stata; tooltip con ambas unidades), con un solo «Desahorro», un solo «Futuro», la especie pública
// fundida en su categoría de consumo y un solo nodo de ancla («Ajuste a cuentas nacionales S14», el neto). Las cifras de
// «Anchoring and residual» van en bn (cuenta) y en % del PIB (bloque nacional_pctpib del panel; <span data-pib>), incluido el
// año del encabezado de unidad (pib.anio del panel): aquí tampoco hay literales.
require_once dirname(__DIR__) . '/metodo/plantilla.php';

metodo_cabecera(array(
	'slug' => 'NTA',
	'titulo' => 'Household NTA Sankey: how the chart is built',
	'lang' => 'en',
	'descripcion' => 'How the Simulador Fiscal CIEP builds the National Transfer Accounts of households by age from the ENIGH, person by person, closed on the household sector of the national accounts.',
));
?>
		<section class="metodo-texto">
			<p>The chart is a Sankey of the National Transfer Accounts (<abbr title="National Transfer Accounts (Lee–Mason)">NTA</abbr>) of households for one survey year, built person by person from the <abbr title="Encuesta Nacional de Ingresos y Gastos de los Hogares (INEGI)">ENIGH</abbr> and closed on the household sector (S.14) of the national accounts. The Simulador's Households module has first annualized every income and expenditure item, split household-level items among the members of each household<?= metodo_nota_ref(1) ?>, and benchmarked each income and consumption component to the national accounts of the same year (Altimir-type scaling). The NTA module then rearranges those person-level amounts into the lifecycle identity <i>C − YL = (τ⁺ − τ⁻) + (YA − S)</i>: consumption not covered by labor income is financed by net transfers and by asset-based reallocations, each term defined as in the household sector and anchored to it. Since v8.15.0 (Cuadratura I, memo CUAD-0 signed on 2026-10-31) the Households module anchors each income to its own cell of the household sector: wages to D.1, mixed income (fees, actual rents and own businesses) to B.3n, imputed rent to B.2n, property income to net D.4 spread by a declared property proxy (the survey sees under 1 % of that cell), with pensions, transfers, financial flows and taxes on products kept out of labor and asset income, so labor income is D.1 + ⅔ B.3n and asset income, net of depreciation, is B.2n + ⅓ B.3n + net D.4 less the return on pension entitlements (D.442) to the peso, plus the adjustment for pension entitlements (D.8); imputed rent is income of the household head. Taxes on products enter as income in proportion to consumption, so income is at market prices and consumption at purchasers' prices. Public transfers received are cash pensions and programs scaled to the sector's social benefits, in-kind consumption (education by enrolment, health by private health spending, the rest per capita) equal to social transfers in kind, and collective consumption per capita; public transfers paid are the income tax, social contributions and indirect taxes households pay (not corporate taxes). Private transfers are gifts, inheritances, remittances and cash given to other households. Saving is each household's residual, assigned to its adults in proportion to income and, since the survey total falls within tolerance of the sector's net saving (B.8n), scaled to it by one factor that the chart declares as one explicit node (the net of the cut and its complement; the table below keeps the two apart). The within-household transfer is the only residual; it sums to zero in every household. Every number is a survey-weighted sum in current pesos, and the chart shows each flow as a share of the GDP of the same year (% of GDP, GDP = 100): the engine emits every link in both units, dividing by the nominal GDP it registers from the national accounts, and nothing is divided outside it. No per-capita values, no single-year age profiles. Age enters only through five groups (0–4, 5–17, 18–24, 25–64, 65 and over) and only at the two ends of the chart: each group appears as an earner on the left and as a consumer on the right. Reading left to right: age groups and the rest of the world feed the income types, which collapse into the household-side income hub (<code>Ing nacional</code>: the sector's primary income at market prices before taxes, plus remittances, taxes on products and the pension-entitlement adjustment; see note<?= metodo_nota_ref(2) ?>); public-enterprise revenue is not household income and goes straight to government as a sector row (<code>Empresas públicas</code>); from there the taxes households pay go to government, the saving of the groups that save goes to assets, and the rest finances private consumption directly; government buys in-kind consumption, which joins the health, education and other-spending categories next to the private spending of the same kind, and collective consumption, which has no age and ends in its own node, and returns the remainder of what it collects as a single cash-transfers node; assets send the saving of the groups that save to one future node, the dissaving of the groups that dissave back into consumption, and the net of the saving anchor to one national-accounts adjustment node; the seven consumption categories are each drawn back to the group that consumed them, private and in-kind together. Who saves and who dissaves, and where the anchor bites, is in the panel below. Cash transfers, transfers between households and transfers within households net to zero across the nation, so the main chart does not draw them by age: the panel below does, group by group and by sex.</p>
			<p class="lead-nota">Node labels are the ones the engine emits, in Spanish. FusionCharts identifies a node by its label, so the engine disambiguates a name that must appear in two columns by prefixing a space (<code>De 0 a 4</code> on the left as earner vs. <code>&nbsp;De 0 a 4</code> on the right as consumer), and dissaving and the future carry their own labels (<code>Desahorro</code>, <code>Futuro</code>). If you replicate the schema, keep node identifiers unique.</p>
<?php
metodo_notas(array(
	1 => '<b>Within-household allocation.</b> The ENIGH records most expenditure at the household level and only part of it by person, so building age profiles requires splitting household spending among its members. Dividing equally is a poor assumption: an infant and an adult do not consume the same amount of the same category. Instead, the data decide the split. Each household’s spending in a category is allocated to its members in proportion to the average spending of a person of the same age and sex in that category; since that average depends on the allocation and the allocation on the average, the two are solved jointly as a fixed point, starting from the equal split and iterating until less than one millionth of the category’s spending changes age-sex cell (profiles stable to six significant figures; each category takes the iterations it needs, typically 100–600). Every iteration preserves each household’s total exactly, so the national aggregate never moves; only its distribution within households does. Income is recorded by person in the ENIGH and needs no allocation. A caveat the reader should know: identifying children’s consumption from how household spending varies with household composition tends to attribute little to them (shared goods, economies of scale): at the fixed point a child aged 0–4 is assigned about 11 % of the food spending of an adult aged 30–64, against the 0.4 → 1 equivalence scale that NTA imposes a priori. The chart shows the data-driven allocation; a floor based on the NTA scale is an explicit option in the Simulador, not applied here.',
	2 => '<b>Why the hub is not national income.</b> SNA net national disposable income is 81.6 % of GDP in the survey year (GDP 100 − consumption of fixed capital 19.2 + net compensation from abroad 0.2 − net property income paid abroad 2.9 + net current transfers from abroad 3.5). The <code>Ing nacional</code> hub is the household side of the account and reads 82.4 % of GDP in this version (v8.15.0, Cuadratura I): the sector’s balance of primary incomes at the peso (D.1 29.9 + B.3n 20.7 + B.2n 2.7 + net D.4 16.6 = 69.9, the engine’s labor and asset incomes now equal their cells, so the labor gap of earlier versions is 0) less the return on pension entitlements D.442 (−1.8, a circuit that returns to the pension funds as D.614), plus flows that national income does not count as household income — the pension-entitlement adjustment D.8 (+3.8) and the survey’s imbalance of private transfers (+0.6) — and without what the other sectors keep after property income: the retained net surplus of corporations (−2.8), the government’s primary income other than taxes on products, which is negative and so adds when left out (+1.7: other production taxes 0.8 less net interest paid 2.5), NPISH (−0.3) and a vintage difference between the BIE series and the institutional-sector tables (−0.3): 81.6 − 1.8 + 3.8 + 0.6 − 2.8 + 1.7 − 0.3 − 0.3 = 82.4. Taxes on products (6.5) and remittances (3.5) are in both, on the government side and abroad in the SNA, as household income here. Public-enterprise revenue (4.8) is no longer in the hub: since v8.15.0 it enters <code>Gobierno</code> directly from <code>Empresas públicas</code> (CUAD-0, decision 10), which is why the hub falls from 85.7 % in v8.14.0 (where it also carried a labor gap of −3.2 and the embedded product taxes) to 82.4 %. The other side of the same change: the household residual before the saving anchor is now 2,116.1 bn against B.8n of 1,901.0 (a gap of +11.3 %, inside the 15 % tolerance; the gap itemized in <code>nta-identidad.txt</code> is +209.2 from personal income tax paid per the revenue law against D.5, +461.0 from cash transfers against D.62 + D.7, −438.1 from private consumption against P.3 and −17.0 from product taxes), so the multiplicative factor is <span data-nta="S_vs_B8n.factor_implicito" data-nta-unidad="factor"></span> (B.8n over the survey total) and the adjustment node is a <b>sink</b> of 215.1 bn fed from <code>Activos</code> (a cut of 227.7 and a complement of 12.6), where v8.14.0 had a source of +266.2 bn (gap −14.0 %). The hub, saving and anchor figures above are printed here for the record; the live ones are the engine’s (the <span data-pib="hub_Ing_nacional"></span> % of GDP of the hub and the panel of «Anchoring and residual»).'
));
?>
		</section>

		<h2>Nodes and links</h2>
		<section class="metodo-texto">
			<p>Weighted sums use the ENIGH expansion factor (<code>factor</code>) over persons. Variable names are those of the Simulador's person-level NTA file (<code>users/&lt;id&gt;/NTA/nta-persona.dta</code>); the anchors are scalars of the household sector S.14 (INEGI, institutional sector accounts: B.2n, B.3n, D.4, D.8, D.61 − D.614, D.62 + D.759, D.63, B.8n), of the total economy (D.21 − D.31) and of the consumption accounts (<code>ConHog</code>, <code>ConGob</code>, <code>SerEGob</code>, <code>SaluGob</code>, <code>ComprasN</code>, <code>ROWTrans</code>); public-enterprise revenue comes from the federal revenue law (LIF) and the cash transfer profiles from the federal budget (PEF). A node that would carry a zero flow is not emitted (for instance, if no group dissaved there would be no <code>Desahorro</code> node), so the number of nodes depends on the year. Private consumption is financed from three places and the chart keeps them apart: what the groups pay from their own income arrives from <code>Ing nacional</code>, what they pay with public cash transfers arrives from <code>Transferencias en efectivo</code>, and what they pay by dissaving arrives from <code>Activos</code>; each group's share of each flow is split across the seven categories by that group's own basket (Σ <code>gas_pc_*</code> of the category over Σ private consumption of the group), the same split the previous version made inside a per-group consumption node. In-kind public consumption arrives from <code>Gobierno</code> into the same categories (<code>Salud</code>, <code>Educación</code>, <code>Otros gastos</code>), so each category sends each group its private plus its in-kind consumption of that kind.</p>
			<p><b>Units.</b> The engine emits every link twice: in current pesos (<code>value</code>) and as a percentage of the GDP of the same year (<code>pctpib</code> = <code>value</code> / GDP × 100, divided in Stata with the nominal GDP that the national-accounts module registers for the year). The chart is drawn and read in % of GDP (GDP = 100); hover a link for both units, and a node for its total in % of GDP. The <code>Ing nacional</code> hub is the household side of the NTA account, not national income: it reads <span data-pib="hub_Ing_nacional"></span> % of GDP against 81.6 % for the SNA net national disposable income of the same year. It is not GDP either: GDP net of depreciation (consumption of fixed capital, <span data-pib="CapFij"></span> % of GDP) and of the balance of primary income with the rest of the world (<span data-pib="ROWProp"></span> % of GDP) is national income; the hub carries what reaches households, plus the taxes on products (<span data-pib="ImpProd"></span>) and remittances (<span data-pib="Remesas"></span> % of GDP); public-enterprise revenue (<span data-pib="OyE"></span> % of GDP) enters the government hub directly, not the income hub; note<?= metodo_nota_ref(2) ?> itemizes the difference with national income; what corporations and government retain is not in the chart.</p>
		</section>
		<div class="table-responsive">
			<table class="table table-sm metodo-tabla">
				<thead>
					<tr><th>Column</th><th>Node (label as emitted)</th><th>Definition</th><th>Outgoing links (value) and anchor</th></tr>
				</thead>
				<tbody>
					<tr>
						<th rowspan="6">1 · Sources</th>
						<td><code>De 0 a 4</code>, <code>De 5 a 17</code>, <code>De 18 a 24</code>, <code>De 25 a 64</code>, <code>De 65 y más</code></td>
						<td>Persons grouped by age (<code>edad</code>), as earners.</td>
						<td>→ <code>Ing laboral</code>: Σ <code>YL</code> (wages anchored to D.1 of S.14, which already includes compensation from abroad, plus the labor share of mixed income, B.3n; without pensions, transfers or financial flows).<br>→ <code>Ing capital</code>: Σ (<code>YA</code> − <code>YA_d8</code> − <code>ALQ</code>): asset income net of depreciation, without the taxes on products, without imputed rent, scaled to S.14.<br>→ <code>Alquiler propio</code>: Σ <code>ALQ</code>, imputed rent of owner-occupied housing assigned to the household head, scaled with asset income.<br>→ <code>Impuestos a productos</code>: Σ <code>ImpProd</code>, taxes net of subsidies on products in proportion to private consumption (anchor D.21 − D.31).<br>→ <code>Derechos de pensión D8</code>: Σ <code>YA_d8</code>, adjustment for the change in pension entitlements in proportion to the labor income of contributors (anchor D.8).</td>
					</tr>
					<tr>
						<td><code>Empresas públicas</code></td>
						<td>Public enterprises and agencies (own revenue, LIF): IMSS + ISSSTE + CFE + Pemex + oil fund (FMP). Not household income (sales of Pemex and CFE and the oil rent are already in the surplus of the corporations and of government in the national accounts), so since v8.15.0 it does not pass through <code>Ing nacional</code>: it is a sector row (CUAD-0, decision 10).</td>
						<td>→ <code>Gobierno</code>: that sum.</td>
					</tr>
					<tr>
						<td><code>El mundo</code></td>
						<td>Rest of the world.</td>
						<td>→ <code>Remesas</code>: Σ <code>Remesas</code>, remittances received (anchor <code>ROWTrans</code>, net current transfers from abroad).</td>
					</tr>
					<tr>
						<td><code>Desahorro</code></td>
						<td>The dissaving of the groups whose (anchored) saving is negative, summed into one source; emitted only if some group dissaves. Which groups, and how much each, is in the panel below.</td>
						<td>→ <code>Activos</code>: Σ over groups of max(−Σ <code>S</code>, 0).</td>
					</tr>
					<tr>
						<td><code>Otras transferencias privadas</code></td>
						<td>Balance of transfers between households when those recorded as received exceed those recorded as given (gifts and inheritances received − cash given to other households and institutions): a survey imbalance, entered as a resource; emitted only if positive (if negative it leaves <code>Ing nacional</code> as <code>Transferencias privadas netas</code>).</td>
						<td>→ <code>Ing nacional</code>: Σ <code>InterRec</code> − Σ <code>InterOtor</code>.</td>
					</tr>
					<tr>
						<td><code>Déficit público</code></td>
						<td>Balance of the government hub when what households pay plus public-enterprise revenue falls short of cash transfers plus public consumption (corporate taxes are not in the account); emitted only if negative (if positive, <code>Gobierno</code> sends it to <code>Resto del gasto público</code>).</td>
						<td>→ <code>Gobierno</code>: −(Σ <code>Tmen</code> + OyE − Σ <code>TpubEf</code> − Σ <code>Cpub</code>).</td>
					</tr>
					<tr>
						<th>2 · Income types</th>
						<td><code>Ing laboral</code>, <code>Ing capital</code>, <code>Alquiler propio</code>, <code>Impuestos a productos</code>, <code>Derechos de pensión D8</code>, <code>Remesas</code></td>
						<td>Labor income; asset income; imputed rent; taxes on products; pension entitlements; remittances. Σ (<code>Ing capital</code> + <code>Alquiler propio</code>) from the age groups = B.2n + ⅓ B.3n + net D.4 of S.14 less D.442 (<code>YA_base</code>; since v8.15.0 the engine brings it to the peso, factor 1). <code>Ing laboral</code> = D.1 + ⅔ B.3n of S.14.</td>
						<td>→ <code>Ing nacional</code>: the sum of the node's inflows (one link per income type).</td>
					</tr>
					<tr>
						<th>3 · Hub</th>
						<td><code>Ing nacional</code></td>
						<td>Household-side income at market prices before taxes (S.14 primary income less D.442, taxes on products, D.8 and remittances, plus the private-transfer balance if positive): the single pivot between resources and their uses. It is not national income: it reads <span data-pib="hub_Ing_nacional"></span> % of GDP against 81.6 % for SNA net national disposable income (note<?= metodo_nota_ref(2) ?>). Inflows = outflows by construction (hover the node for the total in % of GDP).</td>
						<td>→ <code>Gobierno</code>: Σ <code>Tmen</code>, taxes paid by households (personal income tax of employees and of individuals, LIF; social contributions, anchor D.61 − D.614; VAT, excises, car and import taxes, LIF); public-enterprise revenue reaches <code>Gobierno</code> from <code>Empresas públicas</code>, not from the hub.<br>→ <code>Activos</code>: Σ over the groups that save of their saving before the anchor (<code>S</code> + the anchor cut).<br>→ each private category: Σ over groups of the group's own-income financing of private consumption (Σ <code>YL</code> + <code>YA</code> + <code>ImpProd</code> − <code>Tmen</code> − max(<code>S</code>, 0) − cut + <code>InterRec</code> + <code>Remesas</code> + <code>Intra</code> − <code>InterOtor</code>), split by the group's basket.</td>
					</tr>
					<tr>
						<th rowspan="2">4 · Reallocation hubs</th>
						<td><code>Gobierno</code></td>
						<td>General government. Inflows: taxes from <code>Ing nacional</code>, public-enterprise revenue from <code>Empresas públicas</code> and, if needed, <code>Déficit público</code>. Inflows = outflows (hover the node).</td>
						<td>→ <code>Educación</code> (<code>SerEGob</code>, by enrolment), <code>Salud</code> (<code>SaluGob</code> ∝ private health spending), <code>Otros gastos</code> (the rest of in-kind consumption, per capita): together D.63, social transfers in kind, with an age dimension, each entering the consumption category of the same kind next to what households pay for themselves.<br>→ <code>Colectivo</code>: <code>ConGob</code> − D.63, collective consumption; it has no age and ends there.<br>→ <code>Transferencias en efectivo</code>: Σ <code>TpubEf</code>, cash transfers (contributory pensions and Pensión Bienestar with PEF profiles, scholarships and programs from the ENIGH), all scaled by one factor to D.62 + D.759: what the government collects and does not consume, as a single node without age.</td>
					</tr>
					<tr>
						<td><code>Activos</code></td>
						<td>Asset-based reallocation. Inflows: the saving before the anchor of the groups that save and the <code>Desahorro</code> of those that do not (and, in a year where the anchor's complement exceeded its cut, the net complement from <code>Ajuste a cuentas nacionales S14</code>). Inflows = outflows (hover the node).</td>
						<td>→ <code>Futuro</code>: Σ over the groups that save of their anchored saving, as one node (anchor: Σ over groups of saving minus dissaving = B.8n).<br>→ <code>Ajuste a cuentas nacionales S14</code>: the net of the saving anchor, Σ over groups of max(−<code>S_ajuste</code>, 0) (the cut: unanchored saving the anchor removes) minus Σ of max(<code>S_ajuste</code>, 0) (the complement: unanchored dissaving the anchor removes), as one node; the two parts are reported below and in the panel.<br>→ each category: the dissaving of the groups that dissave (plus the complement), split by their baskets.</td>
					</tr>
					<tr>
						<th>5 · Cash transfers</th>
						<td><code>Transferencias en efectivo</code></td>
						<td>Public cash transfers to persons, without age in this chart (the panel below shows who receives them). Inflows = outflows (hover the node).</td>
						<td>→ each private category: Σ over groups of the group's cash transfers received, split by the group's basket.</td>
					</tr>
					<tr>
						<th>6 · Uses</th>
						<td><code>Alimentos</code>, <code>Vestido</code>, <code>Salud</code>, <code>Educación</code>, <code>Vivienda</code>, <code>Transporte</code>, <code>Otros gastos</code></td>
						<td>Consumption categories at purchasers' prices, whoever paid for them. Private: Alimentos = Agua + Alim + BebN; Vestido = Vest + Calz; Salud = SaluT; Educación = EducT + RecrT; Vivienda = Alqu + HogaT + ComuT + Elec; Transporte = Vehi + STra + FTra; Otros gastos = Taba + BebA + DiveT + RestT, each including the person's share of net purchases of residents abroad (<code>ComprasN</code>); Σ private consumption is reported against P.3 of S.14. In kind (D.63, by age, from <code>Gobierno</code>): public health into <code>Salud</code>, public education into <code>Educación</code>, the rest into <code>Otros gastos</code>. Inflows (own income + cash transfers + dissaving + in-kind public consumption) = outflows by the identity.</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ of the category, private plus in kind, over the persons of that group.</td>
					</tr>
					<tr>
						<th>7 · Sinks</th>
						<td><code>&nbsp;De 0 a 4</code> … <code>&nbsp;De 65 y más</code>; <code>Futuro</code>; <code>Colectivo</code>; <code>Ajuste a cuentas nacionales S14</code></td>
						<td>The same five age groups as consumers (private + in-kind consumption; collective consumption, with no age, ends in its own node); the future (the saving of the groups that save, one node); the declared net adjustment of saving to the national accounts (the cut minus its complement; it would appear among the sources if the complement were larger).</td>
						<td>None (terminal nodes).</td>
					</tr>
				</tbody>
			</table>
		</div>

		<h2>Anchoring and residual</h2>
		<section class="metodo-texto">
			<p>The figures below are read from the engine's account file for this chart (<a href="/jsonSankeyNTA.php?cuenta=grupoedad">jsonSankeyNTA.php?cuenta=grupoedad</a>), in thousands of millions of current pesos (bn) unless stated, and, in % of GDP, from the national block of the panel file (<a href="/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo">jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo</a>, <code>nacional_pctpib</code>, divided in Stata with the same GDP as the chart); the full report, with the identity by age group and by five-year group and sex, is <a href="/jsonSankeyNTA.php?cuenta=identidad">nta-identidad.txt</a>.</p>
			<ul class="metodo-cifras">
				<li><b>Saving before the anchor.</b> The household residual sums to <span data-nta="S_vs_B8n.S_sin_ajuste"></span> bn (<span data-pib="S_sin_ajuste"></span> % of GDP) against net saving of the household sector (B.8n) of <span data-nta="S_vs_B8n.AhorroHog"></span> bn (<span data-pib="AhorroHog"></span> % of GDP): a gap of <span data-nta="S_vs_B8n.brecha_pct" data-nta-unidad="pct"></span> %, within the <span data-nta="S_vs_B8n.brecha_max_pct" data-nta-unidad="texto"></span> % tolerance, so the anchor mode resolves to <code><span data-nta="S_vs_B8n.modo" data-nta-unidad="texto"></span></code> (parameter <code><span data-nta="S_vs_B8n.modo_param" data-nta-unidad="texto"></span></code>).</li>
				<li><b>The cut, in one node.</b> Saving is multiplied by <span data-nta="S_vs_B8n.factor_implicito" data-nta-unidad="factor"></span> (B.8n over the survey total), so Σ saving in the chart is <span data-nta="S_vs_B8n.S_final"></span> bn (<span data-pib="S_final"></span> % of GDP). The difference, <span data-nta="S_vs_B8n.S_ajuste"></span> bn (<span data-pib="S_ajuste"></span> % of GDP), is not folded into any other term: the chart carries its net as the single node <code>Ajuste a cuentas nacionales S14</code>, fed from <code>Activos</code> with <span data-pib="ancla_neto" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn (<span data-pib="ancla_neto"></span> % of GDP). That net is the cut, <span data-pib="ancla_recorte" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn (<span data-pib="ancla_recorte"></span> % of GDP: unanchored saving the factor removes from the groups that save), minus its complement, <span data-pib="ancla_complemento" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn (<span data-pib="ancla_complemento"></span> % of GDP: unanchored dissaving it removes from the groups that dissave); the panel below shows both, cell by cell.</li>
				<li><b>Asset income.</b> The engine's household asset income, <span data-nta="ya_s14.YA_motor"></span> bn (<span data-pib="YA_motor"></span> % of GDP), is anchored to <span data-nta="ya_s14.YAHogS14_ancla"></span> bn (B.2n <span data-nta="ya_s14.B2n"></span> + ⅓ B.3n <span data-nta="ya_s14.tercio_B3n"></span> + net D.4 <span data-nta="ya_s14.D4_neto"></span> − D.442 <span data-nta="ya_s14.D442"></span>; the sector's total, <span data-nta="ya_s14.YAHogS14"></span> bn, is <span data-pib="YAHogS14"></span> % of GDP) with factor <span data-nta="ya_s14.factor" data-nta-unidad="factor"></span>: since v8.15.0 the engine's household asset income already equals that cell to the peso (the factor is 1 and is enforced), so nothing is rescaled here.</li>
				<li><b>Cash and family transfers net to zero nationally.</b> Government returns <span data-nta="grupos.0.TpubEf"></span> bn (<span data-pib="TpubEf"></span> % of GDP) in cash transfers out of <span data-nta="grupos.0.Tmen"></span> bn (<span data-pib="Tmen"></span> % of GDP) of taxes paid by households plus <span data-nta="anclas.OyE"></span> bn (<span data-pib="OyE"></span> % of GDP) of public-enterprise revenue; households give <span data-nta="grupos.0.InterOtor"></span> bn (<span data-pib="InterOtor"></span> % of GDP) to other households and record <span data-nta="grupos.0.InterRec"></span> bn (<span data-pib="InterRec"></span> % of GDP) received (plus <span data-nta="grupos.0.Remesas"></span> bn, <span data-pib="Remesas"></span> % of GDP, of remittances, which come from abroad and are income). Who receives and who pays, by age group and by sex, is the panel below; the main chart carries the cash as a single node and the family transfers inside each group's own-income financing.</li>
				<li><b>The only residual is within the household.</b> By age group, the net within-household transfer is <span data-nta="grupos.1.Intra"></span> (0–4), <span data-nta="grupos.2.Intra"></span> (5–17), <span data-nta="grupos.3.Intra"></span> (18–24), <span data-nta="grupos.4.Intra"></span> (25–64) and <span data-nta="grupos.5.Intra"></span> bn (65 and over); it sums to <span data-nta="gates.intra_nacional" data-nta-unidad="mxn"></span> pesos nationally and the largest household total is <span data-nta="gates.intra_hogar_max" data-nta-unidad="mxn"></span> pesos. The identity without the anchor closes to <span data-nta="gates.residual_max_persona" data-nta-unidad="mxn"></span> pesos per person at most; with the anchor, its residual is exactly the cut above.</li>
				<li><b>Consumption.</b> Σ private consumption is <span data-nta="grupos.0.Cpriv"></span> bn (<span data-pib="Cpriv"></span> % of GDP) against P.3 of S.14 of <span data-nta="anclas.ConHogS14_P3"></span> bn (<span data-pib="ConHogS14_P3"></span> % of GDP; the engine anchors to the BIE figure, <span data-nta="anclas.ConHog"></span> bn, and subtracts net purchases of residents abroad); public consumption is <span data-nta="grupos.0.Cpub"></span> bn (<span data-pib="Cpub"></span> % of GDP), of which <span data-nta="congob.individual_D63"></span> bn (<span data-pib="individual_D63"></span> % of GDP) in kind (D.63), now inside the health, education and other-spending categories of the chart, and <span data-nta="congob.colectivo_per_capita"></span> bn (<span data-pib="colectivo"></span> % of GDP) collective, in its own node.</li>
				<li><b>The hubs, in % of GDP.</b> <code>Ing nacional</code> <span data-pib="hub_Ing_nacional"></span>; <code>Gobierno</code> <span data-pib="hub_Gobierno"></span>; <code>Activos</code> <span data-pib="hub_Activos"></span>; <code>Transferencias en efectivo</code> <span data-pib="hub_Transferencias_efectivo"></span>; <code>Futuro</code> <span data-pib="Futuro"></span>; <code>Desahorro</code> <span data-pib="Desahorro"></span>; <code>Colectivo</code> <span data-pib="colectivo"></span> % of GDP (GDP = <span data-pib="valor" data-pib-bloque="pib" data-pib-unidad="bn"></span> bn in <span data-pib="anio" data-pib-bloque="pib" data-pib-unidad="texto"></span>). <code>Ing nacional</code> is not national income: note<?= metodo_nota_ref(2) ?>.</li>
				<li><b>Provenance.</b> <span data-nta="procedencia.modulo" data-nta-unidad="texto"></span>, generated <span data-nta="procedencia.generado_el" data-nta-unidad="texto"></span>; parameters <code><span data-nta="parametros.nta_YA" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_cuotas" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_d8" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_alqu" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_mixto" data-nta-unidad="texto"></span></code> (see the header of <code>01_modulos/NTA.do</code>); Households parameters (CUAD-0, signed 2026-10-31): <code><span data-nta="parametros.households" data-nta-unidad="texto"></span></code>.</li>
			</ul>
		</section>

		<h2>The chart, as the engine emits it</h2>
		<section class="metodo-texto">
			<p class="lead-nota metodo-unidad">Unit: % of <span data-pib="anio" data-pib-bloque="pib" data-pib-unidad="texto"></span> GDP; GDP = 100. Hover a link for both units (% of GDP and current pesos).</p>
		</section>
		<div class="metodo-sankey-wrap">
			<table class="metodo-titulos">
				<tbody>
					<tr>
						<td style="text-align:left;">Sources: age groups (earners) · public enterprises · rest of the world · dissaving · balances</td>
						<td style="text-align:center;">Income types</td>
						<td style="text-align:center;">Household income hub (% of GDP)</td>
						<td style="text-align:center;">Government · Assets</td>
						<td style="text-align:center;">Cash transfers · collective · future · S.14 adjustment</td>
						<td style="text-align:center;">Consumption categories (private + in kind)</td>
						<td style="text-align:right;">Sinks: age groups (consumers)</td>
					</tr>
				</tbody>
			</table>
			<div class="chart metodo-sankey metodo-sankey-alto" id="sankey-nta"></div>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota">Hover a link to read its value in % of GDP and in pesos, and a hub node (<code>Ing nacional</code>, <code>Gobierno</code>, <code>Activos</code>, <code>Transferencias en efectivo</code>) to see that its inflows equal its outflows. The data behind the chart is served verbatim from the engine's output, each link with its <code>value</code> in pesos and its <code>pctpib</code>; the page only picks the % of GDP as the drawn value (<a href="/jsonSankeyNTA.php?corte=v3-grupoedad">jsonSankeyNTA.php?corte=v3-grupoedad</a>); the same engine run also emits the previous version of this chart, with a per-group income and consumption node and a families hub (<code>corte=v2-grupoedad</code>), and the household Sankey by income decile, sex, age group, schooling and rural/urban/indigenous (<code>corte=decil|sexo|grupoedad|escol|rural</code>), which this page no longer draws.</p>
		</section>

		<h2>The account by age group</h2>
		<section class="metodo-texto">
			<p>What the main chart nets out is here, group by group: one mini-Sankey per age group with its inflows on the left (labor income; asset income with pension entitlements and taxes on products; public transfers in cash, in kind and collective; transfers received from other households, remittances included; transfers received within the household; dissaving) and its outflows on the right (private consumption; public consumption in kind and collective; taxes paid; transfers given to other households; transfers given within the household; saving). Within-household transfers are gross sums over persons (what the members who receive get, and what the members who give pay), so a group can appear on both sides; saving is the anchored one of the main chart, with the anchor declared (<code>Ancla S14 recorte</code> or <code>complemento</code>) so that each cell balances exactly by the lifecycle identity. Each flow carries both units (hover: % of GDP and pesos; the file brings both, divided in Stata). Below each chart: the group's lifecycle deficit, consumption minus labor income (<i>C − YL</i>), and its saving, in % of GDP and in pesos, read from the same file. Choose Total, Men or Women: the three variants travel in one file (<a href="/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo">jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo</a>) and the page redraws the five charts without reloading. Node labels are the engine's, in Spanish, as above.</p>
		</section>
		<div class="metodo-panel-wrap">
			<div class="metodo-panel-selector" role="radiogroup" aria-label="Sex">
				<span class="metodo-panel-selector-titulo">Sex</span>
				<label><input type="radio" name="nta-sexo" value="T" checked> Total</label>
				<label><input type="radio" name="nta-sexo" value="H"> Men</label>
				<label><input type="radio" name="nta-sexo" value="M"> Women</label>
			</div>
			<div class="metodo-panel" id="nta-panel">
<?php foreach (array(1, 2, 3, 4, 5) as $g): ?>
				<div class="metodo-panel-celda">
					<h3 class="metodo-panel-titulo"><span data-panel="grupo"></span></h3>
					<div class="metodo-panel-sankey" id="nta-panel-<?= $g ?>"></div>
					<p class="metodo-panel-pie">Lifecycle deficit (<i>C − YL</i>): <b><span data-panel-pct="deficit_cv"></span></b> % of GDP (<span data-panel="deficit_cv"></span> bn)<br>Saving (<i>S</i>): <b><span data-panel-pct="S"></span></b> % of GDP (<span data-panel="S"></span> bn)</p>
				</div>
<?php endforeach; ?>
			</div>
		</div>
<?php
metodo_pie(array(
	'sankeys' => array(
		array('renderAt' => 'sankey-nta', 'url' => '/jsonSankeyNTA.php?corte=v3-grupoedad'),
	),
	'cifras' => array('url' => '/jsonSankeyNTA.php?cuenta=grupoedad'),
	'panel' => array('url' => '/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo', 'contenedor' => 'nta-panel', 'selector' => 'nta-sexo'),
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
