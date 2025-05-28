module uart_reader (
  input  logic       clk_i,
  input  logic       rst_n_i,

  output logic       done_o,

  output logic[31:0] data_o,
  output logic[31:0] addr_o,
  output logic       ready_o,

  input  logic[7:0]  uart_byte_i,
  input  logic       uart_valid_i
);

enum logic [1:0] {INIT , BYTE_RCVD, DATA_RDY, DONE=4'b11} st_s;

logic[31:0]     status_ninstr_s;
logic[31:0]     status_start_addr_s;

logic[1:0]      status_flag_s;

logic[31:0]     word_cnt_s;
logic[2:0]      idx_s;
logic[3:0][7:0] word2send_s;

// Axi master state FSM
always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin    
    data_o        <= 'd0;
    addr_o        <= 'd0;

    idx_s         <= 'd0;

    word_cnt_s    <= 'd0;
    word2send_s   <= 'd0;
    done_o        <= 1'b0;

    status_ninstr_s     <= 'd0;
    status_start_addr_s <= 'd0;
    status_flag_s       <= 'd0;

    st_s          <= INIT;
  end else begin
    case (st_s)
      INIT: begin
        if (uart_valid_i) begin
          word2send_s[idx_s] <= uart_byte_i;
          idx_s              <= idx_s + 'd1;
          st_s               <= BYTE_RCVD;
        end
      end

      BYTE_RCVD: begin
        if (idx_s < 4) begin
          st_s <= INIT;
        end else begin
          idx_s       <= 'd0;
          word2send_s <= 'd0;

          case (status_flag_s)
            2'b00: begin
              addr_o        <= word2send_s;
              status_flag_s <= 2'b10;

              st_s <= INIT; 
            end

            2'b10: begin
              status_ninstr_s <= word2send_s;
              status_flag_s   <= 2'b11;

              st_s <= INIT; 
            end

            2'b11: begin
              data_o     <= word2send_s;
              addr_o     <= addr_o + 'd1;
              word_cnt_s <= word_cnt_s + 'd1;

              st_s <= DATA_RDY;
            end
          endcase
        end
      end

      DATA_RDY: begin
        st_s <= (word_cnt_s < status_ninstr_s) ? INIT : DONE;
      end

      DONE: begin
        done_o <= !done_o ? 1'b1 : done_o;
      end

      default: begin
        st_s <= INIT;
      end
    endcase
  end
end

assign ready_o = (st_s == DATA_RDY) ? 1'b1 : 1'b0;

endmodule