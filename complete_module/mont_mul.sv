module mont_mul #(parameter W = 32, M_BITS = 8, N = W/M_BITS)(
    input logic clk,
    input logic rst,
   //input logic valid_in,
    input logic [W-1:0] A, // number in Montgomery form
    input logic [W-1:0] B, // twiddle_factor in Montgomery form
    input logic [W-1:0] M, // MODULUS
    input logic [M_BITS-1:0] M_inv, // M' = -M^(-1) mod R
    //input logic enable,
    output logic [W-1:0] S
    //output logic valid_out
);


//Each stage have these properties
typedef struct packed {
    logic [W-1:0] s_prev;
    logic [W-1:0] a;
    logic [W-1:0] b;
} stage_reg_t;

stage_reg_t [0 : N-1] stage_reg; 


//The first stage
always_ff @(posedge clk) begin
    if (rst) begin
        stage_reg[0] <= '0;
    end else begin
        //if (valid_in) begin
            logic [M_BITS-1 : 0] Ai;
            logic [W-1 : 0] S_next;
            logic [M_BITS-1:0] qi;
            logic [W-1:0] S_new;

            Ai = A[M_BITS-1 :0];
            S_next = 0 + Ai * B;
            qi = (S_next[M_BITS-1:0] * M_inv) % ((1<< M_BITS));
            stage_reg[0].s_prev <= (S_next + qi *M) >> M_BITS;
            stage_reg[0].a <= A;
            stage_reg[0].b <= B;
       //     stage_reg[0].valid <= 1'b1;
       // end else begin
       //     stage_reg[0].valid <= 1'b0;
       // end
    end
end

//generation of the rest stages
generate
genvar k;
for (k=1; k < N; k++) begin

    stage_reg_t current_stage;
    logic [M_BITS-1 : 0] Ai;
    logic [W-1 : 0] S_next;
    logic [M_BITS-1:0] qi;
    logic [W-1:0] S_new;

 // S for each new stage
    always_comb begin
        current_stage = stage_reg[k-1];
        Ai = current_stage.a[k*M_BITS +: M_BITS];
        S_next =current_stage.s_prev + Ai *current_stage.b;
        qi = (S_next[M_BITS-1:0] * M_inv) % ((1<< M_BITS));
        S_new = (S_next +qi * M) >> M_BITS;
    end

    //Pass the values to the next stage 
    always_ff @(posedge clk) begin
        if(rst) begin
            stage_reg[k] <= '0;
        end else begin
            //stage_reg[k].valid <= current_stage.valid;
            //if(current_stage.valid) begin
                stage_reg[k].s_prev <= S_new;
                stage_reg[k].a <= current_stage.a;
                stage_reg[k].b <= current_stage.b;
            //end
        end
    end
end
endgenerate

//validation and correction of S 
//assign valid_out = stage_reg[N-1].valid;
assign S = (stage_reg[N-1].s_prev < M) ? stage_reg[N-1].s_prev : 
                                    (stage_reg[N-1].s_prev - M);
//logic [W-1:0] S_temp;
//assign S_temp = stage_reg[N-1].s_prev;
//
//// Incremental multiplication by 2^M_BITS mod M
//logic [W-1:0] S_final;
//always_comb begin
//    S_final = S_temp;
//    for (int i = 0; i < N; i++) begin
//        S_final = (S_final * (1 << M_BITS)) % M;
//    end
//end
//
//// Correction
//assign S = (S_final < M) ? S_final : (S_final - M);



endmodule 
