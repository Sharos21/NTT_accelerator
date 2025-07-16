module mine_uart_ntt #(
    parameter W = 32,
    parameter radix =16,
    parameter CLKS_PER_BIT = 87,
    parameter ADDR_WIDTH = $clog2(radix/2),
    parameter NUM_stages = $clog2(radix) // 4
)(
    input logic clk,
    input logic rst,
    input logic rx_i, // seiriaka dedomena
    output logic tx_o
    //output logic [7:0] debug_leds,
    //output logic rst_led
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



// NTT's signals
logic start;
logic done;
logic valid;

logic [W-1:0] incoming_data;
logic [W-1:0] final_result;

logic [NUM_stages-1:0] full_ram;
logic [NUM_stages-1:0] write_enable_array; 
logic [NUM_stages-1:0][W-1:0] write_data_array;
logic [NUM_stages-1:0][ADDR_WIDTH-1:0] write_addr_array;


logic [31:0] cycle_counter;
logic [31:0] final_counter;


always_ff @(posedge clk) begin
    if(rst) begin
        cycle_counter <=0;
        final_counter <= 0;
     end else if (start && !done) begin
        cycle_counter <=cycle_counter +1;
       end else if (done) begin
        final_counter <= cycle_counter;
       end
end


top_top_module #(.W(W), .radix(radix)) uut  ( 
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .valid(valid),
        .incoming_data(incoming_data),
        .write_en_array(write_enable_array),
        .write_data_array(write_data_array),
        .write_addr_array(write_addr_array),
       //.twiddle_factor(twiddle_factor),
        .final_result(final_result),
        .full_ram(full_ram)
    );




///////
//UART_BUFFER to store the twiddle_factor
/////////
logic [radix/2 -1:0] [W-1:0]  uart_twiddle_buffer;
logic [$clog2(radix/2):0] uart_twiddle_buffer_index;
logic uart_buffer_full;

always_ff @(posedge clk) begin
  if(rst) begin
    uart_twiddle_buffer_index <=0;
    uart_buffer_full <=0;
  end else if (uart_ready_s && !uart_buffer_full) begin
    uart_twiddle_buffer[uart_twiddle_buffer_index] <= uart_data_s;
    uart_twiddle_buffer_index <= uart_twiddle_buffer_index +1 ;
    if( uart_twiddle_buffer_index  == radix/2-1) 
      uart_buffer_full <=1;
  end
end


/////
//Logic to preload the rams
//////
logic [$clog2(radix/2):0] index;
logic [$clog2(radix/2):0] increase;
logic [$clog2(NUM_stages) -1:0] stage;
logic [$clog2(radix/2):0] j_counter;

always_ff @(posedge clk) begin
  if(rst) begin
    index <= radix / 2;
    increase <= 1;
    stage <= 0;
    write_enable_array <= '0;
    write_data_array <= '0;
    write_addr_array <= '0;
    j_counter <= 0;
  end else if (uart_buffer_full && !full_ram[stage]) begin
    write_enable_array <= '0; // reset enables each cycle
    if(j_counter < index) begin
      write_enable_array[stage] <= 1;
      write_addr_array[stage] <= j_counter;
      write_data_array[stage] <= uart_twiddle_buffer[j_counter * increase];
      j_counter <= j_counter + 1;
    end else begin
      j_counter <= 0;
      stage <= stage + 1;
      index <= index >> 1;
      increase <= increase << 1;
    end
  end
end


///////
//UART_BUFFER to store the incoming data and the final results
/////////
logic [radix-1:0] [W-1:0] uart_data_buffer;
logic [$clog2(radix)-1:0] uart_data_buffer_index;
logic uart_data_buffer_full;
//final Results
logic [$clog2(radix)-1:0] final_index;
logic [radix-1:0] [W-1:0] output_buffer;

