<?php
require 'config.php';
// update quantities
if ($_SERVER['REQUEST_METHOD']==='POST' && isset($_POST['update'])) {
    foreach($_POST['qty'] as $vid => $q) {
        $q = max(0,(int)$q);
        if ($q == 0) {
            unset($_SESSION['cart'][$vid]);
        } else {
            $_SESSION['cart'][$vid]['qty'] = $q;
        }
    }
    header('Location: cart.php'); exit;
}
$cart = $_SESSION['cart'] ?? [];
$subtotal = 0;
foreach($cart as $c) $subtotal += $c['price'] * $c['qty'];
?>
<!doctype html>
<html><head><meta charset="utf-8"><link rel="stylesheet" href="assets/style.css"><title>Cart</title></head>
<body>
<a href="home.php">← Continue shopping</a>
<h1>Your Cart</h1>
<?php if(empty($cart)): ?>
  <p>Cart is empty</p>
<?php else: ?>
  <form method="post">
  <table>
    <tr><th>Item</th><th>Unit</th><th>Qty</th><th>Line</th></tr>
    <?php foreach($cart as $vid => $c): ?>
      <tr>
        <td><?php echo h($c['title']); ?></td>
        <td>₹<?php echo number_format($c['price'],2); ?></td>
        <td><input type="number" name="qty[<?php echo h($vid); ?>]" value="<?php echo h($c['qty']); ?>" min="0"></td>
        <td>₹<?php echo number_format($c['price']*$c['qty'],2); ?></td>
      </tr>
    <?php endforeach; ?>
  </table>
  <p>Subtotal: ₹<?php echo number_format($subtotal,2); ?></p>
  <button name="update" type="submit">Update Cart</button>
  <a href="checkout.php" class="btn">Checkout</a>
  </form>
<?php endif; ?>
</body></html>
