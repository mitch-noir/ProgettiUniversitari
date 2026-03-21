#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "libs/misc.h"
#include "libs/netlib.h"
#include "libs/game.h"

struct net_thread nthreads[MAX_NUM_CLIENTS];

/**
 * @brief Gestisce la fase di scelta del nickname da parte del client.
 *
 * La funzione si occupa di:
 * - Inviare un messaggio iniziale per richiedere un nickname
 * - Ricevere il nickname dal client
 * - Verificare che il nickname sia univoco
 * - Salvare il nickname nella lista dei giocatori
 * - Inviare l'esito al client (ACK se successo, NAK altrimenti)
 *
 * In caso di insuccesso (nickname duplicato o errore di comunicazione),
 * la funzione ripete la procedura finché non ottiene un nickname valido,
 * oppure termina restituendo `NULL`.
 *
 * @param sockfd Socket del client connesso.
 * @param nt Puntatore alla struttura del thread di rete associato al client.
 *
 * @return Puntatore al nickname scelto se valido, oppure NULL in caso di errore.
 *         Il nickname restituito deve essere liberato dal chiamante con `free_msg()`.
 */
char* nickname_choosing_phase(int sockfd, struct net_thread* nt) {
	char buffer[MAX_MSG_LEN] = {0}; /* Buffer di appoggio */
	int blen; /*Numero di caratteri effettivamente scritti*/

	/* preparazione testo iniziale */
	blen = sprintf(buffer, "%s\n", "Trivia Quiz");
	blen += sprintf(buffer + blen, "%s\n", PLUS_LINE);
	blen += sprintf(buffer + blen, "%s", "Scegli un nickname (deve essere univoco): ");
	
	/* invio al client il testo di richiesta nick */
	send_msg(sockfd, buffer, blen, nt);
	while(true) {
        bool unique; /*Conterrà il risultato del controllo di unicità del nickname*/
        char *nick; /* Puntatore al nickname */
		/* attesa nick dal client */
        nick = receve_msg(sockfd, nt);
        if (nick == NULL) {
            send_nak(sockfd, nt); /* Notifico al client che qualcosa è andato storto */
            return NULL;
        }
		
        pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
        unique = check_nick_unqueness(players, MAX_NUM_CLIENTS, nick);
        pthread_mutex_unlock(&players_mux); 
        
		if (unique) {
			/* salva il nick in memoria */
            pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
			if(save_player(players, MAX_NUM_CLIENTS, nick, *(int*)nt->arg) == -1) {
                free_msg(nick); /* dealloco la memoria assegnata a nick durante la receve_msg */
                pthread_mutex_unlock(&players_mux); 
				send_nak(sockfd, nt);
				return NULL;
			}	
            pthread_mutex_unlock(&players_mux); 

            send_ack(sockfd, nt);
			return nick; /* esce dal ciclo while terminando così la fase di scelta del nickname */
        } else {
			send_nak(sockfd, nt);
            free_msg(nick); /* dealloco la memoria assegnata a nick durante la receve_msg */
		} 
	}
	return NULL;
}

/**
 * @brief Gestisce la fase di scelta del quiz da parte del client.
 *
 * La funzione mostra all'utente tutti i quiz disponibili che non ha ancora completato.
 * Attende quindi la selezione di un quiz da parte del client e verifica che:
 * - L'ID corrisponda a un quiz esistente
 * - Il quiz non sia già stato completato dal giocatore
 * In caso di selezione valida, restituisce l'ID del quiz scelto.
 *
 * Se il client non ha più quiz disponibili, la funzione informa il client e termina la fase di scelta quiz.
 *
 * @param sockfd Descrittore della socket connessa al client.
 * @param nickname Puntatore a una stringa contenente il nickname del giocatore.
 * @param nt Puntatore alla struttura del thread di rete associato al client.
 *
 * @return ID del quiz scelto (>= 0) se la selezione è valida; -1 in caso di errore (es. nickname nullo o errore interno), -2 se non ci sono più quiz disponibili per quel giocatore;
 */
