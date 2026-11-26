# Toll Booth Controller

A Verilog HDL toll booth controller using a 3-state Moore finite state machine
(FSM). It detects one vehicle at a time, waits for payment before opening the
gate, and counts a vehicle only after a paid vehicle passes.

## Features

- **3-state Moore FSM:** `IDLE`, `WAIT_PAY`, and `GATE_OPEN`.
- **Payment-controlled gate:** the gate opens and the green LED turns on only
  after payment is confirmed.
- **Unpaid vehicle handling:** an unpaid vehicle can leave without opening the
  gate or incrementing the counter.
- **8-bit vehicle counter:** counts up to 255 paid vehicles that pass.
- **Asynchronous active-high reset:** resets the FSM to `IDLE` and clears the
  counter without waiting for a clock edge.

## Project Folder Structure

```text
Toll-Booth-Controller-main/
├── toll_booth.v
├── toll_booth_tb.v
├── run.do
├── README.md
└── .gitignore
```

## Inputs and Outputs

| Signal | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Rising-edge-triggered system clock |
| `reset` | Input | 1 bit | Asynchronous active-high reset |
| `car_detect` | Input | 1 bit | `1` when a vehicle is at the gate |
| `paid` | Input | 1 bit | `1` when payment is confirmed |
| `gate_open` | Output | 1 bit | `1` when the gate is open |
| `red_led` | Output | 1 bit | Stop indicator |
| `green_led` | Output | 1 bit | Go indicator |
| `car_count` | Output | 8 bits | Number of paid vehicles that passed |

## Architecture, FSM, and State Transitions

The controller uses a two-bit state register with separate next-state logic,
Moore output logic, and an 8-bit vehicle counter. The state register and
counter use the same asynchronous active-high reset.

| State | Encoding |
| :--- | :---: |
| `IDLE` | `2'b00` |
| `WAIT_PAY` | `2'b01` |
| `GATE_OPEN` | `2'b10` |

| Current state | Condition | Next state | Result |
| :--- | :--- | :--- | :--- |
| `IDLE` | `car_detect == 0` | `IDLE` | Wait for a vehicle |
| `IDLE` | `car_detect == 1` | `WAIT_PAY` | Wait for payment |
| `WAIT_PAY` | `car_detect == 1 && paid == 0` | `WAIT_PAY` | Keep gate closed |
| `WAIT_PAY` | `car_detect == 0` | `IDLE` | Unpaid vehicle leaves; do not count |
| `WAIT_PAY` | `car_detect == 1 && paid == 1` | `GATE_OPEN` | Open the gate |
| `GATE_OPEN` | `car_detect == 1` | `GATE_OPEN` | Keep gate open as vehicle passes |
| `GATE_OPEN` | `car_detect == 0` | `IDLE` | Close gate and increment count once |

The outputs are Moore outputs and depend only on the current state:

| State | `gate_open` | `red_led` | `green_led` |
| :--- | :---: | :---: | :---: |
| `IDLE` | 0 | 1 | 0 |
| `WAIT_PAY` | 0 | 1 | 0 |
| `GATE_OPEN` | 1 | 0 | 1 |

## Running the Project in ModelSim SE Plus 5.7g on Windows

### Software requirements

- Windows
- ModelSim SE Plus 5.7g (Compiler 2003.10)
- The five project files listed above

The design and testbench use Verilog-2001 syntax and require no additional
packages or external tools.

### 1. Open ModelSim and set the project directory

Open ModelSim SE Plus 5.7g from the Windows Start menu or its installed
shortcut. In the Transcript window, change to the directory containing the
project files. For the example Windows installation, enter:

```tcl
cd C:/Users/student/Desktop/Toll-Booth-Controller-main
```

Alternatively, use **File → Change Directory** and select that folder.
Confirm that the Transcript's current directory is the project folder before
compiling or running `run.do`.

### 2. Compile and start simulation manually

