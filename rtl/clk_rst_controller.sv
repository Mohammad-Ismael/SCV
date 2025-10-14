module simple_clk_rst (
    output wire clk,
    output wire reset
);
    reg clk_reg = 0;
    reg rst_reg = 1;
    
    always #10 clk_reg = ~clk_reg;
    
    initial begin
        #100 rst_reg = 0;
    end

    assign clk = clk_reg;
    assign reset = rst_reg;
endmodule