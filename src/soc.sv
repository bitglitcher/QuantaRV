//Author: Benjamin Herrera Navarro 
//Wed Jun 16, 8:31 PM

`timescale 1ps/1ps

module soc
(
    `ifndef __sim__
    input clk, 
    input rst,

    //Uart signals
    input rx,
    output tx
    `endif
);

logic        ACK;
logic        ERR;
logic        RTY;
logic        STB;
logic        CYC;
logic [31:0] ADR;
logic [31:0] DAT_I;
logic [31:0] DAT_O;
logic [2:0]  CTI_O;
logic        WE;

`ifdef __sim__
logic clk;
logic rst;
initial begin
    $dumpfile("soc.vcd");
    $dumpvars(0,soc);
    $display("Initializing Simulations");
    clk = 0;
    rst = 0;
    forever begin
        #10 clk = ~clk;
    end
end
`endif


core core0
(
    .clk(clk),
    .rst(rst),


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


ram ram0
(
    .clk(clk),
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

assign tx = ACK;

endmodule