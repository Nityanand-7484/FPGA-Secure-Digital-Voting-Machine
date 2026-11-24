// ============================================================================
// Module: voting_machine_top.v
// Description: Top-Level Integration of FPGA-Based Secure Digital Voting Machine
//              Instantiates:
//              - Button debouncing filters
//              - Voter authentication module
//              - Candidate selection decoder
//              - Central 7-State FSM controller
//              - 16-bit vote counters
//              - Admin result controller
//              - Multiplexed 7-segment display driver
// ============================================================================

`timescale 1ns / 1ps

module voting_machine_top #(
    parameter SIMULATION_MODE = 0 // Set to 1 in simulation for fast counters
)(
    input  wire       clk,             // 100MHz master board clock
    input  wire       reset,           // Active-high master reset button
    
    // Physical inputs
    input  wire [3:0] candidate_btn,   // Push buttons: BTN1=A, BTN2=B, BTN3=C, BTN4=D
    input  wire       auth_enter,      // Push button to enter passcode
    input  wire       confirm_btn,     // Push button YES / Confirm
    input  wire       cancel_btn,      // Push button NO / Cancel
    input  wire       new_session_btn, // Push button for polling officer to unlock next voter
    input  wire       admin_mode,      // Slide switch: 1=Admin Result Mode, 0=Voting Mode
    input  wire [3:0] auth_code,       // 4 slide switches for entering voter passcode
    
    // Outputs
    output wire [6:0] seg,             // 7-segment cathodes (active-low)
    output wire [3:0] an,              // 7-segment digit anodes (active-low)
    output wire [3:0] status_led       // Status LEDs: LED0=Ready, LED1=Auth, LED2=Cand, LED3=Lock
);

    // Debounce parameter: fast for simulation, ~10ms for hardware synthesis
    localparam DEBOUNCE_VAL = (SIMULATION_MODE == 1) ? 20'd4 : 20'd1_000_000;
    localparam REFRESH_VAL  = (SIMULATION_MODE == 1) ? 18'd4 : 18'd200_000;

    // ------------------------------------------------------------------------
    // 1. Button Debouncers
    // ------------------------------------------------------------------------
    wire [3:0] db_cand_btn;
    wire       db_auth_enter;
    wire       db_confirm_btn;
    wire       db_cancel_btn;
    wire       db_new_session_btn;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_cand_debouncers
            button_debounce #(.DEBOUNCE_LIMIT(DEBOUNCE_VAL)) u_db_cand (
                .clk       (clk),
                .reset     (reset),
                .btn_in    (candidate_btn[i]),
                .btn_pulse (db_cand_btn[i])
            );
        end
    endgenerate

    button_debounce #(.DEBOUNCE_LIMIT(DEBOUNCE_VAL)) u_db_enter (
        .clk       (clk),
        .reset     (reset),
        .btn_in    (auth_enter),
        .btn_pulse (db_auth_enter)
    );

    button_debounce #(.DEBOUNCE_LIMIT(DEBOUNCE_VAL)) u_db_confirm (
        .clk       (clk),
        .reset     (reset),
        .btn_in    (confirm_btn),
        .btn_pulse (db_confirm_btn)
    );

    button_debounce #(.DEBOUNCE_LIMIT(DEBOUNCE_VAL)) u_db_cancel (
        .clk       (clk),
        .reset     (reset),
        .btn_in    (cancel_btn),
        .btn_pulse (db_cancel_btn)
    );

    button_debounce #(.DEBOUNCE_LIMIT(DEBOUNCE_VAL)) u_db_new_session (
        .clk       (clk),
        .reset     (reset),
        .btn_in    (new_session_btn),
        .btn_pulse (db_new_session_btn)
    );

    // ------------------------------------------------------------------------
    // 2. Authentication Module
    // ------------------------------------------------------------------------
    wire auth_valid;
    wire auth_invalid;

    authentication u_auth (
        .clk       (clk),
        .reset     (reset),
        .auth_code (auth_code),
        .enter     (db_auth_enter),
        .valid     (auth_valid),
        .invalid   (auth_invalid)
    );

    // ------------------------------------------------------------------------
    // 3. Candidate Selector Module
    // ------------------------------------------------------------------------
    wire [1:0] cand_code;
    wire       cand_selected;
    wire       cand_sel_enable;

    candidate_selector u_cand_sel (
        .clk                (clk),
        .reset              (reset),
        .enable             (cand_sel_enable),
        .candidate_btn      (db_cand_btn),
        .candidate_code     (cand_code),
        .candidate_selected (cand_selected)
    );

    // Register candidate choice across CONFIRM and CAST states
    reg [1:0] stored_candidate;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stored_candidate <= 2'b00;
        end else if (cand_selected) begin
            stored_candidate <= cand_code;
        end
    end

    // ------------------------------------------------------------------------
    // 4. Central Voting FSM
    // ------------------------------------------------------------------------
    wire [2:0] current_state;
    wire [2:0] disp_mode;
    wire       cast_vote_pulse;
    wire       result_enable;

    voting_fsm u_fsm (
        .clk                (clk),
        .reset              (reset),
        .auth_enter         (db_auth_enter),
        .auth_valid         (auth_valid),
        .auth_invalid       (auth_invalid),
        .candidate_selected (cand_selected),
        .confirm_btn        (db_confirm_btn),
        .cancel_btn         (db_cancel_btn),
        .new_session        (db_new_session_btn),
        .admin_mode         (admin_mode),
        .state              (current_state),
        .status_led         (status_led),
        .disp_mode          (disp_mode),
        .cast_vote          (cast_vote_pulse),
        .cand_sel_enable    (cand_sel_enable),
        .result_enable      (result_enable)
    );

    // ------------------------------------------------------------------------
    // 5. 16-Bit Vote Counters
    // ------------------------------------------------------------------------
    wire [15:0] vote_A, vote_B, vote_C, vote_D;

    vote_counter u_counter (
        .clk       (clk),
        .reset     (reset),
        .cast_vote (cast_vote_pulse),
        .candidate (stored_candidate),
        .vote_A    (vote_A),
        .vote_B    (vote_B),
        .vote_C    (vote_C),
        .vote_D    (vote_D)
    );

    // ------------------------------------------------------------------------
    // 6. Admin Result Controller
    // ------------------------------------------------------------------------
    wire [1:0]  admin_cand_idx;
    wire [15:0] admin_cand_count;

    // Use confirm_btn to cycle through candidates while in admin mode
    result_controller u_results (
        .clk               (clk),
        .reset             (reset),
        .result_enable     (result_enable),
        .cycle_btn         (db_confirm_btn),
        .vote_A            (vote_A),
        .vote_B            (vote_B),
        .vote_C            (vote_C),
        .vote_D            (vote_D),
        .current_candidate (admin_cand_idx),
        .current_count     (admin_cand_count)
    );

    // ------------------------------------------------------------------------
    // 7. 7-Segment Display Driver
    // ------------------------------------------------------------------------
    wire [1:0]  display_cand_id = (result_enable) ? admin_cand_idx : stored_candidate;
    wire [15:0] display_value   = (result_enable) ? admin_cand_count : 16'd0;

    seven_segment #(.REFRESH_LIMIT(REFRESH_VAL)) u_disp (
        .clk        (clk),
        .reset      (reset),
        .disp_mode  (disp_mode),
        .candidate  (display_cand_id),
        .result_val (display_value),
        .seg        (seg),
        .an         (an)
    );

endmodule
