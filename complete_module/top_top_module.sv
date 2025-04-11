module top_top_module #(parameter W =32)
(
    input logic clk,
    input logic rst,
    input logic [W-1:0] incoming_data,
    //input logic [W-1:0] twiddle_factor,
    output logic [W-1:0] final_result
);


//First module
logic [W-1:0] result1;
logic [W-1:0] result2;
logic [W-1:0] result3;

top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(0),
               .FIFO_DEPTH(8), .step(8), .RADIX(16), .TWIDDLE_ARRAY('{32'd5345, 32'd2351, 32'd4266, 32'd1566, 32'd1061, 32'd3598, 32'd6960, 32'd5569}) ) //32'd5345, 32'd2351, 32'd4266, 32'd1566, 32'd1061, 32'd3598, 32'd6960, 32'd5569
 top1(
    .clk(clk),
    .rst(rst),
    .incoming_data(incoming_data),
    //.twiddle_factor(twiddle_factor),
    .final_result(result1)
);

top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(12),
               .FIFO_DEPTH(4), .step(4), .RADIX(8), .TWIDDLE_ARRAY('{32'd2351, 32'd1566, 32'd3598, 32'd5569}) )
 top2(
    .clk(clk),
    .rst(rst),
    .incoming_data(result1),
    //.twiddle_factor(twiddle_factor),
    .final_result(result2)
);

top_module1 #(.W(32), .MODULUS(7681), .counter_Max(32), .counter_threshold(16),
               .FIFO_DEPTH(2), .step(2), .RADIX(4), .TWIDDLE_ARRAY('{32'd1566, 32'd5569}) ) //32'd1566 32'd5569
top3(
    .clk(clk),
    .rst(rst),
    .incoming_data(result2),
    //.twiddle_factor(twiddle_factor),
    .final_result(result3)
);

//Sto teleutaio module panta  to oliko RADIX
top_module3 #(.W(32), .MODULUS(7681), .RADIX(16), .counter_Max(32)) top4(      
    .clk(clk),
    .rst(rst),
    .incoming_data(result3),
    //.twiddle_factor(twiddle_factor),
    .final_result(final_result)
);

endmodule

