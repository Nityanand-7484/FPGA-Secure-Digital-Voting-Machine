// ============================================================================
// Module: result_controller.v
// Description: Allows the administrator to cycle through and display vote counts
//              for all 4 candidates (Candidate A -> B -> C -> D -> A).
//              Active only when result_enable is asserted by the FSM.
// ============================================================================

`timescale 1ns / 1ps

module result_controller (
    input  wire        clk,                // System clock
    input  wire        reset,              // Active-high reset
    input  wire        result_enable,      // Asserted during RESULT state
    input  wire        cycle_btn,          // Button press to advance to next candidate
    input  wire [15:0] vote_A,             // Votes for Candidate A
    input  wire [15:0] vote_B,             // Votes for Candidate B
    input  wire [15:0] vote_C,             // Votes for Candidate C
    input  wire [15:0] vote_D,             // Votes for Candidate D
    output reg  [1:0]  current_candidate,  // 00=A, 01=B, 10=C, 11=D
    output reg  [15:0] current_count       // Current candidate's vote count
);

    // Cycle candidate index on button press when result_enable is high
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_candidate <= 2'b00;
        end else if (result_enable) begin
            if (cycle_btn) begin
                current_candidate <= current_candidate + 2'b01;
            end
        end else begin
            current_candidate <= 2'b00;
        end
    end

    // Multiplex candidate tally to display output
    always @(*) begin
        case (current_candidate)
            2'b00: current_count = vote_A;
            2'b01: current_count = vote_B;
            2'b10: current_count = vote_C;
            2'b11: current_count = vote_D;
            default: current_count = 16'd0;
        endcase
    end

endmodule
