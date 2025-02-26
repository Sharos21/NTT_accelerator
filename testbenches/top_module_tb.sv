module top_module_tb;

    // Testbench signals
    logic clk;
    logic rst;
    logic [31:0] incoming_data;
    //logic [31:0] twiddle_factor;
    logic [31:0] final_result;
   
    

    // Instantiate the top module
    top_top_module #(.W(32)) uut  (
        .clk(clk),
        .rst(rst),
        .incoming_data(incoming_data),
       //.twiddle_factor(twiddle_factor),
        .final_result(final_result)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        
       //twiddle_factor = 32'd1;
        

        // Apply reset
        #10 rst = 0; incoming_data = 32'd1;// First input

        // Provide test data
          
        #10 incoming_data = 32'd2;  // Second input
        #10 incoming_data = 32'd3;  // Third input
        #10 incoming_data = 32'd4;  // Fourth input
        #10 incoming_data = 32'd5;  // 5th
        #10 incoming_data = 32'd6;  // 6th
        #10 incoming_data = 32'd7;  // 7th
        #10 incoming_data = 32'd8;  // 8th
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
        #10 incoming_data = 32'd0;
      

        // Wait for processing
        #300;

        // End simulation
        $stop;
    end

endmodule
