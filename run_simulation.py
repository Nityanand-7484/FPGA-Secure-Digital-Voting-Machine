"""
===============================================================================
FPGA SECURE DIGITAL VOTING MACHINE - INTERACTIVE & GUIDED SIMULATION
===============================================================================
Demonstrates:
  1. System Architecture & Inter-Module Signal Flow
  2. 7-State Finite State Machine (FSM) Operation
  3. Step-by-Step Voting Machine Operating Procedures (Voter & Admin)
===============================================================================
"""

import sys
import time

# -----------------------------------------------------------------------------
# FSM States & Architecture Constants
# -----------------------------------------------------------------------------
STATE_NAMES = [
    "IDLE",
    "AUTHENTICATION",
    "CANDIDATE SELECTION",
    "CONFIRMATION",
    "VOTE CAST",
    "SESSION LOCK",
    "ADMIN RESULT"
]

PASSWORD = 0b1011 # 4-bit reference password (4'b1011)

# ASCII 7-Segment Patterns for each character
SEG_FONT = {
    ' ': ["   ", "   ", "   "],
    'r': ["   ", " _ ", "|  "],
    'd': ["   ", " _|", "|_|"],
    'y': ["   ", "|_|", "  |"],
    'P': [" _ ", "|_|", "|  "],
    'A': [" _ ", "|_|", "| |"],
    'S': [" _ ", "|_ ", " _|"],
    'F': [" _ ", "|_ ", "|  "],
    'E': [" _ ", "|_ ", "|_ "],
    'L': ["   ", "|  ", "|_ "],
    'C': [" _ ", "|  ", "|_ "],
    'b': ["   ", "|_ ", "|_|"],
    'O': [" _ ", "| |", "|_|"],
    'n': ["   ", " _ ", "| |"],
    '1': ["   ", "  |", "  |"],
    '0': [" _ ", "| |", "|_|"],
    '2': [" _ ", " _|", "|_ "],
    '3': [" _ ", " _|", " _|"],
    '4': ["   ", "|_|", "  |"],
    '5': [" _ ", "|_ ", " _|"],
    '6': [" _ ", "|_ ", "|_|"],
    '7': [" _ ", "  |", "  |"],
    '8': [" _ ", "|_|", "|_|"],
    '9': [" _ ", "|_|", " _|"]
}

def render_7seg(text_4char):
    """Renders a 4-character string as visual 7-segment digital displays."""
    padded = text_4char.ljust(4)[:4]
    lines = ["", "", ""]
    for ch in padded:
        glyph = SEG_FONT.get(ch, SEG_FONT[' '])
        lines[0] += glyph[0] + "  "
        lines[1] += glyph[1] + "  "
        lines[2] += glyph[2] + "  "
    
    border = "+---------------------+"
    res = [
        border,
        f"|  {lines[0]}   |",
        f"|  {lines[1]}   |",
        f"|  {lines[2]}   |",
        border
    ]
    return "\n".join(res)

