module FIFO #(
  parameter  DW = 32,
  parameter  DEPTH     = 2,
  localparam PtrWidth  = $clog2(DEPTH)
) (
  input  logic                 clk,
  input  logic                 rst,
  input  logic                 push,
  input  logic [DW-1:0] write_data,
  input  logic                 pop,
  output logic [DW-1:0] read_data,
  output logic                 full,
  output logic                 empty
);

  logic [DW-1:0] mem[DEPTH];
  logic [PtrWidth:0] wrPtr, wrPtrNext;
  logic [PtrWidth:0] rdPtr, rdPtrNext;

  always_comb begin
    wrPtrNext = wrPtr;
    rdPtrNext = rdPtr;
    if (push) begin
      wrPtrNext = wrPtr + 1;
    end
    if (pop) begin
      rdPtrNext = rdPtr + 1;
    end
  end

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      wrPtr <= '0;
      rdPtr <= '0;
    end else begin
      wrPtr <= wrPtrNext;
      rdPtr <= rdPtrNext;
    end

    mem[wrPtr[PtrWidth-1:0]] <= write_data;
  end

  assign read_data = mem[rdPtr[PtrWidth-1:0]];

  assign empty = (wrPtr[PtrWidth] == rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);
  assign full  = (wrPtr[PtrWidth] != rdPtr[PtrWidth]) && (wrPtr[PtrWidth-1:0] == rdPtr[PtrWidth-1:0]);

endmodule