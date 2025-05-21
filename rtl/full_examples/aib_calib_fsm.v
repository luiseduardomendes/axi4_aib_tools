module aib_calibration_fsm #(
    parameter TOTAL_CHNL_NUM = 24
)(
    input  logic clk,
    input  logic rst_n,

    // Status inputs
    input  logic [TOTAL_CHNL_NUM-1:0] ms_tx_transfer_en,
    input  logic [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en,

    // Outputs to AIB interface
    output logic [TOTAL_CHNL_NUM-1:0] ns_mac_rdy,
    output logic [TOTAL_CHNL_NUM-1:0] ns_adapter_rstn,
    output logic [TOTAL_CHNL_NUM-1:0] rx_dcc_dll_lock_req,
    output logic [TOTAL_CHNL_NUM-1:0] tx_dcc_dll_lock_req,
    output logic i_conf_done,
    output logic m_por_ovrd,
    output logic i_m_power_on_reset,

    // FSM status
    output logic link_ready
);

typedef enum logic [2:0] {
    IDLE,
    RESET,
    WAIT_POWERON_RESET_DONE,
    CONFIG,
    WAKEUP,
    WAIT_LINKUP,
    DONE
} state_t;

state_t state, next_state;

logic [15:0] delay_counter; // general-purpose delay

// FSM state register
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// FSM transitions
always_comb begin
    next_state = state;
    case (state)
        IDLE: begin
            next_state = RESET;
        end
        RESET: begin
            if (delay_counter == 16'd1000) // wait for reset propagation
                next_state = WAIT_POWERON_RESET_DONE;
        end
        WAIT_POWERON_RESET_DONE: begin
            if (delay_counter == 16'd1000) // simulate POR delay
                next_state = CONFIG;
        end
        CONFIG: begin
            // In real design, handshake with AVMM config interface
            next_state = WAKEUP;
        end
        WAKEUP: begin
            if (delay_counter == 16'd1000)
                next_state = WAIT_LINKUP;
        end
        WAIT_LINKUP: begin
            if ((ms_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}}) &&
                (sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}}))
                next_state = DONE;
        end
        DONE: begin
            next_state = DONE;
        end
    endcase
end

// FSM Outputs
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_counter <= 0;
        ns_mac_rdy <= 0;
        ns_adapter_rstn <= 0;
        rx_dcc_dll_lock_req <= 0;
        tx_dcc_dll_lock_req <= 0;
        i_conf_done <= 0;
        i_m_power_on_reset <= 0;
        m_por_ovrd <= 0;
        link_ready <= 0;
    end else begin
        case (state)
            RESET: begin
                i_m_power_on_reset <= 0;
                m_por_ovrd <= 1;
                delay_counter <= delay_counter + 1;
            end
            WAIT_POWERON_RESET_DONE: begin
                i_m_power_on_reset <= 1;
                delay_counter <= delay_counter + 1;
            end
            CONFIG: begin
                // Trigger AVMM config here via separate controller
                i_m_power_on_reset <= 0;
            end
            WAKEUP: begin
                i_conf_done <= 1;
                ns_mac_rdy <= {TOTAL_CHNL_NUM{1'b1}};
                ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b1}};
                rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                delay_counter <= delay_counter + 1;
            end
            WAIT_LINKUP: begin
                // wait state
            end
            DONE: begin
                link_ready <= 1;
            end
        endcase
    end
end

endmodule
