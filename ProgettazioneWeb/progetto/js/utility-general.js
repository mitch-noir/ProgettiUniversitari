import {Style} from './style-general.js';

/**
 * @class Utility
 * @description 
 * Questa classe contiene una serie di metodi utilitari che semplificano operazioni comuni
 * come la serializzazione di oggetti, la validazione di input, la gestione di stringhe e la
 * manipolazione dei percorsi delle immagini.
 */
export class Utility {
     /**
     * @summary Converte un oggetto JavaScript in una query string.
     * @description 
     * Questo metodo prende un oggetto JavaScript e lo converte in una stringa query  
     * compatibile con l'URL (ad esempio: "param1=value1&param2=value2").
     * @param {Object} obj - L'oggetto da serializzare.
     * @return {string} La query string risultante.
     * @link https://stackoverflow.com/questions/1714786/query-string-encoding-of-a-javascript-object
     */
    serialize(obj) {
        let str = [];
        for (let p in obj) {
            if (obj.hasOwnProperty(p)) {
                str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
            }
        }
        return str.join("&");
    }
    
    /**
     * @summary Verifica la validità di tutti gli input in una lista di input HTML.
     * @description 
     * Questo metodo controlla se tutti gli input in una NodeList (solitamente una lista di 
     * elementi `<input>`) sono validi in base alle regole di validazione HTML5.
     * @param {NodeListOf<HTMLInputElement>} inputElements  La lista di elementi di input da verificare.
     * @return {boolean} `true` se tutti gli input sono validi, altrimenti `false`.
     */
    checkValidity(inputElements) {
        let validity = true;
        for (const elem of inputElements) {
            validity &= elem.checkValidity(); // Verifica ogni campo
        }
        // return true; // decommentare questa linea per disabilitare la validazione in js, in modo da poter testare quella php
        return validity;  
    }
    
    /**
     * @summary Metodo che esegue il parsing di un oggetto testuale e tenta di convertirlo in JSON
     * @description 
     * Questo metodo analizza una stringa e restituisce l'oggetto JavaScript corrispondente.
     * Se il parsing fallisce, viene sollevato un errore con il testo che ha causato il problema.
     * @param {string} text La stringa da analizzare.
     * @return {Object|undefined} L'oggetto risultante dal parsing del JSON, o `undefined` se il testo è vuoto.
     * @throws {Error} Solleva un errore se il testo non è un valido JSON.
     */
    jsonParseText(text) {
        if (!text)
            return;
    
        let json;
        // eseguo il try cach cosi posso visualizzare cosa nel testo ha provocato l'errore
        try {
            json = JSON.parse(text);
        } catch (error) {
            throw new Error(error + "\n \\/\\/\\/ \n" + text);
        }

        return json;
    }

    /**
     * @summary Disabilita il menu contestuale (click destro) su tutte le immagini presenti nella pagina al momento della chiamata.
     * @description 
     * Questo metodo impedisce agli utenti di fare clic con il tasto destro su qualsiasi immagine 
     * presente nel documento, impedendo così il download diretto.
     */    
    preventImageDownload(){
        // Seleziona tutte le immagini nel documento
        const imgElements = document.querySelectorAll("img"); 
        imgElements.forEach(element => {
            element.addEventListener('contextmenu', (event) => {
                event.preventDefault(); // Disabilita il menu contestuale per ogni immagine
            });
        });
    }

    /**
     * @summary Capitalizza la prima lettera di una stringa.
     * @param {string} string La stringa di input da capitalizzare.
     * @return {string} La stringa con la prima lettera maiuscola.
     */
    capitalize(string){
        return String(string).charAt(0).toUpperCase() + String(string).slice(1);
    }

    /**
     * @summary Trasforma una stringa in un formato valido per essere utilizzato come ID.
     * @param {string} string - La stringa da trasformare.
     * @return {string} La stringa trasformata in un formato valido come ID.
     */
    formatId(string) {
        // converte la stringa in minuscolo e rimuove gli spazi.
        return string.toLowerCase().replace(/\s+/g, '');
    }
    
    /**
     * @summary Modifica un percorso di immagine assoluto in un percorso relativo.
     * @description 
     * Questo metodo converte un percorso di immagine assoluto (formato salvato nel database) 
     * in un percorso relativo, utile per la corretta visualizzazione nelle pagine web.
     * @param {string} originalPath Il percorso assoluto dell'immagine.
     * @return {string} Il percorso relativo dell'immagine.
     */
    transformImagesPath(originalPath) {
        const index = originalPath.indexOf('assets/');
    
        let ret = originalPath;
        if (index !== -1) {
            ret = `./../${originalPath.slice(index)}`
        }
        return ret;
    }
}

