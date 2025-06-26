module ms_reset_duts_fsm #(
    parameter CLK_FREQ_MHZ   = 100,
    parameter TOTAL_CHNL_NUM = 1
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start,
    output logic done,

    // AVMM interface output
    output logic avmm_if_m1_rst_n,

    // Master Interface outputs
    output logic m1_i_conf_done,
    output logic [TOTAL_CHNL_NUM-1:0]   m1_ns_mac_rdy,
    output logic [TOTAL_CHNL_NUM-1:0]   m1_ns_adapter_rstn,
    output logic [TOTAL_CHNL_NUM-1:0]   m1_ms_rx_dcc_dll_lock_req,
    output logic [TOTAL_CHNL_NUM-1:0]   m1_ms_tx_dcc_dll_lock_req,
    output logic                        m1_m_por_ovrd,
    output logic [TOTAL_CHNL_NUM*80-1:0]   m1_data_in,
    output logic [TOTAL_CHNL_NUM*320-1:0] m1_data_in_f,
    output logic [TOTAL_CHNL_NUM*40-1:0]   m1_gen1_data_in,
    output logic [TOTAL_CHNL_NUM*320-1:0] m1_gen1_data_in_f
);

    typedef enum logic [3:0] {
        IDLE,
        ASSERT_RESETS,
        WAIT_1,
        ASSERT_POR_OVRD,
        WAIT_2,
        DEASSERT_RESETS,
        WAIT_3,
        ASSERT_CONF_DONE,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    localparam DELAY_100_NS = (CLK_FREQ_MHZ * 100) / 1000;
    localparam DELAY_200_NS = (CLK_FREQ_MHZ * 200) / 1000;

    logic [31:0] delay_counter;
    logic        counter_load, counter_decr;
    logic        counter_is_zero;

    // FSM State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Delay Counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            delay_counter <= '0;
        else if (counter_load) begin
            case (next_state)
                WAIT_1: delay_counter <= DELAY_100_NS;
                WAIT_2: delay_counter <= DELAY_100_NS;
                WAIT_3: delay_counter <= DELAY_100_NS;
                default: delay_counter <= '0;
            endcase
        end else if (counter_decr) begin
            delay_counter <= delay_counter - 1;
        end
    end

    assign counter_is_zero = (delay_counter == 0);

    // FSM Next-State Logic & Outputs
    always_comb begin
        // Default values
        next_state     = current_state;
        done           = 1'b0;
        counter_load   = 1'b0;
        counter_decr   = 1'b0;

        // Default outputs (inactive)
        avmm_if_m1_rst_n       = 1'b1;
        m1_i_conf_done         = 1'b0;
        m1_ns_mac_rdy          = '0;
        m1_ns_adapter_rstn     = '0;
        m1_ms_rx_dcc_dll_lock_req = '0;
        m1_ms_tx_dcc_dll_lock_req = '0;
        m1_m_por_ovrd          = 1'b0;
        m1_data_in             = '0;
        m1_data_in_f           = '0;
        m1_gen1_data_in        = '0;
        m1_gen1_data_in_f      = '0;

        case (current_state)
            IDLE: begin
                if (start)
                    next_state = ASSERT_RESETS;
            end

            ASSERT_RESETS: begin
                avmm_if_m1_rst_n   = 1'b0;
                m1_ns_adapter_rstn = '0;
                next_state         = WAIT_1;
                counter_load       = 1'b1;
            end

            WAIT_1: begin
                avmm_if_m1_rst_n   = 1'b0;
                m1_ns_adapter_rstn = '0;
                counter_decr       = 1'b1;
                if (counter_is_zero)
                    next_state = ASSERT_POR_OVRD;
            end

            ASSERT_POR_OVRD: begin
                avmm_if_m1_rst_n   = 1'b0;
                m1_ns_adapter_rstn = '0;
                m1_m_por_ovrd      = 1'b1;
                next_state         = WAIT_2;
                counter_load       = 1'b1;
            end

            WAIT_2: begin
                avmm_if_m1_rst_n   = 1'b0;
                m1_ns_adapter_rstn = '0;
                m1_m_por_ovrd      = 1'b1;
                counter_decr       = 1'b1;
                if (counter_is_zero)
                    next_state = DEASSERT_RESETS;
            end

            DEASSERT_RESETS: begin
                avmm_if_m1_rst_n = 1'b1;
                m1_m_por_ovrd    = 1'b1;
                next_state       = WAIT_3;
                counter_load     = 1'b1;
            end

            WAIT_3: begin
                m1_m_por_ovrd  = 1'b1;
                counter_decr   = 1'b1;
                if (counter_is_zero)
                    next_state = ASSERT_CONF_DONE;
            end

            ASSERT_CONF_DONE: begin
                m1_i_conf_done = 1'b1;
                m1_m_por_ovrd  = 1'b1;
                next_state     = SEQUENCE_DONE;
            end

            SEQUENCE_DONE: begin
                done       = 1'b1;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
