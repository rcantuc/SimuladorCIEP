<?php
// /metodo/output — capítulo «output» del método (01_modulos/output.do).
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__, 2) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => 'output', 'lang' => 'es',
	'descripcion' => 'Capítulo output del método del Simulador Fiscal CIEP, generado del repositorio.',
	'migas' => array(array('href' => '/metodo/output/', 'texto' => 'output'))));
?>
		<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="capitulo" data-metodo-capitulo="output" data-metodo-estado="cargando">
			<p class="metodo-cargando">Cargando el capítulo desde <code>metodo.json</code>…</p>
		</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "capitulo", "capitulo": "output"});'));
