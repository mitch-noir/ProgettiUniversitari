<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    /**
     * Controlla se esiste un utente in sessione e restituisce i dati in formato JSON.
     *
     * Se l'utente è autenticato, viene restituito il suo username.
     * Se nessun utente è autenticato, viene restituito un messaggio di errore.
     *
     */ 
    if (!isset($_SESSION['username'])) {
        echo json_encode([
            'status' => 'error',
            'message' => 'getSessionUser returned nothing',
            'error' => 'session username is null'
        ]);
    } else {
        echo json_encode([
            'status' => 'ok',
            'message' => 'getSessionUser successfull',
            'content' => [
                'username' => $_SESSION['username']
            ]
        ]);
    }
?>