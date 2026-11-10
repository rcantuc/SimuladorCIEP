<?php
// entidades/_cuerpo-entidad-es.php — cuerpo de cada página estatal de /entidades en español: traducción de su hermano entidades/_cuerpo-entidad-en.php
// (el idioma original de la página). Lo incluye entidades/_entidad.php según metodo_lang(); debe llevar exactamente los mismos ids, data-* y endpoints
// que el archivo en inglés. Usa las variables del archivo que lo incluye ($h, $nombre, $abrev, $ent, $cortes). Sin números: todo valor llega en runtime
// (test-sitio-entidades.sh lo exige).
?>
		<section class="metodo-texto ent-cabecera" id="ent-cabecera">
			<p class="ent-datos">
				<span><b>Entidad</b> <?= $h($nombre) ?> (<?= $h($abrev) ?>)</span>
				<span><b>Clave INEGI</b> <?= $h($ent['clave']) ?></span>
				<span><b>Muestra ENIGH</b> <span data-ent="muestra.n" data-ent-unidad="entero"></span> personas, que con la expansión representan <span data-ent="muestra.pob" data-ent-unidad="entero"></span> residentes (ENIGH <span data-ent="muestra.anio_enigh" data-ent-unidad="texto"></span>)</span>
				<span><b>Proporción de la población nacional</b> <span data-ent="nacional.share_pob" data-ent-unidad="share"></span> %</span>
				<span><b>Año de política</b> <span data-ent="muestra.paquete" data-ent-unidad="texto"></span>, valores de <span data-ent="muestra.anio_vp" data-ent-unidad="texto"></span></span>
				<span><b>Corrida del motor</b> <span data-ent="procedencia.modulos.ciclo" data-ent-unidad="texto"></span>, <span data-ent="procedencia.generado_el" data-ent-unidad="texto"></span></span>
			</p>
<?php if ($abrev === 'NL'): ?>
			<p class="ent-espejo lead-nota" id="ent-espejo">Nuevo León cuenta además con un espejo propio (SimuladorCoNL), mantenido con Consejo Nuevo León; disponible a solicitud.</p>
<?php endif; ?>
		</section>

		<section class="metodo-texto">
			<p>Cada gráfica de esta página es la <b>corrida nacional del motor con corte por residencia</b>, no un modelo estatal aparte. <b>Lo propio de la entidad</b>: la proyección de población (CONAPO por entidad, §1 del motor), el PIB estatal y su deflactor (la base del PIBE del INEGI para la entidad, §2–3; vintage de la base: <span data-ent="pibe.vintage" data-ent-unidad="texto"></span><?= metodo_nota_ref(2) ?>) y todo lo que se construye con las personas de la ENIGH que residen en la entidad (los dos primeros dígitos del identificador de la vivienda): los cinco Sankeys de aportación y el perfil de ciclo de vida por sexo y edad (§7–8.2), y las tasas efectivas, cuyo numerador y denominador son ambos sumas micro de los residentes de la entidad. <b>Lo federal, común a las 32</b>: los parámetros fiscales del año de política (LIF, PEF, CGPE), los deciles nacionales de ingreso que clasifican a los hogares y los anclajes de cuentas nacionales: cada componente de los hogares se ancla al Sistema de Cuentas Nacionales <i>antes</i> del corte, porque la fracción del SCN no tiene desagregación estatal declarada<?= metodo_nota_ref(3) ?>; nada se recalibra por entidad, de modo que los montos de las 32 entidades suman las cifras nacionales por construcción (montos, no tasas). El ISAN y los impuestos a la importación se imputan con el mismo relativo en numerador y denominador, así que su tasa efectiva es la nacional por construcción y la gráfica de tasas los omite<?= metodo_nota_ref(4) ?>. <b>Qué se ancla a qué</b>: el producto «% del PIB estatal» divide la aportación neta de ciclo de vida de la entidad (motor, pesos del año de valor presente) entre el PIBE de la entidad de ese año (BIE, vintage indicado arriba); la referencia nacional usa el PIB nacional de la misma corrida. Las celdas con muestra escasa (menos de <span data-ent="parametros.sello_n" data-ent-unidad="entero"></span> personas) o dominadas por una persona (más de <span data-ent="parametros.sello_top1" data-ent-unidad="entero"></span> % de la celda) llevan un sello ⚠ en la gráfica y una nota numerada con su n<?= metodo_nota_ref(1) ?>: léanse como indicativas.</p>
		</section>

		<h2>1 · De dónde vienen los impuestos de la entidad y a dónde va el gasto federal</h2>
		<section class="metodo-texto">
			<p>Los hogares de <?= $h($nombre) ?> pagan <span data-ent="ciclo.aporta_pesos" data-ent-unidad="bn"></span> mm de pesos en impuestos y contribuciones y reciben <span data-ent="ciclo.recibe_pesos" data-ent-unidad="bn"></span> mm en pensiones, ingreso básico, educación, salud e inversión: una aportación neta de <span data-ent="ciclo.neto_pesos" data-ent-unidad="bn"></span> mm, <span data-ent="nacional.share_neto" data-ent-unidad="share"></span> % de la neta nacional con <span data-ent="nacional.share_pob" data-ent-unidad="share"></span> % de la población. El Sankey dibuja los mismos flujos que el nacional: los hogares de la entidad según el corte elegido → familias de impuestos → el sistema fiscal federal → gasto → de vuelta a los hogares según el mismo corte; el nodo residual es la posición neta de la entidad frente a la federación. Las celdas con muestra escasa del corte elegido se enlistan bajo la gráfica y se marcan en los tooltips de los enlaces.</p>
		</section>
		<div class="ent-selector metodo-panel-selector" role="radiogroup" aria-label="Corte">
			<span class="metodo-panel-selector-titulo">Corte</span>
