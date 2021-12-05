#include <stdint.h>
#include "spi.h"


//Set recevier bus mode
void spi_set_rx_bm(uint8_t mode)
{
    //Read configuration register
    uint32_t conf = SPI_READ(SPI_CONFR);
    SET_RBM(conf, mode);
    //Modify BUS mode
    SPI_WRITE(SPI_CONFR, conf);
}
//Set transmitter bus mode
void spi_set_tx_bm(uint8_t mode)
{
    //Read configuration register
    uint32_t conf = SPI_READ(SPI_CONFR);
    SET_RBM(conf, mode);
    //Modify BUS mode
    SPI_WRITE(SPI_CONFR, conf);
}
//Set Chip select
inline void spi_set_cs(uint8_t cs)
{
    SPI_WRITE(SPI_CS, cs);
}
//send/receive bytes 
void spi_send_bytes(char* buffer, int32_t size, uint8_t cs)
{

}
void spi_recieve_bytes(char* buffer, int32_t size, uint8_t cs)
{

}
//
void spi_send_byte(uint8_t data, uint8_t cs)
{
    spi_set_cs(cs);
    SPI_WRITE(SPI_TXRX, data);
    return;
}
uint8_t spi_receive_byte(uint8_t data, uint8_t cs)
{
    spi_set_cs(cs);
    return SPI_READ(SPI_TXRX);
}
//
uint8_t spi_get_tx_capacity()
{
    return SPI_READ(SPI_TX_CAPACITY);
}
uint8_t spi_get_rx_capacity()
{
    return SPI_READ(SPI_RX_CAPACITY);
}
//
void spi_flush_rx_buffer()
{
    SPI_WRITE(SPI_FLUSH_RX_BUFFER, 0x00000000);
}
void spi_set_freq(uint32_t f)
{
    SPI_WRITE(SPI_DIVIDER, SPI_DIV_CAL(f));
    return;
}
void spi_set_twp(uint32_t t)
{
    SPI_WRITE(SPI_TWP, t);
    return;
}
void spi_set_cpol(uint8_t s)
{
    //Read configuration register
    uint32_t conf = SPI_READ(SPI_CONFR);
    //Modify CPOL
    SPI_WRITE(SPI_CONFR, SET_CPOL(conf, s));
}
void spi_set_cpha(uint8_t s)
{
    //Read configuration register
    uint32_t conf = SPI_READ(SPI_CONFR);
    //Modify CPHA
    SPI_WRITE(SPI_CONFR, SET_CPHA(conf, s));
}