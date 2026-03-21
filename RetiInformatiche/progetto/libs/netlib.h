#ifndef NETLIB_H
#define NETLIB_H

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#include "misc.h"
#include "game.h"

#define ACK 0x06
#define NAK 0x15
#define EOT 0x04

/* macro usati per/dalla handle_comunications_errors */
#define SEND 0
#define RECV 1
#define NET 2

/* Thread status */
#define T_INIT 0
#define T_ALIVE 1
#define T_TERMINATED 2
#define T_ERROR 3

/**
 * @struct net_thread
 * @brief Struttura per la gestione dello stato di un thread di rete.
 *
 * Contiene le informazioni per il controllo del thread e della connessione socket.
 * 
 *  isAlive e isTerminated assumono i seguenti significati:
 * 
 * | status  | Significato   |
 * |---------|---------------|
 * |   0     | init          |
 * |   2     | terminated    |
 * |   1     | alive         |
 * |   3     | undefined     |
 */
struct net_thread {
	/* thread handling */
	pthread_t 	    thrd;           /**< Identificativo del thread */
    pthread_mutex_t mux;            /**< Mutex per la sincronizzazione */
    void*           arg;            /**< Argomento del thread */
    uint16_t        status;        /**< Flag che indica lo stato del thread */
	
    /* socket and connection handling */
	int 		        sockfd;      /**< Socket associata alla connessione */
    /* player info*/
    struct player**     player;      /**< Puntatore al giocatore gestito dal thread di rete */
};

/* funzione per la gestione dei thread "di rete" */
void    init_nthread(struct net_thread* dt);
int     create_nthread(struct net_thread* dt, const pthread_attr_t* attr, void* (*start_routine)(void*), void* arg);
void    quit_nthread(struct net_thread* dt);
void    quit_nthread_err(struct net_thread* dt);

/* funzioni per la comuncazione sulla rete */
char*     receve_msg(int sockfd, struct net_thread* nthd);
void      free_msg(char* ptr);
void      send_msg(int sockfd, char* buf, int len, struct net_thread* nthd);
uint32_t  receve_num(int sockfd, struct net_thread* nthd);
void      send_num(int sockfd, int num, struct net_thread* nthd);
void      handle_net_errors(int sockfd, int exp_len, int real_len, int type, struct net_thread* nthd, void* ptr);

void    send_ack(int sockfd, struct net_thread* nthd);
void    send_nak(int sockfd, struct net_thread* nthd);
char    receve_status(int sockfd, struct net_thread* nthd);

#endif