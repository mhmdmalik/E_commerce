
<?php
require 'config.php';
$cart = $_SESSION['cart'] ?? [];
if (empty($cart)) { header('Location: cart.php'); exit; }

// For demo: create a simple order (no payment integration)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // compute totals
    $subtotal = 0;
    foreach($cart as $vid=>$c) $subtotal += $c['price'] * $c['qty'];

    // generate order id and order number
    $order_id = bin2hex(random_bytes(16)); // 32-char hex UUID alternative
    $order_number = 'ORD-'.date('YmdHis').'-'.substr(bin2hex(random_bytes(4)),0,8);

    // insert into orders
    $stmt = $mysqli->prepare('INSERT INTO orders (id, order_number, user_id, total, status) VALUES (?, ?, NULL, ?, ?)');
    $status = 'confirmed';
    $stmt->bind_param('ssds', $order_id, $order_number, $subtotal, $status);
    $stmt->execute();

    // Insert order items
    foreach($cart as $vid=>$c){
        $line = $c['price'] * $c['qty'];
        $item_id = bin2hex(random_bytes(16));
        $stmt2 = $mysqli->prepare('INSERT INTO order_items (id, order_id, variant_id, quantity, unit_price, line_total) VALUES (?, ?, ?, ?, ?, ?)');
        $stmt2->bind_param('sssidd', $item_id, $order_id, $vid, $c['qty'], $c['price'], $line);
        $stmt2->execute();
    }

// clear cart
unset($_SESSION['cart']);
echo '<div class="card order-success">
        <h2>✅ Order Placed!</h2>
        <p>Order number: '.htmlspecialchars($order_number).'</p>
        <a class="btn" href="home.php">Back to shop</a>
      </div>';
exit;

}

// show summary
$subtotal = 0; foreach($cart as $c) $subtotal += $c['price']*$c['qty'];
?>

<!doctype html>
<html>
<head>
  <meta charset="utf-8">
<link rel="stylesheet" href="/ecommerce/assets/style.css">



  <title>Checkout</title>
</head>
<body>
  <header>
    <h1>Checkout</h1>
    <a href="cart.php">← Back to Cart</a>
  </header>

  <main>
    <div class="card">
      <h2>Order Summary</h2>
      <p>Subtotal: ₹<?php echo number_format($subtotal,2); ?></p>
      <form method="post">
        <button type="submit">Place order (demo)</button>
      </form>
    </div>
  </main>
</body>
</html>