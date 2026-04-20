-- ------------------------------------------------------------ --
-- 							OPERAZIONE 1						--
-- ------------------------------------------------------------ --
-- Individuazione dei dispositivi attualmente accesi

DROP PROCEDURE IF EXISTS dispositivi_attivi;
DELIMITER $$
CREATE PROCEDURE dispositivi_attivi()
BEGIN 
	SELECT 	d.Mac, d.Nome
    FROM 	Dispositivo d
    WHERE 	OnOff = TRUE;
END $$
DELIMITER ;

-- call dispositivi_attivi();





-- ------------------------------------------------------------ --
-- 							OPERAZIONE 2						--
-- ------------------------------------------------------------ --
-- Creazione una di una nuova Interazione

DROP PROCEDURE IF EXISTS creazione_Interazione;
DELIMITER $$

CREATE PROCEDURE creazione_Interazione (
                                        IN  TspPartenza_    TIMESTAMP,
                                        IN  TspFine_        TIMESTAMP,
                                        IN  MacDispositivo_ CHAR(12),
                                        IN  IdAccount_      INT,
                                        IN  Programma_      INT,
                                        IN  PotenzaWatt_    FLOAT
                                        )
BEGIN
    DECLARE _tipoDipositivo VARCHAR(40) DEFAULT '';
    DECLARE _durata INT DEFAULT 0;
    DECLARE _trueer CHAR(12) DEFAULT NULL;
    DECLARE _starter INT DEFAULT 1;
    
	-- controlli sulla validità dei dati
    IF  YEAR(TspPartenza_) < YEAR(CURRENT_TIMESTAMP())
        AND MONTH(TspPartenza_) < MONTH(CURRENT_TIMESTAMP()) 
        AND DAY(TspPartenza_) < DAY(CURRENT_TIMESTAMP())   
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non si può creare un interazione che inizia nel passato';
    END IF;

    -- controlla che non ci siano attualmente interazioni attive per quel dispositivo
    SET _starter = (    
                        SELECT 	COUNT(*)
                        FROM 	Interazione i
                        WHERE 	i.MacDispositivo = MacDispositivo_
                                AND    (i.TspFine IS NULL  OR TspPartenza_ BETWEEN i.TspPartenza AND i.TspFine)
                    );
	-- se il dispositivo è spendo allora procede alla creazione di un interazione 
    -- in caso contrario la procedura solleva un eccezione generica di codice 45000
    IF _starter = 0 THEN    
	
    
		-- viene creata una tabella temporanea che contiene una lista dei dispositivi con il relativo tipo
        DROP TEMPORARY TABLE IF EXISTS tipo_dispositivo;
        CREATE TEMPORARY TABLE tipo_dispositivo(
            MacDispositivo          CHAR(12)        NOT NULL,
        	Tipo				    VARCHAR(40) ,
            CONSTRAINT pk_InterazioneT PRIMARY KEY (MacDispositivo)
        ) ENGINE = InnoDB DEFAULT CHARSET = latin1;
		
        -- si distinguono 3 insert, ognuna per tipologia di dispositivo
        -- si fa questa distinzione perché in base alla tipologia di dispositivo la query per ricavare la lista sopra descritta cambia
        
        -- dipositivo consumo fisso
        INSERT INTO tipo_dispositivo(MacDispositivo, Tipo)
        SELECT DISTINCT(d.Mac), 'dipositivo consumo fisso' as Tipo
        FROM dispositivo d LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
        	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
        	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
        WHERE 	cv.MacDispositivo IS NULL
        	AND cni.MacDispositivo IS NULL;

        -- dispositivi consumo variabile
        INSERT INTO tipo_dispositivo(MacDispositivo, Tipo)
        SELECT DISTINCT(d.Mac), 'dispositivo consumo variabile' as Tipo
        FROM dispositivo d 
        	LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
        	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
        	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
        WHERE 	cf.MacDispositivo IS NULL
        	AND cni.MacDispositivo IS NULL;

        -- dispositivi ciclo non interrompibile
        INSERT INTO tipo_dispositivo(MacDispositivo, Tipo)
        SELECT DISTINCT(d.Mac), 'dispositivo ciclo non interrompibile' as Tipo
        FROM dispositivo d LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
        	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
        	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
        WHERE 	cf.MacDispositivo IS NULL
        	AND cv.MacDispositivo IS NULL;
            
		-- seleziona un dispositivo, di norma non ci sarebbe bisogno di questo passaggio, però si ritiene necessario
        -- perché siamo in grado di controllare che il MacDispositivo_ sia effettivamente un dispositivo presente nel database
        SET _tipoDipositivo = (
                                SELECT  Tipo     
                                FROM    tipo_dispositivo
                                WHERE   MacDispositivo = MacDispositivo_
                                );
    
        IF _tipoDipositivo IS NULL THEN 
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Dispositivo non presente nel DB';
        END IF;
		
		-- questo case serve a gestire la creazione di un interazione nelle 3 diverse casistiche
        CASE 
            WHEN _tipoDipositivo = 'dispositivo ciclo non interrompibile' THEN 
				
				IF Programma_ IS NULL THEN 
					SIGNAL SQLSTATE '45000'
					SET message_text = 'Programma non può essere nullo';
				END IF;
                SET _durata = (
                                SELECT  Durata 
                                FROM    Programma
                                WHERE   MacDispositivo = MacDispositivo_ AND ID = Programma_
                                );
				select _durata as Durata;
				-- _durata può essere nullo se la coppia macdispositivo e programma non è presente del database
				IF _durata IS NOT NULL THEN 
					
					-- inserimento interazione
					INSERT INTO Interazione(TspPartenza, MacDispositivo, TspFine, IdAccount ) 
					VALUES (TspPartenza_, MacDispositivo_, TspPartenza_ + INTERVAL _durata MINUTE, IdAccount_);
				
					-- inserimento regola
					INSERT INTO Regola(TspPartenza, MacDispositivo, Programma)
					VALUES (TspPartenza_, MacDispositivo_, Programma_);
				END IF;
            WHEN _tipoDipositivo = 'dispositivo consumo variabile'THEN 
                SET _trueer = (
	    					    SELECT 	p.MacConsumoVariabile
                                FROM 	Possesso p 
	    					    WHERE 	p.MacConsumoVariabile = MacDispositivo_ AND p.Potenza = PotenzaWatt_
                                );
				-- trueer è nullo solo se il valore di potenza impostata per quell'dispositivo non è presente tra le possibilità ad esso assegnate  
	    		IF _trueer IS NOT NULL THEN 
	    			INSERT INTO Interazione(TspPartenza, MacDispositivo, TspFine, IdAccount ) 
	    			VALUES (TspPartenza_, MacDispositivo_, TspFine_, IdAccount_);

	    			INSERT INTO Settaggio(TspPartenza, Potenza, MacDispositivo)
	    			VALUES (TspPartenza_, PotenzaWatt_, MacDispositivo_);
	    		END IF;

            WHEN _tipoDipositivo = 'dipositivo consumo fisso' THEN
				-- insert interazione 
                INSERT INTO Interazione(TspPartenza, MacDispositivo, TspFine, IdAccount ) 
                VALUES (TspPartenza_, MacDispositivo_, TspFine_, IdAccount_);

        END CASE ;
    ELSE 
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Impostazione in sovrapposta'; 
    END IF;
