module buffer_tb;

    // Parameters
    parameter WIDTH = 32;
    parameter DEPTH = 2;

    // Signals
    logic clk;
    logic rst;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;
    logic valid_out;

    // Instantiate the buffer module
    buffer #(WIDTH, DEPTH) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // Clock Generation: 10ns period
    always #5 clk = ~clk;

    // Stimulus block
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        data_in = 32'b0;

        // Apply reset
        $display("Applying reset...");
        rst = 1;
        #10 rst = 0;  // De-assert reset after 10ns
        
        // Apply test data
        $display("Applying test data...");

        // Input data sequence
        data_in = 1;  // Test 1
        #10 data_in = 2; // Test 2
        #10 data_in = 3; // Test 3
        #10 data_in = 4;  // Test 4

        // After some cycles, check output
        #10 $display("Checking output after buffer is full...");

        // Observe the values of data_out and valid_out
        $monitor("Time = %0t | data_in = %h | data_out = %h | valid_out = %b", $time, data_in, data_out, valid_out);

        // Run simulation for enough time to see the behavior
        #40;
        
        // End simulation
        $stop;
    end

endmodule
