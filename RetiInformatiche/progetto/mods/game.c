/* game logic */
#include "../libs/game.h"

pthread_mutex_t qlist_mux = PTHREAD_MUTEX_INITIALIZER;
struct quiz* quiz_list = NULL;
struct theme* theme_list = NULL;
struct player* players[MAX_NUM_CLIENTS];
pthread_mutex_t players_mux = PTHREAD_MUTEX_INITIALIZER;

/**
 * @brief Estrae il nome del tema dalla prima riga del file.
 * @param filename Nome del file.
 * @param path Percorso del file.
 * @return Puntatore al nome del tema (da liberare con free), oppure NULL in caso di errore.
 */
char* extract_theme_from_file(char* filename, char* path) {
    char file_path[256] = {0}; /* buffer di appoggio che conterrà il percorso completo del file da cui estrarre il file  */
    FILE *fptr; /* puntatore al file */
    char first_row[1024]; /* buffer che conterrà la prima riga letta del file, che contiente il tema*/
    char *start, *end, *name; /*puntatori di utilità per il parsing */
	int len; /* lunghezza del nome del tema dopo il parsing */

    /* preparo il file_path da usare per aprire il file */
	strcpy(file_path, path);
	strncpy(file_path + strlen(file_path), filename, strlen(filename)); /* preparo il filepath ./filename */
	fptr = fopen(file_path, "r"); /* apro il file */
	if (fptr == NULL) { /* controllo e rrori */
		perror("load_theme - errore durante l'apertura del file");
		printf("filepath: %s\n", file_path);
		return NULL;
	}
	/* leggo la prima riga del file (che contiene il tema del quiz) */
	if (fgets(first_row, sizeof(first_row), fptr) == NULL) {
		perror("load_theme - errore durante la lettura della prima riga del file");
		return NULL;
	}

	/* estrapolo i titolo del tema dalla prima riga calcolando i puntatori alle doppie virgolette (start, end) */
	start = strchr(first_row, '"');
	if (start == NULL) {
		printf("load_theme - Virgolette di apertura non trovate: %s\n", first_row);
		return NULL;
	}

	end = strchr(start+1, '"');
	if (end == NULL) {
		printf("load_theme - Virgolette di chiusura non trovate: %s\n", first_row);
		return NULL;
	}

	/* calcola la lunghezza del contenuto tra le virgolette */
	len = end - start - 1;
	
	/*alloca spazio e copia il contenuto tra le virgolette */
	name = malloc(len + 1);
	if (name == NULL) {
		perror("load_theme - malloc");
		return NULL;
	}
	strncpy(name, start + 1, len); 
	name[len] = '\0'; /* chiusura della stringa */
    return name;
}

/**
 * @brief Carica le domande e risposte dal file e le associa al quiz specificato.
 * Questa funzione si occupa caricare a partire da un file una lista di domande e risposte 
 * 1. Legge una riga alla volta e se incontra una riga con domanda e risposta ne fa il parsing 
 * 2. Fatto il parsing salva domanda e risposta separatamente in una variabile di tipo qea
 * @param filename Nome del file.
 * @param path Percorso del file.
 * @param qz Puntatore al quiz da popolare.
 * @return 0 in caso di successo, -1 in caso di errore.
 */
