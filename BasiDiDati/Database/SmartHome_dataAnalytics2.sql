-- ------------------------------------------------------ --
--						  ANALYTICS 2			 		  --
-- ------------------------------------------------------ --
/* 
    LOGICA:
        1. calcolo energia attualmente consumata;
        2. calcolo valore energia prodotto in media negli ultimi 5 gg in un lasso di tempo coerente (che va da 1 ora prima a due ore dopo l'istante id calcolo);
        3. calcolo il delta energetico δ= autoprodottaInMedia-consumataAttualmente
            i.  se δ<0 significa che ho passivo energetico sto prelevando dalla rete (a pagamento) e non viene consigliato di attivare altri dispositivi, in quanto graverebbero sulla bolletta;
            ii. se δ=0 sono in uno stato di bilanciamento, no perdita, no surplus

            iii.se δ>0 allora ho un attivo energetico (a.k.a. surplus) e posso verificare se vi sia un possibile dispositivo attivabile che abbia un eventuale consumo non superiore a δ. Qualora vi fosse, procedo a suggerirne l'attivazione;

        4. Creo un UNICO suggerimento, scelto fra i programmi attivabili, il programma che verra' suggerito è quelle che sfrutta di più il surplus. 
        Di default il suggerimento e' 'In attesa'.

*/

