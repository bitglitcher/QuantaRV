

//Author: Benjamin Herrera Navarro
//Tue Jun 15
//4:42PM

import global_pkg::*;

module control_unit
(
    input clk,
    input rst,

    //Control signals for the memory access unit
    output memory_operation_t memory_operation,
    output logic cyc,
    input  logic ack,
    input  logic err, //This signal tells the control unit that there was an error.
    input  logic done, //signals that the operations was completed
    input  logic data_valid, //This is needed for the load instruction
    output logic [2:0] funct3_cu,
    //Data signal to and from the memory access unit
    input logic [31:0] fetched_data,
    output logic [31:0] pc,
    output logic [31:0] ir,

    //Register file input source
    output regfile_src_t regfile_src,

    //Register file write control signal
    output logic wr,

    //ALU control signals
    output logic [3:0] op,
    output logic start,
    input  logic alu_done,

    //ALU input 2, data source
    output sr2_src_t sr2_src,
    output sr1_src_t sr1_src,
    input logic [31:0] alu_result,

    //Control signals for the branch unit
    output logic  bu_start,
    input  logic  bu_done,
    input  logic  jump,

    input logic [31:0] [31:0] debug_reg,

    output logic [31:0] csr_out, //This data bus goes to the Register file to read data from the CSRs
    input logic [31:0] rs1_d,    //This data bus comes from the register file to write data to the CSRs

    //Timer interrupt input
    input timer_interrupt,
    input external_interrupt
);

//Instruction Opcodes
parameter LOAD   = 7'b0000011;
parameter STORE  = 7'b0100011;
parameter OP_IMM = 7'b0010011;
parameter OP     = 7'b0110011;
parameter BRANCH = 7'b1100011;
parameter AUIPC  = 7'b0010111;
parameter LUI    = 7'b0110111;
parameter JAL    = 7'b1101111;
parameter JALR   = 7'b1100111;
parameter SYSTEM = 7'b1110011;

parameter ECALL = 12'b000000000000;
parameter EBREAK = 12'b000000000001;
parameter PRIV = 3'b000;

parameter URET = 12'b000000000010;
parameter SRET = 12'b000100000010;
parameter MRET = 12'b001100000010;

//Zcsr instruction opcodes
// csr  rs1 001 rd 1110011 CSRRW
// csr  rs1 010 rd 1110011 CSRRS
// csr  rs1 011 rd 1110011 CSRRC
// csru imm 101 rd 1110011 CSRRWI
// csru imm 110 rd 1110011 CSRRSI
// csru imm 111 rd 1110011 CSRRCI

//Note, this are part of the SYSTEM opcode. These are the funct3 opcodes.
parameter CSRRW = 3'b001;
parameter CSRRS = 3'b010;
parameter CSRRC = 3'b011;
parameter CSRRWI = 3'b101;
parameter CSRRSI = 3'b110;
parameter CSRRCI = 3'b111;


//Reset vector, this is the address at which the PC resets to
parameter RESET_VECTOR = 32'h00000000;//32'h80000000;

reg [5:0] count = 0;
reg [31:0] IR = 0;
reg [31:0] PC = 0;
reg [31:0] CSRS [12'hfff:12'h0];

//////////////////////////////////////////////////////////
//               Machine Mode CSR Addresses             //
//////////////////////////////////////////////////////////
//CSR register parameters
//Machine Information ---- These are not registers, but hardcoded values into the CPU.
parameter mvendorid = 12'hF11; //0xF11 MRO mvendorid Vendor ID.
parameter marchid = 12'hF12; //0xF12 MRO marchid Architecture ID.
parameter mimpid = 12'hF13; //0xF13 MRO mimpid Implementation ID.
parameter mhartid = 12'hF14; //0xF14 MRO mhartid Hardware thread ID.
//Machine Trap Setup
parameter mstatus = 12'h300;//0x300 MRW mstatus Machine status register.
parameter misa = 12'h301;//0x301 MRW misa ISA and extensions
parameter medeleg = 12'h302;//0x302 MRW medeleg Machine exception delegation register.
parameter mideleg = 12'h303;//0x303 MRW mideleg Machine interrupt delegation register.
parameter mie = 12'h304;//0x304 MRW mie Machine interrupt-enable register.
parameter mtvec = 12'h305;//0x305 MRW mtvec Machine trap-handler base address.
parameter mcounteren = 12'h306;//0x306 MRW mcounteren Machine counter enable.
//Machine Trap Handling
parameter mscratch = 12'h340;//0x340 MRW mscratch Scratch register for machine trap handlers.
parameter mepc = 12'h341;//0x341 MRW mepc Machine exception program counter.
parameter mcause = 12'h342;//0x342 MRW mcause Machine trap cause.
parameter mtval = 12'h343;//0x343 MRW mtval Machine bad address or instruction.
parameter mip = 12'h344;//0x344 MRW mip Machine interrupt pending.
//Machine Memory Protection
parameter pmpcfg0 = 12'h3A0;//0x3A0 MRW pmpcfg0 Physical memory protection configuration.
parameter pmpcfg1 = 12'h3A1;//0x3A1 MRW pmpcfg1 Physical memory protection configuration, RV32 only.
parameter pmpcfg2 = 12'h3A2;//0x3A2 MRW pmpcfg2 Physical memory protection configuration.
parameter pmpcfg3 = 12'h3A3;//0x3A3 MRW pmpcfg3 Physical memory protection configuration, RV32 only.
parameter pmpaddr0 = 12'h3B0;//0x3B0 MRW pmpaddr0 Physical memory protection address register.
parameter pmpaddr1 = 12'h3B1;//0x3B1 MRW pmpaddr1 Physical memory protection address register.
parameter pmpaddr2 = 12'h3B2;//0x3B2 MRW pmpaddr2 Physical memory protection address register.
parameter pmpaddr3 = 12'h3B3;//0x3B3 MRW pmpaddr3 Physical memory protection address register.
parameter pmpaddr4 = 12'h3B4;//0x3B4 MRW pmpaddr4 Physical memory protection address register.
parameter pmpaddr5 = 12'h3B5;//0x3B5 MRW pmpaddr5 Physical memory protection address register.
parameter pmpaddr6 = 12'h3B6;//0x3B6 MRW pmpaddr6 Physical memory protection address register.
parameter pmpaddr7 = 12'h3B7;//0x3B7 MRW pmpaddr7 Physical memory protection address register.
parameter pmpaddr8 = 12'h3B8;//0x3B8 MRW pmpaddr8 Physical memory protection address register.
parameter pmpaddr9 = 12'h3B9;//0x3B9 MRW pmpaddr9 Physical memory protection address register.
parameter pmpaddr10 = 12'h3BA;//0x3BA MRW pmpaddr10 Physical memory protection address register.
parameter pmpaddr11 = 12'h3BB;//0x3BB MRW pmpaddr11 Physical memory protection address register.
parameter pmpaddr12 = 12'h3BC;//0x3BC MRW pmpaddr12 Physical memory protection address register.
parameter pmpaddr13 = 12'h3BD;//0x3BD MRW pmpaddr13 Physical memory protection address register.
parameter pmpaddr14 = 12'h3BE;//0x3BE MRW pmpaddr14 Physical memory protection address register.
parameter pmpaddr15 = 12'h3BF;//0x3BF MRW pmpaddr15 Physical memory protection address register.

//Table 2.4: Currently allocated RISC-V machine-level CSR addresses.
//Volume II: RISC-V Privileged Architectures V20190608-Priv-MSU-Ratified 11
//Number Privilege Name Description

