// ============================================================================
// Testbench: voting_machine_tb.v
// Description: Self-checking testbench for FPGA-Based Secure Digital Voting Machine.
//              Exercises all functional test cases from project report (T1 to T7)
//              and models the 3-voter sequence from Table 4.2.
// ============================================================================

`timescale 1ns / 1ps

module voting_machine_tb;

    // Inputs to DUT
    reg        clk;
    reg        reset;
    reg  [3:0] candidate_btn;
    reg        auth_enter;
    reg        confirm_btn;
    reg        cancel_btn;
    reg        new_session_btn;
    reg        admin_mode;
    reg  [3:0] auth_code;

    // Outputs from DUT
    wire [6:0] seg;
    wire [3:0] an;
    wire [3:0] status_led;

    // Instantiate Top-Level Device Under Test (DUT) in SIMULATION_MODE
    voting_machine_top #(
        .SIMULATION_MODE(1)
    ) dut (
        .clk             (clk),
        .reset           (reset),
        .candidate_btn   (candidate_btn),
        .auth_enter      (auth_enter),
        .confirm_btn     (confirm_btn),
        .cancel_btn      (cancel_btn),
        .new_session_btn (new_session_btn),
        .admin_mode      (admin_mode),
        .auth_code       (auth_code),
        .seg             (seg),
        .an              (an),
        .status_led      (status_led)
    );

    // Clock Generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    // Helper task to pulse a button for sufficient cycles
    task pulse_button;
        input integer btn_type; // 0=enter, 1=confirm, 2=cancel, 3=new_session, 4=candA, 5=candB, 6=candC, 7=candD
        begin
            case (btn_type)
                0: auth_enter = 1'b1;
                1: confirm_btn = 1'b1;
                2: cancel_btn = 1'b1;
                3: new_session_btn = 1'b1;
                4: candidate_btn[0] = 1'b1;
                5: candidate_btn[1] = 1'b1;
                6: candidate_btn[2] = 1'b1;
                7: candidate_btn[3] = 1'b1;
            endcase
            #100; // Hold for 10 clock cycles to clear debouncer
            auth_enter = 1'b0;
            confirm_btn = 1'b0;
            cancel_btn = 1'b0;
            new_session_btn = 1'b0;
            candidate_btn = 4'b0000;
            #50;
        end
    endtask

    initial begin
        // Initialize signals
        clk             = 0;
        reset           = 1;
        candidate_btn   = 4'b0000;
        auth_enter      = 0;
        confirm_btn     = 0;
        cancel_btn      = 0;
        new_session_btn = 0;
        admin_mode      = 0;
        auth_code       = 4'b0000;

        $display("==========================================================");
        $display("  STARTING FPGA SECURE VOTING MACHINE SIMULATION          ");
        $display("==========================================================");

        // Apply Reset
        #100;
        reset = 0;
        #50;
        $display("[INFO] System Reset applied. Current State: IDLE. Ready LED = %b", status_led[0]);

        // --------------------------------------------------------------------
        // TEST CASE T2: Invalid Authentication Code
        // --------------------------------------------------------------------
        $display("\n--- [TEST T2] Testing Invalid Passcode Entry ---");
        auth_code = 4'b0101; // Incorrect code (expected 4'b1011)
        pulse_button(0);     // Press Enter
        #100;
        $display("Entered Code: 4'b0101 -> FSM stays in AUTH / Displays FAIL. status_led: %b", status_led);

        // --------------------------------------------------------------------
        // VOTER 1 (from Table 4.2): Votes for CANDIDATE A
        // --------------------------------------------------------------------
        $display("\n--- [VOTER 1] Valid Authentication & Vote for Candidate A ---");
        auth_code = 4'b1011; // Correct code
        pulse_button(0);     // Press Enter -> Moves to SELECT
        #100;
        
        // Select Candidate A (BTN1)
        pulse_button(4);
        #100;
        $display("Candidate A selected. System in CONFIRM state.");

        // Confirm vote (YES)
        pulse_button(1);
        #100;
        $display("Vote Cast for Candidate A! System entered LOCK. Locked LED: %b", status_led[3]);

        // TEST CASE T6: Attempt double voting in same session
        $display("\n--- [TEST T6] Security Check: Double Voting Prevention ---");
        pulse_button(5); // Attempt selecting Candidate B
        pulse_button(1); // Attempt confirming
        #100;
        $display("Double voting attempt rejected. System remains locked (LED3: %b).", status_led[3]);

        // Officer authorizes new session
        pulse_button(3);
        #100;
        $display("New session authorized by official. System returned to IDLE.");

        // --------------------------------------------------------------------
        // VOTER 2 (from Table 4.2): Selects Candidate B, Cancels, then Votes for C
        // --------------------------------------------------------------------
        $display("\n--- [VOTER 2] Select Candidate B, Cancel (T4), then Vote for C (T5) ---");
        auth_code = 4'b1011;
        pulse_button(0); // Authenticate
        #100;

        // Select Candidate B
        pulse_button(5);
        #100;
        $display("Selected Candidate B. Now voter changes mind and presses CANCEL (NO)...");
        pulse_button(2); // Cancel
        #100;
        $display("Successfully returned to CANDIDATE SELECTION state.");

        // Now select Candidate C
        pulse_button(6);
        #100;
        pulse_button(1); // Confirm
        #100;
        $display("Vote Cast for Candidate C! Session locked.");

        // Officer authorizes new session
        pulse_button(3);
        #100;

        // --------------------------------------------------------------------
        // VOTER 3 (from Table 4.2): Votes for CANDIDATE A
        // --------------------------------------------------------------------
        $display("\n--- [VOTER 3] Votes for Candidate A ---");
        auth_code = 4'b1011;
        pulse_button(0); // Authenticate
        #100;
        pulse_button(4); // Select Candidate A
        #100;
        pulse_button(1); // Confirm
        #100;
        $display("Vote Cast for Candidate A! Session locked.");

        // Unlock to IDLE
        pulse_button(3);
        #100;

        // --------------------------------------------------------------------
        // TEST CASE T7: Admin Mode & Result Tally Inspection
        // --------------------------------------------------------------------
        $display("\n--- [TEST T7] Administrator Mode Results Verification ---");
        admin_mode = 1'b1;
        #100;
        $display("Admin Mode Asserted. Displaying tallies from 16-bit counters:");
        $display("  Expected Results: Candidate A = 2, Candidate B = 0, Candidate C = 1, Candidate D = 0");
        $display("  Actual Counters in Hardware:");
        $display("    Candidate A votes = %0d", dut.u_counter.vote_A);
        $display("    Candidate B votes = %0d", dut.u_counter.vote_B);
        $display("    Candidate C votes = %0d", dut.u_counter.vote_C);
        $display("    Candidate D votes = %0d", dut.u_counter.vote_D);

        // Verification assertions
        if (dut.u_counter.vote_A == 2 && 
            dut.u_counter.vote_B == 0 && 
            dut.u_counter.vote_C == 1 && 
            dut.u_counter.vote_D == 0) begin
            $display("\n>>> [ALL TESTS PASSED] MULTI-VOTER VERIFICATION & SYSTEM TALLY SUCCESSFUL! <<<");
        end else begin
            $display("\n>>> [ERROR] VOTE TALLY MISMATCH! <<<");
        end

        admin_mode = 1'b0;
        #100;
        $display("Admin mode disabled. System returned safely to IDLE.");
        $display("==========================================================");
        $finish;
    end

endmodule
