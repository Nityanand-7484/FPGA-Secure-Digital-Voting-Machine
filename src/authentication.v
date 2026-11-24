// ============================================================================
// Module: authentication.v
// Description: Prototype-level Voter Authentication Module
//              Compares 4-bit switch input against an on-chip password (4'b1011).
//              Asserts 'valid' high when password matches on 'enter' pulse.
// ============================================================================

`timescale 1ns / 1ps

module authentication #(
    parameter [3:0] PASSWORD = 4'b1011 // Default 4-bit passcode
)(
    input  wire       clk,        // System clock
    input  wire       reset,      // Active-high synchronous/asynchronous reset
    input  wire [3:0] auth_code,  // 4-bit code entered via switches
    input  wire       enter,      // Enter button trigger (debounced pulse)
    output reg        valid,      // High if entered code matches PASSWORD
    output reg        invalid     // High for 1 cycle if entered code is wrong
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid   <= 1'b0;
            invalid <= 1'b0;
        end else if (enter) begin
            if (auth_code == PASSWORD) begin
                valid   <= 1'b1;
                invalid <= 1'b0;
            end else begin
                valid   <= 1'b0;
                invalid <= 1'b1;
            end
        end else begin
            // Reset the single-cycle invalid strobe once processed
            invalid <= 1'b0;
        end
    end

endmodule
