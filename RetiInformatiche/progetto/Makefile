# Variabili
CC = gcc
CFLAGS = -Wall
LDFLAGS = 

# File sorgente
COMMON_SRCS = mods/netlib.c mods/game.c
SERVER_SRCS = server.c $(COMMON_SRCS) 
CLIENT_SRCS = client.c $(COMMON_SRCS)

# File oggetto
SERVER_OBJS = $(SERVER_SRCS:.c=.o)
CLIENT_OBJS = $(CLIENT_SRCS:.c=.o)

# Eseguibili
SERVER_BIN = server
CLIENT_BIN = client

# Regola per costruire tutto
all: $(SERVER_BIN) $(CLIENT_BIN)

# Regola per costruire il server
$(SERVER_BIN): $(SERVER_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Regola per costruire il client
$(CLIENT_BIN): $(CLIENT_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Regola per costruire i file oggetto
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Regola per pulire i file generati
clean:
	rm -f $(SERVER_OBJS) $(CLIENT_OBJS) $(SERVER_BIN) $(CLIENT_BIN)