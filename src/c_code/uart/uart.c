
#include "uart.h"

//Author: Benjamin Herrera Navarro
//Date: Sat Nov 27 8:07PM


void uart_putc(char c)
{
    UART_WRITE(TXRX, c);
}
void uart_puts(char* s)
{
    char* cpy = s;
    while(*cpy)
    {
        UART_WRITE(TXRX, *cpy);
        cpy = cpy + 1;
    }
}
uint8_t uart_getc_blocking()
{
    uint8_t old_bb_state = UART_READ(CONTROL_REG);
    UART_WRITE(CONTROL_REG, BIT_BB(UART_READ(CONTROL_REG), BUS_LCK));
    uint8_t data = UART_READ(TXRX);
    UART_WRITE(CONTROL_REG, old_bb_state);
    return data;
}
void uart_putc_blocking(char c)
{
    uint8_t old_bb_state = UART_READ(CONTROL_REG);
    UART_WRITE(CONTROL_REG, BIT_BB(UART_READ(CONTROL_REG), BUS_LCK));
    UART_WRITE(TXRX, c);
    UART_WRITE(CONTROL_REG, old_bb_state);
}
void uart_bus_mode(int mode)
{
    UART_WRITE(CONTROL_REG, BIT_BB(UART_READ(CONTROL_REG), mode));
}
void uart_set_parity(bool mode)
{
    UART_WRITE(CONTROL_REG, BIT_PE(UART_READ(CONTROL_REG), mode));
}
uint8_t uart_nrx_bytes()
{
    return UART_READ(RX_CAPACITY);
}
uint8_t uart_ntx_bytes()
{
    return UART_READ(TX_CAPACITY);
}
bool uart_tx_empty()
{
    return CR_TE(UART_READ(CONTROL_REG));
}
bool uart_tx_full()
{
    return CR_TF(UART_READ(CONTROL_REG));
}
bool uart_rx_empty()
{
    return CR_RE(UART_READ(CONTROL_REG));
}
bool uart_rx_full()
{
    return CR_RF(UART_READ(CONTROL_REG));
}
void uart_set_baud_rate(uint32_t baud)
{
    UART_WRITE(DIVISOR, DIVISOR_CALC(baud));
}
void uart_set_stop_bits(uint32_t bits)
{
    UART_WRITE(STOP_BITS, bits);
}