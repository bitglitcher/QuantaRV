//Author: Benjamin Herrera Navarro
//Date: Thu Dec 2 2021
//
//Simple SPI controller for the QuantaRV SoC


module spi(
    input logic clk,
    input logic rst,

    //SPI Signals
    input logic MISO,
    output logic MOSI,
    output logic SCLK,
    output logic CS

    //WIshbone BUS
    output logic ACK,
    output logic ERR,
    output logic RTY,
    input  logic STB,
    input  logic CYC,
    input  logic WE,
    input  logic [31:0] ADR,
    input  logic [31:0] DAT_O,
    output logic [31:0] DAT_I,
    input  logic [2:0]  CTI_O
);

////////////////////////
//Memory Map
//
// ADDRRESS SIZE   DESC
// 0x0000   32bit  RD_WR  Read and Write data
// 0x0004   8bit   CONFR
// 0x0008   32bit  DIVIDER
// 0x000c   32bit  TWP    Transmission Wait Period
//
//
// CONFR Configuration Register
// 0    1    2    3    4    6    8  15
// +----+----+----+----+----+----+---+
// |CPOL|CPHA|TXQE|RXQE|TBM |RBM |XXX|
// +----+----+----+----+----+----+---+
//  CPOL - Clock Polarite/Clock IDDLE
//  CPHA - Clock Phase/Clock Shifting cycle
//  TXQE - Trasmitter Queue Enable
//  RXQE - Receiver Queue EnableE
//  TBM  - Transmitter BUS MODE
//  RBM  - Receiver BUS MODE
//  XXX  - Not used
//
//  TBM STATES
//  0x00 - Lock on FULL
//  0x01 - Error on FULL
//  0x02 - Retry on FULL 
//
//  RBM STATES
//  0x00 - Lock on Empty
//  0x01 - Error on Empty
//  0x02 - Retry on Empty
//
//

reg [15:0] conf_reg;
logic CPOL = conf_reg [0:0];
logic CPHA = conf_reg [1:1];
logic TXQE = conf_reg [2:2];
logic RXQE = conf_reg [3:3];
logic TBM  = conf_reg [4:4];
logic RBM  = conf_reg [5:5];

///////////////////////////
//        FIFO LOGIC     //
///////////////////////////

parameter buffer_depth = 8;

//RX and TX buffers
reg [7:0] tx_fifo [buffer_depth-1:0];
reg [7:0] rx_fifo [buffer_depth-1:0];

//Read and Write pointers
reg [$clog2(buffer_depth)-1:0] tx_wp = 0;
reg [$clog2(buffer_depth)-1:0] tx_rp = 0;
reg [$clog2(buffer_depth)-1:0] rx_wp = 0;
reg [$clog2(buffer_depth)-1:0] rx_rp = 0;


//Write/Read signals and data buses
logic tx_fifo_wr;
logic rx_fifo_rd;
logic [7:0] tx_fifo_wr_data;
logic [7:0] tx_fifo_rd_data;
//tx_fifo write and read
always@(negedge clk)
begin
    if(rst)
    begin
        tx_wp = 0;
        tx_rp = 0;
    end
    else
    begin
        //Write to fifo
        if(tx_fifo_wr & ((3'(tx_wp + 3'b1) != tx_rp) | tx_fifo_rd))
        begin
            tx_fifo [tx_wp] <= tx_fifo_wr_data;
            tx_wp <= tx_wp + 1;
        end
        //Read data
        if(tx_fifo_rd & (tx_rp != tx_wp))
        begin
            tx_rp <= tx_rp + 1;
        end
    end
    tx_fifo_rd_data = tx_fifo[tx_rp];
end
wire tx_full = (3'(tx_wp + 3'b1) == tx_rp);
wire tx_empty = (tx_rp == tx_wp);
logic [7:0] tx_capacity;
always_comb tx_capacity = $(unsigned(tx_wp - tx_rp));
//Read fifo
logic rx_fifo_wr;
logic rx_fifo_rd;
logic [8:0] rx_fifo_wr_data;
logic [8:0] rx_fifo_rd_data;
//rx_fifo write and read
always@(negedge clk)
begin
    //Write to fifo 
    if(rx_fifo_wr & ((3'(rx_wp + 3'b1) != rx_rp) | rx_fifo_rd))
    begin
        rx_fifo [rx_wp] <= rx_fifo_wr_data;
        rx_wp <= rx_wp + 1;
    end
    //Read data
    if(rx_fifo_rd & (rx_rp != rx_wp))
    begin
        rx_rp <= rx_rp + 1;    
    end
end


//Wishbone BUS state machine
typedef enum logic [3:0] { WB_IDDLE, CYCLE } wb_state_t;
wb_state_t wb_state = WB_IDDLE;

always@(posedge clk)
begin
    if(rst)
    begin
        wb_state = WB_IDDLE;
    end
    else
    begin
        case(wb_state)
            WB_IDDLE:
            begin
                if(CYC & STB)
                begin
                    //Write Enable
                    if(WE)
                    begin
                        case(ADR[7:0]
                            //RXTX buffer
                            8'h0000:
                            begin
                                if(!tx_full)
                                begin
                                    ERR = 1'b0;
                                    RTY = 1'b0;
                                    ACK = 1'b0;
                                    tx_fifo_wr = 1'b1;
                                    tx

                                end
                            end
                            //CONFR
                            8'h0004:
                            begin
                                
                            end
                            //DIVIDER
                            8'h000c:
                            begin
                                
                            end
                        endcase
                    end
                    //Read
                    else
                    begin

                    end
                end
            end
            CYCLE:
            begin

            end
        endcase
    end
end


/////////////////////////
//     SPI LOGIC       //
/////////////////////////

//Clock divider
reg [31:0] div;
reg [31:0] div_cnt;
//Transmission wait period
reg [31:0] twp;
reg [31:0] delay_counter;


//Shift register
reg [7:0] shift_reg; //Circular shift register

typedef enum logic [3:0] { IDDLE, DELAY, TRANSMIT } spi_states_t;
spi_states_t spi_states = IDDLE;


always@(posedge clk)
begin
    if(rst)
    begin
        spi_states = IDDLE;
    end
    else
    begin
        case(spi_states)
            IDDLE:
            begin

            end
            DELAY:
            begin
                //wait for a certain period of time before beginning next
                //operation
                if(delay_counter > twp)
                begin
                    spi_states = TRANSMIT;
                end
                else
                begin
                    delay_counter = delay_counter + 32'b1;
                    //Load data from TX Fifo

                end
            end
            TRANSMIT:
            begin
                if(div_cnt > div)
                begin

                end
            end
        endcase
    end
end

assign MOSI = shift_reg [7:7];

endmodule
