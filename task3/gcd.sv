// -----------------------------------------------------------------------------
//
//  Title      :  System Verilog FSMD implementation template for GCD
//             :
//  Developers :  Otto Westy Rasmussen
//             :
//  Purpose    :  This is a template for the FSMD (finite state machine with datapath) 
//             :  implementation of the GCD circuit
//             :
//  Revision   :  02203 fall 2025 v.1.0
//
// -----------------------------------------------------------------------------


module gcd (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);
    typedef enum logic [2 : 0] { 
        waitA, //initial
        inA,
        waitB,
        inB,
        comp,
        fin
     } state_t;

    shortint unsigned reg_a, next_reg_a, reg_b, next_reg_b;

    logic [16 : 0] sub;
    state_t state, next_state;
    
    // Combinatorial logic
    always_comb begin
        next_reg_a = reg_a;
        next_reg_b = reg_b;
        ack = 0;
        C = 'z; // Hi-Z if not computed
        sub = 0;
        case (state)
            waitA: begin
                if (req) begin
                    next_state = inA;
                end else begin
                    next_state = waitA;
                end
            end
            inA: begin
                next_reg_a = AB;
                ack = 1;
                if (req) begin
                    next_state = inA;
                end else begin
                    next_state = waitB;
                end
            end
            waitB: begin
                if (req) begin
                    next_state = inB;
                end else begin
                    next_state = waitB;
                end
            end
            inB: begin
                next_reg_b = AB;
                next_state = comp;
            end
            comp: begin
                sub = reg_a - reg_b;
                if (sub == 0) begin 
                    next_state = fin;
                end else if (sub[16]) begin
                    next_state  = comp;
                    next_reg_b  = ~sub[15:0] + 1;
                end else begin
                    next_state = comp;
                    next_reg_a = sub[15:0];
                end
            end
            fin: begin
                ack = 1;
                C = reg_a;
                if (req) begin
                    next_state = fin;
                end else begin 
                    next_state = waitA;
                end
            end
            default: begin
                next_state = waitA;
            end
        endcase
    end

    // Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= waitA;
            reg_a <= 0;
            reg_b <= 0;
        end else begin
            state <= next_state;
            reg_a <= next_reg_a;
            reg_b <= next_reg_b;
        end
    end

    // lets start ini di bininging
    initial begin
       state <= waitA; 
       reg_a <= 0;
       reg_b <= 0;
    end

endmodule