int load_questions(char* filename, char* path, struct quiz* qz){
	char buffer[1024]; /* buffer di appoggio per la lettura delle singole righe del file */
	char file_path[256] = {0}; /* percorso del file da leggere */
    FILE *fptr; /* puntatore al file */
    struct qea* qaptr_prev = NULL; /* puntatore all'elemento qea precedente */
  
    /* preparo il file_path da usare per aprire il file */
	strcpy(file_path, path);
	strncpy(file_path + strlen(file_path), filename, strlen(filename)); /* preparo il filepath ./filename */ 
	fptr = fopen(file_path, "r"); /* arpo il file */
	if (fptr == NULL) { /* controllo errori */
		perror("load_theme - errore durante l'apertura del file");
		printf("filepath: %s\n", file_path);
		return -1;
	}

	if (fptr == NULL) 
		return -1;

    pthread_mutex_lock(&qz->mux); /* proteggo in mutua esclusione la lista di domande in fase di creazione */
	while(fgets(buffer, sizeof(buffer), fptr) != NULL) { /* legge una riga del file alla volta */
		/* ogni riga di domanda è formattata nel seguente modo all'interno del file */
		/* - Testo domanda? Testo risposta;\n */
		char* qst_mark = strchr(buffer, '?'); 	/* puntatore alla cella in cui è presente '?' */
		char* semi_colon = strchr(buffer, ';');	/* puntatore alla cella in cui è presente ';' */
        uint16_t q_start_idx, q_end_idx, a_start_idx, a_end_idx; /* indici di inizio e fine del testo della domanda e risposta */
        struct qea* new_qea; /* nuovo elemento qea */

		int qlen;; /* lunghezza della stringa di domanda + terminatore stringa */
		int alen ; /* lunghezza della stringa di risposta + terminatore stringa */
		if (qst_mark == NULL) {
			/* la riga letta non corrisponde a una domanda, saltala */
			continue;
		}

		if (semi_colon == NULL) {
			/* la riga letta non corrisponde a una domanda, saltala */
			continue;
		}

		/* calcolo gli indici di inizio e fine del testo della domanda e risposta */
		q_start_idx = 2;
		q_end_idx = (uint16_t)(qst_mark - buffer);
		a_start_idx = (q_end_idx + 2);
		a_end_idx = (uint16_t)(semi_colon - buffer);

		qlen = (q_end_idx - q_start_idx) + 1; /* lunghezza della stringa di domanda + terminatore stringa */
		alen = (a_end_idx - a_start_idx) + 1; /* lunghezza della stringa di risposta + terminatore stringa */
		
		/* creo un elemento question & answer e alloco memoria per esso */
		new_qea = malloc(sizeof(struct qea));
		if (new_qea == NULL) {
			perror("Malloc fallita");
            fclose(fptr);
            free_qea_list(qz->qea_list); /* dealloco tutta la lista creata fino a quel momento. */
			pthread_mutex_unlock(&qz->mux);
            return -1;
		}

		if (qaptr_prev == NULL) { /* se vera stiamo leggendo la prima riga di domanda/risposta */
			qz->qea_list = new_qea; /* inserisco il primo elemento della lista di q&a */
		} else { /* vuol dire che nella qea_list c'è almeno un elemento */
			qaptr_prev->next = new_qea; /* collego l'elemento precedente a quello attuale */
		}

		new_qea->question = malloc(sizeof(char) * qlen); 	/* alloco memoria per la stringa di domanda */
        if (new_qea->question == NULL) {
			perror("Malloc fallita");
            fclose(fptr);
            free_qea_list(qz->qea_list); /* dealloco tutta la lista creata fino a quel momento. */
			pthread_mutex_unlock(&qz->mux);
            return -1;
		}
		new_qea->answer = malloc(sizeof(char) * alen);		/* idem per quella di risposta */
		if (new_qea->answer == NULL) {
			perror("Malloc fallita");
            fclose(fptr);
            free_qea_list(qz->qea_list); /* dealloco tutta la lista creata fino a quel momento. */
            pthread_mutex_unlock(&qz->mux);
            return -1;
		}

		memcpy(new_qea->question, buffer + q_start_idx, qlen - 1); /* copio la domanda nella memoria dinamica */
		new_qea->question[qlen-1] = '\0'; 

		memcpy(new_qea->answer, buffer + a_start_idx, alen - 1); /* copio la risposta in memoria dinamica */
		new_qea->answer[alen-1] = '\0'; 
		
		new_qea->next = NULL;	
		qaptr_prev = new_qea;	/* salvo il puntatore alla qea per il prossimo ciclo */
		/* pulizia memoria per il prossimo round */
		memset(buffer, 0, sizeof(buffer));
	}

    pthread_mutex_unlock(&qz->mux);
	fclose(fptr);
	return 0;
}

/**
 * @brief Salva in memoria un nuovo quiz da file.
 * @param filename Nome del file.
 * @param path Percorso del file.
 * @param quiz_id Identificativo numerico del quiz.
 * @return Puntatore alla struttura quiz creata, NULL in caso di errore.
 */
struct quiz* load_quiz(char* filename, char* path, int quiz_id){
    struct quiz* qz; /* puntatore al nuovo quiz da caricare in memoria */
	if (quiz_id <= 0) {
		printf("Valore di quiz id non valido. \n");
		return NULL;
	}

	qz  = malloc(sizeof(struct quiz)); /* alloco spazio in memoria per un nuovo quiz */
    if (qz == NULL) return NULL;
	qz->id = quiz_id;	/* salvo l'id */
	qz->theme = extract_theme_from_file(filename, path);  /* copio il puntatore alla zona di memoria che contiene il titolo */
	qz->next = NULL;	
  	qz->ranking = NULL;
  	pthread_mutex_init(&qz->mux, NULL);

