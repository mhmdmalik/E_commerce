<?php
require 'config.php';
$variant_id = $_GET['variant_id'] ?? '';
if (!$variant_id) { header('Location: index.php'); exit; }
$stmt = $mysqli->prepare('SELECT pv.id AS variant_id, pv.sku, pv.title, pv.price, p.name FROM product_variants pv JOIN products p ON p.id = pv.product_id WHERE pv.id = ? LIMIT 1');
$stmt->bind_param('s', $variant_id);
$stmt->execute();
$res = $stmt->get_result();
$item = $res->fetch_assoc();
if (!$item) { echo 'Not found'; exit; }
// handle add to cart
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $qty = max(1, (int)$_POST['qty']);
    if (!isset($_SESSION['cart'])) $_SESSION['cart'] = [];
    if (!isset($_SESSION['cart'][$item['variant_id']])) {
        $_SESSION['cart'][$item['variant_id']] = ['title'=>$item['title'],'price'=>$item['price'],'qty'=>$qty];
    } else {
        $_SESSION['cart'][$item['variant_id']]['qty'] += $qty;
    }
    header('Location: cart.php');
    exit;
}
?>
<!doctype html>
<html>
<head><meta charset="utf-8"><title><?php echo h($item['name']); ?></title><link rel="stylesheet" href="assets/style.css"></head>
<body>
<a href="index.php">← Back</a>
<h1><?php echo h($item['name']); ?></h1>
<h2><?php echo h($item['title']); ?></h2>
<p>Price: ₹<?php echo number_format($item['price'],2); ?></p>
<form method="post">
  Quantity: <input type="number" name="qty" value="1" min="1">
  <button type="submit">Add to cart</button>
</form>
</body>
</html>
