<?php
$version = "5.1";
include_once("config.php");
$idSession = generaId();

// ENGINE (Stata model) version for the hero and footer: read from the
// "Version:" line of DEPLOYED_COMMIT (Phase 4 of publicar-vps.sh takes it from
// the `version` field of manifest.json and writes it into the docroot, next to
// this file). It means "which model version produced these numbers", not
// "which deploy is this". Fault tolerant: missing file, missing line or empty
// value -> empty $deployed_version and no version is rendered. Never a fatal.
$deployed_version = "";
$data_updated_iso = "";
$release_url = "";
$deployed_commit_file = __DIR__ . '/DEPLOYED_COMMIT';
if (is_readable($deployed_commit_file)) {
    $dc_lines = @file($deployed_commit_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($dc_lines !== false) {
        foreach ($dc_lines as $dc_line) {
            if (strpos($dc_line, 'Version:') === 0) {
                $deployed_version = trim(substr($dc_line, strlen('Version:')));
            } elseif (strpos($dc_line, 'DataUpdated:') === 0) {
                $data_updated_iso = trim(substr($dc_line, strlen('DataUpdated:')));
            } elseif (strpos($dc_line, 'ReleaseUrl:') === 0) {
                $release_url = trim(substr($dc_line, strlen('ReleaseUrl:')));
            }
        }
    }
}

// Pre-loaded DATA date for the hero ("Last update"): comes from
// manifest.data_updated (ISO YYYY-MM-DD, single source of truth), via the
// "DataUpdated:" line of DEPLOYED_COMMIT. Here it is only reformatted to
// MM/DD/YYYY. Safety net: if missing or not a valid date (regex + checkdate),
// the hardcoded date below is used — the data line is ALWAYS rendered.
$data_updated_display = '03/19/2026';
if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $data_updated_iso, $dm)
        && checkdate((int)$dm[2], (int)$dm[3], (int)$dm[1])) {
    $data_updated_display = $dm[2] . '/' . $dm[3] . '/' . $dm[1];
}

// Clickable version number (hero and footer): links to the exact GitHub
// Release of that version — a subtle open-source signal, not a CTA.
// ReleaseUrl: is derived by Phase 4 of the pipeline from
// manifest.release_url_prefix. Only linked if the URL starts with
// https://github.com/ (expected valid prefix); otherwise the version is
// rendered as plain text — never a broken href. Style: inherits the context
// color, discreet dotted underline.
$deployed_version_html = "";
if ($deployed_version !== "") {
    $deployed_version_html = htmlspecialchars($deployed_version);
    if (strpos($release_url, 'https://github.com/') === 0) {
        $deployed_version_html = '<a href="' . htmlspecialchars($release_url) . '" target="_blank" rel="noopener noreferrer" style="color: inherit; text-decoration: underline dotted;">' . $deployed_version_html . '</a>';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<!--meta name="viewport" content="width=device-width, initial-scale=1"-->
	<meta name="viewport" content="width=device-width, initial-scale=0.25">
	<link rel="icon" type="image/x-icon" href="favicon.ico">

	<meta name="description" content="CIEP Fiscal Simulator">
	<meta name="keywords" content="CIEP Fiscal Simulator">
	<meta name="author" content="CIEP - Ricardo Cantú Calderón">

	<!-- Title -->
	<title>CIEP Fiscal Simulator</title>

	<!-- Google tag (gtag.js) -->
	<script async src="https://www.googletagmanager.com/gtag/js?id=G-W4BCS1HL7G"></script>
	<script>
		window.dataLayer = window.dataLayer || [];
		function gtag(){dataLayer.push(arguments);}
		gtag('js', new Date());

		gtag('config', 'G-W4BCS1HL7G');
	</script>

	<!-- Styles -->
	<link href="https://fonts.googleapis.com/css?family=Lato:400,700,900&display=swap" rel="stylesheet">
	<link href="https://fonts.googleapis.com/css?family=Montserrat:400,500,700&display=swap" rel="stylesheet">
	<link href="https://fonts.googleapis.com/css?family=Material+Icons|Material+Icons+Outlined|Material+Icons+Two+Tone|Material+Icons+Round|Material+Icons+Sharp" rel="stylesheet">
	<link href="plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet">
	<link href="plugins/font-awesome/css/all.min.css" rel="stylesheet">

	<link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:ital,wght@0,200;0,300;0,400;0,600;0,700;1,200;1,300;1,400;1,600;1,700&display=swap" rel="stylesheet">

	<link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">

	<!-- FONTS -->
	<link rel="preconnect" href="https://fonts.gstatic.com">
	<link href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@500;700&display=swap" rel="stylesheet">

	<!-- Theme Styles -->
	<link href="css/connect.min.css" rel="stylesheet">
	<!--link href="css/admin2.css?v=14" rel="stylesheet"-->
	<link href="css/admin2.css?v=17" rel="stylesheet">
	<link href="css/animations.css?v=1" rel="stylesheet">
	<link href="css/custom.css" rel="stylesheet">

	<!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
	<!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
	<!--[if lt IE 9]>
	<script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
	<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
	<![endif]-->

	<style>
		.img-slider img {
			-webkit-filter: drop-shadow(-10px 10px 12px rgba(170, 130, 4, 0.8));
			filter: drop-shadow(-10px 10px 12px rgba(170, 130, 4, 0.8));
		}

		.suffix-percentage::after {
			display: flex;
			align-items: left;
			text-align: right;
			flex: 1;
			min-width: 0;
			border: none;
			background: none;
			content: "%";
		}
		
		.card-transparent.stats-card .stats-info {
			max-width: calc(100% - 50px);
		}
		/* EN: "EXPENDITURES" es más ancha que "GASTOS" — sin esto, "% GDP" baja
		   de línea. Se libera el hueco del stats-icon (estas tarjetas no lo
		   tienen) y se aprieta el margen del span del porcentaje. */
		#btn-gastos .stats-info,
		#btn-gastos_no .stats-info {
			max-width: 100%;
		}
		#btn-gastos .card-title span.stats-change,
		#btn-gastos_no .card-title span.stats-change {
			margin-left: 4px;
		}

		.tabla2 {
		}
		#home-top {
			display: block;
			width: 147px;
			height: 63px;
			overflow: hidden;
			padding-top: 6px;
		}
		#top-logo-ciep {
			width: 107px;
			height: auto;
		}
		.footer-box .nav-social li {
			margin-left: 20px;
		}

		#mac-txt {
			display:none;
			background-color: #fff;
			padding: 10px 10%;
		}
		#mac-txt p{
			text-align: center;
			font-size: 14px;
			color: #1b2959;
			margin-bottom: 0;
		}

		#box-ingresos .ui-tabs .ui-tabs-nav li,
		#box-gastos .ui-tabs .ui-tabs-nav li        {
			padding: 2px 2px !important;
		}

		#box-gastos .ui-tabs .ui-tabs-nav li em,
		#box-ingresos .ui-tabs .ui-tabs-nav li em {
			padding: 0px 2px 1px 5px !important;
			background-color: #ff1452;
			color: #fff;
			font-style: normal;
			border-radius: 4px 10px 4px 10px !important;
			position: relative;
			top: -2px;
			right: -2px;
			font-size: 13px;
			letter-spacing: -1px;
			pointer-events: none;
		}
		#box-ingresos .ui-tabs .ui-tabs-nav li em {
			background-color: #a6ea00;
		}
		#box-gastos .ui-tabs .ui-tabs-nav li em {
			background-color: #ff1452;
		}
		.range-info {
			width: 24%;
		}
		.range-slider {
			width: 19%;
			padding: 0 4px;
		}
		span.anio, span.crecimiento {
			margin-top: 0;
		}
		.tabla-res-ingresos input {
			width: 70px;
			padding: 4px 4px;
		}
		.tableizer-table.t-extra td {
			line-height: 1.34;
		}
		.stats-text.idDeuda {
			line-height: 0.9em;
			text-align: center;
			margin-top: 0;
			padding-bottom: 2px;
			padding-right: 11px;
			padding-left: 12px;
			font-size: 12px;
		}
		.stats-card .stats-text.idDeuda.txt-ingresos {
			padding: 4px 12px;
		}
		.formula .stats-card .stats-text.idDeuda {
			padding: 4px 12px;
		}
		.stats-text.idDeuda em {
			font-size: 85%;
		}
		.formula .card .card-body.card-deuda {
			padding: 16px 25px 15px 25px;
		}
		.card-deuda .card-title {
			bottom: 8px;
		}
		.table-striped tr td:nth-last-child(1) {
			text-align: right;
			padding-right: 20px;
		}
		.table-striped tr.tr-total td:nth-last-child(1) input {
			width: 100%;
			padding-right: 0px;
		}
		.custom-checkbox {
			margin-top: 0;
		}
		.btn-modificar {
			padding: 2px 7px;
			margin-top: -1px;
		}
		.table td, .table th {
			vertical-align: middle;
		}
		.table thead th {
			line-height: 1.42em;
			padding-top: 3px;
		}
		.table-proyeccion tr td:nth-last-child(1),
		.table-proyeccion tr td:nth-last-child(2) {
			padding: 2px 10px 1px 10px;
		}
		#formula-fija .stats-card .stats-text.txt-ingresos,
		#formula-fija .stats-card .stats-text.txt-gastos    {
			display: block;
			text-align: center;
			padding-left: 0;
			padding-right: 0;
			width: 73px !important;
			margin-left: auto;
			margin-right: auto;
		}
		#formula-fija .stats-card .stats-text.idDeuda.txt-ingresos {
			font-size:0;
		}
		.stats-card .stats-text.idDeuda.txt-ingresos {
			font-size: 0;
		}
		.stats-card .idDeuda.txt-ingresos:before {
			font-size: 13px;
			line-height: 1.8em;
		}
		#formula-fija .stats-card .stats-text.idDeuda.txt-gastos    {
			width: 120px !important;
		}
		#formula-fija .stats-card .stats-text {
			font-size: 9px;
			line-height: 1.5em;
			margin-bottom: -5px;
			margin-top: 1px;
		}
		#formula-fija .stats-card .card-title {
			font-size: 18px;
		}
		#formula-fija .stats-card .stats-change {
			font-size: 12px;
		}
		/* Que "% GDP" no baje de línea con números largos (p.ej. -10.324 del
		   endeudamiento): sin quiebre en el título, margen del span apretado
		   y sin el hueco reservado al stats-icon que estas tarjetas no usan. */
		#formula-fija .stats-card .card-title {
			white-space: nowrap;
		}
		#formula-fija .stats-card .card-title span.stats-change {
			margin-left: 4px;
		}
		#formula-fija .stats-card .stats-info {
			max-width: 100%;
		}
		#formula-fija #menos {
			left: 30.6%;
		}
		#formula-fija #igual {
			left: 42.6%;
		}
		#formula-fija .deuda-percapita .stats-card .stats-text {
			font-size: 12px;
			line-height: 1.0em;
			margin-bottom: -2px;
			margin-top: 7px;
			color: #5c6662;
			background: transparent;
			padding-left: 0;
			letter-spacing: 0px;
			text-align: left;
			padding-right: 0;
			font-weight: 500;
			display: block;
		}
		#formula-fija .formula .card-body {
			padding: 4px 10px 4px 10px;
		}
		#formula-fija {
			padding: 7px 0px 6px 0px;
		}
		#formula-fija .card .card-body {
			text-align: center !important;
		}
		#formula-fija .stats-card .stats-icon {
			padding: 0;
			position: relative;
			right: 0;
			top: unset;
			margin: 0;
			bottom: -10px;
			left: -5px;
		}
		#formula-fija .material-icons {
			font-size: 23px;
		}
		#formula-fija #igual {
			top: 10px;
		}
		#formula-fija #menos {
			top: 22px;
		}
		#donation {
			background-color: #FFDE42 !important;
			padding-bottom: 0 !important;
		}

		#donation .columna-1  {
			padding-right: 40px;
			padding-top: 30px;
		}
		#donation .columna-3  {
			padding-left: 50px;
			padding-top: 10px;
		}
		#donation .row-2 {
			background-color: #FFDE42 !important;
		}
		#donation h2{
			color: #171826;
			font-size: 38px;
			font-weight: 800;
			text-align: right;
			margin-bottom: 20px;
			line-height: 1.1em;
		}
		#donation p{
			text-align: right;
			color: #3A3A3A;
			font-size: 17px !important;
			font-weight: 400;
			line-height: 1.3em;
		}
		#donation .columna-3 h3 {
			color: #393E43;
			font-size: 19px !important;
			font-weight: 700;
			line-height: 1.2em;
			text-align: center;
		}
		#donation .columna-3 p {
			color: #393E43;
			font-size: 13px !important;
			font-weight: 400;
			line-height: 1.4em;
			text-align: center;
		}
		#donation .columna-3 #opcion-2 p {
			text-align: left !important;
			font-size: 14px !important;
			margin-top: 20px;
		}
		#tabs-donaciones.ui-widget.ui-widget-content {
			background: transparent;
		}
		#tabs-donaciones.ui-tabs .ui-tabs-nav li.ui-tabs-active {
			color: #171826;
			border: 0;
			border-bottom: 4px solid #FF7121 !important;
			padding: 13px 18px !important;
			font-size: 19px;
			font-weight: 700;
			border-radius: 0 !important;
			background: transparent !important;
			box-shadow: 0px !important;
		}
		#tabs-donaciones.ui-tabs .ui-tabs-nav li {
			color: #171826;
			border: 0;
			padding: 13px 18px !important;
			font-size: 19px;
			font-weight: 700;
			border-radius: 0 !important;
			background: transparent !important;
			box-shadow: -1px 2px 2px rgb(31 45 61 / 0%);
		}
		#tabs-donaciones table {
			width: 100%;
		}
		#tabs-donaciones table td {
			text-align: center;
			padding-top: 10px;
		}
		#tabs-donaciones table a {
			font-size: 15px;
			font-weight: 600;
			color: #393E43;
			background-color: #F6F6F6;
			border-style: solid;
			border-width: 1px 1px 1px 1px;
			border-color: #ECECEC;
			border-radius: 4px 4px 4px 4px;
			padding: 8px 0px 8px 0px;
			box-shadow: -2px 3px 3px 0px rgb(0 0 0 / 9%);
			width: 90%;
		}
		#tabs-donaciones table a:hover {
			color: #FFFFFF;
			background-color: #FF7121 !important;
			border-color: #EE6011;
		}
		#tabs-donaciones .btn-outline-primary:before {
			background: transparent !important;
			display: none;
		}
		.ui-tabs .ui-tabs-nav li {
			box-shadow: 0;
		}
		#tabs-donaciones.ui-tabs .ui-tabs-nav li.ui-tabs-active .ui-tabs-anchor,
		#tabs-donaciones.ui-tabs .ui-tabs-nav li .ui-tabs-anchor  {
			padding: 0 !important;
		}
		#box-gastos .ui-tabs .ui-tabs-nav li {
			margin-right: 2px;
		}
		.ui-tabs .ui-tabs-nav .ui-tabs-anchor {
			padding-right: 0;
		}

		.modal p {
			line-height: 1.3em;
			margin-bottom: 0.3em;
		}
		#sankey-num1, #sankey-num2, #sankey-num3, #sankey-num4, #sankey-num5 {
			z-index: -10;
			position: absolute;
			width: 100%;
			top: 34px;
			height: 600px;
		}
		#sankey-1, #sankey-2, #sankey-3, #sankey-4, #sankey-5 {
			height: 600px;
			padding-right: 4%;
			background: #fff;
		}
		#sankey-num1.visible, #sankey-num2.visible, #sankey-num3.visible, #sankey-num4.visible, #sankey-num5.visible  {
			z-index: 1;
		}
		.pobla {
			padding: 1px 0px 6px 0px;
		}
		.percapita {
			padding: 1px 0px 3px 0px;
		}
		.card-gastos .percapita .form-control {
			padding: 1px 13px;
			height: 23px;
			float: none;
		}
		#educacion  table td {
			padding-top: 2px;
			padding-bottom: 2px;
		}
		.table th a {
			background-color: #ffe719;
			padding: 2px 4px;
			border-radius: 3px;
		}
		.table th a:after {
			content:'→';
			margin-left: 4px;
			top: -1px;
		}

		.input-group {
			position: relative;
		}

		.input-group::after {
			content: '%';
			position: absolute;
			right: -10px;
			top: 50%;
			transform: translateY(-50%);
		}

		.pre-signo::before {
			content: '/';
			position: absolute;
			left: -25px;
			font-size: 21px;
		}
		.pre-signo {
			left: 15px;
		}
		.post-signo::before {
			content: '=';
			position: absolute;
			left: -25px;
			font-size: 21px;
			color: #333333;
			font-family: 'Roboto Mono', monospace;
		}
		.pre-signo-2::before {
			content: '/';
			position: absolute;
			left: -28px;
			font-size: 21px;
		}
		.post-signo-2::before {
			content: '=';
			position: absolute;
			left: -15px;
			bottom: 10px;
			font-size: 21px;
			color: #333333;
			font-family: 'Roboto Mono', monospace;
		}
		.en-amarillo {
			background-color: #ffe719;
			padding: 1px 4px 1px 4px;
			border-radius: 3px;
			color: #333333;
			font-style: normal;
			font-weight: 600;
		}
		.horizontal-line td {
			padding-top: 0;
			padding-bottom: 0;
		}
		.horizontal-line hr {
			margin-top: 0;
			margin-bottom: 0;
			border: 0;
			border-top: 1px solid black;
		}
		.table tbody tr {
			margin-bottom: 0;
		}
		.vertical-center {
			vertical-align: middle !important;
		}
		.non-editable {
        	background-color: #e9ecef; /* Light gray background */
        	cursor: not-allowed; /* Change cursor to indicate non-editable */
    	}
		/* Per cápita control buttons */
		.percapita-control {
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 4px;
		}
		.percapita-value {
			flex: 1;
			text-align: center;
			min-width: 60px;
		}
		.btn-percapita {
			width: 24px;
			height: 24px;
			padding: 0;
			border: 1px solid #ccc;
			border-radius: 4px;
			background: #f8f8f8;
			color: #333;
			font-size: 14px;
			font-weight: bold;
			cursor: pointer;
			transition: all 0.2s ease;
			display: flex;
			align-items: center;
			justify-content: center;
		}
		.btn-percapita:hover {
			background: #e0e0e0;
			border-color: #999;
		}
		.btn-percapita.btn-up:hover {
			background: #d4edda;
			border-color: #28a745;
			color: #28a745;
		}
		.btn-percapita.btn-down:hover {
			background: #f8d7da;
			border-color: #dc3545;
			color: #dc3545;
		}
		.btn-percapita:active {
			transform: scale(0.95);
		}
		/* Tasa efectiva control buttons */
		.tasa-control {
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 4px;
		}
		.tasa-value {
			flex: 1;
			text-align: center;
			min-width: 40px;
		}
		.btn-tasa {
			width: 20px;
			height: 20px;
			padding: 0;
			border: 1px solid #ccc;
			border-radius: 4px;
			background: #f8f8f8;
			color: #333;
			font-size: 12px;
			font-weight: bold;
			cursor: pointer;
			transition: all 0.2s ease;
			display: flex;
			align-items: center;
			justify-content: center;
		}
		.btn-tasa:hover {
			background: #e0e0e0;
			border-color: #999;
		}
		.btn-tasa.btn-up:hover {
			background: #d4edda;
			border-color: #28a745;
			color: #28a745;
		}
		.btn-tasa.btn-down:hover {
			background: #f8d7da;
			border-color: #dc3545;
			color: #dc3545;
		}
		.btn-tasa:active {
			transform: scale(0.95);
		}
		/* Marco macro control buttons */
		.macro-control {
			display: flex;
			align-items: center;
			gap: 2px;
		}
		.macro-value {
			flex: 1;
			text-align: center;
			padding: 2px 4px !important;
			width: 50px !important;
		}
		.btn-macro {
			width: 18px;
			height: 18px;
			padding: 0;
			border: 1px solid #ccc;
			border-radius: 3px;
			background: #f8f8f8;
			color: #333;
			font-size: 11px;
			font-weight: bold;
			cursor: pointer;
			transition: all 0.2s ease;
			display: flex;
			align-items: center;
			justify-content: center;
			flex-shrink: 0;
		}
		.btn-macro:hover {
			background: #e0e0e0;
			border-color: #999;
		}
		.btn-macro.btn-up:hover {
			background: #d4edda;
			border-color: #28a745;
			color: #28a745;
		}
		.btn-macro.btn-down:hover {
			background: #f8d7da;
			border-color: #dc3545;
			color: #dc3545;
		}
		.btn-macro:active {
			transform: scale(0.95);
		}
		/* Toggle buttons for 2027/Simulation */
		.toggle-data-btns {
			display: inline-flex;
			gap: 0;
			margin-bottom: 15px;
			border-radius: 4px;
			overflow: hidden;
			box-shadow: 0 1px 3px rgba(0,0,0,0.12);
		}
		.toggle-data-btns .btn-toggle {
			padding: 6px 14px;
			font-size: 12px;
			font-weight: 600;
			border: 1px solid #ddd;
			background: #f5f5f5;
			color: #666;
			cursor: pointer;
			transition: all 0.2s ease;
			margin: 0;
			border-radius: 0;
			opacity: 0.5;
			position: relative;
		}
		.toggle-data-btns .btn-toggle:first-child {
			border-right: none;
			border-radius: 4px 0 0 4px;
		}
		.toggle-data-btns .btn-toggle:last-child {
			border-radius: 0 4px 4px 0;
		}
		.toggle-data-btns .btn-toggle:hover {
			background: #e8e8e8;
			opacity: 0.7;
		}
		.toggle-data-btns .btn-toggle.active {
			background: #1b2959;
			color: #fff;
			border-color: #1b2959;
			opacity: 1;
		}
		.toggle-data-btns .btn-toggle.active::after {
			content: '';
			position: absolute;
			top: 0;
			right: 0;
			width: 0;
			height: 0;
			border-style: solid;
			border-width: 0 16px 16px 0;
			border-color: transparent #ffcb01 transparent transparent;
		}
		.toggle-data-btns .btn-toggle.active:hover {
			background: #2a3a6a;
		}
		.resultado-header {
			display: flex;
			flex-direction: row;
			justify-content: space-between;
			align-items: center;
			margin-bottom: 10px;
		}
		.resultado-header .card-title {
			margin-bottom: 0;
		}
		.toggle-data-btns .btn-toggle.btn-disabled {
			opacity: 0.3;
			cursor: not-allowed;
		}
	</style>
