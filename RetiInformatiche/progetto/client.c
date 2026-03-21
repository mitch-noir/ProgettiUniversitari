#include <stdio.h> /* Libreria standard per input/output */
#include <string.h> /* Libreria per la gestione delle stringhe */
#include <limits.h> /* Libreria per limiti numerici */

#include "libs/misc.h" /* Inclusione header personalizzato misc */
#include "libs/netlib.h" /* Inclusione header personalizzato netlib */

/**
 * Funzione di utilità per stampare una linea decorativa con '+'
 */
void print_plus_line() {
    printf("%s\n", PLUS_LINE); /* Stampa una linea definita in PLUS_LINE */
}

/**
 * @brief Mostra il menù iniziale al giocatore.
 *
 * Permette all'utente di scegliere se iniziare una nuova sessione di gioco oppure uscire.
 * Valida l’input dell’utente tramite conversione numerica sicura.
 *
 * @return 1 per avviare una sessione di gioco, 2 per uscire, -1 in caso di input non valido.
 */
int starting_menu() {
    int num_chosen = -1; /* Valore di default in caso di errore o scelta non valida */
    int tmp_num_chosen; /* Contiene la scelta fatta dal giocatore, prima che venga controllata */
    char choice[10]; /* Buffer per l'input dell'utente */
    char *endptr = NULL; /* Puntatore per validazione della conversione */

    /* Stampa del menù di avvio */
    printf("Trivia Quiz\n");
    printf("%s\n", PLUS_LINE); /* Stampa una linea definita in PLUS_LINE */
    printf("Menù\n");
    printf("1 - Comincia una sessione di Trivia\n");
    printf("2 - Esci\n");
    printf("%s\n", PLUS_LINE); 
    printf("La tua scelta: ");

    /* Inserimento scelta del giocatore */
    if (fgets(choice, sizeof(choice), stdin) == NULL) {
        fprintf(stderr, "Errore durante la lettura della risposta inserita dal giocatore.\n\n");
        return num_chosen; /* Ritorna -1 in caso di errore in fase di input */
    }

    choice[strlen(choice) - 1] = '\0'; /* Rimuove il carattere di newline */
    tmp_num_chosen = strtol(choice, &endptr, 10); /* Converte la scelta in numero */

    if (choice == endptr) {
        printf("Nessuna cifra trovata!\n");
    } else if (*endptr != '\0') {
        printf("Inseriti caratteri non validi!.\n");
    } else if (errno == ERANGE || tmp_num_chosen > INT_MAX || tmp_num_chosen < INT_MIN) {
        printf("Valore numerico fuori range.\n");
    } else {
        if (tmp_num_chosen == 1 || tmp_num_chosen == 2) {
            num_chosen = tmp_num_chosen;
        } else {
            printf("Scelta non valida!\n");
        }
    }
    printf("\n");
    return num_chosen;
}

/**
 * @brief Gestisce l'inserimento di un nickname da parte del giocatore.
 *
 * Richiede al giocatore l’inserimento di un nickname e lo invia al server.
 * In caso di rifiuto (nickname già usato), richiede un nuovo inserimento.
 *
 * @param sockfd Descrittore della socket del client.
 * @return Sempre NULL (il nickname validato viene gestito dal server).
 */
char* choose_a_nickname(int sockfd) {
    bool vaild_nick = false; /* Stato del nickname scelto */
    bool retry = false; /* Indica se bisogna riprovare l'inserimento */
    char* buf; /* buffer di appoggio per il messaggio iniziale della fase di scelta nick */

    buf = receve_msg(sockfd, PROCESS); /* Riceve messaggio di benvenuto dal server */
    printf("%s", buf); /* Stampa messaggio ricevuto */
    free_msg(buf); /* Libera la memoria del messaggio ricevuto */

    /* Itera finché il giocatore non ha scelto un nickname unico */
    while (!vaild_nick) {
        int dim_buffer; /* lunghezza nick scelto */
        char buffer[MAX_MSG_LEN] = {0}; /* Buffer per il nickname */
        char sv_rply; /* server reply */

        if (retry)
            printf("Scegli un altro nickname: ");

        /* Inserimento scelta */
        if (fgets(buffer, MAX_MSG_LEN, stdin) == NULL) {
            fprintf(stderr, "Errore durante l'inserimento del nickname.\n\n");
            retry = true;
            continue;
        }
        buffer[strlen(buffer) - 1] = '\0'; /* Rimuove newline */
        dim_buffer = strlen(buffer); /* Lunghezza nickname */

        /* Invio nickname al server */
        send_msg(sockfd, buffer, dim_buffer, PROCESS);

        /* Ricezione esito dal server */
        sv_rply = receve_status(sockfd, PROCESS);
        if (sv_rply == (char)ACK) { /* Nickname valido */
            vaild_nick = true;
            retry = false;
        } else {
            vaild_nick = false;
            retry = true;
        }
    }
    return NULL;
}

