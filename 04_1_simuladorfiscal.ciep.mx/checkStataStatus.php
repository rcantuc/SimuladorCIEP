<?php
/**
 * Endpoint para verificar si Stata terminó de ejecutarse
 * Usado para polling desde JavaScript
 */
include_once("config.php");

header('Content-type: application/json; charset=utf-8');

// Revisión de seguridad v8.11a: idSession solo alfanumérico (es nombre de
// directorio bajo $TMP_PATH); inválido o ausente → 400 (helper en config.php).
$idSession = lee_idSession();

$working_dir = $TMP_PATH . $idSession;
$done_file = $working_dir . "/" . $idSession . ".done";
$output_file = $working_dir . "/output.txt";
$log_file = $working_dir . "/" . $idSession . ".log";

$response = [
    'idSession' => $idSession,
    'status' => 'running'
];

// Limpiar caché de stat
clearstatcache(true, $done_file);
clearstatcache(true, $output_file);

// Verificar si Stata terminó
if (file_exists($done_file)) {
    $exit_code = trim(file_get_contents($done_file));
    $response['exit_code'] = $exit_code;
    
    // Verificar si output.txt existe
    if (file_exists($output_file)) {
        $response['status'] = 'completed';
        
        // Leer y parsear output.txt
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
                // Es un array - convertir a array PHP
                $valor_limpio = str_replace(" ", "", $valor);
                $valor_limpio = substr($valor_limpio, 1, -1); // Remover [ y ]
                $elementos = explode(",", $valor_limpio);
                $response[$nombre] = $elementos;
            } else {
                // Es un valor simple
                $response[$nombre] = $valor;
            }
        }
    } else {
        $response['status'] = 'error';
        $response['error'] = 'output.txt not found';
        
        // Incluir log si existe
        if (file_exists($log_file)) {
            $response['log'] = file_get_contents($log_file);
        }
    }
} else {
    // Stata todavía está corriendo
    $response['status'] = 'running';
    
    // Verificar si el proceso sigue vivo
    $pid_file = $working_dir . "/" . $idSession . ".pid";
    if (file_exists($pid_file)) {
        $pid = trim(file_get_contents($pid_file));
        $response['pid'] = $pid;
        
        // Verificar si el proceso existe (solo si el .pid trae un entero: el
        // archivo vive en el directorio de sesión y no se interpola nada más)
        if (ctype_digit($pid)) {
            exec("ps -p " . escapeshellarg($pid), $output, $return_var);
            $response['process_alive'] = ($return_var === 0);
        } else {
            $response['process_alive'] = false;
        }
    }
}

echo json_encode($response);
?>
