module top;

    // Clock and reset signals
    wire clk, reset;

    // Processor interface signals
    wire [31:0] proc_addr;
    wire [31:0] proc_data_out;
    wire proc_mem_en;
    wire [31:0] proc_data_in;

    // Test control
    integer cycle_count = 0;
    reg test_pass;

    // Instantiate clock/reset generator
    simple_clk_rst clk_rst_gen (
        .clk(clk),
        .reset(reset)
    );

    // Instantiate processor
    riscv_processor uut (
        .clk(clk),
        .reset(reset),
        .ext_data_in(proc_data_in),
        .ext_addr(proc_addr),
        .ext_data_out(proc_data_out),
        .ext_mem_en(proc_mem_en)
    );

    // Instantiate main memory
    main_memory memory (
        .clk(clk),
        .reset(reset),
        .mem_en(proc_mem_en),
        .mem_addr(proc_addr),
        .mem_data_in(proc_data_out),
        .mem_data_out(proc_data_in)
    );

    // Cycle counter
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count <= cycle_count + 1;
        end else begin
            cycle_count <= 0;
        end
    end

    // Main test sequence - UPDATED FOR 5000ns
    initial begin
        test_pass = 1;
        $display("Starting RISC-V Processor Testbench");
        $display("Simulation will run for approximately 5000 ns");

        // Wait for reset to complete
        @(negedge reset);
        $display("Reset released at time %0t", $time);

        // Run for 5000ns instead of 1000ns
        #5000;

        // Enhanced verification
        if (proc_mem_en !== 1'b1) begin
            $display("FAIL: Memory enable not asserted");
            test_pass = 0;
        end

        if (uut.IFU.ext_addr[1:0] !== 2'b00) begin
            $display("FAIL: PC misaligned");
            test_pass = 0;
        end

        if (cycle_count < 200) begin  // Adjusted minimum cycles for longer run
            $display("FAIL: Not enough cycles executed");
            test_pass = 0;
        end

        // Final report
        $display("\n=== Simulation Complete ===");
        $display("Time: %0t ns, Cycles: %0d", $time, cycle_count);
        $display("Final PC: %h", uut.IFU.ext_addr);
        $display("Instructions Executed: ~%0d", cycle_count - 1);

        if (test_pass) begin
            $display("*** TEST PASSED ***");
        end else begin
            $display("*** TEST FAILED ***");
        end

        $finish;
    end

    // Enhanced monitoring
    initial begin
        $display("Cycle | PC       | Instruction");
        $display("------+----------+-------------");

        forever begin
            @(posedge clk);
            if (!reset && cycle_count > 0 && cycle_count < 100) begin  // Show first 100 cycles
                $display("%5d | %8h | %h",
                        cycle_count,
                        uut.IFU.ext_addr - 4,
                        uut.IFU.if_id_instr);
            end
        end
    end

       initial begin
        $dumpfile("riscv_processor_sv.vcd");
        $dumpvars(0, top);
        $display("SystemVerilog VCD tracing enabled");
    end

    // Timeout protection
    initial begin
        #6000; // 6000ns timeout (slightly longer than 5000ns)
        $display("\n*** TIMEOUT: Simulation exceeded 6000 ns ***");
        $display("*** TEST FAILED - Simulation too long ***");
        $finish;
    end

endmodule