In the Transcript window, create the `work` library if it does not already
exist, then compile both Verilog files and start the testbench:

```tcl
vlib work
vlog -work work toll_booth.v
vlog -work work toll_booth_tb.v
vsim work.toll_booth_tb
```

If `work` already exists, skip `vlib work`. Both `vlog` commands should finish
without errors before starting `vsim`.

### 3. Add signals and run

In the Transcript window, add the testbench and DUT signals recursively to the
Wave window, then run until the testbench calls `$finish`:

```tcl
add wave -r sim:/toll_booth_tb/*
run -all
```

The recursive waveform command includes the testbench signals and the
controller's internal signals.

### 4. Zoom the waveform

Use the Wave window's **Zoom Full** toolbar button or its **View → Zoom → Zoom
Full** menu item to fit the complete simulation in the window. This GUI action
is used instead of the unsupported `wave zoom full` Transcript command.

### 5. Run the entire flow with `run.do`

With the Transcript's current directory set to the project folder, enter:

```tcl
do run.do
```

The script creates `work` only if needed, compiles the design and testbench,
starts `work.toll_booth_tb`, adds its signals recursively to the Wave window,
and runs to `$finish`.

### Expected Transcript output

The testbench prints these success messages when its checks pass:

```text
ASYNCHRONOUS RESET CHECK PASSED
TEST 1 PASSED
TEST 2 PASSED
TEST 3 PASSED
ALL TESTS PASSED: car_count=2, gate_open=0, red_led=1, green_led=0
```

ModelSim may also print its normal `$finish` notice. On a failed check, the
testbench prints a `FAIL:` message identifying the check and ends simulation.

### Expected waveform behavior

- Reset is asserted between clock edges; the counter clears and the outputs
  show the `IDLE` values: gate closed, red on, green off.
- For the first vehicle, the gate remains closed in `WAIT_PAY`. After payment,
  the gate opens and green turns on. When the vehicle leaves, the gate closes,
  red turns on, and `car_count` becomes 1.
- The unpaid vehicle remains in `WAIT_PAY` with the gate closed. On departure,
  the FSM returns to `IDLE` and `car_count` remains 1.
- The second paid vehicle opens the gate, then closes it on departure;
  `car_count` becomes 2.
- At the end of the testbench, `gate_open=0`, `red_led=1`, `green_led=0`, and
  `car_count=2`.

### Common errors and solutions

| Error or symptom | Solution |
| :--- | :--- |
| `could not open do file` or source files cannot be found | Change the Transcript working directory to the project folder, then run `do run.do` again. |
| `work` library does not exist | Run `vlib work` once from the project folder. The `run.do` script also creates it when absent. |
| `toll_booth` or `toll_booth_tb` cannot be found | Compile `toll_booth.v` and `toll_booth_tb.v` with the two `vlog` commands before `vsim`. |
| Wave window is empty | Run `add wave -r sim:/toll_booth_tb/*` after starting the simulation. |
| Waveform is hard to read | Use the Wave window's **Zoom Full** toolbar button or **View → Zoom → Zoom Full**. |
| A `FAIL:` message appears | Read the specific check in the Transcript and inspect the corresponding signals around that time in the Wave window. |

## Testbench Scenarios

The testbench uses a 10 ns clock period and automatically checks asynchronous
reset, the LED values in each FSM state, payment gating, unpaid departures,
and the vehicle counter:

| Scenario | Expected `car_count` |
| :--- | :---: |
| Initial reset | 0 |
| First paid vehicle passes | 1 |
| Unpaid vehicle leaves | 1 |
| Second paid vehicle passes | 2 |

## Limitations

- The 8-bit counter wraps from 255 to 0 on overflow.
- The controller handles one toll lane and one vehicle at a time.
- Vehicle-type fees, payment timeouts, and display outputs are not implemented.

Possible future extensions include multi-lane support, vehicle-type fee
calculation, a payment timeout, and a 7-segment display.
