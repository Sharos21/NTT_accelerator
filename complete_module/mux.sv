module mux(
    input logic [31:0] in0,
    input logic [31:0] in1,
    input logic sel,
    output logic [31:0] mux_out
);

always_comb begin
    case(sel)
        1'b0: mux_out = in0;
        1'b1: mux_out = in1;
        default: mux_out = 0;
    endcase
end
endmodule