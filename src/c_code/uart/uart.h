#ifndef __UART_H__
#define __UART_H__

//Author: Benjamin Herrera Navarro
//Date: Sat Nov 27 8:07PM

#include <stdint.h>
#include <stdbool.h>

//Internal Memory Map
// 0x0000 - READ/WRITE
// 0x0004 - Baud rate divisor
// 0x0008 - Status/Control register
//
// ADDRESS LENGHT DESC
// 0x0000  32bit  READ/WRITE TX/RX
// 0x0004  32bit  Baud rate divisor
// 0x0008  8bit   Control Register
// 0x000c  8bit   RX Buffer Capacity
// 0x0010  8bit   TX Buffer Capacity
// 0x0014  8bit   Transfer Size
// 0x0018  8bit   Stop Bits
//
// 0x0008  8bit   Control Register
// +----+----+----+----+----+----+----+----+
// | TE | TF | RE | RF | PB | XX |    BB   |
// +----+----+----+----+----+----+----+----+
// TE - Transmitter Buffer Empty
// TF - Transmitter Buffer Full
// RE - Receiver Buffer Empty
// RF - Receiver Buffer Full
// PE - Paratiry Bit Enable
// XX - Not used/Future IRQ Enable signal
// BB - Bus Behavior  - Lock/Error/Retry/ack

//BB states
//0x00 Lock - Full or empty the uart will delay the ACK signal
//0x01 Error - Full or empty the uart will return retry
//0x02 Retry - Full or empty the uart will return error
//0x03 Ack - Full or empty the uart will return 0 on the bus
#define FREQUENCY 25000000
#define UART_BASE 0x1100

#define TXRX          0x00
#define DIVISOR       0x04
#define CONTROL_REG   0x08
#define RX_CAPACITY   0x0c
#define TX_CAPACITY   0x10
#define TRANSFER_SIZE 0x14
#define STOP_BITS     0x18


#define BUS_LCK 0x00
#define BUS_ERR 0x01
#define BUS_RTY 0x02
#define BUS_IGN 0x03

//Macros to help extract the bits from the control register
#define CR_TE(data) ((data >> 0x0) & 0x1)
#define CR_TF(data) ((data >> 0x1) & 0x1)
#define CR_RE(data) ((data >> 0x2) & 0x1)
#define CR_RF(data) ((data >> 0x3) & 0x1)
#define CR_PE(data) ((data >> 0x4) & 0x1)
#define CR_BB(data) ((data >> 0x6) & 0b11)

//To help set the bits
#define BIT_TE(data, mode) ((!(((uint8_t)0x1) << 0x0) & data) | (mode << 0x0))
#define BIT_TF(data, mode) ((!(((uint8_t)0x1) << 0x1) & data) | (mode << 0x1))
#define BIT_RE(data, mode) ((!(((uint8_t)0x1) << 0x2) & data) | (mode << 0x2))
#define BIT_RF(data, mode) ((!(((uint8_t)0x1) << 0x3) & data) | (mode << 0x3))
#define BIT_PE(data, mode) ((!(((uint8_t)0x1) << 0x4) & data) | (mode << 0x4))
#define BIT_BB(data, mode) ((!(((uint8_t)0b11) << 0x6) & data) | (mode << 0x6))

#define UART_WRITE(offset, data) *((uint32_t*)(UART_BASE + offset)) = data
#define UART_READ(offset) *((uint32_t*)(UART_BASE + offset))

#define DIVISOR_CALC(baud) (FREQUENCY/baud)

void uart_putc(char c);
void uart_puts(char* s);
uint8_t uart_getc_blocking();
void uart_putc_blocking(char c);
void uart_bus_mode(int mode);
void uart_set_parity(bool mode);
uint8_t uart_n_rx_bytes();
uint8_t uart_n_tx_bytes();
bool uart_tx_empty();
bool uart_tx_full();
bool uart_rx_empty();
bool uart_rx_full();
void uart_set_baud_rate(uint32_t baud);
void uart_set_stop_bits(uint32_t bits);

#endif