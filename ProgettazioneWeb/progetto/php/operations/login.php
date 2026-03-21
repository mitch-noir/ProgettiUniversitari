<?php 
    
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    /**
     * Gestisce una richiesta POST per il login utente.
     *
     * Il sistema verifica le credenziali dell'utente confrontando l'email e l'hash della password
     * con quelli salvati nel database. Se la verifica ha successo, avvia la sessione e restituisce
     * il nome utente. In caso di errore, restituisce un messaggio con la relativa motivazione.
     *
     * @return void
     */
    
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            $databaseConnection->beginDBTransaction();
            // validazione dati inseriti dall'utente
            checkUserInput($_POST, 'login');
            // tenta di recuperare l'account
            $result = fetchAccountByEmail($connection, $_POST['email']);
            if (!$result) {
                throw new Exception("Login: account doesn't exists", 1);
            } 
            // verifica che la la password inserita sia la stessa salvata nel database
            if(!password_verify( $_POST['password'], $result['passwordHash'])) {
                throw new Exception("Login: password non corretta", 1);
            }

            // utente loggato 
            $_SESSION['username'] = $result['username'];
            // Inserisco lo username dell'utente nella risposta, in modo che submitHandler possa salvarlo in sessionStorage
            $content = [
                'username' => $_SESSION['username']
            ];
            
            echo json_encode([
                'status' => 'ok',
                'message' => 'Login completed',
                'content' => $content  
            ]);
            // commit e chiudo la connessione    
            $databaseConnection->commitTransaction();        
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Login failed',
                'error' => $e->getMessage()
            ]);
            // rollback e chiudo la connessione
            $databaseConnection->rollbackTransaction();
            $databaseConnection->closeConnection();
        }
    }
?>