module top #(
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



    rtl u_rtl (.*);
endmodule


