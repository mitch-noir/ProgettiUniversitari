#include "../libs/netlib.h"

/**
 * @brief Inizializza un oggetto net_thread impostandolo come non attivo.
 *
 * @param dt Puntatore alla struttura da inizializzare.
 */
void init_nthread(struct net_thread* dt) {
	dt->status = T_INIT;
	dt->sockfd = -1;
    dt->player = NULL;
}

/**
 * @brief Crea un nuovo thread e lo associa a una net_thread.
 *
 * @param dt Puntatore alla struttura net_thread da configurare.
 * @param attr Attributi opzionali del thread (può essere NULL).
 * @param start_routine Funzione da eseguire nel thread.
 * @param arg Argomento passato alla funzione del thread.
 * @return 0 se il thread è stato creato con successo, altrimenti un codice d'errore.
 */
int create_nthread(struct net_thread *dt, const pthread_attr_t *attr, void *(*start_routine)(void*), void *arg) {
	int ret = -1;
	ret = pthread_create(&dt->thrd, attr, start_routine, arg);

	if (ret == 0) {
		dt->status = T_ALIVE; 
	} else {
		init_nthread(dt); /* in caso di errore riporto il nthread allo stato iniziale */
	}
	return ret;
}

/**
 * @brief Termina un thread di rete, marcandolo come terminato e liberando la memoria.
 *
 * @param dt Puntatore alla struttura net_thread da terminare.
 */
void quit_nthread(struct net_thread* dt) {
    if (dt == NULL)
        return;

    pthread_mutex_lock(&dt->mux);
    dt->status = T_TERMINATED;
    if (dt->arg != NULL)
        free(dt->arg); /* dealloco la memoria */
    dt->player = NULL; /* la delete player la faccio nel codice chiamante*/
    pthread_mutex_unlock(&dt->mux);
}

/**
 * @brief Termina un thread di rete, marcandolo come terminato con errore.
 *
 * @param dt Puntatore alla struttura net_thread da terminare.
 */
void quit_nthread_err(struct net_thread* dt) {
    if (dt == NULL)
        return;

    pthread_mutex_lock(&dt->mux);
    dt->status = T_ERROR;
    if (dt->arg != NULL)
        free(dt->arg); /* dealloco la memoria */

    dt->player = NULL; /* la delete player la faccio nel codice chiamante*/
    pthread_mutex_unlock(&dt->mux);
}

/**
 * @brief Si occupa di tutte le operazioni necessarie all'invio di un messaggio in rete
 *
 * Prevede l'invio preventivo della dimensione (in formato binary) del messaggio testuale,
 * poi l'invio del messaggio testuale (in formato text).
 * 
 * @param sockfd Socket da cui ricevere.
 * @param nthd Puntatore alla struttura net_thread associata.
 * @return Puntatore al messaggio ricevuto (da liberare con free_msg).
 */
char* receve_msg(int sockfd, struct net_thread* nthd) {
    char* ptr; /* puntatore al messaggio ricevuto */
    int ret; /* valore di ritorno delle recv */
    uint32_t len, dim; /* dimensione del prossimo messaggio testuale da ricevere  */

    ret = recv(sockfd, &len, sizeof(uint32_t), 0);
    handle_net_errors(sockfd, sizeof(uint32_t), ret, RECV, nthd, NULL);

    len = ntohl(len); /*converto il numero da formato network a host*/
    dim = len + 1; /* sommo al numero di caratteri da ricevere uno per il terminatore */ 
    ptr = malloc(dim * sizeof(char));
    if (ptr == NULL) {
        handle_net_errors(sockfd, 0, 0, NET, nthd, NULL); 
    }

    ret = recv(sockfd, ptr, len, 0);
    handle_net_errors(sockfd, len, ret, RECV, nthd, (void*)ptr); 

    ptr[len] = '\0';
    
    return ptr; /* ptr punta alla zona di memoria in chi è presente la stringa ricevuta */
}

/**
 * @brief Libera la memoria allocata per un messaggio ricevuto.
 *
 * @param ptr Puntatore al buffer da liberare.
 */
void free_msg(char* ptr) {
  if (ptr == NULL)
    return;
  free(ptr);
}

/**
 * @brief Invia un messaggio tramite socket.
 *
 * L'invio del messaggio è preceduto dall'invio di un intero (uint32_t) 
 * che ne rappresenta la lunghezza. 
 *
 * @param sockfd Socket su cui inviare.
 * @param buf Buffer contenente il messaggio.
 * @param dim Lunghezza del messaggio.
 * @param nthd Puntatore alla struttura net_thread associata.
 */
