module twiddle_rom #(
    parameter W = 32,
    parameter DEPTH = 8,
    parameter FILE ="./complete_module/twiddle_factor_radix-16.txt"
)(
    input logic [$clog2(DEPTH)-1 : 0] addr,
    output logic[W-1:0] data
);

logic [W-1:0] rom [0:DEPTH-1];

initial begin
    $readmemh( FILE, rom);
end

always_comb begin
    data = rom[addr];
end

endmodule

