module calib_slave_fsm #(
    parameter TOTAL_CHNL_NUM = 24,
    localparam AVMM_WIDTH = 32,
    localparam BYTE_WIDTH = 4
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

    typedef enum logic [3:0] {
        S_IDLE,
        S_READY,
        S_CONFIGURING,
        S_PHASE_ADJUST,
        S_WAIT_REQ,
        S_RESPOND,
        S_DONE
    } s_state_t;

    s_state_t s_state, s_next;
    logic acs_start_main_op;      // Start signal to avalon_config_sequencer
    logic acs_main_op_done;       // Done signal from avalon_config_sequencer
    logic acs_start_phase_adj;
    logic acs_phase_adj_done;

    // Avalon-MM Master Interface Ports
    wire [16:0]                 avmm_address_o;
    wire                        avmm_read_o;
    wire                        avmm_write_o;
    wire [AVMM_WIDTH-1:0]       avmm_writedata_o;
    wire [BYTE_WIDTH-1:0]       avmm_byteenable_o;
    wire [AVMM_WIDTH-1:0]       avmm_readdata_i;      // Input, not used by current write-only sequencer
    wire                        avmm_readdatavalid_i; // Input, not used by current write-only sequencer
    wire                        avmm_waitrequest_i;

    // Instantiate the Avalon Configuration Sequencer
    // IMPORTANT: Ensure the 'avalon_config_sequencer' module definition is available in your project.
    // This instantiation assumes the interface of 'avalon_config_sequencer' as previously designed.
    avalon_config_sequencer u_avalon_config_sequencer (
        .clk                (clk),
        .rst_n              (rst_n),
        .start_main_op      (acs_start_main_op),
        .main_op_done       (acs_main_op_done),
        .start_phase_adj    (acs_start_phase_adj),
        .phase_adj_done     (acs_phase_adj_done),

        // Avalon MM Interface connections
        .avmm_address       (avmm_address_o),
        .avmm_writedata     (avmm_writedata_o),
        .avmm_byteenable    (avmm_byteenable_o),
        .avmm_write         (avmm_write_o),
        .avmm_read          (avmm_read_o),          // Sequencer will drive this (likely low for writes)
        .avmm_waitrequest   (avmm_waitrequest_i)
    );

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
            S_READY: s_next = S_CONFIGURING;
            S_CONFIGURING: begin
                if (acs_main_op_done)
                    s_next = S_PHASE_ADJUST;
                else
                    s_next = S_CONFIGURING;
            end
            S_PHASE_ADJUST: begin
                if (acs_phase_adj_done)
                    s_next = S_WAIT_REQ;
                else
                    s_next = S_PHASE_ADJUST;
            end
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
            acs_start_main_op <= 1'b0;
            acs_start_phase_adj <= 1'b0;
        end else begin
            case (s_state)
                S_IDLE: begin
                    i_conf_done <= 1'b0;
                    ns_mac_rdy <= '0;
                    acs_start_main_op <= 1'b0;
                    acs_start_phase_adj <= 1'b0;
                end
                S_READY: begin
                    i_conf_done <= 1'b1;
                    ns_mac_rdy <= {TOTAL_CHNL_NUM{1'b1}};
                    acs_start_main_op <= 1'b0;
                    acs_start_phase_adj <= 1'b0;
                end
                S_CONFIGURING: begin
                    acs_start_main_op <= 1'b1;
                    acs_start_phase_adj <= 1'b0;
                    ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_tx_transfer_en <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_rx_transfer_en <= {TOTAL_CHNL_NUM{1'b0}};
                end
                S_PHASE_ADJUST: begin
                    acs_start_main_op <= 1'b0;
                    acs_start_phase_adj <= 1'b1;
                    ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_tx_transfer_en <= {TOTAL_CHNL_NUM{1'b0}};
                    sl_rx_transfer_en <= {TOTAL_CHNL_NUM{1'b0}};
                end
                S_RESPOND: begin
                    acs_start_main_op <= 1'b0;
                    acs_start_phase_adj <= 1'b0;
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
