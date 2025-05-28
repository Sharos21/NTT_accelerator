/*
module uart_ntt #(
  parameter W = 32,
  parameter radix =16
) (
  input  logic                                     clk,
  input  logic                                     rst,
  input  logic                                     start,
  input  logic [W-1:0]                             incoming_data,
  input  logic [NUM_stages:0]                      write_en_array,
  input  logic [NUM_stages:0][W-1:0]               write_data_array,
  input  logic [NUM_stages:0][$clog2(radix/2)-1:0] write_addr_array,
  output logic [W-1:0]                             final_result,
  output logic                                     done,

  output logic                                     tx_o,
  input  logic                                     rx_i
);


top_top_module #(
 // Parameters
 .W(32),
 .radix(4)
)
top_top_module_0 (
  .clk              (clk             ),
  .rst              (rst             ),
  .start            (start           ),
  .incoming_data    (incoming_data   ),
  .write_en_array   (write_en_array  ),
  .write_data_array (write_data_array),
  .write_addr_array (write_addr_array),
  .final_result     (data_o          ),
  .done             (done_o          )  // this done signal probably need to be different because is the signal of the NTT that was done
);


////// PC UART --> FPGA UART
logic      Rx_DV_s;
logic[7:0] Rx_Byte_s;

logic[31:0] uart_data_s;
logic[31:0] uart_addr_s;
logic       uart_ready_s;
logic       uart_done_s;

uart_rx #(
  .CLKS_PER_BIT(87)
)
uart_rx_0 (
  .i_Clock     (clk      ),
  .i_Rx_Serial (rx_i     ), // inside is also the starting bit but is also the data
  .o_Rx_DV     (Rx_DV_s  ), // stop bit 
  .o_Rx_Byte   (Rx_Byte_s) // as an output is a byte (8bits)
);

uart_reader uart_reader_0(
  .clk_i    (clk   ),
  .rst_n_i  (!rst  ),

  .done_o   (uart_done_s), // when all words have been received

  .data_o   (uart_data_s ), // data output of 32 bits
  .addr_o   (uart_addr_s ),
  .ready_o  (uart_ready_s),

  // READ from UART
  .uart_valid_i (Rx_DV_s  ), // signal to start assembling the data 
  .uart_byte_i  (Rx_Byte_s) // takes inputs a byte (8 bits)
);
*/

/* Additional logic to handle the incoming data
  from uart_reader and send it to the NTT module
  -----------------------------------------------------
  uart_done_s  : All data has been received
  uart_data_s  : Single word (32-bits) received from UART
  uart_addr_s  : Address to write the data to (increased by 1 each time)
  uart_ready_s : Indicates valid data is ready to be processed
*/
/*
endmodule
*/