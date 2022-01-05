//Author: Benjamin Herrera Navarro
//Date: Sun Dec 5 2021 11:05 PM
module sdram_ctrl
(
    //Sys Con
    input logic clk, //50Mhz Clock
    input logic rst,
	//Pll_clk must always be double clk
	input logic pll_clk, //100Mhz Clock

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
    inout wire [15:0] DQ,
    output logic [11:0] ADDR,

    //Bank address
    output logic [1:0] BA,

    //Clock and Clock Enable
    output logic CLK,
    output logic CKE,
    output logic RAS,
    output logic CAS,
    //Write Enable
    output logic RWE,

    //Chip Select
	output logic CS,

	//Data Mask
    output logic [1:0] DQM
);

/////////////////////////////////////////////////
//Asynchronous read fifo
//
//Read from Wishbone FSM and Write from SDRAM FSM 
parameter rf_size = 4;
logic rf_rd; //Read fifo read signal
logic rf_wr; //Read fifo write signal
logic rf_r_data; //Read fifo read data bus
logic rf_w_data; //Read fifo write data bus
logic rf_empty; //Empty flag
logic rf_full; //Full flag
logic rf_rempty; //Registered empty flag
logic rf_rfull; //Registered full flag
reg [$clog2(rf_size):0] rf_wp; //Write pointer
reg [$clog2(rf_size):0] rf_rp; //Read pointer
wire [$clog2(rf_size):0] rf_wp_g; //Write pointer gray encoding
wire [$clog2(rf_size):0] rf_rp_g; //Read pointer gray encoding
reg [$clog2(rf_size):0] rf_wp_gr; //Write pointer gray encoding reg
reg [$clog2(rf_size):0] rf_rp_gr; //Read pointer gray encoding reg
reg [$clog2(rf_size):0] rf_wp_grs [1:0]; //Write pointer gray encoding reg synchronizer
reg [$clog2(rf_size):0] rf_rp_grs [1:0]; //Read pointer gray encoding reg synchronizer
reg [16:0] rf_mem [$clog2(2**rf_size)-1:0]; //Read fifo memory

//The cast of the addition has to be changed manually
assign rf_wp_g = (rf_wp ^ (2'(rf_wp + 2'b1) >> 1)); //Generate gray encoding
assign rf_rp_g = (rf_rp ^ (2'(rf_rp + 2'b1) >> 1)); //Generate gray encoding

//Generate empty flag
assign rf_empty = (rf_rp_g == rf_wp_grs [0]);

//Generate full flag
assign rf_full = (rf_wp_g == {~rf_rp_grs [0] [$clog2(rf_size):$clog2(rf_size)-1], rf_rp_grs [0][$clog2(rf_size)-2:0]});

always@(posedge clk) //READ DOMAIN WB
begin
	if(rst)
	begin
		rf_rempty <= 1'b1;
		{rf_wp_grs [1], rf_wp_grs [0]} <= {16'b0, 16'b0};		
		rf_rp_gr <= 0;
	end
	else
	begin
		//read pointer logic
		if(!rf_empty & rf_rd)
		begin
			rf_rp <= rf_rp + 1; //Increment counter
		end
		//Gray encoding register
		rf_rp_gr <= rf_rp_g;
	
		//Synchronize write gray encoding register data
		{rf_wp_grs [1], rf_wp_grs [0]} <= {rf_wp_gr, rf_wp_grs[1]};
	
		//FIFO Memory Read
		rf_r_data <= rf_mem[rf_rp [$clog2(rf_size)-1:0]];

		//Register empty flag
		rf_rempty <= rf_empty;		
	end
end

always@(posedge clk) //WRITE DOMAIN SDRAM
begin
	if(rst)
	begin
		rf_rfull <= 1'b0;
		{rf_rp_grs [1], rf_rp_grs [0]} <= {16'b0, 16'b0};		
		rf_wp_gr <= 0;
	end
	else
	begin
		//write pointer logic
		if(!rf_full & rf_wr)
		begin
			rf_wp <= rf_wp + 1; //Increment counter
		end
		//Gray encoding register
		rf_wp_gr <= rf_wp_g;
	
		//Synchronize read gray encoding register data
		{rf_rp_grs [1], rf_rp_grs [0]} <= {rf_rp_gr, rf_rp_grs[1]};
	
		//FIFO Memory Write
		rf_mem[rf_wp [$clog2(rf_size)-1]] <= rf_w_data;

		//Register full flag
		rf_rfull <= rf_full;
	end
