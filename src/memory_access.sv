//Author: Benjamin Herrera Navarro 
//Sun, Jun, 13 
//8:42AM

import global_pkg::*;

module memory_access
(
    //Syscon
    input logic clk,
    input logic rst,

    //Control signals
    input  memory_operation_t memory_operation,
    input  logic cyc,
    output logic ack,
    output logic err, //This signal tells the control unit that there was an error.
    output logic data_valid, //This is needed for the load instruction
    input  logic [2:0] funct3,

    //Data
    input  logic [31:0] store_data,
    input  logic [31:0] address,
    output logic [31:0] load_data,

    //Wishbone interface
    //WB4.master data_bus There is not support for interfaces in icarus

    //Wishbone interface
    input  logic        ACK,
    input  logic        ERR,
    input  logic        RTY,
    output logic        STB,
    output logic        CYC,
    output logic [31:0] ADR,
    input  logic [31:0] DAT_I,
    output logic [31:0] DAT_O,
    output logic [2:0]  CTI_O,
    output logic WE

);

////Signed and unsigned new data buses
//wire [31:0] ALIGNED_BYTE = 32'(signed'(aligned_data [7:0]));
//wire [31:0] ALIGNED_U_BYTE = {24'h0, aligned_data [7:0]};
//wire [31:0] ALIGNED_HALF_WORD = 32'(signed'(aligned_data [15:0]));
//wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, aligned_data [15:0]};
//wire [31:0] ALIGNED_WORD_BUS = aligned_data;


//typedef enum logic[3:0] { IDDLE,  } name;

//The way that this memory access unit works is by using a 64bit shift register
//and shifting values to align data. For a 32bit unaligned data access, it would have to load
//the block of data which constains higher bits of the data into the first half of the shift register.
//To save LUTs, the shift register will only allow the first half to be writable, to store data into 
//the upper half the data will have to be first rotated left.

//Move data into upper half
//     B         A                        B         A
//+---------+---------+              +---------+---------+
//|         | A B C D | ---rotate--> | A B C D |         | 
//+---------+---------+              +---------+---------+

//Comming back to the load unaligned 32bit data example. To load the two blocks of data required to align the data.
//First the block containing the MSB must be loaded. and then shifted
//     B         A                        B         A
//+---------+---------+              +---------+---------+
//|         | C A F E | ---rotate--> | C A F E |         | 
//+---------+---------+              +---------+---------+

//After that, the block of data containing the LSB should be loaded.
//     B         A     
//  7 6 5 4   3 2 1 0  
//+---------+---------+ 
//| C A F E | B E E F |  
//+---------+---------+ 