</head>

	<body>
        <!--div class='cargando' style="visibility:visible; display:block;width:100px;height:50px;color:#000;text-height:max-size;background-color:#FFF;">
                <span class=''>¡Ejecitando! espere ....</span>
        </div-->

		<!--div id="mac-txt"><p>Has sido redireccionado a <b>simuladorfiscal.ddns.net</b> para tener una mejor visualización desde tu dispositivo iOS</p></div-->

		<div class="cargando-notify" id="cargando-notify">
			<div class="spinner-grow text-primary" role="status">
				<span class="sr-only">Loading...</span>
			</div>
			<div class="cargando-text">
				Calculating… <b id="count">30</b>s
			</div>
		</div>

        <div class='loader'>
            <div class='spinner-grow text-primary' role='status'>
                <span class='sr-only'>Loading...</span>
            </div>
        </div>

		<!--div class="toast fade show slide-top-reverse" id="box-actualizar" role="alert" aria-live="assertive" aria-atomic="true">
			<div class="toast-header">
				<strong class="mr-auto">Actualizar valores </strong>
				<small></small>
				<button type="button" class="ml-2 mb-1 close cerrar-actualizar" data-dismiss="toast" aria-label="Close">
					<i class="material-icons">close</i>
				</button>
			</div>
			<div class="toast-body text-dark">
				<button type="button" class="btn btn-primary btn-yellow mt-0 mb-2 cerrar-actualizar w-100" id="btn-actualizar">Actualizar <small>(4sec)</small></button>
				<button type="button" class="btn btn-primary btn-yellow mt-0 mb-0 cerrar-actualizar w-100" id="btn-reestablecer">Reset</button>
			</div>
        </div-->


        <div class="connect-container align-content-stretch d-flex flex-wrap">

            <div class="page-container" style="padding-bottom: 35px;">
				<h6 class="txt-br">THE FISCAL SYSTEM</h6>
                <div class="page-header">
                    <nav class="navbar navbar-expand container">
						<a class="internalLink logo-box" id="home-top" href="#">
            				<img src="images/logo-sim-fiscal-ciep-b.png" width="138" height="146" alt="Simulador Fiscal">
            			</a>
                        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                            <span class="navbar-toggler-icon"></span>
                        </button>

                        <div class="collapse navbar-collapse" id="navbarNav">
                            <ul class="navbar-nav">
                                <!--li class="nav-item">
                                    <a href="#" class="nav-link">Introducción</a>
                                </li-->
                                <!--li class="nav-item">
                                    <a href="#" class="nav-link">Paquete Económico</a>
                                </li-->
                                <li class="nav-item">
                                    <a href="https://ciep.mx/" target="_blank" class="nav-link">
										<img id="top-logo-ciep" src="images/ciep-logo1.png">
									</a>
                                </li>
                            </ul>
                        </div>

						<div class="navbar-search">
							<form>
								<div class="form-group tutorial-btn">
									<a href="#libro-simulador" class="btn btn-outline-primary">The simulator book</a>
								</div>
							</form>
						</div>
						<ul class="navbar-nav nav-social">
                            <li class="nav-item">
                                <a href="http://facebook.com/ciepmx" target="_blank"><img class="social-icon i-face" src="images/f-icon-facebook.svg"></a>
                            </li>
                            <li class="nav-item">
                                <a href="https://twitter.com/ciepmx" target="_blank"><img class="social-icon" src="images/f-icon-twitter.svg"></a>
                            </li>
                            <li class="nav-item">
                                <a href="https://www.youtube.com/user/CIEPMX" target="_blank"><img class="social-icon" src="images/f-icon-youtube.svg"></a>
                            </li>
                        </ul>

						<div id="lang">
							<?php $host = $_SERVER['HTTP_HOST']; $isLocalhost = (strpos($host, 'localhost') !== false || strpos($host, '127.0.0.1') !== false); ?>
							<a href="<?php echo $isLocalhost ? 'index.php' : 'https://simuladorfiscal.ciep.mx/index.php'; ?>" class="lang-item" id="es"><img src="images/lang-es.svg"></a>
							<a href="<?php echo $isLocalhost ? 'index-en.php' : 'https://simuladorfiscal.ciep.mx/index-en.php'; ?>" class="lang-item active" id="en"><img src="images/lang-en.svg"></a>
						</div>
                    </nav>
                </div>

				<div id="formula-fija">
					<div class="formula container">
                            <div class="col-lg-8 col-md-8">
								<div class="row">
									<div class="col-lg-4 col-md-12">
										<div class="card card-transparent stats-card" id="btn-ingresos_no">
											<div class="card-body">
												<div class="stats-info">
													<p class="stats-text txt-ingresos">REVENUES</p>
													<h5 class="card-title" ><span class="INGRESOSTOTAL">20.8%</span><span class="stats-change stats-change-danger" style="margin-left: 3px;">% GDP</span></h5>
												</div>
											</div>
										</div>
									</div>
									<div id="menos"></div>
									<div class="col-lg-4 col-md-12">
										<div class="card card-transparent stats-card" id="btn-gastos_no">
											<div class="card-body">
												<div class="stats-info">
													<p class="stats-text txt-gastos" style="letter-spacing: 0px; padding: 0px 5px;">EXPENDITURES</p>
													<h5 class="card-title"><span class="GASTOSTOTAL">23.0%</span><span class="stats-change stats-change-success">% GDP</span></h5>
												</div>
											</div>
										</div>
									</div>

									<div class="col-lg-4 col-md-12">
										<div class="card card-transparent stats-card" style="min-width: 220px;">
											<div class="card-body">
												<div class="stats-info">
													<p class="stats-text idDeuda">IN-DEBT-ED-NESS</p>
													<h5 class="card-title"><span class="DEUDA">2.2%</span><span class="stats-change stats-change-success" style="margin-left: 3px;">% GDP</span></h5>
												</div>
											</div>
										</div>
									</div>

								</div>
                            </div>
							<div id="igual">
								<div class="lineas"></div>
								<div class="lineas"></div>
							</div>
                            <div class="col-lg-4 col-md-12 deuda-percapita">
								<div class="row">
									<div class="col-lg-6 col-md-12">
										<div class="card card-transparent stats-card">
											<div class="stats-info">
												<p class="stats-text">DEBT per capita <span style="font-size: 1.2em; font-weight: bold;">2027</span></p>
												<h5 class="card-title"><span class="DEUDATOTAL ">$<span class="PROYSHRFSP3">300,000</span></h5>
											</div>
										</div>
									</div>
									<div class="col-lg-6 col-md-12">
										<div class="card card-transparent stats-card">
											<div class="stats-info">
												<p class="stats-text">DEBT per capita <span style="font-size: 1.2em; font-weight: bold;">2032</span></p>
												<h5 class="card-title"><span class="DEUDATOTAL">$<span class="PROYSHRFSP3">300,000</span></span></h5>
											</div>
										</div>
									</div>
								</div>

                            </div>
					</div>
				</div>


				<!-- Slider -->
				<div class="resultados dark-theme resultado-0 base-blanca" style="padding-bottom: 38px !important;">
					<div class="page-container">

						<div id="carouselExampleIndicators" class="carousel slide" data-ride="carousel">

						  <ol class="carousel-indicators">
							<li data-target="#carouselExampleIndicators" data-slide-to="0" class="active"></li>
							<li data-target="#carouselExampleIndicators" data-slide-to="1"></li>
							<li data-target="#carouselExampleIndicators" data-slide-to="2"></li>
							<li data-target="#carouselExampleIndicators" data-slide-to="3"></li>
					</ol>

					<div class="carousel-inner">

						<div class="carousel-item active">
							<div class="main-wrapper container box-resultados">
								<div class="row align-items-center">
									<div class="col-xl-5 pr-0">
										<h2 data-shadow="CIEP Fiscal Simulator" class="card-title">CIEP Fiscal Simulator</h2>
										<p class="card-text">A digital and interactive tool that allows you to <span class="txt-bold">design and simulate your own fiscal policies</span>, evaluating their effects on income redistribution and long-term fiscal sustainability.</p>
										<p class="card-text txt-bold text-3-pasos">FOLLOW 2 SIMPLE STEPS  <i class="fas fa-arrow-right f-right"></i></p>
									<?php /* Simulator version = ENGINE version (manifest.json, via DEPLOYED_COMMIT) — SEPARATE from "Last update" (data date, semi-manual). Only rendered if a version exists; never breaks the page. */ ?>
									<p style="font-size: 0.9rem;">Pre-loaded values are from the <span class="txt-bold">2027 Budget</span>.<br>Last update: <?php echo htmlspecialchars($data_updated_display); ?>.<?php if ($deployed_version_html !== "") { echo '<br>Simulator version: ' . $deployed_version_html . '.'; } ?></p>
									</div>
									<div class="col-xl-7 pl-5 img-slider text-center">
										<img src="images/top-slide-0-v2b.png" alt=" ">
									</div>
								</div>
							</div>
						</div>

						<div class="carousel-item">
							<div class="main-wrapper container box-resultados">
								<div class="row align-items-center">
									<div class="col-xl-4">
										<h2 data-shadow="Step 1." class="card-title title-small">Step 1.</h2>
										<h2 data-shadow="Modify the policies" class="card-title">Modify the policies</h2>
										<p class="card-text"><span class="txt-ingresos">REVENUES</span> are expressed in <span class="txt-bold">effective rates</span>: how much do you want to collect from the taxable base?<br><br><span class="txt-gastos">EXPENDITURES</span> are expressed in <span class="txt-bold">per capita values</span>: how much do you want to deliver to each beneficiary?</p>
										<p style="font-size: 0.9rem;">The <span class="txt-ingresos" style="background-color:#f7f7f7; box-shadow: -1px 2px 2px rgba(31, 45, 61, .08);">Change</span> buttons allow you to modify specific parameters.</p>
									</div>
									<div class="col-xl-8 pl-5 img-slider text-center">
										<img src="images/top-slide-1-v2b.png" alt=" ">
									</div>
								</div>
							</div>
						</div>


						<div class="carousel-item">
							<div class="main-wrapper container box-resultados">
								<div class="row align-items-center">
									<div class="col-xl-4">
										<h2 data-shadow="Step 2." class="card-title title-small">Step 2.</h2>
										<h2 data-shadow="Calculate and review" class="card-title">Calculate and review</h2>
										<p class="card-text"><span class="txt-bold">Press</span> the <span class="txt-calcular">Calculate</span> button to see the results of your proposals on income redistribution and fiscal sustainability.</p>
									</div>
									<div class="col-xl-8 pl-5 img-slider text-center">
										<img src="images/top-slide-3-v2b.png" alt=" ">
									</div>
								</div>
							</div>
						</div>

						<div class="carousel-item">
							<div class="main-wrapper container box-resultados">
								<div class="row align-items-center">
									<div class="col-xl-4">
										<h2 data-shadow="Remember:" class="card-title title-small">Remember:</h2>
										<h2 data-shadow="REVENUES minus EXPENDITURES equals DEBT" class="card-title"><b class="verde-ingresos">REVENUES</b> minus <b class="rojo-gasto">EXPENDITURES</b> equals <b class="gris-deuda">DEBT</b></h2>
										<p class="card-text">Analyze and reflect on your results.</p> <p class="card-text"><span class="txt-bold">Dare</span> to design your own public policies.</p>
									</div>
									<div class="col-xl-8 pl-5 img-slider text-center">
										<img src="images/top-slide-4-v2b.png" alt=" ">
									</div>
								</div>
							</div>
						</div>

					</div>

						</div>


					</div>
				</div>


                <div class="page-content" id="parametros-box">

                    <div class="main-wrapper container" style="padding-top: 0; margin-top: -46px; z-index: 9;">

                        <div class="row stats-row formula">
                            <div class="col-lg-8 col-md-12">
								<div class="row">
									<div class="col-lg-6 col-md-12">
										<div class="card card-transparent stats-card" id="btn-ingresos">
											<div class="card-body pulsate-fwd card-active">
												<div class="stats-info">
													<p class="stats-text txt-ingresos">REVENUES</p>
													<h5 class="card-title"><span class="INGRESOSTOTAL">20.8%</span><span class="stats-change stats-change-danger" style="margin-left: 3px;">% GDP</span></h5>
												</div>
											</div>
										</div>
									</div>
									<div id="menos"></div>
									<div class="col-lg-6 col-md-12">
										<div class="card card-transparent stats-card" id="btn-gastos">
											<div class="card-body pulsate-fwd">
												<div class="stats-info">
													<p class="stats-text txt-gastos" style="letter-spacing: 0px; padding: 0px 5px;">EXPENDITURES</p>
													<h5 class="card-title"><span class="GASTOSTOTAL">23.0%</span><span class="stats-change stats-change-success">% GDP</span></h5>
												</div>
											</div>
										</div>
									</div>
								</div>
                            </div>
							<div id="igual">
								<div class="lineas"></div>
								<div class="lineas"></div>
							</div>
                            <div class="col-lg-4 col-md-12">
                                <div class="card card-transparent stats-card">
                                    <div class="card-body card-fixed card-deuda">
                                        <div class="stats-info">
										<p class="stats-text idDeuda txt-gastos" style="#000"><em>in</em><br>DEBT<br><em>ness</em></p>
                                            <h5 class="card-title"><span class="DEUDA">2.2%</span><span class="stats-change stats-change-success" style="margin-left: 3px;">% GDP</span></h5>

                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

						<div id="trigger-fix"></div>

                           <form name="FormGastos">
						   <input type="hidden" value="<?php echo $idSession; ?>" name="idSession" id="idSession">
						   <input type="hidden" value="" name="moduloCambio" id="moduloCambio">
						   <input type="hidden" value="" name="moduloCambioIva" id="moduloCambioIva">
                           <div class="row mt-4">
                              <div class="col-lg-8">
                                <div class="card card-transactions card-ingresos slide-top" style="zoom: 1;" id="box-ingresos">
                                    <div class="card-body">
										<div id="tabs" class="card-ingresos">
											<ul>
												<li><em>1.</em><a href="#ingreso"><span>Labor<br>Taxes</span></a></li>
												<li><em>2.</em><a href="#consumo"><span>Consumption<br>Taxes</span></a></li>
												<li><em>3.</em><a href="#capital"><span>Capital<br>Taxes</span></a></li>
												<li><em>4.</em><a href="#organismos"><span>Public<br>Enterprises</span></a></li>
											</ul>

											<div id="ingreso">
												<div>
													<h3>1 - LABOR INCOME TAXES</h3>
													<div class="table-responsive">
														<table class="table table-striped new_table-striped">
															<thead>
																<tr>
																	<th scope="col" width="39%" class="vertical-center">Tax</th>
																	<th scope="col" class="vertical-center"><a href="https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/paquete_economico/ilif/ilif_2027.pdf" target="_blank" class="icon-link">REVENUE<br>(% GDP)</a></th>
																	<th scope="col" width="44%" class="vertical-center"><a href="https://www.inegi.org.mx/app/indicadores/?tm=3" target="_blank" class="icon-link pre-signo">National Account</a></th>
																	<th scope="col" class="vertical-center post-signo"><a href="images/TE_Trabajo.png" data-toggle="lightbox">Effective Rates</a></th>
																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte vertical-center"><b>PIT (wage earners)</b><button type="button" class="btn btn-modificar btn-sm" data-toggle="modal" data-target="#Modal-ISR-1" id="ISRsalarios">Change</button></td>
																	<td class="new vertical-center"><input type="number" class="form-control INGRESOS" id="INGRESOS0" name="INGRESOS0" value="0.000" step=".001" min="0" max="100" required></input></td>
																	<td class="vertical-center">Employee compensation<br>(30.246% GDP)</td>
																	<td class="vertical-center">
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS0" data-base="30.246">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF0" name="INGRESOSTEF0">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS0" data-base="30.246">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte vertical-center"><b>PIT (self-employed)</b><button type="button" class="btn btn-modificar btn-sm" data-toggle="modal" data-target="#Modal-ISR-1" id="ISRfisicas">Change</button></td>
																	<td class="new vertical-center"><input type="number" class="form-control INGRESOS" id="INGRESOS1" name="INGRESOS1" value="0.000" step=".001" min="0" max="100" required></td>
																	<td class="vertical-center">Mixed labor income<br>(14.043% GDP)</td>
																	<td class="vertical-center">
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS1" data-base="14.043">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF1" name="INGRESOSTEF1">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS1" data-base="14.043">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte vertical-center"><b>IMSS contributions</b><br><button type="button" class="btn btn-modificar btn-sm" data-toggle="modal" data-target="#Modal-cuotas-imss" id="cuotas-imss">Change</button></td>
																	<td class="new vertical-center"><input type="number" class="form-control INGRESOS" id="INGRESOS2" name="INGRESOS2" value="0.000" step=".001" min="0" max="100" required></td>
																	<td class="vertical-center">Employee compensation<br>(30.246% GDP)</td>
																	<td class="vertical-center">
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS2" data-base="30.246">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF2" name="INGRESOSTEF2">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS2" data-base="30.246">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td class="vertical-center">Total</td>
																	<td class="new vertical-center"><input type="number" class="form-control INGRESOS" id="INGRESOS3" name="INGRESOS3" readonly value="0.000"></td>
																	<td class="vertical-center">Labor income<br>(44.289% GDP)</td>
																	<td class="vertical-center">
																		<div class="input-group">
																			<input style="padding-left: 0; width:60px;" type="text" class="form-control INGRESOSTEF" readonly value="0.0" id="INGRESOSTEF3" name="INGRESOSTEF3">
																		</div>
																	</td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about income taxes and the tax system, visit the CIEP microsite <a href="https://ingresosenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Ingresos p&uacute;blicos en M&eacute;xico</a> (in Spanish).</p>
													</div>
												</div>
											</div>
											<div id="capital">
												<div>
													<h3>3 - CAPITAL TAXES</h3>
													<div class="table-responsive">
														<input type="hidden" name="idSession" id="idSession" value="<?php print $idSession;?>">
														<table class="table table-striped">
															<thead>
																<tr>
																	<th scope="col" width="39%" class="vertical-center">Tax</th>
																	<th scope="col" class="vertical-center"><a href="https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/paquete_economico/ilif/ilif_2027.pdf" target="_blank" class="icon-link">REVENUE<br>(% GDP)</a></th>
																	<th scope="col" width="43%" class="vertical-center"><a href="https://www.inegi.org.mx/app/indicadores/?tm=3" target="_blank" class="icon-link pre-signo">National Account</a></th>
																	<th scope="col" class="vertical-center post-signo"><a href="images/TE_Capital.png" data-toggle="lightbox">Effective Rates</a></th>																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte"><b>CIT (corporations)</b>
																		<button type="button" class="btn btn-modificar btn-sm" data-toggle="modal" data-target="#Modal-ISR-2">Change</button>
																	</td>
																	</td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS4" name="INGRESOS4" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Private capital income<br>(32.855% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS4" data-base="32.855">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF4" name="INGRESOSTEF4">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS4" data-base="32.855">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Products, fees and revenues</b>
																		<div class="limpiar"></div>
																	</td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS5" name="INGRESOS5" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Private capital income<br>(32.855% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS5" data-base="32.855">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF5" name="INGRESOSTEF5">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS5" data-base="32.855">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Mexican Oil Fund</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS15" name="INGRESOS15" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS15" data-base="36.456">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF15" name="INGRESOSTEF15">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS15" data-base="36.456">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td>Total</td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS6" name="INGRESOS6" readonly value="0.000"></td>
																	<td>Private capital income<br>(32.855% GDP)</td>
																	<td>
																		<div class="input-group">
																			<input type="text" class="form-control INGRESOSTEF" id="INGRESOSTEF6" name="INGRESOSTEF6" readonly value="0.000">
																		</div>
																	</td>
																</tr>
															</tbody>
											</table>
								<p class="notas">The Mexican Oil Fund is considered a tax paid by both assignees and contractors.

														<br>
														<p class="notas">To learn more about tax revenue and capital taxes, visit the CIEP microsite <a href="https://ingresosenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Ingresos p&uacute;blicos en M&eacute;xico</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="consumo">
												<div>
													<h3>2 - CONSUMPTION TAXES</h3>
													<div class="table-responsive">
														<table class="table table-striped">
															<thead>
																<tr>
																	<th scope="col" width="39%" class="vertical-center">Tax</th>
																	<th scope="col" class="vertical-center"><a href="https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/paquete_economico/ilif/ilif_2027.pdf" target="_blank" class="icon-link">REVENUE<br>(% GDP)</a></th>
																	<th scope="col" width="43%" class="vertical-center"><a href="https://www.inegi.org.mx/app/indicadores/?tm=3" target="_blank" class="icon-link pre-signo">National Account</a></th>
																	<th scope="col" class="vertical-center post-signo"><a href="images/TE_Consumo.png" data-toggle="lightbox">Effective Rates</a></th>
																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte"><b>IVA</b><br>
																		<button type="button" class="btn btn-modificar btn-sm" data-toggle="modal" data-target="#Modal-IVA" id="IVAiva">Change</button>
																	</td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS7" name="INGRESOS7" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Household consumption<br>(71.791% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS7" data-base="71.791">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF7" name="INGRESOSTEF7">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS7" data-base="71.791">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>ISAN</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS8" name="INGRESOS8" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Vehicle purchases<br>(2.484% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS8" data-base="2.484">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF8" name="INGRESOSTEF8">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS8" data-base="2.484">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>IEPS (no petrolero)</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS9" name="INGRESOS9" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Alcohol, tobacco and gambling<br>(1.587% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS9" data-base="1.587">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF9" name="INGRESOSTEF9">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS9" data-base="1.587">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>IEPS (petrolero)</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS10" name="INGRESOS10" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Private mining consumption<br>(1.999% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS10" data-base="1.999">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF10" name="INGRESOSTEF10">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS10" data-base="1.999">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Imports</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS11" name="INGRESOS11" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Household consumption<br>(71.791% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS11" data-base="71.791">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF11" name="INGRESOSTEF11">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS11" data-base="71.791">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td>Total</td>
																	<td><input type="text" class="form-control INGRESOS" id="INGRESOS12" name="INGRESOS12" readonly value="0.000"></td>
																	<td>Household consumption<br>(71.791% GDP)</td>
																	<td>
																		<div class="input-group">
																			<input type="text" class="form-control INGRESOSTEF" id="INGRESOSTEF12" name="INGRESOSTEF12" readonly value="0.000">
																		</div>
																	</td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more, visit the CIEP microsites <a href="https://ingresosenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Ingresos p&uacute;blicos en M&eacute;xico</a> and, on tobacco excise taxes, <a href="https://iepsaltabaco.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">IEPS al tabaco</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="organismos">
												<div>
													<h3>4 - PUBLIC ENTERPRISES AND AGENCIES</h3>
													<div class="table-responsive">
														<table class="table table-striped">
															<thead>
																<tr>
																	<th scope="col" width="39%" class="vertical-center">Agency or Enterprise</th>
																	<th scope="col" class="vertical-center"><a href="https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/paquete_economico/ilif/ilif_2027.pdf" target="_blank" class="icon-link">REVENUE<br>(% GDP)</a></th>
																	<th scope="col" width="43%" class="vertical-center"><a href="https://www.inegi.org.mx/app/indicadores/?tm=3" target="_blank" class="icon-link pre-signo">National Account</a></th>
																	<th scope="col" class="vertical-center post-signo"><a href="images/TE_Organismos.png" data-toggle="lightbox">Effective Rates</a></th>																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte"><b>IMSS</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS13" name="INGRESOS13" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS13" data-base="36.456">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF13" name="INGRESOSTEF13">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS13" data-base="36.456">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>ISSSTE</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS14" name="INGRESOS14" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS14" data-base="36.456">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF14" name="INGRESOSTEF14">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS14" data-base="36.456">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>CFE</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS17" name="INGRESOS17" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS17" data-base="36.456">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF17" name="INGRESOSTEF17">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS17" data-base="36.456">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Pemex</b></td>
																	<td class="new"><input type="number" class="form-control INGRESOS" id="INGRESOS16" name="INGRESOS16" value="0.000" step=".001" min="0" max="100" required></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
	<div class="tasa-control">
		<button type="button" class="btn-tasa btn-down" data-target="INGRESOS16" data-base="36.456">−</button>
		<span class="INGRESOSTEF tasa-value" id="INGRESOSTEF16" name="INGRESOSTEF16">0.000</span>%
		<button type="button" class="btn-tasa btn-up" data-target="INGRESOS16" data-base="36.456">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td>Total</td>
																	<td><input type="text" class="form-control INGRESOS" readonly value="0.000" id="INGRESOS18" name="INGRESOS18"></td>
																	<td>Capital income<br>(36.456% GDP)</td>
																	<td>
																		<div class="input-group">
																			<input type="text" class="form-control INGRESOSTEF" readonly value="0.000" id="INGRESOSTEF18" name="INGRESOSTEF18">
																		</div>
																	</td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more, visit the CIEP microsites <a href="https://ingresosenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Ingresos p&uacute;blicos en M&eacute;xico</a> and, on Pemex and CFE, <a href="https://energiaenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Energ&iacute;a y Finanzas P&uacute;blicas</a> (in Spanish).</p>
													</div>
												</div>
											</div>
										</div>
                                    </div>
                                </div>
									<div class="card card-transactions card-gastos" style="zoom: 1;" id="box-gastos">
                                    <div class="card-body">

										<div id="tabs-2" class="card-ingresos">
											<ul>
												<li><em>1.</em><a href="#educacion"><span>Education</span></a></li>
												<li><em>2.</em><a href="#salud"><span>Health</span></a></li>
												<li><em>3.</em><a href="#pensiones"><span>Pensions</span></a></li>
                       							<li><em>4.</em><a href="#energia"><span>Energy</span></a></li>
												<li><em>5.</em><a href="#otros-gastos"><span>Other Expenses</span></a></li>
												<li style="margin-right:0px;"><em>6.</em><a href="#ingreso-basico"><span>Transfers</span></a></li>
											</ul>
											<div id="educacion">
												<div>
													<h3>1 - EDUCATION</h3>
													<div class="table-responsive">
														<table class="table table-striped" style="height: 183px;">
															<thead>
																<tr style="height: 36px;">
																	<th scope="col" style="height: 36px; width: 39%;" class="vertical-center">Level</th>
																	<th scope="col" style="height: 36px; width: 22%;" class="vertical-center"><a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link" rel="noopener">Public spending <br />(% GDP)</a></th>
																	<th scope="col" style="height: 36px; width: 22%;" class="vertical-center"><a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2" rel="noopener">Students (public schools)</a></th>
																	<th scope="col" style="height: 36px;" class="vertical-center post-signo-2"><a href="images/GastoPC_Educacion.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>															</thead>
															<tbody>
																<tr style="height: 21px;">
																	<td class="aparte" class="aparte" style="height: 21px; width: 262.984px;"><b>Initial and community</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="iniciaA" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="iniciaA">4,274,850</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="iniciaA" data-pop="4274850">−</button>
		<span class="INPUTSG percapita-value" id="iniciaB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="iniciaA" data-pop="4274850">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Basic</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="basica" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="basica">21,676,198</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="basica" data-pop="21676198">−</button>
		<span class="INPUTSG percapita-value" id="basicaB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="basica" data-pop="21676198">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Upper Secondary</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="medsup" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="medsup">5,367,675</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="medsup" data-pop="5367675">−</button>
		<span class="INPUTSG percapita-value" id="medsupB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="medsup" data-pop="5367675">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Higher Education</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="superi" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="superi">3,842,117</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="superi" data-pop="3842117">−</button>
		<span class="INPUTSG percapita-value" id="superiB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="superi" data-pop="3842117">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Graduate</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="posgra" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="posgra">160,728</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="posgra" data-pop="160728">−</button>
		<span class="INPUTSG percapita-value" id="posgraB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="posgra" data-pop="160728">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Adult Education</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="eduadu" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="eduadu">31,175,047</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="eduadu" data-pop="31175047">−</button>
		<span class="INPUTSG percapita-value" id="eduaduB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="eduadu" data-pop="31175047">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Other educational expenses</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="otrose" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="otrose">31,175,047</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="otrose" data-pop="31175047">−</button>
		<span class="INPUTSG percapita-value" id="otroseB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="otrose" data-pop="31175047">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Education investment</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="invere" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="invere">31,175,047</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="invere" data-pop="31175047">−</button>
		<span class="INPUTSG percapita-value" id="invereB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="invere" data-pop="31175047">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Culture and sports</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="cultur" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="cultur">134,409,421</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="cultur" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="culturB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="cultur" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262.984px;"><b>Science and technology</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" id="invest" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="invest">134,409,421</span></td>
																	<td style="height: 21px; width: 147px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="invest" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="investB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="invest" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total" style="height: 21px;">
																	<td style="height: 21px; width: 262.984px;"><b>Total</b></td>
																	<td style="height: 21px; width: 147.547px;"><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required="" /></td>
																	<td style="height: 21px; width: 112.828px; text-align: right;"><span class="pob-value" data-target="totEducac">134,409,421</span></td>
																	<td style="height: 21px; width: 147px;"><span class="INPUTSG" id="totalB">00,000</span></td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about education spending, visit the CIEP microsite <a href="https://gastoeducativo.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Gasto p&uacute;blico para una educaci&oacute;n de calidad</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="salud">
												<div>
													<h3>2 - HEALTH</h3>
													<div class="table-responsive">
														<table class="table table-striped">
															<thead>
																<tr>
																	<th width="39%" scope="col" style="vertical-align: middle;">Institution</th>
																	<th width="22%" scope="col" style="vertical-align: middle;"><a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link" rel="noopener">Public spending <br />(% GDP)</a></th>
																	<th width="22%" scope="col" style="vertical-align: middle;"><a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2" rel="noopener" title="ENIGH 2024 estimate adjusted to CONAPO population">Beneficiaries</a></th>
																	<th scope="col" class="post-signo-2" style="vertical-align: middle;"><a href="images/GastoPC_Salud.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte"><b>SSA (unaffiliated)</b></td>
																	<td><input type="number" class="form-control GASTOS" id="ssa" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="ssa">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="ssa" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="ssaB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="ssa" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>IMSS-Bienestar</b></td>
																	<td><input type="number" class="form-control GASTOS" id="imssbien" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="imssbien">57,363,801</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="imssbien" data-pop="57363801">−</button>
		<span class="INPUTSG percapita-value" id="imssbienB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="imssbien" data-pop="57363801">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>IMSS</b></td>
																	<td><input type="number" class="form-control GASTOS" id="imss" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="imss">55,311,028</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="imss" data-pop="55311028">−</button>
		<span class="INPUTSG percapita-value" id="imssB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="imss" data-pop="55311028">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>ISSSTE</b></td>
																	<td><input type="number" class="form-control GASTOS" id="issste" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="issste">7,171,893</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="issste" data-pop="7171893">−</button>
		<span class="INPUTSG percapita-value" id="isssteB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="issste" data-pop="7171893">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Pemex</b></td>
																	<td><input type="number" class="form-control GASTOS" id="pemex" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="pemex">619,741</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="pemex" data-pop="619741">−</button>
		<span class="INPUTSG percapita-value" id="pemexB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="pemex" data-pop="619741">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>ISSFAM</b></td>
																	<td><input type="number" class="form-control GASTOS" id="issfam" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="issfam">583,175</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="issfam" data-pop="583175">−</button>
		<span class="INPUTSG percapita-value" id="issfamB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="issfam" data-pop="583175">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Inversi&oacute;n en salud</b></td>
																	<td><input type="number" class="form-control GASTOS" id="invers" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="invers">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="invers" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="inversB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="invers" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td><b>Total</b></td>
																	<td><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="totSalud">134,409,421</span></td>
																	<td><span class="INPUTSG" id="totalSaludB">00,000</span></td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about the health system and its financing, visit the CIEP microsite <a href="https://salud.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Salud en M&eacute;xico</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="pensiones">
												<div>
													<h3>3 - PENSIONS</h3>
													<div class="table-responsive">
														<table class="table table-striped" style="height: 177px;">
															<thead>
																<tr style="height: 36px;">
																	<th scope="col" style="height: 36px; width: 39%; vertical-align: middle;">Institution</th>
																	<th scope="col" style="height: 36px; width: 22%; vertical-align: middle;">
																		<a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link" rel="noopener">Public spending <br />(% GDP)</a>
																	</th>
																	<th scope="col" style="height: 36px; width: 22%; vertical-align: middle;">
																		<a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2" rel="noopener">Pensioners</a>
																	</th>
																	<th scope="col" style="height: 36px; vertical-align: middle;" class="post-signo-2"><a href="images/GastoPC_Pensiones.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>
															</thead>
															<tbody>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>Pensions for older adults</b></td>
																	<td style="height: 21px; width: 140.906px;"><input type="number" class="form-control GASTOS" id="bienestar" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="bienestar">13,924,125</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="bienestar" data-pop="13924125">−</button>
		<span class="INPUTSG percapita-value" id="bienestarB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="bienestar" data-pop="13924125">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>IMSS</b></td>
																	<td style="height: 21px; width: 140.906px;"><input type="number" class="form-control GASTOS" id="penims" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="penims">3,591,149</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="penims" data-pop="3591149">−</button>
		<span class="INPUTSG percapita-value" id="penimsB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="penims" data-pop="3591149">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>ISSSTE</b></td>
																	<td style="height: 21px; width: 140.906px;"><input type="number" class="form-control GASTOS" id="peniss" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="peniss">1,056,700</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="peniss" data-pop="1056700">−</button>
		<span class="INPUTSG percapita-value" id="penissB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="peniss" data-pop="1056700">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>Pemex</b></td>
																	<td style="height: 21px; width: 140.906px;"><input type="number" class="form-control GASTOS" id="penpeme" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="penpeme">97,271</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="penpeme" data-pop="97271">−</button>
		<span class="INPUTSG percapita-value" id="penpemeB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="penpeme" data-pop="97271">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 36px;">
																	<td class="aparte" style="height: 36px; width: 262px;"><b>CFE, LFC, Ferronales, ISSFAM</b></td>
																	<td style="height: 36px; width: 140.906px;"><input type="number" class="form-control GASTOS" id="penotr" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 36px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="penotr">63,040</span></td>
																	<td style="height: 36px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="penotr" data-pop="63040">−</button>
		<span class="INPUTSG percapita-value" id="penotrB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="penotr" data-pop="63040">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total" style="height: 21px;">
																	<td style="height: 21px; width: 262px;"><b>Total</b></td>
																	<td style="height: 21px; width: 140.906px;"><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="totPension">18,732,285</span></td>
																	<td style="height: 21px; width: 150px;"><span class="INPUTSG">00,000</span></td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about the pension system, visit the CIEP microsite <a href="https://pensionesenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Las pensiones en M&eacute;xico</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="energia">
												<div>
													<h3>4 - ENERGY</h3>
													<div class="table-responsive">
														<table class="table table-striped" style="height: 177px;">
															<thead>
																<tr style="height: 36px;">
																	<th scope="col" style="height: 36px; width: 39%; vertical-align: middle;">Institution</th>
																	<th scope="col" style="height: 36px; width: 22%; vertical-align: middle;"><a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link" rel="noopener">Public spending <br />(% GDP)</a></th>
																	<th scope="col" style="height: 36px; width: 22%; vertical-align: middle;"><a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2" rel="noopener">Population</a></th>
																	<th scope="col" style="height: 36px; vertical-align: middle;" class="post-signo-2"><a href="images/GastoPC_Energia.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>
															</thead>
															<tbody>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>CFE</b></td>
																	<td style="height: 21px; width: 140.898px;"><input type="number" class="form-control GASTOS" id="gascfe" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="gascfe">134,409,421</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gascfe" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gascfeB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gascfe" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>Pemex</b></td>
																	<td style="height: 21px; width: 140.898px;"><input type="number" class="form-control GASTOS" id="gaspemex" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="gaspemex">134,409,421</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gaspemex" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gaspemexB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gaspemex" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>SENER and others</b></td>
																	<td style="height: 21px; width: 140.898px;"><input type="number" class="form-control GASTOS" id="gassener" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="gassener">134,409,421</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gassener" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gassenerB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gassener" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 21px;">
																	<td class="aparte" style="height: 21px; width: 262px;"><b>Energy investment</b></td>
																	<td style="height: 21px; width: 140.898px;"><input type="number" class="form-control GASTOS" id="gasinverf" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="gasinverf">134,409,421</span></td>
																	<td style="height: 21px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gasinverf" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gasinverfB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gasinverf" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr style="height: 36px;">
																	<td class="aparte" style="height: 36px; width: 262px;"><b>Debt cost (energy)</b></td>
																	<td style="height: 36px; width: 140.898px;"><input type="number" class="form-control GASTOS" id="gascosdeue" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 36px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="gascosdeue">134,409,421</span></td>
																	<td style="height: 36px; width: 150px;">
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gascosdeue" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gascosdeueB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gascosdeue" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total" style="height: 21px;">
																	<td style="height: 21px; width: 262px;"><b>Total</b></td>
																	<td style="height: 21px; width: 140.898px;"><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required /></td>
																	<td style="height: 21px; width: 131.094px; text-align: right;"><span class="pob-value" data-target="totEnergia">134,409,421</span></td>
																	<td style="height: 21px; width: 150px;"><span class="INPUTSG">00,000</span></td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about Pemex, CFE and the energy sector, visit the CIEP microsite <a href="https://energiaenmexico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Energ&iacute;a y Finanzas P&uacute;blicas</a> (in Spanish).</p>
													</div>
												</div>
											</div>

											<div id="otros-gastos">

												<div>
													<h3>5 - OTHER EXPENSES</h3>
													<div class="table-responsive">
														<table class="table table-striped">
															<thead>
																<tr>
																	<th width="39%" scope="col" style="vertical-align: middle;">Concept</th>
																	<th width="22%" scope="col" style="vertical-align: middle;"><a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link" rel="noopener">Public spending <br />(% GDP)</a></th>
																	<th width="22%" scope="col" style="vertical-align: middle;"><a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2" rel="noopener">Population</a></th>
																	<th scope="col" class="post-signo-2" style="vertical-align: middle;"><a href="images/GastoPC_Otros.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>
															</thead>
															<tbody>
																<tr>
																	<td class="aparte"><b>Other investments</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gasinfra" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gasinfra">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gasinfra" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gasinfraB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gasinfra" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Remaining expenses</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gasotros" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gasotros">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gasotros" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gasotrosB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gasotros" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Revenue sharing and other contributions</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gasfeder" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gasfeder">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gasfeder" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gasfederB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gasfeder" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr>
																	<td class="aparte"><b>Debt cost (government)</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gascosto" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gascosto">134,409,421</span></td>
																	<td>
	<div class="percapita-control">
		<button type="button" class="btn-percapita btn-down" data-target="gascosto" data-pop="134409421">−</button>
		<span class="INPUTSG percapita-value" id="gascostoB">00000</span>
		<button type="button" class="btn-percapita btn-up" data-target="gascosto" data-pop="134409421">+</button>
	</div>
