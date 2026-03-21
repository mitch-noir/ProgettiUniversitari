<?php 
    require_once './../Database.class.php';
    // classe account con tutte i metodi per la gestione protetta dei dati
    
    /**
     * Genera l'hash della password usando BCRYPT e la restituisce.
     *
     * @param string $password La password in chiaro.
     * @return string L'hash della password.
     */
    function getHashPassword($password) {
        return password_hash($password, PASSWORD_BCRYPT);
    }
    /**
     * Controlla se un array contiene valori nulli o stringhe vuote.
     *
     * @param array $array L'array da controllare.
     * @return bool Ritorna true se almeno uno dei campi è vuoto, false altrimenti.
     */
    function emptyCells($array) {
        foreach ($array as $key => $value) {
            if ($value === null || $value === '')
                return true;
        }
        return false;
    }

    /**
     * Genera un username univoco basato sul nome e cognome dell'utente.
     *
     * @param PDO $connection Oggetto PDO per la connessione al database.
     * @param array $array Dati dell'utente, inclusi nome e cognome.
     * @return string Lo username generato.
     * @throws Exception Se i dati non sono validi o si verifica un errore SQL.
     */
    function generateUsername($connection, $array) {
        if (empty($array['first-name']) || empty($array['last-name'])) {
            throw new Exception("generateUsername chiamata quando firstname e/o lastname sono nulli");
        }
        // controllo che l'username non ci sia già
        if (isset($array['username']))
            return $array['username'];
    
        // Creo username
        $firstname = str_replace(['\'', ' '], '', $array['first-name']);
        $lastname = str_replace(['\'', ' '], '', $array['last-name']);
        $username = strtolower($firstname . '.' . $lastname);
        // se ci sono altri utenti che hanno uno username che inizia allo stesso modo si quello 
        // appena creato, li conto e uso questo numero per rendere lo username appena creato univoco
        $i = 0;
        $querySQL =    "SELECT a.username
                        FROM account a
                        WHERE a.username LIKE :username;";

        $stm = $connection->prepare($querySQL);
        $searchTerm = $username . '%';
        $stm->bindParam(':username', $searchTerm, PDO::PARAM_STR);

        if (!$stm->execute()) {
            throw new Exception("Qualcosa è andato storto nella comunicazione col DB");
        }
        
        while ($row = $stm->fetch()) {
            $i++;
        }
        
        $username = $username . $i;
        
        return $username;
    }
    /**
     * Verifica se il tipo di accesso è valido ('signup' o 'login').
     *
     * @param string $type Il tipo di accesso da controllare.
     * @return bool True se è valido, false altrimenti.
     */
    function checkAccessTypeValidity($type){
        return ($type == 'signup' || $type == 'login');
    }

    /**
     * cerca di recuperare l'account dal database utilizzando l'email, se presente lo restituisce
     *
     * @param PDO $connection Connessione al database.
     * @param string $email Email dell'account da cercare.
     * @return array|null Array con i dati dell'account o null se non trovato.
     * @throws Exception In caso di errore nella query.
     */
    function fetchAccountByEmail($connection, $email) {
        try {
            // recupera l'account dal db data l'email
            $query = "SELECT * FROM `account` a WHERE a.`mail` = :mail";
            $statement = $connection->prepare($query); 
            $statement->bindValue(':mail', $email);
            if (!$statement->execute()) {
                throw new Exception("Qualcosa è andato storto nella comunicazione col DB");
            }
    
            // Fetch del risultato
            $result = $statement->fetch(PDO::FETCH_ASSOC);

            // ritorna il risultato (null se il database non ha trovato l'account con la mail specificata)
            return $result; 
    
        } catch (Exception $e) {
            throw $e; // Re-throw dell'eccezione al livello superiore
        }
    }

    /**
     * Recupera un account dal database utilizzando lo username.
     *
     * @param PDO $connection Connessione al database.
     * @param string $username Username dell'account da cercare.
     * @return array|null Array con i dati dell'account o null se non trovato.
     * @throws Exception In caso di errore nella query.
     */
    function fetchAccountByUsername($connection, $username) {
        try {
            $query = "SELECT * FROM `account` a WHERE a.`username` = :username";
            $statement = $connection->prepare($query); 
            $statement->bindValue(':username', $username);
            if (!$statement->execute()) {
                throw new Exception("Qualcosa è andato storto nella comunicazione col DB");
            }
            // Fetch del risultato
            $result = $statement->fetch(PDO::FETCH_ASSOC);
    
            return $result; // Return the result (null se il database non ha trovato l'account con la mail specificata)
    
        } catch (Exception $e) {
            throw $e; // Re-throw dell'eccezione al livello superiore
        }
    }

    /**
     * Controlla se un nome è valido secondo una regex.
     *
     * @param string $value Il nome da controllare.
     * @return bool True se valido, false altrimenti.
     */
    function checkStringName($value) {
        $regexp = '/[A-ZÀ-Ý][A-Za-zÀ-ÿ]+(?:\\s[A-ZÀ-Ý][A-Za-zÀ-ÿ]+)*$/';
        return filter_var($value, FILTER_VALIDATE_REGEXP, ['options' => ['regexp' => $regexp]]);
    }

    /**
     * Verifica se un'email è valida.
     *
     * @param string $email Email da verificare.
     * @return bool True se valida, false altrimenti.
     */
    function checkMail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL);
    }

    /**
     * Controlla se la password soddisfa i requisiti di sicurezza.
     *
     * @param string $password La password da controllare.
     * @return string Messaggi di errore, vuoto se la password è valida.
     */
    function checkSignupPassword($password) {
        $err = '';
        if(strlen($password) < 8)  $err .= "Password troppo corta! \n";
        if(strlen($password) > 40) $err .= "Password troppo lunga! \n";        
        if(!preg_match("#[0-9]+#", $password)) $err .= "La tua password deve contenere almeno un numero !\n";
        if(!preg_match("#[A-Z]+#", $password)) $err .= "La tua password deve contenere almeno una lettera maiuscola!\n";
        if(!preg_match("#[a-z]+#", $password)) $err .= "La tua passwor deve contenere almeno una lettera minuscola!\n";
        if(!preg_match('/[\\W]/',  $password)) $err .= "La tua password deve contenere almeno un carattere speciale!\n";
        if($password !== strip_tags(trim($password))) $err .= "Password non può contenere html tags o spazi vuoti \n";

        return $err;
    }

    /**
     * Controlla se la password di login soddisfa i requisiti di sicurezza. * In questo caso 
     * vi sono meno controlli sui requisiti in quanto i principali vengono fatti in fase di signup
     *
     * @param string $password La password da controllare.
     * @return string Messaggi di errore, vuoto se la password è valida.
     */
    function checkLoginPassword($password){
        $err = '';

        if (strlen($password) < 8) $err .= "La tua password è troppo corta! \n";
        if (strlen($password) > 40) $err .= "La tua password è troppo lunga \n";

        if ($password !== strip_tags(trim($password))) $err .= "Password non può contenere html tags o spazi vuoti \n";

        return $err;
    }
    
    /**
     * Controlla se il nome dell'artista è valido.
     *
     * @param string $artist Il nome dell'artista da verificare.
     * @return bool True se valido, false altrimenti.
     */
    function checkArtistName($artist) {
        $regexp = '/[A-ZÀ-Ý][A-Za-zÀ-ÿ.]+(?:\\s[A-ZÀ-Ý][A-Za-zÀ-ÿ.]+)*$/';
        return filter_var($artist, FILTER_VALIDATE_REGEXP, ['options' => ['regexp' => $regexp]]);
    }
    /**
     * Controlla e valida i dati di input dell'utente in base al tipo di accesso (signup o login).
     *
     * @param array $array Dati dell'utente da validare.
     *      - 'type' (string): Deve essere 'signup' o 'login'.
     *      - 'email' (string): Email da validare.
     *      - 'password' (string): Password da verificare.
     *      - 'first-name' (string) [solo signup]: Nome dell'utente.
     *      - 'last-name' (string) [solo signup]: Cognome dell'utente.
     * @param string $accessType Il tipo di accesso ('signup' o 'login').
     * @throws Exception Se uno dei campi è nullo o non valido.
     */
    function checkUserInput($array, $accessType) {
        if(emptyCells($array)) 
            throw new Exception("Uno o più campi sono nulli", 1);

        if(!checkAccessTypeValidity($array['type']))
            throw new Exception("Metodo di accesso non valido", 1);

        if(!checkMail($array['email']))
            throw new Exception("Email non valida", 1);

        if ($accessType === 'signup') { // caso signup
            if(!checkStringName($array['first-name']))
                throw new Exception("Nome non valido", 1);
            if(!checkStringName($array['last-name']))
                throw new Exception("Cognome non valido", 1);

            try {
                $message = checkSignupPassword($array['password']);
                if($message !== '')
                    throw new Exception($message, 1);
            } catch (Exception $error) {
                throw $error;
            }

        } else { // caso login
            try {
                $message = checkLoginPassword($array['password']);
                if($message !== '')
                    throw new Exception($message, 1);
            } catch (Exception $error) {
                throw $error;
            }
        }
    }   
    
?>