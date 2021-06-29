

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
    input logic [31:0] alu_result,

    //Control signals for the branch unit
    output logic  bu_start,
    input  logic  bu_done,
    input  logic  jump,

    input logic [31:0] [31:0] debug_reg
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
parameter SYSTEM = 7'b1110011;

parameter ECALL = 12'b000000000000;
parameter EBREAK = 12'b000000000001;
parameter PRIV = 3'b000;

//Reset vector, this is the address at which the PC resets to
parameter RESET_VECTOR = 32'h00000000;//32'h80000000;

reg [5:0] count = 0;
reg [31:0] IR = 0;
reg [31:0] PC = 0;
reg [31:0] CSRS [12'hfff:12'h0];


//CSR register parameters
parameter mvendorid = 12'hF11; //0xF11 MRO mvendorid Vendor ID.
parameter marchid = 12'hF12; //0xF12 MRO marchid Architecture ID.
parameter mimpid = 12'hF13; //0xF13 MRO mimpid Implementation ID.
parameter mhartid = 12'hF14; //0xF14 MRO mhartid Hardware thread ID.
//Machine Trap Setup
parameter mstatus = 12'h300;//0x300 MRW mstatus Machine status register.
parameter misa = 12'h301;//0x301 MRW misa ISA and extensions
parameter medeleg = 12'h302;//0x302 MRW medeleg Machine exception delegation register.
parameter mideleg = 12'h303;//0x303 MRW mideleg Machine interrupt delegation register.
parameter mie = 12'h304;//0x304 MRW mie Machine interrupt-enable register.
parameter mtvec = 12'h305;//0x305 MRW mtvec Machine trap-handler base address.
parameter mcounteren = 12'h306;//0x306 MRW mcounteren Machine counter enable.
//Machine Trap Handling
parameter mscratch = 12'h340;//0x340 MRW mscratch Scratch register for machine trap handlers.
parameter mepc = 12'h341;//0x341 MRW mepc Machine exception program counter.
parameter mcause = 12'h342;//0x342 MRW mcause Machine trap cause.
parameter mtval = 12'h343;//0x343 MRW mtval Machine bad address or instruction.
parameter mip = 12'h344;//0x344 MRW mip Machine interrupt pending.
//Machine Memory Protection
//0x3A0 MRW pmpcfg0 Physical memory protection configuration.
//0x3A1 MRW pmpcfg1 Physical memory protection configuration, RV32 only.
//0x3A2 MRW pmpcfg2 Physical memory protection configuration.
//0x3A3 MRW pmpcfg3 Physical memory protection configuration, RV32 only.
//0x3B0 MRW pmpaddr0 Physical memory protection address register.
//0x3B1 MRW pmpaddr1 Physical memory protection address register.
//.
//.
//.
//0x3BF MRW pmpaddr15 Physical memory protection address register.
//Table 2.4: Currently allocated RISC-V machine-level CSR addresses.
//Volume II: RISC-V Privileged Architectures V20190608-Priv-MSU-Ratified 11
//Number Privilege Name Description

//Machine Counter/Timers
parameter mcycle = 12'hB00;//0xB00 MRW mcycle Machine cycle counter.
parameter minstret = 12'hB02;//0xB02 MRW minstret Machine instructions-retired counter.
//0xB03 MRW mhpmcounter3 Machine performance-monitoring counter.
//0xB04 MRW mhpmcounter4 Machine performance-monitoring counter.
//.
//.
//.
//0xB1F MRW mhpmcounter31 Machine performance-monitoring counter.
parameter mcycleh = 12'hB80;//0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
parameter minstreth = 12'hB82;//0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.
//0xB83 MRW mhpmcounter3h Upper 32 bits of mhpmcounter3, RV32I only.
//0xB84 MRW mhpmcounter4h Upper 32 bits of mhpmcounter4, RV32I only.
//.
//.
//.
//0xB9F MRW mhpmcounter31h Upper 32 bits of mhpmcounter31, RV32I only.
//Machine Counter Setup
parameter mcountinhibit = 12'h320;//0x320 MRW mcountinhibit Machine counter-inhibit register.
//0x323 MRW mhpmevent3 Machine performance-monitoring event selector.
//0x324 MRW mhpmevent4 Machine performance-monitoring event selector.
//.
//.
//.
//0x33F MRW mhpmevent31 Machine performance-monitoring event selector.
//Debug/Trace Registers (shared with Debug Mode)
//0x7A0 MRW tselect Debug/Trace trigger register select.
//0x7A1 MRW tdata1 First Debug/Trace trigger data register.
//0x7A2 MRW tdata2 Second Debug/Trace trigger data register.
//0x7A3 MRW tdata3 Third Debug/Trace trigger data register.
//Debug Mode Registers
//0x7B0 DRW dcsr Debug control and status register.
//0x7B1 DRW dpc Debug PC.
//0x7B2 DRW dscratch0 Debug scratch register 0.
//0x7B3 DRW dscratch1 Debug scratch register 1.

