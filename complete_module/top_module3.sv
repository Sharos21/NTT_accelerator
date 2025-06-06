module top_module3 #(parameter W = 32,
                    parameter MODULUS= 7681,
                    parameter RADIX = 8,
                    parameter counter_Max=8,
                    parameter twiddle_buffer_depth = 8,
                    parameter NUM_stages= 3)
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [W-1:0] incoming_data, //incoming data
    //input logic [W-1:0] twiddle_factor, //omega for the mul
    input logic write_en,
    input logic[$clog2(twiddle_buffer_depth)-1:0] write_addr,
    input logic [W-1:0] write_data,
    output logic [W-1:0] final_result,
    output logic done,
    output logic full_ram
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

//twiddle_factor for last step is always gonna be one 
logic twiddle_index;
logic [W-1:0] twiddle_factor;

//flip flop_mul
logic enable;
//done_counter
logic [$clog2(counter_Max):0] done_counter;


//counting stages
always_ff @(posedge clk) begin
    if (rst || !start ) begin
        counter <=0;
        done_counter<=0;
    end else if (counter < counter_Max-1 ) begin
        counter <= counter +1 ;
        done_counter<=0;
        //enable <= 1;
    end else if(!done) begin
         //enable <=0;
         done_counter <= done_counter +1;
    end
end

assign done = (done_counter==NUM_stages*4) ? 1 : 0;

//changing stages
always_ff @(posedge clk) begin 
    if (rst || !start) begin
        switch <=0;
    end else if (counter <= RADIX - 2) begin
        switch<=0;
    end else begin
        switch <= ~switch;
    end
end

twiddle_ram #(.W(W), .DEPTH(1)) twiddle_ram_inst (
    .clk(clk),
    .read_addr(twiddle_index),
    .read_data(twiddle_factor),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_en(write_en),
    .full_ram(full_ram)
  );

assign twiddle_index =0; // gia na pernei panta to ω^0

always_comb begin
    if (counter >= RADIX - 2 && !done) begin
        if (counter == RADIX - 2) begin
            //twiddle_factor = 32'd1; // auto prepei na allaxei gia na einai se montgomery form omos to afino etsi gia na exo kanonikopoiimeni exodo
            push = 1'b1;
            pop = 1'b0;
            sel1 = 1'b0;
            sel2 = 1'b1;
        end else if (switch == 1'b0) begin
            //twiddle_factor = 32'd1; // auto prepei na allaxei gia na einai se montgomery form
            push = 1'b1;
            pop =  1'b1;
            sel1 = 1'b1;
            sel2 = 1'b1;
        end else if (switch == 1'b1) begin
            //twiddle_factor = 32'd1; // auto prepei na allaxei gia na einai se montgomery form
            push = 1'b1;
            pop = 1'b1;
            sel1 = 1'b0;
            sel2 = 1'b0;
        end
    end else if (done) begin
            push = 1'b0;
            pop = 1'b1;
            sel1 = 1'b1;
            sel2 = 1'b1;
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
    .enable(!done),
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
    .enable(done),
    .S(final_result)
);

endmodule