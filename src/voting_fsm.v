// ============================================================================
// Module: voting_fsm.v
// Description: Central 7-State Finite State Machine (FSM) controlling the entire
//              voting sequence:
//              IDLE -> AUTH -> SELECT -> CONFIRM -> CAST -> LOCK -> IDLE
//              Special State: RESULT (admin-mode gated from IDLE)
// ============================================================================

`timescale 1ns / 1ps

module voting_fsm (
    input  wire       clk,                // System clock
    input  wire       reset,              // Master system reset
    input  wire       auth_enter,         // Voter pressed Enter at IDLE to begin
    input  wire       auth_valid,         // Passcode matched
    input  wire       auth_invalid,       // Passcode rejected
    input  wire       candidate_selected, // Candidate chosen (A-D)
    input  wire       confirm_btn,        // Voter pressed YES/Confirm
    input  wire       cancel_btn,         // Voter pressed NO/Cancel
    input  wire       new_session,        // Polling officer initiates next voter
    input  wire       admin_mode,         // Admin switch active
    
    // Control outputs
    output reg  [2:0] state,              // Current FSM state
    output reg  [3:0] status_led,         // Status indicator LEDs
    output reg  [2:0] disp_mode,          // 7-segment display mode
    output reg        cast_vote,          // 1-cycle strobe to increment counter
    output reg        cand_sel_enable,    // Enable candidate buttons
    output reg        result_enable       // Enable admin result cycling
);

    // State Encoding
    localparam IDLE    = 3'd0;
    localparam AUTH    = 3'd1;
    localparam SELECT  = 3'd2;
    localparam CONFIRM = 3'd3;
    localparam CAST    = 3'd4;
    localparam LOCK    = 3'd5;
    localparam RESULT  = 3'd6;

    reg [2:0] next_state;

    // 1. State Register (Synchronous reset)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 2. Next-State Combinational Logic
    always @(*) begin
        next_state = state; // Default: hold current state

        case (state)
            IDLE: begin
                if (admin_mode) begin
                    next_state = RESULT;
                end else if (auth_enter) begin
                    next_state = AUTH;
                end
            end

            AUTH: begin
                if (auth_valid) begin
                    next_state = SELECT;
                end else if (auth_invalid) begin
                    next_state = AUTH; // Stay in AUTH to allow retry or timeout
                end
            end

            SELECT: begin
                if (candidate_selected) begin
                    next_state = CONFIRM;
                end
            end

            CONFIRM: begin
                if (confirm_btn) begin
                    next_state = CAST;
                end else if (cancel_btn) begin
                    next_state = SELECT; // Cancel returns to candidate selection
                end
            end

            CAST: begin
                // Exactly 1 cycle spent in CAST to increment tally
                next_state = LOCK;
            end

            LOCK: begin
                // Session is strictly locked against further voting
                if (new_session) begin
                    next_state = IDLE;
                end
            end

            RESULT: begin
                // Only accessible by admin; returns to IDLE when admin_mode toggled off
                if (!admin_mode) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // 3. Output Logic (Registered or Combinational based on current state)
    always @(*) begin
        // Default values
        cast_vote       = 1'b0;
        cand_sel_enable = 1'b0;
        result_enable   = 1'b0;
        status_led      = 4'b0000;
        disp_mode       = 3'd0;

        case (state)
            IDLE: begin
                status_led = 4'b0001; // LED0: System Ready
                disp_mode  = 3'd0;    // "rdy "
            end

            AUTH: begin
                status_led = 4'b0000;
                disp_mode  = (auth_invalid) ? 3'd2 : 3'd1; // "FAIL" or "PASS"
            end

            SELECT: begin
                status_led      = 4'b0010; // LED1: Authenticated
                cand_sel_enable = 1'b1;
                disp_mode       = 3'd3;    // "SELC"
            end

            CONFIRM: begin
                status_led = 4'b0110; // LED1 & LED2: Candidate Selected
                disp_mode  = 3'd4;    // "YES "
            end

            CAST: begin
                status_led = 4'b1000; // LED3: Vote Cast
                cast_vote  = 1'b1;    // Increment vote counter
                disp_mode  = 3'd5;    // "dOnE"
            end

            LOCK: begin
                status_led = 4'b1000; // LED3: Locked
                disp_mode  = 3'd5;    // "dOnE"
            end

            RESULT: begin
                status_led    = 4'b1111; // All LEDs on in Admin Result mode
                result_enable = 1'b1;
                disp_mode     = 3'd6;    // Result tally mode
            end

            default: begin
                status_led = 4'b0000;
                disp_mode  = 3'd0;
            end
        endcase
    end

endmodule
