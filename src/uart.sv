//Author: Benjamin Herrera Navarro
//Date: Fri Nov 26 6:43 PM


module uart
(
    //Sys Con
    input clk,
    input rst,

    //Wishbone interface
    output logic ACK,
    output logic ERR,
    output logic RTY,
    input logic STB,
    input logic CYC,
    input logic [31:0] ADR,
    output logic [31:0] DAT_I,
    input logic [31:0] DAT_O,
    input logic [2:0]  CTI_O,
    input logic WE,

    //Uart signals
    output logic tx,
    input logic rx
);

//Change     if(rx_fifo_wr & ((3'(rx_wp + 3'b1) != rx_rp) | rx_fifo_rd))
//Manually if buffer depth is changed
parameter buffer_depth = 8;

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
// XX - Not used
// BB - Bus Behavior  - Lock/Error/Retry/ack

//BB states
//0x00 Lock - Full or empty the uart will delay the ACK signal
//0x01 Error - Full or empty the uart will return retry
//0x02 Retry - Full or empty the uart will return error
//0x03 Ack - Full or empty the uart will return 0 on the bus

parameter BB_LOCK = 0;
parameter BB_ERROR = 1;
parameter BB_RETRY = 2;
parameter BB_ACK = 3;

reg [7:0] control_register;

wire [7:0] control_register_read;
assign control_register_read = {
    control_register [7:6],
    1'b0,
    control_register[4:4],
    rx_full,
    rx_empty,
    tx_full,
    tx_empty
};

wire BB_state = control_register [7:6];
wire PE_state = control_register [4:4];


reg [31:0] divisor; 

///////////////////////////
//         FIFO LOGIC    //
///////////////////////////


//RX and TX buffers

reg [7:0] tx_fifo [buffer_depth-1:0];
reg [8:0] rx_fifo [buffer_depth-1:0]; //This one is 9bits to allow the parity bit

//Read and write pointers
reg [$clog2(buffer_depth)-1:0] tx_wp = 0;
reg [$clog2(buffer_depth)-1:0] tx_rp = 0;
reg [$clog2(buffer_depth)-1:0] rx_wp = 0;
reg [$clog2(buffer_depth)-1:0] rx_rp = 0;


logic tx_fifo_wr;
logic tx_fifo_rd;
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
end
assign tx_fifo_rd_data = tx_fifo[tx_rp];
wire tx_full = (3'(tx_wp + 3'b1) == tx_rp);
wire tx_empty = (tx_rp == tx_wp);
logic [7:0] tx_capacity;
always_comb  tx_capacity = $unsigned(tx_wp - tx_rp);
//Read fifo
logic rx_fifo_wr;
logic rx_fifo_rd;
logic [8:0] rx_fifo_wr_data;
logic [8:0] rx_fifo_rd_data;
//rx_fifo write and read
always@(negedge clk)
begin
    if(rst)
    begin
        rx_wp = 0;
        rx_rp = 0;
    end
    else
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
end
assign rx_fifo_rd_data = rx_fifo[rx_rp];
wire rx_full = (3'(rx_wp + 3'b1) == rx_rp);
wire rx_empty = (rx_rp == rx_wp);
logic [7:0] rx_capacity;
assign rx_capacity = $unsigned(rx_wp - rx_rp);

//Stop bits
reg [7:0] stop_bits;

typedef enum logic [3:0] { WB_IDDLE, CYCLE } wb_state_t;

wb_state_t wb_state = WB_IDDLE;

