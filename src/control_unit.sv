

//Author: Benjamin Herrera Navarro
//Tue Jun 15
//4:42PM

import global_pkg::*;

module control_unit
(
    input clk,
    input rst,

    //Control signals for the memory access unit
    output memory_operation_t memory_operation,
    output logic cyc,
    input  logic ack,
    input  logic err, //This signal tells the control unit that there was an error.
    input  logic done, //signals that the operations was completed
    input  logic data_valid, //This is needed for the load instruction
    output logic [2:0] funct3_cu,
    //Data signal to and from the memory access unit
    input logic [31:0] fetched_data,
    output logic [31:0] pc,
    output logic [31:0] ir,

    //Register file input source
    output regfile_src_t regfile_src,

    //Register file write control signal
    output logic wr,

    //ALU control signals
    output logic [3:0] op,
    output logic start,
    input  logic alu_done,

    //ALU input 2, data source
    output sr2_src_t sr2_src,
    output sr1_src_t sr1_src,
    input logic [31:0] alu_result
);

//Instruction Opcodes
parameter LOAD   = 7'b0000011;
parameter STORE  = 7'b0100011;
parameter OP_IMM = 7'b0010011;
parameter OP     = 7'b0110011;
parameter BRANCH = 7'b1100011;
parameter AUIPC  = 7'b0010111;
parameter LUI    = 7'b0110111;
parameter JAL    = 7'b1101111;
parameter JALR   = 7'b1100111;

//Reset vector, this is the address at which the PC resets to
parameter RESET_VECTOR = 32'h00000000;//32'h80000000;

reg [5:0] count = 0;
reg [31:0] IR = 0;
reg [31:0] PC = 0;
reg [31:0] CSRS [12'hfff:12'h0];

typedef enum logic [3:0] { FETCH, WAIT_FETCH, EXECUTE, INC } states_t;
states_t state = FETCH;

wire [3:0] funct3;
wire [6:0] funct7;

assign funct3 = IR [14:12];
assign funct7 = IR [31:25];

//Register to store the carry signal of the adder.
//One of the optimizations of this design will require a 1bit adder instead of a 32bit one.
reg carry;
wire add;
wire cout;

