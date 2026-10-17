<?php
include_once("config.php");
$debug =false; 
$lineaNode = "";
$lineaLinks = "";

$idSession=(isset($_GET['idSession'])) ? $_GET['idSession'] : $_POST['idSession'];
if($debug) print __LINE__ ." : " . $idSession."*\n<br>";

// Check if running on localhost
$is_localhost = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || $_SERVER['HTTP_HOST'] == '127.0.0.1');

if($is_localhost) {
	$base_path = dirname(dirname(__FILE__));
	$ruta = $base_path . "/users/{$idSession}/sankey-escol.json";
	if(!file_exists($ruta)) {
		$ruta = $base_path . "/users/ciepmx/sankey-escol.json";
	}
} else {
	$ruta="/SIM/OUT/current/users/{$idSession}/sankey-escol.json";
	if(!file_exists($ruta)) {
		$ruta="/SIM/OUT/current/users/ciepmx/sankey-escol.json";
	}
}
if($debug) print __LINE__ ." : $ruta\n<br>";

$gestor = fopen($ruta, "r");

fgets($gestor); //lee la primer linea
if($lineaNode = fgets($gestor)) {
	$lineaNode=str_replace("nodes", '"nodes"', $lineaNode);
	$lineaNode=str_replace("label", '"label"', $lineaNode);
}
	
if($debug) print __LINE__ ." : " . $lineaNode."<br><br>";

if($lineaLinks = fgets($gestor)) {
	$lineaLinks=str_replace("links", '"links"', $lineaLinks);
	$lineaLinks=str_replace("{to:", '{"to":', $lineaLinks);
	$lineaLinks=str_replace("value", '"value"', $lineaLinks);
	$lineaLinks=str_replace("from", '"from"', $lineaLinks);
	$lineaLinks=preg_replace('/:(\d*\.\d+),/i', ':"${1}",', $lineaLinks);
}
$lineaLinks=substr($lineaLinks, 0, -3);

if($debug) print __LINE__ ." : " . $lineaLinks;

fclose($gestor);

$respuesta='{"chart": {
	"caption": " ",
	"nombre":"'.$ruta.'",
    "subcaption": " ",
    "theme": "fusion",
    "orientation": "horizontal",
    "linkalpha": 30,
    "linkhoveralpha": 60,
	"showLegend": 0,
	"linkcolor": "blend",
	"enableDrag": "0",
    "nodelabelposition": "start"
	},
	'.$lineaNode.$lineaLinks.'
}';

if(!$debug) header('Content-type: application/json; charset=utf-8');
if($debug) var_dump($respuesta);
if(!$debug) print($respuesta);
if($debug) print __LINE__ .'Falla';

?>
