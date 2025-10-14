module wb (
    input wire clk,
    input wire reset,
    input wire [31:0] mem_wb_result,
    output reg [31:0] wb_data
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wb_data <= 32'h0;
        end else begin
            wb_data <= mem_wb_result;
        end
    end
endmodule