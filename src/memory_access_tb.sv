//Author: Benjamin Herrera Navarro 
//Sun, Jun, 13 
//8:54AM


`timescale 1ps/1ps

module memory_access_tb();


reg [31:0] memory [1:0];

reg clk;

initial begin
    clk = 0;    
    forever begin
        #10 clk = ~clk;
    end
end

typedef enum logic [1:0] { LOAD, STORE } name;

always@(posedge clk)
begin
    //Initialize memory with random values
    memory[0] = $random();
    memory[1] = $random();
end







endmodule