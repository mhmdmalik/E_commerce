<?php
require 'config.php';
// list products (joins first variant)
$sql = "SELECT p.id AS product_id, p.name, p.sku, pv.id AS variant_id, pv.sku AS variant_sku, pv.title, pv.price
        FROM products p
        JOIN product_variants pv ON pv.product_id = p.id
        ORDER BY p.created_at DESC
        LIMIT 50";
$res = $mysqli->query($sql);
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>My Shop</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
  <h1>My Shop</h1>
  <nav>
    <a href="cart.php">
      Cart (<?php echo isset($_SESSION['cart']) ? array_sum(array_column($_SESSION['cart'],'qty')) : 0; ?>)
    </a>
    <!-- Logout Button -->
    <form action="logout.php" method="post" style="display:inline;">
      <button type="submit">Logout</button>
    </form>
  </nav>
</header>
<main>
  <div class="grid">
  <?php while($row = $res->fetch_assoc()): ?>
    <div class="card">
      <h3><?php echo h($row['name']); ?></h3>
      <p><?php echo h($row['title']); ?> — ₹<?php echo number_format($row['price'],2); ?></p>
      <a href="product.php?variant_id=<?php echo urlencode($row['variant_id']); ?>">View / Buy</a>
    </div>
  <?php endwhile; ?>
  </div>
</main>
</body>
</html>