class FPGASimulator:
    def __init__(self):
        self.reset()

    def reset(self):
        self.state = 0 # IDLE
        self.prev_state = 0
        self.vote_counters = [0, 0, 0, 0] # A, B, C, D
        self.selected_cand = 0 # 0=A, 1=B, 2=C, 3=D
        self.admin_mode = False
        self.admin_cycle = 0
        self.last_action = "System Powered On / Reset Applied"
        self.active_signals = ["clk", "reset_sync", "ready_strobe"]

    @property
    def leds_str(self):
        l0 = "[*]" if self.state == 0 else "[ ]"
        l1 = "[*]" if self.state in [2, 3] else "[ ]"
        l2 = "[*]" if self.state == 3 else "[ ]"
        l3 = "[*]" if self.state in [4, 5] else "[ ]"
        if self.state == 6:
            l0 = l1 = l2 = l3 = "[*]"
        return f"LED0 (Ready): {l0}   LED1 (Auth): {l1}   LED2 (Cand): {l2}   LED3 (Lock): {l3}"

    @property
    def display_text(self):
        if self.state == 0:
            return "rdy "
        elif self.state == 1:
            return "PASS"
        elif self.state == 2:
            return "SELC"
        elif self.state == 3:
            cand = ['A', 'b', 'C', 'd'][self.selected_cand]
            return f"yES{cand}"
        elif self.state in [4, 5]:
            return "dOnE"
        elif self.state == 6:
            cand = ['A', 'b', 'C', 'd'][self.admin_cycle]
            val = self.vote_counters[self.admin_cycle]
            return f"{cand}{val:03d}"
        return "    "

    def display_board(self, show_architecture=True):
        print("\n" + "=" * 76)
        print("         FPGA DIGITAL VOTING MACHINE - ARCHITECTURE & FSM MONITOR")
        print("=" * 76)
        print(f" LAST ACTION      : {self.last_action}")
        print(f" CURRENT FSM STATE: {self.state} ({STATE_NAMES[self.state]})")
        print(f" HARDWARE LEDS    : {self.leds_str}")
        print("-" * 76)
        print(" 4-DIGIT 7-SEGMENT DISPLAY (Active-Low Time-Multiplexed Output):")
        print(render_7seg(self.display_text))
        print(f" Raw Digits Encoded: '{self.display_text}'")
        
        if show_architecture:
            print("-" * 76)
            print(" ACTIVE MODULE SIGNAL FLOW:")
            if self.state == 0:
                print("  [IDLE] >> Module 'voting_fsm' waiting for auth_enter or admin_mode switch.")
            elif self.state == 1:
                print("  [AUTH] >> Module 'authentication' comparing switch inputs with PASSWORD (4'b1011).")
            elif self.state == 2:
                print("  [SELECT] >> Module 'candidate_selector' active. Gating candidate_btn[3:0].")
            elif self.state == 3:
                print(f"  [CONFIRM] >> Candidate {['A','B','C','D'][self.selected_cand]} locked in buffer. Waiting confirm_btn or cancel_btn.")
            elif self.state == 4:
                print(f"  [CAST] >> Module 'vote_counter': cast_vote strobe pulsing. Incrementing tally for Candidate {['A','B','C','D'][self.selected_cand]}!")
            elif self.state == 5:
                print("  [LOCK] >> Module 'voting_fsm': Session locked! Input buttons disconnected to prevent double-voting.")
            elif self.state == 6:
                print(f"  [ADMIN RESULT] >> Module 'result_controller' routing Candidate {['A','B','C','D'][self.admin_cycle]} tally: {self.vote_counters[self.admin_cycle]}")
        print("=" * 76)

    def auth_step(self, passcode_str):
        try:
            val = int(passcode_str, 2)
        except ValueError:
            return False, "Invalid binary passcode!"
            
        if self.state in [0, 1]:
            if val == PASSWORD:
                self.state = 2 # SELECT
                self.last_action = f"Passcode {passcode_str} VALID -> FSM moved to CANDIDATE SELECTION"
                return True, "Passcode matched!"
            else:
                self.state = 1 # AUTH
                self.last_action = f"Passcode {passcode_str} INVALID -> Rejected! FSM stays in AUTH"
                return False, "Wrong passcode!"
        return False, "Auth only allowed in IDLE or AUTH state"

    def select_candidate(self, cand):
        if self.state != 2:
            return False, "Candidate selection only allowed in SELECT state"
        idx = {'A': 0, 'B': 1, 'C': 2, 'D': 3}.get(cand.upper())
        if idx is not None:
            self.selected_cand = idx
            self.state = 3 # CONFIRM
            self.last_action = f"Pressed BTN for Candidate {cand.upper()} -> FSM moved to CONFIRMATION"
            return True, f"Candidate {cand.upper()} chosen"
        return False, "Invalid candidate selection"

    def cancel_vote(self):
        if self.state == 3:
            self.state = 2 # Back to SELECT
            self.last_action = "Pressed CANCEL (BtnL) -> Returned to CANDIDATE SELECTION"
            return True, "Selection cancelled"
        return False, "Cancel ignored"

    def confirm_vote(self):
        if self.state == 3:
            # Move to CAST (counter increments), then immediately to LOCK
            self.vote_counters[self.selected_cand] += 1
            self.state = 5 # LOCK
            cand_letter = ['A', 'B', 'C', 'D'][self.selected_cand]
            self.last_action = f"Pressed CONFIRM (BtnR) -> VOTE CAST for {cand_letter}! FSM locked into SESSION LOCK"
            return True, "Vote successfully cast and locked"
        elif self.state == 5:
            self.last_action = "SECURITY ALERT: Double-vote attempted while in LOCK state! Blocked."
            return False, "Double voting blocked!"
        elif self.state == 6:
            self.admin_cycle = (self.admin_cycle + 1) % 4
            self.last_action = f"Admin pressed cycle button -> Viewing Candidate {['A','B','C','D'][self.admin_cycle]}"
            return True, "Cycled admin display"
        return False, "Confirm ignored"

    def new_session(self):
        if self.state in [1, 5]:
            self.state = 0 # IDLE
            self.last_action = "Polling Official pressed new_session_btn (BtnD) -> Booth re-armed to IDLE"
            return True, "Booth ready for next voter"
        return False, "New session key only valid when locked"

    def toggle_admin(self):
        if self.state == 0:
            self.state = 6 # RESULT
            self.admin_cycle = 0
            self.last_action = "Admin Switch (SW15) turned ON -> Entered ADMIN RESULT Mode"
            return True, "Admin mode engaged"
        elif self.state == 6:
            self.state = 0 # IDLE
            self.last_action = "Admin Switch (SW15) turned OFF -> Returned to IDLE"
            return True, "Admin mode disengaged"
        return False, "Admin mode can only be toggled from IDLE"


