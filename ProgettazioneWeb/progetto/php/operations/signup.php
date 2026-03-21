<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    /**
     * Gestisce una richiesta POST per la registrazione di un nuovo utente.
     *
     * Il sistema verifica che l'email non sia già associata a un account esistente. 
     * Nel qual caso genera un errore, se non lo è, genera un nome utente univoco, 
     * cifra la password e inserisce i dati nel database.
     * Se l'operazione ha successo, l'utente viene autenticato automaticamente.
     *
     * @return void
     */
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            // avvio la transazione
            $databaseConnection->beginDBTransaction();
            // validazione dati, in caso contrario solleva un errore
            checkUserInput($_POST, 'signup');
            // utilizza la mail passata per recuperare un eventuale account nel db
            $result = fetchAccountByEmail($connection, $_POST['email']);
            if ($result) { // se l'account è presente genera un errore
                throw new Exception("Account già esistente", 1);
            } 
            // dato il nome e cognome genero uno username, interrogando il db per risolvere il caso in cui più account abbiano stesso nome e cognome
            $username = generateUsername($connection, $_POST);
            // genero la password cryptata
            $passwordHash = getHashPassword($_POST['password']);
            
            // se tutto è andato a buon fine inserisco il nuovo account nel database
            // ed anche le informazioni dell'artista, lascaindo il nome artistico non settato
            insertArtist($connection, $username, $_POST['email'], $passwordHash, $_POST['first-name'], $_POST['last-name']);
            // utente loggato
            $_SESSION['username'] = $username;
            // Inserisco lo username dell'utente nella risposta, in modo che submitHandler possa salvarlo in sessionStorage
            $content = [
                'username' => $_SESSION['username']
            ];
            
            echo json_encode([
                'status' => 'ok',
                'message' => 'Signup completed',
                'content' => $content  
            ]);

            $databaseConnection->commitTransaction();
            // chiudo la connessione
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Signup failed',
                'error' => $e->getMessage()
            ]);
            $databaseConnection->rollbackTransaction();
            // chiudo la connessione
            $databaseConnection->closeConnection();
        }
    }

    /**
     * Inserisce un nuovo account e le informazioni dell'artista nel database.
     *
     * Esegue l'inserimento nella tabella `account` e successivamente
     * nella tabella `artista`. Se uno degli inserimenti fallisce, la transazione viene annullata.
     *
     * @param PDO $connection Connessione al database.
     * @param string $username Username generato per l'utente.
     * @param string $email Email dell'utente.
     * @param string $passwordHash Hash della password dell'utente.
     * @param string $firstname Nome dell'utente.
     * @param string $lastname Cognome dell'utente.
     * 
     * @throws Exception Se si verifica un errore durante l'inserimento dei dati.
     * @return void
     */
    function insertArtist($connection, $username, $email, $passwordHash, $firstname, $lastname) {
        try {
            
            // inserisco il nuovo account nel database
            $SQLQuery_1 = 
                " INSERT INTO `account` (`username`, `mail`, `passwordHash`, `tspPrimoAccesso`) 
                VALUES(:username, :mail, :pswHash, DEFAULT); 
                ";
            $statement = $connection->prepare($SQLQuery_1);
            $statement->bindValue(':username', $username);
            $statement->bindValue(':mail', $email);
            $statement->bindValue(':pswHash', $passwordHash);

            if (!$statement->execute()) {
                throw new Exception("Non è stato possibile inserire un nuovo account! Username: " . $username . " Email: " . $email);
            }
            // inserisco le informazioni dell'artista
            $SQLQuery_2 = 
                " INSERT INTO `artista` (`username`, `nome`, `cognome`, `nomeArtistico`) 
                VALUES(:username, :firstname, :lastname, DEFAULT); ";
            $stm = $connection->prepare($SQLQuery_2);
            $stm->bindValue(':username', $username);
            $stm->bindValue(':firstname', $firstname);
            $stm->bindValue(':lastname', $lastname);

            if (!$stm->execute()) {
                throw new Exception("Execute fallita");
            }
        } catch (PDOException | Exception $e) {
            throw $e;
        }
    }

?>