//This are the different machine performance monitoring events
parameter EVENT_BRANCH = 31'h00000000;
parameter EVENT_MEMORY = 31'h00000001;
parameter EVENT_ALUOPS = 31'h00000002;
parameter EVENT_FENCES = 31'h00000003;
parameter EVENT_ASCINT = 31'h00000004;
parameter EVENT_SCHINT = 31'h00000005;
parameter EVENT_BREAKS = 31'h00000006;
parameter EVENT_ECALLS = 31'h00000007;


//Machine Counter/Timers
parameter mcycle = 12'hB00;//0xB00 MRW mcycle Machine cycle counter.
parameter minstret = 12'hB02;//0xB02 MRW minstret Machine instructions-retired counter.
parameter mhpmcounter3 = 12'hB03;//0xB03 MRW mhpmcounter3 Machine performance-monitoring counter.
parameter mhpmcounter4 = 12'hB04;//0xB04 MRW mhpmcounter4 Machine performance-monitoring counter.
parameter mhpmcounter5 = 12'hB05;//0xB05 MRW mhpmcounter5 Machine performance-monitoring counter.
parameter mhpmcounter6 = 12'hB06;//0xB06 MRW mhpmcounter6 Machine performance-monitoring counter.
parameter mhpmcounter7 = 12'hB07;//0xB07 MRW mhpmcounter7 Machine performance-monitoring counter.
parameter mhpmcounter8 = 12'hB08;//0xB08 MRW mhpmcounter8 Machine performance-monitoring counter.
parameter mhpmcounter9 = 12'hB09;//0xB09 MRW mhpmcounter9 Machine performance-monitoring counter.
parameter mhpmcounter10 = 12'hB0A;//0xB0A MRW mhpmcounter10 Machine performance-monitoring counter.
parameter mhpmcounter11 = 12'hB0B;//0xB0B MRW mhpmcounter11 Machine performance-monitoring counter.
parameter mhpmcounter12 = 12'hB0C;//0xB0C MRW mhpmcounter12 Machine performance-monitoring counter.
parameter mhpmcounter13 = 12'hB0D;//0xB0D MRW mhpmcounter13 Machine performance-monitoring counter.
parameter mhpmcounter14 = 12'hB0E;//0xB0E MRW mhpmcounter14 Machine performance-monitoring counter.
parameter mhpmcounter15 = 12'hB0F;//0xB0F MRW mhpmcounter15 Machine performance-monitoring counter.
parameter mhpmcounter16 = 12'hB10;//0xB10 MRW mhpmcounter16 Machine performance-monitoring counter.
parameter mhpmcounter17 = 12'hB11;//0xB11 MRW mhpmcounter17 Machine performance-monitoring counter.
parameter mhpmcounter18 = 12'hB12;//0xB12 MRW mhpmcounter18 Machine performance-monitoring counter.
parameter mhpmcounter19 = 12'hB13;//0xB13 MRW mhpmcounter19 Machine performance-monitoring counter.
parameter mhpmcounter20 = 12'hB14;//0xB14 MRW mhpmcounter20 Machine performance-monitoring counter.
parameter mhpmcounter21 = 12'hB15;//0xB15 MRW mhpmcounter21 Machine performance-monitoring counter.
parameter mhpmcounter22 = 12'hB16;//0xB16 MRW mhpmcounter22 Machine performance-monitoring counter.
parameter mhpmcounter23 = 12'hB17;//0xB17 MRW mhpmcounter23 Machine performance-monitoring counter.
parameter mhpmcounter24 = 12'hB18;//0xB18 MRW mhpmcounter24 Machine performance-monitoring counter.
parameter mhpmcounter25 = 12'hB19;//0xB19 MRW mhpmcounter25 Machine performance-monitoring counter.
parameter mhpmcounter26 = 12'hB1A;//0xB1A MRW mhpmcounter26 Machine performance-monitoring counter.
parameter mhpmcounter27 = 12'hB1B;//0xB1B MRW mhpmcounter27 Machine performance-monitoring counter.
parameter mhpmcounter28 = 12'hB1C;//0xB1C MRW mhpmcounter28 Machine performance-monitoring counter.
parameter mhpmcounter29 = 12'hB1D;//0xB1D MRW mhpmcounter29 Machine performance-monitoring counter.
parameter mhpmcounter30 = 12'hB1E;//0xB1E MRW mhpmcounter30 Machine performance-monitoring counter.
parameter mhpmcounter31 = 12'hB1F;//0xB1F MRW mhpmcounter31 Machine performance-monitoring counter.
parameter mcycleh = 12'hB80;//0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
parameter minstreth = 12'hB82;//0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.
parameter mhpmcounter3h = 12'hB83;//0xB83 MRW mhpmcounter3h Upper 32 bits of mhpmcounter3, RV32I only.
parameter mhpmcounter4h = 12'hB84;//0xB84 MRW mhpmcounter4h Upper 32 bits of mhpmcounter4, RV32I only.
parameter mhpmcounter5h = 12'hB85;//0xB85 MRW mhpmcounter5h Upper 32 bits of mhpmcounter5, RV32I only.
parameter mhpmcounter6h = 12'hB86;//0xB86 MRW mhpmcounter6h Upper 32 bits of mhpmcounter6, RV32I only.
parameter mhpmcounter7h = 12'hB87;//0xB87 MRW mhpmcounter7h Upper 32 bits of mhpmcounter7, RV32I only.
parameter mhpmcounter8h = 12'hB88;//0xB88 MRW mhpmcounter8h Upper 32 bits of mhpmcounter8, RV32I only.
parameter mhpmcounter9h = 12'hB89;//0xB89 MRW mhpmcounter9h Upper 32 bits of mhpmcounter9, RV32I only.
parameter mhpmcounter10h = 12'hB8A;//0xB8A MRW mhpmcounter10h Upper 32 bits of mhpmcounter10, RV32I only.
parameter mhpmcounter11h = 12'hB8B;//0xB8B MRW mhpmcounter11h Upper 32 bits of mhpmcounter11, RV32I only.
parameter mhpmcounter12h = 12'hB8C;//0xB8C MRW mhpmcounter12h Upper 32 bits of mhpmcounter12, RV32I only.
parameter mhpmcounter13h = 12'hB8D;//0xB8D MRW mhpmcounter13h Upper 32 bits of mhpmcounter13, RV32I only.
parameter mhpmcounter14h = 12'hB8E;//0xB8E MRW mhpmcounter14h Upper 32 bits of mhpmcounter14, RV32I only.
parameter mhpmcounter15h = 12'hB8F;//0xB8F MRW mhpmcounter15h Upper 32 bits of mhpmcounter15, RV32I only.
parameter mhpmcounter16h = 12'hB90;//0xB90 MRW mhpmcounter16h Upper 32 bits of mhpmcounter16, RV32I only.
parameter mhpmcounter17h = 12'hB91;//0xB91 MRW mhpmcounter17h Upper 32 bits of mhpmcounter17, RV32I only.
parameter mhpmcounter18h = 12'hB92;//0xB92 MRW mhpmcounter18h Upper 32 bits of mhpmcounter18, RV32I only.
parameter mhpmcounter19h = 12'hB93;//0xB93 MRW mhpmcounter19h Upper 32 bits of mhpmcounter19, RV32I only.
parameter mhpmcounter20h = 12'hB94;//0xB94 MRW mhpmcounter20h Upper 32 bits of mhpmcounter20, RV32I only.
parameter mhpmcounter21h = 12'hB95;//0xB95 MRW mhpmcounter21h Upper 32 bits of mhpmcounter21, RV32I only.
parameter mhpmcounter22h = 12'hB96;//0xB96 MRW mhpmcounter22h Upper 32 bits of mhpmcounter22, RV32I only.
parameter mhpmcounter23h = 12'hB97;//0xB97 MRW mhpmcounter23h Upper 32 bits of mhpmcounter23, RV32I only.
parameter mhpmcounter24h = 12'hB98;//0xB98 MRW mhpmcounter24h Upper 32 bits of mhpmcounter24, RV32I only.
parameter mhpmcounter25h = 12'hB99;//0xB99 MRW mhpmcounter25h Upper 32 bits of mhpmcounter25, RV32I only.
parameter mhpmcounter26h = 12'hB9A;//0xB9A MRW mhpmcounter26h Upper 32 bits of mhpmcounter26, RV32I only.
parameter mhpmcounter27h = 12'hB9B;//0xB9B MRW mhpmcounter27h Upper 32 bits of mhpmcounter27, RV32I only.
parameter mhpmcounter28h = 12'hB9C;//0xB9C MRW mhpmcounter28h Upper 32 bits of mhpmcounter28, RV32I only.
parameter mhpmcounter29h = 12'hB9D;//0xB9D MRW mhpmcounter29h Upper 32 bits of mhpmcounter29, RV32I only.
parameter mhpmcounter30h = 12'hB9E;//0xB9E MRW mhpmcounter30h Upper 32 bits of mhpmcounter30, RV32I only.
parameter mhpmcounter31h = 12'hB9F;//0xB9F MRW mhpmcounter31h Upper 32 bits of mhpmcounter31, RV32I only.

