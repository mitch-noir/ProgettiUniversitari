import {Style} from './style-general.js'
import {Utility, PHPRequestHandler, setupHeader} from './utility-general.js';

const style = new Style();
const utility = new Utility();
const phpRequest = new PHPRequestHandler();
/**
 * @summary Array contenente informazioni sulle opere.
 * @description Ogni elemento dell'array è un oggetto con le seguenti campi:
 * - `title` {string} - Titolo dell'opera.
 * - `releaseDate` {string} - Data di rilascio.
 * - `serie` {string} - Titolo della serie.
 * - `artist` {string} - Nome dell'artista.
 * - `price` {number} - Prezzo dell'opera.
 * - `genre` {string} - Genere artistico.
 * - `imgPath` {string} - Percorso dell'immagine.
 */
let cardsInfo = [];
let cardsOfSerie = []; // contiene la lista di cards per la serie selezionata
let serieFirstCard = []; // contiene solo parima card di ogni serie, ad eccezione dei 'Singoli'
let filterByTitleIsActive = false;
let descriptions = []; 
document.addEventListener("DOMContentLoaded", init);

/**
 * @summary Funzione di inizializzazione.
 * @description Controlla lo stato di accesso dell'utente, recupera i dati dal server e inizializza i filtri e le carte.
 * @async
 * @returns {Promise<void>}
 */
async function init() {
    let caso;
    utility.preventImageDownload(); // Impedisce il download delle immagini tramite tasto destro
    // Verifica la sincronizzazione tra client e server dell'utente loggato
    if (sessionStorage.getItem('username') === null) {
        try {
            let response = await phpRequest.getSessionUser();
            let text = await response.text();
            if (text) {
                let json = utility.jsonParseText(text);
                if (json.status === 'error') { 
                    console.log('Utente non loggato');
                    caso = 0;
                } else {
                    console.log('Utente loggato sul lato server ma non client');
                    sessionStorage.setItem('username', json.content.username);
                    caso = 1;
                }
            }
        } catch (error) {
            caso = 3; // errore lato server, impedire l'accesso alla funzionalità di sign up e login.
            console.log(error); 
        }
    } else {
        console.log('Utente loggato');
        caso = 2;
    }
    // Imposta l'header in base allo stato di accesso
    setupHeader(caso);
    
    // recupera dal server la lista di immagini (opere) di genere 'Generative' ed aggiorna le carte    
    retreveImagesAndUpdateCards('Generative');

    setupFilterDiv();
    
    // carica le descrizioni dal database
    let descriptionPromise = getDescriptions();
    console.log(descriptionPromise);
    descriptionPromise
    .then(array => { // quando realizzata scrive aggiorna l'array
        descriptions = array;
        updateHead('Generative');
        updateDescription(descriptions, 'Generative');
    })
    .catch(error => {
        console.log(error);
    });
}

/**
 * @summary Recupera la lista di file relativi al genere selezionato e aggiorna le carte.
 * @description 
 * Questa funzione invia una richiesta per ottenere la lista di immagini associate 
 * al genere artistico selezionato. Successivamente, aggiorna le informazioni sulle carte, 
 * le rigenera e le visualizza, ed infine aggiorna l'intestazione.
 * Tutto ciò avviene solo se il recupero delle immagini è andato a buon fine.
 * 
 * @param {string} genre Il genere artistico selezionato per il quale si desidera ottenere la lista di file.
 * 
 * @async La funzione utilizza chiamate asincrone per ottenere i dati dal server e aggiornare la UI.
 */
function retreveImagesAndUpdateCards(genre) {
    phpRequest.getFileList(genre)
    .then(response => {
        return response.text();
    }).then(text => {
        if (text) {
            const json = utility.jsonParseText(text);
            if (json.status === 'error') {
                throw new Error(json.message + ' >> ' + json.error);
            } else {
                // aggiorno le carte
                updateCardsInfo(json.content);
                generateCards(serieFirstCard); // le genero facendone poi il display
            }
        }
    }).catch(error => {
        console.log(error);
    });
}

/**
 * @summary Configura la barra di ricerca e il filtro per genere.
 */
