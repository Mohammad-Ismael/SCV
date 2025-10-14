module exu (
    input wire clk,
    input wire reset,
    input wire [31:0] id_ex_rs1,
    input wire [31:0] id_ex_rs2,
    input wire [31:0] id_ex_imm,
    output reg [31:0] ex_mem_alu,
    output reg [31:0] ex_mem_store_data
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_alu <= 32'h0;
            ex_mem_store_data <= 32'h0;
        end else begin
            ex_mem_alu <= id_ex_rs1 + id_ex_imm;
            ex_mem_store_data <= id_ex_rs2;
        end
    end
endmodule