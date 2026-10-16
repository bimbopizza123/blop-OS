CC     = gcc
LD     = ld
CFLAGS = -std=gnu11 -Wall -Wextra -O2 -pipe -ffreestanding \
         -fno-stack-protector -fno-stack-check -fno-lto -fno-PIC \
		 -m64 -march=x86-64 -mno-80387 -mno-mmx -mno-sse -mno-sse2 \
		 -mno-red-zone -mcmodel=kernel
LDFLAGS = -m elf_x86_64 -nostdlib -static -z max-page-size=0x1000 -T linker.ld

SRC := $(wildcard kernel/*.c)
OBJ := $(SRC:.c=.o)

all: blop_os.iso

kernel/%.o: kernel/%.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.elf: $(OBJ) linker.ld
	$(LD) $(LDFLAGS) $(OBJ) -o $@

blop_os.iso: kernel.elf limine.conf
	rm -rf iso
	mkdir -p iso/boot/limine iso/EFI/BOOT
	cp kernel.elf iso/boot/kernel
	cp limine.conf iso/boot/limine
	cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso/boot/limine
	cp limine/BOOTX64.EFI iso/EFI/BOOT/
	xorriso -as mkisofs -R -r -J \
		-b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		-hfsplus -apm-block-size 2048 \
		--efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label \
		iso -o blop_os.iso
	./limine/limine bios-install blop_os.iso

run: blop_os.iso
	qemu-system-x86_64 -M q35 -m 2G -cdrom blop_os.iso

run-uefi:
	qemu-system-x86_64 -M q35 -m 2G -bios /usr/share/ovmf/OVMF.fd -cdrom blop_os.iso

clean:
	rm -rf iso kernel/*.o kernel.elf blop_os.iso

.PHONY: all run run-uefi clean