void send_msg(int sockfd, char* buf, int dim, struct net_thread* nthd) {
    uint32_t lenh, lenn; /* dimensione del messaggio testuale da inviare in host e network order*/
    int ret; /* valore di ritorno delle send */

    if (sockfd == 0 || buf == NULL || dim < MIN_MSG_LEN || dim > MAX_MSG_LEN) {
        handle_net_errors(sockfd, 0, 0, NET, nthd, NULL);
    }

    lenh = (uint32_t)(dim); /* dimensione del buffer */
    lenn = htonl(lenh);
    ret = send(sockfd, &lenn, sizeof(uint32_t), 0);
    handle_net_errors(sockfd, sizeof(uint32_t), ret, SEND, nthd, NULL);

    ret = send(sockfd, (void*)buf, lenh, 0);
    handle_net_errors(sockfd, lenh, ret, SEND, nthd, NULL);
}

/**
 * @brief Invia un intero (uint32_t) tramite socket.
 *
 * @param sockfd Socket su cui inviare.
 * @param num Numero da inviare.
 * @param nthd Puntatore alla struttura net_thread associata.
 */
void send_num(int sockfd, int num, struct net_thread* nthd) {
    uint32_t net, hst; /* valore di 'num' in network e host order */
    int ret; /* valore di ritorno della send */
    hst = (uint32_t)(num); 
    net = htonl(hst);
    ret = send(sockfd, &net, sizeof(uint32_t), 0);
    handle_net_errors(sockfd, sizeof(uint32_t), ret, SEND, nthd, NULL);
}

/**
 * @brief Riceve un intero (uint32_t) da una socket.
 *
 * @param sockfd Socket da cui ricevere.
 * @param nthd Puntatore alla struttura net_thread associata.
 * @return Il numero ricevuto.
 */
uint32_t receve_num(int sockfd, struct net_thread* nthd) {
    int ret ; /* valore di ritorno della recv */
    uint32_t net, hst; /* valore numerico ricevuto in network e host order */

    ret = recv(sockfd, &net, sizeof(uint32_t), 0);
    handle_net_errors(sockfd, sizeof(uint32_t), ret, RECV, nthd, NULL);

    hst = ntohl(net); 
    return hst;
}

/**
 * @brief Gestisce gli errori di rete durante l'invio o la ricezione.
 *
 * In base al contesto (thread o processo), chiude la connessione e termina l'esecuzione.
 * Tale funzione gestisce i problemi di buffering TCP abortendo il thread o il processo,
 * non appena capitano, non ritenta l'invio o la ricezione dei byte mancanti.
 * Inoltre gestisce la deallocazione forzata delle strutture dati del giocatore che ha subito un errore. 
 *
 * @param sockfd Socket interessata.
 * @param exp_len Lunghezza attesa.
 * @param real_len Lunghezza effettiva.
 * @param type Tipo di operazione (SEND, RECV, NET).
 * @param nthd Puntatore alla struttura net_thread (può essere NULL).
 * @param ptr Puntatore opzionale a risorsa da liberare in caso d'errore.
 */
