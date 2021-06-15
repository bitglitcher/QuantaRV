//Author: Benjamin Herrera Navarro 
//Sun, Jun, 13 
//8:54AM


`timescale 1ps/1ps

import global_pkg::*;

module memory_access_tb();



logic clk;
logic rst;

//Control signals
memory_operation_t memory_operation = LOAD_DATA;
logic cyc;
logic ack;
logic err; //This signal tells the control unit that there was an error.
logic data_valid; //This is needed for the load instruction
logic [2:0] funct3;

//Data
logic [31:0] store_data;
logic [31:0] address;
logic [31:0] load_data;

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

reg [7:0] memory [7:0];

//Memory probes
wire [31:0] memory_l = {memory[3], memory[2], memory[1], memory[0]}; 
wire [31:0] memory_h = {memory[7], memory[6], memory[5], memory[4]};

initial begin
    $dumpfile("memory_access_tb.vcd");
    $dumpvars(0,memory_access_tb);
    funct3 = 0;
    cyc = 0;
    clk = 0;    
    //Initialize memory with random values
    memory[0] = $random();
    memory[1] = $random();
    memory[2] = $random();
    memory[3] = $random();
    memory[4] = $random();
    memory[5] = $random();
    memory[6] = $random();
    memory[7] = $random();
    address = $random();
    store_data = $random();
    forever begin
        #10 clk = ~clk;
    end
end

memory_access memory_access_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .err(err), //This signal tells the control unit that there was an error.
    .data_valid(data_valid), //This is needed for the load instruction
    .funct3(funct3),

    //Data
    .store_data(store_data),
    .address(address),
    .load_data(load_data),

    //Wishbone interface
    //WB4.master data_bus There is not support for interfaces in icarus

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

typedef enum logic [1:0] { IDDLE, WAIT} state_t;

state_t state = IDDLE;

//Memory access, these are the opcodes of the load and store instructions
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;

parameter TEST_COUNT = 32; //Number of tests per OP

reg [31:0] test_cnt = 0;

always@(negedge clk)
begin

    case(state)
        IDDLE:
        begin
            cyc = 1'b1; //Start the access cycle
            if(ack)
            begin
                //waits until the memory access unit finishes fetching data
                state = WAIT; 
            end
            //Set the memory access unit into store mode 
        end
        WAIT:
        begin
            cyc = 1'b0;
            //Wait until data valid
            if(data_valid)
            begin
                //Check if data was loaded corretly
                case(funct3)
                    LB:
                    begin
                        //First align data accordingly to the address;
                        if(load_data == 32'($signed(memory[address[2:0]]))) 
                        begin
                            $display("LB PASS: Got value 0x%08x, and expected 0x%08x", load_data, 32'($signed(memory[address[2:0]])));
                            //Initialize memory with random values
                            memory[0] = $random();
                            memory[1] = $random();
                            memory[2] = $random();
                            memory[3] = $random();
                            memory[4] = $random();
                            memory[5] = $random();
                            memory[6] = $random();
                            memory[7] = $random();
                            address = $random();
                            state = IDDLE;
                            if(test_cnt > TEST_COUNT)
                            begin
                                funct3 = LH;
                                test_cnt = 0;
                            end
                            else
                            begin
                                test_cnt = test_cnt + 1;
                            end
                        end
                        else
                        begin
                            $display("LB Error: Got value 0x%08x, and expected 0x%08x", load_data, 32'($signed(memory[address[2:0]])));
                            $stop;
                        end
                    end
                    LH:
                    begin
                        //First align data accordingly to the address;
                        if(load_data == 32'($signed({memory[3'(address[2:0])+3'b1], memory[address[2:0]]}))) 
                        begin
                            $display("LH PASS: Got value 0x%08x, and expected 0x%08x", load_data, 32'($signed({memory[3'(address[2:0])+3'b1], memory[address[2:0]]})));
                            //Initialize memory with random values
                            memory[0] = $random();
                            memory[1] = $random();
                            memory[2] = $random();
                            memory[3] = $random();
                            memory[4] = $random();
                            memory[5] = $random();
                            memory[6] = $random();
                            memory[7] = $random();
                            address = $random();
                            state = IDDLE;
                            if(test_cnt > TEST_COUNT)
                            begin
                                funct3 = LW;
                                test_cnt = 0;
                            end
                            else
                            begin
                                test_cnt = test_cnt + 1;
                            end
                        end
                        else
                        begin
                            $display("LH Error: Got value 0x%08x, and expected 0x%08x", load_data, 32'($signed({memory[3'(address[2:0])+3'b1], memory[address[2:0]]})));
                            $stop;
                        end                        
                    end
                    LW:
                    begin
                        //First align data accordingly to the address;
                        if(load_data == {memory[3'(address[2:0])+3'b11], memory[3'(address[2:0])+3'b10], memory[3'(address[2:0])+3'b1], memory[address[2:0]]}) 
                        begin
                            $display("LW PASS: Got value 0x%08x, and expected 0x%08x", load_data, {memory[3'(address[2:0])+3'b11], memory[3'(address[2:0])+3'b10], memory[3'(address[2:0])+3'b1], memory[address[2:0]]});
                            //Initialize memory with random values
                            memory[0] = $random();
                            memory[1] = $random();
                            memory[2] = $random();
                            memory[3] = $random();
                            memory[4] = $random();
                            memory[5] = $random();
                            memory[6] = $random();
                            memory[7] = $random();
                            address = $random();
                            state = IDDLE;
                            if(test_cnt > TEST_COUNT)
                            begin
                                funct3 = LBU;
                                test_cnt = 0;
                            end
                            else
                            begin
                                test_cnt = test_cnt + 1;
                            end
                        end
                        else
                        begin
                            $display("LW Error: Got value 0x%08x, and expected 0x%08x", load_data, {memory[3'(address[2:0])+3'b11], memory[3'(address[2:0])+3'b10], memory[3'(address[2:0])+3'b1], memory[address[2:0]]});
                            $stop;
                        end                        
                    end
                    LBU:
                    begin
                        //First align data accordingly to the address;
                        if(load_data == 32'(memory[address[2:0]])) 
                        begin
                            $display("LBU PASS: Got value 0x%08x, and expected 0x%08x", load_data, 32'(memory[address[2:0]]));
                            //Initialize memory with random values
                            memory[0] = $random();
                            memory[1] = $random();
                            memory[2] = $random();
                            memory[3] = $random();
                            memory[4] = $random();
                            memory[5] = $random();
                            memory[6] = $random();
                            memory[7] = $random();
                            address = $random();
                            state = IDDLE;
                            if(test_cnt > TEST_COUNT)
                            begin
                                funct3 = LHU;
                                test_cnt = 0;
                            end
                            else
                            begin
                                test_cnt = test_cnt + 1;
                            end
                        end
                        else
                        begin
                            $display("LBU Error: Got value 0x%08x, and expected 0x%08x", load_data, 32'(memory[address[2:0]]));
                            $stop;
                        end
                    end
                    LHU:
                    begin
                        //First align data accordingly to the address;
                        if(load_data == 32'({memory[3'(address[2:0])+3'b1], memory[address[2:0]]})) 
                        begin
                            $display("LHU PASS: Got value 0x%08x, and expected 0x%08x", load_data, 32'({memory[3'(address[2:0])+3'b1], memory[address[2:0]]}));
                            //Initialize memory with random values
                            memory[0] = $random();
                            memory[1] = $random();
                            memory[2] = $random();
                            memory[3] = $random();
                            memory[4] = $random();
                            memory[5] = $random();
                            memory[6] = $random();
                            memory[7] = $random();
                            address = $random();
                            store_data = $random();
                            state = IDDLE;
                            if(test_cnt > TEST_COUNT)
                            begin
                                funct3 = SB;
                                test_cnt = 0;
                            end
                            else
                            begin
                                test_cnt = test_cnt + 1;
                            end
                        end
                        else
                        begin
                            $display("LHU Error: Got value 0x%08x, and expected 0x%08x", load_data, 32'({memory[3'(address[2:0])+3'b1], memory[address[2:0]]}));
                            $stop;
                        end                        
                    end
                    SB:
                    begin
                        bit [7:0] memory_tmp [7:0];
                        memory_tmp[0] = memory[0];
                        memory_tmp[1] = memory[1];
                        memory_tmp[2] = memory[2];
                        memory_tmp[3] = memory[3];
                        memory_tmp[4] = memory[4];
                        memory_tmp[5] = memory[5];
                        memory_tmp[6] = memory[6];
                        memory_tmp[7] = memory[7];
                        //Modify correspoding byte
                        memory_tmp[address[2:0]] = store_data[7:0];

                        //Compare memory modified by the testbench to that of the memory_access unit
                        if(done)
                        begin
                            
                        end
                    end
                    SH:
                    begin
                        
                    end
                    SW:
                    begin
                        
                    end
                endcase
                //Else post error
            end
        end
    endcase
end



//Handdle memory access requests
assign DAT_I = {memory[{ADR[2:2], 2'b0} + 3'h3], memory[{ADR[2:2], 2'b0} + 3'h2], memory[{ADR[2:2], 2'b0} + 3'h1], memory[{ADR[2:2], 2'b0}]}; 


always@(posedge clk)
begin
    if(CYC & STB)
    begin
        ACK = 1'b1;   
        RTY = 1'b0;   
        ERR = 1'b0;   
        if(WE)
        begin
            {memory[address[1:0]+3'h3], memory[address[1:0]+3'h2], memory[address[1:0]+3'h1], memory[address[1:0]]} = DAT_O;
        end
    end
    else
    begin        
        ACK = 1'b0;   
        RTY = 1'b0;   
        ERR = 1'b0;   
    end
end

endmodule