//If the data that we want to load is in address 0x2, then the address of the required bytes would be
//0x2, 0x3, 0x4, and, 0x5 or data 0xFEBE. There were limitations on how data was loaded into the shift register, the same limitations
//Apply to read data from the shift register. Meaning that we can only read data from the lower half.
//            DATA IN
//           ___| |___
//     B    /    A    \
//  7 6 5 4 | 3 2 1 0 |
//+---------+---------+ 
//| C A F E | B E E F |  
//+---------+---------+ 
//          \___   ___/
//              | |
//           DATA OUT
//To read bytes 0x2, 0x3, 0x4, and, 0x5 (0xFEBE). we would have to rotate to the left until all bytes are aligned with the data output bus. 
//     B         A                         B         A     
//  7 6 5 4   3 2 1 0                   7 6 5 4   3 2 1 0  
//+---------+---------+               +---------+---------+
//| C A F E | B E E F |  ---rotate--> | E F C A | F E B E |
//+---------+---------+               +---------+---------+
//Now the aligned data can be read
//            DATA IN
//           ___| |___
//     B    /    A    \
//  7 6 5 4 | 3 2 1 0 |
//+---------+---------+
//| E F C A | F E B E |
//+---------+---------+
//          \___   ___/
//              | |
//           DATA OUT
//            0xFEBE
//The same algorithm applies with aligned data, just load the data into the first block, but in this case no shifting is needed.
//To load bytes or half words that are not located into address 0x0 of the shift register. Then shifting would be needed to align
//data. 
//To store 32bit unaligned data, there is a mask. Which controls which bytes of the shift register can be writen. For exmaple,
//if we want to store data into address 0x5, 0x4, 0x3, and, 0x2. We should need to first load the data of the blocks on which data is located.
//Same pricipal as with load operations. Load and roatate.
//     B         A      
//  7 6 5 4   3 2 1 0   
//+---------+---------+ 
//| C A F E | B E E F | 
//+---------+---------+ 
//Then data is ratated until the bytes that we want to replace are aligned with the A block of the shift register.
//  7 6 5 4   3 2 1 0  
//+---------+---------+
//| E F C A | F E B E |
//+---------+---------+
//After the data is aligned, we can write out new data, in this example it would be 0xFEED. After that the data can be rotated back into
//its roginal position. 
//            0xFEED                                      
//           ___| |___                                 
//     B    /    A    \                          B         A     
//  7 6 5 4 | 3 2 1 0 |                       7 6 5 4   3 2 1 0  
//+---------+---------+                     +---------+---------+
//| E F C A | F E E D | ---- Rotate Back -> | C A F E | E D E F |
//+---------+---------+                     +---------+---------+
//To modify data of sizes smaller than 32bits, we use the mask to select which bytes of the shift register can be written to. This mask is a 4bit
//Mask corresponding to the lower first bytes of the shift register.
//For example if we wanter to modify only bytes 0 and 1, the corresponding bits must be enabled into the write enable mask.
//In this way we can modify single bytes, to byte store operations and half words to store half word operations.
//                                                       0xAA                                         0xAA                     
//                         Modify Half Word             __| |__                                      __| |__                        
//                                                     /       \                                    /       \                     
//           +-------+                                |+-------+|                                  |+-------+|                          
//           | | | | | Write Enable Mask              || | |W|W||Write Enable Mask                 || | |W|W||Write Enable Mask       
//           +-------+                                |+-------+|                                  |+-------+|                        
//     B      | | | |                            B    | | | | | |                             B    | | | | | |                       
//  7 6 5 4   3 2 1 0                         7 6 5 4 | 3 2 1 0 |                   --->   7 6 5 4 | 3 2 1 0 |                            
//+---------+---------+                     +---------+---------+                        +---------+---------+                            
//| C A F E | B E E F |                     | C A F E | B E E F |                        | C A F E | B E A A |                                
//+---------+---------+                     +---------+---------+                        +---------+---------+                              
//          \___   ___/                               \___   ___/                                  \___   ___/                                  
//              | |                                       | |                                          | |                                 
//           DATA OUT                                  DATA OUT                                     DATA OUT                                



//Register to store the carry signal of the adder.
//One of the optimizations of this design will require a 1bit adder instead of a 32bit one to calculate the address of the next data block.
full_adder full_adder_1
(
    .a(rs1_b),
    .b(xor_w),
    .cin(carry),
    .cout(cout),
    .z(add)
);


//Shift register
reg [63:0] shift_reg;

//Write Enable Mask
logic [3:0] mask;

//Assign load data to the output port of the shift register
//assign load_data = shift_reg[31:0];

wire [31:0] ALIGNED_BYTE = {(shift_reg [7:7])? 24'hffffff : 24'h0, shift_reg [7:0]};
wire [31:0] ALIGNED_U_BYTE = {24'h0, shift_reg [7:0]};
wire [31:0] ALIGNED_HALF_WORD = {(shift_reg [15:15])? 16'hffff : 16'h0, shift_reg [15:0]};
wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, shift_reg [15:0]};
wire [31:0] ALIGNED_WORD_BUS = shift_reg[31:0];

//Multiplexer to choose between the load bus
always_comb
begin
    case(funct3)
        LB: load_data = ALIGNED_BYTE;
        LH: load_data = ALIGNED_HALF_WORD;
        LW: load_data = ALIGNED_WORD_BUS;
        LBU: load_data = ALIGNED_U_BYTE;
        LHU: load_data = ALIGNED_U_HALF_WORD;
        default: load_data = 32'h00000000;
    endcase
end

//Memory access, these are the opcodes of the load and store instructions
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;

//Unaligned access is true if accessing more than a byte and unaligned address
access_size_t access_size; 
always_comb
begin
    case(funct3)
        LB: access_size = BYTE;
        LH: access_size = HALF_WORD;
        LW: access_size = WORD;
        LBU: access_size = BYTE;
        LHU: access_size = HALF_WORD;
        default: access_size = WORD; //Just so modelsim stops bitching
    endcase
end

wire unaligned = (((address [1:0] == 3) & (access_size != BYTE)) | ((address [1:0] != 0) & (access_size == WORD)))? 1 : 0;


//States for the state machine
typedef enum logic[3:0] { IDDLE, LOAD_H1, ROTATE_H2, ALIGN, LOAD_CALC_ADDR, STORE_CALC_ADDR, LOAD_H2, STORE_LOAD_H1, STORE_LOAD_H2, STORE_H1, STORE_H2 } states_t;


