<?php
require 'config.php';
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$cart = $_SESSION['cart'] ?? [];
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>My Cart</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
  <h1>My Shop</h1>
  <a href="index.php">← Continue Shopping</a>
</header>
<main>
  <h2>Your Cart</h2>
  <?php if (empty($cart)): ?>
    <p>Your cart is empty.</p>
  <?php else: ?>
    <table>
      <tr>
        <th>Product</th>
        <th>Quantity</th>
        <th>Price</th>
        <th>Subtotal</th>
      </tr>
      <?php
      $total = 0;
      foreach ($cart as $c):
          $subtotal = $c['price'] * $c['qty'];
          $total += $subtotal;
      ?>
      <tr>
        <td><?php echo htmlspecialchars($c['title']); ?></td>
        <td><?php echo $c['qty']; ?></td>
        <td>₹<?php echo number_format($c['price'], 2); ?></td>
        <td>₹<?php echo number_format($subtotal, 2); ?></td>
      </tr>
      <?php endforeach; ?>
      <tr>
        <td colspan="3" align="right"><strong>Total</strong></td>
        <td><strong>₹<?php echo number_format($total, 2); ?></strong></td>
      </tr>
    </table>

    <!-- Place Order button -->
    <form action="checkout.php" method="post">
      <button type="submit">Place Order</button>
    </form>
  <?php endif; ?>
</main>
</body>
</html>