always_ff @(posedge clk) begin
  if(rst) begin
    uart_data_buffer_index <=0;
    uart_data_buffer_full <= 0;
    final_index <= 0;
  end else if(uart_buffer_full && uart_ready_s && !uart_data_buffer_full) begin
    uart_data_buffer[uart_data_buffer_index] <= uart_data_s;
    uart_data_buffer_index <= uart_data_buffer_index + 1;
      if(uart_data_buffer_index == radix -1)
        uart_data_buffer_full <=1;
  end else if (valid) begin
    output_buffer[final_index] <= final_result;
    final_index <= final_index + 1;
  end
end


////
// DATA SENDING TO THE NTT after loading the twiddle factors
////
logic [$clog2(radix)-1:0] data_index;

always_ff @(posedge clk) begin
  if(rst ) begin
    data_index <=0;
    start <=0;
  end else if (uart_data_buffer_full && !done) begin
    start <=1;
    incoming_data <= uart_data_buffer[data_index];
    data_index <= data_index +1;
  end 
end


//FPGA -> PC
logic [7:0] tx_data;
logic tx_start;
logic tx_done;
logic tx_active;

typedef enum logic [1:0] {IDLE, PREPARE, WAIT_TX_DONE, NEXT} tx_state_t;

tx_state_t tx_state;
logic [$clog2(radix):0] tx_word_index;
logic [1:0] tx_byte_index;

always_ff @(posedge clk) begin
  if(rst) begin
    tx_state <= IDLE;
    tx_word_index <=0;
    tx_byte_index <=0;
    tx_start <=0;
    tx_data <=0;
  end else begin
    tx_start <=0;

    case (tx_state)
    IDLE: begin
      if(done && tx_word_index != radix ) begin
        tx_word_index <=0;
        tx_byte_index <=0;
        tx_state <= PREPARE;
      end
    end

    PREPARE: begin
      case(tx_byte_index)
          2'd0: tx_data <= (tx_word_index < radix) ? output_buffer[tx_word_index][7:0]      : final_counter[7:0];
          2'd1: tx_data <= (tx_word_index < radix) ? output_buffer[tx_word_index][15:8]     : final_counter[15:8];
          2'd2: tx_data <= (tx_word_index < radix) ? output_buffer[tx_word_index][23:16]    : final_counter[23:16];
          2'd3: tx_data <= (tx_word_index < radix) ? output_buffer[tx_word_index][31:24]    : final_counter[31:24];
      endcase
      tx_start <= 1;
      tx_state <= WAIT_TX_DONE;
    end

    WAIT_TX_DONE: begin
      if(tx_done) begin
         tx_state <= NEXT; 
      end
    end

    NEXT: begin
      if(tx_byte_index < 3) begin
        tx_byte_index <= tx_byte_index + 1;
        tx_state <= PREPARE;
      end else begin
        tx_byte_index<=0;
        if(tx_word_index < radix) begin
          tx_word_index <= tx_word_index + 1;
          tx_state <= PREPARE;
        end else begin
          tx_state <= IDLE;
        end
      end
    end

    default: tx_state <= IDLE;
    endcase

  end
end


uart_tx #(.CLKS_PER_BIT(87)
)
uart_tx_0(
  .i_Clock(clk    ),
  .i_Tx_DV(tx_start),
  .i_Tx_Byte(tx_data), // receives a byte so be careful
  .o_Tx_Active(tx_active),
  .o_Tx_Serial(tx_o),
  .o_Tx_Done(tx_done)
);


//assign debug_leds[0] = uart_done_s;
//assign debug_leds[1] = uart_data_buffer_full;
//assign debug_leds[2] = start;
//assign debug_leds[3] = done;
//assign debug_leds[4] = tx_active;
//assign debug_leds[5] = (tx_state == IDLE);
//assign debug_leds[6] = (tx_state == PREPARE);
//assign debug_leds[7] = valid;
//
//assign rst_led = rst;
endmodule