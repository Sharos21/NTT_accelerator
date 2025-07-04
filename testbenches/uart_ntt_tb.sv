
module uart_ntt_tb;

  // Clock parameters
  parameter CLK_PERIOD = 100;  // 10 MHz => 100 ns clock period
  parameter CLKS_PER_BIT = 87; // 115200 baud for UART
  parameter W = 32;
  parameter radix = 16;
  parameter NUM_stages = 4;
  parameter ADDR_WIDTH = $clog2(radix/2);

  // Inputs to uart_ntt
  logic clk;
  logic rst;
  logic rx_i;
  logic [W-1:0] final_result;

  //Outputs of uart_ntt
  logic tx_o;

  // DUT instantiation
  mine_uart_ntt #( // na allaxo to onoma tou module 
    .CLKS_PER_BIT(CLKS_PER_BIT),
    .W(W),
    .radix(radix)
  ) dut (
    .clk(clk),
    .rst(rst),
    .rx_i(rx_i),
    //.final_result(final_result)
    .tx_o(tx_o)
  );

  // UART TX module to drive the rx line
  logic       tx_active;
  logic       tx_serial;
  logic       tx_done;
  logic [7:0] tx_data;
  logic       tx_dv;

  uart_tx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_tx_inst (
    .i_Clock(clk),
    .i_Tx_DV(tx_dv),
    .i_Tx_Byte(tx_data),
    .o_Tx_Active(tx_active),
    .o_Tx_Serial(tx_serial),
    .o_Tx_Done(tx_done)
  );

  logic rx_dv_tb;
  logic [7:0] rx_byte_tb;

 
  uart_rx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_rx_tb(
    .i_Clock(clk),
    .i_Rx_Serial(tx_o),
    .o_Rx_DV(rx_dv_tb),
    .o_Rx_Byte(rx_byte_tb)
  );

  // Connect tx_serial to DUT's rx input
  assign rx_i = tx_serial;

  // Clock generation
  //always #(CLK_PERIOD / 2) clk = ~clk;

  initial begin 
    clk =0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // Task to transmit a 32-bit word over UART
  task uart_send_word(input [31:0] word);
      for (int i = 0; i < W/8; i++) begin
        @(posedge clk);
        tx_data <= word[8*i +: 8];
        @(posedge clk);
        tx_dv   <= 1'b1;
        @(posedge clk);
        tx_dv   <= 1'b0;
        wait (tx_done);
      end
  endtask


  //// Initialization values
  //logic [31:0] twiddle_factors [0:radix/2-1] = '{
  //  32'h000014E1, 32'h0000092F, 32'h000010AA, 32'h0000061E,
  //  32'h00000425, 32'h00000E0E, 32'h00001B30, 32'h000015C1
  //};

  logic [radix/2-1:0] [W-1:0] twiddle_factors  = '{
      //radix 16
      32'h14E1, 32'h092F, 32'h10AA, 32'h061E,
      32'h0425, 32'h0E0E, 32'h1B30, 32'h15C1
      //radix 4
      //32'h061E, 32'h15C1
      
  };

  logic [31:0] input_data [0:radix-1] = '{
    32'h000015C1,32'h00000D81, 32'h00000541, 32'h00001B02,
    32'h000012C2,32'h00000A82, 32'h00000242, 32'h000001803,
    32'h00000FC3,32'h00000783, 32'h00001D44, 32'h00001504,
    32'h00000CC4,32'h00000484, 32'h00001A45, 32'h00000000
  };

  logic [31:0] received_word;
  logic [31:0] received_data [0:radix-1];
  int byte_count = 0;
  int word_count = 0;

  // Word reassembly process
always_ff @(posedge clk) begin
    if(rst) begin
      received_word <= 0;
      byte_count <= 0;
      word_count <= 0;
    end 
    else if(rx_dv_tb) begin
      // Store bytes in little-endian order
      case(byte_count)
        0: received_word[7:0]   <= rx_byte_tb;
        1: received_word[15:8]  <= rx_byte_tb;
        2: received_word[23:16] <= rx_byte_tb;
        3: received_word[31:24] <= rx_byte_tb;
      endcase
      
      if (byte_count == 3) begin
        received_data[word_count] <= received_word;
        $display("[TB] Received word %0d: 0x%h", word_count, received_word);
        byte_count <= 0;
        word_count <= word_count + 1;
      end 
      else begin
        byte_count <= byte_count + 1;
      end
    end
  end


  initial begin
   
    clk = 0;
    rst = 1;
    tx_data = 0;
    tx_dv = 0;

    // Reset pulse
    #(10 * CLK_PERIOD);
    rst = 0;
    
    uart_send_word(32'd0); // sending address
    uart_send_word(32'd24); // sending twiddle factor_size

    // Load RAM with twiddle factors
    $display("Loading twiddle factors into RAM...");
    for (int i = 0; i < radix/2; i++) begin
      uart_send_word(twiddle_factors[i]);
    end


    // Load input data
    $display("Sending input data to NTT...");
    for (int i = 0; i < radix; i++) begin
      uart_send_word(input_data[i]);
    end

    // Wait for NTT to finish processing
    #(200000 * CLK_PERIOD);

    $display("Simulation 1 complete. Final result: %h", final_result);


    rst = 1;
    tx_data = 0;
    tx_dv = 0;
    #(500*CLK_PERIOD);

    rst = 0;
    uart_send_word(32'd0); // sending address
    uart_send_word(32'd24); // sending twiddle factor_size

    $display("Loading twiddle factors into RAM...");
    for (int i = 0; i < radix/2; i++) begin
      uart_send_word(twiddle_factors[i]);
    end


    // Load input data
    $display("Sending input data to NTT...");
    for (int i = 0; i < radix; i++) begin
      uart_send_word(input_data[i]);
    end

    // Wait for NTT to finish processing
    #(200000 * CLK_PERIOD);

    $display("Simulation 2  complete. Final result: %h", final_result);
    
    $stop;
  end


endmodule
