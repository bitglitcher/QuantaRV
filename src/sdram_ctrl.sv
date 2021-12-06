//Author: Benjamin Herrera Navarro
//Date: Sun Dec 5 2021 11:05 PM
module sdram_ctrl
(
    //Sys Con
    input clk,
    input rst,

    //Wishbone interface
    output logic ACK,
    output logic ERR,
    output logic RTY,
    input logic STB,
    input logic CYC,
    input logic [31:0] ADR,
    output logic [31:0] DAT_I,
    input logic [31:0] DAT_O,
    input logic [2:0]  CTI_O,
    input logic WE,
    
    //SDRAM interface
    inout logic [15:0] SDQ,
    output logic [11:0] SA,

    //Bank address
    output logic [1:0] BA,

    //Clock and Clock Enable
    output logic CLK,
    output logic CKE,
    output logic RAS,
    output logic CAS,
    //Write Enable
    output logic WE,

    //Chip Select
    output logic [1:0] DQM
);

parameter CAS_LATENCY = 3;





endmodule