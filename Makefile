ASM = nasm
CC = gcc
LD = ld

CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector
LDFLAGS = -m elf_i386

C_SOURCES = kernel/kernel.c kernel/files.c kernel/shell.c drivers/screen.c drivers/keyboard.c cpu/ports.c cpu/gdt.c cpu/idt.c
C_OBJECTS = $(C_SOURCES:.c=.o)

all: os.iso

boot.o: boot/boot.asm
	$(ASM) -f elf32 boot/boot.asm -o boot.o

gdt.o: cpu/gdt.asm
	$(ASM) -f elf32 cpu/gdt.asm -o gdt.o

isr.o: cpu/isr.asm
	$(ASM) -f elf32 cpu/isr.asm -o isr.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.bin: boot.o gdt.o isr.o $(C_OBJECTS)
	$(LD) $(LDFLAGS) -T kernel/linker.ld -o kernel.bin boot.o gdt.o isr.o $(C_OBJECTS)

os.iso: kernel.bin
	mkdir -p iso/boot/grub
	cp kernel.bin iso/boot/kernel.bin
	cp boot/grub.cfg iso/boot/grub/grub.cfg
	cp files/*.txt iso/boot/
	grub-mkrescue -o os.iso iso

run: os.iso
	qemu-system-i386 -cdrom os.iso

clean:
	rm -f *.o kernel/*.o drivers/*.o cpu/*.o
	rm -f *.bin *.iso
	rm -rf iso/boot
