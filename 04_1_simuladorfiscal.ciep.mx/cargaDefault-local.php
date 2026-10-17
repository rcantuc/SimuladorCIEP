<?php
header('Content-type: application/json; charset=utf-8');

$jsondata = array(
    'GASTOS' => array_fill(0, 50, 23.0),
    'INGRESOS' => array_fill(0, 50, 20.8),
    'DEUDAPARAM' => array(2.2, 2.2, 2.2),
    'PROYSHRFSP1' => array_fill(0, 20, 45.0),
    'PROYSHRFSP2' => array_fill(0, 20, 48.0),
    'PROYSHRFSP3' => array_fill(0, 20, 300000),
    'PROYMAX' => 2050,
    'ISRTASA' => array_fill(0, 50, 0.0),
    'GASTOSPC' => array_fill(0, 50, 0.0),
);

echo json_encode($jsondata);
?>
