<?php 
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (!isset($_SESSION['username'])) {
        header('Location: ./home.php');
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
    <link rel="stylesheet" href="./../css/profile.css">
    <script type="module" src="./../js/profile.js"></script>
    <?php 
        if (!isset($_SESSION['username'])) {   
            echo "<script>sessionStorage.clear();</script>";
        }
    ?>
    <title>noisExpression : : Profile</title>
</head>
<body id="profile">
    <main class="profile-main">
        <div class="profile-info">
            <h1>Profile</h1>
            <ul>
                <li class="username">
                    <p>Username: </p> <p>  </p>
                </li>
                <li class="first-name">
                    <p>First Name: </p> <p>  </p>
                </li>
                <li class="last-name">
                    <p>Last Name: </p> <p>  </p>
                </li>
                <li class="artist-name">
                    <p>Artist Name: </p> <p> <!--<input type="text" id="artist-name" name="artist-name" placeholder="Set your artist name">--> </p>
                </li>
            </ul>
            <!--<button id="update" type="button">Update Profile</button> -->
        </div>  
        <div id="upload"> <!-- presente solo se profilo artista-->
            <form id="uploadcontainer"> <!-- https://nikitahl.com/custom-styled-input-type-file -->
                <div id="dropcontainer" class="drop-container">
                    <label for="images">
                        <span class="drop-title">Drop your artwork here</span>
                        <span>or</span>
                        <input type="file" id="images" accept="image/*" name="images[]" required multiple>
                    </label>
                </div>
                <button type="button">Upload</button>
            </form>
        </div>    
        <div class="logout"><button type="button">Logout</button></div>
    </main>
    <footer class="profile-footer">
        <div>
            Copyright &copy; 2025. Made by Michele S.
        </div>
    </footer>
</body>

</html>