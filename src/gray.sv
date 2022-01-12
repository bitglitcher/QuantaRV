module gray();



reg  [3:0] counter;
wire  [3:0] gray;
logic  clk;

assign gray = (counter ^ (counter >> 1));

initial begin
    $dumpfile("gray.vcd");
    $dumpvars(gray);
    clk = 0;
    counter = 0;
    forever begin
        #10 clk = ~clk;
    end
end


always@(posedge clk)
begin
   counter = counter + 1; 
end

endmodule