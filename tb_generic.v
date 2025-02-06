`timescale 1ns / 1ps

// Test bench for a generic Verilog module
module tb_generic;

// ==========================================================================
// 1. Declare internal signals to connect to the DUT
// ==========================================================================
reg clk;               // Clock signal
reg reset;             // Reset signal
reg [3:0] in_signal;   // Example input signal
wire [7:0] out_signal; // Example output signal

// ==========================================================================
// 2. Instantiate the Design Under Test (DUT)
// ==========================================================================
generic_module uut (
    .clk(clk),           // Connect clock signal
    .reset(reset),       // Connect reset signal
    .input_signal(in_signal), // Connect input signal
    .output_signal(out_signal) // Connect output signal
);

// ==========================================================================
// 3. Generate input clock signal
// ==========================================================================
initial begin
    clk = 0;                     // Initialize clock to 0
    forever #10 clk = ~clk;      // Toggle clock every 10 ns (50 MHz clock)
end

// ==========================================================================
// 4. Generate input reset signal
// ==========================================================================
initial begin
    reset = 1;                   // Assert reset at the start
    #50 reset = 0;               // Deassert reset after 50 ns
end

// ==========================================================================
// 5. Apply input stimuli
// ==========================================================================
initial begin
    in_signal = 4'b0000;         // Initialize input signal

    // Apply test cases
    #100 in_signal = 4'b0101;    // Change input signal after 100 ns
    #100 in_signal = 4'b1111;    // Change input signal after another 100 ns
    #100 in_signal = 4'b0011;    // Change input signal again

    // Stop the simulation after enough time
    #500 $stop;
end

// ==========================================================================
// 6. Monitor output signals
// ==========================================================================
initial begin
    // Display signals to the console
    $monitor("Time: %t | clk: %b | reset: %b | in_signal: %b | out_signal: %b", 
             $time, clk, reset, in_signal, out_signal);
end

// ==========================================================================
// 7. Measure and validate output signals (Optional)
// ==========================================================================
always @(posedge clk) begin
    // Example: Assert if output signal does not match expected value
    if (!reset && in_signal == 4'b0101 && out_signal !== 8'b10101010) begin
        $error("Mismatch detected at time %t! in_signal: %b, out_signal: %b", 
               $time, in_signal, out_signal);
    end
end

endmodule
