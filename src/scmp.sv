//Sun Jun 6, 5:32PM
//Author: Benjamin Herrera Navarro

//GLEL
//EGEG
//0 1 0 0 0
//0 0 1 0 1


module scmp(
    input a,
    input b,
    output eq,
    output ba,
    output ab,
    input eqi,
    input bai,
    input abi
);

assign eq = ((a == b) & eqi);
assign ba = (a == b)? bai : (b > a);
assign ab = (a == b)? abi : (a > b);

endmodule