
import {Utility, PHPRequestHandler, setupHeader} from './utility-general.js';

const utility = new Utility();
const phpRequest = new PHPRequestHandler();
let cardsInfo = [];
let intervalId;
document.addEventListener("DOMContentLoaded", init);

/**
 * @summary Funzione principale di inizializzazione
 * @description Questa funzione viene eseguita quando il DOM è completamente caricato. 
 * Controlla lo stato di autenticazione dell'utente e recupera la lista delle immagini 
 * dal server per la visualizzazione dinamica.
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
    
    // implementa l'effetto del cambio di copertina
    coverEffect();
}

/**
 * @summary Funzione che implementa l'effetto di cambio dinamico della copertina.
 * @description Recupera una lista di immagini dal server e le visualizza a intervalli regolari 
 * come immagini di copertina. Ogni 6 secondi viene selezionata un'immagine casuale.
 * @async
 * @returns {Promise<void>} Non restituisce alcun valore, ma aggiorna dinamicamente il contenuto della pagina, oltre ad aggiornare il contenuto della variabile globale cardsInfo.
*/
async function coverEffect() {
    const main = document.body.querySelector('main');
    try { 
        // Recupera la lista dei file dal server
        const response = await phpRequest.getFileList('All'); // caso generale
        const text = await response.text();
        if (text) {
            const json = utility.jsonParseText(text);
            if (json.status === 'error') {
                throw new Error(json.message + '>>' + json.error);
            } else {
                // Salva la lista delle immagini
                cardsInfo = json.content; 
                
                if (!cardsInfo || cardsInfo.length === 0) {
                    console.log('Non ci sono immagini di cui fare il display');
                    return;
                }

                cardsInfo.forEach(element => {
                    element.imgPath = utility.transformImagesPath(element.imgPath);
                });
                console.log(cardsInfo);

                // Mostra una prima immagine casuale
                let rnd = Math.random() * (cardsInfo.length);
                let idx = Math.floor(rnd);
                displayCover(main, cardsInfo[idx]);

                if (intervalId) {
                    clearInterval(intervalId);
                }
                // Cambia l'immagine di copertina ogni 6 secondi
                intervalId = setInterval(() => {
                    let index = Math.floor(Math.random() * (cardsInfo.length));
                    let card = cardsInfo[index];
                    displayCover(main, card);
                }, 6000);
            }
        }
    } catch (error) {
        console.log(error);
    }
}

/**
 * @summary Mostra una copertina con un'immagine selezionata
 * @description Questa funzione aggiorna dinamicamente la copertina dell'elemento principale con un'immagine presa da un set di immagini disponibili.
 * @param {HTMLElement} parentElem - L'elemento HTML in cui viene inserita la copertina.
 * @param {Object} card - Oggetto contenente i dettagli dell'immagine.
    * @param {string} card.imgPath - Percorso dell'immagine.
    * @param {string} card.title - Titolo dell'immagine (usato come attributo `alt`).
 */
function displayCover(parentElem, card) {
    let coverContainer = parentElem.querySelector('#cover');
    let imgElem;
    let firstCall = false;
    if (coverContainer) {
        imgElem = coverContainer.querySelector('img');
    } else {
        firstCall = true;
        coverContainer = document.createElement('div');
        coverContainer.id = 'cover';
        imgElem = document.createElement('img');
        coverContainer.appendChild(imgElem);
        parentElem.appendChild(coverContainer);
    }

    // Precaricamento dell'immagine
    const newImg = new Image();
    newImg.src = card.imgPath;
    newImg.alt = card.title;
    
    newImg.onload = () => {
        let transitionDone = false;
        if (firstCall) {
            imgElem.classList.add('fade-in');
            imgElem.src = newImg.src; // aggiorna il path dell'immagine
            imgElem.alt = newImg.alt;
        } else {
            imgElem.classList.remove('fade-in');
            imgElem.classList.add('fade-out');
        }
        imgElem.addEventListener('transitionend', () => {
            if (transitionDone) 
                    return;
            transitionDone = true;
            imgElem.src = newImg.src; // aggiorna il path dell'immagine
            imgElem.alt = newImg.alt;
            // Aggiunge un offset per eliminare il lag di caricamento nelle immagini ad alta definizione
            setTimeout(() => {
                imgElem.classList.add('fade-in');
                imgElem.classList.remove('fade-out');
            }, 100); // più grande è più tempo si da all'immagine di essere aggiornata
        }, {once: true});
        
        // codice utile nel caso in cui ci siano errori nell'animazione
        setTimeout(() => {
            if (!transitionDone && imgElem.src !== newImg.src) {
                transitionDone = true;
                imgElem.src = newImg.src;
                imgElem.alt = newImg.alt;
                imgElem.classList.add('fade-in');
                imgElem.classList.remove('fade-out');
            }
        }, 1000);
    }
}