//Machine Counters/Timers for the CPU
reg [63:0] mcycle_reg;
reg [63:0] minstret_reg;
reg [63:0] mhpmcounter_reg [3:31];
reg [31:0] mcountinhibit_reg;

//Machine Counter Setup
parameter mcountinhibit = 12'h320;//0x320 MRW mcountinhibit Machine counter-inhibit register.
parameter mhpmevent3 = 12'h323;//0x323 MRW mhpmevent3 Machine performance-monitoring event selector.
parameter mhpmevent4 = 12'h324;//0x324 MRW mhpmevent4 Machine performance-monitoring event selector.
parameter mhpmevent5 = 12'h325;//0x325 MRW mhpmevent5 Machine performance-monitoring event selector.
parameter mhpmevent6 = 12'h326;//0x326 MRW mhpmevent6 Machine performance-monitoring event selector.
parameter mhpmevent7 = 12'h327;//0x327 MRW mhpmevent7 Machine performance-monitoring event selector.
parameter mhpmevent8 = 12'h328;//0x328 MRW mhpmevent8 Machine performance-monitoring event selector.
parameter mhpmevent9 = 12'h329;//0x329 MRW mhpmevent9 Machine performance-monitoring event selector.
parameter mhpmevent10 = 12'h32A;//0x32A MRW mhpmevent10 Machine performance-monitoring event selector.
parameter mhpmevent11 = 12'h32B;//0x32B MRW mhpmevent11 Machine performance-monitoring event selector.
parameter mhpmevent12 = 12'h32C;//0x32C MRW mhpmevent12 Machine performance-monitoring event selector.
parameter mhpmevent13 = 12'h32D;//0x32D MRW mhpmevent13 Machine performance-monitoring event selector.
parameter mhpmevent14 = 12'h32E;//0x32E MRW mhpmevent14 Machine performance-monitoring event selector.
parameter mhpmevent15 = 12'h32F;//0x32F MRW mhpmevent15 Machine performance-monitoring event selector.
parameter mhpmevent16 = 12'h330;//0x330 MRW mhpmevent16 Machine performance-monitoring event selector.
parameter mhpmevent17 = 12'h331;//0x331 MRW mhpmevent17 Machine performance-monitoring event selector.
parameter mhpmevent18 = 12'h332;//0x332 MRW mhpmevent18 Machine performance-monitoring event selector.
parameter mhpmevent19 = 12'h333;//0x333 MRW mhpmevent19 Machine performance-monitoring event selector.
parameter mhpmevent20 = 12'h324;//0x324 MRW mhpmevent20 Machine performance-monitoring event selector.
parameter mhpmevent21 = 12'h335;//0x335 MRW mhpmevent21 Machine performance-monitoring event selector.
parameter mhpmevent22 = 12'h336;//0x336 MRW mhpmevent22 Machine performance-monitoring event selector.
parameter mhpmevent23 = 12'h337;//0x337 MRW mhpmevent23 Machine performance-monitoring event selector.
parameter mhpmevent24 = 12'h338;//0x338 MRW mhpmevent24 Machine performance-monitoring event selector.
parameter mhpmevent25 = 12'h339;//0x339 MRW mhpmevent25 Machine performance-monitoring event selector.
parameter mhpmevent26 = 12'h33A;//0x33A MRW mhpmevent26 Machine performance-monitoring event selector.
parameter mhpmevent27 = 12'h33B;//0x33B MRW mhpmevent27 Machine performance-monitoring event selector.
parameter mhpmevent28 = 12'h33C;//0x33C MRW mhpmevent28 Machine performance-monitoring event selector.
parameter mhpmevent29 = 12'h33D;//0x33D MRW mhpmevent29 Machine performance-monitoring event selector.
parameter mhpmevent30 = 12'h33E;//0x33E MRW mhpmevent30 Machine performance-monitoring event selector.
parameter mhpmevent31 = 12'h33F;//0x33F MRW mhpmevent31 Machine performance-monitoring event selector.
//Debug/Trace Registers (shared with Debug Mode)
//0x7A0 MRW tselect Debug/Trace trigger register select.
//0x7A1 MRW tdata1 First Debug/Trace trigger data register.
//0x7A2 MRW tdata2 Second Debug/Trace trigger data register.
//0x7A3 MRW tdata3 Third Debug/Trace trigger data register.
//Debug Mode Registers
//0x7B0 DRW dcsr Debug control and status register.
//0x7B1 DRW dpc Debug PC.
//0x7B2 DRW dscratch0 Debug scratch register 0.
//0x7B3 DRW dscratch1 Debug scratch register 1.

//////////////////////////////////////////////
//        MISA REGISTER BIT DESCRIPTION     //
//////////////////////////////////////////////

//0  A Atomic extension
//1  B Tentatively reserved for Bit-Manipulation extension
//2  C Compressed extension 
//3  D Double-precision floating-point extension
//4  E RV32E base ISA5FSingle-precision floating-point extension
//6  G Additional standard extensions present
//7  H Hypervisor extension
//8  I RV32I/64I/128I base ISA
//9  J Tentatively reserved for Dynamically Translated Languages extension
//10 K Reserved
//11 L Tentatively reserved for Decimal Floating-Point extension
//12 M Integer Multiply/Divide extension
//13 N User-level interrupts supported
//14 O Reserved
//15 P Tentatively reserved for Packed-SIMD extension
//16 Q Quad-precision floating-point extension
//17 R Reserved18SSupervisor mode implemented
//19 T Tentatively reserved for Transactional Memory extension
//20 U User mode implemented
//21 V Tentatively reserved for Vector extension
//22 W Reserved
//23 X Non-standard extensions present
//24 Y Reserved
//25 Z Reserved

//MXL XLEN 
//1   32
//2   64
//3   128

parameter MXL_32 = 2'b01;
parameter MXL_64 = 2'b10;
parameter MXL_128 = 2'b11;

