module mont_mul_tb;
    parameter W  = 32;
    parameter M_BITS = 8;

logic clk, rst, valid_in;
logic [W-1:0] A, B , M;
logic [M_BITS-1:0] M_inv;
logic [W-1 : 0] S;
logic valid_out;

mont_mul #(.W(W), .M_BITS(M_BITS)) duut (
    .clk(clk),
    .rst(rst),
    //.valid_in(valid_in),
    .A(A),
    .B(B),
    .M(M),
    .M_inv(M_inv),
    .S(S)
    //.valid_out(valid_out)
);


initial begin
    clk = 0; 
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    A = 32'd6914; //    in montgomery domain with R<<32
    B = 32'd5569; // ω^0  * 1<<32 
    M = 32'd7681;
    M_inv = 8'd255;
    #10 rst = 0; //valid_in =1;
    #10 A = 32'd100; B = 32'd1; M = 32'd7681; M_inv = 8'd255;
    #10 A = 32'd50;  B = 32'd5; M = 32'd7681; M_inv = 8'd255;

    #300;
    $stop;
end

endmodule
    