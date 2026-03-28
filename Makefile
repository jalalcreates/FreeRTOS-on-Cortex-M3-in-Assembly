# Toolchain
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJDUMP = arm-none-eabi-objdump
GDB = arm-none-eabi-gdb
QEMU = qemu-system-arm

# Flags
ASFLAGS = -mcpu=cortex-m3 -mthumb -g
LDFLAGS = -T linker.ld

# Object files
OBJS = main.o tcb.o mutex.o

# Default target
all: main.elf main.lst

# Assemble main
main.o: main.S
	$(AS) $(ASFLAGS) main.S -o main.o

# Assemble tcb
tcb.o: tcb.S
	$(AS) $(ASFLAGS) tcb.S -o tcb.o
mutex.o: mutex.S
	$(AS) $(ASFLAGS) mutex.S -o mutex.o

# Link everything
main.elf: $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o main.elf

# Disassembly
main.lst: main.elf
	$(OBJDUMP) -D main.elf > main.lst

# Run QEMU
run: main.elf
	$(QEMU) -M stm32vldiscovery -cpu cortex-m3 \
	-kernel main.elf -nographic -S -s

# Debug
debug:
	$(GDB) -ex "target remote localhost:1234" \
	       -ex "load" \
	       -ex "b reset_handler" \
	       main.elf

clean:
	-del /Q *.o *.elf *.lst 2>nul || (if exist *.o del /Q *.o) & (if exist *.elf del /Q *.elf) & (if exist *.lst del /Q *.lst)