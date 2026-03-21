<?php 
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="shortcut icon" href="./../assets/icon/favicon.ico" type="image/x-icon">
    <link rel="stylesheet" href="./../assets/fonts/Gloock/stylesheet.css">
    <link rel="stylesheet" href="./../assets/fonts/Gantari/stylesheet.css">
    <link rel="stylesheet" href="./../css/general.css">
    <link rel="stylesheet" href="./../css/home.css">
    <script type="module" src="./../js/home.js"></script>
    <title>noisExpression : : Home</title>
    <?php 
        if (!isset($_SESSION['username'])) {   
            echo "<script>sessionStorage.clear();</script>";
        }
    ?>
</head>
<body id="home">
    
    <main class="home-main">
        
    </main>
    <footer class="home-footer">
        <div>
            Copyright &copy; 2025. Made by Michele S.
        </div>
    </footer>
</body>

</html>