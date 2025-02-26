module butterfly_tb;



logic [31:0] buffer_data_in, normal_data_in;

logic [31:0] positive_data_out;
logic [31:0] negative_data_out;

butterfly uut(
    
    .buffer_data_in(buffer_data_in),
    .normal_data_in(normal_data_in),
    .positive_data_out(positive_data_out),
    .negative_data_out(negative_data_out)
);


initial begin


buffer_data_in = 32'd1;
normal_data_in = 32'd3;
#10;


buffer_data_in = 32'd2;
normal_data_in = 32'd4;

#10;


buffer_data_in = 32'd7679;
normal_data_in = 32'd6766;

#10;

$stop;
end
endmodule