typedef enum logic [3:0] { FETCH, WAIT_FETCH, EXECUTE, INC } states_t;
states_t state = FETCH;

wire [2:0] funct3;
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

//Branch unit opcodes
parameter BEQ = 3'b000;
parameter BNE = 3'b001;
parameter BLT = 3'b100;
parameter BGE = 3'b101;
parameter BLTU = 3'b110;
parameter BGEU = 3'b111;

typedef enum logic [1:0] { CALC_NPC, SAVE_PC, CALC_TARGET, JUMP_TARGET } jalr_states_t;

//Memory access unit control state
typedef enum logic { SET_OPERATION, WAIT} mauc_state_t;


mauc_state_t mauc_state = SET_OPERATION;

jalr_states_t jalr_states = SAVE_PC;

wire [31:0] u_imm = {IR [31:12], 12'b000000000000};
logic [12:0] b_imm;
logic [11:0] i_imm;
assign b_imm [0:0] = 1'b0;
assign b_imm [11:11] = IR [7:7];
assign b_imm [4:1] = IR [11:8];
assign b_imm [10:5] = IR [30:25];
assign b_imm [12:12] = IR [31:31];
assign i_imm = IR [31:20];

always @(negedge clk) begin
    if(rst)
    begin
        state = FETCH;
        PC = RESET_VECTOR;
        cyc = 1'b0;
        count = 0;
        memory_operation = MEM_NONE;
        bu_start = 1'b0;
        jalr_states = CALC_NPC;
        mauc_state = SET_OPERATION;
    end
    case(state)
        FETCH:
        begin
            memory_operation = FETCH_DATA;
            funct3_cu <= LW;
            bu_start = 1'b0;
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
                mauc_state = SET_OPERATION;
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
                    case(mauc_state)
                        SET_OPERATION:
                        begin
                            cyc = 1'b1;
                            if(ack)
                            begin
                                mauc_state = WAIT;
                            end 
                        end
                        WAIT:
                        begin
                            cyc = 1'b0;
                            if(data_valid)
                            begin
                                wr = 1'b1;
                                state = INC;
                            end
                        end
                    endcase
                end
                STORE:
                begin
                    memory_operation = STORE_DATA;
                    case(mauc_state)
                        SET_OPERATION:
                        begin
                            cyc = 1'b1;
                            if(ack)
                            begin
                                mauc_state = WAIT;
                            end
                        end
                        WAIT:
                        begin
                            cyc = 1'b0;
                            if(done)
                            begin
                                state = INC;
                            end
                        end
                    endcase
                    
                end
                OP_IMM:
                begin
                    //Set register file input multiplexer to alu output bus
                    //$display("Executing OP_IMM");
                    regfile_src = ALU_INPUT;
                    sr2_src = I_IMM_SRC;
                    sr1_src = REG_SRC2;
                    op = {((funct3 == 3'b001) | (funct3 == 3'b101))? funct7[5:5] : 1'b0, funct3};
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
                    bu_start = 1'b1;
                    if(bu_done)
                    begin
                        bu_start = 1'b0;
                        if(jump)
                        begin
                            state = FETCH;
                            //Set PC to target address
                            PC = PC + 32'($signed(b_imm));
                        end
                        else
                        begin
                            state = INC; //Continue normal cycle
                        end
                        
                    end
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
                SYSTEM:
                begin
                    case(i_imm)
                        EBREAK:
                        begin
                            $display("EBREAK EXECUTED");
                            $display("--------------REG DUMP--------------");
                            //Display all registers
                            for(int i = 0;i < 8;i++)
                            begin
                                $display("r%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x", i, debug_reg[i], i+8, debug_reg[i+8], i+16, debug_reg[i+16], i+24, debug_reg[i+24]);                            
                            end
                            $display("pc: %02d: 0x%08x", PC);                            
                            $stop;
                        end
                    endcase
                end
                default:
                begin
                    //Trigger Illegal Instruction exeption
                    state = INC;
                end
            endcase
        end
        INC: //Increment Program counter
        begin
            //Disable write to register file signal, so we dont write other values that we dont want to write.
            wr = 1'b0;
            if(count > 31)
            begin
                state = FETCH;
                            //$display("--------------REG DUMP--------------");
                            //Display all registers
                            //for(int i = 0;i < 8;i++)
                            //begin
                            //    $display("r%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x", i, debug_reg[i], i+8, debug_reg[i+8], i+16, debug_reg[i+16], i+24, debug_reg[i+24]);                            
                            //end
                            //$display("pc: 0x%08x", PC);                            
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