<?php
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start(); // avvia la sessione 
        session_regenerate_id(); // genera un nuovo session_id
    }
    header('Location: ./html/home.php');
?>