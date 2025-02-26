module butterfly#(
    parameter MODULUS = 7681
)(
    input logic enable, // New enable signal
    input logic [31:0] buffer_data_in,
    input logic [31:0] normal_data_in,
    output logic [31:0] positive_data_out,
    output logic [31:0] negative_data_out
);
    logic [31:0] modulus = MODULUS;
    logic [31:0] sum;
    logic signed [32:0] diff_signed; // With extra bit for overflow

    always_comb begin
        if (enable) begin
            // For positive values
            sum = buffer_data_in + normal_data_in;
            positive_data_out = (sum >= modulus) ? (sum - modulus) : sum;

            // For negative values
            diff_signed = $signed(buffer_data_in) - $signed(normal_data_in);
            negative_data_out = (diff_signed < 0) ? (diff_signed + $signed(modulus)) : diff_signed;
        end else begin
            positive_data_out = 0;
            negative_data_out = 0;
        end
    end
endmodule
