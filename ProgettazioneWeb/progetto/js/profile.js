import {Utility, PHPRequestHandler} from './utility-general.js';

let filesArray = []; 
const utility = new Utility();
const phpRequest = new PHPRequestHandler();
let genreArray = []; // ['Generative','Glitch', 'Illustration', 'Animation', 'Photography', 'Motion', 'Immersive', 'AI', 'Abstract'];
let dropContainer, fileInput, dropLabel;

document.addEventListener("DOMContentLoaded", init);

/**
 * @summary Funzione di inizializzazione delle funzionalità principali della pagina profilo
 * @description  
 * Si occupa principalmente di 
 * 1. Impostare il bottone di logout
 * 2. Effettuare la sincronizzazione tra client e server dell'utente loggato
 * 3. Recuperare le informazioni del profilo utente e configurare l'interfaccia utente (header e informazioni profilo)
 * 4. Inizializzare gli eventi di drag-and-drop e upload
 * 5. Recuperare i generi artistici disponibili dal server per utilizzarli successivamente.
 * @async
 */
async function init() {
    setupLogout();
    const body = document.querySelector('body');
    const main = body.querySelector('main');
    // controllo che il client e il server siano sincronizzati
    try {
        let user = await phpRequest.getSessionUser();
        let text = await user.text();
        let json = utility.jsonParseText(text);
        if (sessionStorage.getItem('username') === null) {
            if (json.status === 'error') {
                throw new Error(json.error + ' >> ' + json.message);
            } else {
                // qualcosa è successo al sessionStorage e lo ripristiniamo
                if (json.content.username === null) 
                    throw new Error("json.content.username is null");
                sessionStorage.setItem('username', json.content.username);
                window.location.href = './../html/profile.php'; // ricarica la pagina
            }
        } 
    } catch (error) {
        window.location.href = './../html/home.php'; // se qualcosa è andato storto nella fase di sincronizzazione ritorna alla home, commentare la riga per vedere quali errori sono stati generati
        console.log(error); // eseguita solo se la riga precedente è commentata, utile ai fini di debug
    }

    // genero l'header e la sezione profile info
    try {
        // caso in cui sessionStorage username e client sono consistenti
        let header = generateHTMLHeaderProfile();
        body.insertBefore(header, main);

        let profileInfo = await phpRequest.fetchProfileInfo();
        let profileText = await profileInfo.text();
        let profileJson = utility.jsonParseText(profileText);

        setupProfileInfoElements(profileJson);
    } catch (error) {
        console.log(error);
    }

    // Setup degli eventi per il drag and drop dei file
    setupDragDropEvents();
    // Setup del bottone per l'upload dei file
    setupUploadButton();

    // ottiene i generi artistici possibili dal database
    phpRequest.getGenres()
        .then(response => {
            return response.text();
        })
        .then(text => {
            if (text) {
                let json = utility.jsonParseText(text);
                if (json.status === 'error') {
                    throw new Error(json.message + ' >> ' + json.error);
                }
                genreArray = json.content; 
            } else {
                console.log("Text response vuota");
            }
        })
        .catch(error => {console.log(error)});
}

/**
 * @summary Gestisce il setup delle informazioni del profilo utente, inclusa la possibilità di impostare un nome artistico.
 * @description
 * La funzione aggiorna i dati visualizzati nell'area del profilo, come il nome utente, il nome e cognome, e, se il nome artistico non è stato settato,
 * mostra un campo di input e un bottone per consentire all'utente di inserirlo. Se il nome artistico è già presente, viene visualizzato normalmente e 
 * rimosso l'input. Inoltre, la funzione gestisce l'evento di aggiornamento del nome artistico, invocando una richiesta al server per salvare il dato.
 *
 * @param {Object} json - Oggetto JSON contenente i dati del profilo dell'utente. 
 * Il formato di `json.content` deve includere `username`, `firstname`, `lastname`, e `artistname` (quest'ultimo può essere `null` o una stringa).
 */