end

/////////////////////////////////////////////////
//Asynchronous read fifo
//
//Read from Wishbone FSM and Write from SDRAM FSM 
parameter wf_size = 4;
logic wf_rd; //Read fifo read signal
logic wf_wr; //Read fifo write signal
logic wf_r_data; //Read fifo read data bus
logic wf_w_data; //Read fifo write data bus
logic wf_empty; //Empty flag
logic wf_full; //Full flag
logic wf_rempty; //Registered empty flag
logic wf_wfull; //Registered full flag
reg [$clog2(wf_size):0] wf_wp; //Write pointer
reg [$clog2(wf_size):0] wf_rp; //Read pointer
wire [$clog2(wf_size):0] wf_wp_g; //Write pointer gray encoding
wire [$clog2(wf_size):0] wf_rp_g; //Read pointer gray encoding
reg [$clog2(wf_size):0] wf_wp_gr; //Write pointer gray encoding reg
reg [$clog2(wf_size):0] wf_rp_gr; //Read pointer gray encoding reg
reg [$clog2(wf_size):0] wf_wp_grs [1:0]; //Write pointer gray encoding reg synchronizer
reg [$clog2(wf_size):0] wf_rp_grs [1:0]; //Read pointer gray encoding reg synchronizer
reg [16:0] wf_mem [$clog2(2**wf_size)-1:0]; //Read fifo memory

//The cast of the addition has to be changed manually
assign wf_wp_g = (wf_wp ^ (2'(wf_wp + 2'b1) >> 1)); //Generate gray encoding
assign wf_rp_g = (wf_rp ^ (2'(wf_rp + 2'b1) >> 1)); //Generate gray encoding

//Generate empty flag
assign wf_empty = (wf_rp_g == wf_wp_grs [0]);

//Generate full flag
assign wf_full = (wf_wp_g == {~wf_rp_grs [0] [$clog2(wf_size):$clog2(wf_size)-1], wf_rp_grs [0][$clog2(wf_size)-2:0]});

always@(posedge clk) //READ DOMAIN WB
begin
	if(rst)
	begin
		wf_rempty <= 1'b1;
		{wf_wp_grs [1], wf_wp_grs [0]} <= {16'b0, 16'b0};		
		wf_rp_gr <= 0;
	end
	else
	begin
		//read pointer logic
		if(!wf_empty & wf_rd)
		begin
			wf_rp <= wf_rp + 1; //Increment counter
		end
		//Gray encoding register
		wf_rp_gr <= wf_rp_g;
	
		//Synchronize write gray encoding register data
		{wf_wp_grs [1], wf_wp_grs [0]} <= {wf_wp_gr, wf_wp_grs[1]};
	
		//FIFO Memory Read
		wf_r_data <= wf_mem[wf_rp [$clog2(rf_size)-1]];

		//Register empty flag
		wf_rempty <= wf_empty;		
	end
end

always@(posedge clk) //WRITE DOMAIN SDRAM
begin
	if(rst)
	begin
		wf_wfull <= 1'b0;
		{wf_rp_grs [1], wf_rp_grs [0]} <= {16'b0, 16'b0};		
		wf_wp_gr <= 0;
	end
	else
	begin
		//write pointer logic
		if(!wf_full & wf_wr)
		begin
			wf_wp <= wf_wp + 1; //Increment counter
		end
		//Gray encoding register
		wf_wp_gr <= wf_wp_g;
	
		//Synchronize read gray encoding register data
		{wf_rp_grs [1], wf_rp_grs [0]} <= {wf_rp_gr, wf_rp_grs[1]};
	
		//FIFO Memory Write
		wf_mem[wf_wp [$clog2(rf_size)-1]] <= wf_w_data;

		//Register full flag
		wf_wfull <= wf_full;
	end
end

//////////////////////////////////
//Wishbone BUS logic

reg [1:0] ff_synch_0;
reg [1:0] ff_synch_1;
reg [1:0] ff_synch_2;
wire synch_in_0; //REQ
wire synch_in_1; //ACK
wire synch_in_2; //WR

