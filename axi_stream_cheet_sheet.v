`timescale 1 ns / 1 ps

// ===========================================================================
// Comprehensive AXI Stream Cheat Sheet Module
// Demonstrates handshake signals, data flow, and minimal pass-through design
// ===========================================================================
module axi_stream_cheat_sheet #(
    // =========================================================================
    // 1. Parameters: Set Data Width and other AXI-Stream parameters
    // =========================================================================
    parameter integer DATA_WIDTH = 32
)(
    // =========================================================================
    // 2. AXI Stream Slave Interface (Inputs from an upstream module)
    // =========================================================================
    input  wire                       s_axis_aclk,     // Slave clock
    input  wire                       s_axis_aresetn,  // Active-low reset
    input  wire [DATA_WIDTH-1:0]     s_axis_tdata,    // Slave data
    input  wire                       s_axis_tvalid,   // Slave valid
    output wire                       s_axis_tready,   // Slave ready
    input  wire                       s_axis_tlast,    // Slave last (optional)

    // =========================================================================
    // 3. AXI Stream Master Interface (Outputs to a downstream module)
    // =========================================================================
    input  wire                       m_axis_aclk,     // Master clock
    input  wire                       m_axis_aresetn,  // Active-low reset
    output wire [DATA_WIDTH-1:0]     m_axis_tdata,    // Master data
    output wire                       m_axis_tvalid,   // Master valid
    input  wire                       m_axis_tready,   // Master ready
    output wire                       m_axis_tlast     // Master last (optional)
);

    // =========================================================================
    // 4. Registers and Wires
    // =========================================================================
    // Typically, you store incoming data if your module needs to buffer or process
    // it. For a simple pass-through, you might store just one word.
    // Here, we assume a same-clock design (i.e., s_axis_aclk == m_axis_aclk).
    // For different clocks, a dual-clock FIFO is required.

    reg [DATA_WIDTH-1:0]  fifo_data;
    reg                   fifo_valid;
    reg                   fifo_last;  // Keep track of tlast if needed

    // Handshake signals can be driven in various ways; here, we do a one-sample FIFO.
    // s_axis_tready and m_axis_tvalid are outputs, so we typically declare them as regs.
    // For clarity, we make them wires here, then assign them from internal regs if desired.

    // We'll keep the pass-through logic minimal, with commentary.

    // =========================================================================
    // 5. Combinational Assignments for Output
    // =========================================================================
    // For a single-clock domain pass-through, you can tie s_axis_tready to the
    // condition "FIFO is empty" and tie the master output data to FIFO contents.
    
    wire s_ready_int;    // Internally computed ready
    wire m_valid_int;    // Internally computed valid
    wire m_last_int;     // Internally computed last

    // The module outputs
    assign s_axis_tready = s_ready_int;
    assign m_axis_tdata  = fifo_data;
    assign m_axis_tvalid = m_valid_int;
    assign m_axis_tlast  = m_last_int;

    // =========================================================================
    // 6. Sequential Logic (Synchronous with s_axis_aclk)
    //    We assume the same clock for slave and master. 
    // =========================================================================
    always @(posedge s_axis_aclk) begin
        // Reset logic
        if (!s_axis_aresetn || !m_axis_aresetn) begin
            fifo_data  <= {DATA_WIDTH{1'b0}};
            fifo_valid <= 1'b0;
            fifo_last  <= 1'b0;
        end else begin
            // Capture data from slave if FIFO is empty (not storing data)
            // and the slave is presenting valid data.
            if (!fifo_valid && s_axis_tvalid && s_ready_int) begin
                fifo_data  <= s_axis_tdata;
                fifo_last  <= s_axis_tlast;
                fifo_valid <= 1'b1;
            end

            // If the master is ready and we have valid data, we "send" it
            // by clearing fifo_valid. In a single-word pass-through,
            // we send the data immediately in one cycle.
            if (fifo_valid && m_axis_tready) begin
                fifo_valid <= 1'b0;
            end
        end
    end

    // =========================================================================
    // 7. Handshake Logic
    // =========================================================================
    // If FIFO is empty, we can accept new data -> s_ready_int = ~fifo_valid
    // If FIFO is full, we hold off -> s_ready_int = 0
    // For the master, if FIFO is full, we drive valid -> m_valid_int = fifo_valid
    assign s_ready_int = ~fifo_valid;
    assign m_valid_int = fifo_valid;
    // Likewise for tlast, we simply pass the stored last bit:
    assign m_last_int  = fifo_last;

endmodule
