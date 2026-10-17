<?php
error_reporting(0);
ini_set('display_errors', 0);
$tiempo_inicial = microtime(true);
set_time_limit(0);
$version="5.1";
include_once("config.php");
$debug =false; 
//$debug =true; 

/****************  Código para cachar evento de ajax y recuperación de valores del formulario   *****************************/
$llaves=array(
	'idSession',
	'INGRESOS0','INGRESOS1','INGRESOS2','INGRESOS4','INGRESOS5',
	'INGRESOS7','INGRESOS8','INGRESOS9','INGRESOS10','INGRESOS11',
	'INGRESOS13','INGRESOS14','INGRESOS15','INGRESOS16','INGRESOS17',
	
	'CRECPIB2026','CRECPIB2027','CRECPIB2028','CRECPIB2029','CRECPIB2030','CRECPIB2031','CRECPIB2032',
	'CRECDEF2026','CRECDEF2027','CRECDEF2028','CRECDEF2029','CRECDEF2030','CRECDEF2031','CRECDEF2032',
	
	'iniciaA','basica','medsup','superi','posgra','eduadu','otrose','invere','cultur','invest',
	'ssa','imssbien','imss','issste','pemex','issfam','invers',
	'bienestar','penims','peniss','penpeme','penotr',
	'gascfe','gaspemex','gassener','gasinverf','gascosdeue',
	'gasinfra','gasotros','gasfeder','gascosto',
	'IngBas','ingbasico18','ingbasico65','gasmadres','gascuidados',
	
	'ISRTASA0','ISRTASA1','ISRTASA2','ISRTASA3','ISRTASA4','ISRTASA5',
	'ISRTASA6','ISRTASA7','ISRTASA8','ISRTASA9','ISRTASA10',
	'SE0','SE1','SE2','SE3','SE4','SE5','SE6','SE7','SE8','SE9','SE10',
	'DED0','DED1','DED2','DED3',
	'ISRMORA0','ISRMORA1',
	
	'CSSIMSS0','CSSIMSS1','CSSIMSS2','CSSIMSS3','CSSIMSS4','CSSIMSS5',
	'CSSIMSS6','CSSIMSS7','CSSIMSS8','CSSIMSS9','CSSIMSS10','CSSIMSS11',
	'CSSIMSS12','CSSIMSS13','CSSIMSS14','CSSIMSS15','CSSIMSS16','CSSIMSS17',
	'CSSIMSS18','CSSIMSS19','CSSIMSS20',
	
	'CSSISSSTE0','CSSISSSTE1','CSSISSSTE2','CSSISSSTE3','CSSISSSTE4','CSSISSSTE5',
	'CSSISSSTE6','CSSISSSTE7','CSSISSSTE8','CSSISSSTE9','CSSISSSTE10','CSSISSSTE11',
	'CSSISSSTE12','CSSISSSTE13','CSSISSSTE14','CSSISSSTE15','CSSISSSTE16','CSSISSSTE17',
	'CSSISSSTE18','CSSISSSTE19','CSSISSSTE20','CSSISSSTE21','CSSISSSTE22','CSSISSSTE23',
	
	'IVAT0','IVAT1','IVAT2','IVAT3','IVAT4','IVAT5','IVAT6','IVAT7','IVAT8','IVAT9','IVAT10','IVAT11','IVAT12',
	
	'DEUDA0',
	'moduloCambio','moduloCambioIva'
);	
	


$idSession=(isset($_GET['idSession'])) ? $_GET['idSession'] : $_POST['idSession'];

$guardar=array();


if($debug) print __LINE__ ." : " . $idSession."*\n<br>";

$jsondata=array();

foreach($llaves as $k) {
//	$guardar[$k]=(isset($_GET[$k])) ? $_GET[$k] : ((isset($_POST[$k])) ? $_POST[$k]: 0);
	$tGuardar=(isset($_GET[$k])) ? $_GET[$k] : ((isset($_POST[$k])) ? $_POST[$k]: 0);
	if(strpos($tGuardar, '%'))
		$tGuardar=substr($tGuardar, 0, -1);

	$guardar[$k]=$tGuardar;
//	if(!$guardar[$k]) $guardar[$k]="0";

	$jsondata[$k]=$tGuardar;;
if($debug) print __LINE__ ." : " . $k . "=>" .$guardar[$k] ."\n<br />" ;

}


