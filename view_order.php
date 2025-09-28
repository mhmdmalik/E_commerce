<?php
require 'config.php';
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_GET['order_id'])) {
    die("Order not found.");
}

$order_id = (int)$_GET['order_id'];

// Fetch order
$sql = "SELECT * FROM orders WHERE id=?";
$stmt = $mysqli->prepare($sql);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$order = $stmt->get_result()->fetch_assoc();

// Fetch order items
$sql_items = "SELECT oi.quantity, oi.line_total, pv.title, pv.sku
              FROM order_items oi
              JOIN product_variants pv ON oi.variant_id = pv.id
              WHERE oi.order_id=?";
$stmt_items = $mysqli->prepare($sql_items);
$stmt_items->bind_param("i", $order_id);
$stmt_items->execute();
$items = $stmt_items->get_result();
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Order Details</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
  <h1>Order Details</h1>
</header>
<main>
  <?php if ($order): ?>
    <div class="order-box">
      <h2>Order #<?php echo htmlspecialchars($order['order_number']); ?></h2>
      <p><strong>Status:</strong> <?php echo htmlspecialchars($order['status']); ?></p>
      <p><strong>Total:</strong> ₹<?php echo number_format($order['total'],2); ?></p>
      <p><strong>Date:</strong> <?php echo $order['created_at']; ?></p>
    </div>

    <h3>Items</h3>
    <table>
      <tr>
        <th>Product</th>
        <th>SKU</th>
        <th>Quantity</th>
        <th>Line Total</th>
      </tr>
      <?php while ($row = $items->fetch_assoc()): ?>
      <tr>
        <td><?php echo htmlspecialchars($row['title']); ?></td>
        <td><?php echo htmlspecialchars($row['sku']); ?></td>
        <td><?php echo $row['quantity']; ?></td>
        <td>₹<?php echo number_format($row['line_total'],2); ?></td>
      </tr>
      <?php endwhile; ?>
    </table>
    <a href="index.php" class="btn">← Back to Shop</a>
  <?php else: ?>
    <p>Order not found.</p>
  <?php endif; ?>
</main>
</body>
</html>