# -----------------------------------------------------------------------------
# Mode 1: Automated Step-by-Step Guided Walkthrough
# -----------------------------------------------------------------------------
def run_guided_walkthrough():
    sim = FPGASimulator()
    print("\n" + "#" * 76)
    print("   STARTING STEP-BY-STEP OPERATION & ARCHITECTURE GUIDED SIMULATION")
    print("#" * 76)
    print("This walkthrough demonstrates the exact operational flow and FSM states")
    print("from the project report and README.\n")

    def pause_step(step_num, title, description):
        print(f"\n>>> [STEP {step_num}] {title}")
        print(f"    Description: {description}")
        sim.display_board()
        input("    [Press Enter to proceed to the next step...]")

    # Step 1: Power On / Ready
    pause_step(1, "SYSTEM POWER-ON / INITIALIZATION", 
               "System is reset. FSM is in IDLE (0). LED0 is lit. 7-Segment shows 'rdy '.")

    # Step 2: Failed Auth
    sim.auth_step("0101")
    pause_step(2, "VOTER 1: INVALID AUTHENTICATION ATTEMPT", 
               "Voter enters wrong passcode '0101'. Module authentication.v rejects code. FSM stays in AUTH.")

    # Step 3: Valid Auth
    sim.auth_step("1011")
    pause_step(3, "VOTER 1: VALID AUTHENTICATION (4'b1011)", 
               "Voter enters correct passcode '1011'. FSM transitions to CANDIDATE SELECTION (2). Display shows 'SELC'.")

    # Step 4: Candidate Selection
    sim.select_candidate('A')
    pause_step(4, "VOTER 1: CANDIDATE SELECTION (BTN1 -> Candidate A)", 
               "Voter presses BTN1. Candidate code 2'b00 stored. FSM transitions to CONFIRMATION (3). Display shows 'yESA'.")

    # Step 5: Vote Casting & Session Lockout
    sim.confirm_vote()
    pause_step(5, "VOTER 1: VOTE CONFIRMATION (BtnR -> YES)", 
               "Voter presses Confirm. CAST state pulses cast_vote for 1 cycle. vote_counter increments Candidate A. FSM moves to SESSION LOCK (5). Display shows 'dOnE'.")

    # Step 6: Security Check - Double Voting Prevention
    sim.confirm_vote()
    pause_step(6, "SECURITY DEMO: DOUBLE-VOTING PREVENTED", 
               "Voter attempts to press confirm/candidate buttons again in the same session. Hardware FSM rejects input. Vote counters remain unchanged.")

    # Step 7: Official Re-arms Booth
    sim.new_session()
    pause_step(7, "POLLING OFFICIAL: AUTHORIZE NEXT VOTER (BtnD)", 
               "Polling officer presses supervisory button. FSM returns from SESSION LOCK to IDLE (0). Display shows 'rdy '.")

    # Step 8: Voter 2 Cancel & Reselect
    sim.auth_step("1011")
    sim.select_candidate('B')
    sim.display_board()
    print(">>> [STEP 8a] Voter 2 selects Candidate B by accident. Display shows 'yESb'.")
    input("    [Press Enter to see Voter 2 press CANCEL...]")
    sim.cancel_vote()
    sim.display_board()
    print(">>> [STEP 8b] Voter 2 pressed CANCEL (BtnL). FSM safely returned to CANDIDATE SELECTION ('SELC').")
    input("    [Press Enter to re-select Candidate C and confirm...]")
    sim.select_candidate('C')
    sim.confirm_vote()
    pause_step(8, "VOTER 2: RESELECT & VOTE FOR CANDIDATE C", 
               "Voter re-selected Candidate C and confirmed. vote_counter for C incremented. Booth locked.")

    # Officer resets for Voter 3
    sim.new_session()
    sim.auth_step("1011")
    sim.select_candidate('A')
    sim.confirm_vote()
    sim.new_session()
    pause_step(9, "VOTER 3: VOTES FOR CANDIDATE A & COMPLETES ELECTION", 
               "Voter 3 voted for Candidate A. Total votes cast: Candidate A=2, Candidate C=1. System returned to IDLE.")

    # Step 10: Admin Mode Result Inspection
    sim.toggle_admin()
    sim.display_board()
    print(">>> [STEP 10a] Admin flips SW15. Entered ADMIN RESULT Mode. All LEDs lit.")
    print("    Showing Candidate A tally on 7-segment display:")
    input("    [Press Enter to cycle to Candidate B...]")
    sim.confirm_vote() # Cycle to B
    sim.display_board()
    input("    [Press Enter to cycle to Candidate C...]")
    sim.confirm_vote() # Cycle to C
    sim.display_board()
    input("    [Press Enter to cycle to Candidate D...]")
    sim.confirm_vote() # Cycle to D
    sim.display_board()
    input("    [Press Enter to close Admin mode and return to IDLE...]")
    sim.toggle_admin()
    sim.display_board()

    print("\n" + "=" * 76)
    print(">>> GUIDED SIMULATION COMPLETED SUCCESSFULLY! <<<")
    print("=" * 76)


