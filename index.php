<?php
set_time_limit(0);
error_reporting(0);
header('Content-Type: application/json');
$host = $_GET['ip'];

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

$domains = http_get("https://otx.alienvault.com/api/v1/indicators/IPv4/$host/passive_dns");
$data = json_decode($domains, true);

$domain = [];
if (isset($data['passive_dns']) && is_array($data['passive_dns'])) {
    foreach ($data['passive_dns'] as $key) {
        $domain[] = $key['hostname'];
    }
}

if (empty($host)) {
    $status = array(
        "status" => 400,
        "msg" => "Bad Requests"
    );
} elseif (empty($domain)) {
    $status = array(
        "status" => 404,
        "msg" => "No Domain found"
    );
} else {
    $status = array(
        "status" => 200,
        "msg" => "Domain found",
        "domain" => $domain
    );
}
echo json_encode($status, JSON_PRETTY_PRINT);
?>
