//Author: Benjamin Herrera Navarro
//Fri Jun 4, 4:40PM

module regfile
(
    input logic clk,
    input logic [4:0] rd,
    input logic [31:0] rd_d,
    input logic wr,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [31:0] rs1_d,
    output logic [31:0] rs2_d
);

reg [31:0] registers [31:1];

always @(posedge clk) begin
    if(wr) registers[rd] = rd_d;
end

assign rs1_d = (rs1 != 0)? registers [rs1] : 32'b0;
assign rs2_d = (rs2 != 0)? registers [rs2] : 32'b0;


endmodule