<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    /**
     * Gestisce una richiesta POST per ottenere le informazioni del profilo utente.
     *
     * La funzionalità è disponibile solo per gli utenti autenticati. 
     * Vengono eseguiti vari controlli, tra cui la corrispondenza dell'username
     * tra client e server e l'esistenza dell'account utente. Successivamente,
     * vengono recuperate e restituite le informazioni del profilo.
     */
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            $databaseConnection->beginDBTransaction();

            // controllo che tale funzionalità non sia stata chiamata in modalità ospite (nessun utente loggato)            
            if (!isset($_SESSION['username']) || !isset($_POST['username']) || empty($_POST['username']))
                throw new Exception("Funzionalità non disponibile in modalità ospite" . isset($_SESSION['username']) . " : " . isset($_POST['username']), 1);
            // controllo che l'utente loggato combaci su client e server
            if ($_SESSION['username'] !== $_POST['username'])
                throw new Exception("Username su server e client non sincronizzati ", 1);

            // validazione dati 
            $result = fetchAccountByUsername($connection, $_POST['username']);
            if (!$result) {
                throw new Exception("account non esiste", 1);
            } 

            //richiedo le informazioni dell'utente 
            $queryArtista = 
                  " SELECT  *
                    FROM    artista a 
                    WHERE   a.username = :username 
                    LIMIT   1";
            $statement = $connection->prepare($queryArtista);
            $statement->bindParam(':username', $_POST['username']);
            if (!$statement->execute())
                throw new Exception("Comunicazione col database non è andata a buon fine", 1);
            
            $response = $statement->fetch();
            
            $content = [
                'username' => $response['username'],
                'artistname' => $response['nomeArtistico'],
                'firstname' => $response['nome'],
                'lastname' => $response['cognome']
            ];
            
            echo json_encode([
                'status' => 'ok',
                'message' => 'getProfileInfo successfull',
                'content' => $content  
            ]);
            
            // chiudo la connessione
            $databaseConnection->commitTransaction();
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'getProfileInfo failed',
                'error' => $e->getMessage()
            ]);
            $databaseConnection->rollbackTransaction(); // rollback se transazione attiva
            // chiudo la connessione
            $databaseConnection->closeConnection();
        }
    }
    
?>