module top_top_module #(parameter W =32,radix = 16 ,NUM_stages = $clog2(radix) -1)
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [W-1:0] incoming_data,
    input  logic [NUM_stages:0] write_en_array,
    input  logic [NUM_stages:0][W-1:0] write_data_array,
    input  logic [NUM_stages:0][$clog2(radix/2)-1:0] write_addr_array, 
    //input logic [W-1:0] twiddle_factor,
    output logic [W-1:0] final_result,
    output logic done,
    output logic [NUM_stages:0] full_ram
);

//localparam NUM_stages = $clog2(radix) -1; // auto xreiazetai peiragma
logic [W-1:0] stage_results [0:NUM_stages];
assign stage_results[0] = incoming_data;


//First module
//logic [W-1:0] result1;
//logic [W-1:0] result2;
//logic [W-1:0] result3;


genvar i;
generate
    for( i=0; i< NUM_stages; i++) begin :top_module1_inst
//assign counter_thr = (i==0)? 0 : (i*8) + 4;


top_module1 #(.W(W), .MODULUS(7681), .counter_Max(radix*2), .counter_threshold((i == 0) ? 0 : (radix/2 + 4*i)),
               .FIFO_DEPTH(radix >> (i + 1)), .step(radix >> (i + 1)), .RADIX(radix), .twiddle_buffer_depth(radix >> (i + 1)))// .twiddle_increase(1)) //.TWIDDLE_ARRAY('{32'd5345, 32'd2351, 32'd4266, 32'd1566, 32'd1061, 32'd3598, 32'd6960, 32'd5569}) ) //32'd5345, 32'd2351, 32'd4266, 32'd1566, 32'd1061, 32'd3598, 32'd6960, 32'd5569
    top_inst(
    .clk(clk),
    .rst(rst),
    .incoming_data(stage_results[i]),
    .start(start),
    .write_en(write_en_array[i]),
    .write_data(write_data_array[i]),
    .write_addr(write_addr_array[i][($clog2(radix >> (i + 1)) - 1) : 0]),
    //.twiddle_factor(twiddle_factor),
    .final_result(stage_results[i+1]),
    .full_ram(full_ram[i])
);
    end
endgenerate
//
//top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(0), // + 4 in each counter threshold 
//               .FIFO_DEPTH(8), .step(8), .RADIX(16), .twiddle_buffer_depth(8)) // .twiddle_increase(2)) //.TWIDDLE_ARRAY('{32'd2351, 32'd1566, 32'd3598, 32'd5569}) )
// top1(
//    .clk(clk),
//    .rst(rst),
//    .incoming_data(incoming_data),
//    //.twiddle_factor(twiddle_factor),
//    .final_result(result1)
//);
//
//
//
//top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(12), // + 4 in each counter threshold 
//               .FIFO_DEPTH(4), .step(4), .RADIX(8), .twiddle_buffer_depth(8)) // .twiddle_increase(2)) //.TWIDDLE_ARRAY('{32'd2351, 32'd1566, 32'd3598, 32'd5569}) )
// top2(
//    .clk(clk),
//    .rst(rst),
//    .incoming_data(result1),
//    //.twiddle_factor(twiddle_factor),
//    .final_result(result2)
//);
//
//top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(16), // + 4 in each counter threshold
//               .FIFO_DEPTH(2), .step(2), .RADIX(4), .twiddle_buffer_depth(8)) // .twiddle_increase(4)) //.TWIDDLE_ARRAY('{32'd1566, 32'd5569}) ) //32'd1566 32'd5569
//top3(
//    .clk(clk),
//    .rst(rst),
//    .incoming_data(result2),
//    //.twiddle_factor(twiddle_factor),
//    .final_result(result3)
//);

//Sto teleutaio module panta  to oliko RADIX
top_module3 #(.W(W), .MODULUS(7681), .RADIX(radix), .counter_Max(radix*2), .twiddle_buffer_depth(radix>>NUM_stages), .NUM_stages(NUM_stages+1))
 top4(      
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .write_en(write_en_array[NUM_stages]),
    .write_data(write_data_array[NUM_stages]),
    .write_addr(write_addr_array[NUM_stages][($clog2(radix >> NUM_stages) - 1) : 0]),
    .incoming_data(stage_results[NUM_stages]),
    //.twiddle_factor(twiddle_factor),
    .final_result(final_result),
    .full_ram(full_ram[NUM_stages])
);

endmodule