function setupProfileInfoElements(json) {
    const profileContainer = document.querySelector("div.profile-info");
    const usernameP = profileContainer.querySelector("ul li.username p:not(:first-child)");
    usernameP.textContent = json.content.username;
    const firstnameP = profileContainer.querySelector("ul li.first-name p:not(:first-child)");
    firstnameP.textContent = json.content.firstname;
    const lastnameP = profileContainer.querySelector("ul li.last-name p:not(:first-child)");
    lastnameP.textContent = json.content.lastname;
    
    if (json.content.artistname === null || json.content.artistname === '') { // nome artistico non settato
        // render input elem per inserire il nome artistico e il button per l'invio del nome al server
        const artistLi = profileContainer.querySelectorAll("ul li.artist-name p");
        // Crea l'elemento input
        const input = document.createElement("input");
        input.id = "artist-name";
        input.type = "text";
        input.name = "artist-name";
        input.placeholder = "Set your artist name";
        input.required = true;
        input.setAttribute("pattern", "^[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ.]+(?:\\s[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ.]+)*$");
        artistLi[1].appendChild(input);

        // Crea il bottone
        const button = document.createElement('button');
        button.id = 'update';
        button.type = 'button';
        button.textContent = 'Update Profile';
        profileContainer.appendChild(button);

        // aggiungo l'evento al bottone per aggiornare il profilo
        button.addEventListener("click", () => {
            sendArtistName(input);
        });
    } else { // nome artistico settato
        // Trova il li con la classe artist-name
        const artistP = profileContainer.querySelector("ul li.artist-name p:not(:first-child)");
        const input = document.querySelector("input#artist-name");

        // rimuove l'input element nel paragrafo 
        if (input) { artistP.remove(input); }
        
        // aggiorna il contenuto del paragrafo con il nome dell'artista
        artistP.textContent = json.content.artistname;
        
        // Rimuovi il bottone se esiste
        const button = document.querySelector('#update');
        if (button) { button.remove(); }
    }
}

/**
 * @summary Gestisce l'invio del nome artistico al server per l'aggiornamento del profilo.
 * @description
 * La funzione invia il nome artistico inserito dall'utente al server tramite una richiesta PHP.
 * Se il nome è valido, viene inviato e, in caso di successo, la pagina viene ricaricata.
 * In caso di errore, viene mostrato un messaggio di errore.
 *
 * @param {HTMLInputElement} input - Il campo di input contenente il nome artistico da inviare al server.
 */
function sendArtistName(input) {
    const value = input.value;
    if (input.checkValidity()) {
        // Invia il nome artistico al server
        let promise = phpRequest.setArtistName(value);
        promise
            .then(response => {
                return response.text();
            })
            .then(text => {
                let json = utility.jsonParseText(text);
                if (json.status === 'error')
                    throw new Error(json.error);
                console.log(json);
                window.location.href = './../html/profile.php'; // Ricarica la pagina del profilo
            })
            .catch(error => {
                alert(error); // Mostra errore in caso di problemi
            });
    }
    else {
        alert("Artist name not valid");
    };
}

/**
 * @summary Imposta il comportamento di logout al click del bottone di logout.
 */
function setupLogout() {
    const logoutButton = document.querySelector(".logout button");  
    logoutButton.addEventListener("click", () => {
        window.location.href = './../php/operations/logout.php';  // Reindirizza alla pagina di logout
    });
}

/**
 * @summary Configura gli eventi di drag and drop per il caricamento dei file.
 * @description
 * Questa funzione imposta il flusso di eventi di drag and drop all'interno di un contenitore specifico per il caricamento dei file.
 * Gestisce le seguenti azioni:
 * 1. `dragover`: Permette il drop dei file.
 * 2. `dragenter`: Attiva un'animazione visiva quando un elemento entra nel contenitore.
 * 3. `dragleave`: Rimuove l'animazione visiva quando l'elemento esce dal contenitore.
 * 4. `drop`: Gestisce il drop dei file, li trasferisce in un array e aggiorna l'interfaccia utente.
 * 5. `change`: Gestisce l'input dei file tramite il selettore file e aggiorna l'interfaccia utente con i file caricati.
 * 
 */
