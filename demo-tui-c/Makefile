CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lncurses -lm
TARGET = demo
SRC = demo.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)

install-deps:
	@echo "Installing ncurses development library..."
	@if command -v apt-get > /dev/null; then \
		sudo apt-get install -y libncurses5-dev libncurses-dev; \
	elif command -v yum > /dev/null; then \
		sudo yum install -y ncurses-devel; \
	elif command -v dnf > /dev/null; then \
		sudo dnf install -y ncurses-devel; \
	elif command -v pacman > /dev/null; then \
		sudo pacman -S --noconfirm ncurses; \
	elif command -v brew > /dev/null; then \
		brew install ncurses; \
	else \
		echo "Please install ncurses development library manually"; \
	fi

.PHONY: all clean run install-deps