</td>
																</tr>
																<tr class="tr-total">
																	<td><b>Total</b></td>
																	<td><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="totOtros">134,409,421</span></td>
																	<td><span class="INPUTSG">00,000</span></td>
																</tr>
															</tbody>
														</table>

														<br>
														<p class="notas">To learn more about transfers to states and municipalities, visit the CIEP microsite <a href="https://subnacional.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Finanzas P&uacute;blicas Subnacionales</a>; on public investment, <a href="https://inversion.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Inversi&oacute;n en M&eacute;xico</a> (in Spanish).</p>
													</div>

												</div>

											</div>

											<div id="ingreso-basico">
												<div>
													<h3>6 - TRANSFERS</h3>
													<div class="table-responsive">
														<table class="table table-striped" id="tabla-ingreso-basico">
															<thead>
																<tr>
																	<th width="40%;" scope="col" style="vertical-align: middle;">Concept</th>
																	<th width="22%;" scope="col" style="vertical-align: middle;"><a href="https://www.ppef.hacienda.gob.mx/es/PPEF2027" target="_blank" class="icon-link">Public spending<br>(% GDP)</a></th>
																	<th width="22%" scope="col" style="vertical-align: middle;"><a href="https://www.inegi.org.mx/programas/enigh/nc/2024/" target="_blank" class="icon-link pre-signo-2">Population</a></th>
																	<th scope="col" class="post-signo-2" style="vertical-align: middle;"><a href="images/GastoPC_Transferencias.png" data-toggle="lightbox">Per capita <br />(MXN 2027)</a></th>
																</tr>
															</thead>
															<tbody>
																<!-- Ingreso Básico Universal - Título -->
																<tr style="background-color: #e8f4fd; border-left: 3px solid #2196F3;">
																	<td><b>Universal Basic Income</b></td>
																	<td><input type="number" class="form-control GASTOS" id="IngBas" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="IngBas">134,409,421</span></td>
																	<td>
																		<div class="percapita-control">
																			<button type="button" class="btn-percapita btn-down" data-target="IngBas" data-pop="134409421">−</button>
																			<span class="INPUTSG percapita-value" id="IngBasB">0</span>
																			<button type="button" class="btn-percapita btn-up" data-target="IngBas" data-pop="134409421">+</button>
																		</div>
																	</td>
																</tr>
																<!-- Checkmarks para IBU -->
																<tr style="background-color: #e8f4fd; border-left: 3px solid #2196F3; border-bottom: 2px solid #2196F3;">
																	<td colspan="2" style="text-align: center; padding: 6px;">
																		<input name="ingbasico18" type="checkbox" class="INPUTSG" id="ingbasico18" checked="CHECKED">
																		<label for="ingbasico18" style="margin-left: 5px;">
																			<b>Under 18 years old</b>
																		</label>
																	</td>
																	<td colspan="2" style="text-align: center; padding: 6px;">
																		<input name="ingbasico65" type="checkbox" class="INPUTSG" id="ingbasico65" checked="CHECKED">
																		<label for="ingbasico65" style="margin-left: 5px;">
																			<b>Over 65 years old</b>
																		</label>
																	</td>
																</tr>
																<!-- Apoyo a madres trabajadoras -->
																<tr>
																	<td><b>Support for working mothers</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gasmadres" value="0.009" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gasmadres">9,568,242</span></td>
																	<td>
																		<div class="percapita-control">
																			<button type="button" class="btn-percapita btn-down" data-target="gasmadres" data-pop="9568242">−</button>
																			<span class="INPUTSG percapita-value" id="gasmadresB">352</span>
																			<button type="button" class="btn-percapita btn-up" data-target="gasmadres" data-pop="9568242">+</button>
																		</div>
																	</td>
																</tr>
																<!-- Gasto en cuidados -->
																<tr>
																	<td><b>Care spending</b></td>
																	<td><input type="number" class="form-control GASTOS" id="gascuidados" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="gascuidados">134,100,790</span></td>
																	<td>
																		<div class="percapita-control">
																			<button type="button" class="btn-percapita btn-down" data-target="gascuidados" data-pop="134100790">−</button>
																			<span class="INPUTSG percapita-value" id="gascuidadosB">0</span>
																			<button type="button" class="btn-percapita btn-up" data-target="gascuidados" data-pop="134100790">+</button>
																		</div>
																	</td>
																</tr>
																<tr class="tr-total">
																	<td><b>Total</b></td>
																	<td><input type="number" class="form-control GASTOS" value="0.000" step=".001" min="0" required /></td>
																	<td style="text-align: right;"><span class="pob-value" data-target="totTransf">134,409,421</span></td>
																	<td><span class="INPUTSG">00,000</span></td>
																</tr>
															</tbody>
														</table>
														<br>
														<p class="notas">To learn more about care spending, visit the CIEP microsite <a href="https://cuidados.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Cuidados</a>; on social programs and the 2030 Agenda, <a href="https://desarrollosostenible.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Desarrollo sostenible: usos y recursos p&uacute;blicos</a> (in Spanish).</p>
													</div>
												</div>
											</div>
										</div>
                                    </div>
                                </div>

								<div class="card card-transactions card-gastos card-pib" style="zoom: 1;" id="box-pib">
                                    <div class="card-body">
                                        <h5 class="card-title">GDP Growth

										<a href="#" class="btn btn-secondary btn-sm btn-right" id="guardar-pib">Save changes <span class="material-icons">save</span></a>

										<a href="#" class="btn btn-secondary btn-sm btn-right" id="reset-pib">Reset <i class="material-icons">refresh</i></a>

										<!-- Modal -->
                                        <div class="modal fade" id="exampleModalCenter" tabindex="-1" role="dialog" aria-labelledby="exampleModalCenterTitle" aria-hidden="true">
                                            <div class="modal-dialog modal-dialog-centered" role="document">
                                                <div class="modal-content">
                                                    <div class="modal-header">
                                                        <h5 class="modal-title" id="exampleModalCenterTitle">Título del pop-up</h5>
                                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                            <i class="material-icons">close</i>
                                                        </button>
                                                    </div>
                                                    <div class="modal-body">
                                                        Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum at eros.
                                                    </div>
                                                    <div class="modal-footer">
                                                        <button type="button" class="btn btn-secondary btn-xs" data-dismiss="modal">Cancelar</button>
                                                        <button type="button" class="btn btn-info btn-xs">Guardar</button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

										</h5>

										<p>TEST</p>


                                    </div>
                                </div>

								<div class="row">
									<div class="col-lg-6">
										<button type="button" class="btn btn-lg btn-primary btn-yellow cerrar-actualizar w-100" id="btn-reestablecer">Reset</button>
									</div>
									<!--div class="col-lg-4">
										<button type="button" class="btn-actualizar btn btn-lg btn-primary btn-yellow cerrar-actualizar w-100" id="btn-actualizar">Actualizar <small>(7seg)</small></button>
									</div-->
									<div class="col-lg-6">
										<button id="isrSub" type="button" class="btn btn-primary btn-lg btn-block">Calculate</button>
									</div>
								</div>
                            </div>


                            <div class="col-lg-4">
                                <div class="card">
									<div class="card-header"><a href="https://www.finanzaspublicas.hacienda.gob.mx/work/models/Finanzas_Publicas/docs/paquete_economico/cgpe/cgpe_2027.pdf" target="_blank" class="icon-link en-amarillo">Macroeconomic Framework</a></div>

                                    <div class="card-body" style="padding-bottom: 15px;">



										<table class="table-proyeccion" style="width:100%">
											<tbody>
											<tr>
											<th width="32%"><span class="anio">Year</span><div class="limpiar mb-2"></div></th>
											<th width="30%"><span class="anio">GDP (growth %)</span><div class="limpiar mb-2"></div></th>
											<th width="38%"><span class="anio">Prices (growth %)</span><div class="limpiar mb-2"></div></th>
											</tr>

											<!--tr>
												<td>2023</td>
												<td>
													<input name="CRECPIB2023" type="text" required class="form-control box-pib CRECPIB" id="CRECPIB2023" min="0" step=".001" value="0.0">
												</td>
												<td>
													<input name="CRECDEF2023" type="text" required class="form-control box-pib CRECDEF" id="CRECDEF2023" min="0" step=".001" value="0.0">
												</td>
											</tr-->
											<!--tr>
												<td>2024</td>
												<td>
													<input name="CRECPIB2024" type="text" required class="form-control box-pib CRECPIB" id="CRECPIB2024" min="0" step=".001" value="0.0">
												</td>
												<td>
													<input name="CRECDEF2024" type="text" required class="form-control box-pib CRECDEF" id="CRECDEF2024" min="0" step=".001" value="0.0">
												</td>
											</tr-->
											<tr>
												<td>2026</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2026">−</button>
														<input name="CRECPIB2026" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2026" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2026">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2026">−</button>
														<input name="CRECDEF2026" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2026" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2026">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2027</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2027">−</button>
														<input name="CRECPIB2027" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2027" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2027">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2027">−</button>
														<input name="CRECDEF2027" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2027" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2027">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2028</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2028">−</button>
														<input name="CRECPIB2028" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2028" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2028">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2028">−</button>
														<input name="CRECDEF2028" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2028" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2028">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2029</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2029">−</button>
														<input name="CRECPIB2029" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2029" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2029">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2029">−</button>
														<input name="CRECDEF2029" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2029" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2029">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2030</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2030">−</button>
														<input name="CRECPIB2030" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2030" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2030">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2030">−</button>
														<input name="CRECDEF2030" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2030" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2030">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2031</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2031">−</button>
														<input name="CRECPIB2031" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2031" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2031">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2031">−</button>
														<input name="CRECDEF2031" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2031" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2031">+</button>
													</div>
												</td>
											</tr>
											<tr>
												<td>2032</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECPIB2032">−</button>
														<input name="CRECPIB2032" type="text" required class="form-control box-pib CRECPIB macro-value" id="CRECPIB2032" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECPIB2032">+</button>
													</div>
												</td>
												<td>
													<div class="macro-control">
														<button type="button" class="btn-macro btn-down" data-target="CRECDEF2032">−</button>
														<input name="CRECDEF2032" type="text" required class="form-control box-pib CRECDEF macro-value" id="CRECDEF2032" min="0" step=".1" value="0.0">
														<button type="button" class="btn-macro btn-up" data-target="CRECDEF2032">+</button>
													</div>
												</td>
											</tr>

											</tbody>
										</table>
										<p class="notas mt-2">To learn more about the macroeconomic assumptions and the current Economic Package, visit the CIEP microsite <a href="https://paqueteeconomico.ciep.mx" target="_blank" rel="noopener" class="icon-link en-amarillo">Paquete Econ&oacute;mico</a> (in Spanish).</p>
										<!-- DivTable.com -->

										<div class="limpiar mb-3"></div>

                                        <!--div>
											<div class="deuda-info"></div>
											<div id="chart-0-box">
												<a id="lupa"><i class="fas fa-search-plus"></i></a>
												<div id="chart-0"></div>
											</div>
                                        </div-->

                                    </div> <!--fin de card-body-->

									<div class="card-header pt-0 mb-3">
                                        PUBLIC DEBT
                                    </div>
									<div class="modal-body pb-4">
										<div class="tabla-envolvente p-0">
											<table class="tableizer-table t-extra tabla-res-ingresos w-100">
												<style>
													.tableizer-table.t-extra td {
														padding-top: 5px;
														padding-top: 5px;
													}
												</style>
											   <tbody>
												  <!--tr class="sub-header">
													 <td width="61.8%">Concepto</td>
													 <td>Valor</td>
												  </tr-->
												  <tr class="pt-2">
													 <td>Average interest rate (%)</td>
													 <td><input type="number" class="form-control DEUDA" id="DEUDA0" name="DEUDA0" value="10.8" step=".001" min="0" max="100" required  ></td>
												  </tr>

											   </tbody>
											</table>
										</div>
									</div>

                                </div>

                            </div>
                        </div>
                        <div class="row">
                            <div class="col-lg-12">
                                <div class="card">
                                    <!--div class="alert alert-info no-m" role="alert">
                                        Data has been updated 35 minutes ago, go to the reports page to access data history.
                                    </div-->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

	<p class="txt-vertical-2">©2026 | CIEP Fiscal Simulator</p>


	<div class="resultados dark-theme resultado-2 base-gris" style="margin-top:34px;">
			<h6><span></span>Who pays, who receives?</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
                            <div class="col-xl-8 pr-3" id="res-01">
								<div class="resultado-header">
                                	<h2 data-shadow="Contributions per household" class="card-title">Contributions per household</h2>
									<div class="toggle-data-btns" data-section="tablaINCD">
										<button type="button" class="btn-toggle active" data-view="default">2027 values</button>
										<button type="button" class="btn-toggle btn-disabled" data-view="simulacion">Simulation values</button>
									</div>
								</div>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>

                                <div class="chart ml-5">
									<table class="table table-hover" id="tablaINCD">
											<tbody>
											<tr>
												<th style="width:25%">Deciles</th>
												<th style="width:25%">Annual<br>contribution ($)</th>
												<th style="width:25%">Distribution (%)</th>
												<th style="width:25%">% of household<br>income</th>
											</tr>
											<tr>
												<td>I</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>II</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>III</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>IV</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>V</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>VI</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>VII</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>VIII</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>IX</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr>
												<td>X</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											<tr class="td-total">
												<td>National</td>
												<td class="valINCD">-$9,000</td>
												<td class="valINCD2">&nbsp;</td>
												<td class="valINCD3">&nbsp;</td>
											  </tr>
											</tbody>
									</table>
								</div>
                            </div>
							<div class="col-xl-4 pl-5 pr-0">
								<h4>Result of <b>adding</b> obligations and <b>subtracting</b> benefits</h4>
                                <p class="card-text">
									<b>Adding</b> all the <a href="images/ImpuestosAportaciones_2025.png" data-toggle="lightbox">contributions</a> (tax obligations) that households deliver and <b>subtracting</b> all the <a href="images/Transferencias_2025.png" data-toggle="lightbox" target="_blank">transfers</a> (public benefits) they receive, we obtain the <b>net contribution</b>. A progressive tax system should show that households with more resources contribute more (positive result), while households with fewer resources receive more than they contribute (negative result).
								</p>
								<p>
									The first column represents the income <b>decile</b> of households (from I poorest to X richest). The second column shows the average of what a <b>household would contribute annually</b> to the fiscal system. The third column indicates how the tax burden is <b>distributed</b> among different deciles. The fourth column calculates what <b>proportion</b> this contribution represents relative to the household's total annual income.
								</p>
								<!--button type="button" class="btn btn-primary">Saber más</button-->
                            </div>
						</div>
					</div>
			</div>
	</div>

	<div class="resultados dark-theme resultado-3 base-blanca">
			<h6><span></span>The fiscal contracts</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">

							<div class="col-xl-12 mb-5" id="res-02">

                                <h2 data-shadow="Tax burden by age" class="card-title">Tax burden by age</h2>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>
								<div class="row ml-5 chart-duo-box">
									<div class="col-xl-6" style="padding:0 !important;">
										<div class="m-0" id="chart-duo-pt1"></div>
									</div>
									<div class="col-xl-6" style="padding:0 !important;">
										<div class="m-0" id="chart-duo-pt2"></div>
									</div>
								</div>
                            </div>

							<div class="col-xl-3 mt-5"></div>
							<div class="col-xl-9 mt-5">
								<h4>How an individual would contribute <b>throughout their life</b></h4>
                                <p class="card-text">
									<b>People produce</b> and <b>consume</b> differently at each <a href="images/AportacionesNetas_2025.png" data-toggle="lightbox">stage of their life</a>. Young people mainly dedicate themselves to studying, adults actively participate in the labor market, and older adults begin to retire. This life cycle pattern is similar <a class="icon-link" href="https://ntaccounts.org/" target="_blank">worldwide</a>.
								</p>

								<p>
									Additionally, gender roles, wage differences, and unequal opportunities between <b>men</b> and <b>women</b> also modify each person's economic behavior and tax obligations. These graphs include intra-household transfers (e.g., from parents to children when living together) and inter-household transfers (e.g., from grandparents to grandchildren when living in separate households).
								</p>
                            </div>
						</div>
					</div>
			</div>
	</div>


	<div class="resultados dark-theme resultado-4 base-gris">
			<h6><span></span>The demographic reversal</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
							<div class="col-xl-4 pr-5 fc-toolbar">
								<h4>A <b>demographic transition</b> is underway</h4>
                                <p class="card-text">
									Since the 1970s, the population in Mexico between 16 and 65 years old has increased due to the phenomenon known as the <a href="images/piramide.gif" data-toggle="lightbox">"demographic bonus"</a>. This has generated a higher proportion of potential workers in relation to economic dependents (children and older adults).
								</p>
								<p>
									However, depending on the established generational contracts, net contributions could reach a maximum collection point and then begin to decrease. This means that, at some point, there could be more people demanding public services (health, pensions, education) than people contributing fiscally to the system.
								</p>
								<div class="mt-4 alert alert-danger" role="alert">
                                            <p>Starting from <span id="PROYMAX">2030</span>, <b>net contributions</b> begin to DECREASE</p>
                                        </div>

                            </div>
							<div class="col-xl-8 pr-3" id="res-02">
                                <h2 data-shadow="The fiscal bonus" class="card-title">The fiscal bonus</h2>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>
                                <div class="chart ml-5" id="line-1"></div>
                            </div>
						</div>
					</div>
			</div>
	</div>


	<div class="resultados dark-theme resultado-5 base-blanca">
			<h6><span></span>+ Revenues</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
                            <div class="col-xl-8 pr-3" id="res-03">
                                <h2 data-shadow="The resource projection" class="card-title">The resource projection</h2>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>
                                <div class="chart ml-5" id="stacked1"></div>
                            </div>
							<div class="col-xl-4 pl-5 pr-0">
								<h4>Demographics <b>+</b> Economics</h4>
                                <p class="card-text">
                                Taxes on <a href="images/AlTrabajo_2025.png" data-toggle="lightbox">labor</a> and <a href="images/AlConsumo_2025.png" data-toggle="lightbox">consumption</a> are directly influenced by the demographic composition of the population and its productivity level. Taxes and income related to <a href="images/AlCapital_2025.png" data-toggle="lightbox">capital</a> depend mainly on economic activity and investment profitability.
								</p>
								<p>
									By applying the <b>simulated effective rates</b> to the national accounts that make up GDP, along with demographic transition projections and expected economic growth, future available public resources are estimated. These projected revenues must be sufficient to finance committed public spending.
								</p>

							<!--button type="button" class="btn btn-primary">Saber más</button-->

                            </div>
						</div>
					</div>
			</div>
	</div>



	<div class="resultados dark-theme resultado-6 base-gris">
			<h6><span></span>- Expenditures</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
							<div class="col-xl-4 pr-5 fc-toolbar">
								<h4><b>Public</b> obligations</h4>
                                <p class="card-text">
									Expenditures on <a href="images/Salud_2025.png" data-toggle="lightbox">health</a>, <a href="images/Educación_2025.png" data-toggle="lightbox">education</a>, <a href="images/Pensiones_2025.png" data-toggle="lightbox">pensions</a>, <a href="images/Pensión_AM_2025.png" data-toggle="lightbox">senior citizen pensions</a> and other social programs are heavily influenced by the demographic composition of the population. Meanwhile, amortization and the financial cost of public debt depend on financial variables such as accumulated balances, current interest rates, and exchange rates.
                                </p>

								<p>
									Using the <b>simulated per capita expenditures</b> that represent public commitments and obligations, the resources that will be required in the future are projected. To ensure long-term fiscal sustainability, these projected expenditures should not exceed available public revenues.
								</p>

                            </div>
							<div class="col-xl-8 pr-3" id="res-04">
                                <h2 data-shadow="The spending projection" class="card-title">The spending projection</h2>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>
                                <div class="chart ml-5" id="stacked2"></div>
                            </div>
						</div>
					</div>
			</div>
	</div>


	<div class="resultados dark-theme resultado-7 base-blanca">
			<h6><span></span>= Debt</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
                            <div class="col-xl-8 pr-3" id="res-05">
                                <h2 data-shadow="Fiscal sustainability" class="card-title">Fiscal sustainability</h2>
								<p class="txt-vertical"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>
                                <div class="chart ml-5" id="area2"></div>
                            </div>
							<div class="col-xl-4 pl-5 pr-0">
								<h4><b>Need for changes</b> in revenues and/or expenditures</h4>
                                <p class="card-text">
								The <b>public debt trajectory</b> in the long term reflects the government's ability to meet its financial obligations in relation to its capacity to generate revenue. Ideally, this trajectory should remain stable or, preferably, show a decreasing trend.
                                </p>

								<p>
								Excessive indebtedness can create <b>intergenerational inequity</b>: current generations use resources that have not yet been generated, compromising the future. A situation of <b>fiscal unsustainability</b> would pass on payment obligations to future generations, who may not receive the benefits of the expenditures financed by that debt.
								</p>

								<div class="mt-4 alert alert-danger" role="alert" id="textPROYSHRFSP">
                                            <p>A "desirable" trend would be one where debt remains constant or, better yet, decreasing.</p>
                                </div>
                            </div>
						</div>
					</div>
			</div>
	</div>



	<div class="resultados dark-theme resultado-8 base-gris">
			<h6><span></span>Fiscal redistribution</h6>
            <div class="page-container">
                    <div class="main-wrapper container box-resultados">
						<div class="row align-items-center">
                            <div class="col-xl-12 mb-5" id="res-05">
                                <h2 data-shadow="Everything starts and ends with people" class="card-title" style="margin-bottom: 0.67em; margin-bottom: 55px;">Everything starts and ends with people</h2>
								<p class="txt-vertical" style="margin-top: 35px !important;"><b>Source</b>: Prepared with the CIEP Fiscal Simulator.</p>

								<div style="position:relative;">

									<table class="titulos">
										<tbody>
										<tr>
										<td width="20%" class="txt-l" style="padding-left:0px;">Contributing<br>population</td>
										<td width="20%" style="text-align:center; padding-right:44px;">Revenues</td>
										<td width="20%" style="text-align:center; padding-left:0px;">(MXN)</td>
										<td width="20%" style="text-align:center; padding-left:52px;">Public<br>spending</td>
										<td width="20%" class="txt-r" style="padding-left:0px;">Beneficiary<br>population</td>
										</tr>
										</tbody>
									</table>

									<div>
										<div id="btns-sankeys">
											<button type="button" id="btn-sankey-1" class="mr-2 btn btn-primary btn-xs active">Deciles</button>
											<button type="button" id="btn-sankey-2" class="mr-2 btn btn-primary btn-xs">Age groups</button>
											<button type="button" id="btn-sankey-3" class="mr-2 btn btn-primary btn-xs">Education level</button>
											<button type="button" id="btn-sankey-4" class="mr-2 btn btn-primary btn-xs">Rural/Urban</button>
											<button type="button" id="btn-sankey-5" class="btn btn-primary btn-xs">Gender</button>
										</div>

										<div id="sankey-num1" class="visible">
											<div class="chart ml-5" id="sankey-1"></div>
										</div>
										<div id="sankey-num2" class="">
											<div class="chart ml-5" id="sankey-2"></div>
										</div>
										<div id="sankey-num3" class="">
											<div class="chart ml-5" id="sankey-3"></div>
										</div>
										<div id="sankey-num4" class="">
											<div class="chart ml-5" id="sankey-4"></div>
										</div>
										<div id="sankey-num5" class="">
											<div class="chart ml-5" id="sankey-5"></div>
										</div>
										<div style="height:600px;"></div>
									</div>
								</div>

                            </div>
							<div class="col-xl-3 mt-5"></div>
							<div class="col-xl-9 mt-5">
								<h4>This is the <b>beginning</b> and <b>end</b> of the fiscal system</h4>
                                <p class="card-text"><b>People</b> are the beginning and end of the fiscal system. They are its foundation and reason for being. Individuals are those who generate public resources through their contributions and, at the same time, those who receive and benefit from public services and programs.</p>

								<p>On the far left of the graph, we see how <b>households contribute</b> to the system through taxes and public revenues. In the center, the fiscal system concentrates and manages those resources. Finally, on the far right, we see the public policies and social programs that <b>redistribute</b> resources to households and other sectors of society.</p>
								<!--button type="button" class="btn btn-primary">Saber más</button-->
                            </div>

						</div>
					</div>
			</div>
	</div>




