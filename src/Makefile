
all: maus

alu: alu.sv alu_testbench.sv scmp.sv full_adder.sv
	iverilog alu.sv alu_testbench.sv full_adder.sv scmp.sv -g2012

cmp: cas_mag_cmp.sv cas_mag_cmp_tb.sv
	iverilog cas_mag_cmp.sv cas_mag_cmp_tb.sv -g2012

scmp: scmp.sv scmp_tb.sv
	iverilog scmp.sv scmp_tb.sv -g2012

scmps: scmp.sv scmps_tb.sv
	iverilog scmp.sv scmps_tb.sv -g2012


maus: wishbone.sv global_pkg.sv memory_access.sv full_adder.sv memory_access_tb.sv
	iverilog wishbone.sv global_pkg.sv memory_access.sv full_adder.sv memory_access_tb.sv -g2012
