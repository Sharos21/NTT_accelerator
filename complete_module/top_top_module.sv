module top_top_module #(parameter W = 32, NUM_INSTANCES = 3)
(
    input logic clk,
    input logic rst,
    input logic [W-1:0] incoming_data,
    output logic [W-1:0] final_result
);

    // Intermediate results
    logic [W-1:0] results [NUM_INSTANCES:0];

    // Assign the incoming data to the first result
    assign results[0] = incoming_data;

    // Generate block to create multiple instances of top_module1
    generate
        genvar i;
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin : gen_top_module
            // Calculate parameters based on current i
            localparam FIFO_DEPTH = 8 / (2 ** i);
            localparam RADIX = 16 / (2 ** i);
            localparam step = FIFO_DEPTH;
            localparam counter_threshold = 16 - (16 >> i);
            localparam TWIDDLE_SIZE = 8 / (2 ** i);

            // Define TWIDDLE_ARRAY based on i
            localparam logic [W-1:0] TWIDDLE_ARRAY [TWIDDLE_SIZE-1:0] =
                (i == 0) ? '{32'd583, 32'd5756, 32'd849, 32'd4298, 32'd5953, 32'd1213, 32'd7154, 32'd1} :
                (i == 1) ? '{32'd5756, 32'd4298, 32'd1213, 32'd1} :
                (i == 2) ? '{32'd4298, 32'd1} :
                '{32'd1}; // Default case

            // Instantiate top_module1
            top_module1 #(
                .W(W),
                .MODULUS(7681),
                .counter_Max(32),
                .counter_threshold(counter_threshold),
                .FIFO_DEPTH(FIFO_DEPTH),
                .step(step),
                .RADIX(RADIX),
                .TWIDDLE_ARRAY(TWIDDLE_ARRAY)
            ) top_inst (
                .clk(clk),
                .rst(rst),
                .incoming_data(results[i]),
                .final_result(results[i+1])
            );
        end
    endgenerate

    // Instantiate the final module (top_module3)
    top_module3 #(
        .W(W),
        .MODULUS(7681),
        .RADIX(16),
        .counter_Max(32)
    ) top_final (
        .clk(clk),
        .rst(rst),
        .incoming_data(results[NUM_INSTANCES]),
        .final_result(final_result)
    );

endmodule