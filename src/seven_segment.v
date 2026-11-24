// ============================================================================
// Module: seven_segment.v
// Description: Multiplexed 4-digit 7-segment display driver.
//              - Displays readable status words: "RDY ", "AUTH", "INVD", "SEL ", "CONF", "DONE"
//              - In RESULT mode, displays candidate letter + 3-digit vote count (e.g., "A002")
//              - Active-low outputs for common-anode displays (Basys 3 standard)
// ============================================================================

`timescale 1ns / 1ps

module seven_segment #(
    parameter REFRESH_LIMIT = 18'd200_000 // Refresh divider (~500Hz for 100MHz clock)
)(
    input  wire        clk,          // System clock (100MHz)
    input  wire        reset,        // Active-high reset
    input  wire [2:0]  disp_mode,    // Display message mode
    input  wire [1:0]  candidate,    // Candidate ID: 00=A, 01=B, 10=C, 11=D
    input  wire [15:0] result_val,   // Current candidate vote count to display
    output reg  [6:0]  seg,          // Active-low cathode segments {g,f,e,d,c,b,a}
    output reg  [3:0]  an            // Active-low digit anodes {AN3, AN2, AN1, AN0}
);

    // Modes definition
    localparam MODE_RDY   = 3'd0; // Display "rdy "
    localparam MODE_AUTH  = 3'd1; // Display "PASS"
    localparam MODE_INVD  = 3'd2; // Display "FAIL"
    localparam MODE_SEL   = 3'd3; // Display "SELC"
    localparam MODE_CONF  = 3'd4; // Display "YES "
    localparam MODE_DONE  = 3'd5; // Display "dOnE"
    localparam MODE_RES   = 3'd6; // Display candidate letter + 3-digit count

    // Digit refresh counter
    reg [17:0] refresh_counter;
    reg [1:0]  digit_select;

    // 4 character codes for the 4 digits (from left AN3 to right AN0)
    reg [4:0] char3, char2, char1, char0; // 0-9 digits, 10=A, 11=B, 12=C, 13=D, 14=blank, etc.
    reg [4:0] active_char;

    // Segment encoding lookup (Active-low: 0 turns ON segment, 1 turns OFF)
    // Segments: {g, f, e, d, c, b, a}
    function [6:0] get_segments(input [4:0] ch);
        case (ch)
            5'd0:  get_segments = 7'b1000000; // 0
            5'd1:  get_segments = 7'b1111001; // 1
            5'd2:  get_segments = 7'b0100100; // 2
            5'd3:  get_segments = 7'b0110000; // 3
            5'd4:  get_segments = 7'b0011001; // 4
            5'd5:  get_segments = 7'b0010010; // 5
            5'd6:  get_segments = 7'b0000010; // 6
            5'd7:  get_segments = 7'b1111000; // 7
            5'd8:  get_segments = 7'b0000000; // 8
            5'd9:  get_segments = 7'b0010000; // 9
            5'd10: get_segments = 7'b0001000; // A
            5'd11: get_segments = 7'b0000011; // b
            5'd12: get_segments = 7'b1000110; // C
            5'd13: get_segments = 7'b0100001; // d
            5'd14: get_segments = 7'b0101111; // r
            5'd15: get_segments = 7'b0010001; // y
            5'd16: get_segments = 7'b0001100; // P
            5'd17: get_segments = 7'b0010010; // S
            5'd18: get_segments = 7'b0001110; // F
            5'd19: get_segments = 7'b1000111; // L
            5'd20: get_segments = 7'b0111000; // F/I/blank
            5'd21: get_segments = 7'b0000110; // E
            5'd22: get_segments = 7'b0101011; // n
            5'd23: get_segments = 7'b1111111; // Blank
            default: get_segments = 7'b1111111;
        endcase
    endfunction

    // Decode display message according to mode
    always @(*) begin
        case (disp_mode)
            MODE_RDY: begin // "rdy "
                char3 = 5'd14; // r
                char2 = 5'd13; // d
                char1 = 5'd15; // y
                char0 = 5'd23; // Blank
            end
            MODE_AUTH: begin // "PASS"
                char3 = 5'd16; // P
                char2 = 5'd10; // A
                char1 = 5'd17; // S
                char0 = 5'd17; // S
            end
            MODE_INVD: begin // "FAIL"
                char3 = 5'd18; // F
                char2 = 5'd10; // A
                char1 = 5'd1;  // I (as 1)
                char0 = 5'd19; // L
            end
            MODE_SEL: begin // "SELC"
                char3 = 5'd17; // S
                char2 = 5'd21; // E
                char1 = 5'd19; // L
                char0 = 5'd12; // C
            end
            MODE_CONF: begin // "YES "
                char3 = 5'd15; // Y
                char2 = 5'd21; // E
                char1 = 5'd17; // S
                char0 = 5'd23; // Blank
            end
            MODE_DONE: begin // "dOnE"
                char3 = 5'd13; // d
                char2 = 5'd0;  // O (0)
                char1 = 5'd22; // n
                char0 = 5'd21; // E
            end
            MODE_RES: begin // Candidate letter + 3-digit decimal count
                char3 = (candidate == 2'b00) ? 5'd10 :
                        (candidate == 2'b01) ? 5'd11 :
                        (candidate == 2'b10) ? 5'd12 : 5'd13;
                char2 = (result_val / 100) % 10;
                char1 = (result_val / 10) % 10;
                char0 = result_val % 10;
            end
            default: begin
                char3 = 5'd23; char2 = 5'd23; char1 = 5'd23; char0 = 5'd23;
            end
        endcase
    end

    // Anode scanning refresh counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refresh_counter <= 18'd0;
            digit_select    <= 2'b00;
        end else begin
            if (refresh_counter >= REFRESH_LIMIT) begin
                refresh_counter <= 18'd0;
                digit_select    <= digit_select + 2'b01;
            end else begin
                refresh_counter <= refresh_counter + 18'd1;
            end
        end
    end

    // Time-multiplex the 4 display digits (Active-Low Anodes)
    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110; // Enable AN0 (Rightmost)
                active_char = char0;
            end
            2'b01: begin
                an = 4'b1101; // Enable AN1
                active_char = char1;
            end
            2'b10: begin
                an = 4'b1011; // Enable AN2
                active_char = char2;
            end
            2'b11: begin
                an = 4'b0111; // Enable AN3 (Leftmost)
                active_char = char3;
            end
        endcase
        seg = get_segments(active_char);
    end

endmodule
