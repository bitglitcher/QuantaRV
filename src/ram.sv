
module ram
#(parameter SIZE = 4096)

(
    input  logic        clk,
    output logic        ACK,
    output logic        ERR,
    output logic        RTY,
    input  logic        STB,
    input  logic        CYC,
    input  logic [31:0] ADR,
    output logic [31:0] DAT_I,
    input  logic [31:0] DAT_O,
    input  logic [2:0]  CTI_O,
    input  logic        WE
);


reg [31:0] mem [SIZE-1:0];

initial begin
    $readmemh("c_code/ROM.hex", mem);
end

always@(posedge clk)
begin
    if(CYC & STB)
    begin
        ACK = 1'b1;   
        RTY = 1'b0;   
        ERR = 1'b0;   
        if(WE)
        begin
            mem[ADR[31:2]] = DAT_O;            
        end
        else
        begin
            DAT_I = mem[ADR[31:2]];             
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