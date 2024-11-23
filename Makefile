CC = gcc
CCFLAGS = -Wall -g
PROGRAM_NAME = daemon-tracker

all: $(PROGRAM_NAME)

$(PROGRAM_NAME).o: main.c
	$(CC) $(CCFLAGS) -c main.c -o $(PROGRAM_NAME).o

$(PROGRAM_NAME): daemon-tracker.o
	$(CC) $(CCFLAGS) -o $(PROGRAM_NAME) $(PROGRAM_NAME).o

clean:
	rm -f $(PROGRAM_NAME) $(PROGRAM_NAME).o
