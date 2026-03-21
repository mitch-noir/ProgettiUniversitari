<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            $databaseConnection->beginDBTransaction();

            // richiedo la lista di generi al DB 
            $queryGenres = 
                  " SELECT  g.nome
                    FROM    genere g
                    WHERE   g.id > 1
                    ";
            $statement = $connection->prepare($queryGenres);
            if (!$statement->execute())
                throw new Exception("Errore in fase di connessione");
            
            $content = []; // inizializza come array
            // inserisco la lista in un array che verrà poi restituito dal server al client
            while ($row = $statement->fetch()) {
                array_push($content, $row['nome']);
            }
            // formatto la risposta con all'interno la lista di generi '$content'
            echo json_encode([
                'status' => 'ok',
                'message' => 'getGenres successfull',
                'content' => $content  
            ]);
            // chiudo la connessione
            $databaseConnection->commitTransaction();
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'getGenres failed',
                'error' => $e->getMessage()
            ]);
            // chiudo la connessione
            $databaseConnection->rollbackTransaction();
            $databaseConnection->closeConnection();
        }
    }
?>