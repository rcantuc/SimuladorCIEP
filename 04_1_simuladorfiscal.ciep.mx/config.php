<?php
	/************************************************
	*************** variables globales  *************
	************************************************/

// Detectar si estamos en desarrollo local o en servidor
$is_local = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || strpos($_SERVER['HTTP_HOST'], '127.0.0.1') !== false);
$TMP_PATH = $is_local ? dirname(dirname(__FILE__)) . '/users/' : '/SIM/OUT/current/users/';

$calcula_ruta = $is_local ? dirname(dirname(__FILE__)) . '/Web.Stata.do' : '/SIM/OUT/current/01_modulos/Web.Stata.do';
#$calcula_rutaCorto = '/SIM/OUT/6/SIMULADOR53corto.do';

// Detectar Stata en diferentes plataformas
if ($is_local && file_exists('/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se')) {
	$stata_exe = '"/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se"';
} elseif ($is_local && file_exists('/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp')) {
	$stata_exe = '"/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"';
} else {
	$stata_exe = '"/usr/local/stata17/stata-mp"';
}
$Cabecera_Stata_Dos_a_Cuatro = '

';													

$idSession='T202210H'; //valor temporal
/************** Valores iniciales por default ********************/

# generar id unico
date_default_timezone_set('UTC');

function make_seed()
{
  list($usec, $sec) = explode(' ', microtime());
  return (int) ($sec + ((float) $usec * 100000));
}
srand(make_seed());
function generaId($length = 4) {
//	return '0SB0PoQ';
	return '0'.substr(str_shuffle("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), 0, $length); 
}
    //Obtiene la IP del cliente
function get_client_ip() {
	$ipaddress = '';
	if (getenv('HTTP_CLIENT_IP'))
		$ipaddress = getenv('HTTP_CLIENT_IP');
	else if(getenv('HTTP_X_FORWARDED_FOR'))
		$ipaddress = getenv('HTTP_X_FORWARDED_FOR');
	else if(getenv('HTTP_X_FORWARDED'))
		$ipaddress = getenv('HTTP_X_FORWARDED');
	else if(getenv('HTTP_FORWARDED_FOR'))
		$ipaddress = getenv('HTTP_FORWARDED_FOR');
	else if(getenv('HTTP_FORWARDED'))
	   $ipaddress = getenv('HTTP_FORWARDED');
	else if(getenv('REMOTE_ADDR'))
		$ipaddress = getenv('REMOTE_ADDR');
	else
		$ipaddress = 'UNKNOWN';
	return $ipaddress;
}
?>