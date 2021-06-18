module decoder
(
    input logic [31:0] IR,
    output logic [6:0] opcode,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] funct7,
    output logic [11:0] i_imm,
    output logic [11:0] s_imm,
    output logic [12:0] b_imm,
    output logic [31:0] u_imm,
    output logic [20:0] j_imm
);



assign opcode = IR [6:0];
assign rd = IR [11:7];
assign funct3 = IR [14:12];
assign rs1 = IR [19:15];
assign rs2 = IR [24:20];
assign funct7 = IR [31:25];
assign i_imm = IR [31:20];
assign s_imm = {IR [31:25], IR[11:7]};
assign b_imm [0:0] = 1'b0;
assign b_imm [11:11] = IR [7:7];
assign b_imm [4:1] = IR [11:8];
assign b_imm [10:5] = IR [30:25];
assign b_imm [12:12] = IR [31:31];
assign u_imm = {IR [31:12], 12'b000000000000};
assign j_imm [0:0] = 1'b0;
assign j_imm [19:12] = IR [19:12];
assign j_imm [11:11] = IR [20:20];
assign j_imm [10:1] = IR [31:21];
assign j_imm [20:20] = IR [31:31];


endmodule