<?php $primero = true; foreach ($cortes as $k => $etq): ?>
			<label><input type="radio" name="ent-corte" value="<?= $h($k) ?>"<?= $primero ? ' checked' : '' ?>> <?= $h($etq) ?></label>
<?php $primero = false; endforeach; ?>
		</div>
		<div class="metodo-sankey-wrap">
			<div class="chart metodo-sankey" id="ent-sankey"></div>
		</div>
		<div class="ent-sellos" id="ent-sankey-sellos"></div>

		<h2>2 · Aportación neta a lo largo del ciclo de vida, por sexo y quinquenio de edad</h2>
		<section class="metodo-texto">
			<p>Cada barra es un quinquenio de edad de los residentes de la entidad; su longitud es la aportación neta del grupo (impuestos y contribuciones pagados menos transferencias, pensiones, educación, salud e inversión recibidas) como porcentaje de la aportación neta total de la entidad, apilada según el decil nacional de ingreso del hogar (deciles I–V, VI–IX y X); las barras negativas son grupos que reciben más de lo que pagan. Las celdas de las 32 entidades suman, celda por celda, el perfil nacional de «Carga fiscal por edad»; el sello del motor marca las celdas de esta entidad con muestra escasa o con una persona dominante (⚠ junto a la etiqueta de edad).</p>
		</section>
		<div class="ent-ciclo-grid">
			<div class="ent-ciclo-celda"><h3>Hombres</h3><div class="ent-ciclo" id="ent-ciclo-H"></div></div>
			<div class="ent-ciclo-celda"><h3>Mujeres</h3><div class="ent-ciclo" id="ent-ciclo-M"></div></div>
		</div>
		<div class="ent-sellos" id="ent-ciclo-sellos"></div>

		<h2>3 · Tasas efectivas</h2>
		<section class="metodo-texto">
			<p>Para cada impuesto, la barra es la tasa efectiva de la entidad: lo que pagan sus residentes (suma micro del impuesto, ponderada) entre la base micro de esos mismos residentes (sueldos, ingreso mixto, ingreso privado de capital, consumo, alcohol y tabaco, combustibles), ambos después del anclaje nacional y sin recalibración estatal alguna; la marca es la tasa micro nacional, que es el promedio de las 32 entidades ponderado por sus bases. Se omiten el ISAN y los impuestos a la importación (su tasa estatal es la nacional por construcción<?= metodo_nota_ref(4) ?>); una tasa cuyo numerador depende de una sola persona lleva el sello ⚠.</p>
		</section>
		<div class="ent-tasas" id="ent-tasas"></div>
		<div class="ent-sellos" id="ent-tasas-sellos"></div>

		<h2>4 · Aportación neta de ciclo de vida como proporción del PIB estatal</h2>
		<section class="metodo-texto">
			<p class="ent-neto-cifra" id="ent-neto-cifra">La aportación neta de los hogares de <?= $h($nombre) ?> a la federación, <span data-neto="escalares.NetoCiclo{abrev}.valor" data-neto-unidad="bn"></span> mm de pesos, equivale a <b><span data-neto="escalares.NetoCicloPIBE{abrev}.valor" data-neto-unidad="pct3"></span> %</b> del PIB de la entidad (PIBE <span data-neto="titular.anio" data-neto-unidad="texto"></span>: <span data-neto="escalares.pibY{abrev}.valor" data-neto-unidad="bn"></span> mm de pesos); el cociente nacional en la misma corrida es <span data-ent="nacional.neto_pct_pib" data-ent-unidad="pct3"></span> % (neta nacional de <span data-ent="nacional.neto_pesos" data-ent-unidad="bn"></span> mm entre un PIB nacional de <span data-ent="nacional.pib_pesos" data-ent-unidad="bn"></span> mm). Una entidad por encima del cociente nacional es aportante neta en relación con su economía; un cociente negativo indica una receptora neta. La suma de los 32 PIBE difiere del PIB nacional de la corrida<?= metodo_nota_ref(5) ?>, por lo que los cocientes estatales no son proporciones exactas del nacional. El cociente es el escalar del motor <code>NetoCicloPIBE<?= $h($abrev) ?></code>, exportado como <a href="<?= $h($ep . 'neto') ?>">neto-pibe.json</a>; la página no divide nada.</p>
			<p class="ent-neto-nd lead-nota" id="ent-neto-nd" hidden>El cociente no está disponible en esta corrida (no hay <code>neto-pibe.json</code> para esta entidad: no había base de PIB estatal cuando corrió contrato-32); la aportación neta en pesos está en el producto 1.</p>
		</section>
		<div class="ent-neto" id="ent-neto"></div>

		<h2>Notas</h2>
