//------------------------------------------------------------------------------
// rtl: 8-bit registered ALU
// - 10 inputs, 5 outputs
// - Ops: ADD, SUB, AND, OR, XOR, LSL, LSR, ASR
// - Optional saturation on ADD/SUB
// - Compare unit (==, <, >) selected via cmp_mode
//------------------------------------------------------------------------------
// Port summary (exactly 10 inputs, 5 outputs):
// Inputs (10):
//   clk                 : clock
//   rst_n               : active-low synchronous reset
//   en                  : register enable
//   op        [2:0]     : operation select (0..7)
//   a         [7:0]     : operand A
//   b         [7:0]     : operand B
//   carry_in            : carry-in for ADD (ignored otherwise)
//   sat_enable          : saturate ADD/SUB to 0..255
//   cmp_mode  [1:0]     : 00: ==, 01: <, 10: >, 11: reserved
//   shift_amt [2:0]     : shift amount for shift ops
//
// Outputs (5):
//   y         [7:0]     : result
//   carry_out           : carry/borrow out (meaning per op)
//   zero                : y == 0
//   negative            : y[7]
//   cmp_out             : compare result per cmp_mode
//------------------------------------------------------------------------------
module rtl(
  // 10 inputs
  input  logic                   clk,
  input  logic                   rst_n,        // sync reset (active-low)
  input  logic                   en,
  input  logic [2:0]             op,
  input  logic [8-1:0]           a,
  input  logic [8-1:0]           b,
  input  logic                   carry_in,
  input  logic                   sat_enable,
  input  logic [1:0]             cmp_mode,
  input  logic [2:0]             shift_amt,

  // 5 outputs
  output logic [8-1:0]           y,
  output logic                   carry_out,
  output logic                   zero,
  output logic                   negative,
  output logic                   cmp_out
);

  // Internal combinational signals
  logic [8:0] add_ext;   // extended for carry
  logic [8:0] sub_ext;   // extended for borrow (use two’s comp)
  logic [8-1:0] alu_y_comb;
  logic carry_comb;

  //--- Arithmetic --------------------------------------------------------------
  // ADD with carry_in
  always_comb begin
    add_ext = {1'b0, a} + {1'b0, b} + {8'b0, carry_in};
  end

  // SUB: a - b (borrow encoded in MSB of sub_ext)
  always_comb begin
    sub_ext = {1'b0, a} + {1'b0, ~b} + 1'b1; // a + (~b + 1)
  end

  // Saturation logic for ADD/SUB (unsigned clamp to [0, 2^8-1])
  function automatic logic [8-1:0] sat_add(input logic [8:0] sum);
    if (sum[8])         return {8{1'b1}}; // overflow -> 0xFF
    else                    return sum[8-1:0];
  endfunction

  function automatic logic [8-1:0] sat_sub(input logic [8:0] diff);
    // If underflow (borrow), clamp to 0x00; in this encoding, borrow is !diff[8]
    // Here diff = a + (~b + 1), so underflow iff a < b, which makes carry out = 0.
    if (diff[8] == 1'b0) return {8{1'b0}}; // borrow -> 0x00
    else                     return diff[8-1:0];
  endfunction

  //--- Logic/Shift ops ---------------------------------------------------------
  logic [8-1:0] and_r, or_r, xor_r;
  logic [8-1:0] lsl_r, lsr_r, asr_r;

  assign and_r = a & b;
  assign or_r  = a | b;
  assign xor_r = a ^ b;

  assign lsl_r = a << shift_amt;
  assign lsr_r = a >> shift_amt;
  assign asr_r = $signed(a) >>> shift_amt;

  //--- Compare unit ------------------------------------------------------------
  // cmp_mode: 00 -> (a == b), 01 -> (a < b), 10 -> (a > b), 11 -> 0
  always_comb begin
    unique case (cmp_mode)
      2'b00: cmp_out = (a == b);
      2'b01: cmp_out = (a <  b);
      2'b10: cmp_out = (a >  b);
      default: cmp_out = 1'b0;
    endcase
  end

  //--- ALU result select -------------------------------------------------------
  always_comb begin
    alu_y_comb = '0;
    carry_comb = 1'b0;

    unique case (op)
      3'd0: begin // ADD
        alu_y_comb = sat_enable ? sat_add(add_ext) : add_ext[8-1:0];
        carry_comb = add_ext[8];
      end
      3'd1: begin // SUB
        alu_y_comb = sat_enable ? sat_sub(sub_ext) : sub_ext[8-1:0];
        // For SUB, treat carry_comb as NOT borrow (1 = no borrow, 0 = borrow)
        carry_comb = sub_ext[8];
      end
      3'd2: begin // AND
        alu_y_comb = and_r;
        carry_comb = 1'b0;
      end
      3'd3: begin // OR
        alu_y_comb = or_r;
        carry_comb = 1'b0;
      end
      3'd4: begin // XOR
        alu_y_comb = xor_r;
        carry_comb = 1'b0;
      end
      3'd5: begin // LSL
        alu_y_comb = lsl_r;
        carry_comb = 1'b0;
      end
      3'd6: begin // LSR
        alu_y_comb = lsr_r;
        carry_comb = 1'b0;
      end
      3'd7: begin // ASR
        alu_y_comb = asr_r;
        carry_comb = 1'b0;
      end
      default: begin
        alu_y_comb = '0;
        carry_comb = 1'b0;
      end
    endcase
  end

  //--- Registered outputs with synchronous reset ------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      y         <= '0;
      carry_out <= 1'b0;
      zero      <= 1'b1;
      negative  <= 1'b0;
    end else if (en) begin
      y         <= alu_y_comb;
      carry_out <= carry_comb;
      zero      <= (alu_y_comb == '0);
      negative  <= alu_y_comb[8-1];
    end
  end

  // Synthesis-friendly simple assertions (optional; ignored by many tools)
  // pragma translate_off
  initial begin
    assert (8 >= 2) else $error("8 must be >= 2");
  end
  // pragma translate_on

endmodule
