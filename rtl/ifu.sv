module ifu (
    input wire clk,
    input wire reset,
    input wire [31:0] ext_data_in,
    output reg [31:0] ext_addr,
    output reg [31:0] if_id_instr
);
    reg [31:0] pc;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h0;
            ext_addr <= 32'h0;
            if_id_instr <= 32'h00000013;
        end else begin
            pc <= pc + 4;
            ext_addr <= pc;
            if_id_instr <= ext_data_in;
        end
    end
endmodule