`timescale 1ns / 1ps

//=================================================================================
// Module: fir_filter
//
// Description:
//    A parameterizable Finite Impulse Response (FIR) filter implementation in Verilog.
//    This filter uses a straightforward Direct Form structure where new input samples
//    are shifted into a delay line and multiplied by corresponding coefficients.
//    The partial products are then summed to produce the output.
//
// Parameters:
//    DATA_WIDTH   - Bit width of input samples.
//    COEFF_WIDTH  - Bit width of filter coefficients.
//    N_TAPS       - Number of FIR filter taps (also sets the length of the delay line).
//
// I/O Ports:
//    clk       - System clock signal.
//    rst       - Asynchronous reset signal (active high).
//    valid_in  - Indicates when 'data_in' is valid.
//    data_in   - Signed input sample to the filter.
//    valid_out - Indicates when 'data_out' is valid.
//    data_out  - Signed filtered output sample.
//
// Key Points:
//    1. Parameterization allows changing DATA_WIDTH, COEFF_WIDTH, and N_TAPS without
//       rewriting the core logic. This makes the design scalable for different filter
//       specifications or applications.
//
//    2. The filter stores the most recent N_TAPS samples in a shift register (x_reg).
//       Each clock cycle with valid_in=1, a new sample is shifted in, and the oldest
//       sample is discarded.
//
//    3. The multiplication of input samples by coefficients and subsequent accumulation
//       (summing) happens every clock cycle. This design processes one sample per cycle
//       at the given clock rate.
//
//    4. The design as written is a simple non-pipelined version. All multiplications
//       and additions occur within one always block. For higher performance (higher
//       clock speeds or more taps), you can add pipeline registers internally or
//       partition the summation to reduce critical path delays.
//
//    5. Storing coefficients in a reg array and initializing them in an initial block
//       makes the filter easily customizable. Just recalculate and assign new coeffs
//       for different frequency responses.
//
// Scalability Considerations:
//    - By using parameters (N_TAPS, DATA_WIDTH, COEFF_WIDTH), you can easily scale
//      the filter:
//        * Increasing N_TAPS: Just adjust the parameter. The code automatically
//          creates a larger array for x_reg and h, and the for-loops adapt accordingly.
//        * Changing DATA_WIDTH/COEFF_WIDTH: Automatically adjusts internal signal widths
//          to prevent overflow and maintain precision.
//    - For more complex FIR designs or larger N_TAPS, you could:
//        * Add pipeline registers between multiplications and additions to break down
//          the accumulation into multiple stages.
//        * Use DSP slices explicitly and cascade them for partial sum accumulation.
//        * Store coefficients in ROM or memory if you have a very large number of taps.
//    - This current structure (shift register + loop accumulation) is the simplest
//      scalable template. It’s straightforward and can be enhanced by inserting
//      pipeline stages or by splitting the summation into trees of adders for better
//      timing.
//
//=================================================================================

module fir_filter #(
    parameter DATA_WIDTH = 16,     // Bit width of input data
    parameter COEFF_WIDTH = 18,    // Bit width of filter coefficients
    parameter N_TAPS = 8           // Number of FIR filter taps
)(
    input wire clk,                               // System clock
    input wire rst,                               // Asynchronous reset
    input wire valid_in,                          // Input valid signal
    input wire signed [DATA_WIDTH-1:0] data_in,   // Current input sample
    output reg valid_out,                         // Output valid signal
    output reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] data_out // Filtered output sample
);

    //----------------------------------------------------------------------------
    // Coefficients Storage:
    // Here we define the FIR coefficients in a reg array. Each coefficient is a
    // signed value with COEFF_WIDTH bits. We initialize them in an initial block.
    // Storing them in a parameterizable array allows quick coefficient changes,
    // making the design more flexible and scalable.
    //----------------------------------------------------------------------------
    reg signed [COEFF_WIDTH-1:0] h [0:N_TAPS-1];
    initial begin
        // Example coefficients for a low-pass filter.
        // These can be recalculated and replaced as needed.
        h[0] = 18'sd2550;
        h[1] = 18'sd5024;
        h[2] = 18'sd7316;
        h[3] = 18'sd8561;
        h[4] = 18'sd8561;
        h[5] = 18'sd7316;
        h[6] = 18'sd5024;
        h[7] = 18'sd2550;
    end

    //----------------------------------------------------------------------------
    // Input Sample Shift Register (Delay Line):
    // x_reg holds the last N_TAPS input samples. Each new sample is inserted at x_reg[0]
    // and older samples shift down the line. This creates the necessary delayed samples
    // for FIR filtering: x[n], x[n-1], x[n-2], ..., x[n-(N_TAPS-1)].
    //----------------------------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] x_reg [0:N_TAPS-1];

    // 'i' is used as a loop index variable
    integer i;
    // 'acc' is the accumulator used to sum up the products of samples and coefficients.
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] acc;

    //----------------------------------------------------------------------------
    // Main Processing Always Block:
    // This block triggers on the positive edge of clk or when rst is asserted.
    // On reset, it clears the shift register and output signals.
    // On each valid input, it shifts in a new sample and updates the output.
    //
    // Steps per cycle:
    //    1. If valid_in is high, shift the delay line and insert data_in.
    //    2. Multiply each stored sample by its coefficient and accumulate the sum.
    //    3. Assign the summed result to data_out.
    //    4. valid_out mirrors valid_in to indicate output timing.
    //----------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all delay line registers and outputs
            for (i=0; i<N_TAPS; i=i+1)
                x_reg[i] <= 0;
            data_out <= 0;
            valid_out <= 0;
        end else begin
            if (valid_in) begin
                // Shift in the new input sample at x_reg[0]
                x_reg[0] <= data_in;
                for (i=1; i<N_TAPS; i=i+1)
                    x_reg[i] <= x_reg[i-1];
            end

            // Initialize accumulator to zero each cycle
            acc = 0;
            // Compute the FIR output by summing x_reg[i]*h[i] for i = 0 to N_TAPS-1
            for (i=0; i<N_TAPS; i=i+1) begin
                acc = acc + (x_reg[i]*h[i]);
            end

            // Update output data and valid flag
            data_out <= acc;
            // valid_out follows valid_in, meaning output is valid one cycle after input is processed.
            valid_out <= valid_in;
        end
    end

endmodule