END $$

DELIMITER ;
/*	
	creazione_Interazione (TspPartenza_ ,TspFine_ , MacDispositivo_ , IdAccount_ , Programma_ , PotenzaWatt_ ) 
	call creazione_Interazione ( CURRENT_TIMESTAMP(), NULL, '051A3FF14CC6', 1, NULL, NULL); -- dispositivo a consumo fisso  
    call creazione_Interazione ( CURRENT_TIMESTAMP() + INTERVAL 2 SECOND, NULL, '101A3FF14CC6', 4, NULL, 1800);  -- consumo variabile
    call creazione_Interazione ( CURRENT_TIMESTAMP() + INTERVAL 1 SECOND, NULL, '001A3FF14CC6', 2, 1, NULL);-- ciclo non interrompibile 
    select * from interazione order by TspPartenza desc; 
*/






-- ------------------------------------------------------------ --
-- 							OPERAZIONE 3						--
-- ------------------------------------------------------------ --
-- Aggiornamento del TspFine in Selezione

DROP PROCEDURE IF EXISTS aggiornamento_selezione;
DELIMITER $$

CREATE PROCEDURE aggiornamento_selezione  (IN NumeroImpostazione_ INT, 
								IN IdElementoIlluminazione_ INT, 
                                IN IdAccount_ INT,
                                IN Tipo_Operazione VARCHAR(50))
