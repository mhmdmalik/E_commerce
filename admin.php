<?php
require 'config.php';
if (!isset($_SESSION['user_id']) || $_SESSION['role']!=='admin') {
    header('Location: signin.php'); exit;
}
?>
<!doctype html>
<html><head><meta charset="utf-8"><title>Admin Dashboard</title>
<link rel="stylesheet" href="assets/style.css"></head>
<body>
<h1>Admin Dashboard</h1>
<p>Welcome, <?php echo h($_SESSION['full_name']); ?> (<?php echo h($_SESSION['role']); ?>)</p>
<p><a href="logout.php">Logout</a></p>
<p>[TODO: Inventory management pages]</p>
</body></html>
