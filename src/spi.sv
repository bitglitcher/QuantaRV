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
    output logic [7:0] CS,

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
//  RXQE - Receiver Queue Enable
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

parameter BM_LCK = 0;
parameter BM_ERR = 1;
parameter BM_RTY = 2;
parameter BM_ACK = 3;

reg [15:0] conf_reg;
logic CPOL;
logic CPHA;
logic TXQE;
logic RXQE;
logic TBM;
logic RBM;
logic RQFF;

assign CPOL = conf_reg [0:0];
assign CPHA = conf_reg [1:1];
assign TXQE = conf_reg [2:2];
assign RXQE = conf_reg [3:3];
assign TBM  = conf_reg [5:4];
assign RBM  = conf_reg [7:6];
assign RQFF = conf_reg [8:8];

reg [7:0] CS_REG;

///////////////////////////
//        FIFO LOGIC     //
///////////////////////////

parameter buffer_depth = 8;

//RX and TX buffers
reg [7:0] tx_fifo [buffer_depth-1:0];
reg [7:0] rx_fifo [buffer_depth-1:0];

//Read and Write pointers
reg [$clog2(buffer_depth)-1:0] tx_wp;
reg [$clog2(buffer_depth)-1:0] tx_rp;
reg [$clog2(buffer_depth)-1:0] rx_wp;
reg [$clog2(buffer_depth)-1:0] rx_rp;


//Write/Read signals and data buses
logic tx_fifo_wr;
logic tx_fifo_rd;
logic [7:0] tx_fifo_wr_data;
logic [7:0] tx_fifo_rd_data;
//tx_fifo write and read
logic tx_full;
logic tx_empty;
always@(negedge clk)
begin
    if(rst)
    begin
        tx_wp <= 0;
        tx_rp <= 0;
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
    tx_fifo_rd_data <= tx_fifo[tx_rp];
    tx_full <= (3'(tx_wp + 3'b1) == tx_rp);
    tx_empty <= (tx_rp == tx_wp);
end
logic [7:0] tx_capacity;
always_comb tx_capacity = $unsigned(tx_wp - tx_rp);
//Read fifo
logic rx_fifo_wr;
logic rx_fifo_rd;
logic [8:0] rx_fifo_wr_data;
logic [8:0] rx_fifo_rd_data;

logic rx_flush;
logic rx_full;
logic rx_empty;
//rx_fifo write and read
always@(negedge clk)
begin
    if(rst | rx_flush)
    begin
        rx_rp <= 0;
        rx_wp <= 0;
    end
    else
    begin
        //Write to fifo 
        if(rx_fifo_wr & ((3'(rx_wp + 3'b1) != rx_rp) | rx_fifo_rd | (RQFF & rx_full & rx_fifo_wr)))
        begin
            rx_fifo [rx_wp] <= rx_fifo_wr_data;
            rx_wp <= rx_wp + 1;
        end
        //Read data
        if((rx_fifo_rd & (rx_rp != rx_wp)) | (RQFF & rx_full & rx_fifo_wr))
        begin
            rx_rp <= rx_rp + 1;    
        end
        rx_fifo_rd_data <= rx_fifo [rx_rp];
        rx_full <= (3'(rx_wp + 3'b1) == rx_rp);
        rx_empty <= (rx_rp == rx_wp);
    end
end
logic [7:0] rx_capacity;
always_comb rx_capacity = $unsigned(rx_wp - rx_rp);

