<?php
// jsonEntidad.php — los productos de una entidad federativa, como los emite el motor (v8.13.0, template estatal).
//
//   ?abrev=<ABREV>&producto=sankey[&corte=quintil|grupoedad|sexo|rural|escol]
//       users/<id>/<ABREV>/sankey-<corte>.json (SankeySF.do por entidad, contrato-32 §8.2; default quintil = el
//       quintil ESTATAL). El archivo del motor es un fragmento JS (claves sin comillas) con cuatro bloques:
//       chart, entidad (nombre, clave, abrev, corte, población, sello_n/sello_top1, vintages, celdas con su n),
//       nodes y links; cada enlace micro trae n, top1 y sello (regla P5) y, si hubo vintages, la banda
//       v<año>… / bmin / bmax. Aquí se ponen comillas a las claves (la misma gramática que leen
//       compuertas-entidad.py y generar-entidades.py), se valida que sea JSON, y se devuelve
//       {chart, entidad, nodes, links}: los nodos y enlaces viajan tal cual (los valores son cadenas y no
//       se tocan); el bloque `chart` es el de presentación de jsonSankeyNTA.php; a los enlaces con sello=1
//       se les agrega un toolText que declara n y top-1 («read as indicative») y un color de marca. Ningún
//       número se escribe aquí.
//   ?abrev=<ABREV>&producto=ciclo    users/<id>/<ABREV>/ciclo-vida.json      (CicloEntidad.do, ciclo-vida/v1)   byte a byte
//   ?abrev=<ABREV>&producto=tasas    users/<id>/<ABREV>/tasas-efectivas.json (TasasEfectivasEntidad.do)        byte a byte
//   ?abrev=<ABREV>&producto=meta     users/<id>/<ABREV>/meta.json (generar-entidades.py meta, entidad-meta/v1:
//                                    sellos con su n, PIBE y neto del ciclo, espejo)                            byte a byte
//   ?abrev=<ABREV>&producto=neto     alias de meta (el producto «neto del ciclo como % del PIBE» vive ahí)
//   ?producto=indice                 users/<id>/entidades.json (entidades-indice/v1: la tabla de las 32)      byte a byte
//
// Harness de seguridad (test-sitio-entidades.sh, test-sitio-seguridad.sh): abrev se valida ESTRICTO contra el
// catálogo generado entidades/_catalogo.php (clave exacta, mayúsculas incluidas; forma la ruta) → 400 si no está;
// producto y corte en lista blanca → 400; idSession inválido o ausente → escenario default 'ciepmx'
// (lee_idSession de config.php, como los otros jsonSankey*.php). Archivo ausente → 404 con la pista del deploy
// (Fase 3b-ter de publicar-vps.sh embarca users/ricardo/<ABREV>/ para las 32 y entidades.json).
include_once("config.php");

$is_localhost = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || $_SERVER['HTTP_HOST'] == '127.0.0.1');
$base_path = $is_localhost ? dirname(dirname(__FILE__)) . "/users" : "/SIM/OUT/current/users";
$idSession = lee_idSession('ciepmx');
$catalogo = require __DIR__ . '/entidades/_catalogo.php';

function ent_error($codigo, $mensaje) {
	header('Content-type: application/json; charset=utf-8', true, $codigo);
	echo json_encode(array('error' => $mensaje, 'status' => 'error'), JSON_UNESCAPED_UNICODE);
	exit;
}

// Resuelve users/<idSession>/<rel>; si no existe, cae al default ciepmx; si tampoco, 404 con pista de deploy.
function ent_ruta($base_path, $idSession, $rel_fmt) {
	$rel = sprintf($rel_fmt, $idSession);
	if (!file_exists("$base_path/$rel")) {
		$rel = sprintf($rel_fmt, 'ciepmx');
	}
	if (!file_exists("$base_path/$rel")) {
		ent_error(404, "no existe users/$rel (¿viajó users/ricardo/<ABREV>/ y entidades.json en la Fase 3b-ter del deploy? Los produce contrato-32.sh)");
	}
	return array("$base_path/$rel", $rel);
}

function ent_sirve_json($ruta, $rel) {
	header('X-Entidad-Archivo: users/' . $rel);
	header('Content-type: application/json; charset=utf-8');
	readfile($ruta);
	exit;
}

$productos_validos = array('sankey', 'ciclo', 'tasas', 'meta', 'neto', 'indice');
$producto = $_GET['producto'] ?? $_POST['producto'] ?? '';
if (!is_string($producto) || !in_array($producto, $productos_validos, true)) {
	ent_error(400, 'producto inválido: ' . implode('|', $productos_validos));
}