full_adder full_adder_0
(
    .a(PC[0:0]),
    .b((count == 5'h2)? 1'b1 : 1'b0), //To just increment by 4 every time
    .cin(carry),
    .cout(cout),
    .z(add)
);

//Ways the control unit can load data from memory
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;

//ALU OPCODES
parameter ADD =  4'b0000;
parameter SUB =  4'b1000;
parameter SLL =  4'b0001;
parameter SLT =  4'b0010;
parameter SLTU = 4'b0011;
parameter XOR =  4'b0100;
parameter SRL =  4'b0101;
parameter SRA =  4'b1101;
parameter OR =   4'b0110;
parameter AND =  4'b0111;

typedef enum logic [1:0] { CALC_NPC, SAVE_PC, CALC_TARGET, JUMP_TARGET } jalr_states_t;

jalr_states_t jalr_states = SAVE_PC;

wire [31:0] u_imm = {IR [31:12], 12'b000000000000};

always @(negedge clk) begin
    if(rst)
    begin
        state = FETCH;
        PC = RESET_VECTOR;
        cyc = 1'b0;
        count = 0;
        memory_operation = MEM_NONE;
    end
    case(state)
        FETCH:
        begin
            memory_operation = FETCH_DATA;
            funct3_cu <= LW;
            cyc = 1'b1;
            wr = 0;
            if(ack)
            begin
                state = WAIT_FETCH;
            end 
        end
        WAIT_FETCH:
        begin
            funct3_cu <= LW;
            cyc = 1'b0;
            if(data_valid)
            begin
                IR = fetched_data;
                state = EXECUTE;
                jalr_states = CALC_NPC;
            end
            else if(err)
            begin
                //Do an illegal address something thing
            end
        end
        EXECUTE:
        begin
            count = 0;
            carry = 0;
            funct3_cu <= funct3;
            //Decode instructions
            case(IR[6:0])
                LOAD:
                begin
                    //Set register file input multiplexer to load bus source
                    regfile_src = LOAD_SRC;
                    memory_operation = LOAD_DATA;
                end
                STORE:
                begin
                    memory_operation = STORE_DATA;
                    
                end
                OP_IMM:
                begin
                    //Set register file input multiplexer to alu output bus
                    //$display("Executing OP_IMM");
                    regfile_src = ALU_INPUT;
                    sr2_src = I_IMM_SRC;
                    sr1_src = REG_SRC2;
                    op = {funct7[5:5], funct3};
                    //
                    start = 1'b1;
                    if(alu_done)
                    begin
                        start = 1'b0;
                        state = INC;
                        wr = 1'b1; //Write to register file
                    end
                    
                end
                OP:
                begin
                    //Set register file input multiplexer to alu output bus
                    //$display("Executing OP");
                    regfile_src = ALU_INPUT;
                    sr2_src = REG_SRC;
                    sr1_src = REG_SRC2;
                    op = {funct7[5:5], funct3};
                    //
                    start = 1'b1;
                    if(alu_done)
                    begin
                        start = 1'b0;
                        state = INC;
                        wr = 1'b1; //Write to register file
                    end
                end
                BRANCH:
                begin
                    
                end
                AUIPC:
                begin                    
                    //$display("Executing AUIPC");
                    //Set register file input multiplexer to alu output bus
                    op = ADD;
                    regfile_src = ALU_INPUT;
                    sr2_src = ALU_PC_SRC;
                    sr1_src = ALU_U_IMM_SRC;
                    //
                    start = 1'b1;
                    if(alu_done)
                    begin
                        start = 1'b0;
                        state = INC;
                        wr = 1'b1; //Write to register file
                    end
                end
                LUI:
                begin
                    //$display("Executing LUI");
                    regfile_src = U_IMM_SRC;
                    wr = 1'b1; //Write to register file
                    state = INC;
                end
                JAL, JALR:
                begin
                    //$display("Executing JAL");
                    regfile_src = ALU_INPUT;
                    case(jalr_states)
                        CALC_NPC:
                        begin
                            op = ADD;
                            sr2_src = ALU_PC_SRC;
                            sr1_src = ALU_4;
                            wr = 1'b0; //Write to register file
                            start = 1'b1;
                            jalr_states = SAVE_PC;
                        end
                        SAVE_PC:
                        begin
                            start = 1'b0;
                            if(alu_done)
                            begin
                                wr = 1'b1; //Write to register file
                                jalr_states = CALC_TARGET;
                            end
                        end
                        CALC_TARGET:
                        begin
                            wr = 1'b0; //Write to register file
                            if(IR[6:0] == JAL)
                            begin
                                sr2_src = ALU_PC_SRC;
                                sr1_src = ALU_J_IMM;
                            end
                            else if(IR[6:0] == JALR)
                            begin
                                sr2_src = I_IMM_SRC;
                                sr1_src = REG_SRC2;
                            end
                            start = 1'b1;
                            jalr_states = JUMP_TARGET;
                        end
                        JUMP_TARGET:
                        begin
                            start = 1'b0;
                            if(alu_done)
                            begin
                                //-----------------NOTE------------------
                                //This can use instead the shift register capability to shift in all data and not waste space with multiplexors
                                PC = alu_result;
                                state = FETCH;
                            end
                        end
                    endcase
                end
                default: state = INC;
            endcase
        end
        INC: //Increment Program counter
        begin
            //Disable write to register file signal, so we dont write other values that we dont want to write.
            wr = 1'b0;
            if(count > 31)
            begin
                state = FETCH;
            end
            else
            begin
                count = count + 1;
                carry = cout;
                PC[31:0] = {add, PC[31:1]}; //It should end up in the same position
            end
        end
    endcase
end

assign pc = PC;
//assign op = {funct7[5:5], funct3};
assign ir = IR;//{ IR[31:25], rs2_cu, IR[19:0] };

endmodule