function setupFilterDiv() {
    // setup filter
    const filterInput = document.querySelector('.search input');
    filterInput.addEventListener('keyup', (e) => {
        const target = e.target;
        const value = target.value;
        if (value !== '') {
            const filteredCards = filterCardsByTitle(value);
            console.log(filteredCards);
            generateCards(filteredCards);
            console.log('search: ' + value);
            filterByTitleIsActive = true;
        } else {
            generateCards(serieFirstCard);
            filterByTitleIsActive = false;
        }
    });

    setupGenreFilter();
}

/**
 * @summary Genera le carte e le aggiunge al DOM.
 * @param {Array} cardsData - Lista delle carte da generare.
 */
function generateCards(cardsData) {
    // reset del contenitore di carte se già presente
    if (document.querySelector('.card-container')) {
        document.querySelector('.card-container').remove();
    }
    // crea il contenitore in cui verranno aggiunte le carte
    const container = document.createElement('div');
    container.className = 'card-container';
    const main = document.querySelector('main');

    // per ogni carta ne genera il contenuto HTML
    cardsData.forEach(card => {
        // crea la carta
        const cardDiv = document.createElement('div');
        cardDiv.className = 'card';

        // crea la div che conterrà l'immagine e img element
        const imgBox = document.createElement('div');
        imgBox.className = 'img-box';
        const img = document.createElement('img');
        img.src = card.imgPath;
        img.alt = '';
        imgBox.appendChild(img);

        // Crea la div che conterrà le info della carta
        const cardDescription = document.createElement('div');
        cardDescription.className = 'card-desciption';

        // titolo della carta (opera)
        const title = document.createElement('p');
        title.className = 'card-title';
        title.textContent = card.title;
        cardDescription.appendChild(title);

        // Artista
        const artist = document.createElement('p');
        artist.className = 'artist';
        artist.textContent = card.artist;
        cardDescription.appendChild(artist);

        // Data pubblicazione
        const releaseDate = document.createElement('p');
        releaseDate.className = 'card-release-date';
        releaseDate.textContent = card.releaseDate;
        cardDescription.appendChild(releaseDate);

        // Typo di carta (singolo o serie)
        const type = document.createElement('p');
        type.className = 'card-tipe';
        let cardType;
        
        if (card.serie === 'Singoli') {
            cardType = 'One of One';
            cardDiv.classList.add('single');
        } else {
            cardType = card.serie;
            cardDiv.classList.add('serie');
        }
        type.textContent = cardType;
        cardDescription.appendChild(type);
        // implementa il display popup dopo il click della carta
        cardDiv.addEventListener("click", (e) => {
            e.preventDefault();
            // prepara l'array di opere di cui fare il display nella finestra di popup
            if (cardType !== 'One of One') {
                cardsOfSerie = cardsInfo.filter(obj => obj.serie === card.serie); // filtra le sole carte che appartengono alla serie in questione
            } else {
                cardsOfSerie = [];
                cardsOfSerie.push(card);
            }
            // cambia il display delle carte, se un filtro per testo è attivo visualizza tutte le immagini come se fossero dei singoli disattivanto la visualizzazione per serie
            if (!filterByTitleIsActive) {
                displayPopup(cardsOfSerie); // display delle opere della serie selezionata
            } else {
                let cards = [];
                cards.push(card);
                displayPopup(cards); // display singola opera
            }
        });
        // Append del immagine e descrizione alla carta
        cardDiv.appendChild(imgBox);
        cardDiv.appendChild(cardDescription);

        // Append della carta al contenitore di carte
        container.appendChild(cardDiv);
    });

    // append del contenitore di carte al main
    main.appendChild(container);
    utility.preventImageDownload(); // previene il download delle immagini
}

/**
 * @summary Mostra un popup con l'immagine della carta selezionata.
 * @description 
 * Questa funzione crea e visualizza un popup contenente l'immagine della carta selezionata.
 * Se la carta selezionata presenta più immagini, visualizza il titolo delle singole immagini
 * e permette la navigazione tra di esse utilizzando frecce di navigazione. 
 * Impedisce inoltre il download dell'immagine tramite il menu contestuale.
 * 
 * @param {Array} cardList Lista di oggetti rappresentanti le carte, con proprietà `imgPath` e `title`.

 */
