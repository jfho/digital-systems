module FSM (
    input  logic         clk,      // The clock signal.
    input  logic         reset,    // Reset the module.
    input  logic         req,
    input  logic         N,
    input  logic         Z,
    output logic         ack,
    output logic         ABorALU,
    output logic         LDA,
    output logic         LDB,
    output logic [1 : 0] FN
);
  typedef enum logic [2 : 0] {
    waitA,  //initial
    inA,
    waitB,
    inB,
    decision,
    greaterA,
    greaterB,
    fin
  } state_t;  // Input your own state names here

  state_t state, next_state;

  always_comb begin
    ack = 0;
    ABorALU = 1;
    LDA = 0;
    LDB = 0;
    FN = 2'b00;
    case (state)
      waitA: begin
        if (req) begin
          next_state = inA;
        end else begin
          next_state = waitA;
        end
      end
      inA: begin
        LDA = 1;
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
        LDB = 1;
        next_state = decision;
      end
      decision: begin
        ABorALU = 0;
        if (Z) begin
          next_state = fin;
        end else if (N) begin
          next_state = greaterB;
        end else begin
          next_state = greaterA;
        end
      end
      greaterA: begin
        ABorALU = 0;
        LDA = 1;
        next_state = decision;
      end
      greaterB: begin
        ABorALU = 0;
        FN = 2'b01;
        LDB = 1;
        next_state = decision;
      end
      fin: begin
        ABorALU = 0;
        FN = 2'b10;
        ack = 1;
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

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= waitA;
    end else begin
      state <= next_state;
    end
  end
endmodule

module DataPath (
    input  logic          clk,      // The clock signal.
    input  logic [15 : 0] AB,
    input  logic          ABorALU,
    input  logic          LDA,
    input  logic          LDB,
    input  logic [ 1 : 0] FN,
    output logic [15 : 0] C,
    output logic          N,
    output logic          Z
);
  logic [15 : 0] C_int, reg_a_out, reg_b_out, Y;
  c_mux buffer (
      .data_in1 (C_int),
      .data_in2 ('z),
      .s (FN[1]),
      .data_out(C)
  );
  c_mux MUX (
      .data_in1(AB),
      .data_in2(Y),
      .s(ABorALU),
      .data_out(C_int)
  );
  c_reg RegA (
      .clk(clk),
      .en(LDA),
      .data_in(C_int),
      .data_out(reg_a_out)
  );
  c_reg RegB (
      .clk(clk),
      .en(LDB),
      .data_in(C_int),
      .data_out(reg_b_out)
  );
  c_alu ALU (
      .A (reg_a_out),
      .B (reg_b_out),
      .fn(FN),
      .C (Y),
      .Z (Z),
      .N (N)
  );
endmodule

module gcd (
    input  logic          clk,    // The clock signal.
    input  logic          reset,  // Reset the module.
    input  logic          req,    // Start computation.
    input  logic [15 : 0] AB,     // The two operands. One at a time.
    output logic          ack,    // Input received / Computation is complete.
    output logic [15 : 0] C       // The result.
);
  logic N, Z, LDA, LDB, ABorALU;
  logic [1 : 0] FN;
  FSM u_FSM (
      .clk    (clk),
      .reset  (reset),
      .req    (req),
      .N      (N),
      .Z      (Z),
      .ack    (ack),
      .ABorALU(ABorALU),
      .LDA    (LDA),
      .LDB    (LDB),
      .FN     (FN)
  );
  DataPath u_DataPath (
      .clk    (clk),
      .AB     (AB),
      .ABorALU(ABorALU),
      .LDA    (LDA),
      .LDB    (LDB),
      .FN     (FN),
      .C      (C),
      .N      (N),
      .Z      (Z)
  );

endmodule
