# Progetto di Basi di Dati - mySmartHome (A.A. 2020-2021)

## Descrizione del Progetto
Il progetto consiste nella progettazione e implementazione di un database relazionale (DBMS MySQL) per la gestione di una **Smart Home**. Il sistema, denominato **mySmartHome**, permette di monitorare e ottimizzare l'efficienza energetica, il comfort (climatizzazione e illuminazione) e la sicurezza di un'abitazione intelligente.

## Struttura del Lavoro
Il progetto è stato sviluppato seguendo le fasi canoniche della progettazione di basi di dati:
1. **Analisi delle Specifiche:** Studio dei requisiti per la gestione di utenti, stanze, dispositivi e consumi.
2. **Progettazione Concettuale:** Creazione del diagramma Entità-Relazione (E-R).
3. **Progettazione Logica:** Ristrutturazione del diagramma E-R e traduzione nel modello relazionale.
4. **Normalizzazione:** Analisi delle dipendenze funzionali per garantire la Forma Normale di Boyce-Codd.
5. **Analisi delle Prestazioni:** Valutazione del carico applicativo tramite tavole dei volumi e degli accessi, con introduzione di ridondanze ottimizzate.
6. **Implementazione:** Script SQL per la creazione del database, popolamento e sviluppo di logica di back-end (Trigger, Stored Procedure, Event).

## Funzionalità Implementate
Il database gestisce diverse aree tematiche:
* **Area Generale:** Accounting utenti e topologia dell'edificio (stanze, punti di accesso).
* **Area Dispositivi:** Gestione di smart plug, monitoraggio consumi e interazione utente-dispositivo.
* **Area Energia:** Contabilizzazione di energia rinnovabile (pannelli fotovoltaici) e gestione fasce orarie.
* **Area Comfort:** Impostazioni personalizzate per trattamento aria (clima) e smart lighting.
* **Area Sicurezza:** Monitoraggio accessi, rilevamento intrusioni e stato dei serramenti.
* **Data Analytics:** Implementazione di algoritmi per l'estrazione di regole associative (Association Rule Learning) per analizzare le abitudini degli utenti e ottimizzazione energetica.

## Tecnologie Utilizzate
* **DBMS:** Oracle MySQL.
* **Linguaggio:** MySQL.
* **Documentazione:** Word/draw.io per la documentazione e il disegno degli schemi.

## Collaboratori
Il progetto è stato realizzato in collaborazione con:
