<?php
// beacon.php — NEXUSTRACE backend
// Ethical: geolocation accepted only after client consent (client sends 'consent' boolean).
// Writes structured lines to capture/nexustrace.log and prints a live box to PHP error log (visible to serve.sh).

declare(strict_types=1);
date_default_timezone_set('UTC');

header('Content-Type: application/json; charset=utf-8');
// For convenience during testing, uncomment below (restrict in production):
// header('Access-Control-Allow-Origin: *');

$raw = file_get_contents('php://input');

// Basic validation
if ($raw === false || trim($raw) === '') {
    http_response_code(400);
    echo json_encode(['ok'=>false, 'error'=>'empty body']);
    exit;
}

$data = json_decode($raw, true);
if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['ok'=>false, 'error'=>'invalid json', 'msg'=>json_last_error_msg()]);
    exit;
}

// Build entry
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$ua = $_SERVER['HTTP_USER_AGENT'] ?? '';
$ts = gmdate('Y-m-d H:i:s') . ' UTC';

$entry = [
    'timestamp' => $ts,
    'ip' => $ip,
    'ua' => $ua,
    'consent' => isset($data['consent']) ? (bool)$data['consent'] : false,
    'lat' => null,
    'lon' => null,
    'accuracy' => null,
    'maps' => null,
];

// If consent and lat/lon provided, capture them
if ($entry['consent'] === true && isset($data['lat']) && isset($data['lon'])) {
    $lat = is_numeric($data['lat']) ? (float)$data['lat'] : null;
    $lon = is_numeric($data['lon']) ? (float)$data['lon'] : null;
    $acc = isset($data['accuracy']) && is_numeric($data['accuracy']) ? (float)$data['accuracy'] : null;
    if ($lat !== null && $lon !== null) {
        $entry['lat'] = $lat;
        $entry['lon'] = $lon;
        $entry['accuracy'] = $acc;
        $entry['maps'] = "https://maps.google.com/?q={$lat},{$lon}";
        $status = 'OPTED_IN';
    } else {
        $status = 'INVALID_COORDS';
    }
} else {
    $status = $entry['consent'] ? 'MISSING_COORDS' : 'PERMISSION_REFUSED';
}

// Ensure log dir
$logDir = __DIR__ . DIRECTORY_SEPARATOR . 'capture';
if (!is_dir($logDir)) {
    if (!mkdir($logDir, 0755, true)) {
        http_response_code(500);
        echo json_encode(['ok'=>false, 'error'=>'failed to create capture dir']);
        exit;
    }
}
$logFile = $logDir . DIRECTORY_SEPARATOR . 'nexustrace.log';

// Persist: write human-readable line + JSON line
$human = sprintf("[%s] IP: %s | GEO: %s | MAP: %s | STATUS: %s\n",
    $ts,
    $ip,
    ($entry['lat'] !== null && $entry['lon'] !== null) ? "{$entry['lat']},{$entry['lon']}" : 'DENIED',
    $entry['maps'] ?? 'N/A',
    $status
);
$jsonLine = json_encode($entry, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . PHP_EOL;

$ok1 = file_put_contents($logFile, $human, FILE_APPEND | LOCK_EX);
$ok2 = file_put_contents($logFile, $jsonLine, FILE_APPEND | LOCK_EX);

if ($ok1 === false || $ok2 === false) {
    http_response_code(500);
    echo json_encode(['ok'=>false, 'error'=>'failed to write log']);
    exit;
}

// Emit styled activity box to PHP error log so serve.sh can show it live
$box = [];
$box[] = "📡 NEXUS TRACE — NEW ACTIVITY";
$box[] = "┌─────────────────────────────────────────────────────────────┐";
$box[] = sprintf("│ IP         : %-41s │", substr($ip,0,41));
$box[] = sprintf("│ Timestamp  : %-41s │", $ts);
if ($entry['lat'] !== null && $entry['lon'] !== null) {
    $coords = sprintf("%.6f, %.6f", $entry['lat'], $entry['lon']);
    $box[] = sprintf("│ Geolocation: %-41s │", $coords);
    $box[] = sprintf("│ GoogleMap  : %-41s │", $entry['maps']);
    $cons = 'GRANTED';
} else {
    $box[] = sprintf("│ Geolocation: %-41s │", 'DENIED');
    $box[] = sprintf("│ GoogleMap  : %-41s │", 'N/A');
    $cons = 'REFUSED';
}
$box[] = sprintf("│ Consent    : %-41s │", $cons);
$box[] = "└─────────────────────────────────────────────────────────────┘";

foreach ($box as $line) {
    error_log($line);
}

// Successful response to client
echo json_encode(['ok'=>true, 'status'=>$status]);
exit;
