# FPGA-Based Secure Digital Voting Machine Using FSM and RTL Design

An educational digital design project implementing a secure, FSM-driven Electronic Voting Machine (EVM) in Verilog HDL targeted for FPGA development boards (e.g., Digilent Basys 3 / Artix-7).

---

## 📁 Project Structure

```text
FPGA_Voting_Machine_Project/
├── src/                                  # Synthesizable Verilog RTL Modules
│   ├── authentication.v                  # 4-bit switch passcode verification
│   ├── candidate_selector.v              # Candidate push-button decoder (A, B, C, D)
│   ├── vote_counter.v                    # Independent 16-bit per-candidate tally registers
│   ├── button_debounce.v                 # Glitch filter & single-pulse generator
│   ├── seven_segment.v                   # Multiplexed 4-digit 7-segment display driver
│   ├── result_controller.v               # Admin candidate tally multiplexer
│   ├── voting_fsm.v                      # Core 7-state controller FSM
│   └── voting_machine_top.v              # Top-level integration & port mapping
├── tb/                                   # Verilog Testbenches
│   └── voting_machine_tb.v               # Comprehensive self-checking simulation testbench
├── constraints/                          # FPGA Board Pin Constraints
│   └── Basys3_Master.xdc                 # Pin mappings for Digilent Basys 3 (XC7A35T)
└── README.md                             # Project Documentation
```

---

## ⚙️ Module Hierarchy & Architecture

* **`voting_machine_top`** (Top-Level Integration)
  * `button_debounce` (Debouncers for buttons: Candidates A–D, Enter, Confirm, Cancel, New Session)
  * `authentication` (Compares entered 4-bit passcode against on-chip password `4'b1011`)
  * `candidate_selector` (Encodes candidate selections into 2-bit ID `00`=A, `01`=B, `10`=C, `11`=D)
  * `voting_fsm` (Central FSM: `IDLE` $\rightarrow$ `AUTH` $\rightarrow$ `SELECT` $\rightarrow$ `CONFIRM` $\rightarrow$ `CAST` $\rightarrow$ `LOCK`, plus admin `RESULT`)
  * `vote_counter` (Four independent 16-bit counters incremented upon valid vote casting)
  * `result_controller` (Cycles through candidate tallies under admin control)
  * `seven_segment` (Multiplexes 4 display digits: displays `rdy`, `PASS`, `FAIL`, `SELC`, `YES`, `dOnE`, and count `A002`)

---

## 🛡️ Security Features
1. **Passcode-Gated Authentication:** Voter must enter a valid passcode to advance past `IDLE`.
2. **Double-Voting Prevention:** Once a vote is confirmed, the FSM transitions to `LOCK`, ignoring all vote buttons until an election official re-arms the booth with `new_session`.
3. **Cancel / Re-Selection:** Voters can review and cancel their selection before committing their vote.
4. **Admin-Only Result Tally:** Vote counts remain hidden from regular voters and can only be inspected by engaging `admin_mode`.

---

## 🛠️ FPGA Implementation Flow (Xilinx Vivado)

1. **Create Project:** Open Xilinx Vivado and create an **RTL Project**.
2. **Select Part:** Target `xc7a35tcpg236-1` (Digilent Basys 3) or your board's FPGA device.
3. **Add Design Sources:** Add all Verilog files in `src/` to Design Sources. Set `voting_machine_top.v` as Top.
4. **Add Constraints:** Add `constraints/Basys3_Master.xdc`.
5. **Add Simulation Sources:** Add `tb/voting_machine_tb.v`.
6. **Simulate:** Run **Behavioral Simulation** to verify test cases (T1–T7) and multi-voter sequences.
7. **Synthesize & Implement:** Run **Run Synthesis** $\rightarrow$ **Run Implementation**.
8. **Generate Bitstream:** Generate bitstream and program the FPGA via Vivado Hardware Manager.
