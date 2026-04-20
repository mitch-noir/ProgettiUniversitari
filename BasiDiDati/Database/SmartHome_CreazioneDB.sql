BEGIN;
DROP DATABASE IF EXISTS SmartHome; 
CREATE DATABASE SmartHome;
COMMIT;


BEGIN;
USE SmartHome;
COMMIT;

BEGIN;
DROP TABLE IF EXISTS Corrispondenza;
DROP TABLE IF EXISTS Suggerimento;
DROP TABLE IF EXISTS Regola;
DROP TABLE IF EXISTS Settaggio;
DROP TABLE IF EXISTS Interazione;
DROP TABLE IF EXISTS Possesso;
DROP TABLE IF EXISTS Impostazione;
DROP TABLE IF EXISTS Programma;
DROP TABLE IF EXISTS LivelloPotenza;
DROP TABLE IF EXISTS ConsumoFisso;
DROP TABLE IF EXISTS CicloNonInterrompibile;
DROP TABLE IF EXISTS ConsumoVariabile;
DROP TABLE IF EXISTS Dispositivo;
DROP TABLE IF EXISTS SmartPlug;
DROP TABLE IF EXISTS ProduzioneEnergetica;
DROP TABLE IF EXISTS PannelloFotovoltaico;
DROP TABLE IF EXISTS ContatoreBidirezionale;
DROP TABLE IF EXISTS FasciaOraria;
DROP TABLE IF EXISTS Documento;
DROP TABLE IF EXISTS Utente;
DROP TABLE IF EXISTS ImpostazioneDiCondizionamento;
DROP TABLE IF EXISTS Selezione;
DROP TABLE IF EXISTS Account; 
DROP TABLE IF EXISTS ElementoDiCondizionamento;
DROP TABLE IF EXISTS ImpostazioneIlluminazione; 
DROP TABLE IF EXISTS Intensity;
DROP TABLE IF EXISTS Assegnazione; 
DROP TABLE IF EXISTS ElementoIlluminazione; 
DROP TABLE IF EXISTS Temperatura;
DROP TABLE IF EXISTS AccessoDallEsterno;
DROP TABLE IF EXISTS Stato;
DROP TABLE IF EXISTS Serramento;
DROP TABLE IF EXISTS PuntoDiAccesso;
DROP TABLE IF EXISTS Permanenza;
DROP TABLE IF EXISTS RilevamentoInterno;
DROP TABLE IF EXISTS Rilevamento;
DROP TABLE IF EXISTS CollegamentoInterno;
DROP TABLE IF EXISTS Stanza;
DROP TABLE IF EXISTS Porta;
DROP TABLE IF EXISTS Fotografia;
DROP TABLE IF EXISTS Intruso;
DROP TABLE IF EXISTS Persona;
COMMIT;