BEGIN 
	DECLARE _tsp TIMESTAMP DEFAULT NULL;
    
	IF Tipo_Operazione = 'Spegni' THEN
		-- Selezione(NumeroImpostazione, IdElementoIlluminazione, IdAccount, TspInizio, TspFine)
        -- seleziono il timestamp corrispondente alla selezione che voglio disattivare
        SET _tsp = (
						Select TspInizio
                        FROM Selezione
                        WHERE TspFine IS NULL  AND NumeroImpostazione = NumeroImpostazione_ 
								AND IdElementoIlluminazione = IdElementoIlluminazione_ 
					);
		-- 
		UPDATE Selezione 
		SET	TspFine = CURRENT_TIMESTAMP() 
		WHERE TspInizio = _tsp 
				AND IdElementoIlluminazione = IdElementoIlluminazione_ 
				AND NumeroImpostazione = NumeroImpostazione_
                AND IdAccount IN 	(SELECT ID
									FROM Account);
	ELSEIF Tipo_Operazione = 'Accendi' THEN
    
    SET _tsp = (
						Select TspInizio
                        FROM Selezione
                        WHERE IdElementoIlluminazione = IdElementoIlluminazione_
								AND TspFine IS NULL 
								AND IdAccount IN 	(
												SELECT ID
												FROM Account
												)
								AND NumeroImpostazione IN 	(
												Select Numero
                                                FROM ImpostazioneIlluminazione
                                                WHERE IdElementoIlluminazione = IdElementoIlluminazione_
											) 
					);
	
		-- prima si spegne l'impostazione della luce che voglio cambiare
		UPDATE Selezione 
		SET	TspFine = CURRENT_TIMESTAMP() - INTERVAL 1 SECOND
		WHERE IdElementoIlluminazione = IdElementoIlluminazione_
				AND TspFine IS NULL 
                AND IdAccount IN 	(SELECT ID
									FROM Account)
				AND NumeroImpostazione IN 	(
												Select Numero
                                                FROM ImpostazioneIlluminazione
                                                WHERE IdElementoIlluminazione = IdElementoIlluminazione_
											) 
				AND TspInizio = _tsp; -- se non trova niente non fa niete 
		-- poi seleziono una nuova impostazione luminosa
        INSERT INTO Selezione(NumeroImpostazione, IdElementoIlluminazione, IdAccount, TspInizio, TspFine)
        VALUES (NumeroImpostazione_, IdElementoIlluminazione_, IdAccount_, current_timestamp(), NULL);
    END IF; 
	
END $$
DELIMITER ;
/* 	call aggiornamento_selezione  (1, 1 , 2 , 'Accendi'); select * from selezione order by TspInizio desc;
	call aggiornamento_selezione  (1, 1 , 2 , 'Spegni'); select * from selezione order by TspInizio desc;
    call aggiornamento_selezione  (2, 2 , 2 , 'Accendi'); select * from selezione order by TspInizio desc;
    call aggiornamento_selezione  (3, 2 , 2 , 'Accendi'); select * from selezione order by TspInizio desc;
    call aggiornamento_selezione  (3, 2 , 2 , 'Spegni'); select * from selezione order by TspInizio desc;
	
*/






-- ------------------------------------------------------------ --
-- 							OPERAZIONE 	4						--
-- ------------------------------------------------------------ --
-- Calcolo deii consumi energetici di tutta la casa in un lasso di tempo di T=20 minuti  
DROP PROCEDURE IF EXISTS consumi_energetici;
DELIMITER $$
CREATE PROCEDURE consumi_energetici(OUT 	consumi_ DOUBLE)
BEGIN
    DECLARE _energiaCONSUMATA, _energiaLUCI DOUBLE default 0;
    DECLARE _fasciaOraria INT default 0;
    DECLARE _produzione	FLOAT DEFAULT 0;
    DECLARE _energiaSpesaCondizionamento FLOAT DEFAULT 0;
    DECLARE _potenzaSpesaDispositivi FLOAT DEFAULT 0;
    DECLARE _tspBeginInterval, _tspEndInterval TIMESTAMP DEFAULT NULL;
    
    -- si calcola i consumi energetici ogni T minuti 

