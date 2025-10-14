module main_memory (
    input wire clk,
    input wire reset,
    input wire mem_en,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_data_in,
    output reg [31:0] mem_data_out
);

    reg [31:0] memory [0:255];
    
    initial begin
        // Initialize memory
        for (integer i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'h00000000;
        end
        
        // Simple test program
        memory[0] = 32'h00100093;  // addi x1, x0, 1
        memory[1] = 32'h00200113;  // addi x2, x0, 2
        memory[2] = 32'h00300193;  // addi x3, x0, 3
        memory[3] = 32'h00400213;  // addi x4, x0, 4
        memory[4] = 32'h00500293;  // addi x5, x0, 5
        
        for (integer i = 5; i < 256; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end
    end
    
    // Memory read
    always @(*) begin
        if (mem_en && !reset) begin
            if (mem_addr < 1024) begin
                mem_data_out = memory[mem_addr[9:2]];
            end else begin
                mem_data_out = 32'h00000013;
            end
        end else begin
            mem_data_out = 32'h00000013;
        end
    end
    
    // Memory write
    always @(posedge clk) begin
        if (mem_en && !reset && mem_data_in != 32'h0) begin
            if (mem_addr < 1024) begin
                memory[mem_addr[9:2]] <= mem_data_in;
            end
        end
    end

endmodule