int quiz_choosing_phase(int sockfd, char* nickname, struct net_thread* nt) { 
	char buffer[MAX_MSG_LEN] = {0}; /* Buffer di appoggio per il testo da inviare al client */
	struct theme *tmp_tm; /* Puntatore usato per scorrere la lista dei temi disponibili */
	int blen, player_id, num_quiz; /* blan: num. caratteri scritti nel buffer, player_id: id del giocatore, num_quiz: contatore dei quiz disponibili per quel giocatore*/
    struct player* player; /* Puntatore al giocatore che ha il nick passato come parametro*/
        
    if (nickname == NULL) return -1;

	tmp_tm = theme_list; /*Puntatore alla lista dei temi*/
	if (tmp_tm == NULL) 
		return -1;

    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    player_id = find_player(players, MAX_NUM_CLIENTS, nickname); 
    player = players[player_id];
    pthread_mutex_unlock(&players_mux); /* Proteggo l'accesso all'array di giocatori */

	/* Preparazione del testo della fase di scelta quiz */
	blen = sprintf(buffer, "%s\n", "Quiz disponibili");
	blen += sprintf(buffer + blen, "%s\n", PLUS_LINE);
    num_quiz = 0; /* Tiene traccia del numero di quiz disponibili dato il giocatore attuale */
    while(tmp_tm != NULL) { /* Scorro la lista di tutti i temi disponibili nei file */
        int sts = if_quiz_played_by_player(player, tmp_tm); /* Controllo se il giocatore ha già giocato il quiz con quel tema, oppure no*/
        if (sts == 0) { /* Se no, ne aggiunge l'opzione nel testo finale */
            blen += sprintf(buffer + blen, "%d - %s\n", tmp_tm->id, tmp_tm->name);
            num_quiz++;
        } else if (sts == -1) { /* Se c'è stato un errore esci */
            return -1; 
        } /* Altrimenti non fare nulla, e scorri la lista */
        tmp_tm = tmp_tm->next;
    }
	blen += sprintf(buffer + blen, "%s\n", PLUS_LINE);
	blen += sprintf(buffer + blen, "%s", "La tua scelta: ");
	
    if (num_quiz == 0) { /* Se non ci sono quiz giocabili  */
        memset(buffer, 0, strlen(buffer)); /* Svuoto il buffer, contenente il testo di scelta quiz */
        blen = sprintf(buffer, "Non ci sono più quiz disponibili.\n"); /* Inserisco nel buffer un messaggio esplicativo */
    }
    
	send_msg(sockfd, buffer, blen, nt); /* Invio il messaggio */
    send_num(sockfd, num_quiz, nt); /* Invio il numero di quiz ancora disponibili, sarà utile al client per sapere se terminare la fase di scelta dei quiz nel caso non ce ne fossero più */

    if (num_quiz == 0) return -2; /* Termino la fase di scelta quiz, lato server, non ci sono più quiz disponibili */

    /* Ciclo di attesa e controllo della scelta del prossimo quiz da giocare, da parte del giocatore*/
    while(true) { 
		uint32_t hcl_choice;  /* Conterrà l'id del quiz scelto dal giocatore */
        /* Attendo la scelta dell'id del prossimo quiz da giocare */
		hcl_choice = receve_num(sockfd, nt);

		/* controllo che il valore restituito appartenga ad un quiz esistente */ 
		tmp_tm = theme_list;
		while(tmp_tm != NULL) {
			if ((int)hcl_choice == tmp_tm->id) {
				break; /* se la scelta passata corrisponde ad un quiz esistente esco */
			}
			tmp_tm = tmp_tm->next;
		}

		if (tmp_tm != NULL) { /* è stato trovato un quiz con l'id scelto dal client */
            int sts = if_quiz_played_by_player(player, tmp_tm); /* Controllo che non sia stato già giocato */
            if (sts == -1) { /* Qualcosa è andato storto */
                send_nak(sockfd, nt); /* Notifico che il server non ha accettato la scelta */
            } else if (sts == 0) { /* Quiz scelto mai giocato */
			    send_ack(sockfd, nt); /* Invio conferma al client*/
			    return (int)hcl_choice; 
            } else { /* Quiz scelto già giocato */
                send_nak(sockfd, nt); /* Notifico che il server non ha accettato la scelta */
            }
		} else { /* Il quiz non è stato trovato tra la lista di quelli salvati nei file*/
			send_nak(sockfd, nt); /* invio nak e ricomincio il ciclo da campo in attesa di una nuova scelta dal client */
		}
	}
	
	return 0;
}