function setupDragDropEvents() {
    dropContainer = document.getElementById("dropcontainer"); 
    dropLabel = document.querySelector("#dropcontainer label");
    fileInput = document.getElementById("images"); 
    
    let dragCounter = 0;  // Variabile per gestire l'animazione di dragenter e dragleave
    
    // Evento per permettere il drop dei file
    dropContainer.addEventListener("dragover", (e) => {
        e.preventDefault();  // Previene il comportamento di default (l'apertura dei file)
    }, false);  // Il listener è eseguito durante la fase di bubbling (quando l'evento si propaga dal figlio al genitore) e non di captuiring
    
    /**
     * Evento che attiva l'animazione quando un file entra nell'area di drop
     */
    dropContainer.addEventListener("dragenter", (e) => {
        e.preventDefault();  // Previene il comportamento di default
        dragCounter++; 
        dropContainer.classList.add("drag-active");  // Aggiunge la classe per attivare l'animazione visiva
    });

    /**
     * Evento che rimuove l'animazione quando un file esce dall'area di drop
     */
    dropContainer.addEventListener("dragleave", () => {
        dragCounter--;
        if (dragCounter === 0) {
            dropContainer.classList.remove("drag-active");  // Rimuove la classe per disattivare l'animazione
        }
    });
    
    /** 
     * Evento che gestisce i file quando vengono "droppati" nell'area di drop
     */
    dropContainer.addEventListener("drop", (e) => {
        e.preventDefault();  // Evita che i file vengano aperti automaticamente
        dragCounter = 0; 
        dropContainer.classList.remove("drag-active");  // Rimuove l'animazione di drag
        fileTransfer(e.dataTransfer);  // Trasferisce i file nell'array
        updateUploadContainer(filesArray);  // Aggiorna l'interfaccia con la lista dei file caricati
    });

    /** 
     * Evento che gestisce il cambiamento dell'input file
     */
    fileInput.addEventListener("change", () => {
        fileTransfer(fileInput);  // Trasferisce i file selezionati nell'array
        updateUploadContainer(filesArray);  // Aggiorna l'interfaccia con la lista dei file caricati
    });
}

/**
 * @summary Aggiunge i file caricati all'array globale, filtrando quelli non ammessi.
 * @description
 * Questa funzione riceve un oggetto `dataTransfer` o un `HTMLInputElement` di tipo file
 * e aggiunge i file contenuti in `dataTransfer.files` all'array globale `filesArray`.
 * Dopo l'aggiunta, applica il filtro per rimuovere file non validi (troppo grandi, non immagini, o oltre il limite di 20).
 * Se vengono rimossi file, mostra un alert con i possibili errori.
 *
 * @param {DataTransfer | HTMLInputElement} dataTransfer - L'oggetto contenente i file caricati dall'utente.
 */
function fileTransfer(dataTransfer) {
    // Converte FileList in un array e lo concatena a filesArray
    filesArray = [...filesArray, ...Array.from(dataTransfer.files)];

    let len = filesArray.length;
    
    // Filtra i file non ammessi (massimo 20 file, solo immagini, max 3MB)
    filesArray = filterFiles(filesArray);

    // Se la lunghezza dell'array è cambiata, significa che alcuni file non rispettano i vincoli
    if (len > filesArray.length) {
        alert("E' accaduto uno dei seguenti errori:\n" +
              "1. Hai caricato più di 20 immagini\n" +
              "2. Uno o più file non sono immagini\n" +
              "3. Una o più immagini superano i 3MB\n");
    }
}

/**
 * @summary: Aggiorna la finestra di drag and drop mostrando le immagini caricate e i campi
 * genere e serie 
 * 
 * @description:
 * Questa funzione gestisce il display dei file selezionati nella finestra di upload, 
 * permettendo all'utente di visualizzare le immagini caricate e, se necessario, 
 * rimuoverle tramite una "X" accanto al nome del file. Infine aggiunge anche i campi
 * genere artistico e serie in modo da permettere all'utente di scegliere il nome della serie
 * e il genere artistico delle opere caricate.
 * 
 * @param {File[]} files - Un array di oggetti File che rappresentano le immagini caricate dall'utente.
 */
function updateUploadContainer(files) {
    const existingContainerSerie = document.querySelector('#seriecontainer');
    const existingContainerGenre = document.querySelector('#genrecontainer');
    const form = document.querySelector("#uploadcontainer");
    // elimino l'eventuale etichetta della serie 
    if (existingContainerSerie) {
        form.removeChild(existingContainerSerie);
    }
    // elimino l'eventuale etichetta dei generi artistici 
    if (existingContainerGenre) {
        form.removeChild(existingContainerGenre);
    }
    
    // mostra input field per impostare il nome della serie di opere
    if (files.length > 0) {
        const uploadButton = document.querySelector("#uploadcontainer button");
        const labelSerie = generateHTMLSerieField(files);
        form.insertBefore(labelSerie, uploadButton);
        // passo l'array di generi artistici, precedentemente aggiornato da una funzione asincrona
        const labelGeners = generateHTMLSelectGenre(genreArray);
        form.insertBefore(labelGeners, uploadButton);
    }
    updateFileContainer(files);
}
/**
 * @summary: Aggiorna la finestra di drag and drop mostrando le immagini caricate
 * 
 * @description:
 * A differenza della updateUploadContainer questa funzione si occupa solo di
 * gestisce il display dei file selezionati nella finestra di drag and drop, 
 * permettendo all'utente di visualizzare le immagini caricate e, se necessario, 
 * rimuoverle tramite una "X" accanto al nome del file.
 * 
 * @param {File[]} files - Un array di oggetti File che rappresentano le immagini caricate dall'utente.
 */
