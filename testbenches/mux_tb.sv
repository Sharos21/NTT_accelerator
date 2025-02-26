module mux_tb;
    // Testbench signals
    logic [31:0] in0;
    logic [31:0] in1;
    logic sel;
    logic [31:0] mux_out;

    // Instantiate the multiplexer
    mux uut (
        .in0(in0),
        .in1(in1),
        .sel(sel),
        .mux_out(mux_out)
    );

    // Test sequence
    initial begin
        // Initialize inputs
        in0 = 32'd5;
        in1 = 32'd10;

        // Test case 1: sel = 0
        sel = 1'b0;
        #10;  // Wait for 10 time units
       

        // Test case 2: sel = 1
        sel = 1'b1;
        #10;  // Wait for 10 time units
        

        // End simulation
        $stop;
    end

endmodule
