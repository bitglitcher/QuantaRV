//Author: Benjamin Herrera Navarro
//Fri Jun 4, 4:40PM

module regfile
(
    input logic clk,
    input logic [4:0] rd,
    input logic [31:0] rd_d,
    input logic wr,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output logic [31:0] rs1_d,
    output logic [31:0] rs2_d
);

reg [31:0] registers [31:0];

always @(posedge clk) begin
    if(wr & (rd != 0)) registers[rd] <= rd_d;
end
logic [31:0] rs1_b;
logic [31:0] rs2_b;

always@(posedge clk)
begin
    rs1_d <= registers [rs1];
    rs2_d <= registers [rs2];
end

`include "debug_def.sv"

//This way we can debug the values in the registers
`ifdef __sim__
initial begin
    for(int i = 0;i < 32;i++)
    begin
        registers[i] = 32'b0;
    end
end

//assert (registers[1] == 32'b0) 
//else   $display("x0 is not zero");

wire [31:0] r00 = registers[1];
wire [31:0] r01 = registers[1];
wire [31:0] r02 = registers[2];
wire [31:0] r03 = registers[3];
wire [31:0] r04 = registers[4];
wire [31:0] r05 = registers[5];
wire [31:0] r06 = registers[6];
wire [31:0] r07 = registers[7];
wire [31:0] r08 = registers[8];
wire [31:0] r09 = registers[9];
wire [31:0] r10 = registers[10];
wire [31:0] r11 = registers[11];
wire [31:0] r12 = registers[12];
wire [31:0] r13 = registers[13];
wire [31:0] r14 = registers[14];
wire [31:0] r15 = registers[15];
wire [31:0] r16 = registers[16];
wire [31:0] r17 = registers[17];
wire [31:0] r18 = registers[18];
wire [31:0] r19 = registers[19];
wire [31:0] r20 = registers[20];
wire [31:0] r21 = registers[21];
wire [31:0] r22 = registers[22];
wire [31:0] r23 = registers[23];
wire [31:0] r24 = registers[24];
wire [31:0] r25 = registers[25];
wire [31:0] r26 = registers[26];
wire [31:0] r27 = registers[27];
wire [31:0] r28 = registers[28];
wire [31:0] r29 = registers[29];
wire [31:0] r30 = registers[30];
wire [31:0] r31 = registers[31];
`endif

endmodule