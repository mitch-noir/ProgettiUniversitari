#ifndef GAME_H
#define GAME_H

/* game logic */
#include <sys/types.h>
#include <stdint.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <limits.h>
#include <pthread.h>

#include "misc.h"

/**
 * @struct player
 * @brief Rappresenta un giocatore con nickname, ID e lista dei quiz completati.
 */
struct player {
    char* nickname;               /**< Nickname del giocatore */
    int   thread_id;              /**< Identificativo numerico del thread che gestisce il giocatore */
    struct theme* quiz_played;    /**< Lista dei temi giocati */
    pthread_mutex_t mux;          /**< Mutex che protegge l'accesso alla struttura player */
};

/**
 * @struct player_score
 * @brief Nodo della classifica associata a un quiz.
 */
struct player_score {
    struct player* player;               /**< Puntatore al giocatore */
    int score;                           /**< Punteggio ottenuto */
    struct player_score* next;           /**< Nodo successivo */
};

/**
 * @struct qea
 * @brief Struttura contenente una domanda e la sua risposta.
 */
struct qea {
    char* question;                      /**< Testo della domanda */
    char* answer;                        /**< Testo della risposta */
    struct qea* next;                    /**< Prossima domanda */
};

/**
 * @struct quiz
 * @brief Rappresenta un quiz associato a un tema.
 */
struct quiz {
    char* theme;                         /**< Titolo del tema */
    int id;                              /**< Identificativo del quiz */
    struct qea* qea_list;                /**< Lista di domande e risposte */
    struct quiz* next;                   /**< Prossimo quiz */
    struct player_score* ranking;        /**< Classifica del quiz */
    pthread_mutex_t mux;                 /**< Mutex per accesso concorrente */
};

/**
 * @struct theme
 * @brief Contiene le informazioni di un tema disponibile.
 * struttura utile nella fase iniziale di vita del server, 
 * per poter salvare i temi disponibili, prima della load effettiva dei quiz, 
 * ma anche per tener traccia per ogni player a quali temi ha partecipato o sta partecipando
 */
struct theme {
    char* name;                          /**< Nome del tema */
    int id;                              /**< Identificativo numerico */
    struct theme* next;                  /**< Nodo successivo */
};

extern pthread_mutex_t  qlist_mux; /* mutex per l'accesso alla variabile globale quiz_list */
extern struct quiz*     quiz_list; /* puntatore alla testa della lista di quiz */
extern struct theme*    theme_list; /* lista dei temi disponibili nella cartella /quiz */
extern struct player*   players[MAX_NUM_CLIENTS]; /* Array di giocatori */
extern pthread_mutex_t  players_mux; /* mutex per l'accesso all'array di giocatori */

char* extract_theme_from_file(char* filename, char* path);
int load_questions(char* filename, char* path, struct quiz* qz);
void print_qea(struct qea* list);

struct quiz* load_quiz(char* filename, char* path, int quiz_id);
int insert_quiz(struct quiz** list, struct quiz* qz);
struct quiz* find_quiz(int quiz_number);
struct quiz* request_quiz(int quiz_number);

void free_qea_list(struct qea* head);
void free_quiz(struct quiz* qz);
void free_ranking(struct player_score* ptr);

struct theme* load_theme(char* filename, char* path, int id);
int load_theme_list(struct theme** t_list, char* path);
void free_theme_list(struct theme** t_list);

int find_player(struct player* player_list[], int dim, char* nick_ptr);
bool check_nick_unqueness(struct player* player_list[], int dim, char* nick_ptr);
int save_player(struct player* player_list[], int dim, char* nick_ptr, int tid);
void delete_player_rank(struct player** player, int exit_status);
void delete_player(struct player* player, int exit_status);
void print_players(struct player* player_list[], int dim);

int if_quiz_played_by_player(struct player* player, struct theme* theme);
void check_quiz_played(struct player* player, struct theme* theme);
void update_quiz_ranking(struct player* player, int quiz_id);

#endif