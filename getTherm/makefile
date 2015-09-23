CC=gcc
CFLAGS=-Wall -O3

all: build

build: main.o
	$(CC) main.o -o /usr/bin/getTemp

test: main.o
	$(CC) main.o -o test

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

clean:
	rm -f main.o test /usr/bin/getTemp
