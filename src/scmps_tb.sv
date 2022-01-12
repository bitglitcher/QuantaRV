`timescale 1ps/1ps

module scmp_tb();



reg [31:0] A;
reg [31:0] B;
wire [32:0] AB;
wire [32:0] EQ;
wire [32:0] BA;

assign AB[0] = 0;
assign BA[0] = 0;
assign EQ[0] = 1;

wire OAB = (~A[31:31] & B[31:31])? 1'b1 : (A[31:31] & B[31:31])? BA[32:32] : AB [32:32];
wire OBA = (A[31:31] & ~B[31:31])? 1'b1 : (A[31:31] & B[31:31])? AB[32:32] : BA [32:32];
wire OEQ = EQ[32:32];

genvar i;
generate
    for(i = 0;i < 32;i++)
    begin : gen_block
        scmp scmp_generated
        (
            .a( A [i] ^ A[31:31] ),
            .b( B [i] ^ B[31:31] ),
            .eqi(EQ [i]),
            .bai(BA [i]),
            .abi(AB [i]),
            .ab( AB [i+1]),
            .eq( EQ [i+1]),
            .ba( BA[i+1])

        );

    end
endgenerate

reg clk = 0;

initial begin
    //$dumpfile("cas_cmp.vcd");
    //$dumpvars(0,scmp_tb);
    A = 0;
    B = 0;
    

    forever begin
        #10 clk = ~clk;
    end
end

always@(posedge clk)
begin
    if($urandom_range(0,20) < 8)
    begin
        A = $urandom();
        B = A;
    end
    else
    begin
        A = $urandom();
        B = $urandom();
    end
end

int passes = 0;
int eq_cov = 0;
int ba_cov = 0;
int ab_cov = 0;

always @(negedge clk) begin
    if($signed(A) == $signed(B))
    begin
        if(OEQ == 1)
        begin
            $display("EQ: PASS A: 0x%08x B: 0x%08x COV: AB %d BA %d EQ %d", A, B, ab_cov, ba_cov, eq_cov);
            passes = passes + 1;
            eq_cov = eq_cov + 1;
        end
        else
        begin
            $display("EQ: FAIL A: 0x%08x B: 0x%08x AT: %t", A, B, $time);
            #10
            $stop;
        end
    end
    else if($signed(A) < $signed(B))
    begin
        if((OBA == 1))
        begin
            $display("BA: PASS A: 0x%08x B: 0x%08x COV: AB %d BA %d EQ %d", A, B, ab_cov, ba_cov, eq_cov);
            passes = passes + 1;
            ba_cov = ba_cov + 1;
        end
        else
        begin
            $display("BA: FAIL A: 0x%08x B: 0x%08x", A, B);
            #10
            $stop;
        end
    end
    else if($signed(A) > $signed(B))
    begin
        if((OAB == 1))
        begin
            $display("AB: PASS A: 0x%08x B: 0x%08x COV: AB %d BA %d EQ %d", A, B, ab_cov, ba_cov, eq_cov);
            passes = passes + 1;
            ab_cov = ab_cov + 1;
        end
        else
        begin
            $display("AB: FAIL A: %d B: %d", $signed(A), $signed(B));
            #10
            $stop;
        end
    end
end


endmodule