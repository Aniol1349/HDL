`timescale 1ns / 1ps

module ChebeshyvDSP_1 #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  axi_clk,
    input  wire                  axi_resetn,

    // Slave AXI-Stream Interface
    input  wire                  s_axis_valid,
    input  wire [DATA_WIDTH-1:0] s_axis_data,
    output reg                   s_axis_ready,

    // Master AXI-Stream Interface
    output reg                   m_axis_valid,
    output reg  [DATA_WIDTH-1:0] m_axis_data,
    input  wire                  m_axis_ready
);

    //------------------------------
    // Internal registers and signals
    //------------------------------
    reg [DATA_WIDTH-1:0] buffer_reg;
    reg buffer_full;

    //--------------------------------------
    // Sequential logic for buffer management
    //--------------------------------------
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            buffer_reg   <= {DATA_WIDTH{1'b0}};
            buffer_full  <= 1'b0;
            m_axis_data  <= {DATA_WIDTH{1'b0}};
            m_axis_valid <= 1'b0;
        end else begin
            // Manage buffer loading
            if (s_axis_valid && s_axis_ready && !m_axis_ready) begin
                buffer_reg  <= s_axis_data; // Load buffer if output isn't ready
                buffer_full <= 1'b1;
            end else if (buffer_full && m_axis_ready) begin
                buffer_full <= 1'b0;       // Buffer content consumed
            end

            // Output data selection logic
            if (buffer_full) begin
                m_axis_data <= buffer_reg; // Send buffered data
            end else if (s_axis_valid && s_axis_ready) begin
                m_axis_data <= s_axis_data; // Direct passthrough
            end

            // m_axis_valid management (must remain stable until acknowledged)
            if (m_axis_valid && !m_axis_ready) begin
                m_axis_valid <= m_axis_valid; // Maintain assertion
            end else begin
                m_axis_valid <= buffer_full || (s_axis_valid && s_axis_ready);
            end
        end
    end

    //--------------------------------------
    // Combinational logic for slave readiness
    //--------------------------------------
    always @(*) begin
        s_axis_ready = !buffer_full; // Ready unless buffer is occupied
    end

endmodule
