`timescale 1ns / 1ps

//==============================================================================
// Testbench: tb_fir_filter
//
// Description:
//   This testbench is designed to verify the functionality of the FIR filter
//   by stimulating it with a test input signal and observing the output.
//
// Key Objectives:
//   1. Generate a mixed signal composed of two sine waves:
//      - One at an in-band frequency (F_in), which the FIR filter should pass.
//      - One at an out-of-band frequency (F_out), which the FIR filter should attenuate.
//   
//   2. Feed these samples into the FIR filter and observe if the output behaves
//      as expected (i.e., low-frequency sine is passed, high-frequency sine is reduced).
//
//   3. Validate the correct handling of input/output data flow by checking valid signals,
//      ensuring the testbench matches the filter's parameters.
//
// Parameters:
//   DATA_WIDTH  - Bit width of the input sample data.
//   COEFF_WIDTH - Bit width of the FIR filter coefficients.
//   N_TAPS      - Number of FIR filter taps.
//
// Testbench Strategy:
//   - A fixed sampling frequency (Fs) is assumed, and we generate samples at this rate.
//   - We compute two sine waves (F_in and F_out) at each sample index using the $sin function.
//   - We mix these waves, scale them, and clip them to fit into DATA_WIDTH bits.
//   - The resulting samples are fed to the DUT (Device Under Test) each clock cycle when valid_in=1.
//   - After sending a certain number of samples (num_samples), we stop feeding new data and allow
//     the filter to settle, then stop the simulation.
//
// Scalable and Adaptable:
//   - By parameterizing DATA_WIDTH, COEFF_WIDTH, and N_TAPS, this testbench can easily be reused
//     for different FIR configurations.
//   - Changing frequencies or amplitude is straightforward—just modify the corresponding variables.
//
//==============================================================================

module tb_fir_filter;

    //----------------------------------------------------------------------------
    // Parameter Declarations
    //----------------------------------------------------------------------------
    parameter DATA_WIDTH = 16;    // Must match the FIR filter's input width
    parameter COEFF_WIDTH = 18;   // Must match the FIR filter's coefficient width
    parameter N_TAPS = 8;         // Must match the FIR filter's number of taps

    //----------------------------------------------------------------------------
    // DUT I/O Signals
    //----------------------------------------------------------------------------
    reg clk;    // Clock signal
    reg rst;    // Reset signal, active high
    reg valid_in;   // Indicates when input data_in is valid
    reg signed [DATA_WIDTH-1:0] data_in;   // Input sample to the FIR filter

    wire valid_out;  // Indicates when output data_out is valid
    wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] data_out; // Filtered output data

    //----------------------------------------------------------------------------
    // DUT Instantiation
    //
    // We connect the testbench signals to the FIR filter module under test.
    // Parameters are passed to match the filter's internal configuration.
    //----------------------------------------------------------------------------
    fir_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .N_TAPS(N_TAPS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    //----------------------------------------------------------------------------
    // Test Signal Generation Variables
    //
    // These variables are used to compute the input samples (two sine waves mixed):
    //   Fs       - Sampling frequency in Hz.
    //   F_in     - In-band frequency to be passed by the FIR filter.
    //   F_out    - Out-of-band frequency to be attenuated by the FIR filter.
    //   two_pi   - Constant for 2*pi, used to compute sinusoidal angles.
    //   angle_in/out - Angles in radians for the sine functions.
    //   sine_in/out  - Computed sine values (real).
    //   mixed_sample - Combined sine_in + sine_out, then scaled.
    //
    // We use `real` for floating-point arithmetic in simulation only (not synthesizable).
    // The final integer conversion truncates to DATA_WIDTH bits.
    //----------------------------------------------------------------------------
    real Fs;
    real F_in;
    real F_out;
    real two_pi;
    real angle_in;
    real angle_out;
    real sine_in;
    real sine_out;
    real mixed_sample;

    integer amplitude;    // Scale factor for the input signal amplitude
    integer num_samples;  // Number of samples to send to the FIR filter
    integer sample_int;   // Intermediate integer sample after scaling and clipping
    integer i;            // Loop counter for generating samples

    //----------------------------------------------------------------------------
    // Clock Generation
    //
    // We use a 100 MHz clock (10 ns period) for the simulation. The FIR filter
    // processes one sample per clock when valid_in=1. In a real design, the
    // sample rate might be lower than the clock speed, but here we simplify by
    // presenting a new sample every clock cycle.
    //----------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clk every 5 ns => 100 MHz
    end

    //----------------------------------------------------------------------------
    // Main Test Sequence
    //
    // Steps:
    //   1. Set up parameters (Fs, frequencies, amplitude).
    //   2. Assert reset, wait, then release it.
    //   3. Generate num_samples input samples, each mixed from two sine waves.
    //   4. Drive valid_in high during sample generation, then low afterwards.
    //   5. Wait enough time for the filter to produce output and settle.
    //   6. Stop the simulation.
    //----------------------------------------------------------------------------
    initial begin
        // Initialize test parameters
        Fs = 44100.0;     // Audio CD standard sampling rate
        F_in = 1000.0;    // In-band frequency (1 kHz)
        F_out = 25000.0;  // Out-of-band frequency (25 kHz)
        two_pi = 6.283185307179586; // 2*pi constant
        amplitude = 10000;  // Scale factor for signal amplitude
        num_samples = 2000; // Number of samples to generate

        // Initialize signals
        rst = 1;
        valid_in = 0;
        data_in = 0;

        // Wait 100 ns with reset asserted
        #100;
        rst = 0; // Deassert reset
        #100;

        // Generate and feed samples into the FIR filter
        for (i = 0; i < num_samples; i = i + 1) begin
            @(posedge clk); // Wait for next clock edge
            valid_in <= 1;

            // Compute the angle for each frequency at sample index i
            // angle = 2*pi*(F * i / Fs)
            angle_in  = two_pi * (F_in  * i / Fs);
            angle_out = two_pi * (F_out * i / Fs);

            // Compute the sine values (range: -1 to +1)
            sine_in  = $sin(angle_in);
            sine_out = $sin(angle_out);

            // Mix the two waves and scale
            mixed_sample = (sine_in + sine_out) * amplitude;

            // Convert from real to integer (truncation)
            sample_int = mixed_sample;

            // Clip to fit in 16-bit signed range
            // This ensures the input doesn't overflow and matches DATA_WIDTH
            if (sample_int > 32767)   sample_int = 32767;
            if (sample_int < -32768)  sample_int = -32768;

            data_in <= sample_int;
        end

        // After sending all samples, stop providing new ones
        @(posedge clk);
        valid_in <= 0;

        // Wait additional time to see the output settling after last sample
        #10000;
        $stop; // End simulation
    end

    //----------------------------------------------------------------------------
    // Output Monitoring
    //
    // On every clock, if valid_out=1, display the current input and output.
    // This helps us observe the filter's behavior in real-time:
    //   - Initially, output may reflect both frequencies.
    //   - Over time, we expect the out-of-band frequency (25 kHz) to be attenuated,
    //     leaving primarily the 1 kHz component visible in the output.
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time: %t, Input: %d, Output: %d", $time, data_in, data_out);
        end
    end

endmodule
