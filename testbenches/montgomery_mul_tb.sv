module montgomery_mul_tb;
    parameter W = 32;
    parameter M_BITS = 8;
    
    logic clk, rst, start;
    logic [W-1:0] A, B, M;
    logic [W-1:0] M_inv;
    logic [W-1:0] S;
    logic done;
    int dokimi=-1;
    
    montgomery_mul #(.W(W), .M_BITS(M_BITS)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .M(M),
        .M_inv(M_inv),
        .S(S),
        .done(done)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        start = 0;
        A = 32'd6914; //first 2 elements in montgomery_Form
        B = 32'd1;
        M = 32'd7681;
        M_inv = 32'd255;
        #10 rst = 0;
        #10 start = 1;
        #10 start = 0;

        #300;
        $stop;
    end
    
    
endmodule