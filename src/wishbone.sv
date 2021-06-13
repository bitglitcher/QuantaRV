interface WB4(input clk, input rst);
    logic ACK;
    logic ERR;
    logic RTY;
    logic STB;
    logic [31:0] ADR;
    logic CYC;
    logic [31:0] DAT_I;
    logic [31:0] DAT_O;
    logic WE;
    logic [2:0] CTI_O;
    modport slave(input clk, rst,
    input STB,
    input ADR,
    input CYC,
    output DAT_I,
    input  DAT_O,
    input CTI_O,
    output ACK,
    output ERR,
    output RTY,
    input WE);
    modport master(input clk, rst,
    output STB,
    output ADR,
    output CYC,
    input  DAT_I,
    output DAT_O,
    output CTI_O,
    input ACK,
    input ERR,
    input RTY,
    output WE);
endinterface //WB4