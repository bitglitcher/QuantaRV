//Author: Benjamin Herrera Navarro
//Date: Mon, Dec 6 2021 2:06PM

//Cache module of 256Byte blocks
module cache
(
	input logic clk,
	input logic rst,

	//Slave interface
    output logic        S_ACK,
    output logic        S_ERR,
    output logic        S_RTY,
    input  logic        S_STB,
    input  logic        S_CYC,
    input  logic [31:0] S_ADR,
    output logic [31:0] S_DAT_I,
    input  logic [31:0] S_DAT_O,
    input  logic [2:0]  S_CTI_O,
    input  logic        S_WE,
 

    //Master Memory Controller BUS
    input  logic        M_ACK,
    input  logic        M_ERR,
    input  logic        M_RTY,
    output logic        M_STB,
    output logic        M_CYC,
    output logic [31:0] M_ADR,
    input  logic [31:0] M_DAT_I,
    output logic [31:0] M_DAT_O,
    output logic [2:0]  M_CTI_O,
    output logic        M_WE
);

parameter n_rows = 8; //8 256x32Bit blocks 
parameter n_blocks = 256;
parameter block_size = 4; //In bytes
parameter row_adr_lsb = 10; //log2(block_size)
parameter row_adr_msb = 12; //log2(block_size) + log2(n_rows) - 1
parameter dlsb = 2; //Data lsb 
parameter dmsb = 9; //Data msb 
parameter tlsb = 13; //Tag lsb
parameter tmsb = 31; //Tag msb
parameter CC  = 3'b000; //Classic Cycle
parameter CAB = 3'b001; //Constant Address Burst
parameter IBC = 3'b010; //Incrementing Burst Cycle
parameter EOB = 3'b111; //End of Cycle

reg dirty [n_rows-1:0];
reg valid [n_rows-1:0];
reg [tmsb-tlsb:0] tag  [n_rows-1:0];
reg [31:0] data [n_rows-1:0] [n_blocks-1:0];

typedef enum logic [3:0] { IDDLE, HIT, MISS_SO, MISS_SC, MISS_FO, MISS_FC } wb_state_t;
wb_state_t wb_state = IDDLE;

//There is a maximum of 256 32bit transfers
reg [$clog2(n_blocks):0] offset = 0;