void handle_net_errors(int sockfd, int exp_len, int real_len, int type, struct net_thread* nthd, void* ptr){
    char* sv = "server";
    char* cl = "client";
    bool isThread = (nthd != NULL) ? true : false; /* true -> (thread server), false -> (processo client) */

    if (type == NET) { /* Se la funzione è stata chiamata in modalità generica, quindi non per via dell'invio/ricezione dei dati, assumendo che ci sia stato un errore*/
        free_msg(ptr); /*chiama la free se ptr != NULL*/ 
        if (isThread) {
            fprintf(stderr, "Errore nel thread no. %d: %s\n", *(int*)nthd->arg, strerror(errno));
            close(sockfd);
            /* chiusura thread */ 
            pthread_mutex_lock(&players_mux);
            pthread_mutex_lock(&qlist_mux); /*Proteggo la lista di quiz perché potrebbe uno dei suoi elemento può essere modifiato*/
            delete_player(*(nthd->player), -1);
            pthread_mutex_unlock(&qlist_mux); 
            *(nthd->player) = NULL;
            pthread_mutex_unlock(&players_mux);
            quit_nthread_err(nthd);
            pthread_exit(NULL);
        } else {
            fprintf(stderr, "Errore: %s\n", strerror(errno));
            close(sockfd);
            exit(EXIT_FAILURE); /* terminazione processo client */
        }
    } else { /* Se la funizione è stata chimata in modalità SEND o RECV*/
        if (exp_len != real_len) {
            free_msg(ptr); /* chiama la free se ptr != NULL*/ 
            if (real_len == 0) { /* Uno degli interlocutori si è disconnesso */
                close(sockfd);
                if (isThread) {
                    printf("Errore nel thread no. %d: il %s si è disconnesso.\n", *(int*)nthd->arg, cl);
                    /* chiusura thread */ 
                    pthread_mutex_lock(&players_mux);
                    pthread_mutex_lock(&qlist_mux); /*Proteggo la lista di quiz perché potrebbe uno dei suoi elemento può essere modifiato*/
                    delete_player(*(nthd->player), -1);
                    pthread_mutex_unlock(&qlist_mux);   
                    *(nthd->player) = NULL;
                    pthread_mutex_unlock(&players_mux);
                    quit_nthread_err(nthd);
                    pthread_exit(NULL);
                } else {
                    printf("Errore: Il %s si è disconnesso.\n", sv);
                    exit(EXIT_FAILURE); /* terminazione processo client */
                }
            } else if (real_len == -1) { /* C'è stato un errore di rete */
                if (isThread) {
                    fprintf(stderr, "Errore nel thread no. %d: %s\n", *(int*)nthd->arg, strerror(errno));
                    close(sockfd);
                    /* chiusura thread */ 
                    pthread_mutex_lock(&players_mux);
                    pthread_mutex_lock(&qlist_mux); /*Proteggo la lista di quiz perché potrebbe uno dei suoi elemento può essere modifiato*/
                    delete_player(*(nthd->player), -1);
                    pthread_mutex_unlock(&qlist_mux);   
                    *(nthd->player) = NULL;
                    pthread_mutex_unlock(&players_mux);
                    quit_nthread_err(nthd);
                    pthread_exit(NULL);
                } else {
                    fprintf(stderr, "Errore: %s\n", strerror(errno));
                    close(sockfd);
                    exit(EXIT_FAILURE); /* terminazione processo client */
                }
            } else { /* real_len < exp_len */
                if (type == SEND) { /* Se ho inviato meno byte di quelli indicati */
                    if (isThread) { /* thread server */
                        printf("Errore nel thread no. %d: solo parte dei dati è stata inviata al %s.\n", *(int*)nthd->arg, cl);
                        close(sockfd);
                        /* chiusura thread */ 
                        pthread_mutex_lock(&players_mux);
                        pthread_mutex_lock(&qlist_mux); /*Proteggo la lista di quiz perché potrebbe uno dei suoi elemento può essere modifiato*/
                        delete_player(*(nthd->player), -1);
                        pthread_mutex_unlock(&qlist_mux);   
                        *(nthd->player) = NULL;
                        pthread_mutex_unlock(&players_mux);
                        quit_nthread_err(nthd);
                        pthread_exit(NULL);
                    } else { /* processo client */
                        printf("Errore: Solo parte dei dati è stata inviata al %s.\n", sv);
                        close(sockfd);
                        exit(EXIT_FAILURE); /* terminazione processo client */
                    }
                }
                if (type == RECV) { /* Se ho ricevuto meno byte di quelli indicati */
                    if (isThread) { /* thread server */
                        printf("Thrd no. %d: solo parte dei dati è stata ricevuta dal %s.\n", *(int*)nthd->arg, cl);
                        close(sockfd);
                        /* chiusura thread */ 
                        pthread_mutex_lock(&players_mux);
                        pthread_mutex_lock(&qlist_mux); /*Proteggo la lista di quiz perché potrebbe uno dei suoi elemento può essere modifiato*/
                        delete_player(*(nthd->player), -1);
                        pthread_mutex_unlock(&qlist_mux);   
                        *(nthd->player) = NULL;
                        pthread_mutex_unlock(&players_mux);
                        quit_nthread_err(nthd);
                        pthread_exit(NULL);
                    } else { /* processo client */
                        printf("Solo parte dei dati è stata ricevuta dal %s.\n", sv);
                        close(sockfd);
                        exit(EXIT_FAILURE); /* terminazione processo client */
                    }
                }
            }
        }
    }
}

/**
 * @brief Invia un messaggio di ACK (1 byte).
 *
 * @param sockfd Socket su cui inviare.
 * @param nthd Puntatore alla struttura net_thread associata.
 */
void send_ack(int sockfd, struct net_thread* nthd) {
  char ack = ACK;
  send_msg(sockfd, &ack, 1, nthd);
}

/**
 * @brief Invia un messaggio di NAK (1 byte).
 *
 * @param sockfd Socket su cui inviare.
 * @param nthd Puntatore alla struttura net_thread associata.
 */
void send_nak(int sockfd, struct net_thread* nthd) {
  char nak = NAK;
  send_msg(sockfd, &nak, 1, nthd);
}

/**
 * @brief Riceve uno status (ACK/NAK o altro) dalla socket.
 *
 * @param sockfd Socket da cui ricevere.
 * @param nthd Puntatore alla struttura net_thread associata.
 * @return Il carattere ricevuto.
 */
char receve_status(int sockfd, struct net_thread* nthd) {
  char *status = receve_msg(sockfd, nthd); /*stringa di stato*/
  char ret = status[0]; /* continene lo stato (in quanto è specificato nel primo carattere) */
  free_msg(status);
  return ret;
}