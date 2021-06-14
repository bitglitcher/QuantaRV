
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