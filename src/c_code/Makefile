

all: rom.hex


rom.hex:
	#riscv64-unknown-elf-gcc -Wl,--print-memory-usage -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -fpic -O0 rv32i_gen.s -o test_linked.o
	riscv64-unknown-elf-gcc -Wl,--print-memory-usage -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -fpic -O3 -mcmodel=medlow -mexplicit-relocs crt0.s uart/uart.c spi/spi.c main.c -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