    /* inserisce nel quiz la lista di domande/risposte caricandola dal file */
	if(load_questions(filename, path, qz) == -1) { /* se fallisce annullo anche le operazioni precedenti */
        free(qz->theme);
        pthread_mutex_destroy(&qz->mux);
        free(qz);
        return NULL;
    }
	return qz;
}

/**
 * @brief Inserisce un quiz in ordine crescente nella lista globale quiz_list.
 * @param list Puntatore al puntatore della lista.
 * @param qz Puntatore al quiz da inserire.
 * @return 0 in caso di successo, -1 in caso di errore.
 */
int insert_quiz(struct quiz** list, struct quiz* qz) { 
    struct quiz *qptr_curr, *qptr_prev; /* puntatori di utilità usati per scorrere la lista di quiz */
    int target_id; /* id del quiz da inserire */
	if (qz == NULL) return -1;
	if (list == NULL) return -1;
  
	if (*list == NULL) {
		*list = qz;
        return 0;
	} 
    /* aggiunge in coda alla lista il quiz */
    qptr_curr = *list;
    qptr_prev = NULL;
    target_id = qz->id;
    while(qptr_curr->next != NULL) { /* scorre la lista fino in fondo */
        if (target_id < qptr_curr->id) break;
        /* preparazione per il prossimo ciclo */
        qptr_prev = qptr_curr;
        qptr_curr = qptr_curr->next; 
    }
    /* all'uscita dal while qptr_curr o punta all'ultimo elemento non nullo della lista, o al primo elemento che ha id maggiore di target_id */
    if (qptr_curr->next == NULL) {
        qptr_curr->next = qz; /* inserisco il quiz in fondo */
    } else if (qptr_curr->id == target_id) { 
        if (qz == qptr_curr) {
            printf("Errore quiz gia' in lista.\n");
        } else {
            printf("Errore stai cercando di sovrascrivere un altro quiz con stesso id");
            /* dealloca la memoria per quel qz in quanto non può essere usato */
            free_quiz(qz); /* si assume che qz sia stato allocato precedentemente */
        }
        return -1;
    } else { /* inserisco il quiz tra i due elementi */
        qz->next = qptr_curr;
        qptr_prev->next = qz;
    }
    return 0;
}

/**
 * @brief Cerca un quiz nella lista globale quiz_list.
 * @param quiz_number Identificativo del quiz.
 * @return Puntatore al quiz trovato o NULL se non presente.
 */
struct quiz* find_quiz(int quiz_number) {
    struct quiz* qptr = quiz_list;
    while(qptr != NULL) {
		if (qptr->id == quiz_number) {
			break;
		}
		qptr = qptr->next; /* salta al prossimo elemento */
	}

	if (qptr != NULL) {
		/* allora il quiz è stato caricato in memoria, ne restituisco il puntatore */
        return qptr; 
	} 
    return NULL;
} 

/**
 * @brief Carica (se necessario) e restituisce il quiz richiesto.
 * Funzione che restituisce (se non ci sono errori) il puntatore al quiz indicato dal valore di quiz_number
 * 1. Controlla che il quiz non sia già stato precedentemente caricato in memoria se si restituisce il puntatore 
 * 2. Altrimenti tenta di caricare un nuovo quiz da un file che ha per titolo quiz_num.txt
 * 
 * Nota: in questo modo si ottimizzano gli accessi in memoria (lettura file), in quanto lo si fa una sola volta per quiz
 * e inoltre non lo si richiede per tutti i quiz disponibili ma solo se richiesti su domanda (e se non già caricati)
 * @param quiz_number Identificativo del quiz.
 * @return Puntatore al quiz in memoria o NULL in caso di errore.
 */
struct quiz* request_quiz(int quiz_number) {
    struct quiz* qz; /* puntatore al quiz da caricare in memoria */
    struct quiz* qptr; /*puntatore al quiz ricercato*/
    char filename[100] = {0};

	if (quiz_number <= 0) {
		return NULL; /* errore */
	} 

	/* dato il numero di quiz ricerco se tale quiz è stato già caricato in memoria */
	qptr = find_quiz(quiz_number); /** fatto in mutua esculsione, perché la lista dei quiz potrebbe cambiare durante la find_quiz */
	
	if (qptr != NULL) {
		/* allora il quiz è stato caricato  in quanto qptr punta al quiz di mio interesse */
		return qptr; 
	}

	/* se mi trovo qui, il quiz non è stato caricato, devo quindi caricarlo dal file */
	if (sprintf(filename, "%d.txt", quiz_number) < 0) { /* creo la stringa del file_path */
		perror("Sprintf");
		return NULL;
	}
	
