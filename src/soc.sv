//Author: Benjamin Herrera Navarro 
//Wed Jun 16, 8:31 PM

`timescale 1ps/1ps

`include "debug_def.sv"

module soc
(
    `ifndef __sim__
    input logic clk, 
    input logic rst,

    //Uart signals
    input logic rx,
    output logic tx,

    //SPI Signals
	output reg  spi_master_clk,
	output reg  spi_master_cs_n,
	output reg  spi_master_mosi,
	input  wire spi_master_miso,
    
    //GPIO
    inout wire [31:0] gpio

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

logic clk_gen;
always@(posedge clk) clk_gen = ~clk_gen;

logic rst_get;
always@(posedge clk_gen)
begin
    rst_get = ~rst;
end

`ifdef __sim__
logic rx;
logic tx;

//SPI Signals
logic spi_master_clk;
logic spi_master_cs_n;
logic spi_master_mosi;
logic spi_master_miso;

//GPIO
logic [31:0] gpio;

logic clk;
logic rst;
initial begin
    $dumpfile("soc.vcd");
    $dumpvars(0,soc);
    $display("Initializing Simulations");
    clk_gen = 0;
    rst = 1;
    #10
    clk_gen = ~clk_gen;
    rst = 0;
    repeat(10)
    begin
        #10 clk_gen = ~clk_gen;
    end
    #10
    clk_gen = ~clk_gen;
    rst = 1;
    forever begin
        #10 clk_gen = ~clk_gen;
    end
end
`endif


core core0
(
    .clk(clk_gen),
    .rst(rst_get),
    .irq(timer_irq),


    //Wishbone interface
    .ACK(to_cpu_ack),
    .ERR(to_cpu_err),
    .RTY(to_cpu_rty),
    .STB(STB),
    .CYC(CYC),
    .ADR(ADR),
    .DAT_I(to_cpu_data),
    .DAT_O(DAT_O),
    .CTI_O(CTI_O),
    .WE(WE)
);

logic timer_irq;

////////////////////////////
//        MEMORY MAP      //
////////////////////////////
//  ADDRESS         DEVICE
//  0x0000-0x0fff   OnChipRAM
//  0x1000-0x10ff   SPI
//  0x1100-0x11ff   UART
//  0x1200-0x12ff   Timer
//  0x1300-0x13ff   GPIO

logic [31:0] data_r_onchip_ram;
logic [31:0] data_r_spi;
logic [31:0] data_r_uart;
logic [31:0] data_r_timer;
logic [31:0] data_r_gpio;
logic ack_onchip_ram;
logic ack_spi;
logic ack_uart;
logic ack_timer;
logic ack_gpio;
logic err_onchip_ram;
logic err_spi;
logic err_uart;
logic err_timer;
logic err_gpio;
logic rty_onchip_ram;
logic rty_spi;
logic rty_uart;
logic rty_timer;
logic rty_gpio;

logic stb_onchip_ram;
logic stb_spi;
logic stb_uart;
logic stb_timer;
logic stb_gpio;

logic to_cpu_ack;
logic to_cpu_rty;
logic to_cpu_err;
logic [31:0] to_cpu_data;

//Address decoder
always_comb begin
        //OnChipRAM
        if((ADR >= 32'h0000) & (ADR <= 32'h0fff))
        begin
            to_cpu_data = data_r_onchip_ram;
            to_cpu_ack = ack_onchip_ram;
            to_cpu_rty = rty_onchip_ram;
            to_cpu_err = err_onchip_ram;
            stb_onchip_ram = STB;
            stb_spi = 1'b0;
            stb_uart = 1'b0;
            stb_timer = 1'b0;
            stb_gpio = 1'b0;
        end
        //SPI
        else if((ADR >= 32'h1000) & (ADR <= 32'h10ff))
        begin
            to_cpu_data = data_r_spi;
            to_cpu_ack = ack_spi;
            to_cpu_rty = rty_spi;
            to_cpu_err = err_spi;
            stb_onchip_ram = 1'b0;
            stb_spi = STB;
            stb_uart = 1'b0;
            stb_timer = 1'b0;
            stb_gpio = 1'b0;
        end
        //UART
        else if((ADR >= 32'h1100) & (ADR <= 32'h11ff))
        begin
            to_cpu_data = data_r_uart;
            to_cpu_ack = ack_uart;
            to_cpu_rty = rty_uart;
            to_cpu_err = err_uart;
            stb_onchip_ram = 1'b0;
            stb_spi = 1'b0;
            stb_uart = STB;
            stb_timer = 1'b0;
            stb_gpio = 1'b0;
        end
        //Timer
        else if((ADR >= 32'h1200) & (ADR <= 32'h12ff))
        begin
            to_cpu_data = data_r_timer;
            to_cpu_ack = ack_timer;
            to_cpu_rty = rty_timer;
            to_cpu_err = err_timer;
            stb_onchip_ram = 1'b0;
            stb_spi = 1'b0;
            stb_uart = 1'b0;
            stb_timer = STB;
            stb_gpio = 1'b0;
        end
        //GPIO
        else if((ADR >= 32'h1300) & (ADR <= 32'h13ff))
        begin
            to_cpu_data = data_r_gpio;
            to_cpu_ack = ack_gpio;
            to_cpu_rty = rty_gpio;
            to_cpu_err = err_gpio;
            stb_onchip_ram = 1'b0;
            stb_spi = 1'b0;
            stb_uart = 1'b0;
            stb_timer = 1'b0;
            stb_gpio = STB;
        end
        //Address access error
        else
        begin
            to_cpu_data = 32'b0;
            to_cpu_ack = 1'b0;
            to_cpu_rty = 1'b0;
            to_cpu_err = 1'b1;
            stb_onchip_ram = 1'b0;
            stb_spi = 1'b0;
            stb_uart = 1'b0;
            stb_timer = 1'b0;
            stb_gpio = 1'b0;
        end
    end

//Onchip memory. 4K
ram #(.SIZE(32'hfff)) ram0
(
    .clk(clk_gen),
    .ACK(ack_onchip_ram),
    .ERR(err_onchip_ram),
    .RTY(rty_onchip_ram),
    .STB(stb_onchip_ram),
    .CYC(CYC),
    .ADR(ADR),
    .DAT_I(data_r_onchip_ram),
    .DAT_O(DAT_O),
    .CTI_O(CTI_O),
    .WE(WE)
);

timer timer_0
(
    .clk(clk_gen),
    .rst(rst_get),
    .ACK(ack_timer),
    .ERR(err_timer),
    .RTY(rty_timer),
    .STB(stb_timer),
    .CYC(CYC),
    .ADR(ADR),
    .DAT_I(data_r_timer),
    .DAT_O(DAT_O),
    .CTI_O(CTI_O),
    .WE(WE),
    .irq(timer_irq)
);

uart uart_0
(
    //Sys Con
    .clk(clk_gen),
    .rst(rst_get),

    //Wishbone interface
    .ACK(ack_uart),
    .ERR(err_uart),
    .RTY(rty_uart),
    .STB(stb_uart),
    .CYC(CYC),
    .ADR(ADR),
    .DAT_I(data_r_uart),
    .DAT_O(DAT_O),
    .CTI_O(3'b0),
    .WE(WE),

    //Uart signals
    .tx(tx),
    .rx(rx)
);

endmodule