wire [31:0] misa_ext_impl;
assign misa_ext_impl [0:0] = 1'b0;   //A Atomic extension
assign misa_ext_impl [1:1] = 1'b0;   //B Tentatively reserved for Bit-Manipulation extension
assign misa_ext_impl [2:2] = 1'b0;   //C Compressed extension 
assign misa_ext_impl [3:3] = 1'b0;   //D Double-precision floating-point extension
assign misa_ext_impl [4:4] = 1'b0;   //E RV32E base ISA5FSingle-precision floating-point extension
assign misa_ext_impl [6:6] = 1'b0;   //G Additional standard extensions present
assign misa_ext_impl [7:7] = 1'b0;   //H Hypervisor extension
assign misa_ext_impl [8:8] = 1'b1;   //I RV32I/64I/128I base ISA
assign misa_ext_impl [9:9] = 1'b0;   //J Tentatively reserved for Dynamically Translated Languages extension
assign misa_ext_impl [10:10] = 1'b0; //K Reserved
assign misa_ext_impl [11:11] = 1'b0; //L Tentatively reserved for Decimal Floating-Point extension
assign misa_ext_impl [12:12] = 1'b0; //M Integer Multiply/Divide extension
assign misa_ext_impl [13:13] = 1'b0; //N User-level interrupts supported
assign misa_ext_impl [14:14] = 1'b0; //O Reserved
assign misa_ext_impl [15:15] = 1'b0; //P Tentatively reserved for Packed-SIMD extension
assign misa_ext_impl [16:16] = 1'b0; //Q Quad-precision floating-point extension
assign misa_ext_impl [17:17] = 1'b0; //R Reserved18SSupervisor mode implemented
assign misa_ext_impl [19:19] = 1'b0; //T Tentatively reserved for Transactional Memory extension
assign misa_ext_impl [20:20] = 1'b0; //U User mode implemented
assign misa_ext_impl [21:21] = 1'b0; //V Tentatively reserved for Vector extension
assign misa_ext_impl [22:22] = 1'b0; //W Reserved
assign misa_ext_impl [23:23] = 1'b0; //X Non-standard extensions present
assign misa_ext_impl [24:24] = 1'b0; //Y Reserved
assign misa_ext_impl [25:25] = 1'b0; //Z Reserved
assign misa_ext_impl [31:26] = 6'b0; //# All other bits are set to 0
assign misa_ext_impl [31:30] = MXL_32; //MXL_32

//Mstatus bits
logic mstatus_uie;
logic mstatus_sie;
logic mstatus_mie;
logic mstatus_upie;
logic mstatus_spie;
logic mstatus_mpie;
logic [1:0] mstatus_spp;
logic [1:0] mstatus_mpp;
logic [1:0] mstatus_fs;
logic [1:0] mstatus_xs;
logic mstatus_mprv;
logic mstatus_sum;
logic mstatus_mxr;
logic mstatus_tvm;
logic mstatus_tw;
logic mstatus_tsr;
logic mstatus_sd;


logic [31:0] misa_reg;
logic [31:0] medeleg_reg;
logic [31:0] mideleg_reg;

//Value Name       Description
//0     Direct     All exceptions set pc to BASE.
//1     Vectored   Asynchronous interrupts set pc to BASE+4×cause.
//≥2    Reserved

parameter TRAP_DIRECT = 2'b0;
parameter TRAP_VECTORED = 2'b1;


reg [31:0] mie_reg;
reg [31:0] mtvec_reg;
reg [31:0] mcounteren_reg;

initial begin
    mstatus_uie = 0;
    mstatus_sie = 0;
    mstatus_mie = 0;
    mstatus_upie = 0;
    mstatus_spie = 0;
    mstatus_mpie = 0;
    mstatus_spp = 0;
    mstatus_mpp = 0;
    mstatus_fs = 0;
    mstatus_xs = 0;
    mstatus_mprv = 0;
    mstatus_sum = 0;
    mstatus_mxr = 0;
    mstatus_tvm = 0;
    mstatus_tw = 0;
    mstatus_tsr = 0;
    mstatus_sd = 0;
    misa_reg = 0;
    medeleg_reg = 0;
    mideleg_reg = 0;
    mie_reg = 0;
    mtvec_reg = 0;
    mcounteren_reg = 0;
end

//Machine Information ---- These are not registers, but hardcoded values into the CPU.
parameter mvendorid_data = 32'hdeadbeef; //0xF11 MRO mvendorid Vendor ID.
parameter marchid_data = 32'hcafefeed; //0xF12 MRO marchid Architecture ID.
parameter mimpid_data = 32'h01ABCDEF; //0xF13 MRO mimpid Implementation ID.
parameter mhartid_data = 32'h00000001; //0xF14 MRO mhartid Hardware thread ID.

//Machine Trap Handling Register Declarations
logic [31:0] mscratch_reg; // 12'h340;//0x340 MRW mscratch Scratch register for machine trap handlers.
logic [31:0] mepc_reg; // 12'h341;//0x341 MRW mepc Machine exception program counter.
logic [31:0] mcause_reg; // 12'h342;//0x342 MRW mcause Machine trap cause.
logic [31:0] mtval_reg; // 12'h343;//0x343 MRW mtval Machine bad address or instruction.
logic [31:0] mip_reg_ro; // 12'h344;//0x344 MRW mip Machine interrupt pending.

always @(posedge clk) begin
    mip_mtip = timer_interrupt;
    mip_meip = external_interrupt;
end

//Machine Interrupt Pending Bits
logic mip_meip = 1'b0;
logic mip_seip = 1'b0;
logic mip_ueip = 1'b0;
logic mip_mtip = 1'b0;
logic mip_stip = 1'b0;
logic mip_utip = 1'b0;
logic mip_msip = 1'b0;
logic mip_ssip = 1'b0;
logic mip_usip = 1'b0;

assign mip_reg_ro [31:12] = 0;
assign mip_reg_ro [11:11] = mip_meip;
assign mip_reg_ro [10:10] = 1'b0;
assign mip_reg_ro [9:9] = mip_seip;
assign mip_reg_ro [8:8] = mip_ueip;
assign mip_reg_ro [7:7] = mip_mtip;
assign mip_reg_ro [6:6] = 1'b0;
assign mip_reg_ro [5:5] = mip_stip;
assign mip_reg_ro [4:4] = mip_utip;
assign mip_reg_ro [3:3] = mip_msip;
assign mip_reg_ro [2:2] = 1'b0;
assign mip_reg_ro [1:1] = mip_ssip;
assign mip_reg_ro [0:0] = mip_usip;
//Machine Interrupt Enable Bits

wire mie_meie;
wire mie_seie;
wire mie_ueie;
wire mie_mtie;
wire mie_stie;
wire mie_utie;
wire mie_msie;
wire mie_ssie;
wire mie_usie;

assign mie_meie = mie_reg [11:11];
assign mie_seie = mie_reg [9:9];
assign mie_ueie = mie_reg [8:8];
assign mie_mtie = mie_reg [7:7];
assign mie_stie = mie_reg [5:5];
assign mie_utie = mie_reg [4:4];
assign mie_msie = mie_reg [3:3];
assign mie_ssie = mie_reg [1:1];
assign mie_usie = mie_reg [0:0];



initial begin
    mscratch_reg = 0;
    mepc_reg = 0;
    mcause_reg = 0;
    mtval_reg = 0;
end