<div class="container-fluid pb-0 mb-0 justify-content-center text-light footer-box" id="libro-simulador">
	<!-- CIEP book banner (same pattern as the banner on paqueteeconomico.ciep.mx) -->
	<style>
	.libro-promo{background:linear-gradient(90deg,rgba(255,255,255,.85) 0%,rgba(255,255,255,.8) 40%,rgba(255,255,255,.55) 58%,rgba(255,255,255,0) 76%),#FFD520 url('images/libro-promo/fondo-portada.jpg') right center/cover no-repeat;border-radius:0;padding:64px 24px;margin:0 -15px}
	.libro-promo-inner{max-width:1080px;margin:0 auto;display:flex;align-items:center;gap:44px;flex-wrap:wrap;justify-content:space-between}
	.libro-promo-txt{flex:0 1 430px;max-width:430px;min-width:280px;font-family:'Roboto Mono',monospace;color:#1F262B;text-align:left}
	.libro-promo-eyebrow{display:inline-block;background:#1F262B;color:#FFD520;font-size:12px;font-weight:700;letter-spacing:2px;padding:6px 14px;margin-bottom:14px;text-transform:uppercase}
	#libro-simulador .libro-promo-title{font-size:30px;line-height:1.15;font-weight:700;margin:0 0 10px;color:#1F262B;position:static}#libro-simulador .libro-promo-title:after{content:none}
	.libro-promo-tag{font-size:17px;font-weight:600;margin:0 0 14px;color:#1F262B}
	.libro-promo-desc{font-size:13.5px;line-height:1.6;margin:0 0 22px;color:#1F262B}
	.libro-promo-cta{display:inline-block;background:#1F262B;color:#fff;font-weight:700;font-size:14px;padding:12px 28px;border-radius:28px;text-decoration:none;transition:transform .15s ease,box-shadow .15s ease}
	.libro-promo-cta:hover{color:#e8f04b;text-decoration:none;transform:translateY(-2px);box-shadow:0 8px 22px rgba(31,38,43,.35)}
	.libro-promo-img{flex:0 1 380px;min-width:260px;text-align:center}
	.libro-promo-img img{width:100%;max-width:400px;height:auto;border-radius:10px;box-shadow:0 18px 45px rgba(31,38,43,.4)}
	.footer-micrositios a.icon-link{white-space:nowrap}
	@media(max-width:767px){.libro-promo{padding:36px 16px;background:#FFD520}.libro-promo-title{font-size:24px}.libro-promo-inner{gap:26px}}
	</style>
	<div class="libro-promo">
	  <div class="libro-promo-inner">
	    <div class="libro-promo-txt">
	      <span class="libro-promo-eyebrow">The Simulator's Book</span>
	      <h2 class="libro-promo-title">Human-Centered Public Finance</h2>
	      <p class="libro-promo-tag">An informed debate is a public good.</p>
	      <p class="libro-promo-desc">The &ldquo;citizen's textbook&rdquo; to understand the foundations and purposes of our public resources. The theory behind this simulator: replicate every chart, simulate scenarios, and join the debate. (In Spanish.)</p>
	      <a class="libro-promo-cta" href="https://libro.ciep.mx" target="_blank" rel="noopener">Discover the book</a>
	    </div>
	    <div class="libro-promo-img">
	      <a href="https://libro.ciep.mx" target="_blank" rel="noopener"><img src="images/libro-promo/portada-libro-900.jpg" alt="Cover of the book Finanzas P&uacute;blicas Antropoc&eacute;ntricas" loading="lazy"></a>
	    </div>
	  </div>
	</div>

		<footer>

				<div class="row justify-content-center mb-0 pt-5 pb-0 row-2 px-3 pb-5">
					<div class="main-wrapper container">
						<div class="col-12 px-0">
							<div class="row row-2">
								<div class="col-sm-2">
									<a class="internalLink logo-box" id="footer-logo">
										<img src="images/logo-sim-fiscal-ciep-b.png" width="138" height="146" alt="Simulador Fiscal v3">
									</a>
								</div>

								<div class="col-sm-2 my-sm-0 mt-5">
									<p class="footer_title"><small>Simulators:</small></p>
									<ul class="list-unstyled mb-0">
										<li><a class="icon-link" href="https://simuladorfiscal.ciep.mx/" target="_blank" rel="noopener">Fiscal Simulator</a></li>
										<li><a class="icon-link" href="https://tenencia.ciep.mx/" target="_blank" rel="noopener">Vehicle Tax Simulator</a></li>
										<li><a class="icon-link" href="https://iepsaltabaco.ciep.mx/" target="_blank" rel="noopener">Tobacco Excise Tax</a></li>
									</ul>
								</div>

								<div class="col-sm-5 my-sm-0 mt-5 footer-micrositios">
									<p class="footer_title"><small>Microsites:</small></p>
									<div class="row">
										<div class="col-sm-6">
											<ul class="list-unstyled mb-0">
												<li><a class="icon-link" href="https://libro.ciep.mx/" target="_blank" rel="noopener">The CIEP Book</a></li>
												<li><a class="icon-link" href="https://paqueteeconomico.ciep.mx/" target="_blank" rel="noopener">Economic Package</a></li>
												<li><a class="icon-link" href="https://ingresosenmexico.ciep.mx/" target="_blank" rel="noopener">Public Revenue</a></li>
												<li><a class="icon-link" href="https://pensionesenmexico.ciep.mx/" target="_blank" rel="noopener">Pensions in Mexico</a></li>
												<li><a class="icon-link" href="https://salud.ciep.mx/" target="_blank" rel="noopener">Health in Mexico</a></li>
												<li><a class="icon-link" href="https://gastoeducativo.ciep.mx/" target="_blank" rel="noopener">Education in Mexico</a></li>
											</ul>
										</div>
										<div class="col-sm-6">
											<ul class="list-unstyled mb-0">
												<li><a class="icon-link" href="https://energiaenmexico.ciep.mx/" target="_blank" rel="noopener">Energy in Mexico</a></li>
												<li><a class="icon-link" href="https://subnacional.ciep.mx/" target="_blank" rel="noopener">Subnational Finances</a></li>
												<li><a class="icon-link" href="https://inversion.ciep.mx/" target="_blank" rel="noopener">Investment in Mexico</a></li>
												<li><a class="icon-link" href="https://desarrollosostenible.ciep.mx/" target="_blank" rel="noopener">Sustainable Development</a></li>
												<li><a class="icon-link" href="https://cuidados.ciep.mx/" target="_blank" rel="noopener">Care Economy</a></li>
											</ul>
										</div>
									</div>
								</div>

								<div class="col-sm-3 my-sm-0 mt-5">
									<p class="footer_title"><small>Contact:</small></p>
									<ul class="list-unstyled mb-0">
										<li>Puebla 151 Letra O, Col. Roma Norte,</li>
										<li>Cuauhtémoc, Mexico City, 06700</li>
										<li><a class="icon-link" href="mailto:info@ciep.mx">info@ciep.mx</a> / (55) 53.40.86.88</li>
										<li class="mb-0"><a class="icon-link" href="https://ciep.mx/" target="_blank" rel="noopener">ciep.mx</a></li>
									</ul>
								</div>

							</div>
						</div>
					</div>
				</div>


				<div class="row justify-content-center mt-0 pt-0 row-1 mb-0 px-sm-3 px-2">
					<div class="main-wrapper container">
						<div class="col-12 px-0">
							<div class="row my-4 row-1 no-gutters">
								<div class="col-sm-6 col-auto my-auto">
									<small>&#9400; 2026 | CIEP Fiscal Simulator - ricardocantu@ciep.mx<?php if ($deployed_version_html !== "") { echo ' | Version ' . $deployed_version_html; } ?></small>
								</div>

								<div class="col-md-6 my-auto text-right ">

								<ul class="navbar-nav nav-social mr-3">
									<li class="nav-item">
										<a href="http://facebook.com/ciepmx" target="_blank"><img class="social-icon i-face" src="images/f-icon-facebook.svg"></a>
									</li>
									<li class="nav-item">
										<a href="https://twitter.com/ciepmx" target="_blank"><img class="social-icon" src="images/f-icon-twitter.svg"></a>
									</li>
									<li class="nav-item">
										<a href="https://www.youtube.com/user/CIEPMX" target="_blank"><img class="social-icon" src="images/f-icon-youtube.svg"></a>
									</li>
								</ul>

								</div>
							</div>
						</div>
					</div>
				</div>

		</footer>

</div>








	<!-- Modal-ISR-1 -->
	<div class="modal fade" id="Modal-ISR-1" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
		<div class="modal-dialog modal-xl" role="document">
			<div class="modal-content modal-xl">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">PIT Law. Articles 151, 152 and tenth transitory. Updated with annex 8 of the Miscellaneous Fiscal Resolution for 2026.</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<i class="material-icons">close</i>
					</button>
				</div>
				<div class="modal-body">

			      <div class="row">
					<div class="col-sm-6" id="tabla-inter-1">
						<div class="tabla-envolvente">

            <table class="tableizer-table tabla-res-ingresos w-100">
						   <tbody>
							  <tr class="sub-header">
								 <td style="width:25% !important">Lower limit ($)</td>
								 <td style="width:25% !important">Upper limit ($)</td>
								 <td style="width:22% !important">Fixed fee ($)</td>
								 <td style="width:25% !important">Rate (%)</td>
							  </tr>
							  <tr>
								 <td>0.01</td>
								 <td>8,952.49</td>
								 <td class="ISRCUFI">0.0</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA0">−</button>
										<input name="ISRTASA0" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA0" value="1.92">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA0">+</button>
								   </div>
								 </span></td>
							  </tr>
							  <tr>
								 <td>8,952.50</td>
								 <td>75,984.55</td>
								 <td class="ISRCUFI">148.51</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA1">−</button>
										<input name="ISRTASA1" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA1" value="6.40">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA1">+</button>
								   </div>
								 </span></td>
							  </tr>
								  <tr>
								 <td>75,984.56</td>
								 <td>133,536.07</td>
								 <td class="ISRCUFI">3855.14</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA2">−</button>
										<input name="ISRTASA2" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA2" value="10.88">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA2">+</button>
								   </div>
								 </span></td>
							  </tr>


							  <tr>
								 <td>133,536.08</td>
								 <td>155,229.80</td>
								 <td class="ISRCUFI">9265.20</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA3">−</button>
										<input name="ISRTASA3" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA3" value="16.00">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA3">+</button>
								   </div>
								 </span></td>
							  </tr>
							  <tr>
								 <td>155,229.81</td>
								 <td>185,852.57</td>
								 <td class="ISRCUFI">12264.16</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA4">−</button>
										<input name="ISRTASA4" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA4" value="17.92">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA4">+</button>
								   </div>
								 </span></td>
							  </tr>
							  <tr>
								 <td>185,852.58</td>
								 <td>374,837.88</td>
								 <td class="ISRCUFI">17005.47</td>
								 <td class="numeros"><span class="destacado">
								   <div class="macro-control">
										<button type="button" class="btn-macro btn-down" data-target="ISRTASA5">−</button>
										<input name="ISRTASA5" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA5" value="21.36">
										<button type="button" class="btn-macro btn-up" data-target="ISRTASA5">+</button>
								   </div>
								 </span></td>
							  </tr>
							  <tr>
							    <td>374,837.89</td>
							    <td>590,795.99</td>
							    <td class="ISRCUFI">51883.01</td>
							    <td class="numeros"><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="ISRTASA6">−</button>
									<input name="ISRTASA6" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA6" value="23.52">
									<button type="button" class="btn-macro btn-up" data-target="ISRTASA6">+</button>
							      </div>
							    </span></td>
						     </tr>
							  <tr>
							    <td>590,796.00</td>
							    <td>1,127,926.84</td>
							    <td class="ISRCUFI">95768.74</td>
							    <td class="numeros"><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="ISRTASA7">−</button>
									<input name="ISRTASA7" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA7" value="30.00">
									<button type="button" class="btn-macro btn-up" data-target="ISRTASA7">+</button>
							      </div>
							    </span></td>
						     </tr>
							  <tr>
							    <td>1,127,926.85</td>
							    <td>1,503,902.46</td>
							    <td class="ISRCUFI">234993.95</td>
							    <td class="numeros"><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="ISRTASA8">−</button>
									<input name="ISRTASA8" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA8" value="32.00">
									<button type="button" class="btn-macro btn-up" data-target="ISRTASA8">+</button>
							      </div>
							    </span></td>
						     </tr>
							  <tr>
							    <td>1,503,902.47</td>
							    <td>4,511,707.37</td>
							    <td class="ISRCUFI">338944.34</td>
							    <td class="numeros"><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="ISRTASA9">−</button>
									<input name="ISRTASA9" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA9" value="34.00">
									<button type="button" class="btn-macro btn-up" data-target="ISRTASA9">+</button>
							      </div>
							    </span></td>
						     </tr>

							 <tr>
							    <td>4,511,707.38</td>
							    <td>And above</td>
							    <td class="ISRCUFI">1222522.76</td>
							    <td class="numeros"><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="ISRTASA10">−</button>
									<input name="ISRTASA10" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje IVA macro-value" id="ISRTASA10" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="ISRTASA10">+</button>
							      </div>
							    </span></td>
						     </tr>
                </tbody>
            </table>

						</div>
					</div>

					<div class="col-sm-6">
						  <div class="tabla-envolvente">
                             <table class="tableizer-table tabla-res-ingresos w-100">
                             <tbody>

							  <tr class="sub-header tabla2">
							    <td>Lower limit ($)</td>
							    <td>Upper limit ($)</td>
							    <td width="34%">Employment subsidy ($ annual)</td>
						     </tr>
							  <tr class="tabla2">
							    <td>0.01</td>
							    <td>21,227.52</td>
							    <td><span class="destacado">
					        <div class="macro-control">
								<button type="button" class="btn-macro btn-down" data-target="SE0">−</button>
								<input name="SE0" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE0" value="35.00">
								<button type="button" class="btn-macro btn-up" data-target="SE0">+</button>
							</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>21,227.53</td>
							    <td>23,744.40</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE1">−</button>
									<input name="SE1" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE1" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE1">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>31,840.57</td>
							    <td>41,674.08</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE2">−</button>
									<input name="SE2" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE2" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE2">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>41,674.09</td>
							    <td>42,454.44</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE3">−</button>
									<input name="SE3" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE3" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE3">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>42,454.45</td>
							    <td>53,353.80</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE4">−</button>
									<input name="SE4" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE4" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE4">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>53,353.80</td>
							    <td>56,606.16</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE5">−</button>
									<input name="SE5" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE5" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE5">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>56,606.16</td>
							    <td>64,025.04</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE6">−</button>
									<input name="SE6" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE6" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE6">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>64,025.04</td>
							    <td>74,696.04</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE7">−</button>
									<input name="SE7" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE7" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE7">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>74,696.04</td>
							    <td>85,366.80</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE8">−</button>
									<input name="SE8" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE8" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE8">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>85,366.80</td>
							    <td>88,587.96</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE9">−</button>
									<input name="SE9" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE9" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE9">+</button>
								</div>
							    </span></td>
						     </tr>
							  <tr class="tabla2">
							    <td>88,587.96</td>
							    <td>And above</td>
							    <td><span class="destacado">
							      <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="SE10">−</button>
									<input name="SE10" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS macro-value" id="SE10" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="SE10">+</button>
								</div>
							    </span></td>
						     </tr>
							  <!-- tr class="tabla2">
							    <td>88,587.97</td>
							    <td>And above</td>
							    <td><span class="destacado">
							      <input name="SE11" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRSUBS" id="SE11" value="35.00">
							    </span></td -->
						     </tr>
						   </tbody>
						</table>
					  </div>
					</div>
				  </div>

					<div class="tabla-envolvente mt-4">
						<table class="tableizer-table tabla-res-ingresos w-100">
							 <tr class="sub-header">
							    <td class="">Concepto</td>
							    <td class="">Valor</td>
						     </tr>
							  <tr class="tabla3">
							    <td>Deductions in minimum wages (#)</td>
							    <td><span class="destacado">
							    <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="DED0">−</button>
									<input name="DED0" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRDEDU macro-value" id="DED0" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="DED0">+</button>
								</div>
							    </span></td>
						     </tr>
							 <tr class="tabla2">
							    <td>Deductions as % of taxable income (%)</td>
							    <td class=""><span class="destacado">
							    <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="DED1">−</button>
									<input name="DED1" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRDEDU macro-value" id="DED1" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="DED1">+</button>
								</div>
							    </span></td>
						     </tr>
							 <tr class="tabla3">
							    <td>Informality (% of people) </td>
							    <td class=""><span class="destacado">
							    <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="DED2">−</button>
									<input name="DED2" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRDEDU macro-value" id="DED2" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="DED2">+</button>
								</div>
                                </span></td>
						     </tr>
							 <tr class="tabla2">
							    <td>Informality (% of people) </td>
							    <td class=""><span class="destacado">
							    <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="DED3">−</button>
									<input name="DED3" type="text" class="liga-sISR__as suma-a actualizaIngreso actualizaPorcentaje ISRDEDU macro-value" id="DED3" value="35.00">
									<button type="button" class="btn-macro btn-up" data-target="DED3">+</button>
								</div>
                                </span></td>
						     </tr>

						</table>
					</div>
				</div>

				<div class="modal-footer mt-3">
					<button type="button" class="isrSub btn btn-lg btn-primary cerrar-actualizar w-100">Calculate</button>
				</div>

		</div>
	</div>
</div>


<!-- Modal Cuotas IMSS -->
<div class="modal fade" id="Modal-cuotas-imss" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl" role="document">
    <div class="modal-content modal-xl">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalLabel">Social Security Contributions</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <i class="material-icons">close</i>
        </button>
      </div>
      <div class="modal-body">
        <div class="tabla-envolvente">

          <div style="width:52%; float:left;">
          <table class="tableizer-table tabla-res-ingresos w-100">
          <tbody>
          <tr class="sub-header">
          <td style="width: 55% !important;">IMSS Contributions</td>
          <td style="width: 15% !important;">Employers</td>
          <td style="width: 12% !important;">Workers</td>
          <td style="width: 15% !important;">Federal Government</td>
          </tr>
          <tr>
          <td>
          <p class="p1">Illness and maternity, insured</p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS0">−</button><input type="text" id="CSSIMSS0" name="CSSIMSS0" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS0">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS1">−</button><input type="text" id="CSSIMSS1" name="CSSIMSS1" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS1">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS2">−</button><input type="text" id="CSSIMSS2" name="CSSIMSS2" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS2">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1">Illness and maternity, pensioners</p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS3">−</button><input type="text" id="CSSIMSS3" name="CSSIMSS3" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS3">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS4">−</button><input type="text" id="CSSIMSS4" name="CSSIMSS4" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS4">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS5">−</button><input type="text" id="CSSIMSS5" name="CSSIMSS5" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS5">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1">Disability and life</p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS6">−</button><input type="text" id="CSSIMSS6" name="CSSIMSS6" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS6">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS7">−</button><input type="text" id="CSSIMSS7" name="CSSIMSS7" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS7">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS8">−</button><input type="text" id="CSSIMSS8" name="CSSIMSS8" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS8">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1">Work risks</p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS9">−</button><input type="text" id="CSSIMSS9" name="CSSIMSS9" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS9">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS10">−</button><input type="text" id="CSSIMSS10" name="CSSIMSS10" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS10">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS11">−</button><input type="text" id="CSSIMSS11" name="CSSIMSS11" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS11">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1">Daycare and social benefits</p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS12">−</button><input type="text" id="CSSIMSS12" name="CSSIMSS12" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS12">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS13">−</button><input type="text" id="CSSIMSS13" name="CSSIMSS13" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS13">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS14">−</button><input type="text" id="CSSIMSS14" name="CSSIMSS14" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS14">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Retirement, old age unemployment and old age<br><br></span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS15">−</button><input type="text" id="CSSIMSS15" name="CSSIMSS15" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS15">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS16">−</button><input type="text" id="CSSIMSS16" name="CSSIMSS16" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS16">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS17">−</button><input type="text" id="CSSIMSS17" name="CSSIMSS17" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS17">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Social contribution -- up to 25 UMA --</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS18">−</button><input type="text" id="CSSIMSS18" name="CSSIMSS18" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS18">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS19">−</button><input type="text" id="CSSIMSS19" name="CSSIMSS19" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS19">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSIMSS20">−</button><input type="text" id="CSSIMSS20" name="CSSIMSS20" class="CSSIMSS macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSIMSS20">+</button></div></td>
          </tr>
          </tbody>
          </table>
          </div>

          <div style="width:48%; float:left;">
          <table class="tableizer-table tabla-res-ingresos w-100">
          <tbody>
          <tr class="sub-header">
          <td style="width: 55% !important;">ISSSTE Contributions</td>
          <td style="width: 15% !important;">Employers</td>
          <td style="width: 12% !important;">Workers</td>
          <td style="width: 15% !important;">Federal Government</td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Health insurance<br>workers<br></span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE0">−</button><input type="text" id="CSSISSSTE0" name="CSSISSSTE0" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE0">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE1">−</button><input type="text" id="CSSISSSTE1" name="CSSISSSTE1" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE1">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE2">−</button><input type="text" id="CSSISSSTE2" name="CSSISSSTE2" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE2">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Health insurance<br>pensioners<br></span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE3">−</button><input type="text" id="CSSISSSTE3" name="CSSISSSTE3" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE3">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE4">−</button><input type="text" id="CSSISSSTE4" name="CSSISSSTE4" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE4">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE5">−</button><input type="text" id="CSSISSSTE5" name="CSSISSSTE5" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE5">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Work risk</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE6">−</button><input type="text" id="CSSISSSTE6" name="CSSISSSTE6" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE6">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE7">−</button><input type="text" id="CSSISSSTE7" name="CSSISSSTE7" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE7">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE8">−</button><input type="text" id="CSSISSSTE8" name="CSSISSSTE8" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE8">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Disability and life</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE9">−</button><input type="text" id="CSSISSSTE9" name="CSSISSSTE9" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE9">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE10">−</button><input type="text" id="CSSISSSTE10" name="CSSISSSTE10" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE10">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE11">−</button><input type="text" id="CSSISSSTE11" name="CSSISSSTE11" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE11">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Social and cultural services</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE12">−</button><input type="text" id="CSSISSSTE12" name="CSSISSSTE12" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE12">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE13">−</button><input type="text" id="CSSISSSTE13" name="CSSISSSTE13" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE13">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE14">−</button><input type="text" id="CSSISSSTE14" name="CSSISSSTE14" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE14">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Retirement, old age unemployment and old age</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE15">−</button><input type="text" id="CSSISSSTE15" name="CSSISSSTE15" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE15">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE16">−</button><input type="text" id="CSSISSSTE16" name="CSSISSSTE16" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE16">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE17">−</button><input type="text" id="CSSISSSTE17" name="CSSISSSTE17" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE17">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Housing<br><br></span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE18">−</button><input type="text" id="CSSISSSTE18" name="CSSISSSTE18" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE18">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE19">−</button><input type="text" id="CSSISSSTE19" name="CSSISSSTE19" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE19">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE20">−</button><input type="text" id="CSSISSSTE20" name="CSSISSSTE20" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE20">+</button></div></td>
          </tr>
          <tr>
          <td>
          <p class="p1"><span>Social contribution</span></p>
          </td>
          <td class=" "><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE21">−</button><input type="text" id="CSSISSSTE21" name="CSSISSSTE21" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE21">+</button></div></td>
          <td class="ISRCUFIb"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE22">−</button><input type="text" id="CSSISSSTE22" name="CSSISSSTE22" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE22">+</button></div></td>
          <td class="numeros"><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="CSSISSSTE23">−</button><input type="text" id="CSSISSSTE23" name="CSSISSSTE23" class="CSSISSSTE macro-value" value="0.00" /><button type="button" class="btn-macro btn-up" data-target="CSSISSSTE23">+</button></div></td>
          </tr>
          </tbody>
          </table>
          </div>

        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="isrSub btn btn-lg btn-primary cerrar-actualizar w-100" id="btn-actualizar0b">Calculate</button>
      </div>
    </div>
  </div>
</div>


	<!-- Modal-ISR-2 -->
	<div class="modal fade" id="Modal-ISR-2" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
		<div class="modal-dialog modal-lg" role="document">
			<div class="modal-content modal-lg">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">CIT Law. Article 9.</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<i class="material-icons">close</i>
					</button>
				</div>
				<div class="modal-body">
					<div class="tabla-envolvente">
						<table class="tableizer-table tabla-res-ingresos w-100">
						   <tbody>
							  <tr class="sub-header">
								 <td width="61.8%">Concept</td>
								 <td>Value</td>
							  </tr>
							  <tr>
								 <td>CIT rate (%)</td>
								 <!--td>47.277</td-->
								 <td><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="ISRMORA0">−</button><input type="number" class="form-control ISRMORA macro-value" id="ISRMORA0" name="ISRMORA0" value="10.8" step=".001" min="0" max="100" required><button type="button" class="btn-macro btn-up" data-target="ISRMORA0">+</button></div></td>
							  </tr>
							  <tr>
								 <td>Informality (% of people)</td>
								 <!--td>2.913</td-->
								 <td><div class="macro-control"><button type="button" class="btn-macro btn-down" data-target="ISRMORA1">−</button><input type="number" class="form-control ISRMORA macro-value" id="ISRMORA1" name="ISRMORA1" value="10.8" step=".001" min="0" max="100" required><button type="button" class="btn-macro btn-up" data-target="ISRMORA1">+</button></div></td>
							  </tr>
						   </tbody>
						</table>
					</div>
				</div>
				<div class="modal-footer">
					<button type="button" class="isrSub btn btn-lg btn-primary cerrar-actualizar w-100" id="btn-actualizar0">Calculate</button>
				</div>
			</div>
		</div>
	</div>

	<!-- Modal-IVA -->
	<div class="modal fade" id="Modal-IVA" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
		<div class="modal-dialog modal-lg" role="document">
			<div class="modal-content modal-lg">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">VAT Law. Articles 1, 2-A and 15.</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<i class="material-icons">close</i>
					</button>
				</div>
				<div class="modal-body">
					<div class="tabla-envolvente">
						<table class="tableizer-table tabla-res-ingresos w-100">
						   <tbody>
							  <tr class="sub-header">
								 <td width="40%"><span>Concept</span></td>
								 <td width="50%"><span class="destacado">Value</span></td>
							  </tr>
							  <tr>
								 <td><span>General rate (%)</span></td>
								 <td><span>
								   <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="IVAT0">−</button>
									<input name="IVAT0" type="number" class="IVAT form-control macro-value" id="IVAT0" max="100" min="0" step=".001" value="16" required>
									<button type="button" class="btn-macro btn-up" data-target="IVAT0">+</button>
								   </div>
								 </span></td>
							  </tr>
							  <tr>
								 <td>Food (non-basic basket)</td>
								 <td>

								 <div><input type="radio" class="IVAT" id="IVAT1a" name="IVAT1" value="1" checked> <label for="IVAT1a">zero rate</label></div>
                                      <div><input type="radio" class="IVAT" id="IVAT1b" name="IVAT1" value="2" > <label for="IVAT1b">exempt</label></div>
                                      <div><input type="radio" class="IVAT" id="IVAT1c" name="IVAT1" value="3" > <label for="IVAT1c">taxed</label></div>

								 </td>
							  </tr>
							  <tr>
								 <td>Rent (housing)</td>
								 <td>

								 <div> <input type="radio" class="IVAT" id="IVAT2a" name="IVAT2" value="1" > <label for="IVAT2a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT2b" name="IVAT2" value="2" checked> <label for="IVAT2b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT2c" name="IVAT2" value="3" > <label for="IVAT2c">taxed</label></div>

								 </td>
							  </tr>
								  <tr>
								 <td>Basic basket (food)</td>
								 <!--td>22.018</td-->
								 <td>

								 <div> <input type="radio" class="IVAT" id="IVAT3a" name="IVAT3" value="1" checked> <label for="IVAT3a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT3b" name="IVAT3" value="2" > <label for="IVAT3b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT3c" name="IVAT3" value="3" > <label for="IVAT3c">taxed</label></div>

								   </td>
							  </tr>


							  <tr>
								 <td>Education (teaching services)</td>
								 <!--td>26.454</td-->
								 <td>

								 <div> <input type="radio" class="IVAT" id="IVAT4a" name="IVAT4" value="1" > <label for="IVAT4a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT4b" name="IVAT4" value="2" checked> <label for="IVAT4b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT4c" name="IVAT4" value="3" > <label for="IVAT4c">taxed</label></div>

								 </td>
							  </tr>
							  <tr>
								 <td>Out-of-home consumption</td>
								 <!--td>26.454</td-->
								 <td>

								 <div> <input type="radio" class="IVAT" id="IVAT5a" name="IVAT5" value="1" > <label for="IVAT5a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT5b" name="IVAT5" value="2" > <label for="IVAT5b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT5c" name="IVAT5" value="3" checked> <label for="IVAT5c">taxed</label></div>

								 </td>
							  </tr>
							  <tr>
								 <td>Pets and pet food</td>
								 <!--td>39.951</td-->
								 <td>

								 <div> <input type="radio" class="IVAT" id="IVAT6a" name="IVAT6" value="1" > <label for="IVAT6a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT6b" name="IVAT6" value="2" > <label for="IVAT6b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT6c" name="IVAT6" value="3" checked> <label for="IVAT6c">taxed</label></div>

								 </td>
							  </tr>
							  <tr>
								<td>Medicines</td>
								<td>

								<div> <input type="radio" class="IVAT" id="IVAT7a" name="IVAT7" value="1" checked> <label for="IVAT7a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT7b" name="IVAT7" value="2" > <label for="IVAT7b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT7c" name="IVAT7" value="3" > <label for="IVAT7c">taxed</label></div>

								</td>
							 </tr>
							  <tr>
								<td>Feminine hygiene products</td>
								<td>

								<div> <input type="radio" class="IVAT" id="IVAT8a" name="IVAT8" value="1" checked> <label for="IVAT8a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT8b" name="IVAT8" value="2" > <label for="IVAT8b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT8c" name="IVAT8" value="3" > <label for="IVAT8c">taxed</label></div>

								</td>
							 </tr>
							  <tr>
								<td>Other products</td>
								<td>

								<div> <input type="radio" class="IVAT" id="IVAT9a" name="IVAT9" value="1" > <label for="IVAT9a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT9b" name="IVAT9" value="2" > <label for="IVAT9b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT9c" name="IVAT9" value="3" checked> <label for="IVAT9c">taxed</label></div>

								</td>
							 </tr>
							  <tr>
								<td>Local transportation</td>
								<td>

								<div> <input type="radio" class="IVAT" id="IVAT10a" name="IVAT10" value="1" > <label for="IVAT10a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT10b" name="IVAT10" value="2" checked> <label for="IVAT10b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT10c" name="IVAT10" value="3" > <label for="IVAT10c">taxed</label></div>

								</td>
							 </tr>
							 <tr>
								<td>Long-distance transportation</td>
								<td>

								<div> <input type="radio" class="IVAT" id="IVAT11a" name="IVAT11" value="1" > <label for="IVAT11a">zero rate</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT11b" name="IVAT11" value="2" > <label for="IVAT11b">exempt</label></div>
                                       <div> <input type="radio" class="IVAT" id="IVAT11c" name="IVAT11" value="3" checked> <label for="IVAT11c">taxed</label></div>

								</td>
							 </tr>

							  <tr>
								<td>Informality + evasion<br>(% of consumption)</td>
								<td><p>
								  <div class="macro-control">
									<button type="button" class="btn-macro btn-down" data-target="IVAT12">−</button>
									<input name="IVAT12" type="number" id="IVAT12" value="14.3" class="IVAT form-control macro-value" step=".001" min="0" max="100" required>
									<button type="button" class="btn-macro btn-up" data-target="IVAT12">+</button>
								  </div>
								</p>
								</td>
							 </tr>

						   </tbody>
						</table>
					</div>

				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-lg btn-primary cerrar-actualizar w-100 isrSub" id="btn-actualizar0">Calculate</button>
				</div>
			</div>
		</div>
	</div>


	<!-- Modal-crecimiento-pib -->
	<!--div class="modal fade" id="Modal-crecimiento-pib" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
		<div class="modal-dialog" role="document">
			<div class="modal-content modal-xl">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">Crecimiento del PIB</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
						<i class="material-icons">close</i>
					</button>
				</div>
				<div class="modal-body">
					<div class="chart m-0" id="pib-2"></div>
				</div>
			</div>
		</div>
	</div-->


	<!-- Modal-crecimiento-pib PERSONALIZADO -->
	<div class="modal" id="modal-pib-custom">
		<div class="modal-dialog">
			<div class="modal-content modal-xl pb-4">
				<div class="modal-header">
					<h5 class="modal-title" id="exampleModalLabel">Gross Domestic Product (GDP)</h5>
					<button type="button" class="close cerrar-custom">
						<i class="material-icons">close</i>
					</button>
				</div>
				<div class="modal-body">
					<div class="chart m-0" id="pib-2"></div>
				</div>
			</div>
		</div>
	</div>



		<script src='https://cdn.fusioncharts.com/fusioncharts/latest/fusioncharts.js'></script>
		<script src='https://cdn.fusioncharts.com/fusioncharts/latest/themes/fusioncharts.theme.fusion.js'></script>

		<!-- Javascripts -->
        <script src="plugins/jquery/jquery-3.4.1.min.js"></script>
        <script src="plugins/bootstrap/popper.min.js"></script>
        <script src="plugins/bootstrap/js/bootstrap.min.js"></script>
        <script src="plugins/jquery-slimscroll/jquery.slimscroll.min.js"></script>
        <script src="plugins/jquery-sparkline/jquery.sparkline.min.js"></script>
        <script src="plugins/apexcharts/dist/apexcharts.min.js"></script>
        <script src="plugins/blockui/jquery.blockUI.js"></script>
		<!-- script src="plugins/chartjs/chart.min.js"></script quitado hoy-->
        <!-- script src="plugins/d3/d3.min.js"></script quitado hoy-->
        <!-- script src="plugins/nvd3/nv.d3.min.js"></script quitado hoy-->
        <script src="plugins/flot/jquery.flot.min.js"></script>
        <script src="plugins/flot/jquery.flot.time.min.js"></script>
        <script src="plugins/flot/jquery.flot.symbol.min.js"></script>
        <script src="plugins/flot/jquery.flot.resize.min.js"></script>
        <script src="plugins/flot/jquery.flot.tooltip.min.js"></script>
		<script src="plugins/apexcharts/dist/apexcharts.min.js"></script>
        <script src="js/connect.js"></script>
        <script src="js/pages/dashboard.js"></script>
		<script src="js/pages/blockui.js"></script>

		<!-- script src="js/pages/charts-v2.js?v=2"></script> <!--  aqui se calculan las graficas-->
		<script src="js/stataCalcula-en.js"></script><!--  calculations for charts-->


		<script>
		$(document).ready(function(){
		    $( "#btn-ingresos" ).click(function() {
				$( ".card-transactions" ).removeClass( "slide-top" );
				$( "#box-ingresos" ).addClass( "slide-top" );
				$(".stats-card .card-body").removeClass("card-active");
				$("#btn-ingresos .card-body").addClass("card-active");
		    });
			$( "#btn-gastos" ).click(function() {
				$( ".card-transactions" ).removeClass( "slide-top" );
				$( "#box-gastos" ).addClass( "slide-top" );
				$(".stats-card .card-body").removeClass("card-active");
				$("#btn-gastos .card-body").addClass("card-active");
		    });
			$( "#btn-pib" ).click(function() {
				$( ".card-transactions" ).removeClass( "slide-top" );
				$( "#box-pib" ).addClass( "slide-top" );
				$(".stats-card .card-body").removeClass("card-active");
				$("#btn-pib .card-body").addClass("card-active");
		    });


			$( "#reset-ingresos" ).click(function() {
				$("#box-ingresos").addClass("blink-2");
				setTimeout( function(){
					$("#box-ingresos").removeClass("blink-2");
				},1000);
			});
			$( "#reset-gastos" ).click(function() {
				$("#box-gastos").addClass("blink-2");
				setTimeout( function(){
					$("#box-gastos").removeClass("blink-2");
				},1000);
			});
			$( "#reset-pib" ).click(function() {
				$("#box-pib").addClass("blink-2");
				setTimeout( function(){
					$("#box-pib").removeClass("blink-2");
				},1000);
			});



			$( "#res1-100" ).click(function() {
				$( "#res-01" ).toggleClass( "w-100" );
			});
			$( "#res2-100" ).click(function() {
				$( "#res-02" ).toggleClass( "w-100" );
			});
			$( "#res3-100" ).click(function() {
				$( "#res-03" ).toggleClass( "w-100" );
			});
			$( "#res4-100" ).click(function() {
				$( "#res-04" ).toggleClass( "w-100" );
			});
			$( "#res5-100" ).click(function() {
				$( "#res-05" ).toggleClass( "w-100" );
			});
			$( "#res6-100" ).click(function() {
				$( "#res-06" ).toggleClass( "w-100" );
			});


		});



		</script>

		<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>

		<script src="https://cdnjs.cloudflare.com/ajax/libs/ekko-lightbox/5.3.0/ekko-lightbox.min.js"></script>

		<script>
    // julio-24 Daniel // Inicializar las pestañas
    $("#tabs").tabs(); //initialize tabs
    $(function() {
      $("#tabs").tabs({
        activate: function(event, ui) {
          var scrollTop = $(window).scrollTop(); // save current scroll position
          window.location.hash = ui.newPanel.attr('id'); // add hash to url
          //$(window).scrollTop(scrollTop); // keep scroll at current position
          $('html, body').animate({
              scrollTop: $("#parametros-box").offset().top
          }, 0); // La duración del desplazamiento es de 1000 milisegundos (1 segundo)
        }
      });
    });

    $("#tabs-2").tabs(); //initialize tabs
    $(function() {
      $("#tabs-2").tabs({
        activate: function(event, ui) {
          var scrollTop = $(window).scrollTop(); // save current scroll position
          window.location.hash = ui.newPanel.attr('id'); // add hash to url
          //$(window).scrollTop(scrollTop); // keep scroll at current position
          $('html, body').animate({
              scrollTop: $("#parametros-box").offset().top
          }, 0); // La duración del desplazamiento es de 1000 milisegundos (1 segundo)
        }
      });
    });

    $(document).ready(function() {
        $('#btn-ingresos, #btn-gastos').click(function() {
            $('html, body').animate({
                scrollTop: $("#parametros-box").offset().top
            }, 0); // La duración del desplazamiento es de 1000 milisegundos (1 segundo)
        });
    });




			$("#tabs-sankeys").tabs(); //initialize tabs
			$(function() {
				$("#tabs-sankeys").tabs({
					activate: function(event, ui) {
						var scrollTop = $(window).scrollTop(); // save current scroll position
						window.location.hash = ui.newPanel.attr('id'); // add hash to url
						$(window).scrollTop(scrollTop); // keep scroll at current position
					}
				});
			});

			$("#tabs-donaciones").tabs(); //initialize tabs
			$(function() {
				$("#tabs-donaciones").tabs({
					activate: function(event, ui) {
						var scrollTop = $(window).scrollTop(); // save current scroll position
						window.location.hash = ui.newPanel.attr('id'); // add hash to url
						$(window).scrollTop(scrollTop); // keep scroll at current position
					}
				});
			});

			$(window).scroll(function() {
			   var hT = $('#trigger-fix').offset().top,
				   wS = $(this).scrollTop();
			   if (wS > hT){
				   $('#formula-fija').addClass( "fixed" );
			   } else {
				   $('#formula-fija').removeClass( "fixed" );
			   }
			});
		  </script>

		<script>
		var range1 = $('.input-range-1'),
			value1 = $('.range-value-1'),
			range2 = $('.input-range-2'),
			value2 = $('.range-value-2'),
			range3 = $('.input-range-3'),
			value3 = $('.range-value-3'),
			range4 = $('.input-range-4'),
			value4 = $('.range-value-4'),
			range5 = $('.input-range-5'),
			value5 = $('.range-value-5');

		value1.html(range1.attr('value'));
		value2.html(range1.attr('value'));
		value3.html(range1.attr('value'));
		value4.html(range1.attr('value'));
		value5.html(range1.attr('value'));

		range1.on('input', function(){
			value1.html(this.value);
		});
		range2.on('input', function(){
			value2.html(this.value);
		});
		range3.on('input', function(){
			value3.html(this.value);
		});
		range4.on('input', function(){
			value4.html(this.value);
		});
		range5.on('input', function(){
			value5.html(this.value);
		});


		window.FontAwesomeConfig = {
			searchPseudoElements: true
		  }

		  /** funciones movida a stataCalcual.js *  /
		  $( ".form-control" ).click(function() {
			  /*$( "#box-actualizar" ).removeClass( "slide-top-reverse" );* /
			  $( "#box-actualizar" ).addClass( "slide-top" );
			});
		$( ".cerrar-actualizar" ).click(function() {
			  $( "#box-actualizar" ).removeClass( "slide-top" );
			  /*$( "#box-actualizar" ).addClass( "slide-top-reverse" );* /
			});

		$( "#btn-actualizar, #btn-reestablecer" ).click(function() {
			  $( ".table" ).addClass( "blink-1" );
			  setTimeout(function() {
					$(".table").removeClass( "blink-1" );
				}, 1500);
			});

		$( "#btn-actualizar" ).click(function() {
			  $( "#ampliar" ).addClass( "opacity1" );
			});
			/*******************/

		$( "#ampliar" ).click(function() {
			  $( "#ampliar" ).removeClass( "opacity1" );
			});


		$('.carousel').carousel({
		  interval: 80000,
		  pause: false
		});

		$(document).on('click', '[data-toggle="lightbox"]', function(event) {
                event.preventDefault();
                $(this).ekkoLightbox();
        });

		$(function() {
		  $("#btn-sankey-1").click(function() {
			$(this).toggleClass("active");
			$("#sankey-num1").addClass("visible");
			$("#sankey-num2").removeClass("visible");
			$("#sankey-num3").removeClass("visible");
			$("#sankey-num4").removeClass("visible");
			$("#sankey-num5").removeClass("visible");
		  });

		  $("#btn-sankey-2").click(function() {
			$(this).toggleClass("active");
			$("#sankey-num1").removeClass("visible");
			$("#sankey-num2").addClass("visible");
			$("#sankey-num3").removeClass("visible");
			$("#sankey-num4").removeClass("visible");
			$("#sankey-num5").removeClass("visible");
		  });

		  $("#btn-sankey-3").click(function() {
			$(this).toggleClass("active");
			$("#sankey-num1").removeClass("visible");
			$("#sankey-num2").removeClass("visible");
			$("#sankey-num3").addClass("visible");
			$("#sankey-num4").removeClass("visible");
			$("#sankey-num5").removeClass("visible");
		  });

		  $("#btn-sankey-4").click(function() {
			$(this).toggleClass("active");
			$("#sankey-num1").removeClass("visible");
			$("#sankey-num2").removeClass("visible");
			$("#sankey-num3").removeClass("visible");
			$("#sankey-num4").addClass("visible");
			$("#sankey-num5").removeClass("visible");
		  });

		  $("#btn-sankey-5").click(function() {
			$(this).toggleClass("active");
			$("#sankey-num1").removeClass("visible");
			$("#sankey-num2").removeClass("visible");
			$("#sankey-num3").removeClass("visible");
			$("#sankey-num4").removeClass("visible");
			$("#sankey-num5").addClass("visible");
		  });

		  $("#lupa").click(function() {
			$("#modal-pib-custom").addClass("activo");
		  });
		  $(".cerrar-custom").click(function() {
			$("#modal-pib-custom").removeClass("activo");
		  });

		});

		</script>

		<script>
		  $( function() {
			$( "#accordion" ).accordion();
		  } );
		</script>

    <script>
    		var countdownTimer = null;

    		function startCountdown(seconds) {
    			if (countdownTimer) clearInterval(countdownTimer);
    			var counter = seconds;
    			$('#count').text(counter);
    			$('#cargando-notify').addClass('active');
    			countdownTimer = setInterval(function() {
    				counter--;
    				if (counter > 0) {
    					$('#count').text(counter);
    				}
    				if (counter === 0) {
    					clearInterval(countdownTimer);
    					countdownTimer = null;
    				}
    			}, 1000);
    		}

    		$( "#isrSub" ).click(function() { startCountdown(35); });
    		$( "#Modal-ISR-1 .isrSub" ).click(function() { startCountdown(35); });
    		$( "#Modal-cuotas-imss .isrSub" ).click(function() { startCountdown(35); });
    		$( "#Modal-IVA .isrSub" ).click(function() { startCountdown(35); });
    		$( "#Modal-ISR-2 .isrSub" ).click(function() { startCountdown(35); });

    		</script>

		<script>
		if (navigator.appVersion.indexOf("Mac")!=-1) OSName="MacOS";

			var isOpera = !!window.opera || navigator.userAgent.indexOf('Opera') >= 0;
			// Opera 8.0+ (UA detection to detect Blink/v8-powered Opera)
			var isFirefox = typeof InstallTrigger !== 'undefined';   // Firefox 1.0+
			var isSafari = Object.prototype.toString.call(window.HTMLElement).indexOf('Constructor') > 0;
			// At least Safari 3+: "[object HTMLElementConstructor]"
			var isChrome = !!window.chrome;                          // Chrome 1+
			var isIE = /*@cc_on!@*/false;                            // At least IE6

			if(OSName == "MacOS" && isChrome == true)
			{
				$( "#mac-txt" ).show();
			}
		</script>


    </body>
</html>
