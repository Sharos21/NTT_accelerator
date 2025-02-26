module flip_flop_miltiplier(
    input logic clk,
    input logic rst,
    input logic [31:0] twiddle_factor,
    input logic [31:0] mul_data_in,
    output logic [31:0] result
);

logic [63:0] tmp;
logic [31:0] modulus = 31'd7681;

always_comb begin
tmp =  twiddle_factor * mul_data_in;
//result = tmp % modulus;
end

always_ff @(posedge clk) begin
    result<= tmp % modulus;
end


endmodule