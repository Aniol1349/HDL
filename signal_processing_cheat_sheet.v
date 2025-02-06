`timescale 1ns / 1ps

// Verilog Module Cheat Sheet: Signal Processing Basics to Advanced
module SignalProcessingCheatSheet;

// ==========================================================================
// 1. Parameters and Internal Signals
// ==========================================================================
// Parameters allow flexibility in configuring the module for different applications.
parameter DATA_WIDTH = 16;       // Bit-width of the input data
// Explanation: The range of signed data is -2^(DATA_WIDTH-1) to 2^(DATA_WIDTH-1)-1.
// For example, with DATA_WIDTH=16, the range is -32768 to 32767.

parameter SCALE_FACTOR = 2;     // Scaling factor for data
// Explanation: SCALE_FACTOR is a multiplier that amplifies or attenuates the input signal.
// For example, SCALE_FACTOR=2 doubles the signal, and SCALE_FACTOR=0.5 halves it.

parameter OFFSET = 0;           // Offset for scaling
// Explanation: OFFSET is an additive constant used to shift the scaled signal.
// This is useful for bias correction or aligning the signal to a desired baseline.

parameter NORMALIZE_MAX = 32767; // Max value for normalization
parameter NORMALIZE_MIN = -32768; // Min value for normalization
// Explanation: NORMALIZE_MAX and NORMALIZE_MIN define the bounds for normalization.
// Normalization rescales the signal to fit a fixed range, improving consistency across datasets.

// Internal signals
reg signed [DATA_WIDTH-1:0] in_data;      // Input signal
wire signed [DATA_WIDTH-1:0] scaled_data; // Scaled signal
wire signed [DATA_WIDTH-1:0] normalized_data; // Normalized signal
reg [DATA_WIDTH-1:0] smoothed_data;      // Smoothed signal

// ==========================================================================
// 2. Scaling Implementation
// ==========================================================================
// Scaling adjusts the input signal by a factor and applies an offset.
assign scaled_data = (in_data * SCALE_FACTOR) + OFFSET;
// Use case: In audio processing, scaling adjusts volume levels. In sensor data, scaling converts raw ADC values to meaningful units.

// ==========================================================================
// 3. Normalization Implementation
// ==========================================================================
// Normalization maps the signal to a fixed range (e.g., [-1, 1]).
wire signed [DATA_WIDTH-1:0] range = NORMALIZE_MAX - NORMALIZE_MIN;
assign normalized_data = ((in_data - NORMALIZE_MIN) * 32767) / range; // Normalized to [-1, 1] range
// Use case: Normalization is essential in machine learning, where inputs must be scaled to similar ranges for effective training.

// ==========================================================================
// 4. Moving Average Filter (Smoothing)
// ==========================================================================
// Smoothes the signal using a simple 5-point moving average.
reg signed [DATA_WIDTH-1:0] window[0:4]; // Sliding window buffer
integer i;

always @(in_data) begin
    // Shift window
    for (i = 4; i > 0; i = i - 1) begin
        window[i] <= window[i-1];
    end
    window[0] <= in_data;

    // Compute average
    smoothed_data <= (window[0] + window[1] + window[2] + window[3] + window[4]) / 5;
end
// Use case: Smoothing is used in financial data analysis to reduce noise or in sensor applications to filter fluctuations.

// ==========================================================================
// 5. Clipping Implementation
// ==========================================================================
// Ensures the signal remains within specified bounds to prevent saturation.
function [DATA_WIDTH-1:0] clip_signal;
    input signed [DATA_WIDTH-1:0] value;
    input signed [DATA_WIDTH-1:0] min_val;
    input signed [DATA_WIDTH-1:0] max_val;
    begin
        if (value > max_val)
            clip_signal = max_val;
        else if (value < min_val)
            clip_signal = min_val;
        else
            clip_signal = value;
    end
endfunction
// Use case: Clipping is used in audio processing to limit volume or in control systems to prevent actuator saturation.

// ==========================================================================
// 6. Derivative Calculation
// ==========================================================================
// Computes the discrete derivative of the signal to measure changes.
reg signed [DATA_WIDTH-1:0] prev_data;
wire signed [DATA_WIDTH-1:0] derivative;

assign derivative = in_data - prev_data;

always @(posedge clk) begin
    prev_data <= in_data;
end
// Use case: Derivatives are used in motion analysis (e.g., velocity from position) or edge detection in image processing.

// ==========================================================================
// 7. Integration Calculation
// ==========================================================================
// Computes the discrete integral of the signal for accumulation.
reg signed [DATA_WIDTH+15:0] integral;

always @(posedge clk) begin
    if (reset)
        integral <= 0;
    else
        integral <= integral + in_data;
end
// Use case: Integration is used in energy computation, position from velocity, or signal smoothing.

// ==========================================================================
// 8. Floating-Point to Fixed-Point Conversion
// ==========================================================================
// Fixed-point representation is preferred in FPGA systems due to limited hardware resources.
// Floating-point numbers are converted to fixed-point for efficient computation.
parameter FLOAT_WIDTH = 32; // Floating-point input bit-width
parameter FIX_WIDTH = 16;   // Fixed-point output bit-width
parameter Q_FACTOR = 8;     // Number of fractional bits in fixed-point format

reg [FLOAT_WIDTH-1:0] float_input; // Input in floating-point format
wire signed [FIX_WIDTH-1:0] fixed_output; // Output in fixed-point format

assign fixed_output = float_input[FLOAT_WIDTH-1:Q_FACTOR]; // Truncate or shift to fixed-point
// Hint: Consider rounding logic for better precision when truncating floating-point values.
// Use case: Converting sensor data or machine learning weights for FPGA implementation.

// ==========================================================================
// 9. Overflow Handling
// ==========================================================================
// Overflow occurs when a computation exceeds the representable range.
// This function implements saturation logic to clip the values within a safe range.
function signed [FIX_WIDTH-1:0] saturate;
    input signed [FIX_WIDTH-1:0] value;
    input signed [FIX_WIDTH-1:0] max_val;
    input signed [FIX_WIDTH-1:0] min_val;
    begin
        if (value > max_val)
            saturate = max_val;
        else if (value < min_val)
            saturate = min_val;
        else
            saturate = value;
    end
endfunction
// Hint: Saturation prevents catastrophic failures in safety-critical systems such as industrial automation.
// Use case: Preventing wraparound errors in computations like control systems or digital filters.

// ==========================================================================
// 10. Bit Growth in Arithmetic Operations
// ==========================================================================
// Arithmetic operations like addition and multiplication increase the bit-width required to store results.
parameter ADDER_INPUT_WIDTH = 16; // Input bit-width for addition
parameter ADDER_OUTPUT_WIDTH = ADDER_INPUT_WIDTH + 1; // Output bit-width for addition

reg signed [ADDER_INPUT_WIDTH-1:0] operand_a, operand_b;
wire signed [ADDER_OUTPUT_WIDTH-1:0] sum;

assign sum = operand_a + operand_b;
// Explanation: Addition increases bit-width by 1 to accommodate carry.

parameter MULT_INPUT_WIDTH = 16; // Input bit-width for multiplication
parameter MULT_OUTPUT_WIDTH = MULT_INPUT_WIDTH * 2; // Output bit-width for multiplication

reg signed [MULT_INPUT_WIDTH-1:0] multiplicand, multiplier;
wire signed [MULT_OUTPUT_WIDTH-1:0] product;

assign product = multiplicand * multiplier;
// Hint: Plan bit growth during design to avoid truncation errors in critical calculations.
// Use case: Ensuring intermediate results in multipliers or filters do not overflow.

// ==========================================================================
// 11. Pipelining for High Throughput
// ==========================================================================
// Pipelining splits operations into smaller stages to improve throughput at the cost of latency.
reg signed [ADDER_INPUT_WIDTH-1:0] pipeline_stage1;
reg signed [ADDER_OUTPUT_WIDTH-1:0] pipeline_stage2;

always @(posedge clk) begin
    pipeline_stage1 <= operand_a + operand_b; // First stage
    pipeline_stage2 <= pipeline_stage1 + operand_b; // Second stage
end
// Hint: Balance latency and throughput based on the application's performance needs.
// Use case: High-performance FIR filters, matrix multiplications, or FFT implementations.

// ==========================================================================
// 12. Dynamic Range Scaling
// ==========================================================================
// Scaling adjusts the input signal dynamically to prevent overflow while maximizing resolution.
parameter SCALE_DYNAMIC_MAX = 100; // Maximum scaling factor
parameter SCALE_DYNAMIC_MIN = 1;   // Minimum scaling factor
reg [DATA_WIDTH-1:0] dynamic_scale_factor;

always @(in_data) begin
    if (in_data > NORMALIZE_MAX / 2)
        dynamic_scale_factor <= SCALE_DYNAMIC_MIN;
    else
        dynamic_scale_factor <= SCALE_DYNAMIC_MAX;
end

assign scaled_dynamic_output = in_data * dynamic_scale_factor;
// Hint: Dynamic scaling is crucial in adaptive systems, such as communications or radar processing.
// Use case: Maximizing dynamic range in image or signal compression applications.

// ==========================================================================
// 13. Quantization Noise Mitigation
// ==========================================================================
// Quantization introduces noise during fixed-point conversion or data compression.
// Logic to add dithering (random noise) to reduce the effect of quantization noise.
reg [DATA_WIDTH-1:0] quantization_noise;
reg [DATA_WIDTH-1:0] dithered_signal;

always @(posedge clk) begin
    quantization_noise <= $random % 2; // Simple random noise generator
    dithered_signal <= fixed_output + quantization_noise;
end

// Hint: Dithering improves the perceptual quality of signals, especially in image and audio processing.
// Use case: Reducing artifacts in image rendering or improving sound fidelity in digital audio.

endmodule
