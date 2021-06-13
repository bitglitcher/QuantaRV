
interface decode;
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
    logic [11:0] i_imm;
    logic [11:0] s_imm;
    logic [12:0] b_imm;
    logic [31:0] u_imm;
    logic [20:0] j_imm;
endinterface //interfacename