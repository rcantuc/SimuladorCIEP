<?php
header('Content-Type: text/plain; charset=utf-8');
echo "OK\n";

$version_file = __DIR__ . '/DEPLOYED_COMMIT';
if (file_exists($version_file)) {
    $deployed = trim(file_get_contents($version_file));
    echo "Deployment: " . $deployed . "\n";
    // Baseline (v8.15b-pre; CUAD-0 §4 ter): tag desde el que los números publicados son comparables. La escribe la
    // Fase 4 de publicar-vps.sh como línea "Baseline:" de DEPLOYED_COMMIT (manifest.json: baseline); si el deploy es
    // anterior a ese campo, se dice explícitamente en vez de callar.
    if (preg_match('/^Baseline:\s*(\S+)\s*$/m', $deployed, $m)) {
        echo "Baseline: " . $m[1] . "\n";
    } else {
        echo "Baseline: n/d (DEPLOYED_COMMIT sin línea Baseline:)\n";
    }
} else {
    echo "Deployment: unknown (no DEPLOYED_COMMIT file)\n";
    echo "Baseline: n/d\n";
}

echo "Timestamp: " . gmdate('c') . "\n";
?>