function updateFileContainer(files) {
    const existingFileList = dropContainer.querySelector('#filelist');
    let update = false;
    if (existingFileList) {
        dropContainer.removeChild(existingFileList);
        update = true;
    }
    
    if (files.length > 0) {
        console.log(files);
        const ul = document.createElement('ul');
        ul.id = 'filelist';
        files.forEach((file, index) => {
            const li = document.createElement('li');
            const fileTitleDiv = document.createElement('div');
            const removeDiv = document.createElement('div');
            const removeP = document.createElement('p');

            // Display del nome del file
            fileTitleDiv.textContent = file.name;

            // Aggiunge il bottone per rimuovere il file
            removeP.textContent = 'x';
            removeP.addEventListener('click', () => {
                // Rimuove l'i-esimo file dall'array corrispondente all'i-esimo elemento p cliccato
                filesArray = filesArray.filter((_, i) => i !== index);
                updateUploadContainer(filesArray); // update dello UI
            });

            removeDiv.appendChild(removeP);
            li.append(fileTitleDiv, removeDiv);
            ul.appendChild(li);
        });
        
        if (!update) {
            // se mi trovo qui allora è la prima chiamata di funzione
            dropContainer.removeChild(dropLabel);
        }
        dropContainer.append(ul);
    } else {
        const ul = document.querySelector("#dropContainer ul");
        if (ul !== null)
            dropContainer.removeChild(ul);
        dropContainer.append(dropLabel);
        fileInput.value = '';
    }
}

/**
 * @summary Configura il comportamento del bottone di upload per il caricamento dei file.
 * @description
 * Questa funzione aggiunge un listener all'evento "click" del bottone di upload. Quando l'utente clicca il bottone, la funzione esegue i seguenti passaggi:
 * 1. Verifica che sia stato scelto un nome d'arte (se non è presente, impedisce l'upload dei file).
 * 2. Verifica che l'array di file da caricare non sia vuoto.
 * 3. Recupera i dati necessari come l'username, l'ID del genere e il titolo della serie.
 * 4. Esegue dei controlli di validità sui campi passati (incluso il titolo della serie e l'ID del genere).
 * 5. Invia i file, insieme ai dati aggiuntivi, al server tramite una richiesta HTTP per l'upload.
 * 6. Gestisce la risposta del server e aggiorna l'interfaccia utente con i risultati dell'upload.
 * 7. Se l'upload è andato a buon fine, svuota l'array dei file e aggiorna l'interfaccia utente.
 * 
 */
function setupUploadButton() {
    const button = document.querySelector("#upload form > button");  

    button.addEventListener("click", () => {
        // Controlla se è stato scelto un nome d'arte
        const artistInput = document.querySelector('#artist-name');  
        if (artistInput !== null) {
            alert('Non puoi caricare opere senza aver prima scelto un nome d\'arte');
            filesArray = []; // svuota l'array dei file
            updateUploadContainer(filesArray); // aggiorna l'interfaccia
            return;
        }

        console.log(filesArray); // fa il log dei file da inviare

        // Se l'array di file è vuoto, non fare nulla
        if (filesArray.length === 0) {
            alert('Nessun file caricato');
            return;
        }

        // Recupera i dati necessari per l'upload
        const username = sessionStorage.getItem('username');
        const genreId = document.querySelector('select').value;
        const seriesTitle = document.querySelectorAll('#seriecontainer input');

        // Controlla la validità dei campi
        if (!utility.checkValidity(seriesTitle)) {
            alert('Nome della serie vuoto o non valido');
            return;
        }

        // Verifica che l'ID del genere sia un numero valido
        if (isNaN(genreId)) {
            alert("L'id del genere non è un numero");
            return;
        }

        // Verifica che l'ID del genere sia compreso tra 2 e 10
        if (genreId < 2 || genreId > 10) {
            alert('L\'id del genere artistico è fuori dall\'intervallo');
            return;
        }

        // Effettua la richiesta per caricare i file
        phpRequest.uploadFiles(username, genreId, seriesTitle[0].value, filesArray)
            .then(response => {
                return response.text();
            })
            .then(text => {
                if (text) {
                    let json = utility.jsonParseText(text);
                    if (json.status === 'error') {
                        // Mostra errore se qualcosa è andato storto
                        alert(json.error);
                    } else {
                        console.log('Upload completato');
                        console.log(json); // fa il log della risposta del server
                        filesArray = []; // svuota l'array dei file
                        updateUploadContainer(filesArray); // aggiorna l'interfaccia
                    }
                }
            })
            .catch(error => {
                consol.log(error); // Gestione errori
            });
    });
}


