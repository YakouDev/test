<?php
set_time_limit(0);
error_reporting(0);
header('Content-Type: application/json');

$api_key = 'e4d0bf40-fdbe-401e-b359-335efd380705';

$host = $_GET['ip'];
$hwid = $_GET['hwid'];

// Verifikasi API Key
if ($_SERVER['HTTP_X_API_KEY'] !== $api_key) {
    $status = array(
        "status" => 403,
        "msg" => "Access denied"
    );
    echo json_encode($status, JSON_PRETTY_PRINT);
    exit;
}

// Memeriksa HWID dari berkas hwid.txt
$allowed_hwid = array("testing");
if (!in_array($hwid, $allowed_hwid)) {
    $status = array(
        "status" => 403,
        "msg" => "Access denied"
    );
    echo json_encode($status, JSON_PRETTY_PRINT);
    exit;
}

// Fungsi untuk mengambil data menggunakan cURL
function http_get($url)
{
    $im = curl_init($url);
    curl_setopt($im, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($im, CURLOPT_CONNECTTIMEOUT, 10);
    curl_setopt($im, CURLOPT_FOLLOWLOCATION, 1);
    curl_setopt($im, CURLOPT_HEADER, 0);
    $response = curl_exec($im);
    curl_close($im);
    return $response;
}

$domains = http_get("https://api.threatminer.org/v2/host.php?q=$host&rt=2");
$data = json_decode($domains, true);

foreach ($data['results'] as $key) {
    $domain[] = $key['domain'];
}

if (empty($host)) {
    $status = array(
        "status" => 400,
        "msg" => "Bad Requests",
    );
} elseif ($data['status_code'] == 200) {
    $status = array(
        "status" => 200,
        "msg" => "Domain found",
        "domain" => $domain
    );
} else {
    $status = array(
        "status" => 404,
        "msg" => "No Domain found",
    );
}

echo json_encode($status, JSON_PRETTY_PRINT);
?>
