
`timescale 1ps/1ps

module alu_testbench();

parameter ADD_OP =  4'b0000;
parameter SUB_OP =  4'b1000;
parameter SLL_OP =  4'b0001;
parameter SLT_OP =  4'b0010;
parameter SLTU_OP = 4'b0011;
parameter XOR_OP =  4'b0100;
parameter SRL_OP =  4'b0101;
parameter SRA_OP =  4'b1101;
parameter OR_OP =   4'b0110;
parameter AND_OP =  4'b0111;

reg clk;
reg [31:0] rs1;
reg [31:0] rs2;
wire [31:0] rd;
reg [3:0] op;
wire done;
reg start;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,alu_testbench);
    $display("------------Initializing------------");
    clk = 0;
    rs1 = 0;
    op = 0;
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
    .op(op),
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
                    op = ADD_OP;
                    op = ADD_OP;
                end

                SUB:
                begin
                    op = SUB_OP;
                    op = SUB_OP;
                end

                AND:
                begin
                    op = AND_OP;
                    op = AND_OP;
                end

                OR:
                begin
                    op = OR_OP;
                    op = OR_OP;
                end

                XOR:
                begin
                    op = XOR_OP;
                    op = XOR_OP;
                end

                SRL:
                begin
                    op = SRL_OP;
                    op = SRL_OP;
                end

                SLL:
                begin
                    op = SLL_OP;
                    op = SLL_OP;
                end

                SRA:
                begin
                    op = SRA_OP;
                    op = SRA_OP;
                end

                SLTU:
                begin
                    op = SLTU_OP;
                    op = SLTU_OP;
                end

                SLT:
                begin
                    op = SLT_OP;
                    op = SLT_OP;
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