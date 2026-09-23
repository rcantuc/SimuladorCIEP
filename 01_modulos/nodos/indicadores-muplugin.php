<?php
/**
 * Plugin Name: CIEP Indicadores (decorador de hashtags)
 * Description: Encola el decorador estático que añade a los hashtags del
 * home la cifra del motor (contrato /indicadores/statajson_indicadores.json,
 * Simulador Fiscal CIEP). WordPress no guarda ningún número: el JSON y el
 * JS viven como estáticos bajo el docroot y se regeneran con el motor.
 *
 * FUENTE versionada: 01_modulos/nodos/indicadores-muplugin.php
 * Instalación (una vez): copiar a wp-content/mu-plugins/ciep-indicadores.php
 * (los mu-plugins no se activan: existir es estar activo; viaja con el rsync).
 */
add_action( 'wp_enqueue_scripts', function () {
	wp_enqueue_script( 'ciep-indicadores', home_url( '/indicadores/decorador.js' ), array(), null, true );
} );
