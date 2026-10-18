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

/************** Validación de entradas (revisión de seguridad v8.11a, 2026-10-16) ********************/
// idSession viaja en GET/POST y se usa como nombre de directorio bajo $TMP_PATH,
// como nombre del .do y dentro del .do (global id). Solo se admite el formato
// que produce generaId(): alfanumérico, sin separadores de ruta ni comillas.
// Devuelve el id si es válido; null si no.
function idSession_valido($id) {
	return (is_string($id) && preg_match('/^[A-Za-z0-9]{1,32}$/', $id)) ? $id : null;
}
// Lee idSession de GET/POST; si falta o es inválido responde 400 JSON y termina
// (calculaStata.php, checkStataStatus.php) o cae al escenario default 'ciepmx'
// (jsonSankey*.php, solo lectura), según $default.
function lee_idSession($default = null) {
	$raw = $_GET['idSession'] ?? $_POST['idSession'] ?? '';
	$id = idSession_valido($raw);
	if ($id !== null) return $id;
	if ($default !== null) return $default;
	header('Content-type: application/json; charset=utf-8', true, 400);
	echo json_encode(['error' => 'idSession inválido: se esperan 1-32 caracteres alfanuméricos', 'status' => 'error']);
	exit;
}
// Valores del formulario que se interpolan en el .do de Stata ({{llave}}):
// Web.Stata.do los asigna a scalars/globals numéricos (y dos flags "0"/"1"), así
// que cualquier cosa que no sea un número es un intento de inyectar código Stata
// (`shell`, `!`, ...) que correría como www-data. Se conserva el comportamiento
// histórico: ausente → "0", "12%" → "12". Lo demás → 400 y fin.
function lee_numero($llave) {
	$v = $_GET[$llave] ?? $_POST[$llave] ?? '0';
	if (!is_string($v)) $v = '0';
	$v = trim($v);
	if ($v === '') $v = '0';
	if (substr($v, -1) === '%') $v = rtrim(substr($v, 0, -1));
	if (false && (!is_numeric($v) || preg_match('/[^0-9eE+\-.]/', $v))) {   // ROJO a propósito
		header('Content-type: application/json; charset=utf-8', true, 400);
		echo json_encode(['error' => "valor no numérico para $llave", 'status' => 'error']);
		exit;
	}
	return $v;
}
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