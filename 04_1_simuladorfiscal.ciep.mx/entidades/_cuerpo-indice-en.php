<?php
// entidades/_cuerpo-indice-en.php — cuerpo del índice de /entidades en inglés (el idioma original de la página). Lo incluye entidades/index.php según metodo_lang(); su hermano
// entidades/_cuerpo-indice-es.php es la traducción al español y debe llevar exactamente los mismos ids, data-* y endpoints. Usa las variables del
// archivo que lo incluye ($catalogo). Sin números: todo valor llega en runtime (test-sitio-entidades.sh lo exige).
?>
		<section class="metodo-texto">
			<p>One page per state, all built the same way: the national engine run cut by the residence of the ENIGH households, with the federal parameters and national-accounts anchors shared by the 32 (see the method paragraph of any state page). Each page shows four products: the five contribution Sankeys with a selector of cut, the net contribution over the lifecycle by sex and five-year age group, the effective tax rates by tax (ISAN and import taxes omitted: national rate by construction) and the net lifecycle contribution as a share of the state's GDP (PIBE). The table below says how thin each state's sample is: <i>n</i> is the number of ENIGH persons living in the state; «cells below the seal threshold» counts the cells of the three products with fewer than <span data-ind="parametros.sello_n" data-ind-unidad="entero"></span> persons; «sealed cells» also counts the cells where one person puts more than <span data-ind="parametros.sello_top1" data-ind-unidad="entero"></span> % of the amount (Sankey links / lifecycle cells / taxes, out of their totals); «top-1 concentration» is the largest share of one person in a cell that is <i>not</i> thin (n at or above the threshold), with the cell. Read the sealed cells as indicative. Figures from the run of ENIGH <span data-ind="nacional.anio_enigh" data-ind-unidad="texto"></span> for <span data-ind="nacional.paquete" data-ind-unidad="texto"></span> (values of <span data-ind="nacional.anio_vp" data-ind-unidad="texto"></span>); national sample <span data-ind="nacional.n" data-ind-unidad="entero"></span> persons, national net contribution <span data-ind="nacional.neto_pct_pib" data-ind-unidad="pct3"></span> % of GDP<?= metodo_nota_ref(1) ?>.</p>
		</section>
		<div class="table-responsive">
			<table class="table table-sm metodo-tabla ent-indice" id="ent-indice">
				<thead>
					<tr>
						<th>#</th>
						<th>State</th>
						<th>Abbr.</th>
						<th class="num">ENIGH sample (n)</th>
						<th class="num">Cells below the seal threshold</th>
						<th>Sealed cells (Sankeys / lifecycle / rates)</th>
						<th>Top-1 concentration (cells with n ≥ threshold)</th>
						<th class="num">Net contribution / PIBE (%)</th>
						<th>Page</th>
					</tr>
				</thead>
				<tbody>
<?php foreach ($catalogo as $abrev => $e): ?>
					<tr data-abrev="<?= htmlspecialchars($abrev) ?>">
						<td><?= htmlspecialchars($e['pos']) ?></td>
						<td><a href="<?= htmlspecialchars(metodo_url('/entidades/' . $abrev . '/', 'entidades')) ?>"><?= htmlspecialchars($e['nombre']) ?></a></td>
						<td><?= htmlspecialchars($abrev) ?></td>
						<td class="num" data-col="n" data-col-unidad="entero"></td>
						<td class="num" data-col="celdas_n_menor.total" data-col-unidad="entero"></td>
						<td data-col="sellos_texto" data-col-unidad="texto"></td>
						<td data-col="top1" data-col-unidad="top1"></td>
						<td class="num" data-col="neto_pct_pibe" data-col-unidad="pct3"></td>
						<td><a href="<?= htmlspecialchars(metodo_url('/entidades/' . $abrev . '/', 'entidades')) ?>">open</a></td>
					</tr>
<?php endforeach; ?>
				</tbody>
			</table>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota" id="ent-indice-estado">The figures of this table are read from <a href="/jsonEntidad.php?producto=indice">jsonEntidad.php?producto=indice</a> (generated <span data-ind="procedencia.generado_el" data-ind-unidad="texto"></span> by <span data-ind="procedencia.generador" data-ind-unidad="texto"></span>); the pages read their own files under <code>users/&lt;id&gt;/&lt;ABREV&gt;/</code>.</p>
		</section>

		<h2>Notes</h2>
<?php
metodo_notas(array(
	1 => '<b>Σ32 PIBE vs national GDP.</b> The state ratios divide each state\'s net contribution by its own PIBE; the sum of the 32 PIBE of the value-present year (<span data-ind="pibe_32.suma_pesos" data-ind-unidad="bn"></span> bn MXN) differs from the national GDP of the run (<span data-ind="pibe_32.pib_nacional_pesos" data-ind-unidad="bn"></span> bn) by <span data-ind="pibe_32.discrepancia_pct" data-ind-unidad="signo-pct2"></span> %, so the state ratios are not exact shares of the national ratio. Informative, not gated (contrato-32 §4b).',
));
?>