/**
 * @brief Genera un report sullo stato delle classifiche.
 *
 * Il report include:
 * - Le classifiche per ogni tema/quiz giocato
 * - L'elenco dei giocatori che hanno completato ciascun quiz
 *
 * Il messaggio è costruito in un buffer interno 'msg' e poi copiato in una zona di memoria
 * allocata dinamicamente, che il chiamante dovrà successivamente liberare con `free()`.
 *
 * La funzione assume che la dimensione massima del report sia entro i 3584 caratteri.
 *
 * @note La funzione accede a strutture globali come `players` e `theme_list`.
 *       L'accesso alla classifica di ogni quiz è protetto tramite `pthread_mutex` per garantire la coerenza.
 *
 * @return Puntatore a una stringa allocata dinamicamente contenente il messaggio di report.
 *         Restituisce `NULL` in caso di errore (es. fallimento malloc).
 */
char* report_rankings() {
    char buffer[3584] = {0}; /* Per semplicità si assume che la dimensione del messaggio di report non supererà mai i 3584 caratteri.*/
    char* msg; /*Messaggio da ritornare*/
    int len; /* Lunghezza del messaggio */
    struct theme* thead; /*puntatore per scorrere la lista dei temi*/
    struct quiz* qhead; /*puntatore per scorrere la lista di quiz*/

    /* Inserisce nel buffer le classifiche per tema */
    thead = theme_list;
    msg = NULL;
    len = 0;
    while(thead) {
        /* per ogni tema stamparne la classifica */
        len += sprintf(buffer + len, "\n");
        len += sprintf(buffer + len, "Punteggio tema %d\n", thead->id);
        qhead = find_quiz(thead->id); /* Richiede protezione in mutua esclusione*/

        if (qhead != NULL) {
            struct player_score* s_ptr; /* Puntatore usato per scorrere la classifica di un determinato quiz */
            pthread_mutex_lock(&qhead->mux); /* proteggo in mutua esclusione la lettura della classifica, così so che non verrà cambiata durante la lettura */
            s_ptr = qhead->ranking; 
            while (s_ptr) {
                len += sprintf(buffer + len, "- %s %d\n", s_ptr->player->nickname, s_ptr->score);
                s_ptr = s_ptr->next;
            }
            pthread_mutex_unlock(&qhead->mux);
        }    

        len += sprintf(buffer + len, "\n");
        thead = thead->next;
    }
    /* Inserisce nel buffer, per ogni quiz i giocatori che li hanno completati */
    thead = theme_list;
    while(thead) {
        /* per ogni tema stampare la lista dei giocatori che lo hanno completato */
        len += sprintf(buffer + len, "\n");
        len += sprintf(buffer + len, "Quiz tema %d completato\n", thead->id);

        pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
        for (int i = 0; i < MAX_NUM_CLIENTS; i++) { /* scorre tutti i giocatori */
            struct theme *tplayed; /* Puntatore usato per scorrere lista dei temi giocati da un giocatore */
            if (players[i] == NULL) continue; /* Se la cella non corrisponde ad un giocatore esistente, salta al prossimo ciclo*/
            
            tplayed = players[i]->quiz_played; /* Per ogni giocatore esistene, controlla che il tema puntato da thead sia tra i suoi completati*/
            while(tplayed) {
                if (tplayed->id == thead->id) { /* se si lo inserisce nel buffer per l'invio del messaggio*/
                    len += sprintf(buffer + len, "- %s\n", players[i]->nickname);
                }
                tplayed = tplayed->next;
            }
        }
        pthread_mutex_unlock(&players_mux); /* Proteggo l'accesso all'array di giocatori */

        thead = thead->next;
    }
    len += sprintf(buffer + len, "\n"); /* len contiene la dimensione totale del buffer*/
    msg = malloc((len + 1) * sizeof(char));
    if (msg == NULL)
        return NULL;
    
    (void) strcpy(msg, buffer); /* Riempie il messaggio utilizzando i dati del buffer */
    return msg;
}


