`timescale 1ps/1ps

module cas_mag_cmp_tb();



reg [31:0] A;
reg [31:0] B;
wire [32:0] AB;
wire [32:0] EQ;
wire [32:0] BA;

assign AB[0] = 0;
assign BA[0] = 0;
assign EQ[0] = 0;

genvar i;
generate
    for(i = 0;i < 32;i++)
    begin : gen_block
        cas_mag_cmp cas_mag_cmp_generated
        (
            .A(A [31-i]),
            .B(B [31-i]),
            .ABI(AB [i]),
            .BAI(BA [i]),
            .AB(AB [i+1]),
            .EQ(EQ [i+1]),
            .BA(BA[i+1])
        );

    end
endgenerate

reg clk = 0;

initial begin
    $dumpfile("cas_cmp.vcd");
    $dumpvars(0,cas_mag_cmp_tb);
    A = 0;
    B = 0;
    

    forever begin
        #10 clk = ~clk;
    end
end

always@(posedge clk)
begin
    if($urandom_range(0,20) < 10)
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
    if((EQ[32] == 1))
    begin
        if((A == B))
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
    else if((BA[32] == 1))
    begin
        if((A < B))
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
    else if((AB[32] == 1))
    begin
        if((A >B))
        begin
            $display("AB: PASS A: 0x%08x B: 0x%08x COV: AB %d BA %d EQ %d", A, B, ab_cov, ba_cov, eq_cov);
            passes = passes + 1;
            ab_cov = ab_cov + 1;
        end
        else
        begin
            $display("AB: FAIL A: 0x%08x B: 0x%08x", A, B);
            #10
            $stop;
        end
    end
end


endmodule