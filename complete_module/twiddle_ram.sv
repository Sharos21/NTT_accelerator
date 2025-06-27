module twiddle_ram #(
    parameter W = 32,
    parameter DEPTH = 8
)(
    input logic clk,
    input logic write_en,
    input logic rst,
    input logic [($clog2(DEPTH) > 0) ? ($clog2(DEPTH)-1) : 0 :0] write_addr,
    input logic [W-1:0] write_data,
    ///read
    input logic [($clog2(DEPTH) > 0) ? ($clog2(DEPTH)-1) : 0 :0] read_addr,
    output logic [W-1:0] read_data,
    output logic full_ram
);

logic [DEPTH-1:0] [W-1:0] ram;
logic [DEPTH-1:0] writren_flag = '0;

if (DEPTH == 1) begin 
    logic [W-1:0] ram;
    logic written_flag = 1'b0;

    always_ff @(posedge clk) begin
        if(rst) begin
            written_flag <= 0;
        end else if (write_en) begin
            ram <= write_data;
            written_flag <= 1'b1;
        end
    end

    assign read_data = ram;
    assign full_ram = written_flag;

end else begin 
    logic [DEPTH-1:0] [W-1:0] ram;
    logic [DEPTH-1:0] written_flag = '0;

    always_ff @(posedge clk) begin
        if(rst) begin
            written_flag <= 0;
    end else if (write_en) begin
            ram[write_addr] <= write_data;
            written_flag[write_addr] <= 1'b1;
        end
    end

    assign read_data = ram[read_addr];
    assign full_ram = &writren_flag;
end

endmodule