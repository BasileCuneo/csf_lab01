
CC=	arm-linux-gnueabihf-gcc
CFLAGS= -std=c99 -I.
LDFLAGS=-lm
TARGET = avl_counter_test
USER = root
HOSTNAME = 192.168.0.2

all: $(TARGET)

$(TARGET): avl_counter_test.o
	@echo "\033[0;36mCompiling $(TARGET)...\033[0m"
	$(CC) -o $@ $^ $(LDFLAGS) $(LDLIBS)

%.o : %.c
	$(CC) -o $@ -c $< $(CFLAGS) -Wall

deploy: $(TARGET)
	@echo "\033[0;36mDeploying $(TARGET)...\033[0m"
	scp $(TARGET) $(USER)@$(HOSTNAME):/root

run: deploy
	@echo "\033[0;36mRunning $(TARGET) on remote...\033[0m"
	ssh -t -t $(USER)@$(HOSTNAME) "LD_LIBRARY_PATH=/usr/xenomai/lib ./$(TARGET)"

clean:
	rm -f *.o $(TARGET)

.PHONY: clean