	qz = load_quiz(filename, "quiz/", quiz_number); /* crea un nuovo elemento quiz a partire da un file (specificando nome e percorso) */
	if (qz == NULL ) { /* Se c'è stato un errore nel caricamento di un quiz, fallisco */
        return NULL;
    }
	if (insert_quiz(&quiz_list, qz) == -1) { /* inserisce il nuovo elemento in coda alla lista quiz e controllo di mutua esculusione */
		printf("insert_quiz fallita\n");
		free_quiz(qz);
	}

	return qz;		/* ritorna il puntatore alla zona di memoria che contiene il quiz */
	/* nota tale zona di memoria è stata allocata nella load_quiz, non c'è bisogno di farlo qui */
}

/**
 * @brief Dealloca la lista di domande e risposte.
 * @param head Puntatore alla testa della lista.
 */
void free_qea_list(struct qea* head) {
	while(head != NULL) {
		struct qea* tmp = head;
		head = head->next;
		
		free(tmp->question);
		free(tmp->answer);
		free(tmp);
	}
}

/**
 * @brief Dealloca l'intera classifica.
 * @param ptr Puntatore alla classifica.
 */
void free_ranking(struct player_score* ptr) {
    struct player_score* head = ptr;

    while (head != NULL) {
        struct player_score* tmp = head;
        head = head->next;
        free(tmp);
    }
}   

/**
 * @brief Dealloca un oggetto quiz e tutte le sue risorse.
 * @param qz Puntatore al quiz da liberare.
 */
void free_quiz(struct quiz* qz) {
	free(qz->theme);
	free_qea_list(qz->qea_list);
	if (qz->ranking != NULL) {
		free_ranking(qz->ranking);
	}
	free(qz);
	printf("Quiz deallocato con successo.\n");
}

/**
 * @brief Stampa su stdout le domande e risposte di una lista.
 * @param list Puntatore alla lista qea.
 */
void print_qea(struct qea* list) {
	struct qea* head = list;
	while(head != NULL) {
		printf("Domanda: %s?\n", head->question);
		printf("Risposta: %s\n", head->answer);
		head = head->next;
	}
}

/**
 * @brief Crea e inizializza un nuovo oggetto theme a partire da un file specificato da path/filname.
 * @param filename Nome del file.
 * @param path Percorso.
 * @param id Identificativo del tema.
 * @return Puntatore al nuovo tema o NULL in caso di errore.
 */
struct theme* load_theme(char* filename, char* path, int id) {
	struct theme *new_theme;
	
	new_theme = malloc(sizeof(struct theme));
	if (new_theme == NULL) {
		printf("Errore durante la malloc per il nuovo tema.\n");
		return NULL;
	}
	new_theme->name = extract_theme_from_file(filename, path); /* fa anche la malloc all'interno */
	if (new_theme->name == NULL) {
		printf("Errore durante l'estrazione dei tema dal file.\n");
		free(new_theme);
		return NULL;
	}
	new_theme->id = id;
	new_theme->next = NULL;

	return new_theme;
}

/**
 * @brief Carica i temi disponibili dai file nella cartella specificata.
 *
 * Questa funzione esamina i file nella directory `path` e, per ogni file `num.txt`,
 * estrae il tema e lo inserisce nella lista dei temi `t_list`, mantenendo l'ordine crescente per ID.
 * L'inizializzazione viene effettuata una sola volta: se la lista non è NULL, non fa nulla.
 *
 * @param t_list Puntatore al puntatore della lista dei temi.
 * @param path Percorso della cartella contenente i file `.txt`.
 * @return 0 in caso di successo, -1 se la lista è già stata caricata o in caso di errore.
 */
