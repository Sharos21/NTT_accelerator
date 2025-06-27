module top_module1 #(parameter W = 32,
                    parameter MODULUS = 7681,
                    parameter counter_Max = 16, // Maximum counter value
                    parameter counter_threshold = 0,
                    parameter FIFO_DEPTH = 4,
                    parameter step = 4,
                    parameter RADIX = 8,
                    parameter twiddle_buffer_depth = 8,
                    parameter twiddle_increase = twiddle_buffer_depth/FIFO_DEPTH 
                   // parameter [RADIX/2-1:0][W-1:0] TWIDDLE_ARRAY = '{32'd5756, 32'd4298, 32'd1213, 32'd1} // Twiddle factors
)                                                                   
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [W-1:0] incoming_data, // Incoming data
    input logic write_en,
    input logic[$clog2(twiddle_buffer_depth)-1:0] write_addr,
    input logic [W-1:0] write_data,
    input logic done,
    output logic [W-1:0] final_result,
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
logic enable;
logic [W-1:0] butterfly_positive_data_out;
logic [W-1:0] butterfly_negative_data_out;
///////////////

////Multiplexers///////////
logic [W-1:0] mux_output1;
logic [W-1:0] mux_output2;
logic sel1;
logic sel2;
logic [$clog2(counter_Max)-1:0] counter; // Counter
//////////////


logic [$clog2(twiddle_buffer_depth)-1 : 0] twiddle_index;
logic [W-1:0] twiddle_factor;



always_ff @(posedge clk) begin
    if (rst)            counter <= 0;
    else if (!start)    counter <= 0;
    else                counter <= counter + 1;
  end





logic [$clog2(step):0] threshold_activation_count; // Counter to track how many times condition is true

always_ff @(posedge clk) begin
    if (rst || !start) begin
        threshold_activation_count <= 0;
    end else if (counter >= counter_threshold && threshold_activation_count < step) begin
        threshold_activation_count <= threshold_activation_count + 1;
    end
end


  localparam int STEP_WIDTH = $clog2(step);
  wire step_max ;
  assign step_max = &counter[STEP_WIDTH-1:0];  // reduction AND
  logic tgl_edge, tgl_edge_d;

  always_ff @(posedge clk) begin
    if (rst) begin
      tgl_edge_d <= 1'b0;
      tgl_edge   <= 1'b0;
    end else begin
      tgl_edge_d <= step_max;
      tgl_edge   <= step_max && !tgl_edge_d;
    end
  end

logic [1:0] case_sel, next_case_sel;

always_ff @(posedge clk or posedge rst) begin
    if (rst) case_sel <= 2'd3;
    else     case_sel <= next_case_sel;
  end

  // Combinational next-state + outputs
  always_comb begin
    // default next-state
    next_case_sel = case_sel;

    // calculate next_case_sel
    if (!start) begin
      next_case_sel = 2'd2;
    end else if (threshold_activation_count < step) begin
      next_case_sel = 2'd3;
    end else begin
      if (tgl_edge)
        next_case_sel = (case_sel == 2'd1) ? 2'd0 : 2'd1;
      else
        next_case_sel = case_sel;
    end

    // default outputs
    push = 1'b0; 
    if (counter < counter_threshold) begin
      pop = 1'b1;
    end else begin
    pop = 1'b0; 
    end
    sel1 = 1'b0; sel2 = 1'b0;
    case (next_case_sel)
      2'd3: begin
        push = 1'b1;
        sel2 = 1'b1;
      end
      2'd2: begin
        // all zeros
      end
      2'd1: begin
        push = 1'b1;
        pop  = 1'b1;
        sel1 = 1'b1;
        sel2 = 1'b1;
      end
      2'd0: begin
        push = 1'b1;
        pop  = 1'b1;
      end
    endcase
  end

  // ------------------------------------------------------------------
  // 5) Twiddle index update
  // ------------------------------------------------------------------
  //logic [$clog2(twiddle_buffer_depth)-1:0] next_twiddle_index;
  always_ff @(posedge clk ) begin
    if (rst) twiddle_index <= 0;
    else if (next_case_sel == 2'd0)
      twiddle_index <= twiddle_index + 1;
    else
      twiddle_index <= 0;
  end
  



//Instatiation of rom for each top_module
twiddle_ram #(.W(W), .DEPTH(twiddle_buffer_depth)) twiddle_ram_inst (
    .clk(clk),
    .rst(rst),
    .read_addr(twiddle_index),
    .read_data(twiddle_factor),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_en(write_en),
    .full_ram(full_ram)
  );

/*
always_comb begin
    case (case_sel)
        default: begin 
                //twiddle_factor = TWIDDLE_ARRAY[twiddle_index];
                if(counter < counter_threshold) begin
                    pop = 1'b1;
                end else begin
                    pop = 1'b0;
                end

                if(rst) begin
                push = 1'b0;
                end else begin
                push = 1'b1;
                end
                //pop =  1'b0;
                sel1 = 1'b0;
                sel2 = 1'b1;
        end

        2'd2: begin
                push = 1'b0;
                pop = 1'b0;
                sel1 = 1'b0;
                sel2 = 1'b0;
        end

        2'd1: begin // i katastasi 1 
                //twiddle_factor = TWIDDLE_ARRAY[twiddle_index];
                push = 1'b1;
                pop = 1'b1;
                sel1 = 1'b1;
                sel2 = 1'b1;
        end

        2'd0: begin //  i katastasi pou exo 0 aplos 
            //twiddle_factor = TWIDDLE_ARRAY[twiddle_index]; 
            push = 1'b1;
            pop = 1'b1;
            sel1 = 1'b0;
            sel2 = 1'b0;
        end
    endcase
end
*/


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
butterfly #(.MODULUS(MODULUS)
) butterfly_inst(
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

mont_mul multiplexer_inst(
    .clk(clk),
    .rst(rst),
    .A(mux_output2),
    .B(twiddle_factor),
    .M(MODULUS),
    .M_inv(8'd255),
    .enable(1'b0), // 0 in order to work always
    .S(final_result)
);

//multiplier multiplier_inst(
//    .clk(clk),
//    .rst(rst),
//    .mul_data_in(mux_output2),
//    .twiddle_factor(twiddle_factor),
//    .result(final_result)
//);


endmodule