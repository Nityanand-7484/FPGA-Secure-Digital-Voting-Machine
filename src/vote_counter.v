// ============================================================================
// Module: vote_counter.v
// Description: Maintains independent 16-bit vote counters for 4 candidates.
//              Each counter can store up to 65,535 votes.
//              When cast_vote is asserted, increments the selected candidate.
// ============================================================================

`timescale 1ns / 1ps

module vote_counter (
    input  wire        clk,        // System clock
    input  wire        reset,      // Active-high master reset
    input  wire        cast_vote,  // Pulse from FSM indicating valid vote cast
    input  wire [1:0]  candidate,  // Candidate ID (00=A, 01=B, 10=C, 11=D)
    output reg  [15:0] vote_A,     // Tally for Candidate A
    output reg  [15:0] vote_B,     // Tally for Candidate B
    output reg  [15:0] vote_C,     // Tally for Candidate C
    output reg  [15:0] vote_D      // Tally for Candidate D
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vote_A <= 16'd0;
            vote_B <= 16'd0;
            vote_C <= 16'd0;
            vote_D <= 16'd0;
        end else if (cast_vote) begin
            case (candidate)
                2'b00: vote_A <= vote_A + 16'd1;
                2'b01: vote_B <= vote_B + 16'd1;
                2'b10: vote_C <= vote_C + 16'd1;
                2'b11: vote_D <= vote_D + 16'd1;
                default: ; // Do nothing for undefined states
            endcase
        end
    end

endmodule
