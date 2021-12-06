
all: soc

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

cu: global_pkg.sv control_unit.sv full_adder.sv
	iverilog global_pkg.sv full_adder.sv control_unit.sv -g2012

soc: branch_unit.sv ram.sv alu.sv regfile.sv full_adder.sv control_unit.sv decoder.sv core.sv scmp.sv global_pkg.sv memory_access.sv soc.sv timer.sv uart.sv
	iverilog branch_unit.sv ram.sv global_pkg.sv alu.sv regfile.sv control_unit.sv decoder.sv full_adder.sv scmp.sv memory_access.sv core.sv soc.sv uart.sv timer.sv spi.sv -g2012

bu: branch_unit.sv branch_unit_tb.sv
	iverilog branch_unit.sv branch_unit_tb.sv -g2012