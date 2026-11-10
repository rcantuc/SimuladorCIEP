<?php
// /metodo — índice del método del Simulador Fiscal CIEP: un capítulo por módulo, en el orden de SIM.do, generado del repo.
// GENERADO por 05_scripts/metodo.py: no editar a mano (test-sitio-metodo.sh regenera y exige bytes idénticos).
// Todo el contenido lo pinta /js/metodo-capitulo.js desde /metodo/metodo.json; aquí no hay números ni frases del método.
require_once dirname(__DIR__) . '/plantilla-metodo.php';
metodo_cabecera(array('slug' => 'metodo', 'titulo' => array('es' => 'Método', 'en' => 'Method'), 'lang' => 'es',
	'descripcion' => array('es' => 'Cómo calcula el Simulador Fiscal CIEP: un capítulo por módulo, generado del repositorio.',
		'en' => 'How the Simulador Fiscal CIEP computes: one chapter per module, generated from the repository.')));
?>
		<div id="metodo-contenido" class="metodo-generado" data-metodo-pagina="indice" data-metodo-estado="cargando">
			<p class="metodo-cargando"><?= metodo_lang() === 'es' ? 'Cargando el método…' : 'Loading the method…' ?></p>
		</div>
<?php
metodo_pie(array('scripts' => array('/js/metodo-capitulo.js'), 'init' => 'metodoCapitulo({"url": "/metodo/metodo.json", "pagina": "indice"});'));
