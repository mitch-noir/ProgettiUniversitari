
/**
 * @class Style
 * @classdesc classe che racchiude un insieme di utilità spesso utilizzate per lo styling del sito
 */
export class Style {
    /**
     * Evidenzia un elemento di navigazione quando il mouse passa sopra di esso e sfoca gli altri elementi.
     * @param {NodeList} list - Un elenco di elementi.
     * 
     * @example
     * const style = new Style();
     * const navLinks = document.querySelectorAll("nav a");
     * style.highlightNavigation(navLinks);
     */
    highlightNavigation(list) {
        // Aggiunge eventi di mouseover e mouseout a ciascun elemento pressente nella list
        list.forEach(element => {
            /**
             * Evento per aggiungere una classe agli elementi non attivi quando il mouse è sopra un elemento.
             */
            element.addEventListener("mouseover", () => {
                // Itera su tutti gli elementi della lista
                for (const elem of list) {
                    if (element !== elem) { // Se l'elemento non è quello attualmente attivo
                        elem.classList.add("not-hover-class"); // Aggiunge la classe per sfocare l'elemento
                    }
                }
            });

            /**
             * Evento per rimuovere la classe "not-hover-class" quando il mouse lascia l'elemento.
             */
            element.addEventListener("mouseout", () => {
                // Seleziona tutti gli elementi che hanno la classe "not-hover-class"
                const notHoverElements = document.querySelectorAll(".not-hover-class");
                
                // Rimuove la classe "not-hover-class" da ciascun elemento se presenti
                if (notHoverElements.length > 0) {
                    notHoverElements.forEach(elem => {
                        elem.classList.remove("not-hover-class");
                    });
                }
            });
        });
    }
}





  