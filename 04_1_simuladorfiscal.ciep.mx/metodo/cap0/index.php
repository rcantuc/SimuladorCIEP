<?php
// /metodo/cap0 — capítulo 0 del método: requerimientos para replicar el simulador (02_governance/metodo/cap0-requerimientos.md).
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__, 2) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => array('es' => 'Capítulo 0', 'en' => 'Chapter 0'), 'lang' => 'es',
	'descripcion' => array('es' => 'Capítulo 0 del método del Simulador Fiscal CIEP: requerimientos para replicarlo en otro país.',
		'en' => 'Chapter 0 of the method of the Simulador Fiscal CIEP: requirements to replicate it in another country.'),
	'migas' => array(array('href' => '/metodo/cap0/', 'texto' => array('es' => 'Capítulo 0', 'en' => 'Chapter 0')))));
?>
		<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="cap0" data-metodo-estado="cargando">
			<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el capítulo…' : 'Loading the chapter…' ?></p>
		</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "cap0"});'));
