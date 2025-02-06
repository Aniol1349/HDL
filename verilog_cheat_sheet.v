`timescale 1ns / 1ps

// Comprehensive Verilog Basics Cheat Sheet Module
module verilog_cheat_sheet (
    input wire clk,              // Clock signal
    input wire reset,            // Reset signal (active-high)
    input wire [3:0] input_data, // 4-bit input data
    output reg [7:0] output_data // 8-bit output data
);

    // ===================================================================
    // 1. Parameters: Define constants for reusability and scalability
    // ===================================================================
    parameter WIDTH = 8;        // Parameter for data width
    parameter MAX_COUNT = 255; // Parameter for a counter's maximum value

    // ===================================================================
    // 2. Registers and Wires
    // ===================================================================
    reg [WIDTH-1:0] register_a;   // Register (stores data)
    reg [WIDTH-1:0] counter;      // Counter register
    wire [WIDTH-1:0] result;      // Wire (used for combinational logic)

    // ===================================================================
    // 3. Combinational Logic
    // ===================================================================
    // Use `assign` for simple combinational logic
    assign result = input_data + register_a; // Example: Add input and register

    // ===================================================================
    // 4. Sequential Logic (Synchronous with Clock)
    // ===================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize on reset
            register_a <= 0;
            counter <= 0;
        end else begin
            // Update on clock edge
            register_a <= result;          // Store combinational result
            counter <= counter + 1;        // Increment counter
        end
    end

    // ===================================================================
    // 5. Conditional Statements
    // ===================================================================
    always @(posedge clk) begin
        if (input_data == 4'b0001) begin
            output_data <= 8'b11110000;    // Set output based on input
        end else if (input_data == 4'b0010) begin
            output_data <= 8'b00001111;    // Different output for another input
        end else begin
            output_data <= 8'b10101010;    // Default case
        end
    end

    // ===================================================================
    // 6. Case Statements
    // ===================================================================
    always @(posedge clk) begin
        case (input_data)
            4'b0000: output_data <= 8'b00000001; // Case for input 0
            4'b0001: output_data <= 8'b00000010; // Case for input 1
            4'b0010: output_data <= 8'b00000100; // Case for input 2
            default: output_data <= 8'b11111111; // Default case
        endcase
    end

    // ===================================================================
    // 7. Generate Statement (Parameterized Instantiation)
    // ===================================================================
    genvar i; // Generate variable
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_block
            always @(posedge clk) begin
                if (reset) begin
                    output_data[i] <= 0; // Reset each bit
                end else begin
                    output_data[i] <= input_data[i]; // Pass-through logic
                end
            end
        end
    endgenerate

    // ===================================================================
    // 8. Multi-Bit and Arithmetic Operations
    // ===================================================================
    always @(posedge clk) begin
        // Bit slicing
        output_data[3:0] <= input_data; // Assign lower 4 bits
        output_data[7:4] <= ~input_data; // Assign negation to upper 4 bits

        // Concatenation
        output_data <= {input_data, ~input_data}; // Combine data

        // Arithmetic operations
        register_a <= register_a + 1; // Increment
        counter <= counter - 1;       // Decrement
    end

    // ===================================================================
// 9. Shift Registers
// ===================================================================
always @(posedge clk) begin
    // Example: 4-bit shift register
    register_a <= {register_a[WIDTH-2:0], input_data[0]};
    // Shifts all bits left, inserting input_data[0] into LSB
end

// ===================================================================
// 10. Counter Module
// ===================================================================
// A simple parameterized up-counter
reg [WIDTH-1:0] up_counter; // Counter variable

always @(posedge clk or posedge reset) begin
    if (reset) begin
        up_counter <= 0;       // Reset counter
    end else begin
        up_counter <= up_counter + 1; // Increment counter
    end
end

// ===================================================================
// 11. Simple State Machine (Finite State Machine - FSM)
// ===================================================================
// Declare states using local parameters
localparam IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10;

reg [1:0] state; // Current state
reg [1:0] next_state; // Next state

// State transition on clock
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE; // Reset to IDLE state
    end else begin
        state <= next_state; // Move to next state
    end
end

// Define state transitions
always @(*) begin
    case (state)
        IDLE: 
            if (input_data == 4'b0001)
                next_state = READ;
            else
                next_state = IDLE;
        READ:
            if (input_data == 4'b0010)
                next_state = WRITE;
            else
                next_state = READ;
        WRITE:
            next_state = IDLE;
        default: 
            next_state = IDLE;
    endcase
end

// Output logic based on state
always @(state) begin
    case (state)
        IDLE: output_data = 8'b00000000;
        READ: output_data = 8'b11111111;
        WRITE: output_data = 8'b10101010;
        default: output_data = 8'b00000000;
    endcase
end

// ===================================================================
// 12. Latches (Avoid When Possible)
// ===================================================================
// Latches are created unintentionally if not all conditions are covered
// This example creates a latch:
always @(*) begin
    if (input_data[0] == 1) begin
        output_data = 8'b11111111; // No else case -> latch created
    end
end

// ===================================================================
// 13. RAM and ROM Instantiation
// ===================================================================
// Synchronous RAM with write and read
reg [WIDTH-1:0] ram [0:15]; // 16 x WIDTH memory
reg [3:0] address;          // Address signal

always @(posedge clk) begin
    if (write_enable) begin
        ram[address] <= input_data; // Write data to RAM
    end
end

always @(posedge clk) begin
    if (read_enable) begin
        output_data <= ram[address]; // Read data from RAM
    end
end

// ===================================================================
// 14. Practical Tips for Writing Verilog
// ===================================================================
// Tip 1: Always reset flip-flops in sequential logic
// This ensures predictable behavior during simulation and hardware reset.

// Tip 2: Avoid latches by covering all conditions in combinational blocks
// Example:
always @(*) begin
    if (condition1)
        signal = value1;
    else if (condition2)
        signal = value2;
    else
        signal = default_value; // Default case prevents latch
end

// Tip 3: Use non-blocking (`<=`) for sequential logic and blocking (`=`) for combinational
// Sequential example:
always @(posedge clk) begin
    register <= next_value; // Non-blocking for flip-flop
end
// Combinational example:
always @(*) begin
    signal = a & b;         // Blocking for pure logic
end

// Tip 4: Parameterize your modules for flexibility
// Example: Width can be passed as a parameter for counters, adders, etc.

// ===================================================================
// 15. Arithmetic Operations
// ===================================================================
// Verilog supports bitwise and arithmetic operations
always @(*) begin
    output_data = input_data + register_a;  // Addition
    output_data = input_data - register_a;  // Subtraction
    output_data = input_data * 2;           // Multiplication
    output_data = input_data << 1;          // Left shift (multiply by 2)
    output_data = input_data >> 1;          // Right shift (divide by 2)
end

// ===================================================================
// 16. Useful Patterns
// ===================================================================

// Pattern 1: Bit Reversal
reg [WIDTH-1:0] reversed_bits;
integer i;
always @(*) begin
    for (i = 0; i < WIDTH; i = i + 1) begin
        reversed_bits[i] = input_data[WIDTH-1-i];
    end
end

// Pattern 2: Priority Encoder
always @(*) begin
    casez (input_data) // 'z' allows wildcard matching
        4'b1???: output_data = 8'b10000000;
        4'b01??: output_data = 8'b01000000;
        4'b001?: output_data = 8'b00100000;
        4'b0001: output_data = 8'b00010000;
        default: output_data = 8'b00000000;
    endcase
end

// Pattern 3: Debouncing a Button Input
reg [15:0] debounce_counter;
reg button_stable;

always @(posedge clk) begin
    if (button_raw == 1) begin
        if (debounce_counter < 16'hFFFF)
            debounce_counter <= debounce_counter + 1;
        else
            button_stable <= 1;
    end else begin
        debounce_counter <= 0;
        button_stable <= 0;
    end
end

// ===================================================================
// End of Verilog Basics Cheat Sheet
// ===================================================================

endmodule
