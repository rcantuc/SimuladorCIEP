<?php
// jsonSankeyNTA.php — el Sankey NTA de los hogares, como lo emite el motor.
//
// Origen (motor, solo lectura): Households.do §"Sankeys NTA" corre
// 01_modulos/visualizations/Sankey.do por corte (decil, sexo, grupoedad, escol,
// rural) y SankeySumSim.ado escribe users/<id>/SankeyNTA/sankey-<corte>.json —
// un fragmento JS (nodes/links sin comillas en las claves) que aquí se convierte
// al JSON que FusionCharts consume, con la MISMA transformación y el MISMO bloque
// `chart` que jsonSankey*.php (los Sankeys del sistema fiscal de la portada):
// copiado y no importado porque esos cinco PHP son archivos de un solo corte sin
// función compartida, y esta página (/NTA) no debe tocar su contrato.
//
// Solo lectura. `corte` en lista blanca (forma la ruta); idSession inválido o
// ausente → escenario default 'ciepmx' (helper lee_idSession de config.php).
// La página /NTA es estática y siempre pide el default; el parámetro idSession
// queda por simetría con los otros jsonSankey*.php.
include_once("config.php");

$cortes_validos = array('decil', 'sexo', 'grupoedad', 'escol', 'rural');
$corte = $_GET['corte'] ?? $_POST['corte'] ?? 'grupoedad';
if (!is_string($corte) || !in_array($corte, $cortes_validos, true)) {
	header('Content-type: application/json; charset=utf-8', true, 400);
	echo json_encode(array('error' => 'corte inválido: ' . implode('|', $cortes_validos), 'status' => 'error'));
	exit;
}
$idSession = lee_idSession('ciepmx');

$is_localhost = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || $_SERVER['HTTP_HOST'] == '127.0.0.1');
$base_path = $is_localhost ? dirname(dirname(__FILE__)) . "/users" : "/SIM/OUT/current/users";
$rel = "{$idSession}/SankeyNTA/sankey-{$corte}.json";
if (!file_exists("$base_path/$rel")) {
	$rel = "ciepmx/SankeyNTA/sankey-{$corte}.json";
}
$ruta = "$base_path/$rel";
if (!file_exists($ruta)) {
	header('Content-type: application/json; charset=utf-8', true, 404);
	echo json_encode(array('error' => "no existe users/$rel (¿viajó SankeyNTA/ en la Fase 3b-ter del deploy?)", 'status' => 'error'));
	exit;
}

// Mismo parseo que jsonSankeyGrupoedad.php:38-57 — línea 1: $(document).ready + chart;
// línea 2: nodes; línea 3: links (termina en "]};"); línea 4: FusionCharts.ready.
$gestor = fopen($ruta, "r");
fgets($gestor);
$lineaNode = "";
$lineaLinks = "";
if ($lineaNode = fgets($gestor)) {
	$lineaNode = str_replace("nodes", '"nodes"', $lineaNode);
	$lineaNode = str_replace("label", '"label"', $lineaNode);
}
if ($lineaLinks = fgets($gestor)) {
	$lineaLinks = str_replace("links", '"links"', $lineaLinks);
	$lineaLinks = str_replace("{to:", '{"to":', $lineaLinks);
	$lineaLinks = str_replace("value", '"value"', $lineaLinks);
	$lineaLinks = str_replace("from", '"from"', $lineaLinks);
	$lineaLinks = preg_replace('/:(\d*\.\d+),/i', ':"${1}",', $lineaLinks);
}
$lineaLinks = substr($lineaLinks, 0, -3);
fclose($gestor);

// `nombre` relativo a users/ (trazabilidad del archivo servido, sin ruta absoluta
// del servidor). FusionCharts ignora las claves de `chart` que no conoce.
$respuesta = '{"chart": {
	"caption": " ",
	"nombre":"users/' . $rel . '",
	"corte":"' . $corte . '",
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
	' . $lineaNode . $lineaLinks . '
}';

header('Content-type: application/json; charset=utf-8');
print($respuesta);
?>
