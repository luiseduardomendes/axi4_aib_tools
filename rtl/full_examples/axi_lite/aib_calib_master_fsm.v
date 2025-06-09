// calib_master_fsm.sv
// This FSM controls a calibration sequence and includes an Avalon-MM master interface
// to configure a peripheral using an instantiated Avalon configuration sequencer.

module calib_master_fsm #(
    parameter TOTAL_CHNL_NUM = 24
)(
    input  wire        clk,
    input  wire        rst_n,
    output reg         calib_done,

    // Control outputs to AIB master interface
    output reg                       i_conf_done, // Signifies that the configuration sequence (via Avalon) is done
    output reg [TOTAL_CHNL_NUM-1:0] ns_mac_rdy,
    output reg [TOTAL_CHNL_NUM-1:0] ns_adapter_rstn,
    output reg [TOTAL_CHNL_NUM-1:0] ms_rx_dcc_dll_lock_req,
    output reg [TOTAL_CHNL_NUM-1:0] ms_tx_dcc_dll_lock_req,

    // Status inputs from AIB slave interface
    input  wire [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en,
    input  wire [TOTAL_CHNL_NUM-1:0] sl_rx_transfer_en,

    // Avalon-MM Master Interface Ports
    // These ports will be driven by the instantiated avalon_config_sequencer
    output wire [16:0]                 avmm_address_o,
    output wire                        avmm_read_o,
    output wire                        avmm_write_o,
    output wire [AVMM_WIDTH-1:0]       avmm_writedata_o,
    output wire [BYTE_WIDTH-1:0]       avmm_byteenable_o,
    input  wire [AVMM_WIDTH-1:0]       avmm_readdata_i,      // Input, not used by current write-only sequencer
    input  wire                        avmm_readdatavalid_i, // Input, not used by current write-only sequencer
    input  wire                        avmm_waitrequest_i
);

    // Local parameters for Avalon Interface, matching the provided interface snippet
    localparam AVMM_WIDTH = 32;
    localparam BYTE_WIDTH = 4;

    typedef enum logic [2:0] {
        IDLE,
        RESET,
        CONFIGURING,        // State to trigger and wait for Avalon configuration
        CONF_DONE,          // Avalon configuration is complete
        ASSERT_READY,
        SEND_DLL_LOCK_REQ,
        WAIT_TRANSFER_EN,
        DONE
    } state_t;

    state_t state, next_state_logic; // Renamed 'next' to 'next_state_logic' to avoid keyword clash if any

    // Internal signals for controlling the avalon_config_sequencer
    logic acs_start_main_op;      // Start signal to avalon_config_sequencer
    logic acs_main_op_done;       // Done signal from avalon_config_sequencer

    // Instantiate the Avalon Configuration Sequencer
    // IMPORTANT: Ensure the 'avalon_config_sequencer' module definition is available in your project.
    // This instantiation assumes the interface of 'avalon_config_sequencer' as previously designed.
    avalon_config_sequencer u_avalon_config_sequencer (
        .clk                (clk),
        .rst_n              (rst_n),
        .start_main_op      (acs_start_main_op),
        .main_op_done       (acs_main_op_done),

        // Avalon MM Interface connections
        .avmm_address       (avmm_address_o),
        .avmm_writedata     (avmm_writedata_o),
        .avmm_byteenable    (avmm_byteenable_o),
        .avmm_write         (avmm_write_o),
        .avmm_read          (avmm_read_o),          // Sequencer will drive this (likely low for writes)
        .avmm_waitrequest   (avmm_waitrequest_i)
    );


    // State register: Determines the current state of the FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE; // Reset to IDLE state
        else
            state <= next_state_logic; // On clock edge, move to the calculated next state
    end

    // Next state logic: Combinational logic to determine the next state
    always_comb begin
        next_state_logic = state; // Default: stay in current state
        case (state)
            IDLE: next_state_logic = RESET;
            RESET: next_state_logic = CONFIGURING;
            CONFIGURING: begin
                // Wait in CONFIGURING state until the avalon_config_sequencer (acs) is done.
                if (acs_main_op_done)
                    next_state_logic = CONF_DONE;
                else
                    next_state_logic = CONFIGURING; // Stay polling acs_main_op_done
            end
            CONF_DONE: next_state_logic = ASSERT_READY;
            ASSERT_READY: next_state_logic = SEND_DLL_LOCK_REQ;
            SEND_DLL_LOCK_REQ: next_state_logic = WAIT_TRANSFER_EN;
            WAIT_TRANSFER_EN:
                if (sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}} &&
                    sl_rx_transfer_en == {TOTAL_CHNL_NUM{1'b1}})
                    next_state_logic = DONE;
            DONE: next_state_logic = DONE; // Stay in DONE state
            default: next_state_logic = IDLE;
        endcase
    end

    // Output logic: Determines the values of outputs based on the current state
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset values for all registered outputs
            calib_done          <= 1'b0;
            i_conf_done         <= 1'b0;
            ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b0}};
            ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b0}};
            ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
            ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
            acs_start_main_op   <= 1'b0; // Reset start signal to sequencer
        end else begin
            // Default assignments for signals that might not be set in every state
            // This helps in managing pulse signals or ensuring signals are de-asserted correctly.
            acs_start_main_op <= 1'b0; // Default to de-asserting start for sequencer

            case (state)
                IDLE: begin // Explicitly set all to reset state for clarity
                    calib_done          <= 1'b0;
                    i_conf_done         <= 1'b0;
                    ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b0}};
                    ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    acs_start_main_op   <= 1'b0;
                end
                RESET: begin
                    // Ensure outputs are at their initial values during RESET
                    calib_done          <= 1'b0;
                    i_conf_done         <= 1'b0; // i_conf_done is low until CONF_DONE state
                    ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b0}};
                    ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    acs_start_main_op   <= 1'b0;
                end
                CONFIGURING: begin
                    // Start the avalon_config_sequencer and keep i_conf_done low.
                    acs_start_main_op   <= 1'b1;
                    i_conf_done         <= 1'b0;
                    // Other calibration control signals remain at their reset values (low)
                    ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b1}};
                    ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    calib_done          <= 1'b0;
                end
                CONF_DONE: begin
                    // Avalon configuration is complete, so assert i_conf_done.
                    // acs_start_main_op is already de-asserted by default or explicitly here.
                    i_conf_done         <= 1'b1;
                    acs_start_main_op   <= 1'b0; // Ensure sequencer start is de-asserted
                    // Other signals remain as they were or at reset values.
                end
                ASSERT_READY: begin
                    // i_conf_done remains asserted (or could be a pulse if de-asserted here)
                    ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b1}};
                    ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b1}};
                end
                SEND_DLL_LOCK_REQ: begin
                    // ns_mac_rdy and ns_adapter_rstn could be de-asserted here if they are pulses
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                end
                WAIT_TRANSFER_EN: begin
                    // ms_rx_dcc_dll_lock_req and ms_tx_dcc_dll_lock_req remain asserted.
                end
                DONE: begin
                    calib_done          <= 1'b1;
                    // De-assert other signals if they should not persist after done.
                    i_conf_done         <= 1'b0; // Example: make i_conf_done a pulse
                    ns_mac_rdy          <= {TOTAL_CHNL_NUM{1'b0}};
                    ns_adapter_rstn     <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b0}};
                end
            endcase
        end
    end

endmodule