int load_theme_list(struct theme** t_list, char* path) {
	DIR* dptr;  /* puntatore alla cartella da cui caricare la lista di temi*/
	struct dirent* ep; /* puntatore all'entrata della directory */

	/* tale controllo permette di caricare la lista di quiz solo se è inizialmente vuota */
	if (*t_list != NULL) {
		printf("Lista temi già allocata. \n");
		return -1;
	}

	dptr = opendir(path); 

	if (dptr != NULL) {
		while( (ep = readdir(dptr)) != NULL ) { /* recupera una entry della directory */
			char* filename = ep->d_name; 
			int nf_len = strlen(filename); /* dimenzione della stringa titolo.extention */
			int t_len = nf_len - 4; /* dimensione stringa titolo senza estensione */
			char* extension = filename + t_len; /*puntatore all'estensione */
			if (nf_len <= 4) continue; /* se il file ha un titolo troppo corto lo ignoro */
			if (strcmp(extension, ".txt") == 0) { /* considera solo i file che terminano per .txt */
				long int num; /*contiente il titolo in formato decimale*/
				char *name, *endptr; /* ptr di utilità*/
				name = malloc(t_len + 1); /* alloca spazio solo per il titolo del file + '\0' */
				strncpy(name, filename, t_len);
				name[t_len] = '\0'; /* inserisce il terminatore */
				num = strtol(name, &endptr, 10); /* converte la stringa in un numero decimale */
				
				if (strlen(endptr) != 0) {
					/* vuol dire che endptr non punta ad una stringa vuota quindi ci sono dei caratteri non convertibili in numeri decimali, quindi ignora il file */
					printf("Il titolo non rappresenta un numero decimale: %s\n", filename); 
					continue;
				} 
				if (num > INT_MAX) continue; /* ignora il file con il num_id troppo grande */
				
				/* se ci troviamo qui il file è nel formato giusto, possiamo aprirlo */
				if (*t_list == NULL) { /* se la lista di temi è vuota inseriamo il primo in testa */
					*t_list = load_theme(filename, path, num); /* carica un nuovo tema in memoria a partire dal file indicato da path/filename */
					if (*t_list == NULL) {
						printf("load_theme ha dato puntatore null come risultato.\n");
					}
				} else { /* se la lista di temi non è vuota procediamo al caricamento e inseriamo in modo ordinato il tema nella lista (in base al nome del file) */
                    struct theme* pt; /* puntatore al tema caricato */
					struct theme* ptr = *t_list; /* puntatore di utilià per scorrere la lista di temi */
					struct theme* prev_ptr = NULL; /* puntatore di utilità */
					while (ptr != NULL) { /* ricerco la posizione nella lista in cui inserire il nuovo tema */
						if (num < ptr->id) 
							break; 
						prev_ptr = ptr;
						ptr = ptr->next;
					} 
					/*	
						esco dal while per due motivi: 
						1. ptr == NULL quindi vuol dire che il numero del tema è il più grande di tutti quelli nella lista, quindi il tema va inserito in coda
						2. num < ptr->id quindi ptr != NULL quindi il tema va inserito in mezzo alla lista  
					*/ 
					pt = load_theme(filename, path, num);
					if (pt == NULL) { 
						printf("Errore durante la load del tema.\n");
						return -1;
					}
					if (ptr == NULL) { 
						prev_ptr->next = pt; /* inserisco in coda*/
					} else {
						pt->next = ptr;
						if(prev_ptr == NULL) { /* sto inserendo in testa alla lista */
							*t_list = pt;
						} else { /* sto inserendo in mezzo alla lista */
							prev_ptr->next = pt; 
						}
					}
				}
			}
		}
	}
  return 0;
}

/**
 * @brief Dealloca la memoria della lista dei temi.
 *
 * @param t_list Puntatore al puntatore della lista dei temi da liberare.
 */
void free_theme_list(struct theme** t_list){
	if (*t_list == NULL)
		return;

	struct theme *head = *t_list;
	while(head != NULL) {
		struct theme* tmp = head; 
		head = head->next;
        if (tmp->name != NULL)
            free(tmp->name);
		free(tmp);
	}
	*t_list = NULL;
	/*printf("Lista dei temi deallocata con successo\n");*/
}

/**
 * @brief Cerca un giocatore tramite nickname all'interno della lista.
 *
 * @param player_list Array di puntatori a strutture player.
 * @param dim Dimensione dell'array.
 * @param nick_ptr Puntatore al nickname da cercare.
 * @return Indice del giocatore se trovato, -1 altrimenti.
 */
int find_player(struct player* player_list[], int dim, char* nick_ptr) { /* La lista giocatori 'player_list' va protetta in mutua esclusione dal chiamante */
    if (nick_ptr == NULL) return -1;
    if (dim < 1) return -1;
    if (player_list == NULL) return -1;

    for (int i = 0; i < dim; i++) { /* Scorre l'array di puntatori a giocatore */
        int scmp; /* esito della string compare */

        if (player_list[i] == NULL) continue;
        pthread_mutex_lock(&(player_list[i]->mux));
        scmp = strcmp(player_list[i]->nickname, nick_ptr);
        pthread_mutex_unlock(&(player_list[i]->mux));
		if (scmp == 0) {
            return i; /* Restituisce l'indice del giocatore che ha il nickname specificato come terzo paramtro */
        }
    }

    return -1; /* Se non lo trova */
}

/**
 * @brief Verifica che il nickname non sia già stato utilizzato.
 *
 * @param player_list Array di puntatori a strutture player.
 * @param dim Dimensione dell'array.
 * @param nick_ptr Puntatore al nickname da verificare.
 * @return true se il nickname è unico, false altrimenti.
 */
