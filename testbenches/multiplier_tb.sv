module multiplier_tb;

    // Testbench signals
    logic [31:0] modulus;
    logic [31:0] twiddle_factor;
    logic [31:0] data_in;
    logic [31:0] result;

    // Instantiate the multiplier
    multiplier uut (
        .twiddle_factor(twiddle_factor),
        .data_in(data_in),
        .modulus(modulus),
        .result(result)
    );

    // Testbench stimulus
    initial begin
        data_in= 32'd6;
        twiddle_factor = 32'd1;
        modulus = 32'd7681;
        #10ns

        data_in = 32'd7679;
        twiddle_factor =32'd4298;
        #10ns
        $stop;
    end

endmodule