function displayPopup(cardList) {
    if (document.querySelector('div.popup')) {
        document.querySelector('div.popup').remove();
    }

    const display = document.createElement('div');
    display.classList.add("popup");
    const imgContainer = document.createElement('div');
    imgContainer.classList.add('img-container');
    const exitElem = document.createElement('div');
    exitElem.id = 'exit';
    const exitSpan = document.createElement('span');
    exitSpan.textContent = 'x';
    exitElem.appendChild(exitSpan);
    const spanContainer = document.createElement('div');
    spanContainer.id = 'control';

    const spanImgTitle = document.createElement('span');
    const img = document.createElement('img');
    img.src = cardList[0].imgPath;
    img.alt = cardList[0].title;
    spanImgTitle.textContent = cardList[0].title;
    spanImgTitle.id = 'imgTitle';
    imgContainer.append(img);
    display.append(imgContainer, spanContainer, exitElem);


    // impedisce di fare il download delle immagini
    img.addEventListener('contextmenu', (event) => {
        event.preventDefault(); // Disabilita il menu contestuale per ogni immagine
    });
    
    if (cardList.length > 1 && !filterByTitleIsActive) {
        // Contenitori per le frecce
        const leftArrowContainer = document.createElement('div');
        const rightArrowContainer = document.createElement('div');
        leftArrowContainer.classList.add('arrow-container');
        rightArrowContainer.classList.add('arrow-container');
        
        // Frecce vere e proprie
        const rightArrow = document.createElement('span');
        const leftArrow = document.createElement('span');
        leftArrow.textContent = '<';
        rightArrow.textContent = '>';
        
        let i = 0;
        
        // Aggiungi le classi per lo stile
        rightArrow.classList.add('arrow');
        rightArrow.classList.add('right');
        leftArrow.classList.add('arrow');
        leftArrow.classList.add('left');
        
        // Aggiungi le frecce ai loro contenitori
        rightArrowContainer.appendChild(rightArrow);
        
        // Navigazione verso destra
        rightArrow.addEventListener('click', () => {
            if (i < cardList.length - 1) {
                i++;
                img.src = cardList[i].imgPath;
                img.alt = cardList[i].title;
                spanImgTitle.textContent = cardList[i].title;
                
                // Aggiungi il leftArrow se non esiste
                if (!leftArrowContainer.contains(leftArrow)) {
                    leftArrowContainer.appendChild(leftArrow);
                }
                // Rimuovi il rightArrow se siamo all'ultima immagine
                if (i === cardList.length - 1) {
                    rightArrowContainer.removeChild(rightArrow);
                }
            }
        });
        
        // Navigazione verso sinistra
        leftArrow.addEventListener('click', () => {
            if (i > 0) {
                i--;
                img.src = cardList[i].imgPath;
                img.alt = cardList[i].title;
                spanImgTitle.textContent = cardList[i].title;
                
                // Aggiungi il rightArrow se non esiste
                if (!rightArrowContainer.contains(rightArrow)) {
                    rightArrowContainer.appendChild(rightArrow);
                }
                // Rimuovi il leftArrow se siamo alla prima immagine
                if (i === 0) {
                    leftArrowContainer.removeChild(leftArrow);
                }
            }
        });
        
        // titolo e frecce di navigazione
        spanContainer.append(leftArrowContainer, spanImgTitle, rightArrowContainer);
    } 
    // setup evento per chiudere il popup
    exitElem.addEventListener('click', () => {
        if (document.querySelector('div.popup')) {
            document.querySelector('div.popup').remove();
        }
        cardsOfSerie = []; // ripulisco l'array di carte della serie selezionata (dato che ora non ci sono più serie selezionate)
    });
    
    document.body.append(display);
}

/**
 * @summary Imposta il filtro per i generi artistici.
 * @description
 * Questa funzione recupera i generi artistici disponibili dal database e 
 * li visualizza come opzioni cliccabili nella UI. Quando un genere viene selezionato, 
 * la funzione aggiorna la lista di opere (carte) mostrate in base al genere scelto, 
 * oltre al titolo e la descrizione.
 * @async La funzione utilizza chiamate asincrone per recuperare i dati dal server.
 */