// --- ?producto=indice : la tabla de las 32 (sin abrev) ---
if ($producto === 'indice') {
	list($ruta, $rel) = ent_ruta($base_path, $idSession, '%s/entidades.json');
	ent_sirve_json($ruta, $rel);
}

// --- abrev: estricto contra el catálogo (forma la ruta) ---
$abrev = $_GET['abrev'] ?? $_POST['abrev'] ?? '';
if (!is_string($abrev) || $abrev === '' || !array_key_exists($abrev, $catalogo) || !preg_match('/^[A-Za-z]{2,6}$/', $abrev)) {
	ent_error(400, 'abrev inválido: una de ' . implode('|', array_keys($catalogo)));
}

if ($producto === 'ciclo') {
	list($ruta, $rel) = ent_ruta($base_path, $idSession, "%s/{$abrev}/ciclo-vida.json");
	ent_sirve_json($ruta, $rel);
}
if ($producto === 'tasas') {
	list($ruta, $rel) = ent_ruta($base_path, $idSession, "%s/{$abrev}/tasas-efectivas.json");
	ent_sirve_json($ruta, $rel);
}
if ($producto === 'meta' || $producto === 'neto') {
	list($ruta, $rel) = ent_ruta($base_path, $idSession, "%s/{$abrev}/meta.json");
	ent_sirve_json($ruta, $rel);
}

// --- ?producto=sankey : el Sankey de aportación por corte (FusionCharts) ---
$cortes_validos = array('quintil', 'grupoedad', 'sexo', 'rural', 'escol');
$corte = $_GET['corte'] ?? $_POST['corte'] ?? 'quintil';
if (!is_string($corte) || !in_array($corte, $cortes_validos, true)) {
	ent_error(400, 'corte inválido: ' . implode('|', $cortes_validos));
}
list($ruta, $rel) = ent_ruta($base_path, $idSession, "%s/{$abrev}/sankey-{$corte}.json");

$texto = file_get_contents($ruta);
if ($texto === false || !preg_match('/const dataSource=(\{.*\});\s*FusionCharts/s', $texto, $m)) {
	ent_error(500, "users/$rel no tiene la forma que escribe SankeySF.do (const dataSource={...}; FusionCharts…)");
}
// claves sin comillas → con comillas (misma regex que compuertas-entidad.py / generar-entidades.py)
$js = preg_replace('/([{,\[])\s*([A-Za-z0-9]+)\s*:/', '$1"$2":', $m[1]);
$d = json_decode($js, true);
if (!is_array($d) || !isset($d['nodes']) || !isset($d['links'])) {
	ent_error(500, "users/$rel no se pudo leer como JSON (nodes/links)");
}

// Marca de sello en los enlaces micro con sello=1 (regla P5 del motor: n < sello_n o top-1 > sello_top1): solo
// presentación (toolText con los valores que el propio enlace trae, tal cual; color de marca). Nada se recalcula.
$entidad = isset($d['entidad']) && is_array($d['entidad']) ? $d['entidad'] : array();
$marcados = 0;
foreach ($d['links'] as &$l) {
	if (isset($l['sello']) && $l['sello'] === '1') {
		$l['toolText'] = $l['from'] . ' → ' . $l['to'] . '<br>' . $l['value'] . ' MXN<br>⚠ thin cell: n = ' . $l['n'] . ', top-1 = ' . $l['top1'] . ' % of the cell — read as indicative';
		$l['color'] = '#c0392b';
		$marcados++;
	}
}
unset($l);

$chart = array(
	'caption' => ' ',
	'nombre' => 'users/' . $rel,
	'abrev' => $abrev,
	'corte' => $corte,
	'corteMotor' => $entidad['corte'] ?? $corte,
	'enlacesConSello' => (string)$marcados,
	'subcaption' => ' ',
	'theme' => 'fusion',
	'orientation' => 'horizontal',
	'linkalpha' => 30,
	'linkhoveralpha' => 60,
	'showLegend' => 0,
	'linkcolor' => 'blend',
	'enableDrag' => '0',
	'nodelabelposition' => 'start',
	'plotToolText' => '$label<br>$nodeValue MXN',
	'linkToolText' => '$from → $to<br>$linkValue MXN',
);
$respuesta = array('chart' => $chart, 'entidad' => $entidad, 'nodes' => $d['nodes'], 'links' => $d['links']);

header('X-Entidad-Archivo: users/' . $rel);
header('Content-type: application/json; charset=utf-8');
print(json_encode($respuesta, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
?>
