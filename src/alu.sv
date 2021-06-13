
//Fri Jun 4, 4:40PM


/*
Autor: Benjamin Herrera Navarro
Creado el dia 3/10/2020
Full Adder para la arquitectura D16i
6:34PM
*/

module full_adder
(
    input a,
    input b,
    input cin,
    output cout,
    output z
);

wire p;
wire r;
wire s;

xor(p, a, b);
xor(z, p, cin);
and(r, p, cin);
and(s, a, b);
or(cout, r, s);

endmodule

module alu
(
    input  logic        clk,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    output logic [31:0] rd,

    //input  logic [2:0] func3,
    //input  logic [6:0] func7,
    input [3:0] op,

    output logic done,
    input  logic start
);

//R type
parameter ADD =  4'b0000;
parameter SUB =  4'b1000;
parameter SLL =  4'b0001;
parameter SLT =  4'b0010;
parameter SLTU = 4'b0011;
parameter XOR =  4'b0100;
parameter SRL =  4'b0101;
parameter SRA =  4'b1101;
parameter OR =   4'b0110;
parameter AND =  4'b0111;

////R type
//parameter ADD =  10'b0000000000;
//parameter SUB =  10'b0100000000;
//parameter SLL =  10'b0000000001;
//parameter SLT =  10'b0000000010;
//parameter SLTU = 10'b0000000011;
//parameter XOR =  10'b0000000100;
//parameter SRL =  10'b0000000101;
//parameter SRA =  10'b0100000101;
//parameter OR =   10'b0000000110;
//parameter AND =  10'b0000000111;
////I type
//parameter ADDI =  10'b???????000;
//parameter SLTI =  10'b???????010;
//parameter SLTIU = 10'b???????011;
//parameter XORI =  10'b???????100;
//parameter ORI =   10'b???????110;
//parameter ANDI =  10'b???????111;
//parameter SLLI =  10'b???????001;
//parameter SRLI =  10'b0000000101;
//parameter SRAI =  10'b0100000101;

reg carry = 0;
wire cout;
reg [3:0]  op_r = 0;

reg [31:0] result = 0;
reg [5:0] index = 0;

typedef enum logic [3:0] { IDDLE, COMPUTE } alu_state_t;

alu_state_t state = IDDLE;

wire rs1_b = rs1[index[4:0]];
wire rs2_b = rs2[index[4:0]];
reg sub_enable;
wire add;
wire xor_w;
xor(xor_w, rs2_b, sub_enable);
full_adder full_adder_1
(
    .a(rs1_b),
    .b(xor_w),
    .cin(carry),
    .cout(cout),
    .z(add)
);

reg eqi;
reg bai;
reg abi;
wire ba;
wire ab;
wire eq;

//Use to togle the XOR 
reg ase; //a input sign enablein STL operations
reg bse; //b input sign enable

//keeps sign when shifing
reg signb;
//Enable to compare signed

scmp scmp_0(
    .a(rs1_b ^ ase),
    .b(rs2_b ^ bse),
    .eq(eq),
    .ba(ba),
    .ab(ab),
    .eqi(eqi),
    .bai(bai),
    .abi(abi)
);

always@(posedge clk)
begin
    case(state)
        IDDLE:
        begin
            done = 1'b0;
            //Initial Carry 1 if sub
            if(op == SUB)
            begin
                carry = 1'b1;
                sub_enable = 1'b1;
            end
            else
            begin
                carry = 1'b0;
                sub_enable = 1'b0;
            end
            if(op == SRA)
            begin
                signb = rs1[31:31];
            end

            if(op == SLT)
            begin
                ase = rs1[31:31];
                bse = rs2[31:31];
            end
            else
            begin
                ase = 1'b0;
                bse = 1'b0;
            end

            if(start)
            begin
                state = COMPUTE;
                op_r = op;
                index = 0;
                bai = 0;
                abi = 0;
                eqi = 1'b1;
            end 
        end
        COMPUTE:
        begin
            if((op_r == SRL) | (op_r == SRA))
            begin
                if(index >= (31 + rs2[4:0]))
                begin
                    state = IDDLE;
                    done = 1'b1;
                end
            end
            else if((op_r == SLTU) | (op_r == SLT))
            begin
                if(index == 62)
                begin
                    state = IDDLE;
                    done = 1'b1;
                end
            end
            else if(index == 31)
            begin
                state = IDDLE;
                done = 1'b1;
            end

            index = index + 1;
            carry = cout;
            eqi = eq;
            bai = ba;
            abi = ab;
        end
    endcase

end

always@(negedge clk)
begin
    case(state)
        COMPUTE:
        begin
            case(op_r)
                ADD, SUB:
                begin
                    result[31:0] = {add, result[31:1]};
                end
                SLL:
                begin
                    if(index < rs2[4:0])
                    begin
                        result[31:0] = {1'b0, result[31:1]};
                    end
                    else
                    begin
                        result[31:0] = {rs1[index[4:0]-rs2[4:0]], result[31:1]};
                    end
                end
                SLT:
                begin
                    if(index == 31)
                    begin
                        if((rs1_b == 1) & (rs2_b == 0))
                        begin
                            result[31:0] = {1'b1, result[31:1]};
                        end
                        else if((rs1_b == 0) & (rs2_b == 1))
                        begin
                            result[31:0] = {1'b0, result[31:1]};
                        end
                        else
                        begin
                            result[31:0] = {(ase & bse)? ab : ba, result[31:1]};
                        end
                    end
                    else
                    begin
                        result[31:0] = {1'b0, result[31:1]};
                    end
                end
                SLTU:
                begin
                    if(index == 31)
                    begin
                        result[31:0] = {ba, result[31:1]};
                    end
                    else
                    begin
                        result[31:0] = {1'b0, result[31:1]};
                    end
                end
                //SLTU: rd_d = (ra_d < rb_d) ? 32'h00000001 : 32'h00000000;
                XOR: 
                begin
                    result[31:0] = {rs1_b ^ rs2_b, result[31:1]};
                end
                SRL: 
                begin
                    if(index > 31)
                    begin
                        result[31:0] = {1'b0, result[31:1]};
                    end
                    else
                    begin
                        result[31:0] = {rs1_b, result[31:1]};
                    end
                end
                SRA: 
                begin
                    if(index > 31)
                    begin
                        result[31:0] = {signb, result[31:1]};
                    end
                    else
                    begin
                        result[31:0] = {rs1_b, result[31:1]};
                    end
                end
                OR: 
                begin
                    result[31:0] = {rs1_b | rs2_b, result[31:1]};
                end
                AND: 
                begin
                    result[31:0] = {rs1_b & rs2_b, result[31:1]};
                end
                //default: rd_d = 32'h00000000;
            endcase
        end
    endcase
end


assign rd = result;

wire [31:0] diff_bus = (result ^ (rs1 + rs2));

endmodule