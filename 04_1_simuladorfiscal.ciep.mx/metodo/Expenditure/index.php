<?php
// /metodo/Expenditure — capítulo «Expenditure» del método (01_modulos/Expenditure.do).
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__, 2) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => 'Expenditure', 'lang' => 'es',
	'descripcion' => array('es' => 'Capítulo Expenditure del método del Simulador Fiscal CIEP, generado del repositorio.',
		'en' => 'Chapter Expenditure of the method of the Simulador Fiscal CIEP, generated from the repository.'),
	'migas' => array(array('href' => '/metodo/Expenditure/', 'texto' => 'Expenditure'))));
?>
		<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="capitulo" data-metodo-capitulo="Expenditure" data-metodo-estado="cargando">
			<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el capítulo…' : 'Loading the chapter…' ?></p>
		</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "capitulo", "capitulo": "Expenditure"});'));
