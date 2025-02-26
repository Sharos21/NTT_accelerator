module top_module2 #(parameter W = 32,
                    parameter counter_Max = 16,
                    parameter RADIX = 4,
                    parameter counter_start = 0,
                    parameter FIFO_DEPTH = 2)
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
logic enable;
logic [W-1:0] butterfly_positive_data_out;
logic [W-1:0] butterfly_negative_data_out;
///////////////

////Multiplexers///////////
logic [W-1:0] mux_output1;
logic [W-1:0] mux_output2;
logic sel1;
logic sel2;
logic [$clog2(counter_Max)-1:0] counter; // this number has to change if i change the parameters
//////////////

//twiddle_factor
logic [W-1:0] twiddle_factor;

always_ff @(posedge clk) begin
    if (rst ) begin // isos edo na xreiazetai na balo to counter == me kati
        counter <=0;
    end else begin
        counter <= counter +1 ;
    end
end

assign enable = (counter < RADIX/2)? 0: 1; // isos xreiazetai allagi



/////////
always_comb begin
    if( counter > 4'd3 && counter < 4'd6) begin
        twiddle_factor = 32'd1;
        push = 1'b1;
        sel1 = 1'b0;
        sel2 = 1'b1;
        pop =  1'b0;
    end else if( counter < 4'd8) begin
        twiddle_factor = 32'd1;
        sel1 = 1'b1;
        sel2 = 1'b1;
        push = 1'b1;
        pop = 1'b1;
    end else if(counter == 4'd8) begin
        twiddle_factor =32'd1;
        push = 1'b1;
        pop = 1'b1;
        sel1 = 1'b0;
        sel2 = 1'b0;
    end else if (counter == 4'd9) begin
        twiddle_factor = 32'd4298;
        push = 1'b1;
        pop = 1'b1;
        sel1 = 1'b0;
        sel2 = 1'b0;
    end else if (counter == 4'd10) begin
        twiddle_factor = 32'd1;
        push = 1'b1;
        pop = 1'b1;
        sel1 = 1'b1;
        sel2 = 1'b1;
    end else if (counter == 4'd11) begin
        twiddle_factor = 32'd1;
        push = 1'b1;
        pop = 1'b1;
        sel1 = 1'b1;
        sel2 = 1'b1;
    end else if (counter == 4'd12) begin
        twiddle_factor = 32'd1;
        push = 1'b0;
        pop = 1'b1;
        sel1 = 1'b0;
        sel2 = 1'b0;
    end else if (counter > 4'd12) begin
        twiddle_factor = 32'd4298;
        push = 1'b0;
        pop = 1'b1;
        sel1 = 1'b0;
        sel2 = 1'b0;
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
fifo_duth #(.DW(32), .DEPTH(FIFO_DEPTH)
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
butterfly butterfly_inst(
    .enable(enable),
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

multiplier multiplier_inst(
    .clk(clk),
    .rst(rst),
    .mul_data_in(mux_output2),
    .twiddle_factor(twiddle_factor),
    .result(final_result)
);


endmodule