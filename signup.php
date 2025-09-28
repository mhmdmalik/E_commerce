<?php
session_start();
require "db.php";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name  = $_POST["name"];
    $email = $_POST["email"];
    $pass  = password_hash($_POST["password"], PASSWORD_BCRYPT);

    $sql = "INSERT INTO users (full_name, email, password_hash) VALUES (?,?,?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $name, $email, $pass);

    if ($stmt->execute()) {
        $_SESSION["user_id"] = $stmt->insert_id;
        $_SESSION["user_name"] = $name;
        header("Location: home.php");
        exit;
    } else {
        echo "Error: " . $stmt->error;
    }
}
?>

<!DOCTYPE html>
<html>
<head>
  <title>Signup</title>
   <link rel="stylesheet" href="assets/style.css">
</head>
<body>
  <h2>Signup</h2>
  <form method="post">
    <input type="text" name="name" placeholder="Full Name" required><br>
    <input type="email" name="email" placeholder="Email" required><br>
    <input type="password" name="password" placeholder="Password" required><br>
    <button type="submit">Signup</button>
  </form>
  <p>Already have an account? <a href="index.php">Login here</a></p>
</body>
</html>
