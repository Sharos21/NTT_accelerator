module top_module3 #(parameter W = 32,
                    parameter MODULUS= 7681,
                     parameter RADIX = 8,
                     parameter counter_Max=8)
(
    input logic clk,
    input logic rst,
    input logic [W-1:0] incoming_data, //incoming data
    //input logic [W-1:0] twiddle_factor, //omega for the mul
    output logic [W-1:0] final_result
);

///Buffer/////
logic [W-1:0] buffer_data_in;
logic [W-1:0] buffer_data_out;
logic push;
logic full;
logic empty;
logic pop;
////////////////

////Butterfly//////////
logic [W-1:0] butterfly_positive_data_out;
logic [W-1:0] butterfly_negative_data_out;
///////////////

////Multiplexers///////////
logic [W-1:0] mux_output1;
logic [W-1:0] mux_output2;
logic sel1;
logic sel2;
logic switch; // switch signal to change between the same two cases
logic [$clog2(counter_Max)-1:0] counter; // Counter
//////////////

//twiddle_factor
logic [W-1:0] twiddle_factor;

//flip flop_mul
logic enable;


//counting stages
always_ff @(posedge clk) begin
    if (rst ) begin
        counter <=0;
    end else if (counter < counter_Max-1 ) begin
        counter <= counter +1 ;
        enable <= 1;
    end else begin
         enable <=0;
    end
end

//changing stages
always_ff @(posedge clk) begin 
    if (rst) begin
        switch <=0;
    end else if (counter <= RADIX - 2) begin
        switch<=0;
    end else begin
        switch <= ~switch;
    end
end

always_comb begin
    if (counter >= RADIX - 2) begin
        if (counter == RADIX - 2) begin
            twiddle_factor = 32'd1;
            push = 1'b1;
            pop = 1'b0;
            sel1 = 1'b0;
            sel2 = 1'b1;
        end else if (switch == 1'b0) begin
            twiddle_factor = 32'd1;
            push = 1'b1;
            pop =  1'b1;
            sel1 = 1'b1;
            sel2 = 1'b1;
        end else if (switch == 1'b1) begin
            twiddle_factor = 32'd1;
            push = 1'b1;
            pop = 1'b1;
            sel1 = 1'b0;
            sel2 = 1'b0;
        end
    end
end



//Instasiate gia ton proto multiplexer
mux mux_inst1(
    .in0(incoming_data),
    .in1(butterfly_negative_data_out),
    .sel(sel1),
    .mux_out(mux_output1)
);

//Instasiate gia ton buffer
fifo_duth #(.DW(32), .DEPTH(RADIX/RADIX)
) buffer_inst (
    .clk(clk),
    .rst(rst),
    .write_data(mux_output1),
    .push(push),
    .full(full),
    .empty(empty),
    .pop(pop),
    .read_data(buffer_data_out)
);

//Butterfly
butterfly#(.MODULUS(MODULUS))
     butterfly_inst(
    .enable(full),
    .buffer_data_in(buffer_data_out),
    .normal_data_in(incoming_data),
    .positive_data_out(butterfly_positive_data_out),
    .negative_data_out(butterfly_negative_data_out)
);


mux mux_inst2(
    .in0(buffer_data_out),
    .in1(butterfly_positive_data_out),
    .sel(sel2),
    .mux_out(mux_output2)
);

//flip_flop_miltiplier multiplier_inst(
//    .clk(clk),
//    .rst(rst),
//    .enable(enable),
//    .mul_data_in(mux_output2),
//    .twiddle_factor(twiddle_factor),
//    .result(final_result)
//);

mont_mul multiplexer_inst(
    .clk(clk),
    .rst(rst),
    .A(mux_output2),
    .B(twiddle_factor),
    .M(MODULUS),
    .M_inv(8'd255),
    .S(final_result)
);

endmodule