//Clock divider
reg [31:0] div;
reg [31:0] div_cnt;
//Transmission wait period
reg [31:0] twp;
reg [31:0] delay_counter;

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
                rx_flush = 1'b1;
                tx_fifo_wr = 1'b0;
                rx_fifo_rd = 1'b0;
                if(CYC & STB)
                begin
                    //Write Enable
                    if(WE)
                    begin
                        case(ADR[7:0])
                            //RXTX buffer
                            8'h00:
                            begin
                                case(TBM)
                                    BM_LCK:
                                    begin
                                        if(!tx_full)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            tx_fifo_wr = 1'b1;
                                            rx_fifo_rd = 1'b0;
                                            tx_fifo_wr_data = DAT_O [7:0];
                                            wb_state = CYCLE; 
                                        end
                                        else
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b0;
                                            tx_fifo_wr = 1'b0;
                                            rx_fifo_rd = 1'b0;
                                            wb_state = WB_IDDLE;
                                        end
                                    end
                                    BM_ERR:
                                    begin
                                        if(!tx_full)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            tx_fifo_wr = 1'b1;
                                            tx_fifo_wr_data = DAT_O [7:0];
                                            wb_state = CYCLE; 
                                        end
                                        else
                                        begin
                                            ERR = 1'b1;
                                            RTY = 1'b0;
                                            ACK = 1'b0;
                                            rx_fifo_rd = 1'b0;
                                            tx_fifo_wr = 1'b0;
                                            wb_state = CYCLE;
                                        end
                                    end
                                    BM_RTY:
                                    begin 
                                        if(!tx_full)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            tx_fifo_wr = 1'b1;
                                            tx_fifo_wr_data = DAT_O [7:0];
                                            wb_state = CYCLE; 
                                        end
                                        else
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b1;
                                            ACK = 1'b0;
                                            rx_fifo_rd = 1'b0;
                                            tx_fifo_wr = 1'b0;
                                            wb_state = CYCLE;
                                        end
                                    end
                                endcase
                            end
                            //CONFR
                            8'h04:
                            begin
                                //$timeformat(-9, 2, " ps", 20);
                                //$display("WRITE t=%0t d=0x%08x",$time, DAT_O);
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                conf_reg = DAT_O [15:0];
                                wb_state = CYCLE;
                            end
                            //DIVIDER
                            8'h08:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                div = DAT_O [31:0];
                                wb_state = CYCLE;
                            end
                            //TWP
                            8'h0c:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                twp = DAT_O [31:0];
                                wb_state = CYCLE;
                            end
                            //CS
                            8'h10:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                CS_REG = DAT_O [7:0];
                                wb_state = CYCLE;
                            end
                            // 0x0014   8bit   FLUSH RX BUFFER
                            8'h14:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b0;
                                DAT_I = 32'b0;
                                rx_flush = 1'b1;
                                wb_state = CYCLE;
                            end
                            default:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = 32'b0;
                                wb_state = CYCLE; 
                            end
                        endcase
                    end
                    //Read
                    else
                    begin
                        case(ADR[7:0])
                            //RXTX buffer
                            8'h00:
                            begin
                                case(RBM)
                                    BM_LCK:
                                    begin
                                        if(!rx_empty)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            rx_fifo_rd = 1'b1;
                                            DAT_I = {24'h0, rx_fifo_rd_data};
                                            wb_state = CYCLE;
                                        end
                                        else
                                        begin
                                            rx_fifo_rd = 1'b0;
                                            tx_fifo_wr = 1'b0;
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b0;
                                            wb_state = WB_IDDLE;
                                        end
                                    end
                                    BM_ERR:
                                    begin
                                        if(!rx_empty)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            rx_fifo_rd = 1'b1;
                                            DAT_I = {24'h0, rx_fifo_rd_data};
                                            wb_state = CYCLE;
                                        end
                                        else
                                        begin
                                            ERR = 1'b1;
                                            RTY = 1'b0;
                                            ACK = 1'b0;
                                            rx_fifo_rd = 1'b0;
                                        end
                                    end
                                    BM_RTY:
                                    begin 
                                        if(!rx_empty)
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b0;
                                            ACK = 1'b1;
                                            rx_fifo_rd = 1'b1;
                                            DAT_I = {24'h0, rx_fifo_rd_data};
                                            wb_state = CYCLE;
                                        end
                                        else
                                        begin
                                            ERR = 1'b0;
                                            RTY = 1'b1;
                                            ACK = 1'b0;
                                            rx_fifo_rd = 1'b0;
                                        end
                                    end
                                endcase
                            end
                            //CONFR
                            8'h04:
                            begin
                                //$display("READ %0t",$time);
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = {16'b0, conf_reg};
                                wb_state = CYCLE;
                            end
                            //DIVIDER
                            8'h08:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = div;
                                wb_state = CYCLE;
                            end
                            //TWP
                            8'h0c:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = twp;
                                wb_state = CYCLE;
                            end
                            //CS
                            8'h10:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = {24'b0, CS_REG [7:0]};
                                wb_state = CYCLE;
                            end
                            // 0x0018   8bit   RX Capacity
                            8'h18:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = {24'b0, rx_capacity [7:0]};
                                wb_state = CYCLE;
                            end                            
                            // 0x001c   8bit   TX Capacity
                            8'h1c:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = {24'b0, tx_capacity [7:0]};
                                wb_state = CYCLE;
                            end
                            default:
                            begin
                                ERR = 1'b0;
                                RTY = 1'b0;
                                ACK = 1'b1;
                                DAT_I = 32'b0;
                                wb_state = CYCLE;
                            end
                        endcase
                    end
                end
            end
            CYCLE:
            begin
                ERR = 1'b0;
                RTY = 1'b0;
                ACK = 1'b0;
                rx_flush = 1'b0;
                tx_fifo_wr = 1'b0;
                rx_fifo_rd = 1'b0;
                wb_state = WB_IDDLE;
            end
            default:
            begin
                rx_flush = 1'b0;
                ERR = 1'b0;
                RTY = 1'b0;
                ACK = 1'b0;
                wb_state = WB_IDDLE;
            end
        endcase
    end
end


/////////////////////////
//     SPI LOGIC       //
/////////////////////////

//0 - First edge | 1 - Second edge
reg edge_cnt = 0;

//Shift register
reg [7:0] shift_reg = 0; //Circular shift register

typedef enum logic [3:0] { IDDLE, DELAY, TRANSMIT } spi_states_t;
spi_states_t spi_state = IDDLE;

reg [3:0] bit_count = 0;

always@(posedge clk)
begin
    if(rst)
    begin
        spi_state <= IDDLE;
    end
    else
    begin
        case(spi_state)
            IDDLE:
            begin
                if(!tx_empty)
                begin
                    tx_fifo_rd <= 1'b1;
                    shift_reg <= tx_fifo_rd_data;
                    spi_state <= DELAY;
                end
                else
                begin
                    tx_fifo_rd <= 1'b0;
                    shift_reg <= shift_reg; 
                end
                SCLK <= CPOL;
                delay_counter = 0;
            end
            DELAY:
            begin
                tx_fifo_rd <= 1'b0;
                //wait for a certain period of time before beginning next
                //operation
                if(delay_counter > twp)
                begin
                    spi_state <= TRANSMIT;
                end
                else
                begin
                    delay_counter <= delay_counter + 32'b1;
                end
                //Setup SCLK
                SCLK <= CPOL;
                edge_cnt <= 0;
                bit_count = 0;
                div_cnt = 0;
            end
            TRANSMIT:
            begin
                tx_fifo_rd <= 1'b0;
                if(div_cnt > div)
                begin
                    if(bit_count < 8)
                    begin
                        edge_cnt = ~edge_cnt;
                        SCLK = ~SCLK;
                        div_cnt = 0;
                        if(CPHA & edge_cnt)
                        begin
                            shift_reg <= {shift_reg, MISO};
                            bit_count <= bit_count + 1;
                        end
                        else if(~CPHA & ~edge_cnt)
                        begin
                            shift_reg <= {shift_reg, MISO};
                            bit_count <= bit_count + 1;
                        end
                        else
                        begin
                            shift_reg <= shift_reg;
                        end
                    end
                    else
                    begin
                        spi_state <= IDDLE;
                    end
                end
                else
                begin
                    div_cnt <= div_cnt + 1; 
                end
            end
            default:
            begin
                spi_state <= IDDLE;
            end
        endcase
    end
end

assign MOSI = shift_reg [7:7];
assign CS = CS_REG;

initial begin
    ACK = 0;
    RTY = 0;
    ERR = 0;
    conf_reg = 0;
    div_cnt = 0;
    bit_count = 0;
    tx_wp = 0;
    tx_rp = 0;
    rx_wp = 0;
    rx_rp = 0;
end


endmodule
