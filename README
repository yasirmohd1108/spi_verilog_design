PARAMETERIZED SPI MASTER & SLAVE CORE IN VERILOG
Hey there! This is a project I built to learn digital design and hardware description languages better. It's a fully synthesizable and parameterized Serial Peripheral Interface (SPI) IP core written in Verilog-2001.
I designed both the Master and Slave modules from scratch and verified them in Xilinx Vivado across all 4 standard SPI modes.
Features
Full-Duplex Communication: Simultaneous data transmission and reception between Master and Slave.
All 4 SPI Modes Supported: Configurable via parameters (CPOL and CPHA):
Mode 0: 
CPOL=0,CPHA=0 (Clock idle low, sample on 1st edge)
Mode 1: 
CPOL=0,CPHA=1 (Clock idle low, sample on 2nd edge)
Mode 2: 
CPOL=1,CPHA=0 (Clock idle high, sample on 1st edge)
Mode 3: 
CPOL=1,CPHA=1 (Clock idle high, sample on 2nd edge)
CDC Synchronizer: Added 3-stage flip-flop synchronizers on the slave side (SCLK, CS_N, and MOSI) to prevent metastability issues when receiving signals across clock domains.
Clock Division: Custom clock divider that outputs timing strobes for sampling and shifting bits correctly.
Self-Checking Testbench: A testbench that instantiates all 4 modes at once to automatically verify data transfers.
How it Works:
        +--------------------------------------------------------+
        |                      SPI MASTER                        |
        |                                                        |
        |   +---------------+            +-------------------+   |
        |   |  CLK_DIVIDER  |--sclk----->|                   |---|---> SCLK
        |   |               |--edge1---->|   CONTROL FSM &   |---|---> MOSI
        |   |               |--edge2---->|   SHIFT REGISTER  |<--|--- MISO
        |   +---------------+            +-------------------+   |---|---> CS_N
        +--------------------------------------------------------+
                                   |
             ================================================
                                   |
        +--------------------------------------------------------+
        |                       SPI SLAVE                        |
        |                                                        |
        |   +---------------+            +-------------------+   |
 SCLK --|-->|   3-STAGE     |--sclk_clean|   SAMPLING &      |---|---> MISO
 MOSI --|-->|  SYNCHRONIZER |--mosi_clean|   SHIFT LOGIC     |<--|--- MOSI
 CS_N --|-->|  & EDGE DET   |--cs_n_clean|                   |   |
        |   +---------------+            +-------------------+   |
        +--------------------------------------------------------+
​
Project Structure:
├── CLK_DIVIDER.v  # Generates SCLK and edge tick pulses
├── SPI_MASTER.v   # FSM and logic for the SPI Master
├── SPI_SLAVE.v    # Slave logic with CDC synchronizers
└── SPI_TB.v       # Self-checking testbench for all 4 modes
​
Verification & Results:
I simulated the entire design in AMD Vivado Simulator. To verify everything works properly:
Master transmits: 0xA5
Slave transmits: 0x3C
Simulation Terminal Output
==================================================
          SPI MULTI-MODE TESTBENCH START
==================================================
[0 ns] Applying Reset...
[40 ns] Reset De-asserted.
--------------------------------------------------
[60 ns] Starting Transaction:
          Master TX Data = 0xA5
          Slave  TX Data = 0x3C
--------------------------------------------------
[2060 ns] Transmission Completed across all SPI modes.

==================================================
             VERIFICATION RESULTS
==================================================
[MODE 0 PASS] Master RX: 0x3C | Slave RX: 0xA5
[MODE 1 PASS] Master RX: 0x3C | Slave RX: 0xA5
[MODE 2 PASS] Master RX: 0x3C | Slave RX: 0xA5
[MODE 3 PASS] Master RX: 0x3C | Slave RX: 0xA5
==================================================
            SIMULATION COMPLETE
==================================================
​
Running the Simulation:
In Vivado GUI
Open Vivado and create a new project.
Add CLK_DIVIDER.v, SPI_MASTER.v, and SPI_SLAVE.v as design sources.
Add SPI_TB.v as a simulation source.
Click Run Simulation -> Run Behavioral Simulation.
Quick CLI Run (Vivado Terminal)
xvlog CLK_DIVIDER.v SPI_MASTER.v SPI_SLAVE.v SPI_TB.v
xelab SPI_TB -s top_sim -debug typical
xsim top_sim -runall
​
What I Learned:
Debugging timing shift bugs when handling CPOL=1 modes.
Why Clock Domain Crossing (CDC) synchronization is essential when dealing with external SPI clocks.
Structuring clean, modular RTL code with Verilog parameters.
