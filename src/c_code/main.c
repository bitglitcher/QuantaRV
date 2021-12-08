#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "uart/uart.h"
#include "spi/spi.h"
#include "memory_map.h"

uint32_t read_mvendorid()
{
  int value = 0;
  asm("csrr %0, mvendorid": "=r"(value));
  return value;
}
uint32_t read_marchid()
{
  int value = 0;
  asm("csrr %0, marchid": "=r"(value));
  return value;
}
uint32_t read_mimpid()
{
  int value = 0;
  asm("csrr %0, mimpid": "=r"(value));
  return value;
}
uint32_t read_mhartid()
{
  int value = 0;
  asm("csrr %0, mhartid": "=r"(value));
  return value;
}


__attribute__((aligned(32))) void trap_handler()
{
    // char buffer [50];
    // sprintf(buffer, "Currently In Trap Handler\n");
    // prints(buffer);
}

__attribute__((aligned(32))) void timer_interrupt_handler()
{
    // char buffer [50];
    // sprintf(buffer, "Currently In Timer Interrupt Handler\n");
    // prints(buffer);
    //*((uint32_t*)0x10000088) = *((uint32_t*)0x10000080) + 0xfffff;
}

char banner [] = "\
   ____                    _        _______      __\n\
  / __ \\                  | |      |  __ \\ \\    / /\n\
 | |  | |_   _  __ _ _ __ | |_ __ _| |__) \\ \\  / / \n\
 | |  | | | | |/ _` | '_ \\| __/ _` |  _  / \\ \\/ /  \n\
 | |__| | |_| | (_| | | | | || (_| | | \\ \\  \\  /   \n\
  \\___\\_\\\\__,_|\\__,_|_| |_|\\__\\__,_|_|  \\_\\  \\/    \n\
                                                   \n\
                                                   \n";


#define OP_TYPE_DATA 0x0000
#define GET_EOP_CODE(data) ((data >> 9) & 0x1)

//Header to transfer information to it
typedef struct
{
    uint8_t op_type;
    uint32_t s_addr;
    uint32_t size;
} hd_t;

typedef struct
{
    //8 bits are data and the last bit is the parity bit
    //The remaining bits from the 9th bit define if the operation will be aborted
    uint16_t data;
} sp_t;

int main(void) {
  //Testing SPI
    spi_set_cs(1);
    spi_set_freq(15e6);
    spi_set_twp(0);
    spi_set_tx_bm(SPI_BUS_MODE_LCK);
    spi_set_tx_bm(SPI_BUS_MODE_LCK);
   /* while (0)
    {
      spi_set_cs(0xf);
      spi_set_cpha(0);
      spi_set_cpol(0);
      spi_set_cs(0b11111110);
      spi_send_byte(0b11001010, 1);
      spi_set_cs(0xf);

      spi_set_cpha(1);
      spi_set_cpol(0);
      spi_set_cs(0b11111110);
      spi_send_byte(0b11001010, 1);
      spi_set_cs(0xf);

      spi_set_cpha(0);
      spi_set_cpol(1);
      spi_set_cs(0b11111110);
      spi_send_byte(0b11001010, 1);
      spi_set_cs(0xf);
      
      spi_set_cpha(1);
      spi_set_cpol(1);
      spi_set_cs(0b11111110);
      spi_send_byte(0b11001010, 1);
      spi_set_cs(0xf);
    }*/
    uart_set_baud_rate(115200);
    uart_set_parity(0);
    uart_bus_mode(BUS_LCK);
    uart_set_stop_bits(1);
    /*
    uart_puts(banner);
    uart_puts("By: Bitglitcher\n\n\n");

    char buffer [50];

    uart_puts("heartid: 0x");
    itoa(read_mhartid(), buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
    uart_puts("marchid: 0x");
    itoa(read_marchid(), buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
    uart_puts("mimpid: 0x");
    itoa(read_mimpid(), buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
    uart_puts("vendorid: 0x");
    itoa(read_mvendorid(), buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
    
    //Memory Test
    //Write a value between 0-2^32-1 and read it back to
    //test of the memory is being read and written to
    uart_puts("OnChip Memory: BASE 0x");
    itoa(OCR_BASE, buffer, 16);
    uart_puts(buffer);
    uart_puts(" LENGHT 0x");
    itoa(OCR_END-OCR_BASE, buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
    uart_puts("SDRAM        : BASE 0x");
    itoa(SDRAM_BASE, buffer, 16);
    uart_puts(buffer);
    uart_puts(" LENGHT 0x");
    itoa(SDRAM_END-SDRAM_BASE, buffer, 16);
    uart_puts(buffer);
    uart_puts("\n");
*/
    char buffer [50];
    //Separate output
    uart_puts("--------------------------------\n");
    uart_puts("Testing SDRAM...\n");
    for(int i = SDRAM_BASE;i < SDRAM_END;i=i+4)
    {
		uart_puts("Testing Address 0x");
		itoa(i, buffer, 16);
		uart_puts(buffer);
		*((uint32_t*)(i)) = i; //Assign it to its own address
   		//Read back and cofirm value
		if(*((uint32_t*)(i)) != i)
		{
			uart_puts("Error writting to 0x");
			itoa(i, buffer, 16);
			uart_puts(buffer);
			uart_puts("SDRAM Memory Test Failed\n");
			;
		}	
		else
		{
			uart_puts(" D: 0x");
		       	itoa(*((uint32_t*)(i)), buffer, 16);
			uart_puts(buffer);
			uart_puts("\r");
		}
	}
	uart_puts("SDRAM test finished");
    while(1);
	
/*
    while(1)
    {
        char c = uart_getc_blocking();
        uart_puts("You typed: ");
        uart_putc(c);
        uart_puts("\n");
    }*/
}
