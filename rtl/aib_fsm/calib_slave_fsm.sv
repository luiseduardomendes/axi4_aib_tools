//
// File: calib_slave_fsm.sv
// Description: Top-level slave FSM that orchestrates the slave-side AIB 
//              initialization flow.
//
module calib_slave_fsm #(
    parameter TOTAL_CHNL_NUM = 24,
    parameter CLK_FREQ_MHZ = 100
)(
    // Clock and Reset
    input  logic clk,
    input  logic rst_n,

    // From Master AIB
    input  logic [TOTAL_CHNL_NUM-1:0] ms_rx_dcc_dll_lock_req,
    input  logic [TOTAL_CHNL_NUM-1:0] ms_tx_dcc_dll_lock_req,

    // To Slave AIB
    output reg                       i_conf_done,
    output reg [TOTAL_CHNL_NUM-1:0] ns_mac_rdy,
    output reg [TOTAL_CHNL_NUM-1:0] ns_adapter_rstn,
    output reg [TOTAL_CHNL_NUM-1:0] sl_rx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] sl_tx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en,
    output reg [TOTAL_CHNL_NUM-1:0] sl_rx_transfer_en,

    // AVMM Interface
    output logic       avmm_write_o,
    output logic       avmm_read_o,
    output logic[16:0] avmm_address_o,
    output logic[31:0] avmm_writedata_o,
    output logic[3:0]  avmm_byteenable_o,
    input  logic       avmm_waitrequest_i
);
    localparam DELAY_1000NS = CLK_FREQ_MHZ;
    typedef enum logic[3:0] { IDLE, STATIC_CONFIG, WAKEUP, WAKEUP_WAIT, WAIT_MASTER_REQ, RESPOND, LINK_UP, DONE } state_t;
    state_t state, next_state;
    
    logic [10:0] delay_cnt;
    logic start_reg_config, reg_config_done;

    initial_register_config_fsm #(.TOTAL_CHNL_NUM(TOTAL_CHNL_NUM)) 
        reg_config_inst(.clk(clk), .rst_n(rst_n), .start_config(start_reg_config), .config_done(reg_config_done), .is_bca_mode(1'b1), .*);
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) state <= IDLE; else state <= next_state;
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) delay_cnt <= '0;
        else if(state != next_state) delay_cnt <= '0;
        else delay_cnt <= delay_cnt + 1;
    end

    always_comb begin
        next_state = state;
        i_conf_done = 1'b0; ns_mac_rdy = '0; ns_adapter_rstn = '0;
        sl_rx_dcc_dll_lock_req = '0; sl_tx_dcc_dll_lock_req = '0;
        sl_tx_transfer_en = '0; sl_rx_transfer_en = '0;
        start_reg_config = 1'b0;
        
        case(state)
            IDLE: next_state = STATIC_CONFIG;
            STATIC_CONFIG: begin start_reg_config = 1'b1; if(reg_config_done) next_state = WAKEUP; end
            WAKEUP: begin i_conf_done = 1'b1; ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; next_state = WAKEUP_WAIT; end
            WAKEUP_WAIT: begin i_conf_done = 1'b1; ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; if(delay_cnt >= DELAY_1000NS) begin ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}}; next_state = WAIT_MASTER_REQ; end end
            WAIT_MASTER_REQ: begin i_conf_done = 1'b1; ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}}; if((&ms_rx_dcc_dll_lock_req) && (&ms_tx_dcc_dll_lock_req)) next_state = RESPOND; end
            RESPOND: begin i_conf_done = 1'b1; ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}}; sl_rx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}}; sl_tx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}}; next_state = LINK_UP; end
            LINK_UP: begin i_conf_done = 1'b1; ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}}; sl_tx_transfer_en = {TOTAL_CHNL_NUM{1'b1}}; sl_rx_transfer_en = {TOTAL_CHNL_NUM{1'b1}}; next_state = DONE; end
            DONE: next_state = DONE;
        endcase
    end
endmodule
