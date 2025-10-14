module riscv_processor (
    input wire clk,
    input wire reset,
    input wire [31:0] ext_data_in,
    output wire [31:0] ext_addr,
    output wire [31:0] ext_data_out,
    output wire ext_mem_en
);

    wire [31:0] if_id_instr;
    wire [31:0] id_ex_rs1, id_ex_rs2, id_ex_imm;
    wire [31:0] ex_mem_alu, ex_mem_store_data;
    wire [31:0] wb_data;

    // IFU - Instruction Fetch Unit
    ifu IFU (
        .clk(clk),
        .reset(reset),
        .ext_data_in(ext_data_in),
        .ext_addr(ext_addr),
        .if_id_instr(if_id_instr)
    );

    // DEC - Instruction Decode
    dec DEC (
        .clk(clk),
        .reset(reset),
        .if_id_instr(if_id_instr),
        .wb_data(wb_data),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_imm(id_ex_imm)
    );

    // EXU - Execution Unit
    exu EXU (
        .clk(clk),
        .reset(reset),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_imm(id_ex_imm),
        .ex_mem_alu(ex_mem_alu),
        .ex_mem_store_data(ex_mem_store_data)
    );

    // WB - Write Back Unit
    wb WB (
        .clk(clk),
        .reset(reset),
        .mem_wb_result(ex_mem_alu),
        .wb_data(wb_data)
    );

    // Memory interface
    assign ext_data_out = ex_mem_store_data;
    assign ext_mem_en = ~reset;

endmodule