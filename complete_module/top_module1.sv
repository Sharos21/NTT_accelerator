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
    input logic [W-1:0] incoming_data, // Incoming data
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
logic [$clog2(counter_Max)-1:0] counter; // Counter
//////////////

// Twiddle factor logic
//logic [$clog2(RADIX/2) > 0 ? $clog2(RADIX/2) - 1 : 0 : 0] twiddle_index;
//logic [W-1:0] twiddle_array [0:RADIX/2-1]; // Twiddle factor array

logic [$clog2(twiddle_buffer_depth)-1 : 0] twiddle_index;
logic [W-1:0] twiddle_factor;

// Initialize twiddle_array from the parameter
//generate
//    genvar i;
//    for (i = 0; i < RADIX/2; i = i + 1) begin
//        assign twiddle_array[i] = TWIDDLE_ARRAY[i];
//    end
//endgenerate

// to change between the cases
logic [1:0] case_sel;


always_ff @(posedge clk) begin
    if (rst ) begin 
        counter <=0;
        twiddle_index <=0;
    end else begin
        counter <= counter +1 ;
        if(case_sel == 2'd0) begin
            twiddle_index <= twiddle_index + twiddle_increase; // isos na mporo na peraso to ena san parametro oste na kano sosto parse
        end else 
            twiddle_index <= 0;
    end
end





logic [$clog2(step):0] threshold_activation_count; // Counter to track how many times condition is true

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        threshold_activation_count <= 0;
    end else if (counter >= counter_threshold && threshold_activation_count < step) begin
        threshold_activation_count <= threshold_activation_count + 1;
    end
end

logic [$clog2(step)-1:0] step_cnt;
logic                   tgl_edge;

always_comb begin
    if(rst) begin
        case_sel = 2'd3;
        step_cnt = 0;
        tgl_edge =0;
    end else begin
        
            if(threshold_activation_count < step) begin
                case_sel = 2'd3;
            end else begin
                step_cnt = counter;
                tgl_edge = (step_cnt ==0) ? 1 : 0 ;
                //if(step_cnt == 0) begin
                //    tgl_edge = 1;
                //end else begin
                //    tgl_edge = 0;
                //end

                if (tgl_edge) begin
                    case_sel = (case_sel == 2'd1) ? 2'd0 : 2'd1; // Toggle between `1` and `2`
                end
            end
        
    end
end


//always_comb begin
//    //if (counter >= counter_threshold) begin
//        
//
//        if (threshold_activation_count < step) begin
//            case_sel = 2'd3; // Default case
//        end else begin
//            // change between cases 
//            if (counter  % step == 0) begin
//                case_sel = (case_sel == 2'd1) ? 2'd0 : 2'd1; // Toggle between `1` and `2`
//            end
//        end
//
//    //end else begin
//    //    case_sel = 2'd3; // Default case before threshold
//    //end
//end

//Instatiation of rom for each top_module
twiddle_rom #(.W(W), .DEPTH(twiddle_buffer_depth)) twiddle_rom_inst (
    .addr(twiddle_index),
    .data(twiddle_factor)
  );

always_comb begin
    case (case_sel)
        default: begin 
                //twiddle_factor = TWIDDLE_ARRAY[twiddle_index];
                if(counter < counter_threshold) begin
                    pop = 1'b1;
                end else begin
                    pop = 1'b0;
                end
                push = 1'b1;
                //pop =  1'b0;
                sel1 = 1'b0;
                sel2 = 1'b1;
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


//assign enable = (counter < RADIX/2)? 0 : 1; 


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