function setupGenreFilter() {
    const genreDiv = document.querySelector('.filter div.genre');
    // richiede i generi artistici presenti nel DB
    phpRequest.getGenres()
    .then((result) => {
        return result.text(); // restituisce il risultato convetito in testo
    })
    .then((text) => {
        if (text) {
            let json = utility.jsonParseText(text);
            if (json.status === 'error') {
                throw new Error(json.message + ' >> ' + json.error);
            }
            json.content.forEach(genre => {
                const p = document.createElement('p');
                p.textContent = genre;
                p.id = genre.toLowerCase();
                p.addEventListener('click', () => {
                    const selected = document.querySelector('.genre p.selected');
                    // Se il genere selezionato è lo stesso, non fare nulla
                    if (selected !== null) {
                        if (selected.id === genre.toLowerCase()) {
                            // Se il genere selezionato è lo stesso, non fare nulla
                            return;
                        } else {
                            selected.classList.remove('selected'); // deseleziono l'elemento
                        }
                    }
                    // Richiede la lista di file relativi al genere selezionato e aggiorna le carte
                    retreveImagesAndUpdateCards(genre);
                    // ed aggiorna il titolo e la descrizione
                    updateHead(genre);
                    updateDescription(descriptions, genre); 
                    p.classList.add('selected');
                });
                genreDiv.appendChild(p);
            });
            const plist = genreDiv.querySelectorAll('p');
            style.highlightNavigation(plist); // permette di creare 
        }
    })
    .catch((error) => {
        console.log(error);
    });
}

/**
 * @summary Aggiorna le informazioni delle variabili globali che rappresentano le carte.
 * @description 
 * Questa funzione aggiorna le variabili globali `cardsInfo` e `serieFirstCard` 
 * con i nuovi dati ricevuti. Per ogni nuova carta aggiorna i percorsi
 * delle immagini e identifica la prima carta di ogni serie aggiungendola 
 * a `serieFirstCard`.
 * 
 * @param {Array} infoArray Array di oggetti contenenti informazioni sulle carte.
 */
function updateCardsInfo(infoArray) {
    cardsInfo = []; // pulisce l'array
    cardsInfo = infoArray; // ricopia nuove informazioni sulle opere relative al genere selezionate
    cardsInfo.forEach(element => {
        element.imgPath = utility.transformImagesPath(element.imgPath);
    });
    let pastSerie = '';
    serieFirstCard = [];
    for (const card of cardsInfo) {
        if (card.serie === 'Singoli' || (card.serie !== 'Singoli' && pastSerie !== card.serie)) {
            serieFirstCard.push(card);
            pastSerie = card.serie;
        }
    }
}

/**
 * @summary Filtra le carte per titolo.
 * @param {string} searchTerm  Il termine di ricerca.
 * @returns {Array} Restutuisce le carte filtrate.
 */
function filterCardsByTitle(searchTerm) {
    return cardsInfo.filter(obj => obj.title.includes(searchTerm));
}

/**
 * @summary Aggiorna il titolo della pagina.
 * @param {string} genre - Il genere artistico selezionato.
 */
function updateHead(genre) {
    const titleElem = document.querySelector('#title-genre');
    titleElem.textContent = genre;
}

/**
 * @summary Recupera le descrizioni dei generi dal server.
 * @async
 * @returns {Promise<Array>} Restituisce un array di descrizioni.
 */
async function getDescriptions() {
    let array = [];
    try {
        let response = await phpRequest.getDescriptions();
        let text = await response.text();

        if (text) {
            let json = utility.jsonParseText(text);
            if (json.status === 'error') {
                throw new Error(json.message + ' >> ' + json.error);
            } else {
                console.log(json.content);
                array = json.content;
            }
        }
    } catch (error) {
        console.log(error);
    }
    return array;
}

/**
 * @summary Aggiorna la descrizione in base al genere selezionato.
 * @param {Array} array - L'array delle descrizioni.
 * @param {string} choice - Il genere selezionato.
 */
function updateDescription(array, choice) {
    let obj = array.filter(obj => obj.name === choice);
    obj = obj[0];
    const desContainer = document.querySelector('p.description');
    desContainer.textContent = obj.description;
}