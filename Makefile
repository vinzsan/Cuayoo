ASSEMBLER = nasm
LINKER = ld
SOURCE_DIR = src

.PHONY: all clean

all: test

build/lib.o: $(SOURCE_DIR)/lib.asm
	mkdir -p build 
	$(ASSEMBLER) -f elf64 $(SOURCE_DIR)/lib.asm -o build/lib.o

build/mutex.o: $(SOURCE_DIR)/mutex.asm 
	mkdir -p build 
	$(ASSEMBLER) -f elf64 $(SOURCE_DIR)/mutex.asm -o build/mutex.o 

build/memory.o: $(SOURCE_DIR)/memory.asm 
	mkdir -p build 
	$(ASSEMBLER) -f elf64 $(SOURCE_DIR)/memory.asm -o build/memory.o

build/main.o: $(SOURCE_DIR)/main.asm
	mkdir -p build
	$(ASSEMBLER) -f elf64 $(SOURCE_DIR)/main.asm -o build/main.o

test: build/main.o build/lib.o build/memory.o build/mutex.o
	$(LINKER) build/main.o build/lib.o build/memory.o build/mutex.o -o test

clean:
	rm -rf build
