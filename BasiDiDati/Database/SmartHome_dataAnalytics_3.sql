-- ------------------------------------------------------ --
--						  ANALYTICS 3			 		  --
-- ------------------------------------------------------ --

DROP TABLE IF EXISTS sprechiEnergetici; 
CREATE TABLE sprechiEnergetici(
	TspRilevamento 	TIMESTAMP NOT NULL,
    EnergiaSprecata	FLOAT DEFAULT 0,
    PRIMARY KEY (TspRilevamento)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP PROCEDURE IF EXISTS analytics_3;
DELIMITER $$

CREATE PROCEDURE analytics_3()
BEGIN
	DECLARE _tspBeginInterval, _tspEndInterval TIMESTAMP DEFAULT NULL;
    DECLARE _energiaLUCI FLOAT DEFAULT 0;
    -- si deficisce l'intervallo 

    set @inizio = current_timestamp(); 
	-- set @inizio = '2021-07-11 12:00:00'; 	-- data valida per il test di funzionamento

    set _tspBeginInterval =  @inizio - INTERVAL 1199 SECOND; -- 20 MINUTI - 1 SECOND
	set _tspEndInterval = @inizio; -- 1 SECONDO
	
    -- chiamando l'operazione 3, avrò in una tabella temporanea chiamata stanze_Occupate, in cui sono presenti le persone e in quali stanze si trovano
    -- se sono fuori casa non compaiono nella tabella.
	CALL permanenza_Attuale(); 
    
    -- di seguito lo studio degli sprechi energetici negli ultimi venti minuti, si contanto quindi le luci attualmente accese in stanze non occupate
    SET _energiaLUCI = (	
						SELECT SUM(D.PotenzaConsumata) AS ConsumoLuci
						FROM (
						    SELECT 	sel.NumeroImpostazione, 
						    		sel.IdElementoIlluminazione, 
						            sel.IdAccount, 
						            sel.TspInizio, 
						            sel.TspFine, 
						            CASE
									WHEN 	sel.TspFine > _tspEndInterval THEN 0 
						    		ELSE 	IF(sel.TspInizio < _tspBeginInterval, 
												ROUND((iy.Potenza/3600) * timestampdiff(SECOND,_tspBeginInterval, _tspEndInterval),7),
                                                ROUND((iy.Potenza/3600) * timestampdiff(SECOND,sel.TspInizio, _tspEndInterval),7))
						            END 
						            as PotenzaConsumata
						    FROM selezione sel INNER JOIN ImpostazioneIlluminazione imil ON sel.NumeroImpostazione = imil.Numero AND sel.IdElementoIlluminazione = imil.IdElementoIlluminazione
						    	    INNER JOIN ElementoIlluminazione ei ON ei.Id = imil.IdElementoIlluminazione
						            INNER JOIN Assegnazione ass ON ass.Gradi = imil.Kelvin AND ass.IdElemIlluminazione = ei.Id 
						            INNER JOIN Intensity iy ON iy.IdElemIlluminazione = ei.Id AND iy.Percentuale = imil.Livello
							WHERE ei.NumeroStanza	NOT IN (SELECT stanza from stanze_Occupate)
								AND ((sel.TspFine IS NULL AND  sel.TspInizio < _tspBeginInterval )
									OR 
                                      sel.TspFine IS NULL AND  sel.TspInizio >= _tspBeginInterval ) 
						    	) AS D
						WHERE D.PotenzaConsumata <> 0
						);
	
	IF _energiaLUCI IS NULL THEN
		SET _energiaLUCI = 0;
	END IF;
    
       
    INSERT INTO sprechiEnergetici(TspRilevamento, EnergiaSprecata)
    VALUES (_tspEndInterval, _energiaLUCI);
    
END $$
DELIMITER ;

DROP EVENT IF EXISTS consumi_Luce;
CREATE EVENT consumi_Luce
ON SCHEDULE EVERY 20 minute
STARTS CURRENT_TIMESTAMP() 
DO 
	CALL analytics_3();
/*	
	Per poter testare correttamente i suo funzionamento, ed avere un risultato visivo di ciò
	si è calcolato con l'analytics, è consigliato eseguire quanto scritto qui sotto:
    
	insert into selezione 
	values
	(113,11,5,current_timestamp(),NULL),
	(76,10,4,current_timestamp(),NULL);

	CALL analytics_3() 
	select *
	from sprechiEnergetici;
*/

