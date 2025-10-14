module dec (
    input wire clk,
    input wire reset,
    input wire [31:0] if_id_instr,
    input wire [31:0] wb_data,
    output reg [31:0] id_ex_rs1,
    output reg [31:0] id_ex_rs2,
    output reg [31:0] id_ex_imm
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            id_ex_rs1 <= 32'h0;
            id_ex_rs2 <= 32'h0;
            id_ex_imm <= 32'h0;
        end else begin
            id_ex_rs1 <= wb_data + 1;
            id_ex_rs2 <= wb_data + 2;
            id_ex_imm <= { {20{if_id_instr[31]}}, if_id_instr[31:20] };
        end
    end
endmodule