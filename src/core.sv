//Author: Benjamin Herrera Navarro
//Wed Jun 16 9:36

import global_pkg::*;

module core
(
    input clk,
    input rst,


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
    output logic        WE
);


//Control signals for the memory access unit
memory_operation_t memory_operation;
wire cyc;
wire ack;
wire err; //This signal tells the control unit that there was an error.
wire done; //signals that the operations was completed
wire data_valid; //This is needed for the load instruction
//Data buses to memory access unit
logic [31:0] store_data;
logic [31:0] address;
logic [31:0] load_data;
//Control signals for the ALU
logic [3:0] op;
logic start;
logic alu_done;
//Data signal to and from the memory access unit
wire [31:0] fetched_data = load_data;
wire [31:0] pc;

//Main data buses and register file control signals
logic wr;
logic [31:0] rs1_d;
logic [31:0] rs2_d;
logic [31:0] rd_d;
logic [31:0] alu_out;
logic [2:0] funct3_cu;

regfile_src_t regfile_src;
sr2_src_t sr2_src;
sr1_src_t sr1_src;

logic bu_start;
logic bu_done;
logic jump;

control_unit control_unit_0
(
    .clk(clk),
    .rst(rst),

    //Control signals for the memory access unit
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .err(err), //This signal tells the control unit that there was an error.
    .done(done), //signals that the operations was completed
    .data_valid(data_valid), //This is needed for the load instruction
    .funct3_cu(funct3_cu),

    //Data signal to and from the memory access unit
    .fetched_data(fetched_data),
    .pc(pc),
    .ir(IR),
    
    //Register file input source
    .regfile_src(regfile_src),

    //Register file write control signal
    .wr(wr),

    //ALU control signals
    .op(op),
    .start(start),
    .alu_done(alu_done),

    //ALU input 2, data source
    .sr2_src(sr2_src),
    .sr1_src(sr1_src),

    .alu_result(alu_out),

    //Control signals for the branch unit
    .bu_start(bu_start),
    .jump(jump),
    .bu_done(bu_done)
);

logic [31:0] IR;
logic [6:0]  opcode;
logic [4:0]  rd;
logic [2:0]  funct3;
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [6:0]  funct7;
logic [11:0] i_imm;
logic [11:0] s_imm;
logic [12:0] b_imm;
logic [31:0] u_imm;
logic [20:0] j_imm;

decoder decoder_0
(
    .IR(IR),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm)
);

branch_unit branch_unit_0
(
    .clk(clk),
    .start(bu_start),
    .rs1(rs1_d),
    .rs2(rs2_d),
    .funct3(funct3),
    .done(bu_done),
    .jump(jump)
);

//always_comb
//begin
//    unique case(regfile_src)
//        ALU_INPUT: rd_d <=  rd_alu;
//        U_IMM_SRC: rd_d <= decode_bus.u_imm;
//        AUIPC_SRC: rd_d <= decode_bus.u_imm + PC;
//        PC_SRC: rd_d <= PC + 4;
//        LOAD_SRC: rd_d <= load_data;
//        CSR_SRC: rd_d <= csr_dout;
//    endcase
//end

//Multiplexer to choose between the loaded data and the ALU
always_comb begin
    case (regfile_src)
            ALU_INPUT: rd_d = alu_out;    //OP OP-IMM
            U_IMM_SRC: rd_d = u_imm;      //LUI
            //AUIPC_SRC: rd_d = u_imm + pc; //AUIPC
            LOAD_SRC: rd_d = load_data; //LOAD
            //PC_SRC:    rd_d = pc + 4; //JALR
            //CSR_SRC:   rd_d = 32'haeaeaeae;
            default: rd_d = 32'b0;
    endcase
end

regfile regfile_0
( 
    .clk(clk),
    .rd(rd),
    .rd_d(rd_d),
    .wr(wr),
    .rs1(rs1),
    .rs2(rs2),
    .rs1_d(rs1_d),
    .rs2_d(rs2_d)
);


logic [31:0] alu_src2;
always_comb begin
    case(sr2_src)
        REG_SRC: alu_src2 = rs2_d;
        I_IMM_SRC: alu_src2 = 32'($signed(i_imm));
        ALU_PC_SRC: alu_src2 = pc;
    endcase    
end

logic [31:0] alu_src1;
always_comb begin
    case(sr1_src)
        REG_SRC2:  alu_src1 = rs1_d;
        U_IMM_SRC: alu_src1 = u_imm;
        I_IMM_SRC1: alu_src1 = 32'($signed(i_imm));
        ALU_J_IMM: alu_src1 = 32'($signed(j_imm));
        ALU_4: alu_src1 = 32'h4;
    endcase    
end



alu alu_0
(
    .clk(clk),
    .rs1(alu_src1),
    .rs2(alu_src2),
    .rd(alu_out),
    .op(op),
    .done(alu_done),
    .start(start)
);

//Address bus for the load and store operations
logic [31:0] address_ld;
assign address = address_ld;
//Multiplexer to choose between the load or store address
always_comb
begin
    unique case(memory_operation)
        //Address = rs1 + imm_i sign extended to 32bits
        FETCH_DATA:  address_ld = pc;
        //This operations should use the ALU to calculate values instead
        LOAD_DATA: address_ld = rs1_d + 32'($signed(i_imm));
        STORE_DATA: address_ld = rs1_d + 32'($signed(s_imm));
        //MEM_NONE: address_ld = 32'b0;
    endcase
end

memory_access memory_access_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .err(err), //This signal tells the control unit that there was an error.
    .done(done), //signals that the operations was completed
    .data_valid(data_valid), //This is needed for the load instruction
    .funct3(funct3_cu), //funct signal modified by the control unit

    //Data
    .store_data(rs2_d),
    .address(address),
    .load_data(load_data),

    //Wishbone interface
    //WB4.master data_bus There is not support for interfaces in icarus

    //Wishbone interface
    .ACK(ACK),
    .ERR(ERR),
    .RTY(RTY),
    .STB(STB),
    .CYC(CYC),
    .ADR(ADR),
    .DAT_I(DAT_I),
    .DAT_O(DAT_O),
    .CTI_O(CTI_O),
    .WE(WE)
);

endmodule