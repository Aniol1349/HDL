`timescale 1ns / 1ps

module ChebeshyvDSP_1 #(
    parameter DATA_WIDTH = 32,
    parameter STATE_PASS_THROUGH = 1'b0,
    parameter STATE_BUFFER = 1'b1
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

    // FSM state registers
    reg current_state, next_state;

    // Data Buffer Register
    reg [DATA_WIDTH-1:0] buffer_reg;

    //-----------------------------------
    // Sequential FSM state update logic
    //-----------------------------------
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            current_state <= STATE_PASS_THROUGH;
        end else begin
            current_state <= next_state;
        end
    end

    //-----------------------------
    // Combinational next-state logic
    //-----------------------------
    always @(*) begin
        case (current_state)
            STATE_PASS_THROUGH: begin
                if (s_axis_valid && !m_axis_ready)
                    next_state = STATE_BUFFER;
                else
                    next_state = STATE_PASS_THROUGH;
            end

            STATE_BUFFER: begin
                if (m_axis_ready)
                    next_state = STATE_PASS_THROUGH;
                else
                    next_state = STATE_BUFFER;
            end

            default: next_state = STATE_PASS_THROUGH;
        endcase
    end

    //---------------------------------------------------------
    // Sequential logic: AXI-Stream handshake and buffer output
    //---------------------------------------------------------
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            s_axis_ready <= 1'b1;                      // Ready to accept input data immediately
            m_axis_valid <= 1'b0;
            m_axis_data  <= {DATA_WIDTH{1'b0}};
            buffer_reg   <= {DATA_WIDTH{1'b0}};
        end else begin
            case (current_state)

                STATE_PASS_THROUGH: begin
                    s_axis_ready <= 1'b1;              // Accepting new data from upstream
                    if (s_axis_valid && m_axis_ready) begin
                        m_axis_data  <= s_axis_data;   // Direct passthrough, no buffering needed
                        m_axis_valid <= 1'b1;
                    end else if (s_axis_valid && !m_axis_ready) begin
                        m_axis_valid <= 1'b0;          // Consumer stalled; data will be buffered
                    end else begin
                        m_axis_valid <= 1'b0;          // No valid data to pass through
                    end
                end

                STATE_BUFFER: begin
                    s_axis_ready <= 1'b0;              // Buffer full, stall upstream data
                    m_axis_data  <= buffer_reg;        // Output buffered data
                    m_axis_valid <= 1'b1;
                    if (m_axis_ready) begin
                        m_axis_valid <= 1'b0;          // Buffered data consumed, ready to return to pass-through
                    end
                end

                default: begin
                    s_axis_ready <= 1'b1;
                    m_axis_valid <= 1'b0;
                end
            endcase
        end
    end

    //--------------------------------------------------
    // Buffer register loading logic on state transition
    //--------------------------------------------------
    always @(posedge axi_clk or negedge axi_resetn) begin
        if (!axi_resetn) begin
            buffer_reg <= {DATA_WIDTH{1'b0}};
        end else if (current_state == STATE_PASS_THROUGH && next_state == STATE_BUFFER) begin
            buffer_reg <= s_axis_data;                 // Capture input data into buffer register
        end
    end

endmodule
