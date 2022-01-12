
`timescale 1ps/1ps

module alu_testbench();

parameter ADD_F3 =  3'b000;
parameter ADD_F7 =  7'b0000000;
parameter SUB_F3 =  3'b000;
parameter SUB_F7 =  7'b0100000;
parameter SLL_F3 =  3'b001;
parameter SLL_F7 =  7'b0000000;
parameter SLT_F3 =  3'b010;
parameter SLT_F7 =  7'b0000000;
parameter SLTU_F3 = 3'b011;
parameter SLTU_F7 = 7'b0000000;
parameter XOR_F3 =  3'b100;
parameter XOR_F7 =  7'b0000000;
parameter SRL_F3 =  3'b101;
parameter SRL_F7 =  7'b0000000;
parameter SRA_F3 =  3'b101;
parameter SRA_F7 =  7'b0100000;
parameter OR_F3  =  3'b110;
parameter OR_F7  =  7'b0000000;
parameter AND_F3 =  3'b111;
parameter AND_F7 =  7'b0000000;
//I type
parameter ADDI =  10'b???????000;
parameter SLTI =  10'b???????010;
parameter SLTIU = 10'b???????011;
parameter XORI =  10'b???????100;
parameter ORI =   10'b???????110;
parameter ANDI =  10'b???????111;
parameter SLLI =  10'b???????001;
parameter SRLI =  10'b0000000101;
parameter SRAI =  10'b0100000101;

reg clk;
reg [31:0] rs1;
reg [31:0] rs2;
wire [31:0] rd;
reg [2:0] op;
wire done;
reg start;

reg [2:0] func3;
reg [6:0] func7;
reg imm_t;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,alu_testbench);
    $display("------------Initializing------------");
    clk = 0;
    rs1 = 0;
    func3 = 0;
    func7 = 0;
    imm_t = 0;
    rs2 = 0;
    start = 0;
    $display("----------Done Initializing---------");
    forever begin
        #10 clk = ~clk; 
    end
end

alu alu0
(
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .func3(func3),
    .func7(func7),
    .imm_t(imm_t),
    .done(done),
    .start(start)
);


typedef enum logic[3:0] { START, WAIT, SCORE } states_t;

typedef enum logic[3:0] { ADD, SUB, AND, OR, XOR, SRL, SLL, SRA, SLTU, SLT} test_ops_t;

test_ops_t test_ops = ADD;

states_t state = START;

parameter N_TESTS = 32;

reg [31:0] counter = 0;

task automatic print_error(rd, rs1, rs2);
    $display("Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 + rs2);
    $display("S1: 0B%b", rs1);
    $display("S2: 0B%b", rs2);
    $display("RD: 0B%b", rd);
    $display("EX: 0B%b XOR", rs1 + rs2);
    $display("----------------------------------");
    $display("DF: 0B%b", rd ^ (rs1 + rs2));
endtask //automatic

always@(negedge clk)
begin
    case(state)
        START:
        begin
            start = 1'b1;
            state = WAIT;
            case(test_ops)
                ADD:
                begin
                    func3 = ADD_F3;
                    func7 = ADD_F7;
                end

                SUB:
                begin
                    func3 = SUB_F3;
                    func7 = SUB_F7;
                end

                AND:
                begin
                    func3 = AND_F3;
                    func7 = AND_F7;
                end

                OR:
                begin
                    func3 = OR_F3;
                    func7 = OR_F7;
                end

                XOR:
                begin
                    func3 = XOR_F3;
                    func7 = XOR_F7;
                end

                SRL:
                begin
                    func3 = SRL_F3;
                    func7 = SRL_F7;
                end

                SLL:
                begin
                    func3 = SLL_F3;
                    func7 = SLL_F7;
                end

                SRA:
                begin
                    func3 = SRA_F3;
                    func7 = SRA_F7;
                end

                SLTU:
                begin
                    func3 = SLTU_F3;
                    func7 = SLTU_F7;
                end

                SLT:
                begin
                    func3 = SLT_F3;
                    func7 = SLT_F7;
                end

            endcase
        end
        WAIT:
        begin
            start = 1'b0;
            if(done)
            begin
                case(test_ops)
                    ADD:
                    begin
                        if(rd == (rs1 + rs2))
                        begin
                            $display("ADD PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 + rs2);
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                //$stop;
                                test_ops = SUB;
                                counter = 0;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("ADD Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 + rs2);
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 + rs2);
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 + rs2));
                            $stop;
                        end
                    end

                    SUB:
                    begin
                        if(rd == (rs1 - rs2))
                        begin
                            $display("SUB PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 - rs2);
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                test_ops = AND;
                                counter = 0;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SUB Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 - rs2);
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 - rs2);
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 - rs2));
                            $stop;
                        end
                    end

                    AND:
                    begin
                        if(rd == (rs1 & rs2))
                        begin
                            $display("AND PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 & rs2);
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                test_ops = OR;
                                counter = 0;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("AND Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 & rs2);
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 & rs2);
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 & rs2));
                            $stop;
                        end
                    end

                    OR:
                    begin
                        if(rd == (rs1 | rs2))
                        begin
                            $display("OR PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 | rs2);
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                test_ops = XOR;
                                counter = 0;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("OR Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 | rs2);
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 | rs2);
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 | rs2));
                            $stop;
                        end
                    end
                    XOR:
                    begin
                        if(rd == (rs1 ^ rs2))
                        begin
                            $display("XOR PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 ^ rs2);
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = SRL;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("XOR Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 ^ rs2);
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 ^ rs2);
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 ^ rs2));
                            $stop;
                        end
                    end
                    SRL:
                    begin
                        if(rd == (rs1 >> (rs2 & 5'b11111)))
                        begin
                            $display("SRL PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 >> (rs2 & 5'b11111));
                            rs1 = $urandom();
                            rs2 = ($urandom() & 5'b11111);
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = SLL;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SRL Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 >> (rs2 & 5'b11111));
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2 & 5'b11111);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 >> (rs2 & 5'b11111));
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 >> (rs2 & 5'b11111)));
                            $stop;
                        end
                    end
                    SLL:
                    begin
                        if(rd == (rs1 << (rs2 & 5'b11111)))
                        begin
                            $display("SLL PASS: RD value is 0x%08x and expected 0x%08x", rd, rs1 << (rs2 & 5'b11111));
                            rs1 = $urandom();
                            rs2 = ($urandom() & 5'b11111);
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = SRA;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SLL Error: RD value is 0x%08x but expected 0x%08x", rd, rs1 << (rs2 & 5'b11111));
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2 & 5'b11111);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", rs1 << (rs2 & 5'b11111));
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ (rs1 << (rs2 & 5'b11111)));
                            $stop;
                        end
                    end
                    SRA:
                    begin
                        if($signed(rd) == ($signed(rs1) >>> (rs2 & 5'b11111)))
                        begin
                            $display("SRA PASS: RD value is 0x%08x and expected 0x%08x", rd, $signed(rs1) >>> (rs2 & 5'b11111));
                            rs1 = $urandom();
                            rs2 = ($urandom() & 5'b11111);
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = SLTU;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SRA Error: RD value is 0x%08x but expected 0x%08x", rd, $signed(rs1) >>> (rs2 & 5'b11111));
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2 & 5'b11111);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", $signed(rs1) >>> (rs2 & 5'b11111));
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ ($signed(rs1) >>> (rs2 & 5'b11111)));
                            $stop;
                        end
                    end
                    SLTU:
                    begin
                        if(rd == ($unsigned(rs1) < $unsigned(rs2)))
                        begin
                            $display("SLTU PASS: RD value is 0x%08x and expected 0x%08x", rd, ($unsigned(rs1) < $unsigned(rs2)));
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = SLT;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SLTU Error: RD value is 0x%08x but expected 0x%08x", rd, ($unsigned(rs1) < $unsigned(rs2)));
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", 32'($unsigned(rs1) < $unsigned(rs2)));
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ ($unsigned(rs1) < $unsigned(rs2)));
                            $stop;
                        end
                    end
                    SLT:
                    begin
                        if(rd == ($signed(rs1) < $signed(rs2)))
                        begin
                            $display("SLT PASS: RD value is 0x%08x and expected 0x%08x", rd, ($signed(rs1) < $signed(rs2)));
                            rs1 = $urandom();
                            rs2 = $urandom();
                            if(counter > N_TESTS)
                            begin
                                counter = 0;
                                test_ops = ADD;
                            end
                            counter = counter + 1;
                        end
                        else 
                        begin
                            $display("SLT Error: RD value is 0x%08x but expected 0x%08x", rd, ($signed(rs1) < $signed(rs2)));
                            $display("S1: 0B%b", rs1);
                            $display("S2: 0B%b", rs2);
                            $display("RD: 0B%b", rd);
                            $display("EX: 0B%b XOR", 32'($signed(rs1) < $signed(rs2)));
                            $display("----------------------------------");
                            $display("DF: 0B%b", rd ^ ($signed(rs1) < $signed(rs2)));
                            $stop;
                        end
                    end

                endcase
                state = START;
            end
        end
    endcase
end

endmodule