// ============================================================================
// Module: candidate_selector.v
// Description: Decodes 4 physical push buttons into candidate selection.
//              BTN1 (bit 0) -> Candidate A (2'b00)
//              BTN2 (bit 1) -> Candidate B (2'b01)
//              BTN3 (bit 2) -> Candidate C (2'b10)
//              BTN4 (bit 3) -> Candidate D (2'b11)
// ============================================================================

`timescale 1ns / 1ps

module candidate_selector (
    input  wire       clk,                // System clock
    input  wire       reset,              // Active-high reset
    input  wire       enable,             // Enabled only during CANDIDATE SELECTION state
    input  wire [3:0] candidate_btn,      // Debounced push-button pulses for candidates
    output reg  [1:0] candidate_code,     // 2-bit code: 00=A, 01=B, 10=C, 11=D
    output reg        candidate_selected  // Asserted when a candidate button is pressed
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            candidate_code     <= 2'b00;
            candidate_selected <= 1'b0;
        end else if (enable) begin
            if (candidate_btn[0]) begin
                candidate_code     <= 2'b00; // Candidate A
                candidate_selected <= 1'b1;
            end else if (candidate_btn[1]) begin
                candidate_code     <= 2'b01; // Candidate B
                candidate_selected <= 1'b1;
            end else if (candidate_btn[2]) begin
                candidate_code     <= 2'b10; // Candidate C
                candidate_selected <= 1'b1;
            end else if (candidate_btn[3]) begin
                candidate_code     <= 2'b11; // Candidate D
                candidate_selected <= 1'b1;
            end else begin
                candidate_selected <= 1'b0;
            end
        end else begin
            candidate_selected <= 1'b0;
        end
    end

endmodule