/**
 * @brief Permette al giocatore di selezionare un quiz disponibile tra quelli inviati dal server.
 *
 * Riceve l'elenco dei temi disponibili dal server e consente all’utente di scegliere uno tra questi.
 * In caso di input non valido o errore, ripete la richiesta.
 *
 * @param sockfd Descrittore della socket del client.
 * @return L’ID del quiz scelto, o -1 se non sono disponibili quiz.
 */
int choose_a_theme(int sockfd) {
    int theme_id; /* id del tema scelto */
    uint32_t num_quiz; /* num quiz disponibili che il giocatore può scegliere */
    bool retry; /* vero in caso di scelta errata */
    char* buf; /* buffer di appoggio per la stampa del testo iniziale */

    printf("\n");
    /* printf("Attesa lista dei temi... \n"); */
    buf = receve_msg(sockfd, PROCESS); /* Ricezione lista dei temi disponibili */
    printf("%s", buf);
    free(buf);

    num_quiz = receve_num(sockfd, PROCESS); /* Ricezione numero quiz disponibili */

    if (num_quiz == 0) {
        return -1; /* Nessun quiz disponibile */
    }

    theme_id = -1;
    retry = false;

    /* Itera finchè il giocatore non ha fatto una scelta valida sia per il server che per il client*/
    while (1) {
        long choice = 0; /* scelta temporanea del giocatore */
        char* endptr = NULL; /* punta ad una zona di mem che contiene caratteri non convertibili in cifre decimali*/
        char buffer[MAX_MSG_LEN] = {0}; /* buffer di input */

        if (retry) {
            printf("Riprova: ");
        }

        /* Inserimento scelta */
        if (fgets(buffer, MAX_MSG_LEN, stdin) == NULL) {
            perror("errore durante l'inserimento della risposta ");
            retry = true;
            continue;
        }
        buffer[strlen(buffer) - 1] = '\0'; /* Rimuove newline */
        choice = strtol(buffer, &endptr, 10);

        if (buffer == endptr) {
            printf("Nessuna cifra inserita.\n");
        } else if (*endptr != '\0') {
            printf("Inseriti caratteri non validi.\n");
        } else if (errno == ERANGE || choice < 1) {
            printf("Valore numerico fuori range.\n");
        } else {
            char status; /* risposta del server */
            send_num(sockfd, choice, PROCESS); /* Invio scelta al server */
            status = receve_status(sockfd, PROCESS); /* Ricezione conferma */
            if (status == ACK) { /* il server ha accettato l'id scelto, posso terminare la fase di scelta quiz */
                theme_id = choice;
                break;
            }
        }
        retry = true;
    }
    return theme_id;
}

/**
 * @brief Riceve e visualizza il report dei punteggi dal server.
 *
 * Il report può essere suddiviso in più parti, ognuna terminata con un ACK/NAK.
 * Le parti vengono concatenate e stampate su console.
 *
 * @param sockfd Descrittore della socket del client.
 * @return 0 in caso di successo, -1 in caso di errore (es. allocazione fallita).
 */
int showscore(int sockfd) {
    uint32_t msg_dim, bytes_recvd; /*msg_dim: dimensione del messaggio totale; bytes_recvd: bytes effettivamente ricevuti*/
    char *recv_buf; /* buffer di ricezione che conterrà il report delle classifiche */

    msg_dim = receve_num(sockfd, PROCESS); /* Riceve dimensione del messaggio */

    recv_buf = malloc(msg_dim); /* Alloca buffer per il messaggio */
    if (recv_buf == NULL) return -1;

    /** 
     * Riceve le classifiche dal server, in uno o più chunk in base alla dimensione 
     * totale del messaggio che contiene le classifiche
     **/
    bytes_recvd = 0;
    while (1) {
        char sts;
        char *chunk; /* Buffer intermedio */

        chunk = receve_msg(sockfd, PROCESS);

        strcpy(recv_buf + bytes_recvd, chunk); /* Ricompongo parte del messaggio finale */

        bytes_recvd += strlen(chunk);
        free_msg(chunk); /* Libero la memoria usata dal chunk*/

        sts = receve_status(sockfd, PROCESS);
        if (sts == NAK) {
            break; /* Fine dei chunk */
        }
    }

    printf("%s", recv_buf);
    return 0;
}

/**
 * @brief Gestisce la fase di gioco principale (domande e risposte).
 *
 * Riceve le domande dal server, acquisisce la risposta dell’utente e la invia.
 * Gestisce comandi speciali come `endquiz` e `show score`.
 *
 * @param sockfd Descrittore della socket del client.
 * @return 0 se il quiz è terminato normalmente, 1 se è stato interrotto volontariamente (endquiz), -1 in caso di errore.
 */
