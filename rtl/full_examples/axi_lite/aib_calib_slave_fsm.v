module calib_slave_fsm #(
    parameter TOTAL_CHNL_NUM = 24
)(
    input  wire        clk,
    input  wire        rst_n,

    // Requests from master
    input  wire [TOTAL_CHNL_NUM-1:0] ms_rx_dcc_dll_lock_req,
    input  wire [TOTAL_CHNL_NUM-1:0] ms_tx_dcc_dll_lock_req,

    // Outputs
    output reg                       i_conf_done,
    output reg [TOTAL_CHNL_NUM-1:0] ns_mac_rdy,
    output reg [TOTAL_CHNL_NUM-1:0] ns_adapter_rstn,
    output reg [TOTAL_CHNL_NUM-1:0] sl_rx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] sl_tx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en,
    output reg [TOTAL_CHNL_NUM-1:0] sl_rx_transfer_en
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_READY,
        S_WAIT_REQ,
        S_RESPOND,
        S_DONE
    } s_state_t;

    s_state_t s_state, s_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s_state <= S_IDLE;
        else
            s_state <= s_next;
    end

    always_comb begin
        s_next = s_state;
        case (s_state)
            S_IDLE: s_next = S_READY;
            S_READY: s_next = S_WAIT_REQ;
            S_WAIT_REQ:
                if ((ms_rx_dcc_dll_lock_req == {TOTAL_CHNL_NUM{1'b1}}) &&
                    (ms_tx_dcc_dll_lock_req == {TOTAL_CHNL_NUM{1'b1}}))
                    s_next = S_RESPOND;
            S_RESPOND: s_next = S_DONE;
            S_DONE: s_next = S_DONE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_conf_done <= 1'b0;
            ns_mac_rdy <= '0;
            ns_adapter_rstn <= '0;
            sl_rx_dcc_dll_lock_req <= '0;
            sl_tx_dcc_dll_lock_req <= '0;
            sl_tx_transfer_en <= '0;
            sl_rx_transfer_en <= '0;
        end else begin
            case (s_state)
                S_IDLE: begin
                    i_conf_done <= 1'b0;
                    ns_mac_rdy <= '0;
                end
                S_READY: begin
                    i_conf_done <= 1'b1;
                    ns_mac_rdy <= {TOTAL_CHNL_NUM{1'b1}};
                end
                S_RESPOND: begin
                    ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b1}};
                    sl_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    sl_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    sl_tx_transfer_en <= {TOTAL_CHNL_NUM{1'b1}};
                    sl_rx_transfer_en <= {TOTAL_CHNL_NUM{1'b1}};
                end
            endcase
        end
    end

endmodule