/**
 * @brief Genera un report finale sullo stato del gioco.
 *
 * Il report include:
 * - L'elenco dei partecipanti attualmente connessi
 * - Le classifiche per ogni tema/quiz giocato
 * - L'elenco dei giocatori che hanno completato ciascun quiz
 *
 * La funzione assume che la dimensione massima del report sia entro i 4096 caratteri.
 *
 * @note La funzione accede a strutture globali come `players` e `theme_list`.
 *       L'accesso alla classifica di ogni quiz è protetto tramite `pthread_mutex` per garantire la coerenza.

 */
void game_report() {
    char buffer[4096] = {0}; /* Per semplicità si assume che la dimensione del messaggio di report non supererà mai i 4096 caratteri.*/
    char *tmp; /* Puntatore al messaggio temporaneo di report delle classifiche che verrà copiato in buffer per la stampa del report di gioco */
    int num_partecipanti, len; /* len: num caratteri scritti in buffer */

    /*Conta i partecipanti*/
    num_partecipanti = 0;
    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    for(int i = 0; i < MAX_NUM_CLIENTS; i++) {
        if (players[i] == NULL) continue;
        num_partecipanti++;
    }
    pthread_mutex_unlock(&players_mux); 

    /* Inserisce nel buffer la lista dei partecipanti */
    len = sprintf(buffer, "Partecipanti (%d)\n", num_partecipanti);

    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    for(int i = 0; i < MAX_NUM_CLIENTS; i++) {
        if (players[i] == NULL) continue;
        len += sprintf(buffer + len, "- %s\n", players[i]->nickname);
    }
    pthread_mutex_unlock(&players_mux); 

    tmp = report_rankings();
    if (tmp == NULL) {
        return;
    }
    strcpy(buffer + len, tmp); 
    
    printf("%s", buffer);    
    free(tmp);
}

/**
 * @brief Invia al client il report finale del gioco eventualmente frammentato in più messaggi.
 *
 * Usa la funzione `game_report()` per ottenere il report e lo invia al client in pacchetti.
 * Se il messaggio supera `MAX_MSG_LEN`, lo frammenta e invia ACK/NAK per sincronizzazione.
 *
 * @param sockfd Descrittore della socket connessa al client.
 * @param qz Puntatore al quiz attuale (non utilizzato direttamente in questa funzione).
 * @param nt Puntatore alla struttura del thread di rete.
 */
void show_score(int sockfd, struct quiz* qz, struct net_thread* nt) {
    char  *msg; /* Puntatore al messaggio di reporta da inviare al client*/
    char  *chunk; /* Puntatore al una portzione del messaggio di report principale */
    int   bytes_sent; /* Numero di byte inviati*/
    int   msg_dim; /* Dimensione totale del messaggio di report 'msg'*/

    msg = report_rankings();
    if (msg == NULL) return;

    msg_dim = strlen(msg);
    bytes_sent = 0;

    send_num(sockfd, msg_dim, nt); /* notifico il client della dimensione del messaggio finale */

    /* Ciclo di invio del messaggio completo */
    while (bytes_sent < msg_dim) {
        int nbytes; /* Num. byte da inviare in questo passo del ciclo*/
        bool send_end; /* vera se ho inviato tutti i bytes */
        if ((msg_dim - bytes_sent) > MAX_MSG_LEN) { /* se i byte rimanenti da inviare sono di più di quelli che si possono inviare in un solo messaggio, lo frammento */
            nbytes = MAX_MSG_LEN;
            send_end = false;
        } else {
            nbytes = (msg_dim - bytes_sent); /* invio i bytes mancanti */
            send_end = true;
        }
        /* Preparo il chunk e lo invio*/
        chunk = msg + bytes_sent;
        send_msg(sockfd, chunk, nbytes, nt);
        if (!send_end) 
            send_ack(sockfd, nt); /* dice al client di aspettarsi un altro messaggio */
        else 
            send_nak(sockfd, nt); /* buffer terminato, notifica il client di non aspettarsi altro */
        bytes_sent += nbytes;
    }
    free(msg);
    return;
}


