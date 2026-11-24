// ============================================================================
// Module: button_debounce.v
// Description: Filters mechanical switch bouncing and produces a clean,
//              single-clock-cycle pulse for every valid press.
//              - Parameter DEBOUNCE_LIMIT: threshold for counter
//              - Uses a 2-stage synchronizer against metastability
//              - Uses edge detection to produce exactly 1-cycle output pulse
// ============================================================================

`timescale 1ns / 1ps

module button_debounce #(
    parameter DEBOUNCE_LIMIT = 20'd1_000_000 // ~10ms for 100MHz clock (smaller for sim)
)(
    input  wire clk,        // System clock
    input  wire reset,      // Active-high reset
    input  wire btn_in,     // Raw noisy button input
    output reg  btn_pulse   // Exactly one clock-cycle pulse on confirmed press
);

    // 2-stage synchronizer flip-flops to prevent metastability
    reg sync_0;
    reg sync_1;

    // Debounce counter and state
    reg [19:0] counter;
    reg        debounced_state;
    reg        prev_debounced_state;

    // Synchronization to clk domain
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
        end
    end

    // Debounce counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter              <= 20'd0;
            debounced_state      <= 1'b0;
            prev_debounced_state <= 1'b0;
            btn_pulse            <= 1'b0;
        end else begin
            // Check if input matches current debounced state
            if (sync_1 != debounced_state) begin
                counter <= counter + 20'd1;
                if (counter >= DEBOUNCE_LIMIT) begin
                    debounced_state <= sync_1;
                    counter         <= 20'd0;
                end
            end else begin
                counter <= 20'd0;
            end

            // Rising-edge detection generates a single-cycle pulse
            prev_debounced_state <= debounced_state;
            btn_pulse <= (debounced_state == 1'b1 && prev_debounced_state == 1'b0);
        end
    end

endmodule