//Mcause Codes
//Interrupt Exception Code Description
//1         0         User software interrupt
//1         1         Supervisor software interrupt
//1         2         Reserved for future standard use
//1         3         Machine software interrupt
//1         4         User timer interrupt
//1         5         Supervisor timer interrupt
//1         6         Reserved for future standard use
//1         7         Machine timer interrupt
//1         8         User external interrupt
//1         9         Supervisor external interrupt
//1         10        Reserved for future standard use
//1         11        Machine external interrupt
//1         12–15     Reserved for future standard use
//1         ≥16       Reserved for platform use
//0         0         Instruction address misaligned
//0         1         Instruction access fault
//0         2         Illegal instruction
//0         3         Breakpoint
//0         4         Load address misaligned
//0         5         Load access fault
//0         6         Store/AMO address misaligned
//0         7         Store/AMO access fault
//0         8         Environment call from U-mode
//0         9         Environment call from S-mode
//0         10        Reserved
//0         11        Environment call from M-mode
//0         12        Instruction page fault
//0         13        Load page fault
//0         14        Reserved for future standard use
//0         15        Store/AMO page fault
//0         16–23     Reserved for future standard use
//0         24–31     Reserved for custom use
//0         32–47     Reserved for future standard use
//0         48–63     Reserved for custom use
//0         ≥64       Reserved for future standard use
////////////////////////////////////////////////////////////////
//                                                 INT   CAUSE
parameter MCAUSE_U_SOFT_INT                     = {1'b1, 31'd0};
parameter MCAUSE_S_SOFT_INT                     = {1'b1, 31'd1};
parameter MCAUSE_M_SOFT_INT                     = {1'b1, 31'd3};
parameter MCAUSE_U_TIMER_INTT                   = {1'b1, 31'd4};
parameter MCAUSE_S_TIMER_INT                    = {1'b1, 31'd5};
parameter MCAUSE_M_TIMER_INT                    = {1'b1, 31'd7};
parameter MCAUSE_U_EXT_INT                      = {1'b1, 31'd8};
parameter MCAUSE_S_EXT_INT                      = {1'b1, 31'd9};
parameter MCAUSE_M_EXT_INT                      = {1'b1, 31'd11};
parameter MCAUSE_INS_ADDRESS_MISALIGNED         = {1'b0, 31'd0};
parameter MCAUSE_INS_ACCESS_FAULT               = {1'b0, 31'd1};
parameter MCAUSE_ILLEGAL_INS                    = {1'b0, 31'd2};
parameter MCAUSE_BREAKPOINT                     = {1'b0, 31'd3};
parameter MCAUSE_LOAD_ADDRESS_MISALIGNED        = {1'b0, 31'd4};
parameter MCAUSE_LOAD_ACCESS_FAULT              = {1'b0, 31'd5};
parameter MCAUSE_STORE_AMO_ADDRESS_MISALIGNED   = {1'b0, 31'd6};
parameter MCAUSE_STORE_AMO_ACCESS_FAULT         = {1'b0, 31'd7};
parameter MCAUSE_ENV_CALL_U_MODE                = {1'b0, 31'd8};
parameter MCAUSE_ENV_CALL_S_MODE                = {1'b0, 31'd9};
parameter MCAUSE_ENV_CALL_M_MODE                = {1'b0, 31'd11};
parameter MCAUSE_INS_PAGE_FAULT                 = {1'b0, 31'd12};
parameter MCAUSE_LOAD_PAGE_FAULT                = {1'b0, 31'd13};
parameter MCAUSE_STORE_AMO_PAGE_FAULT           = {1'b0, 31'd15};


/////////////////////////////////////////////////
//                CSR READ/WRITE LOGIC         //
/////////////////////////////////////////////////
//All registers will be read and written on the positive edge of the clock even if they are contants to utilize blocks of memory instead of FFs on the FPGA

//The source of the csr address has to be choosen from a register or from an immidiate address.
wire [11:0] csr_read_address;
assign csr_read_address = i_imm; //The address of the CSR always comes from the i_imm bus
logic [31:0] read_data;
logic [31:0] write_data;
logic [31:0] internal_cause;
logic [31:0] internal_mtval;
logic csr_write;
//This signal would be set so the CSR logic stores all data necessary to the CSRs.
logic trap_sig;
logic priv_return;
always@(posedge clk)
begin
    if(rst)
    begin
        //Reset mstatus bits
        //Reset MIE
        mstatus_mie = 0;
        //Reset MPRIV
        mstatus_mprv = 0;
        //Reset current mode
        current_mode = M_MODE;
    end
    else
    begin
        if(priv_return)
        begin
            case(i_imm)
                URET:
                begin
                    $display("NOT SUPPORTED PRIV_RETURN URET");
                    $stop;
                end
                SRET:
                begin
                    $display("NOT SUPPORTED PRIV_RETURN SRET");
                    $stop;
                end
                MRET:
                begin
                    mstatus_mpp <= M_MODE; //Is set to M_MODE because the other modes are not supported;
                    mstatus_mie <= mstatus_mpie;
                    mstatus_mpie <= 1'b1;
                    current_mode <= mstatus_mpp;
                end
            endcase
            //Set xIE to xMIE
        end else if(trap_sig)
        begin
            //Save epc
            mepc_reg <= PC;
            //Set cause
            mcause_reg <= internal_cause; //The failing instruction logic sets this register
            //Set Machine Mode
            current_mode <= M_MODE; //Traps are always taken in M Machine mode
            //Set mtval
            mtval_reg <= internal_mtval;
            //Set previous machine mode on mstatus
            mstatus_mpp <= current_mode;
            //Disable Machine Global Interrupts. This by default disables all the interrupts of the system.
            mstatus_mie <= 1'b0;
            //Save Old Machine Global Interrupt Enable bit
            mstatus_mpie <= mstatus_mie;
            //Jump to the trap vector
        end
        else
        begin
            //We are using ranges because in some cases there we can use blocks of memory to implement the CSRs and save LUTs
            if((csr_read_address >= mvendorid) & (csr_read_address <= mhartid))
            begin
                //Machine Information -- These are read only CSRs
                unique case(csr_read_address)
                    mvendorid: read_data = mvendorid_data; 
                    marchid: read_data = marchid_data; 
                    mimpid: read_data = mimpid_data; 
                    mhartid: read_data = mhartid_data; 
                endcase
            end
            //Machine Trap Setup
            else if((csr_read_address >= mstatus) & (csr_read_address <= mcounteren))
            begin
                unique case(csr_read_address)
                    mstatus:
                    begin
                        read_data = 
                        {
                            mstatus_uie,
                            mstatus_sie,
                            2'b0,
                            mstatus_mie,
                            mstatus_upie,
                            mstatus_spie,
                            1'b0,
                            mstatus_mpie,
                            mstatus_spp,
                            2'b0,
                            mstatus_mpp,
                            mstatus_fs,
                            mstatus_xs,
                            mstatus_mprv,
                            mstatus_sum,
                            mstatus_mxr,
                            mstatus_tvm,
                            mstatus_tw,
                            mstatus_tsr,
                            8'b0,
                            mstatus_sd
                        };
                    end
                    misa: read_data = misa_reg;
                    medeleg: read_data = 32'b0; //NOT IMPLEMENTED
                    mideleg: read_data = 32'b0; //NOT IMPLEMENTED
                    mie: read_data = mie_reg;
                    mtvec: read_data = mtvec_reg;
                    mcounteren: read_data = mcounteren_reg;
                endcase
                if(csr_write)
                begin
                    unique case(csr_read_address)
                        mstatus: 
                        begin
                            //Avoid writting to the hardwired to zero bits
                            mstatus_uie = write_data [0:0];
                            mstatus_sie = write_data [1:1];
                            mstatus_mie = write_data [3:3];
                            mstatus_upie = write_data [4:4];
                            mstatus_spie = write_data [5:5];
                            mstatus_mpie = write_data [7:7];
                            mstatus_spp = write_data [8:8];
                            mstatus_mpp = write_data [12:11];
                            mstatus_fs = write_data [14:13];
                            mstatus_xs = write_data [16:15];
                            mstatus_mprv = write_data [17:17];
                            mstatus_sum = write_data [18:18];
                            mstatus_mxr = write_data [19:19];
                            mstatus_tvm = write_data [20:20];
                            mstatus_tw = write_data [21:21];
                            mstatus_tsr = write_data [22:22];
                            mstatus_sd = write_data [31:31];
                        end
                        //misa: misa; //misa is not writtable in this implementation
                        //medeleg: read_data = 32'b0; //NOT IMPLEMENTED
                        //mideleg: read_data = 32'b0; //NOT IMPLEMENTED
                        mie: mie_reg = write_data;
                        mtvec: mtvec_reg = write_data;
                        mcounteren: mcounteren_reg = write_data;
                    endcase
                end
            end
            else if((csr_read_address >= mscratch) & (csr_read_address <= mip))
            begin
                unique case(csr_read_address)
                    mscratch: read_data = mscratch_reg;
                    mepc: read_data = mepc_reg;
                    mcause: read_data = mcause_reg;
                    mtval: read_data = mtval_reg;
                    mip: read_data = mip_reg_ro;
                endcase
                if(csr_write)
                begin
                    unique case(csr_read_address)
                        mscratch: mscratch_reg = write_data;
                        mepc: mepc_reg = write_data;
                        mcause: mcause_reg = write_data;
                        mtval: mtval_reg = write_data;
                        mip: 
                        begin
                            mip_seip = write_data [9:9];
                            mip_ueip = write_data [8:8];
                            mip_stip = write_data [5:5];
                            mip_utip = write_data [4:4];
                            mip_ssip = write_data [1:1];
                            mip_usip = write_data [0:0];
                        end
                    endcase
                end
            end
            else
            begin
                read_data = 32'b0;
            end
        end
    end