/**
 * @class PHPRequestHandler
 * @description 
 * Questa classe fornisce metodi per interagire con il server PHP,
 * inclusi il recupero di sessioni, il caricamento di file e la gestione dei dati utente, e invio dati.
 */
export class PHPRequestHandler {
    constructor() {
        this.utility = new Utility();
    }
    /**
     * @summary Recupera l'username della sessione corrente.
     * @description 
     * Questo metodo effettua una richiesta al server per ottenere il valore di `$_SESSION['username']`.
     * @async
     * @return {Promise<Response>} La risposta del server contenente l'username della sessione.
     * @throws {Error} Se la richiesta HTTP non va a buon fine.
     */    
    async getSessionUser() {
        const response = await fetch(
            './../php/operations/getSessionUser.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                }
            }
        );
    
        if (!response.ok) {
            throw new Error("Http error");
        }
        
        return response;
    }
    
    /**
     * @summary Recupera la lista dei generi artistici disponibili nel database.
     * @description 
     * Effettua una richiesta al server per ottenere un array con i nomi dei generi artistici disponibili.
     * @async
     * @return {Promise<Response>} La risposta del server in formato JSON nel cui campo content è presente la lista dei generi artistici.
     * @throws {Error} Se la richiesta HTTP non va a buon fine.
     */
    async getGenres() { 
        const response = await fetch(
            './../php/operations/getGenres.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                }
            }
        );
    
        if (!response.ok) {
            throw new Error("Http error");
        }
        
        return response;
    }

    /**
     * @summary Carica una o più immagini nel database.
     * @description 
     * Questo metodo invia file al server per essere salvati nel database, 
     * associadovi un genere, un artista e una serie.
     * @async
     * @param {string} username     Il nome utente di chi sta caricando i file.
     * @param {string} genreId      L'ID del genere artistico associato ai file.
     * @param {string} title        Il titolo della serie di immagini.
     * @param {File[]} arrayFiles   Un array di file da caricare.
     * @return {Promise<Response>}  La risposta del server.
     * @throws {Error}              Se la richiesta HTTP non va a buon fine.
     */
    async uploadFiles(username, genreId, title, arrayFiles) {
        // Crea un FormData object
        const formData = new FormData();

        // Fa lìappend dei dati di tipo non-file
        formData.append('username', username);
        formData.append('genreId', genreId);
        formData.append('title', title); // titolo della serie

        // Fa l'append dei files
        arrayFiles.forEach((file) => {
            formData.append(`images[]`, file);  
        });

        // Invia il FormData object al server
        const response = await fetch('./../php/operations/uploadFiles.php', {
            method: 'POST',
            body: formData 
        });

        if (!response.ok) {
            throw new Error("HTTP error");
        }

        return response;
    }   

    /**
     * @summary Recupera la lista dei file per un determinato genere artistico.
     * @description 
     * Effettua una richiesta al server per ottenere un array contenente informazioni sui file associati al genere specificato.
     * @async
     * @param {string} genre        Il genere artistico di cui recuperare i file.
     * @return {Promise<Response>}  La risposta del server contenente i dettagli dei file in formato JSON.
     * @throws {Error}              Se la richiesta HTTP non va a buon fine.
     */
    async getFileList(genre) {
        const json = {
            'genre': genre
        };
        const queryString = this.utility.serialize(json);
        const response = await fetch(
            './../php/operations/getArtworkList.php', 
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: queryString,
            }            
        );

        if (!response.ok) {
            throw new Error("HTTP error");
        }

        return response;
    }

    /**
     * @summary Imposta il nome artistico dell'utente attualmente loggato.
     * @async
     * @param {string} artistname   Il nome artistico da assegnare all'utente.
     * @return {Promise<Response>}  La risposta del server.
     * @throws {Error}              Se la richiesta HTTP non va a buon fine.
     */
    async setArtistName(artistname) {
        const queryObj = {
            'username': sessionStorage.getItem('username'),
            'artist-name': artistname
        };
        const queryString = this.utility.serialize(queryObj);
        const response = await fetch(
            './../php/operations/setArtistName.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: queryString
            }
        )

        if (!response.ok)
            throw new Error("Http error");

        return response;
    }

    /**
     * @summary Recupera le informazioni del profilo dell'utente loggato.
     * @description 
     * Effettua una richiesta al server per ottenere i dati relativi al profilo dell'utente attualmente loggato.
     * @async
     * @return {Promise<Response>} La risposta del server contenente i dettagli del profilo in formato JSON.
     * @throws {Error} Se la richiesta HTTP non va a buon fine.
     */
    async fetchProfileInfo() {
        const queryObj = {
            'username': sessionStorage.getItem('username')
        };
        const queryString = this.utility.serialize(queryObj);
        const response = await fetch(
            './../php/operations/getProfileInfo.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: queryString
            }
        )

        if (!response.ok)
            throw new Error("Http error");

        return response;
    }
    
    /**
     * @summary Recupera la descrizione dei generi artistici.
     * @description 
     * Questo metodo restituisce un JSON contenente una lista di descrizioni per i vari generi artistici.
     * @async
     * @return {Promise<Response>}  La risposta del server in formato JSON contenente un array di descrizioni dei generi artistici.
     * @throws {Error}     Se la richiesta HTTP non va a buon fine.
     */
    async getDescriptions() {
        const response = await fetch(
            './../php/operations/getDescription.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                }
            }
        );
        if (!response.ok) {
            throw new Error("Http error");
        } 
        return response;
    }
    
    /**
     * @summary Invia i dati di login al server.
     * @description 
     * Questo metodo effettua una richiesta al server PHP per autenticare un utente.
     * @async
     * @param {string} queryString Una stringa formattata con i dati di login
     * @return {Promise<Response>} La risposta del server contenente l'esito dell'autenticazione.
     * @throws {Error} Se la richiesta HTTP non va a buon fine.
     */
    async submitLogin(queryString) {
        const response = await fetch(
            './../php/operations/login.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: queryString,
            }
        );
        
        if (!response.ok) {
            throw new Error("Http error");
        }

        return response;
    }
    
    /**
     * @summary Invia i dati di registrazione al server.
     * @description 
     * Questo metodo effettua una richiesta al server PHP per registrare un nuovo utente.
     * @async
     * @param {string} queryString  Una stringa formattata come stringa query con i dati di registrazione
     * @return {Promise<Response>} La risposta del server contenente l'esito della registrazione.
     * @throws {Error} Se la richiesta HTTP non va a buon fine.
     */
    async submitSignup(queryString) {
        const response = await fetch(
            './../php/operations/signup.php',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: queryString,
            }
        );
        if (!response.ok) {
            throw new Error("Http error");
        }
        
        return response;
    }
}