/**
 * @summary Filtra i file non ammessi in base a tre criteri principali.
 * @description
 * Questa funzione accetta un array di file e applica tre filtri:
 * 1. Accetta solo file di tipo immagine.
 * 2. Esclude i file con dimensioni superiori a 3 MB.
 * 3. Limita il numero massimo di file a 20.
 *
 * @param {File[]} array - Un array contenente i file caricati.
 * @returns {File[]} Un nuovo array contenente solo i file che rispettano i criteri di selezione.
 */
function filterFiles(array) {
    array = array.filter(file => file.type.startsWith('image/')); // Accetta solo immagini
    array = array.filter(file => file.size <= 3145728); // Esclude file superiori a 3 MB
    array = array.slice(0, 20); // Limita il numero massimo di file a 20
    return array;
}

/**
 * @summary Genera un elemento label con un menu a tendina per la selezione di un genere artistico.
 * @description
 * La funzione crea un `<label>` contenente un `<select>` precompilato con un elenco di generi artistici.
 * Ogni opzione del menu a tendina ha un valore numerico allineato con gli ID corrispondenti nel database.
 *
 * @param {string[]} optionsArray - Un array contenente i nomi dei generi artistici disponibili.
 * @returns {HTMLLabelElement} Un elemento label contenente un menu a tendina per la selezione del genere.
 */
function generateHTMLSelectGenre(optionsArray) {
    // Crea il lable elem
    const label = document.createElement('label');
    label.id = 'genrecontainer';
    label.setAttribute('for', 'genre');

    // Crea lo span element
    const span = document.createElement('span');
    span.textContent = 'Choose a genre ';
    label.appendChild(span);

    // Crea il select element
    const select = document.createElement('select');
    select.setAttribute('name', 'genre');
    select.id = 'genre';
    label.appendChild(select);

    // Popola il select element con gli option elements
    optionsArray.forEach((value, index) => {
        const option = document.createElement('option');
        option.value = index + 2;  // Set the value, + 2 mi permette di allineare i valori con i rispettivi id nel database
        option.textContent = value;  // Set the display text
        select.appendChild(option);
    });

    return label;
}

/**
 * @summary Crea un campo di input HTML per il nome della serie, con validazione e personalizzazione.
 * @description
 * Questa funzione genera dinamicamente un campo di input HTML all'interno di un'etichetta (`label`) per il nome della serie. 
 * Se l'array passato come parametro contiene un solo elemento, l'input viene disabilitato e il valore viene impostato su "Singoli".
 * Viene applicata una validazione tramite un pattern RegEx per assicurarsi che il nome della serie segua un formato corretto.
 *
 * @param {Array} array - Un array che contiene informazioni relative alle serie. Se contiene un solo elemento, l'input viene disabilitato.
 * @returns {HTMLElement} Un elemento `label` che contiene un campo di input per il nome della serie.
 */
function generateHTMLSerieField(array) {
    const label = document.createElement('label');
    const span = document.createElement('span');
    label.id = 'seriecontainer';
    label.setAttribute('for', 'serie');
    span.textContent = 'Serie\'s name'
    const input = document.createElement('input');
    label.append(span, input);
    input.id = 'serie';
    input.required = true;
    input.type = 'text';
    input.placeholder = 'insert'
    input.pattern = '^[A-ZÀ-Ý][A-Za-zÀ-ÿ]+(?:\\s[A-ZÀ-Ý][A-Za-zÀ-ÿ]+)*$';
    
    if (array.length === 1) {
        // appartiene ai singoli
        input.disabled = true; // Completamente non-focusable
        input.tabIndex = -1;  // Si assicura che non possa essere selezionato tramite tab
        input.value = 'Singoli';
    }

    return label;
}
/**
 * @summary Crea un'intestazione HTML per il profilo dell'artista, con il solo nome del sito in modo da poter tornare alla home page
 * @description
 * Questa funzione genera dinamicamente un'intestazione (`header`) contenente il nome del sito (con un link alla homepage) 
 *
 * @returns {HTMLElement} Un elemento `header` che contiene il nome del sito e il link all'opera.
 */
function generateHTMLHeaderProfile() {
    const header = document.createElement("header");
    header.className = "general-header";

    const siteName = document.createElement("a");
    siteName.id = "site-name";
    siteName.href = "home.php";
    siteName.textContent = "noisExpression";
    header.appendChild(siteName);  

    return header;
}