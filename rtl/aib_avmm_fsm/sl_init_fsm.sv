// This module is the top-level FSM for the AIB Slave calibration and initialization sequence.
// It instantiates and controls the execution of the following sub-FSMs in order:
// 1. sl_reset_duts_fsm:      Handles the initial reset sequence for the slave DUT.
// 2. sl_write_csr_adapt_fsm: Writes initial configuration to the adapter CSRs.
// 3. sl_duts_wakeup_fsm:     Brings the adapter and MAC out of reset and signals config done.
// 4. sl_phase_adjust_wrkarnd_fsm: Performs a complex phase adjustment workaround sequence.
// 5. link_up_fsm:            Waits for transfer enable signals to confirm link is up.
//
// It also instantiates the avalon_mm_fsm to serve as the physical bus interface for
// register read/write operations.

module calib_slave_fsm #(
    parameter ACTIVE_CHNLS   = 1,
    parameter TOTAL_CHNL_NUM = 24,
    parameter CLK_FREQ_MHZ   = 100,
    parameter AVMM_WIDTH     = 32,
    parameter BYTE_WIDTH     = 4,
    parameter ADDR_WIDTH     = 16,
    parameter GEN2_MODE      = 1'b1
) (
    // Clock and Reset
    input                               clk,
    input                               rst_n,

    // AIB Interface from Master
    input      [TOTAL_CHNL_NUM-1:0]     ms_tx_transfer_en,
    input      [TOTAL_CHNL_NUM-1:0]     ms_rx_transfer_en, // Unused
    
    // Outputs to control the AIB slave
    output logic                        calib_done,
    output logic                        i_conf_done,
    output logic [TOTAL_CHNL_NUM-1:0]   ns_adapter_rstn,
    output logic [TOTAL_CHNL_NUM-1:0]   ns_mac_rdy,
    output logic [TOTAL_CHNL_NUM-1:0]   sl_rx_dcc_dll_lock_req,
    output logic [TOTAL_CHNL_NUM-1:0]   sl_tx_dcc_dll_lock_req,
    output logic                        i_m_power_on_reset,

    // Avalon-MM Interface for register access
    output logic [ADDR_WIDTH-1:0]       avmm_address_o,
    output logic                        avmm_read_o,
    output logic                        avmm_write_o,
    output logic [AVMM_WIDTH-1:0]       avmm_writedata_o,
    output logic [BYTE_WIDTH-1:0]       avmm_byteenable_o,
    input      [AVMM_WIDTH-1:0]         avmm_readdata_i,
    input                               avmm_readdatavalid_i,
    input                               avmm_waitrequest_i
);

    // Main FSM state definitions
    typedef enum logic [3:0] {
        IDLE,
        RESET_DUTS,
        WRITE_CSR,
        DUTS_WAKEUP,
        PHASE_ADJUST,
        DCC_BYPASS,
        DLL_BYPASS,
        LINK_UP,
        CAL_DONE
    } main_fsm_state_t;

    main_fsm_state_t current_state, next_state;

    // --- Sub-FSM Start/Done Signals ---
    logic reset_duts_start,     reset_duts_done;
    logic write_csr_start,      write_csr_done;
    logic duts_wakeup_start,    duts_wakeup_done;
    logic phase_adjust_start,   phase_adjust_done;
    logic link_up_start,        link_up_done;
    logic dcc_bypass_done,      dcc_bypass_start;
    logic dll_bypass_done,      dll_bypass_start;
    logic avmm_fsm_start,       avmm_fsm_done;
    
    // --- Sub-FSM Output Wires ---
    logic reset_duts_avmm_rst_n;
    logic [TOTAL_CHNL_NUM-1:0] reset_duts_adapter_rstn, wakeup_adapter_rstn;
    logic wakeup_conf_done;
    logic [TOTAL_CHNL_NUM-1:0] wakeup_mac_rdy;
    logic [TOTAL_CHNL_NUM-1:0] wakeup_rx_lock;
    logic [TOTAL_CHNL_NUM-1:0] wakeup_tx_lock;
    // Wires for unused outputs of sl_reset_duts_fsm
    logic                      reset_s1_i_conf_done_w;
    logic [TOTAL_CHNL_NUM-1:0] reset_s1_ns_mac_rdy_w;
    logic [TOTAL_CHNL_NUM-1:0] reset_s1_sl_rx_dcc_dll_lock_req_w;
    logic [TOTAL_CHNL_NUM-1:0] reset_s1_sl_tx_dcc_dll_lock_req_w;
    logic                      reset_s1_m_device_detect_ovrd_w;
    logic [TOTAL_CHNL_NUM*80-1:0]   reset_s1_data_in_w;
    logic [TOTAL_CHNL_NUM*320-1:0] reset_s1_data_in_f_w;
    logic [TOTAL_CHNL_NUM*80-1:0]   reset_s1_gen1_data_in_f_w;


    // --- Avalon Muxing Logic ---
    logic csr_avmm_start, phase_avmm_start;
    logic csr_avmm_is_write, phase_avmm_is_write;
    logic [ADDR_WIDTH-1:0] csr_avmm_addr, phase_avmm_addr;
    logic [AVMM_WIDTH-1:0] csr_avmm_wdata, phase_avmm_wdata;
    logic [BYTE_WIDTH-1:0] csr_avmm_be, phase_avmm_be;
    logic avmm_is_write_mux;
    logic [ADDR_WIDTH-1:0] avmm_addr_mux;
    logic [AVMM_WIDTH-1:0] avmm_wdata_mux;
    logic [BYTE_WIDTH-1:0] avmm_be_mux;

    //================================================================
    // Main FSM Logic
    //================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        calib_done = 1'b0;
        
        reset_duts_start   = 1'b0;
        write_csr_start    = 1'b0;
        duts_wakeup_start  = 1'b0;
        phase_adjust_start = 1'b0;
        link_up_start      = 1'b0;
        
        case(current_state)
            IDLE:           next_state = RESET_DUTS;
            RESET_DUTS:     if (reset_duts_done)   next_state = WRITE_CSR;    else reset_duts_start = 1'b1;
            WRITE_CSR:      if (write_csr_done)    next_state = DUTS_WAKEUP;  else write_csr_start = 1'b1;
            DUTS_WAKEUP:    
                if (duts_wakeup_done) begin
                    if (GEN2_MODE) begin
                        next_state = PHASE_ADJUST; 
                    end else begin
                        next_state = DCC_BYPASS; 
                    end
                end else begin
                    duts_wakeup_start = 1'b1;
                end
            PHASE_ADJUST:   if (phase_adjust_done) next_state = LINK_UP;      else phase_adjust_start = 1'b1;
            LINK_UP:        if (link_up_done)      next_state = CAL_DONE;     else link_up_start = 1'b1;
            CAL_DONE:       calib_done = 1'b1;
            default:        next_state = IDLE;
        endcase
    end
    
    //================================================================
    // Sub-FSM Instantiations
    //================================================================

    sl_reset_duts_fsm #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ),
        .TOTAL_CHNL_NUM(TOTAL_CHNL_NUM)
    ) i_sl_reset_duts_fsm (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(reset_duts_start), 
        .done(reset_duts_done),
        .avmm_if_s1_rst_n(reset_duts_avmm_rst_n),
        .s1_ns_adapter_rstn(reset_duts_adapter_rstn),
        .s1_i_m_power_on_reset(i_m_power_on_reset),
        // Connect remaining unused outputs to dummy wires
        .s1_i_conf_done(reset_s1_i_conf_done_w),
        .s1_ns_mac_rdy(reset_s1_ns_mac_rdy_w),
        .s1_sl_rx_dcc_dll_lock_req(reset_s1_sl_rx_dcc_dll_lock_req_w),
        .s1_sl_tx_dcc_dll_lock_req(reset_s1_sl_tx_dcc_dll_lock_req_w),
        .s1_m_device_detect_ovrd(reset_s1_m_device_detect_ovrd_w),
        .s1_data_in(reset_s1_data_in_w),
        .s1_data_in_f(reset_s1_data_in_f_w),
        .s1_gen1_data_in_f(reset_s1_gen1_data_in_f_w)
    );

    sl_write_csr_adapt_fsm #(
        .AVMM_WIDTH(AVMM_WIDTH), .BYTE_WIDTH(BYTE_WIDTH), .ADDR_WIDTH(ADDR_WIDTH),
        .ACTIVE_CHNLS(ACTIVE_CHNLS)
    ) i_sl_write_csr_adapt_fsm (
        .clk(clk), .rst_n(rst_n), .start(write_csr_start), .done(write_csr_done),
        .transaction_start(csr_avmm_start),
        .transaction_is_write(csr_avmm_is_write),
        .transaction_addr(csr_avmm_addr),
        .transaction_wdata(csr_avmm_wdata),
        .transaction_be(csr_avmm_be),
        .transaction_done(avmm_fsm_done)
    );
    
    sl_duts_wakeup_fsm #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ), .TOTAL_CHNL_NUM(TOTAL_CHNL_NUM)
    ) i_sl_duts_wakeup_fsm (
        .clk(clk), .rst_n(rst_n), .start(duts_wakeup_start), .done(duts_wakeup_done),
        .s1_i_conf_done(wakeup_conf_done),
        .s1_ns_mac_rdy(wakeup_mac_rdy),
        .s1_ns_adapter_rstn(wakeup_adapter_rstn),
        .s1_sl_rx_dcc_dll_lock_req(wakeup_rx_lock),
        .s1_sl_tx_dcc_dll_lock_req(wakeup_tx_lock)
    );

    sl_phase_adjust_wrkarnd_fsm #(
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ), .AVMM_WIDTH(AVMM_WIDTH), .BYTE_WIDTH(BYTE_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)
    ) i_sl_phase_adjust_wrkarnd_fsm (
        .clk(clk), .rst_n(rst_n), .start(phase_adjust_start), .done(phase_adjust_done),
        .transaction_start(phase_avmm_start),
        .transaction_is_write(phase_avmm_is_write),
        .transaction_addr(phase_avmm_addr),
        .transaction_wdata(phase_avmm_wdata),
        .transaction_be(phase_avmm_be),
        .transaction_done(avmm_fsm_done),
        .transaction_rdata(avmm_readdata_i)
    );

    avmm_multi_write_fsm #(
        .ACTIVE_CHNLS(ACTIVE_CHNLS),
        .SEQ_COUNT(4),
        .ADDR0(16'h34C),
        .DATA0(32'h0000_0000),
        .ADDR1(16'h350),
        .DATA1({1'b1,2'b0,3'b111,26'h0}),
        .ADDR2(16'h368),
        .DATA2({4{3'h0,5'd16}}),
        .ADDR3(16'h364),
        .DATA3({2'b11,30'h0})
    ) ms_dcc_bypass_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (dcc_bypass_start),
        .done    (dcc_bypass_done),
        .transaction_start     (csr_avmm_start),
        .transaction_is_write  (csr_avmm_is_write),
        .transaction_addr      (csr_avmm_addr),
        .transaction_wdata     (csr_avmm_wdata),
        .transaction_be        (csr_avmm_be),
        .transaction_done      (avmm_fsm_done)
    );

    avmm_multi_write_fsm #(
        .ACTIVE_CHNLS(ACTIVE_CHNLS),
        .SEQ_COUNT(2),
        .ADDR0(16'h348),
        .DATA0({1'b0,1'b1,1'b1,14'h0,8'h0,7'd64}),
        .ADDR1(16'h344),
        .DATA1({4'b1111,28'h0})
    ) ms_dll_bypass_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (dll_bypass_start),
        .done    (dll_bypass_done),
        .transaction_start     (csr_avmm_start),
        .transaction_is_write  (csr_avmm_is_write),
        .transaction_addr      (csr_avmm_addr),
        .transaction_wdata     (csr_avmm_wdata),
        .transaction_be        (csr_avmm_be),
        .transaction_done      (avmm_fsm_done)
    );

    
    link_up_fsm #(
        .TOTAL_CHNL_NUM(TOTAL_CHNL_NUM)
    ) i_link_up_fsm (
        .clk(clk), .rst_n(rst_n), .start(link_up_start), .done(link_up_done),
        .ms_tx_transfer_en(ms_tx_transfer_en),
        .sl_tx_transfer_en(wakeup_tx_lock) // Assuming sl_tx_transfer_en is equivalent to sl_tx_dcc_dll_lock_req
    );

    avalon_mm_fsm #(
        .AVMM_WIDTH(AVMM_WIDTH), .BYTE_WIDTH(BYTE_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)
    ) i_avalon_mm_fsm (
        .clk(clk), .rst_n(reset_duts_avmm_rst_n),
        .start_transaction(avmm_fsm_start),
        .is_write(avmm_is_write_mux),
        .transaction_addr(avmm_addr_mux),
        .transaction_wdata(avmm_wdata_mux),
        .transaction_be(avmm_be_mux),
        .transaction_rdata(avmm_readdata_i),
        .transaction_done(avmm_fsm_done),
        .avm_address(avmm_address_o),
        .avm_write(avmm_write_o),
        .avm_read(avmm_read_o),
        .avm_writedata(avmm_writedata_o),
        .avm_byteenable(avmm_byteenable_o),
        .avm_readdata(avmm_readdata_i),
        .avm_readdatavalid(avmm_readdatavalid_i),
        .avm_waitrequest(avmm_waitrequest_i)
    );
    
    //================================================================
    // Muxing and Output Assignment
    //================================================================
    
    assign avmm_fsm_start    = (current_state == WRITE_CSR) ? csr_avmm_start : phase_avmm_start;
    assign avmm_is_write_mux = (current_state == WRITE_CSR) ? csr_avmm_is_write : phase_avmm_is_write;
    assign avmm_addr_mux     = (current_state == WRITE_CSR) ? csr_avmm_addr : phase_avmm_addr;
    assign avmm_wdata_mux    = (current_state == WRITE_CSR) ? csr_avmm_wdata : phase_avmm_wdata;
    assign avmm_be_mux       = (current_state == WRITE_CSR) ? csr_avmm_be : phase_avmm_be;

    assign i_conf_done            = wakeup_conf_done;
    assign ns_mac_rdy             = wakeup_mac_rdy;
    assign sl_rx_dcc_dll_lock_req = wakeup_rx_lock;
    assign sl_tx_dcc_dll_lock_req = wakeup_tx_lock;

    assign ns_adapter_rstn  = (current_state == RESET_DUTS) ? reset_duts_adapter_rstn : wakeup_adapter_rstn;
    
endmodule