/**
 * @brief Gestisce la fase di gioco vera e propria.
 *
 * Invia le domande al client, riceve le risposte e aggiorna il punteggio del giocatore.
 * Riconosce comandi speciali (come "show score" e "endquiz") e termina al termine del quiz, o a seguito di una endquiz.
 *
 * @param sockfd Descrittore della socket connessa al client.
 * @param nick_ptr Puntatore al nickname del giocatore.
 * @param quiz_id Identificativo del quiz selezionato.
 * @param nt Puntatore alla struttura del thread di rete.
 *
 * @return
 * - 0 se il quiz è completato correttamente
 * - -1 in caso di errore
 * - -2 se il client esce anticipatamente
 */
int game_phase(int sockfd, char* nick_ptr, int quiz_id, struct net_thread* nt) {
    struct player*  player;     /* puntatore al giocatore che sta partecipando al gioco */
    struct theme*   theme_choosen; /* puntatore al tema del quiz a cui il giocatore sta partecipando attualmente, eventualmente usato per aggiungere il tema giocato  alla lista dei temi completati */
    struct quiz*    current_quiz; /* puntatore al quiz a cui il giocatore sta partecipando attualmente */
    struct qea*     head;       /* puntatote usato per scorrere la lista di domande del quiz attuale */
    int   id, blen, retn;   /*id del giocatore; dim del testo iniziale di gioco; valore da ritornare*/
    char  eot = EOT;        /* carattere speciale che indica la fine della trasmissione delle domande */
    char  buf[MAX_MSG_LEN] = {0}; /* buffer di appoggio */

    retn = -1;
    /* controlli */
    if (sockfd < 0) return -1;
    if (nick_ptr == NULL) return -1;
    if (quiz_id < 0) return -1;
    if (nt == NULL) return -1;

    /* dato il nickname trovo l'id del giocatore */
    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    id = find_player(players, MAX_NUM_CLIENTS, nick_ptr);
    pthread_mutex_unlock(&players_mux); 
    if (id == -1) return -1;

    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    player = players[id]; /* accedo alla struttura dati del giocatore */
    pthread_mutex_unlock(&players_mux); 

    pthread_mutex_lock(&qlist_mux); 
    current_quiz = request_quiz(quiz_id); /* ottengo il puntatore al quiz scelto dal giocatore */
    pthread_mutex_unlock(&qlist_mux); 
    if (current_quiz == NULL) return -1;

    theme_choosen = malloc(sizeof(struct theme)); /* creo spazio per il tema */
    if (theme_choosen == NULL) {
        printf("Errore durante la malloc per il tema.\n");
        return -1;
    } 
    /**
     * copio l'id del quiz nel tema, il nome del tema non serve, ma solo l'id
     * per tener traccia dei quiz a cui il giocatore ha partecipato 
     */
    theme_choosen->name = NULL; 
    theme_choosen->id = quiz_id;
    theme_choosen->next = NULL;

    /* compongo ed invio il messaggio di intestazione che segna l'inizio del gioco */
    blen = sprintf(buf, "Quiz - %s\n", current_quiz->theme);
    blen = sprintf(buf + blen, "%s\n", PLUS_LINE);
    send_msg(sockfd, buf, blen, nt);
    

    head = current_quiz->qea_list; /* preparo il puntatore alla lista di domande */
    while(head != NULL) { /* Scorro le domande */
        char* client_answer; /* Puntatore alla risposta inviata dal client */
        int qst_len = strlen(head->question); /* lunghezza della domanda */
        /* invia la domanda */ 
        send_msg(sockfd, head->question, qst_len, nt);    
        /* attende e riceve la risposta */
        client_answer = receve_msg(sockfd, nt);

        /* controlla se la risposta è corretta o se rappresenta un comando e invia lo status */
        if (strcmp(client_answer, CMD_EXIT) == 0) { /* Il giocatore ha digitato il comando di fine gioco */
            check_quiz_played(player, theme_choosen); /* Segna il quiz attuale come giocato */
            pthread_mutex_lock(&qlist_mux); 
            game_report();
            pthread_mutex_unlock(&qlist_mux); 
            free_msg(client_answer); /* Dealloca la memoria usata per contenere la risposta del client */
            retn = -2;
            break;
        } else if (strcmp(client_answer, CMD_SHOWSCORE) == 0) { /* Comando show score */
            pthread_mutex_lock(&qlist_mux); 
            game_report();
            show_score(sockfd, current_quiz, nt); /*chiamata a funzione di showscore*/
            pthread_mutex_unlock(&qlist_mux); 
        } else if (strcmp(client_answer, head->answer) == 0) { /*Risposta errata*/
            char* reply = "Risposta corretta";
            send_msg(sockfd, reply, strlen(reply), nt); /* Invio esito */
            update_quiz_ranking(player, quiz_id); /* aggiorno la classifica */
            head = head->next;
            if (head == NULL) {
                send_msg(sockfd, &eot, 1, nt); /* invio terminatore, dico al client che non ci sono più domande */
                check_quiz_played(player, theme_choosen); /* Segna il quiz attuale come giocato */
                retn = 0;
            } else {
                send_ack(sockfd, nt); /* Notifico il client che ci sarà un altra domanda */
            }
            pthread_mutex_lock(&qlist_mux); 
            game_report();
            pthread_mutex_unlock(&qlist_mux); 
        } else { /*Risposta errata*/
            char* reply = "Risposta errata";
            send_msg(sockfd, reply, strlen(reply), nt); /* Invio esito */
            head = head->next;
            if (head == NULL) {
                send_msg(sockfd, &eot, 1, nt); /* invio terminatore, dico al client che non ci sono più domande */
                check_quiz_played(player, theme_choosen); /* Segna il quiz attuale come giocato */
                retn = 0;
            } else {
                send_ack(sockfd, nt); /* Notifico il client che ci sarà un altra domanda */
            }
            pthread_mutex_lock(&qlist_mux); 
            game_report();
            pthread_mutex_unlock(&qlist_mux); 
        }
        free_msg(client_answer);
    }
    pthread_mutex_unlock(&qlist_mux); 
    
    return retn;
}

