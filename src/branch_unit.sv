//Author: Benjamin Herrera Navarro
//Fri Jun 18, 6:53AM


//The logic inside this branch unit can be replaced with a space efficient implementation
module branch_unit
(
    input logic clk,
    input logic start,
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    input logic [2:0] funct3,
    output logic done,
    output logic jump
);

parameter BEQ = 3'b000;
parameter BNE = 3'b001;
parameter BLT = 3'b100;
parameter BGE = 3'b101;
parameter BLTU = 3'b110;
parameter BGEU = 3'b111;

typedef enum logic [2:0] { IDDLE, COMPARE } states_t;

states_t state = IDDLE; 
always @(posedge clk) begin
    unique case(state)
        IDDLE:
        begin
            state = COMPARE;
            done = 1'b0;
        end
        COMPARE:
        begin
            done = 1'b1;
            case(funct3)
                BEQ:
                begin
                    if($signed(rs1) == $signed(rs1))
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                end
                BNE:
                begin
                    if($signed(rs1) != $signed(rs1))
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                    
                end
                BLT:
                begin
                    if($signed(rs1) < $signed(rs1))
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                    
                end
                BGE:
                begin
                    if($signed(rs1) >= $signed(rs1))
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                    
                end
                BLTU:
                begin
                    if(rs1 < rs1)
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                    
                end
                BGEU:
                begin
                    if(rs1 >= rs1)
                        jump = 1'b1;
                    else
                        jump = 1'b0;
                    
                end
            endcase
        end
    endcase
end










endmodule