always@(posedge clk)
begin
    case(wb_state)
        WB_IDDLE:
        begin
            rx_fifo_rd = 1'b0;
            tx_fifo_wr = 1'b0;
            if(CYC & STB)
            begin
                //Address decoder
                if(WE) //Write
                begin
                    case(ADR [7:0])
                        // 0x0000  32bit  READ/WRITE TX/RX
                        8'h00: 
                        begin
                            //Bus behavior
                            unique case(BB_state)
                                BB_LOCK:
                                begin
                                    //If the tx buffer is full then wait until it's not full
                                    if(!tx_full)
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        tx_fifo_wr_data = DAT_O [7:0];
                                        tx_fifo_wr = 1'b1;
                                    end
                                end
                                BB_ERROR:
                                begin
                                    if(tx_full)
                                    begin
                                        ACK = 1'b0;
                                        ERR = 1'b1;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                    end
                                end
                                BB_RETRY:
                                begin
                                    if(tx_full)
                                    begin
                                        ACK = 1'b0;
                                        ERR = 1'b0;
                                        RTY = 1'b1;
                                        wb_state = CYCLE;
                                    end
                                end
                                BB_ACK: //Basically it will ignore if its full
                                begin                                    
                                    if(!tx_full)
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                    end
                                    else
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        tx_fifo_wr_data = DAT_O [7:0];
                                        tx_fifo_wr = 1'b1;     
                                    end
                                end
                            endcase
                        end
                        // 0x0004  32bit  Baud rate divisor
                        8'h04: 
                        begin
                            divisor = DAT_O;
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end
                        // 0x0008  8bit   Control Register
                        8'h08: 
                        begin
                            // 0x0008  8bit   Control Register
                            // +----+----+----+----+----+----+----+----+
                            // | TE | TF | RE | RF | PB | XX |    BB   |
                            // +----+----+----+----+----+----+----+----+
                            // TE - Transmitter Buffer Empty
                            // TF - Transmitter Buffer Full
                            // RE - Receiver Buffer Empty
                            // RF - Receiver Buffer Full
                            // PE - Paratiry Bit Enable
                            // XX - Not used
                            // BB - Bus Behavior  - Lock/Error/Retry/ack
                            control_register [4:4] = DAT_O [4:4];
                            control_register [7:6] = DAT_O [7:6];
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end
                        // 0x000c  8bit   RX Buffer Capacity
                        8'h0c:
                        begin
                            //rx_capacity = DAT_O [7:0]; //Cant write to these, so ignore
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end 
                        // 0x0010  8bit   TX Buffer Capacity
                        8'h10: 
                        begin
                            //tx_capacity = DAT_O [7:0]; //Cant write to these, so ignore
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end
                        // 0x0014  8bit   Transfer Size
                        8'h14:
                        begin
                            //Not implemented
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end 
                        // 0x0018  8bit   Stop Bits
                        8'h18:
                        begin
                            stop_bits = DAT_O [7:0];
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end
                        default:
                        begin
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end 
                    endcase
                    end
                else //Read
                begin
                    case(ADR [7:0])
                        //Read from RX Buffer
                        8'h00: 
                        begin
                            //Bus behavior
                            unique case(BB_state)
                                BB_LOCK:
                                begin
                                    //If the tx buffer is full then wait until it's not full
                                    if(!rx_empty)
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        DAT_I = {23'b0, rx_fifo_rd_data};
                                        rx_fifo_rd = 1'b1;
                                    end
                                end
                                BB_ERROR:
                                begin
                                    if(rx_empty)
                                    begin
                                        ACK = 1'b0;
                                        ERR = 1'b1;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        DAT_I = 32'b0;
                                    end
                                end
                                BB_RETRY:
                                begin
                                    if(rx_empty)
                                    begin
                                        ACK = 1'b0;
                                        ERR = 1'b0;
                                        RTY = 1'b1;
                                        wb_state = CYCLE;
                                        DAT_I = 32'b0;
                                    end
                                end
                                BB_ACK: //Basically it will ignore if its full
                                begin                                    
                                    if(!rx_empty)
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        DAT_I = 32'b0;
                                    end
                                    else
                                    begin
                                        ACK = 1'b1;
                                        ERR = 1'b0;
                                        RTY = 1'b0;
                                        wb_state = CYCLE;
                                        DAT_I = {23'b0, rx_fifo_rd_data};
                                        rx_fifo_rd = 1'b1;
                                    end
                                end
                            endcase
                        end
                        8'h04: 
                        begin
                            DAT_I = divisor;
                            wb_state = CYCLE;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                        end
                        8'h08: 
                        begin
                            DAT_I = {24'b0, control_register_read};
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end
                        8'h0c: 
                        begin
                            DAT_I = {24'b0, rx_capacity};
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end
                        8'h10:
                        begin
                            DAT_I = {24'b0, tx_capacity};
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end 
                        8'h14:
                        begin
                            DAT_I = 32'h8; //The device has a fixed transfer bit size of 8
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end 
                        8'h18:
                        begin
                            DAT_I = stop_bits;
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end 
                        default:
                        begin
                            ACK = 1'b1;
                            ERR = 1'b0;
                            RTY = 1'b0;
                            wb_state = CYCLE;
                        end
                    endcase                   
                end
            end
        end
        CYCLE:
        begin
            ACK = 1'b0;
            ERR = 1'b0;
            rx_fifo_rd = 1'b0;
            tx_fifo_wr = 1'b0;
            RTY = 1'b0;
            wb_state = WB_IDDLE;  
        end
        default: wb_state = WB_IDDLE;
    endcase
end



typedef enum logic [3:0] { IDDLE, START, TRANSFER, PARITY, STOP } states_t;

states_t state_tx = IDDLE;
states_t state_rx = IDDLE;

reg [31:0] tx_counter;
reg [31:0] rx_counter;
reg [7:0] tx_bit_counter;
reg [7:0] rx_bit_counter;
reg [7:0] tx_shift_reg;
reg [8:0] rx_shift_reg;
reg [7:0] tx_data;


always@(posedge clk)
begin
    //Transmitter logic
    if(rst)
    begin
        state_tx = IDDLE;
    end
    else                       
    begin
        case(state_tx)
            IDDLE:
            begin
                if(!tx_empty)
                begin
                    state_tx = START;
                    tx_fifo_rd = 1'b1;
                    tx_shift_reg = tx_fifo_rd_data;
                    tx_data = tx_fifo_rd_data;
                    $write("%c", tx_fifo_rd_data);
		    $fflush();
                end
            end
            START:
            begin
                tx_fifo_rd = 1'b0;
                tx = 1'b0;
                if(divisor > tx_counter)
                begin
                    //Keep incrementing tx_counter until its bigger than divisor
                    tx_counter = tx_counter + 1;
                end
                else
                begin
                    state_tx = TRANSFER;
                    tx_counter = 32'b0;    
                    tx_bit_counter = 0;
                end
            end
            TRANSFER:
            begin
                tx_fifo_rd = 1'b0;
                if(divisor > tx_counter)
                begin
                    tx_counter = tx_counter + 1;
                    tx = tx_shift_reg [0:0];
                end
                else
                begin
                    if(tx_bit_counter <= 7)
                    begin
                        tx_shift_reg = {1'b0, tx_shift_reg [7:1]};
                        tx_bit_counter = tx_bit_counter + 1;
                        state_tx = TRANSFER;
                        tx_counter = 32'b0;    
                    end
                    else
                    begin
                        tx_bit_counter = 0;
                        tx_counter = 32'b0;    
                        state_tx = PARITY; 
                    end
                end
            end
            PARITY:
            begin
                if(PE_state)
                begin
                    tx_fifo_rd = 1'b0;
                    //Calculate parity
                    tx = ~^tx_data;
                    if(divisor > tx_counter)
                    begin
                        //Keep incrementing tx_counter until its bigger than divisor
                        tx_counter = tx_counter + 1;
                    end
                    else
                    begin
                        state_tx = STOP;
                        tx_counter = 32'b0;    
                        tx_bit_counter = 0;
                    end
                end
                else
                begin
                    state_tx = STOP;
                    tx_counter = 32'b0;    
                    tx_bit_counter = 0;
                    tx = 0;
                end
            end
            STOP:
            begin
                tx_fifo_rd = 1'b0;
                tx = 1'b1;
                if(stop_bits != 0)
                begin
                    if(divisor > tx_counter)
                    begin
                        tx_counter = tx_counter + 1;
                    end
                    else
                    begin
                        if(tx_bit_counter < stop_bits)
                        begin
                            tx_bit_counter = tx_bit_counter + 1;
                            state_tx = STOP;
                            tx_counter = 32'b0;    
                        end
                        else
                        begin
                            tx_bit_counter = 0;
                            tx_counter = 32'b0;    
                            state_tx = IDDLE; 
                        end
                    end
                end
                else
                begin
                    state_tx = IDDLE;
                end
            end
            default:
            begin
                state_tx = IDDLE;
            end
        endcase
    end
end

//Receiver logic
always@(posedge clk)
begin
    if(rst)
    begin
        state_rx = IDDLE;
    end
    else
    begin
        case(state_rx)
        IDDLE:
        begin
            rx_fifo_wr = 1'b0;
            rx_shift_reg = 0;
            rx_counter = 0;
            if(~rx)
            begin
                state_rx = START;
                rx_fifo_wr = 1'b0;
                rx_counter = 0;
            end
        end
        START:
        begin
            rx_shift_reg = rx_shift_reg;
            if(divisor > rx_counter)
            begin
                rx_counter = rx_counter + 1;
            end
            else
            begin
                state_rx = TRANSFER;
                rx_counter = 0;
                rx_bit_counter = 0;
            end
        end
        TRANSFER:
        begin
            if(divisor > rx_counter)
            begin
                //Sample the rx signal
                if((divisor >> 1) == rx_counter)
                begin
                    rx_shift_reg = {rx, rx_shift_reg [8:1]};
                end
                rx_counter = rx_counter + 1;
            end
            else
            begin
                rx_shift_reg = rx_shift_reg;
                if(rx_bit_counter <= 7)
                begin
                    rx_bit_counter = rx_bit_counter + 1;
                    state_rx = TRANSFER;
                    rx_counter = 0;
                end
                else
                begin
                    state_rx = PARITY;
                    rx_bit_counter = 0;
                    rx_counter = 0;
                end
            end
        end
        PARITY:
        begin
            if(PE_state)
            begin
                if(divisor > rx_counter)
                begin
                    //Sample the rx signal
                    if((divisor >> 1) == rx_counter)
                    begin
                        rx_shift_reg = {rx, rx_shift_reg [8:1]};
                    end
                    rx_counter = rx_counter + 1;
                end
                else
                begin
                    state_rx = STOP;
                    rx_bit_counter = 0;
                    rx_shift_reg = rx_shift_reg;
                    rx_counter = 0;
                end
            end
            else
            begin
                state_rx = STOP;
                rx_bit_counter = 0;
                rx_shift_reg = rx_shift_reg;
                rx_counter = 0;
            end
        end
        STOP:
        begin
            rx_shift_reg = rx_shift_reg;
            if(stop_bits == 0)
            begin
                rx_fifo_wr_data = rx_shift_reg;
                rx_fifo_wr = 1'b1;
                state_rx = IDDLE;
                rx_bit_counter = 0;
                rx_counter = 0;
            end
            else
            begin
                if(divisor > rx_counter)
                begin
                    rx_counter = rx_counter + 1;
                end
                else
                begin
                    //Sample the rx signal
                    if(rx_bit_counter >= stop_bits)
                    begin
                        rx_fifo_wr_data = rx_shift_reg;
                        rx_fifo_wr = 1'b1;
                        state_rx = IDDLE;
                        rx_bit_counter = 0;
                        rx_counter = 0;
                    end
                    else
                    begin
                        rx_bit_counter = rx_bit_counter + 1;
                        state_rx = STOP;
                        rx_counter = 0;
                    end
                end                
            end
        end
        default:
        begin
            state_rx = IDDLE;
            rx_bit_counter = 0;
            rx_counter = 0;
        end
        endcase
    end
end

reg [7:0] [7:0] txbytes;
assign txbytes [0] = tx_fifo [0];
assign txbytes [1] = tx_fifo [1];
assign txbytes [2] = tx_fifo [2];
assign txbytes [3] = tx_fifo [3];
assign txbytes [4] = tx_fifo [4];
assign txbytes [5] = tx_fifo [5];
assign txbytes [6] = tx_fifo [6];
assign txbytes [7] = tx_fifo [7];
reg [8:0] [7:0] rxbytes;
assign rxbytes [0] = rx_fifo [0];
assign rxbytes [1] = rx_fifo [1];
assign rxbytes [2] = rx_fifo [2];
assign rxbytes [3] = rx_fifo [3];
assign rxbytes [4] = rx_fifo [4];
assign rxbytes [5] = rx_fifo [5];
assign rxbytes [6] = rx_fifo [6];
assign rxbytes [7] = rx_fifo [7];
initial begin
    ACK = 0;
    ERR = 0;
    RTY = 0;
    DAT_I = 0;
    divisor = 0;
    tx = 1;
    rx_counter = 0;
    tx_counter = 0;
    for(int i = 0; i < buffer_depth;i++)
    begin
        tx_fifo [i] = 0;
        rx_fifo [i] = 0;
    end
    //tx_fifo_rd_data = 0;
    //rx_fifo_rd_data = 0;
    tx_fifo_wr_data = 0;
    rx_fifo_wr_data = 0;
    rx_bit_counter = 0;
    tx_bit_counter = 0;
    rx_shift_reg = 0;
    tx_shift_reg = 0;
    tx_data = 0;
    control_register = 0;
    stop_bits = 0;
    rx_rp = 0;
    tx_rp = 0;
    tx_fifo_wr = 0;
    tx_fifo_rd = 0;
    rx_fifo_wr = 0;
    rx_fifo_rd = 0;
end


endmodule
