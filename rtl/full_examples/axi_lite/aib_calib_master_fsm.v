module calib_master_fsm #(
    parameter TOTAL_CHNL_NUM = 24
)(
    input  wire        clk,
    input  wire        rst_n,
    output reg         calib_done,

    // Control outputs to AIB master interface
    output reg                       i_conf_done,
    output reg [TOTAL_CHNL_NUM-1:0] ns_mac_rdy,
    output reg [TOTAL_CHNL_NUM-1:0] ns_adapter_rstn,
    output reg [TOTAL_CHNL_NUM-1:0] ms_rx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] ms_tx_dcc_dll_lock_req,

    // Status inputs from AIB slave interface
    input  wire [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en,
    input  wire [TOTAL_CHNL_NUM-1:0] sl_rx_transfer_en
);

    typedef enum logic [2:0] {
        IDLE,
        RESET,
        CONF_DONE,
        ASSERT_READY,
        SEND_DLL_LOCK_REQ,
        WAIT_TRANSFER_EN,
        DONE
    } state_t;

    state_t state, next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next;
    end

    always_comb begin
        next = state;
        case (state)
            IDLE: next = RESET;
            RESET: next = CONF_DONE;
            CONF_DONE: next = ASSERT_READY;
            ASSERT_READY: next = SEND_DLL_LOCK_REQ;
            SEND_DLL_LOCK_REQ: next = WAIT_TRANSFER_EN;
            WAIT_TRANSFER_EN:
                if (sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}} &&
                    sl_rx_transfer_en == {TOTAL_CHNL_NUM{1'b1}})
                    next = DONE;
            DONE: next = DONE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calib_done          <= 1'b0;
            i_conf_done         <= 1'b0;
            ns_mac_rdy          <= '0;
            ns_adapter_rstn     <= '0;
            ms_rx_dcc_dll_lock_req <= '0;
            ms_tx_dcc_dll_lock_req <= '0;
        end else begin
            case (state)
                IDLE, RESET: begin
                    calib_done <= 1'b0;
                    i_conf_done <= 1'b0;
                    ns_mac_rdy <= '0;
                    ns_adapter_rstn <= '0;
                    ms_rx_dcc_dll_lock_req <= '0;
                    ms_tx_dcc_dll_lock_req <= '0;
                end
                CONF_DONE: begin
                    i_conf_done <= 1'b1;
                end
                ASSERT_READY: begin
                    ns_mac_rdy <= {TOTAL_CHNL_NUM{1'b1}};
                    ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b1}};
                end
                SEND_DLL_LOCK_REQ: begin
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                end
                DONE: begin
                    calib_done <= 1'b1;
                end
            endcase
        end
    end

endmodule