/**
 * @brief Funzione eseguita da ciascun thread server figlio.
 *
 * Gestisce l'intero ciclo di vita di un client:
 * - Scelta del nickname
 * - Scelta dei quiz
 * - Esecuzione della fase di gioco
 *
 * Alla fine libera risorse, chiude socket e rimuove il giocatore.
 *
 * @param arg Puntatore a un intero che rappresenta l'indice del thread.
 *
 * @return NULL sempre (standard pthread).
 */
void* thread_server(void* arg) {
    int id = *(int*)arg; /* id del thread corrente */
    int th_sockfd = nthreads[id].sockfd; /* socket di comunicazione con il client */
    int theme_id; /* id del tema scelto */
    char* nickname; /* nickname scelto dal client */

    nthreads[id].arg = arg; /* copio l'indirizzo di memoria */
    
	if (th_sockfd < 0) {
		printf("Socket non inizializzata.\n");
        quit_nthread(&nthreads[id]);
        pthread_exit(NULL);
	}

    /* Fase di scelta del nickname */
    nickname = nickname_choosing_phase(th_sockfd, &nthreads[id]);
    if (nickname == NULL) {
        close(th_sockfd);
        quit_nthread(&nthreads[id]); /* la free arg la si può fare qui dentro grazie alla riga nthreads[id].arg = arg; */
        pthread_exit(NULL);
    }
    nthreads[id].player = &players[id]; 
    pthread_mutex_lock(&qlist_mux); 
    game_report();
    pthread_mutex_unlock(&qlist_mux); 

    do { 
        /* Fase di scelta del quiz */
        theme_id = quiz_choosing_phase(th_sockfd, nickname, &nthreads[id]);
        if (theme_id < 0) {
            if (theme_id == -1) {
                printf("Thrd %d: Lista temi vuota o errore, chiusura socket.\n", id);
            } else if (theme_id == -2) {
                printf("Thrd %d: Quiz esauriti.\n", id);
            }
            close(th_sockfd);
            pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
            pthread_mutex_lock(&qlist_mux);
            delete_player(players[id], 0);
            pthread_mutex_unlock(&qlist_mux);
            pthread_mutex_unlock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
            
            players[id] = NULL;
            quit_nthread(&nthreads[id]);
            pthread_exit(NULL);
        }
    } while (game_phase(th_sockfd, nickname, theme_id, &nthreads[id]) == 0); /* Cicla finchè la fase di gioco esce con status == 0 */


    printf("Thrd %d: Eliminazione giocatore e chiusura socket.\n", id);
    close(th_sockfd);

    pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    pthread_mutex_lock(&qlist_mux);
    
    delete_player(players[id], 0);
    
    pthread_mutex_unlock(&qlist_mux);
    
    players[id] = NULL;
    pthread_mutex_unlock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
    
    quit_nthread(&nthreads[id]);
    pthread_exit(NULL);
}

