<?php
include_once("config.php");
$debug =false; 
//$debug =true; 
//var_dump($gestor);
//fgets($gestor);
$lineaNode = "";
$lineaLinks = "";



$idSession=(isset($_GET['idSession'])) ? $_GET['idSession'] : $_POST['idSession'];
if($debug) print __LINE__ ." : " . $idSession."*\n<br>";

// Check if running on localhost
$is_localhost = (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || $_SERVER['HTTP_HOST'] == '127.0.0.1');

if($is_localhost) {
	$base_path = dirname(dirname(__FILE__));
	$ruta = $base_path . "/users/{$idSession}/sankey-grupoedad.json";
	if(!file_exists($ruta)) {
		$ruta = $base_path . "/users/ciepmx/sankey-grupoedad.json";
	}
} else {
	//$ruta="/SIM/OUT/5/5.3/users/{$idSession}/sankey-decil.json";
	$ruta="/SIM/OUT/current/users/{$idSession}/sankey-grupoedad.json";
	if(!file_exists($ruta)) {
		$ruta="/SIM/OUT/current/users/ciepmx/sankey-grupoedad.json";
	}
}
if($debug) print __LINE__ ." : $ruta\n<br>";

$gestor = fopen($ruta, "r");
//$gestor = fopen("/SIM/OUT/5/5.0/users/sankey-decil.json", "r");

fgets($gestor); //lee la primer linea
if($lineaNode = fgets($gestor)) {
//	$lineaNode=fgets($gestor);
	$lineaNode=str_replace("nodes", '"nodes"', $lineaNode);
	$lineaNode=str_replace("label", '"label"', $lineaNode);
//    echo $lineaNode.'<br/>';
}
	
if($debug) print __LINE__ ." : " . $lineaNode."<br><br>";