int game(int sockfd) {
    int game_status; /* usato come valore di ritorno */
    char* starting_text; /* buffer di appoggio per la stampa del testo iniziale */

    starting_text = receve_msg(sockfd, PROCESS); /* Riceve testo iniziale */
    printf("%s", starting_text);
    free_msg(starting_text);

    while (true) {
        char* server_question; /* buffer di appoggio per la domanda attuale inviata dal server */
        char answer[MAX_MSG_LEN] = {0}; /* buffer di input, che conterrà la risposta immessa dal giocatore */

        printf("\n");
        server_question = receve_msg(sockfd, PROCESS); /* Riceve domanda */
        printf("%s?\n", server_question); /* La mostra al giocatore */
        do {
            if (fgets(answer, sizeof(answer), stdin) == NULL) {
                fprintf(stderr, "Errore durante la lettura della risposta inserita del giocatore.\n\n");
                return -1;
            }
            answer[strlen(answer) - 1] = '\0'; /* Rimuove newline */
        } while (strlen(answer) == 0);

        send_msg(sockfd, answer, strlen(answer), PROCESS); /* Invia risposta */

        if (strcmp(answer, "endquiz") == 0) {
            game_status = 1; /* Termina quiz */
            break;
        } else if (strcmp(answer, "show score") == 0) {
            if (showscore(sockfd) != 0) {
                game_status = -1; /* Errore durante showscore */
                break;
            }
        } else {
            char* reply = receve_msg(sockfd, PROCESS); /* Riceve feedback */
            char sts = receve_status(sockfd, PROCESS); /* Riceve lo stato dal server */
            printf("%s\n", reply);
            free_msg(reply);
            if (sts == EOT) {
                printf("Quiz terminato.\n");
                game_status = 0;
                break;
            }
        }
    }
    return game_status;
}

/**
 * @brief Funzione principale del client Trivia Quiz.
 *
 * Valida la porta passata come argomento, stabilisce la connessione con il server e gestisce
 * l’intero ciclo di gioco, che include:
 * - Visualizzazione menù iniziale
 * - Scelta del nickname
 * - Scelta del quiz
 * - Risposta alle domande del quiz
 *
 * @param argc Numero di argomenti (atteso: 2).
 * @param argv Vettore di argomenti, dove argv[1] è la porta.
 * @return 0 in caso di terminazione corretta, altrimenti termina il programma con `exit(EXIT_FAILURE)`.
 */
int main(int argc, char* argv[]) {
    struct sockaddr_in sv_addr; 
    int sfd, port, ret, player_choice;
    char *str_port; /* stringa che conterrà il numero di porta inserito come argomento dopo la ./client */
    bool restart; /* permette di riavviare la fase di gioco dall'inizio */

    if (argc != 2) {
        printf("Programma avviato con un numero di parametri non appropriato.\n");
        exit(EXIT_FAILURE);
    }

    port = strtol(argv[1], &str_port, 10); /* Converte la porta in intero */

    if (strlen(str_port) > 0) {
        printf("Il numero di porta inserito contiene caratteri non convertibili in numero.\n");
        exit(EXIT_FAILURE);
    }
    if (port == 0) {
        printf("Il numero di porta non può essere nullo.\n");
        exit(EXIT_FAILURE);
    }
    if (port > (uint16_t)-1) {
        printf("Il numero di porta inserito non è rappresentabile su 16 bit\n");
        exit(EXIT_FAILURE);
    }

    printf("Creazione socket..\n");
    restart = true;

    /* Ciclo che percorre tutte le fasi di gioco */
    while (true) {
        int game_status;
        /** 
         * Se il giocatore ha scelto di uscire dal quiz tramite il comando endquiz 
         * devo dargli la possibilità di poter cominciare da capo la sessione di gioco,
         * dato che la endquiz provoca nel server l'eliminazione del giocatore e
         * la chiusura della connessione, il client deve poter avviare una nuova connessione
         * chiudendo la precedente 
         **/
        if (restart) { 
            sfd = socket(AF_INET, SOCK_STREAM, 0);
            if (sfd == -1) {
                perror("Errore durante la creazione del socket");
                exit(EXIT_FAILURE);
            }

            player_choice = starting_menu();
            if (player_choice != 1) {
                close(sfd);
                exit(0);
            }

            memset(&sv_addr, 0, sizeof(struct sockaddr_in));
            sv_addr.sin_family = AF_INET;
            sv_addr.sin_port = htons(port);
            (void)inet_pton(AF_INET, SV_ADDRESS, &sv_addr.sin_addr);

            ret = connect(sfd, (struct sockaddr*)&sv_addr, sizeof(struct sockaddr_in));
            if (ret == -1) {
                perror("Connect fallita");
                close(sfd);
                exit(EXIT_FAILURE);
            }
            
            /* Fase di scelta del nickname */
            (void)choose_a_nickname(sfd); 
        }

        printf("\n");
        if (choose_a_theme(sfd) == -1) { /* Fase di scelta del tema */
            break; /* Il gioco termina se non ci sono più quiz disponibili */
        }

        printf("\n");
        game_status = game(sfd); /* Fase di gioco vera e propria */

        if (game_status == 0) {
            restart = false;
        } else if (game_status == -1) {
            printf("Errore durante il gioco.\n");
            close(sfd);
            exit(EXIT_FAILURE);
        } else { /* Il client ha digitato il comando endquiz, chiudo la socket */
            printf("\n");
            restart = true;
            close(sfd);
        }
    }

    close(sfd);
    return 0;
}
