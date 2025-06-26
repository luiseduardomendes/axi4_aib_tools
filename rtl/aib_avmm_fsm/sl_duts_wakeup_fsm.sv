// This module implements a synthesizable Finite-State Machine (FSM) to handle
// the DUTs wakeup sequence for the SLAVE side. It asserts the necessary signals
// to bring the AIB adapter out of configuration and into an active state.

module sl_duts_wakeup_fsm #(
    parameter CLK_FREQ_MHZ   = 100,
    parameter TOTAL_CHNL_NUM = 1
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start, // A pulse on this input starts the sequence
    output logic done,  // A pulse on this output indicates the sequence is complete

    // Outputs for Slave Interface 1 (intf_s1)
    output logic s1_i_conf_done,
    output logic [TOTAL_CHNL_NUM-1:0] s1_ns_mac_rdy,
    output logic [TOTAL_CHNL_NUM-1:0] s1_ns_adapter_rstn,
    output logic [TOTAL_CHNL_NUM-1:0] s1_sl_rx_dcc_dll_lock_req,
    output logic [TOTAL_CHNL_NUM-1:0] s1_sl_tx_dcc_dll_lock_req
);

    // FSM State Definitions
    typedef enum logic [2:0] {
        IDLE,
        SET_CONF_DONE,
        WAIT_1,
        DEASSERT_ADAPTER_RESET,
        WAIT_2,
        SET_LOCK_REQ,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Delay counter logic
    localparam DELAY_1000_NS = (CLK_FREQ_MHZ * 1000) / (1000*1000);

    logic [31:0] delay_counter;
    logic        counter_load;
    logic        counter_decr;
    logic        counter_is_zero;

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Delay counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_counter <= '0;
        end else if (counter_load) begin
            delay_counter <= DELAY_1000_NS;
        end else if (counter_decr) begin
            delay_counter <= delay_counter - 1;
        end
    end

    assign counter_is_zero = (delay_counter == 0);

    // FSM next state logic and output assignments
    always_comb begin
        // Default values
        next_state = current_state;
        done = 1'b0;
        counter_load = 1'b0;
        counter_decr = 1'b0;

        // Default output values
        s1_i_conf_done            = 1'b0;
        s1_ns_mac_rdy             = '0;
        s1_ns_adapter_rstn        = '0;
        s1_sl_rx_dcc_dll_lock_req = '0;
        s1_sl_tx_dcc_dll_lock_req = '0;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = SET_CONF_DONE;
                end
            end

            SET_CONF_DONE: begin
                s1_i_conf_done = 1'b1;
                s1_ns_mac_rdy  = {TOTAL_CHNL_NUM{1'b1}};
                next_state     = WAIT_1;
                counter_load   = 1'b1;
            end

            WAIT_1: begin
                s1_i_conf_done = 1'b1;
                s1_ns_mac_rdy  = {TOTAL_CHNL_NUM{1'b1}};
                counter_decr   = 1'b1;
                if (counter_is_zero) begin
                    next_state = DEASSERT_ADAPTER_RESET;
                end
            end

            DEASSERT_ADAPTER_RESET: begin
                s1_i_conf_done     = 1'b1;
                s1_ns_mac_rdy      = {TOTAL_CHNL_NUM{1'b1}};
                s1_ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};
                next_state         = WAIT_2;
                counter_load       = 1'b1;
            end

            WAIT_2: begin
                s1_i_conf_done     = 1'b1;
                s1_ns_mac_rdy      = {TOTAL_CHNL_NUM{1'b1}};
                s1_ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};
                counter_decr       = 1'b1;
                if (counter_is_zero) begin
                    next_state = SET_LOCK_REQ;
                end
            end

            SET_LOCK_REQ: begin
                s1_i_conf_done            = 1'b1;
                s1_ns_mac_rdy             = {TOTAL_CHNL_NUM{1'b1}};
                s1_ns_adapter_rstn        = {TOTAL_CHNL_NUM{1'b1}};
                s1_sl_rx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
                s1_sl_tx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
                next_state                = SEQUENCE_DONE;
            end

            SEQUENCE_DONE: begin
                // Keep signals asserted while signaling done
                s1_i_conf_done            = 1'b1;
                s1_ns_mac_rdy             = {TOTAL_CHNL_NUM{1'b1}};
                s1_ns_adapter_rstn        = {TOTAL_CHNL_NUM{1'b1}};
                s1_sl_rx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
                s1_sl_tx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
                done                      = 1'b1;
                next_state                = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
