#ifndef __MEMORY_H__
#define __MEMORY_H__

////////////////////////////
//        MEMORY MAP      //
////////////////////////////
//  ADDRESS         DEVICE
//  0x0000-0x0fff   OnChipRAM
//  0x1000-0x10ff   SPI
//  0x1100-0x11ff   UART
//  0x1200-0x12ff   Timer
//  0x1300-0x13ff   GPIO
//  0x1400-0xXXXX   SDRAM

#define OCR_BASE   0x00000000
#define SPI_BASE   0x00001000
#define UART_BASE  0x00001100
#define TIMER_BASE 0x00001200
#define GPIO_BASE  0x00001300
#define SDRAM_BASE 0x00001400

//SDRAM 0xEBFF or ~60KB
#define SDRAM_END  0x0000ffff
//OnChipRAM 0xfff or 4KB
#define OCR_END 0x00000fff
#endif
