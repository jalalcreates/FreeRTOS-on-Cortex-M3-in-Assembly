# Toolchain
CC = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJDUMP = arm-none-eabi-objdump
GDB = arm-none-eabi-gdb
QEMU = qemu-system-arm

# Flags
CFLAGS = -mcpu=cortex-m3 -mthumb -g
LDFLAGS = -T linker.ld

# Targets
all: main.elf main.lst

# Assemble
main.o: main.s
	$(CC) $(CFLAGS) main.s -o main.o

# Link
main.elf: main.o
	$(LD) $(LDFLAGS) main.o -o main.elf

# Disassembly (useful for debugging)
main.lst: main.elf
	$(OBJDUMP) -D main.elf > main.lst

# Run QEMU (starts paused, waiting for GDB)
run: main.elf
	$(QEMU) -M stm32vldiscovery -cpu cortex-m3 \
	-kernel main.elf -nographic -S -s

# Debug with GDB
debug:
	$(GDB) -ex "target remote localhost:1234" \
	       -ex "load" \
	       -ex "b systick_handler" \
	       main.elf

clean:
	rm -f *.o *.elf *.lst