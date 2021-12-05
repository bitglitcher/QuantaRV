//Date: Sun Dec 5 7:43AM

#ifndef __SPI_H__
#define __SPI_H__

#include <stdint.h>

////////////////////////
//     Memory Map
//
// ADDRRESS SIZE   DESC
// 0x0000   32bit  RD_WR  Read and Write data
// 0x0004   8bit   CONFR
// 0x0008   32bit  DIVIDER
// 0x000c   32bit  TWP    Transmission Wait Period
// 0x0010   8bit   CS     Chip Select
// 0x0014   8bit   FLUSH RX BUFFER
// 0x0018   8bit   RX Capacity
// 0x001c   8bit   TX Capacity
//
//
// CONFR Configuration Register
// 0    1    2    3    4    6    8    9  15
// +----+----+----+----+----+----+----+---+
// |CPOL|CPHA|TXQE|RXQE|TBM |RBM |RQFF|XXX|
// +----+----+----+----+----+----+----+---+
//  CPOL - Clock Polarite/Clock IDDLE
//  CPHA - Clock Phase/Clock Shifting cycle
//  TXQE - Trasmitter Queue Enable
//  RXQE - Receiver Queue EnableE
//  TBM  - Transmitter BUS MODE
//  RBM  - Receiver BUS MODE
//  RQFF - Recevier Queue Flush First
//  XXX  - Not used
//
//  TBM STATES
//  0x00 - Lock on FULL
//  0x01 - Error on FULL
//  0x02 - Retry on FULL 
//  0x03 - ACK on FULL 
//
//  RBM STATES
//  0x00 - Lock on Empty
//  0x01 - Error on Empty
//  0x02 - Retry on Empty
//  0x03 - ACK on Empty
//
// When the RQFF bit is active, the RX Queue wont be filled and it will discard the first entry 
// RQFL - Recevier Queue Flush First
#define SPI_BASE 0x00001000
//Frequency at which the core is running
#define SPI_FREQ 25000000

//Helper macro to calculate the divider value
#define SPI_DIV_CAL(tF) SPI_FREQ/tF

#define SPI_WRITE(offset, data) *((uint32_t*)(SPI_BASE + offset)) = data
#define SPI_READ(offset) *((uint32_t*)(SPI_BASE + offset))

#define SPI_BUS_MODE_LCK 0x0
#define SPI_BUS_MODE_ERR 0x1
#define SPI_BUS_MODE_RTY 0x2
#define SPI_BUS_MODE_ACK 0x3

#define SPI_TXRX            0x0000
#define SPI_CONFR           0x0004
#define SPI_DIVIDER         0x0008
#define SPI_TWP             0x000c
#define SPI_CS              0x0010
#define SPI_FLUSH_RX_BUFFER 0x0014
#define SPI_RX_CAPACITY     0x0018
#define SPI_TX_CAPACITY     0x001c

#define GET_CPOL(data) ((data >> 0) & 0b01)
#define GET_CPHA(data) ((data >> 1) & 0b01)
#define GET_TXQE(data) ((data >> 2) & 0b01)
#define GET_RXQE(data) ((data >> 3) & 0b01)
#define GET_TBM(data) ((data >> 4) & 0b11)
#define GET_RBM(data) ((data >> 6) & 0b11)
#define GET_RQFF(data) ((data >> 8) & 0b01)

#define SET_CPOL(d1, d2) ((d1 & ~((uint32_t)(0b01 << 0))) | ((d2 & 0b01) << 0))
#define SET_CPHA(d1, d2) ((d1 & ~((uint32_t)(0b01 << 1))) | ((d2 & 0b01) << 1))
#define SET_TXQE(d1, d2) ((d1 & ~((uint32_t)(0b01 << 2))) | ((d2 & 0b01) << 2))
#define SET_RXQE(d1, d2) ((d1 & ~((uint32_t)(0b01 << 3))) | ((d2 & 0b01) << 3))
#define SET_TBM(d1, d2) ((d1 & ~((uint32_t)(0b11 << 4))) | ((d2 & 0b11) << 4))
#define SET_RBM(d1, d2) ((d1 & ~((uint32_t)(0b11 << 6))) | ((d2 & 0b11) << 6))
#define SET_RQFF(d1, d2) ((d1 & ~((uint32_t)(0b01 << 8))) | ((d2 & 0b01) << 8))


//Set recevier bus mode
void spi_set_rx_bm(uint8_t mode);
//Set transmitter bus mode
void spi_set_tx_bm(uint8_t mode);
//Set Chip select
void spi_set_cs(uint8_t cs);
//send/receive bytes 
void spi_send_bytes(char* buffer, int32_t size, uint8_t cs);
void spi_recieve_bytes(char* buffer, int32_t size, uint8_t cs);
//
void spi_send_byte(uint8_t data, uint8_t cs);
uint8_t spi_receive_byte(uint8_t data, uint8_t cs);
//
uint8_t spi_get_tx_capacity();
uint8_t spi_get_rx_capacity();
//
void spi_flush_rx_buffer();
void spi_set_freq(uint32_t f);
void spi_set_twp(uint32_t t);
void spi_set_cpol(uint8_t s);
void spi_set_cpha(uint8_t s);



#endif