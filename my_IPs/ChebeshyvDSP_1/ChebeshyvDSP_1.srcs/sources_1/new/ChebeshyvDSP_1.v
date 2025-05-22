`timescale 1ns / 1ps

module ChebeshyvDSP_1 #(
    parameter DATA_WIDTH = 32,
    parameter TID_WIDTH  = 3   // Ensure this matches the I2S IP's TID width
)(
    input  wire                     axi_clk,
    input  wire                     axi_resetn,

    // Slave AXI-Stream Interface
    input  wire                     s_axis_valid,
    input  wire [DATA_WIDTH-1:0]    s_axis_data,
    input  wire [TID_WIDTH-1:0]     s_axis_tid,
    output wire                     s_axis_ready, // Using 'wire' for combinational assign

    // Master AXI-Stream Interface (Registered Outputs)
    output reg                      m_axis_valid,
    output reg [DATA_WIDTH-1:0]     m_axis_data,
    output reg [TID_WIDTH-1:0]      m_axis_tid,
    input  wire                     m_axis_ready
);

    // Internal buffer registers to hold one transaction
    reg [DATA_WIDTH-1:0]  buffer_data_reg;
    reg [TID_WIDTH-1:0]   buffer_tid_reg;
    reg                   buffer_full_reg; // Indicates if buffer_data_reg holds valid data

    // s_axis_ready: Can accept if the buffer is not full.
    // This is a continuous assignment to an output wire. Correct for Verilog-2001.
    assign s_axis_ready = !buffer_full_reg;

    always @(posedge axi_clk or negedge axi_resetn) begin // START always
        if (!axi_resetn) begin // START if_reset
            // Reset state
            m_axis_valid     <= 1'b0;
            m_axis_data      <= {DATA_WIDTH{1'b0}};
            m_axis_tid       <= {TID_WIDTH{1'b0}};
            buffer_data_reg  <= {DATA_WIDTH{1'b0}};
            buffer_tid_reg   <= {TID_WIDTH{1'b0}};
            buffer_full_reg  <= 1'b0;
        end else begin // START else_for_reset
            // This logic implements a standard single-element skid buffer.

            if (m_axis_valid && !m_axis_ready) begin // START if_stalled
                // --- STALLED State ---
                m_axis_valid <= 1'b1; // Keep m_axis_valid asserted.

                if (!buffer_full_reg && s_axis_valid && s_axis_ready) begin // START inner_if_stall_buffering
                    buffer_data_reg <= m_axis_data; 
                    buffer_tid_reg  <= m_axis_tid;  
                    buffer_full_reg <= 1'b1;        
                end // END inner_if_stall_buffering
            end else begin // START else_for_stalled (NOT STALLED State)
                if (buffer_full_reg) begin // START inner_if_buffer_output
                    m_axis_data     <= buffer_data_reg;
                    m_axis_tid      <= buffer_tid_reg;
                    m_axis_valid    <= 1'b1;
                    buffer_full_reg <= 1'b0; 
                end else if (s_axis_valid && s_axis_ready) begin // START inner_else_if_passthrough
                    m_axis_data     <= s_axis_data;
                    m_axis_tid      <= s_axis_tid;
                    m_axis_valid    <= 1'b1;
                end else begin // START inner_else_idle
                    m_axis_valid    <= 1'b0; 
                end // END inner_else_idle (also effectively ends inner_if_buffer_output and inner_else_if_passthrough)
            end // END else_for_stalled
        end // END else_for_reset
    end // END always

endmodule