<?php
metodo_notas(array(
	1 => '<b>Sellos de muestra.</b> El motor sella una celda (un enlace del Sankey desde o hacia un grupo de hogares, una celda quinquenio × sexo del ciclo de vida, un impuesto de la gráfica de tasas) cuando su muestra sin ponderar tiene menos de <span data-ent="parametros.sello_n" data-ent-unidad="entero"></span> personas o cuando una sola persona concentra más de <span data-ent="parametros.sello_top1" data-ent-unidad="entero"></span> % del monto de la celda (regla P5 de <code>SankeySF.do</code>; <code>sello</code>, <code>n</code> y <code>top1</code> viajan en cada JSON). Celdas selladas en esta entidad: <span data-ent="sellos.texto" data-ent-unidad="texto"></span> (enlaces del Sankey / celdas del ciclo de vida / impuestos). Los sellos se leen de <code>meta.json</code>, que <code>generar-entidades.py</code> construye a partir de los JSON del motor al desplegar; la tabla de las 32 (contrato-32, §4) lleva los mismos conteos<span data-ent="tabla_32.coincide" data-ent-unidad="coincide"></span>.',
	2 => '<b>PIB estatal (PIBE).</b> <code>master/PIBDeflactor&lt;ABREV&gt;.dta</code>, construido por <code>PIBDeflactor</code> por entidad a partir del BIE del INEGI (PIB por entidad federativa a precios corrientes, índice de precios implícito, empleo estatal e ITAEE) y sellado con sus fechas de consulta; vintage de la base usada aquí: <span data-ent="pibe.vintage" data-ent-unidad="texto"></span>. El PIBE del año de valor presente (<span data-ent="pibe.anio_vp" data-ent-unidad="texto"></span>) es el escalar del motor <code>pibY&lt;ABREV&gt;</code>; el cociente del producto 4 es el escalar <code>NetoCicloPIBE&lt;ABREV&gt;</code> que <code>contrato-32.do</code> calcula en Stata a partir de él y de <code>NetoCiclo&lt;ABREV&gt;</code> (la neta del módulo de ciclo de vida), exportado con <code>scalarjson</code>.',
	3 => '<b>Fracción de cuentas nacionales sin desagregación estatal.</b> Los componentes de los hogares (ingresos laborales y de capital, consumo, contribuciones) se escalan al sector hogares de las cuentas nacionales a nivel nacional antes del corte por residencia; el SCN no publica cuentas por sector institucional por entidad, así que el motor declara la fracción como nacional y no recalibra por entidad. Consecuencia: los montos de las 32 suman los nacionales por construcción (verificado en contrato-32: Sankeys dentro de 1e-13 relativo, ciclo de vida dentro de la tolerancia de impresión); las tasas y las proporciones no son aditivas.',
	4 => '<b>Tasa nacional por construcción.</b> Para el ISAN y los impuestos a la importación, numerador y denominador se imputan a los hogares con el mismo relativo (<code>Distribucion</code>), de modo que el cociente estatal es igual a la tasa micro nacional en las 32 entidades y no aporta información estatal; la gráfica omite ambos renglones (decisión del reporte v8.13a, FLAG TE ISAN/IMPORT).',
	5 => '<b>Σ32 PIBE frente al PIB nacional.</b> En esta corrida la suma de los 32 PIB estatales del año de valor presente es de <span data-ent="pibe_32.suma_pesos" data-ent-unidad="bn"></span> mm de pesos frente a un PIB nacional de <span data-ent="pibe_32.pib_nacional_pesos" data-ent-unidad="bn"></span> mm: una discrepancia de <span data-ent="pibe_32.discrepancia_pct" data-ent-unidad="signo-pct2"></span> %, informativa (los PIB estatales provienen de las cuentas estatales; el PIB nacional, de las cuentas nacionales y de la proyección del motor; no es un candado). La suma, la discrepancia y el cociente nacional son los escalares del motor <code>pibYSum32</code>, <code>pibeDiscrepancia32</code> y <code>NetoCicloPIBNac</code> (<code>contrato-32.do</code>, exportados con <code>scalarjson</code>), transcritos aquí.',
));
?>
