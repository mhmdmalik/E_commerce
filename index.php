<?php
session_start();
require "db.php";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST["email"];
    $pass  = $_POST["password"];

    $sql = "SELECT id, full_name, password_hash FROM users WHERE email=?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $stmt->store_result();
    $stmt->bind_result($id, $name, $hash);

    if ($stmt->fetch() && password_verify($pass, $hash)) {
        $_SESSION["user_id"] = $id;
        $_SESSION["user_name"] = $name;
        header("Location: home.php");
        exit;
    } else {
        echo "Invalid email or password.";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
  <title>Login</title>
   <link rel="stylesheet" href="assets/style.css">
</head>
<body>
  <h2>Login</h2>
  <form method="post">
    <input type="email" name="email" placeholder="Email" required><br>
    <input type="password" name="password" placeholder="Password" required><br>
    <button type="submit">Login</button>
  </form>
  <p>Don’t have an account? <a href="signup.php">Signup here</a></p>
</body>
</html>
