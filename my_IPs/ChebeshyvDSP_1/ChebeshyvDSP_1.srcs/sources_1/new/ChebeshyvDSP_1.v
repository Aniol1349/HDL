`timescale 1ns / 1ps

module ChebeshyvDSP_1 #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH),
    parameter FIFO_ALMOST_FULL = FIFO_DEPTH - 8
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

    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr;
    reg [ADDR_WIDTH:0]   fifo_count;

    wire fifo_empty = (fifo_count == 0);
    wire fifo_full  = (fifo_count == FIFO_DEPTH);

    // Handshake control (no direct combinational path!)
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            s_axis_ready <= 1'b0;
            m_axis_valid <= 1'b0;
        end else begin
            // Throttle input early to prevent overflow
            s_axis_ready <= (fifo_count < FIFO_ALMOST_FULL);

            // Generate output valid appropriately
            if (!m_axis_valid || m_axis_ready)
                m_axis_valid <= !fifo_empty;
        end
    end

    // FIFO Write/Read management
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            write_ptr   <= 0;
            read_ptr    <= 0;
            fifo_count  <= 0;
            m_axis_data <= {DATA_WIDTH{1'b0}};
        end else begin
            // FIFO Write
            if (s_axis_valid && s_axis_ready) begin
                fifo[write_ptr] <= s_axis_data;
                write_ptr <= (write_ptr == FIFO_DEPTH - 1) ? 0 : write_ptr + 1;
            end

            // FIFO Read
            if (m_axis_valid && m_axis_ready) begin
                m_axis_data <= fifo[read_ptr];
                read_ptr <= (read_ptr == FIFO_DEPTH - 1) ? 0 : read_ptr + 1;
            end

            // Manage FIFO Count correctly
            case ({s_axis_valid && s_axis_ready, m_axis_valid && m_axis_ready})
                2'b01: fifo_count <= fifo_count - 1; // Read only
                2'b10: fifo_count <= fifo_count + 1; // Write only
                default: fifo_count <= fifo_count;   // No change / simultaneous R/W
            endcase
        end
    end

endmodule
