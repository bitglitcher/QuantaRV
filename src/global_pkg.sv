
package global_pkg;


typedef enum logic[3:0] { REG_SRC, I_IMM_SRC } sr2_src_t;
typedef enum logic[3:0] { ALU_INPUT, U_IMM_SRC, AUIPC_SRC, LOAD_SRC, PC_SRC, CSR_SRC } regfile_src_t;
typedef enum logic[3:0] { J_IMM, B_IMM, I_IMM, EPC } jmp_target_src_t;
typedef enum logic[3:0] { MEM_NONE, LOAD_DATA, STORE_DATA} memory_operation_t;
typedef enum logic[3:0] { CSR_SET, CSR_CLEAR, CSR_WRITE } write_mode_t;
typedef enum logic[3:0] { VAL_IR, VAL_PC, VAL_ADDR } val_src_t;
typedef enum logic [1:0] { BYTE, HALF_WORD, WORD } access_size_t;

typedef struct packed { //Device Map
    logic [31:0] high;
    logic [31:0] low;
} memory_map_t;

endpackage