//REQ synchronizer
always@(posedge pll_clk)
begin
	ff_synch_0 <= {synch_in_0, ff_synch_0 [1:1]};
end

//ACK synchronizer
always@(posedge clk)
begin
	ff_synch_1 <= {synch_in_1, ff_synch_1 [1:1]}; 
end

//WR Synchronizers
always@(posedge pll_clk)
begin
	ff_synch_2 <= {synch_in_2, ff_synch_2 [1:1]}; 
end


typedef enum logic [3:0] { WB_IDDLE, CYCLE } wb_states_t;
wb_states_t wb_state = WB_IDDLE;

always@(posedge clk)
begin
	if(rst)
	begin
		wb_state = WB_IDDLE;
	end
	else
	begin
		case(wb_state)
			WB_IDDLE:
			begin
				
			end
			CYCLE:
			begin
				
			end
		endcase
	end
end


//////////////////////////////////
//SDRAM Controll Logic
//
parameter CL = 3'b010;
parameter ARC = 4096; //Auto refresh cycles
typedef enum logic [1:0] { ISSUE, INHIBIT } cmd_state_t; 
typedef enum logic [3:0] { IDDLE, REFRESH, ACTIVE, WRITE, READ, LOAD_REGISTER, PRECHARGE, I_PRECHARGE_A, I_AUTO_REFRESH_1, I_AUTO_REFRESH_2, POW, WAIT} states_t;
states_t state = IDDLE;
cmd_state_t cmd_state = ISSUE;

parameter FREQ = 100000000; //Frequency
//Power On Delay Time 
parameter tPDT = 100; //100 microseconds
//Cycles Until Statble
parameter CUS = (tPDT/((1/FREQ)*1000000));
//13 bit cycle counterp
reg [12:0] cycle_cnt;


parameter tRFC = 63;
parameter cRFC = tRFC/(1000000000/FREQ);
parameter tMRD = 2;

///////////////////////////////////////////////////
//              PRECHARGE COUNTER
parameter tRP = 20; //Time to precharge
parameter cRP = tRP/(1000000000/FREQ); //Clocks to precharge

///////////////////////////////////////////////////
// 				AUTO REFRESH COUNTER
parameter refresh_count = 6400000; //Refresh Count
reg [$clog2(refresh_count+10):0] auto_refresh_cnt;
reg refresh_sig; //Signal to autore fresh memory
reg ack_refresh;

//Data to be send to DQ
reg [15:0] FF_DQ;

always@(posedge pll_clk)
begin
	if(rst)
	begin
		auto_refresh_cnt <= 0;
	end
	else
	begin
		if(auto_refresh_cnt > refresh_count) //Will stay in this state until the counter is reseted
		begin
			if(ack_refresh) //Wait for ACK signal
			begin
				refresh_sig <= 0;
				auto_refresh_cnt <= 0;
			end
			else
			begin
				refresh_sig <= 1;				
			end
		end
		else
		begin
			auto_refresh_cnt <= auto_refresh_cnt + 1;		
		end
	end
end

//////////////////////////////////////////////////
//       SDRAM CONTROLLER STATE MACHINE