bool check_nick_unqueness(struct player* player_list[], int dim, char* nick_ptr) { /* La lista giocatori 'player_list' va protetta in mutua esclusione dal chiamante */
    if (nick_ptr == NULL) return false;
    if (dim < 1) return false;
    if (player_list == NULL) return false;
    
    if (find_player(player_list, dim, nick_ptr) != -1) return false; /* Ritorna false se find_player trova un giocatore con il nickname specificato */

    return true;
}

/**
 * @brief Salva un nuovo giocatore nella lista.
 *
 * @param player_list Array di puntatori a strutture player.
 * @param dim Dimensione dell'array.
 * @param nick_ptr Puntatore al nickname del nuovo giocatore (già allocato).
 * @param tid id del thread che ha chiamato la save_player
 * @return 0 in caso di successo, -1 in caso di errore o se la lista è piena.
 */
int save_player(struct player* player_list[], int dim, char* nick_ptr, int tid) { /* La lista giocatori 'player_list' va protetta in mutua esclusione dal chiamante */
    struct player* new_player; /* puntatore al nuovo giocatore da salvare */
    
    /* Controllo parametri */
    if (nick_ptr == NULL) return -1;
    if (dim < 1) return -1;
    if (player_list == NULL) return -1;
    
	
    if (player_list[tid] != NULL) {
        /* C'è già un giocatore in quella posizione, probabiltmente non è stato eliminato per via di un errore nel precedente thread con stesso id*/
        printf("Il giocatore della sessione precedente non è stato eliminato correttamente.\n");
        return -1;
    }

    new_player = malloc(sizeof(struct player));
    if (new_player == NULL) return -1;
    
    new_player->nickname = nick_ptr; /* non c'è bisogno della malloc in quanto è già stata fatta per creare nick_ptr */
    new_player->quiz_played = NULL;
    new_player->thread_id = tid;
    /*mux init*/
    pthread_mutex_init(&(new_player->mux), NULL);
    player_list[tid] = new_player;

    return 0;
}

/**
 * @brief Rimuove il giocatore da tutte le classifiche dei quiz a cui ha partecipato.
 * 
 * Utilizzando la lista dei temi completati dal giocatore, è possibile individuare i quiz
 * e la relativa classifica da cui togliore il giocatore.
 * 
 * @param player Puntatore al puntatore del giocatore da rimuovere.
 */
