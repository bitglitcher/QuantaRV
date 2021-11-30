#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "uart/uart.h"

// void prints(char* string)
// {
//     char* c = string;
//     while(*c)
//     {
//         //*d = *c;
//         uart_write(*c);
//         c++;
//     }
// }

// void printn(int n)
// {

//     char c[50];
//     itoa(n, c, 10);
//     prints(c);
//     prints("\n");
// }

// uint32_t read_mvendorid()
// {
//   int value = 0;
//   asm("csrr %0, mvendorid": "=r"(value));
//   return value;
// }
// uint32_t read_marchid()
// {
//   int value = 0;
//   asm("csrr %0, marchid": "=r"(value));
//   return value;
// }
// uint32_t read_mimpid()
// {
//   int value = 0;
//   asm("csrr %0, mimpid": "=r"(value));
//   return value;
// }
// uint32_t read_mhartid()
// {
//   int value = 0;
//   asm("csrr %0, mhartid": "=r"(value));
//   return value;
// }

// uint32_t read_mstatus()
// {
//   int value = 0;
//   asm("csrr %0, mstatus": "=r"(value));
//   return value;
// }
// uint32_t read_misa()
// {
//   int value = 0;
//   asm("csrr %0, misa": "=r"(value));
//   return value;
// }
// uint32_t read_medeleg()
// {
//   int value = 0;
//   asm("csrr %0, medeleg": "=r"(value));
//   return value;
// }
// uint32_t read_mideleg()
// {
//   int value = 0;
//   asm("csrr %0, mideleg": "=r"(value));
//   return value;
// }
// uint32_t read_mie()
// {
//   int value = 0;
//   asm("csrr %0, mie": "=r"(value));
//   return value;
// }
// uint32_t read_mtvec()
// {
//   int value = 0;
//   asm("csrr %0, mtvec": "=r"(value));
//   return value;
// }
// void write_mtvec(uint32_t value)
// {
//   asm("csrw mtvec, %0": : "r"(value));
// }
// uint32_t read_mcounteren()
// {
//   int value = 0;
//   asm("csrr %0, mcounteren": "=r"(value));
//   return value;
// }
// uint32_t read_mscratch()
// {
//   int value = 0;
//   asm("csrr %0, mscratch": "=r"(value));
//   return value;
// }
// uint32_t read_mepc()
// {
//   int value = 0;
//   asm("csrr %0, mepc": "=r"(value));
//   return value;
// }
// uint32_t read_mcause()
// {
//   int value = 0;
//   asm("csrr %0, mcause": "=r"(value));
//   return value;
// }
// uint32_t read_mtval()
// {
//   int value = 0;
//   asm("csrr %0, mtval": "=r"(value));
//   return value;
// }
// uint32_t read_mip()
// {
//   int value = 0;
//   asm("csrr %0, mip": "=r"(value));
//   return value;
// }

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

int main(void) {
    uart_set_baud_rate(115200);
    uart_set_parity(0);
    uart_bus_mode(BUS_LCK);
    uart_set_stop_bits(1);
    uart_puts(banner);
    uart_puts("By: Bitglitcher\n");
    while(1);
}

// int main()
// {
//     // prints("\n\n\n\n");
//     uart_init();
//     prints(banner);
//     while(1);
    //char buffer [50];
    // sprintf(buffer, "mvendorid: 0x%08x\n", read_mvendorid());
    // prints(buffer);
    // sprintf(buffer, "marchid: 0x%08x\n", read_marchid());
    // prints(buffer);
    // sprintf(buffer, "mimpid: 0x%08x\n", read_mimpid());
    // prints(buffer);
    // sprintf(buffer, "mhartid: 0x%08x\n", read_mhartid());
    // prints(buffer);
    // sprintf(buffer, "mstatus: 0x%08x\n", read_mstatus());
    // prints(buffer);
    // sprintf(buffer, "misa: 0x%08x\n", read_misa());
    // prints(buffer);
    // sprintf(buffer, "medeleg: 0x%08x\n", read_medeleg());
    // prints(buffer);
    // sprintf(buffer, "mideleg: 0x%08x\n", read_mideleg());
    // prints(buffer);
    // sprintf(buffer, "mie: 0x%08x\n", read_mie());
    // prints(buffer);
    // sprintf(buffer, "mtvec: 0x%08x\n", read_mtvec());
    // prints(buffer);
    // sprintf(buffer, "mcounteren: 0x%08x\n", read_mcounteren());
    // prints(buffer);
    // sprintf(buffer, "mscratch: 0x%08x\n", read_mscratch());
    // prints(buffer);
    // sprintf(buffer, "mepc: 0x%08x\n", read_mepc());
    // prints(buffer);
    // sprintf(buffer, "mcause: 0x%08x\n", read_mcause());
    // prints(buffer);
    // sprintf(buffer, "mtval: 0x%08x\n", read_mtval());
    // prints(buffer);
    // sprintf(buffer, "mip: 0x%08x\n", read_mip());
    // //prints(buffer);

    // sprintf(buffer, "Illegal Instruction Execution\n");
    // prints(buffer);
    // asm(".word 0xaeaeaeae");
    // sprintf(buffer, "Return From Trap Handler\n");
    // prints(buffer);
    // sprintf(buffer, "mstatus: 0x%08x\n", read_mstatus());
    // prints(buffer);
    // sprintf(buffer, "misa: 0x%08x\n", read_misa());
    // prints(buffer);
    // sprintf(buffer, "medeleg: 0x%08x\n", read_medeleg());
    // prints(buffer);
    // sprintf(buffer, "mideleg: 0x%08x\n", read_mideleg());
    // prints(buffer);
    // sprintf(buffer, "mie: 0x%08x\n", read_mie());
    // prints(buffer);
    // sprintf(buffer, "mtvec: 0x%08x\n", read_mtvec());
    // prints(buffer);

    //prints("Hello QuantaRV!\n");
    //printn(10+23);
    //printn(10-23);
    //printn(10*23);
    //printn((10*23)/10);
    //printn(10*230);
    //prints("Fibonacci numbers!\n");
    //int i = 1;
    //int a = 0;
    //for(int x = 0;x < 1000;x++)
    //{
    //    int tmp = a;
    //    a = i + a;
    //    i = tmp;
//
    //    printn(a);
    //    prints(" ");
    //}{}
    //Setup Compare registers to some random value.
    //while (1)
    //{
    //  SPRINTF:
    //  sprintf(buffer, "TL: 0x%08x, TH: 0x%08x, CL: 0x%08x, CH: 0x%08x\n",*((uint32_t*)0x10000080), *((uint32_t*)0x10000084),
    //    *((uint32_t*)0x10000088), *((uint32_t*)0x1000008c));
    //  prints(buffer);
    //}

// }