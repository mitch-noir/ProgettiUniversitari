<?php
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    // cancella il contenuto di $_SESSION
    session_unset();
    // distrugge la sessione
    session_destroy();

    header("Location: ./../../index.php");
?>