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
    <link rel="stylesheet" href="./../css/discover.css">
    <script type="module" src="./../js/discover.js"></script>
    <?php 
        if (!isset($_SESSION['username'])) {   
            echo "<script>sessionStorage.clear();</script>";
        }
    ?>
    <title>noisExpression : : Discover</title>
</head>
<body id="discover">
    
<main class="discover-main">
        <section class="head">
            <h1 id='title-genre'>Generative</h1>
            <p class="description">
                
            </p>
        </section>
        <div class="filter">
            <div class="genre">
                <!-- Generate via JS-->
                
            </div>
            <div class="search">
                <input type="search" placeholder="search artwork title">
            </div>
        </div>
        
    </main>
    <footer class="discover-footer">
        <div>
            Copyright &copy; 2025. Made by Michele S.
        </div>
    </footer>
</body>

</html>