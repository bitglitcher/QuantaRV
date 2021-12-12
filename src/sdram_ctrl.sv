//Author: Benjamin Herrera Navarro
//Date: Sun Dec 5 2021 11:05 PM
module sdram_ctrl
(
    //Sys Con
    input clk, //50Mhz Clock
    input rst,
	input pll_clck, //100Mhz Clock

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
    inout logic [15:0] DQ,
    output logic [11:0] ADDR,

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
	output logic CS,

	//Data Mask
    output logic [1:0] DQM
);

//////////////////////////////////
//Wishbone BUS logic


typedef enum logic [3:0] { WB_IDDLE, CYCLE };

//////////////////////////////////
//SDRAM Controll Logic
//
parameter CAS_LATENCY = 3;
parameter ARC = 4096; //Auto refresh cycles

typedef enum logic [3:0] { IDDLE, REFRESH, ACTIVE, WRITE, READ, LOAD_REGISTER, PRECHARGE, INIT, POW} states_t;
states_t state = IDDLE;

parameter FREQ = 50000000; //Frequency
//Power On Delay Time 
parameter tPDT = 100; //100 microseconds
//Cycles Until Statble
parameter CUS = (tPDT/((1/FREQ)*1000000));

//13 bit cycle counterp

reg [12:0] cycle_cnt;

//State machine
always@(posedge clk)
begin
	if(rst)
	begin
		state = IDDLE;
	end
	else
	begin
		case(state)
			POW:
			begin
				cycle_cnt <= 0;
				//Assing pins to nop state
				CS <= 1'b0;
				RAS <= 1'b0;
				CAS <= 1'b0;
				WE <= 1'b1;
				DQM <= 2'b0;
				ADDR <= 12'b0;
				DQ <= 16'b0;
			end
			INIT:
			begin
				//Wait a certain amount of cycles until stabls
				if(cycle_cnt > CUS)
				begin
					state 
				end
				else
				begin

				end
				//Keep pins on the NOP state
				CS <= 1'b0;
				RAS <= 1'b0;
				CAS <= 1'b0;
				WE <= 1'b1;
				DQM <= 2'b0;
				ADDR <= 12'b0;
				DQ <= 16'b0;

				
			end
			IDDLE:
			begin

			end
			REFRESH:
			begin

			end
			ACTIVE:
			begin

			end
			WRITE:
			begin

			end
			READ:
			begin

			end
			//The load register command can only be issued
			//When all banks are at iddle.
			LOAD_REGISTER:
			begin

			end
			//The precharge command is used to deactivate a bank.
			PRECHARGE:
			begin

			end
		endcase
	end
end



endmodule
