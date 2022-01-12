//10:32PM
//Sat JUN 5 2021
//Author: Benjamin Herrera Navarro
//Cascadable 1bit comparator for the QuantaRV Core

module cas_mag_cmp
(
    input A,
    input B,
    input ABI,
    input BAI,
    output AB,
    output EQ,
    output BA
);

assign EQ = (~(ABI | BAI) & (A == B));
assign AB = (ABI | (~BAI & (B<A)));
assign BA = (BAI | (~ABI & (B>A)));

endmodule