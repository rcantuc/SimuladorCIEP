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
require_once dirname(__DIR__) . '/metodo/plantilla.php';

metodo_cabecera(array(
	'slug' => 'NTA',
	'titulo' => 'National Transfer Accounts Sankey: the whole economy, person to person',
	'lang' => 'en',
	'descripcion' => 'How the Simulador Fiscal CIEP draws the whole economy of one survey year as flows from persons by age, through the institutional sectors of the national accounts, back to persons by age, with net national disposable income as the single pivot.',
));
?>
		<section class="metodo-texto">
			<p>The chart is a Sankey of the National Transfer Accounts (<abbr title="National Transfer Accounts (Lee–Mason)">NTA</abbr>) for one survey year, built person by person from the <abbr title="Encuesta Nacional de Ingresos y Gastos de los Hogares (INEGI)">ENIGH</abbr> and closed on the institutional sectors of the national accounts: not only the household sector (S.14) but also corporations (S.11 + S.12), general government (S.13), non-profit institutions serving households (S.15, <abbr title="Instituciones sin fines de lucro que sirven a los hogares">ISFLSH</abbr>) and the rest of the world. The Simulador's Households module has first annualized every income and expenditure item, split household-level items among the members of each household<?= metodo_nota_ref(1) ?>, and benchmarked each income and consumption component to its own cell of the household sector (wages to D.1, mixed income to B.3n, imputed rent to B.2n, property income to net D.4, consumption to P.3). The NTA module then rearranges those person-level amounts into the lifecycle identity <i>C − YL = (τ⁺ − τ⁻) + (YA − S)</i> and, since v8.17.0, carries the account one step further: what the other sectors keep also belongs to persons. The retained net surplus of corporations enters asset income in proportion to a declared property proxy (<code>retenido_a_personas = on</code>, the same proxy that spreads net D.4 and the corporate income tax, red seal), what corporations pay or transfer on behalf of their owners (corporate income tax, the pension-entitlement adjustment, net transfers) is a retained tax, and so the corporate net saving reaches persons; the government's net dissaving is assigned to every person alike as a debt paid today (<code>deficit_a_personas = per_capita</code>; the alternative, in proportion to taxes paid, is measured and reported), and the net saving of the ISFLSH reaches persons per capita. With these settings the saving of persons sums to the net saving of the whole economy (B.8n of S.1): in the survey year the nation dissaves, and the chart says so with a financing source and a declared adjustment node, never by absorbing anything in silence.</p>
			<p>Reading left to right: the five age groups and the rest of the world feed the income types; labor income, asset income and imputed rent collapse into <code>Hogares</code> (the household sector's balance of primary incomes, with the return on pension entitlements D.442 as its own source), taxes on products go to <code>Gobierno ingreso primario</code> together with other production taxes and the property income the government receives (its interest payments on the public debt leave to <code>Por identificar</code>, because the sector tables do not say who receives them), and the retained surplus of corporations passes through <code>Sociedades</code>; every sector's primary balance, remittances and a declared vintage difference between the BIE series and the sector tables enter the single hub, <code>Ingreso nacional disponible</code>, which equals the SNA net national disposable income to the peso. From the hub the secondary distribution is drawn as a clearing house: what persons pay leaves by named nodes (personal income tax and other current taxes, social contributions to the social-security funds, to pension funds and insurers, to employers' schemes, net insurance premiums, donations to ISFLSH, miscellaneous transfers) towards the disposable income of the sector that receives it, and each sector's own primary balance net of what it pays to the others follows the same route; corporations pay their income tax to government, and government, corporations and ISFLSH pay persons cash benefits, private pensions and insurance claims and the pension-entitlement adjustment, which join <code>Hogares ingreso disponible</code>. Government buys in-kind consumption, which joins the education, health and other-spending categories next to private spending of the same kind, and collective consumption, which has no age and ends in its own node; ISFLSH do the same with their in-kind consumption; households finance the seven consumption categories and send the saving of the groups that save to <code>Futuro</code>, while the dissaving of the groups that dissave, of corporations and of government is financed by <code>Financiamiento deuda y venta de activos</code>. The seven categories are each drawn back to the group that consumed them, private and in kind together. Every number is a survey-weighted sum in current pesos, and the chart shows each flow as a share of the GDP of the same year (% of GDP, GDP = 100): the engine emits every link in both units and nothing is divided outside it. No per-capita values, no single-year age profiles. Age enters only through five groups (0–4, 5–17, 18–24, 25–64, 65 and over) and only at the two ends. Who saves and who dissaves, and how much of the corporate and public dissaving each group carries, is in the panel below; the household-side cut of earlier versions (the v3 chart) is drawn further down for comparison<?= metodo_nota_ref(2) ?>.</p>
			<p class="lead-nota">Node labels are the ones the engine emits, in Spanish. FusionCharts identifies a node by its label, so the engine disambiguates a name that must appear in two columns by prefixing a space (<code>De 0 a 4</code> on the left as earner vs. <code>&nbsp;De 0 a 4</code> on the right as consumer) and names each sector twice (<code>Hogares</code> before the hub, <code>Hogares ingreso disponible</code> after it). If you replicate the schema, keep node identifiers unique and the graph acyclic.</p>
<?php
metodo_notas(array(
	1 => '<b>Within-household allocation.</b> The ENIGH records most expenditure at the household level and only part of it by person, so building age profiles requires splitting household spending among its members. Dividing equally is a poor assumption: an infant and an adult do not consume the same amount of the same category. Instead, the data decide the split. Each household’s spending in a category is allocated to its members in proportion to the average spending of a person of the same age and sex in that category; since that average depends on the allocation and the allocation on the average, the two are solved jointly as a fixed point, starting from the equal split and iterating until less than one millionth of the category’s spending changes age-sex cell (profiles stable to six significant figures; each category takes the iterations it needs, typically 100–600). Every iteration preserves each household’s total exactly, so the national aggregate never moves; only its distribution within households does. Income is recorded by person in the ENIGH and needs no allocation. A caveat the reader should know: identifying children’s consumption from how household spending varies with household composition tends to attribute little to them (shared goods, economies of scale): at the fixed point a child aged 0–4 is assigned about 11 % of the food spending of an adult aged 30–64, against the 0.4 → 1 equivalence scale that NTA imposes a priori. The chart shows the data-driven allocation; a floor based on the NTA scale is an explicit option in the Simulador, not applied here.',
	2 => '<b>The hub is national disposable income.</b> Since v8.17.0 the pivot of the chart is the SNA net national disposable income of the survey year as the BIE publishes it (gross national disposable income less consumption of fixed capital): <span data-pib="v4_hub"></span> % of GDP, <span data-pib="v4_hub" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn, to the peso. It is the sum of the balance of primary incomes of every institutional sector read from INEGI’s sector tables — households <span data-pib="v4_hogares_B5n"></span> (the engine’s labor and asset incomes equal their cells, plus D.442), corporations <span data-pib="v4_sociedades_B5n"></span>, general government <span data-pib="v4_gobierno_B5n"></span> (taxes on products and other production taxes plus property income received, less the interest on the public debt), ISFLSH <span data-pib="v4_isflsh_B5n"></span> — plus net current transfers from abroad <span data-pib="v4_remesas"></span> (remittances, BIE) and a declared vintage difference between the BIE series and the sector tables of <span data-pib="v4_vintage_hub"></span> % of GDP on the way in and <span data-pib="v4_vintage_usos"></span> on the way out (<code>vintage_nodo = si</code>: it is a node, not a correction). The household-side hub of earlier versions (<code>Ing nacional</code> in the v3 chart below, <span data-pib="hub_Ing_nacional"></span> % of GDP) counted taxes on products and the pension-entitlement adjustment as household income and left the other sectors out; the whole-economy chart puts each item where the national accounts put it, so the two hubs differ by construction and the bridge between them is in CUAD-2. Three things the earlier charts could not say are now in the picture. First, the account of the household closes: with every transfer row anchored to its own cell by paying and receiving sector (personal income tax plus other current taxes to D.5, contributions to D.61 by receiving sector, cash benefits to D.62 + D.759, insurance claims to D.72, donations to ISFLSH, net premiums, remittances sent and miscellaneous transfers to the D.7 paid, transfers between households balanced so that they net to zero as in the SNA), the household residual before the saving anchor sums to <span data-nta="S_vs_B8n.S_sin_ajuste"></span> bn against B.8n of S.14 of <span data-nta="S_vs_B8n.AhorroHog"></span> bn: a gap of <span data-nta="S_vs_B8n.brecha_pct" data-nta-unidad="pct"></span> % against an expected <span data-nta="S_vs_B8n.brecha_esperada_pct" data-nta-unidad="pct"></span> % (the accrual-versus-cash difference of product taxes plus the vintage of remittances), so the adjustment node <code>Ajuste a cuentas nacionales S14</code> carries <span data-pib="v4_ajuste_S14" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn (<span data-pib="v4_ajuste_S14"></span> % of GDP) where v8.16.0 needed a sink of about one quarter of household saving. Second, the saving of persons is the saving of the nation: household saving <span data-nta="S_vs_B8n.S_final"></span> bn plus the retained corporate saving attributed by the property proxy <span data-nta="S_vs_B8n.S_ret"></span>, the public dissaving assigned per capita <span data-nta="S_vs_B8n.S_def"></span> and the ISFLSH saving <span data-nta="S_vs_B8n.S_isflsh"></span> give <span data-nta="S_vs_B8n.S_personas"></span> bn (<span data-pib="S_personas"></span> % of GDP), equal to B.8n of the total economy, <span data-nta="S_vs_B8n.B8nS1"></span> bn (the gate holds it to 1e-9; with the two attributions off the figure would be the household cell alone). Third, that dissaving is financed: the <code>Financiamiento</code> source carries <span data-pib="v4_financiamiento"></span> % of GDP (the dissaving of the age groups that dissave, of corporations and of government) against <span data-pib="v4_futuro"></span> % of GDP saved into <code>Futuro</code>; the rest of the world lends the economy <span data-pib="v4_mundo_B9" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn in the year (B.9 of S.2, <span data-pib="v4_mundo_B9"></span> % of GDP). What the sector tables do not say who receives — the interest on the public debt and a small residual of miscellaneous transfers — is drawn to <code>Por identificar</code> (<span data-pib="v4_por_identificar"></span> % of GDP, red seal), not absorbed. Every peso and % of GDP figure in this note is the engine’s.'
));
?>
		</section>

		<h2>Nodes and links</h2>
		<section class="metodo-texto">
			<p>Weighted sums use the ENIGH expansion factor (<code>factor</code>) over persons. Variable names are those of the Simulador's person-level NTA file (<code>users/&lt;id&gt;/NTA/nta-persona.dta</code>); cells are those of INEGI's institutional sector tables for the survey year (S.1, S.11, S.12, S.13, S.14, S.15, S.2: B.5n, B.6n, B.8n, B.9, D.5, D.61, D.62, D.63, D.7 and its components, D.8, P.3, P.32) read by <code>SCN.ado</code> from the frozen asset, and the BIE series for the hub, remittances and GDP. A node that would carry a zero flow is not emitted, so the number of nodes depends on the year and on the parameters of CUAD-2 (<code>hub</code>, <code>retenido_a_personas</code>, <code>deficit_a_personas</code>, <code>isflsh_regla</code>, <code>circuito_d442</code>, <code>vintage_nodo</code>, <code>financiamiento</code>, <code>inter_hogar</code>; the signed values are the defaults and any other value prints a FLAG in <code>nta-identidad.txt</code>). Every intermediate node conserves flow (inflows = outflows, hover it for the total in % of GDP); the identity node by node is cuadro 5 of <a href="/jsonSankeyNTA.php?cuenta=identidad">nta-identidad.txt</a>.</p>
			<p><b>Units.</b> The engine emits every link twice: in current pesos (<code>value</code>) and as a percentage of the GDP of the same year (<code>pctpib</code> = <code>value</code> / GDP × 100, divided in Stata). The chart is drawn and read in % of GDP (GDP = 100); hover a link for both units. The hub is the SNA net national disposable income (<span data-pib="v4_hub"></span> % of GDP); GDP net of depreciation (<span data-pib="CapFij"></span> % of GDP) and of the net primary income paid abroad (<span data-pib="ROWProp"></span> % of GDP) is national income, and national income plus net current transfers from abroad (<span data-pib="ROWTrans"></span> % of GDP) is the hub; note<?= metodo_nota_ref(2) ?> itemizes it by sector.</p>
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
						<td>→ <code>Ing laboral</code>: Σ <code>YL</code> (D.1 of S.14 plus the labor share of mixed income B.3n).<br>→ <code>Ing capital</code>: Σ (<code>YA_base</code> − <code>ALQ</code>): asset income net of depreciation without imputed rent (⅓ B.3n + net D.4 − D.442).<br>→ <code>Alquiler propio</code>: Σ <code>ALQ</code>, imputed rent of owner-occupied housing (B.2n), assigned to the household head.<br>→ <code>Impuestos a productos</code>: Σ <code>ImpProd</code>, taxes net of subsidies on products in proportion to private consumption (D.21 − D.31): income at market prices that the national accounts record in government.<br>→ <code>Sociedades</code>: Σ <code>YA_ret</code>, the retained net surplus of corporations attributed by the property proxy (B.5n of S.11 + S.12; <code>retenido_a_personas = on</code>, red seal).</td>
					</tr>
					<tr>
						<td><code>El mundo</code></td>
						<td>Rest of the world.</td>
						<td>→ <code>Remesas</code>: Σ <code>Remesas</code>, remittances received (anchor <code>ROWTrans</code>, net current transfers from abroad).</td>
					</tr>
					<tr>
						<td><code>Fondos de pensión D442</code></td>
						<td>Return on pension entitlements paid by pension funds to households (D.442 of S.14): part of the household sector's primary income that is not in the engine's asset income (the contributions D.614 it finances are netted out, <code>circuito_d442 = neto</code>).</td>
						<td>→ <code>Hogares</code>: the cell.</td>
					</tr>
					<tr>
						<td><code>Otros impuestos a la producción</code>, <code>Renta de la propiedad recibida por el gobierno</code></td>
						<td>What the government receives in its primary distribution besides taxes on products: other taxes less subsidies on production (D.29 − D.39) and property income received (D.4, including the oil rent D.45), net of the small rent it pays.</td>
						<td>→ <code>Gobierno ingreso primario</code>: the cells.</td>
					</tr>
					<tr>
						<td><code>ISFLSH</code></td>
						<td>Non-profit institutions serving households: their balance of primary incomes (B.5n of S.15; <code>isflsh_regla = sector</code>).</td>
						<td>→ <code>Ingreso nacional disponible</code>: the cell.</td>
					</tr>
					<tr>
						<td><code>Vintage BIE vs CSI</code></td>
						<td>The difference between the BIE net national income and the sum of the sectors' primary balances in the sector tables (two INEGI vintages of the same year), as a node (<code>vintage_nodo = si</code>).</td>
						<td>→ <code>Ingreso nacional disponible</code>: INBD − ROWTrans − B.5n of S.1.</td>
					</tr>
					<tr>
						<td><code>Financiamiento deuda y venta de activos</code></td>
						<td>What finances dissaving: the dissaving of the age groups whose household saving is negative, the net dissaving of corporations (B.8n of S.11 + S.12 &lt; 0) and of general government (B.8n of S.13 &lt; 0). One node (<code>financiamiento = un_nodo_4</code>); the counterpart in the financial account is the lending of the rest of the world and of the sectors that save.</td>
						<td>→ each consumption category: the dissaving of the groups that dissave, split by their baskets; → <code>Sociedades ingreso disponible</code> and → <code>Gobierno ingreso disponible</code>: −B.8n of each.</td>
					</tr>
					<tr>
						<th>2 · Income types</th>
						<td><code>Ing laboral</code>, <code>Ing capital</code>, <code>Alquiler propio</code>, <code>Impuestos a productos</code>, <code>Sociedades</code>, <code>Remesas</code></td>
						<td>Labor income; asset income; imputed rent; taxes on products; the retained surplus of corporations (a sector node: it enters from the age groups and conserves); remittances.</td>
						<td>→ <code>Hogares</code> (the first three), → <code>Gobierno ingreso primario</code> (taxes on products), → <code>Ingreso nacional disponible</code> (<code>Sociedades</code>, <code>Remesas</code>): the node's inflows.</td>
					</tr>
					<tr>
						<th rowspan="2">3 · Sectors, primary income</th>
						<td><code>Hogares</code></td>
						<td>Household sector before taxes and transfers: labor income + asset income + imputed rent + D.442 = B.5n of S.14 to the peso (gate).</td>
						<td>→ <code>Ingreso nacional disponible</code>: B.5n of S.14.</td>
					</tr>
					<tr>
						<td><code>Gobierno ingreso primario</code>, <code>Intereses de la deuda</code></td>
						<td>General government before taxes and transfers: taxes on products + other production taxes + property income received; it pays the interest on the public debt (D.41 of S.13), whose receivers the sector tables do not identify.</td>
						<td>→ <code>Ingreso nacional disponible</code>: B.5n of S.13.<br>→ <code>Intereses de la deuda</code> → <code>Por identificar</code>: D.41 paid.</td>
					</tr>
					<tr>
						<th>4 · Hub</th>
						<td><code>Ingreso nacional disponible</code></td>
						<td>Net national disposable income (BIE): the single pivot between the primary distribution and its uses. Σ B.5n of the sectors + remittances + vintage = the BIE figure to the peso (gate). Inflows = outflows by construction.</td>
						<td>→ <code>Hogares ingreso disponible</code>: B.5n of S.14 − taxes and contributions paid − transfers paid + remittances received (the household cell after the secondary distribution).<br>→ <code>ISR de personas</code> (D.5 of S.14), <code>Cuotas a la seguridad social</code> (D.61 received by S.13), <code>Cuotas a Afores y aseguradoras</code> (D.61 received by S.12 net of D.614), <code>Cuotas a planes de empleadores</code> (D.61 received by S.11), <code>Primas netas de seguros</code> (D.71 paid by S.14), <code>Donativos a ISFLSH</code> (D.751 paid by S.14), <code>Otras transferencias D759</code> (D.759 paid by S.14): what persons pay, by receiving sector, from the person-level account.<br>→ <code>Ingreso primario neto del gobierno</code>, <code>Sociedades saldo primario</code>, <code>ISFLSH saldo primario</code>: each sector's own primary balance net of what it pays to the other sectors (the residual that makes the sector conserve, with every other inflow and outflow a cell).<br>→ <code>Vintage BIE vs CSI usos</code>: INBD − Σ B.6n of the sectors − the residual sent to <code>Por identificar</code>.</td>
					</tr>
					<tr>
						<th rowspan="4">5 · Sectors, disposable income</th>
						<td><code>Hogares ingreso disponible</code></td>
						<td>Households after taxes and transfers: inflows from the hub plus <code>Transferencias en efectivo</code> (D.62 of S.13 + D.759 of S.14), <code>Prestaciones privadas</code> (D.62 paid by corporations + insurance claims D.72), <code>Derechos de pensión D8</code> (D.8 paid by S.12) and the small benefits ISFLSH pay = B.6n of S.14 + D.8 (gate).</td>
						<td>→ each category: Σ over groups of the group's private consumption less its dissaving, split by the group's basket (Σ = P.3 of S.14 − dissaving).<br>→ <code>Futuro</code>: Σ over the groups that save of their household saving before the anchor.<br>→ <code>Ajuste a cuentas nacionales S14</code>: B.8n of S.14 − Σ saving before the anchor (a sink if the national accounts save more than the survey; a source into this node if less).</td>
					</tr>
					<tr>
						<td><code>Gobierno ingreso disponible</code></td>
						<td>General government after taxes and transfers: inflows from the named tax nodes, from <code>ISR de sociedades</code> (D.5 of S.11 + S.12), from <code>Otras transferencias D759</code> (D.759 received) and from <code>Financiamiento</code> (−B.8n of S.13). Inflows − financing − transfers paid = B.6n of S.13 (gate).</td>
						<td>→ <code>Transferencias en efectivo</code> → <code>Hogares ingreso disponible</code>: cash benefits and other current transfers to households (D.62 of S.13 + D.759 received by S.14), what <code>TpubEf</code> anchors to.<br>→ <code>Educación</code>, <code>Salud</code>, <code>Otros gastos</code>: social transfers in kind D.63 of S.13 (education by enrolment, health ∝ private health spending, the rest per capita).<br>→ <code>Colectivo</code>: collective consumption P.32 of S.13 (per capita in the person-level account).<br>→ <code>ISFLSH ingreso disponible</code>: D.751 paid by government.</td>
					</tr>
					<tr>
						<td><code>Sociedades ingreso disponible</code></td>
						<td>Corporations (S.11 + S.12) after taxes and transfers: inflows from contributions, premiums, their own primary balance and <code>Financiamiento</code> (−B.8n of S.11 + S.12: the non-financial corporations' dissaving exceeds the financial corporations' saving). Inflows − financing − transfers paid = B.6n of S.11 + S.12 (gate).</td>
						<td>→ <code>ISR de sociedades</code> → <code>Gobierno ingreso disponible</code>: D.5 of S.11 + S.12.<br>→ <code>Prestaciones privadas</code> → <code>Hogares ingreso disponible</code>: D.62 paid by S.11 + S.12 and insurance claims D.72 received by households.<br>→ <code>Derechos de pensión D8</code> → <code>Hogares ingreso disponible</code>: D.8 paid by S.12.<br>→ <code>Otras transferencias D759</code>: D.759 paid by S.11 + S.12 (received by government; the residual to <code>Por identificar</code>).<br>→ <code>ISFLSH ingreso disponible</code>: D.751 paid by corporations.</td>
					</tr>
					<tr>
						<td><code>ISFLSH ingreso disponible</code></td>
						<td>Non-profit institutions after transfers: donations from households, corporations and government plus their own balance (B.5n + contributions received − what they pay) = B.6n of S.15 (gate).</td>
						<td>→ <code>Hogares ingreso disponible</code>: D.62 paid by S.15.<br>→ <code>Otros gastos</code>: their in-kind consumption D.63 of S.15.<br>→ <code>Futuro</code>: B.8n of S.15.</td>
					</tr>
					<tr>
						<th>6 · Uses</th>
						<td><code>Alimentos</code>, <code>Vestido</code>, <code>Salud</code>, <code>Educación</code>, <code>Vivienda</code>, <code>Transporte</code>, <code>Otros gastos</code></td>
						<td>Consumption categories at purchasers' prices, whoever paid for them. Private: Alimentos = Agua + Alim + BebN; Vestido = Vest + Calz; Salud = SaluT; Educación = EducT + RecrT; Vivienda = Alqu + HogaT + ComuT + Elec; Transporte = Vehi + STra + FTra; Otros gastos = Taba + BebA + DiveT + RestT, each including the person's share of net purchases of residents abroad; Σ private consumption = P.3 of S.14 (gate). In kind (D.63 of S.13 and of S.15, by age). Inflows (households + financing + in kind) = outflows by the identity.</td>
						<td>→ <code>&nbsp;&lt;age group&gt;</code>: Σ of the category, private plus in kind, over the persons of that group.</td>
					</tr>
					<tr>
						<th>7 · Sinks</th>
						<td><code>&nbsp;De 0 a 4</code> … <code>&nbsp;De 65 y más</code>; <code>Futuro</code>; <code>Colectivo</code>; <code>Por identificar</code>; <code>Ajuste a cuentas nacionales S14</code>; <code>Vintage BIE vs CSI usos</code></td>
						<td>The same five age groups as consumers (private + in-kind consumption); the future (saving of the groups that save, of corporations if positive and of the ISFLSH); collective consumption, with no age; what the sector tables leave unidentified (interest on the public debt, residual D.759: red seal); the declared adjustment of household saving to the national accounts; the vintage difference after the hub.</td>
						<td>None (terminal nodes).</td>
					</tr>
				</tbody>
			</table>
		</div>

		<h2>Anchoring and residual</h2>
		<section class="metodo-texto">
			<p>The figures below are read from the engine's account file for this chart (<a href="/jsonSankeyNTA.php?cuenta=grupoedad">jsonSankeyNTA.php?cuenta=grupoedad</a>), in thousands of millions of current pesos (bn) unless stated, and, in % of GDP, from the national block of the panel file (<a href="/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo">jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo</a>, <code>nacional_pctpib</code>, divided in Stata with the same GDP as the chart); the full report, with the identity by age group and by five-year group and sex, the decomposition of the saving gap and the identity node by node of this chart, is <a href="/jsonSankeyNTA.php?cuenta=identidad">nta-identidad.txt</a>.</p>
			<ul class="metodo-cifras">
				<li><b>The hub.</b> Net national disposable income (BIE) is <span data-pib="v4_hub" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn, <span data-pib="v4_hub"></span> % of GDP: households <span data-pib="v4_hogares_B5n"></span>, corporations <span data-pib="v4_sociedades_B5n"></span>, government <span data-pib="v4_gobierno_B5n"></span>, ISFLSH <span data-pib="v4_isflsh_B5n"></span>, remittances <span data-pib="v4_remesas"></span> and vintage <span data-pib="v4_vintage_hub"></span> % of GDP (the household-side hub of the v3 chart reads <span data-pib="hub_Ing_nacional"></span>).</li>
				<li><b>Saving of the household before the anchor.</b> The household residual sums to <span data-nta="S_vs_B8n.S_sin_ajuste"></span> bn (<span data-pib="S_sin_ajuste"></span> % of GDP) against net saving of the household sector (B.8n of S.14) of <span data-nta="S_vs_B8n.AhorroHog"></span> bn (<span data-pib="AhorroHog"></span> % of GDP): a gap of <span data-nta="S_vs_B8n.brecha_pct" data-nta-unidad="pct"></span> %, expected <span data-nta="S_vs_B8n.brecha_esperada_pct" data-nta-unidad="pct"></span> % once every transfer row is anchored by sector (CUAD-2), within the <span data-nta="S_vs_B8n.brecha_max_pct" data-nta-unidad="texto"></span> % tolerance, so the anchor mode resolves to <code><span data-nta="S_vs_B8n.modo" data-nta-unidad="texto"></span></code> (parameter <code><span data-nta="S_vs_B8n.modo_param" data-nta-unidad="texto"></span></code>) with factor <span data-nta="S_vs_B8n.factor_implicito" data-nta-unidad="factor"></span>; the chart carries the difference as the node <code>Ajuste a cuentas nacionales S14</code>, <span data-pib="v4_ajuste_S14" data-pib-bloque="v3_mxn" data-pib-unidad="bn"></span> bn (<span data-pib="v4_ajuste_S14"></span> % of GDP).</li>
				<li><b>Saving of persons = saving of the nation.</b> Household saving with the anchor is <span data-nta="S_vs_B8n.S_final"></span> bn; the retained corporate saving attributed by the property proxy adds <span data-nta="S_vs_B8n.S_ret"></span> bn (B.8n of S.11 + S.12: <span data-nta="S_vs_B8n.B8nS11S12"></span>), the public dissaving assigned per capita <span data-nta="S_vs_B8n.S_def"></span> bn (B.8n of S.13: <span data-nta="S_vs_B8n.B8nS13"></span>) and the ISFLSH saving per capita <span data-nta="S_vs_B8n.S_isflsh"></span> bn (B.8n of S.15: <span data-nta="S_vs_B8n.B8nS15"></span>); the saving of persons is <span data-nta="S_vs_B8n.S_personas"></span> bn (<span data-pib="S_personas"></span> % of GDP) against B.8n of the total economy of <span data-nta="S_vs_B8n.B8nS1"></span> bn (gate 1e-9). <code>Financiamiento</code> carries <span data-pib="v4_financiamiento"></span> % of GDP, <code>Futuro</code> <span data-pib="v4_futuro"></span>; the rest of the world lends <span data-pib="v4_mundo_B9"></span> % of GDP (B.9 of S.2).</li>
				<li><b>Asset income.</b> The engine's household asset income, <span data-nta="ya_s14.YA_motor"></span> bn (<span data-pib="YA_motor"></span> % of GDP), equals <span data-nta="ya_s14.YAHogS14_ancla"></span> bn (B.2n <span data-nta="ya_s14.B2n"></span> + ⅓ B.3n <span data-nta="ya_s14.tercio_B3n"></span> + net D.4 <span data-nta="ya_s14.D4_neto"></span> − D.442 <span data-nta="ya_s14.D442"></span>) with factor <span data-nta="ya_s14.factor" data-nta-unidad="factor"></span> (enforced to 1 since v8.15.0); the retained surplus of corporations attributed to persons adds <span data-pib="YA_ret"></span> % of GDP (B.5n of S.11 + S.12, red seal: the property proxy covers under 1 % of net D.4 in the survey).</li>
				<li><b>Under-reporting and top incomes (CUAD-3).</b> Since v8.17.2 the gap between the ENIGH and the S.14 cell of compensation of employees (D.1) and of mixed income (B.3n plus D.422, withdrawals from the income of quasi-corporations) is allocated within each cell in proportion to Y<sup>ε</sup>, so that higher incomes absorb a larger share of the under-reporting (del Castillo Negrete, CEPAL, <i>La distribución del ingreso y la riqueza</i>, Documentos de Proyectos LC/TS, cap. III §3; the method and its calibration against the ISR of natural persons by declared-income bracket are in <code>02_governance/CUAD-3.md</code>). The elasticity in force is <code>altimir_elasticidad = <span data-nta="parametros.altimir_elasticidad" data-nta-unidad="texto"></span></code> (1 would be the uniform Altimir factor of earlier versions); effective rents of dwellings are anchored to B.2n (<code>rentas_celda = <span data-nta="parametros.rentas_celda" data-nta-unidad="texto"></span></code>) and the business cell is <code>ing_mixto_ancla = <span data-nta="parametros.ing_mixto_ancla" data-nta-unidad="texto"></span></code>. Property income (D.4) keeps the property proxy of CUAD-0 and carries no elasticity.</li>
				<li><b>Cash and family transfers.</b> Government and the other sectors pay persons <span data-nta="grupos.0.TpubEf"></span> bn (<span data-pib="TpubEf"></span> % of GDP) in cash benefits (D.62 + D.759 of S.14) out of <span data-nta="grupos.0.Tmen_hh"></span> bn (<span data-pib="Tmen_hh"></span> % of GDP) of taxes and contributions households pay; households receive <span data-nta="grupos.0.OtrosRec"></span> bn in insurance claims (D.72) and pay <span data-nta="grupos.0.OtrosOtor"></span> bn to other sectors (D.7 paid: donations to ISFLSH, net premiums, remittances sent, miscellaneous transfers); they give <span data-nta="grupos.0.InterOtor"></span> bn to other households and record <span data-nta="grupos.0.InterRec"></span> bn received (the two balance by construction, <code>inter_hogar = balance</code>: factor <span data-nta="sectores.factor_inter_hogar" data-nta-unidad="factor"></span> on what is given, red seal), plus <span data-nta="grupos.0.Remesas"></span> bn (<span data-pib="Remesas"></span> % of GDP) of remittances. Who receives and who pays, by age group and by sex, is the panel below.</li>
				<li><b>The only residual is within the household.</b> By age group, the net within-household transfer is <span data-nta="grupos.1.Intra"></span> (0–4), <span data-nta="grupos.2.Intra"></span> (5–17), <span data-nta="grupos.3.Intra"></span> (18–24), <span data-nta="grupos.4.Intra"></span> (25–64) and <span data-nta="grupos.5.Intra"></span> bn (65 and over); it sums to <span data-nta="gates.intra_nacional" data-nta-unidad="mxn"></span> pesos nationally and the largest household total is <span data-nta="gates.intra_hogar_max" data-nta-unidad="mxn"></span> pesos. The identity without the anchor closes to <span data-nta="gates.residual_max_persona" data-nta-unidad="mxn"></span> pesos per person at most; with the anchor, its residual is exactly the adjustment above.</li>
				<li><b>Consumption.</b> Σ private consumption is <span data-nta="grupos.0.Cpriv"></span> bn (<span data-pib="Cpriv"></span> % of GDP) = P.3 of S.14, <span data-nta="anclas.ConHogS14_P3"></span> bn (<span data-pib="ConHogS14_P3"></span> % of GDP); public consumption is <span data-nta="grupos.0.Cpub"></span> bn (<span data-pib="Cpub"></span> % of GDP), of which <span data-nta="congob.individual_D63"></span> bn (<span data-pib="individual_D63"></span> % of GDP) in kind (D.63 received by households, from government and from ISFLSH, inside the health, education and other-spending categories) and <span data-nta="congob.colectivo_per_capita"></span> bn (<span data-pib="colectivo"></span> % of GDP) collective (P.32 of S.13, in its own node).</li>
				<li><b>The hubs, in % of GDP.</b> Whole economy: <code>Ingreso nacional disponible</code> <span data-pib="v4_hub"></span>; <code>Colectivo</code> <span data-pib="v4_colectivo"></span>; <code>Futuro</code> <span data-pib="v4_futuro"></span>; <code>Financiamiento</code> <span data-pib="v4_financiamiento"></span>; <code>Por identificar</code> <span data-pib="v4_por_identificar"></span>. Household-side cut (v3): <code>Ing nacional</code> <span data-pib="hub_Ing_nacional"></span>; <code>Gobierno</code> <span data-pib="hub_Gobierno"></span>; <code>Activos</code> <span data-pib="hub_Activos"></span>; <code>Transferencias en efectivo</code> <span data-pib="hub_Transferencias_efectivo"></span>; <code>Futuro</code> <span data-pib="Futuro"></span>; <code>Desahorro</code> <span data-pib="Desahorro"></span> % of GDP (GDP = <span data-pib="valor" data-pib-bloque="pib" data-pib-unidad="bn"></span> bn in <span data-pib="anio" data-pib-bloque="pib" data-pib-unidad="texto"></span>).</li>
				<li><b>Provenance.</b> <span data-nta="procedencia.modulo" data-nta-unidad="texto"></span>, generated <span data-nta="procedencia.generado_el" data-nta-unidad="texto"></span>; parameters <code><span data-nta="parametros.hub" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.retenido_a_personas" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.deficit_a_personas" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.isflsh_regla" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.circuito_d442" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.vintage_nodo" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.financiamiento" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.inter_hogar" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_YA" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_cuotas" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_d8" data-nta-unidad="texto"></span></code>, <code><span data-nta="parametros.nta_alqu" data-nta-unidad="texto"></span></code> (see the header of <code>01_modulos/NTA.do</code>); Households parameters (CUAD-0, CUAD-1 and CUAD-2, signed addenda): <code><span data-nta="parametros.households" data-nta-unidad="texto"></span></code>.</li>
			</ul>
		</section>

		<h2>The chart, as the engine emits it</h2>
		<section class="metodo-texto">
			<p class="lead-nota metodo-unidad">Unit: % of <span data-pib="anio" data-pib-bloque="pib" data-pib-unidad="texto"></span> GDP; GDP = 100. Hover a link for both units (% of GDP and current pesos). The chart is wide: scroll it sideways.</p>
		</section>
		<div class="metodo-sankey-wrap metodo-sankey-scroll">
			<table class="metodo-titulos metodo-titulos-economia">
				<tbody>
					<tr>
						<td style="text-align:left;">Sources: age groups (earners) · rest of the world · pension funds · government receipts · ISFLSH · vintage · financing</td>
						<td style="text-align:center;">Income types · sectors before taxes and transfers</td>
						<td style="text-align:center;">Hub: net national disposable income (% of GDP)</td>
						<td style="text-align:center;">Secondary distribution: taxes, contributions, premiums, donations</td>
						<td style="text-align:center;">Sectors after taxes and transfers · benefits · pension entitlements</td>
						<td style="text-align:center;">Consumption categories (private + in kind) · collective · future · unidentified</td>
						<td style="text-align:right;">Sinks: age groups (consumers)</td>
					</tr>
				</tbody>
			</table>
			<div class="chart metodo-sankey metodo-sankey-economia" id="sankey-nta"></div>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota">Hover a link to read its value in % of GDP and in pesos, and a sector node (<code>Ingreso nacional disponible</code>, <code>Hogares</code>, <code>Gobierno ingreso primario</code>, <code>Sociedades</code>, the four <code>… ingreso disponible</code>) to see that its inflows equal its outflows. The data behind the chart is served verbatim from the engine's output, each link with its <code>value</code> in pesos and its <code>pctpib</code>; the page only picks the % of GDP as the drawn value (<a href="/jsonSankeyNTA.php?corte=v4-economia">jsonSankeyNTA.php?corte=v4-economia</a>). The same engine run also emits the household-side cut below (<code>corte=v3-grupoedad</code>), the previous version with per-group income and consumption nodes (<code>corte=v2-grupoedad</code>) and the household Sankey by income decile, sex, age group, schooling and rural/urban/indigenous (<code>corte=decil|sexo|grupoedad|escol|rural</code>), which this page does not draw.</p>
		</section>

		<h3>The household-side cut (v3)</h3>
		<section class="metodo-texto">
			<p class="lead-nota">The chart of v8.13.0–v8.16.0, for comparison: ages at both ends, the household-side income hub <code>Ing nacional</code> (primary income of households at market prices plus remittances, taxes on products and the pension-entitlement adjustment), government and assets as reallocation hubs, cash transfers as a single node. Same engine run, same person-level account; the corporate and public saving attributed to persons is not in this cut (it is the household saving that the saving anchor relates to B.8n of S.14). Unit: % of GDP.</p>
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
			<div class="chart metodo-sankey metodo-sankey-alto" id="sankey-nta-v3"></div>
		</div>

		<h2>The account by age group</h2>
		<section class="metodo-texto">
			<p>What the main chart nets out is here, group by group: one mini-Sankey per age group with its inflows on the left (labor income; asset income with pension entitlements, the retained corporate surplus and taxes on products; public transfers in cash, in kind and collective; the ISFLSH saving attributed; transfers received from other households, remittances included; insurance claims; transfers received within the household; dissaving) and its outflows on the right (private consumption; public consumption in kind and collective; taxes paid, including the retained corporate tax and the public debt assigned; transfers given to other households; transfers paid to other sectors; transfers given within the household; saving). Within-household transfers are gross sums over persons (what the members who receive get, and what the members who give pay), so a group can appear on both sides; saving is the saving of persons of the main account (household saving with the anchor plus the corporate, public and ISFLSH saving attributed), with the anchor declared (<code>Ancla S14 recorte</code> or <code>complemento</code>) so that each cell balances exactly by the lifecycle identity. Each flow carries both units (hover: % of GDP and pesos; the file brings both, divided in Stata). Below each chart: the group's lifecycle deficit, consumption minus labor income (<i>C − YL</i>), and its saving, in % of GDP and in pesos, read from the same file. Choose Total, Men or Women: the three variants travel in one file (<a href="/jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo">jsonSankeyNTA.php?cuenta=panel-grupoedad-sexo</a>) and the page redraws the five charts without reloading. Node labels are the engine's, in Spanish, as above.</p>
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
			$fecha = ' Data updated ' . $dm[1] . '-' . $dm[2] . '-' . $dm[3] . '.';
		}
		return '<b>Source</b>: CIEP, <a href="/">Simulador Fiscal CIEP</a>' . $version . ', National Transfer Accounts by individual (<code>NTA.do</code>) with INEGI\'s ' . $enigh . ' benchmarked to the institutional sectors of the ' . $sna . 'System of National Accounts (INEGI, BIE and institutional sector accounts).' . $fecha;
	},
));
?>
