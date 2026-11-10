<?php
// entidades/_cuerpo-indice-es.php — cuerpo del índice de /entidades en español: traducción de su hermano entidades/_cuerpo-indice-en.php
// (el idioma original de la página). Lo incluye entidades/index.php según metodo_lang(); debe llevar exactamente los mismos ids, data-* y endpoints
// que el archivo en inglés. Usa las variables del archivo que lo incluye ($catalogo). Sin números: todo valor llega en runtime
// (test-sitio-entidades.sh lo exige).
?>
		<section class="metodo-texto">
			<p>Una página por entidad, todas construidas de la misma manera: la corrida nacional del motor con corte por la residencia de los hogares de la ENIGH, con los parámetros federales y los anclajes de cuentas nacionales comunes a las 32 (véase el párrafo de método de cualquier página estatal). Cada página muestra cuatro productos: los cinco Sankeys de aportación con un selector de corte, la aportación neta a lo largo del ciclo de vida por sexo y quinquenio de edad, las tasas efectivas por impuesto (se omiten el ISAN y los impuestos a la importación: tasa nacional por construcción) y la aportación neta de ciclo de vida como proporción del PIB de la entidad (PIBE). La tabla de abajo indica qué tan escasa es la muestra de cada entidad: <i>n</i> es el número de personas de la ENIGH que residen en la entidad; «celdas bajo el umbral del sello» cuenta las celdas de los tres productos con menos de <span data-ind="parametros.sello_n" data-ind-unidad="entero"></span> personas; «celdas selladas» cuenta además las celdas donde una persona aporta más de <span data-ind="parametros.sello_top1" data-ind-unidad="entero"></span> % del monto (enlaces del Sankey / celdas del ciclo de vida / impuestos, sobre sus totales); «concentración top-1» es la mayor proporción de una sola persona en una celda que <i>no</i> es escasa (n igual o mayor al umbral), junto con la celda. Léanse las celdas selladas como indicativas. Cifras de la corrida con la ENIGH <span data-ind="nacional.anio_enigh" data-ind-unidad="texto"></span> para <span data-ind="nacional.paquete" data-ind-unidad="texto"></span> (valores de <span data-ind="nacional.anio_vp" data-ind-unidad="texto"></span>); muestra nacional de <span data-ind="nacional.n" data-ind-unidad="entero"></span> personas, aportación neta nacional de <span data-ind="nacional.neto_pct_pib" data-ind-unidad="pct3"></span> % del PIB<?= metodo_nota_ref(1) ?>.</p>
		</section>
		<div class="table-responsive">
			<table class="table table-sm metodo-tabla ent-indice" id="ent-indice">
				<thead>
					<tr>
						<th>#</th>
						<th>Entidad</th>
						<th>Abrev.</th>
						<th class="num">Muestra ENIGH (n)</th>
						<th class="num">Celdas bajo el umbral del sello</th>
						<th>Celdas selladas (Sankeys / ciclo de vida / tasas)</th>
						<th>Concentración top-1 (celdas con n ≥ umbral)</th>
						<th class="num">Aportación neta / PIBE (%)</th>
						<th>Página</th>
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
						<td><a href="<?= htmlspecialchars(metodo_url('/entidades/' . $abrev . '/', 'entidades')) ?>">abrir</a></td>
					</tr>
<?php endforeach; ?>
				</tbody>
			</table>
		</div>
		<section class="metodo-texto">
			<p class="lead-nota" id="ent-indice-estado">Las cifras de esta tabla se leen de <a href="/jsonEntidad.php?producto=indice">jsonEntidad.php?producto=indice</a> (generado el <span data-ind="procedencia.generado_el" data-ind-unidad="texto"></span> por <span data-ind="procedencia.generador" data-ind-unidad="texto"></span>); las páginas leen sus propios archivos en <code>users/&lt;id&gt;/&lt;ABREV&gt;/</code>.</p>
		</section>

		<h2>Notas</h2>
<?php
metodo_notas(array(
	1 => '<b>Σ32 PIBE frente al PIB nacional.</b> Los cocientes estatales dividen la aportación neta de cada entidad entre su propio PIBE; la suma de los 32 PIBE del año de valor presente (<span data-ind="pibe_32.suma_pesos" data-ind-unidad="bn"></span> mm de pesos) difiere del PIB nacional de la corrida (<span data-ind="pibe_32.pib_nacional_pesos" data-ind-unidad="bn"></span> mm) en <span data-ind="pibe_32.discrepancia_pct" data-ind-unidad="signo-pct2"></span> %, por lo que los cocientes estatales no son proporciones exactas del cociente nacional. Informativa, no es un candado (contrato-32 §4b).',
));
?>