/**
 * @brief Punto di ingresso principale del server.
 *
 * - Carica i temi dalla cartella "quiz/"
 * - Inizializza le strutture globali
 * - Crea la socket di ascolto TCP
 * - Accetta nuove connessioni e avvia thread server dedicati
 *
 * Gestisce massimo `MAX_NUM_CLIENTS` connessioni concorrenti.
 *
 * @return 0 sempre in caso di terminazione corretta (non viene mai raggiunto nel ciclo infinito).
 */
int main() {
    struct sockaddr_in sv_addr; 
    int listen_sock, blen;
    char buffer[2048] = {0}; /* buffer di appoggio per la stampa */
    int* 	arg[MAX_NUM_CLIENTS]; /* array di argomenti per i thread server */
    socklen_t addrlen = sizeof(struct sockaddr_in); 
    struct theme* tmp_tm; /* puntatore usato per scorrere la lista dei temi disponibili nella cartella quiz */

    if(load_theme_list(&theme_list, "quiz/")) {
        printf("Errore durante il caricamento della lista dei temi.\n");
        exit(EXIT_FAILURE);
    }

    /* Inizializzo la socket di ascolto */
    listen_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_sock == -1) {
        perror("Errore durante la creazione del socket");
        exit(EXIT_FAILURE);
    }

    memset(&sv_addr, 0, sizeof(struct sockaddr_in));
    sv_addr.sin_family = AF_INET;
    sv_addr.sin_port = htons(atoi(SV_PORT));
    (void)inet_pton(AF_INET, SV_ADDRESS, &sv_addr.sin_addr);

    /* Associo la socket di ascolto ad un indirizzo ip e porta*/
    if (bind(listen_sock, (struct sockaddr*)&sv_addr, addrlen) == -1) {
        perror("Errore durante la bind");
        close(listen_sock);
        exit(EXIT_FAILURE); 
    }

    /* Predispongo la socket a ricevere richieste di connessione */
    if (listen(listen_sock, 1) == -1) {
        perror("Errore durante la listen");
        close(listen_sock);
        exit(EXIT_FAILURE); 
    }

    /* inizializzazione threads e giocatori, e liste */
    for(int i = 0; i < MAX_NUM_CLIENTS; i++) {
        init_nthread(&nthreads[i]);
        pthread_mutex_init(&nthreads[i].mux, NULL);
        /* init giocatori */
        players[i] = NULL;
    }
    
    /* Preparazione del testo dei disponibili */
	blen = sprintf(buffer, "%s\n", "Trivia Quiz");
	blen += sprintf(buffer + blen, "%s\n", PLUS_LINE);
    blen += sprintf(buffer + blen, "Temi: \n");
    tmp_tm = theme_list;
    while(tmp_tm != NULL) { /* Scorro la lista di tutti i temi disponibili nei file */
        blen += sprintf(buffer + blen, "%d - %s\n", tmp_tm->id, tmp_tm->name);
        tmp_tm = tmp_tm->next;
    }
	blen += sprintf(buffer + blen, "%s\n", PLUS_LINE);
    printf("%s\n", buffer);
    /** accept e creazione threads per la gestione di nuove connessioni */ 
    while(1) {
        int new_sock, index_created_thread; /* new_sock: file descriptor della nuova socket; index_created_thread: indice nell'array dei thread di rete del thread appena creato */
        struct sockaddr_in cl_addr;

        index_created_thread = -2; /* conterrà l'index del thread appena creato */
        /* printf("In attesa di nuove connessioni... \n\n"); */
        new_sock = accept(listen_sock, (struct sockaddr*)&cl_addr, &addrlen); 
        if (new_sock == -1) {
            perror("La richiesta di connessione non e' stata accettata");
            close(listen_sock);
            exit(EXIT_FAILURE); 
        }

        /* creo un nuovo thread */
        for (uint16_t i = 0; i < MAX_NUM_CLIENTS; i++) {
            int ret;
            uint16_t thread_status; /* status del thread: T_INIT, T_ALIVE, T_TERMINATED or T_ERROR*/
            /* accedo alle informazioni del nthread in maniera sicura */
            pthread_mutex_lock(&nthreads[i].mux);
            thread_status = nthreads[i].status;

            if (thread_status != T_ALIVE) {
                if (thread_status == T_ERROR) { /* Thread terminato con errore, cancello la struttura dati player e tutto ciò che è associato ad esso*/
                    if (players[i] != NULL) {
                        pthread_mutex_lock(&players_mux); /* Proteggo l'accesso all'array di giocatori */
                        pthread_mutex_lock(&qlist_mux);
                        delete_player(players[i], -1);
                        pthread_mutex_unlock(&qlist_mux);
                        players[i] = NULL; 
                        pthread_mutex_unlock(&players_mux);
                    }
                }
                arg[i] = (int*)malloc(sizeof(int));
                *arg[i] = i;
                index_created_thread = i;
                nthreads[i].sockfd = new_sock;
                ret = create_nthread(&nthreads[i], NULL, thread_server, (void*)arg[i]);
                if(ret == -1) { /* se la creazione del thread è fallita */ 
                    /* annullo le operazioni precedenti */
                    *arg[i] = 0;
                    free(arg[i]);
                    index_created_thread = -1;
                }
            }
            pthread_mutex_unlock(&nthreads[i].mux);
            if (index_created_thread != -2) { /* c'è stato un tentativo di creazione di un thread (non mi interessa qui sapere se a buon fine o meno) */
                break;
            }
        }
        if (index_created_thread < 0) { /* Capita se l'array di nthread è pieno oppure se la pthread_create da errore in create_nthread */
            printf("Impossibile creare un nuovo thread server, la richiesta è stata rifiutata...\n");
            close(new_sock);
        } else {
            /* printf("Connessione gestita dal thread no. %d.\n", index_created_thread); */
        }
        /* non chiudo la nuova socket perché tale compito spetta al thread figlio */
    }

    free_theme_list(&theme_list);
    printf("Chiusura server.\n");
    close(listen_sock);
    return 0;
}