-- Interazione(TspPartenza, MacDispositivo, TspCreazione, TpsFine*, IdAccount ) 
DROP TEMPORARY TABLE IF EXISTS InterazioneTEMPORANEA;
CREATE TEMPORARY TABLE InterazioneTEMPORANEA(
    TspPartenza             TIMESTAMP       NOT NULL,
    MacDispositivo          CHAR(12)        NOT NULL,
    TspCreazione            TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    TspFine                 TIMESTAMP,
    IdAccount               INT             NOT NULL,
	PotenzaWh				FLOAT 			DEFAULT 0,
    CONSTRAINT ck_tspssT CHECK (TspPartenza >= TspCreazione AND TspPartenza <= TspFine ),
    CONSTRAINT pk_InterazioneT PRIMARY KEY (TspPartenza, MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

INSERT INTO InterazioneTEMPORANEA(TspPartenza, MacDispositivo, TspCreazione, TspFine, IdAccount, PotenzaWh)
SELECT ie.*, ROUND(RAND() * 6 * cf.Power/7 + cf.Power/7, 4) as Power
FROM Interazione ie INNER JOIN dispositivo d ON ie.MacDispositivo = d.Mac
	LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
WHERE 	cv.MacDispositivo IS NULL
	AND cni.MacDispositivo IS NULL;
                            
-- dispositivi consumo variabile
INSERT INTO InterazioneTEMPORANEA(TspPartenza, MacDispositivo, TspCreazione, TspFine, IdAccount, PotenzaWh)
SELECT ie.*, s.Potenza 
FROM Interazione ie INNER JOIN dispositivo d ON ie.MacDispositivo = d.Mac
	LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
    INNER JOIN Settaggio s ON s.TspPartenza = ie.TspPartenza AND s.MacDispositivo = ie.MacDispositivo
WHERE 	cf.MacDispositivo IS NULL
	AND cni.MacDispositivo IS NULL;
    
-- dispositivi ciclo non interrompibile
-- Programma(ID, Durata, ConsumoMedio, Potenza, MacDispositivo )
-- Regola(TspPartenza, MacDispositivo, Programma)
INSERT INTO InterazioneTEMPORANEA(TspPartenza, MacDispositivo, TspCreazione, TspFine, IdAccount, PotenzaWh)
SELECT ie.*, p.Potenza
FROM Interazione ie INNER JOIN dispositivo d ON ie.MacDispositivo = d.Mac
	LEFT OUTER JOIN ConsumoVariabile cv ON d.Mac = cv.MacDispositivo
	LEFT OUTER JOIN CicloNonInterrompibile cni ON d.Mac = cni.MacDispositivo
	LEFT OUTER JOIN ConsumoFisso cf ON d.Mac = cf.MacDispositivo
    INNER JOIN Regola r ON r.TspPartenza = ie.TspPartenza AND r.MacDispositivo = ie.MacDispositivo
    INNER JOIN Programma p ON p.ID = r.Programma
WHERE 	cf.MacDispositivo IS NULL
	AND cv.MacDispositivo IS NULL;

	set _tspBeginInterval = current_timestamp() - INTERVAL 1199 SECOND; -- 20 MINUTI - 1 SECOND
	set _tspEndInterval = current_timestamp(); -- 1 SECONDO
    
	SET _fasciaOraria = ( -- ricerca il nome della fascia oraria attuale 
							SELECT 	FO.Num
                            FROM 	FasciaOraria FO
                            WHERE 	FO.OraFine >= HOUR(_tspEndInterval) 
									AND FO.OraInizio <= HOUR (_tspEndInterval)
                                    AND FO.TspCreazione = (
															SELECT 	MAX(FO1.TspCreazione)
															FROM 	FasciaOraria FO1
															WHERE 	FO1.TspCreazione < _tspEndInterval -- ricerca l'ultimo set di fasce orarie create 
                                                            )
						);
	
	-- energia consumata dalle luci
	SET _energiaLUCI = (	
						SELECT SUM(D.PotenzaConsumata) AS ConsumoLuci
						FROM (
						    SELECT 	sel.NumeroImpostazione, 
						    		sel.IdElementoIlluminazione, 
						            sel.IdAccount, 
						            sel.TspInizio, 
						            sel.TspFine, 
						            CASE
						    		WHEN	sel.TspInizio <= _tspBeginInterval THEN 
						    			IF(_tspBeginInterval > sel.TspFine,  0 , 
						    				IF(_tspBeginInterval = sel.TspFine,  ROUND((iy.Potenza/3600) * 1 /*un secondo di attività*/,7) , 
						    					IF(sel.TspFine > _tspEndInterval, ROUND((iy.Potenza/3600) * timestampdiff(SECOND,_tspBeginInterval, _tspEndInterval),7),
						    						 ROUND((iy.Potenza/3600) * timestampdiff(SECOND,_tspBeginInterval,sel.TspFine),7)))) 
						    		WHEN 	sel.TspInizio > _tspBeginInterval THEN
						    			IF(sel.TspFine > _tspEndInterval, 
											IF(sel.TspInizio > _tspEndInterval,  0,
						    					ROUND((iy.Potenza/3600) * timestampdiff(SECOND,sel.TspInizio, _tspEndInterval),7)), 
						    					ROUND((iy.Potenza/3600) * timestampdiff(SECOND,sel.TspInizio, sel.TspFine ),7))
						    		ELSE 	NULL 
						            END 
						            as PotenzaConsumata
						    FROM selezione sel INNER JOIN ImpostazioneIlluminazione imil ON sel.NumeroImpostazione = imil.Numero AND sel.IdElementoIlluminazione = imil.IdElementoIlluminazione
						    	    INNER JOIN ElementoIlluminazione ei ON ei.Id = imil.IdElementoIlluminazione
						            INNER JOIN Assegnazione ass ON ass.Gradi = imil.Kelvin AND ass.IdElemIlluminazione = ei.Id 
						            INNER JOIN Intensity iy ON iy.IdElemIlluminazione = ei.Id AND iy.Percentuale = imil.Livello
						    	) AS D
						WHERE D.PotenzaConsumata <> 0
						);
                            
	SET _potenzaSpesaDispositivi = (
									SELECT  ROUND(SUM(20 * PotenzaWh/60), 4)
									FROM InterazioneTEMPORANEA it
									WHERE _tspEndInterval BETWEEN it.TspPartenza AND it.TspFine
									);
                                        
	IF _potenzaSpesaDispositivi IS NULL THEN 
		SET _potenzaSpesaDispositivi = 0;
	END IF;
        
	IF _energiaLUCI IS NULL THEN 
		SET _energiaLUCI = 0;
	END IF;
	   
    SET _energiaSpesaCondizionamento = (
					SELECT 		ROUND(SUM((edc.PotenzaMedia / 3600) * 1200),4)
					FROM 		ImpostazioneDiCondizionamento idc INNER JOIN ElementoDiCondizionamento edc 	
							ON edc.ID = idc.IdElementoDiCondizionamento 
					WHERE 		(YEAR(_tspEndInterval) BETWEEN YEAR(idc.DataInizio) AND YEAR(idc.DataFine))
								AND (MONTH(_tspEndInterval) BETWEEN MONTH(idc.DataInizio) AND MONTH(idc.DataFine))
								AND (DAY(_tspEndInterval) BETWEEN DAY(idc.DataInizio) AND DAY(idc.DataFine))
								AND (HOUR(_tspEndInterval) BETWEEN OraAvvio AND OraSpegnimento)
		);
	IF _energiaSpesaCondizionamento IS NULL THEN 
        -- siamo in questo stato quando non ci sono condizionatori accesi
		SET _energiaSpesaCondizionamento = 0;
	END IF;
        
        -- energia consumata dalle luci + energia consumata dal riscaldamento + energia consumata dai dispositivi
    SET _energiaCONSUMATA = _energiaLUCI + _energiaSpesaCondizionamento + _potenzaSpesaDispositivi;
    
    -- SELECT _energiaLUCI, _energiaSpesaCondizionamento, _potenzaSpesaDispositivi,  ROUND(_energiaCONSUMATA, 6) as energiaConsumata;
    
    SET consumi_ = ROUND(_energiaCONSUMATA, 6);
        
END $$
DELIMITER ;

DROP EVENT IF EXISTS consumi_Attuali;
CREATE EVENT consumi_Attuali
ON SCHEDULE EVERY 20 MINUTE  
STARTS CURRENT_TIMESTAMP() 
DO 
	CALL consumi_energetici(@consumiAttuali);

-- TODO: select @consumiAttuali; -- TODO 



-- ------------------------------------------------------------ --
-- 							OPERAZIONE 5						--
-- ------------------------------------------------------------ --
-- Controllo degli accessi esterni alla casa e della corrispondenza con gli IdAccount, per il rilevamento di una eventuale intrusione

DROP PROCEDURE IF EXISTS intrusione;
DELIMITER $$
-- con questa procedura si controlla la casistica in cui l'accesso dall'esterno viene fatto da un intruso, e tale accesso può essere fatto anche da una finestra
-- registra un solo nuovo intruso alla volta con id e fotografia e restituisce l'id della persona che corrisponde al nuovo intruso registrato.
CREATE PROCEDURE intrusione(	
								OUT personaIntrusa_ INT
							)
BEGIN
    DECLARE _tempo VARCHAR(100) DEFAULT 0;
    DECLARE _idIntruso INT DEFAULT 0;
	
    -- stringa da inserire nel nome del file creato 
    SET _tempo = CAST((CURRENT_TIMESTAMP() + 0) AS CHAR);

    INSERT INTO Persona
    VALUES (); -- sfrutto AUTO_INCREMENT 

    SET personaIntrusa_ = (SELECT MAX(Codice) FROM Persona);

    INSERT INTO Intruso(Persona)
    VALUES (personaIntrusa_);
	
    SET _idIntruso = (
					SELECT ID
					FROM Intruso
                    WHERE Persona = personaIntrusa_
                    );
	
    INSERT INTO Fotografia(Immagine, Intruso) 
    VALUES (CONCAT("10.177.31.200/cctvfiles/", _tempo, ".png"), _idIntruso);
    
END $$ 

DELIMITER ;


DROP TRIGGER IF EXISTS ingresso_in_casa;
DELIMITER $$

CREATE TRIGGER ingresso_in_casa
BEFORE INSERT ON AccessoDallEsterno
FOR EACH ROW
BEGIN
	DECLARE _serramento INTEGER DEFAULT 0;
    DECLARE _isAccount BOOL DEFAULT FALSE;
    DECLARE _isFinestra BOOL DEFAULT FALSE;
    -- recupero il serramento che devo aprire e che poi chiuderò eventualmente
    SET _serramento = (
                        SELECT  DISTINCT(s.ID)
                        FROM    PuntoDiAccesso pa INNER JOIN Serramento s ON s.PuntoAccesso = pa.ID 
                        WHERE   pa.ID = new.PuntoAccesso AND pa.NumeroStanza = new.NumeroStanza
                        ); 
                        
	IF _serramento IS NULL THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Serramento non trovato';
	END IF;
	
    -- controllo che la persona inserita si riferisca ad un account 
	SET _isAccount = (SELECT new.Persona	IN (
											SELECT a.persona 
											FROM persona p INNER JOIN account a on a.persona = p.codice) as D);
	-- controllo che il serramento sia o non sia una finestra 
	SET _isFinestra = (SELECT new.PuntoAccesso IN 	(SELECT p.id
											FROM serramento s inner join PuntoDiAccesso p ON p.ID = s.PuntoAccesso AND p.NumeroStanza = s.NumeroStanza
											WHERE	p.Tipologia = 'Finestra' AND p.NumeroStanza = new.NumeroStanza));
    
    IF new.Persona IS NULL THEN 
    
        CALL intrusione(new.Persona);
        
        INSERT INTO Stato (TspCambio, IdSerramento, Stato, Persona)
        VALUES (new.TspIN, _serramento, 1, new.Persona);
        
	ELSEIF _isAccount THEN 
		SET _isFinestra = (SELECT new.PuntoAccesso IN 	(SELECT p.id
											FROM serramento s inner join PuntoDiAccesso p ON p.ID = s.PuntoAccesso AND p.NumeroStanza = s.NumeroStanza
											WHERE	p.Tipologia = 'Finestra'));
		IF _isFinestra THEN
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un utente non può entrare dalla finestra';
		END IF;
        
        -- aggiorno lo stato del serramento in questione
        INSERT INTO Stato (TspCambio, IdSerramento, Stato, Persona)
        VALUES 
        (new.TspIN, _serramento, 1, new.Persona),
        (new.TspIN + INTERVAL FLOOR(RAND() * 11 + 10) SECOND , _serramento, 0, new.Persona);
        
    ELSE -- qui vi entro se inserisco nel campo persona in accesso dall' esterno un numero che corrisponde ad un intruso
    
		INSERT INTO Stato (TspCambio, IdSerramento, Stato, Persona)
        VALUES (new.TspIN, _serramento, 1, new.Persona);
        
    END IF; 
    -- Aggiornamento Permanenza

    INSERT INTO Permanenza(TspIniziale, Persona, NumeroStanza )
    VALUES (new.TspIN, new.Persona, new.NumeroStanza);

END $$

DELIMITER ;


-- Attivazione tramite trigger
/*	
	INSERT INTO AccessoDallEsterno(TspIN, PuntoAccesso, NumeroStanza, Persona)
    VALUES (CURRENT_TIMESTAMP, 9, 5, NULL); 
    select *
    from permanenza; 
    
    select * 
    from AccessoDallEsterno;
    select *
    from intruso i inner join persona p ON i.persona = p.codice inner join fotografia f on f.Intruso = i.Id;
    
*/






-- ------------------------------------------------------------ --
-- 							OPERAZIONE 6						--
-- ------------------------------------------------------------ --
-- Operazione che restituisce il numero della stanza in cui gli Account si trovano 
-- (gli Account non presenti nel resultset sono tutti e i soli account fuori casa)
DROP PROCEDURE IF EXISTS permanenza_Attuale;
DELIMITER $$

CREATE PROCEDURE permanenza_Attuale()
BEGIN
	
    -- tabella che contiene la stanza acupata da quale persona
	DROP TEMPORARY TABLE IF EXISTS stanze_Occupate;
	CREATE TEMPORARY TABLE stanze_Occupate(
    stanza INT NOT NULL, 
    persona INT not null,
    primary key (stanza, persona)
	);
    
    DROP TEMPORARY TABLE IF EXISTS persone_UsciteDiCasa;
	CREATE TEMPORARY TABLE persone_UsciteDiCasa(
    persona INT not null,
    primary key (persona)
	);
    
	
	-- ricerca degli Account presenti in stanze con accessi verso l'esterno
  	INSERT INTO persone_UsciteDiCasa
	WITH 
	stanzeConAccessoAllEsterno as ( -- PuntoDiAccesso(ID, NumeroStanza,  PuntoCardinale, Tipologia)
									-- lista delle stanze che hanno un accesso all'esterno percorribile dagli account (le finestre non valgono)
								SELECT 	sr.*
    							FROM	PuntoDiAccesso pda INNER JOIN serramento sr ON sr.PuntoAccesso = pda.Id
    							WHERE 	pda.Tipologia = 'Porta Finestra' OR pda.Tipologia = 'Porta Ingresso'
								),
	stanzePotenzialmenteOccupate as (
					-- restituisce le stanze con accesso dall'esterno che sono occupate da persone ancora presenti in esse oppure che sono state occupate da persone appena uscite di casa
					SELECT  DISTINCT(p.NumeroStanza) as Stanza, p.Persona, p.TspIniziale
					FROM    Permanenza p INNER JOIN (	
													SELECT MAX(p1.TspIniziale) as TspIniziale, p1.Persona
													FROM	permanenza p1 
													WHERE p1.Persona IN   (SELECT  a.Persona FROM    account a) 
    				                                GROUP BY p1.Persona
												) AS d ON d.TspIniziale = p.TspIniziale AND d.Persona = p.Persona
							INNER JOIN (SELECT se.NumeroStanza
										FROM	stanzeConAccessoAllEsterno se
                                            ) as d1 ON p.NumeroStanza = d1.NumeroStanza
					GROUP BY p.Persona
					),
	cambiDiStato as ( 
				-- questa tabella da come risultato il numero di cambi di stato fatti da ogni persona su serramenti Con Accesso All'esterno
				-- una persona si trova fuori di casa solo se il numero di Accessi all'esterno è pari (si assume che la posizione di partenza iniziale sia fuori casa 
                -- e che quindi se io entro in casa ho un'apertura dell'serramento, e quando esco di casa ho un altra apertura, che sommata alla precedente fanno 2 aperture )
                -- il discorso è inverso se la persona parte dall'interno della casa ma si assume che questa casistica non avvenga mai 
				select count(*) as NumeroAccessi, s.Persona
				from stato s
				where YEAR(s.TspCambio) = YEAR(Current_Timestamp) and s.stato = 1 
					and s.IdSerramento IN (SELECT se.Id
											FROM stanzeConAccessoAllEsterno se)
				group by persona
				order by  TspCambio desc
                )
	SELECT spo.Persona
    FROM stanzePotenzialmenteOccupate spo INNER JOIN cambiDiStato cbs ON cbs.Persona = spo.Persona
	WHERE cbs.NumeroAccessi % 2 = 0; -- quindi avrò una lista delle persone che sono fuori casa
    
    
    
    -- inserisco persone presenti in stanze senza accessi all'esterno
    INSERT INTO stanze_Occupate
    WITH 
	stanzeOccupate as (
					-- seleziono il massimo tsp che corrisponde alla persona cercata, 
					-- inoltre è necessario fare il controllo per ogni persona perchè se si vuole registrare la presenza di cambiamenti di stato dopo
					-- l'uscita dalla casa bisogna controllare per ogni persona e da chi è stato fatto 
					-- quindi preleva l'ultimo accesso fatto da ogni persona
					SELECT  DISTINCT(p.NumeroStanza) as Stanza, p.Persona, p.TspIniziale
					FROM    Permanenza p INNER JOIN (	
													SELECT MAX(p1.TspIniziale) as TspIniziale, p1.Persona
													FROM	permanenza p1 
													WHERE p1.Persona IN   (SELECT  a.Persona FROM    account a) 
    				                                GROUP BY p1.Persona
												) AS d ON d.TspIniziale = p.TspIniziale AND d.Persona = p.Persona
					GROUP BY p.Persona
					),
	stanzeConAccessoAllEsterno as ( -- PuntoDiAccesso(ID, NumeroStanza,  PuntoCardinale, Tipologia)
								SELECT 	sr.*
    							FROM	PuntoDiAccesso pda INNER JOIN serramento sr ON sr.PuntoAccesso = pda.Id
    							WHERE 	pda.Tipologia = 'Porta Finestra' OR pda.Tipologia = 'Porta Ingresso'
								)
  -- nel result set sono presenti solo le persone attualmente in altre parti della casa che non hanno punti di accesso dall'esterno percorribili da un account
	SELECT	so.Stanza, so.Persona 
	FROM 	stanzeOccupate so 
	WHERE  so.Persona NOT IN (	SELECT *
								FROM persone_UsciteDiCasa);
	select * 
	from stanze_Occupate;
	
END $$
DELIMITER ;
/* 
call permanenza_Attuale();

-- la persona 3 entra in casa

select * 
from stanze_Occupate;

insert into AccessoDallEsterno(TspIN, PuntoAccesso, NumeroStanza, Persona)
values
(CURRENT_TIMESTAMP - INTERVAL 8 MINUTE, 1, 1 ,3);

call permanenza_Attuale();
select * 
from stanze_Occupate;
*/





-- ------------------------------------------------------------ --
-- 							OPERAZIONE 7						--
-- ------------------------------------------------------------ --
-- Inserimento dei valori di produzione energetica prodotta e consumata nel contatore bidirezionale
DROP PROCEDURE IF EXISTS contatore_bidirezionale;
DELIMITER $$ 
CREATE PROCEDURE contatore_bidirezionale(IN energiaEccedente FLOAT, IN energiaPrelevataDallaRete FLOAT)
BEGIN
	/* NON SERVE PERCHè LA FASCIA ORARIA VIENE GESTITA DAL TRIGGER
	DECLARE _fasciaOraria INT DEFAULT 0;
	-- ContatoreBidirezionale(TspRilevamento, EnergiaOut, EnergiaIn, NumFasciaOraria)
    SET _fasciaOraria = ( -- ricerca il nome della fascia oraria attuale 
							SELECT 	FO.Num
                            FROM 	FasciaOraria FO
                            WHERE 	FO.OraFine >= HOUR(CURRENT_TIMESTAMP()) 
									AND FO.OraInizio <= HOUR (CURRENT_TIMESTAMP())
                                    AND FO.TspCreazione = (
															SELECT 	MAX(DISTINCT(FO1.TspCreazione))
															FROM 	FasciaOraria FO1
															WHERE 	FO1.TspCreazione < CURRENT_TIMESTAMP() -- ricerca l'ultimo set di fasce orarie create 
                                                            )
						);
					*/
	IF energiaEccedente <> 0 AND energiaPrelevataDallaRete <> 0 THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Procedura chiamata incorrettamente';
	END IF;
	INSERT INTO ContatoreBidirezionale(TspRilevamento,  EnergiaOut, EnergiaIn)
    VALUES (CURRENT_TIMESTAMP(), energiaEccedente, energiaPrelevataDallaRete);
END $$
DELIMITER ;



-- ------------------------------------------------------------ --
-- 							OPERAZIONE 8						--
-- ------------------------------------------------------------ --
-- Inserimento in ProduzioneEnergetica dei valori di energia prodotta dai pannelli fotovoltaici
DROP PROCEDURE IF EXISTS produzione_pannelli;
DELIMITER $$ 
CREATE PROCEDURE produzione_pannelli	(IN TspRilevamento_ TIMESTAMP, 
								IN IdPannello_ INT, 
                                IN ValoreEnergia_ FLOAT)
BEGIN
	-- notare che la fascia oraria viene gestita dal trigger quindi non c'è bisogno che essa venga gestita qui
	INSERT INTO ProduzioneEnergetica(TspRilevamento, IdPannello, ValoreEnergia)
    VALUES (TspRilevamento_, IdPannello_, ValoreEnergia_);
END $$
DELIMITER ;