always@(posedge clk)
begin
	if(rst)
	begin
		wb_state <= IDDLE;
	end
	else
	begin
		case(wb_state)
			IDDLE:
			begin
				if(S_STB & S_CYC)
				begin
					if((tag [S_ADR[row_adr_msb:row_adr_lsb]] == S_ADR [tmsb:tlsb]) & (valid [S_ADR[row_adr_msb:row_adr_lsb]] == 1))
					begin
						wb_state <= HIT;
						if(S_WE)
						begin
							data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb]] <= S_DAT_O;
							dirty [S_ADR[row_adr_msb:row_adr_lsb]] <= 1'b1;
						end
						// else
						// begin
						// 	S_DAT_I <= data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb]];
						// end
						S_ACK <= 1'b1;
						S_ERR <= 1'b0;
						S_RTY <= 1'b0;
					end
					else
					begin
						if((valid [S_ADR[row_adr_msb:row_adr_lsb]] == 1) & (dirty [S_ADR[row_adr_msb:row_adr_lsb]] == 1))
						begin
							wb_state <= MISS_SO;
							offset <= 0;
							S_ACK <= 1'b0;
							S_ERR <= 1'b0;
							S_RTY <= 1'b0;
						end
						else if((valid [S_ADR[row_adr_msb:row_adr_lsb]] == 1) & (dirty [S_ADR[row_adr_msb:row_adr_lsb]] == 0))
						begin
							wb_state <= MISS_FO;
							offset <= 0;
							S_ACK <= 1'b0;
							S_ERR <= 1'b0;
							S_RTY <= 1'b0;
						end
						else
						begin
							wb_state <= MISS_FO;
							offset <= 0;
							S_ACK <= 1'b0;
							S_ERR <= 1'b0;
							S_RTY <= 1'b0;	
						end
					end
				end
				else
				begin
					S_ACK <= 1'b0;
					S_ERR <= 1'b0;
					S_RTY <= 1'b0;
					M_CYC <= 1'b0;
					M_STB <= 1'b0;
					M_CTI_O <= IBC;
					M_ADR <= 32'b0;
					M_DAT_O <= 32'b0;
				end
			end
			HIT:
			begin
				S_ACK <= 1'b1;
				S_RTY <= 1'b0;
				S_ERR <= 1'b0;
				wb_state <= IDDLE;
			end
			MISS_SO:
			begin
				S_DAT_I <= 32'b0;

				if(offset < n_blocks)
				begin
					//Do a 256*32fetch
					M_STB <= 1'b1;
					M_CYC <= 1'b1;
					M_CTI_O <= IBC; //Incrementing Burst Cycle
					M_ADR <= tag [S_ADR[row_adr_msb:row_adr_lsb]] + offset; //The SDRAM accesses are 256byte blocks
					M_WE <= 1'b1; //Write transfer
					if(M_ACK)
					begin
						M_STB <= 1'b0;
						M_CYC <= 1'b0;
						wb_state <= MISS_SC;
					end
					else if(M_RTY)
					begin
						wb_state <= IDDLE;
						S_ERR <= 1'b0;
						S_RTY <= 1'b1;
						S_ACK <= 1'b0;
						M_STB <= 1'b0;
						M_CYC <= 1'b0;
					end	
					else if(M_ERR)
					begin
						//Notify the master device about an error
						S_ERR <= 1'b1;
						//End cycle and IDDLE
						wb_state <= IDDLE;
						S_RTY <= 1'b0;
						S_ACK <= 1'b0;
						M_CYC <= 1'b0;
						M_STB <= 1'b0;

					end
					else
					begin
						wb_state <= MISS_SO;
					end
				end
				else
				begin
					//Fetch the data from memory
					wb_state <= MISS_FO;
					offset <= 1'b0;
					M_CYC <= 1'b0;
					M_STB <= 1'b0;
				end
			end
			MISS_SC:
			begin
				wb_state <= MISS_SO;
				M_STB <= 1'b0;
				offset <= offset + 1;
				M_CYC <= 1'b1;
				M_CTI_O <= IBC;
			end
			MISS_FO:
			begin
				if(offset < n_blocks)
				begin
					//Fetch block into cache memory
					M_STB <= 1'b1;
					M_CYC <= 1'b1;
					M_ADR <= tag [S_ADR[row_adr_msb:row_adr_lsb]] + (offset << 2);
					M_CTI_O = IBC;
					data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb] + offset] <= M_DAT_I;
					if(M_ACK)
					begin
						wb_state <= MISS_FC;
						M_STB <= 1'b0;
						//M_CYC <= 1'b0;
					end
					else if(M_RTY)
					begin
						wb_state <= IDDLE;
						S_ERR <= 1'b0;
						S_RTY <= 1'b1;
						S_ACK <= 1'b0;
						M_STB <= 1'b0;
						M_CYC <= 1'b0;
					end	
					else if(M_ERR)
					begin
						//Notify the master device about an error
						S_ERR <= 1'b1;
						//End cycle and IDDLE
						wb_state <= IDDLE;
						S_RTY <= 1'b0;
						S_ACK <= 1'b0;
						M_CYC <= 1'b0;
						M_STB <= 1'b0;

					end
					else
					begin
						wb_state <= MISS_FO;
					end
				end
				else
				begin
					S_ACK <= 1'b1;
					S_ERR <= 1'b0;
					S_RTY <= 1'b0;
					M_CYC <= 1'b0;
					M_STB <= 1'b0;
					if(S_WE)
					begin
						data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb]] <= S_DAT_O;
						dirty [S_ADR[row_adr_msb:row_adr_lsb]] <= 1'b1;
					end
					else
					begin
						//S_DAT_I <= data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb]];
						dirty [S_ADR[row_adr_msb:row_adr_lsb]] <= 1'b0;
					end
					wb_state <= IDDLE;
					valid [S_ADR[row_adr_msb:row_adr_lsb]] <= 1'b1;
					tag [S_ADR[row_adr_msb:row_adr_lsb]] <= S_ADR [tmsb:tlsb];
				end
			end
			MISS_FC:
			begin
				M_STB <= 1'b0;
				M_CYC <= 1'b1;
				wb_state <= MISS_FO;
				offset <= offset + 1;
				M_CTI_O <= IBC;	
			end
		endcase
	end	
	S_DAT_I <= data [S_ADR[row_adr_msb:row_adr_lsb]] [S_ADR [dmsb:dlsb]];
end

`include "debug_def.sv"

`ifdef __sim__
//On simulation initialize them all to 0 
initial
begin
	S_ACK = 0;
	S_ERR = 0;
	M_WE <= 1'b0;
	S_RTY = 0;
	for(int i = 0;i < n_rows;i++)
	begin
		dirty [i] = 0;
		valid [i] = 0;
		tag [i] = 0;
	end
end
`endif

endmodule
