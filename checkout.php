<?php
require 'config.php';
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$cart = $_SESSION['cart'] ?? [];

if (empty($cart)) {
    header('Location: cart.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($cart)) {
    // Generate unique order number
    $order_number = "ORD-" . date("YmdHis") . "-" . substr(uniqid(), -6);

    // Calculate total
    $total = 0;
    foreach ($cart as $c) {
        $total += $c['price'] * $c['qty'];
    }

    // Example user_id (replace with logged-in user's id if available)
    $user_id = $_SESSION['user_id'] ?? 1;

    // Insert into orders
    $stmt = $mysqli->prepare("INSERT INTO orders (order_number, user_id, status, total) VALUES (?, ?, 'Pending', ?)");
    if (!$stmt) {
        die("Prepare failed: " . $mysqli->error);
    }
    $stmt->bind_param("sid", $order_number, $user_id, $total);

    if ($stmt->execute()) {
        $order_id = $stmt->insert_id;
    } else {
        die("Order insert failed: " . $stmt->error);
    }

    // Make sure order_id is valid
    if ($order_id > 0) {
        // Insert order items
        $stmt_item = $mysqli->prepare(
            "INSERT INTO order_items (order_id, variant_id, quantity, unit_price, line_total) 
             VALUES (?, ?, ?, ?, ?)"
        );
        if (!$stmt_item) {
            die("Prepare failed: " . $mysqli->error);
        }

        foreach ($cart as $vid => $c) {
            $line_total = $c['price'] * $c['qty'];
            $unit_price = $c['price'];
            $stmt_item->bind_param("iiidd", $order_id, $vid, $c['qty'], $unit_price, $line_total);

            if (!$stmt_item->execute()) {
                die("Order item insert failed: " . $stmt_item->error);
            }
        }
    }

    // Clear cart
    unset($_SESSION['cart']);
}
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Checkout</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
  <h1>My Shop</h1>
</header>
<main>
  <?php if (isset($order_number)): ?>
    <div class="success">
      <p>✅ Order placed successfully!</p>
      <p><strong>Order number:</strong> <?php echo htmlspecialchars($order_number); ?></p>
      <p><strong>Amount Paid:</strong> ₹<?php echo number_format($total, 2); ?></p>
      <a href="view_order.php?order_id=<?php echo $order_id; ?>" class="btn">View Order Details</a>
      <a href="index.php" class="btn">← Back to shop</a>
    </div>
  <?php else: ?>
    <p>No order was placed.</p>
    <a href="cart.php" class="btn">Back to Cart</a>
  <?php endif; ?>
</main>
</body>
</html>
