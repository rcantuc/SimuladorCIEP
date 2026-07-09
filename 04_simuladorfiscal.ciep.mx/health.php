<?php
header('Content-Type: text/plain; charset=utf-8');
echo "OK\n";

$version_file = __DIR__ . '/DEPLOYED_COMMIT';
if (file_exists($version_file)) {
    echo "Deployment: " . trim(file_get_contents($version_file)) . "\n";
} else {
    echo "Deployment: unknown (no DEPLOYED_COMMIT file)\n";
}

echo "Timestamp: " . gmdate('c') . "\n";
?>