//State machine
always@(negedge clk)
begin
	if(rst)
	begin
		state = IDDLE;
	end
	else
	begin
		case(state)
			//INIT SEQUENCE
			POW:
			begin
				cycle_cnt <= 0;
				//Assing pins to nop state
				CS <= 1'b0;
				RAS <= 1'b1;
				CAS <= 1'b1;
				RWE <= 1'b1;

				DQM <= 2'b0;
				ADDR <= 12'b0;
				CKE <= 1'b1; 
				BA <= 0;
			end
			WAIT:
			begin
				//Wait a certain amount of cycles until stable
				if(cycle_cnt > CUS)
				begin
					state = IDDLE;
				end
				else
				begin
					cycle_cnt = cycle_cnt + 1;
				end
				//Keep pins on the NOP state
				CS <= 1'b0;
				RAS <= 1'b1;
				CAS <= 1'b1;
				RWE <= 1'b1;

				DQM <= 2'b0;
				ADDR <= 12'b0;
				CKE = 1'b1;
				BA <= 0;
				cmd_state = ISSUE;
			end
			I_PRECHARGE_A:
			begin
				case(cmd_state)
					ISSUE:
					begin
						//Issue precharge all command
						CS <= 1'b0;
						RAS <= 1'b0;
						CAS <= 1'b1;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						//Precharge all banks
						ADDR [10:10] <= 1;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter

						state <= state; //Stay on the same state
						cmd_state <= INHIBIT;
					end
					INHIBIT:
					begin
						//Keep pins in the inhibit state
						CS <= 1'b1;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter

						//Wait precharge time
						if(cycle_cnt < cRP)
						begin
							state <= state; //Stay on the same state
							cmd_state <= INHIBIT;
							//Increment cycle counter
							cycle_cnt <= cycle_cnt + 1;			
						end
						else
						begin
							state <= I_AUTO_REFRESH_1;
							cmd_state <= ISSUE;
						end
					end
					default:
					begin
						cmd_state <= ISSUE;
					end
				endcase
			end
			//The AUTO REFRESH command should not be issued until the minimum tRP has been met after the PRECHARGE com-mand, as shown in Bank/Row Activation 
			I_AUTO_REFRESH_1:
			begin
				case(cmd_state)
					ISSUE:
					begin
						//Issue AUTO REFRESH command
						CS <= 1'b0;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b1;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter
					end
					INHIBIT:
					begin
						//Keep pins in the inhibit state
						CS <= 1'b1;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter
					
						//Exit state when the tRFC time is met
						if(cycle_cnt < cRFC)
						begin
							state <= state; //Stay on the same state
							cmd_state <= INHIBIT;
							//Increment cycle counter
							cycle_cnt <= cycle_cnt + 1;			
						end
						else
						begin
							state <= I_AUTO_REFRESH_2;
							cmd_state <= ISSUE;
						end						
					end
				endcase
			end
			I_AUTO_REFRESH_2:
			begin
				case(cmd_state)
					ISSUE:
					begin
						//Issue AUTO REFRESH command
						CS <= 1'b0;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b1;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE <= 1'b1;
						BA <= 0; //The bank address doesnt matter

						cmd_state <= INHIBIT;
						state <= state;
					end
					INHIBIT:
					begin
						//Keep pins in the inhibit state
						CS <= 1'b1;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter
					
						//Exit state when the tRFC time is met
						if(cycle_cnt < cRFC)
						begin
							state <= state; //Stay on the same state
							cmd_state <= INHIBIT;
							//Increment cycle counter
							cycle_cnt <= cycle_cnt + 1;			
						end
						else
						begin
							state <= LOAD_REGISTER;
							cmd_state <= ISSUE;
						end						
					end
				endcase
			end
			LOAD_REGISTER:
			begin
				case(cmd_state)
					ISSUE:
					begin
						//All banks were set to IDDLE on the I_PRECHARGE_A state
						//ISSUE LMR command
						CS <= 1'b0;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						//Register configuration
						ADDR [2:0] <= 3'b111; //Full Page Burst
						ADDR [3:3] <= 1'b1; //Continous Burst 
						ADDR [6:4] <= CL; //Continous Burst 
						ADDR [8:7] <= 0;
						ADDR [9:9] <= 0; //Burst Read/Burst Write
						ADDR [11:10] <= 0;
		
						CKE <= 1'b1;
						BA <= 0;
		
						cmd_state <= INHIBIT;
						state <= state;
					end
					INHIBIT:
					begin
						//Keep pins in the inhibit state
						CS <= 1'b1;
						RAS <= 1'b0;
						CAS <= 1'b0;
						RWE <= 1'b0;
		
						DQM <= 2'b0;
						
						ADDR [10:10] <= 0;
						ADDR [9:0] <= 0;
						ADDR [11:11] <= 0;
		
						CKE = 1'b1;
						BA <= 0; //The bank address doesnt matter
					
						//Exit state when the tMRD time is met
						if(cycle_cnt < tMRD)
						begin
							state <= state; //Stay on the same state
							cmd_state <= INHIBIT;
							//Increment cycle counter
							cycle_cnt <= cycle_cnt + 1;			
						end
						else
						begin
							state <= IDDLE;
							cmd_state <= ISSUE;
						end						
					end
				endcase
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
			//The precharge command is used to deactivate a bank.
			PRECHARGE:
			begin

			end
		endcase
	end
end

assign CLK = pll_clk;

assign DQ = (state == WRITE)? FF_DQ : 16'bz; 

endmodule
