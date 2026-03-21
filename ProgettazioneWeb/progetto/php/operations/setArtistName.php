<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    /**
     * Gestisce una richiesta POST per impostare il nome artistico di un utente.
     *
     * La funzionalità è disponibile solo per gli utenti autenticati. 
     * Vengono eseguiti vari controlli, tra cui la validità del nome artistico e 
     * l'esistenza dell'account dell'utente.
     *
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
            if (!isset($_POST['artist-name'])) {
                throw new Exception("Nome artistico non impostato", 1);
            }
            if (!checkArtistName($_POST['artist-name'])) {
                throw new Exception("Nome artistico sintatticamente non valido", 1);
            }

            // controllo che il nume utente abbia un account 
            $result = fetchAccountByUsername($connection, $_POST['username']);
            if (!$result) {
                throw new Exception("Account non esiste", 1);
            } 

            // controllo se l'utente ha già un nome artistico
            if (artistNameIsSet($connection, $_POST['username'])) {
                throw new Exception("Hai già scelto il nome artistico", 1);
            }

            // controllo che il nome artistico non sia stato scelto da altri
            if (isArtistNameAlreadyUsed($connection, $_POST['artist-name'])) {
                throw new Exception("Nome artistico già scelto", 1);
            }

            // modifico il nome artistico dell'utente loggato
            setArtistName($connection, $_POST['username'], $_POST['artist-name']);
            
            // risposta al client
            echo json_encode([
                'status' => 'ok',
                'message' => 'setArtistName successfull'
            ]);

            $databaseConnection->commitTransaction();
            // chiudo la connessione
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            // risposta al client
            echo json_encode([
                'status' => 'error',
                'message' => 'setArtistName failed',
                'error' => $e->getMessage()
            ]);
            // revoco la transazione 
            $databaseConnection->rollbackTransaction();
            // chiudo la connessione
            $databaseConnection->closeConnection();
        }
    }

    /**
     * Determina se l'utente identificato dallo username ha già scelto un nome artistico
     *
     * @param PDO $connection Oggetto PDO per la connessione al database.
     * @param string $username Username dell'artista
     * @return boolean true se l'utente ha già scelto un nome artistico, false altrimenti
     * @throws Exception Se si verifica un errore.
     */
    function artistNameIsSet($connection, $username) {
        try {
            $selectQuery = 
                    " SELECT  username
                    FROM    artista
                    WHERE   nomeArtistico is not null 
                            and username = :username;
                    ";
            $statement = $connection->prepare($selectQuery);
            $statement->bindParam(':username', $username);
            if (!$statement->execute())
                throw new Exception("Errore in fase di esecuzione");
            
            $res;
            if ($statement->fetch()) {
                // se non vuoto l'artista ha già un nome 
                $res = true;
            } else {
                $res = false;
            }
            
            return $res;
        } catch (PDOException | Exception $e) {
            throw $e; // Re-throw the exception for further handling
        }
    }

    /**
     * Determina se il nome artistico passato come parametro è stato già usato da qualcun'altro
     *
     * @param PDO $connection   Oggetto PDO per la connessione al database.
     * @param string $artistname  Nome artistico di cui si vuole controllare l'unicità
     * @return boolean true se il nome artistico è stato già scelto, false altrimenti
     * @throws Exception Se si verifica un errore.
     */
    function isArtistNameAlreadyUsed($connection, $artistname) {
        try {
            $selectQuery = 
                    " SELECT  username
                    FROM    artista
                    WHERE   nomeArtistico = :artistname;
                    ";
            $statement = $connection->prepare($selectQuery);
            $statement->bindParam(':artistname', $artistname);
            if (!$statement->execute())
                throw new Exception("Errore in fase di esecuzione");
            
            $res;
            if ($statement->fetch()) {
                // se non vuoto il nome d'arte è stato già scelto 
                $res = true;
            } else {
                $res = false;
            }

            return $res;
        } catch (PDOException | Exception $e) {
            throw $e; // Re-throw the exception for further handling
        }
    } 
    /**
     * Imposta il nome artistico di un determinato username nel databse
     *
     * @param PDO $connection Oggetto PDO per la connessione al database.
     * @param string $username Username dell'artista
     * @param string $artistname  Nome artistico 
     * @throws Exception Se si verifica un errore.
     */
    function setArtistName($connection, $username, $artistname){
        try {
            $updateQuery = 
                  " UPDATE artista
                    SET 
                        nomeArtistico = :artistname
                    WHERE 
                        username = :username
                    ";
            $statement = $connection->prepare($updateQuery);
            $statement->bindParam(':username', $username);
            $statement->bindParam(':artistname', $artistname);
            if (!$statement->execute())
                throw new Exception("Errore in fase di esecuzione");
        } catch (PDOException | Exception $e) {
            throw $e; 
        }            
    }
?>