void delete_player_rank(struct player** player, int exit_status) { /* La lista giocatori va protetta dal chiamante, ed anche la lista quiz*/
	struct quiz *quiz_list_ptr; /* puntatore alla lista di quiz da scorrere */
	struct theme *theme_played_ptr; /* puntatore alla lista dei temi giocati */
    /* Controlli */
	if (player == NULL) return;
 	if (*player == NULL) return;
    /* mutext lock*/
    pthread_mutex_lock(&(*player)->mux); /* Proteggo la lista dei quiz giocati perché potrebbe essere letta da una show score di un altro thread*/
	if ((*player)->quiz_played == NULL) {
        pthread_mutex_unlock(&(*player)->mux);
        return;
    }

    /* Copio il puntatore alla lista dei temi dei quiz completati */
	
    if (exit_status == -1) { 
        /* Se la delete_player_rank è stata chiamata a seguito di una errore, 
        l'ultimo quiz che il giocatore stava giocando non è stato segnato come giocato quindi va cercato */
        quiz_list_ptr = quiz_list;
        while(quiz_list_ptr) { 
            struct player_score *target_pl, *prev_pl; /* puntatoridi utilità alle entrate della classifica */
            bool found = false; /* indica se il giocatore che si vuole eliminare si trova in classifica  */
            theme_played_ptr = (*player)->quiz_played;
            while(theme_played_ptr) {
                if (theme_played_ptr->id == quiz_list_ptr->id) {
                    found = true;
                    break;
                }
                theme_played_ptr = theme_played_ptr->next;
            }

            if (found) { /* Quiz trovato, non mi intereassa aggiornarne la classifica adesso, salto al prossimo ciclo */
                quiz_list_ptr = quiz_list_ptr->next;
                continue;
            }

            /*Se il quiz non è segnato tra quelli giocati, ricerco il quiz che è stato interrotto e ne elimino l'entrata del giocatore*/
            pthread_mutex_lock(&quiz_list_ptr->mux);
            target_pl = quiz_list_ptr->ranking; 
            prev_pl = NULL;
            while(target_pl) { /* ricerco lo score del giocatore da eliminare nella classifica */
                if (target_pl->player == *player) {
                    if (prev_pl != NULL) { 
                        prev_pl->next = target_pl->next; 
                        free(target_pl);
                    } else { /* elimino lo score in cima alla classifica*/
                        quiz_list_ptr->ranking = target_pl->next;
                        free(target_pl);
                    }
                }
                prev_pl = target_pl;
                target_pl = target_pl->next;
            }

            pthread_mutex_unlock(&quiz_list_ptr->mux);

            quiz_list_ptr = quiz_list_ptr->next;
        }

    }

    theme_played_ptr = (*player)->quiz_played;
	while(theme_played_ptr) { /* per ogni tema giocato elimino il giocatore dalla classifica di tale tema */
		struct player_score *target_pl, *prev_pl;
		quiz_list_ptr = quiz_list; /* Puntatore alla testa della lista di quiz globale*/
		while(quiz_list_ptr) { /* Ricerca il puntatore al quiz che ha lo stesso id desiderato */
			if (quiz_list_ptr->id == theme_played_ptr->id)
				break;
			quiz_list_ptr = quiz_list_ptr->next;
		}
	
		if (quiz_list_ptr == NULL) {
			break;
		}
		/* quiz_list_ptr punta al quiz da cui si vuole togliere il giocatore */
		pthread_mutex_lock(&quiz_list_ptr->mux); /* proteggo il quiz in mutua esclusione, così se altri thread vogliono accedervi devono aspettare che la classifica sia aggiornata */
		
        target_pl = quiz_list_ptr->ranking;
        prev_pl = NULL;
		while(target_pl) { /* Ricerca il giocatore nella classifica */
			if (target_pl->player == *player)
				break;
            prev_pl = target_pl;
			target_pl = target_pl->next;
		}

		if (prev_pl == NULL) { 
            if (target_pl == NULL) { /* lista vuota */
                theme_played_ptr = theme_played_ptr->next;
                pthread_mutex_unlock(&quiz_list_ptr->mux);
                continue; 
            } 
            /* il giocatore da eliminare si trova in testa alla classifica */
            quiz_list_ptr->ranking = quiz_list_ptr->ranking->next; /* scollego il primo elemento dalla classifica */
            free(target_pl); /* lo dealloco */
            theme_played_ptr = theme_played_ptr->next;
            pthread_mutex_unlock(&quiz_list_ptr->mux);
            continue;
        }

        if (target_pl == NULL) { /* giocatore non trovato, in classifica non far nulla */
            pthread_mutex_unlock(&quiz_list_ptr->mux);
        } else {
            prev_pl->next = target_pl->next; /* scollego target dalla classifica */
            pthread_mutex_unlock(&quiz_list_ptr->mux);
            free(target_pl);
        }
		
		theme_played_ptr = theme_played_ptr->next;
	}

    pthread_mutex_unlock(&(*player)->mux);

	return;
}

/**
 * @brief Rimuove un giocatore dalla lista e dealloca tutta la memoria associata.
 *
 * Rimuove anche le partecipazioni ai quiz e il nickname.
 *
 * @param player puntatore al player.
 * @param dim Dimensione dell'array.
 * @return 0 sempre, -1 in caso di parametri non validi.
 */
void delete_player(struct player* player, int exit_status) { 
    if (player == NULL) return;

    delete_player_rank(&player, exit_status); /* Elimina le entrate in tutte le classifiche in cui il giocatore si trova */
    free(player->nickname); /* Dealloca la memoria usata per memorizzare il nickname */
    free_theme_list(&player->quiz_played);  /* Dealloca la lista dei temi dei quiz completati */
    pthread_mutex_destroy(&(player->mux));  /*pl mutex destroy*/
    free(player); /* Dealloca il giocatore */

    return;
}

/**
 * @brief Stampa l'elenco dei giocatori attualmente registrati.
 *
 * @param player_list Array di puntatori a strutture player.
 * @param dim Numero massimo di giocatori nell'array.
 */
void print_players(struct player* player_list[], int dim) { /* la player_list va protetta in mutua esclusione dal chiamante */
  if (dim < 1) return;
  if (player_list == NULL) return;

	for (int i = 0; i < dim; i++) {
        if (player_list[i] == NULL) continue;

		printf("%d - %s\n", i, player_list[i]->nickname);
	}
}

/**
 * @brief Registra un tema come completato da un giocatore.
 *
 * Aggiunge il tema specificato alla lista dei quiz completati del giocatore.
 *
 * @param player Puntatore alla struttura del giocatore.
 * @param theme Puntatore alla struttura del tema da registrare.
 */
