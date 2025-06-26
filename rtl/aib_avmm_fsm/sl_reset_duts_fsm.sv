// This module implements a synthesizable Finite-State Machine (FSM) to handle
// the Device Under Test (DUT) reset sequence for the SLAVE side only. It translates
// the provided task, which contains non-synthesizable delays, into a clocked,
// state-driven process.

module sl_reset_duts_fsm #(
    // Parameter to define the clock frequency in MHz. Used to calculate delays.
    parameter CLK_FREQ_MHZ   = 100,
    // Parameter to define the number of channels for data vectors.
    parameter TOTAL_CHNL_NUM = 1
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start, // A pulse on this input starts the reset sequence
    output logic done,  // A pulse on this output indicates the sequence is complete

    // Outputs for AVMM interfaces
    output logic avmm_if_s1_rst_n,

    // Outputs for Slave Interface 1 (intf_s1)
    output logic s1_i_conf_done,
    output logic s1_ns_mac_rdy,
    output logic s1_ns_adapter_rstn,
    output logic s1_sl_rx_dcc_dll_lock_req,
    output logic s1_sl_tx_dcc_dll_lock_req,
    output logic s1_m_device_detect_ovrd,
    output logic s1_i_m_power_on_reset,
    output logic [TOTAL_CHNL_NUM*80-1:0]   s1_data_in,
    output logic [TOTAL_CHNL_NUM*320-1:0] s1_data_in_f,
    output logic [TOTAL_CHNL_NUM*80-1:0]   s1_gen1_data_in_f
);

    // FSM State Definitions
    typedef enum logic [3:0] {
        IDLE,
        ASSERT_RESETS,
        WAIT_1,
        SETUP_INTERFACES,
        WAIT_2,
        ASSERT_SLAVE_POR,
        WAIT_3,
        DEASSERT_SLAVE_POR,
        WAIT_4,
        DEASSERT_MAIN_RESETS,
        WAIT_5,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Delay counter logic
    localparam DELAY_100_NS = (CLK_FREQ_MHZ * 100) / (1000*1000);
    localparam DELAY_200_NS = (CLK_FREQ_MHZ * 200) / (1000*1000);

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
            // Load counter with new delay value
            case(next_state)
                WAIT_1: delay_counter <= DELAY_100_NS;
                WAIT_2: delay_counter <= DELAY_100_NS;
                WAIT_3: delay_counter <= DELAY_200_NS;
                WAIT_4: delay_counter <= DELAY_200_NS;
                WAIT_5: delay_counter <= DELAY_100_NS;
                default: delay_counter <= '0;
            endcase
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

        // Default output values (inactive)
        avmm_if_s1_rst_n = 1'b1;

        s1_i_conf_done          = 1'b0;
        s1_ns_mac_rdy           = 1'b0;
        s1_ns_adapter_rstn      = 1'b0;
        s1_sl_rx_dcc_dll_lock_req = 1'b0;
        s1_sl_tx_dcc_dll_lock_req = 1'b0;
        s1_m_device_detect_ovrd = 1'b0;
        s1_i_m_power_on_reset   = 1'b0;
        s1_data_in              = '0;
        s1_data_in_f            = '0;
        s1_gen1_data_in_f       = '0;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = ASSERT_RESETS;
                end
            end

            ASSERT_RESETS: begin
                // Assert main system resets and initialize interface signals
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                // Move to the first wait state
                next_state   = WAIT_1;
                counter_load = 1'b1;
            end

            WAIT_1: begin
                // Maintain asserted resets while waiting
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                // Decrement counter
                counter_decr = 1'b1;
                if (counter_is_zero) begin
                    next_state = SETUP_INTERFACES;
                end
            end

            SETUP_INTERFACES: begin
                // Continue asserting resets
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                // Configure interface overrides
                s1_m_device_detect_ovrd = 1'b0;
                s1_i_m_power_on_reset   = 1'b0;
                // Move to the next wait state
                next_state   = WAIT_2;
                counter_load = 1'b1;
            end

            WAIT_2: begin
                // Maintain signal values from previous state
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                counter_decr     = 1'b1;
                if (counter_is_zero) begin
                    next_state = ASSERT_SLAVE_POR;
                end
            end

            ASSERT_SLAVE_POR: begin
                // Maintain previous state
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                // Assert slave power-on-reset
                s1_i_m_power_on_reset = 1'b1;
                next_state   = WAIT_3;
                counter_load = 1'b1;
            end

            WAIT_3: begin
                // Maintain previous state
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                s1_i_m_power_on_reset = 1'b1;
                counter_decr = 1'b1;
                if (counter_is_zero) begin
                    next_state = DEASSERT_SLAVE_POR;
                end
            end
            
            DEASSERT_SLAVE_POR: begin
                // Maintain previous state except for POR
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                // De-assert slave power-on-reset
                s1_i_m_power_on_reset = 1'b0;
                next_state   = WAIT_4;
                counter_load = 1'b1;
            end
            
            WAIT_4: begin
                // Maintain previous state
                avmm_if_s1_rst_n = 1'b0;
                s1_ns_adapter_rstn = 1'b0;
                counter_decr = 1'b1;
                if (counter_is_zero) begin
                    next_state = DEASSERT_MAIN_RESETS;
                end
            end

            DEASSERT_MAIN_RESETS: begin
                // De-assert main system resets
                avmm_if_s1_rst_n = 1'b1;
                next_state   = WAIT_5;
                counter_load = 1'b1;
            end
            
            WAIT_5: begin
                counter_decr = 1'b1;
                if (counter_is_zero) begin
                    next_state = SEQUENCE_DONE;
                end
            end

            SEQUENCE_DONE: begin
                // Signal that the sequence is finished for one cycle
                done = 1'b1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
