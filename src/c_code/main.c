#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "uart/uart.h"
#include "spi/spi.h"

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
    while (1)
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
      spi_set_cp(0xf);
      
      spi_set_cpha(1);
      spi_set_cpol(1);
      spi_set_cs(0b11111110);
      spi_send_byte(0b11001010, 1);
      spi_set_cs(0xf);
    }
    uart_set_baud_rate(115200);
    uart_set_parity(0);
    uart_bus_mode(BUS_LCK);
    uart_set_stop_bits(1);
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
    

    while(1)
    {
        char c = uart_getc_blocking();
        uart_puts("You typed: ");
        uart_putc(c);
        uart_puts("\n");
    }
}