# -----------------------------------------------------------------------------
# Mode 2: Interactive Terminal Operation
# -----------------------------------------------------------------------------
def run_interactive_mode():
    sim = FPGASimulator()
    while True:
        sim.display_board()
        print("ACTIONS:")
        print("  1. Enter 4-bit Passcode (SW3..0) & Press Enter (BtnU)")
        print("  2. Select Candidate (BTN1: A, BTN2: B, BTN3: C, BTN4: D)")
        print("  3. Press Confirm (YES / BtnR)")
        print("  4. Press Cancel  (NO / BtnL)")
        print("  5. Polling Official: Authorize Next Voter (BtnD)")
        print("  6. Admin: Toggle Admin Mode Switch (SW15)")
        print("  7. Master System Reset (BtnC)")
        print("  8. Exit Simulator")
        
        choice = input("\nEnter selection (1-8): ").strip()
        if choice == '1':
            code = input("Enter 4-bit binary code (default 1011): ").strip()
            ok, msg = sim.auth_step(code)
            print(f"[{'SUCCESS' if ok else 'REJECTED'}] {msg}")
        elif choice == '2':
            cand = input("Enter candidate letter (A, B, C, or D): ").strip()
            ok, msg = sim.select_candidate(cand)
            print(f"[{'SUCCESS' if ok else 'ERROR'}] {msg}")
        elif choice == '3':
            ok, msg = sim.confirm_vote()
            print(f"[{'SUCCESS' if ok else 'BLOCKED'}] {msg}")
        elif choice == '4':
            ok, msg = sim.cancel_vote()
            print(f"[{'SUCCESS' if ok else 'IGNORED'}] {msg}")
        elif choice == '5':
            ok, msg = sim.new_session()
            print(f"[{'SUCCESS' if ok else 'IGNORED'}] {msg}")
        elif choice == '6':
            ok, msg = sim.toggle_admin()
            print(f"[{'SUCCESS' if ok else 'IGNORED'}] {msg}")
        elif choice == '7':
            sim.reset()
            print("[RESET] System Master Reset executed.")
        elif choice == '8':
            print("Exiting simulator. Goodbye!")
            break
        else:
            print("Invalid choice, try again.")


# -----------------------------------------------------------------------------
# Main Entry Point
# -----------------------------------------------------------------------------
def main():
    print("=" * 76)
    print("   FPGA SECURE DIGITAL VOTING MACHINE - SYSTEM SIMULATOR")
    print("=" * 76)
    print("Choose simulation mode:")
    print("  1. Guided Step-by-Step Architecture & Operating Walkthrough")
    print("  2. Interactive Virtual Voting Booth (Manual Control)")
    print("  3. Exit")
    
    choice = input("\nSelect mode (1-3): ").strip()
    if choice == '1':
        run_guided_walkthrough()
    elif choice == '2':
        run_interactive_mode()
    else:
        print("Exited.")

if __name__ == "__main__":
    main()