$cmd = "rm -f " . escapeshellarg($TMP_PATH . $idSession) . "/*" ;
if($debug) print  __LINE__ ." : " ."$cmd<br />";
shell_exec( $cmd );

mkdir($TMP_PATH.$idSession,0755,true);
if($debug) print  __LINE__ ." : " ."mkdir $TMP_PATH$idSession<br />";


/****** copiado de la base de datos necesaria  ****/
/*
$cmd = "cp $bases  $TMP_PATH$idSession" ;
shell_exec( $cmd );
if($debug) print __LINE__ ." : " . "$cmd <br>\n";
*/
$stata_out=$TMP_PATH.$idSession."/{$idSession}.do";
if($debug) print __LINE__ ." : " ."$stata_out<br />";
if($debug) print __LINE__ ." : " ."$calcula_ruta<br />";

$gestor = fopen($calcula_ruta, "r");
$contenido = fread($gestor, filesize($calcula_ruta));
fclose($gestor);

$guardar['ruta']= $TMP_PATH.$idSession."/";
if($debug) print __LINE__ ." : " .'ruta' . "=>" .$guardar['ruta'] ."\n<br />" ;

foreach($llaves as $llave){
	$guardarLlave=$guardar[$llave];
	$contenido=str_replace('{{'.$llave.'}}', $guardar[$llave],$contenido);
}

$fh = fopen($stata_out,'w');
fwrite($fh,$contenido);
fclose($fh);

// Eliminar output.txt anterior si existe
$working_dir = $TMP_PATH . $idSession;
$output_file = $working_dir . "/output.txt";
if(file_exists($output_file)) {
	unlink($output_file);
}

// Ejecutar Stata de forma síncrona
$do_file_name = $idSession . ".do";
$cmd = "cd " . escapeshellarg($working_dir) . " && " . $stata_exe . " -b do " . escapeshellarg($do_file_name) . " 2>&1";
$salida = shell_exec($cmd);

// Leer y parsear output.txt
$output_file = $working_dir . "/output.txt";
if(file_exists($output_file)) {
	$contenido = file_get_contents($output_file);
	
	// Limpiar prefijo
	$contenido = str_replace(".quietlylogoffoutput", "", $contenido);
	$contenido = trim($contenido);
	
	// Buscar patrones: NOMBRE:[valor]NOMBRE: o NOMBRE:[valor]$
	preg_match_all('/(\w+):\s*(\[[^\]]*\]|[^A-Z\s][^\s]*?)(?=\s+\w+:|$)/', $contenido, $matches, PREG_SET_ORDER);
	
	foreach($matches as $match) {
		$nombre = trim($match[1]);
		$valor = trim($match[2]);
		
		// Saltar líneas vacías o sin contenido
		if(empty($valor) || $valor === '.' || strlen($valor) < 1) continue;
		
		if(strpos($valor, '[') === 0) {
			// Es un array - convertir a array PHP con valores numéricos
			$valor_limpio = str_replace(" ", "", $valor);
			$valor_limpio = substr($valor_limpio, 1, -1); // Remover [ y ]
			$elementos = explode(",", $valor_limpio);
			// Convertir strings a números (float o int)
			$elementos = array_map(function($el) {
				if($el === 'null') return null;
				return is_numeric($el) ? floatval($el) : $el;
			}, $elementos);
			$jsondata[$nombre] = $elementos;
		} else {
			// Es un valor simple
			$jsondata[$nombre] = $valor;
		}
	}
}
$jsondata['tiempo']= microtime(true)-$tiempo_inicial;
/****************** genera el log de ejecuciones *********** /

unset($jsondata['ruta']);
$calcula_log = $TMP_PATH . $idSession . "/" . $idSession . "_execution.log";
$fp = fopen($calcula_log, 'a');//opens file in append mode  
$linea=implode(';',$jsondata) .";". get_client_ip(). ";". date("m/d/y;H:i:s")."\n";
fwrite($fp, $linea);  
fclose($fp);  


/****************** regresa los resultados *****************/

if(!$debug) header('Content-type: application/json; charset=utf-8');
if($debug) var_dump($jsondata);
else echo json_encode($jsondata);

?>
