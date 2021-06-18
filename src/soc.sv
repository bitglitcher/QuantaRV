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
    .ACK((ADR < 4096)? ram_cyc : uart_ack),
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

logic ram_cyc = (ADR < 4096)? CYC : 1'b0;
logic uart_cyc = (ADR == 32'hffff)? CYC : 1'b0;

logic ram_ack;
logic uart_ack;

ram ram0
(
    .clk(clk),
    .ACK(ram_ack),
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

always @(posedge clk) begin
   if(uart_cyc & STB)
   begin
       uart_ack = 1'b1;
       $write("%c", DAT_O & 32'hff);
   end 
   else
   begin
       uart_ack = 1'b0;
   end
end

endmodule