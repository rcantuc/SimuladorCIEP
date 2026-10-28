<?php
// jsonSankeyNTA.php — el Sankey NTA de los hogares (y la cuenta NTA por grupo), como los emite el motor.
//
// Dos lecturas de solo lectura sobre users/<id>/ (v8.12.5, NTA-2):
//
//   ?corte=<corte>   (default v2-grupoedad) → users/<id>/SankeyNTA/sankey-<corte>.json
//       v2-grupoedad: el Sankey v2 (contrato v2.1) que escribe 01_modulos/NTA.do §7 → SankeySumSim
//                     folder(SankeyNTA) name(v2-grupoedad): la cuenta NTA por individuo alineada con S.14.
//                     Es lo que dibuja la página de método /NTA.
//       decil | sexo | grupoedad | escol | rural: los cortes v1 (Households.do §"Sankeys NTA" →
//                     visualizations/Sankey.do → SankeySumSim). El motor los sigue emitiendo; /NTA ya no
//                     los dibuja (v1 retirado del sitio en v8.12.5) pero el endpoint los conserva mientras
//                     existan los archivos.
//       El archivo del motor es un fragmento JS (nodes/links sin comillas en las claves) que aquí se
//       convierte al JSON que FusionCharts consume, con la MISMA transformación y el MISMO bloque `chart`
//       que jsonSankey*.php (los Sankeys del sistema fiscal de la portada): copiado y no importado porque
//       esos cinco PHP son archivos de un solo corte sin función compartida, y esta página no debe tocar su
//       contrato. Los nodos y enlaces viajan tal cual (sin redondeo); lo único que agrega el PHP es el
//       bloque `chart` (presentación: plotToolText/linkToolText con los macros de FusionCharts) y, en el
//       v2, un toolText local en los nodos de grupo («Ingreso <g>», «Consumo <g>») que dice que entradas =
//       salidas en ese nodo. Ningún número se escribe aquí.
//
//   ?cuenta=<cuenta>  → users/<id>/NTA/nta-<cuenta>.{json,txt}
//       grupoedad | quinquenio-sexo: los JSON de la cuenta NTA por grupo (NTA.do §6.2 y §6.3), ya JSON válido:
//                     se sirven byte a byte (la página /NTA lee de aquí Σ S sin ancla vs B.8n, el factor del
//                     recorte y el residual intra-hogar; nada se recalcula en PHP ni en JS).
//       identidad:    el reporte de texto nta-identidad.txt (text/plain), enlazado desde /NTA.
//
// `corte`/`cuenta` en lista blanca (forman la ruta); idSession inválido o ausente → escenario default
// 'ciepmx' (helper lee_idSession de config.php). La página /NTA es estática y siempre pide el default;
// el parámetro idSession queda por simetría con los otros jsonSankey*.php. En el VPS estos archivos
// llegan a users/ciepmx/ en la Fase 3b-ter de publicar-vps.sh (manifiesto del default).
include_once("config.php");

$is_localhost = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || $_SERVER['HTTP_HOST'] == '127.0.0.1');
$base_path = $is_localhost ? dirname(dirname(__FILE__)) . "/users" : "/SIM/OUT/current/users";
$idSession = lee_idSession('ciepmx');

function nta_error($codigo, $mensaje) {
	header('Content-type: application/json; charset=utf-8', true, $codigo);
	echo json_encode(array('error' => $mensaje, 'status' => 'error'));
	exit;
}

// Resuelve users/<idSession>/<rel>; si no existe, cae al default ciepmx; si tampoco, 404 con pista de deploy.
function nta_ruta($base_path, $idSession, $rel_fmt) {
	$rel = sprintf($rel_fmt, $idSession);
	if (!file_exists("$base_path/$rel")) {
		$rel = sprintf($rel_fmt, 'ciepmx');
	}
	if (!file_exists("$base_path/$rel")) {
		nta_error(404, "no existe users/$rel (¿viajó users/ricardo/NTA/ y SankeyNTA/ en la Fase 3b-ter del deploy?)");
	}
	return array("$base_path/$rel", $rel);
}

// --- ?cuenta= : la cuenta NTA por grupo (JSON del motor, byte a byte) o el reporte de identidad (texto) ---
$cuenta = $_GET['cuenta'] ?? $_POST['cuenta'] ?? '';
if ($cuenta !== '') {
	$cuentas_validas = array('grupoedad', 'quinquenio-sexo', 'identidad');
	if (!is_string($cuenta) || !in_array($cuenta, $cuentas_validas, true)) {
		nta_error(400, 'cuenta inválida: ' . implode('|', $cuentas_validas));
	}
	$ext = ($cuenta === 'identidad') ? 'txt' : 'json';
	list($ruta, $rel) = nta_ruta($base_path, $idSession, "%s/NTA/nta-{$cuenta}.{$ext}");
	header('X-NTA-Archivo: users/' . $rel);
	if ($ext === 'txt') {
		header('Content-type: text/plain; charset=utf-8');
	} else {
		header('Content-type: application/json; charset=utf-8');
	}
	readfile($ruta);
	exit;
}

// --- ?corte= : el Sankey (default: v2 por grupo de edad) ---
$cortes_validos = array('v2-grupoedad', 'decil', 'sexo', 'grupoedad', 'escol', 'rural');
$corte = $_GET['corte'] ?? $_POST['corte'] ?? 'v2-grupoedad';
if (!is_string($corte) || !in_array($corte, $cortes_validos, true)) {
	nta_error(400, 'corte inválido: ' . implode('|', $cortes_validos));
}
list($ruta, $rel) = nta_ruta($base_path, $idSession, "%s/SankeyNTA/sankey-{$corte}.json");

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

// v2: en los nodos de grupo («Ingreso <g>», «Consumo <g>») un toolText local que declara la conservación
// (entradas = salidas; $nodeValue es ese total, macro de FusionCharts). Solo texto de presentación: la
// etiqueta y el orden de los nodos no cambian (05_scripts/test-sitio-nta.js lo exige).
if ($corte === 'v2-grupoedad') {
	$lineaNode = preg_replace(
		'/\{"label":"((?:Ingreso|Consumo) [^"]*)"\}/u',
		'{"label":"$1","toolText":"$label<br>inflows = outflows = $nodeValue MXN"}',
		$lineaNode
	);
}

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
    "nodelabelposition": "start",
    "plotToolText": "$label<br>$nodeValue MXN",
    "linkToolText": "$from → $to<br>$linkValue MXN"
	},
	' . $lineaNode . $lineaLinks . '
}';

header('Content-type: application/json; charset=utf-8');
print($respuesta);
?>
