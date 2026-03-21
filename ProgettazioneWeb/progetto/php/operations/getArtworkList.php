<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';

    $max_file_size = 3145728; // 3MB

    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // avvio la connessione al db 
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            // comincio la transazione
            $databaseConnection->beginDBTransaction();
            // questa funzionalità è disponibile in modalità ospite senza utente
            if (!isset($_POST['genre'])) {
                throw new Exception("Genere non Settato", 1);
            } 
            // validazione del genere inserito
            if(!validateGenre($connection, $_POST['genre'])) {
                throw new Exception("Genere non valido", 1);
            } 
            
            // richiesta al DB della lista di opere
            $query;
            if ($_POST['genre'] === 'All') { // caso in cui richieto tutte le opere a prescindere dal genere a cui appartengono
                $query = "  SELECT a.nomeArtistico as artista, o.titolo as titolo, o.prezzo, s.titolo as serie, g.nome as genere, o.path , CAST(o.dataPubblicazione AS DATE) as `data`
                        FROM 	artista a INNER JOIN opera o ON o.artista = a.username
                                INNER JOIN serie s ON s.id = o.serie 
                                INNER JOIN genere g ON g.id = o.genere";
                $statement = $connection->prepare($query);
            } else {    // caso in cui vengono richieste solo le opere di uno specifico genere
                $query = "  SELECT a.nomeArtistico as artista, o.titolo as titolo, o.prezzo, s.titolo as serie, g.nome as genere, o.path , CAST(o.dataPubblicazione AS DATE) as `data`
                        FROM 	artista a INNER JOIN opera o ON o.artista = a.username
                                INNER JOIN serie s ON s.id = o.serie 
                                INNER JOIN genere g ON g.id = o.genere
                        WHERE   g.nome = :genrename";
                $statement = $connection->prepare($query);
                $statement->bindParam(':genrename', $_POST['genre']);
            }
            if (!$statement->execute())
                throw new Exception("Errore nel recuperare la lista dal database", 1);
            
            // genero la lista di opere se presente altrimenti $jsonArray rimane vuota (caso ammesso)
            $jsonArray = array();
            while ($row = $statement->fetch()) {
                $title = pathinfo($row['titolo'], PATHINFO_FILENAME);
                $path = str_replace(['\\'], '/', $row['path']);
                $jsonElem = [
                    'artist' => $row['artista'],
                    'title' => $title,
                    'price' => $row['prezzo'],
                    'serie' => $row['serie'],
                    'genre' => $row['genere'],
                    'imgPath' => $path,
                    'releaseDate' => $row['data'],
                ];
                array_push($jsonArray, $jsonElem);
            }
            
            // inserisco la lista di opere nella risposta  
            echo json_encode([
                'status' => 'ok',
                'message' => 'getFileList successfull',
                'content' => $jsonArray
            ]);

            // concludo la transazione e chiudo la connessione
            $databaseConnection->commitTransaction();
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'getFileList failed',
                'error' => $e->getMessage()
            ]);
            // termino la transazione e chiudo la connessione
            $databaseConnection->rollbackTransaction();
            $databaseConnection->closeConnection();
        }
    }
    
    /**
     * Controlla che il genere passato sia valido, eventualmente interrogando il database,
     * se il genere è valido restituisce true.
     *
     * @param PDO $connection Connessione al database.
     * @param string $genre Genere artistico da validare
     * @return boolean true se il genere è valido, false altrimenti
     * @throws Exception Se la comunicazione con il db va storto.
     */
    function validateGenre($connection, $genre) {
        if ($genre === 'All')
            return true;

        $querySql = "SELECT g.nome FROM `genere` as g WHERE g.id > 1; ";
        $stm = $connection->prepare($querySql);
        if (!$stm->execute())
            throw new Exception("validateGenre ha causato un errore durante la comuncazione col DB", 1);
        
        $found = false;
        while ($row = $stm->fetch()) {
            if ($row['nome'] === $genre) {
                $found = true;
                break;
            }
        }
        return $found;
    }
?>