if($lineaLinks = fgets($gestor)) {
//	$lineaLinks=fgets($gestor);
	$lineaLinks=str_replace("links", '"links"', $lineaLinks);
	$lineaLinks=str_replace("{to:", '{"to":', $lineaLinks);
	$lineaLinks=str_replace("value", '"value"', $lineaLinks);
	$lineaLinks=str_replace("from", '"from"', $lineaLinks);
	$lineaLinks=preg_replace('/:(\d*\.\d+),/i', ':"${1}",', $lineaLinks);
//    echo $lineaLinks.'<br/>';
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



/*

$respuesta='{"chart": {
	"caption": "El sistema fiscal mexicano",
    "subcaption": "De la recaudación al gasto público",
    "theme": "fusion",
    "orientation": "horizontal",
    "linkalpha": 30,
    "linkhoveralpha": 60,
    "nodelabelposition": "start"
	},
	"nodes":[{"label":"I"},{"label":"Laboral"},{"label":" Consumo"},{"label":" FMP"},{"label":"  De Capital"},{"label":"II"},{"label":"III"},{"label":"IV"},{"label":"V"},{"label":"VI"},{"label":"VII"},{"label":"VIII"},{"label":"IX"},{"label":"X"},{"label":"OyE estatales"},{"label":"Otros ingresos"},{"label":"Futuro"},{"label":"Endeudamiento"},{"label":"Sistema Fiscal"},{"label":"Educacion"},{"label":"Salud"},{"label":" Salarios de gobiern"},{"label":"  Pension Bienestar"},{"label":"  Pensiones"},{"label":"   Infraestructura"},{"label":"Otros gastos"},{"label":"Otras Part y Aport"},{"label":"Costo de la deuda"},{"label":" I"},{"label":" II"},{"label":" III"},{"label":" IV"},{"label":" V"},{"label":" VI"},{"label":" VII"},{"label":" VIII"},{"label":" IX"},{"label":" X"},{"label":"No distribuibles"},{"label":"Estados y municipios"},{"label":"Sistema financiero"}],
	"links":[{"to":"Laboral","value":".0458029221388865","from":"I"},{"to":" Consumo","value":".2050627336163059","from":"I"},{"to":" FMP","value":".1362576865045573","from":"I"},{"to":"  De Capital","value":".0056120861135731","from":"I"},{"to":"Laboral","value":".1333675596853484","from":"II"},{"to":" Consumo","value":".2732106999008164","from":"II"},{"to":" FMP","value":".1361466453162207","from":"II"},{"to":"  De Capital","value":".0166103870085577","from":"II"},{"to":"Laboral","value":".2148118095558586","from":"III"},{"to":" Consumo","value":".3312683889702446","from":"III"},{"to":" FMP","value":".1362020972686649","from":"III"},{"to":"  De Capital","value":".0323790631432095","from":"III"},{"to":"Laboral","value":".2916565952270425","from":"IV"},{"to":" Consumo","value":".3822234212196493","from":"IV"},{"to":" FMP","value":".1362185501618117","from":"IV"},{"to":"  De Capital","value":".0565379582716428","from":"IV"},{"to":"Laboral","value":".3862604126303704","from":"V"},{"to":" Consumo","value":".4473518913727079","from":"V"},{"to":" FMP","value":".136209637298002","from":"V"},{"to":"  De Capital","value":".0864377933883485","from":"V"},{"to":"Laboral","value":".5162089235751528","from":"VI"},{"to":" Consumo","value":".5518036643329109","from":"VI"},{"to":" FMP","value":".1361856654960505","from":"VI"},{"to":"  De Capital","value":".1152778976107226","from":"VI"},{"to":"Laboral","value":".6161268650935028","from":"VII"},{"to":" Consumo","value":".6296168464121275","from":"VII"},{"to":" FMP","value":".1361840286549459","from":"VII"},{"to":"  De Capital","value":".1671337518344084","from":"VII"},{"to":"Laboral","value":".7690497736861163","from":"VIII"},{"to":" Consumo","value":".758592511279318","from":"VIII"},{"to":" FMP","value":".136224886320915","from":"VIII"},{"to":"  De Capital","value":".2585049276127521","from":"VIII"},{"to":"Laboral","value":".9435640599693302","from":"IX"},{"to":" Consumo","value":".9455311505295337","from":"IX"},{"to":" FMP","value":".1361851586033212","from":"IX"},{"to":"  De Capital","value":".4510416578619753","from":"IX"},{"to":"Laboral","value":"1.464151078438401","from":"X"},{"to":" Consumo","value":"1.662719273454103","from":"X"},{"to":" FMP","value":".1361856443755194","from":"X"},{"to":"  De Capital","value":"2.520464477154814","from":"X"},{"to":"  De Capital","value":"4.273999999956287","from":"OyE estatales"},{"to":"  De Capital","value":"1.069999999989057","from":"Otros ingresos"},{"to":"Endeudamiento","value":"3.099181581117024","from":"Futuro"},{"to":"Sistema Fiscal","value":"5.38100000000001","from":"Laboral"},{"to":"Sistema Fiscal","value":"6.187380581087717","from":" Consumo"},{"to":"Sistema Fiscal","value":"1.362000000000008","from":" FMP"},{"to":"Sistema Fiscal","value":"9.053999999945347","from":"  De Capital"},{"to":"Sistema Fiscal","value":"3.099181581117024","from":"Endeudamiento"},{"to":"Educacion","value":"3.252939316816678","from":"Sistema Fiscal"},{"to":"Salud","value":"2.56985482039888","from":"Sistema Fiscal"},{"to":" Salarios de gobiern","value":"1.737867532429872","from":"Sistema Fiscal"},{"to":"  Pension Bienestar","value":".6071107195377454","from":"Sistema Fiscal"},{"to":"  Pensiones","value":"4.242409988607947","from":"Sistema Fiscal"},{"to":"   Infraestructura","value":"1.71585624998672","from":"Sistema Fiscal"},{"to":"Otros gastos","value":"3.321656087757713","from":"Sistema Fiscal"},{"to":"Otras Part y Aport","value":"4.62185742277152","from":"Sistema Fiscal"},{"to":"Costo de la deuda","value":"3.014010023843029","from":"Sistema Fiscal"},{"to":" I","value":".387903546103412","from":"Educacion"},{"to":" II","value":".3727278775591662","from":"Educacion"},{"to":" III","value":".3598131594580724","from":"Educacion"},{"to":" IV","value":".3592270736607703","from":"Educacion"},{"to":" V","value":".3380647961638729","from":"Educacion"},{"to":" VI","value":".3209573006689734","from":"Educacion"},{"to":" VII","value":".3033429587375436","from":"Educacion"},{"to":" VIII","value":".2990582433056851","from":"Educacion"},{"to":" IX","value":".2811981080455565","from":"Educacion"},{"to":" X","value":".2306462531136261","from":"Educacion"},{"to":" I","value":".1898310648934461","from":"Salud"},{"to":" II","value":".2202693091569566","from":"Salud"},{"to":" III","value":".2409846787817388","from":"Salud"},{"to":" IV","value":".2544572765201404","from":"Salud"},{"to":" V","value":".2670647371073663","from":"Salud"},{"to":" VI","value":".2792706369424926","from":"Salud"},{"to":" VII","value":".2803576582078426","from":"Salud"},{"to":" VIII","value":".2823451836789561","from":"Salud"},{"to":" IX","value":".2818772406850603","from":"Salud"},{"to":" X","value":".2733970344248796","from":"Salud"},{"to":" I","value":".0067890664104048","from":" Salarios de gobiern"},{"to":" II","value":".0207765740063492","from":" Salarios de gobiern"},{"to":" III","value":".0510348807533167","from":" Salarios de gobiern"},{"to":" IV","value":".0624804319179407","from":" Salarios de gobiern"},{"to":" V","value":".0969818322745881","from":" Salarios de gobiern"},{"to":" VI","value":".1489082636619283","from":" Salarios de gobiern"},{"to":" VII","value":".2119889321124811","from":" Salarios de gobiern"},{"to":" VIII","value":".2209531391835658","from":" Salarios de gobiern"},{"to":" IX","value":".3719641340717652","from":" Salarios de gobiern"},{"to":" X","value":".5459902780375323","from":" Salarios de gobiern"},{"to":" I","value":".0217099447740191","from":"  Pension Bienestar"},{"to":" II","value":".0349506994327169","from":"  Pension Bienestar"},{"to":" III","value":".0470359916338538","from":"  Pension Bienestar"},{"to":" IV","value":".0596115904137666","from":"  Pension Bienestar"},{"to":" V","value":".0623254701115346","from":"  Pension Bienestar"},{"to":" VI","value":".0730445335947245","from":"  Pension Bienestar"},{"to":" VII","value":".0764194893542774","from":"  Pension Bienestar"},{"to":" VIII","value":".0754318093708503","from":"  Pension Bienestar"},{"to":" IX","value":".0788909842099076","from":"  Pension Bienestar"},{"to":" X","value":".0776902066420944","from":"  Pension Bienestar"},{"to":" I","value":".0964476841522592","from":"  Pensiones"},{"to":" II","value":".2178523486458412","from":"  Pensiones"},{"to":" III","value":".2522406731773612","from":"  Pensiones"},{"to":" IV","value":".3072249807494371","from":"  Pensiones"},{"to":" V","value":".3802008926776042","from":"  Pensiones"},{"to":" VI","value":".4624208970842236","from":"  Pensiones"},{"to":" VII","value":".5148109329229184","from":"  Pensiones"},{"to":" VIII","value":".650235355278808","from":"  Pensiones"},{"to":" IX","value":".6765415486876842","from":"  Pensiones"},{"to":" X","value":".6844346752318105","from":"  Pensiones"},{"to":" I","value":".1517170141808857","from":"   Infraestructura"},{"to":" II","value":".1605018934273417","from":"   Infraestructura"},{"to":" III","value":".1641557125871088","from":"   Infraestructura"},{"to":" IV","value":".1623486437428426","from":"   Infraestructura"},{"to":" V","value":".1649341487659334","from":"   Infraestructura"},{"to":" VI","value":".1665920088345146","from":"   Infraestructura"},{"to":" VII","value":".1891768895237974","from":"   Infraestructura"},{"to":" VIII","value":".1824091717892958","from":"   Infraestructura"},{"to":" IX","value":".1903926378012233","from":"   Infraestructura"},{"to":" X","value":".1836281293337769","from":"   Infraestructura"},{"to":"No distribuibles","value":"3.321656087757713","from":"Otros gastos"},{"to":"Estados y municipios","value":"4.62185742277152","from":"Otras Part y Aport"},{"to":"Sistema financiero","value":"3.014010023843029","from":"Costo de la deuda"}]
}';


*/



if(!$debug) header('Content-type: application/json; charset=utf-8');
if($debug) var_dump($respuesta);
if(!$debug) print($respuesta);
if($debug) print __LINE__ .'Falla';

?>
