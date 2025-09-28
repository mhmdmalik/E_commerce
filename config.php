<?php
// config.php - update with your XAMPP MySQL credentials if needed
$DB_HOST = 'localhost';
$DB_NAME = 'e_commerce';
$DB_USER = 'root';
$DB_PASS = '';
$mysqli = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);
if ($mysqli->connect_errno) {
    die('DB connection failed: ' . $mysqli->connect_error);
}
// simple helper for escaping
function h($s){ return htmlspecialchars($s, ENT_QUOTES); }
session_start();
?>