end

//The data comming from a CSR read is always in read_data.
assign csr_out = read_data;

//////////////////////////////////////////////
//        Machine Privilege Register        //
//////////////////////////////////////////////

//The privilege register that keep the current state of the CPU
//is hidden for the user and its controlled only by hardware, it should be 
//never accessible by the program running on the core.

//These are the following modes of operation.
//0 00 User/Application U 
//1 01 Supervisor       S
//2 10 Reserved
//3 11 Machine          M


//parameter RESERVED_MODE = 2'b10; //Not needed
parameter U_MODE = 2'b00; //User Mode
parameter S_MODE = 2'b01; //Supervisor Mode
parameter M_MODE = 2'b11; //Machine Mode

//On reset the mode should always be Machine mode
reg [1:0] current_mode;



typedef enum logic [3:0] { FETCH, WAIT_FETCH, EXECUTE, INC, TRAP, ATRAP} states_t;
states_t state = FETCH;

wire [2:0] funct3;
wire [6:0] funct7;

assign funct3 = IR [14:12];
assign funct7 = IR [31:25];
assign rd = IR [11:7];
assign rs1 = IR [19:15];

//Register to store the carry signal of the adder.
//One of the optimizations of this design will require a 1bit adder instead of a 32bit one.
reg carry;
wire add;
wire cout;