// Configurazione dei campi del form di registrazione
const formConfig = [
    {
        label: "First Name", // Etichetta del campo
        id: "first-name", // ID del campo
        type: "text", // Tipo del campo (testo)
        placeholder: "ex: Marco Àmÿ", // Testo di esempio nel campo
        value: "Marco Pio", // Valore predefinito
        required: true, // Campo obbligatorio
        pattern: "^[A-ZÀ-Ý][A-Za-zÀ-ÿ]+(?:\\s[A-ZÀ-Ý][A-Za-zÀ-ÿ]+)*$" // Espressione regolare per validare l'input
    },
    // Configurazione per gli altri campi: cognome, email, password e selezione del ruolo
    {
        label: "Last Name",
        id: "last-name",
        type: "text",
        placeholder: "ex: De Rossi",
        value: "Rossi",
        required: true,
        pattern: "^[A-ZÀ-Ý][A-Za-zÀ-ÿ]+(?:\\s[A-ZÀ-Ý][A-Za-zÀ-ÿ]+)*$"
    },
    {
        label: "Email",
        id: "email",
        type: "email",
        placeholder: "youremail@example.com",
        value: "marcopio.rossi00@example.com",
        required: true,
        pattern: "^(.+)@([^\\.].*)\\.([a-z]{2,})$" // Da correggere per email più precise
    },
    {
        label: "Password",
        id: "password",
        type: "password",
        placeholder: "ex: a-A9bbbbb",
        value: "qiwuh-72992yGHYU",
        required: true, // 
        pattern: "^(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])(?=.*[\\W]).{8,40}$" 
        // Almeno 8 caratteri, almeno un numero, almeno una maiuscola, almeno una minuscola, almeno un carattere speciale          
    }
];

