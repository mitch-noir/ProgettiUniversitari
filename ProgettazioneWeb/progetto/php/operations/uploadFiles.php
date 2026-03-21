<?php 
    // specifica che il contenuto della risposta HTTP del server è di tipo JSON.
    header('Content-Type: application/json');
    
    include_once './../handlers.php';

    $max_file_size = 3145728; // 3MB
    
    // Check Stato Sessione
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    /**
     * Gestisce il caricamento di immagini e l'eventuale creazione di una nuova serie artistica.
     *
     * Questo script riceve una richiesta POST contenente dati della serie artistica e file immagine.
     * Esegue una serie di controlli di validità sui dati, salva le immagini su disco e registra le informazioni nel database.
     */
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        try {
            // stabilisco una connessione con il db
            $databaseConnection = new DatabaseConnection();
            $connection = $databaseConnection->getConnection();
            $databaseConnection->beginDBTransaction();
            
            if (!isset($_SESSION['username']) || !isset($_POST['username']) || empty($_POST['username']))
            throw new Exception("Funzionalità non disponibile in modalità ospite" . isset($_SESSION['username']) . " : " . isset($_POST['username']), 1);
        
            if ($_SESSION['username'] !== $_POST['username'])
                throw new Exception("Username su server e client non sincronizzati ", 1);

            $content = [];
            // Validazione dati
            if (emptyCells($_POST)) 
                throw new Exception("Uno o più campi sono nulli", 1);

            if (!checkStringName($_POST['title']))
                throw new Exception("Titolo della serie non valido: " . $_POST['title'], 1);

            if (!is_numeric($_POST['genreId']))
                throw new Exception("Id del genere artistico dev'essere un numero: " . $_POST['genreId'], 1);

            $maxId = getMaxId($connection);
            if ($_POST['genreId'] < 2 || $_POST['genreId'] > $maxId) {
                throw new Exception("Id del genere artistico fuori range: " . $_POST['genreId'], 1);
            }
            // controlla che siano state passati dei file
            if (!$_FILES['images']) 
                throw new Exception("_FILES['images'] non presente", 1);

            /* check della validità dei file */
            // controllo se ci sono stati errori nel caricamento
            $error = '';
            foreach ($_FILES['images']['error'] as $index => $errCode) {
                if ($errCode !== UPLOAD_ERR_OK) {
                    if ($error === '')
                        $error .= 'Error: ';
                    $error .= $fileKey . " ha generato errore di tipo " . $errCode . "\n";
                }
            }
            // notifica gli errori che ci sono stati e blocca l'esecuzione del resto del programma
            if ($error !== '')
                throw new Exception($error);

            // controllo che tutti i file caricati siano delle immagini
            $validExtensions = array('avif', 'gif', 'jpeg', 'jpg', 'png', 'tif', 'tiff', 'webp');
            $validMimeTypes = array('image/avif', 'image/gif', 'image/jpeg', 'image/png', 'image/tiff', 'image/webp');
            foreach ($_FILES['images']['name'] as $index => $fileName) {
                $exploded = explode('.', $fileName);
                $extension = end($exploded);

                if (!(in_array($_FILES['images']['type'][$index], $validMimeTypes) && in_array($extension, $validExtensions))) {
                    throw new Exception("E' stata caricato un file non immagine " . $fileName, 1);
                }
            }

            // controllo che i file siano tutti di dimensione minore di 3 MB
            foreach ($_FILES['images']['size'] as $index => $size) {
                if ($size > $max_file_size) {
                    throw new Exception("Errore l'immagine caricata ha una dimensione maggiore ai 3MB: " . $_FILES['images']['name'][$index], 1);
                }
            }
            
            // se ci troviamo qui i file caricati sono validi

            // restituisce l'id della serie inserita, ne crea uno nuovo se non esiste
            $serieId = getSerieId($connection, $_POST['title']);
            
            // genera i path dove salvare i file usando lo username e l'id della serie 
            // path: /username/idserie/
            $userpath = $_SESSION['username'];
            $relativePath = $userpath . '/' . $serieId;
            $parentPath = './../../assets/images/';

            // restituisce la cartella se già presente, altrimenti la crea
            $folder = getFolder($parentPath, $relativePath); // in caso di errore fa il throw di un errore
            
            // salva la destinazione finale dei file nell'array $_FILES['images']['path']
            foreach ($_FILES['images']['name'] as $index => $fileName) {
                // calcolo il path di destinazione dello specifico file
                $destination = $folder . DIRECTORY_SEPARATOR . $fileName;
                if (file_exists($destination)) {
                    // il file esiste già genera errore perchè si sta cercando di sovrascriverlo erroneamente
                    throw new Exception("Titolo già presente nella serie", 1);
                }
                $_FILES['images']['path'][$index] = $destination; // inserisco un campo path nell'array di immagini in cui salvare la destinazione calcolata
            }
            //inserisci le opere nel DB una volta fatto tutto il precedente
            $files = reArrayFiles($_FILES['images']); // rearrangia la matrice
            insertArtworks($connection, $files);

            // salvataggio dei file nella cartella, lo faccio qui per far si che venga fatto solo se nel databse le opere sono state inserite correttamente
            foreach ($_FILES['images']['name'] as $index => $fileName) {
                $tmp = $_FILES['images']['tmp_name'][$index];
                $destination = $_FILES['images']['path'][$index];
                // sposto il file dal path temporaneo a quello finale
                move_uploaded_file($tmp, $destination);
            }
            
            // inserisco le seguenti informazioni nella risposta, ai fini di debug
            array_push($content, $maxId);
            array_push($content, $_POST);
            array_push($content, $_FILES);
            array_push($content, $serieId);
            array_push($content, realpath($folder));

            echo json_encode([
                'status' => 'ok',
                'message' => 'updateFiles successfull',
                'content' => $content
            ]);
            
            // chiudo la connessione
            $databaseConnection->commitTransaction();
            $databaseConnection->closeConnection();
        } catch (PDOException | Exception $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'updateFiles failed',
                'error' => $e->getMessage(),
                $_FILES
            ]);
            // chiudo la connessione
            $databaseConnection->rollbackTransaction();
            $databaseConnection->closeConnection();
        }
    }
    /**
     * Ottiene il massimo ID della tabella genere.
     *
     * @param PDO $connection Connessione al database.
     * @return int ID massimo della tabella genere.
     * @throws Exception Se la query non restituisce risultati.
     */
    function getMaxId ($connection) {
        $query = "SELECT max(id) as max FROM genere";
        $stm = $connection->prepare($query);
        if (!$stm->execute())
            throw new Exception("Errore in fase di esecuzione");

        $row = $stm->fetch();
        if ($row === false) {
            throw new Exception("Nessuna riga trovata nella tabella Genere.");
        }
        return $row['max'];
    }
    
    /**
     * Ottiene l'ID di una serie esistente o ne crea una nuova.
     *
     * @param PDO $connection Connessione al database.
     * @param string $title Titolo della serie.
     * @return int ID della serie.
     * @throws Exception Se non è possibile recuperare o creare la serie.
     */
    function getSerieId($connection, $title) {
        $query = "  SELECT *
                    FROM serie s
                    WHERE s.titolo = :title 
                    LIMIT 1";
        $statement = $connection->prepare($query);
        $statement->bindValue(':title', $title);
        if (!$statement->execute())
            throw new Exception("Errore nel eseguire la select in getSerieId");
        $row = $statement->fetch();
        $id;
        if ($row) {
            $id = $row['id'];
        } else { // il titolo non c'è e va inserito
            $insert = " INSERT INTO serie (titolo) VALUES (:title)";
            $statement = $connection->prepare($insert);
            $statement->bindValue(':title', $title);
            if (!$statement->execute())
                throw new Exception("Errore nel eseguire la insert in getSerieId");
            
            // ritilizzo la prima query
            $statement = $connection->prepare($query);
            $statement->bindValue(':title', $title);
            if (!$statement->execute())
                throw new Exception("Errore nel eseguire la select in getSerieId");
            $row = $statement->fetch();

            if ($row === false) {
                throw new Exception("Errore: Non è stato possibile trovare l'id della serie appena inserita.");
            }

            $id = $row['id'];
        }

        return $id;
    }

    /**
     * Crea una cartella per salvare le immagini, se non esiste già.
     *
     * @param string $parentFolder Cartella principale.
     * @param string $relativePath Percorso relativo della cartella da creare.
     * @return string Percorso assoluto della cartella creata.
     * @throws Exception Se non è possibile creare la cartella.
     */
    function getFolder($parentFolder, $relativePath) {
        $childDirectoryArray = explode('/', $relativePath);
        $path = realpath($parentFolder);
        if (!$path)
            throw new Exception("Cartella radice delle immagini non trovata", 1);
        
        // creo le cartelle ricorsivamente una dentro l'altra
        foreach ($childDirectoryArray as $index => $dirName) {
            $newFolderPath = $path . DIRECTORY_SEPARATOR . $dirName;
            if (!file_exists($newFolderPath)) {
                if (!mkdir($newFolderPath, 0777, true)) {
                    throw new Exception("Impossibile creare la cartella: " . $dirName , 1);
                }
            }
            $path = $newFolderPath;
        }
        return $path;
    }

    /**
     * Inserisce le opere nel database.
     *
     * @param PDO $connection Connessione al database.
     * @param array $artworks Elenco delle opere da inserire.
     * @throws Exception Se si verifica un errore nell'inserimento.
     */
    function insertArtworks($connection, $artworks) {
        // ottengo l'id della serie in questione
        $selQuery = "   SELECT * 
                        FROM serie s
                        WHERE s.titolo = :titolo 
                        LIMIT 1";
        
        $stm = $connection->prepare($selQuery);
        $stm->bindParam(':titolo', $_POST['title']);
        if (!$stm->execute())
            throw new Exception("Errore in fase di connessione");
        $row = $stm->fetch();
        if (!$row)
            throw new Exception("Titolo non trovato tra le serie nel DB");  

        $serieId = $row['id'];
        
         // Preparo la `INSERT` query
        $insQuery = "INSERT INTO `opera` (`serie`, `titolo`, `artista`, `prezzo`, `genere`, `path`) VALUES ";
        $values = [];
        foreach ($artworks as $piece) { // formatto una riga per ogni opera
            $values[] = "(?, ?, ?, DEFAULT, ?, ?)";
        }
        $insQuery .= implode(", ", $values) . ';'; // trasformo l'array in una stringa inserendo delle ',' come separatori tra elementi ed un ';' finale
        $stm = $connection->prepare($insQuery);

        // faccio il bind dinamico dei valori
        $i = 1; // i PDO binds partono da 1
        foreach ($artworks as $piece) {
            $stm->bindValue($i++, $serieId, PDO::PARAM_INT);       // `serie`
            $stm->bindValue($i++, $piece['name'], PDO::PARAM_STR); // `titolo`
            $stm->bindValue($i++, $_SESSION['username'], PDO::PARAM_STR); // `artista`
            $stm->bindValue($i++, $_POST['genreId'], PDO::PARAM_INT);     // `genere`
            $stm->bindValue($i++, $piece['path'], PDO::PARAM_STR);        // `path`
        }

        // Execute the statement
        if (!$stm->execute()) {
            throw new Exception("Errore in fase di esecuzione query");
        }
            
    }
    // riarrangia l'array 
    function reArrayFiles($file_post) {

        $file_ary = array();
        $file_count = count($file_post['name']);
        $file_keys = array_keys($file_post);
    
        for ($i=0; $i<$file_count; $i++) {
            foreach ($file_keys as $key) {
                $file_ary[$i][$key] = $file_post[$key][$i];
            }
        }
    
        return $file_ary;
    }
?>