full_adder full_adder_0
(
    .a(PC[0:0]),
    .b((count == 5'h2)? 1'b1 : 1'b0), //To just increment by 4 every time
    .cin(carry),
    .cout(cout),
    .z(add)
);

//Ways the control unit can load data from memory
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;

//ALU OPCODES
parameter ADD =  4'b0000;
parameter SUB =  4'b1000;
parameter SLL =  4'b0001;
parameter SLT =  4'b0010;
parameter SLTU = 4'b0011;
parameter XOR =  4'b0100;
parameter SRL =  4'b0101;
parameter SRA =  4'b1101;
parameter OR =   4'b0110;
parameter AND =  4'b0111;

//Branch unit opcodes
parameter BEQ = 3'b000;
parameter BNE = 3'b001;
parameter BLT = 3'b100;
parameter BGE = 3'b101;
parameter BLTU = 3'b110;
parameter BGEU = 3'b111;

typedef enum logic [1:0] { CALC_NPC, SAVE_PC, CALC_TARGET, JUMP_TARGET } jalr_states_t;

//Memory access unit control state
typedef enum logic { SET_OPERATION, WAIT} mauc_state_t;

//Set and Clear Atomic state machine states
//typedef enum logic { READ_}

mauc_state_t mauc_state = SET_OPERATION;

jalr_states_t jalr_states = SAVE_PC;


typedef enum logic { WRITE_CSR, SET_PC } trap_t;
trap_t trap_state = WRITE_CSR;


wire [31:0] u_imm = {IR [31:12], 12'b000000000000};
logic [12:0] b_imm;
logic [11:0] i_imm;
assign b_imm [0:0] = 1'b0;
assign b_imm [11:11] = IR [7:7];
assign b_imm [4:1] = IR [11:8];
assign b_imm [10:5] = IR [30:25];
assign b_imm [12:12] = IR [31:31];
assign i_imm = IR [31:20];

//Logic to help the Control Unit recognize if the CSR will be read, write or access to it is illegal
wire csr_writable; //Only writable is needed because CSRs are always readable
wire csr_illegal_access;

//This is tell the mode in which this CSRs are allocated.
wire csr_addr_priv = i_imm [9:8];

//It's illegal access if the current mode is lower than the csr_addr_priv
assign csr_illegal_access = (current_mode < csr_addr_priv)? 1'b1 : 1'b0;

parameter READ_WRITE_0 = 2'b00; //Read write 0
parameter READ_WRITE_1 = 2'b01; //Read write 1
parameter READ_WRITE_C = 2'b10; //Read write custom
parameter READ_ONLY    = 2'b11; //Read only

assign csr_writable = (((i_imm[11:10] == READ_WRITE_0) | (i_imm[11:10] == READ_WRITE_0)) & ~(i_imm[11:10] == READ_ONLY))? 1'b1 : 1'b0;

always @(negedge clk) begin
    if(rst)
    begin
        state = FETCH;
        PC = RESET_VECTOR;
        cyc = 1'b0;
        count = 0;
        memory_operation = MEM_NONE;
        bu_start = 1'b0;
        jalr_states = CALC_NPC;
        mauc_state = SET_OPERATION;
        trap_sig = 1'b0;
        //Setup Privilege Register Mode to Machine mode
        //current_mode <= M_MODE;
        trap_sig = 1'b0;
        priv_return = 1'b0;
    end
    else
    begin        
        case(state)
            //Takes all asynchronomous traps before executing another instruction
            ATRAP:
            begin
                // $display("TRAP EXECUTED");
                // $display("\t\tPC %08x", PC);                            
                // $display("\t\tCAUSE %08x", internal_cause);                            
                // $display("\t\tmtval %08x", internal_mtval);                            
                // $display("*IGNORED*");
                wr = 1'b0;
                csr_write = 1'b0;
                trap_sig = 1'b1;
                unique case(trap_state)
                    WRITE_CSR:
                    begin
                        trap_sig = 1'b1;     
                        trap_state = SET_PC;       
                    end
                    SET_PC:
                    begin
                        trap_sig = 1'b0;            
                        //Depending on the mode that executes it
                        if(mtvec_reg [1:0] == TRAP_DIRECT)
                        begin
                            PC = {mtvec_reg [31:2], 2'b0};
                            //$display("PC set to 0x%08x", {mtvec_reg [31:2], 2'b0});         
                        end
                        else if(mtvec_reg [1:0] == TRAP_VECTORED & internal_cause[31:31]) //Only do vectored on Asynchronous traps
                        begin
                            //$display("PC set to 0x%08x", {mtvec_reg [31:2], 2'b0} + {internal_cause [29:0], 2'b0});         
                            PC = {mtvec_reg [31:2], 2'b0} + {internal_cause [29:0], 2'b0};
                        end
                        else
                        begin
                            PC = {mtvec_reg [31:2], 2'b0};
                        end
                        state = FETCH;
                    end
                endcase
            end
            FETCH:
            begin
                //Take asynchrounous interrupts
                //MEI, MSI, MTI, SEI, SSI, STI, UEI,USI, UTI.
                //Interrupts can only be disabled for higher privileges, meaning that they can only be disabled for M_MODE when M_MODE
                if(mip_meip & mie_meie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_EXT_INT;
                    internal_mtval = 32'b0;
                end else if(mip_msip & mie_msie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_SOFT_INT;
                    internal_mtval = 32'b0;
                end else if(mip_mtip & mie_mtie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_TIMER_INT;
                    internal_mtval = 32'b0;
                end
                // end else if(mip_seip & mie_mtie)
                // begin
                    
                // end
                // end else if(mip_ssip & mie_msie)
                // begin
                    
                // end
                // end else if(mip_stip & mie_msie)
                // begin
                    
                // end
                // end else if(mip_ueip & mie_msie)
                // begin
                    
                // end
                // end else if(mip_usip & mie_msie)
                // begin
                    
                // end
                else //Fetch instruction if there were not interrupts
                begin
                    memory_operation = FETCH_DATA;
                    funct3_cu <= LW;
                    bu_start = 1'b0;
                    cyc = 1'b1;
                    wr = 0;
                    trap_sig = 1'b0;
                    trap_state = WRITE_CSR;
                    priv_return = 1'b0;
                    if(ack)
                    begin
                        state = WAIT_FETCH;
                    end else if(err)
                    begin
                        
                    end
                end 
            end
            WAIT_FETCH:
            begin
                funct3_cu <= LW;
                cyc = 1'b0;
                if(data_valid)
                begin
                    IR = fetched_data;
                    state = EXECUTE;
                    jalr_states = CALC_NPC;
                    mauc_state = SET_OPERATION;
                end
                else if(err)
                begin
                    //Do an illegal address something thing
                end
            end
            EXECUTE:
            begin
                count = 0;
                carry = 0;
                funct3_cu <= funct3;
                //Decode instructions
                case(IR[6:0])
                    LOAD:
                    begin
                        //Set register file input multiplexer to load bus source
                        regfile_src = LOAD_SRC;
                        memory_operation = LOAD_DATA;
                        case(mauc_state)
                            SET_OPERATION:
                            begin
                                cyc = 1'b1;
                                if(ack)
                                begin
                                    mauc_state = WAIT;
                                end
                            end
                            WAIT:
                            begin
                                cyc = 1'b0;
                                if(data_valid)
                                begin
                                    wr = 1'b1;
                                    state = INC;
                                end
                            end
                        endcase
                    end
                    STORE:
                    begin
                        memory_operation = STORE_DATA;
                        case(mauc_state)
                            SET_OPERATION:
                            begin
                                cyc = 1'b1;
                                if(ack)
                                begin
                                    mauc_state = WAIT;
                                end
                            end
                            WAIT:
                            begin
                                cyc = 1'b0;
                                if(done)
                                begin
                                    state = INC;
                                end
                            end
                        endcase
                        
                    end
                    OP_IMM:
                    begin
                        //Set register file input multiplexer to alu output bus
                        //$display("Executing OP_IMM");
                        regfile_src = ALU_INPUT;
                        sr2_src = I_IMM_SRC;
                        sr1_src = REG_SRC2;
                        op = {((funct3 == 3'b001) | (funct3 == 3'b101))? funct7[5:5] : 1'b0, funct3};
                        //
                        start = 1'b1;
                        if(alu_done)
                        begin
                            start = 1'b0;
                            state = INC;
                            wr = 1'b1; //Write to register file
                        end
                        
                    end
                    OP:
                    begin
                        //Set register file input multiplexer to alu output bus
                        //$display("Executing OP");
                        regfile_src = ALU_INPUT;
                        sr2_src = REG_SRC;
                        sr1_src = REG_SRC2;
                        op = {funct7[5:5], funct3};
                        //
                        start = 1'b1;
                        if(alu_done)
                        begin
                            start = 1'b0;
                            state = INC;
                            wr = 1'b1; //Write to register file
                        end
                    end
                    BRANCH:
                    begin
                        bu_start = 1'b1;
                        if(bu_done)
                        begin
                            bu_start = 1'b0;
                            if(jump)
                            begin
                                state = FETCH;
                                //Set PC to target address
                                PC = PC + 32'($signed(b_imm));
                            end
                            else
                            begin
                                state = INC; //Continue normal cycle
                            end
                            
                        end
                    end
                    AUIPC:
                    begin                    
                        //$display("Executing AUIPC");
                        //Set register file input multiplexer to alu output bus
                        op = ADD;
                        regfile_src = ALU_INPUT;
                        sr2_src = ALU_PC_SRC;
                        sr1_src = ALU_U_IMM_SRC;
                        //
                        start = 1'b1;
                        if(alu_done)
                        begin
                            start = 1'b0;
                            state = INC;
                            wr = 1'b1; //Write to register file
                        end
                    end
                    LUI:
                    begin
                        //$display("Executing LUI");
                        regfile_src = U_IMM_SRC;
                        wr = 1'b1; //Write to register file
                        state = INC;
                    end
                    JAL, JALR:
                    begin
                        //$display("Executing JAL");
                        regfile_src = ALU_INPUT;
                        case(jalr_states)
                            CALC_NPC:
                            begin
                                op = ADD;
                                sr2_src = ALU_PC_SRC;
                                sr1_src = ALU_4;
                                wr = 1'b0; //Write to register file
                                start = 1'b1;
                                jalr_states = SAVE_PC;
                            end
                            SAVE_PC:
                            begin
                                start = 1'b0;
                                if(alu_done)
                                begin
                                    wr = 1'b1; //Write to register file
                                    jalr_states = CALC_TARGET;
                                end
                            end
                            CALC_TARGET:
                            begin
                                wr = 1'b0; //Write to register file
                                if(IR[6:0] == JAL)
                                begin
                                    sr2_src = ALU_PC_SRC;
                                    sr1_src = ALU_J_IMM;
                                end
                                else if(IR[6:0] == JALR)
                                begin
                                    sr2_src = I_IMM_SRC;
                                    sr1_src = REG_SRC2;
                                end
                                start = 1'b1;
                                jalr_states = JUMP_TARGET;
                            end
                            JUMP_TARGET:
                            begin
                                start = 1'b0;
                                if(alu_done)
                                begin
                                    //-----------------NOTE------------------
                                    //This can use instead the shift register capability to shift in all data and not waste space with multiplexors
                                    PC = alu_result;
                                    state = FETCH;
                                end
                            end
                        endcase
                    end
                    SYSTEM:
                    begin
                        case(funct3)
                            PRIV:
                            begin
                                case(i_imm)
                                    EBREAK:
                                    begin
                                        $display("EBREAK EXECUTED");
                                        $display("--------------REG DUMP--------------");
                                        //Display all registers
                                        for(int i = 0;i < 8;i++)
                                        begin
                                            $display("r%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x", i, debug_reg[i], i+8, debug_reg[i+8], i+16, debug_reg[i+16], i+24, debug_reg[i+24]);                            
                                        end
                                        $display("pc: %02d: 0x%08x", PC);                            
                                        $stop;
                                    end
                                    URET:
                                    begin
                                        $display("ERROR: USER MODE NOT IMPLEMENTED");
                                        $stop;
                                        state = TRAP;
                                        internal_cause <= MCAUSE_ILLEGAL_INS;
                                        internal_mtval = IR; 
                                    end
                                    SRET:
                                    begin
                                        $display("ERROR: SUPERVISOR MODE NOT IMPLEMENTED");
                                        $stop;
                                        state = TRAP;
                                        internal_cause <= MCAUSE_ILLEGAL_INS;
                                        internal_mtval = IR; 
                                    end
                                    MRET:
                                    begin
                                        PC = mepc_reg;
                                        priv_return = 1'b1;
                                        state = FETCH;
                                    end
                                endcase
                            end
                            //Write on a read only CSR will create an illegal instruction exeption, registers that contain read only bits will be ignored
                            //Zicsr extention
                            CSRRW:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                    $display("Illegal Access to 0x%08x CSR", i_imm);
                                    $stop;
    
                                end
                                else
                                begin
                                    if(rd == 0) //Do not read but do write. Basically it's value will not be written anywhere.
                                    begin
                                        if(csr_writable)
                                        begin
                                            write_data <= rs1_d;
                                            csr_write = 1'b1;
                                            state = INC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                            $display("Illegal Write to 0x%08x CSR", i_imm);
                                            $stop;
                                        end
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            write_data <= rs1_d;
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                            $display("Illegal Write to 0x%08x CSR", i_imm);
                                            $stop;
                                        end
                                    end
                                end
                            end
                            CSRRS:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                end
                                else
                                begin
                                    if(rs1 == 0) //Do not write or make exeption for writting. Only read in this case.
                                    begin
                                        //In this state its only read. The contents of the CSR will be written to the Register file.
                                        state = INC;
                                        wr = 1'b1;
                                        regfile_src = CSR_SRC;
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            //Change this
                                            write_data <= (rs1_d | read_data); //Read and Set
                                            
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                end
                            end
                            CSRRC:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                end
                                else
                                begin
                                    if(rs1 == 0) //Do not write or make exeption for writting. Only read in this case.
                                    begin
                                            state = INC;
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            //Change this
                                            write_data <= read_data & ~(rs1_d); //This is for Read and Clear
                                            
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                end
                            end
                            CSRRWI:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                end
                                else
                                begin
                                    if(rd == 0) //Do not read but do write. Basically it's value will not be written anywhere.
                                    begin
                                        if(csr_writable)
                                        begin
                                            write_data <= {26'b0,rs1};
                                            csr_write = 1'b1;
                                            state = INC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            write_data <= {26'b0,rs1};
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                end
                            end
                            CSRRSI:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                end
                                else
                                begin
                                    if(rs1 == 0) //Do not write or make exeption for writting. Only read in this case.
                                    begin
                                        //In this state its only read. The contents of the CSR will be written to the Register file.
                                        state = INC;
                                        wr = 1'b1;
                                        regfile_src = CSR_SRC;
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            //Change this
                                            write_data <= (rs1_d | {26'b0,rs1}); //Read and Set
                                            
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                end
                            end
                            CSRRCI:
                            begin
                                //No matter if its read or write. Illegal Access will yield and illegal instruction exeption.
                                if(csr_illegal_access)
                                begin
                                    //Make an illegal instruction exeption.
                                    state = TRAP;
                                    internal_cause <= MCAUSE_ILLEGAL_INS;
                                    internal_mtval = IR; 
                                end
                                else
                                begin
                                    if(rs1 == 0) //Do not write or make exeption for writting. Only read in this case.
                                    begin
                                            state = INC;
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                    end
                                    else //Do read and write
                                    begin
                                        if(csr_writable)
                                        begin
                                            //Change this
                                            write_data <= read_data & ~({26'b0,rs1}); //This is for Read and Clear
                                            
                                            csr_write = 1'b1;
                                            state = INC;
                                            //Activate Register file to write
                                            wr = 1'b1;
                                            regfile_src = CSR_SRC;
                                        end
                                        else
                                        begin
                                            //Else Create an illegal instruction exeption because the register is not writable
                                            state = TRAP;
                                            internal_cause <= MCAUSE_ILLEGAL_INS;
                                            internal_mtval = IR; 
                                        end
                                    end
                                end
                            end
                        endcase
                    end
                    default:
                    begin
                        //Trigger Illegal Instruction exeption
                        state = TRAP;
                        internal_cause <= MCAUSE_ILLEGAL_INS;
                        internal_mtval = IR; 
                    end
                endcase
            end
            INC: //Increment Program counter
            begin
                //Disable write to register file signal, so we dont write other values that we dont want to write.
                wr = 1'b0;
                csr_write = 1'b0;
                if(count > 31)
                begin
                    state = FETCH;
                                //$display("--------------REG DUMP--------------");
                                //Display all registers
                                //for(int i = 0;i < 8;i++)
                                //begin
                                //    $display("r%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x\tr%02d: 0x%08x", i, debug_reg[i], i+8, debug_reg[i+8], i+16, debug_reg[i+16], i+24, debug_reg[i+24]);                            
                                //end
                                //$display("pc: 0x%08x", PC);                            
                end
                else
                begin
                    count = count + 1;
                    carry = cout;
                    PC[31:0] = {add, PC[31:1]}; //It should end up in the same position
                end
            end
            //This is the state that handles illegal instruction exeptions
            TRAP:
            begin
                //Take asynchrounous interrupts instead if any
                //MEI, MSI, MTI, SEI, SSI, STI, UEI,USI, UTI.
                //Interrupts can only be disabled for higher privileges, meaning that they can only be disabled for M_MODE when M_MODE
                if(mip_meip & mie_meie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_EXT_INT;
                    internal_mtval = 32'b0;
                end else if(mip_msip & mie_msie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_SOFT_INT;
                    internal_mtval = 32'b0;
                end else if(mip_mtip & mie_mtie & ((mstatus_mie | (current_mode < M_MODE))))
                begin
                    state = ATRAP;
                    internal_cause = MCAUSE_M_TIMER_INT;
                    internal_mtval = 32'b0;
                end
                else
                begin
                    // $display("TRAP EXECUTED");
                    // $display("\t\tPC %08x", PC);                            
                // $display("\t\tPC %08x", PC);                            
                    // $display("\t\tPC %08x", PC);                            
                    // $display("\t\tCAUSE %08x", internal_cause);                            
                // $display("\t\tCAUSE %08x", internal_cause);                            
                    // $display("\t\tCAUSE %08x", internal_cause);                            
                    // $display("\t\tmtval %08x", internal_mtval);                            
                    // $display("*IGNORED*");
                    wr = 1'b0;
                    csr_write = 1'b0;
                    trap_sig = 1'b1;
                    unique case(trap_state)
                        WRITE_CSR:
                        begin
                            trap_sig = 1'b1;     
                        trap_sig = 1'b1;     
                            trap_sig = 1'b1;     
                            trap_state = SET_PC;       
                        trap_state = SET_PC;       
                            trap_state = SET_PC;       
                        end
                        SET_PC:
                        begin
                            trap_sig = 1'b0;            
                        trap_sig = 1'b0;            
                            trap_sig = 1'b0;            
                            PC = {mtvec_reg [31:2], 2'b0}; //This state only handles synchronous traps
                            state = FETCH;
                        end
                    endcase
                end
            end
        endcase
    end
end

assign pc = PC;
//assign op = {funct7[5:5], funct3};
assign ir = IR;//{ IR[31:25], rs2_cu, IR[19:0] };

wire [6:0] instruction;
assign instruction = IR[6:0]; 

endmodule