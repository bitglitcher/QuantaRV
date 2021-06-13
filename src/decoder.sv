module decoder
(
    input logic [31:0] IR,
    decode decode_bus
);



assign decode_bus.opcode = IR [6:0];
assign decode_bus.rd = IR [11:7];
assign decode_bus.funct3 = IR [14:12];
assign decode_bus.rs1 = IR [19:15];
assign decode_bus.rs2 = IR [24:20];
assign decode_bus.funct7 = IR [31:25];
assign decode_bus.i_imm = IR [31:20];
assign decode_bus.s_imm = {IR [31:25], IR[11:7]};
assign decode_bus.b_imm [0:0] = 1'b0;
assign decode_bus.b_imm [11:11] = IR [7:7];
assign decode_bus.b_imm [4:1] = IR [11:8];
assign decode_bus.b_imm [10:5] = IR [30:25];
assign decode_bus.b_imm [12:12] = IR [31:31];
assign decode_bus.u_imm = {IR [31:12], 12'b000000000000};
assign decode_bus.j_imm [0:0] = 1'b0;
assign decode_bus.j_imm [19:12] = IR [19:12];
assign decode_bus.j_imm [11:11] = IR [20:20];
assign decode_bus.j_imm [10:1] = IR [31:21];
assign decode_bus.j_imm [20:20] = IR [31:31];


endmodule