void check_quiz_played(struct player* player, struct theme* theme) {
    struct theme* head; /*Puntatore alla lista di temi giocati*/
    
    if (player == NULL) return;
    if (theme == NULL) return;

    pthread_mutex_lock(&(player->mux));
    head = player->quiz_played;

    if (head == NULL) {
        player->quiz_played = theme;
        pthread_mutex_unlock(&(player->mux));
        return;
    } 

    while(head->next != NULL) {
        head = head->next; /* scorre la lista */
    }

    /* qui head punta all'ultimo elemento della lista */
    head->next = theme;
    pthread_mutex_unlock(&(player->mux));
    return;
}

/**
 * @brief Verifica se un giocatore ha già completato un determinato quiz.
 *
 * @param player Puntatore alla struttura del giocatore.
 * @param theme Puntatore alla struttura del tema da verificare.
 * @return 1 se il quiz è già stato giocato, 0 se non lo è, -1 in caso di errore.
 */
int if_quiz_played_by_player(struct player* player, struct theme* theme) {
    struct theme* head; /*Puntatore alla lista di temi giocati*/
    
    if (player == NULL) return -1; /* errore */
    if (theme == NULL) return -1; /* errore */

    
    pthread_mutex_lock(&(player->mux)); 
    head = player->quiz_played; 
 
    if (head == NULL) { /* quiz mai giocati */
        pthread_mutex_unlock(&(player->mux));
        return 0; 
    }

    while(head!= NULL) {
        if(head->id == theme->id)
            break; 
        head = head->next; /* scorre la lista */
    }
    pthread_mutex_unlock(&(player->mux));
    if (head == NULL) return 0; /* quiz mai giocato */
    else return 1; /* quiz già giocato */
}

/**
 * @brief Aggiorna la classifica di un quiz incrementando il punteggio del giocatore.
 *
 * Se il giocatore non è presente in classifica, viene aggiunto con punteggio 1.
 * Se è già presente, il punteggio viene incrementato e la posizione aggiornata.
 * La classifica è mantenuta ordinata in ordine decrescente di punteggio.
 *
 * @param player Puntatore alla struttura del giocatore.
 * @param quiz_id ID del quiz da aggiornare.
 */
void update_quiz_ranking(struct player* player, int quiz_id) {
    struct quiz *curr_quiz; /* puntatore al quiz da aggiornare */
    struct player_score *prev, *curr, *pl_ptr, *pl_prev; /* puntatore allo score del giocatore */

    if (player == NULL) return;
    if (quiz_id < 0) return;

    
    curr_quiz = find_quiz(quiz_id);
    if (curr_quiz == NULL) return;

    
    pthread_mutex_lock(&curr_quiz->mux); /* Proteggo l'accesso al quiz */
    prev = NULL;
    curr = curr_quiz->ranking;
    pl_ptr = NULL;
    pl_prev = NULL;

    /* cerca il nodo del giocatore */
    while(curr) {
        if (curr->player == player) {
            pl_ptr = curr;
            break;
        }
        pl_prev = curr;
        curr = curr->next;
    }

    if (pl_ptr == NULL) {
        /* giocatore non presente, inseriscilo in classifica con punteggio 1 */
        struct player_score* new_score = malloc(sizeof(struct player_score)); /* nuova entry da inserire nella classifica */
        if(!new_score) {
            pthread_mutex_unlock(&curr_quiz->mux);
            return;
        }
        new_score->player = player;
        new_score->score = 1;
        new_score->next = NULL;

        if (curr_quiz->ranking == NULL) {
            curr_quiz->ranking = new_score; /* inserisco il primo elemento della classifica */
        } else {
            pl_prev->next = new_score; /* inserisco il giocatore in fondo alla classifica */
        }

        pthread_mutex_unlock(&curr_quiz->mux);
        return;
    }
    
    /* giocatore già in classifica: rimuovo il giocatore dalla classifica */
    if (pl_prev == NULL) {
        curr_quiz->ranking = pl_ptr->next;
    } else {
        pl_prev->next = pl_ptr->next;
    }

    /* ne incrementa il punteggio */
    pl_ptr->score++;

    /* reinserisco il giocatore nella posizione corretta */
    prev = NULL;
    curr = curr_quiz->ranking;
    while (curr && curr->score >= pl_ptr->score) {
        prev = curr;
        curr = curr->next;
    }

    if (prev == NULL) { /* inserisco in cima */
        pl_ptr->next = curr_quiz->ranking;
        curr_quiz->ranking = pl_ptr;
    } else {
        pl_ptr->next = curr;
        prev->next = pl_ptr;
    }

    pthread_mutex_unlock(&curr_quiz->mux);
    return;
}