// Classi CSS usate nel menu di registrazione
const MENU_CLASS = "signup-menu";
const CONTAINER_CLASS = "signup-container";
// classi di utilità
const utility = new Utility();
const phpRequest = new PHPRequestHandler();

/**
 * @summary Gestisce l'accesso e la registrazione tramite il pulsante fornito.
 * @description 
 * Crea e gestisce dinamicamente il menu di registrazione e login, 
 * permettendo all'utente di inserire i propri dati e inviarli al server.
 * @param {HTMLElement} elementTrigger L'elemento che attiverà il menu di registrazione.
 */
function accessHandler(elementTrigger) {
    const HTMLElement = elementTrigger; // Riferimento all'elemento che attiverà il menu di registrazione
    createSignUpMenu(); // Crea il menu di registrazione
    addEventHandler(); // Aggiunge gli eventi al pulsante di attivazione

    // Crea il menu di registrazione e lo aggiunge al DOM
    function createSignUpMenu(){
        const containerDiv = document.createElement("div");
        const menuDiv = document.createElement("div");
        menuDiv.classList.add(MENU_CLASS); // Aggiunge la classe CSS per il menu
        containerDiv.classList.add(CONTAINER_CLASS); // Aggiunge la classe CSS per il contenitore
        containerDiv.appendChild(menuDiv);
        document.body.appendChild(containerDiv);

        generateForm(); // Genera il form di registrazione
        const loginDiv = loginOption(); // Aggiunge l'opzione per il login
        menuDiv.appendChild(loginDiv);
        focusOut(); // Gestisce la chiusura del menu quando si clicca fuori
    }

    // Aggiunge gli eventi di attivazione al pulsante
    function addEventHandler() {
        HTMLElement.addEventListener("click", () => {
            const signUpContainer = document.querySelector(`.${String(CONTAINER_CLASS)}`);
            signUpContainer.classList.add("focused"); // Mostra il menu
            signUpContainer.classList.add("up"); // Aggiunge uno stile visibile
        });
    }

    // Genera il form di registrazione dinamicamente
    function generateForm() {
        deleteMenu(); // Rimuove eventuali contenuti esistenti
        const divElement = document.querySelector(`.${String(MENU_CLASS)}`);
        
        const formElement = document.createElement("form");
        divElement.appendChild(formElement);
        const divInput = document.createElement("div");
        formElement.appendChild(divInput);
        formConfig.forEach(obj => { // Cicla sui campi configurati
            const labelElem = document.createElement("label");
            labelElem.setAttribute("for", obj.id);
            labelElem.textContent = obj.label;

            const inputElem = document.createElement("input");
            inputElem.id = obj.id;
            inputElem.setAttribute("name", obj.id);
            inputElem.setAttribute("type", obj.type);
            inputElem.setAttribute("placeholder", obj.placeholder);
            if (obj.required)
                inputElem.required = true;
            inputElem.setAttribute("pattern", obj.pattern);
            // inputElem.value = obj.value; // decommentare se non si vuole il form vuoto all'avvio, ma con dei valori di esempio nei campio
            divInput.appendChild(labelElem);
            divInput.appendChild(inputElem);
        });
        
        const divButton = document.createElement("div");
        formElement.appendChild(divButton);
        const submitButton = document.createElement("button");
        submitButton.setAttribute("type", "button");
        submitButton.textContent = "Submit";
        submitButton.addEventListener("click", (e) => {
            e.preventDefault();
            const inputElements = document.querySelectorAll(`.${String(MENU_CLASS)} form input`);
            if (!utility.checkValidity(inputElements)) // Controlla validità dei campi
                return;
            sendSignUp(); // Invia i dati del form
        });
        divButton.appendChild(submitButton);
    }

    // Gestisce la chiusura del menu quando si clicca fuori 
    function focusOut() {
        // console.log("focusOut");
        const menuElem = document.querySelector(`.${String(MENU_CLASS)}`);
        const containerElem = document.querySelector(`.${String(CONTAINER_CLASS)}`);
        menuElem.addEventListener("click", (event) => {
            event.stopPropagation(); // Evita propagazione del click
        });
        containerElem.addEventListener("click", () => {
            containerElem.classList.remove("focused"); // Nasconde il menu
            setTimeout(() => {
                containerElem.classList.remove("up"); // Rimuove stile z-index
            }, 1000);
        });
    }

    // Crea il div per l'opzione login
    function loginOption() {
        const loginDiv = document.createElement("div");
        const p = document.createElement("p");
        const pClickable = document.createElement("p");
        p.textContent = "You already have an account? ";
        pClickable.textContent = "LOG IN!";
        pClickable.id = "login-button";
        pClickable.classList.add("login");
        pClickable.addEventListener("click", (e) => {
            e.preventDefault();
            generateLoginForm()
        }); // Aggiunge il form di login
        loginDiv.append(p, pClickable);
        return loginDiv;
    }

    // Genera il form di login dinamicamente
    function generateLoginForm() {
        deleteMenu(); // Pulisce il menu
        const menuDiv = document.querySelector(`.${String(MENU_CLASS)}`);
        const formElement = document.createElement("form");
        menuDiv.appendChild(formElement);
        const divInput = document.createElement("div");
        formElement.appendChild(divInput);
        const formArray = [formConfig[2], formConfig[3]]; // Solo email e password

        formArray.forEach(obj => {
            const labelElem = document.createElement("label");
            labelElem.setAttribute("for", obj.id);
            labelElem.textContent = obj.label;

            const inputElem = document.createElement("input");
            inputElem.id = obj.id;
            inputElem.setAttribute("name", obj.id);
            inputElem.setAttribute("type", obj.type);
            inputElem.setAttribute("placeholder", obj.placeholder);
            if (obj.required)
                inputElem.required = true;
            inputElem.setAttribute("pattern", obj.pattern);
            // inputElem.value = obj.value;
            divInput.appendChild(labelElem);
            divInput.appendChild(inputElem);
        });

        const divButton = document.createElement("div");
        formElement.appendChild(divButton);
        const loginButton = document.createElement("button");
        loginButton.setAttribute("type", "button");
        loginButton.textContent = "Login";
        loginButton.addEventListener("click", (e) => {
            e.preventDefault();
            const inputElements = document.querySelectorAll(`.${String(MENU_CLASS)} form input`);
            if (!utility.checkValidity(inputElements)) // Controlla validità dei campi 
                return;
            sendLogin(); // Invia i dati di login
        });
        const signupButton = document.createElement("button");
        signupButton.setAttribute("type", "button");
        signupButton.textContent = "Sign up";
        signupButton.addEventListener("click", (e) => {
            e.preventDefault();
            generateForm(); // Torna al form di registrazione
            const menuDiv = document.querySelector(`.${String(MENU_CLASS)}`);
            const loginDiv = loginOption();
            menuDiv.appendChild(loginDiv);
        });
        divButton.append(loginButton, signupButton);
    }

    // Rimuove tutti i contenuti del menu
    function deleteMenu() {
        const signupElems = document.querySelectorAll(`.${String(MENU_CLASS)} > *`);
        signupElems.forEach(field => {
            field.remove(); // Elimina ogni elemento
        });
    }

    // Invia i dati del login
    function sendLogin() {
        const promise = submitHandler('login');  //console.log(promise);
        promise
            .then(result => {
                if (result === '') {
                    window.location.href = './../html/home.php';
                } else {
                    window.alert(result);
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    // Invia i dati della registrazione
    function sendSignUp() {
        const promise = submitHandler('signup');  
        promise
            .then(result => {
                if (result === '') {
                    window.location.href = './../html/home.php';
                } else {
                    window.alert(result);
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    // Funzione generica per inviare i dati del form
    async function submitHandler(type) {
        let res = ''; // Default response value
        let queryObject = {};
        const formElem = document.querySelector(`.${String(MENU_CLASS)} form`);
        const inputElements = formElem.querySelectorAll("input");

        // Loop over inputs to collect form data
        for (const input of inputElements) {
            let name = input.id;
            let value = input.value;
            queryObject[name] = value;
            input.value = ''; // Clear form inputs after submission
        }

        queryObject['type'] = type; // Specify the type of submit

        console.log(queryObject); // debug

        const queryString = utility.serialize(queryObject); // Convert the object to a query string
        console.log(queryString);

        try {
            let promise;
            if (type === 'signup') {
                promise = phpRequest.submitSignup(queryString);
            } else if (type === 'login') {
                promise = phpRequest.submitLogin(queryString);
            } else {
                throw new Error("Tipo di invio non supportato");
            }

            // Wait for the promise to resolve
            const response = await promise;
            // console.log("Response Object: ", response);
            
            const text = await response.text();
            if (text) {
                let json = utility.jsonParseText(text);
                if (json.status === 'error') {
                    throw new Error(json.message + ' >> ' + json.error);
                }
                sessionStorage.setItem("username", json.content.username); 
            } else {
                console.log("Niente da notificare");
            }
        } catch (error) {
            res = error;
        }

        // Return res after the async operation completes
        return res;
    }    
}

/**
 * @summary     Configura l'header della pagina in base allo stato di accesso.
 * @description 
 * Mostra un'intestazione personalizzata in base al valore di `logtype`. 
 * Se l'utente non è autenticato, mostra il pulsante di registrazione. 
 * Se è autenticato, mostra il link al profilo. 
 * Se l'accesso è limitato per via di un errore lato server, non mostra alcun header interattivo. 
 * Limitando l'utente alla sola navigazione della home e della pagina discover
 * @param {number} logtype Il tipo di stato dell'accesso:
 *      - `0`: Mostra il pulsante "Sign up".
 *      - `1` o `2`: Mostra il link al profilo utente.
 *      - `altro` : Nasconde le opzioni di accesso (niente header interattivo).
 */
export function setupHeader(logtype) {
    const style = new Style();
    switch (logtype) {
        case 0:
            updateHeader('Sign up', 'signup');
            break;
        case 1:
        case 2:
            updateHeader('profile', 'profile');        
            break;
        default: // impedisce l'accesso alla funzionalità di sign up e login.
            updateHeader('', '');  
            break;
    }
    const aNavElements = document.querySelectorAll("header.general-header nav a");
    style.highlightNavigation(aNavElements); // Richiama la funzione per gestire la navigazione con evidenziazione
}

/**
 * @summary     Aggiorna l'intestazione della pagina in cui sono presenti i link di navigazione
 * @description 
 * Inserisce un elemento `<header>` generato dinamicamente all'interno del `<body>`, 
 * posizionandolo prima del `<main>`. Se `type` è 'profile', aggiunge un evento di click 
 * per reindirizzare alla pagina del profilo. Se `type` è 'signup', gestisce l'accesso utente.
 * @param {string} name Il testo da visualizzare nell'elemento access.
 * @param {string} type Il tipo di intestazione da generare ('profile', 'signup' o stringa vuota).
 */
function updateHeader(name, type) {
    const body = document.querySelector('body');
    const main = body.querySelector('main');
    
    const headerElement = generateHTMLHeader(name, type); // qui viene gestita anche la creazione di un header con sezione accesso vuota caso type === ''
    body.insertBefore(headerElement, main);
    // in base al valore di type, popolo l'elemento '<p>'
    if (type === 'profile') {
        const p = headerElement.querySelector('#profile');
        p.addEventListener("click", () => {
            window.location.href = "./../html/profile.php";
        });
    } else if (type === 'signup') {
        const loginElement = headerElement.querySelector('p');
        accessHandler(loginElement);
    } // se type === '' non fare nulla
}

/**
 * @summary genera l'header in cui è presente il titolo del sito con link alla home, alla pagina discover, alla pagina di documentazione e il tasto per il sign up o per il profilo o nessuno dei due a seconda del parametro passato
 * @param {string} string   Il testo da visualizzare nell'elemento access se `id` è fornito.
 * @param {string} id       L'ID da assegnare all'elemento access; se vuoto, l'elemento non viene popolato.
 * @return {HTMLElement} L'elemento `<header>` generato con i suoi sotto-elementi.
 */
function generateHTMLHeader(string, id) {
    const header = document.createElement("header");
    header.className = "general-header";

    const siteName = document.createElement("a");
    siteName.id = "site-name";
    siteName.href = "home.php";
    siteName.textContent = "noisExpression";
    header.appendChild(siteName);

    const nav = document.createElement("nav");

    const discoverLink = document.createElement("a");
    discoverLink.href = "discover.php";
    discoverLink.textContent = "Discover";
    nav.appendChild(discoverLink);

    const docLink = document.createElement("a");
    docLink.href = "./../documentazione.html";
    docLink.textContent = "Documentation";
    nav.appendChild(docLink);

    header.appendChild(nav);
    
    const access = document.createElement("p");
    if (id !== '') { 
        access.id = utility.formatId(id);
        access.textContent = utility.capitalize(string);
    } // se non vi si passa nulla creo un elemento vuoto
    header.appendChild(access);

    return header;
}