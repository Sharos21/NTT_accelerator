module top_module_tb;


    // Parameters
    parameter W = 32;
    parameter radix = 16;
    parameter NUM_stages = 4;
    parameter ADDR_WIDTH = $clog2(radix/2);

    // Testbench signals
    logic clk;
    logic rst;
    logic start;
    logic done;
    logic [NUM_stages-1:0] full_ram;
    logic [31:0] incoming_data;
    //logic [31:0] twiddle_factor;
    logic [31:0] final_result;
   
    logic [NUM_stages-1:0] write_enable_array;
    logic [NUM_stages-1:0][W-1:0] write_data_array;
    logic [NUM_stages-1:0][ADDR_WIDTH-1:0] write_addr_array;

    integer i;

     localparam logic [radix/2-1:0] [W-1:0] twiddle_factor  = '{
        //radix 16
        32'h14E1, 32'h092F, 32'h10AA, 32'h061E,
        32'h0425, 32'h0E0E, 32'h1B30, 32'h15C1
        //radix 4
        //32'h061E, 32'h15C1
        
    };

   
    // Instantiate the top module
    top_top_module #(.W(W), .radix(radix)) uut  ( 
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .incoming_data(incoming_data),
        .write_en_array(write_enable_array),
        .write_data_array(write_data_array),
        .write_addr_array(write_addr_array),
       //.twiddle_factor(twiddle_factor),
        .final_result(final_result),
        .full_ram(full_ram)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        incoming_data = 0;
        write_enable_array = '0;
        write_data_array = '0;
        write_addr_array = '0;
        
        //  reset
        #10 rst = 0;

        

        //stage 0
        for (int i = 0; i < radix/2; i++) begin
            write_enable_array[0] = 1;
            write_addr_array[0] = i;
            write_data_array[0] = twiddle_factor[i];
            #10;
        end
        
        write_enable_array[0] = 0;
       

        //stage 1 
        for (int i = 0; i < radix/4; i++) begin
            write_enable_array[1] = 1;
            write_addr_array[1] = i;
            write_data_array[1] = twiddle_factor[i * 2];
            #10;
        end
       
        write_enable_array[1] = 0;

       //stage 2
        write_enable_array[2] = 1;
        write_addr_array[2] = 0;
        write_data_array[2] = twiddle_factor[0];
        #10;
        write_addr_array[2] = 1;
        write_data_array[2] = twiddle_factor[4];
        #10;
        
        write_enable_array[2] = 0;

       //stage 3
        write_enable_array[3] = 1;
        write_addr_array[3] = 0;
        write_data_array[3] = twiddle_factor[0];
        #10;
        
        write_enable_array[3] = 0;
        
        #10 start =1; incoming_data = 32'd5569;// First input

       
        //Test data   
        #10 incoming_data = 32'd3457;  // Second input
        #10 incoming_data = 32'd1345;  // Third input
        #10 incoming_data = 32'd6914;  // Fourth input
        #10 incoming_data = 32'd4802;  // 5th
        #10 incoming_data = 32'd2690;  // 6th
        #10 incoming_data = 32'd578;  // 7th
        #10 incoming_data = 32'd6147;  // 8th
        #10 incoming_data = 32'd4035;
        #10 incoming_data = 32'd1923;
        #10 incoming_data = 32'd7492;
        #10 incoming_data = 32'd5380;
        #10 incoming_data = 32'd3268;
        #10 incoming_data = 32'd1156;
        #10 incoming_data = 32'd6725;
        #10 incoming_data = 32'd0;
      
         //@(posedge done);
        #10000;
        $stop;
    end

endmodule
