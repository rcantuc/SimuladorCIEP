<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 0); // No mostrar errores en pantalla, solo en el log

$debugInfo = [];

try {
    // Configuración del archivo de log
    $logFile = __DIR__ . '/logs/calcular_clicks.log';
    $logDir = __DIR__ . '/logs';
    
    $debugInfo['logFile'] = $logFile;
    $debugInfo['logDir'] = $logDir;
    $debugInfo['currentDir'] = __DIR__;
    
    // Crear directorio de logs si no existe
    if (!file_exists($logDir)) {
        $created = mkdir($logDir, 0777, true);
        $debugInfo['dirCreated'] = $created;
        if (!$created) {
            throw new Exception("No se pudo crear el directorio de logs");
        }
    } else {
        $debugInfo['dirExists'] = true;
    }
    
    // Verificar permisos de escritura
    if (!is_writable($logDir)) {
        chmod($logDir, 0777);
    }
    $debugInfo['dirWritable'] = is_writable($logDir);
    
    // Obtener datos del cliente
    $timestamp = date('Y-m-d H:i:s');
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
    
    // Obtener datos adicionales del POST
    // Revisión de seguridad v8.11a: lo que entra a la bitácora se acota a un
    // token corto sin saltos de línea ni controles (una línea por clic; sin
    // inyección de renglones falsos). Lo que no cumple se registra como 'invalid'.
    $sessionId = $_POST['sessionId'] ?? $_GET['sessionId'] ?? 'unknown';
    $pageVersion = $_POST['pageVersion'] ?? $_GET['pageVersion'] ?? 'es';
    $sessionId = (is_string($sessionId) && preg_match('/^[A-Za-z0-9_-]{1,32}$/', $sessionId)) ? $sessionId : 'invalid';
    $pageVersion = (is_string($pageVersion) && preg_match('/^[a-z]{2}$/', $pageVersion)) ? $pageVersion : 'invalid';
    $userAgent = preg_replace('/[^\x20-\x7E]/', '?', $userAgent);
    
    $debugInfo['receivedData'] = [
        'sessionId' => $sessionId,
        'pageVersion' => $pageVersion,
        'method' => $_SERVER['REQUEST_METHOD']
    ];
    
    // Preparar línea de log
    $logLine = sprintf(
        "[%s] IP: %s | Session: %s | Version: %s | UserAgent: %s\n",
        $timestamp,
        $ip,
        $sessionId,
        $pageVersion,
        substr($userAgent, 0, 100)
    );
    
    // Escribir al archivo de log
    $success = file_put_contents($logFile, $logLine, FILE_APPEND | LOCK_EX);
    
    $debugInfo['writeSuccess'] = ($success !== false);
    $debugInfo['bytesWritten'] = $success;
    
    if ($success !== false) {
        // v8.11a: sin 'debug' en la respuesta pública (traía rutas del servidor);
        // el JS no lo consume.
        echo json_encode([
            'status' => 'success',
            'message' => 'Click registrado correctamente',
            'timestamp' => $timestamp
        ]);
    } else {
        throw new Exception("file_put_contents retornó false");
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'debug' => $debugInfo,
        'error_details' => error_get_last()
    ]);
}
?>