-- 1. CALCOLO L'ENERGIA CHE LA CASA STA CONSUMANDO --

    -- set @dataRichiesta = current_timestamp(); 
    set @dataRichiesta='2021-07-22 10.50'; -- data valida per il test di funzionamento
    
    drop procedure if exists analytics2;
	DELIMITER $$
	create procedure analytics2()
	BEGIN
	DECLARE consumoIlluminazione DOUBLE DEFAULT 0;
    DECLARE consumoCondizionamento DOUBLE DEFAULT 0;
    DECLARE consumoDispConsumoFisso DOUBLE DEFAULT 0;
    DECLARE consumoDispConsumoVariabile DOUBLE DEFAULT 0;
    DECLARE consumoDispNonInterrompibili DOUBLE DEFAULT 0;
    DECLARE consumoTotaleCasa DOUBLE DEFAULT 0;
    DECLARE energiaProdotta DOUBLE DEFAULT 0;
    DECLARE deltaEnergetico DOUBLE DEFAULT 0;


    -- CONSUMI ENERGETICI DELL'ILLUMINAZIONE AL MOMENTO DELLA RICHIESTA --
    SET consumoIlluminazione = (
                                     SELECT  sum(time_to_sec(timediff(sel.TspFine, sel.TspInizio))/3600 *(iy.Potenza))
                                    FROM Selezione sel INNER JOIN ImpostazioneIlluminazione imil 
                                        ON sel.NumeroImpostazione = imil.Numero 
                                        AND sel.IdElementoIlluminazione = imil.IdElementoIlluminazione
                                    INNER JOIN ElementoIlluminazione ei 
                                        ON ei.Id = imil.IdElementoIlluminazione
                                    INNER JOIN Intensity iy 
                                        ON iy.IdElemIlluminazione = ei.Id 
                                        AND iy.Percentuale = imil.Livello
                                    WHERE @dataRichiesta BETWEEN TspInizio AND TspFine
                                );


    -- CONSUMI ENERGETICI DEGLI ELEM DI CONDIZIONAMENTO AL MOMENTO DELLA RICHIESTA --
    SET consumoCondizionamento =(
                    SELECT sum((OraSpegnimento-OraAvvio)*PotenzaMedia)
					FROM 		ImpostazioneDiCondizionamento idc INNER JOIN ElementoDiCondizionamento edc 	
						ON edc.ID = idc.IdElementoDiCondizionamento 
					WHERE (YEAR(@dataRichiesta) BETWEEN YEAR(idc.DataInizio) AND YEAR(idc.DataFine))
								AND (MONTH(@dataRichiesta) BETWEEN MONTH(idc.DataInizio) AND MONTH(idc.DataFine))
								AND (DAY(@dataRichiesta) BETWEEN DAY(idc.DataInizio) AND DAY(idc.DataFine))
								AND (HOUR(@dataRichiesta) BETWEEN OraAvvio AND OraSpegnimento)
        );


    -- CONSUMI ENERGETICI DEI DISPOSITIVI AL MOMENTO DELLA RICHIESTA --
  
    -- dispositivi a consumo fisso --
    SET consumoDispConsumoFisso = (
        SELECT sum(time_to_sec(timediff(i.TspFine, i.TspPartenza))/3600*df.Power)
        FROM Interazione i INNER JOIN ConsumoFisso df ON i.MacDispositivo = df.MacDispositivo
        WHERE @dataRichiesta BETWEEN i.TspPartenza AND IFNULL(i.TspFine,CURRENT_TIMESTAMP())
    );

    -- dispositivi a consumo variabile --
    SET consumoDispConsumoVariabile = (
        SELECT sum(time_to_sec(timediff(i.TspFine, i.TspPartenza))/3600*Possesso.Potenza)
        FROM Interazione i INNER JOIN ConsumoVariabile dv ON i.MacDispositivo = dv.MacDispositivo 
        INNER JOIN Possesso  ON Possesso.MacConsumoVariabile = dv.MacDispositivo
        WHERE @dataRichiesta BETWEEN i.TspPartenza AND IFNULL(i.TspFine,CURRENT_TIMESTAMP())
    );

    -- dispositivi a ciclo non interrompibile --
    SET consumoDispNonInterrompibili = (
        SELECT sum(time_to_sec(timediff(i.TspFine, i.TspPartenza))/3600*p.ConsumoMedio)
        FROM Interazione i INNER JOIN CicloNonInterrompibile dni ON i.MacDispositivo = dni.MacDispositivo
        INNER JOIN Programma p ON p.MacDispositivo = dni.MacDispositivo
        WHERE @dataRichiesta BETWEEN i.TspPartenza AND IFNULL(i.TspFine,CURRENT_TIMESTAMP())
    );
    IF consumoIlluminazione IS NULL THEN
    SET consumoIlluminazione =0;
    END IF;
    IF consumoCondizionamento IS NULL THEN
    SET consumoCondizionamento =0;
    END IF;
    IF consumoDispConsumoFisso IS NULL THEN
    SET consumoDispConsumoFisso =0;
    END IF;
    IF consumoDispConsumoVariabile IS NULL THEN
    SET consumoDispConsumoVariabile =0;
    END IF;
    IF consumoDispNonInterrompibili IS NULL THEN
    SET consumoDispNonInterrompibili =0;
    END IF;
    
    -- SOMMO I SINGOLI CONSUMI E OTTENGO IL TOTALE --
    SET consumoTotaleCasa = consumoIlluminazione + consumoCondizionamento + consumoDispConsumoFisso + consumoDispConsumoVariabile + consumoDispNonInterrompibili;
	
    -- CALCOLO MEDIA 5giorni ENERGIA AUTO PRODOTTA --
    SET @dataIter = @dataRichiesta;
        
    WHILE @dataIter BETWEEN @dataRichiesta- INTERVAL 5 DAY AND @dataRichiesta
	DO
	SET  energiaProdotta = energiaProdotta + (
	    SELECT sum(pe.ValoreEnergia)
	    FROM ProduzioneEnergetica pe
		WHERE DAY(pe.TspRilevamento ) = DAY(@dataIter)
			AND HOUR(pe.TspRilevamento) BETWEEN HOUR(@dataIter) AND (HOUR(@dataIter) + 2)
                );
	    SET @dataIter = @dataIter + INTERVAL 1 DAY;
    END WHILE;
	SET  energiaProdotta = energiaProdotta  / 5;
        
    IF energiaProdotta IS NULL THEN
    SET energiaProdotta =0;
    END IF;
    -- VALUTO DELTA ENERGETICA --
    SET deltaEnergetico = energiaProdotta - consumoTotaleCasa;
    
    -- MODIFICA MANUALE PER IL TEST DI FUNZIONAMENTO --
    SET deltaEnergetico = 500; 
    -- --------------------------------------------- --
    
    IF deltaEnergetico>0 THEN

    DROP TABLE IF EXISTS Suggerimenti;
    CREATE TEMPORARY TABLE Suggerimenti(
        Id INT NOT NULL PRIMARY KEY,
        Risposta TINYTEXT
    );

    INSERT INTO Suggerimenti (Id, Risposta)
        SELECT p.id, 'In attesa...' as Risposta
        FROM Programma p
        WHERE (p.ConsumoMedio<=deltaEnergetico) AND p.ID NOT IN ( 
		-- controllo che il suggerimento non si sovrapponga ad una interazione già esistente
					SELECT p.ID
					FROM Programma p INNER JOIN Interazione i ON p.MacDispositivo =i.MacDispositivo
					WHERE i.TspPartenza BETWEEN @dataRichiesta AND (@dataRichiesta+ INTERVAL p.Durata minute)
						OR IFNULL(i.TspFine, CURRENT_TIME()) BETWEEN @dataRichiesta AND (@dataRichiesta+ INTERVAL p.Durata minute)
                        )
		ORDER BY p.ConsumoMedio DESC, p.ID DESC
		LIMIT 1;

        
	SELECT *
    FROM Suggerimenti;
               
    END IF;               
    
	END $$
    DELIMITER ;
    call analytics2;