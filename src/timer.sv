//Author: Benjamin Herrera Navarro
//Tue, Sep 16, 9:36AM


module timer
(
    input  logic        clk,
    input  logic        rst,
    output logic        ACK,
    output logic        ERR,
    output logic        RTY,
    input  logic        STB,
    input  logic        CYC,
    input  logic [31:0] ADR,
    output logic [31:0] DAT_I,
    input  logic [31:0] DAT_O,
    input  logic [2:0]  CTI_O,
    input  logic        WE,
    output logic        irq
);

reg [63:0] time_reg = 0;
reg [63:0] time_cmp = 0;

always @(posedge clk) begin
    time_reg = time_reg + 1;
end

//Set the irq signal when time contains a value greater than or equal to the value on timecmp 
assign irq = (time_reg >= time_cmp)? 1'b1 : 1'b0;

initial begin
    ACK = 1'b0;
    ERR = 1'b0;
    RTY = 1'b0;
end

always@(posedge clk)
begin
    if(STB & CYC)
    begin
        //Do not an ack signal when writting to the timer register or unaligned reads.
        ACK = (((ADR[3:0] >= 4'h0) & (ADR[3:0] <= 4'hc)) & ~(((ADR[3:0] == 4'h0) | (ADR[3:0] == 4'h4)) & WE) | (ADR[1:0] != 2'b00));
        //This device does not support unaligned reads, and send error if it tries to write to the time register.
        ERR = ((ADR[3:0] == 4'h0) & (ADR[3:0] == 4'h4) & WE) | (ADR[1:0] != 2'b00);
        RTY = 1'b0;
        //Always send the data on the posedge of the clock
        unique case(ADR[3:0])
            4'h0: DAT_I = time_reg [31:0]; 
            4'h4: DAT_I = time_reg [63:32];
            4'h8: DAT_I = time_cmp [31:0];
            4'hc: DAT_I = time_cmp [63:32];
        endcase
        if(WE)
        begin
            unique case(ADR[3:0])
                //4'h0: time_reg [31:0] = DAT_O; //Do not allow to write to this register
                //4'h4: time_reg [63:32] = DAT_O; //Do not allow to write to this register
                4'h8: time_cmp [31:0] = DAT_O; 
                4'hc: time_cmp [63:32] = DAT_O; 
            endcase
        end
    end
    else
    begin
        ACK = 1'b0;
        ERR = 1'b0;
        RTY = 1'b0;
    end
end

endmodule
