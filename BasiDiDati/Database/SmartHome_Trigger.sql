-- TRIGGER 1
-- Alla creazione di un nuovo account si crea una nuova persona
DROP TRIGGER IF EXISTS account_a_persona;
DELIMITER $$

CREATE TRIGGER account_a_persona
BEFORE INSERT ON Account
FOR EACH ROW
BEGIN    
	INSERT INTO Persona
    VALUES ();
    
    SET new.Persona = (SELECT MAX(Codice) FROM Persona);
END $$

DELIMITER ;

-- ----------------------------------------------------------------------------

-- TRIGGER 2
-- Non si possono creare impostazioni sovrapposte per lo stesso condizionatore
DROP TRIGGER IF EXISTS condizionamento_sovrapposto;
DELIMITER $$
-- ImpostazioneDiCondizionamento(ID, IdElementoDiCondizionamento, OraSpegnimento, OraAvvio, UmiditaTarget, TemperaturaTarget, DataInizio, DataFine, IdAccount)

CREATE TRIGGER  condizionamento_sovrapposto
BEFORE INSERT ON  ImpostazioneDiCondizionamento  FOR EACH ROW
BEGIN
    DECLARE _starter INT DEFAULT NULL;
    SET _starter = (    -- query che restituisce l'ID dell'impostazione sovrapposta
                    SELECT  i.ID
                    FROM    ImpostazioneDiCondizionamento i
                    WHERE   i.IdElementoDiCondizionamento = new.IdElementoDiCondizionamento
                            AND ((new.DataInizio BETWEEN i.DataInizio AND i.DataFine) 
                                OR (new.DataInizio <= i.DataInizio AND (new.DataFine >= i.DataFine OR new.DataFine BETWEEN i.DataInizio AND i.DataFine)))
                            AND ((new.OraAvvio BETWEEN i.OraAvvio AND i.OraSpegnimento) 
                                OR (new.OraAvvio <= i.OraAvvio AND (new.OraSpegnimento >= i.OraSpegnimento OR new.OraSpegnimento BETWEEN i.OraAvvio AND i.OraSpegnimento)))
                    );
                    
	SET @iolo = (SELECT COUNT(*)
		FROM ImpostazioneDiCondizionamento);
        
    IF _starter IS NOT NULL THEN
		SET @mex = CONCAT(' Impostazione Sovrapposta in riga ', @iolo);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =@mex ;
    END IF;
END $$

DELIMITER ;

-- ----------------------------------------------------------------------------

-- TRIGGER 3
-- Inserisce la fascia oraria giusta in base al timestamp di rilevamento per il contatore bidirezionale
DROP TRIGGER IF EXISTS fasciaOraria_di_ContatoreBidirezionale;
DELIMITER $$
CREATE TRIGGER fasciaOraria_di_ContatoreBidirezionale
BEFORE INSERT ON ContatoreBidirezionale
FOR EACH ROW 
BEGIN
	SET new.NumFasciaOraria = (
								SELECT 	FO.Num
								FROM 	FasciaOraria FO
								WHERE 	FO.OraFine >= HOUR(new.TspRilevamento) 
									AND FO.OraInizio <= HOUR (new.TspRilevamento)
                                    AND FO.TspCreazione = (
															SELECT 	MAX(FO1.TspCreazione)
															FROM 	FasciaOraria FO1
															)
							);
END $$

DELIMITER ;

-- ----------------------------------------------------------------------------

-- TRIGGER 4
-- inserisce la fascia oraria giusta in base al timestamp di rilevamento dell'energia prodotta
DROP TRIGGER IF EXISTS fasciaOraria_di_ProduzioneEnergetica;
DELIMITER $$
CREATE TRIGGER fasciaOraria_di_ProduzioneEnergetica
BEFORE INSERT ON ProduzioneEnergetica
FOR EACH ROW 
BEGIN
	SET new.NumFasciaOraria = (
								SELECT 	FO.Num
								FROM 	FasciaOraria FO
								WHERE 	FO.OraFine >= HOUR(new.TspRilevamento) 
									AND FO.OraInizio <= HOUR (new.TspRilevamento)
                                    AND FO.TspCreazione = (
															SELECT 	MAX(FO1.TspCreazione)
															FROM 	FasciaOraria FO1
															)
							);
END $$

DELIMITER ;

-- inserire controllo corso di validità in documento
DROP TRIGGER IF EXISTS in_corso_di_validita
DELIMITER $$
CREATE TRIGGER in_corso_di_validita
BEFORE INSERT ON Documento
FOR EACH ROW
BEGIN 
	IF new.DataScadenza <= CURRENT_TIMESTAMP() THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Documento Scaduto';
	END IF;
END $$

DELIMITER ;
