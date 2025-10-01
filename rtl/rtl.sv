module rtl #(
    parameter DATA_WIDTH = 8,
    parameter SEL_WIDTH = 4  // 2^4 = 16 > 10, so enough for 10 ports
) (
    input logic clk,
    input logic rst_n,
    input logic [SEL_WIDTH-1:0] sel,
    input logic [DATA_WIDTH-1:0] port0_in,
    input logic [DATA_WIDTH-1:0] port1_in,
    input logic [DATA_WIDTH-1:0] port2_in,
    input logic [DATA_WIDTH-1:0] port3_in,
    input logic [DATA_WIDTH-1:0] port4_in,
    input logic [DATA_WIDTH-1:0] port5_in,
    input logic [DATA_WIDTH-1:0] port6_in,
    input logic [DATA_WIDTH-1:0] port7_in,
    input logic [DATA_WIDTH-1:0] port8_in,
    input logic [DATA_WIDTH-1:0] port9_in,
    output logic [DATA_WIDTH-1:0] mux_out,
    output logic valid_out
);

// Internal signal for combinational logic
logic [DATA_WIDTH-1:0] mux_out_comb;

// 10-to-1 multiplexer using case statement
always @(*) begin
    case (sel)
        4'd0: mux_out_comb = port0_in;
        4'd1: mux_out_comb = port1_in;
        4'd2: mux_out_comb = port2_in;
        4'd3: mux_out_comb = port3_in;
        4'd4: mux_out_comb = port4_in;
        4'd5: mux_out_comb = port5_in;
        4'd6: mux_out_comb = port6_in;
        4'd7: mux_out_comb = port7_in;
        4'd8: mux_out_comb = port8_in;
        4'd9: mux_out_comb = port9_in;
        default: mux_out_comb = {DATA_WIDTH{1'b0}}; // Default to 0
    endcase
end

// Registered output for better timing
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mux_out <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end else begin
        mux_out <= mux_out_comb;
        // valid_out is high when sel is between 0-9
        valid_out <= (sel <= 4'd9);
    end
end

endmodule
