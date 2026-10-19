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
	if (!is_numeric($v) || preg_match('/[^0-9eE+\-.]/', $v)) {
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

/************** Freno de abuso de CPU (v8.11c, 2026-10-18) ********************/
// calculaStata.php lanza un Stata (~35 s de CPU) por cada «Calcular»: sin freno,
// N peticiones = N Stata en paralelo. Dos topes, PHP plano, estado en archivos
// bajo $TMP_PATH/_ratelimit/ con flock (un idSession es alfanumérico: '_ratelimit'
// no puede chocar con ninguna sesión):
//   MAX_STATA_SIMULTANEOS  guardia real contra DoS por CPU: Stata corriendo a la vez.
//   LIMITE_CORRIDAS_POR_IP corridas aceptadas por IP en cada VENTANA_SEG (nadie acapara).
// Un usuario legítimo (un escenario cada tanto) no los toca. Defaults firmados por
// Ricardo el 2026-10-18 (100/10 min: las aulas y talleres del CIEP salen por una sola
// IP pública; 10 era poco). Se afinan AQUÍ. Única exención: 127.0.0.1 (pruebas locales
// y el harness de CI) queda fuera del tope por IP; el de simultáneos aplica a todos,
// porque protege la CPU de la máquina, no a un usuario.
define('LIMITE_CORRIDAS_POR_IP', 100);
define('IPS_EXENTAS_LIMITE_IP', '127.0.0.1');	// lista separada por comas; solo loopback IPv4
define('VENTANA_SEG', 600);
define('MAX_STATA_SIMULTANEOS', 3);
define('RETRY_SIMULTANEOS_SEG', 30);	// Retry-After cuando el tope es de simultáneos (una corrida dura ~35 s)
define('STATA_SLOT_TTL', 600);		// un slot que nadie liberó (proceso muerto) deja de contar a los 10 min

// Admisión de una corrida. IP = REMOTE_ADDR (NO get_client_ip(): esa lee cabeceras
// X-Forwarded-For/Client-IP que el cliente falsifica; el sitio va directo en Apache,
// sin proxy delante — misma fuente que usa logCalcular.php).
// Devuelve ['ok'=>true, 'slot'=>ruta] (hay que liberarlo con stata_libera) o
// ['ok'=>false, 'motivo'=>'ip'|'simultaneos', 'retry'=>segundos]. Si el estado no se
// puede abrir, deja pasar (el sitio no se cae por el freno) y lo anota en error_log.
function stata_admision($tmp_path) {
	$dir = $tmp_path . '_ratelimit/';
	if (!is_dir($dir) && !@mkdir($dir, 0755, true) && !is_dir($dir)) {
		error_log('ratelimit: no se pudo crear ' . $dir);
		return array('ok' => true, 'slot' => null);
	}
	$lock = @fopen($dir . 'lock', 'c');
	if (!$lock || !flock($lock, LOCK_EX)) {
		error_log('ratelimit: no se pudo bloquear ' . $dir . 'lock');
		return array('ok' => true, 'slot' => null);
	}
	$ahora = time();
	$vivos = 0;
	foreach (glob($dir . 'slot-*') ?: array() as $f) {
		if ($ahora - (int)@filemtime($f) > STATA_SLOT_TTL) { @unlink($f); continue; }
		$vivos++;
	}
	$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
	$exenta = in_array($ip, array_map('trim', explode(',', IPS_EXENTAS_LIMITE_IP)), true);
	$archivo_ip = $dir . 'ip-' . sha1($ip);
	$marcas = array();
	foreach (@file($archivo_ip, FILE_IGNORE_NEW_LINES) ?: array() as $t) {
		if ($ahora - (int)$t < VENTANA_SEG) $marcas[] = (int)$t;
	}
	$res = null;
	if ($vivos >= MAX_STATA_SIMULTANEOS) {
		$res = array('ok' => false, 'motivo' => 'simultaneos', 'retry' => RETRY_SIMULTANEOS_SEG);
	} elseif (!$exenta && count($marcas) >= LIMITE_CORRIDAS_POR_IP) {
		$res = array('ok' => false, 'motivo' => 'ip', 'retry' => max(1, min($marcas) + VENTANA_SEG - $ahora));
	} else {
		if (!$exenta) {
			$marcas[] = $ahora;
			file_put_contents($archivo_ip, implode("\n", $marcas) . "\n");
		}
		$slot = $dir . 'slot-' . getmypid() . '-' . bin2hex(random_bytes(4));
		touch($slot);
		$res = array('ok' => true, 'slot' => $slot);
		if (mt_rand(1, 50) === 1) {	// barrido ocasional de IPs inactivas
			foreach (glob($dir . 'ip-*') ?: array() as $f) {
				if ($ahora - (int)@filemtime($f) > VENTANA_SEG) @unlink($f);
			}
		}
	}
	flock($lock, LOCK_UN);
	fclose($lock);
	return $res;
}
function stata_libera($slot) {
	if ($slot) @unlink($slot);
}
?>