states_t state = IDDLE;

reg [5:0] count; //This register counts how many times data is being shifted


always@(posedge clk)
begin
    case(state)
        IDDLE:
        begin
            data_valid = 0;
            count = 0;
            if(cyc)
            begin
                data_valid = 0;
                //Depending on memory operations
                ack = 1'b1;
                err = 1'b0;
                //Now we can deconde memory_operation
                case(memory_operation)
                    MEM_NONE: state = IDDLE;//Just do nothing
                    LOAD_DATA:
                    begin
                        if(unaligned)
                        begin
                            //This is to load the upper block into the shift register, so later it can be shifted
                            state = LOAD_H2;
                        end
                        else
                        begin
                            state = LOAD_H1;
                        end
                    end
                    STORE_DATA:
                    begin
                        if(unaligned)
                        begin
                            //This is to load the upper block into the shift register, so later it can be shifted
                            state = LOAD_H2;
                        end
                        else
                        begin
                            state = LOAD_H1;
                        end
                    end
                endcase
            end
        end
        //Calculates the address of the next block of data by using a single bit adder.
        LOAD_CALC_ADDR:
        begin
            
        end
        LOAD_H2:
        begin
            ack = 1'b0;
            CYC = 1'b1;
            STB = 1'b1; 
            WE = 1'b0;
            //IMPORTANT, THIS LATER HAS TO BE CHANGED TO USE A 1bit ADDER
            ADR = {(address[31:2] + 30'b1), 2'b0};
            
            //wait for termination signals
            //ACK termination signals are reported back to the control unit
            if(ACK)
            begin
                shift_reg[31:0] = DAT_I;
                //Now is can rotate to align data
                state = ROTATE_H2;
                count = 0; //Reset counter so it can be used in the next statea
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
            //Error termination signals are reported back to the control unit
            else if(ERR)
            begin
                //Go back to IDDLE. Cycle terminated.
                state = IDDLE;
                err = 1'b1;
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
            //Retry termination signals are handled automatically
            else if(RTY)
            begin
                //Stop cycle signals
                CYC = 1'b0;
                STB = 1'b0; 
                //Retry
                state = LOAD_H2;
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
        end
        ROTATE_H2:
        begin
            //Stop until data was shifted for 32 cycles
            if(count < 32)
            begin
                //Rotate left
                shift_reg[63:0] = {shift_reg[0:0], shift_reg[63:1]};
                count = count + 1;
            end
            else
            begin
                //Stop rotating
                state = LOAD_H1;
                count = 0;
            end
        end
        LOAD_H1:
        begin
            ack = 1'b0;
            CYC = 1'b1;
            STB = 1'b1; 
            WE = 1'b0;
            //IMPORTANT, THIS LATER HAS TO BE CHANGED TO USE A 1bit ADDER
            ADR = {address[31:2], 2'b0};
            
            //wait for termination signals
            //ACK termination signals are reported back to the control unit
            if(ACK)
            begin
                shift_reg[31:0] = DAT_I;
                //Now is can rotate to align data
                state = ALIGN;
                count = 0; //Reset counter so it can be used in the next statea
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
            //Error termination signals are reported back to the control unit
            else if(ERR)
            begin
                //Go back to IDDLE. Cycle terminated.
                state = IDDLE;
                err = 1'b1;
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
            //Retry termination signals are handled automatically
            else if(RTY)
            begin
                //Stop cycle signals
                CYC = 1'b0;
                STB = 1'b0; 
                //Retry
                state = LOAD_H1;
                //Reset counter so it can be used in the next cycle
                count = 0;
                //Stop wishbone cycle
                CYC = 1'b0;
                STB = 1'b0; 
                WE = 1'b0;
            end
        end
        ALIGN:
        begin
            //Rotate data until its aligned
            if(count < 5'(address[1:0] << 3))
            begin
                //Rotate left
                shift_reg[63:0] = {shift_reg[0:0], shift_reg[63:1]};
                count = count + 1;
            end
            else
            begin
                //Stop rotating
                state = IDDLE;
                //Signal the control unit that data is ready
                //The control unit has to see this instantly after a cycle
                data_valid = 1'b1;
            end

        end
        STORE_LOAD_H2:
        begin
            
        end
        STORE_LOAD_H1:
        begin
            
        end
    endcase
end

wire [5:0] align_by;
assign align_by = 5'(address[1:0]) << 3;

endmodule