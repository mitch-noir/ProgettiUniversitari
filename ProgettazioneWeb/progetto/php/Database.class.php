<?php 

    abstract class Database {
        protected static $DBHOST = 'localhost';
        protected static $DBNAME = 'ms_db';
        protected static $USER = 'root';
        protected static $PASSWORD = '';
    }
    /**
     * Classe per gestire la connessione al database utilizzando PDO.
     * 
     * La classe si occupa di stabilire una connessione al database MySQL, 
     * di gestire eventuali errori di connessione e di fornire metodi per 
     * ottenere o chiudere la connessione.
     * Inoltre permette di avviare o chiudere le transazioni verso il database
     * solo sotto le giuste condizioni
     */
    class DatabaseConnection extends Database {
        protected $connection = null;
        protected $propertyString = null;
        protected $hasActiveTransaction = false;
        public function __construct(){
            try {   
                $this->propertyString = "mysql:host=" . parent::$DBHOST . ";dbname=" . parent::$DBNAME;
                // creo una connessione con pDO
                $this->connection = new PDO($this->propertyString, parent::$USER, parent::$PASSWORD); 
                // Disabilito Esecuzione Emulata (sicurezza)
                $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                $this->connection->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            } catch (PDOException $error){
                // chiudo la connessione
                $this->connection = null; 
                throw new Exception($error->getMessage()); // inoltra al livello superire l'errore
            }
        }   
        
        public function getConnection() {
            return $this->connection;
        }

        public function closeConnection() {
            $this->connection = null;
        }

        public function beginDBTransaction() {
            if ( $this->hasActiveTransaction ) {
                return false;
            } else {
                if ($this->connection !== null) {
                    $this->hasActiveTransaction = $this->connection->beginTransaction();
                    return $this->hasActiveTransaction;
                }
                return false;
            }
        }
        
        // fa il commit solo se la transazione è attiva
        public function commitTransaction() {
            if ($this->hasActiveTransaction)
                $this->connection->commit();
            $this->hasActiveTransaction = false;
        }
        

        // fa il rollback solo se la transazione è attiva
        public function rollbackTransaction() {
            if ($this->hasActiveTransaction)
                $this->connection->rollback();
            $this->hasActiveTransaction = false;
        }
    }

?>