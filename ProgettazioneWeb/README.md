# 🖼️noisExpression - Art Gallery Platform

**noisExpression** è un'applicazione web full-stack progettata per permettere agli artisti di pubblicare le proprie opere digitali e offrirne la visione ai visitatori attraverso una bacheca interattiva.

## 📄 Documentazione di Progetto

### [Home.php](https://www.google.com/search?q=./index.php)

Questa pagina funge da landing page e vetrina dinamica.

* **Slideshow:** Visualizza un'immagine pubblicata sul sito ogni 6 secondi, ruotando casualmente tra i contenuti della piattaforma.
* **Navigazione:** Fornisce l'accesso rapido alla sezione  *Discover* .

### [Discover.php](https://www.google.com/search?q=./html/discover.php)

La sezione principale per l'esplorazione delle opere, suddivise per genere artistico e tipologia (opere singole o in serie).

* **Esplorazione:** È possibile filtrare le opere per genere tramite il menu di navigazione a metà pagina.
* **Interazione con le "Carte":** Ogni opera è rappresentata da una card che mostra titolo, data di pubblicazione, nome dell'artista e nome della serie.
* **Visualizzazione Popup:** Cliccando su una card si apre un popup:
  * Se l'opera è  **singola** , viene mostrata l'immagine a tutto schermo.
  * Se l'opera fa parte di una  **serie** , è possibile navigare tra le immagini della serie stessa utilizzando le frecce direzionali.
* **Ricerca:** È presente una barra di ricerca per trovare opere specifiche all'interno del genere selezionato.

### Autenticazione (Sign up / Login)

La barra di navigazione gestisce dinamicamente l'accesso dell'utente:

* **Sign up:** Se l'utente non è loggato, può avviare la registrazione tramite un menu a comparsa.
* **Login:** Dallo stesso menu è possibile passare alla schermata di accesso inserendo email e password.
* **Profile:** Una volta effettuato l'accesso, il pulsante cambia per fornire il link diretto alla gestione del profilo.

### [Profilo.php](https://www.google.com/search?q=./html/profilo.php)

Area riservata all'utente per la gestione della propria identità artistica e il caricamento dei contenuti.

* **Dati Utente:** Visualizzazione di username, nome e cognome.
* **Identità Artistica:** Per caricare opere, l'utente deve prima impostare un  **nome d'arte unico** .
* **Upload Opere:**
  * Selezione del genere artistico.
  * Caricamento di singoli file o serie (se più di un'immagine, è possibile definire un nome per la serie).
  * Validazione lato server dei file e dei metadati inseriti.

---

### 🛠 Dettagli Tecnici

* **Frontend:** HTML5, CSS3 (Custom fonts: Gloock, Gantari), JavaScript Vanilla.
* **Backend:** PHP.
* **Database:** MySQL.

---

> **Copyright © 2025** > Progetto realizzato da **Michele S.** 
>
> Università di Pisa
