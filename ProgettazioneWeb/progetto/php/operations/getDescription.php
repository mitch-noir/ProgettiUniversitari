<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    /**
     * Gestisce una richiesta POST per ottenere la lista dei generi dal database.
     *
     * Recupera i generi con id maggiore di 1 e restituisce nome e descrizione
     * in formato JSON. In caso di errore, restituisce un messaggio di errore.
     *
     */
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            $databaseConnection->beginDBTransaction();
            
            // chiedo la lista di descrizioni al database
            $queryGenres = 
                  " SELECT  g.nome, g.descrizione
                    FROM    genere g
                    WHERE   g.id > 1
                    ";
            $statement = $connection->prepare($queryGenres);
            if (!$statement->execute())
                throw new Exception("Errore in fase di connessione");
            
            $content = []; // inizializza come array
            // converto ogni riga restituita come oggetto e la salvo in un array
            while ($row = $statement->fetch()) {
                $elem = [
                    'name' => $row['nome'],
                    'description' => $row['descrizione']
                ];
                array_push($content, $elem);
            }
            // se non ci sono errori invio al client la lista formattata
            echo json_encode([
                'status' => 'ok',
                'message' => 'getDescription successfull',
                'content' => $content  
            ]);
            //concludo la transazione e chiudo la connessione
            $databaseConnection->commitTransaction();
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'getDescription failed',
                'error' => $e->getMessage()
            ]);
            //termino la transazione e  chiudo la connessione
            $databaseConnection->rollbackTransaction();
            $databaseConnection->closeConnection();
        }
    }
?>