-- Persona(Codice)
-- ------------------------------------ --
-- --           Persona              -- --
-- ------------------------------------ --
BEGIN;
CREATE TABLE Persona(
    Codice      INT     NOT NULL AUTO_INCREMENT,
    CONSTRAINT  pk_persona PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Intruso(ID, Persona)
-- ------------------------------------ --
-- --           Intruso              -- --
-- ------------------------------------ --
CREATE TABLE Intruso(
    ID              INT     NOT NULL AUTO_INCREMENT, 
    Persona         INT     NOT NULL,
    CONSTRAINT  fk_infiltrato FOREIGN KEY (Persona) REFERENCES Persona(Codice),
    CONSTRAINT  pk_intruso PRIMARY KEY (Id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--  Fotografia(Tsp, Immagine, Intruso)
-- ------------------------------------ --
-- --          Fotografia            -- --
-- ------------------------------------ --
CREATE TABLE Fotografia(
    Tsp             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP, 
    Immagine        VARCHAR(300)    NOT NULL, -- contiene il percorso in cui è salvata l'immagine
    Intruso         INT             NOT NULL,
    CONSTRAINT  fk_sorveglianza FOREIGN KEY (Intruso) REFERENCES Intruso(ID),
    CONSTRAINT  pk_fotografia PRIMARY KEY (Tsp)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Porta(Numero)
-- ------------------------------------ --
-- --           Porta                -- --
-- ------------------------------------ --
CREATE TABLE Porta(
    Numero      INT     NOT NULL,
    CONSTRAINT  pk_porta PRIMARY KEY (Numero)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--  Stanza(Numero, Lunghezza, Larghezza, Altezza, LivelloDiDispersione, Nome, LivelloEfficienza, Piano)
-- ------------------------------------ --
-- --           Stanza               -- --
-- ------------------------------------ --
CREATE TABLE Stanza(
    Numero              INT         NOT NULL,
    Lunghezza           FLOAT       NOT NULL,
    Larghezza           FLOAT       NOT NULL,
    Altezza             FLOAT       NOT NULL,
    LivelloDispersione  FLOAT       NOT NULL,
    Nome                VARCHAR(100)    NOT NULL,
    LivelloEfficienza   FLOAT       NOT NULL,
    Piano               TINYINT     NOT NULL,
    CONSTRAINT  ck_altezza CHECK(Altezza >= 2.5 AND Altezza <= 30),
    CONSTRAINT  ck_lunghezza CHECK(Lunghezza >= 1 AND Lunghezza <= 30),
    CONSTRAINT  ck_larghezza CHECK(Larghezza >= 1 AND Larghezza <= 30),
    CONSTRAINT ck_piano CHECK(Piano >= -1),
    CONSTRAINT  pk_stanza PRIMARY KEY (Numero)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
 
-- (NumeroStanza, NumeroPorta)
-- ------------------------------------ --
-- --      CollegamentoInterno       -- --
-- ------------------------------------ --
CREATE TABLE CollegamentoInterno(
    NumeroStanza        INT      NOT NULL,
    NumeroPorta         INT      NOT NULL, 
    CONSTRAINT  fk_numeroporta FOREIGN KEY (NumeroPorta) REFERENCES Porta(Numero),
    CONSTRAINT  fk_numerostanza FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero), 
    CONSTRAINT  pk_porta PRIMARY KEY (NumeroStanza, NumeroPorta)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

 
-- Rilevamento(Tsp, UmiditaEsterna, TemperaturaEsterna)
-- ------------------------------------ --
-- --           Rilevamento          -- --
-- ------------------------------------ --
CREATE TABLE Rilevamento(
    Tsp                 TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    UmiditaEsterna      FLOAT       NOT NULL,
    TemperaturaEsterna  FLOAT       NOT NULL,
    CONSTRAINT  pk_rilevamento PRIMARY KEY (Tsp),
    CONSTRAINT  ck_UmiditaEsterna CHECK (UmiditaEsterna >= 0 AND UmiditaEsterna <= 100) 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- RilevamentoInterno(TspRilevamentoEsterno, NumeroStanza, UmiditaInterna, TemperaturaInterna)
-- ------------------------------------ --
-- --        RilevamentoInterno      -- --
-- ------------------------------------ --
CREATE TABLE RilevamentoInterno(
    TspRilevamentoEsterno   TIMESTAMP   NOT NULL,
    NumeroStanza        INT         NOT NULL,
    UmiditaInterna      FLOAT       NOT NULL,
    TemperaturaInterna  FLOAT       NOT NULL,
    CONSTRAINT  fk_tsprilevamento FOREIGN KEY (TspRilevamentoEsterno) REFERENCES Rilevamento(Tsp) ON DELETE CASCADE, 
    CONSTRAINT  fk_stanzarilevamento FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero) ON DELETE CASCADE,
    CONSTRAINT  ck_UmiditaInterna CHECK (UmiditaInterna >= 0 AND UmiditaInterna <= 100), 
    CONSTRAINT  pk_rilevamentoInterno PRIMARY KEY (TspRilevamentoEsterno, NumeroStanza)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--  Permanenza(TspIniziale, Persona, NumeroStanza )
-- ------------------------------------ --
-- --           Permanenza           -- --
-- ------------------------------------ --
CREATE TABLE Permanenza(
    TspIniziale         DATETIME   DEFAULT CURRENT_TIMESTAMP,
    Persona             INT         NOT NULL,
    NumeroStanza        INT         NOT NULL,
    CONSTRAINT  pk_permanenza PRIMARY KEY (TspIniziale, Persona),
    CONSTRAINT  fk_sosta FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero),
    CONSTRAINT  fk_attuazione FOREIGN KEY (Persona) REFERENCES Persona(Codice)  
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



--  PuntoDiAccesso(ID, NumeroStanza,  PuntoCardinale, Tipologia)
-- ------------------------------------ --
-- --        PuntoDiAccesso          -- --
-- ------------------------------------ --
CREATE TABLE PuntoDiAccesso(
    Id                  INT         NOT NULL,
    Tipologia           VARCHAR(50) NOT NULL,
    PuntoCardinale      CHAR(2)     NOT NULL,
    NumeroStanza        INT         NOT NULL,
    CONSTRAINT  ck_puntoCardinale CHECK(PuntoCardinale IN ('N', 'NE', 'NO', 'S', 'SE', 'SO', 'E', 'O')),
    CONSTRAINT  ck_tipologia CHECK(Tipologia IN ('Finestra', 'Porta Finestra', 'Porta Ingresso')),
    CONSTRAINT  fk_collegamentoEsterno FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero),
    CONSTRAINT  pk_puntoAccesso PRIMARY KEY (Id, NumeroStanza)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Serramento(ID, Nome, PuntoAccesso, NumeroStanza)
-- ------------------------------------ --
-- --           Serramento           -- --
-- ------------------------------------ --
CREATE TABLE Serramento(
    Id                  INT         NOT NULL,
    Nome                VARCHAR(100)    NOT NULL,
    PuntoAccesso        INT         NOT NULL,
    NumeroStanza        INT         NOT NULL,
    CONSTRAINT  fk_fortificazione FOREIGN KEY (PuntoAccesso, NumeroStanza) REFERENCES PuntoDiAccesso(Id, NumeroStanza),
    CONSTRAINT  pk_serramento PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Stato(TspCambio, IdSerramento, Stato, Persona)
-- ----------------------------------- --
-- --           Stato                -- --
-- ------------------------------------ --
CREATE TABLE Stato(
    TspCambio           TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    IdSerramento        INT         NOT NULL,
    Stato               INT     NOT NULL,    
    Persona             INT         NOT NULL,
    CONSTRAINT  fk_sicurezza FOREIGN KEY (IdSerramento) REFERENCES Serramento(Id),
    CONSTRAINT  fk_cambio FOREIGN KEY (Persona) REFERENCES Persona(Codice),
    CONSTRAINT  pk_stato PRIMARY KEY (IdSerramento, TspCambio)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



-- AccessoDallEsterno(TspIN, PuntoAccesso, NumeroStanza, Persona)
-- ------------------------------------ --
-- --     AccessoDallEsternoStato    -- --
-- ------------------------------------ --
CREATE TABLE AccessoDallEsterno(
    TspIN           TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    PuntoAccesso    INT         NOT NULL, 
    NumeroStanza    INT         NOT NULL, 
    Persona         INT         NOT NULL,
    CONSTRAINT  fk_utilizzatore FOREIGN KEY (Persona) REFERENCES Persona(Codice),
    CONSTRAINT  fk_accesso FOREIGN KEY (PuntoAccesso, NumeroStanza) REFERENCES PuntoDiAccesso(Id, NumeroStanza),
    CONSTRAINT  pk_accessoesterno PRIMARY KEY (TspIN, PuntoAccesso, NumeroStanza)   
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Temperatura(Gradi) 
-- ----------------------------------- --
-- --         Temperatura           -- --
-- ----------------------------------- --
CREATE TABLE Temperatura(
    Gradi               INT         NOT NULL,
    CONSTRAINT  ck_gradi CHECK (Gradi >= 1500 AND Gradi <= 9000),
    CONSTRAINT  pk_temperatura PRIMARY KEY (Gradi) 
)ENGINE=InnoDB DEFAULT CHARSET = latin1;


-- ElementoIlluminazione(Id, Nome, NumeroStanza)
-- ----------------------------------- --
-- --     ElementoIlluminazione     -- --
-- ----------------------------------- --
CREATE TABLE ElementoIlluminazione(
    Id                  INT         NOT NULL,
    Nome                VARCHAR(100)    NOT NULL,
    NumeroStanza        INT         NOT NULL,
    CONSTRAINT  fk_installazione FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero),
    CONSTRAINT  pk_elementoIlluminazione PRIMARY KEY (Id)
)ENGINE=InnoDB DEFAULT CHARSET = latin1;

-- Assegnazione(Gradi, IdElemIlluminazione)
-- ----------------------------------- --
-- --          Assegnazione         -- --
-- ----------------------------------- --
CREATE TABLE Assegnazione(
    Gradi               INT         NOT NULL,
    IdElemIlluminazione INT         NOT NULL,
    CONSTRAINT  fk_elemIllum FOREIGN KEY (IdElemIlluminazione) REFERENCES ElementoIlluminazione(Id),
    CONSTRAINT  fk_temperatura FOREIGN KEY (Gradi) REFERENCES Temperatura(Gradi),
    CONSTRAINT  pk_elementoIlluminazione PRIMARY KEY (Gradi, IdElemIlluminazione)
)ENGINE=InnoDB DEFAULT CHARSET = latin1;

-- Intensity(Percentuale, IdElemIlluminazione, Potenza)
-- ----------------------------------- --
-- --          Intensity            -- --
-- ----------------------------------- --
CREATE TABLE Intensity(
    Percentuale         INT         NOT NULL,
    IdElemIlluminazione INT         NOT NULL, 
    Potenza             FLOAT         NOT NULL,
    CONSTRAINT  ck_potenza CHECK (Potenza >= 0 AND Potenza <= 1000), 
    CONSTRAINT  ck_intensity CHECK (Percentuale > 0 AND Percentuale <= 100),
    CONSTRAINT  fk_forza FOREIGN KEY (IdElemIlluminazione) REFERENCES  ElementoIlluminazione(Id),
    CONSTRAINT  pk_Intensity PRIMARY KEY (Percentuale, IdElemIlluminazione)   
)ENGINE=InnoDB DEFAULT CHARSET = latin1;

-- ImpostazioneIlluminazione(Numero, IdElementoIlluminazione, Livello*, Kelvin*)
-- ----------------------------------- --
-- --   ImpostazioneIlluminazione   -- --
-- ----------------------------------- --
CREATE TABLE ImpostazioneIlluminazione(
    Numero              INT         NOT NULL,
    IdElementoIlluminazione INT     NOT NULL,
    Livello             INT         NOT NULL,
    Kelvin              INT         NOT NULL,
    CONSTRAINT  fk_setting FOREIGN KEY (IdElementoIlluminazione) REFERENCES ElementoIlluminazione(Id),
    CONSTRAINT  ck_livello  CHECK (Livello in (10, 20, 30, 40, 50, 60, 70, 80, 90, 100) OR Livello IS NULL), 
    CONSTRAINT  ck_kelvin   CHECK ((Kelvin >= 1500 AND Kelvin <= 9000) OR Kelvin IS NULL),
    CONSTRAINT  pk_impostazioneIlluminazione PRIMARY KEY (Numero, IdElementoIlluminazione)
)ENGINE=InnoDB DEFAULT CHARSET = latin1;


-- ElementoDiCondizionamento(ID, PotenzaMedia, NumeroStanza)
-- ----------------------------------- --
-- --   ElementoDiCondizionamento   -- --
-- ----------------------------------- --
CREATE TABLE ElementoDiCondizionamento(
    ID                  INT     NOT NULL,
    PotenzaMedia        FLOAT   NOT NULL,
    NumeroStanza        INT     NOT NULL,
    CONSTRAINT  ck_potenzamedia CHECK(PotenzaMedia > 0 AND PotenzaMedia <= 3000),
    CONSTRAINT  fk_clima FOREIGN KEY (NumeroStanza) REFERENCES Stanza(Numero),
    CONSTRAINT  pk_elementoDiCondizionamento PRIMARY KEY (ID)
)ENGINE=InnoDB DEFAULT CHARSET = latin1;

-- Account(ID, Username, PSW, Question, Answer, Persona)
-- ----------------- --
-- --   Account   -- --
-- ----------------- --
CREATE TABLE Account(
    ID                  INT         NOT NULL,
    Username            VARCHAR(16)	NOT NULL,
    PSW                 VARCHAR(50)	NOT NULL,   
    Question            TEXT        NOT NULL,
    Answer              TEXT        NOT NULL,
    Persona             INT         NOT NULL,
    CONSTRAINT fk_manifestazione FOREIGN KEY (Persona) REFERENCES Persona(Codice),
    CONSTRAINT pk_account PRIMARY KEY (ID)
)ENGINE=InnoDB DEFAULT CHARSET = latin1;


-- Selezione(NumeroImpostazione, IdElementoIlluminazione, IdAccount, TspInizio, TspFine*)
-- ----------------------------------- --
-- --           Selezione           -- --
-- ----------------------------------- --
CREATE TABLE Selezione(
    NumeroImpostazione  INT         NOT NULL, 
    IdElementoIlluminazione INT     NOT NULL, 
    IdAccount           INT         NOT NULL, 
    TspInizio           TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    TspFine             TIMESTAMP   DEFAULT NULL, 

    CONSTRAINT  fk_Impostazione FOREIGN KEY (NumeroImpostazione, IdElementoIlluminazione) REFERENCES ImpostazioneIlluminazione(Numero,IdElementoIlluminazione),
    CONSTRAINT  fk_selezione    FOREIGN KEY (IdAccount) REFERENCES Account(ID),
    CONSTRAINT  pk_selezione PRIMARY KEY (NumeroImpostazione, IdElementoIlluminazione, IdAccount, TspInizio), 
    CONSTRAINT  ck_tspSelezione CHECK (TspInizio < TspFine)  
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ImpostazioneDiCondizionamento(ID, IdElementoDiCondizionamento, OraSpegnimento, OraAvvio, UmiditaTarget, TemperaturaTarget, DataInizio, DataFine, IdAccount)
-- ----------------------------------- --
-- -- ImpostazioneDiCondizionamento -- --
-- ----------------------------------- --
CREATE TABLE ImpostazioneDiCondizionamento(
    ID                  INT         NOT NULL,
    IdElementoDiCondizionamento INT NOT NULL,
    OraSpegnimento      TINYINT	    NOT NULL,
    OraAvvio            TINYINT     NOT NULL,
    UmiditaTarget       INT         NOT NULL,
    TemperaturaTarget   FLOAT       NOT NULL,
    DataInizio          DATE		NOT NULL,
    DataFine            DATE		NOT NULL,
    IdAccount           INT         NOT NULL,
    
    CONSTRAINT  ck_oraSpegnimento  CHECK(OraSpegnimento >= 0 AND OraSpegnimento < 24 ),
    CONSTRAINT  ck_oraAvvio  CHECK(OraAvvio >= 0 AND OraAvvio < 24 ),
    CONSTRAINT  ck_vincoloOra CHECK (OraSpegnimento > OraAvvio),
    CONSTRAINT  ck_umiditatarget CHECK (UmiditaTarget >= 0 AND UmiditaTarget <= 100),
    CONSTRAINT  ck_ordinedata CHECK (DataFine >= DataInizio),

    CONSTRAINT  fk_imposizione FOREIGN KEY (IdElementoDiCondizionamento) REFERENCES ElementoDiCondizionamento(ID),
    CONSTRAINT  fk_opzione FOREIGN KEY (IdAccount) REFERENCES Account(ID),
    CONSTRAINT  pk_impostazioneDiCondizionamento PRIMARY KEY (ID, IdElementoDiCondizionamento)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- Utente(CF, NumeroTelefono, DataIscrizione, DataNascita, Nome, Cognome, IdAccount)
-- ----------------------------------- --
-- --             Utente            -- --
-- ----------------------------------- --
CREATE TABLE Utente(
    CF                  CHAR(16)    NOT NULL,
    NumeroTelefono      CHAR(10)    NOT NULL,
    DataIscrizione      DATE	   	NOT NULL,
    DataNascita         DATE		NOT NULL,
    Nome                VARCHAR(50) NOT NULL,
    Cognome             VARCHAR(50) NOT NULL,
    IdAccount           INT         NOT NULL,

    CONSTRAINT  ck_dataUtente CHECK (DataIscrizione > DataNascita),
    CONSTRAINT  fk_registrazione FOREIGN KEY (IdAccount) REFERENCES Account(ID),
    CONSTRAINT  pk_utente PRIMARY KEY (CF)       
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Documento( IdDocumento, DataScadenza, Ente, Tipologia, CF)
-- ----------------------------------- --
-- --             Utente            -- --
-- ----------------------------------- --
CREATE TABLE Documento(
    IdDocumento         VARCHAR(20)    NOT NULL,
    DataScadenza        DATE		   NOT NULL,
    Ente                VARCHAR(50)	NOT NULL,
    Tipologia           VARCHAR(50) NOT NULL,
    CF                  VARCHAR(20)    NOT NULL,

    CONSTRAINT  fk_identificazione FOREIGN KEY (CF) REFERENCES Utente(CF),
    CONSTRAINT  pk_documento PRIMARY KEY (IdDocumento) 
) ENGINE = InnoDB DEFAULT CHARSET = latin1;  


-- FasciaOraria(Num, Nome, TspCreazione, OraInizio, OraFine, PrezzokWh, SceltaUtilizzo, IdAccount)
-- ----------------------------------- --
-- --           FasciaOraria        -- --
-- ----------------------------------- --
CREATE TABLE FasciaOraria(
    Num             INT             NOT NULL,
    Nome            VARCHAR(50)		NOT NULL,
    TspCreazione    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    OraInizio       TINYINT         NOT NULL,
    OraFine         TINYINT         NOT NULL,
    PrezzokWh       FLOAT           NOT NULL,
    SceltaUtilizzo  BOOL            NOT NULL,
    IdAccount       INT             NOT NULL,

    CONSTRAINT  ck_fasciaOff CHECK(OraFine >= 0 AND OraFine < 24 ),
    CONSTRAINT  ck_fasciaOn CHECK(OraInizio >= 0 AND OraInizio < 24 ),
    CONSTRAINT  ck_fascia CHECK (OraFine > OraInizio), 
    CONSTRAINT  ck_intervallo CHECK((((OraFine - OraInizio) >= 1) AND ((OraFine - OraInizio) <= 7 )) AND (((OraFine - OraInizio) <> 4)  AND ((OraFine - OraInizio) <> 6)) ),

    CONSTRAINT  fk_definizione FOREIGN KEY (IdAccount) REFERENCES Account(Id),
    CONSTRAINT  pk_fasciaOraria PRIMARY KEY (Num)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- ContatoreBidirezionale(TspRilevamento,  EnergiaOut, EnergiaIn, NumFasciaOraria)
-- ----------------------------------- --
-- --    ContatoreBidirezionale     -- --
-- ----------------------------------- --
CREATE TABLE ContatoreBidirezionale(
    TspRilevamento          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    EnergiaOUT              FLOAT      NOT NULL,
    EnergiaIN               FLOAT      NOT NULL,
    NumFasciaOraria         INT         NOT NULL,

    CONSTRAINT  ck_energia  CHECK (EnergiaIN >= 0 AND EnergiaOUT >= 0),
    CONSTRAINT  fk_passaggio FOREIGN KEY (NumFasciaOraria) REFERENCES FasciaOraria(Num),
    CONStraint  pk_contatore PRIMARY KEY (TspRilevamento)    
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- PannelloFotovoltaico(Id, Superficie, PotenzaNominale)
-- ----------------------------------- --
-- --     PannelloFotovoltaico      -- --
-- ----------------------------------- --
CREATE TABLE PannelloFotovoltaico(
    Id                      INT         NOT NULL,
    Superficie              FLOAT      NOT NULL,
    PotenzaNominale         FLOAT      NOT NULL,

    CONSTRAINT ck_superficie CHECK (Superficie >= 10 AND Superficie <= 50000), -- IN CM^2
    CONSTRAINT ck_nominale CHECK(PotenzaNominale >= 0),
    CONSTRAINT pk_contatore PRIMARY KEY (Id)  
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- ProduzioneEnergetica(TspRilevamento, IdPannello, ValoreEnergia, NumFasciaOraria )
-- ----------------------------------- --
-- --     ProduzioneEnergetica      -- --
-- ----------------------------------- --
CREATE TABLE ProduzioneEnergetica(
    TspRilevamento          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    IdPannello              INT             NOT NULL,
    ValoreEnergia           FLOAT          NOT NULL,
    NumFasciaOraria         INT             NOT NULL,

    CONSTRAINT ck_valoreEnergia CHECK (ValoreEnergia >= 0),
    CONSTRAINT fk_produzione FOREIGN KEY (NumFasciaOraria) REFERENCES FasciaOraria(Num),
    CONSTRAINT fk_fornitura FOREIGN KEY (IdPannello) REFERENCES  PannelloFotovoltaico(Id),
    CONSTRAINT pk_produzioneEnergetica PRIMARY KEY (TspRilevamento, IdPannello)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- SmartPlug(Codice, Stato)
-- ----------------------------------- --
-- --           SmartPlug           -- --
-- ----------------------------------- --
CREATE TABLE SmartPlug(
    Codice                  INT         NOT NULL,
    Stato                   BOOL     NOT NULL,
    CONSTRAINT pk_smartPlug PRIMARY KEY (Codice)  
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- Dispositivo(Mac, SmartPlug, Nome, OnOff)
-- ----------------------------------- --
-- --          Dispositivo          -- --
-- ----------------------------------- --
CREATE TABLE Dispositivo(
    Mac                     CHAR(12)    NOT NULL,
    SmartPlug               INT         NOT NULL,
    Nome                    VARCHAR(50)	NOT NULL,
    OnOff                   BOOL        NOT NULL DEFAULT 0,   -- attributo ridondante

    CONSTRAINT fk_smartPlug FOREIGN KEY (SmartPlug) REFERENCES SmartPlug(Codice),
    CONSTRAINT pk_dispositivo PRIMARY KEY (Mac)  
) ENGINE = InnoDB DEFAULT CHARSET = latin1;



-- ConsumoVariabile(MacDispositivo)
-- ----------------------------------- --
-- --        ConsumoVariabile       -- --
-- ----------------------------------- --
CREATE TABLE ConsumoVariabile(
    MacDispositivo          CHAR(12)    NOT NULL,
    CONSTRAINT fk_sottoinsieme1 FOREIGN KEY (MacDispositivo) REFERENCES Dispositivo(Mac),
    CONSTRAINT pk_ConsumoVariabile PRIMARY KEY (MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- CicloNonInterrompibile(MacDispositivo)
-- ----------------------------------- --
-- --     CicloNonInterrompibile    -- --
-- ----------------------------------- --
CREATE TABLE CicloNonInterrompibile(
    MacDispositivo          CHAR(12)    NOT NULL,
    CONSTRAINT fk_sottoinsieme3 FOREIGN KEY (MacDispositivo) REFERENCES Dispositivo(Mac),
    CONSTRAINT pk_CicloNonInterrimpibile PRIMARY KEY (MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ConsumoFisso(MacDispositivo, Power)
-- ----------------------------------- --
-- --           ConsumoFisso        -- --
-- ----------------------------------- --
CREATE TABLE ConsumoFisso(
    MacDispositivo          CHAR(12)    NOT NULL,
    Power                   FLOAT      NOT NULL,  
    CONSTRAINT fk_sottoinsieme2 FOREIGN KEY (MacDispositivo) REFERENCES Dispositivo(Mac),
    CONSTRAINT pk_ConsumoFisso PRIMARY KEY (MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- LivelloPotenza(Potenza)
-- ----------------------------------- --
-- --         LivelloPotenza        -- --
-- ----------------------------------- --
CREATE TABLE LivelloPotenza(
    Potenza                FLOAT      NOT NULL,  
    CONSTRAINT pk_LivelloPotenza PRIMARY KEY (Potenza)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Programma(ID, Durata, ConsumoMedio, Potenza, MacDispositivo )
-- ----------------------------------- --
-- --          Programma            -- --
-- ----------------------------------- --
CREATE TABLE Programma(
    ID                      INT         NOT NULL,
    Durata                  INT         NOT NULL,
    ConsumoMedio            FLOAT	    NOT NULL,    
    Potenza                FLOAT 	    NOT NULL,  
    MacDispositivo          CHAR(12)    NOT NULL,
	
    CONSTRAINT ck_potenzaProgramma CHECK (Potenza > 0 AND Potenza <= 2500),
    CONSTRAINT fk_comportamento FOREIGN KEY (MacDispositivo) REFERENCES CicloNonInterrompibile(MacDispositivo),
    CONSTRAINT fk_associazione FOREIGN KEY (Potenza) REFERENCES LivelloPotenza(Potenza),
    CONSTRAINT pk_programma PRIMARY KEY (ID)   
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Impostazione(Numero, Programma, Nome, Valore) 
-- ----------------------------------- --
-- --           Impostazione        -- --
-- ----------------------------------- --
CREATE TABLE Impostazione(
    Numero              INT             NOT NULL,
    Programma           INT             NOT NULL,
    Nome                VARCHAR(50)     NOT NULL,
    Valore              FLOAT	        NOT NULL,

    CONSTRAINT fk_programmazione FOREIGN KEY (Programma) REFERENCES Programma(ID),
    CONSTRAINT pk_impostazione PRIMARY KEY (Numero, Programma)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Possesso(Potenza, MacConsumoVariabile) 
-- ----------------------------------- --
-- --           Possesso            -- --
-- ----------------------------------- --
CREATE TABLE Possesso(
    Potenza              FLOAT	    NOT NULL,
    MacConsumoVariabile     CHAR(12)    NOT NULL,
    CONSTRAINT fk_setPotenza FOREIGN KEY (Potenza) REFERENCES LivelloPotenza(Potenza),
    CONSTRAINT fk_setConsumoVar FOREIGN KEY (MacConsumoVariabile) REFERENCES ConsumoVariabile(MacDispositivo),
    CONSTRAINT pk_Possesso PRIMARY KEY (Potenza, MacConsumoVariabile)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Interazione(TspPartenza, MacDispositivo, TspCreazione, TpsFine*, IdAccount ) 
-- ----------------------------------- --
-- --        Interazione            -- --
-- ----------------------------------- --
CREATE TABLE Interazione(
    TspPartenza             TIMESTAMP       NOT NULL,
    MacDispositivo          CHAR(12)        NOT NULL,
    TspCreazione            TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    TspFine                 TIMESTAMP,
    IdAccount               INT             NOT NULL,

    CONSTRAINT ck_tspss CHECK (TspPartenza >= TspCreazione AND TspPartenza <= TspFine ),
    CONSTRAINT fk_effettuazione FOREIGN KEY (IdAccount) REFERENCES Account(ID),
    CONSTRAINT pk_Interazione PRIMARY KEY (TspPartenza, MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Settaggio(TspPartenza, Potenza, MacDispositivo)
-- ----------------------------------- --
-- --          Settaggio            -- --
-- ----------------------------------- --
CREATE TABLE Settaggio(
    TspPartenza             TIMESTAMP       NOT NULL,
    Potenza              FLOAT          NOT NULL,
    MacDispositivo          CHAR(12)        NOT NULL,

    CONSTRAINT fk_interazione FOREIGN KEY (TspPartenza, MacDispositivo) REFERENCES Interazione(TspPartenza, MacDispositivo),
    CONSTRAINT fk_livellosettato FOREIGN KEY (Potenza) REFERENCES LivelloPotenza(Potenza),
    CONSTRAINT pk_Settaggio PRIMARY KEY (TspPartenza, Potenza, MacDispositivo)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Regola(TspPartenza, MacDispositivo, Programma)
-- ----------------------------------- --
-- --           Regola              -- --
-- ----------------------------------- --
CREATE TABLE Regola(
    TspPartenza             TIMESTAMP       NOT NULL,
    MacDispositivo          CHAR(12)        NOT NULL,
    Programma               INT             NOT NULL,
    
    CONSTRAINT fk_interazioneDispositivo FOREIGN KEY (TspPartenza, MacDispositivo) REFERENCES Interazione(TspPartenza, MacDispositivo),
    CONSTRAINT fk_regola FOREIGN KEY (Programma) REFERENCES Programma(ID),
    CONSTRAINT pk_Regola PRIMARY KEY (TspPartenza, MacDispositivo, Programma)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Suggerimento(ID, Testo, Risposta, IdAccount)
-- ----------------------------------- --
-- --          Suggerimento         -- --
-- ----------------------------------- --
CREATE TABLE Suggerimento(
    ID              INT         NOT NULL,
    Risposta        TEXT        NOT NULL,
    TspInizio       TIMESTAMP   NOT NULL,
    IdAccount       INT         NOT NULL,

    CONSTRAINT fk_Answer FOREIGN KEY (IdAccount) REFERENCES Account(ID),
    CONSTRAINT pk_suggerimento PRIMARY KEY (ID)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- Corrispondenza(IdSuggerimento, IdProgramma)
-- ----------------------------------- --
-- --       Corrispondenza          -- --
-- ----------------------------------- --
CREATE TABLE Corrispondenza(
    IdSuggerimento              INT         NOT NULL,
	IdProgramma					INT 		NOT NULL,
    CONSTRAINT fk_corrispProgramma FOREIGN KEY (IdProgramma) REFERENCES Programma(ID),
    CONSTRAINT fk_corrispSuggerimento FOREIGN KEY (IdSuggerimento) REFERENCES Suggerimento(ID),
    CONSTRAINT pk_corrispondenza PRIMARY KEY (IdSuggerimento, IdProgramma)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

COMMIT;